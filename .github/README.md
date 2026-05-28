# GitHub 配置

- CI 工作流位于 `.github/workflows/ci.yml`，执行 `game/tools/check-all.sh` 的 scaffold 检查，并通过 `game/tools/test-godot.sh` 跑 Godot headless 测试。
- Web 部署工作流位于 `.github/workflows/deploy-web.yml`，将 Godot Web 导出产物发布到 GitHub Pages。
