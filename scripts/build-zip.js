#!/usr/bin/env node
/** 将 static/ 下指定文件打成项目根目录的 frontend.zip，不依赖系统 zip 命令 */
const fs = require('fs');
const path = require('path');
const archiver = require('archiver');

const root = path.join(__dirname, '..');
const staticDir = path.join(root, 'static');
const outPath = path.join(root, 'frontend.zip');

const files = [
  'route_registry.json',
  'tokens.min.html', 'proxies.min.html', 'logs.min.html', 'config.min.html',
  'api.min.html', 'build_key.min.html',
  'shared.min.js', 'shared-styles.min.css',
];

const archive = archiver('zip', { zlib: { level: 9 } });
const out = fs.createWriteStream(outPath);

out.on('close', () => console.log('  written', outPath, '(' + (archive.pointer() / 1024).toFixed(1) + ' KB)'));

archive.pipe(out);
for (const name of files) {
  const full = path.join(staticDir, name);
  if (!fs.existsSync(full)) {
    console.error('missing:', full);
    process.exit(1);
  }
  archive.file(full, { name });
}
archive.finalize();
