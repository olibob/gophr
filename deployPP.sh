#!/bin/bash
#Constants

REGION="eu-central-1"
REPOSITORY_NAME="gophr"
CLUSTER="apcluster"
FAMILY=`sed -n 's/.*"family": "\(.*\)",/\1/p' taskdefPP.json`
NAME=`sed -n 's/.*"name": "\(.*\)",/\1/p' taskdefPP.json`
SERVICE_NAME="${NAME}-srv-pp"

#Store the repositoryUri as a variable
REPOSITORY_URI=`aws ecr describe-repositories --repository-names ${REPOSITORY_NAME} --region ${REGION} | jq .repositories[].repositoryUri | tr -d '"'`

if [ "$IMAGE_TAG" == "" ]; then
  echo "TAG cannot be empty"
  exit 1
fi

#Replace the build number and respository URI placeholders with the constants above
sed -e "s;%TAG%;${IMAGE_TAG};g" -e "s;%REPOSITORY_URI%;${REPOSITORY_URI};g" taskdefPP.json > ${NAME}PP-v_${BUILD_NUMBER}.json
#Register the task definition in the repository
aws ecs register-task-definition --family ${FAMILY} --cli-input-json file://${WORKSPACE}/${NAME}PP-v_${BUILD_NUMBER}.json --region ${REGION}
SERVICES=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .failures[]`
#Get latest revision
REVISION=`aws ecs describe-task-definition --task-definition ${FAMILY} --region ${REGION} | jq .taskDefinition.revision`

#Create or update service
if [ "$SERVICES" == "" ]; then
  echo "entered existing service"

    aws ecs update-service --cluster ${CLUSTER} --region ${REGION} --service ${SERVICE_NAME} --task-definition ${FAMILY}:${REVISION}
else
  echo "service not found"
  exit 1
fi
