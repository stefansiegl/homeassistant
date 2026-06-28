# Sprachsteuerung — Haustür (Nuki)

Nur **Status abfragen** per Google Assistant — **kein Öffnen oder Schließen** per Sprache.

## Sprachbefehle

| Beispiel | Antwort (je nach Status) |
|----------|--------------------------|
| „Hey Google, **Haustür Status**“ | z. B. „Die Haustür ist abgeschlossen.“ |
| „Hey Google, **ist die Haustür zu**?“ | … |
| „Hey Google, **ist die Tür zu**?“ | … |

Mögliche Antworten:

- **Abgeschlossen** — `lock.nuki_haustur_lock` = `locked`
- **Aufgeschlossen** — `unlocked`
- **Nicht verriegelt / offen** — `unlatched`
- **Wird gerade bewegt** — `locking` / `unlocking`
- **Unbekannt** — Nuki nicht erreichbar

## Sicherheit

| Entity | Google Assistant |
|--------|------------------|
| `script.haustuer_status` | ✅ freigegeben (nur Info + TTS) |
| `lock.nuki_haustur_lock` | ❌ **nicht** freigegeben |

Öffnen/Schließen per Sprache ist bewusst nicht vorgesehen.

## Technik

- Skript: `script.haustuer_status` in `scripts.yaml`
- TTS: `media_player.benachrichtigung_lautsprecher`
- Quellen: `lock.nuki_haustur_lock`, `binary_sensor.nuki_haustur_locked`
- Freigabe: `google_assistant_expose.yaml`
- Aliase: `configuration.yaml` → `cloud.google_actions.entity_config`

Nach Änderungen: Core-Neustart, dann **„Hey Google, synchronisiere meine Geräte“**.

## Siehe auch

- [Sprachsteuerung Garten](sprachsteuerung-garten.md)
- Dashboard Batterie: Nuki-Batterie-Warnung in `docs/dashboard-batterie.md`
