# macOS のヒラギノフォントを Docker から利用する

本リポジトリでは、TeX Live と LuaLaTeX を Docker コンテナ内で実行し、ヒラギノなどの macOS 標準フォントだけをホストから参照します。フォントファイルそのものは、ライセンスと環境依存性を考慮して Git リポジトリや Docker イメージには含めません。

この機能は macOS 専用です。ヒラギノを必要としない文書自体は、`hiragino-base` または `hiragino-slides` を読み込まなければ macOS 固有フォントに依存しません。ただし、現在の `scripts/latexmk-docker` は macOS のフォントディレクトリを常にマウントする実装のため、ほかの OS で同じスクリプトを使うにはマウントを任意化する変更が必要です。

## 構成

役割を次のように分離しています。

```text
TeX Live / LuaLaTeX       Docker image: kazuma-latex:2026
フォント設定              texmf/tex/latex/style/*.sty
macOS 標準フォント        host: /System/Library/Fonts
コンテナからの参照先      container: /host-fonts/system
LaTeX 文書                各プロジェクト
```

`scripts/latexmk-docker` は、ホストのフォントディレクトリを次のように読み取り専用でマウントします。

```text
/System/Library/Fonts:/host-fonts/system:ro
```

`ro` を指定しているため、コンテナからホストのシステムフォントが変更されることはありません。

## 新しい Mac でのセットアップ

### 1. 必要なフォントを確認する

ターミナルで次のコマンドを実行します。

```shell
ls "/System/Library/Fonts/ヒラギノ明朝 ProN.ttc" \
   "/System/Library/Fonts/ヒラギノ丸ゴ ProN W4.ttc" \
   "/System/Library/Fonts/ヒラギノ角ゴシック W6.ttc" \
   "/System/Library/Fonts/HelveticaNeue.ttc"
```

4ファイルすべてが表示されることを確認してください。macOS のバージョンによって配置や名前が変わる可能性があるため、ファイル名は推測せず、実際の `/System/Library/Fonts` を確認します。

> [!IMPORTANT]
> 現在の設定が参照する角ゴシックは `ヒラギノ角ゴシック W6.ttc` です。`ヒラギノ角ゴシック ProN W6.ttc` ではありません。

### 2. Docker Desktop にディレクトリを共有する

Docker Desktop の次の画面を開きます。

```text
Settings → Resources → File Sharing
```

`/System/Library/Fonts` を共有対象に追加し、必要に応じて **Apply & Restart** を実行します。

### 3. コンテナからフォントを確認する

Docker Desktop の再起動後、次のコマンドを実行します。

```shell
docker run --rm \
  -v "/System/Library/Fonts:/host-fonts/system:ro" \
  kazuma-latex:2026 \
  ls "/host-fonts/system/ヒラギノ明朝 ProN.ttc" \
     "/host-fonts/system/ヒラギノ丸ゴ ProN W4.ttc" \
     "/host-fonts/system/ヒラギノ角ゴシック W6.ttc" \
     "/host-fonts/system/HelveticaNeue.ttc"
```

これにより、Docker の共有設定とファイル名を同時に確認できます。

### 4. テスト文書をコンパイルする

リポジトリのルートから `test/` に移動し、次を実行します。ラッパーはカレントディレクトリをコンテナの作業ディレクトリにするため、これによりPDFも `test/` に生成されます。

```shell
cd test
../scripts/latexmk-docker -lualatex 4_hiragino_document.tex
../scripts/latexmk-docker -lualatex 5_hiragino_beamer.tex
cd ..
```

次の PDF を目視し、日本語と欧文のフォント、およびスライド内の数式が正しく表示されることを確認します。

- `test/4_hiragino_document.pdf`: 通常文書用プリセットの明朝、角ゴシック、Helvetica Neue
- `test/5_hiragino_beamer.pdf`: スライド用プリセットの丸ゴシック、太字、Helvetica Neue、数式

## 文書からの利用方法

通常のレポートや論文では次を読み込みます。

```tex
\usepackage{hiragino-base}
```

設定されるフォントは次のとおりです。

- 日本語本文: ヒラギノ明朝 ProN
- 日本語サンセリフ: ヒラギノ角ゴシック W6
- 欧文サンセリフ: Helvetica Neue

Beamer スライドでは次を読み込みます。

```tex
\usepackage{hiragino-slides}
```

設定されるフォントは次のとおりです。

- 日本語本文: ヒラギノ丸ゴ ProN W4
- 日本語太字: ヒラギノ角ゴシック W6
- 欧文本文: Helvetica Neue
- 数式: serif

Beamer の数式だけを serif にする設定は `\usefonttheme[onlymath]{serif}` です。`\usefonttheme[onlymath]{mathserif}` を指定すると、存在しない `beamerfontthememathserif.sty` を探すためエラーになります。

スタイルは family name の自動検索に頼らず、`/host-fonts/system/` と実際の `.ttc` ファイル名を指定しています。設定を変更する場合は、次のファイルを編集します。

- `texmf/tex/latex/style/hiragino-base.sty`
- `texmf/tex/latex/style/hiragino-slides.sty`

## リポジトリで管理する範囲

フォントの参照方法を再現できるよう、次のものは Git で管理します。

- `scripts/latexmk-docker` の読み取り専用マウント設定
- `hiragino-base.sty` と `hiragino-slides.sty`
- `test/4_hiragino_document.tex` と `test/5_hiragino_beamer.tex`
- このセットアップ手順

一方、`.ttc`、`.ttf`、`.otf` などのフォントファイルはコピー、コミット、Docker イメージへの組み込みを行いません。各 Mac に正規にインストールされているファイルを、その Mac 上でのみマウントして利用します。

## トラブルシューティング

### `mounts denied` と表示される

`/System/Library/Fonts` が Docker Desktop の **Settings → Resources → File Sharing** に登録されているか確認し、Docker Desktop を再起動します。

### `fontspec Error: The font ... cannot be found` と表示される

次の順で確認します。

1. `/System/Library/Fonts` がコンテナへマウントされている
2. `/host-fonts/system` から対象ファイルを読み取れる
3. `.sty` に記載された名前と実際のファイル名が完全に一致する

family name とファイル名は異なる場合があります。本環境では、`.sty` に実ファイル名を記載します。

### macOS の更新後にコンパイルできない

macOS の更新によってフォントの配置や名前が変わっていないか確認します。変更されていた場合は、上記の4ファイルを再確認したうえで `.sty` のファイル名とテスト文書を更新してください。

### macOS 以外でマウントに失敗する

現在の `scripts/latexmk-docker` は macOS の `/System/Library/Fonts` を常にマウントするため、macOS 以外ではそのまま利用できません。ヒラギノを使わないクロスプラットフォーム運用では、マウントを任意化した別のラッパーを用意する必要があります。
