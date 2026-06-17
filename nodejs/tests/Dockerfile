# Node.js テンプレート monkey test 用 Docker イメージ
# PowerShell + Node.js 24 + pnpm を含む Ubuntu 24.04 ベース
FROM mcr.microsoft.com/powershell:ubuntu-24.04

# 基本ツールのインストール
RUN apt-get update -qq && apt-get install -y -qq \
    curl \
    ca-certificates \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Node.js 24 のインストール（NodeSource）
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# pnpm を corepack で有効化
RUN corepack enable && corepack prepare pnpm@latest --activate

# バージョン確認
RUN node --version && pnpm --version && pwsh --version

WORKDIR /workspace
