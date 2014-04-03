#!/bin/bash

declare -A ARGS
ARGS=($@)

source ./functions.sh


# Verify some variables
die_if_not_set $LINENO MIRANTIS_PUBLIC_REPO_PREFIX
die_if_not_set $LINENO MIRANTIS_INTERNAL_REPO_PREFIX
die_if_not_set $LINENO APT_LOCAL_REPO


# First, remove any repository references
drop_mirantis_public_repos
drop_mirantis_internal_repos

apt-get update


# Then, remove all packages that are not in OBS_REQUEST_IDS
add_mirantis_internal_repo stable testing


# Then, add per-requiest repositories
add_mirantis_internal_repo "$BUILD_REQUEST_IDS"


# Update cache before actual installation
apt-get update


install_murano_prereqs


purge_murano_packages


install_murano_packages


#configure_murano


restart_murano
