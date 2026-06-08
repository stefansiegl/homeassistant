#!/usr/bin/env python3
"""Export hourly gas statistics (metadata_id=848) from HA backup without full restore."""
import argparse
import glob
import io
import json
import os
import sys
import tarfile
import tempfile

from securetar import SecureTarFile

META_ID = 848
STORAGE = "/config/.storage/backup"
BACKUP_DIR = "/backup"


def load_password():
    with open(STORAGE, encoding="utf-8") as f:
        data = json.load(f)
    pwd = data.get("data", {}).get("config", {}).get("create_backup", {}).get("password")
    if not pwd:
        raise SystemExit("Backup password not found in .storage/backup")
    return pwd


def find_backup_path(slug: str) -> str:
    for pattern in (
        os.path.join(BACKUP_DIR, f"{slug}.tar"),
        os.path.join(BACKUP_DIR, f"*{slug}*"),
    ):
        matches = sorted(glob.glob(pattern))
        if matches:
            return matches[-1]
    for path in sorted(glob.glob(os.path.join(BACKUP_DIR, "*.tar")), reverse=True):
        try:
            with open(path, "rb") as f:
                head = f.read(4)
            if head.startswith(b"{") or head.startswith(b"["):
                continue
        except OSError:
            continue
        return path
    raise SystemExit(f"Backup not found for slug {slug}")


def decrypt_outer_backup(backup_path: str, password: str, workdir: str) -> str:
    plain = os.path.join(workdir, "outer-plain.tar")
    with SecureTarFile(backup_path, password=password) as st:
        try:
            tar = st.open()
        except Exception:
            # pre-decrypted outer tar (e.g. from prior extraction)
            return backup_path
        with open(plain, "wb") as out:
            for chunk in iter(lambda: tar.fileobj.read(1024 * 1024), b""):
                out.write(chunk)
        st.close()
    return plain


def decrypt_inner_mariadb(outer_tar: str, password: str, workdir: str) -> str:
    plain = os.path.join(workdir, "core_mariadb-plain.tar")
    if os.path.exists(plain):
        return plain
    with tarfile.open(outer_tar, "r:") as outer:
        member = outer.getmember("core_mariadb.tar.gz")
        inner = outer.extractfile(member)
        st = SecureTarFile(fileobj=inner, password=password, gzip=True)
        intar = st.open()
        with open(plain, "wb") as out:
            for chunk in iter(lambda: intar.fileobj.read(1024 * 1024), b""):
                out.write(chunk)
        st.close()
    return plain


def extract_datadir(mariadb_plain: str, workdir: str) -> str:
    datadir = os.path.join(workdir, "datadir", "data", "databases")
    os.makedirs(datadir, exist_ok=True)
    with tarfile.open(mariadb_plain, "r:") as tar:
        for m in tar.getmembers():
            if m.name.startswith("data/databases/"):
                tar.extract(m, path=os.path.join(workdir, "datadir"))
    return datadir


def query_backup_stats(datadir: str, min_state: float, max_state: float):
    import subprocess
    import time

    socket = os.path.join(os.path.dirname(datadir), "mysqld.sock")
    pidfile = os.path.join(os.path.dirname(datadir), "mysqld.pid")
    log = os.path.join(os.path.dirname(datadir), "mysqld.log")
    for p in (socket, pidfile, log):
        try:
            os.remove(p)
        except FileNotFoundError:
            pass
    proc = subprocess.Popen(
        [
            "mariadbd",
            f"--user=root",
            f"--datadir={datadir}",
            f"--socket={socket}",
            f"--pid-file={pidfile}",
            f"--log-error={log}",
            "--bind-address=127.0.0.1",
            "--port=3308",
            "--innodb-force-recovery=1",
            "--skip-grant-tables",
        ],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )
    try:
        for _ in range(30):
            if os.path.exists(socket):
                break
            time.sleep(1)
        else:
            raise SystemExit("mariadbd on backup datadir failed to start")
        sql = (
            "SELECT start_ts, state FROM statistics "
            f"WHERE metadata_id={META_ID} AND state>={min_state} AND state<={max_state} "
            "ORDER BY start_ts"
        )
        out = subprocess.check_output(
            ["mariadb", f"--socket={socket}", "homeassistant", "-N", "-e", sql],
            text=True,
        )
        return out
    finally:
        proc.terminate()
        try:
            proc.wait(timeout=10)
        except subprocess.TimeoutExpired:
            proc.kill()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--slug", default="3a55c738")
    ap.add_argument("-o", "--output", default="/tmp/gas_backup_hourly.tsv")
    ap.add_argument("--min-state", type=float, default=9000)
    ap.add_argument("--max-state", type=float, default=10200)
    ap.add_argument("--outer-tar", help="Pre-decrypted outer backup tar")
    args = ap.parse_args()

    password = load_password()
    workdir = tempfile.mkdtemp(prefix="gas-export-")
    try:
        outer = args.outer_tar or decrypt_outer_backup(find_backup_path(args.slug), password, workdir)
        mariadb_plain = decrypt_inner_mariadb(outer, password, workdir)
        datadir = extract_datadir(mariadb_plain, workdir)
        tsv = query_backup_stats(datadir, args.min_state, args.max_state)
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(tsv)
        rows = len([ln for ln in tsv.splitlines() if ln.strip()])
        print(f"Exported {rows} rows to {args.output}")
    finally:
        pass


if __name__ == "__main__":
    main()
