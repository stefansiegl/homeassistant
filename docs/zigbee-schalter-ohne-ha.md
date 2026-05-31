# Schalter ohne Home Assistant

Wenn **Home Assistant down** ist, laufen **keine Automationen** aus dem Repo — Szenen, Neutralwerte, Drehregler-Logik und Raum-Toggles funktionieren dann nicht.

## Was trotzdem gehen kann

| Voraussetzung | Was funktioniert |
|---------------|------------------|
| **Zigbee2MQTT + Coordinator laufen** (Add-on/OS ok, nur HA Core aus) | Optional: **direkte Zigbee-Bindings** Schalter → Lampe(n) |
| **HA + Z2M beide down** | Kein Zigbee-Routing — **kein einfacher Fallback** |

Die komfortable Logik (Kathi-Szene, Drehregler mit HA-Toggle, Neutralwert) **braucht immer HA**.

## Einfachster Fallback: Zigbee-Bindings in Zigbee2MQTT

Gerät direkt an Lampe(n) **binden** — der Schalter steuert per Zigbee, ohne MQTT/HA.

### Vorgehen (UI)

1. Zigbee2MQTT Frontend → Gerät (z. B. Hue Rocker Schalter3)
2. Tab **Bind** / **Reporting**
3. Ziel: **Gruppe** oder einzelne Lampe (z. B. Ess-Deckenlampen)
4. Cluster typisch: **OnOff**, ggf. **LevelControl** (Dimmen)

### Grenzen

- **Keine Szenen**, kein „nur Decken an, Aus = alles“, kein Kathi/Hell
- **Drehregler TLG S57018:** Binding-Support prüfen — evtl. nur On/Off oder einfaches Dimmen, nicht eure HA-Logik
- **Ein Schalter ↔ eine Gruppe** — Konflikt, wenn HA parallel per MQTT dieselben Lampen steuert (meist ok, gelegentlich „Zickzack“)

### Empfehlung fürs Haus

| Priorität | Schalter | Binding-Ziel (Fallback) | HA-Logik behalten |
|-----------|----------|-------------------------|-------------------|
| Hoch | Küche-Tür, Schalter3/4 Ess/Wohn (Hue Rocker) | jeweilige **Hauptlicht-Gruppe** | ja — Bind nur Notfall |
| Mittel | Drehregler Ess/Wohn | Deckenlampen-Gruppe (falls Binding möglich) | ja |
| Niedrig | 8-fach, Hue Dimmer | schwer sinnvoll (Szenen) | nur HA |

Bindings **in Zigbee2MQTT UI** anlegen — nicht in Git, gerätespezifisch. Nach Pairing dokumentieren in [`lights.md`](lights.md), welcher Schalter gebunden ist.

## Alternative (nicht „einfach“)

- **Zweiter Coordinator / Hue Bridge** parallel — Aufwand hoch, hier nicht vorgesehen
- **Smarte Relais** statt Zigbee-Lampen — anderes System

## Kurzantwort

**Ja, teilweise:** Hue-Rocker per **Z2M-Binding** an Lampengruppe → Licht geht auch ohne HA, solange **Zigbee2MQTT läuft**. Volle Haus-Logik gibt es nur mit HA.
