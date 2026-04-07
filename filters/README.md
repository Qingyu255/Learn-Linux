A **filter** is just a program that follows this pattern:

* **reads** data from `stdin`
* **transforms / selects / analyzes** it
* **writes** result to `stdout`

That makes filters easy to **chain** with pipes.

Example with `grep`:

```bash
cat names.txt | grep "Alice" | wc -l
```

What happens:

* `cat` sends file contents to stdout
* `grep` filters only lines containing `"Alice"`
* `wc -l` counts those lines

So the big Unix idea is: **small programs, each doing one thing well, connected together**.

## Intuition

Think of stdin/stdout like water pipes:

* input flows in
* the filter changes it
* output flows out

Example:

```bash
echo -e "apple\nbanana\napricot" | grep "^a"
```

Output:

```bash
apple
apricot
```

`grep` is acting as a filter: it only lets matching lines pass through.

---

# `grep` crash course

`grep` searches **lines** of text for a **pattern**.

Basic form:

```bash
grep PATTERN file
```

Example:

```bash
grep hello notes.txt
```

This prints every line in `notes.txt` containing `hello`.

---

## 1. Most basic usage

### Search for a word in a file

```bash
grep error app.log
```

Prints lines containing `error`.

### Search from command output

```bash
ps aux | grep python
```

Shows lines from `ps aux` containing `python`.

---

## 2. Very useful flags

## `-i` case-insensitive

```bash
grep -i error app.log
```

Matches `error`, `Error`, `ERROR`, etc.

---

## `-n` show line numbers

```bash
grep -n error app.log
```

Output might look like:

```bash
12:error connecting to db
48:fatal error occurred
```

---

## `-v` invert match

Show lines that **do not** match.

```bash
grep -v "^#" config.txt
```

Useful for ignoring comments.

---

## `-r` recursive search

Search through directories.

```bash
grep -r "TODO" .
```

Search current directory recursively.

---

## `-l` show only filenames

```bash
grep -l "main" *.c
```

Only prints names of files that contain `main`.

---

## `-c` count matching lines

```bash
grep -c error app.log
```

Prints how many matching lines there are.

---

## `-w` whole word match

```bash
grep -w cat words.txt
```

Matches `cat` but not `catalog`.

---

## `-x` whole line match

```bash
grep -x "hello" file.txt
```

Only matches lines that are exactly `hello`.

---

## `-o` print only the matched part

```bash
echo "abc123xyz" | grep -o "[0-9]\+"
```

Output:

```bash
123
```

---

# 3. Regex basics with grep

`grep` is much more powerful when you use patterns.

## Anchors

### `^` start of line

```bash
grep "^root" /etc/passwd
```

Lines starting with `root`

### `$` end of line

```bash
grep "sh$" /etc/passwd
```

Lines ending in `sh`

---

## Dot `.`

Matches any single character.

```bash
grep "c.t" file.txt
```

Matches `cat`, `cut`, `c9t`

---

## `*`

In regex, `*` means “repeat previous thing 0 or more times”.

Example with extended regex:

```bash
grep -E "ab*c" file.txt
```

Matches:

* `ac`
* `abc`
* `abbc`
* `abbbc`

---

## Character classes

### Match one of several chars

```bash
grep -E "gr[ae]y" file.txt
```

Matches `gray` or `grey`

### Digits

```bash
grep -E "[0-9]" file.txt
```

### Lowercase letters

```bash
grep -E "[a-z]" file.txt
```

---

# 4. Basic vs extended regex

Traditional `grep` uses **basic regex**.

For friendlier syntax, use:

```bash
grep -E
```

This lets you use `|`, `+`, `?`, `()` more naturally.

Example:

```bash
grep -E "cat|dog" pets.txt
```

Without `-E`, that syntax is clumsier.

A good beginner rule:

* use plain `grep` for simple literal matches
* use `grep -E` for regex work

---

# 5. Literal vs regex meaning

This matters a lot.

```bash
grep "." file.txt
```

This does **not** search for a literal dot. `.` means “any character”.

To search for an actual dot:

```bash
grep "\." file.txt
```

Same idea for other regex symbols.

---

# 6. Common practical patterns

## Find comment lines in shell/python files

```bash
grep "^#" script.sh
```

## Ignore blank lines

```bash
grep -v "^$" file.txt
```

## Find blank lines only

```bash
grep "^$" file.txt
```

## Find lines starting with spaces or tabs

```bash
grep -E "^[[:space:]]+" file.txt
```

## Find words containing digits

```bash
grep -E "[[:alnum:]]*[0-9][[:alnum:]]*" file.txt
```

## Find `.c` includes

```bash
grep '^#include' main.c
```

## Find possible function calls

```bash
grep -E '[a-zA-Z_][a-zA-Z0-9_]*\(' file.c
```

Not perfect parsing, but often useful.

---

# 7. `grep` with pipes

This is where Unix filters shine.

## Example: check running processes

```bash
ps aux | grep nginx
```

## Example: only non-comment config lines

```bash
cat config.txt | grep -v "^#" | grep -v "^$"
```

Better as:

```bash
grep -v "^#" config.txt | grep -v "^$"
```

Even better with one regex if you want.

---

## Example: search history

```bash
history | grep docker
```

## Example: search open ports

```bash
netstat -an | grep LISTEN
```

---

# 8. `grep` on source code

## Find `main`

```bash
grep -rn "main" .
```

* `-r` recursive
* `-n` line numbers

## Find TODO comments

```bash
grep -rn "TODO" .
```

## Find exact variable name

```bash
grep -rw "counter" .
```

---

# 9. Exit status

This is super important in shell scripting.

`grep` exit codes:

* `0` = found a match
* `1` = no match
* `2` = error

So in scripts:

```bash
if grep -q "hello" file.txt; then
  echo "found"
else
  echo "not found"
fi
```

`-q` means quiet, just use exit status.

---

# 10. `grep` vs `cat | grep`

Usually avoid useless `cat`.

Instead of:

```bash
cat file.txt | grep hello
```

prefer:

```bash
grep hello file.txt
```

But piping is still fine when input comes from another command:

```bash
dmesg | grep usb
```

---

# 11. Mini practice set

Make a file:

```bash
cat > practice.txt <<'EOF'
apple
banana
Apple pie
grape
apricot
cat
catalog
123abc
#comment
EOF
```

Now try these.

## Practice 1: lines containing `app`

```bash
grep "app" practice.txt
```

Expected:

```bash
apple
```

---

## Practice 2: case-insensitive `apple`

```bash
grep -i "apple" practice.txt
```

Expected:

```bash
apple
Apple pie
```

---

## Practice 3: lines starting with `a`

```bash
grep "^a" practice.txt
```

Expected:

```bash
apple
apricot
```

---

## Practice 4: lines ending with `e`

```bash
grep "e$" practice.txt
```

Expected:

```bash
apple
grape
```

---

## Practice 5: lines that are exactly `cat`

```bash
grep -x "cat" practice.txt
```

Expected:

```bash
cat
```

---

## Practice 6: lines that are not comments

```bash
grep -v "^#" practice.txt
```

---

## Practice 7: lines containing digits

```bash
grep -E "[0-9]" practice.txt
```

Expected:

```bash
123abc
```

---

## Practice 8: whole word `cat`

```bash
grep -w "cat" practice.txt
```

Expected:

```bash
cat
```

not `catalog`.

---

# 12. Good mental model

When using `grep`, ask:

1. Am I searching for a **literal string** or a **pattern**?
2. Do I care about **case**?
3. Do I want:

   * matching lines
   * non-matching lines
   * count only
   * filenames only
4. Is this one file or a whole directory tree?

---

# 13. The 10 commands worth memorizing

```bash
grep "text" file
grep -i "text" file
grep -n "text" file
grep -v "text" file
grep -w "text" file
grep -x "text" file
grep -c "text" file
grep -r "text" .
grep -rn "text" .
grep -E "pattern" file
```

---

# 14. One-line cheat sheet

* `^abc` → starts with `abc`
* `abc$` → ends with `abc`
* `.` → any one char
* `[abc]` → one of `a/b/c`
* `[0-9]` → digit
* `grep -i` → ignore case
* `grep -v` → not matching
* `grep -r` → recursive
* `grep -n` → line numbers
* `grep -E` → extended regex

---

# 15. Why filters matter in Unix

Because you can compose them:

```bash
cat access.log | grep "404" | sort | uniq | wc -l
```

That pipeline is basically:

* select matching lines
* sort them
* collapse duplicates
* count them

That is the Unix philosophy in action.
