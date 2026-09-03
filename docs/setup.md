# LaTeX 実行環境のセットアップ

この文書では、新しい PC に本リポジトリの Docker ベース LaTeX 環境をセットアップする方法を説明します。

セットアップの流れは次のとおりです。

1. Git、Docker、必要に応じて Visual Studio Code をインストールする
2. リポジトリをクローンし、Docker イメージをビルドする
3. macOS では、必要に応じてシステムフォントを Docker と共有する
4. Docker 内の LaTeX と共有 `texmf` を確認する
5. テスト文書をコンパイルする
6. Visual Studio Code を使用する場合は LaTeX Workshop を設定する

すべての動作確認が成功すれば、ホスト側に MacTeX や TeX Live を導入せずに執筆環境を利用できます。

## 前提条件

あらかじめ、次のソフトウェアをインストールしてください。

- Git
- Docker
  - macOS / Windows: Docker Desktop
  - Linux: Docker Engine
- Visual Studio Code（エディターからビルドする場合）
- Visual Studio Code 拡張機能 LaTeX Workshop（同上）

ホスト側に MacTeX や TeX Live をインストールする必要はありません。LaTeX の実行環境は Docker イメージ内に用意されます。

インストール後、ターミナルで次のコマンドが成功することを確認します。

```shell
git --version
docker --version
docker run --rm hello-world
```

Docker Desktop を使用する場合は、以降の操作を始める前に Docker Desktop を起動してください。

## 1. リポジトリの取得

任意の作業用ディレクトリで、リポジトリをクローンします。

```shell
git clone https://github.com/Tsuboi-coder/latex-env.git
cd latex-env
```

## 2. Docker イメージのビルド

リポジトリのルートディレクトリで次のコマンドを実行します。

```shell
docker build -t kazuma-latex:2026 .
```

この処理では TeX Live のイメージを取得し、フォント関連のツール、Python、および Pygments を追加します。初回はイメージのダウンロードに時間とディスク容量が必要です。

ビルド後、イメージが作成されたことを確認します。

```shell
docker image ls kazuma-latex:2026
```

## 3. 補助スクリプトの確認

`scripts/latexmk-docker` はスクリプト自身の位置からリポジトリのルートと `texmf` ディレクトリを特定します。そのため、クローン先に応じたパスの書き換えは不要です。

補助スクリプトに実行権限があることを確認します。権限がない場合は付与してください。

```shell
chmod +x scripts/latexmk-docker
```

> [!NOTE]
> 補助スクリプトは、実行時のカレントディレクトリをコンテナの `/work` に割り当てます。通常はリポジトリのルートディレクトリから実行してください。

## 4. 動作確認

まず、LuaLaTeX と latexmk が Docker イメージ内で実行できることを確認します。これらを `docker run` 経由で呼び出すことで、ホスト側の TeX 環境を誤って使用していないことも確認できます。

```shell
docker run --rm kazuma-latex:2026 lualatex --version
docker run --rm kazuma-latex:2026 latexmk --version
```

次に、独自スタイルがコンテナから見えることを確認します。リポジトリのルートディレクトリで実行してください。

```shell
docker run --rm \
  -v "$(pwd)/texmf:/root/texmf:ro" \
  kazuma-latex:2026 \
  kpsewhich teststyle.sty
```

次のパスが表示されれば、`texmf` のマウントは成功しています。

```text
/root/texmf/tex/latex/style/teststyle.sty
```

最後に、LuaLaTeX を使って基本機能を段階的に確認する3つのテスト文書をコンパイルします。`3_minted_python.tex` では `minted` が外部プログラムの Pygments を実行するため、`-shell-escape` が必要です。

```shell
cd test
../scripts/latexmk-docker -lualatex 1_lualatex_basic.tex
../scripts/latexmk-docker -lualatex 2_shared_style_math.tex
../scripts/latexmk-docker -lualatex -shell-escape 3_minted_python.tex
cd ..
```

次の PDF が生成または更新されれば、セットアップは完了です。

- `test/1_lualatex_basic.pdf`: LuaLaTeX による日本語・英語の基本組版
- `test/2_shared_style_math.pdf`: 共有 `texmf` のスタイル読み込み、数式、化学式
- `test/3_minted_python.pdf`: `minted`、Python、Pygments、`shell-escape`

ここまで成功すれば、TeX Live、LuaLaTeX、独自スタイル、Python、Pygments、および `minted` が Docker 内で利用できています。

## 5. Visual Studio Code の設定

Visual Studio Code からコンパイルする場合は、LaTeX Workshop をインストールし、ユーザー設定の `settings.json` に次の設定を追加します。既存の設定がある場合は、外側の `{}` を重複させず、該当するプロパティを追加してください。

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
      "tools": [
        "docker-lualatex"
      ]
    }
  ],
  "latex-workshop.latex.recipe.default": "first"
}
```

`command` は、クローンしたリポジトリ内にある `scripts/latexmk-docker` の絶対パスに変更してください。ターミナルで次のコマンドを実行するとパスを確認できます。

```shell
cd latex-env
pwd
```

たとえば `pwd` が `/Users/example/latex-env` を返した場合、`command` は `/Users/example/latex-env/scripts/latexmk-docker` です。これは Visual Studio Code が任意の文書ディレクトリから補助スクリプトを呼び出せるようにするための設定であり、補助スクリプト自体や `texmf` のパスを書き換える必要はありません。

> [!IMPORTANT]
> 文書の引数には拡張子を含む `%DOCFILE_EXT%` を使用します。`%DOC%` に変更すると、環境や文書によって正しくビルドできない場合があります。

設定後、LaTeX Workshop のレシピから `Docker LuaLaTeX` を選択して文書をビルドします。このレシピには `-shell-escape` が含まれるため、`minted` を使用する文書もコンパイルできます。信頼できない LaTeX 文書には使用しないでください。

## 日常的な使い方

コンパイル対象の `.tex` ファイルを指定して、補助スクリプトを実行します。

```shell
./scripts/latexmk-docker -lualatex path/to/document.tex
```

生成された中間ファイルを削除する場合は、次のように実行します。

```shell
./scripts/latexmk-docker -c path/to/document.tex
```

PDF を含む生成物をすべて削除する場合は `-C` を使用します。

```shell
./scripts/latexmk-docker -C path/to/document.tex
```

## 独自スタイルの追加

独自の `.sty` ファイルは、次のディレクトリ以下に配置します。

```text
texmf/tex/latex/
```

このディレクトリはコンテナ内の `/root/texmf` に読み取り専用でマウントされます。たとえば `texmf/tex/latex/style/example.sty` を追加すると、LaTeX 文書から次のように読み込めます。

```tex
\usepackage{example}
```

## Docker イメージの更新

`Dockerfile` を変更した場合や、ベースとなる TeX Live イメージを更新したい場合は、再度ビルドします。

```shell
docker build --pull -t kazuma-latex:2026 .
```

## フォントについて

macOS のヒラギノと Helvetica Neue を利用する設定に対応しています。フォントファイルはライセンスと環境依存性を考慮し、このリポジトリへのコミットや Docker イメージへのコピーを行いません。ホストの `/System/Library/Fonts` をコンテナへ読み取り専用でマウントします。

新しい Mac では Docker Desktop の共有設定、実際のフォントファイル名、および専用テスト文書を確認する必要があります。詳しい手順、スタイルの使い分け、管理範囲、トラブルシューティングは [macOS のヒラギノフォントを Docker から利用する](hiragino-fonts.md) を参照してください。

## トラブルシューティング

### Docker デーモンに接続できない

`Cannot connect to the Docker daemon` などと表示される場合は、Docker Desktop または Docker Engine が起動していることを確認してください。

### `Unable to find image 'kazuma-latex:2026' locally` と表示される

Docker イメージが未作成です。「Docker イメージのビルド」の手順を実行してください。

### 独自スタイルが見つからない

次の点を確認してください。

- リポジトリ内に `texmf` ディレクトリが存在する
- `.sty` ファイルが `texmf/tex/latex/` 以下に置かれている
- ファイル名と `\usepackage{...}` の名前が一致している

コンテナからスタイルファイルが見えるかは、次のコマンドで確認できます。

```shell
docker run --rm \
  -v "$(pwd)/texmf:/root/texmf:ro" \
  kazuma-latex:2026 \
  kpsewhich teststyle.sty
```

### `minted` のコンパイルに失敗する

`minted` を使用する文書には `-shell-escape` が必要です。

```shell
./scripts/latexmk-docker -lualatex -shell-escape path/to/document.tex
```

それでも失敗する場合は、`test/3_minted_python.tex` をコンパイルし、Docker イメージ内の Python・Pygments を含む共通環境に問題がないか切り分けてください。

### Linux で生成物の所有者が root になる

現在の補助スクリプトはコンテナの既定ユーザーで処理を実行します。そのため、Linux では生成ファイルが root 所有になることがあります。必要に応じて、Docker の `--user` オプションでホスト側のユーザー ID とグループ ID を渡す運用を検討してください。

## 現在の注意事項

- Docker イメージ名とタグ `kazuma-latex:2026` は、`scripts/latexmk-docker` とビルドコマンドで一致させる必要があります。
- `scripts/latexmk-docker` は macOS の `/System/Library/Fonts` をマウントするため、現状のスクリプトは macOS 固有です。
- `texlive/texlive:latest` を使用しているため、異なる時期にビルドすると TeX Live の内容が変わる可能性があります。
- 環境が安定した段階で、Dockerfile の TeX Live イメージを固定タグへ変更し、リポジトリにもバージョンタグを付けると再現性を高められます。
- 補助スクリプトは Bash を使用するため、Windows では WSL などの Bash 環境が必要です。
