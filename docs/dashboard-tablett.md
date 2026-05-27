# Dashboard: Tablett (EG)

Kiosk-Dashboard für das **Tablet im Erdgeschoss** (`url_path`: `/dashboard-tablett`).

## Zweck & Design

| Prinzip | Bedeutung |
|---------|-----------|
| **Touch-first** | Große Flächen, wenig Präzision nötig — bedienbar mit dem Finger |
| **Aus der Ferne** | Lesbar/ab erkennbar von weiter weg (große Typo, klare Kontraste) |
| **Hübsch + funktional** | Wohnzimmer-tauglich, nicht „Admin-Übersicht“ |
| **Weniger ist mehr** | Keine Detail-Flut — nur das, was am Tablett gebraucht wird |

Technik: u. a. **button-card** (HACS), Szenen-Bilder unter `/local/images/dashboards/`, Schrift **MichromaLocal**.

## Aktueller Inhalt (Stand Migration)

1. **Licht-Szenen** (horizontal, große Karten): `scene.hell`, `scene.gemutlich`, `scene.kino`, `scene.sonnenuntergang`
2. **Müll-Hinweis** (button-card, JS-Template): Rest-, Gelb-, Bio-, Papier-Tonnen; Anzeige wenn nächste Abholung „bald“

YAML: [`dashboards/tablett.yaml`](../dashboards/tablett.yaml) — **1:1 aus Storage migriert**, noch nicht inhaltlich überarbeitet.

## Backlog (inhaltlich — später)

- [ ] **Müll-Logik prüfen/fixen** — Biomüll-Hinweis soll nicht dauerhaft angezeigt werden (Vermutung: `daysTo`-Logik / Schwellwert `min <= 10` vs. Kommentar „0 oder 1“)
- [ ] **Inhalt festlegen** — Was soll auf dem Tablett dauerhaft sichtbar sein? (Licht, Müll, Wetter, Lüftung, …)
- [ ] **Benutzer/Sichtbarkeit** — Tablet vermutlich Benutzer `kioskmode`; andere Nutzer (David, …) ggf. ausblenden; **Stefan (Admin)** sieht immer alles
- [ ] **Kiosk-Mode** (README-Roadmap) — ggf. mit HACS `kiosk-mode` verknüpfen
- [ ] **Lovelace-Ressourcen** — erledigt global in `configuration.yaml` (`button-card`, Mushroom, card-mod, kiosk-mode)

## Migration

- Storage-Quelle: `.storage/lovelace.dashboard_tablett`
- Nach YAML-Registrierung: **Core-Neustart** nötig (nicht nur YAML reload)
- Storage-Metadaten bleiben ggf. in `.storage` (harmlos, wie bei Adrian Licht)

## Siehe auch

- [`konfigurations-strategie.md`](./konfigurations-strategie.md) — Dashboard-Migrations-Backlog
- [`lights.md`](./lights.md) — Szenen
- [`standards.md`](./standards.md) — UI/Glue-Method
