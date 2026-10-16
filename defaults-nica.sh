default:
  - &MPDROOT_TAG v26.06.11
package: defaults-nica
version: v2027.01
env:
  CHECK_CONFIG_DIR: "${ALIBUILD_CONFIG_DIR:?\e[31mERROR: ALIBUILD_CONFIG_DIR is not set. Make sure you have at least aliBuild v1.17.19. Aborting!\e[0m}"
  PATH: "$ALIBUILD_CONFIG_DIR/scripts:$PATH"
  CFLAGS: -fPIC -O2
  CMAKE_BUILD_TYPE: RELWITHDEBINFO
  CXXFLAGS: -fPIC -O2 -std=c++20
  CXXSTD: '20'
  GEANT4_BUILD_MULTITHREADED: 'OFF'
  BUILD_RPM: 'OFF'
overrides:
  mpdroot:
    tag: *MPDROOT_TAG
    version: *MPDROOT_TAG
  mpddev:
    version: *MPDROOT_TAG
---
