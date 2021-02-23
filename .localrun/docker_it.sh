#! /bin/bash

_HOME2_=$(dirname $0)
export _HOME2_
_HOME_=$(cd $_HOME2_;pwd)
export _HOME_

echo $_HOME_
cd $_HOME_


build_for='
ubuntu:18.04
'

for system_to_build_for in $build_for ; do

    system_to_build_for_orig="$system_to_build_for"
    system_to_build_for=$(echo "$system_to_build_for_orig" 2>/dev/null|tr ':' '_' 2>/dev/null)

    cd $_HOME_/
    mkdir -p $_HOME_/"$system_to_build_for"/

    # rm -Rf $_HOME_/"$system_to_build_for"/script 2>/dev/null
    # rm -Rf $_HOME_/"$system_to_build_for"/workspace 2>/dev/null

    mkdir -p $_HOME_/"$system_to_build_for"/artefacts
    mkdir -p $_HOME_/"$system_to_build_for"/script
    mkdir -p $_HOME_/"$system_to_build_for"/workspace

    ls -al $_HOME_/"$system_to_build_for"/

    rsync -a ../ --exclude=.localrun $_HOME_/"$system_to_build_for"/workspace/data
    chmod a+rwx -R $_HOME_/"$system_to_build_for"/workspace/data

    echo '#! /bin/bash


pkgs_Ubuntu_18_04="
    :u:
    sudo
    ca-certificates
    shtool
    elfutils
    patch
    bzip2
    vim
    devscripts
    debhelper
    libconfig-dev
    cmake
    wget
    unzip
    zip
    automake
    autotools-dev
    build-essential
    check
    checkinstall
    libtool
    pkg-config
    rsync
    git
    libx11-dev
    libasound2-dev
    libopenal-dev
    alsa-utils
    libv4l-dev
    v4l-conf
    v4l-utils
    libjpeg8-dev
    libavcodec-dev
    libavdevice-dev
    libsodium-dev
    libvpx-dev
    libopus-dev
    libx264-dev
    libcurl4-gnutls-dev
    openjdk-8-jdk
    lib32stdc++6
    lib32z1
    ant
    ant-optional
    faketime
    tcl
    autoconf
    gawk
    libssl-dev
    make
    libqt5widgets5
"


pkgs_Ubuntu_20_04="$pkgs_Ubuntu_18_04"
pkgs_DebianGNU_Linux_9="$pkgs_Ubuntu_18_04"
pkgs_DebianGNU_Linux_10="$pkgs_Ubuntu_18_04"

export DEBIAN_FRONTEND=noninteractive


os_release=$(cat /etc/os-release 2>/dev/null|grep "PRETTY_NAME=" 2>/dev/null|cut -d"=" -f2)
echo "using /etc/os-release"
system__=$(cat /etc/os-release 2>/dev/null|grep "^NAME=" 2>/dev/null|cut -d"=" -f2|tr -d "\""|sed -e "s#\s##g")
version__=$(cat /etc/os-release 2>/dev/null|grep "^VERSION_ID=" 2>/dev/null|cut -d"=" -f2|tr -d "\""|sed -e "s#\s##g")

echo "compiling on: $system__ $version__"

pkgs_name="pkgs_"$(echo "$system__"|tr "." "_"|tr "/" "_")"_"$(echo $version__|tr "." "_"|tr "/" "_")
echo "PKG:-->""$pkgs_name""<--"

for i in ${!pkgs_name} ; do
    if [[ ${i:0:3} == ":u:" ]]; then
        echo "apt-get update"
        apt-get update > /dev/null 2>&1
    elif [[ ${i:0:3} == ":c:" ]]; then
        cmd=$(echo "${i:3}"|sed -e "s#\\\s# #g")
        echo "$cmd"
        $cmd > /dev/null 2>&1
    else
        echo "apt-get install -y --force-yes ""$i"
        apt-get install -qq -y --force-yes $i > /dev/null 2>&1
    fi
done

#------------------------


cd /workspace/data/

ls -al
id -a
pwd


export ANDROID_BUILD_TOOLS="25.0.2"
export NDK_VERSION="17c"
export WGET="wget --quiet --tries=0"
export ANDROID_HOME=$PWD/android-sdk-linux

rm -rf $ANDROID_HOME android-sdk.tgz

$WGET --output-document=android-sdk.tgz https://dl.google.com/android/repository/tools_r25.2.5-linux.zip
unzip -qq -d $ANDROID_HOME android-sdk.tgz

mkdir -p $ANDROID_HOME/licenses || true
echo 8933bad161af4178b1185d1a37fbf41ea5269c55 > $ANDROID_HOME/licenses/android-sdk-license
echo 79120722343a6f314e0719f863036c702b0e6b2a > $ANDROID_HOME/licenses/android-sdk-preview-license
echo 84831b9409646a918e30573bab4c9c91346d8abd > $ANDROID_HOME/licenses/android-sdk-preview-license-d099d938
echo y | $ANDROID_HOME/tools/android --silent update sdk --no-ui --all --filter android-14,android-29,platform-tools,extra-android-m2repository,build-tools-${ANDROID_BUILD_TOOLS}

export PATH=$PATH:${ANDROID_HOME}/platform-tools:${ANDROID_HOME}/tools

rm -rf $PWD/android-ndk*  android-ndk.zip
$WGET --output-document=android-ndk.zip https://dl.google.com/android/repository/android-ndk-r${NDK_VERSION}-linux-x86_64.zip
unzip -qq android-ndk.zip

export ANDROID_NDK_HOME=$PWD/android-ndk-r${NDK_VERSION}

git submodule foreach --recursive git reset --hard
git submodule foreach --recursive git clean -fdx
git submodule sync --recursive
git submodule foreach --recursive git submodule sync
git submodule update --init --recursive

projectroot=`pwd`
# standardize timezone to reduce build differences
export TZ=UTC
TIMESTAMP=`printf "%(%Y-%m-%d %H:%M:%S)T" \
    $(git log -n1 --format=format:%at)`

faketime -f "$TIMESTAMP" make -C external/
faketime -f "$TIMESTAMP" $ANDROID_NDK_HOME/ndk-build

./gradlew clean assemble

ls -hal /workspace/data/build/outputs/aar/data-debug.aar
ls -hal /workspace/data/build/outputs/aar/data-release.aar

cp -av /workspace/data/build/outputs/aar/data-debug.aar /artefacts/
cp -av /workspace/data/build/outputs/aar/data-release.aar /artefacts/

#------------------------

# Chmod since everything is root:root
chmod 755 -R /artefacts/

#------------------------


' > $_HOME_/"$system_to_build_for"/script/run.sh

    docker run -ti --rm \
      -v $_HOME_/"$system_to_build_for"/artefacts:/artefacts \
      -v $_HOME_/"$system_to_build_for"/script:/script \
      -v $_HOME_/"$system_to_build_for"/workspace:/workspace \
      --net=host \
     "$system_to_build_for_orig" \
     /bin/sh -c "apk add bash >/dev/null 2>/dev/null; /bin/bash /script/run.sh"
     if [ $? -ne 0 ]; then
        echo "** ERROR **:$system_to_build_for_orig"
        exit 1
     else
        echo "--SUCCESS--:$system_to_build_for_orig"
     fi

done

