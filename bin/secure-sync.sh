#!/bin/bash

set -e

aws s3 sync s3://${AWS_S3_CONFIG_BUCKET}/credentials.json config/secure/service_account_cred.json
