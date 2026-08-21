# Live-Audit — Modul-Referenz

Manifest: [`manifests/live-audit-modules.json`](../../../manifests/live-audit-modules.json)

| Modul | Fokus | T2 |
|-------|-------|-----|
| `core` | configuration.yaml, automations, helpers, Standards | — |
| `haushalt` | Waschmaschine, Trockner, Spülmaschine, Hebeanlage | — |
| `garten` | Bewässerung, Garten-Dashboard | — |
| `climate` | Lüftung, Klima-Templates | — |
| `energie` | Stabil-Sensoren, Kosten, Energie-Dashboard | `check-energie-statistik.sh` |
| `monitoring` | Haus-Warnungen, Aggregat | — |
| `zaehler` | AI-on-the-Edge Gas/Wasser | — |
| `dashboards` | Alle Lovelace-YAML unter `dashboards/` | — |
| `integrations` | Add-ons, HACS-Inventar | `export-hacs-inventar.sh` |
| `hardware` | hardware.md, Räume (Spec vs. Doku) | — |
| `lights` | Szenen, Licht-Inventar | — |
| `sprache` | Google Assistant expose | — |

## Modul `hardware`

Kein YAML-Entity-Scan — primär **Doku-Abgleich** gegen `.storage` (Areas/Devices, nur lesen). T1 extrahiert Entity-Refs aus Specs; fehlende Hardware-Erwähnungen manuell prüfen.

## Modul `integrations`

T2 exportiert HACS-Inventar — Diff gegen `docs/hacs-inventar.md` manuell oder in Follow-up-Session.

## Neues Modul hinzufügen

1. Eintrag in `manifests/live-audit-modules.json`
2. Optional Spiegel in `live-audit-modules.yaml`
3. Modul-ID in `manifests/live-audit-state.json` → `module_order` + `modules`
4. Zeile in dieser Referenz + [`docs/live-audit.md`](../../../docs/live-audit.md)
