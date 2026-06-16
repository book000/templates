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

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

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

# -------------------------------------------------------------------
# 前提チェック
# -------------------------------------------------------------------

Write-Host ''
Write-Host '=== Node.js プロジェクトセットアップ ===' -ForegroundColor Green
Write-Host ''

# node の存在確認
if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
  Write-Error 'node が見つかりません。Node.js をインストールしてください。'
}

# pnpm の存在確認
if (-not (Get-Command pnpm -ErrorAction SilentlyContinue)) {
  Write-Error 'pnpm が見つかりません。corepack enable または npm install -g pnpm でインストールしてください。'
}

# -------------------------------------------------------------------
# 対話入力フェーズ
# -------------------------------------------------------------------

$ProjectName = Prompt-Input 'プロジェクト名 (例: my-app)'
$OrgName = Prompt-Input 'GitHub 組織 / ユーザー名' 'book000'
$Repository = Prompt-Input 'リポジトリ名' $ProjectName
$Description = Prompt-Input 'プロジェクトの説明'
$Author = Prompt-Input '作者名' $OrgName
$LicenseType = Prompt-Input 'ライセンス' 'MIT'
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

foreach ($srcFile in $templateConfig.src) {
  $url = "$NODEJS_BASE_URL/$Variant/$srcFile"
  Fetch-File -Url $url -Destination $srcFile
  Write-Host "  取得: $srcFile" -ForegroundColor Gray
}

# Dockerfile（選択時のみ）
if ($UseDockerfile) {
  Fetch-File -Url "$NODEJS_BASE_URL/common/Dockerfile" -Destination 'Dockerfile'
  Write-Host '  取得: Dockerfile' -ForegroundColor Gray
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
if ($UseESM) {
  $tsconfig.compilerOptions.module = 'es2015'
  Write-Host '  module: es2015 (ESM)' -ForegroundColor Gray
}
else {
  Write-Host '  module: commonjs (CJS)' -ForegroundColor Gray
}

# test 選択時: types に "jest" を追加
if ($UseTest) {
  $existingTypes = @($tsconfig.compilerOptions.types)
  if ($existingTypes -notcontains 'jest') {
    $tsconfig.compilerOptions.types = $existingTypes + @('jest')
    Write-Host '  types に jest を追加しました' -ForegroundColor Gray
  }
}

$tsconfig | ConvertTo-Json -Depth 10 | Set-Content 'tsconfig.json' -Encoding UTF8

# -------------------------------------------------------------------
# .gitignore の生成
# -------------------------------------------------------------------

Write-Host '[5/9] .gitignore を生成しています...' -ForegroundColor Cyan

$gitignoreContent = (Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/github/gitignore/main/Node.gitignore' -UseBasicParsing).Content

# pnpm 追記
$gitignoreContent += @'


# pnpm
pnpm-lock.yaml
'@

# data/ ディレクトリ（選択時）
if ($IgnoreDataDir) {
  $gitignoreContent += @'


# データディレクトリ
data/
'@
}

$gitignoreContent | Set-Content '.gitignore' -Encoding UTF8

# -------------------------------------------------------------------
# .node-version の生成
# -------------------------------------------------------------------

$nodeVersion = (node --version).TrimStart('v')
# BOM なし UTF-8 で書き込む（PS5.1 の Set-Content -Encoding UTF8 は BOM を付与するため）
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[System.IO.File]::WriteAllText((Join-Path (Get-Location).Path '.node-version'), $nodeVersion, $utf8NoBom)
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
  $licenseText | Set-Content 'LICENSE' -Encoding UTF8
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
  $imageRef = "$OrgName/$ProjectName"
  $dockerContent = $dockerContent.Replace('tomacheese/twitter-dm-memo', $imageRef)
  $dockerContent = $dockerContent.Replace('packageName: "twitter-dm-memo"', "packageName: `"$ProjectName`"")
  $dockerContent | Set-Content '.github/workflows/docker.yml' -Encoding UTF8
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

# 共通スクリプト
$scripts = [ordered]@{
  'preinstall'    = 'npx only-allow pnpm'
  'start'         = 'tsx ./src/main.ts'
  'dev'           = 'tsx watch ./src/main.ts'
  'lint'          = 'run-z lint:prettier,lint:eslint,lint:tsc'
  'lint:prettier' = 'prettier --check src'
  'lint:eslint'   = 'eslint . -c eslint.config.mjs'
  'lint:tsc'      = 'tsc'
  'fix'           = 'run-z fix:prettier fix:eslint'
  'fix:eslint'    = 'eslint . -c eslint.config.mjs --fix'
  'fix:prettier'  = 'prettier --write src'
}

# test スクリプト
if ($UseTest) {
  $scripts['test'] = 'jest --runInBand --passWithNoTests --detectOpenHandles --forceExit'
}

# バリアント固有スクリプト
if ($templateConfig.scripts) {
  $templateConfig.scripts.PSObject.Properties | ForEach-Object {
    $scripts[$_.Name] = $_.Value
  }
}

# package.json オブジェクトを構築
$packageJson = [ordered]@{
  name        = "@$OrgName/$ProjectName"
  version     = '1.0.0'
  description = $Description
  license     = $LicenseType
  author      = $Author
  scripts     = $scripts
  engines     = [ordered]@{ node = ">=$nodeMajor" }
  repository  = [ordered]@{
    type = 'git'
    url  = "git+$RepositoryUrl.git"
  }
  bugs        = [ordered]@{
    url = $BugUrl
  }
}

# homepage（入力ありの場合）
if ($Homepage) {
  $packageJson['homepage'] = $Homepage
}

# ESM: type: module を追加
if ($UseESM) {
  $packageJson['type'] = 'module'
}

$packageJson | ConvertTo-Json -Depth 10 | Set-Content 'package.json' -Encoding UTF8

# -------------------------------------------------------------------
# 依存パッケージのインストール（pnpm add）
# -------------------------------------------------------------------

# 共通 devDependencies
$commonDevDeps = @(
  'typescript',
  '@types/node',
  'tsx',
  'prettier',
  'eslint',
  'run-z',
  '@book000/node-utils',
  '@book000/eslint-config'
)

# test 用 devDependencies
$testDevDeps = @()
if ($UseTest) {
  $testDevDeps = @(
    'jest',
    '@types/jest',
    'ts-jest'
  )
}

# バリアント固有 devDependencies
$variantDevDeps = @()
if ($templateConfig.devDependencies -and $templateConfig.devDependencies.Count -gt 0) {
  $variantDevDeps = [string[]]$templateConfig.devDependencies
}

$allDevDeps = $commonDevDeps + $testDevDeps + $variantDevDeps

Write-Host "  pnpm add -D -E ($($allDevDeps.Count) パッケージ)..." -ForegroundColor Gray
pnpm add -D -E $allDevDeps

# -------------------------------------------------------------------
# Jest 設定の追記（test 選択時）
# -------------------------------------------------------------------

if ($UseTest) {
  Write-Host '  Jest 設定を package.json に追加しています...' -ForegroundColor Gray

  $pkg = Get-Content 'package.json' -Raw | ConvertFrom-Json

  if ($UseESM) {
    # ESM + Jest
    $jestConfig = [ordered]@{
      preset                  = 'ts-jest/presets/default-esm'
      extensionsToTreatAsEsm  = @('.ts')
      transform               = [ordered]@{
        '^.+\\.tsx?$' = @('ts-jest', [ordered]@{ useESM = $true })
      }
    }
  }
  else {
    # CommonJS + Jest
    $jestConfig = [ordered]@{
      preset          = 'ts-jest'
      testEnvironment = 'node'
    }
  }

  Add-Member -InputObject $pkg -MemberType NoteProperty -Name 'jest' -Value $jestConfig -Force
  $pkg | ConvertTo-Json -Depth 10 | Set-Content 'package.json' -Encoding UTF8
}

# -------------------------------------------------------------------
# .depcheckrc.json の更新
# -------------------------------------------------------------------

if (($templateConfig.depcheckIgnore -and $templateConfig.depcheckIgnore.Count -gt 0) -or $UseTest) {
  $depcheck = Get-Content '.depcheckrc.json' -Raw | ConvertFrom-Json
  $existingIgnores = if ($depcheck.ignores) { @($depcheck.ignores) } else { @() }

  # バリアント固有の無視パッケージを追加
  if ($templateConfig.depcheckIgnore) {
    foreach ($item in $templateConfig.depcheckIgnore) {
      if ($existingIgnores -notcontains $item) {
        $existingIgnores += $item
      }
    }
  }

  # test 用
  if ($UseTest -and $existingIgnores -notcontains '@types/jest') {
    $existingIgnores += '@types/jest'
  }

  $depcheck.ignores = $existingIgnores
  $depcheck | ConvertTo-Json -Depth 10 | Set-Content '.depcheckrc.json' -Encoding UTF8
}

# -------------------------------------------------------------------
# schema/ ディレクトリの作成（configSchema ありのバリアント）
# -------------------------------------------------------------------

if ($templateConfig.configSchema) {
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
if ($templateConfig.configSchema) {
  Write-Host '  3. pnpm run generate-schema  # スキーマ生成'
}
if ($UseTest) {
  Write-Host '  3. pnpm run test        # テスト実行'
}
Write-Host ''
