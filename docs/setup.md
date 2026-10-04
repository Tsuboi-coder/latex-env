# LaTeX 実行環境のセットアップ

このリポジトリは、Docker 上の TeX Live / LuaLaTeX、`latexmk`、Python、Pygments を提供します。独自スタイルは含まず、`latex-env` だけで基本的な文書をビルドできます。

## 前提条件

- Git
- Docker Desktop（macOS / Windows）または Docker Engine（Linux）
- Visual Studio Code と LaTeX Workshop（エディターからビルドする場合のみ）

ホスト側への MacTeX や TeX Live のインストールは不要です。Windows では Docker Desktop の WSL 2 バックエンドを有効にし、WSL のシェルから補助スクリプトを実行してください。

## 1. 取得とイメージのビルド

```shell
git clone https://github.com/Tsuboi-coder/latex-env.git
cd latex-env
docker build -t kazuma-latex:2026 .
```

イメージ名を変える場合は、ビルド時のタグと実行時の `LATEX_IMAGE` を一致させます。

```shell
docker build -t my-latex:2026 .
export LATEX_IMAGE=my-latex:2026
```

`scripts/latexmk-docker` の既定値は `kazuma-latex:2026` です。

## 2. 基本環境の確認

```shell
docker run --rm kazuma-latex:2026 lualatex --version
docker run --rm kazuma-latex:2026 latexmk --version

cd test
../scripts/latexmk-docker -lualatex 1_lualatex_basic.tex
../scripts/latexmk-docker -lualatex -shell-escape 3_minted_python.tex
cd ..
```

`1_lualatex_basic.pdf` と `3_minted_python.pdf` が生成または更新されれば、基本環境は利用できます。`minted` を使う文書には `-shell-escape` が必要です。信頼できない文書には付けないでください。

## 3. 独自スタイルを使う（任意）

独自スタイルは別リポジトリの [`latex-styles`](https://github.com/Tsuboi-coder/latex-styles) で管理します。利用する場合だけクローンし、その `texmf` ディレクトリを環境変数で指定します。

```shell
git clone https://github.com/Tsuboi-coder/latex-styles.git "$HOME/latex-styles"
export LATEX_STYLES_ROOT="$HOME/latex-styles/texmf"
```

現在の配置例では次の値です。

```shell
export LATEX_STYLES_ROOT="$HOME/Documents/Repository/latex-styles/texmf"
```

補助スクリプトは、指定されたディレクトリをコンテナの `/root/texmf` へ読み取り専用でマウントします。未設定ならマウントせず、不正なパスなら誤設定を表示して終了します。

```shell
./scripts/latexmk-docker -lualatex path/to/document.tex
```

設定値は [`.env.example`](../.env.example) を参照してください。このファイルは説明用であり、補助スクリプトが `.env` を自動で読み込むことはありません。シェルの設定ファイルなどから環境変数を `export` してください。

スタイルが見えるかは次のように確認できます。

```shell
docker run --rm \
  -v "$LATEX_STYLES_ROOT:/root/texmf:ro" \
  "${LATEX_IMAGE:-kazuma-latex:2026}" \
  kpsewhich bookmacro-lua.sty
```

## macOS のシステムフォント

macOS では `/System/Library/Fonts` が存在するときだけ、補助スクリプトが `/host-fonts/system` へ読み取り専用でマウントします。フォントファイルをリポジトリやイメージへコピーすることはありません。ヒラギノを使うスタイルの必要ファイルと確認方法は、`latex-styles` の `docs/hiragino-fonts.md` を参照してください。

Linux / WSL ではこのマウントを省略します。ヒラギノを要求しない文書とスタイルは同じ補助スクリプトで利用できます。

## Visual Studio Code

LaTeX Workshop のユーザー設定に次を追加します。`command` は実際にクローンした場所の絶対パスへ変更してください。

```json
{
  "latex-workshop.latex.tools": [
    {
      "name": "docker-lualatex",
      "command": "/absolute/path/to/latex-env/scripts/latexmk-docker",
      "args": [
        "-lualatex",
        "-shell-escape",
        "-synctex=1",
        "-interaction=nonstopmode",
        "-file-line-error",
        "%DOCFILE_EXT%"
      ]
    }
  ],
  "latex-workshop.latex.recipes": [
    {
      "name": "Docker LuaLaTeX",
      "tools": ["docker-lualatex"]
    }
  ],
  "latex-workshop.latex.recipe.default": "first"
}
```

GUI から起動した Visual Studio Code はシェルの環境変数を引き継がない場合があります。その場合は、ターミナルから `code` を起動するか、LaTeX Workshop のツール設定で環境変数を渡してください。

## 日常的な使い方

```shell
./scripts/latexmk-docker -lualatex path/to/document.tex
./scripts/latexmk-docker -c path/to/document.tex  # 中間ファイルを削除
./scripts/latexmk-docker -C path/to/document.tex  # PDF を含む生成物を削除
```

補助スクリプトは実行時のカレントディレクトリを `/work` に割り当てます。文書のあるディレクトリから、補助スクリプトを絶対パスまたは相対パスで呼び出してください。

## トラブルシューティング

### Docker デーモンに接続できない

Docker Desktop または Docker Engine が起動していることを確認してください。

### Docker イメージが見つからない

イメージをビルドし、必要なら `LATEX_IMAGE` をビルド時のタグへ設定してください。

### 独自スタイルが見つからない

`LATEX_STYLES_ROOT` が `texmf/tex/latex/...` を含む TEXMF ルートを指すことを確認し、上記の `kpsewhich` で切り分けてください。

### Linux / WSL で生成物が root 所有になる

コンテナは既定ユーザーで処理するため、生成ファイルが root 所有になることがあります。単純な `--user` の追加では LuaLaTeX のフォントキャッシュが書き込めなくなる場合があるため、生成先とキャッシュの双方を非 root ユーザーが書き込める構成が必要です。

## 再現性について

現在の `Dockerfile` は `texlive/texlive:latest` を基にしているため、ビルド時期によって TeX Live の内容が変わる可能性があります。安定版を切る際はベースイメージを固定し、`latex-env` と、それに対してテストした `latex-styles` の組み合わせをタグで記録してください。
