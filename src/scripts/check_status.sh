#!/bin/bash
# This example uses envsubst to support variable substitution in the string parameter type.
# https://circleci.com/docs/orbs-best-practices/#accepting-parameters-as-strings-or-environment-variables

# Check if the key variable is set
if [ -z "${!PARAM_CIRCLECI_API_KEY}" ]; then
  echo "CircleCI API key not set"
fi

CIRCLE_TOKEN="${!PARAM_CIRCLECI_API_KEY}"
PIPELINE_ID=$(cat circleback_workspace/CIRCLEBACK_ORB_PIPELINE)

fetch_status() {
  API_RESPONSE=$(
    curl --request GET \
      --url "https://circleci.com/api/v2/pipeline/$PIPELINE_ID/workflow" \
      --header "Circle-Token: $CIRCLE_TOKEN" \
      --header "content-type: application/json"
  )

  WORKFLOWS=$(echo "$API_RESPONSE" | jq -c '.items[]')

  if [ -z "$WORKFLOWS" ]; then
    echo "Failed to fetch workflows."
    echo "API Response: $API_RESPONSE"
    exit 1
  fi

  for workflow in $WORKFLOWS; do
    status=$(echo "$workflow" | jq -r '.status')
    name=$(echo "$workflow" | jq -r '.name')
    # Check if the status equals "RUNNING"
    if [ "$status" == "running" ]; then
      echo "Triggered pipeline is still running. Workflow \"$name\" has status \"$status.\""

      if [ "$PARAM_POLL" == "false" ]; then
        echo "Polling disabled, exiting."
        exit 1
      fi

      sleep "$PARAM_POLL_INTERVAL"
      fetch_status
      break
    elif [ "$status" != "success" ]; then
      echo "Triggered pipeline did not succeed. Workflow \"$name\" failed with status \"$status.\""
      exit 1
    fi
  done
}

fetch_status

echo "Pipeline finished, continuing."
