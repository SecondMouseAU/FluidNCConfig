import XCTest

@testable import FluidNCConfig

final class FluidNCConfigTests: XCTestCase {
    /// A relay-spindle three-axis mill, in the shape of a typical bring-up file.
    private let relayMill = """
        name: Example mill (bring-up)
        board: Example board, FluidNC v4.1.1

        # Pin map comment
        spi:
          miso_pin: gpio.19

        kinematics:
          Cartesian:

        axes:
          homing_runs: 2
          # 800 steps/mm
          x:
            steps_per_mm: 800.0
            max_rate_mm_per_min: 2000.0
            acceleration_mm_per_sec2: 150.0
            max_travel_mm: 300.0
            soft_limits: true
            homing:
              cycle: 2
              positive_direction: false
              mpos_mm: 0.0
              seek_mm_per_min: 600.0
              feed_mm_per_min: 25.0
            motor0:
              limit_all_pin: gpio.36:low
              standard_stepper:
                step_pin: gpio.12:low
                direction_pin: gpio.14
          y:
            steps_per_mm: 800.0
            max_travel_mm: 295.0
            motor0:
              limit_all_pin: gpio.34:low
          z:
            steps_per_mm: 800.0
            max_rate_mm_per_min: 1500.0
            max_travel_mm: 60.0   # switch to switch
            homing:
              cycle: 1
              positive_direction: true
              mpos_mm: 0.0
            motor0:
              limit_all_pin: gpio.35:low

        relay:
          output_pin: gpio.17
          spinup_ms: 1000
          spindown_ms: 2000

        probe:
          pin: gpio.12:low:pu
          check_mode_start: true

        coolant:
          flood_pin: gpio.22
          mist_pin: NO_PIN

        start:
          must_home: true
        """

    func testReadsAxesAndHoming() throws {
        let config = try FluidNCConfig(parsing: relayMill)
        XCTAssertEqual(config.name, "Example mill (bring-up)")
        XCTAssertEqual(config.board, "Example board, FluidNC v4.1.1")
        XCTAssertEqual(Set(config.axes.keys), [.x, .y, .z])

        let x = try XCTUnwrap(config.axes[.x])
        XCTAssertEqual(x.stepsPerMM, 800)
        XCTAssertEqual(x.maxRate, 2000)
        XCTAssertEqual(x.acceleration, 150)
        XCTAssertEqual(x.maxTravel, 300)
        XCTAssertEqual(x.softLimits, true)
        XCTAssertTrue(x.hasMotor)
        XCTAssertEqual(x.homing?.cycle, 2)
        XCTAssertEqual(x.homing?.positiveDirection, false)
        XCTAssertEqual(x.homing?.seekRate, 600)
        XCTAssertEqual(x.homing?.feedRate, 25)

        let z = try XCTUnwrap(config.axes[.z])
        XCTAssertEqual(z.maxTravel, 60, "a trailing comment must not reach the value")
        XCTAssertEqual(z.homing?.positiveDirection, true)
        XCTAssertEqual(z.homing?.machinePosition, 0)
        XCTAssertNil(config.axes[.y]?.homing)
        XCTAssertNil(config.axes[.y]?.maxRate, "an absent value stays nil, never zero")
    }

    func testReadsRelaySpindleAndPeripherals() throws {
        let config = try FluidNCConfig(parsing: relayMill)
        let spindle = try XCTUnwrap(config.spindle)
        XCTAssertEqual(spindle.type, "relay")
        XCTAssertFalse(spindle.isVariableSpeed)
        XCTAssertEqual(spindle.spinUpSeconds, 1)
        XCTAssertEqual(spindle.spinDownSeconds, 2)
        XCTAssertNil(spindle.maxRPM)
        XCTAssertTrue(config.hasProbe)
        XCTAssertTrue(config.hasFloodCoolant)
        XCTAssertFalse(config.hasMistCoolant, "NO_PIN means not assigned")
        XCTAssertFalse(config.hasToolChanger)
        XCTAssertEqual(config.mustHome, true)
    }

    func testReadsVariableSpeedSpindle() throws {
        let config = try FluidNCConfig(
            parsing: """
                axes:
                  x:
                    max_travel_mm: 100
                10V:
                  output_pin: gpio.17
                  speed_map: 0=0.0% 10000=100.0%
                  spinup_ms: 500
                """)
        let spindle = try XCTUnwrap(config.spindle)
        XCTAssertEqual(spindle.type, "10v")
        XCTAssertTrue(spindle.isVariableSpeed)
        XCTAssertEqual(spindle.maxRPM, 10000)
        XCTAssertEqual(spindle.spinUpSeconds, 0.5)
    }

    func testCommentedOutAlternativeSpindleIsIgnored() throws {
        let config = try FluidNCConfig(
            parsing: """
                relay:
                  output_pin: gpio.17
                # 10V:
                #   speed_map: 0=0.0% 10000=100.0%
                """)
        XCTAssertEqual(config.spindle?.type, "relay")
    }

    func testKeysAreCaseInsensitive() throws {
        let config = try FluidNCConfig(
            parsing: """
                AXES:
                  X:
                    Max_Travel_MM: 250
                RELAY:
                  spinup_ms: 100
                """)
        XCTAssertEqual(config.axes[.x]?.maxTravel, 250)
        XCTAssertEqual(config.spindle?.type, "relay")
    }

    func testToolChangerBlockIsDetected() throws {
        let config = try FluidNCConfig(parsing: "atc:\n  dwell_ms: 100\n")
        XCTAssertTrue(config.hasToolChanger)
    }

    func testUnknownKeysSequencesAndFlowValuesAreIgnored() throws {
        let config = try FluidNCConfig(
            parsing: """
                future_option: whatever
                uart1:
                  txd_pin: gpio.1
                  modes: [8N1, 8E1]
                list:
                  - one
                  - two:
                      nested: 1
                axes:
                  z:
                    max_travel_mm: 70
                """)
        XCTAssertEqual(config.axes[.z]?.maxTravel, 70)
    }

    func testColonInsideValueIsNotASeparator() throws {
        let config = try FluidNCConfig(parsing: "probe:\n  pin: gpio.12:low:pu\n")
        XCTAssertTrue(config.hasProbe)
    }

    func testQuotesAndHashInsideQuotes() throws {
        let config = try FluidNCConfig(parsing: "name: \"My # mill\"  # real comment\n")
        XCTAssertEqual(config.name, "My # mill")
    }

    func testWindowsLineEndings() throws {
        let config = try FluidNCConfig(
            parsing: "axes:\r\n  x:\r\n    max_travel_mm: 300\r\n")
        XCTAssertEqual(config.axes[.x]?.maxTravel, 300)
    }

    func testEmptyInputGivesAnEmptyConfigNotAnError() throws {
        let config = try FluidNCConfig(parsing: "")
        XCTAssertTrue(config.axes.isEmpty)
        XCTAssertNil(config.spindle)
        XCTAssertNil(config.mustHome)
    }

    func testTabIndentationIsRejectedWithLineNumber() {
        XCTAssertThrowsError(try FluidNCConfig(parsing: "axes:\n\tx:\n")) { error in
            XCTAssertEqual(
                error as? FluidNCConfigError,
                FluidNCConfigError(line: 2, message: "tab in indentation"))
        }
    }

    func testDuplicateKeyIsRejected() {
        XCTAssertThrowsError(try FluidNCConfig(parsing: "name: a\nname: b\n")) { error in
            XCTAssertEqual((error as? FluidNCConfigError)?.line, 2)
        }
    }

    func testLineWithoutColonIsRejected() {
        XCTAssertThrowsError(try FluidNCConfig(parsing: "axes:\n  not a mapping\n")) { error in
            XCTAssertEqual((error as? FluidNCConfigError)?.line, 2)
        }
    }

    func testInconsistentIndentationIsRejected() {
        XCTAssertThrowsError(
            try FluidNCConfig(parsing: "axes:\n    x:\n  y:\n")
        ) { error in
            XCTAssertEqual((error as? FluidNCConfigError)?.line, 3)
        }
    }
}
