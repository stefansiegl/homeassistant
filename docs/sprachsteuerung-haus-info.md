# Sprachsteuerung — Haus-Infos (Müll, Energie)

Info-Skripte mit **TTS** über `media_player.benachrichtigung_lautsprecher` — wie Garten-Status und Haustür.

## Müllabfuhr

| Skript | Beispiel |
|--------|----------|
| `haus_muell_info` | „Hey Google, **wann kommt Müll**?“ |

Quellen: `sensor.waste_rest_days/gelb_days/bio_days/papier_days` (Attribut `daysTo`).  
Antwortet für Abholungen in den **nächsten 14 Tagen**.

## Energie

| Skript | Beispiel | Inhalt |
|--------|----------|--------|
| `haus_strom_info` | „Hey Google, **wie viel Strom verbrauchen wir**?“ | Aktuelle Watt, kWh Bezug/Einspeisung, Kosten |
| `haus_energie_info` | „Hey Google, **Energie Status**“ | Strom + Wasser + Gas + Kosten |

Sensoren: `mt691_*_stabil`, `watermeter_value_stabil`, `gasmeter_value_stabil`, `*_kosten`.

**Hinweis:** Zählerstände und Kosten sind **kumuliert** seit Erfassung, nicht Monatswerte.

## Kinderzimmer-Licht

| Skript / Entity | Beispiel |
|---------------|----------|
| `script.licht_ein_adrian` | „Hey Google, **Licht Adrian an**“ |
| `script.licht_aus_adrian` | „Hey Google, **Licht Adrian aus**“ |
| `script.licht_ein_david` | „Hey Google, **Licht David an**“ |
| `script.licht_aus_david` | „Hey Google, **Licht David aus**“ |
| `script.licht_aus_alle` | „Hey Google, **alle Lichter aus**“ |
| `light.licht_1og_adrian` | „Hey Google, **schalte Licht Adrian** ein“ (direkt) |
| `light.licht_1og_david` | „Hey Google, **schalte Licht David** ein“ (direkt) |

## Testliste

[`sprachsteuerung-testliste.tsv`](sprachsteuerung-testliste.tsv) — zum Import in Google Sheets.

## Wichtig: Befehlsform statt Frage

Google/Gemini fängt **Fragen** ab („Wann kommt Müll?“, „Wie viel Strom?“) und antwortet selbst —
ohne Home Assistant.

**Info-Skripte:** „Hey Google, **starte** Müllabfuhr Info“ / „**starte** Strom Info“

**Aus/Stop:** „Rasensprenger **aus**“, „**deaktiviere** Rasensprenger“, „**stoppe** Bewässerung“ — nicht „aktiviere … aus“

Skripte erscheinen bei Google als **Szenen** — Trigger-Wort ist meist *aktiviere/starte* + Name.
