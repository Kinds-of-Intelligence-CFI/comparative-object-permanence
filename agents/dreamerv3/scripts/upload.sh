# Upload all model checkpoints to Google Drive
# Uses the the `gdrive files upload` command
# Parent folder id is --parent 12w8xDaqaHbn-Gde5lnMTBhJGJIiRl7Kv
# Logs the order of the checkpoints in the file `checkpoints.txt`, so we can rename later

set -e
set -o pipefail
set -u

# Usage: ./upload.sh <path/to/checkpoints>
PATH_TO_CHECKPOINTS=$1

# For each .chkpt file in the checkpoints folder (recursive)
# Sort by name, so we can rename later
for f in $(find $PATH_TO_CHECKPOINTS -name "*.ckpt" | sort -V); do
    # Upload the file to Google Drive
    # --parent 12w8xDaqaHbn-Gde5lnMTBhJGJIiRl7Kv is the parent folder id
    gdrive files upload $f --parent 12w8xDaqaHbn-Gde5lnMTBhJGJIiRl7Kv
    now=$(date +"%Y-%m-%d_%H-%M-%S")
    echo "$now $f" >> checkpoints.txt
done
echo "Done uploading checkpoints" >> checkpoints.txt