# dotfiles

使用 [GNU Stow](https://www.gnu.org/software/stow/) 管理 Desktop 和 Server 配置。

## 目录结构

```text
desktop/          桌面环境配置
server/           远程服务器配置
deploy.sh         部署脚本
```

每个角色目录下，一个子目录就是一个独立的 Stow 软件包。例如：

```text
desktop/
├── fish/.config/fish/
├── niri/.config/niri/
└── tmux/.tmux.conf

server/
├── fish/.config/fish/
├── nvim/.config/nvim/
└── tmux/.tmux.conf
```

Desktop 和 Server 配置彼此独立。即使内容相同，也不通过公共目录或 Git 分支共享。

## 部署

依赖：

- Bash
- Git
- GNU Stow

先预览链接变化：

```bash
./deploy.sh desktop --dry-run
./deploy.sh server --dry-run
```

部署当前角色下的全部软件包：

```bash
./deploy.sh desktop
./deploy.sh server
```

脚本使用 `stow --restow --no-folding`。它只创建文件级链接，遇到已有普通文件时会停止，不会自动覆盖或采用这些文件。

更新配置：

```bash
git pull --ff-only
./deploy.sh server
```

## 添加软件包

按照目标 `$HOME` 的目录结构创建包。例如添加 Server 版 Fastfetch：

```text
server/fastfetch/.config/fastfetch/config.jsonc
```

再次执行 `./deploy.sh server` 即可。角色目录中不要放置非 Stow 软件包目录。
