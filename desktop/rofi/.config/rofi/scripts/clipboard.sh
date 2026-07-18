#!/usr/bin/env bash

tmp_dir="/tmp/cliphist"
retv="${ROFI_RETV:-0}"
data="${ROFI_DATA:-}"
selected="${1:-}"
confirm_wipe="确认清空全部历史"
cancel_wipe="取消"

print_header() {
    local state="${1:-}"

    printf '\0prompt\x1f剪贴板\n'
    printf '\0message\x1fEnter: 复制  Shift+Delete: 删除  Ctrl+Shift+Delete: 清空\n'
    printf '\0no-custom\x1ftrue\n'
    printf '\0use-hot-keys\x1ftrue\n'
    [[ -n "$state" ]] && printf '\0data\x1f%s\n' "$state"
}

print_history() {
    local history prog

    rm -rf "$tmp_dir"
    mkdir -p "$tmp_dir"
    print_header

    history="$(cliphist list)"
    if [[ -z "$history" ]]; then
        printf '剪贴板历史为空\0nonselectable\x1ftrue\n'
        return
    fi

    read -r -d '' prog <<EOF
/^[0-9]+\s<meta http-equiv=/ { next }
match(\$0, /^([0-9]+)\s(\[\[\s)?binary.*(jpg|jpeg|png|bmp)/, grp) {
    system("echo " grp[1] "\\\\\t | cliphist decode >$tmp_dir/"grp[1]"."grp[3])
    print \$0"\0icon\x1f$tmp_dir/"grp[1]"."grp[3]
    next
}
1
EOF
    printf '%s\n' "$history" | gawk "$prog"
}

print_wipe_confirmation() {
    print_header "confirm-wipe"
    printf '\0message\x1f此操作会永久删除全部剪贴板历史\n'
    printf '%s\0urgent\x1ftrue\n' "$confirm_wipe"
    printf '%s\n' "$cancel_wipe"
}

if [[ "$data" == "confirm-wipe" ]]; then
    if [[ "$retv" == "1" && "$selected" == "$confirm_wipe" ]]; then
        cliphist wipe
        exit
    fi

    if [[ "$retv" == "1" && "$selected" == "$cancel_wipe" ]]; then
        print_history
        exit
    fi

    print_wipe_confirmation
    exit
fi

case "$retv" in
    1)
        [[ -n "$selected" ]] && cliphist decode <<<"$selected" | wl-copy
        ;;
    3)
        if [[ -n "$selected" ]]; then
            printf '%s\n' "$selected" | cliphist delete
        fi
        print_history
        ;;
    10)
        print_wipe_confirmation
        ;;
    *)
        print_history
        ;;
esac
