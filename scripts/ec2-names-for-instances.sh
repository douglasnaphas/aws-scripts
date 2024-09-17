#!/bin/bash

# Check if a file is provided as an argument; otherwise, read from stdin
input_file="${1:-/dev/stdin}"

# Read instance IDs into an array
mapfile -t instance_ids < "$input_file"

# Ensure there are instance IDs to process
if [ ${#instance_ids[@]} -eq 0 ]; then
    echo "No instance IDs provided."
    exit 1
fi

# Build the list of instance IDs for the AWS CLI command
instance_ids_str="${instance_ids[@]}"

# Make a single AWS CLI call to describe the instances
aws_output=$(aws ec2 describe-instances --instance-ids ${instance_ids_str} \
    --query 'Reservations[].Instances[].{InstanceId:InstanceId, Name:Tags[?Key==`Name`]|[0].Value}' \
    --output json)

# Check if the AWS CLI call was successful
if [ $? -ne 0 ]; then
    echo "Error fetching instance details."
    exit 1
fi

# Ensure jq is installed
if ! command -v jq >/dev/null 2>&1; then
    echo "The 'jq' utility is required but not installed. Please install jq."
    exit 1
fi

# Create an associative array to hold the mapping from InstanceId to Name
declare -A instance_names

# Parse the AWS CLI output using jq
while read -r instance_id instance_name; do
    instance_names["$instance_id"]="$instance_name"
done < <(echo "$aws_output" | jq -r '.[] | [.InstanceId, (.Name // "")] | @tsv')

# Output the instance ID and name
for instance_id in "${instance_ids[@]}"; do
    echo "$instance_id ${instance_names[$instance_id]}"
done
