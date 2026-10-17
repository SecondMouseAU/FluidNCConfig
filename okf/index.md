---
type: repo
title: FluidNCConfig
resource: https://github.com/SecondMouseAU/FluidNCConfig
tags: [fluidnc, cnc, config, yaml, swift]
description: Dependency-free reader for FluidNC config.yaml files, into a typed model with no defaults.
timestamp: 2026-10-18
---

# FluidNCConfig

A small, dependency-free Swift reader for the `config.yaml` that FluidNC (the CNC controller
firmware) stores on a machine. It returns the facts a CAM program needs: axes with travel, rates and
homing, the spindle kind, and which peripherals are assigned. MIT-licensed.

## Role in the ecosystem

- **Cluster:** cam
- **Depends on:** nothing (leaf)
- **Feeds products:** CAM and machine-setup programs that need a machine's limits. This package
  knows nothing about its consumers.

## Components

See [`components/`](components/index.md) for the public surface.

## References

See [`references/`](references/index.md) for the YAML subset and the FluidNC keys read.

## Policies

- [Query `context` first for OCCT / OCCTSwift docs](policies/context-first.md)
- [Documentation updates are mandatory](policies/docs-current.md)
- [No em-dashes, banned words in prose](policies/writing-style.md)
- [Search before building](policies/search-before-building.md)
- [Code structure](policies/code-structure.md)
- [Issue labels and project-board tracking](policies/issue-tracking.md)
- [Code style](policies/code-style.md)
