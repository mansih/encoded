#!/bin/bash
# Setup encoded app
# encoded user
# apt deps:

GIT_REPO="$1"
GIT_REMOTE="$2"
GIT_BRANCH="$3"

git_uri="$GIT_REMOTE/$GIT_BRANCH"

encd_pybin='/srv/encoded/.pyvenv/bin'
encd_home='/srv/encoded'
mkdir "$encd_home"
chown encoded:encoded "$encd_home"
cd "$encd_home"
sudo -u encoded python3 -m venv .pyvenv
sudo -u encoded "$encd_pybin/pip" install --upgrade pip zc.buildout setuptools redis
sudo -u encoded git clone "$GIT_REPO" .
sudo -u encoded git checkout -b "$GIT_BRANCH" "$git_uri"
sudo -u encoded "$encd_pybin/pip" install -r requirements.txt
