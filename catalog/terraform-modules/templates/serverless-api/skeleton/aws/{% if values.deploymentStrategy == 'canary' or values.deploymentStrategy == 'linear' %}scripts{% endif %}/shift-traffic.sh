#!/usr/bin/env bash
# Moves the traffic of the API to the newest published function version with
# CodeDeploy, using the deployment configuration of the deployment group, and
# waits for the result.
#
# Run it in the directory of the Terraform configuration after `terraform apply`.
# Needs the AWS CLI, jq and credentials that may read the Terraform state, read
# the function alias and create CodeDeploy deployments.
set -euo pipefail

function_name=$(terraform output -raw function_name)
target_version=$(terraform output -raw function_version)
application=$(terraform output -raw codedeploy_application)
deployment_group=$(terraform output -raw codedeploy_deployment_group)

current_version=$(aws lambda get-alias \
  --function-name "$function_name" \
  --name live \
  --query FunctionVersion \
  --output text)

if [ "$current_version" = "$target_version" ]; then
  echo "The alias live of $function_name already points at version $target_version."
  exit 0
fi

app_spec=$(jq -cn \
  --arg name "$function_name" \
  --arg current "$current_version" \
  --arg target "$target_version" \
  '{
    version: "0.0",
    Resources: [{
      function: {
        Type: "AWS::Lambda::Function",
        Properties: {Name: $name, Alias: "live", CurrentVersion: $current, TargetVersion: $target}
      }
    }]
  }')
revision=$(jq -cn --arg content "$app_spec" \
  '{revisionType: "AppSpecContent", appSpecContent: {content: $content}}')

deployment_id=$(aws deploy create-deployment \
  --application-name "$application" \
  --deployment-group-name "$deployment_group" \
  --description "Version $current_version to $target_version" \
  --revision "$revision" \
  --query deploymentId \
  --output text)

echo "Deployment $deployment_id moves $function_name from version $current_version to $target_version."
aws deploy wait deployment-successful --deployment-id "$deployment_id"
echo "Deployment $deployment_id succeeded."
