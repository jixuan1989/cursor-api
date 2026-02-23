# 调试与命令行启动

## 一、命令行前台启动（调试用）

在项目根目录执行，**前台运行**，所有日志和调试输出都会出现在当前终端：

```bash
# 进入项目目录
cd /path/to/cursor-api

# 确保已配置 .env（AUTH_TOKEN 等）

# 前台启动（阻塞当前终端，Ctrl+C 停止）
./target/release/cursor-api
```

## 二、使用已有启动脚本（后台 / 前台）

- **后台启动**（默认）：  
  `~/scripts/cursor-api-start.sh`  
  输出在项目下 `logs/cursor-api.log`，想看“控制台”可：  
  `tail -f /path/to/cursor-api/logs/cursor-api.log`
- **前台启动**（便于看实时输出）：  
  `~/scripts/cursor-api-start.sh --foreground`

## 三、调试日志文件（可选）

若需将内部 `crate::debug!` 写入文件，可设置：

```bash
export DEBUG_LOG_FILE=debug.log
./target/release/cursor-api
```

调试日志会追加写入当前目录下的 `debug.log`（或你指定的路径）。
