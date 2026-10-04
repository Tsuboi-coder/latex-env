# latex-env

再現可能な Docker ベースの LuaLaTeX ビルド環境です。TeX Live、`latexmk`、Python、Pygments を提供し、独自スタイルがなくても単独で利用できます。

独自スタイルは別リポジトリの [`latex-styles`](https://github.com/Tsuboi-coder/latex-styles) で管理します。必要な場合だけ `LATEX_STYLES_ROOT` でその TEXMF ツリーをマウントします。依存方向は `latex-styles` から本環境への一方向です。

```shell
docker build -t latex-env:2026 .
export LATEX_STYLES_ROOT="$HOME/Documents/Repository/latex-styles/texmf" # 任意
./scripts/latexmk-docker -lualatex path/to/document.tex
```

イメージ名は `LATEX_IMAGE` で変更できます。設定例は [`.env.example`](.env.example)、詳しい導入・検証方法は [docs/setup.md](docs/setup.md) を参照してください。

## 環境テスト

`test/` には環境だけで完結するテストを置いています。

| ファイル | 検証する役割 |
| --- | --- |
| `1_lualatex_basic.tex` | LuaLaTeX による日本語・英語の基本組版 |
| `3_minted_python.tex` | `minted`、Python、Pygments、`shell-escape` |

スタイル固有のテストとサンプルは `latex-styles` 側にあります。

## ライセンス

このプロジェクトは [MIT License](LICENSE) のもとで公開しています。
