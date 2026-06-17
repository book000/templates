#!/usr/bin/env bash
# Node.js テンプレート setup.ps1 の monkey test
#
# 使用方法:
#   nodejs/tests/run-monkey-test.sh [--full]
#
# オプション:
#   --full  pnpm install + lint まで実行してフル検証を行う
#           （デフォルトはファイル生成 / バリデーション確認のみ・高速）
#
# テスト内容:
#   SC01: base CJS ハッピーパス
#   SC02: 無効な ProjectName の再入力（バリデーションループ確認）
#   SC03: 無効な OrgName の再入力（バリデーションループ確認）
#   SC04: config-batch + テストあり
#   SC05: fastify + Dockerfile
#   SC06: discord-bot + ESM + data/ 追加
#   SC07: 無効なバリアント番号（範囲外 → 既定値へフォールバック）
#   SC08: 既存ファイルの上書き拒否（中断確認）
#   SC09: 既存ファイルの上書き承認（続行確認）
#   SC10: irm | iex セッション状態リーク確認（StrictMode / ErrorActionPreference）
#   SC11: [--full のみ] pnpm install + pnpm run lint でフル検証

set -uo pipefail

# -------------------------------------------------------------------
# 設定
# -------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DOCKER_IMAGE="nodejs-template-test"
MOCK_PORT=8080
FULL_MODE=false
MOCK_PID=""

# pnpm ストアキャッシュ（Docker ボリューム名）
PNPM_STORE_VOLUME="nodejs-template-test-pnpm-store"

# -------------------------------------------------------------------
# 出力ユーティリティ
# -------------------------------------------------------------------
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0

_log()  { echo -e "${NC}$*${NC}"; }
_info() { echo -e "${CYAN}$*${NC}"; }
_pass() { echo -e "${GREEN}  ✓ $*${NC}"; ((PASS_COUNT++)); }
_fail() { echo -e "${RED}  ✗ $*${NC}"; ((FAIL_COUNT++)); }

# Docker がファイルを root で作成するため chmod してから削除する
cleanup_dir() {
    local dir="$1"
    chmod -R a+w "$dir" 2>/dev/null || true
    rm -rf "$dir" 2>/dev/null || true
}

# -------------------------------------------------------------------
# 引数解析
# -------------------------------------------------------------------
for arg in "$@"; do
  case "$arg" in
    --full) FULL_MODE=true ;;
    *) echo "Unknown option: $arg"; exit 1 ;;
  esac
done

# -------------------------------------------------------------------
# クリーンアップ
# -------------------------------------------------------------------
cleanup() {
  if [[ -n "$MOCK_PID" ]]; then
    kill "$MOCK_PID" 2>/dev/null || true
    _info "[cleanup] mock server stopped (PID=$MOCK_PID)"
  fi
}
trap cleanup EXIT

# -------------------------------------------------------------------
# Docker イメージのビルド
# -------------------------------------------------------------------
build_image() {
  _info ">>> Docker イメージをビルドしています: $DOCKER_IMAGE"
  if docker images --format '{{.Repository}}:{{.Tag}}' | grep -q "^${DOCKER_IMAGE}:latest$"; then
    _info ">>> キャッシュ済みイメージを使用します（再ビルドするには docker rmi $DOCKER_IMAGE）"
  else
    docker build -t "$DOCKER_IMAGE" "$SCRIPT_DIR" 2>&1 | tail -5
    _info ">>> ビルド完了"
  fi
}

# -------------------------------------------------------------------
# モックサーバーの起動
# -------------------------------------------------------------------
start_mock_server() {
  _info ">>> モックサーバーを起動しています (port=$MOCK_PORT)..."
  python3 "$SCRIPT_DIR/mock-server.py" "$MOCK_PORT" &
  MOCK_PID=$!
  # 起動待機（最大 5 秒）
  local retries=0
  until curl -s "http://localhost:$MOCK_PORT/nodejs/base/template.json" > /dev/null 2>&1; do
    ((retries++))
    if [[ $retries -ge 10 ]]; then
      _fail "モックサーバーが起動しませんでした"
      exit 1
    fi
    sleep 0.5
  done
  _info ">>> モックサーバー起動完了 (PID=$MOCK_PID)"
}

# -------------------------------------------------------------------
# テスト用 setup.ps1 を準備する（URL 差し替え + pnpm install スキップ制御）
#
# 出力: 一時ファイルのパス
# -------------------------------------------------------------------
prepare_test_script() {
  local skip_install="${1:-true}"
  local tmp_script
  tmp_script="$(mktemp /tmp/setup-test-XXXXXX.ps1)"
  local mock_base="http://host.docker.internal:$MOCK_PORT"

  sed \
    -e "s|https://raw.githubusercontent.com/book000/templates/master|$mock_base|g" \
    -e "s|https://raw.githubusercontent.com/github/gitignore/main|$mock_base/github-gitignore|g" \
    -e "s|https://api.github.com/licenses|$mock_base/api-licenses|g" \
    "$REPO_ROOT/nodejs/setup.ps1" > "$tmp_script"

  # --full なしの場合: pnpm install をスキップしてファイル生成確認に集中する
  if [[ "$skip_install" == "true" ]]; then
    # "pnpm install" 行をコメントアウト
    sed -i 's/^pnpm install$/# [TEST] pnpm install skipped for speed/' "$tmp_script"
  fi

  echo "$tmp_script"
}

# -------------------------------------------------------------------
# Docker でシナリオを実行する
#
# 引数:
#   $1  シナリオ名
#   $2  入力文字列（改行区切り）
#   $3  作業ディレクトリ（ホスト側の絶対パス）
#   $4  スクリプトファイルのホストパス
#   $5  追加の Docker オプション（省略可）
#
# 戻り値:
#   Docker 実行の stdout+stderr
# -------------------------------------------------------------------
run_docker_scenario() {
  local name="$1"
  local inputs="$2"
  local work_dir="$3"
  local script_file="$4"
  local extra_opts="${5:-}"

  # pwsh は -NonInteractive だと Read-Host が動作しないため使わない。
  # stdin パイプ時、Read-Host は空 EOF で空文字列を返す。
  # shellcheck disable=SC2086
  printf '%s' "$inputs" | docker run \
    --rm --interactive \
    --add-host=host.docker.internal:host-gateway \
    -v "$script_file:/tmp/setup.ps1:ro" \
    -v "$work_dir:/workspace" \
    -v "$PNPM_STORE_VOLUME:/root/.local/share/pnpm/store" \
    -e PNPM_HOME=/root/.local/share/pnpm \
    $extra_opts \
    "$DOCKER_IMAGE" \
    pwsh -Command "
      Set-Location /workspace
      \$ErrorActionPreference = 'Continue'
      iex (Get-Content /tmp/setup.ps1 -Raw)
    " 2>&1 || true
}

# -------------------------------------------------------------------
# アサーション関数群
# -------------------------------------------------------------------

assert_file_exists() {
  local dir="$1" file="$2" label="$3"
  if [[ -f "$dir/$file" ]] || [[ -d "$dir/$file" ]]; then
    _pass "$label: '$file' が存在する"
  else
    _fail "$label: '$file' が存在しない"
    ls -la "$dir" 2>/dev/null | head -20 || true
  fi
}

assert_file_not_exists() {
  local dir="$1" file="$2" label="$3"
  if [[ ! -e "$dir/$file" ]]; then
    _pass "$label: '$file' が存在しない（期待通り）"
  else
    _fail "$label: '$file' が存在してしまっている"
  fi
}

assert_json_field() {
  local dir="$1" file="$2" jq_expr="$3" expected="$4" label="$5"
  if [[ ! -f "$dir/$file" ]]; then
    _fail "$label: '$file' が存在しないため $jq_expr を確認できない"
    return
  fi
  local actual
  actual=$(node -e "const j=require('$dir/$file'); console.log($jq_expr)" 2>/dev/null || echo "ERROR_PARSING")
  if [[ "$actual" == "$expected" ]]; then
    _pass "$label: $file > $jq_expr == '$expected'"
  else
    _fail "$label: $file > $jq_expr == '$actual' (期待値: '$expected')"
  fi
}

assert_file_not_contains() {
  local dir="$1" file="$2" needle="$3" label="$4"
  if [[ ! -f "$dir/$file" ]]; then
    _fail "$label: '$file' が存在しないため確認できない"
    return
  fi
  if grep -qF "$needle" "$dir/$file" 2>/dev/null; then
    _fail "$label: $file に '$needle' が含まれている（含まれていないべき）"
  else
    _pass "$label: $file に '$needle' が含まれていない"
  fi
}

assert_output_contains() {
  local output="$1" needle="$2" label="$3"
  if echo "$output" | grep -qF "$needle"; then
    _pass "$label: 出力に '$needle' が含まれる"
  else
    _fail "$label: 出力に '$needle' が含まれない"
    echo "--- 実際の出力 (末尾 20 行) ---"
    echo "$output" | tail -20
    echo "---"
  fi
}

# -------------------------------------------------------------------
# メイン処理開始
# -------------------------------------------------------------------

# Docker ボリューム確認 / 作成
docker volume create "$PNPM_STORE_VOLUME" > /dev/null 2>&1 || true

build_image
start_mock_server

# デフォルトテスト用スクリプト（pnpm install スキップ）
TEST_SCRIPT=$(prepare_test_script "true")
# shellcheck disable=SC2064
trap "cleanup; rm -f '$TEST_SCRIPT'" EXIT

# -------------------------------------------------------------------
# SC01: base CJS ハッピーパス
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC01: base CJS ハッピーパス"
_log "================================================================"
SC01_DIR="$(mktemp -d)"
SC01_INPUTS="my-project
book000
my-project-repo
A test project
book000
MIT


1
1
n
n
n
n
"
SC01_OUT=$(run_docker_scenario "SC01" "$SC01_INPUTS" "$SC01_DIR" "$TEST_SCRIPT")
echo "$SC01_OUT" | tail -15

assert_file_exists     "$SC01_DIR" "package.json"                          "SC01"
assert_file_exists     "$SC01_DIR" "tsconfig.json"                         "SC01"
assert_file_exists     "$SC01_DIR" "src/main.ts"                           "SC01"
assert_file_exists     "$SC01_DIR" ".gitignore"                            "SC01"
assert_file_exists     "$SC01_DIR" ".node-version"                         "SC01"
assert_file_exists     "$SC01_DIR" ".github/workflows/nodejs-ci-pnpm.yml"  "SC01"
assert_file_exists     "$SC01_DIR" "renovate.json"                         "SC01"
assert_file_exists     "$SC01_DIR" ".devcontainer/devcontainer.json"       "SC01"
assert_json_field      "$SC01_DIR" "package.json" "j.name"                 "@book000/my-project" "SC01"
assert_file_not_exists "$SC01_DIR" "Dockerfile"                            "SC01"
# テストなし → scripts.test が存在しないか確認
assert_file_not_contains "$SC01_DIR" "package.json" '"test":'              "SC01"
assert_output_contains "$SC01_OUT" "セットアップ完了"                      "SC01"
cleanup_dir "$SC01_DIR"

# -------------------------------------------------------------------
# SC02: 無効な ProjectName の再入力ループ確認
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC02: 無効な ProjectName の再入力ループ"
_log "================================================================"
SC02_DIR="$(mktemp -d)"
SC02_INPUTS="My-Project
-bad-start
has space
my\$dollar
valid-project
book000
valid-project
Valid project test
book000
MIT


1
1
n
n
n
n
"
SC02_OUT=$(run_docker_scenario "SC02" "$SC02_INPUTS" "$SC02_DIR" "$TEST_SCRIPT")
echo "$SC02_OUT" | tail -15

assert_file_exists     "$SC02_DIR" "package.json"                          "SC02"
assert_json_field      "$SC02_DIR" "package.json" "j.name"                 "@book000/valid-project" "SC02"
assert_output_contains "$SC02_OUT" "小文字英数字"                          "SC02"
assert_output_contains "$SC02_OUT" "セットアップ完了"                      "SC02"
cleanup_dir "$SC02_DIR"

# -------------------------------------------------------------------
# SC03: 無効な OrgName の再入力ループ確認
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC03: 無効な OrgName の再入力ループ"
_log "================================================================"
SC03_DIR="$(mktemp -d)"
SC03_INPUTS="valid-project
Bad Org!
-bad-org
good-org
valid-project
Test
good-org
MIT


1
1
n
n
n
n
"
SC03_OUT=$(run_docker_scenario "SC03" "$SC03_INPUTS" "$SC03_DIR" "$TEST_SCRIPT")
echo "$SC03_OUT" | tail -15

assert_file_exists  "$SC03_DIR" "package.json"                             "SC03"
assert_json_field   "$SC03_DIR" "package.json" "j.name"                    "@good-org/valid-project" "SC03"
assert_output_contains "$SC03_OUT" "英数字・ハイフン・ドット"              "SC03"
cleanup_dir "$SC03_DIR"

# -------------------------------------------------------------------
# SC04: config-batch + テストあり
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC04: config-batch + テストあり"
_log "================================================================"
SC04_DIR="$(mktemp -d)"
SC04_INPUTS="config-batch-app
book000
config-batch-app
A config batch application
book000
MIT


2
1
y
n
n
n
"
SC04_OUT=$(run_docker_scenario "SC04" "$SC04_INPUTS" "$SC04_DIR" "$TEST_SCRIPT")
echo "$SC04_OUT" | tail -15

assert_file_exists "$SC04_DIR" "package.json"   "SC04"
assert_file_exists "$SC04_DIR" "src/main.ts"    "SC04"
assert_file_exists "$SC04_DIR" "src/config.ts"  "SC04"
assert_file_exists "$SC04_DIR" "schema"         "SC04"
assert_json_field  "$SC04_DIR" "package.json" "j.name" "@book000/config-batch-app" "SC04"
# テストあり → @types/jest が devDependencies に含まれるか
if [[ -f "$SC04_DIR/package.json" ]]; then
  if node -e "const j=require('$SC04_DIR/package.json'); process.exit(j.devDependencies && j.devDependencies['@types/jest'] ? 0 : 1)" 2>/dev/null; then
    _pass "SC04: devDependencies に @types/jest が含まれる"
  else
    _fail "SC04: devDependencies に @types/jest が含まれない"
  fi
fi
cleanup_dir "$SC04_DIR"

# -------------------------------------------------------------------
# SC05: fastify + Dockerfile
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC05: fastify + Dockerfile"
_log "================================================================"
SC05_DIR="$(mktemp -d)"
SC05_INPUTS="fastify-app
book000
fastify-app
A Fastify HTTP server
book000
MIT


3
1
n
y
n
n
"
SC05_OUT=$(run_docker_scenario "SC05" "$SC05_INPUTS" "$SC05_DIR" "$TEST_SCRIPT")
echo "$SC05_OUT" | tail -15

assert_file_exists "$SC05_DIR" "package.json"   "SC05"
assert_file_exists "$SC05_DIR" "src/main.ts"    "SC05"
assert_file_exists "$SC05_DIR" "Dockerfile"     "SC05"
assert_file_exists "$SC05_DIR" "entrypoint.sh"  "SC05"
assert_file_exists "$SC05_DIR" ".github/workflows/docker.yml" "SC05"
assert_json_field  "$SC05_DIR" "package.json" "j.name" "@book000/fastify-app" "SC05"
# docker.yml のイメージ名が置換されているか
if [[ -f "$SC05_DIR/.github/workflows/docker.yml" ]]; then
  if grep -q "book000/fastify-app" "$SC05_DIR/.github/workflows/docker.yml"; then
    _pass "SC05: docker.yml のイメージ名が置換されている"
  else
    _fail "SC05: docker.yml のイメージ名が置換されていない"
    head -20 "$SC05_DIR/.github/workflows/docker.yml"
  fi
fi
cleanup_dir "$SC05_DIR"

# -------------------------------------------------------------------
# SC06: discord-bot + ESM + data/ .gitignore 追加
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC06: discord-bot + ESM + data/"
_log "================================================================"
SC06_DIR="$(mktemp -d)"
SC06_INPUTS="discord-bot
book000
discord-bot
A Discord bot
book000
MIT


4
2
n
n
y
n
"
SC06_OUT=$(run_docker_scenario "SC06" "$SC06_INPUTS" "$SC06_DIR" "$TEST_SCRIPT")
echo "$SC06_OUT" | tail -15

assert_file_exists "$SC06_DIR" "package.json"    "SC06"
assert_file_exists "$SC06_DIR" "src/main.ts"     "SC06"
assert_file_exists "$SC06_DIR" "src/config.ts"   "SC06"
assert_file_exists "$SC06_DIR" "src/discord.ts"  "SC06"
# ESM: package.json に type: module
if [[ -f "$SC06_DIR/package.json" ]]; then
  if node -e "const j=require('$SC06_DIR/package.json'); process.exit(j.type==='module' ? 0 : 1)" 2>/dev/null; then
    _pass "SC06: package.json に type=module が設定されている"
  else
    _fail "SC06: package.json に type=module が設定されていない（ESM 選択したのに）"
  fi
fi
# .gitignore に data/ が含まれるか
if [[ -f "$SC06_DIR/.gitignore" ]]; then
  if grep -q "data/" "$SC06_DIR/.gitignore"; then
    _pass "SC06: .gitignore に data/ が含まれている"
  else
    _fail "SC06: .gitignore に data/ が含まれていない"
  fi
fi
cleanup_dir "$SC06_DIR"

# -------------------------------------------------------------------
# SC07: 無効なバリアント番号（範囲外 → 既定値 base にフォールバック）
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC07: 無効なバリアント番号 → 既定値フォールバック"
_log "================================================================"
SC07_DIR="$(mktemp -d)"
SC07_INPUTS="test-project
book000
test-project
Test
book000
MIT


99
abc
0
1
1
n
n
n
n
"
SC07_OUT=$(run_docker_scenario "SC07" "$SC07_INPUTS" "$SC07_DIR" "$TEST_SCRIPT")
echo "$SC07_OUT" | tail -15

# 無効選択 → 既定値 (base) → base 固有ファイルのみ存在
assert_file_exists     "$SC07_DIR" "src/main.ts"    "SC07"
assert_file_not_exists "$SC07_DIR" "src/discord.ts" "SC07"
assert_output_contains "$SC07_OUT" "既定値を使用します" "SC07"
cleanup_dir "$SC07_DIR"

# -------------------------------------------------------------------
# SC08: 既存ファイルがある場合の上書き拒否 → 中断
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC08: 既存ファイル → 上書き拒否 → 中断"
_log "================================================================"
SC08_DIR="$(mktemp -d)"
echo '{"name":"existing-sentinel"}' > "$SC08_DIR/package.json"
SC08_INPUTS="new-project
book000
new-project
New project
book000
MIT


1
1
n
n
n
n
n
"
SC08_OUT=$(run_docker_scenario "SC08" "$SC08_INPUTS" "$SC08_DIR" "$TEST_SCRIPT")
echo "$SC08_OUT" | tail -15

assert_output_contains "$SC08_OUT" "既に存在します" "SC08"
assert_output_contains "$SC08_OUT" "中断" "SC08"
# package.json が上書きされていないことを確認
if [[ -f "$SC08_DIR/package.json" ]]; then
  if node -e "const j=require('$SC08_DIR/package.json'); process.exit(j.name==='existing-sentinel' ? 0 : 1)" 2>/dev/null; then
    _pass "SC08: package.json が上書きされていない（中断動作が正常）"
  else
    _fail "SC08: package.json が上書きされてしまった"
  fi
fi
cleanup_dir "$SC08_DIR"

# -------------------------------------------------------------------
# SC09: 既存ファイルがある場合の上書き承認 → 続行
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC09: 既存ファイル → 上書き承認 → 続行"
_log "================================================================"
SC09_DIR="$(mktemp -d)"
echo '{"name":"existing-sentinel"}' > "$SC09_DIR/package.json"
SC09_INPUTS="overwrite-project
book000
overwrite-project
Overwrite test
book000
MIT


1
1
n
n
n
n
y
"
SC09_OUT=$(run_docker_scenario "SC09" "$SC09_INPUTS" "$SC09_DIR" "$TEST_SCRIPT")
echo "$SC09_OUT" | tail -15

assert_output_contains "$SC09_OUT" "セットアップ完了" "SC09"
assert_json_field "$SC09_DIR" "package.json" "j.name" "@book000/overwrite-project" "SC09"
cleanup_dir "$SC09_DIR"

# -------------------------------------------------------------------
# SC10: irm | iex セッション状態リーク確認
# スクリプトが iex で実行された後に StrictMode / ErrorActionPreference が
# セッションに残留しないことを確認する
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "SC10: irm | iex セッション状態リーク確認"
_log "================================================================"
SC10_DIR="$(mktemp -d)"
SC10_INPUTS="state-check-project
book000
state-check-project
State check
book000
MIT


1
1
n
n
n
n
"

SC10_WRAPPER="$(mktemp /tmp/session-state-check-XXXXXX.ps1)"
cat > "$SC10_WRAPPER" << 'PWSH_EOF'
# セッション状態リークチェック用ラッパー
# setup.ps1 を iex で実行し（irm | iex と同等）、実行前後のセッション状態を比較する

# 実行前の状態を記録
$beforeEAP = $ErrorActionPreference
Set-StrictMode -Off

# setup.ps1 を iex で実行（irm | iex と同等の挙動）
$scriptContent = Get-Content /tmp/setup.ps1 -Raw
Invoke-Expression $scriptContent

# 実行後の状態を確認
$afterEAP = $ErrorActionPreference

# StrictMode リークチェック:
# StrictMode -Version Latest が残っていれば、存在しないプロパティアクセスで例外が出る
$strictLeaked = $false
try {
  $obj = [PSCustomObject]@{ foo = 'bar' }
  $null = $obj.nonexistent_property_xyz  # StrictMode なしでは $null、あれば例外
} catch {
  $strictLeaked = $true
}

# 結果出力
Write-Host ""
Write-Host "=== SESSION STATE CHECK ===" -ForegroundColor Magenta
Write-Host "ErrorActionPreference before iex: $beforeEAP"
Write-Host "ErrorActionPreference after  iex: $afterEAP"
if ($beforeEAP -ne $afterEAP) {
  Write-Host "LEAK_DETECTED: ErrorActionPreference changed $beforeEAP -> $afterEAP" -ForegroundColor Red
} else {
  Write-Host "OK: ErrorActionPreference not leaked" -ForegroundColor Green
}
if ($strictLeaked) {
  Write-Host "LEAK_DETECTED: Set-StrictMode -Version Latest leaked into session" -ForegroundColor Red
} else {
  Write-Host "OK: Set-StrictMode not leaked" -ForegroundColor Green
}
Write-Host "==========================="
PWSH_EOF

SC10_OUT=$(printf '%s' "$SC10_INPUTS" | docker run \
  --rm --interactive \
  --add-host=host.docker.internal:host-gateway \
  -v "$TEST_SCRIPT:/tmp/setup.ps1:ro" \
  -v "$SC10_WRAPPER:/tmp/session-check.ps1:ro" \
  -v "$SC10_DIR:/workspace" \
  "$DOCKER_IMAGE" \
  pwsh -Command "
    Set-Location /workspace
    . /tmp/session-check.ps1
  " 2>&1) || true

echo "$SC10_OUT" | grep -E "(SESSION STATE|before|after|LEAK|OK:)" | head -10

if echo "$SC10_OUT" | grep -q "LEAK_DETECTED"; then
  _fail "SC10: セッション状態リークが検出された"
else
  _pass "SC10: セッション状態リークなし（ErrorActionPreference・StrictMode 正常）"
fi

rm -f "$SC10_WRAPPER"
cleanup_dir "$SC10_DIR"

# -------------------------------------------------------------------
# SC11: [--full のみ] pnpm install + pnpm run lint でフル検証
# -------------------------------------------------------------------
if [[ "$FULL_MODE" == "true" ]]; then
  _log ""
  _log "================================================================"
  _log "SC11: [full] pnpm install + pnpm run lint 検証（base CJS）"
  _log "================================================================"

  # pnpm install を含むスクリプトを別途準備
  FULL_SCRIPT=$(prepare_test_script "false")

  SC11_DIR="$(mktemp -d)"
  SC11_INPUTS="full-test-project
book000
full-test-project
Full install test
book000
MIT


1
1
n
n
n
n
"
  SC11_OUT=$(run_docker_scenario "SC11" "$SC11_INPUTS" "$SC11_DIR" "$FULL_SCRIPT")
  echo "$SC11_OUT" | tail -30

  if [[ -d "$SC11_DIR/node_modules" ]]; then
    _pass "SC11: node_modules が生成されている（pnpm install 成功）"
  else
    _fail "SC11: node_modules が生成されていない（pnpm install 失敗）"
  fi

  # common config ファイルをコピーして lint を実行
  cp "$REPO_ROOT/nodejs/common/tsconfig.json"     "$SC11_DIR/tsconfig.json"
  cp "$REPO_ROOT/nodejs/common/eslint.config.mjs" "$SC11_DIR/eslint.config.mjs"
  cp "$REPO_ROOT/nodejs/common/.prettierrc.yml"   "$SC11_DIR/.prettierrc.yml"

  LINT_OUT=$(docker run --rm \
    -v "$SC11_DIR:/workspace" \
    -v "$PNPM_STORE_VOLUME:/root/.local/share/pnpm/store" \
    -e PNPM_HOME=/root/.local/share/pnpm \
    "$DOCKER_IMAGE" \
    pwsh -Command "
      Set-Location /workspace
      pnpm run lint
      exit \$LASTEXITCODE
    " 2>&1) || true
  echo "$LINT_OUT" | tail -20

  if echo "$LINT_OUT" | grep -qiE "^(error|ERR_|failed)"; then
    _fail "SC11: pnpm run lint でエラーが発生した"
  else
    _pass "SC11: pnpm run lint が成功した"
  fi

  rm -f "$FULL_SCRIPT"
  cleanup_dir "$SC11_DIR"
fi

# -------------------------------------------------------------------
# 結果サマリー
# -------------------------------------------------------------------
_log ""
_log "================================================================"
_log "テスト結果"
_log "================================================================"
echo -e "${GREEN}  PASS: $PASS_COUNT${NC}"
echo -e "${RED}  FAIL: $FAIL_COUNT${NC}"
_log ""

if [[ $FAIL_COUNT -gt 0 ]]; then
  _log "❌ ${FAIL_COUNT} 件のテストが失敗しました"
  exit 1
else
  _log "✅ 全テスト合格"
  exit 0
fi
