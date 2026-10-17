import Foundation

/// The machine facts a FluidNC `config.yaml` states.
///
/// Every value is optional because a configuration may omit it, and a missing value is not the
/// same as zero. The caller decides what an absent travel or rate means; nothing is defaulted
/// here. Keys the reader does not know are ignored, so newer firmware options do not break it.
public struct FluidNCConfig: Sendable, Equatable {
    /// One of FluidNC's six axes.
    public enum Axis: String, CaseIterable, Sendable {
        case x, y, z, a, b, c
    }

    /// Settings of a single axis.
    public struct AxisConfig: Sendable, Equatable {
        /// Steps per millimetre (`steps_per_mm`).
        public var stepsPerMM: Double?
        /// Maximum rate in mm/min (`max_rate_mm_per_min`).
        public var maxRate: Double?
        /// Acceleration in mm/s² (`acceleration_mm_per_sec2`).
        public var acceleration: Double?
        /// Travel in mm (`max_travel_mm`), the span between the limit switches.
        public var maxTravel: Double?
        /// Whether soft limits are enabled (`soft_limits`).
        public var softLimits: Bool?
        /// Homing settings, when the axis has a `homing:` block.
        public var homing: Homing?
        /// True when the axis has at least one motor.
        public var hasMotor: Bool
    }

    /// Homing settings of an axis.
    public struct Homing: Sendable, Equatable {
        /// Position in the homing sequence (`cycle`); 0 means the axis is not homed.
        public var cycle: Int?
        /// True when the axis homes toward its positive end (`positive_direction`).
        public var positiveDirection: Bool?
        /// Machine position assigned at the switch, in mm (`mpos_mm`).
        public var machinePosition: Double?
        /// Search speed in mm/min (`seek_mm_per_min`).
        public var seekRate: Double?
        /// Final approach speed in mm/min (`feed_mm_per_min`).
        public var feedRate: Double?
    }

    /// The spindle block, when the configuration has one.
    public struct Spindle: Sendable, Equatable {
        /// The block name, lower-cased, for example `relay`, `pwm` or `10v`.
        public var type: String
        /// False for a relay, which can only switch on and off.
        public var isVariableSpeed: Bool
        /// Seconds FluidNC waits after starting (`spinup_ms`).
        public var spinUpSeconds: Double?
        /// Seconds FluidNC waits after stopping (`spindown_ms`).
        public var spinDownSeconds: Double?
        /// Speed at full output in RPM, from `speed_map` when present.
        public var maxRPM: Double?
    }

    /// The `name:` line.
    public var name: String?
    /// The `board:` line.
    public var board: String?
    /// Axes present in the file.
    public var axes: [Axis: AxisConfig]
    /// The spindle block, or nil when there is none.
    public var spindle: Spindle?
    /// True when a flood coolant pin (M8) is assigned.
    public var hasFloodCoolant: Bool
    /// True when a mist coolant pin (M7) is assigned.
    public var hasMistCoolant: Bool
    /// True when a probe pin is assigned.
    public var hasProbe: Bool
    /// True when the configuration has an automatic tool changer block.
    public var hasToolChanger: Bool
    /// True when `start: must_home` is set.
    public var mustHome: Bool?
}
