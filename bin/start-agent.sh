#!/usr/bin/env bash

rootdir=$(git rev-parse --show-toplevel)
rootdir=${rootdir:-$(pwd)}

tempfile="$rootdir/src/integration-test/resources/agent/.temp"

pushd $rootdir/src/integration-test/resources/agent

# Get the CodeBuild service role ARN
CODEBUILD_ROLE_ARN=$(aws sts get-caller-identity --query 'Arn' --output text)

# Create config with role and region
mkdir -p ./.aws
echo "[default]
region = ${AWS_REGION:-us-west-2}
role_arn = ${CODEBUILD_ROLE_ARN}
credential_source = EcsContainer
" > ./.aws/config

# For debugging
echo "Using role ARN: ${CODEBUILD_ROLE_ARN}"
cat ./.aws/config

docker build -t agent:latest .
docker run -p 25888:25888/udp -p 25888:25888/tcp \
    -e AWS_REGION=${AWS_REGION:-us-west-2} \
    -e AWS_CONTAINER_CREDENTIALS_RELATIVE_URI \
    -v ${PWD}/.aws/config:/root/.aws/config:ro \
    agent:latest &> $tempfile &

# Show logs for debugging
sleep 2
cat $tempfile

popd
