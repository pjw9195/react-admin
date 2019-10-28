#!/bin/bash
AWS_PROFILE=$1
IMAGE_NAME=ourhealth
REGISTRY_URL=022995118196.dkr.ecr.ap-northeast-2.amazonaws.com/${IMAGE_NAME}:latest
HOST=ubuntu@ourhealths.kauboy.co.kr
APP_PATH=/home/ubuntu/${IMAGE_NAME}
DOCKER_COMPOSE=docker-compose.yml
PEM_FILE=~/.ssh/kaujinwoo.pem

function printUsage() {
    echo "Usage: deploy-dev.sh {profileName}"
    echo ""
}

function errorCheck() {
    if [[ $? -ne 0 ]]; then
    exit 1
fi
}

if [[ -z ${AWS_PROFILE} ]]; then
  printUsage
  exit 1
fi

set -e


npm run build
errorCheck

docker build -t ${IMAGE_NAME} .
errorCheck

docker tag ${IMAGE_NAME}:latest ${REGISTRY_URL}
errorCheck

ECR_LOGIN=$(aws ecr get-login --no-include-email --region ap-northeast-2 --profile ${AWS_PROFILE})
eval ${ECR_LOGIN}
errorCheck

docker push ${REGISTRY_URL}
errorCheck

ssh ${HOST} -i ${PEM_FILE} "sudo "${ECR_LOGIN}" && sudo docker pull "${REGISTRY_URL}""
errorCheck

ssh ${HOST} -i ${PEM_FILE} "mkdir -p ${APP_PATH}"
errorCheck

scp -i ${PEM_FILE} -d ./${DOCKER_COMPOSE} ${HOST}:${APP_PATH}
errorCheck

ssh ${HOST} -i ${PEM_FILE} "sudo docker-compose -f "${APP_PATH}"/"${DOCKER_COMPOSE}" -p "${IMAGE_NAME}" up -d --remove-orphans"
errorCheck

ssh ${HOST} -i ${PEM_FILE} "sudo docker image prune -f"
docker image prune -f

echo "Deploy Success!"
