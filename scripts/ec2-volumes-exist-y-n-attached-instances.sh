#!/bin/bash

# Check if a file is provided as an argument; otherwise, read from stdin
input_file="${1:-/dev/stdin}"

# Read volume IDs into an array
mapfile -t volume_ids < "$input_file"

# Ensure there are volume IDs to process
if [ ${#volume_ids[@]} -eq 0 ]; then
    echo "No volume IDs provided."
    exit 1
fi

# Build a comma-separated list of volume IDs for the filter
volume_ids_str=$(IFS=','; echo "${volume_ids[*]}")

# Make a single AWS CLI call to describe volumes using filters
aws_output=$(aws ec2 describe-volumes \
    --filters "Name=volume-id,Values=${volume_ids_str}" \
    --query 'Volumes[].{VolumeId:VolumeId, Attachments:Attachments}' \
    --output json)

# Check if the AWS CLI call was successful
if [ $? -ne 0 ]; then
    echo "Error fetching volume details."
    exit 1
fi

# Parse the AWS CLI output
# Ensure jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "The 'jq' utility is required but not installed. Please install jq."
    exit 1
fi

# Create associative arrays for existing volumes and their attachments
declare -A volume_exists
declare -A volume_attachments

# Populate the associative arrays
existing_volumes=$(echo "$aws_output" | jq -r '.[] | .VolumeId')

# Mark existing volumes
for vid in $existing_volumes; do
    volume_exists["$vid"]=1
done

# Get attachments for existing volumes
while IFS= read -r volume; do
    vid=$(echo "$volume" | jq -r '.VolumeId')
    instance_ids=$(echo "$volume" | jq -r '.Attachments[].InstanceId' | paste -sd "," -)
    if [ -n "$instance_ids" ]; then
        volume_attachments["$vid"]="$instance_ids"
    fi
done <<< "$(echo "$aws_output" | jq -c '.[]')"

# Output the results
for vid in "${volume_ids[@]}"; do
    if [ "${volume_exists[$vid]}" ]; then
        if [ "${volume_attachments[$vid]}" ]; then
            echo "$vid y ${volume_attachments[$vid]}"
        else
            echo "$vid y"
        fi
    else
        echo "$vid n"
    fi
done
