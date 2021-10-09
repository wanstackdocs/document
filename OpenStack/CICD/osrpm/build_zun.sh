#!/bin/bash

cd $(dirname $BASH_SOURCE)

git clean -fd
git checkout -- '*'
git pull

python setup.py sdist

packages=/home/gitlab-runner/packages
if [ -d $packages ]; then
    commit=$(git log --format="%H" -n1)
    commit_dir=$packages/zun/$commit
    if [ -e $commit_dir ]; then
        /bin/rm -fr $commit_dir
    fi
    mkdir -p $commit_dir
    cp dist/* $commit_dir
fi
