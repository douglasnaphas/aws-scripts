#!/bin/bash

# Take in a newline-separated list of AWS EBS snapshot ids, and output a
# newline separated list where each line contains the snapshot id followed by: 
# - the value of the tag aws:backup:source-resource, if it exists
# - a comma-separated list of all the snapshot's tags

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
    --query 'Snapshots[].{SnapshotId:SnapshotId, SourceResource:Tags[?Key==`aws:backup:source-resource`]|[0].Value, AllTags:Tags}' \
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
declare -A all_tags_list

# Populate the associative arrays
while IFS=$'\t' read -r snapshot_id source_resource_tag all_tags_json; do
    source_resource_tags["$snapshot_id"]="$source_resource_tag"
    # Convert the array of tags into a comma-separated list of 'Key=Value' pairs
    if [ -n "$all_tags_json" ] && [ "$all_tags_json" != "null" ]; then
        tags_list=$(echo "$all_tags_json" | jq -r '.[] | "\(.Key)=\(.Value)"' | paste -sd "," -)
    else
        tags_list=""
    fi
    all_tags_list["$snapshot_id"]="$tags_list"
done < <(echo "$aws_output" | jq -r '.[] | [.SnapshotId, (.SourceResource // ""), (.AllTags // []) | @json] | @tsv')

# Output the snapshot ID, the source resource tag, and all tags
for snapshot_id in "${snapshot_ids[@]}"; do
    echo -e "$snapshot_id\t${source_resource_tags[$snapshot_id]}\t${all_tags_list[$snapshot_id]}"
done
