---
type: component
title: Components index
resource: https://github.com/SecondMouseAU/FluidNCConfig
tags: [index]
description: Public modules and API surfaces exposed by FluidNCConfig.
timestamp: 2026-10-18
---

# Components

- **`FluidNCConfig`** (library) — `FluidNCConfig(parsing:)` reads the text of a `config.yaml` into a
  `Sendable` value: `name`, `board`, `axes` (`AxisConfig` with `stepsPerMM`, `maxRate`,
  `acceleration`, `maxTravel`, `softLimits`, `homing`, `hasMotor`), `spindle` (`type`,
  `isVariableSpeed`, spin-up and spin-down seconds, `maxRPM`), coolant, probe and tool-changer
  presence, and `mustHome`. Every value is optional; nothing is defaulted. Invalid YAML throws a
  `FluidNCConfigError` with a line number.
