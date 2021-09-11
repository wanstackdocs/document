#!/bin/bash

set -e

packages=/home/gitlab-runner/packages
final_dir=/home/gitlab-runner/webroot/installer

commit=$(git log --format="%H" -n1)
commit_dir=$packages/installer/$commit

do_build(){
    if [ -e $packages ]; then # running on gitlab-runner
        echo 'collecting packages'
        failed=false
        for mod in cinder keystoneauth1 neutron-lib python-glanceclient \
            python-novaclient glance keystonemiddleware neutron \
            nova python-neutronclient; do
            mod_commit=$(git submodule status src/$mod | awk '{print $1}')
            pkg_dir=$packages/$mod/$mod_commit
            if ! ls $pkg_dir/* &>/dev/null; then
                echo "mod $mod $mod_commit not built"
                failed=true
                continue
            fi
            /bin/cp $pkg_dir/* packages/yum/ 
        done
        
        for mod in zun python-zunclient kuryr-libnetwork neutron-taas; do
            mod_commit=$(git submodule status src/$mod | awk '{print $1}')
            pkg_dir=$packages/$mod/$mod_commit
            if ! ls $pkg_dir/* &>/dev/null; then
                echo "mod $mod $mod_commit not built"
                failed=true
                continue
            fi
            /bin/cp $pkg_dir/* packages/pip/ 
        done
        
        if $failed; then
            exit 1
        fi
    fi
    
    # get version info

    tag=$(git describe --tags --exact-match 2>/dev/null || true)
    if [ -n "$tag" ]; then
        ver=$tag
    else
        ver=$(git describe --tags 2>/dev/null || true)
        if [ -z "$ver" ]; then
            ver=$(date +%Y%m%d)-$(git log --format="%h" -n1)
        fi
    fi
    
    echo "$ver" > version
    echo >> version
    echo $commit installer >> version
    echo >> version
    git submodule | sed 's/^ *//' >> version
    
    # making package
    
    /bin/cp params.example /tmp/params.example.bk
    
    params=params.example
    sed -i "s|^ADMIN_PASS=.*\$|ADMIN_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^KEYSTONE_DBPASS=.*\$|KEYSTONE_DBPASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^GLANCE_DBPASS=.*\$|GLANCE_DBPASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^GLANCE_PASS=.*\$|GLANCE_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^METADATA_SECRET=.*\$|METADATA_SECRET=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^RABBIT_PASS=.*\$|RABBIT_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^NOVA_DBPASS=.*\$|NOVA_DBPASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^NOVA_PASS=.*\$|NOVA_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^PLACEMENT_PASS=.*\$|PLACEMENT_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^NEUTRON_DBPASS=.*\$|NEUTRON_DBPASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^NEUTRON_PASS=.*\$|NEUTRON_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^CINDER_DBPASS=.*\$|CINDER_DBPASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^CINDER_PASS=.*\$|CINDER_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^KURYR_PASS=.*\$|KURYR_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^ZUN_PASS=.*\$|ZUN_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^ZUN_DBPASS=.*\$|ZUN_DBPASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^REDIS_PASS=.*\$|REDIS_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    sed -i "s|^REGISTRY_PASS=.*\$|REGISTRY_PASS=$(mktemp -u XXXXXXXXXXXX)|" $params
    
    echo 'creating yum repo'
    (cd packages/yum; createrepo .)
    
    echo 'making tar ball'
    pkgname=cpcloud-$ver.tgz
    tar cfz "$pkgname" * --xform 's|^|cpcloud-installer/|' --exclude src \
      --exclude build.sh --exclude "cpcloud*.tgz"
    
    /bin/mv /tmp/params.example.bk params.example

    if [ -d $packages ]; then
        test ! -e $commit_dir || /bin/rm -fr $commit_dir
        mkdir -p $commit_dir
        /bin/mv $pkgname $commit_dir
    fi
}


if ! ls $commit_dir/* &>/dev/null; then
    if [ -n "$CI_COMMIT_TAG" ]; then
        echo "$commit is not built"
        exit 1
    fi
    do_build
else
    echo "$commit already built"
fi


if [ -d $commit_dir ]; then
    cd $commit_dir
    pkgname=$(ls cpcloud*.tgz)

    CLOUD_URL='http://172.29.100.244/remote.php/webdav/'
    MODULE_NAME=cpcloud/installer

    if [ -n "$CI_COMMIT_TAG" ]; then
        tag_dir=$final_dir/tags
        test -e $tag_dir || mkdir -p $tag_dir
        dst_pkgname=cpcloud-$CI_COMMIT_TAG.tgz
        dst_path=$tag_dir/$dst_pkgname
        /bin/cp -l $commit_dir/$pkgname $dst_path
        echo "Final package: $dst_path"
        #curl --user ${CLOUD_USER}:${CLOUD_PASS} -X PUT "${CLOUD_URL}${MODULE_NAME}/${dst_pkgname}" --data-binary @"$commit_dir/$pkgname"
        #echo "upload ok"
    elif [ -n "$CI_COMMIT_REF_NAME" ]; then
        br_dir=$final_dir/$CI_COMMIT_REF_NAME
        test -e $br_dir || mkdir -p $br_dir
        /bin/cp -lf $commit_dir/$pkgname $br_dir
        echo "Final package: $br_dir/$pkgname"
        #if [[ "$CI_COMMIT_REF_NAME" == master ]] || [[ "$CI_COMMIT_REF_NAME" =~ ^br_ ]]; then
        #    curl --user ${CLOUD_USER}:${CLOUD_PASS} -X PUT "${CLOUD_URL}${MODULE_NAME}/$CI_COMMIT_REF_NAME/${pkgname}" --data-binary @"$commit_dir/$pkgname"
        #    echo "upload ok"
        #fi
    fi
fi
