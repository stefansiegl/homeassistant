# Das gesunde Haus — Regeln für Claude Code

Home-Assistant-Konfiguration als "Design as Code". Diese Datei ist die
**self-contained** Quelle für KI-Arbeitsregeln (versioniert in Git, kein
Cross-Session-Memory außerhalb des Repos). Ergänzende Skills liegen unter
[`.claude/skills/`](./.claude/skills/) (`ha-abgleich`, `ha-live-audit`) —
bei Widerspruch gilt nach Abstimmung mit dem Nutzer diese Datei bzw.
[`docs/standards.md`](./docs/standards.md).

## Sprache

- Antworte dem Nutzer auf **Deutsch**, außer er schreibt Englisch.
- Docs in `/docs` sind Deutsch. Entity-IDs/YAML-Keys bleiben wie in Home
  Assistant üblich (meist Englisch/snake_case).

## Workflow (verbindlich)

1. **Spec zuerst** — vor Änderungen an `.yaml` / ESPHome / Zigbee2MQTT: das
   passende Dokument in `/docs` lesen oder anlegen/aktualisieren. YAML ohne
   Doc-Update gilt als Fehler (siehe [`README.md`](./README.md)).
2. **Implementierung erst auf Anfrage** — nicht ungefragt von Spec zu YAML
   übergehen (außer der Nutzer beauftragt es im selben Schritt).
3. **Scope nennen** — am Ende: geänderte Dateien, neue Entities/Automationen,
   was der Nutzer in HA testen soll.
4. Roadmap-Punkte aus `README.md` nur abarbeiten, wenn der Nutzer sie
   anspricht oder die Spec sie referenziert.

**Quellen-Hierarchie bei Konflikten:** Feature-Spec (`docs/<thema>.md`) →
[`docs/konfigurations-strategie.md`](./docs/konfigurations-strategie.md)
(YAML vs. UI) → [`docs/standards.md`](./docs/standards.md) (Naming/UI) →
Inventar-Docs (`docs/hardware.md`, `docs/lights.md`, …) → bestehende YAML.
Bei Widerspruch **nicht raten** — Nutzer fragen oder Spec anpassen.

## HA-Neustart nach YAML-Änderungen (Safety-Workflow, verbindlich)

Nach Änderungen an `configuration.yaml` (Template, Powercalc, Gruppen),
`helpers.yaml`, `automations.yaml` oder `scripts.yaml`, die laufendes
Verhalten betreffen, **immer diese Reihenfolge**:

1. **`ha core check`** — Config validieren, bevor irgendetwas angewendet wird.
2. **Committen** — die geprüften Änderungen als eigenen Commit, das ist der
   Rollback-Punkt (kein Restart auf ungetesteten/unkommitteten Stand).
3. **`ha core restart` selbst ausführen**, auf HA-Start warten.
4. **Prüfen:** `ha core logs` (neue `ERROR`/`WARNING`, speziell zu den
   geänderten Automationen/Skripten/Entities — bekannte, unabhängige
   Fehler wie das HACS-Repo-ID-Problem oder ESP32-BLE-Reconnects ignorieren)
   sowie `ha resolution info --raw-json` (`issues`/`unhealthy` auf neue
   Einträge, nicht nur den Dauer-Hinweis "kein aktuelles Backup").
5. **Bei Fehlschlag:** Rollback per `git revert <commit>` (kein
   `reset --hard`, keine Historie überschreiben) + erneut `ha core restart`,
   dann wieder Logs/Issues prüfen. Kein Rollback ohne den Nutzer über den
   Fehler zu informieren.
6. **Ergebnis dem Nutzer mitteilen** — nicht nur "bitte neu laden/neustarten"
   schreiben, sondern was geprüft wurde und ob es sauber war.

Ausnahme: reine Doc- oder Dashboard-YAML-Änderungen, wenn ein
Browser-Reload reicht.

## Diagnose

Bei Fehlern/Warnungen zuerst selbst nachsehen, nicht um Copy-Paste bitten:
`ha core logs` (ggf. mit `grep` nach `ERROR`/`WARNING`), `ha supervisor
logs`, Zigbee2MQTT-Log unter `zigbee2mqtt/log/`. `.storage` nur **lesen**
für Diagnose/Migration.

## `.storage`, Secrets & Scope — nicht ohne Zustimmung

- `.storage/`, `.cloud/`, Token-Caches, Inhalte von `secrets.yaml` — **kein
  Edit ohne vorherige Rückfrage + ausdrückliche Zustimmung**. Vorher
  erklären: was, warum reicht UI/YAML nicht, warum ist `.storage` hier der
  beste Weg.
- Secrets nie hardcoden, nur `!secret`.
- Keine Commits/Pushes ohne Auftrag des Nutzers.
- Nur Dateien ändern, die zur aktuellen Spec gehören — keine Refactors
  "nebenbei".
- Änderung an `secrets.yaml`: am Ende explizit daran erinnern, die Datei
  erneut manuell nach Google Drive zu kopieren (Offsite-Kopie, nicht Git).

## YAML-Implementierung

| Datei | Inhalt |
|-------|--------|
| `configuration.yaml` | Core, Templates, Includes, Integrationen |
| `automations.yaml` | Automationen (modular nach Bereich) |
| `scripts.yaml` / `scenes.yaml` | Skripte und Szenen |
| `esphome/` | ESP-Geräte |
| `zigbee2mqtt/configuration.yaml` | Zigbee friendly_name ↔ Hardware |

`custom_components/` ist gitignored — nur ändern, wenn der Nutzer es
verlangt. Naming, Zigbee-Device-Triggers, Qualitätsstandards: siehe
[`docs/standards.md`](./docs/standards.md) und
[`docs/lights.md`](./docs/lights.md).

## Neue Feature-Spec (`docs/<feature>.md`)

Pflichtinhalt: Ziel, Entities (bestehend/neu), Verhalten (Trigger/
Bedingungen/Aktionen), Randfälle (manuell, away, unavailable, Nacht), UI
optional, Abnahme-Checkliste (`- [ ]`). Bei neuen Geräten Inventar-Docs
(`docs/lights.md`, `docs/hardware.md`) ergänzen.

## Persistenz / "Gedächtnis"

Alles, was projektbezogen dauerhaft gilt (Entscheidungen, Konventionen,
offene Punkte), gehört in **diese Datei, `docs/*.md` oder die Roadmap in
`README.md`** — nicht in Claudes globales Cross-Session-Memory außerhalb
des Repos. Ziel: das Repo ist vollständig self-contained, jede
Umgebung/jedes Tool sieht denselben Stand.

## Weitere Referenzen

- Abgleich-Checkliste: [`docs/abgleich-checkliste.md`](./docs/abgleich-checkliste.md)
- Energie-Statistik-Wartung (bei Recorder/Energie-Themen):
  [`docs/energie-statistik-praevention.md`](./docs/energie-statistik-praevention.md)
- HACS-Inventar: [`docs/hacs-inventar.md`](./docs/hacs-inventar.md) +
  `manifests/hacs-inventar.json`; nach HACS-Updates in der Session
  `bin/hacs-abgleich.sh --push` ausführen oder Nutzer erinnern.
