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

  # Check if the value contains the namespace name
  if [[ "${VALUE}" != *"${NAMESPACE}"* ]]; then
    # If not, replace or append the namespace name to the value
    NEW_VALUE="${VALUE}"
    if [ -n "${VALUE}" ]; then
      NEW_VALUE="${NAMESPACE}-${VALUE}"
    else
      NEW_VALUE="${NAMESPACE}-"
    fi
    echo "Updated value with namespace: ${VALUE} -> ${NEW_VALUE}"

    # Check if the key exists in Google Cloud Secret Manager
    EXISTING_VALUE=$(gcloud secrets versions access latest --secret=${KEY} --project=${PROJECT_ID} 2>/dev/null)

    if [ "${EXISTING_VALUE}" != "${NEW_VALUE}" ]; then
      # Disable all past versions of the secret
      gcloud secrets versions list ${KEY} --project=${PROJECT_ID} --filter="state=enabled" --format="value(name)" | xargs -I {} gcloud secrets versions disable {} --project=${PROJECT_ID}

      # Create a new version of the secret in Google Cloud Secret Manager
      gcloud secrets versions add ${KEY} --data-file=- --project=${PROJECT_ID} <<EOF
${NEW_VALUE}
EOF

      echo "Updated ${KEY} in Google Cloud Secret Manager"
    else
      echo "Value for ${KEY} is already up-to-date in Google Cloud Secret Manager"
    fi
  else
    # If the value already contains the namespace, proceed as before
    # Check if the key exists in Google Cloud Secret Manager
    EXISTING_VALUE=$(gcloud secrets versions access latest --secret=${KEY} --project=${PROJECT_ID} 2>/dev/null)

    if [ "${EXISTING_VALUE}" != "${VALUE}" ]; then
      # Disable all past versions of the secret
      gcloud secrets versions list ${KEY} --project=${PROJECT_ID} --filter="state=enabled" --format="value(name)" | xargs -I {} gcloud secrets versions disable {} --project=${PROJECT_ID}

      # Create a new version of the secret in Google Cloud Secret Manager
      gcloud secrets versions add ${KEY} --data-file=- --project=${PROJECT_ID} <<EOF
${VALUE}
EOF

      echo "Updated ${KEY} in Google Cloud Secret Manager"
    else
      echo "Value for ${KEY} is already up-to-date in Google Cloud Secret Manager"
    fi
  fi
done

unset IFS
