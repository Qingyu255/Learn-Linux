## Hard links: A hard link is another directory entry for the same inode.
# What that means:
# Deleting one name does not delete the file data if another hard link still exists.
# Both names share the same inode and same contents.
# Editing one edits the same underlying file.
echo hello > a.txt
ln a.txt b.txt
# a.txt = original name
# b.txt = hard link
# b.txt is a hard link to the same inode that a.txt points to.
# More precisely, both a.txt and b.txt point to the same inode, which contains the actual data of the file.
# Simply, a.txt and b.txt are two hard links to the same file object

## Symbolic link (symlink, soft link): A symbolic link is a special file that stores a path to another file.
# What that means
# If the original file is removed, the symlink becomes broken or dangling.
# The symlink has its own inode.
# It can point to directories too.
# It can point across different filesystems.
ln -s a.txt c.txt
# Now, c.txt = symlink to a.txt
# c.txt is a symbolic link that points to a.txt. It contains the path to a
# If you delete a.txt:
# b.txt still works, because it is the same underlying file
# c.txt breaks, because it was only storing the path a.txt