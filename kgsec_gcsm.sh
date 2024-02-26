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

# Check if the secret already exists in Google Cloud Secret Manager
if gcloud secrets describe ${SECRET_ID} --project=${PROJECT_ID} &>/dev/null; then
  echo "Secret ${SECRET_ID} already exists. Updating versions..."

  # Update the existing secret with new versions
  IFS=$'\n'
  for ENTRY in ${SECRET_VALUES}; do
    KEY=$(echo "${ENTRY}" | cut -d'=' -f1)
    VALUE=$(echo "${ENTRY}" | cut -d'=' -f2)

    gcloud secrets versions add ${SECRET_ID} --data-file=- --project=${PROJECT_ID} <<EOF
${VALUE}
EOF

    echo "Updated ${KEY} in Google Cloud Secret Manager"
  done

  unset IFS
else
  echo "Secret ${SECRET_ID} does not exist. Creating and adding values..."

  # Create the secret in Google Cloud Secret Manager
  IFS=$'\n'
  for ENTRY in ${SECRET_VALUES}; do
    KEY=$(echo "${ENTRY}" | cut -d'=' -f1)
    VALUE=$(echo "${ENTRY}" | cut -d'=' -f2)

    gcloud secrets create ${KEY} --replication-policy="automatic" --data-file=- --project=${PROJECT_ID} <<EOF
${VALUE}
EOF

    echo "Added ${KEY} to Google Cloud Secret Manager"
  done

  unset IFS
fi
