import Foundation
import PromiseKit

public class BatterySensor: SensorProvider {
    public let request: SensorProviderRequest
    required public init(request: SensorProviderRequest) {
        self.request = request
    }

    // swiftlint:disable:next function_body_length
    public func sensors() -> Promise<[WebhookSensor]> {
        var level = Current.device.batteryLevel()
        if level == -100 { // simulator fix
            level = 100
        }

        var state = "Unknown"
        var icon = "mdi:battery"

        let batState = Current.device.batteryState()
        let isLowPowerMode = Current.device.isLowPowerMode()

        switch batState {
        case .charging(let level):
            state = "Charging"
            icon = Self.chargingIcon(level: level)
        case .unplugged(let level):
            state = "Not Charging"
            icon = Self.unpluggedIcon(level: level)
        case .full:
            state = "Full"
        }

        let levelSensor = with(WebhookSensor(
            name: "Battery Level",
            uniqueID: "battery_level",
            icon: .batteryIcon,
            deviceClass: .battery,
            state: level
        )) {
            $0.Icon = icon
            $0.Attributes = [
                "Battery State": state,
                "Low Power Mode": isLowPowerMode
            ]
            $0.UnitOfMeasurement = "%"
        }

        let stateSensor = with(WebhookSensor(
            name: "Battery State",
            uniqueID: "battery_state",
            icon: .batteryIcon,
            deviceClass: .battery,
            state: state
        )) {
            $0.Icon = icon
            $0.Attributes = [
                "Battery Level": level,
                "Low Power Mode": isLowPowerMode
            ]
        }

        return .value([levelSensor, stateSensor])
    }

    static func chargingIcon(level: Int) -> String {
        switch level {
        case 100...: return "mdi:battery-charging-100"
        case 90...:  return "mdi:battery-charging-80"
        case 80...:  return "mdi:battery-charging-80"
        case 70...:  return "mdi:battery-charging-60"
        case 60...:  return "mdi:battery-charging-60"
        case 50...:  return "mdi:battery-charging-40"
        case 40...:  return "mdi:battery-charging-40"
        case 30...:  return "mdi:battery-charging-20"
        case 20...:  return "mdi:battery-charging-20"
        case 10...:  return "mdi:battery-outline"
        default:     return "mdi:battery-outline"
        }
    }

    static func unpluggedIcon(level: Int) -> String {
        switch level {
        case 100...: return "mdi:battery"
        case 90...:  return "mdi:battery-90"
        case 80...:  return "mdi:battery-80"
        case 70...:  return "mdi:battery-70"
        case 60...:  return "mdi:battery-60"
        case 50...:  return "mdi:battery-50"
        case 40...:  return "mdi:battery-40"
        case 30...:  return "mdi:battery-30"
        case 20...:  return "mdi:battery-20"
        case 10...:  return "mdi:battery-10"
        default:     return "mdi:battery-outline"
        }
    }
}
