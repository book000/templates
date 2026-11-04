"""app.add のテスト。"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app import add


def test_add():
    assert add(1, 2) == 3
