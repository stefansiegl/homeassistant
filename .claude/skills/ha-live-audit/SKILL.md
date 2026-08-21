---
name: ha-live-audit
description: Modularer Live-Abgleich Repo-Dokumentation und YAML gegen die laufende Home-Assistant-Instanz. Verwenden bei „Live-Audit", „System-Abgleich", „Docs vs HA", audit-live --resume oder /loop ha-live-audit.
disable-model-invocation: true
---

# HA Live-Audit (Repo ↔ Live-System)

Periodischer Vollabgleich: Specs/Docs + YAML-Referenzen gegen die **laufende HA-Instanz**. Ergänzt `ha-abgleich` (Checkliste bei Implementierung).

Spec: [`docs/live-audit.md`](../../../docs/live-audit.md)

## Wann welcher Skill?

| Situation | Skill |
|-----------|-------|
| Feature implementieren, PR, Migration | `ha-abgleich` |
| Periodischer Docs↔Live-Check, Probleme finden | **`ha-live-audit`** |
| 1 Modul pro Tag automatisch | `/loop 1d ha-live-audit --resume` |
| **Alle 12 Module täglich abends** | Cron `bin/audit-live-nightly.sh` + geplanter Claude-Task (siehe Spec) |

## Session-Budget

- **Standard:** genau **1 Modul** pro Aufruf (`--module` oder `--resume`)
- **`--quick`:** T0+T1, kein T2-Domain-Skript
- **Nicht** alle 12 Module in einer Session — Langläufer über State-Manifest

## Workflow (on-demand)

1. Skill + Spec [`docs/live-audit.md`](../../../docs/live-audit.md) lesen
2. State prüfen: [`manifests/live-audit-state.json`](../../../manifests/live-audit-state.json)
3. Audit starten:
   ```bash
   bin/audit-live.sh --resume          # nächstes pending Modul
   bin/audit-live.sh --module haushalt # gezielt
   bin/audit-live.sh --reset-cycle     # neuer Zyklus
   ```
4. Neuesten Report lesen: `log/live-audit/*.md` + `.json`
5. **Summary** im Chat: Anzahl fail/warn/info, wichtigste Punkte
6. **Doc-Fixes** wo Abweichung klar (Spec/Inventar aktualisieren)
7. **Kein YAML** ohne expliziten Nutzer-Auftrag
8. State committen nur wenn Nutzer es wünscht

## Loop-Modus

```text
/loop 1d ha-live-audit --resume
```

Pro Tick: 1 Modul (`--resume`) → Report → Summary → Doc-Fixes. Nach 12 Modulen: `--reset-cycle`.

Nutzt den eingebauten `loop`-Skill von Claude Code (`/loop <intervall> <prompt>`) — kein eigener Loop-Skill im Repo nötig.

## Nightly (Cron + geplanter Task)

1. **Cron 22:00:** `bin/audit-live-nightly.sh` → `log/live-audit/nightly-latest.md`
2. **Geplanter Claude-Task** (eigene Session): Skill laden → Summary lesen → bei fail/warn Doc-Fixes; kein YAML ohne Auftrag
3. Install: `bin/install-audit-nightly-cron.sh` (einmalig)

Spec: [`docs/live-audit.md`](../../../docs/live-audit.md) → Automatisierung

## Report interpretieren

| Severity | Bedeutung | KI-Aktion |
|----------|-----------|-----------|
| `fail` | Entity fehlt, Automation aus, core check fail | Doc oder Implementierung klären; Nutzer informieren |
| `warn` | unavailable/unknown; bekannter offener Punkt | Spec prüfen; ggf. `known_issues` in Manifest |
| `info` | T2-Hinweise, Log-Warn-Schwellwert | Optional dokumentieren |

### False Positives (nicht als fail werten)

- **Service-Aufrufe** in YAML (`action:`, `service:`) — Extractor filtert, Rest manuell ignorieren
- **Config-Pfade** (`homeassistant.customize`, `lovelace.resources`) — keine Entities
- **Notify-Service-Namen** vs. echte Entity-IDs (z. B. Doc sagt `notify.mobile_app_pixel_9_pro`, Live: `notify.pixel_9_pro`) → **Doc-Fix**

### Bekannte Issues

In [`manifests/live-audit-modules.json`](../../../manifests/live-audit-modules.json) → `known_issues` (z. B. Home Connect Waschmaschine = `warn`).

## Nach dem Modul

Kurz notieren:

- Modul-ID + Status (ok/warn/fail)
- Geänderte Docs (Dateiliste)
- Offene Punkte für Nutzer (UI-only, Pairing, …)

Modul-Details: [`modules-reference.md`](modules-reference.md)

## Beispiele

**Nutzer:** „Mach einen Live-Audit."

→ `bin/audit-live.sh --resume` → Report `haushalt` → Summary → Doc-Fix wenn notify-Entity falsch benannt

**Nutzer:** `/loop 1d ha-live-audit --resume`

→ Loop armen → pro Tag 1 Modul → nach 12 Modulen Zyklus complete melden
