#!/usr/bin/env bash
# Gera (com o Nano Banana, via gemini-imagem) toda imagem de prompts.json que ainda não está em originais/.
# Para no limite diário (exit 4) ou deslogado (exit 2). Log em gerar.log.
cd "$(dirname "$0")"
for nome in $(python3 -c 'import json;print("\n".join(json.load(open("prompts.json"))))'); do
  [ -f "originais/$nome.jpg" ] && continue
  prompt=$(python3 -c "import json,sys;print(json.load(open('prompts.json'))[sys.argv[1]])" "$nome")
  echo "== $nome $(date +%H:%M:%S)" >> gerar.log
  saida=$(timeout 240 gemini-imagem "$prompt" "originais/$nome.png" 2>&1); cod=$?
  echo "$saida" | tail -2 >> gerar.log
  if [ $cod -eq 2 ] || [ $cod -eq 4 ]; then echo "PAROU ($cod) em $nome" >> gerar.log; exit $cod; fi
  # guarda em JPEG reduzido (1376 px de largura): sobra resolução para a pixelização e o repo fica leve
  ~/Projetos/jogos/_ferramentas/venv/bin/python - "originais/$nome.png" <<'PY'
import sys
from PIL import Image
im = Image.open(sys.argv[1]).convert("RGB")
im.thumbnail((1376, 9999))
im.save(sys.argv[1][:-4] + ".jpg", quality=90)
PY
  rm -f "originais/$nome.png"
done
echo "FIM $(date +%H:%M:%S)" >> gerar.log
