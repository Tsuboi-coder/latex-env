# latex-env

Docker 上の TeX Live / LuaLaTeX と、リポジトリで共有する `texmf` を利用する LaTeX 環境です。セットアップ方法は [docs/setup.md](docs/setup.md) を参照してください。

## テスト文書

`test/` の文書は、次の順に環境の機能を確認します。

| ファイル | 検証する役割 |
| --- | --- |
| `1_lualatex_basic.tex` | LuaLaTeX による日本語・英語の基本組版 |
| `2_shared_style_math.tex` | 共有 `texmf` の独自スタイル、数式、化学式 |
| `3_minted_python.tex` | `minted`、Python、Pygments、`shell-escape` |
| `4_hiragino_document.tex` | 通常文書用ヒラギノプリセットと Helvetica Neue |
| `5_hiragino_beamer.tex` | Beamer 用ヒラギノプリセット、太字、数式 |

基本環境の確認方法は [docs/setup.md](docs/setup.md#4-動作確認)、macOS フォントの準備と確認方法は [docs/hiragino-fonts.md](docs/hiragino-fonts.md) に記載しています。
