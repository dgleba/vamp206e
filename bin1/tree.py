#!/usr/bin/env python3
import os
import argparse

'''
If tree is not installed, use this..

'''

def tree(path=".", prefix="", include_files=False, max_depth=None, depth=0):
    if max_depth is not None and depth > max_depth:
        return

    try:
        entries = sorted(os.listdir(path))
    except PermissionError:
        return

    filtered = []
    for name in entries:
        full = os.path.join(path, name)
        is_dir = os.path.isdir(full)

        if is_dir:
            filtered.append(name)
        elif include_files:
            filtered.append(name)

    for index, name in enumerate(filtered):
        full_path = os.path.join(path, name)
        connector = "└── " if index == len(filtered) - 1 else "├── "
        print(prefix + connector + name)

        if os.path.isdir(full_path):
            extension = "    " if index == len(filtered) - 1 else "│   "
            tree(
                full_path,
                prefix + extension,
                include_files=include_files,
                max_depth=max_depth,
                depth=depth + 1
            )

def parse_args():
    parser = argparse.ArgumentParser(description="Folder tree viewer")
    parser.add_argument("-f", action="store_true", help="include files (default: only directories)")
    parser.add_argument("-d", "--depth", type=int, default=None, help="limit depth")
    parser.add_argument("path", nargs="?", default=".", help="starting directory")
    return parser.parse_args()

if __name__ == "__main__":
    args = parse_args()
    tree(args.path, include_files=args.f, max_depth=args.depth)

