# 部署目录

本目录存放 Docker Compose、镜像构建和发布脚本。构建上下文是仓库根目录，因此请在仓库根目录执行命令，或使用 `-f deploy/docker-compose.yml`。

## Docker Compose

```bash
cp deploy/.env.openship.example deploy/.env
docker compose -f deploy/docker-compose.yml config
docker compose -f deploy/docker-compose.yml up -d
```

说明见 `Doc/openship-compose.md`。

## 发布脚本

```bash
./deploy/deploy.sh
./deploy/docker.sh
```

说明见 `Doc/deployment-guide.md` 和 `Doc/docker-release.md`。
