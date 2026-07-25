# Sprachsteuerung — MS To Do Listen

Drei Listen per Sprache befüllen. Einträge landen in **Microsoft To Do** (Handy-App) über die Integration `ms365_todo`.

| Liste | MS-To-Do-Name | HA-Entity |
|-------|---------------|-----------|
| Einkaufen | Einkaufen | `todo.todo_einkaufen` |
| Kathi mitnehmen | Kathi mitnehmen | `todo.todo_kathi_mitnehmen` |
| Allgemein | Todo | `todo.todo_todo` |

## Sprachbefehle (Home Assistant Assist)

Die Befehle laufen über **Assist** (Satz-Trigger), nicht über die Google-Assistant-Gerätefreigabe.

### Einkaufsliste

- „Bitte **Milch** auf die Einkaufsliste setzen“
- „**Milch** auf die Einkaufsliste setzen“
- „Füge **Milch** zur Einkaufsliste hinzu“
- „Pack **Milch** auf die Einkaufsliste“

Antwort: „Milch steht auf der Einkaufsliste.“

### Kathi mitnehmen

- „Bitte nimm **Blumen** auf die Liste Kathi mitnehmen auf“
- „Nimm **Blumen** auf die Liste Kathi mitnehmen auf“
- „**Blumen** auf die Liste Kathi mitnehmen“

Antwort: „Blumen steht auf der Liste Kathi mitnehmen.“

### Allgemeine To-do-Liste

- „Bitte **Steuererklärung** auf die To do Liste setzen“
- „**Steuererklärung** auf die To do Liste setzen“
- „Füge **Steuererklärung** zur To do Liste hinzu“
- „**Steuererklärung** auf meine Aufgabenliste“

Antwort: „Steuererklärung steht auf der To do Liste.“

## Wo funktioniert das?

| Gerät | Funktioniert? |
|-------|---------------|
| **HA Companion App** (Assist-Button / Mikrofon) | ✅ Ja |
| **Home Assistant Voice** (Satellit) | ✅ Ja |
| **Assist im Browser** (Dashboard) | ✅ Ja (zum Testen) |
| **Hey Google** auf Nest/Home-Lautsprecher | ❌ Nein (siehe unten) |

Eure Assist-Pipeline **Gemini** hat `prefer_local_intents: true` — die Satz-Trigger werden lokal erkannt, bevor Gemini antwortet.

## Warum nicht „Hey Google, bitte Milch …“?

Die Nabu-Casa-Anbindung an Google Assistant unterstützt **keine Todo-Entities** und kann **keinen dynamischen Text** (den Artikelnamen) an Home Assistant übergeben. Skripte in Google sind nur „Starte X“ ohne Inhalt.

Die frühere Freigabe `todo.mstodo_*` in `google_assistant_expose.yaml` war doppelt wirkungslos (falsche Entity-IDs **und** nicht unterstützte Domain) — wurde entfernt.

### Workaround für Google-Lautsprecher

1. **Kurzfristig:** Assist auf dem Handy (HA-App) — gleiche Sätze ohne „Hey Google“.
2. **Mittelfristig:** Home-Assistant-Voice-Satellit im Wohnbereich (Wake-Word + Assist).
3. **Nicht empfohlen:** Google-eigene Einkaufsliste (syncet nicht zu MS To Do).

## Technik (Git)

Drei Automationen in `automations.yaml`:

- `todo_sprache_einkaufen`
- `todo_sprache_kathi_mitnehmen`
- `todo_sprache_allgemein`

Service-Aufruf **todo.add_item** (HA-Service, kein Entity) → Integration `ms365_todo`.

## Testen

1. HA Companion öffnen → Assist (Mikrofon).
2. „Bitte Testartikel auf die Einkaufsliste setzen“ sagen.
3. In HA **To-do lists** oder MS To Do auf dem Handy prüfen.

## Siehe auch

- [Sprachsteuerung Garten](sprachsteuerung-garten.md)
- [Sprachsteuerung Licht EG](sprachsteuerung-licht-eg.md)
