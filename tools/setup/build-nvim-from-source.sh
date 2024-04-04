#!/bin/bash

# Cmake: 3.26.3
# GCC: 13.1.0
# Binutils: 2.41
# Set CC, CXX to correct location
# Ensure they match PATH gcc/g++

usage() {
	echo "Usage: $0 -t <target dir> [-c] [-g] [-d]" 1>&2
	echo "Flags:"
	echo "  -c      clean build"
	echo "  -g      also do git clean"
	echo "  -d      dry run only"
	exit 1
}

TARGET=""
CLEAN=0
GITCLEAN=0
DRYRUN=0

while getopts "t:cgd" o; do
	case "$o" in
		t)
			TARGET="$(readlink -f "$OPTARG")"
			;;
		c)
			CLEAN=1
			;;
		g)
			GITCLEAN=1
			;;
		d)
			DRYRUN=1
			;;
		*)
			usage
			;;
	esac
done

if [ -z "$TARGET" ]; then
	usage
fi

echo "Options:"
echo "  Target:    $TARGET"
echo "  Clean:     $CLEAN"
echo "  Git clean: $GITCLEAN"

echo "Tool versions:"
echo "  GCC: $(which gcc) -- $(gcc --version | head -n1)"
echo "  LD: $(which ld) -- $(ld --version | head -n1)"
echo "  CMake: $(which cmake)  -- $(cmake --version | head -n1)"

if [ $DRYRUN -eq 1 ]; then
	echo "Exiting now due to -d (dry run) flag"
	exit
fi

if [ $CLEAN -eq 1 ]; then
	echo "Cleaning build dir"
	rm -rf build

	if [ $GITCLEAN -eq 1 ]; then
		git clean -xdf .
		git reset --hard
	fi

	make clean
fi


make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$TARGET" -j \
&& make CMAKE_BUILD_TYPE=Release CMAKE_INSTALL_PREFIX="$TARGET" -j install
exit $?
