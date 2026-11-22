#!/usr/bin/env bash
# Abre a Cripta em tela cheia. Esc ou fechar a janela sai.
set -euo pipefail
cd "$(dirname "$0")"
exec godot --path . --fullscreen "$@"
