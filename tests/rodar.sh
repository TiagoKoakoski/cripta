#!/usr/bin/env bash
# Roda todos os testes headless. Sai com erro se qualquer um falhar.
set -uo pipefail
cd "$(dirname "$0")/.."
godot --headless --path . --import >/dev/null 2>&1
falhas=0
for t in tests/teste_*.gd; do
  saida=$(timeout 300 godot --headless --path . --script "res://$t" 2>&1)
  cod=$?
  echo "$saida" | grep -E "Resultado|FALHOU|SCRIPT ERROR|Parse Error" | sed "s|^|$(basename $t): |"
  [ $cod -ne 0 ] && falhas=$((falhas + 1))
done
echo "== arquivos de teste com falha: $falhas"
exit $falhas
