# NovaTasks

English | [简体中文](README_zh.md)

A HarmonyOS task-management prototype with agent workflows and distributed-device coordination.

Archived project retained for reference.

## Overview

The source separates task lists, task details and settings from repositories, network services, agent execution and distributed-device managers. Remote workflow behavior depends on the service configuration and available devices.

## Technology and Dependencies

ArkTS, ArkUI, OHPM and Hvigor. The committed template specifies SDK/model version `26.0.0`; use a toolchain that supports it. Tests use Hypium 1.0.25 and Hamock 1.0.0; the entry package has no declared third-party runtime dependency.

## Repository Structure

- `entry/src/main/ets/` — ArkTS application code
- `entry/src/main/resources/` — module resources and routes
- `AppScope/` — application metadata and resources
- `build-profile.example.json5` — portable build configuration template
- `oh-package.json5` — package and test dependencies
- `hvigor/` — build configuration
- `entry/src/main/ets/manager/` — task storage, agent and device managers
- `entry/src/main/ets/service/` — network service
- `entry/src/main/ets/viewmodel/` — task view models

## Quick Start

1. Install DevEco Studio and a HarmonyOS SDK compatible with `build-profile.example.json5`.
2. Copy `build-profile.example.json5` to `build-profile.json5` and configure the local SDK and signing in DevEco Studio.
3. Open the repository root, restore dependencies with OHPM through the IDE, and select the `entry` module.
4. Select a compatible device or emulator and run the application. Keep signing material and machine-specific paths local.

Review `entry/src/main/ets/common/` and `service/` before using remote workflows, then configure the required backend locally. The repository does not include a standalone backend deployment.
