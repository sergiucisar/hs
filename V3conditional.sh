#!/bin/bash

# ... (previous code)

# Iterate through each key in the Kubernetes secret
IFS=$'\n'
for ENTRY in ${SECRET_VALUES}; do
  KEY=$(echo "${ENTRY}" | cut -d'=' -f1)
  VALUE=$(echo "${ENTRY}" | cut -d'=' -f2)

  # Check if the key exists in Google Cloud Secret Manager
  EXISTING_VALUE=$(gcloud secrets versions access latest --secret=${KEY} --project=${PROJECT_ID} 2>/dev/null)

  # Compare existing value with the new value
  if [ "${EXISTING_VALUE}" != "${VALUE}" ]; then
    # If EXISTING_VALUE is null, create a new version
    if [ -z "${EXISTING_VALUE}" ]; then
      # Create a new version of the secret in Google Cloud Secret Manager
      gcloud secrets versions add ${KEY} --data-file=- --project=${PROJECT_ID} <<EOF
${VALUE}
EOF
    else
      # Disable all past versions of the secret
      gcloud secrets versions list ${KEY} --project=${PROJECT_ID} --filter="state=enabled" --format="value(name)" | xargs -I {} gcloud secrets versions disable {} --project=${PROJECT_ID}

      # Create a new version of the secret in Google Cloud Secret Manager
      gcloud secrets versions add ${KEY} --data-file=- --project=${PROJECT_ID} <<EOF
${VALUE}
EOF
    fi

    echo "Updated ${KEY} in Google Cloud Secret Manager"
  else
    echo "Value for ${KEY} is already up-to-date in Google Cloud Secret Manager"
  fi
done

# ... (rest of the script)
