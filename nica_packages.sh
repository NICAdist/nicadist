# metapackage for building all "root" NICA packages
package: nica_packages
version: v2024.06
requires:
  - ACTS
  - Boost
  - clang-format
  - CUDA
  - EMACS
  - emulzie
  - EnvironmentModules
  - FairRoot
  - mfddev
  - mpddev
  - mpdroot
  - mxpfit
  - ndmspc
  - NICA_scheduler
  - RapidYAML
  - ROOT
#  - libTorch
#  - JAM2
#  - TinyXML2
#  - Vc
#  - KFParticle
#  - PFSimple
#  - QnTools
---
## #!/bin/bash -e
## 
## # Modulefile
## MODULEDIR="$INSTALLROOT/etc/modulefiles"
## MODULEFILE="$MODULEDIR/$PKGNAME"
## mkdir -p "$MODULEDIR"
## 
## generate-module --project=NICA > $MODULEFILE
