#Requires -Version 5.1
<#
.SYNOPSIS
  Node.js プロジェクトのテンプレートをセットアップする
.DESCRIPTION
  book000/templates の Node.js テンプレートを使用して、
  新しい Node.js プロジェクトをセットアップします。

  使用方法:
    irm https://raw.githubusercontent.com/book000/templates/master/nodejs/setup.ps1 | iex
#>

# テンプレートのベース URL
$TEMPLATES_BASE_URL = 'https://raw.githubusercontent.com/book000/templates/master'
$NODEJS_BASE_URL = "$TEMPLATES_BASE_URL/nodejs"

# -------------------------------------------------------------------
# ユーティリティ関数
# -------------------------------------------------------------------

<#
.SYNOPSIS
  ファイルを URL から取得して保存する
#>
function Fetch-File {
  param(
    [string]$Url,
    [string]$Destination
  )
  $dir = Split-Path -Parent $Destination
  if ($dir -and -not (Test-Path $dir)) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
  }
  Invoke-WebRequest -Uri $Url -OutFile $Destination -UseBasicParsing
}

<#
.SYNOPSIS
  選択肢から 1 つを対話選択する
#>
function Prompt-Choice {
  param(
    [string]$Title,
    [string[]]$Choices,
    [int]$DefaultIndex = 0
  )
  Write-Host ''
  Write-Host $Title -ForegroundColor Cyan
  for ($i = 0; $i -lt $Choices.Length; $i++) {
    $marker = if ($i -eq $DefaultIndex) { '>' } else { ' ' }
    Write-Host "  $marker [$($i + 1)] $($Choices[$i])"
  }
  $answer = Read-Host "選択 (1-$($Choices.Length)) [既定: $($DefaultIndex + 1)]"
  if ([string]::IsNullOrWhiteSpace($answer)) {
    return $DefaultIndex
  }
  $parsedInt = 0
  if (-not [int]::TryParse($answer, [ref]$parsedInt)) {
    Write-Host '無効な入力です。既定値を使用します。' -ForegroundColor Yellow
    return $DefaultIndex
  }
  $idx = $parsedInt - 1
  if ($idx -lt 0 -or $idx -ge $Choices.Length) {
    Write-Host '無効な入力です。既定値を使用します。' -ForegroundColor Yellow
    return $DefaultIndex
  }
  return $idx
}

<#
.SYNOPSIS
  Yes/No を対話入力する
#>
function Prompt-YesNo {
  param(
    [string]$Question,
    [bool]$Default = $false
  )
  $hint = if ($Default) { 'Y/n' } else { 'y/N' }
  $answer = Read-Host "$Question [$hint]"
  if ([string]::IsNullOrWhiteSpace($answer)) {
    return $Default
  }
  return $answer -match '^[yY]'
}

<#
.SYNOPSIS
  文字列を対話入力する
#>
function Prompt-Input {
  param(
    [string]$Prompt,
    [string]$Default = ''
  )
  if ($Default) {
    $answer = Read-Host "$Prompt [$Default]"
    if ([string]::IsNullOrWhiteSpace($answer)) { return $Default }
    return $answer
  }
  else {
    return Read-Host $Prompt
  }
}

<#
.SYNOPSIS
  BOM なし UTF-8 でファイルに書き込む
.DESCRIPTION
  PS5.1 の Set-Content -Encoding UTF8 は BOM (U+FEFF) 付き UTF-8 で書き込むため、
  JSON / YAML / シェルスクリプト等では [System.IO.File]::WriteAllText を使う。
#>
function Write-Utf8NoBom {
  param(
    [string]$Path,
    [string]$Content
  )
  $encoding = New-Object System.Text.UTF8Encoding $false
  $absolutePath = Join-Path (Get-Location).Path $Path
  [System.IO.File]::WriteAllText($absolutePath, $Content, $encoding)
}

<#
.SYNOPSIS
  template.json のプロパティに安全にアクセスする（StrictMode 対応）
#>
function Get-TemplateProperty {
  param(
    [PSCustomObject]$Template,
    [string]$PropertyName,
    $DefaultValue = $null
  )
  $prop = $Template.PSObject.Properties[$PropertyName]
  if ($null -eq $prop) { return $DefaultValue }
  return $prop.Value
}

# -------------------------------------------------------------------
# メイン処理
# 関数化することで irm | iex 実行時に Set-StrictMode / $ErrorActionPreference が
# ユーザーの PS セッションに残留するのを防ぐ
# -------------------------------------------------------------------
function Invoke-NodejsProjectSetup {
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# -------------------------------------------------------------------
# 前提チェック
# -------------------------------------------------------------------

Write-Host ''
Write-Host '=== Node.js プロジェクトセットアップ ===' -ForegroundColor Green
Write-Host ''

# node の存在確認
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Host 'Error: node が見つかりません。Node.js をインストールしてください。' -ForegroundColor Red
  return
}

# pnpm の存在確認
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
  Write-Host 'Error: pnpm が見つかりません。corepack enable または npm install -g pnpm でインストールしてください。' -ForegroundColor Red
  return
}

# -------------------------------------------------------------------
# 対話入力フェーズ
# -------------------------------------------------------------------

# プロジェクト名（npm パッケージ名規則のバリデーションあり）
$ProjectName = ''
do {
  $ProjectName = Prompt-Input 'プロジェクト名 (例: my-app)'
  if ($ProjectName -cnotmatch '^[a-z0-9][a-z0-9\-_\.]*$' -or $ProjectName.Length -gt 214) {
    Write-Host '  プロジェクト名は小文字英数字・ハイフン・アンダースコア・ドットのみ使用できます。' -ForegroundColor Yellow
    $ProjectName = ''
  }
} while ([string]::IsNullOrEmpty($ProjectName))

$OrgName = ''
do {
  $OrgName = Prompt-Input 'GitHub 組織 / ユーザー名' 'book000'
  if ($OrgName -cnotmatch '^[a-zA-Z0-9][a-zA-Z0-9\-\.]*$') {
    Write-Host '  組織 / ユーザー名は英数字・ハイフン・ドットのみ使用できます。' -ForegroundColor Yellow
    $OrgName = ''
  }
} while ([string]::IsNullOrEmpty($OrgName))

$Repository = ''
do {
  $Repository = Prompt-Input 'リポジトリ名' $ProjectName
  if ($Repository -cnotmatch '^[a-zA-Z0-9_][a-zA-Z0-9\-_\.]*$') {
    Write-Host '  リポジトリ名は英数字・ハイフン・アンダースコア・ドットのみ使用できます。' -ForegroundColor Yellow
    $Repository = ''
  }
} while ([string]::IsNullOrEmpty($Repository))

$Description = Prompt-Input 'プロジェクトの説明'
$Author = Prompt-Input '作者名' $OrgName

$LicenseType = ''
do {
  $LicenseType = Prompt-Input 'ライセンス' 'MIT'
  if ($LicenseType -cnotmatch '^[a-zA-Z0-9.\-]+$') {
    Write-Host '  ライセンス識別子は英数字・ドット・ハイフンのみ使用できます（例: MIT, Apache-2.0）。' -ForegroundColor Yellow
    $LicenseType = ''
  }
} while ([string]::IsNullOrEmpty($LicenseType))
$Homepage = Prompt-Input 'ホームページ URL (任意・Enter でスキップ)' ''
$BugUrl = Prompt-Input 'バグ報告 URL' "https://github.com/$OrgName/$Repository/issues"
$RepositoryUrl = "https://github.com/$OrgName/$Repository"

# バリアント選択
$VariantChoices = @(
  'base             - 最小構成',
  'config-batch     - 設定ファイルありのバッチ処理',
  'fastify          - Fastify HTTP サーバー',
  'discord-bot      - Discord Bot'
)
$VariantNames = @('base', 'config-batch', 'fastify', 'discord-bot')
$VariantIndex = Prompt-Choice 'バリアントを選択してください' $VariantChoices 0
$Variant = $VariantNames[$VariantIndex]

# モジュール形式選択
$ModuleChoices = @(
  'CommonJS (既定・現行の標準)',
  'ESM (ES Modules)'
)
$ModuleIndex = Prompt-Choice 'モジュール形式を選択してください' $ModuleChoices 0
$UseESM = ($ModuleIndex -eq 1)

# オプション選択
$UseTest = Prompt-YesNo 'テスト (Jest) を追加しますか？' $false
$UseDockerfile = Prompt-YesNo 'Dockerfile を追加しますか？' $false
$IgnoreDataDir = Prompt-YesNo 'data/ ディレクトリを .gitignore に追加しますか？' $false
$UseAddReviewer = Prompt-YesNo 'add-reviewer ワークフローを追加しますか？' $false

# -------------------------------------------------------------------
# 既存ファイルの上書き確認
# -------------------------------------------------------------------

$existingFiles = @('package.json', 'tsconfig.json', 'src')
$hasExisting = $existingFiles | Where-Object { Test-Path $_ }
if ($hasExisting) {
  Write-Host ''
  Write-Host '以下のファイル / ディレクトリが既に存在します:' -ForegroundColor Yellow
  $hasExisting | ForEach-Object { Write-Host "  - $_" -ForegroundColor Yellow }
  $overwrite = Prompt-YesNo '上書きして続行しますか？' $false
  if (-not $overwrite) {
    Write-Host 'セットアップを中断しました。' -ForegroundColor Red
    return
  }
}

Write-Host ''
Write-Host 'セットアップを開始します...' -ForegroundColor Green

# -------------------------------------------------------------------
# バリアント設定の読み込み（template.json）
# -------------------------------------------------------------------

Write-Host ''
Write-Host "[1/9] バリアント設定を読み込んでいます ($Variant)..." -ForegroundColor Cyan

$templateJsonUrl = "$NODEJS_BASE_URL/$Variant/template.json"
$templateJsonContent = (Invoke-WebRequest -Uri $templateJsonUrl -UseBasicParsing).Content
$templateConfig = $templateJsonContent | ConvertFrom-Json

# -------------------------------------------------------------------
# 共通テンプレートファイルの取得
# -------------------------------------------------------------------

Write-Host '[2/9] 共通テンプレートを取得しています...' -ForegroundColor Cyan

$commonFiles = @(
  'tsconfig.json',
  '.prettierrc.yml',
  'eslint.config.mjs',
  'renovate.json',
  '.depcheckrc.json',
  '.fixpackrc',
  'pnpm-workspace.yaml',
  '.devcontainer/devcontainer.json'
)

foreach ($file in $commonFiles) {
  $url = "$NODEJS_BASE_URL/common/$file"
  Fetch-File -Url $url -Destination $file
  Write-Host "  取得: $file" -ForegroundColor Gray
}

# -------------------------------------------------------------------
# バリアント src ファイルの取得
# -------------------------------------------------------------------

Write-Host '[3/9] バリアントファイルを取得しています...' -ForegroundColor Cyan

# 空配列を返す関数は PS pipeline で $null になるため @() でラップして配列を保証する
$templateSrc = @(Get-TemplateProperty -Template $templateConfig -PropertyName 'src' -DefaultValue @())
foreach ($srcFile in $templateSrc) {
  $url = "$NODEJS_BASE_URL/$Variant/$srcFile"
  Fetch-File -Url $url -Destination $srcFile
  Write-Host "  取得: $srcFile" -ForegroundColor Gray
}

# Dockerfile + entrypoint.sh（選択時のみ）
if ($UseDockerfile) {
  Fetch-File -Url "$NODEJS_BASE_URL/common/Dockerfile" -Destination 'Dockerfile'
  Write-Host '  取得: Dockerfile' -ForegroundColor Gray
  Fetch-File -Url "$NODEJS_BASE_URL/common/entrypoint.sh" -Destination 'entrypoint.sh'
  Write-Host '  取得: entrypoint.sh' -ForegroundColor Gray
}

# -------------------------------------------------------------------
# tsconfig.json のモジュール形式パッチ
# -------------------------------------------------------------------

Write-Host '[4/9] tsconfig.json を設定しています...' -ForegroundColor Cyan

$tsconfig = Get-Content 'tsconfig.json' -Raw | ConvertFrom-Json

# PS5.1 では単一要素の JSON 配列がスカラーに変換されるため明示的に配列化する
$tsconfig.compilerOptions.types = @($tsconfig.compilerOptions.types)
$tsconfig.compilerOptions.lib   = @($tsconfig.compilerOptions.lib)

# モジュール形式を設定
# CJS 既定: テンプレートのまま（module=node16 + moduleResolution=node16）
# ESM 選択時: module=es2015 + moduleResolution=bundler に変更する
#             （tsx + bundler 解決で拡張子なし import を許可）
if ($UseESM) {
  $tsconfig.compilerOptions.module = 'es2015'
  $tsconfig.compilerOptions.moduleResolution = 'bundler'
  Write-Host '  module: es2015, moduleResolution: bundler (ESM)' -ForegroundColor Gray
}
else {
  Write-Host '  module: node16, moduleResolution: node16 (CJS)' -ForegroundColor Gray
}

# test 選択時: types に "jest" を追加
if ($UseTest) {
  $existingTypes = @($tsconfig.compilerOptions.types)
  if ($existingTypes -notcontains 'jest') {
    $tsconfig.compilerOptions.types = $existingTypes + @('jest')
    Write-Host '  types に jest を追加しました' -ForegroundColor Gray
  }
}

Write-Utf8NoBom -Path 'tsconfig.json' -Content ($tsconfig | ConvertTo-Json -Depth 10)

# -------------------------------------------------------------------
# .gitignore の生成
# -------------------------------------------------------------------

Write-Host '[5/9] .gitignore / .node-version を生成しています...' -ForegroundColor Cyan

$gitignoreContent = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/github/gitignore/main/Node.gitignore' -UseBasicParsing).Content

# pnpm 追記（pnpm-lock.yaml はコミット対象のためここには含めない）
$gitignoreContent += @'


# pnpm
pnpm-debug.log*
'@

# data/ ディレクトリ（選択時）
if ($IgnoreDataDir) {
  $gitignoreContent += @'


# データディレクトリ
data/
'@
}

Write-Utf8NoBom -Path '.gitignore' -Content $gitignoreContent

$nodeVersion = (node --version).TrimStart('v')
Write-Utf8NoBom -Path '.node-version' -Content $nodeVersion
Write-Host "  .node-version: $nodeVersion" -ForegroundColor Gray

# -------------------------------------------------------------------
# LICENSE の生成
# -------------------------------------------------------------------

Write-Host '[6/9] LICENSE を生成しています...' -ForegroundColor Cyan

$year = (Get-Date).Year
$licenseApiUrl = "https://api.github.com/licenses/$($LicenseType.ToLower())"
try {
  $licenseResponse = (Invoke-WebRequest -Uri $licenseApiUrl -UseBasicParsing).Content | ConvertFrom-Json
  $licenseText = $licenseResponse.body
  $licenseText = $licenseText -replace '\[year\]', $year
  $licenseText = $licenseText -replace '\[fullname\]', $Author
  Write-Utf8NoBom -Path 'LICENSE' -Content $licenseText
  Write-Host "  $LicenseType ライセンスを生成しました" -ForegroundColor Gray
}
catch {
  Write-Host "  LICENSE の取得に失敗しました。手動で設定してください。" -ForegroundColor Yellow
}

# -------------------------------------------------------------------
# ワークフローの取得
# -------------------------------------------------------------------

Write-Host '[7/9] ワークフローを取得しています...' -ForegroundColor Cyan

if (-not (Test-Path '.github/workflows')) {
  New-Item -ItemType Directory -Path '.github/workflows' -Force | Out-Null
}

# nodejs-ci-pnpm.yml
Fetch-File -Url "$TEMPLATES_BASE_URL/workflows/nodejs-ci-pnpm.yml" -Destination '.github/workflows/nodejs-ci-pnpm.yml'
Write-Host '  取得: .github/workflows/nodejs-ci-pnpm.yml' -ForegroundColor Gray

# docker.yml（Dockerfile 選択時）
if ($UseDockerfile) {
  $dockerContent = (Invoke-WebRequest -Uri "$TEMPLATES_BASE_URL/workflows/docker.yml" -UseBasicParsing).Content
  # GHCR の image path はリポジトリ名に合わせる（npm パッケージ名 $ProjectName とは独立）
  # GHCR イメージ名は小文字必須
  $imageRef = "$($OrgName.ToLower())/$($Repository.ToLower())"
  $dockerContent = $dockerContent.Replace('tomacheese/twitter-dm-memo', $imageRef)
  $dockerContent = $dockerContent.Replace('packageName: "twitter-dm-memo"', "packageName: `"$Repository`"")
  # 置換が実際に行われたか確認（テンプレート側のプレースホルダーが変更された場合の検知）
  if (-not $dockerContent.Contains($imageRef)) {
    Write-Host '  警告: docker.yml のイメージ名置換に失敗した可能性があります。手動で確認してください。' -ForegroundColor Yellow
  }
  Write-Utf8NoBom -Path '.github/workflows/docker.yml' -Content $dockerContent
  Write-Host '  取得: .github/workflows/docker.yml' -ForegroundColor Gray
}

# add-reviewer.yml（選択時）
if ($UseAddReviewer) {
  Fetch-File -Url "$TEMPLATES_BASE_URL/workflows/add-reviewer.yml" -Destination '.github/workflows/add-reviewer.yml'
  Write-Host '  取得: .github/workflows/add-reviewer.yml' -ForegroundColor Gray
}

# -------------------------------------------------------------------
# package.json の生成
# -------------------------------------------------------------------

Write-Host '[8/9] package.json を生成しています...' -ForegroundColor Cyan

# エンジン設定（メジャーバージョン取得）
$nodeMajor = $nodeVersion.Split('.')[0]

# バリアントの package.json を取得してベースにする。
# このファイルには CI でテスト済みのピン留めバージョンが含まれている。
$packageJsonContent = (Invoke-WebRequest -Uri "$NODEJS_BASE_URL/$Variant/package.json" -UseBasicParsing).Content
$packageJson = $packageJsonContent | ConvertFrom-Json

# プロジェクト固有の値を上書き
# npm スコープ名は小文字必須
$packageJson.name             = "@$($OrgName.ToLower())/$ProjectName"
$packageJson.description      = $Description
$packageJson.license          = $LicenseType
$packageJson.author           = $Author
$packageJson.engines.node     = ">=$nodeMajor"
$packageJson.repository.url   = "git+$RepositoryUrl.git"
$packageJson.bugs.url         = $BugUrl

# homepage（入力ありの場合）
if ($Homepage) {
  Add-Member -InputObject $packageJson -MemberType NoteProperty -Name 'homepage' -Value $Homepage -Force
}

# ESM: type: module を追加 + jest config を ESM 用に変更
if ($UseESM) {
  Add-Member -InputObject $packageJson -MemberType NoteProperty -Name 'type' -Value 'module' -Force
  $jestConfig = [ordered]@{
    preset                  = 'ts-jest/presets/default-esm'
    extensionsToTreatAsEsm  = @('.ts')
    transform               = [ordered]@{
      '^.+\.tsx?$' = @('ts-jest', [ordered]@{ useESM = $true })
    }
  }
  Add-Member -InputObject $packageJson -MemberType NoteProperty -Name 'jest' -Value $jestConfig -Force
}

# test を使わない場合: jest 関連を package.json から除去
if (-not $UseTest) {
  # devDependencies から jest 関連を削除
  foreach ($dep in @('jest', '@types/jest', 'ts-jest')) {
    $packageJson.devDependencies.PSObject.Properties.Remove($dep)
  }
  # scripts から test を削除
  $packageJson.scripts.PSObject.Properties.Remove('test')
  # jest 設定を削除
  $packageJson.PSObject.Properties.Remove('jest')
}

Write-Utf8NoBom -Path 'package.json' -Content ($packageJson | ConvertTo-Json -Depth 10)

# -------------------------------------------------------------------
# 依存パッケージのインストール（pnpm install）
# テスト済みのピン留めバージョンで再現性のあるインストールを行う
# -------------------------------------------------------------------

Write-Host "  pnpm install（CI テスト済みバージョン）..." -ForegroundColor Gray
pnpm install

# -------------------------------------------------------------------
# .depcheckrc.json の更新
# -------------------------------------------------------------------

# 空配列を返す関数は PS pipeline で $null になるため @() でラップして配列を保証する
$templateDepcheckIgnore = @(Get-TemplateProperty -Template $templateConfig -PropertyName 'depcheckIgnore' -DefaultValue @())
if ($templateDepcheckIgnore.Count -gt 0 -or $UseTest) {
  $depcheck = Get-Content '.depcheckrc.json' -Raw | ConvertFrom-Json
  $existingIgnores = if ($depcheck.ignores) { @($depcheck.ignores) } else { @() }

  # バリアント固有の無視パッケージを追加
  foreach ($item in $templateDepcheckIgnore) {
    if ($existingIgnores -notcontains $item) {
      $existingIgnores += $item
    }
  }

  # test 用
  if ($UseTest -and $existingIgnores -notcontains '@types/jest') {
    $existingIgnores += '@types/jest'
  }

  $depcheck.ignores = $existingIgnores
  Write-Utf8NoBom -Path '.depcheckrc.json' -Content ($depcheck | ConvertTo-Json -Depth 10)
}

# -------------------------------------------------------------------
# schema/ ディレクトリの作成（configSchema ありのバリアント）
# -------------------------------------------------------------------

if (Get-TemplateProperty -Template $templateConfig -PropertyName 'configSchema' -DefaultValue $false) {
  New-Item -ItemType Directory -Path 'schema' -Force | Out-Null
  Write-Host '  schema/ ディレクトリを作成しました' -ForegroundColor Gray
}

# -------------------------------------------------------------------
# fixpack / fixdevcontainer で整形
# -------------------------------------------------------------------

Write-Host '[9/9] package.json を整形しています...' -ForegroundColor Cyan

try {
  npx --yes fixpack
}
catch {
  Write-Host '  fixpack の実行をスキップしました' -ForegroundColor Yellow
}

try {
  npx --yes fixdevcontainer
}
catch {
  Write-Host '  fixdevcontainer の実行をスキップしました' -ForegroundColor Yellow
}

# -------------------------------------------------------------------
# 完了メッセージ
# -------------------------------------------------------------------

Write-Host ''
Write-Host '=== セットアップ完了！ ===' -ForegroundColor Green
Write-Host ''
Write-Host "プロジェクト : @$OrgName/$ProjectName" -ForegroundColor Cyan
Write-Host "バリアント   : $Variant" -ForegroundColor Cyan
Write-Host "モジュール   : $(if ($UseESM) { 'ESM' } else { 'CommonJS' })" -ForegroundColor Cyan
Write-Host ''
Write-Host '次のステップ:' -ForegroundColor Yellow
Write-Host '  1. git init && git add . && git commit -m "feat: 初期コミット"'
Write-Host '  2. pnpm run lint        # lint 確認'
if (Get-TemplateProperty -Template $templateConfig -PropertyName 'configSchema' -DefaultValue $false) {
  Write-Host '  3. pnpm run generate-schema  # スキーマ生成'
}
if ($UseTest) {
  Write-Host '  3. pnpm run test        # テスト実行'
}
Write-Host ''
}

# エントリポイント
Invoke-NodejsProjectSetup
