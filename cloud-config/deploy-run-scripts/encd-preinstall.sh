#!/bin/bash
# Setup encoded app
# encoded user
# apt deps:

GIT_REPO="$1"
GIT_REMOTE="$2"
GIT_BRANCH="$3"

git_uri="$GIT_REMOTE/$GIT_BRANCH"

encd_home='/srv/encoded'
mkdir "$encd_home"
chown encoded:encoded "$encd_home"
cd "$encd_home"
sudo -u encoded git clone "$GIT_REPO" .
sudo -u encoded git checkout -b "$GIT_BRANCH" "$git_uri"
sudo pip3 install --upgrade pip
sudo pip3 install -U zc.buildout setuptools redis
sudo pip3 install -r requirements.txt
