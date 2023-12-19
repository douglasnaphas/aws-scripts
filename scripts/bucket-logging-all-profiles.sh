#!/usr/bin/env bash
cat ~/.aws/config | grep '[[]profile' | tr -d '[]' | awk '{print $2}' | \
  while read profile ; do
    echo $profile
    aws --profile $profile s3 ls | \
      awk '{print $3}' | \
      while read bucket ; do
        echo $bucket
        aws --profile $profile s3api get-bucket-logging --bucket $bucket
        echo
      done
    echo "========================================"
  done