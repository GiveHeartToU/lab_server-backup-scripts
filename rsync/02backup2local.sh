#!/bin/zsh

# A script to perform incremental backups using rsync

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
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting backup..." | tee -a "${LOG_FILE}"

# Perform the backup using rsync
if rsync -avzq --delete --partial --partial-dir="${PARTIAL_DIR}" \
  --link-dest="${LATEST_LINK}" \
  --exclude={'*ttest.txt',"*.bam","*.bam.bai","*.fastq"} \
  --max-size='100m' \
  --log-file="${LOG_FILE}" \
  "${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_SOURCE_DIR}/" \
  "${BACKUP_PATH}" < /dev/null; then
  rm -rf "${LATEST_LINK}"
  ln -s "${BACKUP_PATH}" "${LATEST_LINK}"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup completed successfully from ${DATETIME}" | tee -a "${LOG_FILE}"
else
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup failed from ${DATETIME}" | tee -a "${LOG_FILE}"
  exit 1
fi

# Remove the lock file explicitly (although trap should handle it)
rm -f "${LOCK_FILE}"

# Log the end of the script
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Backup script finished." | tee -a "${LOG_FILE}"
