# cursor-api 安全分析报告

**分析时间**: 2025-02-22  
**结论**: **未发现高危恶意行为**；存在若干低风险与使用策略层面的注意点。

---

## 一、总体结论

- **无命令执行、无任意代码执行**：未发现 `Command::`、`exec`、`system()`、`eval` 等调用。
- **无后门或外联回传**：外部请求仅发往 Cursor 官方相关域名（用于对话、模型、Token 刷新等），且由代码与配置决定，无隐藏回连。
- **认证与权限**：管理员接口依赖环境变量 `AUTH_TOKEN`；业务接口支持 Bearer/动态 Key/共享 Token，无硬编码密钥。
- **依赖与构建**：使用 Cargo 与常见 crates（axum、reqwest、rkyv 等），含本地 patch 目录，未发现异常依赖或构建脚本执行恶意逻辑。

因此，从「是否危险」的角度：**程序本身未发现明显恶意或高危漏洞**，可作为自建代理服务使用，但需按下面建议做好部署与配置。

---

## 二、已检查的安全点

| 检查项           | 结果说明 |
|------------------|----------|
| 命令/进程执行    | 未发现 shell 或子进程执行；`natural_args` 仅解析「import env / listen / help」并设置环境变量或打印帮助。 |
| 认证与鉴权       | 管理员路由使用 `admin_auth_middleware` 校验 `AUTH_TOKEN`；v1/cpp 使用 `get_token_bundle` 等，支持多种合法 Token 来源。 |
| 敏感信息日志     | 对 token/响应体的 `debug!` 已注释，仅记录状态码等非敏感信息，未发现将完整 token 写入日志。 |
| 请求体大小       | 使用 `RequestBodyLimitLayer`，默认 2MB（`REQUEST_BODY_LIMIT`），可缓解大 body DoS。 |
| 代理 URL         | 代理配置仅通过管理员 API 写入，并经 `ProxyUrl::from_str` → `Proxy::all(s)` 校验；普通用户无法通过聊天等接口注入代理 URL。 |
| 静态资源路径     | 前端 `DirectoryProvider` 使用 `base_path.join(relative_path)`，`relative_path` 来自构建期 `route_registry.json`，非用户输入，路径遍历风险低。 |

---

## 三、低风险与建议

### 1. 命令行「import env」路径未做规范化（低风险）

- **位置**: `natural_args.rs` 中 `load_env_file(env_file, ...)`，`env_file` 来自命令行解析（如 `import env from ../../some/file`）。
- **行为**: 使用 `dotenvy::from_filename(filename)` 直接读文件，未做 `Path::canonicalize` 或禁止 `..`，理论上可读当前用户有权限的任意文件。
- **前提**: 攻击者需能控制进程启动参数（本地或通过某种「启动脚本」间接控制）。
- **建议**: 仅在受控环境启动；若需加固，可对 `env_file` 做规范化并限制在指定目录下。

### 2. 默认监听地址

- **行为**: 默认 `HOST=0.0.0.0`，服务会监听所有网卡。
- **建议**: 若仅本机使用，将 `HOST` 设为 `127.0.0.1`；对外提供时配合防火墙与反向代理。

### 3. 敏感数据与 Token 存储

- **行为**: Token、代理等持久化在 `DATA_DIR` 下（如 `tokens.bin`、`proxies.bin`），为二进制格式。
- **建议**: 确保 `DATA_DIR` 目录权限仅服务进程可读写，避免其他用户或进程读取。

### 4. `unsafe` 使用

- **行为**: 代码中存在较多 `unsafe`（如 `transmute`、`get_unchecked`、`unwrap_unchecked`），多为性能优化与类型转换。
- **建议**: 后续修改时注意不破坏已有不变式；若有 fuzz/测试可覆盖关键解析与序列化路径。

---

## 四、使用与合规注意（非「程序危险」）

- **Cursor ToS**：本项目通过用户提供的 Cursor 会话 Cookie（如 `WorkosCursorSessionToken`）代理请求至 Cursor 官方 API，此类用法可能违反 Cursor 服务条款。使用与对外提供此类服务时需自行评估合规风险。
- **自建部署**：README 建议自部署；若使用他人提供的在线服务，需注意 Token 与对话内容可能被托管方接触，建议仅使用自建或可信实例。

---

## 五、简要结论（是否「危险」）

- **从恶意代码与高危漏洞角度**：**未发现程序本身存在明显危险行为**；未发现命令执行、回连、日志泄露 token、未校验的代理注入等。
- **从安全加固角度**：建议关注命令行 env 文件路径、监听地址、数据目录权限，并注意 Cursor ToS 与自建/托管策略。

以上分析基于当前代码静态阅读，未进行动态测试或依赖的完整审计。若后续增加新依赖或新接口，建议再做一次针对性安全与隐私检查。
