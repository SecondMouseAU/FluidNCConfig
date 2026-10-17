---
type: reference
title: References index
resource: https://github.com/SecondMouseAU/FluidNCConfig
tags: [index]
description: Background the reader depends on.
timestamp: 2026-10-18
---

# References

## The YAML subset

FluidNC configuration files use nested block mappings and scalar values. The reader supports exactly
that: `key: value`, `key:` followed by an indented block, `#` comments (not inside quotes), quoted
scalars, and `\n` or `\r\n` line endings. It rejects tabs in indentation, inconsistent
indentation, a duplicate key, and a line that is not `key: value`. Sequences (`- item`) and flow
collections (`[a, b]`, `{a: 1}`) do not occur in FluidNC configuration; sequence items are skipped
and flow values are kept as raw text, so they never fail a parse.

A colon is a separator only at the end of a line or before a space, so pin values such as
`gpio.34:low` and `gpio.12:low:pu` stay whole.

## FluidNC keys read

Keys match case-insensitively, as FluidNC matches them.

| Section | Keys |
|---|---|
| top | `name`, `board` |
| `axes.<x..c>` | `steps_per_mm`, `max_rate_mm_per_min`, `acceleration_mm_per_sec2`, `max_travel_mm`, `soft_limits`, `motor0`/`motor1` (presence) |
| `axes.<n>.homing` | `cycle`, `positive_direction`, `mpos_mm`, `seek_mm_per_min`, `feed_mm_per_min` |
| spindle block | first of `relay`, `PWM`, `Laser`, `DAC`, `BESC`, `10V`, `Huanyang`, `H2A`, `YL620`, `NowForever`; reads `spinup_ms`, `spindown_ms`, `speed_map` |
| `coolant` | `flood_pin`, `mist_pin` (assigned unless `NO_PIN`) |
| `probe` | `pin` |
| `atc` | presence of the block |
| `start` | `must_home` |

`max_travel_mm` is the span between limit switches. It is not the usable working envelope, which
depends on tool stick-out, fixturing and spoilboard.
