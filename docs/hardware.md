## AI-on-the-Edge (Zähler)

Zwei ESP32-CAM-Geräte mit [AI-on-the-Edge](https://github.com/jomjol/AI-on-the-edge-device) lesen Gas- und Wasserzähler per Kamera aus.

| Gerät | MQTT-ID | Web-UI (LAN) | HA-Haupt-Entity | Stand Abgleich 2026-05-27 |
|-------|---------|--------------|-------------------|---------------------------|
| Gaszähler | `gasmeter` | http://192.168.188.122/ | `sensor.gasmeter_value` | ✅ aktiv (~9970,9 m³) |
| Wasserzähler | `watermeter` | http://192.168.188.121/ | `sensor.watermeter_value` | ✅ aktiv (~148,7 m³) |

Details: [`ai-on-the-edge.md`](./ai-on-the-edge.md)

## Dimmer

Der Markt für Licht Dimmer mit Zigbee Basis ist sehr kompliziert. Die meisten Hardware Komponenten erfordern, dass der Dimmer zwischen die Lampe geschaltet wird (um Strom zu erhalten). Dies ist jedoch nicht das gewünschte Verhalten. 

Ich teste nun "SLC SmartOne ZigBee 4in1 Wandschalter Wanddimmer" von Lampenwelt

## Friends of Hue

Die Schalter sind leider noch nicht gut genug, manchmal muss man mehrfach drücken, gefällt mir nicht. 