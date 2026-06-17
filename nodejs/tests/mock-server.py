#!/usr/bin/env python3
"""
Node.js テンプレート monkey test 用モックサーバー

以下の URL をシミュレートする:
  - book000/templates の raw URL → ローカルリポジトリのファイルを返す
  - github/gitignore の raw URL  → mocks/Node.gitignore を返す
  - api.github.com/licenses      → モック JSON を返す
"""

import json
import os
import sys
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path

# このスクリプトの 2 階層上がリポジトリルート (nodejs/tests/ → nodejs/ → repo root)
REPO_ROOT = Path(__file__).resolve().parent.parent.parent
MOCKS_DIR = Path(__file__).resolve().parent / "mocks"


class MockHandler(BaseHTTPRequestHandler):
    """モックリクエストハンドラー"""

    def log_message(self, format: str, *args) -> None:  # noqa: A002
        """アクセスログをリポジトリルートからの相対パスで出力する"""
        print(f"[mock] {self.address_string()} {format % args}", flush=True)

    def do_GET(self) -> None:
        """GET リクエストを処理する"""
        raw_path = self.path.split("?")[0].lstrip("/")

        # GitHub License API モック: /api-licenses/<license>
        if raw_path.startswith("api-licenses/"):
            license_id = raw_path[len("api-licenses/"):]
            self._serve_license_mock(license_id)
            return

        # GitHub gitignore モック: /github-gitignore/Node.gitignore
        if raw_path.startswith("github-gitignore/"):
            mock_file = MOCKS_DIR / "Node.gitignore"
            if mock_file.exists():
                self._send_bytes(mock_file.read_bytes(), "text/plain")
            else:
                # フォールバック: 最低限の Node.js .gitignore
                self._send_bytes(
                    b"node_modules/\ndist/\n.env\n", "text/plain"
                )
            return

        # テンプレートファイル: /<path> → リポジトリルートからのファイル
        file_path = REPO_ROOT / raw_path
        if file_path.exists() and file_path.is_file():
            content_type = self._guess_content_type(raw_path)
            self._send_bytes(file_path.read_bytes(), content_type)
        else:
            self.send_error(404, f"Not found: {raw_path}")

    def _serve_license_mock(self, license_id: str) -> None:
        """GitHub ライセンス API のレスポンスをモックする"""
        license_name = license_id.upper()
        # MIT ライセンスのテキストをシンプルに模倣する
        body = (
            f"MIT License\n\n"
            f"Copyright (c) [year] [fullname]\n\n"
            f"Permission is hereby granted, free of charge, to any person obtaining a copy\n"
            f"of this software and associated documentation files (the \"Software\"), to deal\n"
            f"in the Software without restriction, including without limitation the rights\n"
            f"to use, copy, modify, merge, publish, distribute, sublicense, and/or sell\n"
            f"copies of the Software, and to permit persons to whom the Software is\n"
            f"furnished to do so, subject to the following conditions:\n\n"
            f"The above copyright notice and this permission notice shall be included in all\n"
            f"copies or substantial portions of the Software.\n"
        )
        data = json.dumps(
            {"key": license_id.lower(), "name": f"{license_name} License", "body": body}
        )
        self._send_bytes(data.encode(), "application/json")

    def _send_bytes(self, content: bytes, content_type: str) -> None:
        """バイト列をレスポンスとして送信する"""
        self.send_response(200)
        self.send_header("Content-Type", content_type)
        self.send_header("Content-Length", str(len(content)))
        self.end_headers()
        self.wfile.write(content)

    def _guess_content_type(self, path: str) -> str:
        """ファイルパスから Content-Type を推定する"""
        if path.endswith(".json"):
            return "application/json"
        if path.endswith((".yaml", ".yml")):
            return "text/yaml"
        if path.endswith((".ts", ".mjs", ".js")):
            return "text/javascript"
        if path.endswith(".ps1"):
            return "text/plain"
        return "application/octet-stream"


def main() -> None:
    """モックサーバーを起動する"""
    port = int(sys.argv[1]) if len(sys.argv) > 1 else 8080
    server = HTTPServer(("", port), MockHandler)
    print(
        f"[mock-server] port={port} repo_root={REPO_ROOT}",
        flush=True,
    )
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("[mock-server] stopped", flush=True)


if __name__ == "__main__":
    main()
