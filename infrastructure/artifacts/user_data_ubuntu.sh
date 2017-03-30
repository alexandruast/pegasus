#!/bin/bash
sudo DEBIAN_FRONTEND=noninteractive \
  apt-get -y -qq update
sudo DEBIAN_FRONTEND=noninteractive \
  apt-get -y -qq install python aptitude
