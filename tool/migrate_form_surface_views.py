#!/usr/bin/env python3
"""Replace _isDark(context) theme ternaries with FormSurfaceColors in module views."""

from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MODULES = ROOT / "lib" / "app" / "modules"

# Order matters: longer / more specific patterns first.
TERNARY_REPLACEMENTS: list[tuple[str, str]] = [
    (r"_isDark\(context\) \? Colors\.white : AppColors\.textColorPrimary", "FormSurfaceColors.of(context).headline"),
    (r"_isDark\(context\) \? Colors\.white70 : AppColors\.textColorSecondary", "FormSurfaceColors.of(context).secondary"),
    (r"_isDark\(context\) \? Colors\.white70 : AppColors\.designPlaceholder", "FormSurfaceColors.of(context).hint"),
    (r"_isDark\(context\) \? Colors\.white : const Color\(0xFF2E2E2E\)", "FormSurfaceColors.of(context).headline"),
    (r"_isDark\(context\) \? Colors\.white : const Color\(0xFF1F2937\)", "FormSurfaceColors.of(context).headline"),
    (r"_isDark\(context\) \? Colors\.white : const Color\(0xFF1A1A1A\)", "FormSurfaceColors.of(context).headline"),
    (r"_isDark\(context\) \? Colors\.white : const Color\(0xFF111111\)", "FormSurfaceColors.of(context).headline"),
    (r"_isDark\(context\) \? Colors\.white : Colors\.black", "FormSurfaceColors.of(context).headline"),
    (r"_isDark\(context\) \? Colors\.white : Colors\.black87", "FormSurfaceColors.of(context).headline"),
    (r"_isDark\(context\) \? const Color\(0xFF3A3A3C\) : const Color\(0xFFEDEDED\)", "FormSurfaceColors.of(context).divider"),
    (r"_isDark\(context\) \? const Color\(0xFF2C2C2E\) : Colors\.white", "FormSurfaceColors.of(context).dropdownBg"),
    (r"_isDark\(context\) \? const Color\(0xFF2C2C2E\) : const Color\(0xFFF4F3EF\)", "FormSurfaceColors.of(context).impactBannerBg"),
    (r"_isDark\(context\) \? const Color\(0xFF1C1C1E\) : const Color\(0xFFF9F8F6\)", "FormSurfaceColors.of(context).scaffold"),
    (r"_isDark\(context\) \? const Color\(0xFF1C1C1E\) : const Color\(0xFFF8F8F8\)", "FormSurfaceColors.of(context).tileBg"),
    (r"_isDark\(context\) \? const Color\(0xFF1F1F1F\) : AppColors\.colorWhite", "FormSurfaceColors.of(context).inputFill"),
    (r"_isDark\(context\) \? const Color\(0xFF1F1F1F\) : Colors\.white", "FormSurfaceColors.of(context).inputFill"),
    (r"_isDark\(context\) \? const Color\(0xFF2C2C2E\) : Colors\.white", "FormSurfaceColors.of(context).card"),
    (r"_isDark\(context\) \? const Color\(0xFF8E8E93\) : const Color\(0xFF6B7280\)", "FormSurfaceColors.of(context).sectionLabel"),
    (r"_isDark\(context\) \? const Color\(0xFF8E8E93\) : const Color\(0xFF8A8A8A\)", "FormSurfaceColors.of(context).hint"),
    (r"_isDark\(context\) \? const Color\(0xFFAEAEB2\) : const Color\(0xFF3D3D3D\)", "FormSurfaceColors.of(context).secondary"),
    (r"_isDark\(context\) \? const Color\(0xFFAEAEB2\) : const Color\(0xFF4A4A4A\)", "FormSurfaceColors.of(context).secondary"),
    (r"_isDark\(context\) \? Colors\.white : AppColors\.colorWhite", "FormSurfaceColors.of(context).headline"),
    (r"Theme\.of\(context\)\.brightness == Brightness\.dark", "FormSurfaceColors.of(context).isDark"),
    (r"final isDark = _isDark\(context\);", "final c = FormSurfaceColors.of(context);"),
    (r"final isDark = Theme\.of\(context\)\.brightness == Brightness\.dark;", "final c = FormSurfaceColors.of(context);"),
]

# After renaming isDark -> c.isDark for remaining local uses
LOCAL_REPLACEMENTS: list[tuple[str, str]] = [
    (r"\bisDark \? const Color\(0xFF2C2C2E\) : Colors\.white\b", "c.dropdownBg"),
    (r"\bisDark \? const Color\(0xFF2C2C2E\) : const Color\(0xFFF4F3EF\)\b", "c.impactBannerBg"),
    (r"\bisDark \? Colors\.white : const Color\(0xFF2E2E2E\)\b", "c.headline"),
    (r"\bisDark \? Colors\.white : const Color\(0xFF1F2937\)\b", "c.headline"),
    (r"\bisDark \? const Color\(0xFF8E8E93\) : const Color\(0xFF8A8A8A\)\b", "c.hint"),
    (r"\bisDark \? const Color\(0xFFAEAEB2\) : const Color\(0xFF3D3D3D\)\b", "c.secondary"),
    (r"\bisDark \? const Color\(0xFF3A3A3C\) : const Color\(0xFFEDEDED\)\b", "c.divider"),
    (r"\bisDark \? const Color\(0xFF3A3A3C\) : Colors\.transparent\b", "c.fieldWellFill"),
    (r"\bisDark \? const Color\(0xFF3A3A3C\) : Colors\.white\b", "c.fill"),
    (r"\bisDark \? Colors\.white : AppColors\.textColorPrimary\b", "c.headline"),
    (r"\bisDark \? Colors\.white70 : AppColors\.textColorSecondary\b", "c.secondary"),
]

_IS_DARK_METHOD = re.compile(
    r"\n\s*bool _isDark\(BuildContext context\) =>[^\n]*;\n",
    re.MULTILINE,
)


def import_path_for(file: Path) -> str:
    depth = len(file.relative_to(MODULES).parts) - 1  # views/file.dart -> module depth
  # modules/foo/views/x.dart -> ../../../
    ups = depth + 2  # to lib/app from views
    return f"import '{('../..' * ups)[2:]}/core/theme/form_surface_colors.dart';"


def ensure_import(text: str, imp: str) -> str:
    if "form_surface_colors.dart" in text:
        return text
    anchor = "import '../../../core/"
    if "rent/" in str(imp) or "/rent/" in imp:
        pass
    for line in text.splitlines():
        if line.startswith("import '") and "/core/" in line:
            idx = text.find(line) + len(line) + 1
            return text[:idx] + imp + "\n" + text[idx:]
    m = re.search(r"(import [^;]+;\n)+", text)
    if m:
        return text[: m.end()] + imp + "\n" + text[m.end() :]
    return imp + "\n" + text


def migrate_file(path: Path) -> tuple[bool, list[str]]:
    text = path.read_text(encoding="utf-8")
    if "bool _isDark" not in text and "_isDark(context)" not in text:
        return False, []

    orig = text
    for pat, repl in TERNARY_REPLACEMENTS:
        text = re.sub(pat, repl, text)
    for pat, repl in LOCAL_REPLACEMENTS:
        text = re.sub(pat, repl, text)

    text = _IS_DARK_METHOD.sub("\n", text)

    remaining = len(re.findall(r"_isDark\(context\)", text))
    if remaining == 0 or remaining < len(re.findall(r"_isDark\(context\)", orig)):
        imp = import_path_for(path)
        # fix import path
        rel_parts = path.relative_to(MODULES).parts
        ups = len(rel_parts)  # rent/foo/views -> 4 parts, need ../../../../ 
        prefix = "/".join([".."] * ups)
        imp = f"import '{prefix}/core/theme/form_surface_colors.dart';"
        text = ensure_import(text, imp)

    if text == orig:
        leftovers = sorted(set(re.findall(r"_isDark\(context\)[^\n]{0,80}", text)))
        return False, leftovers

    path.write_text(text, encoding="utf-8")
    leftovers = sorted(set(re.findall(r"_isDark\(context\)", text)))
    return True, leftovers


def main() -> None:
    changed = 0
    leftover_files: list[str] = []
    for path in sorted(MODULES.rglob("*view*.dart")):
        ok, left = migrate_file(path)
        if ok:
            changed += 1
            rel = path.relative_to(ROOT)
            print(f"OK {rel} ({len(left)} _isDark left)")
            if left:
                leftover_files.append(str(rel))
    print(f"\nUpdated {changed} files")
    if leftover_files:
        print("Files with remaining _isDark:", ", ".join(leftover_files[:20]))


if __name__ == "__main__":
    main()
