#!/bin/bash

# Check if the user provided the handles file as an argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <handles_file>"
    exit 1
fi

# Assign the argument to the HANDLES_FILE variable
HANDLES_FILE=$1
BUCKETNAME="hwe-fall-2024"

# Loop through the file and perform actions for each handle
while IFS= read -r handle; do
    # Delete the S3 directory and all files under it
    S3_PATH="s3://${BUCKETNAME}/${handle}"
    aws s3 rm "$S3_PATH" --recursive

    # Remove any policies attached to the IAM user
    POLICIES=$(aws iam list-attached-user-policies --user-name "$handle" --query 'AttachedPolicies[].PolicyName' --output text)
    for policy in $POLICIES; do
        aws iam detach-user-policy --user-name "$handle" --policy-arn "arn:aws:iam::aws:policy/${policy}"
    done

    # Remove the IAM user from any groups
    IAM_GROUPS=$(aws iam list-groups-for-user --user-name "$handle" --query 'Groups[].GroupName' --output text)
    for group in $IAM_GROUPS; do
        aws iam remove-user-from-group --user-name "$handle" --group-name "$group"
    done

    # Remove the login profile from the IAM user
    aws iam delete-login-profile --user-name "$handle" >/dev/null 2>&1

    # Remove all access keys associated with the IAM user
    ACCESS_KEYS=$(aws iam list-access-keys --user-name "$handle" --query 'AccessKeyMetadata[].AccessKeyId' --output text)
    for access_key in $ACCESS_KEYS; do
        aws iam delete-access-key --user-name "$handle" --access-key-id "$access_key"
    done

    # Delete the IAM user
    aws iam delete-user --user-name "$handle"

    echo "Deleted IAM user: $handle"
done < "$HANDLES_FILE"
