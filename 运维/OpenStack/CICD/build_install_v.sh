#!/bin/bash
set -e

cd $(dirname $BASH_SOURCE)

function download_openstack_rpm() {
    openstack_url="http://10.100.7.30/openstack_victoria/"
    openstack_packages=$(curl $openstack_url | awk -F "\"" '{print $2}' | egrep "tar.gz|rpm")
    for p in $openstack_packages; do
        curl -C - -O $openstack_url$p
    done
}

#git clean -fd
#git checkout -- '*'
#git pull
sudo mv yum /tmp/
sudo rm -rf /tmp/yum/repodata
sudo rm -rf /tmp/yum/modules.yaml
sudo createrepo /tmp/yum/
cd /tmp/yum
/home/gitlab-runner/.local/bin/repo2module  -s stable . -n modules.yaml
cd -
sudo modifyrepo_c --mdtype=modules /tmp/yum/modules.yaml /tmp/yum/repodata/
sudo mv /tmp/yum yum
cd openstack
sudo rm -rf openstack
git clone -b dev git@10.10.10.12:cpcloud/openstack.git
cd -
tag=$(git describe --tags --exact-match 2>/dev/null || true)
if [ -n "$tag" ]; then
    ver=$tag
else
    ver=$(git describe --tags 2>/dev/null || true)
    if [ -z "$ver" ]; then
        ver=$(date +%Y%m%d)-$(git log --format="%h" -n1)
    fi
fi
cd ..
tar --exclude=".git" --exclude=".gitlab-ci.yml" --exclude="build.sh" -czf install-$ver.tgz install
cd -
sudo rm -rf yum

webroot="/usr/share/nginx/html/installer"
packages=/home/gitlab-runner/packages
if [ -d $packages ]; then
    commit=$(git log --format="%H" -n1)
    commit_dir=$packages/install/$commit
    if [ -e $commit_dir ]; then
        /bin/rm -fr $commit_dir
    fi
    mkdir -p $commit_dir
    sudo cp install-$ver.tgz $commit_dir
    sudo rm -rf $webroot/install.tgz*
    sudo cp install-$ver.tgz $webroot
fi