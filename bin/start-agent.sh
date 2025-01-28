#!/usr/bin/env bash
#
# Run integration tests against a CW Agent.
#
# usage:
#   export AWS_REGION=us-west-2  # Optional, defaults to us-west-2
#   ./start-agent.sh

rootdir=$(git rev-parse --show-toplevel)
rootdir=${rootdir:-$(pwd)} # in case we are not in a git repository (Code Pipelines)

tempfile="$rootdir/src/integration-test/resources/agent/.temp"

###################################
# Configure and start the agent
###################################

pushd $rootdir/src/integration-test/resources/agent

# Create only config file with region
mkdir -p ./.aws
echo "[default]
region = ${AWS_REGION:-us-west-2}
" > ./.aws/config

# Build and run docker with IAM role support
docker build -t agent:latest .
docker run -p 25888:25888/udp -p 25888:25888/tcp \
    -e AWS_REGION=${AWS_REGION:-us-west-2} \
    -e AWS_CONTAINER_CREDENTIALS_RELATIVE_URI=${AWS_CONTAINER_CREDENTIALS_RELATIVE_URI} \
    -e AWS_CONTAINER_CREDENTIALS_FULL_URI=${AWS_CONTAINER_CREDENTIALS_FULL_URI} \
    -e AWS_EC2_METADATA_DISABLED=false \
    agent:latest &> $tempfile &

# Wait for container to start
sleep 5

# Optional: Check if container is running
if ! docker ps | grep agent:latest > /dev/null; then
    echo "Error: Container failed to start"
    cat $tempfile
    exit 1
fi

popd
