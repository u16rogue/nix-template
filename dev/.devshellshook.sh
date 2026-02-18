#!/usr/bin/env bash

USE_SHELL="$(which fish)"
PROGRAM="$(which zellij)"
PROGRAM_ARGS=""

BWRAP_ARGS+=( \
    --hostname "devshell-$HOSTNAME"
    --ro-bind ~/.config/fish ~/.config/fish \
    --ro-bind ~/.config/zellij ~/.config/zellij \
    --setenv SHELL "$USE_SHELL" \
)

if [[ -f ".zellij.kdl" ]]; then
    PROGRAM_ARGS="$PROGRAM_ARGS --layout .zellij.kdl"
fi

if [[ -n "$PROGRAM_ARGS" ]]; then
    PROGRAM="$PROGRAM -- $PROGRAM_ARGS"
fi

