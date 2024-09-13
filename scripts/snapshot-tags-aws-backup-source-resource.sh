#!/bin/bash

# Take in a newline-separated list of AWS EBS snapshot ids, and output a
# newline separated list where each line contains the snapshot id followed by 
# the value of the tag aws:backup:source-resource, if it exists.

#!/bin/bash

# Check if a file is provided as an argument; otherwise, read from stdin
input="${1:-/dev/stdin}"

# Read snapshot IDs into an array
mapfile -t snapshot_ids < "$input"

# Ensure there are snapshot IDs to process
if [ ${#snapshot_ids[@]} -eq 0 ]; then
    echo "No snapshot IDs provided."
    exit 1
fi

# Make the AWS CLI call to describe all snapshots at once
aws_output=$(aws ec2 describe-snapshots --snapshot-ids "${snapshot_ids[@]}" \
    --query 'Snapshots[].{SnapshotId:SnapshotId, SourceResource:Tags[?Key==`aws:backup:source-resource`].Value|[0]}' \
    --output json)

# Check if the AWS CLI call was successful
if [ $? -ne 0 ]; then
    echo "Error fetching snapshot details."
    exit 1
fi

# Parse the JSON output using jq to create a mapping of SnapshotId to Tag Value
# Ensure jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "The 'jq' utility is required but not installed. Please install jq."
    exit 1
fi

# Create an associative array to hold the mapping
declare -A snapshot_tags

# Populate the associative array
while IFS=$'\t' read -r snapshot_id tag_value; do
    snapshot_tags["$snapshot_id"]="$tag_value"
done < <(echo "$aws_output" | jq -r '.[] | [.SnapshotId, .SourceResource] | @tsv')

# Output the snapshot ID and the tag value (if it exists), preserving the input order
for snapshot_id in "${snapshot_ids[@]}"; do
    echo "$snapshot_id ${snapshot_tags[$snapshot_id]}"
done
