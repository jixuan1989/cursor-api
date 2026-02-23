# cursor-api 使用与配置详解

本文档基于 README、`.env.example` 及 [GitHub Issues](https://github.com/wisdgod/cursor-api/issues) 整理，便于快速上手与排错。

---

## 一、概念区分（易混淆）

| 名称 | 含义 | 用途 |
|------|------|------|
| **AUTH_TOKEN** | 你自己设的**管理员密码** | 调用管理接口（/tokens、/proxies、/config 等）和作为 Bearer 访问 Chat 时的“主密钥”，可任意字符串，**不是** Cursor 的 Cookie |
| **WorkosCursorSessionToken（Cookie 第三段）** | Cursor 网站登录后的 **Session Token** | 在 `/tokens` 页面或 `/tokens/add` 里**添加账号**时使用，用于拉取该账号的 checksum、client_key 等；也可作为 `/build-key` 的输入 |
| **/build-key 生成的 key** | 程序根据 token+checksum 等生成的 **API Key** | 调用 `/v1/chat/completions` 时用 `Authorization: Bearer <该 key>`，可带动态配置（代理、时区等） |

**结论**：  
- **AUTH_TOKEN**：自己定，只用于“证明你是管理员”和作为一种 Bearer 认证方式。  
- **对话用的 key**：要么是 `AUTH_TOKEN`、要么是 `AUTH_TOKEN-<别名>`、要么是 `/build-key` 返回的 key（或日志里缓存的数字 key）。

---

## 二、获取 Cursor 的 Token（用于添加账号 / build-key）

1. 打开 [www.cursor.com](https://www.cursor.com) 并登录。
2. 浏览器 F12 → **Application** → **Cookies**。
3. 找到 **WorkosCursorSessionToken**，复制**整条 Cookie 值**。  
   - 该值通常由多段用冒号 `:` 分隔；README 里说的“第三个字段”是指其中一段，实际操作时多数场景用**整段 Cookie 值**即可（即复制整个 `WorkosCursorSessionToken` 的值）。
   - 若接口要求只填“第三段”，再按 `:` 拆开取第三段；`%3A%3A` 为 `::` 的 URL 编码。

---

## 三、最小可运行配置

### 1. 必填环境变量

```bash
# 必填：管理员认证令牌，自定义字符串即可
AUTH_TOKEN=你的任意密码或随机字符串
```

### 2. 可选但常用的环境变量

```bash
# 端口（默认 3000，你项目已改为 5555）
PORT=5555

# 仅本机访问时建议
HOST=127.0.0.1

# 数据目录（token、代理、日志持久化）
DATA_DIR=data

# 前端资源（默认 frontend.zip，也可指向目录）
FRONTEND_PATH=frontend.zip
```

### 3. 启动方式

```bash
# 方式 A：用 .env
cp .env.example .env
# 编辑 .env 至少填 AUTH_TOKEN=
./target/release/cursor-api

# 方式 B：命令行传参
export AUTH_TOKEN=你的管理员令牌
./target/release/cursor-api import env listen on port 5555
```

---

## 四、推荐使用流程（来自 Issue #26 作者说明）

1. **先配代理**（若你访问 Cursor 需要代理）  
   - 打开前端：`http://localhost:5555/proxies`（需先有 frontend.zip 或 FRONTEND_PATH 指向的目录）。  
   - 或直接调接口：`POST /proxies/set`，Header：`Authorization: Bearer <AUTH_TOKEN>`，Body 见 README「代理管理接口」。

2. **再添加 Token**  
   - 打开 `http://localhost:5555/tokens`，选择刚配的代理（若有），再添加从 Cursor Cookie 里复制的 **WorkosCursorSessionToken**（整段或按说明取第三段）。  
   - 添加后若提示“缺少配置版本”，在页面上对对应 token 做：**刷新 Session Token** → **刷新 Config Version**。

3. **用该账号调用对话**  
   - **方式一**：用管理员身份：`Authorization: Bearer <AUTH_TOKEN>`，会轮询已添加的 token。  
   - **方式二**：指定账号：`Authorization: Bearer <AUTH_TOKEN>-<该 token 的别名>`。  
   - **方式三**：用 `/build-key` 生成的 key：在 build-key 页面或接口填入 token/checksum 等，得到 key，对话时 `Authorization: Bearer <build-key 返回的 key>`；日志里也会缓存数字 key，可作“别名”使用。

4. **没有 /tokens 页面时**  
   - 若访问 `/health` 的 `endpoints` 里没有 `/tokens`，说明前端未加载成功，需要正确的 **frontend.zip** 或 `FRONTEND_PATH` 目录（见 [doc/build-frontend-zip.md](build-frontend-zip.md)）。

---

## 五、环境变量一览（.env.example 精简说明）

| 变量 | 默认/示例 | 说明 |
|------|-----------|------|
| **HOST** | 空(即 0.0.0.0) | 监听 IP，仅本机填 127.0.0.1 |
| **PORT** | 5555 | 监听端口 |
| **AUTH_TOKEN** | （必填） | 管理员认证令牌，自定义 |
| **DATA_DIR** | data | 数据目录，存 tokens.bin、proxies.bin、logs.bin 等 |
| **FRONTEND_PATH** | frontend.zip | 前端资源 zip 或目录路径 |
| **CONFIG_FILE** | config.toml | 配置文件路径（若用 config 功能） |
| **KEY_PREFIX** | sk- | 动态 Key 前缀 |
| **DEFAULT_INSTRUCTIONS** | Respond in Chinese by default | 默认 system 提示词，占位符 {{currentDateTime}} 会替换 |
| **GENERAL_TIMEZONE** | Asia/Shanghai | 通用时区 |
| **GENERAL_GCPP_HOST** | Asia | 代码补全区域：Asia / EU / US |
| **PRI_REVERSE_PROXY_HOST** / **PUB_REVERSE_PROXY_HOST** | 空 | 私有/公开反向代理主机名（高级） |
| **REQUEST_BODY_LIMIT** | 2000000 | 请求体上限（字节），默认 2MB |
| **REQUEST_LOGS_LIMIT** | 100 | 内存中保留的请求日志条数，0 为不记 |
| **SERVICE_TIMEOUT** | 30 | 服务请求超时（秒） |
| **REAL_USAGE** | true | 是否拉取真实额度 |
| **SAFE_HASH** | true | 安全哈希（与 client key/checksum 更新有关） |
| **BYPASS_MODEL_VALIDATION** | false | 是否绕过模型校验 |
| **MODEL_ID_SOURCE** | server_id | 模型唯一标识来源：id / client_id / server_id |
| **CONTEXT_FILL_MODE** | 1 | 上下文填充模式（见 .env.example 注释） |
| **ALLOWED_PROVIDERS** | auth0,google-oauth2,github | 允许的 token 提供者 |
| **NTP_SERVERS** | 空 | NTP 服务器列表，逗号分隔；空则禁用 NTP |
| **DEBUG** / **DEBUG_LOG_FILE** | true / debug.log | 调试开关与日志文件 |
| **DYNAMIC_KEY_SECRET** | 空 | 动态密钥校验密钥，hex: 开头或普通字符串（会 SHA256）；空则禁用动态 Key |
| **DURATION_FORMAT** / **DURATION_LANGUAGE** | random / random | 运行时间显示格式与语言 |

更多项见项目根目录 **`.env.example`** 内注释。

---

## 六、常见问题（来自 Issues）

### 1. 401 / Invalid authorization token

- **AUTH_TOKEN** 填的是 Cursor Cookie 时：AUTH_TOKEN 应是**你自己设的管理员密码**，不要填 WorkosCursorSessionToken。  
- 调用 Chat 时：若用管理员身份，Header 为 `Authorization: Bearer <AUTH_TOKEN>`；若用 build-key，为 `Authorization: Bearer <build-key 返回的 key>`。

### 2. 添加 token 失败 / 缺少配置版本

- 先到 **/proxies** 配置代理（如需代理），再在 **/tokens** 里为该账号选择代理。  
- 添加后对该 token 执行：**刷新 Session Token**，再 **刷新 Config Version**。

### 3. blocked due to suspicious network activity（Issue #23）

- 属于 Cursor 侧风控（VPN/代理/机房 IP 等）。  
- 处理建议：换代理、稍后重试、或换 Google/GitHub 账号 / Cursor Pro；本项目无法消除该限制。

### 4. 提示 update to the latest version of Cursor（Issue #27、#25）

- Cursor 服务端要求客户端版本足够新。  
- 到 [cursor.com/downloads](https://cursor.com/downloads) 更新到最新 Cursor 客户端；若仅用 API 无本地客户端，可尝试保持本项目与官方接口兼容的最新版本。

### 5. 没有 /tokens、/proxies 等页面

- 需要正确加载前端：确保 **frontend.zip** 存在且为当前打包版本，或设置 **FRONTEND_PATH** 为包含 `route_registry.json` 及对应 .min 资源的目录。  
- 打包方法见 [build-frontend-zip.md](build-frontend-zip.md)。

### 6. 对话里仍显示“我在 Cursor 编辑器中运行”（Issue #28）

- 多为客户端或上游把响应里的说明写死，与 cursor-api 转发无关；若需改文案可在调用方或默认提示词中处理。

---

## 七、认证方式小结（调用 /v1/chat/completions）

1. **Bearer &lt;AUTH_TOKEN&gt;**：管理员身份，轮询已添加的 token。  
2. **Bearer &lt;AUTH_TOKEN&gt;-&lt;别名&gt;**：使用指定别名的 token。  
3. **Bearer &lt;build-key 返回的 key&gt;**：使用该 key 所绑定的 token 与配置（含代理、时区等）。  
4. **Bearer &lt;日志中缓存的数字 key / base64 key&gt;**：与 build-key 返回的后两个 key 对应，可用作同一配置的别名。  
5. **共享 Token**：若配置了 SHARED_TOKEN 且启用共享，可用该共享 token 作为 Bearer（仅 Chat 权限，与 AUTH_TOKEN 不同步）。

---

## 八、参考链接

- 项目 README：仓库根目录 `README.md`  
- 环境变量示例：`.env.example`  
- 前端打包：`doc/build-frontend-zip.md`  
- GitHub Issues：<https://github.com/wisdgod/cursor-api/issues>
