# Changelog

Versions track the GHCR image tag (`ghcr.io/super-quant-2026/strategy-bot:vX.Y.Z`).
The dashboard's sidebar fetches this file at startup and shows a red dot when
the topmost version below differs from the running image's `BOT_VERSION`.

Format follows [Keep a Changelog](https://keepachangelog.com/) loosely.

## v0.2.7 — 2026-06-14

### Added
- 🔎 **添加交易对全面优化**：币种改为「可搜索下拉」，只列出两个交易所都能交易的币种（不存在的币种无法添加）；未配置 API Key 的交易所自动置灰并说明原因；币种与交易所在创建后锁定，避免误改导致原交易所仓位失管。
- 🗒️ **持仓详情「执行状态」改版**：面向普通用户，最新报错用大白话 + 处理建议突出展示，历史折叠，原始技术日志收进「技术详情」。
- 🔑 交易所页新增 API Key 权限配置说明（仅开合约+现货交易、绑服务器 IP 白名单、禁提币）。
- 📈 盈亏曲线：鼠标悬停查看任意时点盈亏，横轴日期不再截断。

### Fixed
- 🔢 连续下单失败次数现在会真实累计（并跨重启保留），不再永远显示 0。
- 💱 Hyperliquid 合约以 USDC 计价（不再误写 USDT），MMR / 可用保证金读取真实账户数据；Gate 可用保证金、Aster 保证金显示修复。
- 🧹 清仓后仓位自动刷新，无需手动刷新页面；编辑交易对弹窗点击空白处不再误关闭；左侧导航栏在长页面固定；持仓详情手续费按本地成交记录对齐。

## v0.2.6 — 2026-06-11

### Fixed
- 🐛 **平仓遇「Price not increased by tick size」自动恢复**：交易所盘中调整价格精度（如 binance 把某币 tick 从 0.0001 调到 0.001）后，旧缓存的交易规格会让平仓单被拒并中止。现检测到此类错误自动重载交易规格、按新精度重算价格并重试一次，无需手动重启服务。

### Added
- 🧹 **孤儿持仓自动清理**：在交易所手动平掉（或经其它 bot 实例平掉）的仓位，持仓记录不再一直显示「未平」。系统启动后及每 30 分钟核对一次交易所实仓，两腿均确认为零才自动闭合记录（不下单、不造盈亏数据，已删除卡片的遗留记录同样覆盖）。

## v0.2.5 — 2026-06-04

### Fixed
- 🐛 **Gate 小数张下单修复**：Gate 上「合约面值 ≠ 1」的币种（如 LAB 每张=100 币、ETH 每张=0.01 币）此前被强制按整数张下单、最小下单金额被抬高（LAB 一度需 ~$1629/腿）。根因是 `下单量 / 合约面值` 的浮点除法误差（如 0.009/0.01=0.8999…）被向下截断少算一张，之前误判成「gate 不支持小数张」。现按 gate 的 `enable_decimal` 字段判定、恢复小数张下单，并在换算处消除浮点误差。binance / okx 等不受影响。
- 🐛 **Gate 持仓数量显示修复**：Gate 持仓「数量」此前用 `value / 开仓价` 反算而偏大（标记价 > 开仓价时，如 10 LAB 显示成 10.17，与对腿不齐）。改用 `value / 标记价`（gate 的 value 本就是标记价计的市值），现与交易所一致、两腿对齐。

### Added
- 🔄 **重启服务按钮**：侧边栏「退出登录」上方新增「重启服务」。遇到行情卡顿 / 状态异常时可一键完整重启（约 15-30 秒自动恢复），无需 SSH；已有持仓不受影响。

## v0.2.4 — 2026-06-03

### Fixed
- 🐛 **Gate 小面值合约成交修复**：Gate 上「合约面值 < 1」的币种（如 ETH 永续，1 张 = 0.01 币）开仓时成交数量被少算 —— 按小数张下单后 Gate 把 `order.size`/`left`/持仓 `size` 全报 0（只有 `value`/`fee` 暴露真实成交），导致误判「下单已暂停」或只开出单腿、残留单边持仓。现改为按整数张下单（自动下单量对齐到整张）。其它交易所、以及合约面值 = 1（如 SOL）和 > 1（如 ESPORTS）的币种不受影响。这是 v0.2.3（cs>1）修复的镜像补全。

## v0.2.3 — 2026-06-03

### Fixed
- 🐛 **Gate 大面值合约成交修复**：Gate 上「合约面值 > 1」的币种（如 ESPORTS，1 张 = 100 币）开仓时，成交数量在某些情况下被少算（Gate 的小数张被截断 + `size=0` 成交回报约定被 ccxt 读成 0），导致误判「下单已暂停」或只开出单腿、留下单边敞口。现改为按整数张下单 + 用订单自身的 `size`/`left` 校正真实成交量。binance / okx 等其它交易所、以及合约面值 = 1 的币种不受影响。

## v0.2.2 — 2026-06-03

### Added
- 🤖 **下单金额全自动**：去掉「单笔最小金额 / 最大金额」设置，系统按每个交易所的真实规则（最小下单量 / 最小名义额 / 价格步进 / 合约面值）自动选取一个合适的单笔下单量（中等偏小、向上取整到可行档）。**不用再手动猜金额**，也不再因金额不符各所最小档而频繁报「下单已暂停 / 只开单腿」。你只需设「最大仓位」控制总规模。

### Fixed
- ⚡ **行情轮询限流**：修复持仓详情面板高频轮询打爆交易所 REST 限流、导致服务器 IP 被交易所临时封禁（binance 418）的问题；详情接口加 5s 缓存、前端实时刷新放宽到 8s。
- 🐛 **Gate 小数合约成交识别**：Gate 永续 `enable_decimal` 市场的小数张订单（如 0.2 张）成交后回报 `size=0`，旧逻辑用手续费反推会得到错误成交量、把已成交的腿误判为 underfill 而暂停。改用订单自身的 `finish_as / left / fill_price` 恢复真实成交量。

## v0.2.1 — 2026-06-03

### Fixed
- **关键**：修复 **OKX / Gate** 等 `contractSize ≠ 1` 的交易所开仓时，成交数量被当成「合约张数」而非「币本位数量」来校验，导致误判「下单已暂停」、只开出单腿、或平仓失败的问题。binance / bitget / aster（`contractSize = 1`）不受影响 —— 升级后这些交易所的开 / 平仓恢复正常。

### Added
- 📈 系统升级弹窗新增**进度条**（按预估时间平滑推进），升级过程不再是无反馈的「请稍候」。

## v0.2.0 — 2026-06-01

### Added
- 🏆 **利润上报**：平仓后自动把战绩上报到 SuperQuant 排行榜，经交易所逐笔核实后才计分。在「设置 → 利润上报」填入 Bot 令牌即可启用，并提供一键「上报测试」检查与排行榜后端的连通性和鉴权。
- 📊 **更新日志页**：侧栏新增「更新日志」，以时间线展示每个版本的更新内容与时间。
- 🔐 **账号密码登录**：新增独立的管理密码登录。

### Changed
- ⚡ **精简为纯实盘模式**：移除调试 / 模拟下单（paper-trading）与旧的全局风控模块，更轻、更快、更专注于真实套利。

### ⚠️ 升级须知（Breaking）
- 本版起登录改为**账号密码**，初始密码为 `superquant123`。升级后请用它登录，并**立即在「设置 → 修改密码」中改掉**。忘记密码可在服务器上 `docker exec -it <bot 容器> python -m app.cli.reset_password` 重置。

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
