#!/usr/bin/env python3
"""Syntax-only check of all C# sources with tree-sitter (NOT a compiler: no type/semantic checking).
Used in environments without the .NET SDK / AutoCAD. The real gate is BuildRelease.bat on Windows."""
import pathlib, sys
import tree_sitter_c_sharp as tscs
from tree_sitter import Language, Parser

root = pathlib.Path(__file__).resolve().parents[1]
parser = Parser(Language(tscs.language()))
bad = 0
files = sorted(p for p in root.rglob("*.cs") if "bin" not in p.parts and "obj" not in p.parts)
for f in files:
    tree = parser.parse(f.read_bytes())
    errs = []
    def walk(n):
        if n.type == "ERROR" or n.is_missing:
            errs.append(n)
        for c in n.children:
            walk(c)
    walk(tree.root_node)
    if errs:
        bad += 1
        for e in errs[:5]:
            print(f"{f.relative_to(root)}:{e.start_point[0]+1}:{e.start_point[1]+1}: {'MISSING ' + e.type if e.is_missing else 'syntax error'}")
print(f"{len(files)} C# files parsed, {bad} with syntax errors")
sys.exit(1 if bad else 0)
