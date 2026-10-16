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
  # We switch to github.com repositories since git.jinr.ru may be unreachable
  autotools:
    source: https://github.com/NICAdist/autotools.git
  Boost:
    source: https://github.com/NICAdist/boost.git
  Cuba:
    source: https://github.com/NICAdist/cuba.git
  FastJet:
    source: https://github.com/NICAdist/FastJet.git
  FFTW:
    source: https://github.com/NICAdist/FFTW.git
  GCC-ToolChain:
    source: https://github.com/NICAdist/GCC-ToolChain.git
  giflib:
    source: https://github.com/NICAdist/giflib.git
  GSL:
    source: https://github.com/NICAdist/GSL.git
  HepPDT:
    source: https://github.com/NICAdist/HepPDT.git
  libtirpc:
    source: https://github.com/NICAdist/libtirpc.git
  Pythia8JAM2:
    source: https://github.com/NICAdist/Pythia8JAM2.git
  SMASH-pack:
    source: https://github.com/NICAdist/SMASH-pack.git
  vHLLE:
    source: https://github.com/NICAdist/vhlle.git
  XGBoost:
    source: https://github.com/NICAdist/XGBoost.git
---
