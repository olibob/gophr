#!/bin/bash
#Constants

REGION="eu-central-1"
REPOSITORY_NAME="gophr"
CLUSTER="apcluster"
FAMILY=`sed -n 's/.*"family": "\(.*\)",/\1/p' taskdef.json`
NAME=`sed -n 's/.*"name": "\(.*\)",/\1/p' taskdef.json`
SERVICE_NAME="${NAME}-service-${ENV_TYPE}"
TARGET_GROUP_NAME="gophrApp"

getTargetGroupARN() {
  echo `aws elbv2 describe-target-groups --names ${TARGET_GROUP_NAME} | jq .TargetGroups[].TargetGroupArn  | tr -d '"'`
}

getLoadBalancerARN() {
  echo `aws elbv2 describe-target-groups --names ${TARGET_GROUP_NAME} | jq .TargetGroups[].LoadBalancerArns[0] | tr -d '"'`
}

# Attention!!!
# The ENV_TYPE variable needs to be defined prior to running this script
# e.g.: expoert ENV_TYPE="dev"
if [ "${ENV_TYPE}" == "" ]; then
  echo "ENV_TYPE environment variable not defined!"
  exit -1
fi

#Store the repositoryUri as a variable
REPOSITORY_URI=`aws ecr describe-repositories --repository-names ${REPOSITORY_NAME} --region ${REGION} | jq .repositories[].repositoryUri | tr -d '"'`

#Replace the build number and respository URI placeholders with the constants above
sed -e "s;%BUILD_NUMBER%;${BUILD_NUMBER};g" -e "s;%REPOSITORY_URI%;${REPOSITORY_URI};g" -e "s;%ENV_TYPE%;${ENV_TYPE};g" taskdef.json > ${NAME}-v_${BUILD_NUMBER}.json
#Register the task definition in the repository
aws ecs register-task-definition --family ${FAMILY} --cli-input-json file://${WORKSPACE}/${NAME}-v_${BUILD_NUMBER}.json --region ${REGION}
SERVICES=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .failures[]`

#Get latest revision if a revision is not explicitly requested (mainly for not dev deployments)
if [ "${REVISION}" == "" ]; then
  REVISION=`aws ecs describe-task-definition --task-definition ${FAMILY} --region ${REGION} | jq .taskDefinition.revision`
fi

#Create or update service
if [ "$SERVICES" == "" ]; then
  echo "entered existing service"
  DESIRED_COUNT=`aws ecs describe-services --services ${SERVICE_NAME} --cluster ${CLUSTER} --region ${REGION} | jq .services[].desiredCount`
  if [ ${DESIRED_COUNT} = "0" ]; then
    if [ "${ENV_TYPE}" == "dev" ]; then
      DESIRED_COUNT="1"
      aws ecs update-service --cluster ${CLUSTER} --region ${REGION} --service ${SERVICE_NAME} --task-definition ${FAMILY}:${REVISION} --desired-count ${DESIRED_COUNT}
    else
      DESIRED_COUNT="2"
      TARGET_GROUP=$(getTargetGroup)
      LOAD_BALANCER=$(getLoadBalancerARN)

      sed -e "s;%CLUSTER%;${CLUSTER};g" -e "s;%SERVICE_NAME%;${SERVICE_NAME};g" -e "s;%TARGET_GROUP%;${TARGET_GROUP};g" -e "s;%LOAD_BALANCER%;${LOAD_BALANCER};g" servicedef.json > ${SERVICE_NAME}-v_${BUILD_NUMBER}.json

      aws ecs update-service --region ${REGION} --service ${SERVICE_NAME} --cli-input-json file://${SERVICE_NAME}-v_${BUILD_NUMBER}.json
    fi
  fi
else
  echo "entered new service"
  if [ "${ENV_TYPE}" == "dev" ]; then
    aws ecs create-service --service-name ${SERVICE_NAME} --desired-count 1 --task-definition ${FAMILY} --cluster ${CLUSTER} --region ${REGION}
  else
    echo "deploying ..."
    TARGET_GROUP=$(getTargetGroup)
    LOAD_BALANCER=$(getLoadBalancerARN)

    sed -e "s;%CLUSTER%;${CLUSTER};g" -e "s;%SERVICE_NAME%;${SERVICE_NAME};g" -e "s;%TARGET_GROUP%;${TARGET_GROUP};g" -e "s;%LOAD_BALANCER%;${LOAD_BALANCER};g" servicedef.json > ${SERVICE_NAME}-v_${BUILD_NUMBER}.json

    aws ecs create-service --service-name ${SERVICE_NAME} --region ${REGION} --cli-input-json file://${SERVICE_NAME}-v_${BUILD_NUMBER}.json
  fi
fi
