#!/usr/bin/env python3
import argparse
import fnmatch
import os
import sys
from datetime import datetime


UNITS = {"B": 1, "K": 1024, "M": 1024 ** 2, "G": 1024 ** 3, "T": 1024 ** 4}


def parse_size(text):
    text = text.strip().upper()
    if not text:
        raise argparse.ArgumentTypeError("empty size")
    if text[-1] in UNITS:
        number, factor = text[:-1], UNITS[text[-1]]
    else:
        number, factor = text, 1
    try:
        value = float(number)
    except ValueError:
        raise argparse.ArgumentTypeError("invalid size: {!r}".format(text))
    if value < 0:
        raise argparse.ArgumentTypeError("size must not be negative")
    return int(value * factor)


def human(size):
    value = float(size)
    for unit in ("B", "K", "M", "G", "T"):
        if value < 1024 or unit == "T":
            if unit == "B":
                return "{}{}".format(int(value), unit)
            return "{:.1f}{}".format(value, unit)
        value /= 1024


def is_hidden(name):
    return name.startswith(".")


def excluded(name, patterns):
    return any(fnmatch.fnmatch(name, pattern) for pattern in patterns)


def walk(root, include_hidden, follow_symlinks, max_depth, excludes):
    root = os.path.abspath(root)
    base_depth = root.rstrip(os.sep).count(os.sep)
    for current, dirs, files in os.walk(root, followlinks=follow_symlinks):
        depth = current.count(os.sep) - base_depth
        if max_depth is not None and depth >= max_depth:
            dirs[:] = []
        dirs[:] = [
            d for d in dirs
            if (include_hidden or not is_hidden(d)) and not excluded(d, excludes)
        ]
        for name in files:
            if not include_hidden and is_hidden(name):
                continue
            if excluded(name, excludes):
                continue
            path = os.path.join(current, name)
            try:
                info = os.stat(path, follow_symlinks=follow_symlinks)
            except OSError:
                continue
            yield path, info.st_size, info.st_mtime


def collect(args):
    results = []
    for path, size, mtime in walk(
        args.path,
        args.hidden,
        args.follow_symlinks,
        args.max_depth,
        args.exclude,
    ):
        if size >= args.min_size:
            results.append((path, size, mtime))
    return results


def sort_results(results, key, reverse):
    if key == "size":
        results.sort(key=lambda item: item[1], reverse=not reverse)
    elif key == "newest":
        results.sort(key=lambda item: item[2], reverse=not reverse)
    elif key == "oldest":
        results.sort(key=lambda item: item[2], reverse=reverse)
    elif key == "name":
        results.sort(key=lambda item: os.path.basename(item[0]).lower(), reverse=reverse)
    else:
        results.sort(key=lambda item: item[0], reverse=reverse)
    return results


def format_row(path, size, mtime, human_readable):
    size_text = human(size) if human_readable else str(size)
    when = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")
    return "{:>10}  {}  {}".format(size_text, when, path)


def build_parser():
    parser = argparse.ArgumentParser()
    parser.add_argument("path", nargs="?", default=".")
    parser.add_argument("-s", "--min-size", type=parse_size, default="1M")
    parser.add_argument(
        "-S", "--sort",
        choices=("size", "oldest", "newest", "name", "path"),
        default="size",
    )
    parser.add_argument("-n", "--top", type=int, default=None)
    parser.add_argument("-H", "--human", action="store_true")
    parser.add_argument("-a", "--hidden", action="store_true")
    parser.add_argument("-r", "--reverse", action="store_true")
    parser.add_argument("-L", "--follow-symlinks", action="store_true")
    parser.add_argument("-d", "--max-depth", type=int, default=None)
    parser.add_argument("-x", "--exclude", action="append", default=[])
    parser.add_argument("-c", "--total", action="store_true")
    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    if not os.path.isdir(args.path):
        print("error: not a directory: {}".format(args.path), file=sys.stderr)
        return 2
    results = collect(args)
    sort_results(results, args.sort, args.reverse)
    if args.top is not None:
        results = results[: args.top]
    for path, size, mtime in results:
        print(format_row(path, size, mtime, args.human))
    if args.total:
        total = sum(size for _, size, _ in results)
        total_text = human(total) if args.human else str(total)
        print("{} files, {} total".format(len(results), total_text), file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
