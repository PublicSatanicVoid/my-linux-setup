#!/bin/bash

# Builds Mosh on a standard CENT7 machine with root access, and generates a
# portable distribution that should run on other CENT7 machines (without root access,
# and potentially different installed or missing library versions)

MOSH_VERSION="1.4.0"
MOSH_SRC_URL="https://mosh.org/mosh-${MOSH_VERSION}.tar.gz"

LINUXDEPLOY_EXE="linuxdeploy-x86_64.AppImage"
LINUXDEPLOY_EXE_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/1-alpha-20240109-1/${LINUXDEPLOY_EXE}"

DIST_FILENAME="mosh-dist"
BUILD_LOG="mosh-build.log"


function check_code {
    if [ $1 -ne 0 ]; then
        echo "--------------------------------------------------------------"
        echo "FAILURE ($1) : $2"
        echo "See log file ${BUILD_LOG} for more details."
        echo "--------------------------------------------------------------"
        exit 1
    fi
}



if [ "$1" != "--internal" ]; then
    "$0" --internal 2>&1 | tee "${BUILD_LOG}"
else
    echo "Installing dependencies..."
    echo

    sudo yum install -y protobuf-compiler protobuf-static protobuf protobuf-c protobuf-c-devel protobuf-c-compiler protobuf-devel

    sudo yum install -y ncurses ncurses-devel ncurses-libs ncurses-static ncurses-base

    sudo yum install -y fuse fuse-devel fuse-libs


    BASE="$(pwd)"

    mkdir build
    pushd build
    BUILD_BASE="$(pwd)"


    echo "Downloading and building Mosh..."

    wget "$MOSH_SRC_URL"
    check_code $? wget

    tar -xf "mosh-${MOSH_VERSION}.tar.gz"
    check_code $? untar

    pushd "mosh-${MOSH_VERSION}"

    mkdir target

    ./configure --prefix="$(pwd)/target"
    check_code $? configure

    make -j
    check_code $? make

    make install
    check_code $? install

    popd


    echo "Downloading linuxdeploy..."

    wget "${LINUXDEPLOY_EXE_URL}"
    check_code $? wget

    chmod +x "${LINUXDEPLOY_EXE}"
    check_code $? chmod


    echo "Creating standalone distribution of mosh..."

    "./${LINUXDEPLOY_EXE}" \
        --appdir="${DIST_FILENAME}" \
        --executable="${BUILD_BASE}/mosh-1.4.0/target/bin/mosh-server" \
        --executable="${BUILD_BASE}/mosh-1.4.0/target/bin/mosh-client"
    check_code $? linuxdeploy

    chmod -R a-w "${DIST_FILENAME}"

    tar -cJf "${DIST_FILENAME}.tar.xz" "${DIST_FILENAME}"
    check_code $? tar

    popd
    mv build/"${DIST_FILENAME}.tar.xz" .
    check_code $? mv

    echo "Build files are in 'build' folder"
    echo "Portable distribution is at: ${DIST_FILENAME}.tar.xz"

fi

