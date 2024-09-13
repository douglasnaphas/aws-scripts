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
    --query 'Snapshots[].{
        SnapshotId: SnapshotId,
        SourceResource: Tags[?Key==`aws:backup:source-resource`]|[0].Value,
        VolumeId: VolumeId
    }' \
    --output json)

# Check if the AWS CLI call was successful
if [ $? -ne 0 ]; then
    echo "Error fetching snapshot details."
    exit 1
fi

# Ensure jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "The 'jq' utility is required but not installed. Please install jq."
    exit 1
fi

# Create associative arrays to hold the mapping
declare -A source_resource_tags
declare -A volume_ids

# Populate the associative arrays
while IFS=$'\t' read -r snapshot_id source_resource_tag volume_id; do
    source_resource_tags["$snapshot_id"]="$source_resource_tag"
    volume_ids["$snapshot_id"]="$volume_id"
done < <(echo "$aws_output" | jq -r '.[] | [
    .SnapshotId,
    (.SourceResource // ""),
    (.VolumeId // "")
] | @tsv')

# Output the snapshot ID, the source resource tag, and the volume ID
for snapshot_id in "${snapshot_ids[@]}"; do
    echo -e "${snapshot_id},${volume_ids[$snapshot_id]}"
done
