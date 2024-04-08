#!/bin/bash
set -e

# Function to load Kubernetes secrets as environment variables
load_secrets() {
    # Use kube-secrets-init to fetch and inject secrets into environment
    kube-secrets-init

    # Alternatively, you can load specific secrets manually
    # export MY_SECRET=$(cat /mnt/secrets-store/my-secret)
}

# Main entrypoint logic
main() {
    # Load secrets as environment variables
    load_secrets

    # Run Rails console (`rails c`)
    exec rails c
}

# Execute the main entrypoint logic
main "$@"
