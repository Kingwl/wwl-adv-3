# GitHub 配置

- CI 工作流位于 `.github/workflows/ci.yml`，并委托 `game/tools/check-all.sh` 执行项目检查。
- Web 部署工作流位于 `.github/workflows/deploy-web.yml`，将 `site/` 发布到 GitHub Pages。
