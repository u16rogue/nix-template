#!/usr/bin/env bash

BWRAP_ARGS+=( \
    --hostname "devshell-$HOSTNAME" \
)

if command -v "fish" &> /dev/null; then
    BWRAP_ARGS+=(--setenv SHELL "$(which fish)")
    if [[ -e ~/.config/fish ]]; then
        BWRAP_ARGS+=(--ro-bind ~/.config/fish ~/.config/fish)
    fi
fi

if command -v "zellij" &> /dev/null; then
    PROGRAM="$(which zellij)"
    if [[ -e ~/.config/zellij ]]; then
        BWRAP_ARGS+=(--ro-bind ~/.config/zellij ~/.config/zellij)
    fi

    if [[ -f "$PWD/.zellij.kdl" ]]; then
        PROGRAM_ARGS="$PROGRAM_ARGS --layout .zellij.kdl"
    fi

    if [[ -n "$PROGRAM_ARGS" ]]; then
        PROGRAM="$PROGRAM -- $PROGRAM_ARGS"
    fi
fi
