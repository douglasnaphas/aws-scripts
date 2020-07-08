#!/usr/bin/env bash

echo "hello, \$1 is $1"
KEYWORD=$1

# get all the buckets of interest
aws s3api list-buckets | \
  jq '.Buckets | map(select(.Name | test("'${KEYWORD}'")))'

# for each

  # get the 
