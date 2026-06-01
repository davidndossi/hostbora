#!/usr/bin/env python3
"""Batch-apply UI trend patterns across module views."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULES = ROOT / "lib" / "app" / "modules"

TOKENS_IMPORT = "import 'package:host_bora/app/core/theme/app_theme_tokens.dart';\n"
SKELETON_IMPORT = "import 'package:host_bora/app/core/widget/skeleton_presets.dart';\n"
ASYNC_IMPORT = "import 'package:host_bora/app/core/widget/async_screen_body.dart';\n"

REPLACEMENTS: list[tuple[re.Pattern[str], str]] = [
    (
        re.compile(
            r"return const Center\(child: CircularProgressIndicator\(\)\);"
        ),
        "return const DefaultScreenSkeleton();",
    ),
    (
        re.compile(
            r"return Center\(child: CircularProgressIndicator\([^)]*\)\);"
        ),
        "return const DefaultScreenSkeleton();",
    ),
    (
        re.compile(
            r"_isDark\(context\)\s*\?\s*Colors\.white\s*:\s*AppColors\.textColorPrimary"
        ),
        "context.tokens.textPrimary",
    ),
    (
        re.compile(
            r"_isDark\(context\)\s*\?\s*Colors\.white70\s*:\s*AppColors\.textColorSecondary"
        ),
        "context.tokens.textSecondary",
    ),
    (
        re.compile(
            r"_isDark\(context\)\s*\?\s*Colors\.white54\s*:\s*AppColors\.textColorSecondary"
        ),
        "context.tokens.textMuted",
    ),
    (
        re.compile(
            r"Theme\.of\(context\)\.brightness == Brightness\.dark\s*\?\s*Colors\.white\s*:\s*AppColors\.textColorPrimary"
        ),
        "context.tokens.textPrimary",
    ),
    (
        re.compile(
            r"Theme\.of\(context\)\.brightness == Brightness\.dark\s*\?\s*Colors\.white70\s*:\s*AppColors\.textColorSecondary"
        ),
        "context.tokens.textSecondary",
    ),
    (
        re.compile(
            r"Theme\.of\(context\)\.brightness == Brightness\.dark\s*\?\s*Colors\.white54\s*:\s*AppColors\.textColorSecondary"
        ),
        "context.tokens.textMuted",
    ),
    # Only non-const Color literals (avoid `const context.tokens` parse errors).
    (
        re.compile(r"(?<!const )Color\(0xFF2C2C2E\)"),
        "context.tokens.cardBackground",
    ),
    (
        re.compile(r"(?<!const )Color\(0xFF3A3A3C\)"),
        "context.tokens.elevatedSurface",
    ),
    (
        re.compile(r"(?<!const )Color\(0xFF1C1C1E\)"),
        "context.tokens.scaffoldBackground",
    ),
]


def ensure_import(content: str, import_line: str) -> str:
    if import_line.strip() in content:
        return content
    if "import 'package:flutter/material.dart';" in content:
        return content.replace(
            "import 'package:flutter/material.dart';",
            "import 'package:flutter/material.dart';\n" + import_line,
            1,
        )
    return import_line + content


def migrate_file(path: Path) -> bool:
    original = path.read_text(encoding="utf-8")
    content = original
    changed = False

    for pattern, repl in REPLACEMENTS:
        new_content, n = pattern.subn(repl, content)
        if n:
            content = new_content
            changed = True

    if "context.tokens" in content and TOKENS_IMPORT.strip() not in content:
        content = ensure_import(content, TOKENS_IMPORT)
        changed = True

    if "DefaultScreenSkeleton" in content and SKELETON_IMPORT.strip() not in content:
        content = ensure_import(content, SKELETON_IMPORT)
        changed = True

    if content != original:
        path.write_text(content, encoding="utf-8")
    return changed


def main() -> None:
    updated = 0
    for path in sorted(MODULES.rglob("*.dart")):
        if migrate_file(path):
            updated += 1
            print(f"updated: {path.relative_to(ROOT)}")
    print(f"\nDone. {updated} files updated.")


if __name__ == "__main__":
    main()
