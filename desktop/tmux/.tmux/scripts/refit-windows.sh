#!/bin/sh

tmux list-windows -a -F '#{window_id}' |
while IFS= read -r window_id; do
    tmux resize-window -A -t "$window_id"
    tmux set-window-option -u -t "$window_id" window-size
done
