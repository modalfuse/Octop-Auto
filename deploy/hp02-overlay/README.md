# hp02 Octop dashboard overlay — 项目空间

运行中的自托管实例（pip/venv）补丁，与 `dashboard/` 源码侧注入一致。

## 文件
- `dashboard/index.html`：相对原构建产物增加 `project-space.css/js`
- `dashboard/assets/project-space.js`
- `dashboard/assets/project-space.css`

## 应用到 hp02
```bash
BASE=~/.octop/venv/lib/python3.12/site-packages/octop/dashboard
cp dashboard/assets/project-space.* "$BASE/assets/"
# 或对照 diff 只插入两行 link/script；完整替换见仓库内 index.html
```
静态资源热读，一般无需重启。强制刷新浏览器即可。

## 说明
侧栏「项目空间」为前端注入；项目列表存浏览器 `localStorage`（键 `octop:project-space`）。
