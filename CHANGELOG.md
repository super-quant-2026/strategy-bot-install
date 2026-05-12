# Changelog

Versions track the GHCR image tag (`ghcr.io/super-quant-2026/strategy-bot:vX.Y.Z`).
The dashboard's sidebar fetches this file at startup and shows a red dot when
the topmost version below differs from the running image's `BOT_VERSION`.

Format follows [Keep a Changelog](https://keepachangelog.com/) loosely.

## v0.1.3 — 2026-05-12

### Fixed
- **关键**:`docker-compose.encrypted.yml` 的 bot service 增加 `com.centurylinklabs.watchtower.enable=true` label。v0.1.1/v0.1.2 漏了这个 label,导致 watchtower 在 `LABEL_ENABLE=true` 模式下扫不到 bot 容器(`Scanned=0 Updated=0`),升级按钮**完全无效**。升到 v0.1.3 后需要 `docker compose -f docker-compose.encrypted.yml up -d` 重建 bot 容器让新 label 生效。
- `/control/update` 改为 fire-and-forget:之前等待 watchtower 同步完成 + 5s 超时,实际 pull 要 20-30s,前端总是误报"升级失败"。现在端点立即返回 200,前端通过 `/health` 轮询版本号变化判断升级成功。

### Changed
- `install.sh` / `.env.example` / `docker-compose.encrypted.yml` 默认 `IMAGE_TAG=latest` 而不是 `v0.1.0-beta`。Watchtower 监听同一 image:tag 的 digest 变化才能升级,锁版本号等于关掉升级按钮。想锁版本的用户:`IMAGE_TAG=v0.1.3 bash <(curl -sSL .../install.sh)`。

## v0.1.2 — 2026-05-12

### Fixed
- 升级按钮在 dev / 无 watchtower 环境点击时返回 HTTP 500 — 后端 `/control/update`
  端点改用 `aiohttp`(项目已有依赖,httpx 没装),失败时返回带 detail 的 503。
- 升级模态框失败提示从展示原始 JSON body 改为提取 `detail` 字段,可读性提升。

### Changed
- 升级链路验证:`IMAGE_TAG=latest` 时 watchtower 可正确拉到新版本并重建容器。

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
