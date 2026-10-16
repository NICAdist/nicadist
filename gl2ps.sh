package: gl2ps
version: v1.4.1
tag: 5a9eeb15eb0cfe8493a0c78c3dd96df30a539f04
source: https://github.com/Open-Cascade-SAS/gl2ps.git
requires:
  - freeglut
  - libpng
  - zlib
build_requires:
  - CMake
  - ninja
---
#!/bin/bash -e
rsync -a --exclude '**/.git' $SOURCEDIR/ .

# bump minimal required version of CMake (to supress < 3.5 warning)
sed -i 's@VERSION 2.8 FATAL_ERROR@VERSION 3.15 FATAL_ERROR@g' CMakeLists.txt
# make search for LATEX silent
sed -i 's@find_package(LATEX)@find_package(LATEX QUIET)@g' CMakeLists.txt
# fix for case when EMF is not built (and defined)
sed -i 's@  fp = (format != GL2PS_EMF)@#ifdef GL2PS_EMF\n  fp = (format != GL2PS_EMF)@g' gl2psTest.c
sed -i 's@  printf(\"Saving image to file \%s... \", file);@#else\n  fp = fopen(file, \"wb\");\
  if(!fp){\n    printf(\"Unable to open file \%s for writing\\n\", file);\n    exit(1);\n    }\
#endif\n  printf(\"Saving image to file \%s... \", file);@g' gl2psTest.c
sed -i 's@    else if(format == GL2PS_PGF) format = GL2PS_EMF;@#ifdef GL2PS_EMF\n    else if(format == GL2PS_PGF) format = GL2PS_EMF;\n#endif@g' gl2psTest.c

cmake "$BUILDDIR"                                                         \
      -DCMAKE_INSTALL_PREFIX="$INSTALLROOT"                               \
      ${CMAKE_BUILD_TYPE:+-DCMAKE_BUILD_TYPE=$CMAKE_BUILD_TYPE}           \
      ${CXXFLAGS:+-DCMAKE_CXX_FLAGS="$CXXFLAGS"}                          \
      ${CXXSTD:+-DCMAKE_CXX_STANDARD=$CXXSTD}                             \
      -DCMAKE_COLOR_DIAGNOSTICS=ON                                        \
      -G Ninja                                                            \
      -DENABLE_LIBEMF=OFF                                                 \
      ${FREEGLUT_ROOT:+-DGLUT_INCLUDE_DIR=$FREEGLUT_ROOT/include}         \
      ${FREEGLUT_ROOT:+-DGLUT_glut_LIBRARY=$FREEGLUT_ROOT/lib/libglut.so} \
      ${LIBPNG_ROOT:+-DPNG_ROOT=$LIBPNG_ROOT}                             \

cmake --build . -- ${JOBS+-j $JOBS} install

# Modulefile
MODULEDIR="$INSTALLROOT/etc/modulefiles"
MODULEFILE="$MODULEDIR/$PKGNAME"
mkdir -p "$MODULEDIR"

generate-module --project=NICA --lib > $MODULEFILE

cat >> "$MODULEFILE" << EoF
prepend-path PKG_CONFIG_PATH \$PKG_ROOT/lib/pkgconfig
prepend-path ROOT_INCLUDE_PATH \$PKG_ROOT/include
EoF

mkdir -p "$INSTALLROOT/lib/pkgconfig"
cat > "$INSTALLROOT/lib/pkgconfig/libgl2ps.pc" << EoF
prefix=$INSTALLROOT
exec_prefix=\${prefix}
libdir=$INSTALLROOT/lib
toolexeclibdir=\${libdir}
includedir=\${prefix}/include

Name: gl2ps
Description: gl2ps - an OpenGL to PostScript (and PDF, and SVG...) printing library
Version: 1.4.1
Libs: -L\${toolexeclibdir} -lgl2ps
Cflags: -I\${includedir}
EoF

nicadist-postbuild-hook
