#!/bin/bash
set -ex

APP_NAME="jdk"
APP_VERSION="8.121.13"
SOURCE_REPO='alpine'
SOURCE_TAG='3.5'
DEST_REPO='packer'
LOGIN_USERNAME="${LOGIN_USERNAME}"
LOGIN_PASSWORD="${LOGIN_PASSWORD}"

INSTALL_SCRIPT="install-alpine-jdk.sh"
ASSETS_SOURCE="assets/${APP_NAME}-${APP_VERSION}/"
ASSETS_DEST="/tmp/provisioning"
JAVA_HOME="/opt/jdk"
INSTALL_ARGS="${APP_VERSION} ${ASSETS_DEST} ${JAVA_HOME}"

PACKER_TEMPLATE='packer-docker-runtime.json'

DEST_TAG_PREFIX="${SOURCE_REPO}-${APP_NAME}-${APP_VERSION}"

packer_args=(
  -var "source_repo=$SOURCE_REPO"
  -var "source_tag=$SOURCE_TAG"
  -var "dest_repo=$DEST_REPO"
  -var "assets_source=$ASSETS_SOURCE"
  -var "assets_dest=$ASSETS_DEST"
  -var "dest_tag_prefix=$DEST_TAG_PREFIX"
  -var "install_script=$INSTALL_SCRIPT"
  -var "path_string=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${JAVA_HOME}/bin"
  -var "JAVA_HOME=$JAVA_HOME"
  -var "install_args=$INSTALL_ARGS"
  -var "login_username=$LOGIN_USERNAME"
  -var "login_password=$LOGIN_PASSWORD"
  $PACKER_TEMPLATE)

  echo "Running: packer build ${packer_args[*]}"
  packer build ${packer_args[*]}
