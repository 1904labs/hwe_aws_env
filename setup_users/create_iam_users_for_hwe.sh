#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Pass 2 args, the filename of handles to create, and a suffix that will be appended to each users handle to create their initial password"
    exit 1
fi
BUCKETNAME="hwe-fall-2024"
GROUP_NAME="hwe-students"
FILENAME=$1
INITIAL_PASSWORD_SUFFIX=$2

# Check if handles.txt file exists
if [ ! -f "$FILENAME" ]; then
    echo "$FILENAME file not found!"
    exit 2 
fi

# Check if the group exists
aws iam get-group --group-name "$GROUP_NAME" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Group $GROUP_NAME does not exist! Exiting..."
    exit 2 
fi

# Loop through each line in handles.txt and create IAM users
while IFS= read -r handle; do
    # Create IAM user if it doesn't already exist
    aws iam get-user --user-name "$handle" >/dev/null 2>&1
    if [ $? -ne 0 ]; then
        aws iam create-user --user-name "$handle"
        if [ $? -eq 0 ]; then
            echo "Created IAM user: $handle"
        else
            echo "Failed to create IAM user: $handle"
            continue
        fi

        # Set an initial password for the user
        INITIAL_PASSWORD="${handle}${INITIAL_PASSWORD_SUFFIX}"
        aws iam create-login-profile --user-name "$handle" --password "$INITIAL_PASSWORD" --password-reset-required
        if [ $? -eq 0 ]; then
            echo "Assigned initial password for $handle: $INITIAL_PASSWORD (Password reset required at first login)"
        else
            echo "Failed to assign initial password for $handle"
        fi
    else
        echo "Skipping account creation for $handle: Account already exists"
    fi

    # Add the user to the specified group
    aws iam add-user-to-group --user-name "$handle" --group-name "$GROUP_NAME"
    if [ $? -eq 0 ]; then
        echo "Enrolled $handle in group $GROUP_NAME"       
    else
        echo "Failed to enroll $handle in group $GROUP_NAME"
    fi
    echo "Congratulations! You have successfully connected to S3 and read a file under s3://${BUCKETNAME}/${handle}! Your credentials are set up correctly!" > success_message
    aws s3 cp success_message "s3://${BUCKETNAME}/${handle}/success_message"
    if [ $? -eq 0 ]; then
        echo "Created directory s3://${BUCKETNAME}/${handle}"
    else
        echo "Failed to create directory s3://${BUCKETNAME}/${handle}"
    fi
done < "$FILENAME"
