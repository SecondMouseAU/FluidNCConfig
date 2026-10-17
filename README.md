# FluidNCConfig

[![Swift](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSecondMouseAU%2FFluidNCConfig%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/SecondMouseAU/FluidNCConfig)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FSecondMouseAU%2FFluidNCConfig%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/SecondMouseAU/FluidNCConfig)

A small, dependency-free Swift reader for the `config.yaml` of a [FluidNC](https://github.com/bdring/FluidNC)
CNC controller. It returns what a CAM or machine-setup program needs: axes with travel, rates and
homing, the spindle kind, and which peripherals are assigned. **MIT**-licensed.

```swift
import FluidNCConfig

let config = try FluidNCConfig(parsing: yamlText)

config.axes[.z]?.maxTravel                  // 60.0, or nil if the file does not say
config.axes[.z]?.homing?.positiveDirection  // true
config.spindle?.isVariableSpeed             // false for a relay spindle
config.spindle?.spinUpSeconds               // 1.0
config.hasProbe                             // true
```

## Design

- **Nothing is defaulted.** A value the file does not state is `nil`, not zero. A program that
  guesses a travel limit can cut outside the machine; the caller decides what an absent value means.
- **Tolerant of new firmware.** Unknown keys are ignored, and keys match case-insensitively as
  FluidNC matches them.
- **Strict about structure.** A tab in the indentation, inconsistent indentation, a duplicate key
  or a line that is not `key: value` throws `FluidNCConfigError` with the line number.
- **No dependencies.** It reads the block-YAML subset FluidNC uses, not general YAML.

`max_travel_mm` is the span between limit switches. It is not the usable working envelope, which
depends on tool stick-out, fixturing and spoilboard.

## Install

```swift
.package(url: "https://github.com/SecondMouseAU/FluidNCConfig.git", from: "0.1.0")
```

## What it reads

See [`okf/references/index.md`](okf/references/index.md) for the supported syntax and the keys read.

## Licence

MIT. See [`LICENSE`](LICENSE).
