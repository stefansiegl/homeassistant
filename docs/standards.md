# Standards & KI-Regeln

Zentrale Konventionen für „Das gesunde Haus“. Claude Code lädt ergänzend [`CLAUDE.md`](../CLAUDE.md) und Skills unter [`.claude/skills/`](../.claude/skills/) — bei Widerspruch gilt dieses Dokument nach Abstimmung mit dem Nutzer.

## Vision

Sinnvolles Smart Home: Technik dient den Bewohnern und bleibt im Hintergrund.

## Dokumentation vor Code

1. Spec in `/docs` (Deutsch) anlegen oder aktualisieren  
2. Nutzer gibt Implementierung frei  
3. YAML / ESPHome / Zigbee anpassen  
4. Inventar-Docs und Abnahme-Checkliste pflegen  

**Was in YAML vs. UI gehört:** ausführlich in [`konfigurations-strategie.md`](./konfigurations-strategie.md).

## UI (Lovelace)

- **Cards:** Mushroom  
- **Layout:** Glue-Method (nahtliche, ruhige Oberfläche — keine „fremden“ Karten-Stile mischen)

Details pro Dashboard können in Feature-Specs stehen.

## Naming

| Ebene | Muster | Beispiel |
|-------|--------|----------|
| Friendly Name | `Typ-Geschoss-Raum[-Detail]` | `Licht-EG-Kueche` |
| entity_id | snake_case, oft Präfix `licht_`, `schalter_` | `light.licht_eg_kueche` |
| Lichtgruppen | `hauptlicht_*`, `alle_lichter_*` | `light.hauptlicht_wohnzimmer` |
| Automation | deutsch, Bereich vorne | `Müll: Benachrichtigung …` |

Vollständige Licht- und Controller-Listen: [`lights.md`](./lights.md).

## Automationen

- Modular nach Funktionsbereich (Beleuchtung, Müll, Klima, …)  
- Zigbee-Schalter: **Device Triggers** mit `device_id`, nicht nur Batterie-Sensor (siehe `lights.md`)  
- Sprachausgaben / Benachrichtigungen: deutsch, TTS wo im Bestand (`tts.google_translate_say`)

## Geheimnisse & Git

- Passwörter/Keys nur in `secrets.yaml` oder Add-on-Secrets — in YAML nur `!secret`  
- Nicht committen: `.storage`, `.cloud`, Logs, DBs (siehe `.gitignore`)

## Arbeit mit der KI

- Spec-Datei im Chat nennen: *„Implementiere `docs/briefkasten.md`“*  
- Scope eingrenzen: nur Automation, nur Template, kein Dashboard, …  
- Nach Implementierung in HA testen und Abnahme-Checkliste abhaken  
