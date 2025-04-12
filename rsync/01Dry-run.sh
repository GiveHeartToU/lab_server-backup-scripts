#!/bin/zsh

# A script to diagnose rsync errors

set -o errexit
set -o nounset
set -o pipefail

readonly REMOTE_USER="your server id"
readonly REMOTE_HOST="your server IP"
readonly REMOTE_SOURCE_DIR="Path need to be backen-up"
readonly LOCAL_BACKUP_DIR="Path to save"
readonly DATETIME="$(date '+%Y-%m-%d_%H:%M:%S')"
readonly BACKUP_PATH="${LOCAL_BACKUP_DIR}/${DATETIME}"
readonly LATEST_LINK="${LOCAL_BACKUP_DIR}/latest"
readonly LOG_FILE="${LOCAL_BACKUP_DIR}/backup_${DATETIME}.log"
readonly LOCK_FILE="${LOCAL_BACKUP_DIR}/backup.lock"
readonly PARTIAL_DIR="${LOCAL_BACKUP_DIR}/partial"

# Ensure the backup directory exists
if [ ! -d "${LOCAL_BACKUP_DIR}" ]; then
  mkdir -p "${LOCAL_BACKUP_DIR}"
fi

# Ensure the partial directory exists
if [ ! -d "${PARTIAL_DIR}" ]; then
  mkdir -p "${PARTIAL_DIR}"
fi

# Create a lock file to prevent concurrent runs
if [ -e "${LOCK_FILE}" ]; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup script is already running." | tee -a "${LOG_FILE}"
  exit 1
fi

touch "${LOCK_FILE}"

# Trap to remove the lock file in case of exit or error
trap 'rm -f "${LOCK_FILE}"' EXIT

# Log the start of the backup
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup (dry run)..." | tee -a "${LOG_FILE}"

# Perform a dry-run backup using rsync
if rsync -avz --delete --partial --partial-dir="${PARTIAL_DIR}" \
  --dry-run \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_SOURCE_DIR}/" \
  --link-dest="${LATEST_LINK}" \
  --exclude={'*ttest.txt',"*.bam","*.bam.bai","*.fastq"} \ 
  --max-size='100m' \
  "${BACKUP_PATH}" < /dev/null | tee -a "${LOG_FILE}"; then
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dry run completed successfully." | tee -a "${LOG_FILE}"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dry run failed." | tee -a "${LOG_FILE}"
  exit 1
fi

# Log the completion of the test
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Dry run finished. Please check the log for details." | tee -a "${LOG_FILE}"

# Remove the lock file explicitly (although trap should handle it)
rm -f "${LOCK_FILE}"
