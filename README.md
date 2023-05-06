# Home Assistant Configuration

Contains the configuration for my home automation project. A good number of the configurations are actually stored
in the database of homeassistant and are thus not shown here. 

## What might be interesting
- Waste Collection: [config](includes/waste_collection_schedule.yaml) and [sensors](includes/sensors/platformsensors-wastecollection.yaml)
- Vacuum automation ensuring cleaning after some time passed and ensures that it actually can (checks whether the door it open)
- Nifty use of door sensors (ensuring door is completely open, checking for mail, checking for garbage)
- manual override for testing purposes of warning sesnsors that are normally
  hidden.


## What is still open:
- Finish Kiosk Mode (create default dashboard layout, integrate important information, put tablet to the wall)
- Voice automation
- Call kids to lunch/dinner through Nest minis in their rooms
- Automated watering setup for the garden
- Integrate eufy security cam
- Integrate lawnmower robot (first my grass needs to grow though)
- Include flower sensors outside (they do not want to connect yet)

## Hardware
- FritzBox and 3 Fritz Repeater
- Philipps Hue lights:
- Philipps Hue bridge:
- Nuki door lock and bridge
- 4 Google Nest minis
- 3 ESPHomes providing BLE to the different floors
- 2 Vacuums (Xiaomi Mi Robot, RoboRock S7 Max)
- 1 Robot lawn mower
- 10 ish Xiaomi temperature sensors
- 8 flower sensors
- a couple of door sensors
- 5 shellies plugs and 1 Fritz power plug
- Solar