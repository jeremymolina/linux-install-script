#!/bin/bash
# Default values of arguments
SHOULD_INITIALIZE=0
INSTALL_METHOD=""
INSTALL_DISTRO=""

#Function to install depending the distro | source | flatpak-repo
installpkg(){
  PACKAGE=$1
  SOURCE=$2
  REPO=$3
  LEVEL=$4
  
  echo "=> installing $PACKAGE distro $INSTALL_DISTRO via $INSTALL_METHOD $SOURCE";
  if [ "$PACKAGE" != "-" ]; then
	  if [ -z "$SOURCE" ] 
	  then
	  	if [ $INSTALL_DISTRO == "flat" ]; then flatpak install flathub $PACKAGE --noninteractive --user;
	  	elif [ $INSTALL_DISTRO == "ubuntu" ]; then sudo apt install $PACKAGE --yes
	  	elif [ $INSTALL_DISTRO == "solus" ]; then sudo eopkg install $PACKAGE --yes-all
	  	elif [ $INSTALL_DISTRO == "arch" ]; then yes | sudo pacman -S $PACKAGE;
	  	elif [ $INSTALL_DISTRO == "fedora" ]; then sudo dnf install $PACKAGE -y;
	  	fi
	  else
	  	if [ $SOURCE == "flatOnly" ]; then flatpak install $REPO $PACKAGE --noninteractive --$LEVEL;
	  	elif [ $SOURCE == "debOnly" ] && [ $INSTALL_DISTRO == "ubuntu" ]; then sudo apt install $PACKAGE --yes;
	  	elif [ $SOURCE == "solusOnly" ] && [ $INSTALL_DISTRO == "solus" ]; then sudo eopkg install $PACKAGE --yes;
	  	elif [ $SOURCE == "aurOnly" ] && [ $INSTALL_DISTRO == "arch" ]; then yay -S --noconfirm --nodiffmenu --mflags --skipinteg --needed $PACKAGE;
	  	elif [ $SOURCE == "archOnly" ] && [ $INSTALL_DISTRO == "arch" ]; then sudo pacman -S --noconfirm --needed $PACKAGE;
	  	elif [ $SOURCE == "dnfOnly" ] && [ $INSTALL_DISTRO == "fedora" ]; then sudo dnf install $PACKAGE -y;
	  	fi
	  fi
  else
  	echo "=> A package was skippet as it was set to: $PACKAGE"
  fi
}
installalt(){
  ALT1=$1 #flatpak
  ALT2=$2 #ubuntu/deb
  ALT3=$3 #solus/eopkg
  ALT4=$4 #arch/aur
  ALT5=$5 #fedora/dnf
  if [ "$INSTALL_DISTRO" == "flat" ]; then installpkg $ALT1;
  elif [ "$INSTALL_DISTRO" == "ubuntu" ]; then installpkg $ALT2;
  elif [ "$INSTALL_DISTRO" == "solus" ]; then installpkg $ALT3;
  elif [ "$INSTALL_DISTRO" == "arch" ]; then installpkg $ALT4;
  elif [ "$INSTALL_DISTRO" == "fedora" ]; then installpkg $ALT5;
  fi;
}

installapt(){
	sleep 3
	echo "=> add Edge PPA"
	## Setup
	curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg
	sudo install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/
	sudo sh -c 'echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge-dev.list'
	sudo rm microsoft.gpg
	
	sleep 3
	
	echo "=> add Signal PPA"
	wget -O- https://updates.signal.org/desktop/apt/keys.asc | sudo apt-key add -
	if [ ! -f /etc/apt/sources.list.d/signal-xenial.list ]; then
	echo "deb [arch=amd64] https://updates.signal.org/desktop/apt xenial main" | sudo tee -a /etc/apt/sources.list.d/signal-xenial.list
	fi
	
	sleep 3
	sudo apt-get install build-essential cmake git #dev-build essentials
	
}

installeopkg(){
	echo "=> add specil repo Solus"
	sudo eopkg add-repo Cantalupo https://solus.cantalupo.com.br/eopkg-index.xml.xz
	echo "=> special install:microsoft-edge-dev"
	sudo eopkg bi --ignore-safety https://raw.githubusercontent.com/prateekmedia/3rdParty/main/browser/microsoft-edge-dev/pspec.xml && sudo eopkg it microsoft-edge-dev*.eopkg && sudo rm microsoft-edge-dev*.eopkg

}

installarch(){
	echo "=> install arch Dev-Tools"
	sudo pacman -S --noconfirm base-devel #dev-base
	echo " => install yay aur installer"
	yes | sudo pacman -S yay #aur installer
	echo "=> enable TRIM M.2."
	sudo systemctl enable fstrim.timer #enable TRIM M.2.
	
}

installdnf(){
	sleep 3
	echo "=> enable rpm fusion"
	sudo rpm -Uvh http://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm
	sudo rpm -Uvh http://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
	sleep 3
	echo "=> install Fedy"
	sudo dnf copr enable kwizart/fedy -y
	sudo dnf install fedy -y
	echo "=> install Dev-Tools"
	sudo dnf -y groupinstall "Development Tools"
	#sudo echo "fastestmirror=true" >> /etc/dnf/dnf.conf
	#sudo echo "deltarpm=true" >> /etc/dnf/dnf.conf
	echo "=> add Edge repo"
	sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
	sudo dnf config-manager --add-repo https://packages.microsoft.com/yumrepos/edge
	sudo mv /etc/yum.repos.d/packages.microsoft.com_yumrepos_edge.repo /etc/yum.repos.d/microsoft-edge-dev.repo
	sleep 3
	echo "=> install better font"
	sudo dnf install -y freetype-freeworld
	cd /etc/fonts/conf.d
	sudo ln -s /usr/share/fontconfig/conf.avail/10-autohint.conf 
	sudo ln -s /usr/share/fontconfig/conf.avail/10-sub-pixel-rgb.conf 
	sudo ln -s /usr/share/fontconfig/conf.avail/11-lcdfilter-default.conf
	gsettings set org.gnome.settings-daemon.plugins.xsettings antialiasing rgba 
	gsettings set org.gnome.settings-daemon.plugins.xsettings hinting slight
	sleep 3
}

# Loop through arguments and process them
for arg in "$@"
do
    case $arg in
        -i|--initialize)
        SHOULD_INITIALIZE=1
        shift 
        ;;
        -d=*|--distro=*)
        INSTALL_DISTRO="${arg#*=}"
        shift
        ;;
    esac
done

echo "# Installation Method: $SHOULD_INITIALIZE"
echo "# Distro: $INSTALL_DISTRO"

echo "";
echo "Install method is set to $SHOULD_INITIALIZE and distro $INSTALL_DISTRO do you want to proceed ? (yes)"
	read input
	if [ "$input" == "yes" ]
		then
			echo "Starting Installation process..."
		else
			exit
	fi

sleep 2

echo "Run basics tasks"
echo "=> updates/upgrades/dependencies"

if [ $SHOULD_INITIALIZE == "1" ]
then
	if [ $INSTALL_DISTRO == "ubuntu" ] 
	then
		sudo apt upgrade --yes #run upgrades
		installapt #install apt
		sudo apt update --yes #run updates
		
	elif [ $INSTALL_DISTRO == "solus" ] 
	then
		sudo eopkg upgrade #run upgrades
		installeopkg #install eopkg specific 
	elif [ $INSTALL_DISTRO == "arch" ] 
	then
		sudo pacman-mirrors --fasttrack #Fast-track 
		sudo pacman -Syu #run updates
		installarch #install arch 
	elif [ $INSTALL_DISTRO == "fedora" ] 
	then
		sudo dnf update -y #run 
		installdnf #install dnf
		sudo dnf update -y #run updates		
	fi
	
	echo "=> add Flatpak repos"
	#flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo --user
	#flatpak remote-add --if-not-exists nuvola https://dl.tiliado.eu/flatpak/nuvola.flatpakrepo --user
	flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo --system
	flatpak remote-add --if-not-exists nuvola https://dl.tiliado.eu/flatpak/nuvola.flatpakrepo --system
	flatpak update
fi

echo "Install packages"
#installalt order
#flatpak ubuntu solus arch fedora
installalt - gufw gufw gufw gufw #gufw
installalt com.discordapp.Discord discord discord discord discord #discord
installalt org.signal.Signal signal-desktop signal-desktop - signal-desktop #signal
installalt org.telegram.desktop telegram-desktop telegram telegram-desktop telegram-desktop #telegram
installalt com.valvesoftware.Steam steam steam steam-manjaro steam #steam
installalt org.vlc.videolan vlc vlc vlc vlc #vlc
installalt org.gimp.GIMP gimp gimp gimp gimp #gimp
installalt - grsync grsync grsync grsync #grsync
installalt - timeshift - timeshift timeshift #timeshift
installalt org.kde.krita krita krita krita krita #krita
installalt com.obsproject.Studio obs-studio obs-studio obs-studio obs-studio #obs
installalt - gnome-tweaks gnome-tweaks gnome-tweaks gnome-tweak-tool #gnome-tweaks
installalt - gnome-sushi gnome-sushi sushi sushi #gnome-sushi
installalt - evolution - - evolution #evolution email client/calendar sync
installalt - evolution-ews - - evolution-ews #evolution email client/calendar sync

#Flat only
installpkg com.bitwarden.desktop flatOnly flathub system #Bitwarden
installpkg eu.tiliado.NuvolaAppYoutubeMusic flatOnly nuvola user #Youtube Music

#Ubuntu only
if [ $INSTALL_DISTRO == "ubuntu" ]; then
	installpkg microsoft-edge-dev debOnly #microsoft-edge
	installpkg 
fi

#AUR only
if [ $INSTALL_DISTRO == "arch" ]; then
	installpkg microsoft-edge-dev aurOnly #microsoft-edge
	installpkg megasync aurOnly #mega
	installpkg standardnotes-desktop aurOnly #standard-notes
	installpkg appimagelauncher archOnly #standard-notes
	installpkg org.signal.Signal flatonly flathub system #signal
fi

#Solus only
if [ $INSTALL_DISTRO == "solus" ]; then
	installpkg menulibre solusOnly #menulibre
	installpkg git solusOnly #git
	installpkg megasync solusOnly #mega
	installpkg lightdm-settings solusOnly #lightdm-settings
fi

#Fedora only
if [ $INSTALL_DISTRO == "fedora" ]; then
	installpkg microsoft-edge-dev dnfOnly #microsoft-edge
	installpkg gnome-shell-extension-pop-shell dnfOnly #pop-shell
fi

echo "Recommended post-manual tasks"
	echo "* Gnome extensions https://extensions.gnome.org/"
	echo "** Caffeine https://extensions.gnome.org/extension/19/user-themes/"
	echo "** Dash to Dock https://extensions.gnome.org/extension/307/dash-to-dock/"
	echo "** Screenshot Tool https://extensions.gnome.org/extension/1112/screenshot-tool/"
	echo "** Sound Input & Output Device Chooser https://extensions.gnome.org/extension/906/sound-output-device-chooser/"
	echo "** User Themes https://extensions.gnome.org/extension/19/user-themes/"
	echo "** Top icons https://extensions.gnome.org/extension/2311/topicons-plus/"
	echo ""
echo "@ AppImages"
	echo "@@ AppImageLauncher https://github.com/TheAssassin/AppImageLauncher/releases"
	echo "@@ PlingStore https://www.pling.com/p/1175480/"
	echo "@@ StandardNotes https://standardnotes.org/download/linux"
	echo ""
echo "? Extras"
	echo "~~ ocs-url https://www.opendesktop.org/p/1136805/"
	echo "?? Sennheiser GSX1000 https://github.com/evilphish/sennheiser-gsx-1000"
	echo "?? PopOS boot animation https://www.reddit.com/r/pop_os/comments/8ga9um/boot_screen/dzi9cz4/"
	echo "?? Mainline Kernel manager https://github.com/bkw777/mainline"
	echo "?? NVIDIA drivers Fedora https://rpmfusion.org/Howto/NVIDIA"
