# 503 Service Unavailable 与测试说明

## 一、503 表示什么

当请求 **`/v1/chat/completions`** 返回 **503 Service Unavailable** 时，程序返回的是 **`no_available_tokens`**：

- 表示：当前**没有“可用”的 Cursor token** 被选中来转发请求。
- “可用”指：已添加、**已启用（enabled）**、且**健康检查通过（health is available）**。

也就是说：要么池子里没有 token，要么有 token 但全部被禁用或全部不健康，所以会 503。

---

## 二、按下面顺序自查

### 1. 在 /tokens 页面确认

打开 **http://localhost:5555/tokens**，用 AUTH_TOKEN 登录后看：

| 检查项 | 说明 |
|--------|------|
| 是否有至少一个 token | 没有则先去「添加 Token」，填 Cursor 的 WorkosCursorSessionToken（整段 Cookie 值）。 |
| 状态是否为「启用」 | 若某 token 被禁用，在列表里启用它（或用「设置状态」批量启用）。 |
| 是否有报错/不健康 | 若显示配置缺失、过期等，对该 token 做「刷新 Session Token」→「刷新 Config Version」或「更新 Profile」。 |

只要有一个 token 是**启用且健康**的，用 AUTH_TOKEN 调 chat 时就不应再 503。

### 2. 用“指定别名”的方式再测一次

若池子里有多个 token，可以**强制用某一个**，排除是否只有部分 token 不可用：

```bash
# 把 <你的AUTH_TOKEN> 和 <别名> 换成实际值（/tokens 页里看到的别名）
curl -X POST http://localhost:5555/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <你的AUTH_TOKEN>-<别名>" \
  -d '{"model":"default","messages":[{"role":"user","content":"说你好"}],"stream":false}'
```

- 若这样仍 503：多半是该 token 未启用或不健康，回到上面第 1 步处理。
- 若这样返回 200 或别的错误（如 4xx/5xx 内容错误）：说明至少有一个 token 可用，503 可能是轮询到别的不可用 token，可继续用别名或把不可用的 token 启用/修好。

### 3. 确认代理（如需）

若你访问 Cursor 必须走代理：

- 在 **/proxies** 里配好代理。
- 在 **/tokens** 里给对应 token **设置代理**，否则请求 Cursor 可能失败，导致健康检查不通过或请求失败。

---

## 三、用 model 为 default 的测试命令

下面命令使用 **`"model": "default"`**，且用 AUTH_TOKEN 轮询池子里的 token：

```bash
curl -X POST http://localhost:5555/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 你的AUTH_TOKEN" \
  -d '{
    "model": "default",
    "messages": [{"role": "user", "content": "说你好"}],
    "stream": false
  }'
```

把 **`你的AUTH_TOKEN`** 换成你 `.env` 里的 `AUTH_TOKEN` 实际值。

- **200 + 有 `choices[].message.content`**：说明 token 可用，模型 default 也生效。
- **503**：按第二节检查 token 是否已添加、启用、健康，以及是否要配代理。

流式测试（同样用 default）：

```bash
curl -X POST http://localhost:5555/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer 你的AUTH_TOKEN" \
  -d '{"model":"default","messages":[{"role":"user","content":"说你好"}],"stream":true}'
```

---

## 四、429 与「请更新 Cursor」提示

当返回 **429** 且 body 中出现 **"Please update to the latest version of Cursor at cursor.com/downloads"** 时：

- 这是 **Cursor 服务端** 根据请求头里的客户端版本做的限制，要求使用较新版本的 Cursor 客户端。
- 本程序会向 Cursor 发送 **`x-cursor-client-version`** 和 **User-Agent** 中的版本号；默认已使用 **2.5.0**（与官网当前 Latest 一致）。
- 若仍出现该 429：
  1. **升级 cursor-api** 到最新版本（已包含 2.5.0 默认版本）。
  2. 或在 **config.toml** 中显式设置更高版本，例如：`cursor_client_version = "2.5.0"`。
  3. 若 Cursor 再次提高要求，可把 `cursor_client_version` 改为官网 [cursor.com/downloads](https://cursor.com/downloads) 上标注的最新版本号（如 2.6.0 等）。

---

## 五、小结

| 现象 | 处理方向 |
|------|----------|
| 503 no_available_tokens | 保证至少一个 token 已添加、启用且健康；必要时用 AUTH_TOKEN-别名 指定 token 测试。 |
| 429 + 请更新 Cursor | 使用最新 cursor-api（默认 2.5.0）；必要时在 config.toml 设置 `cursor_client_version` 为更高版本。 |
| 模型用 default | 请求体里 `"model": "default"` 即可。 |
| 仍 503 | 查 /tokens 状态、代理设置，并对问题 token 做刷新 Session/Config Version 或更新 Profile。 |
| 422 messages[N]…ChatCompletionContentText | 常见原因：(1) **assistant 的 content 为 null**（仅 tool_calls 无文本）— 已支持，更新到最新代码；(2) content 数组里含不认识的块类型 — 已支持 `text`/`thinking`/`input_json` 及兜底。 |
