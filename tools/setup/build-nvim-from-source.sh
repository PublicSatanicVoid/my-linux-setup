#!/bin/bash

# Lua: 5.4.6
# CMake: 3.28.0
# GCC: 14.1.0
# Binutils: 2.41
#
# Set $CC, $CXX, $LD appropriately

export CPPFLAGS="-D_GNU_SOURCE"
export CFLAGS="-O2 -pipe $CPPFLAGS"
export CXXFLAGS="$CFLAGS"
export LDFLAGS=""
export PATH="/sbin:/bin"

unset LD_LIBRARY_PATH
export -f LD_LIBRARY_PATH

usage() {
	echo "Usage: $0 -t <target dir> [-c] [-g] [-d] [-s] [-v]" 1>&2
	echo "Flags:"
	echo "  -c      clean build"
	echo "  -g      also do git clean"
	echo "  -d      dry run only"
    echo "  -s      build single-threaded"
    echo "  -v      build with verbose output"
	exit 1
}

TARGET=""
CLEAN=0
GITCLEAN=0
DRYRUN=0
SINGLETHREAD=0
VERBOSE=0

while getopts "t:cgdsv" o; do
	case "$o" in
		t) TARGET="$(readlink -f "$OPTARG")";;
		c) CLEAN=1;;
		g) GITCLEAN=1;;
		d) DRYRUN=1;;
        s) SINGLETHREAD=1;;
        v) VERBOSE=1;;
		*) usage;;
	esac
done

if [ -z "$TARGET" ]; then
	usage
fi

echo "Options:"
echo "  Target:         $TARGET"
echo "  Clean:          $CLEAN"
echo "  Git clean:      $GITCLEAN"
echo "  Singlethreaded: $SINGLETHREAD"
echo "  Verbose:        $VERBOSE"

echo "Tool versions:"
echo "  GCC:   $(which gcc) -- $(gcc --version | head -n1)"
echo "  LD:    $(which ld) -- $(ld --version | head -n1)"
echo "  CMake: $(which cmake)  -- $(cmake --version | head -n1)"
echo "  Lua:   $(which lua) -- $(lua -v | awk '{print $2}')"

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


make_opts=""
cmake_opts="-DCMAKE_BUILD_TYPE=Release" 
if [ $VERBOSE -eq 1 ]; then
    make_opts+=" VERBOSE=1"
fi
if [ $SINGLETHREAD -eq 0 ]; then
    make_opts+=" -j"
fi
if [ $CLEAN -eq 1 ]; then
    cmake_opts+=" --fresh"
fi

sh -xc "cmake -S cmake.deps -B .deps $cmake_opts" \
 && sh -xc "cd .deps; make $make_opts" \
 && sh -xc "cmake -S . -B build $cmake_opts -DCMAKE_INSTALL_PREFIX=$TARGET" \
 && sh -xc "cd build; make $make_opts" \
 && sh -xc "cd build; make $make_opts install"

exit $?
