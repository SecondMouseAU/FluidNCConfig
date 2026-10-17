import Foundation

extension FluidNCConfig {
    /// Spindle block names FluidNC defines, lower-cased.
    private static let spindleTypes = [
        "relay", "pwm", "laser", "dac", "besc", "10v", "huanyang", "h2a", "yl620", "nowforever",
    ]

    /// Read a configuration from the text of a `config.yaml`.
    ///
    /// - Throws: ``FluidNCConfigError`` for text that is not valid block YAML: a tab in the
    ///   indentation, inconsistent indentation, a line that is not `key: value`, or a duplicate key.
    public init(parsing text: String) throws {
        let root = try YAMLSubset.parse(text)

        var axes: [Axis: AxisConfig] = [:]
        if let axesNode = root["axes"] {
            for axis in Axis.allCases {
                if let node = axesNode[axis.rawValue], !node.keys.isEmpty {
                    axes[axis] = Self.axis(node)
                }
            }
        }

        self.init(
            name: root["name"]?.scalar,
            board: root["board"]?.scalar,
            axes: axes,
            spindle: Self.spindle(root),
            hasFloodCoolant: Self.pin(root["coolant"]?["flood_pin"]),
            hasMistCoolant: Self.pin(root["coolant"]?["mist_pin"]),
            hasProbe: Self.pin(root["probe"]?["pin"]),
            hasToolChanger: root.has("atc"),
            mustHome: Self.bool(root["start"]?["must_home"])
        )
    }

    private static func axis(_ node: YAMLNode) -> AxisConfig {
        let homing = node["homing"].map {
            Homing(
                cycle: number($0["cycle"]).map { Int($0) },
                positiveDirection: bool($0["positive_direction"]),
                machinePosition: number($0["mpos_mm"]),
                seekRate: number($0["seek_mm_per_min"]),
                feedRate: number($0["feed_mm_per_min"])
            )
        }
        let hasMotor = node.keys.contains { $0.hasPrefix("motor") }
        return AxisConfig(
            stepsPerMM: number(node["steps_per_mm"]),
            maxRate: number(node["max_rate_mm_per_min"]),
            acceleration: number(node["acceleration_mm_per_sec2"]),
            maxTravel: number(node["max_travel_mm"]),
            softLimits: bool(node["soft_limits"]),
            homing: homing,
            hasMotor: hasMotor
        )
    }

    private static func spindle(_ root: YAMLNode) -> Spindle? {
        guard let key = root.keys.first(where: { spindleTypes.contains($0) }),
            let node = root[key]
        else { return nil }
        return Spindle(
            type: key,
            isVariableSpeed: key != "relay",
            spinUpSeconds: number(node["spinup_ms"]).map { $0 / 1000 },
            spinDownSeconds: number(node["spindown_ms"]).map { $0 / 1000 },
            maxRPM: maxRPM(node["speed_map"]?.scalar)
        )
    }

    /// RPM paired with the highest percentage in a map such as `0=0.0% 10000=100.0%`.
    static func maxRPM(_ map: String?) -> Double? {
        guard let map else { return nil }
        var best: (percent: Double, rpm: Double)?
        for pair in map.split(separator: " ") {
            let parts = pair.split(separator: "=")
            guard parts.count == 2, let rpm = Double(parts[0]),
                let percent = Double(parts[1].replacingOccurrences(of: "%", with: ""))
            else { continue }
            if best == nil || percent > best!.percent { best = (percent, rpm) }
        }
        return best?.rpm
    }

    private static func number(_ node: YAMLNode?) -> Double? {
        node?.scalar.flatMap { Double($0) }
    }

    private static func bool(_ node: YAMLNode?) -> Bool? {
        switch node?.scalar?.lowercased() {
        case "true": return true
        case "false": return false
        default: return nil
        }
    }

    /// A pin is assigned when its value is present and is not `NO_PIN`.
    private static func pin(_ node: YAMLNode?) -> Bool {
        guard let value = node?.scalar, !value.isEmpty else { return false }
        return value.uppercased() != "NO_PIN"
    }
}
