# NovaTasks

[English](README.md) | 简体中文

包含代理流程与分布式设备协调的 HarmonyOS 任务管理原型。

归档项目，保留用于参考。

## 项目概述

源码将任务列表、详情及设置页面与仓储、网络服务、代理执行和分布式设备管理分离。远程流程依赖服务配置和可用设备。

## 技术栈与依赖

ArkTS、ArkUI、OHPM、Hvigor。已提交模板指定 SDK/模型版本 `26.0.0`，需使用兼容工具链。测试使用 Hypium 1.0.25 和 Hamock 1.0.0；entry 未声明第三方运行时依赖。

## 文件结构

- `entry/src/main/ets/` — ArkTS 应用代码
- `entry/src/main/resources/` — 模块资源与路由
- `AppScope/` — 应用配置与资源
- `build-profile.example.json5` — 可移植构建配置模板
- `oh-package.json5` — 包与测试依赖
- `hvigor/` — 构建配置
- `entry/src/main/ets/manager/` — 任务存储、代理及设备管理
- `entry/src/main/ets/service/` — 网络服务
- `entry/src/main/ets/viewmodel/` — 任务视图模型

## 快速上手

1. 安装 DevEco Studio 及与 `build-profile.example.json5` 匹配的 HarmonyOS SDK。
2. 将 `build-profile.example.json5` 复制为 `build-profile.json5`，在 IDE 中配置本地 SDK 与签名。
3. 打开仓库根目录，通过 IDE 的 OHPM 恢复依赖并选择 `entry` 模块。
4. 选择兼容设备或模拟器后运行；签名材料与机器路径仅在本地配置。

使用远程流程前，检查 `entry/src/main/ets/common/` 与 `service/`，在本地配置所需后端。仓库不包含独立后端部署。
