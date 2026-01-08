# Self-Hosted Runner 配置指南

## 快速安装（一行命令）

在 runner 机器上执行以下命令，自动安装所有必需工具：

```bash
curl -fsSL https://raw.githubusercontent.com/IOTCloudfire/iot-fire-cloud/develop/github/runner-setup.sh | sudo bash
```

## 安装后操作

```bash
# 1. 重新登录使 docker 组生效
exit
# 重新 SSH 登录

# 2. 验证安装
make --version && docker --version && docker compose version && git --version && unzip -v | head -1

# 3. 重启 runner 服务（在 runner 目录下执行）
./svc.sh stop && ./svc.sh start
```

## 工具清单

| 工具             | 用途                   |
| ---------------- | ---------------------- |
| `make`           | 执行 Makefile 构建命令 |
| `docker`         | 构建和推送容器镜像     |
| `docker compose` | 多容器编排             |
| `git`            | 代码检出               |
| `unzip` / `zip`  | 压缩解压               |
| `curl` / `wget`  | 文件下载               |
| `jq`             | JSON 处理              |

## 常见问题

### Docker 权限问题

```bash
sudo usermod -aG docker $USER && newgrp docker
```

### Runner 找不到 Docker

```bash
sudo systemctl restart actions.runner.*.service
```
