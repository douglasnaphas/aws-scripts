#!/usr/bin/env node

const program = require('commander');
program
  .version('1.0.0')
  .option('-k, --keyword WORD', 'The word to search policy names for')
  .parse(process.argv);

(async () => {
  const AWS = require('aws-sdk');
  console.log('hello world');
  const iam = new AWS.IAM();
  const iamResponse = await new Promise((resolve, reject) => {
    iam.listPolicies({}, (err, data) => {
      resolve({ err: err, data: data });
    });
  });
  console.log('error:');
  console.log(iamResponse.err);
  console.log('data:');
  console.log(iamResponse.data);
})();
