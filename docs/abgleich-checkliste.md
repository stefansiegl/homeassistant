# Abgleich-Checkliste (KI + Repo ↔ Home Assistant)

Diese Checkliste beschreibt, **was bei Änderungen** im Repo geprüft/abgeglichen werden soll, damit YAML/Docs und die reale Home-Assistant-Instanz konsistent bleiben.

Sie ist bewusst pragmatisch: lieber wenige, wiederholbare Checks als ein großer Prozess.

---

## Wenn wir neue Features implementieren (nach Spec)

- **Spec gelesen?** (`docs/<feature>.md` + `docs/standards.md` + `docs/konfigurations-strategie.md`)
- **Scope klar?** Welche Dateien dürfen geändert werden (YAML/Dashboards/ESPHome/Z2M)?
- **Benennung & Bereiche:**
  - Neue Entities / Geräte-Namen nach Naming-Standard
  - Relevante Areas/Bereiche prüfen: [`raeume-und-bereiche.md`](./raeume-und-bereiche.md)
- **Secrets:** neue Passwörter/Keys nur via `!secret` (nie hardcoden)

---

## Nach YAML-Änderungen (Safety)

- **HA YAML-Konfiguration prüfen** (UI: Einstellungen → System → YAML-Konfiguration prüfen)
- **Reload statt Restart**, wenn möglich:
  - Automationen/Skripte/Szenen reloaded
- **Fehlerbild**: wenn etwas fehlt, zuerst in Logs prüfen statt “blind” weiter ändern

---

## Abgleich-Inventar & Doku

- **Lichter/Controller:** `docs/lights.md` aktualisiert?
- **Hardware:** `docs/hardware.md` aktualisiert?
- **Integrationen/Add-ons:** `docs/integrationen-und-addons.md` aktualisiert, wenn wir etwas installieren/abschalten?
- **HACS:** nach manuellen HACS-Updates `bin/hacs-abgleich.sh --push`; automatisch sonntags 06:00 (Cron) — siehe [`hacs-inventar.md`](./hacs-inventar.md)
- **Räume/Bereiche:** bei Umbenennung/Neuanlage `docs/raeume-und-bereiche.md` aktualisieren (aus Area Registry ablesen)

---

## Dashboards (Lovelace) – wenn wir migrieren

- Pro Dashboard: Storage → YAML in `dashboards/*.yaml`
- In `configuration.yaml` unter `lovelace: dashboards:` registrieren
- Ressourcen (Mushroom/card-mod) konsistent halten

---

## “UI-only” Änderungen, die dokumentiert werden müssen

Auch wenn etwas bewusst in der UI bleibt (Pairing, OAuth, Add-on-Install), sollte danach ein kurzer Doku-Eintrag erfolgen:

- Was wurde geändert?
- Wo findet man es in HA?
- Welche Entities/IDs sind die “Anker” für YAML/Automationen?

