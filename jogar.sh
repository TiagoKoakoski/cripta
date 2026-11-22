#!/usr/bin/env bash
# Abre a Cripta em tela cheia. Esc sai do jogo.
set -euo pipefail
cd "$(dirname "$0")"
exec godot --path . --fullscreen "$@"
