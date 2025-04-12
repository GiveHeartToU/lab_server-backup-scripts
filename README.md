# lab_server-backup-scripts

Data backup is of paramount importance, especially for research data analysts. Their work often involves processing and generating vast amounts of critical and unique datasets. Losing this data due to hardware failure, software corruption, accidental deletion, or even cyberattacks can have devastating consequences, leading to significant setbacks in research progress, wasted time and resources, and potentially irrecoverable loss of valuable findings.

Implementing a robust backup strategy ensures the preservation of these irreplaceable datasets, allowing analysts to recover their work in case of unforeseen events. This not only safeguards their progress but also maintains the integrity and reproducibility of their research, which is fundamental to the scientific process. Regular and reliable backups are therefore not just a good practice, but an essential component of responsible and effective research data management.

This Repository containing scripts for implementing different server backup strategies that works on myself, featuring rsync and restic...

| Feature/Tool        | `rsync`                                  | `rclone`                                     | `borg`                                       | `restic`                                     |
|-----------------------|------------------------------------------|----------------------------------------------|----------------------------------------------|----------------------------------------------|
| 🧠 Incremental Backup | ✅ `--link-dest`                         | ❌ (Full sync)                               | ✅ Automatic block-level incremental          | ✅ Block-level incremental                   |
| ⚙️ Parallel Processing | ❌ (Manual directory splitting needed) | ✅ `--transfers` multi-threading             | ✅ (Chunk parallel, background processing) | ✅ (Concurrent upload/download)              |
| 💾 Deduplication/Compression | ❌ (Only hard links for space saving) | ❌ (Pure synchronization)                    | ✅ Content-based deduplication + compression | ✅ Content-based deduplication + compression |
| 🔐 Encryption Support | ❌ (Relies on SSH security)             | ✅ Encryptable (when interacting with cloud) | ✅ Strong encryption (AES-GCM)                | ✅ Strong encryption (AES)                    |
| 🔌 Cross-Platform Support | ✅ (macOS/Linux native, Win via WSL)    | ✅ Native support for Windows/macOS/Linux     | ⛔ No Windows support (unless using WSL)     | ✅ Native support for Windows/macOS/Linux     |
| 📂 Storage Targets    | Local / SSH / Network Drive              | Local / SSH / Cloud (S3/GDrive etc.)        | Local / SSH / Network Drive              | Local / SSH / Cloud (supports SFTP)        |
| 🔁 Version Rollback   | ❌ (Requires snapshot dir + hardlink)     | ❌ (No version snapshots)                    | ✅ Built-in version control                   | ✅ Built-in version control                   |
| 🛠️ Ease of Use        | ⭐⭐⭐ (General but requires understanding) | ⭐⭐⭐⭐ (Scriptable, suitable for cloud)       | ⭐⭐ (Requires understanding of repo concept) | ⭐⭐⭐⭐ (Simple commands for operation)       |
| 🧪 Best Use Case       | Lightweight file sync/copy               | Cloud storage interaction, large file transfer | Scientific data long-term archiving, intense version control | Scientific data snapshots, cross-platform regular backups |

## 1. rsync
[Official Documents](https://download.samba.org/pub/rsync/rsync.1)
`rsync` is a versatile command-line tool for synchronizing files and directories.

On **macOS**, `rsync` is readily available in the terminal. While the built-in version might be slightly older, it generally functions without issues and is the recommended method for running `rsync` on macOS.

For **Windows**, as `rsync` is primarily a Linux utility, it requires a Linux-like environment to run. One approach, as suggested in [this article](https://blog.csdn.net/Blazar/article/details/109710997), is to utilize Git, which provides the necessary command-line tools. Another solution is to use software like [Mobaxterm](https://mobaxterm.mobatek.net), which offers support for many Unix/Linux commands, including `rsync`. The underlying logic required for windows should be WSL. **Windows users** might encounter a common bug: `rsync: mkstemp ... failed: No such file or directory (2)`. A potential solution for this issue can be found at [https://kenfallon.com/rsync-mkstemp-failed-no-such-file-or-directory-2/](https://kenfallon.com/rsync-mkstemp-failed-no-such-file-or-directory-2/). Anyway, Linux and macOS systems are recommended.

### 1.1 linux -> local Pull-down

#### `01Dry-run.sh`

**Purpose:** This script performs a **dry run** of the backup process. It simulates the execution of the `rsync` command without actually transferring or modifying any files. This is invaluable for testing your backup configuration, verifying the source and destination paths, and understanding exactly which files would be synchronized. Use this script to preview the actions of the actual backup before running it.

**Usage:** `bash 01Dry-run.sh` (First of all, we have to modify the script for specific options and variables.)

#### `02backup2local.sh`

**Purpose:** This script executes the **actual backup** to a local or mounted destination. It utilizes `rsync`'s capabilities for efficient **incremental backups** using the `--link-dest` option (or similar, depending on the script's implementation). This means that after the initial full backup, subsequent runs will only transfer the changes, saving time and storage space by creating hard links to unchanged files from previous backups.

**Usage:** 
- `bash 02backup2local.sh` (Refer to the script for specific options and variables, especially regarding the previous backup location for incremental backups.) **You do not need to specify an incremental backup location the first time**
- `caffeinate -i bash 02backup2local.sh` This will ensure that your Mac stays awake until the backup process is finished.

#### `03break_continue.sh`

**Purpose:** This script is designed to handle interrupted backups and **resume** the transfer. It leverages `rsync`'s ability to continue partially transferred files, making it particularly useful for backups over unstable network connections or when dealing with large datasets where interruptions are possible.

**Usage:** `bash 03break_continue.sh` (Find the time in the log file name under the path and modify DATETIME= in the script.)

**Note:** Please review the contents of each script for specific command-line options, configurable variables (like source and destination paths), and any prerequisites before execution. Ensure that the destination directory exists and has the necessary permissions for the backup process.

## 2. restic

Demand is Backing Up Data from a CentOS Server to a Local Drive (macOS/Windows)

**Understanding `restic`'s Approach:**

It's important to note that `restic` is designed for **local execution to back up local data to a repository**, which can be local or remote. It does **not** inherently support pulling data from a remote server to back it up locally.

Therefore, the recommended approach is for the **CentOS server (acting as the `restic` client) to push its data to a repository located on the local macOS or Windows machine.**

**Proposed Solution:**

1.  **Source (Data Origin):** CentOS server running the `restic` client.
2.  **Backup Repository (Destination):** The local external hard drive connected to your macOS or Windows machine.
3.  **Accessibility:** The CentOS server will need a way to access the local external drive. For macOS, this can be achieved by enabling the built-in SFTP server ("Remote Login"). For Windows, you might need to set up an SFTP server application.

**Workflow:**

The `restic` process will run on the CentOS server, reading the local data to be backed up and then securely transferring it via SFTP to the designated repository on the connected external drive.

**Key Takeaway:**

`restic` follows a "read local data → push to a repository" model. It does not require mounting remote file systems or using tools like `rsync` to pull data down for backup. This setup allows for a centralized backup repository on your local machine, where multiple servers (if applicable) can push their backups.
