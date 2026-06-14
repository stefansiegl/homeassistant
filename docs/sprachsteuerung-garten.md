# Sprachsteuerung — Garten Bewässerung

Steuerung per **Google Assistant** (Nabu Casa / Home Assistant Cloud) und **Assist**.

**Hinweis:** Es gibt bewusst **kein** „Garten Bewässerung an“ — nicht genug Wasserdruck für alle Zonen gleichzeitig.

## Ziel-Phrasen (Beispiele)

| Zone | Nutzer sagt (DE) | Wirkung |
|------|------------------|---------|
| **A — großer Rasensprenger** | „Rasensprenger an“ / „großer Rasensprenger an“ | Zone A starten |
| **B — Versenkregner / Kreisregner** | „Versenkregner an“ / „Kreisregner an“ | Zone B starten |
| **C — Hecke / Beet / Tropf** | „Tropfschlauch an“ / „Hecke an“ / „Beet an“ / „Tropfregner an“ | Zone C starten |
| **A aus** | „Rasensprenger aus“ / „großer Rasensprenger aus“ | Zone A stoppen |
| **B aus** | „Versenkregner aus“ / „Kreisregner aus“ | Zone B stoppen |
| **C aus** | „Tropfschlauch aus“ / „Hecke aus“ / „Beet aus“ / „Tropfregner aus“ | Zone C stoppen |
| **Alles aus** | „Garten Bewässerung aus“ / „Bewässerung aus“ / „Garten Wasser aus“ | Alle Zonen stoppen |
| **Status** | „Läuft Bewässerung“ / „Welche Bewässerung läuft“ | Sprachausgabe: welche Zone läuft |

Google formuliert Scripts oft als „Starte …“ — die Aliase erlauben kürzere Varianten.

## Technik

### Scripts (Google = Szene/Script starten)

| Script | Primärname | Aktion |
|--------|------------|--------|
| `script.garten_rasen_gross_bewaessern` | Rasensprenger an | Ventil A öffnen → Dauer → schließen |
| `script.garten_rasen_klein_bewaessern` | Versenkregner an | Ventil B öffnen → Dauer → schließen |
| `script.garten_tropf_bewaessern` | Tropfschlauch an | Ventil C öffnen → Dauer → schließen |
| `script.garten_rasen_gross_aus` | Rasensprenger aus | Job stoppen + Ventil A zu |
| `script.garten_rasen_klein_aus` | Versenkregner aus | Job stoppen + Ventil B zu |
| `script.garten_tropf_aus` | Tropfschlauch aus | Job stoppen + Ventil C zu |
| `script.garten_bewaesserung_aus` | Garten Bewässerung aus | Alle Jobs stoppen + alle Ventile zu |
| `script.garten_bewaesserung_status` | Läuft Bewässerung | TTS: welche Zone(n) aktiv |

Status-Skript prüft offene Ventile **und** laufende Bewässerungs-Scripts. Ausgabe über `media_player.benachrichtigung_lautsprecher`.

Dauer: `input_number.garten_rasen_dauer_minuten` / `garten_tropf_dauer_minuten`.  
Sicherheit: `input_number.garten_max_laufzeit_stunden`.

### Aliase & Google-Namen

In `configuration.yaml` → `cloud.google_actions.entity_config` (Git-versioniert).  
Freigabe: `.storage/homeassistant.exposed_entities` für Google + Assist.

## Einrichtung (nach YAML-Änderung)

1. **YAML laden:** Skripte neu laden oder Core-Neustart
2. **Google Home:** „Hey Google, synchronisiere meine Geräte“
3. Test: „Hey Google, Rasensprenger an“ / „Läuft Bewässerung“

## Referenzen

- Bewässerungslogik: [`garten-bewaesserung.md`](garten-bewaesserung.md)
- Vorbild Licht EG: [`sprachsteuerung-licht-eg.md`](sprachsteuerung-licht-eg.md)

## Freigabe Google Assistant

Die Script-Entities werden in der HA-UI unter **Einstellungen → Sprachassistenten → Google Assistant → Freilegen** sichtbar, sofern `expose_new: true` (Nabu Casa) aktiv ist. Zusätzlich sind die Garten-Scripts in `.storage/homeassistant.exposed_entities` für Google + Assist freigegeben (nicht in Git — bei Neuaufsetzen einmal prüfen).

Nach YAML-Änderungen: **„Hey Google, synchronisiere meine Geräte“**.

## Status prüfen

- Sprache: „Läuft Bewässerung“ / „Welche Bewässerung läuft“
- Skript prüft offene Ventile und laufende Bewässerungs-Jobs
- Antwort per TTS auf `media_player.benachrichtigung_lautsprecher`
- Alles stoppen: „Garten Bewässerung aus“ (schadet nicht, wenn bereits aus)
