#!/bin/bash

if [ $# -ne 2 ]; then
    echo "Pass 2 args, the filename of handles to create, and the semester for this HWE session in the form semester-year(eg, fall-2023)"
    echo "Must also set the default password for each user"
    exit 1
fi

FILENAME=$1
SEMESTER=$2
# CHANGE ME: The value for this field will be appended to each user's handle to populate their initial password.
# The value for this field should be set manually inside the script on each run and not committed to source control.
INITIAL_PASSWORD_SUFFIX=""
if [ -z "$INITIAL_PASSWORD_SUFFIX" ] ; then
    echo "INITIAL_PASSWORD_SUFFIX needs to be set to something! But don't commit it to source control!"
    exit 1 
fi
GROUP_NAME="hwe-students"

# Check if handles.txt file exists
if [ ! -f "$FILENAME" ]; then
    echo "$FILENAME file not found!"
    exit 2 
fi

if [ -z "$INITIAL_PASSWORD_SUFFIX" ]; then
    echo "Must set INITIAL_PASSWORD_SUFFIX to some value!"
    exit 3 
fi

# Check if the group exists
aws iam get-group --group-name "$GROUP_NAME" >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "Group $GROUP_NAME does not exist! Exiting..."
    exit 4 
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
    BUCKETNAME="hwe-${SEMESTER}"
    echo "Congratulations! You have successfully connected to S3 and read a file under s3://${BUCKETNAME}/${handle}! Your credentials are set up correctly!" > success_message
    aws s3 cp success_message "s3://${BUCKETNAME}/${handle}/success_message"
    if [ $? -eq 0 ]; then
        echo "Created directory s3://${BUCKETNAME}/${handle}"
    else
        echo "Failed to create directory s3://${BUCKETNAME}/${handle}"
    fi
done < "$FILENAME"
