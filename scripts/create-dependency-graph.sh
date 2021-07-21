#!/bin/bash
###############################################################
#                Unofficial 'Bash strict mode'                #
# http://redsymbol.net/articles/unofficial-bash-strict-mode/  #
###############################################################
set -euo pipefail
IFS=$'\n\t'
###############################################################

set -x

IMG_NAME="${1}"
BUILD_NUMBER="${2}"

# NOTE: This list should not include ANY packages that are maintained in pi-top APT repos
# (including mirrors/self-packaged)

packages=(
	adapta-gtk-theme
	adduser
	agnostics
	alsa-utils
	apt
	aptitude
	arping
	asciinema
	at-spi2-core
	baobab
	barrier
	bash
	bc
	breeze-cursor-theme
	caffeine
	caffeine-indicator
	chafa
	chromium-browser
	codelite
	compton
	coreutils
	cups
	dbus-x11
	dconf-gsettings-backend
	debianutils
	desktop-file-utils
	dpkg
	erlang-base
	espeak
	fontconfig-infinality
	fonts-droid-fallback
	fonts-freefont-ttf
	fonts-noto-mono
	fonts-piboto
	fonts-roboto-hinted
	fonts-symbola
	gimp
	gjs
	gnome-calculator
	gnome-icon-theme
	gnupg
	grep
	gsettings-backend
	gtk2-engines-clearlookspix
	gtk2-engines-pixbuf
	gtk2-engines-pixflat
	gui-pkinst
	hicolor-icon-theme
	hplip
	htop
	i2c-tools
	imagemagick
	init-system-helpers
	inotify-tools
	iproute2
	iputils-ping
	isc-dhcp-server
	jackd2
	jq
	libatk1.0-0
	libatlas-base-dev
	libatlas-base-dev
	libatomic1
	libaubio5
	libc-bin
	libc6
	libcairo-gobject2
	libcairo2
	libcurl3-nss
	libext-dev
	libfm-gtk4
	libfm-modules
	libfreetype6
	libfreetype6-dev
	libgbm1
	libgcc1
	libgdk-pixbuf2.0-0
	libgeis1
	libgksu2-0
	libgles2
	libglib2.0-0
	libglib2.0-bin
	libgtk-3-0
	libgtk-3-dev
	libgtk2.0-0
	libgtk2.0-bin
	libgtk2.0-common
	libi2c0
	libicu-dev
	libinput10
	libjasper-dev
	libjpeg-dev
	libjpeg62-dev
	libjpeg62-turbo
	libjs-sphinxdoc
	liblapack-dev
	liblcms1-dev
	libmraa-dev
	libmraa1
	libnotify-bin
	libnss3
	libopenblas-dev
	libpango-1.0-0
	libpango1.0-0
	libpangocairo-1.0-0
	libpixman-1-0
	libpng16-16
	libportmidi0
	libpugixml1v5
	libqscintilla2-qt5-13
	libqt4-test
	libqt4-xml
	libqt5concurrent5
	libqt5core5a
	libqt5gui5
	libqt5network5
	libqt5opengl5
	libqt5positioning5
	libqt5printsupport5
	libqt5qml5
	libqt5quick5
	libqt5svg5
	libqt5webchannel5
	libqt5webengine5
	libqt5webenginecore5
	libqt5webenginewidgets5
	libqt5widgets5
	libqt5xml5
	libqtgui4
	libqwt-qt5-6
	libraspberrypi-bin
	libreoffice
	libreoffice-common
	libreoffice-pi
	libreoffice-style-papirus
	libsdl-image1.2
	libsdl-mixer1.2
	libsdl-ttf2.0-0
	libsdl1.2debian
	libsecret-1-0
	libsmpeg0
	libstdc++6
	libtiff5
	libudev1
	libwebp6
	libwebpdemux2
	libwebpmux2
	libwnck-3-dev
	libx11
	libx11-6
	libx11-dev
	libxext-dev
	libxi6
	libxkbcommon0
	libxkbfile1
	libxrandr2
	libxss-dev
	libxss1
	libxtst6
	libzmq3
	libzmq3-dev
	lightdm
	lxinput
	lxmenu-data
	lxpanel
	lxpanel-data
	lxplug-bluetooth
	lxplug-cputemp
	lxplug-ejecter
	lxplug-magnifier
	lxplug-network
	lxplug-ptbatt
	lxplug-volumepulse
	lxsession
	lxterminal
	mawk
	minecraft-pi
	mpg123
	mtpaint
	mu-editor
	net-tools
	omxplayer
	onboard
	openbox
	p7zip-full
	passwd
	pcmanfm
	pi-greeter
	pi-printer-support
	pimixer
	pipanel
	pishutdown
	piwiz
	plymouth
	plymouth-themes
	policykit-1
	procps
	pt-about
	pt-diagnostics
	pt-hub
	pt-os-setup
	pt-pma
	pt-pulse
	pt-speaker
	pt-tour
	pulseaudio
	pulseaudio-module-bluetooth
	pulseaudio-module-jack
	python-bluetool
	python-games
	python-numpy-abi9
	python-smbus
	python3
	python3-aiofiles
	python3-aiohttp
	python3-aiohttp-cors
	python3-flask
	python3-flask-cors
	python3-flask-sockets
	python3-gevent
	python3-gevent-websocket
	python3-gpiozero
	python3-imageio
	python3-imutils
	python3-isc-dhcp-leases
	python3-matplotlib
	python3-minecraftpi
	python3-monotonic
	python3-mraa
	python3-netifaces
	python3-notify2
	python3-numpy
	python3-numpy-abi9
	python3-opencv
	python3-pil
	python3-pil.imagetk
	python3-pip
	python3-psutil
	python3-pt-buttons
	python3-pt-common
	python3-pt-hub-v1
	python3-pt-hub-v2
	python3-pt-hub-v3
	python3-pt-keyboard
	python3-pt-oled
	python3-pt-pma
	python3-pt-proto-plus
	python3-pt-pulse
	python3-pt-speaker
	python3-pt-speech
	python3-pycrc
	python3-pyftdi
	python3-pygame
	python3-pyinotify
	python3-pynput
	python3-pynput
	python3-pyserial
	python3-python-osc
	python3-pyv4l2camera
	python3-pywifi
	python3-rpi.gpio
	python3-scipy
	python3-serial
	python3-simple-pid
	python3-sklearn
	python3-smbus
	python3-smbus2
	python3-spidev
	python3-systemd
	python3-thonny
	python3-upm
	python3-waitress
	python3-websockets
	python3-wxgtk
	python3-wxgtk3.0
	python3-zmq
	python3.7
	python3:any
	qml-module-qtgraphicaleffects
	qml-module-qtquick-controls2
	qml-module-qtquick-window2
	qml-module-qtquick2
	qml-module-qtwebengine
	raspberrypi-sys-mods
	raspi-config
	rc-gui
	read-edid
	realvnc-vnc-server
	realvnc-vnc-viewer
	rp-bookshelf
	rpd-icons
	rpd-wallpaper
	rsync
	ruby
	sc3-plugins-server
	scratch2
	scratch3
	scrot
	sed
	silversearcher-ag
	smartsim
	sonic-pi-server
	sphinx-rtd-theme-common
	squashfs-tools
	sshpass
	sugar-turtleart-activity
	supercollider-server
	system-config-printer
	systemd
	udev
	vim
	visual-studio-code
	vlc
	wiring-pi
	wiringpi
	wmctrl
	wolfram-engine
	wpacli
	wpasupplicant
	x11-xserver-utils
	xclip
	xdotool
	xfce4-notifyd
	xprintidle
	xserver-xorg
	xserver-xorg-input-evdev
	xserver-xorg-video-fbturbo
	zenity
	zip
	zlib1g-dev
	zsh
)

append_to_file() {
	text="${1}"
	file="${2}"

	echo "${text}" | sudo tee -a "${file}"
}

update_debtree_file() {
	header="${1}"
	conf_file="${2}"

	append_to_file "" "${conf_file}"
	append_to_file "${header}" "${conf_file}"
	append_to_file "$(printf '%s\n' "${packages[@]}")" "${conf_file}"
}

debtree_images_folder="/tmp/debtree-images"
if [ ! -d "${debtree_images_folder}" ]; then
	mkdir "${debtree_images_folder}"
else
	rm "${debtree_images_folder}"/*
fi

# * include suggested packages
# * show which packages are installed on the system
debtree_args=("--with-suggests" "--show-installed")

# Reset to default list first:
# echo "libc6
# libgcc1
# libstdc++6
# zlib1g
# libx11-6
# multiarch-support
# libc-dev
# libc6-dev" | sudo tee /etc/debtree/skiplist
update_debtree_file "# remove non pi-top packages from graphs:" /etc/debtree/skiplist

debtree "${debtree_args[@]}" pt-os | dot -T png >"${debtree_images_folder}/${IMG_NAME}_c${BUILD_NUMBER}-deps-os-pt.png"

# TODO: move to another script
tree --charset=ascii /etc/systemd/system >"${debtree_images_folder}/${IMG_NAME}_c${BUILD_NUMBER}-systemd-tree.txt"

exit 0
