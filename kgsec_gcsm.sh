#!/bin/bash

# Set your Google Cloud Project ID and Secret Manager Secret ID
PROJECT_ID="your-project-id"
SECRET_ID="your-secret-id"

# Set the Kubernetes namespace and secret name
NAMESPACE="your-namespace"
SECRET_NAME="your-secret-name"

# Get the Kubernetes secret data
SECRET_DATA=$(kubectl get secret ${SECRET_NAME} -n ${NAMESPACE} -o json | jq -r '.data')

# Decode the base64-encoded data
SECRET_VALUES=$(echo "${SECRET_DATA}" | jq -r 'to_entries | map("\(.key)=\(.value | @base64d)") | .[]')

# Iterate through each key-value pair and add it to Google Cloud Secret Manager
IFS=$'\n'
for ENTRY in ${SECRET_VALUES}; do
    KEY=$(echo "${ENTRY}" | cut -d'=' -f1)
    VALUE=$(echo "${ENTRY}" | cut -d'=' -f2)

    # Add the secret to Google Cloud Secret Manager
    gcloud secrets create ${KEY} --replication-policy="automatic" --data-file=- <<EOF
${VALUE}
EOF

    echo "Added ${KEY} to Google Cloud Secret Manager"
done

unset IFS
