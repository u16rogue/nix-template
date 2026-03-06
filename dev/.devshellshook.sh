#!/usr/bin/env bash

BWRAP_ARGS+=(--hostname "devshell-$HOSTNAME")

if command -v fish &> /dev/null; then
    BWRAP_ARGS+=(--setenv SHELL "$(which fish)")
    [[ -e ~/.config/fish ]] && BWRAP_ARGS+=(--ro-bind ~/.config/fish ~/.config/fish)
fi

if command -v zellij &> /dev/null; then
    PROGRAM="$(which zellij)"
    PROGRAM_ARGS=()
    [[ -e ~/.config/zellij ]] && BWRAP_ARGS+=(--ro-bind ~/.config/zellij ~/.config/zellij)
    [[ -f "$PWD/.zellij.kdl" ]] && PROGRAM_ARGS+=(--layout .zellij.kdl)
    PROGRAM_ARGS+=(attach --create "dflt")
fi
