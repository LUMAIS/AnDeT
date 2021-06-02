#!/bin/sh
#
# \description  Install external system libraries for the AnDeT
# Note: this script is designed for Linux Ubuntu and might also work on Debian
# or other Linuxes
#
# \author Artem Lutov <lutov.analytics@gmail.com>

# Target OS: Linux
# Actual build OS: Linux Debian 9 + / Ubuntu 18.04+

# Update and init all submodules
git submodule update --init --recursive

# Common development packages required to build executables
echo "Checking and installing common build environment ..."
echo "-- make --"
make --version
ERR=$?
if [ $ERR -ne 0 ]; then
	sudo apt-get install -y build-essential	make g++ cmake bc
fi

echo "-- g++ --"
g++ --version
ERR=$?
if [ $ERR -ne 0 ]; then
	sudo apt-get install -y g++
fi

echo "-- cmake --"
cmake --version
ERR=$?
if [ $ERR -ne 0 ]; then
	sudo apt-get install -y cmake bc
fi
# Install the latest version of cmake if required
CMAKE_MIN=3.11  # Minimal required version of cmake
CMAKE_VER=`cmake --version | grep -o '[0-9].[0-9]*'`
RES=`echo "$CMAKE_VER>$CMAKE_MIN" | bc`
if [ $RES -eq 0 ]; then
	set -o xtrace
	wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
	sudo apt-get install -y apt-transport-https ca-certificates gnupg software-properties-common wget
	LINUX_CNAME=`lsb_release -cs`  # Linux code name
	sudo apt-add-repository -y "deb https://apt.kitware.com/ubuntu/ $LINUX_CNAME main"
	set +o xtrace
	sudo apt-get update
	sudo apt-get install -y cmake
fi

# Component-specific requirements
# hermes (tracking data format)
whereis go | grep go > /dev/null
ERR=$?
if [ $ERR -eq 0 ]; then
	whereis libprotobuf | grep libprotobuf > /dev/null
	ERR=$?
fi
if [ $ERR -eq 0 ]; then
	whereis asio | grep asio > /dev/null
	ERR=$?
fi
if [ $ERR -ne 0 ]; then
	echo "Installing build environment for hermes (tracking data format) ..."
	sudo apt-get install -y golang libprotobuf-dev protobuf-compiler libasio-dev
fi

# artemis (object detection and tracking)
whereis libprotobuf | grep libprotobuf > /dev/null
ERR=$?
if [ $ERR -eq 0 ]; then
	# Note: opencv is not detectable via `whereis``
	dpkg -l | grep libopencv > /dev/null
	ERR=$?
fi
if [ $ERR -eq 0 ]; then
	whereis eigen3 | grep eigen3 > /dev/null
	ERR=$?
fi
if [ $ERR -eq 0 ]; then
	whereis glog | grep glog > /dev/null
	ERR=$?
fi
if [ $ERR -eq 0 ]; then
	# Note: glfw3 is not detectable via `whereis``
	dpkg -l | grep libglfw3 > /dev/null
	ERR=$?
fi
if [ $ERR -eq 0 ]; then
	# Note: glew is not detectable via `whereis``
	dpkg -l | grep libglew > /dev/null
	ERR=$?
fi
if [ $ERR -ne 0 ]; then
	echo "Installing build environment for artemis (object detection and tracking) ..."
	sudo apt-get install -y libprotobuf-dev protobuf-compiler libopencv-dev libeigen3-dev libgoogle-glog-dev libglfw3-dev libglew-dev
fi

#  libasio-dev
# https://github.com/formicidae-tracker/fort-configuration/search?q=REQUIRED&unscoped_q=REQUIRED
# 'libopencv-imgproc-dev', 'libopencv-highgui-dev'
# , 'libboost-dev'
# , 'google-mock', 'ffmpeg'

# leto (live tracking video and tracking configuration)
whereis go | grep go > /dev/null
ERR=$?
if [ $ERR -ne 0 ]; then
	echo "Installing build environment for leto (live tracking video and tracking configuration) ..."
	sudo apt-get install -y golang
fi

# Euresys CoaxLink driver dependencies
# See coaxlink-linux-x86_64-13.0.1.32$ ./shell/check-install.sh
whereis libtinfo | grep libtinfo > /dev/null
ERR=$?
if [ $ERR -eq 0 ]; then
	whereis gconf | grep gconf > /dev/null
	ERR=$?
fi
if [ $ERR -ne 0 ]; then
	echo "Installing environment for the Euresys CoaxLink ..."
	sudo apt-get install -y libtinfo5 libgconf-2-4
fi
if [ ! -f '/opt/euresys/egrabber/shell/setup_gentl_paths.sh' ]; then
	# Note:  && echo is used to print a new line
	read -sp "Please, install the Euresys CoaxLink driver:
https://www.euresys.com/en/Support/Software,-drivers-and-documentation?series=105d06c5-6ad9-42ff-b7ce-622585ce607f&os=Linux
Press Enter when the driver appears in the system..." && echo
	if [ ! -f '/opt/euresys/egrabber/shell/setup_gentl_paths.sh' ]; then
		echo "ERROR: environment variables initialization script of the Euresys CoaxLink driver is not found"
		ERR=2  # ENOENT = 2 = No such file or directory
	fi
fi
#echo "Installing the build environment for FORT:artemis (FORmicidae Tracker) ..."
## Note: requires some FORT:hermes dependences: libprotobuf-dev libasio-dev
## NOTE: requires installation of Euresys grabber drivers
#sudo apt-get install -y ... 

#echo "Installing build environment for FORT:olympus (web UI) ..."
#sudo apt install -y npm
##sudo npm install -g @angular/cli typescript


if [ $ERR -eq 0 ]; then
	ERR=$?
fi
if [ $ERR -ne 0 ]; then
	echo "ERROR, installation of the build environment is failed, error code: $ERR"
	exit $ERR
fi
