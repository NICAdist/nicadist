package: DDS
version: v3.18.0
tag: "3.18"
source: https://github.com/FairRootGroup/DDS.git
requires:
  - Boost
  - protobuf
build_requires:
  - abseil-cpp
  - CMake
  - ninja
---
#!/bin/bash -e
export CLICOLOR_FORCE=1 # force color output
export CPPFLAGS="${CPPFLAGS} -fdiagnostics-color=always"
export NINJA_STATUS="[%p] " # nicer output of ninja (CMake-based builds)

[[ $GCC_TOOLCHAIN_ROOT ]] && export DDS_LD_LIBRARY_PATH="$GCC_TOOLCHAIN_ROOT/lib64"

sed -i 's@::${DDS_BOOST_LIB_DIR}@::$<TARGET_FILE_DIR:dds_tools_lib>::$<TARGET_FILE_DIR:dds_proto_lib>::${DDS_BOOST_LIB_DIR}@g' $SOURCEDIR/CMakeLists.txt

# Change calls to LOG to special hanlders in order to avoid clash
# with protobuf logger
sed -i 's@LOG(debug)@DBG@g' $SOURCEDIR/dds-commander/src/main.cpp
sed -i 's@LOG(error)@ERR@g' $SOURCEDIR/dds-commander/src/main.cpp
sed -i 's@LOG(fatal)@FAT@g' $SOURCEDIR/dds-commander/src/main.cpp
sed -i 's@LOG(info)@INF@g' $SOURCEDIR/dds-commander/src/main.cpp
sed -i 's@LOG(log_stderr)@STDERR@g' $SOURCEDIR/dds-commander/src/main.cpp
sed -i 's@LOG(log_stdout)@STDOUT@g' $SOURCEDIR/dds-commander/src/main.cpp
sed -i 's@LOG(warning)@WRN@g' $SOURCEDIR/dds-commander/src/main.cpp
sed -i 's@LOG(error)@ERR@g' $SOURCEDIR/dds-commander/src/UIChannelInfo.cpp
sed -i 's@LOG(fatal)@FAT@g' $SOURCEDIR/dds-commander/src/UIChannelInfo.cpp
sed -i 's@LOG(info)@INF@g' $SOURCEDIR/dds-commander/src/UIChannelInfo.cpp
sed -i 's@LOG(debug)@DBG@g' $SOURCEDIR/dds-commander/src/ConnectionManager.cpp
sed -i 's@LOG(error)@ERR@g' $SOURCEDIR/dds-commander/src/ConnectionManager.cpp
sed -i 's@LOG(info)@INF@g' $SOURCEDIR/dds-commander/src/ConnectionManager.cpp
sed -i 's@LOG(warning)@WRN@g' $SOURCEDIR/dds-commander/src/ConnectionManager.cpp

cmake "$SOURCEDIR"                                              \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                     \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE} \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                   \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                              \
      -G Ninja                                                  \
      -DCMAKE_INSTALL_LIBDIR=lib                                \
      ${BOOST_ROOT:+-DBOOST_ROOT=$BOOST_ROOT}                   \
      ${BOOST_ROOT:+-DDDS_BOOST_LIB_DIR="$BOOST_ROOT/lib"}      \
      ${PROTOBUF_ROOT:+-DProtobuf_ROOT="$PROTOBUF_ROOT"}

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --bin --lib > $MODULEFILE

DDSVER="$(basename $(find $INSTALLROOT/lib/cmake -type d -name 'DDS-*'))"

cat >> "$MODULEFILE" << EoF
setenv DDS_LOCATION \$PKG_ROOT
setenv DDS_DIR \$PKG_ROOT/lib/cmake/$DDSVER
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

nicadist-postbuild-hook
