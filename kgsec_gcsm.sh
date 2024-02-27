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

# Iterate through each key in the Kubernetes secret
IFS=$'\n'
for ENTRY in ${SECRET_VALUES}; do
  KEY=$(echo "${ENTRY}" | cut -d'=' -f1)
  VALUE=$(echo "${ENTRY}" | cut -d'=' -f2)

  # Check if the key exists in Google Cloud Secret Manager
  EXISTING_VALUE=$(gcloud secrets versions access latest --secret=${KEY} --project=${PROJECT_ID} 2>/dev/null)

  if [ "${EXISTING_VALUE}" != "${VALUE}" ]; then
    # If the value is different or missing, update the existing secret with a new version
    gcloud secrets versions add ${KEY} --data-file=- --project=${PROJECT_ID} <<EOF
${VALUE}
EOF

    echo "Updated ${KEY} in Google Cloud Secret Manager"
  else
    echo "Value for ${KEY} is already up-to-date in Google Cloud Secret Manager"
  fi
done

unset IFS

