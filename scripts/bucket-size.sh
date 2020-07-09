#!/usr/bin/env bash

KEYWORD=$1

aws s3api list-buckets | \
  jq '.Buckets | map(select(.Name | test("'${KEYWORD}'")))[] | .Name' | \
  tr -d '"' | \
while read bucket
do
  aws s3api list-object-versions --bucket ${bucket} | \
    jq '.Versions[] | .Size' | \
    awk -v bucket=${bucket} \
      '{s = s + $1}
       END {
         printf("%17s   %s   %s\n", "BYTES", "MAX COST", "BUCKET");
         printf("%'"17'"'d   %8.2f   %s\n", s, s * .023 / 1000 / 1000 / 1000, bucket);
       }'
done

