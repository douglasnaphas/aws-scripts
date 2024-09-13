#!/bin/bash

# Take in a newline-separated list of AWS EBS snapshot ids, and output a
# newline separated list where each line contains the snapshot id followed by 
# the value of the tag aws:backup:source-resource, if it exists.

# Check if a file is provided as an argument; otherwise, read from stdin
input="${1:-/dev/stdin}"

# Read snapshot IDs line by line
while IFS= read -r snapshot_id; do
    # Fetch the tag value for aws:backup:source-resource
    tag_value=$(aws ec2 describe-snapshots --snapshot-ids "$snapshot_id" \
        --query 'Snapshots[0].Tags[?Key==`aws:backup:source-resource`].Value' \
        --output text)

    # Output the snapshot ID and tag value
    echo "$snapshot_id $tag_value"
done < "$input"
