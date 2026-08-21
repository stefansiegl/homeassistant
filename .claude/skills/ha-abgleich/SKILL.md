---
name: ha-abgleich
description: Checkliste für konsistente Änderungen im Home-Assistant-Repo (Docs-first, YAML vs UI, Räume, Integrationen, Dashboards). Verwenden, wenn der Nutzer „Abgleich", „Checkliste", „konsistent halten", „Migration" oder „Review" erwähnt.
disable-model-invocation: true
---

# HA Abgleich (Repo ↔ Home Assistant)

Diese Skill-Checkliste wird genutzt, um Änderungen systematisch abzusichern und Doku/YAML/UI sauber zu halten.

## 1) Vor der Implementierung

- Relevante Specs lesen: `docs/<feature>.md`
- Standards prüfen: `docs/standards.md`
- YAML vs UI prüfen: `docs/konfigurations-strategie.md`
- Haus-Struktur prüfen: `docs/raeume-und-bereiche.md`
- Integrationen/Add-ons prüfen (falls betroffen): `docs/integrationen-und-addons.md`

## 2) Während der Implementierung

- Änderungen auf den Spec-Scope begrenzen (keine Neben-Refactors)
- Secrets: nur `!secret`, nichts hardcoden
- **`secrets.yaml` geändert:** Nutzer an **Google-Drive-Kopie** erinnern (siehe `CLAUDE.md`)
- Neue/änderte Entities:
  - Naming nach Standard
  - Inventar-Dateien aktualisieren (Lichter/HW)

## 3) Nach der Implementierung (Safety)

- HA YAML-Konfiguration prüfen (UI oder `ha core check`, falls verfügbar)
- Reload statt Restart, wo möglich (Automationen/Skripte/Szenen)
- Fehler in Logs prüfen, bevor weitergebaut wird

## 4) Doku-Abgleich

- `docs/abgleich-checkliste.md` abarbeiten
- Falls UI-only Schritte nötig waren: kurze Notiz ergänzen (was/wo/IDs)

## 5) Periodischer Live-Check

- Für vollständigen Docs↔Live-Abgleich: Skill **`ha-live-audit`** + `bin/audit-live.sh --resume`
- Spec: `docs/live-audit.md`

## Beispiele

- Nutzer: „Bitte mach den Abgleich und migrier das Tablett-Dashboard."
  - Aktion: Skill laden → Dashboard-Migration gemäß `konfigurations-strategie.md` → danach Doku-Update + YAML-Check.
