# Upstream-PR: Gardena Bluetooth — Produkttyp über Proxies

**Status:** Backlog — Patch und Anleitung liegen bereit; PR bei `home-assistant/core` noch **nicht** eingereicht (Custom Integration bleibt bis dahin aktiv).

Patch für [home-assistant/core](https://github.com/home-assistant/core), abgeleitet aus dem lokalen Workaround `custom_components/gardena_bluetooth/`.

## Problem

Gardena BT-Geräte (1285-Ventil u. a.) senden oft:

- **Advertising:** Service-UUID `98bd0001-…`
- **Scan Response:** Herstellerdaten `0x0426` (1062) inkl. Produkttyp

ESPHome-Bluetooth-Proxies und passive Scanner leiten nicht immer die Scan Response zuverlässig weiter. Die Core-Integration matcht bisher primär auf `manufacturer_id` → Pairing/Setup scheitert mit *Unable to find product type*, obwohl das Gerät erreichbar ist.

## Lösung (Patch)

1. **`async_get_product`:** Active Scan zuerst über `ScanService`-UUID, Herstellerdaten über mehrere Pakete akkumulieren; Fallback auf `manufacturer_id`.
2. **`async_get_products`:** Matcher auf `service_uuid` statt nur `manufacturer_id` (weiterhin akkumulieren).
3. **`async_probe_product_type` / `async_resolve_product_type`:** Kurzer BLE-Connect und Charakteristik-Lesen, wenn Werbung unvollständig bleibt.
4. **`config_flow`:** Discovery nutzt `async_resolve_product_type`; Client wird mit bekanntem `product_type` verbunden.

## Dateien

| Datei | Änderung |
|-------|----------|
| `homeassistant/components/gardena_bluetooth/__init__.py` | Scan + Probe |
| `homeassistant/components/gardena_bluetooth/config_flow.py` | Resolve in Discovery |
| `tests/components/gardena_bluetooth/test_init.py` | Migration per Probe |
| `tests/components/gardena_bluetooth/test_config_flow.py` | BT-Discovery ohne Mfg-Daten |

Patch-Datei: [`../upstream-patches/home-assistant-core/`](../upstream-patches/home-assistant-core/)

## PR bei GitHub erstellen

### 1. Fork anlegen

Auf GitHub: **Fork** von `home-assistant/core` → z. B. `stefansiegl/core` (einmalig).

### 2. Branch pushen

```bash
cd /tmp/ha-core-pr   # oder frischer Clone
git remote add fork git@github.com:stefansiegl/core.git   # GitHub-User anpassen
git push -u fork gardena-bluetooth-proxy-product-type
```

Alternativ Patch anwenden:

```bash
git clone --depth 1 --branch dev https://github.com/home-assistant/core.git ha-core
cd ha-core
git checkout -b gardena-bluetooth-proxy-product-type
git am /pfad/zum/config/upstream-patches/home-assistant-core/*.patch
git push -u fork gardena-bluetooth-proxy-product-type
```

### 3. Pull Request

**Base:** `home-assistant/core` → `dev`  
**Title:** `Fix Gardena Bluetooth product type discovery via proxies`

**Body (Vorschlag):**

```markdown
## Proposed change

Gardena Bluetooth devices often advertise the scan service UUID in the main
advertisement while manufacturer data (product type) arrives in scan responses.
ESPHome Bluetooth proxies and passive scanners may only forward partial data,
which leads to "Unable to find product type" during pairing and migration.

This PR:
- Matches active scans on the Gardena scan service UUID and accumulates
  manufacturer data across packets
- Falls back to manufacturer-id matching when needed
- Resolves the product type via a short BLE connection probe when advertisements
  stay incomplete

## Type of change

- [ ] Dependency upgrade
- [ ] Bugfix (non-breaking change which fixes an issue)
- [x] New feature (non-breaking change which adds functionality)
- [ ] Breaking change (fix/feature causing existing functionality to break)
- [ ] Code quality improvements to existing code or addition of tests

## Additional information

- Tested locally with Gardena Irrigation Valve 1285-20 over ESPHome Bluetooth
  proxy (manufacturer data missing in forwarded advertisement, product type
  resolved via connection probe).
- Related to split advertising / scan response behaviour common on BLE proxies.

## Checklist

- [x] The code change is tested and works locally.
- [x] Local tests pass. **Your PR cannot be merged unless tests pass**
- [ ] There is no commented out code in this PR.
- [ ] I have followed the [development checklist][dev-checklist]
- [ ] I have followed the [perfect PR][perfect-pr] guidelines.
- [ ] Tests have been added to verify my fix/feature works.
- [ ] All user-facing or tested entities have meaningful unique IDs.

[dev-checklist]: https://developers.home-assistant.io/docs/development_checklist/
[perfect-pr]: https://developers.home-assistant.io/docs/submitting_pull_requests/
```

### 4. Tests (lokal / CI)

```bash
pytest tests/components/gardena_bluetooth/
```

## Nach Merge in Core

1. Custom Integration `custom_components/gardena_bluetooth/` aus diesem Repo **entfernen**
2. Integration in HA neu laden (Core)
3. Debug-Logger in `configuration.yaml` für Gardena wieder entfernen
4. Abschnitt in [`garten-bewaesserung.md`](garten-bewaesserung.md) aktualisieren

## Maintainer

Integration-Owner laut Manifest: `@elupus`
