# Changelog

Versions track the GHCR image tag (`ghcr.io/super-quant-2026/strategy-bot:vX.Y.Z`).
The dashboard's sidebar fetches this file at startup and shows a red dot when
the topmost version below differs from the running image's `BOT_VERSION`.

Format follows [Keep a Changelog](https://keepachangelog.com/) loosely.

## v0.1.1 — 2026-05-10

### Added
- 一键热更新:侧栏版本号 badge 显示当前镜像版本,有新版自动红点;点击弹窗显示 CHANGELOG + 一键升级按钮,后端通过 Watchtower sidecar 拉新镜像 + 重建容器,UI 自动轮询 /health,升级完成后提示刷新。
- `BOT_VERSION` 环境变量,build 时由 GitHub Actions 注入 image tag,`/health` 端点返回。
- `WATCHTOWER_TOKEN` 安装时自动生成的 32 字符随机 token,docker network 内 bot 跟 watchtower 共享。

### Changed
- `docker-compose.encrypted.yml` 多了一个 `watchtower` sidecar(单独 mount `docker.sock`,bot 不再需要权限提升)。
- `.env.example` 新增 `WATCHTOWER_TOKEN` 和 `IMAGE_TAG` 两个字段。

## v0.1.0-beta — 2026-05-10

### Added
- Initial public beta.
- Cython 加密的核心策略模块(`engine` / `api` / `spot_reconcile` / `funding_cron`)。
- 资费 / 价差套利引擎,支持 binance / okx / bybit / bitget / gate / aster / hyperliquid 七家交易所。
- 一键安装:`sudo bash <(curl -sSL .../install.sh)`,Ubuntu/Debian + amd64。
- 交易所连接测试,显示账户类型 / 持仓模式 / USDT 余额。
- Pair 配置:`SF` / `FS` / `FF` 三种类型,可设置开/平仓价差阈值、止损、最大仓位、单笔金额。
- 全局风控:MMR / 可用保证金 监控。
- 飞书 / 电报 通知。
