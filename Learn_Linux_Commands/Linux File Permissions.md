#terminal

## **1. Understanding File Permissions in Linux**

Each file and directory in Linux has an **owner**, a **group**, and a set of **permissions** that determine who can access or modify them.
*(File Type) = 1*
*(Owner, Group, Others) = 3 chunks of 3 totaling 9*

When you run:

`ls -l`

You'll see output like this:

`-rwxr-xr--  1 user group 1234 Feb 26 12:34 filename`

Each file has a set of **ten characters** at the beginning that represent its type and permissions:

`-rwxr-xr--`

### **Breaking Down the Permission String**

The ten characters are divided into four parts:

|Position|Meaning|
|---|---|
|`-`|File type (e.g., `-` for regular file, `d` for directory, `l` for symbolic link)|
|`rwx`|Owner (user) permissions|
|`r-x`|Group permissions|
|`r--`|Others (world) permissions|

Each permission is represented by three letters:

- `r` (read) → View the contents of the file/directory.
- `w` (write) → Modify the file (or create/delete files in a directory).
- `x` (execute) → Run the file as a program or enter a directory.

If a permission is missing, it's replaced by `-`.

Example breakdown of `-rwxr-xr--`:

|Section|Value|Meaning|
|---|---|---|
|`-`|`-`|Regular file|
|`rwx`|`rwx`|Owner (`user`) can read, write, and execute|
|`r-x`|`r-x`|Group can read and execute, but not write|
|`r--`|`r--`|Others can only read|

---

## **2. Numeric (Octal) Representation of Permissions**

Each permission corresponds to a number:

- `r` = **4**
- `w` = **2**
- `x` = **1**

To find the numeric (octal) representation of a permission set, sum up the values:

|Permission|Binary|Decimal|
|---|---|---|
|`---`|`000`|`0`|
|`--x`|`001`|`1`|
|`-w-`|`010`|`2`|
|`-wx`|`011`|`3`|
|`r--`|`100`|`4`|
|`r-x`|`101`|`5`|
|`rw-`|`110`|`6`|
|`rwx`|`111`|`7`|

Example:  
`rwxr-xr--` becomes **`750`** (owner `7`, group `5`, others `0`).

---

## **3. Changing Permissions (`chmod`)**

To modify permissions, use `chmod`.

### **Using Numeric Mode**

`chmod 750 filename`

Sets:

- `rwx` (7) for owner
- `r-x` (5) for group
- `---` (0) for others

### **Using Symbolic Mode**

You can modify specific permissions with `chmod`:

`chmod u+x filename  # Add execute to user chmod g-w filename  # Remove write from group chmod o+r filename  # Add read for others chmod a+x filename  # Add execute for everyone (a = all)`

---

## **4. Changing Ownership (`chown` and `chgrp`)**

### **Change File Owner**

`chown newuser filename`

### **Change File Group**

`chgrp newgroup filename`

### **Change Both Owner and Group**

`chown newuser:newgroup filename`

---

## **5. Special Permissions: SUID, SGID, Sticky Bit**

Besides basic permissions, there are three special permission bits.

### **1. SUID (Set User ID) - `s` in User Execute Position**

- Allows a program to run as the owner, not as the user executing it.
- Commonly used for commands like `passwd`.

`chmod u+s filename`

Example:  
`-rwsr-xr-x` (The `s` replaces `x` in user permissions)

### **2. SGID (Set Group ID) - `s` in Group Execute Position**

- Files: Runs with the group’s permissions.
- Directories: New files inherit the group.

Set SGID:

`chmod g+s directory`

Example:  
`-rwxr-sr-x` (SGID active)

### **3. Sticky Bit - `t` in Others Execute Position**

- Used on directories to prevent users from deleting files they don’t own.
- Common in `/tmp`.

Set Sticky Bit:

`chmod +t directory`

Example:  
`drwxrwxrwt` (`t` at the end)

---

## **6. Default Permissions: `umask`**

When a new file is created, default permissions are set based on the **umask** value.

Check `umask`:

`umask`

Typical values:

- `0022` → Results in files with `644` (`rw-r--r--`) and directories with `755` (`rwxr-xr-x`).
- `0002` → Used in collaborative environments.

Modify `umask`:

`umask 027  # New files: 640, directories: 750`

---

## **7. Examples and Practical Scenarios**

### **Scenario 1: Making a Script Executable**

`chmod +x script.sh`

Sets `rwx` for owner, `r-x` for others.

### **Scenario 2: Secure a Private File**

`chmod 600 secret.txt`

Only the owner can read/write (`rw-------`).

### **Scenario 3: Shared Group Directory**

`chmod 2775 /shared`

- `2` → SGID ensures group ownership.
- `775` → Full access for group.

---

## **8. Summary of Key Commands**

|Task|Command|
|---|---|
|View permissions|`ls -l`|
|Change permissions (numeric)|`chmod 750 file`|
|Change permissions (symbolic)|`chmod u+rwx,g+rx,o-r file`|
|Set SUID|`chmod u+s file`|
|Set SGID|`chmod g+s file`|
|Set Sticky Bit|`chmod +t directory`|
|Change file owner|`chown user file`|
|Change file group|`chgrp group file`|
|Change both owner and group|`chown user:group file`|
|Check umask value|`umask`|
|Set new umask|`umask 027`|

