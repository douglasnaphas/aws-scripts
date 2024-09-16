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

# Build a comma-separated list of volume IDs
volume_ids_str=$(IFS=','; echo "${volume_ids[*]}")

# Make a single AWS CLI call to describe the volumes using filters
aws_output=$(aws ec2 describe-volumes --filters "Name=volume-id,Values=${volume_ids_str}" --query 'Volumes[].VolumeId' --output text)

# Check if the AWS CLI call was successful
if [ $? -ne 0 ]; then
    echo "Error fetching volume details."
    exit 1
fi

# Convert the output into an array of existing volume IDs
read -a existing_volumes <<< "$aws_output"

# Create an associative array for quick lookup
declare -A volume_exists
for vid in "${existing_volumes[@]}"; do
    volume_exists["$vid"]=1
done

# Output the volume ID and whether it exists ("y" or "n")
for vid in "${volume_ids[@]}"; do
    if [ "${volume_exists[$vid]}" ]; then
        echo "$vid y"
    else
        echo "$vid n"
    fi
done
