# Python for R &amp; Perl programmers

A Pythonic cheatsheet for someone already fluent in R and Perl. Every entry maps
a habit you have onto the idiom a fluent Python programmer reaches for. Open it
anytime with `:Python`. Idioms target Python 3.10+.

## Mental model — what's genuinely different

* **Zero-indexed, half-open.** `x[0]` is first; `x[1:3]` is items 1–2. (R is 1-indexed and inclusive.)
* **Whitespace is syntax.** Indentation defines blocks — no `{ }`, no `end`. Four spaces, never tabs.
* **No sigils.** No `$ @ %`, no `<-`. One name, one `=`, whatever the type.
* **Everything is an object** with methods: prefer `x.method()` over `f(x)`.
* **"One obvious way."** Python prizes a single readable idiom over Perl's TIMTOWTDI.
* **Batteries included.** Reach for the standard library (`import`) before writing or installing.

## Environment &amp; running code

| Command | Does |
|---|---|
| `python -m venv .venv && source .venv/bin/activate` | Create + activate a project sandbox (like `renv`); `deactivate` to exit |
| `pip install pandas numpy` | Install into the active venv; `pip freeze > requirements.txt` to record |
| `uv venv && uv pip install pandas` | `uv` — the modern, fast installer/resolver; increasingly the default |
| `python script.py` | Run a script; args land in `sys.argv` (Perl's `@ARGV`) |
| `python -m pytest` | Run a module as a program (`http.server`, `pytest`, `json.tool`) |
| `ipython` | The REPL you want — tab-complete, `?` for help; `jupyter lab` = the RMarkdown analogue |
| `ruff check . && ruff format .` | Lint + format in one fast tool (already in your Neovim LSP) |

## Variables, scalars &amp; f-strings

```python
x = 42            # no `my`, no `<-`, no sigils
name = "Ada"      # ' and " are interchangeable
f"{name} is {age} ({age/12:.1f} yr)"   # f-strings: the one true interpolation
f"{x = }"         # self-documenting debug -> "x = 42"
a, b = b, a       # tuple unpacking: swap with no temp
first, *rest = items
```

* `x is None` / `x is not None` — test for "undef" with `is`, never `==` (like `is.null()` / `defined`).
* Augmented assignment `+= -= *=`; there is **no** `++` / `--`.
* Convert explicitly: `int("10")`, `str(10)`, `float("1.5")` — Python does not auto-coerce str↔num like Perl.

## The four core containers

| Task | R | Perl | Python |
|---|---|---|---|
| Ordered sequence | `c(1,2,3)` | `@a = (1,2,3)` | `a = [1, 2, 3]` (list) |
| Append | `a <- c(a, 4)` | `push @a, 4` | `a.append(4)` |
| Key→value map | `list(k=v)` | `%h = (k => 1)` | `h = {"k": 1}` (dict) |
| Lookup | `l[["k"]]` | `$h{k}` | `h["k"]` / `h.get("k")` |
| Key exists? | `"k" %in% names(l)` | `exists $h{k}` | `"k" in h` |
| Immutable record | — | — | `pt = (x, y)` (tuple) |
| Unique membership | `unique()` | `%seen` trick | `s = {1, 2, 3}` (set) |
| Length | `length(x)` | `scalar @a` | `len(x)` |
| Slice | `x[2:4]` (incl.) | `@a[1..3]` | `x[1:4]` (half-open) |
| Last item | `tail(x, 1)` | `$a[-1]` | `x[-1]` |

* Slice tricks: `x[::-1]` reverse, `x[::2]` every 2nd, `x[-3:]` last 3.
* Iterate a dict: `for k, v in h.items():`. Also `.keys()`, `.values()`.
* `h.get("k", default)` — safe lookup with fallback, no `KeyError`.

## Control flow — iterate over things, not indices

```python
for row in rows:                        # over items, not C-style indices
    process(row)

for i, row in enumerate(rows, start=1): # need the index? enumerate
    print(i, row)

for name, score in zip(names, scores):  # two lists in lockstep
    ...

label = "adult" if age >= 18 else "minor"   # ternary

match cmd.split():                      # structural match (3.10+)
    case ["go", dst]: travel(dst)
    case ["quit"]:    stop()
    case _:           unknown()
```

* `range(5)` → 0..4 (half-open); `range(2, 10, 2)` for start/stop/step.
* **Truthiness:** empty list/dict/str, `0`, `None` are falsy — write `if not items:`, not `len(x) == 0`.
* Chained comparison works: `if 0 < x < 10:`.
* `break` / `continue` as usual; a loop `else` runs if no `break` fired.

## Comprehensions — the signature idiom

| Task | R | Perl | Python |
|---|---|---|---|
| Transform | `sapply(xs, f)` | `map { f($_) } @xs` | `[f(x) for x in xs]` |
| Filter | `Filter(p, xs)` | `grep { p($_) } @xs` | `[x for x in xs if p(x)]` |
| Map + filter | `sapply(xs[keep], f)` | `map {..} grep {..}` | `[f(x) for x in xs if p(x)]` |
| Build a dict | `setNames(v, k)` | `%h = map {..} @xs` | `{k: f(k) for k in keys}` |
| Unique set | `unique()` | `keys %seen` | `{f(x) for x in xs}` |
| Lazy / streaming | — | — | `(f(x) for x in xs)` (generator) |

* Nested = flatten: `[y for row in grid for y in row]` (loops read left-to-right).
* Pass a generator straight to a reducer: `sum(x*x for x in nums)` — lazy, no temp list.
* `any(x < 0 for x in xs)`, `all(...)` — short-circuiting existence / universal tests.

## Functions

```python
def area(w, h=1, *, unit="cm"):
    """Docstring — shows up in help()."""
    return w * h

area(3); area(3, 4); area(3, unit="in")   # params after * are keyword-only

def summarise(*args, **kwargs):   # args -> tuple (Perl @_), kwargs -> dict
    ...

f = lambda x: x * 2               # anonymous; keep tiny

def bmi(w: float, h: float) -> float:   # type hints (documentary, not enforced)
    return w / h**2
```

* **Gotcha:** a mutable default (`def f(x, acc=[]):`) is created **once** and shared across calls. Use `acc=None` then `acc = acc or []`.
* Built-ins take `key=`: `max(xs, key=len)`, `sorted(rows, key=lambda r: r.age)`.

## Strings &amp; regex

Regex lives in the `re` module — it isn't baked into the syntax like Perl's `=~`.

| Task | Perl | Python |
|---|---|---|
| Interpolate | `"$name!"` | `f"{name}!"` |
| Join list | `join ",", @a` | `",".join(a)` |
| Split | `split /,/, $s` | `s.split(",")` |
| Trim newline | `chomp $s` | `s.rstrip("\n")` / `s.strip()` |
| Contains | `index($s,$t) >= 0` | `t in s` |
| Replace all | `s/a/b/g` | `s.replace("a", "b")` |
| Match | `$s =~ /(\d+)/` | `re.search(r"(\d+)", s)` |
| Regex sub | `s/(\w+)/.../` | `re.sub(r"(\w+)", repl, s)` |
| Case / test | `uc`, `lc` | `s.upper()`, `s.lower()`, `s.startswith(..)` |

* Use **raw strings** `r"..."` for patterns; then `m.group(1)`, `m.groups()`.
* `re.finditer(pat, text)` for all matches (lazy); `re.findall` returns a list.

## Idioms that mark you as fluent

* `with open(path) as fh: ...` — **context managers**: guaranteed cleanup (close/unlock/commit) on exit.
* **EAFP** ("easier to ask forgiveness"): `try: val = d[k]` / `except KeyError:` rather than pre-checking.
* Unpacking: `head, *tail = xs`; `x, (y, z) = pair`.
* `Counter(words).most_common(3)` (`from collections import Counter`) — the idiomatic tally.
* `defaultdict(list)` then `d[k].append(v)` — auto-vivifying dict (Perl gave you this free).
* `sorted(rows, key=..., reverse=True)` returns new; `.sort()` mutates in place.
* Walrus: `if (n := len(data)) > 10:` — assign inside an expression, reuse `n`.
* `enumerate` / `zip` over `range(len(...))` — the tell of fluency.
* Build strings with `", ".join(...)`, not `+=` in a loop.

## Files, paths &amp; JSON

```python
from pathlib import Path

text = Path("in.txt").read_text()          # whole file, one call
Path("out.txt").write_text(result)

with open("big.tsv") as fh:                # line by line, memory-safe
    for line in fh:
        cols = line.rstrip("\n").split("\t")

p = Path("data") / "2026" / "raw.csv"      # join with /
p.exists(), p.suffix, p.stem, p.parent
for f in Path("data").glob("*.csv"): ...

import json
cfg = json.loads(Path("c.json").read_text())
Path("o.json").write_text(json.dumps(cfg, indent=2))
```

`pathlib.Path` replaces `File::Spec` / manual joining and `os.path`; `/` joins parts portably.

## NumPy — vectors done right

NumPy arrays are R's vectors/matrices: vectorized, broadcast, no explicit loops. `import numpy as np`.

| Task | R | NumPy |
|---|---|---|
| Make a vector | `c(1, 2, 3)` | `np.array([1, 2, 3])` |
| Sequence | `seq(0, 1, 0.1)` | `np.arange(0, 1, .1)` / `np.linspace(0, 1, 11)` |
| Vectorized math | `x * 2 + 1` | `x * 2 + 1` (elementwise) |
| Summaries | `mean(x); sd(x)` | `x.mean(); x.std()` |
| Boolean mask | `x[x > 0]` | `x[x > 0]` |
| Vectorized if-else | `ifelse(x>0, 1, -1)` | `np.where(x > 0, 1, -1)` |
| Reshape | `matrix(x, 2, 5)` | `x.reshape(2, 5)` |
| Matrix multiply | `A %*% B` | `A @ B` |
| Row/col reduce | `colMeans(A)` | `A.mean(axis=0)` |

* Combine masks with `&  |  ~` (bitwise) and **parenthesise** each: `a[(a > 0) & (a < 10)]` — not `and` / `or`.
* `a.shape`, `a.dtype`, `a.ndim`. `axis=0` = down rows, `axis=1` = across columns.

## pandas — the data.frame you know

A `DataFrame` is a `data.frame` / `tibble`; a `Series` is one column. `import pandas as pd`. Row labels are the `index`.

**Load &amp; inspect**

```python
df = pd.read_csv("cells.csv")
df.head()       # head()
df.info()       # str()
df.describe()   # summary()
df.shape        # dim()
df.columns      # names()
```

**Select &amp; filter**

```python
df["gene"]                     # one column -> Series
df[["gene", "expr"]]           # many columns
df.loc[df.expr > 5, "gene"]    # filter + pick, by label
df.iloc[0:5, :2]               # by integer position
df.query("expr > 5 and hit")   # readable filter
df[(df.a > 0) & (df.b == "x")] # boolean filter: & | ~ + parentheses
```

**Mutate, group &amp; combine**

```python
df.assign(rpkm=lambda d: d.counts / d.len)   # mutate() — non-destructive
df.groupby("sample")["expr"].mean()          # split-apply-combine
df.groupby("s").agg(n=("expr", "size"),
                    mu=("expr", "mean"))      # named aggregations
pd.merge(a, b, on="id", how="left")          # joins: left/right/inner/outer
df.sort_values("expr", ascending=False)      # arrange(desc())
df["expr"].fillna(0); df.dropna()            # missing data (NaN / pd.NA)
df.to_csv("out.csv", index=False)            # write back out
```

**Chain it like a dplyr pipeline**

```python
(df
   .query("expr > 0")
   .assign(log_expr=lambda d: np.log1p(d.expr))
   .groupby("sample", as_index=False)
   .agg(mean_expr=("log_expr", "mean"))
   .sort_values("mean_expr", ascending=False))
```

Wrap the chain in parentheses and lead each step with `.` — it reads top-to-bottom
like `df |> filter() |> mutate() |> group_by() |> summarise() |> arrange()`.

**Transform, reshape &amp; combine**

* `df.groupby("s")["x"].transform("mean")` — grouped mutate; broadcasts a group stat back to every row (R `ave()`).
* `df["s"].value_counts(normalize=True)` — frequency table (`table()` / `prop.table()`); `.nunique()` for distinct count.
* `df.nlargest(5, "expr")` — top rows (`slice_max()` / `top_n()`); `nsmallest` for the bottom.
* `pd.concat([a, b])` — stack rows (`rbind`); `axis=1` binds columns (`cbind`).
* `df.pivot_table(index="gene", columns="cond", values="x", aggfunc="mean")` — long→wide (`pivot_wider()`).
* `df.melt(id_vars="gene", var_name="cond", value_name="x")` — wide→long (`pivot_longer()`).
* `df["x"].rolling(7).mean()` — windows; also `.cumsum()`, `.shift(1)` (lag), `.rank()`, `.diff()`.

**Strings, dates &amp; factors (accessors)**

* `df["name"].str.lower().str.contains("kras")` — vectorized string ops via `.str` (stringr on a column, regex-aware).
* `pd.to_datetime(df["date"]).dt.year` — parse, then `.dt` accessor (`.month`, `.weekday`, `.floor("D")`); the lubridate analogue.
* `df["cond"] = df["cond"].astype("category")` — **factors**; order with `.cat.reorder_categories([...], ordered=True)`.
* `df["expr"].clip(0, 100).round(2)` — elementwise numeric helpers.

**Reading real-world files**

* `pd.read_csv("f.tsv", sep="\t", na_values=["NA", "-"], parse_dates=["date"])` — also `usecols=`, `dtype={...}`, `nrows=`, `comment="#"`.
* `pd.read_parquet("f.parquet")` — fast, typed, columnar; prefer over CSV for large data. Also `read_excel`, `read_sql`.

**Pandas-specific gotchas**

* Assign through `.loc`: `df.loc[mask, "col"] = value`. The chained `df[mask]["col"] = ...` triggers `SettingWithCopyWarning` and may not stick.
* Avoid row-wise `df.apply(f, axis=1)` / `iterrows()` — vectorize with column math, `.str`, or `np.where`.
* Arithmetic and joins align by **index label**, not row position; `reset_index(drop=True)` when the labels get in the way.

## dplyr → pandas Rosetta

| Verb | dplyr | pandas |
|---|---|---|
| Filter rows | `filter(expr > 5)` | `df.query("expr > 5")` |
| Pick columns | `select(gene, expr)` | `df[["gene", "expr"]]` |
| New columns | `mutate(z = x / y)` | `df.assign(z=lambda d: d.x / d.y)` |
| Rename | `rename(g = gene)` | `df.rename(columns={"gene": "g"})` |
| Sort | `arrange(desc(expr))` | `df.sort_values("expr", ascending=False)` |
| Group + summarise | `group_by(s) \|> summarise(m = mean(x))` | `df.groupby("s").agg(m=("x", "mean"))` |
| Join | `left_join(b, by = "id")` | `df.merge(b, on="id", how="left")` |
| Distinct | `distinct()` | `df.drop_duplicates()` |
| Count | `count(s)` | `df["s"].value_counts()` |
| Long ↔ wide | `pivot_longer / wider` | `df.melt()` / `df.pivot()` |
| Chain | `df \|> f() \|> g()` | `df.pipe(f).pipe(g)` |

## Plotting — for a ggplot2 native

Two good routes. **plotnine** *is* ggplot2 ported to Python — same grammar, almost
the same code. **seaborn** is the Pythonic statistical-plotting library. Both render
through **matplotlib**, which you drop to for fine control and saving.

**plotnine — literally ggplot2**

```python
from plotnine import *

(ggplot(df, aes("mass", "expr", color="sample"))
 + geom_point(alpha=.6)
 + geom_smooth(method="lm")
 + facet_wrap("~condition")
 + scale_y_log10()
 + labs(x="Mass", y="Expression")
 + theme_minimal())
```

Same `+` layering, `aes()`, geoms, facets, scales, themes. Save with `p.save("f.png", dpi=300)` or `ggsave`.

**seaborn — the Pythonic route**

```python
import seaborn as sns

sns.set_theme(style="whitegrid")
sns.relplot(data=df, x="mass", y="expr",
            hue="sample", col="condition", kind="scatter")  # facets via col=/row=
sns.lmplot(data=df, x="mass", y="expr")                     # + linear fit
```

`hue` / `size` / `style` are aesthetics; `col` / `row` are facets. `relplot` / `displot` / `catplot` are the faceting ("figure-level") functions.

**ggplot2 → Python, layer by layer** (plotnine mirrors ggplot2 almost exactly)

| Layer | ggplot2 (R) | plotnine | seaborn |
|---|---|---|---|
| Data + mapping | `ggplot(df, aes(x, y))` | `ggplot(df, aes("x", "y"))` | `data=df, x="x", y="y"` |
| Points | `geom_point()` | `geom_point()` | `sns.scatterplot(...)` |
| Line | `geom_line()` | `geom_line()` | `sns.lineplot(...)` |
| Histogram | `geom_histogram()` | `geom_histogram()` | `sns.histplot(...)` |
| Boxplot | `geom_boxplot()` | `geom_boxplot()` | `sns.boxplot(...)` |
| Bar (count) | `geom_bar()` | `geom_bar()` | `sns.countplot(...)` |
| Smooth / lm | `geom_smooth(method="lm")` | `geom_smooth(method="lm")` | `sns.lmplot(...)` |
| Colour by group | `aes(colour = g)` | `aes(color="g")` | `hue="g"` |
| Facet | `facet_wrap(~ g)` | `facet_wrap("~g")` | `col="g"` / `row=` |
| Log axis | `scale_y_log10()` | `scale_y_log10()` | `ax.set_yscale("log")` |
| Labels / title | `labs(x =, title =)` | `labs(x=, title=)` | `.set(xlabel=, title=)` |
| Theme | `theme_minimal()` | `theme_minimal()` | `sns.set_theme(style=)` |
| Save | `ggsave("f.png")` | `p.save("f.png")` | `plt.savefig("f.png")` |

**Quick EDA &amp; the matplotlib base**

```python
import matplotlib.pyplot as plt

df.plot(x="mass", y="expr", kind="scatter")   # pandas built-in quick plot
df["expr"].hist(bins=30); df.plot.box()       # per-column distributions

fig, ax = plt.subplots()                       # the figure/axes object model
ax.plot(x, y); ax.set(xlabel="t", title="…")   # every sns/pandas plot returns an ax
plt.savefig("f.png", dpi=300, bbox_inches="tight")  # the ggsave you want
plt.show()                                     # display; Jupyter renders inline
```

## Gotchas that will bite an R/Perl brain

* **Zero-indexed**, and `x[1:3]` excludes index 3. `x[0]` first, `x[-1]` last.
* `b = a` binds a **reference**, not a copy — mutating `b` mutates `a`. Copy with `a.copy()` / `list(a)`.
* `7 / 2 == 3.5` (always float); `7 // 2 == 3` (floor). Like R's `/` vs `%/%`.
* Boolean operators are **words**: `a and b`, `not x`. Save `& | ~` for arrays/Series.
* Test null with `x is None`; test a Series with `.isna()` — never `== NaN` (never equal).
* Floats: `0.1 + 0.2 != 0.3`. Compare with `math.isclose(a, b)`.
* Mutable default args (`def f(x=[]):`) persist between calls — use a `None` sentinel.
* `print(a, b)` inserts a space and a trailing newline; no bare sigil interpolation.

## The modern toolchain &amp; essentials

```python
from dataclasses import dataclass

@dataclass
class Cell:
    barcode: str
    counts: int = 0

c = Cell("AACG", 12); c.counts   # free __init__/__repr__, attribute access
```

```python
import argparse, logging

def main() -> None:
    p = argparse.ArgumentParser()
    p.add_argument("--n", type=int, default=10)
    args = p.parse_args()
    logging.info("running with n=%s", args.n)

if __name__ == "__main__":   # run-vs-import guard
    main()
```

* `ruff check --fix .` / `ruff format .` — lint + format (already in your Neovim LSP).
* `mypy src/` — static type checking off your hints; catches what R/Perl defer to runtime.
* `pytest` — standard test runner: files `test_*.py`, plain `assert`, fixtures.
* `uv add pandas` / `uv run script.py` — venv + deps + lockfile from `pyproject.toml`.
* `import this` — the Zen of Python; the taste behind "one obvious way."
