# 提示词设置
set -g __fish_config_start_time (date +%s%3N)

function fish_greeting
    set -l host (hostname 2>/dev/null)
    set -l distro "Unknown distro"
    set -l uptime_text

    if test -r /etc/os-release
        for distro_key in PRETTY_NAME NAME ID
            set -l distro_line (string match -r "^$distro_key=.*" </etc/os-release)
            if test -n "$distro_line"
                set distro (string trim -c '"' -- (string replace "$distro_key=" '' -- $distro_line))
                break
            end
        end
    end

    if type -q uptime
        set uptime_text (string trim -- (uptime -p 2>/dev/null))
    end

    set -l title "Welcome to $host"
    set -l divider_width (math (string length -- "$title") + 4)

    set_color blue
    printf "\n"
    printf "  ◆ "
    set_color brblue
    printf "%s\n" "$title"

    set_color blue
    printf "  %s\n" (string repeat -n $divider_width -- "━")

    set_color brblack
    printf "  %s" "$distro"
    if test -n "$uptime_text"
        printf "  •  %s" "$uptime_text"
    end

    if set -q __fish_config_start_time
        set -l now (date +%s%3N)
        set -l elapsed (math $now - $__fish_config_start_time)

        printf "  •  Fish %sms" "$elapsed"
        set -e __fish_config_start_time
    end
    printf "\n"
    set_color normal
end

# Keep non-interactive Fish free of inherited man-pager tweaks.
# Interactive shells re-enable batman below when available.
set -e MANPAGER MANROFFOPT

# Keep Arch system commands ahead of Anaconda-provided shims.
set -l anaconda_bin /opt/anaconda/bin
set -l reordered_path
for path_entry in $PATH
    if test "$path_entry" != "$anaconda_bin"
        set -a reordered_path "$path_entry"
        if test "$path_entry" = /usr/bin
            set -a reordered_path "$anaconda_bin"
        end
    end
end
if not contains -- "$anaconda_bin" $reordered_path
    set -a reordered_path "$anaconda_bin"
end
set -gx PATH $reordered_path

if status is-interactive
    # 交互模式下的缩写
    abbr --add ex exit

    abbr --add cx codex
    abbr --add oc opencode
    abbr --add cl claude
    abbr --add clr 'claude --resume'
    abbr --add clc 'claude --continue'
    abbr --add cld 'claude --dangerously-skip-permissions'

    # hapi wrapper
    abbr --add hacx 'hapi codex'
    abbr --add haoc 'hapi opencode'
    abbr --add hacld 'hapi claude --dangerously-skip-permissions'
    abbr --add haclc 'hapi claude --continue'
    abbr --add haclr 'hapi claude --resume'

    abbr --add vi nvim
    abbr --add nv neovide
    abbr --add ls "eza --icons=auto --git --group-directories-first"
    abbr --add la "eza --icons=auto --git --group-directories-first -lha"
    abbr --add tm tmux
    abbr --add tmm "tmux new -A -s main"
    abbr --add tma "tmux attach -t"
    abbr --add archwiki "xdg-open /usr/share/doc/arch-wiki-zh-cn/html/zh-cn/首页.html"
    abbr --add lg lazygit
    abbr --add ff fastfetch
    abbr --add dev 'set dir $HOME/Programming/dev/; 
    cd (echo $dir(string join \n (echo ./) (fd --type directory --max-depth 1 --base-directory $dir) | fzf)) 2>/dev/null; 
    and nvim .'

    abbr --add learn 'set dir $HOME/Programming/learn/; 
    cd (echo $dir(string join \n (echo ./) (fd --type directory --max-depth 2 --base-directory $dir) | fzf)) 2>/dev/null; 
    and nvim .'
    # if type -q swallow
    #   abbr --add code "swallow code --wait"
    #   abbr --add nv "swallow neovide"
    # end
    # yazi 目录跳转
    function y
        set tmp (mktemp -t "yazi-cwd.XXXXXX")
        yazi $argv --cwd-file="$tmp"
        if set cwd (command cat -- "$tmp"); and [ -n "$cwd" ]; and [ "$cwd" != "$PWD" ]
            builtin cd -- "$cwd"
        end
        rm -f -- "$tmp"
    end
    # 初始化 zoxide
    if type -q zoxide
        zoxide init --cmd cd fish | source
    end

    # Let batman own man paging in interactive shells only.
    if type -q batman 
        batman --export-env | source
    end
    # 优化 thefuck 速度
    if type -q thefuck
        function fuck --wraps='thefuck' --description 'Correct previous command'
            thefuck $history[1] | source
        end
    end
    if type -q starship
        starship init fish | source
    end
end

bind \co accept-autosuggestion

# add the -g flag to show the group belonged
function ll --wraps=ls --description 'List contents of directory using long format'
    ls -lhg $argv
end

# pnpm
set -gx PNPM_HOME "/home/bdbd/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
