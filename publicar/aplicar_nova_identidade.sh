#!/bin/bash
# aplicar_nova_identidade.sh
# Aplica o novo design ao catálogo preservando todas as fotos do deploy atual
set -e

SCRIPT_DIR="$( cd "$(dirname "$0")" && pwd )"
TEMPLATE="$SCRIPT_DIR/design-template.html"
CATALOGO_DIR=~/Desktop/LG\ Consultoria/Alinhagem\ Móveis/Catálogo

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  A Linhagem — Aplicar Nova Identidade Visual"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# 1. Verifica se template existe
if [ ! -f "$TEMPLATE" ]; then
  echo "ERRO: design-template.html não encontrado em $SCRIPT_DIR"
  exit 1
fi
echo "✓ Template encontrado"

# 2. Entra na pasta do catálogo
cd "$CATALOGO_DIR"
echo "✓ Pasta: $(pwd)"

# 3. Atualiza do git
git pull --quiet
echo "✓ Git atualizado"

# 4. Extrai ALL_PHOTOS + merge com novo design via Python
python3 - "$TEMPLATE" <<'PYEOF'
import sys, re

template_path = sys.argv[1]

# Lê o index.html atual (com as fotos)
with open('index.html', 'r', encoding='utf-8') as f:
    current = f.read()

# Extrai o array ALL_PHOTOS completo
match = re.search(r'const ALL_PHOTOS\s*=\s*(\[.*?\])\s*;', current, re.DOTALL)
if not match:
    print("ERRO: ALL_PHOTOS não encontrado no index.html atual", file=sys.stderr)
    sys.exit(1)

photos_array = match.group(1)
count = photos_array.count('"src"')
print(f"  Extraídas {count} fotos do index.html atual")

# Lê o novo template de design
with open(template_path, 'r', encoding='utf-8') as f:
    template = f.read()

# Substitui o placeholder pelo array real de fotos
new_html = template.replace(
    'const ALL_PHOTOS=[];',
    f'const ALL_PHOTOS={photos_array};'
)

if f'const ALL_PHOTOS={photos_array};' not in new_html:
    print("ERRO: não foi possível injetar as fotos no template", file=sys.stderr)
    sys.exit(1)

# Salva o novo index.html
with open('index.html', 'w', encoding='utf-8') as f:
    f.write(new_html)

print(f"  index.html gerado: {len(new_html):,} bytes com {count} fotos")
PYEOF

echo "✓ Novo design aplicado com fotos preservadas"

# 5. Commit e push
git add index.html
git commit -m "Nova identidade visual: logo SVG fingerprint, hero premium, design refinado"
git push
echo "✓ Push para GitHub concluído"
echo ""
echo "✅ Pronto! Coolify vai redeploy automaticamente em ~30s"
echo "   Acesse: https://linhagem.lgtech.io"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
