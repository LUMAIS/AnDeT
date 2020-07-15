#!/bin/sh
#
# \description  Build AnDeT components
# Note: this script is designed for Linux Ubuntu and might also work on Debian
# or other Linuxes
#
# \author Artem Lutov <lutov.analytics@gmail.com>

# build [-i,--initial] [component]
# components: artemis fort-tags hermes leto olympus

USAGE="$0 [-h,--help] | [-i,--init]
  -h,--help  - help, show this usage description
  -i,--init  - initialize the build environment, which should be done only when building the project for the first time

  Examples:
  \$ $0 -i
  \$ $0
"

INIT=0  # Whether to initialize the build environment
while [ $1 ]; do
	case $1 in
	-h|--help)
		# Use defaults for the remained parameters
		#echo -e $USAGE # -e to interpret '\n""
        printf "$USAGE"
		exit 0
		;;
	-i|--init)
		INIT=1
		echo "Build environment installation is activated"
		shift
		;;
	*)
		printf "Error: Invalid option specified: $1 ...\n\n$USAGE"
		exit 1
		;;
	esac
done

# Initialize the build environment if required
if [ $INIT -ne 0 ]; then
    ./install_reqs.sh

    ERR=$?
    if [ $ERR -ne 0 ]; then
        echo "ERROR, installation of the build environment is failed, error code: $ERR"
        exit $ERR
    fi
fi

# Update all submodules
git submodule update --recursive

NBUILDS=0  # The number of all builds

# Define environment variables related to the Frame Grabber, required to build dependent components (artemis)
if [ -f '/opt/euresys/coaxlink/shell/setup_gentl_paths.sh' ]; then
	. /opt/euresys/coaxlink/shell/setup_gentl_paths.sh
else
	echo "ERROR: environment variables initialization script of the Euresys CoaxLink driver is not found"
fi

# Build ant tracking app
ERR_ARTM=0
# -p to omit error if the directory is already exists
# Note: -j 4 (> 1) is not supported by artemis
cd artemis && \
mkdir -p build && \
cd build && cmake .. && make && \
cd ../..
ERR_ARTM=$?
NBUILDS=$((NBUILDS+1))

# Build tracking data format
ERR_HERM=0
# -p to omit error if the directory is already exists
cd hermes && \
mkdir -p build && \
cd build && cmake .. && make && \
cd ../..
# ERROR on building:
# src/fort/hermes/CMakeFiles/fort-hermes-cpp.dir/build.make:61: *** target pattern contains no '%'.  Stop.
# make[1]: *** [CMakeFiles/Makefile2:205: src/fort/hermes/CMakeFiles/fort-hermes-cpp.dir/all] Error 2
# make: *** [Makefile:130: all] Error 2
ERR_HERM=$?
NBUILDS=$((NBUILDS+1))

# Build server part of  tracking configuration (is deployed on a grabbing PC)
ERR_LETO=0
cd leto/leto && \
go build -i . && \
cd ../..
# Clients to get live video streams
#cd ../leto-cli
#go build -i .
ERR_LETO=$?
NBUILDS=$((NBUILDS+1))

## Build web UI for the climate control (and for some other controls)
#cd olympus
#go build -i .
##go install .
##go get -u .
##
## Install webapp environment
#cd webapp
#ERR=$?
#if [ $ERR -ne 0 ]; then
#	echo "ERROR, the build script should be executed from the repository root."
#	exit $ERR
#fi
#npm install
### Note: audit fix breaks build-angular version
##npm audit fix
##npm uninstall @angular-devkit/build-angular
##npm install --save-dev @angular-devkit/build-angular@0.13
####ng update @angular/cli @angular/core --allow-dirty --force
##
## Serve the client application
##ng serve
#cd ../..

# Report the build execution status
if [ $ERR_ARTM -ne 0 -o $ERR_HERM -ne 0 -o $ERR_LETO -ne 0 ]; then
	echo "ERROR, some builds were failed, error codes:
  leto-cli: $ERR_ARTM
  tag-layouter: $ERR_HERM
  studio: $ERR_LETO
"
	exit 1
fi

echo "Successfully completed builds: $NBUILDS"
