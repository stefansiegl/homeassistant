# Benachrichtigung-Lautsprecher (TTS)

Zentraler **Media-Player-Gruppe** für Sprachausgaben (TTS) im Haus: Waschmaschine/Trockner, Garten-Status, Haustür, Haus-Infos.

## Entity

| Entity | Typ | Rolle |
|--------|-----|-------|
| `media_player.benachrichtigung_lautsprecher` | group (UI) | Ziel für alle TTS-Skripte und Haushalt-Benachrichtigungen |
| `media_player.nest_mini_esszimmer` | music_assistant | Aktuelles Wiedergabegerät (Nest Mini, physisch im Esszimmer) |
| `media_player.nest_mini_esszimmer_raw` | cast | Cast-Roh-Entity (Powercalc, ggf. Direktzugriff) |

**Früher:** Gruppe mit `media_player.kuche` + `media_player.bad_2og` (offline). Nest stammte aus dem Legozimmer (`media_player.legozimmer_1og` / `nest_mini_legozimmer_raw`).

## Verwendung

- `automations.yaml` — Waschmaschine/Trockner TTS, Haus-Warnungen
- `scripts.yaml` — Garten, Haustür, Müll/Energie-Infos
- Docs: `docs/haushalt-waschmaschine.md`, `docs/sprachsteuerung-*.md`

TTS-Aufruf typisch:

```yaml
- action: tts.speak
  target:
    entity_id: media_player.benachrichtigung_lautsprecher
  data:
    media_player_entity_id: media_player.benachrichtigung_lautsprecher
    message: "…"
```

## Einrichtung / Änderung

Gruppe und Mitglieder: **HA-UI** → Einstellungen → Helfer → „Benachrichtigung-Lautsprecher“.  
Gerätenamen/Area: UI oder Registry (Nest-Umzug Legozimmer → Esszimmer, 2026-06).

## Abnahme

1. `media_player.nest_mini_esszimmer` in HA erreichbar (nicht `unavailable`)
2. `media_player.benachrichtigung_lautsprecher` zeigt Gruppe mit Esszimmer-Nest
3. Test: `script.haustuer_status` oder Waschmaschine fertig → Sprache aus Esszimmer
