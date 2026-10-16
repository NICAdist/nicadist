#!/bin/bash

# Script to initialize Unified Development/Use Environment for MPDRoot
#######################################################################################################################
################################################ Functionality ########################################################
###                                                                                                                 ###
###                                                                                                                 ###
###  1. Detects OS version, to choose appropriate method to install toolbox                                         ###
###                                                                                                                 ###
###     Tested/supported OS:                                                                                        ###
###      a) Red Hat based: Fedora, CentOS 8, AlmaLinux                                                              ###
###      b) Debian based : Debian 11, 12, Ubuntu 24.04, 22.04, 20.04                                                ###
###      c) Arch based : Manjaro 21.2                                                                               ###
###                                                                                                                 ###
###                                                                                                                 ###
###  2. If you have different distribution which is based on any of the of the supported from above, you can        ###
###     select appropriate installation method by passing distribution name (-d) and version (-v)                   ###
###                                                                                                                 ###
###     Example:                                                                                                    ###
###                                                                                                                 ###
###     nica-init.sh -d Ubuntu -v 20.04                                                                             ###
###                                                                                                                 ###
###     will attempt to install using the method for Ubuntu 20.04                                                   ###
###     (tested to work with Mint 20.2, Pop!_os 20.04 LTS)                                                          ###
###                                                                                                                 ###
###                                                                                                                 ###
###  3. Installs cvmfs, then starts cvmfs service and enables autostart cvmfs service on boot.                      ###
###                                                                                                                 ###
###     If you do not want to enable start cvmfs service on boot:                                                   ###
###                                                                                                                 ###
###     nica-init.sh -a no                                                                                          ###
###                                                                                                                 ###
###     NOTE (Advanced users): nica-init.sh -c no                                                                   ###
###                            disables cvmfs installation                                                          ###
###                                                                                                                 ###
###  4. Creates toolbox container                                                                                   ###
###                                                                                                                 ###
###                                                                                                                 ###
###  5. Writes out the installation summary (success) & short how to                                                ###
###                                                                                                                 ###
###                                                                                                                 ###
###  UNINSTALLATION: ./nica-init.sh uninstall                                                                       ###
###                                                                                                                 ###
#######################################################################################################################

main () {

 # exit when any command fails
 set -e

 AUTOSTART_CVMFS=yes
 TOOLBOX_OS_VER="a9"

 ######################
 ### uninstallation ###
 ######################
 # remove cvmfs, remove toolbox image & exit
 if [[ "$1" == "uninstall" ]]; then
  remove_all
  exit 0
 fi

 ######################
 ###  installation  ###
 ######################
 identify_os

 # overwrite default input parameters if passed into the script
 while getopts d:v:c:a:t: flag
 do
    case "${flag}" in
         d) OS=${OPTARG};;
         v) OS_VERSION=${OPTARG};;
         c) INSTALL_CVMFS=${OPTARG};;
         a) AUTOSTART_CVMFS=${OPTARG};;
         t) TOOLBOX_OS_VER=${OPTARG};;
    esac
 done

 install_toolbox

 # create toolbox container 
  podman pull registry.gitlab.com/ndmspc/user/${TOOLBOX_OS_VER}:alibuild-dev
  toolbox create -c ${TOOLBOX_OS_VER}-nica-dev -i registry.gitlab.com/ndmspc/user/${TOOLBOX_OS_VER}:alibuild-dev -y
 
 if [[ $INSTALL_CVMFS != no ]]; then
  get_cvmfs_script
  install_cvmfs
  # start cvmfs now and choose whether to enable autostart
  [[ $AUTOSTART_CVMFS == no ]] && sudo systemctl start cvmfs || sudo systemctl enable --now cvmfs
 fi

 # write out init summary & short how to
 generate_summary

}


function identify_os() {

 OS=$(cat /etc/os-release | grep NAME= | head -n 1 | cut -d '=' -f2 | tr -d '"' | cut -d ' ' -f1)
 OS_VERSION=$(cat /etc/os-release | grep VERSION_ID= | head -n 1 | cut -d '=' -f2 | tr -d '"')
 OS_VARIANT_ID=$(cat /etc/os-release | grep VARIANT_ID= | head -n 1 | cut -d '=' -f2 | tr -d '"')

}


function install_toolbox() {

 case $OS in

  Fedora | AlmaLinux)
   if [ "$OS_VARIANT_ID" = "silverblue" ];then
    echo "Toolbox installed by default on Fedora Silverblue"
   else
    echo "Installing toolbox on $OS $OS_VERSION"
    sudo dnf install toolbox -y
   fi
  ;;

  CentOS)
    echo "Installing toolbox on CentOS $OS_VERSION"
    sudo dnf install toolbox -y
  ;;

  Ubuntu)
   echo "Installing toolbox on Ubuntu $OS_VERSION"
   sudo apt install curl -y && . /etc/os-release
   if [ "$OS_VERSION" = "20.04" ];then
    install_suse_podman_package
    install_debian_toolbox_package
   elif [ "$OS_VERSION" = "24.04" ];then
    sudo apt-get --allow-downgrades install podman-toolbox=0.0.99.3+git20230118+446d7bfdef6a-2 -y
   else
    sudo apt --allow-downgrades --allow-change-held-packages install podman flatpak curl -y -qq
    install_debian_toolbox_package
   fi
  ;;

  Debian)
   echo "Installing toolbox on Debian $OS_VERSION"
   sudo apt install podman flatpak curl -y
   install_debian_toolbox_package
  ;;

  Manjaro)
   echo "Installing toolbox on Manjaro Linux"
   sudo pacman -S --noconfirm toolbox
   sudo sh -c 'echo "'$USER':100000:65536" >> /etc/subuid'
   sudo sh -c 'echo "'$USER':100000:65536" >> /etc/subgid'
  ;;

   *)
    generate_unsupported_message
    exit 1
   ;;
 esac

}

function install_suse_podman_package() {

  sudo sh -c "echo 'deb http://download.opensuse.org/repositories/devel:/kubic:/libcontainers:/stable/xUbuntu_${OS_VERSION}/ /' > /etc/apt/sources.list.d/devel:kubic:libcontainers:stable.list"
  wget -nv https://download.opensuse.org/repositories/devel:kubic:libcontainers:stable/xUbuntu_${OS_VERSION}/Release.key -O- | sudo apt-key add -
  sudo apt-get update -qq && sudo apt-get -qq -y install podman flatpak

}

function install_debian_toolbox_package() {

   rm -f ./podman-toolbox.deb
   wget -O podman-toolbox.deb http://old.kali.org/kali/pool/main/g/golang-github-containers-toolbox/podman-toolbox_0.0.99.2-2_amd64.deb
   sudo apt install ./podman-toolbox.deb -y -qq
   rm -f ./podman-toolbox.deb

}

function generate_unsupported_message() {
  
  if [[ "$OS" != "Gentoo" ]]; then
    echo
    echo " YOUR LINUX DISTRIBUTION MIGHT BE UNSUPPORTED BY THIS SCRIPT."
    echo
    echo " If your Linux distribution is based on any of the supported OS,"
    echo " then run the script according to the following example:"
    echo
    echo "     nica-init.sh -d Ubuntu -v 20.04    "
    echo
    echo " In this case, your Linux distribution would be based on Ubuntu 21.10. (Example: pop!_OS 21.10)"
    echo " Otherwise create a new issue at https://git.jinr.ru/nica/nicadist/-/issues"
    echo " and request to support your distribution."
    echo
  else
    echo 
    echo " You are using Gentoo Linux."
    echo
    echo " Please visit https://git.jinr.ru/nica/nicadist/-/issues/41 and follow the instructions."
    echo 
  fi

}

function get_cvmfs_script() {

 rm -f ./cvmfs_install
 wget -O cvmfs_install https://github.com/NICAdist/nicadist/-/raw/master/scripts/cvmfs_install
 chmod +x cvmfs_install

}

function install_cvmfs() {

 sudo CVMFS_DEFAULT_CONFIG=default.local ./cvmfs_install

}

function generate_summary() {

 echo "================================================"
 echo
 echo "INSTALLATION SUCCESSFUL"
 echo
 echo "How to use:"
 echo
 COUNTER=1
 if [[ $AUTOSTART_CVMFS = no ]]; then
  echo "1. Start cvmfs service by:"
  echo "   sudo systemctl start cvmfs"
  echo "   (to enable autostart at boot - run once and forget: sudo systemctl enable cvmfs"
  let COUNTER++
  echo
 fi
 echo "$((COUNTER++)). Enter toolbox container by:"
 echo "   toolbox enter ${TOOLBOX_OS_VER}-nica-dev"
 echo
 MACHINE="toolbox"
 echo "$COUNTER. Load MPDRoot environment as a user by:"
 echo "   [user@$MACHINE ]$ module add mpdroot"
 echo
 echo "   or MPDRoot environment as a developer by:"
 echo "   [user@$MACHINE ]$ module add mpddev"
 echo
 if [[ $INSTALL_CVMFS == no ]]; then
  echo "   WARNING:"
  echo "    You chose not to install CVMFS."
  echo "    You must use aliBuild to build MPDRoot "
  echo "    with its dependencies on your local machine."
 fi
 echo
 echo "================================================"

}

function remove_all() {

 echo -e "\n\033[32mRemoving cvmfs if it exists on your local machine...\033[0m\n"
 get_cvmfs_script
 sudo ./cvmfs_install clean
 sudo rm -f /etc/cvmfs/default.local
 echo -e  "\n\033[32mRemoving ${TOOLBOX_OS_VER}-nica-dev toolbox container if it exists on your machine...\033[0m\n"
 toolbox rm ${TOOLBOX_OS_VER}-nica-dev
 echo -e  "\n\033[32mRemoving ${TOOLBOX_OS_VER}:alibuild-dev toolbox image if it exists on your machine...\033[0m\n"
 toolbox rmi ${TOOLBOX_OS_VER}:alibuild-dev
 echo -e "\n\033[31m WARNING: If you got Error message that container c7-nica-dev is running"
 echo -e "          THEN YOUR UNINSTALL WAS NOT SUCCESSFUL !!"
 echo -e "          You must reboot first and run uninstall again.\033[0m\n"
 if [[ "$OS" == "Ubuntu" || "$OS" == "Debian" ]]; then
  echo
  echo -e "\033[91mDebian/Ubuntu toolbox & podman packages are then removed by:\033[0m\n"
  echo -e "\033[91msudo apt remove podman-toolbox podman\033[0m\n"
  echo 
 fi

}


main "$@"

