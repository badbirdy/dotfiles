# Wayland / Niri 剪贴板管理方案调研

日期：2026-07-18

## 结论

最适合当前仓库的路线不是立刻换后端，而是先把已有的 `cliphist + Rofi` 补成真正的“管理器”：继续使用现有历史数据库和图片支持，在菜单中增加“粘贴、删除当前项、清空全部”动作，并把 `Mod+V` 从一次性管道改为调用现成的 `clipboard.sh` 或新的统一脚本。这条路线改动最小，也最符合当前 Niri、Rofi 和 GNU Stow 结构。

如果希望少写脚本、直接获得编辑和删除能力，第二选择是恢复已经安装过的 Clipcat。它原生提供 `insert/remove/edit/clear` 客户端命令、Rofi/Fuzzel finder、图片、持久化和敏感内容过滤；代价是常驻 daemon + client/server 配置，而且官方仍把 Wayland 标作 experimental。

如果更看重完整 TUI/GUI 体验，Clipse 或 `cliphist-tui` 比纯 Rofi 菜单更合适。CopyQ 功能最全，但更重，且对 Niri 来说窗口式工具的集成感不如前三者。

## 实施前状态

当前 Desktop 配置已经形成完整的 cliphist 数据链：

- Niri 启动 `wl-paste --watch cliphist store`，见 [`desktop/niri/.config/niri/config.kdl`](../../desktop/niri/.config/niri/config.kdl#L300-L301)。
- `Mod+V` 执行 `cliphist list | rofi -dmenu | cliphist decode | wl-copy`，见 [`desktop/niri/.config/niri/binds.kdl`](../../desktop/niri/.config/niri/binds.kdl#L293-L295)。Rofi 提供搜索，选中项会重新写回剪贴板，但没有动作层，所以用户感受上基本是“只能看/选”。
- 仓库其实已有 [`desktop/rofi/.config/rofi/scripts/clipboard.sh`](../../desktop/rofi/.config/rofi/scripts/clipboard.sh)，能把 cliphist 中的图片解码成临时文件并作为 Rofi 图标预览；Rofi 也已经把 `clipboard` 注册为 script mode，见 [`config.rasi`](../../desktop/rofi/.config/rofi/config.rasi#L9-L17)。但当前 `Mod+V` 绕过了这个脚本，而且脚本本身仍只有选择，没有单条删除或清空。
- 本机安装的是 `cliphist 0.7.0`，支持 `delete`、`delete-query` 和 `wipe`；当前数据库上限为 750 项，`~/.cache/cliphist/db` 实测约 50 MiB。这说明管理动作和容量控制都有实际价值。
- Niri 配置中仍保留了注释掉的 `clipcatd` 与 `clipcat-menu`，见上面两个 Niri 文件。系统已安装 `clipcat 0.25.0`，真实 `$HOME` 中也残留可用配置和旧历史。该配置含私人 snippets，不应直接搬入仓库；迁移时应把 snippets 留在未跟踪的本地覆盖文件中。

## 已实施

- `Mod+V` 已改为打开 Rofi 的 `clipboard` script mode，不再绕过图片预览脚本。
- `Enter` 恢复选中内容，`Shift+Delete` 删除当前条目并刷新列表。
- `Ctrl+Shift+Delete` 打开二次确认页，确认后才执行 `cliphist wipe`。
- 空历史会显示不可选中的提示；现有图片缩略图逻辑保持不变。

## 本机已有的其他 dotfiles 示例

### `unixchad_dotfiles`：给 cliphist 包一层可组合脚本

本地路径：`/home/bdbd/dotfiles-others/unixchad_dotfiles`

公开源：[gnuunixchad/dotfiles 的 `.local/bin/clip`](https://github.com/gnuunixchad/dotfiles/blob/24873ac635a9ba22cc4147a2b948bde5abdbf8a2/.local/bin/clip)

它在 Wayland 下仍使用 `cliphist list -> 菜单 -> decode -> wl-copy`，但额外实现了 `clip --wipe`，清空前用菜单确认并发送通知；Sway 自启动则保持简单的 `wl-paste --watch cliphist store`。这证明不换后端也可以逐步增加管理动作，且脚本边界很清楚。

可迁移点：

- 保留当前 cliphist 后端。
- 为 `wipe` 增加确认，而不是把危险动作直接绑到按键。
- 同一脚本中集中处理打开菜单和管理动作，Niri 只绑定脚本入口。
- 当前仓库还应再补 `cliphist delete`，否则仍不能删除单条。

### `ShorinArchExperience-ArchlinuxGuide`：Niri 下的 Clipse 与 cliphist-tui

本地路径：`/home/bdbd/dotfiles-others/ShorinArchExperience-ArchlinuxGuide`

公开源：[Niri 安装文档的剪贴板章节](https://github.com/SHORiN-KiWATA/ShorinArchExperience-ArchlinuxGuide/blob/85eb432e1241d995c4502af3ccec9320ff192bc6/wiki/archlinux/%E5%AE%89%E8%A3%85Niri.md#%E5%89%AA%E8%B4%B4%E6%9D%BF)

该仓库给出两条 Niri 原生路线：

- `spawn-at-startup "clipse" "--listen"`，快捷键打开 `clipse-gui` 或 Kitty 中的 Clipse TUI，并用 Niri `window-rule` 设置浮动窗口。
- 继续使用 `wl-paste + cliphist`，但通过作者的 [`cliphist-tui`](https://github.com/SHORiN-KiWATA/cliphist-tui) 提供 Kitty 图片预览和更完整的 TUI，再用 Niri 浮动窗口规则固定尺寸与位置。

可迁移点：

- Niri 集成本身很直接：一个 watcher、一个快捷键、一个浮动规则。
- 想保留当前数据库时，`cliphist-tui` 的迁移成本低于 Clipse。
- Clipse 是独立后端，切换时应先停止 `wl-paste --watch cliphist store`，避免两个管理器同时记录同一内容。

### 同一 Shorin 仓库的 CopyQ 示例

公开源：[Mango/CopyQ 配置说明](https://github.com/SHORiN-KiWATA/ShorinArchExperience-ArchlinuxGuide/blob/85eb432e1241d995c4502af3ccec9320ff192bc6/wiki/legacy/%E5%AE%89%E8%A3%85mangowc.md#%E5%89%AA%E8%B4%B4%E6%9D%BF)

示例使用 `copyq` 自启动、`copyq toggle` 快捷键和 `com.github.hluk.copyq` 浮动窗口规则。仓库的旧 Hyprland 配置也采用了相同结构。这种方式几乎不需要自写菜单脚本，但会引入托盘/窗口式 GUI 和更大的配置面。

### 其他两个本地 dotfiles

`/home/bdbd/dotfiles-others/niri-dotfiles` 只有 Neovim 系统剪贴板同步；`/home/bdbd/dotfiles-others/dotfiles_Sonny` 只有编辑器剪贴板与截图写入 `wl-copy`，没有可迁移的 Wayland 历史管理方案。

## 方案比较

| 方案 | 搜索 | 删除单条 / 清空 | 图片 | 敏感内容 | 持久化 | Rofi / Fuzzel / Walker | Niri / Wayland |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 增强现有 `cliphist + wl-clipboard` | 由 Rofi/Fuzzel/Walker 提供 | `cliphist delete`、`delete-query`、`wipe` | 后端支持；当前脚本已有 Rofi 图标预览 | `wl-copy --sensitive` 可发提示；需要确认前端/存储链是否确实跳过，密码仍应保守处理 | BoltDB，当前就在使用 | Rofi/Fuzzel 是简单管道；Walker 可作为前端或自定义 provider | 最成熟、最贴合当前配置；`wl-paste --watch` 要求 compositor 支持 data-control，Niri 满足当前实用路径 |
| Clipcat | finder 搜索 | `clipcat-menu remove/edit`；`clipcatctl clear` | 支持捕获与持久化图片 | `sensitive_mime_types` 和 `denied_text_regex_patterns` | 支持，路径和上限可配置 | 官方直接支持 Rofi、Fuzzel、fzf、skim、dmenu；Walker 需自定义调用 CLI | 官方支持 Wayland，但仍标 experimental；本机已有配置可回退测试 |
| Clipse / clipse-gui | TUI/GUI 内搜索 | TUI/GUI 内管理，适合键盘操作 | 需按当前版本验证 GUI/TUI 的图片体验 | 可通过监听/配置策略降低风险，但不应默认假定密码完全不会入库 | 独立历史文件 | 不依赖 Rofi/Fuzzel/Walker；通过终端或 GTK 浮窗打开 | 本地 Niri 指南已有可直接参考的启动、快捷键和浮动规则 |
| `cliphist-tui` | TUI 内搜索 | 以其当前功能为准；后端仍可直接调用 delete/wipe | 明确使用 Kitty icat 预览 | 继承 cliphist/wl-clipboard 的边界 | 复用现有 cliphist DB | 不依赖 launcher；适合 Kitty 浮窗 | 本地 Niri 指南给出完整窗口规则，迁移成本低 |
| CopyQ | GUI 搜索、过滤、编辑很强 | 完整 GUI/命令行管理 | 支持 | 可用规则/忽略机制精细控制，但配置复杂；默认持久历史仍需谨慎 | 强，支持多标签和丰富元数据 | 自带 GUI，不需要 launcher；可由 Rofi/Walker 只负责 `copyq toggle` | 可作为浮动窗口运行；比原生菜单/TUI 更重，需在 Niri 会话实测剪贴板监听与焦点行为 |

## 敏感内容的现实边界

[`wl-clipboard`](https://github.com/bugaevc/wl-clipboard) 定义了 `wl-copy --sensitive`，在 `wl-paste --watch` 启动的子进程中通过 `CLIPBOARD_STATE=sensitive` 暗示管理器不要展示或持久化。其手册同时说明，目前通常只有 `x-kde-passwordManagerHint` 能可靠触发这个状态；不是所有应用和密码管理器都会提供该 MIME 类型。因此：

- 任何方案都不应宣传为“绝不会记录密码”。
- 优先选择能识别敏感 MIME、支持正则拒绝和临时暂停 watcher 的方案。
- 对一次性密码、私钥和令牌，继续使用密码管理器的自动输入，或显式使用 `wl-copy --paste-once` / `--sensitive`；不要仅依赖历史管理器过滤。
- 若继续用 cliphist，实施前应针对实际密码管理器做一次黑盒验证：复制测试秘密后确认历史中没有出现，而不是只检查配置文本。

## 推荐落地顺序

1. **先增强 cliphist 前端。** `Mod+V` 改为统一脚本入口，默认搜索/选择；用明确快捷键或二级确认菜单提供删除当前项与清空；复用现有图片预览逻辑。这个阶段不迁移数据库，也不增加 daemon。
2. **加容量和隐私策略。** 将 `max-items` 从默认/当前 750 调整到更符合使用习惯的值；清理旧的 50 MiB 数据库前先确认；补敏感剪贴板测试。
3. **若仍嫌脚本交互局促，再试 Clipcat。** 本机已经安装并有旧配置，可在不改仓库的临时会话里启动，重点验证 Wayland 图片、Rofi 删除、焦点和密码管理器行为。满意后再把不含 snippets 的公共配置放进 Stow 包。
4. **需要大图预览或完整历史浏览时选 cliphist-tui/Clipse。** 复用历史优先 `cliphist-tui`；接受迁移到独立后端时再选 Clipse。
5. **CopyQ 作为重型备选。** 适合确实需要编辑、多标签、复杂规则和托盘 GUI 的情况，不建议只为“删除/清空”这两个动作引入。

## 主要一手来源

- [cliphist 官方仓库](https://github.com/sentriz/cliphist)：命令、图片/二进制历史、数据库和 launcher 管道示例。
- [wl-clipboard 官方仓库与手册](https://github.com/bugaevc/wl-clipboard)：Wayland watcher、任意 MIME、`--sensitive`、`--paste-once` 和 `CLIPBOARD_STATE`。
- [Clipcat 官方仓库](https://github.com/xrelkd/clipcat)：图片、持久化、Wayland 状态、敏感 MIME/正则过滤及 Rofi/Fuzzel finder。
- [Clipse 官方仓库](https://github.com/savedra1/clipse)：TUI/listener 的功能与配置。
- [CopyQ 官方仓库](https://github.com/hluk/CopyQ) 与 [官方文档](https://copyq.readthedocs.io/)：GUI、命令、规则与历史管理。
- [gnuunixchad/dotfiles](https://github.com/gnuunixchad/dotfiles/blob/24873ac635a9ba22cc4147a2b948bde5abdbf8a2/.local/bin/clip)：cliphist 菜单与确认清空的具体 dotfiles 实例。
- [SHORiN-KiWATA/ShorinArchExperience-ArchlinuxGuide](https://github.com/SHORiN-KiWATA/ShorinArchExperience-ArchlinuxGuide/blob/85eb432e1241d995c4502af3ccec9320ff192bc6/wiki/archlinux/%E5%AE%89%E8%A3%85Niri.md#%E5%89%AA%E8%B4%B4%E6%9D%BF)：Niri 下 Clipse、cliphist、Fuzzel 与 cliphist-tui 的具体配置。

## 未在本次做的事

- 没有重启当前剪贴板 watcher；Rofi 和 Niri 会直接读取已链接的配置。
- 没有删除或迁移任何剪贴板历史。
- 没有把真实 `$HOME` 中的 Clipcat snippets 写入仓库。
