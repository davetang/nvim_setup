#!/usr/bin/env python3
"""Recursively scan a directory tree and report files at or above a size threshold.

For every regular file under the given path whose size is >= the minimum, one
line is printed with the file's size, its last-modified time, and its path. The
result set can be sorted (by size, age, or name), trimmed to the top N, shown
with human-readable sizes, and filtered (hidden files, glob excludes, maximum
depth, symlink handling).

Example:
    ./scan_large_files.py ~/data -s 10M -S newest -H -n 20

This is the fully-annotated "answer key" mirror of scan_large_files.py: the code
is identical, only documentation has been added. Standard library only.
"""
import argparse
import fnmatch
import os
import sys
from datetime import datetime


# Multipliers for the size-suffix letters accepted by --min-size. Binary
# (1024-based) units, so "1K" is 1024 bytes, "1M" is 1024*1024, and so on.
UNITS = {"B": 1, "K": 1024, "M": 1024 ** 2, "G": 1024 ** 3, "T": 1024 ** 4}


def parse_size(text):
    """Convert a human-friendly size string into an integer number of bytes.

    Accepts an optional single-letter unit suffix from UNITS (case-insensitive),
    e.g. "500K", "10M", "1.5G"; a bare number ("1048576") is treated as bytes.
    Raises argparse.ArgumentTypeError on malformed or negative input so argparse
    reports a clean "invalid value" message instead of dumping a traceback.
    """
    text = text.strip().upper()
    if not text:
        raise argparse.ArgumentTypeError("empty size")
    # If the last character is a known unit letter, peel it off as the factor
    # and treat the rest as the number; otherwise the whole string is bytes.
    if text[-1] in UNITS:
        number, factor = text[:-1], UNITS[text[-1]]
    else:
        number, factor = text, 1
    try:
        # float() (not int()) so fractional sizes like "1.5M" are allowed.
        value = float(number)
    except ValueError:
        raise argparse.ArgumentTypeError("invalid size: {!r}".format(text))
    if value < 0:
        raise argparse.ArgumentTypeError("size must not be negative")
    return int(value * factor)


def human(size):
    """Format a byte count as a short human-readable string (2048 -> '2.0K').

    Steps down through B, K, M, G, T (1024-based), stopping at the first unit
    where the value is below 1024, or at T as the largest unit. Bytes print as a
    whole number; every larger unit keeps one decimal place.
    """
    value = float(size)
    for unit in ("B", "K", "M", "G", "T"):
        if value < 1024 or unit == "T":
            if unit == "B":
                return "{}{}".format(int(value), unit)
            return "{:.1f}{}".format(value, unit)
        value /= 1024


def is_hidden(name):
    """Return True for dotfiles/dotdirs (names beginning with '.')."""
    return name.startswith(".")


def excluded(name, patterns):
    """Return True if `name` matches any of the shell-style glob `patterns`."""
    return any(fnmatch.fnmatch(name, pattern) for pattern in patterns)


def walk(root, include_hidden, follow_symlinks, max_depth, excludes):
    """Yield (path, size, mtime) for each file under `root` that passes the filters.

    Applies the hidden-file, exclude-glob, max-depth and symlink options while
    descending. A generator, so callers stream results instead of building the
    whole list up front.
    """
    root = os.path.abspath(root)
    # Separator count of the root, used as a baseline so `depth` below is
    # measured relative to the starting directory (root itself is depth 0).
    base_depth = root.rstrip(os.sep).count(os.sep)
    for current, dirs, files in os.walk(root, followlinks=follow_symlinks):
        depth = current.count(os.sep) - base_depth
        # Pruning os.walk requires mutating `dirs` IN PLACE (dirs[:] = ...);
        # rebinding the name (dirs = ...) would not change what os.walk visits.
        # Emptying it stops os.walk from descending any deeper here.
        # Depth counts levels *below* the start dir: -d 0 = this dir only,
        # -d 1 also includes one level of subdirectories (differs from
        # `find -maxdepth`, which would call the start dir's own files depth 1).
        if max_depth is not None and depth >= max_depth:
            dirs[:] = []
        # Drop hidden and excluded directories so we never descend into them.
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
                # follow_symlinks=False reports on the link itself (lstat-style);
                # True reports the target. Unreadable files / broken links raise
                # OSError, which we skip rather than abort the whole scan.
                info = os.stat(path, follow_symlinks=follow_symlinks)
            except OSError:
                continue
            yield path, info.st_size, info.st_mtime


def collect(args):
    """Gather every file >= args.min_size into a list of (path, size, mtime)."""
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
    """Sort `results` in place by `key`, honouring the --reverse flag.

    size/newest default to DESCENDING (largest / most-recent first) via
    `reverse=not reverse`; oldest/name/path default to ASCENDING. The --reverse
    flag flips whichever order was chosen. Tuple layout: (path, size, mtime).
    """
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
    """Build one output line: right-aligned size, 'YYYY-MM-DD HH:MM' mtime, path."""
    size_text = human(size) if human_readable else str(size)
    when = datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M")
    return "{:>10}  {}  {}".format(size_text, when, path)


def build_parser():
    """Construct the argparse parser defining every command-line option."""
    parser = argparse.ArgumentParser(
        description="Scan a directory tree for files at or above a size threshold.",
    )
    parser.add_argument(
        "path", nargs="?", default=".",
        help="directory to scan (default: current directory)",
    )
    # argparse passes a *string* default through `type`, so the effective default
    # here is parse_size("1M") == 1048576 (an int), not the literal string "1M".
    parser.add_argument(
        "-s", "--min-size", type=parse_size, default="1M",
        help="only report files this size or larger, e.g. 500K, 10M, 2G (default: 1M)",
    )
    parser.add_argument(
        "-S", "--sort",
        choices=("size", "oldest", "newest", "name", "path"),
        default="size",
        help="ordering of the output (default: size)",
    )
    parser.add_argument(
        "-n", "--top", type=int, default=None,
        help="show only the first N results after sorting",
    )
    parser.add_argument(
        "-H", "--human", action="store_true",
        help="print sizes as human-readable units (e.g. 2.0M)",
    )
    parser.add_argument(
        "-a", "--hidden", action="store_true",
        help="include hidden files and directories (dotfiles)",
    )
    parser.add_argument(
        "-r", "--reverse", action="store_true",
        help="reverse the chosen sort order",
    )
    parser.add_argument(
        "-L", "--follow-symlinks", action="store_true",
        help="follow symbolic links (directories and files)",
    )
    parser.add_argument(
        "-d", "--max-depth", type=int, default=None,
        help="do not descend more than this many levels below the start dir",
    )
    parser.add_argument(
        "-x", "--exclude", action="append", default=[],
        help="glob of names to skip; repeatable, e.g. -x '*.log' -x node_modules",
    )
    parser.add_argument(
        "-c", "--total", action="store_true",
        help="print a trailing 'N files, TOTAL' summary to stderr",
    )
    return parser


def main(argv=None):
    """Parse arguments, scan, sort and print; return a process exit code."""
    args = build_parser().parse_args(argv)
    if not os.path.isdir(args.path):
        print("error: not a directory: {}".format(args.path), file=sys.stderr)
        return 2
    results = collect(args)
    sort_results(results, args.sort, args.reverse)
    if args.top is not None:
        # Slice AFTER sorting so --top yields the largest/newest/... N.
        results = results[: args.top]
    for path, size, mtime in results:
        print(format_row(path, size, mtime, args.human))
    if args.total:
        # Summary goes to stderr so stdout stays a clean list you can pipe.
        total = sum(size for _, size, _ in results)
        total_text = human(total) if args.human else str(total)
        print("{} files, {} total".format(len(results), total_text), file=sys.stderr)
    return 0


if __name__ == "__main__":
    # Propagate main()'s return value as the process exit status.
    sys.exit(main())
