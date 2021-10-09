#!/bin/bash
# 打包 openstack queens版本 源码包 为RPM包


set -o xtrace
set -e

code_path=$PWD
code_name=$(basename $code_path)
if [ -n "$1" ]; then
    code_name=$1
fi

dist_rpm_path="/home/gitlab-runner/packages"
src_rpm_path="$(dirname $BASH_SOURCE)/src_rpms"

base_url="http://vault.centos.org/centos/7/cloud/Source/openstack-queens/"


function init_env(){
    echo "nameserver    114.114.114.114" > /etc/resolv.conf

    if [ ! -d $dist_rpm_path ]; then
        mkdir -p $dist_rpm_path
    fi

    rm -rf /etc/yum.repos.d/*
    curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
    curl -o /etc/yum.repos.d/epel-7.repo https://mirrors.aliyun.com/repo/epel-7.repo
    yum clean all
    yum makecache

    yum install -y vim wget python-pip rpm-build git
    yum install -y centos-release-openstack-queens
    groupadd mockbuild
    useradd mockbuild -g mockbuild
    export LC_ALL=en_US.UTF-8

    yum install -y python-pygments
    pip install pygments-json

}

function clean(){
    rm -rf ~/rpmbuild
}

function repack(){
    echo "Packaging: $code_name ..."
    local code_name=$1
    local version_name=$2
    local tar_name="$version_name.tar.gz"
    local src_rpm_name=$3

    commit=$(git log --format="%H" -n1)
    dist_rpm_subdir=$dist_rpm_path/$code_name/$commit

    if [ ! -f $src_rpm_path/$src_rpm_name ]; then
        curl -o $src_rpm_path/$src_rpm_name $base_url/$src_rpm_name
    fi

    rm -rf ~/rpmbuild
    rpm -Uvh $src_rpm_path/$src_rpm_name

    cd ..
    cp -r $code_name $version_name
    tar czf ~/rpmbuild/SOURCES/$tar_name $version_name --exclude ".git" 
    rm -rf $version_name

    if [ -f $code_path/*.spec ]; then
        spec=$code_path/*.spec
    else
        spec=~/rpmbuild/SPECS/*.spec
    fi
    sed -i 's/^find.*gitignore.*/#&/' $spec

    cd ~/rpmbuild

    if ! rpmbuild --clean -bb $spec 2>&1 | tee build.log; then
        if grep -q "needed" build.log; then
            grep "needed" build.log | awk '{print $1}' | xargs -r yum install -y
            if rpmbuild --clean -bb $spec 2>&1 | tee build.log; then
                build_ok=true
            else
                build_ok=false
            fi
        else
            build_ok=false
        fi
    else
        build_ok=true
    fi

    if $build_ok; then
        n=$(find RPMS -name "*.rpm" | wc -l)
        if [ "$n" = 0 ]; then
            echo "no package found"
            return 1
        fi
        test -e $dist_rpm_subdir || /bin/rm -fr $dist_rpm_subdir
        mkdir -p $dist_rpm_subdir
        find RPMS -name "*.rpm" | xargs -i /bin/cp {} $dist_rpm_subdir
        echo "Done with package: $code_name"
        return 0
    else
        return 1
    fi
}

if test -z "$code_name"; then
    echo "Usage: $0 <init|clean|nova|novaclient|neutron|neutronclient|cinder|cinderclient|glance|glanceclient>"
    exit 1
fi

case $code_name in
    init)
        init_env
        ;;
    clean)
        clean
        ;;
    nova)
        repack "nova" "nova-17.0.4" "openstack-nova-17.0.4-1.el7.src.rpm"
        ;;
    python-novaclient)
        repack "python-novaclient" "python-novaclient-9.1.1" "python-novaclient-9.1.1-1.el7.src.rpm"
        ;;
    neutron)
        repack "neutron" "neutron-12.0.2" "openstack-neutron-12.0.2-1.el7.src.rpm"
        ;;
    python-neutronclient)
        repack "python-neutronclient" "python-neutronclient-6.7.0" "python-neutronclient-6.7.0-1.el7.src.rpm"
        ;;
    neutron-lib)
        repack "neutron-lib" "neutron-lib-1.13.0" "python-neutron-lib-1.13.0-1.el7.src.rpm"
        ;;
    cinder)
        repack "cinder" "cinder-12.0.3" "openstack-cinder-12.0.3-1.el7.src.rpm"
        ;;
    python-cinderclient)
        repack "python-cinderclient" "python-cinderclient-3.5.0" "python-cinderclient-3.5.0-1.el7.src.rpm"
        ;;
    glance)
        repack "glance" "glance-16.0.1" "openstack-glance-16.0.1-1.el7.src.rpm"
        ;;
    python-glanceclient)
        repack "python-glanceclient" "python-glanceclient-2.10.0" "python-glanceclient-2.10.0-1.el7.src.rpm"
        ;;
    keystonemiddleware)
        repack "keystonemiddleware" "keystonemiddleware-4.21.0" "python-keystonemiddleware-4.21.0-1.el7.src.rpm"
        ;;
    keystoneauth1)
        repack "keystoneauth1" "keystoneauth1-3.4.1" "python-keystoneauth1-3.4.1-1.el7.src.rpm"
        ;;
    *)
        echo "Unsupported module: $module"
        exit 1
        ;;
esac
