Think of every file or directory as carrying two labels and three permission buckets:

* **owner user ID (UID)**: who owns it
* **group ID (GID)**: which group it belongs to

Then Linux checks permissions for **exactly one** of these classes when you try to access it:

1. **user**: you are the owner
2. **group**: you are not the owner, but you are in the file’s group
3. **other**: everyone else

It does **not** combine them. It picks the first matching class and uses those bits.

---

## 1. See permissions with `ls -l`

```bash
ls -l
```

Example output:

```bash
-rwxr-x--- 1 alice devs 1234 Apr  5 12:00 script.sh
drwxr-xr-x 2 alice devs 4096 Apr  5 12:01 docs
```

Break down the first one:

```bash
-rwxr-x---
```

### First character: file type

* `-` = regular file
* `d` = directory
* `l` = symbolic link

### Next 9 characters: permission bits

They come in 3 groups of 3:

```bash
rwx r-x ---
^^^ ^^^ ^^^
 u   g   o
```

* first triplet = **user/owner**
* second triplet = **group**
* third triplet = **other**

Within each triplet:

* `r` = read
* `w` = write
* `x` = execute
* `-` = permission absent

So:

```bash
-rwxr-x---
```

means:

* owner: `rwx` → can read, write, execute
* group: `r-x` → can read and execute, not write
* others: `---` → no access

---

## 2. See owner and group

From:

```bash
-rwxr-x--- 1 alice devs 1234 Apr  5 12:00 script.sh
```

* owner = `alice`
* group = `devs`

You can also inspect with:

```bash
stat script.sh
```

Example useful lines:

```bash
Access: (0750/-rwxr-x---)
Uid: ( 1000/alice)
Gid: ( 1001/devs)
```

---

## 3. See your own user and groups

```bash
id
```

Example:

```bash
uid=1000(alice) gid=1000(alice) groups=1000(alice),1001(devs),1002(docker)
```

This tells you what groups you belong to.

You can also run:

```bash
groups
```

---

# File permission meanings

For a **regular file**:

* `r` = you can read the file contents
* `w` = you can modify the file contents
* `x` = you can execute it as a program/script

Example:

```bash
chmod u+x script.sh
./script.sh
```

Without execute permission, even if you can read it, you usually cannot run it directly.

---

# Directory permission meanings

For a **directory**, the meanings are different.

Suppose:

```bash
drwxr-x--- 2 alice devs 4096 Apr  5 12:01 docs
```

## `r` on a directory = can list names

You can do:

```bash
ls docs
```

This lets you see filenames inside.

## `w` on a directory = can change directory entries

You can add/remove/rename files in it:

```bash
touch docs/newfile
rm docs/oldfile
mv docs/a docs/b
```

But usually you also need `x` on the directory.

## `x` on a directory = can enter/search/traverse it

This is the big one.

It allows:

```bash
cd docs
cat docs/file.txt
```

provided the file itself also allows access.

A nice way to think of it:

* `r` lets you see the directory’s **list of names**
* `x` lets you **walk through** the directory to reach files
* `w` lets you **change the list of names**

---

## 4. Important directory combinations

### `r` without `x`

You may be able to list names, but not actually access files inside.

### `x` without `r`

You cannot list the directory contents, but if you already know a filename, you may access it.

Example:

```bash
chmod 111 secret_dir
ls secret_dir          # likely fails
cat secret_dir/a.txt   # may work if you know the name and file perms allow it
```

### `w` without `x`

Usually not very useful for normal directory manipulation, because `x` is needed to traverse/search the directory.

---

# 5. Changing permissions with `chmod`

## Symbolic mode

```bash
chmod u+r file.txt   # add read for owner
chmod g-w file.txt   # remove write for group
chmod o+x file.txt   # add execute for others
chmod ugo-r file.txt # remove read from everyone
chmod a+r file.txt   # add read for all (a = all)
```

Common examples:

```bash
chmod u+x script.sh
chmod go-rwx private.txt
chmod g+w shared.txt
```

---

## Numeric mode

Each permission bit has a value:

* `r` = 4
* `w` = 2
* `x` = 1

Add them per triplet.

Examples:

* `7` = 4+2+1 = `rwx`
* `6` = 4+2 = `rw-`
* `5` = 4+1 = `r-x`
* `4` = `r--`
* `0` = `---`

So:

```bash
chmod 750 script.sh
```

means:

* owner = 7 = `rwx`
* group = 5 = `r-x`
* other = 0 = `---`

Equivalent to:

```bash
chmod u=rwx,g=rx,o= script.sh
```

More examples:

```bash
chmod 644 notes.txt
```

=`rw-r--r--`

* owner can read/write
* group can read
* others can read

```bash
chmod 600 secrets.txt
```

=`rw-------`

Only owner can read/write.

```bash
chmod 755 mydir
```

=`rwxr-xr-x`

Common for directories and executable scripts.

---

# 6. Changing owner and group

## Change owner

```bash
sudo chown bob file.txt
```

## Change owner and group together

```bash
sudo chown bob:admins file.txt
```

## Change only group

```bash
chgrp admins file.txt
```

Usually you can only change a file’s group to a group you belong to, unless you are root.

---

# 7. Example workflow

Create a file:

```bash
touch report.txt
ls -l report.txt
```

Maybe you see:

```bash
-rw-r--r-- 1 alice alice 0 Apr  5 12:10 report.txt
```

Meaning:

* owner can read/write
* group can read
* others can read

Now make it private:

```bash
chmod 600 report.txt
ls -l report.txt
```

Now:

```bash
-rw------- 1 alice alice 0 Apr  5 12:10 report.txt
```

Only owner has access.

---

## Example with a script

```bash
echo 'echo hello' > hello.sh
ls -l hello.sh
```

Maybe:

```bash
-rw-r--r-- 1 alice alice 11 Apr  5 12:11 hello.sh
```

Try running it:

```bash
./hello.sh
```

You may get:

```bash
Permission denied
```

Because it lacks execute permission.

Fix it:

```bash
chmod u+x hello.sh
ls -l hello.sh
./hello.sh
```

Now maybe:

```bash
-rwxr--r-- 1 alice alice 11 Apr  5 12:11 hello.sh
```

---

# 8. Example with directories

```bash
mkdir project
touch project/a.txt
ls -ld project
```

Example:

```bash
drwxr-xr-x 2 alice alice 4096 Apr  5 12:12 project
```

Now remove execute for group and others:

```bash
chmod 744 project
ls -ld project
```

This becomes:

```bash
drwxr--r-- 2 alice alice 4096 Apr  5 12:12 project
```

Owner: `rwx`
Group: `r--`
Other: `r--`

This is strange for a directory: group/others may be able to list names, but cannot traverse into it.

A more normal directory permission is:

```bash
chmod 755 project
```

or for a private directory:

```bash
chmod 700 project
```

---

# 9. The selection logic Linux uses

When you access a file, Linux checks roughly like this:

* Are you root? special rules apply
* Are you the file owner? use **user** bits
* Else, are you in the file’s group? use **group** bits
* Else use **other** bits

Example:

```bash
-rw-r----- 1 alice devs file.txt
```

If:

* `alice` opens it → owner bits: `rw-`
* `bob` is in group `devs` → group bits: `r--`
* `charlie` is not owner and not in `devs` → other bits: `---`

---

# 10. Cheat sheet

## View

```bash
ls -l
ls -ld dirname
stat file
id
groups
```

## Change permissions

```bash
chmod 755 file
chmod u+x file
chmod go-rwx file
```

## Change ownership

```bash
sudo chown user file
sudo chown user:group file
chgrp group file
```

## Common numeric permissions

* `644` = regular readable file
* `600` = private file
* `755` = executable/script or open directory
* `700` = private executable/private directory
* `750` = owner full, group read/execute, others none

---

# 11. One intuition that helps

For **files**:

* `r` = read contents
* `w` = change contents
* `x` = run it

For **directories**:

* `r` = see names
* `w` = change names
* `x` = pass through / access entries inside

That “directory stores filenames” idea is why directory permissions behave differently.

If you want, I can also draw this as a small permission matrix with concrete users like `alice`, `bob`, and `charlie`.
