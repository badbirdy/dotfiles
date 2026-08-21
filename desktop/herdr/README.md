# 从 tmux 迁移到 Herdr

这份教程面向已经熟悉 tmux、希望在日常开发中使用 Herdr 的用户。
当前快捷键以本目录下的 `config.toml` 为准，并通过 GNU Stow 管理。

## 一、先建立对应关系

| tmux | Herdr | 说明 |
| --- | --- | --- |
| server / session | Herdr server / named session | 持久化运行环境；普通开发优先使用 workspace |
| window | tab | 一个 workspace 中可以有多个 tab |
| pane | pane | 终端分割区域 |
| `prefix` | `prefix` | 当前都是 `Ctrl-a` |
| session 切换 | workspace 导航 | Herdr 用 workspace 组织项目和 agent |
| status bar | tab bar + sidebar | sidebar 额外显示 workspace、pane 和 agent 状态 |
| resurrect / continuum | Herdr 持久 server 和 restore | 不再依赖 tmux 插件 |
| `prefix :` | Herdr CLI | Herdr 没有 tmux 那种内置命令提示符，使用 `herdr ...` 命令 |

tmux 习惯上从 session 开始组织工作；Herdr 更推荐从 workspace 开始。通常一个项目对应一个 workspace，workspace 里再按需要创建 tab 和 pane。

## 二、启动、脱离和恢复

启动或连接默认 Herdr server：

```bash
herdr
```

脱离当前界面，但不停止 pane 中的程序：

```text
Ctrl-a，然后按 q 或 d
```

`q` 是 Herdr 原生快捷键，`d` 是为了兼容 tmux 的 `prefix+d`。

重新连接：

```bash
herdr
```

Herdr 的 server 会继续运行，Codex 等支持原生恢复的 agent 可以在恢复时重新连接到自己的会话。

如果需要完全独立的一组 Herdr 运行环境，可以使用 named session：

```bash
herdr session list
herdr session attach work
herdr session attach side-project
```

named session 适合需要完全隔离 pane、workspace、socket 和持久状态的场景；普通项目切换优先使用 workspace。

## 三、创建和切换 workspace

### 创建 workspace

当前配置：

```text
Ctrl-a，然后按 Shift-n
```

这会创建一个新的 workspace。

也可以从 shell 创建：

```bash
herdr workspace create
herdr workspace create --cwd ~/Projects/my-project --label my-project
```

### 切换 workspace

```text
Ctrl-a，然后按 s
```

这会打开 Herdr 的 goto 界面，用来切换 workspace，也可以定位到其中的 tab、pane 和 agent。这里使用 `goto` 而不是 Herdr 原本的 navigate workspace 快捷键，目的是让 tmux 的 `prefix+s` 继续承担 session/workspace 切换。

相关操作：

```text
Ctrl-a，然后按 Shift-w  重命名当前 workspace
Ctrl-a，然后按 $        重命名当前 workspace
Ctrl-a，然后按 ,        重命名当前 tab
Ctrl-a，然后按 Shift-k  关闭当前 workspace
Ctrl-a，然后按 Shift-d  关闭当前 workspace
Ctrl-a，然后按 b        展开/收起 sidebar
```

`Shift-k` 是为了保留原 tmux `prefix+K` 的习惯；`Shift-d` 是 Herdr 默认风格的关闭快捷键。

## 四、tab 对应 tmux window

```text
Ctrl-a，然后按 c        新建 tab
Ctrl-a，然后按 n        下一个 tab
Ctrl-a，然后按 p        上一个 tab
Ctrl-a，然后按 1..9     跳转到对应编号的 tab
Ctrl-a，然后按 &        关闭当前 tab
```

Herdr 的 tab 属于当前 workspace。切换 workspace 后，tab 列表也随之切换。

## 五、pane 操作

### 分割

```text
Ctrl-a，然后按 v                 向右分割 pane
Ctrl-a，然后按 Shift-反斜杠       tmux 原 `prefix+|` 的兼容写法
Ctrl-a，然后按 -                 向下分割 pane
```

Herdr 的配置使用 `prefix+v` 和 `prefix+minus` 表示向右、向下分割；其中 `prefix+Shift-反斜杠` 是为了兼容 tmux 原来的 `prefix+|`。

### 聚焦和关闭

```text
Ctrl-a，然后按 h  聚焦左侧 pane
Ctrl-a，然后按 j  聚焦下方 pane
Ctrl-a，然后按 k  聚焦上方 pane
Ctrl-a，然后按 l  聚焦右侧 pane
Ctrl-a，然后按 x  关闭当前 pane
Ctrl-a，然后按 z  放大/恢复当前 pane
```

### 调整大小

```text
Ctrl-a，然后按 Shift-r
```

进入 resize mode 后，使用 `h/j/k/l` 调整 pane 大小，按 `Esc` 退出。

这里特意使用了 `Shift-r`：tmux 中的 `prefix+r` 是重载配置，不能同时拿来进入 resize mode。

## 六、复制和滚动

Herdr 内置 copy mode：

```text
Ctrl-a，然后按 [
```

在 copy mode 中可以使用 vi/tmux 风格的移动方式：

```text
h/j/k/l       移动
w/b/e         按单词移动
PageUp/Down   翻页
Ctrl-b/Ctrl-f 反向/正向翻页
v 或 Space    开始选择
y 或 Enter    复制
q 或 Esc      退出
/ 或 ?         搜索
```

当前还启用了鼠标选择即复制：

```toml
[ui]
copy_on_select = true
```

因此日常复制可以直接用鼠标；需要查看较早输出时使用 `prefix+[` 进入 copy mode。

## 七、配置重载和设置

```text
Ctrl-a，然后按 r        重载配置
Ctrl-a，然后按 Shift-s  打开 Herdr 设置
Ctrl-a，然后按 ?        查看当前所有快捷键
```

也可以从 shell 重载：

```bash
herdr server reload-config
```

配置文件的仓库路径是：

```text
desktop/herdr/.config/herdr/config.toml
```

部署后的路径是：

```text
~/.config/herdr/config.toml
```

修改后可以检查 TOML：

```bash
herdr config check
```

## 八、tmux `prefix :` 的替代方式

Herdr 没有 tmux 那种按 `prefix+:` 后输入命令的交互式命令行。需要执行控制命令时，在普通 shell 中使用 Herdr CLI：

```bash
herdr workspace list
herdr workspace create
herdr pane list
herdr pane current
herdr pane split --current --direction right
herdr pane zoom --current --toggle
herdr server reload-config
herdr session list
```

Herdr CLI 通过本地 socket 控制正在运行的 server，作用上相当于 tmux 的命令模式，但输入位置从 Herdr 内部改成了 shell。

## 九、Codex 工作流

Herdr 会识别 Codex pane，并在 sidebar 中显示 agent 状态。推荐的日常布局是：

1. `Ctrl-a Shift-n` 创建项目 workspace。
2. 在主 pane 中启动 Codex。
3. `Ctrl-a v` 或 `Ctrl-a -` 创建 shell、测试或日志 pane。
4. 用 `Ctrl-a s` 在项目 workspace 之间切换。
5. 通过 sidebar 查看 Codex 是否正在工作、完成或等待输入。
6. 用 `Ctrl-a q` 脱离，稍后重新运行 `herdr` 连接。

## 十、哪些 tmux 功能没有一比一迁移

以下功能不能直接照搬：

- `tmux-resurrect` / `tmux-continuum` 插件：由 Herdr 自己的 server persistence 和 restore 机制替代。
- tmux 状态栏中的 `#{continuum_status}`：Herdr 使用 sidebar、agent 状态和 toast 通知展示运行状态。
- `prefix+s` 中自定义的 fzf session 列表：现在对应 Herdr 的 workspace 导航。
- `prefix+K` 中“从 fzf 选择任意 session 后确认删除”：现在映射为关闭当前 workspace，避免把 Herdr workspace 和 named session 混为一谈。
- tmux 的内置 `prefix+:` 命令提示符：使用 `herdr` CLI 替代。

## 十一、通过 Stow 管理

在仓库根目录执行：

```bash
./deploy.sh desktop --dry-run
./deploy.sh desktop
```

只操作 herdr 包时：

```bash
stow --restow --no-folding \
  --dir="$PWD/desktop" \
  --target="$HOME" \
  herdr
```

不要直接编辑 `~/.config/herdr/config.toml`；它是指向仓库文件的符号链接，应编辑仓库中的配置文件后再重载 Herdr。
