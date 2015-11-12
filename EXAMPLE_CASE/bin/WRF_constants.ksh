#!/bin/ksh -l

##########################################################################
#
# Script Name: constants.ksh
#
# Description:
#    This script localizes several tools specific to this platform.  It
#    should be called by other workflow scripts to define common
#    variables.
#
##########################################################################

# Usin GMT time zone for time computations
export TZ="GMT"

# Give other group members write access to the output files
umask 2

# Load modules
source /glade/apps/opt/lmod/lmod/init/ksh
export MODULEPATH_ROOT=/glade/apps/opt/modulefiles
export MODULEPATH=$MODULEPATH_ROOT/compilers/:$MODULEPATH_ROOT/idep/:$MODULEPATH_ROOT/cdep/intel

module load intel/12.1.5
module load netcdf/4.3.0
module load ncl/6.2.0
module load ncarbinlibs/1.1
module load ncarenv/1.0
module load ncarcompilers/1.0
module list

# Set up paths to shell commands
AWK="/usr/bin/gawk --posix"
BASENAME=/bin/basename
BC=/usr/bin/bc
CAT=/bin/cat
CHMOD=/bin/chmod
CONFIG_d01_PATH=/glade/p/ral/jnt/Aerocivil/DOMAINS/v3.6.1/met_config/27km/masks
CONFIG_d02_PATH=/glade/p/ral/jnt/Aerocivil/DOMAINS/v3.6.1/met_config/9km/masks
CONFIG_d03_PATH=/glade/p/ral/jnt/Aerocivil/DOMAINS/v3.6.1/met_config/3km/masks
CONVERT=/usr/bin/convert
COPYGB=/glade/p/ral/jnt/Aerocivil/CODE/UPP/v3.0/UPPV3.0/bin/copygb.exe
CP=/bin/cp
CTRANS=/glade/apps/opt/ncl/6.0.0/gnu/4.4.6/bin/ctrans
CUT=/usr/bin/cut
DATE=/bin/date
DIRNAME=/usr/bin/dirname
ECHO=/bin/echo
EXPR=/usr/bin/expr
GREP=/bin/grep
# Grid specifications used in RC testing
GRIDSPEC_d01="255 0 118 124 -10056 -87633 128 19719 -58866 243 240 64"
GRIDSPEC_d01_RGD=NONE
GRIDRES_d01=27km
GRIDSPEC_d02="255 0 239 248 -5306 -83082 128 14675 -63661 81 80 64"
GRIDSPEC_d02_RGD="\"lambert 725 500 31.820 -112.440 -101.800 3 6371.2 33.000 45.000\""
GRIDRES_d02=9km
GRIDSPEC_d03="255 0 428 476 -221 -78315 128 12569 -66722 27 26 64"
GRIDSPEC_d03_RGD="\"lambert 725 500 31.820 -112.440 -101.800 3 6371.2 33.000 45.000\""
GRIDRES_d03=3km
HSI=/ncar/opt/hpss/hsi
LN=/bin/ln
LS=/bin/ls
POINT1_d01="123"
POINT1_d02="247"
POINT1_d03="475"
POINT2_d01="117"
POINT2_d02="238"
POINT2_d03="427"
MET_DIR=/glade/p/ral/jnt/Aerocivil/CODE/MET/v5.1_beta/met-5.1beta1
MKDIR=/bin/mkdir
MPIRUN=mpirun.lsf
MV=/bin/mv
NCAR_LIB=/glade/apps/opt/ncl/6.2.0/gnu/4.4.6/lib
NX_d01=118
NX_d02=239
NX_d03=428
NY_d01=124
NY_d02=248
NY_d03=476
OD=/usr/bin/od
PATH=${NCARG_ROOT}/bin:${PATH}
RM=/bin/rm
RSYNC=/usr/bin/rsync
SED=/bin/sed
STRIDE_d01=6
STRIDE_d02=12
STRIDE_d03=24
TAIL=/usr/bin/tail
TAR=/bin/tar
TOUCH=/bin/touch
TR=/usr/bin/tr
VERSION="WRFv3.6.1"
WC=/usr/bin/wc
WGRIB=/glade/apps/opt/wgrib/1.8.1.0b/gnu/4.7.0/wgrib
