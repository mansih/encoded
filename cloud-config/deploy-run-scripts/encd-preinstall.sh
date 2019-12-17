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
sudo -H -u encoded git clone "$GIT_REPO" "$encd_home"
sudo -H -u encoded git checkout -b "$GIT_BRANCH" "$git_uri"

encd_venv="$encd_home/.pyvenv"
sudo -H -u encoded python3 -m venv "$encd_venv"
sourde "$encd_venv/bin/activate"
sudo -H -u encoded "$encd_venv/bin/pip" install --upgrade pip zc.buildout setuptools redis
sudo -H -u encoded "$encd_venv/bin/pip" install -r "$encd_home/requirements.txt"
