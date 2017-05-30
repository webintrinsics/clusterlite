#!/bin/bash

#
# Generated by Webintrinsics Clusterlite:
# __COMMAND__
#
# Parameters: __PARSED_ARGUMENTS__
#
# Prerequisites:
# - Docker engine
# - Internet connection
#

set -e

install_volume() {
    echo "__LOG__ installing data directory"
    # creating reference to volume directory
    mkdir /var/lib/clusterlite || echo ""
    echo __VOLUME__ > /var/lib/clusterlite/volume.txt
    # setting up volume directory
    mkdir __VOLUME__ || echo ""
    mkdir __VOLUME__/clusterlite || echo ""
    echo __CONFIG__ > __VOLUME__/clusterlite.json
    echo "{}" > __VOLUME__/placements.json
}

install_weave() {
    echo "__LOG__ installing weave network"
    # downloading weave installation script
    docker_location="$(which docker)"
    weave_destination="${docker_location/docker/weave}"
    curl -L git.io/weave -o ${weave_destination}
    chmod a+x ${weave_destination}
    # disabling weave check for new versions
    export CHECKPOINT_DISABLE=1
    # setting specific weave version to install
    export WEAVE_VERSION=1.9.5
    # launching weave node with encryption and fixed set of seeds
    weave launch --password __TOKEN__ __SEEDS__
    # waiting for quorum consistency
    weave prime
}

install_volume
install_weave
echo "__LOG__ done"

