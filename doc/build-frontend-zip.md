# 如何编译出 frontend.zip

`frontend.zip` 是前端静态资源包，程序通过环境变量 `FRONTEND_PATH`（默认 `frontend.zip`）加载，也可改为指向一个目录。

## 方式一：用脚本一键生成（推荐）

**前提**：已安装 Node.js（>= 14），并已安装脚本依赖。

```bash
# 1. 安装脚本依赖（仅首次）
cd /home/hxd/codes/cursor-api/scripts
npm install

# 2. 在项目根目录执行打包脚本
cd /home/hxd/codes/cursor-api
./scripts/build-frontend-zip.sh
```

脚本会：

1. 用 `scripts/minify.js` 把 `static/` 下的 html/js/css 压成 `.min.*` 到 `static/`；
2. 把 `route_registry.json` 和这些 `.min` 文件打成一个 zip，输出到项目根目录的 **`frontend.zip`**。

## 方式二：分步执行

```bash
cd /home/hxd/codes/cursor-api

# 1. 安装依赖（仅首次）
(cd scripts && npm install)

# 2. 生成 .min 文件
node scripts/minify.js \
  tokens.html proxies.html logs.html config.html api.html build_key.html \
  shared.js shared-styles.css

# 3. 打 zip（在 static 目录下执行 zip，避免 zip 内带一层 static/ 目录）
rm -f frontend.zip
(cd static && zip -q ../frontend.zip \
  route_registry.json \
  tokens.min.html proxies.min.html logs.min.html config.min.html api.min.html build_key.min.html \
  shared.min.js shared-styles.min.css)
```

## 方式三：直接用 static 目录（不打包 zip）

不生成 zip 也可以，把 `FRONTEND_PATH` 指到 `static` 目录即可。但此时 `route_registry.json` 里引用的是 `.min.*` 文件，需要先执行上面的 minify 步骤，让 `static/` 下存在对应的 `.min.html`、`shared.min.js`、`shared-styles.min.css` 等。

```bash
# 生成 .min 文件
node scripts/minify.js tokens.html proxies.html logs.html config.html api.html build_key.html shared.js shared-styles.css

# 启动时指定目录
export FRONTEND_PATH=/home/hxd/codes/cursor-api/static
./target/release/cursor-api
```

## 依赖说明

- **Node.js** >= 14
- `scripts/package.json` 中的依赖：`archiver`、`html-minifier-terser`、`terser`、`clean-css`、`markdown-it` 等（`npm install` 会安装）
- 打包 zip：有系统 `zip` 时用系统命令，否则用 Node 的 `archiver` 打 zip，**无需额外安装 zip 包**

## 输出位置

- 脚本生成的 **`frontend.zip`** 在**项目根目录**（与 `Cargo.toml` 同级）。
- 程序默认读取当前工作目录下的 `frontend.zip`，也可通过 `FRONTEND_PATH` 指定绝对路径或 `static` 目录。
