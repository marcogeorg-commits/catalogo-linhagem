"""Tira as fotos de dentro do index.html e grava cada uma como arquivo WebP.

Roda na montagem da imagem (Dockerfile), então o index.html continua podendo vir
com as fotos embutidas: basta trocá-lo e dar push.

Para cada foto embutida grava duas versões, com nome pelo conteúdo (cache eterno
no navegador sem risco de mostrar foto velha):
  fotos/<hash>.webp    grande, até 900 px, para a foto aberta
  fotos/p/<hash>.webp  pequena, 420 px de largura, para a grade

Uso: python separar_fotos.py index.html PASTA_DE_SAIDA
"""
import base64
import hashlib
import io
import re
import sys
from pathlib import Path

from PIL import Image

GRANDE = 900
PEQUENA = 420

FOTO = re.compile(r'"src":\s*"data:image/[a-z+]+;base64,([A-Za-z0-9+/=]+)"')

# Ajustes no código da página: a grade usa a versão pequena e a foto aberta
# já deixa a anterior e a próxima carregando (o deslizar no celular fica imediato).
TROCAS = [
    ('<img src="${p.src}" alt="${p.desc}" loading="lazy"/>',
     '<img src="${p.thumb||p.src}" alt="${p.desc}" loading="lazy" decoding="async"/>'),
    ("document.getElementById('lbImg').src=p.src;",
     "document.getElementById('lbImg').src=p.src;"
     "[1,-1].forEach(d=>{const n=visiblePhotos[(lbIndex+d+visiblePhotos.length)%visiblePhotos.length];"
     "if(n)new Image().src=n.src;});"),
]


def gravar(img, caixa, destino, qualidade):
    img = img.copy()
    img.thumbnail(caixa)  # só reduz, nunca aumenta
    img.save(destino, "WEBP", quality=qualidade, method=6)


def main(entrada, saida):
    html = Path(entrada).read_text(encoding="utf-8")
    saida = Path(saida)
    (saida / "fotos" / "p").mkdir(parents=True, exist_ok=True)

    def trocar(m):
        dados = base64.b64decode(m.group(1))
        nome = hashlib.sha256(dados).hexdigest()[:12] + ".webp"
        img = Image.open(io.BytesIO(dados)).convert("RGB")
        gravar(img, (GRANDE, GRANDE), saida / "fotos" / nome, 80)
        gravar(img, (PEQUENA, 10_000), saida / "fotos" / "p" / nome, 72)
        return f'"src": "fotos/{nome}", "thumb": "fotos/p/{nome}"'

    html, quantas = FOTO.subn(trocar, html)
    for antes, depois in TROCAS:
        if antes in html:
            html = html.replace(antes, depois)
        else:
            print(f"aviso: trecho não encontrado, ajuste pulado: {antes[:50]}...")

    (saida / "index.html").write_text(html, encoding="utf-8")
    total = sum(f.stat().st_size for f in (saida / "fotos").rglob("*.webp"))
    print(f"{quantas} fotos separadas; index.html {len(html.encode()) // 1024} KB; "
          f"fotos {total // 1024} KB no total")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
