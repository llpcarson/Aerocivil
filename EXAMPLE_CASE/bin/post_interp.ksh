#!/bin/ksh -l
#dis
#dis    Open Source License/Disclaimer, Forecast Systems Laboratory
#dis    NOAA/OAR/FSL, 325 Broadway Boulder, CO 80305
#dis
#dis    This software is distributed under the Open Source Definition,
#dis    which may be found at http://www.opensource.org/osd.html.
#dis
#dis    In particular, redistribution and use in source and binary forms,
#dis    with or without modification, are permitted provided that the
#dis    following conditions are met:
#dis
#dis    - Redistributions of source code must retain this notice, this
#dis    list of conditions and the following disclaimer.
#dis
#dis    - Redistributions in binary form must provide access to this
#dis    notice, this list of conditions and the following disclaimer, and
#dis    the underlying source code.
#dis
#dis    - All modifications to this software must be clearly documented,
#dis    and are solely the responsibility of the agent making the
#dis    modifications.
#dis
#dis    - If significant modifications or enhancements are made to this
#dis    software, the FSL Software Policy Manager
#dis    (softwaremgr@fsl.noaa.gov) should be notified.
#dis
#dis    THIS SOFTWARE AND ITS DOCUMENTATION ARE IN THE PUBLIC DOMAIN
#dis    AND ARE FURNISHED "AS IS."  THE AUTHORS, THE UNITED STATES
#dis    GOVERNMENT, ITS INSTRUMENTALITIES, OFFICERS, EMPLOYEES, AND
#dis    AGENTS MAKE NO WARRANTY, EXPRESS OR IMPLIED, AS TO THE USEFULNESS
#dis    OF THE SOFTWARE AND DOCUMENTATION FOR ANY PURPOSE.  THEY ASSUME
#dis    NO RESPONSIBILITY (1) FOR THE USE OF THE SOFTWARE AND
#dis    DOCUMENTATION; OR (2) TO PROVIDE TECHNICAL SUPPORT TO USERS.
#dis
#dis

##########################################################################
#
#Script Name: post_interp.ksh
# 
#     Author: Christopher Harrop
#             Forecast Systems Laboratory
#             325 Broadway R/FST
#             Boulder, CO. 80305
#
#   Released: 10/30/2003
#    Version: 1.0
#    Changes: 05/31/2011 John Halley Gotway
#               Append WRFTWO records to WRFPRS files.
#             12/04/2012 John Halley Gotway
#               Redirect call to copygb to copygb_budget.pl.
#
# Purpose: This script post processes wrf output.  It is based on scripts
#          whose authors are unknown.
#
#               EXE_ROOT = The full path of the post executables
#          MOAD_DATAHOME = Top level directory of wrf domain data
#          MOAD_DATAROOT = Top level directory of wrf output and
#                          configuration data.
#             START_TIME = The cycle time to use for the initial time. 
#                          If not set, the system clock is used.
#              FCST_TIME = The two-digit forecast that is to be poste
#            DOMAIN_LIST = A list of domains to run.
#                  MODEL = ARW or NMM 
# 
# A short and simple "control" script could be written to call this script
# or to submit this  script to a batch queueing  system.  Such a "control" 
# script  could  also  be  used to  set the above environment variables as 
# appropriate  for  a  particular experiment.  Batch  queueing options can
# be  specified on the command  line or  as directives at  the top of this
# script.  A set of default batch queueing directives is provided.
#
##########################################################################

# Set the SGE queueing options 
#$ -S /bin/ksh
#$ -pe ncomp 1
#$ -l h_rt=2:00:00
#$ -N post
#$ -j y
#$ -V
#$ -cwd

# Set path for manual testing of script
#export SCRIPTS=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE/bin

# Make sure $SCRIPTS/constants.ksh exists
if [ ! -x "${CONSTANT}" ]; then
  ${ECHO} "ERROR: ${CONSTANT} does not exist or is not executable"
  exit 1
fi

unset MP_PE_AFFINITY

# Read constants into the current shell
. ${CONSTANT}

# Use the copygb budget interpolation script
COPYGB=${SCRIPTS}/copygb_budget_nn.pl

# Constants used for manual testing of the script
#export WRF_ROOT=/glade/p/ral/jnt/Aerocivil/CODE/WRF/v3.6.1/WRFV3_ARW
#export EXE_ROOT=/glade/p/ral/jnt/Aerocivil/CODE/UPP/v3.0/UPPV3.0/bin
#export MOAD_DATAHOME=/glade/p/ral/jnt/Aerocivil/DOMAINS/v3.6.1/RAPps/static/2013072912
#export MOAD_DATAROOT=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE/OUTPUT/RAPps_12km_3km_v3.6.1/DOMAINS/2013072912
#export MODEL=ARW
#export START_TIME=2013072912
#export FCST_TIME=03
#export DOMAIN_LIST="d02"
#export POST_PROC=64

# Print run parameters

${ECHO} "post_interp.ksh started at `${DATE}`"
${ECHO}
${ECHO} "MOAD_DATAHOME = ${MOAD_DATAHOME}"
${ECHO} "MOAD_DATAROOT = ${MOAD_DATAROOT}"
${ECHO} "     EXE_ROOT = ${EXE_ROOT}"
${ECHO} "        MODEL = ${MODEL}"
${ECHO} "  DOMAIN_LIST = ${DOMAIN_LIST}"
${ECHO} "     POST_PROC = ${POST_PROC}"

# Set up some constants
export POST=${EXE_ROOT}/unipost.exe
if [ "${MODEL}" == "ARW" ]; then
  export CORE=NCAR
else
  ${ECHO} "unipost crashed! MODEL and CORE undefined."
  exit 1
fi

# Check to make sure the number of processors for running Post was specified
if [ -z "${POST_PROC}" ]; then
  ${ECHO} "ERROR: The variable \$POST_PROC must be set to contain the number of processors to run Post"
  exit 1
fi

# Check to make sure the EXE_ROOT var was specified
if [ ! -d ${EXE_ROOT} ]; then
  ${ECHO} "ERROR: EXE_ROOT, '${EXE_ROOT}', does not exist"
  exit 1
fi

# Check to make sure the post executable exists
if [ ! -x ${POST} ]; then
  ${ECHO} "ERROR: ${POST} does not exist, or is not executable"
  exit 1
fi

# Check to make sure that the MOAD_DATAHOME exists
if [ ! -d ${MOAD_DATAHOME} ]; then
  ${ECHO} "ERROR: MOAD_DATAHOME, '${MOAD_DATAHOME}', does not exist"
  exit 1
fi

# Check to make sure that the MOAD_DATAROOT exists
if [ ! -d ${MOAD_DATAROOT} ]; then
  ${ECHO} "ERROR: MOAD_DATAROOT, '${MOAD_DATAROOT}', does not exist"
  exit 1
fi

# Make sure DOMAIN_LIST is defined
if [ ! "${DOMAIN_LIST}" ]; then
  ${ECHO} "ERROR: \$DOMAIN_LIST is not defined!"
  exit 1
fi

# Make sure START_TIME is defined
if [ ! "${START_TIME}" ]; then
  ${ECHO} "ERROR: \$START_TIME is not defined!"
  exit 1
fi

# If START_TIME is not defined, use the current time
if [ `${ECHO} "${START_TIME}" | ${AWK} '/^[[:digit:]]{10}$/'` ]; then
  START_TIME=`${ECHO} "${START_TIME}" | ${SED} 's/\([[:digit:]]\{2\}\)$/ \1/'`
elif [ ! "`${ECHO} "${START_TIME}" | ${AWK} '/^[[:digit:]]{8}[[:blank:]]{1}[[:digit:]]{2}$/'`" ]; then
  ${ECHO} "ERROR: start time, '${START_TIME}', is not in 'yyyymmddhh' or 'yyyymmdd hh' format"
  exit 1
fi
START_TIME=`${DATE} -d "${START_TIME}"`

# Print out times
${ECHO} "   START TIME = "`${DATE} +%Y%m%d%H -d "${START_TIME}"`
${ECHO} "    FCST_TIME = ${FCST_TIME}"

# Loop through the domain list
for DOMAIN in ${DOMAIN_LIST}; do
   
# Set up the work directory and cd into it
workdir=${MOAD_DATAROOT}/postprd/${FCST_TIME}_${DOMAIN}
${RM} -rf ${workdir}
${MKDIR} -p ${workdir}
cd ${workdir}

# Set up some constants
export XLFRTEOPTS="unit_vars=yes"
export tmmark=tm00
export MP_SHARED_MEMORY=yes
export RSTFNL=${workdir}/
export COMSP=${workdir}/

if [ ${DOMAIN} == "d01" ]; then
  GRIDSPEC=${GRIDSPEC_d01}
  DOMAIN_ID="01"
elif [ ${DOMAIN} == "d02" ]; then
  GRIDSPEC=${GRIDSPEC_d02}
  DOMAIN_ID="02"
elif [ ${DOMAIN} == "d03" ]; then
  GRIDSPEC=${GRIDSPEC_d03}
  DOMAIN_ID="03"
else
  ${ECHO} "unipost crashed! GRIDSPEC undefined."
  exit 1
fi
${ECHO} "GRIDSPEC=${GRIDSPEC}"

timestr=`${DATE} +%Y-%m-%d_%H:%M:%S -d "${START_TIME} ${FCST_TIME} hours"`

MODEL_OUTFILE=${MOAD_DATAROOT}/wrfprd/wrfout_${DOMAIN}_${timestr}
FTYPE="netcdf"

${ECHO} "MODEL_OUTFILE=${MODEL_OUTFILE}"

${CAT} > itag <<EOF
${MODEL_OUTFILE}
${FTYPE}
${timestr}
${CORE} 
EOF

${CAT} > input${FCST_TIME}.prd <<EOF
${workdir}/WRFPRS.GrbF${FCST_TIME}.${DOMAIN}
EOF

${RM} -f fort.*
ln -s ${MOAD_DATAHOME}/wrf_cntrl.parm fort.14
ln -s ./itag fort.19

# Linke micro lookup table
ln -s ${WRF_ROOT}/run/ETAMPNEW_DATA eta_micro_lookup.dat

# Get the current time
now=`${DATE} +%Y%m%d%H%M%S`

# Run unipost
${MPIRUN} ${POST}< itag
#${POST}< itag
#${MPIRUN} ${POST}< itag
error=$?
if [ ${error} -ne 0 ]; then
  ${ECHO} "${POST} crashed!  Exit status=${error}"
  ${MPIRUN} ${EXIT_CALL} ${error}
  exit
fi

# Rename the output files to include the domain identifier
${MV} WRFPRS${FCST_TIME}.tm00 WRFPRS_${DOMAIN}_${FCST_TIME}.tm00
${MV} WRFTWO${FCST_TIME}.tm00 WRFTWO_${DOMAIN}_${FCST_TIME}.tm00
${MV} WRFNAT${FCST_TIME}.tm00 WRFNAT_${DOMAIN}_${FCST_TIME}.tm00

# Check to make sure all Post output files were produced
if [ ! -s "${workdir}/WRFPRS_${DOMAIN}_${FCST_TIME}.tm00" ]; then
  ${ECHO} "unipost crashed! WRFPRS_${DOMAIN}_${FCST_TIME}.tm00 is missing"
  ${MPIRUN} ${EXIT_CALL} 1
  exit
fi
if [ ! -s "${workdir}/WRFTWO_${DOMAIN}_${FCST_TIME}.tm00" ]; then
  ${ECHO} "unipost crashed! WRFTWO_${DOMAIN}_${FCST_TIME}.tm00 is missing"
  ${MPIRUN} ${EXIT_CALL} 1
  exit
fi
if [ ! -s "${workdir}/WRFNAT_${DOMAIN}_${FCST_TIME}.tm00" ]; then
  ${ECHO} "unipost crashed! WRFNAT_${DOMAIN}_${FCST_TIME}.tm00 is missing"
  ${MPIRUN} ${EXIT_CALL} 1
  exit
fi

# Move the output files to postprd
${MV} ${workdir}/WRFPRS_${DOMAIN}_${FCST_TIME}.tm00 ${MOAD_DATAROOT}/postprd
${MV} ${workdir}/WRFTWO_${DOMAIN}_${FCST_TIME}.tm00 ${MOAD_DATAROOT}/postprd
${MV} ${workdir}/WRFNAT_${DOMAIN}_${FCST_TIME}.tm00 ${MOAD_DATAROOT}/postprd
cd ${MOAD_DATAROOT}/postprd
${RM} -rf ${workdir}

# Do this later (after copygb is run).  If not running copygb, do this here.
# Append entire WRFTWO to WRFPRS
#${CAT} WRFPRS_${DOMAIN}_${FCST_TIME}.tm00 WRFTWO_${DOMAIN}_${FCST_TIME}.tm00 > WRFPRS_${DOMAIN}_${FCST_TIME}.tm00.new
#error=$?
#if [ ${error} -ne 0 ]; then
#  ${ECHO} "ERROR: ${CAT} WRFPRS_${DOMAIN}_${FCST_TIME}.tm00 WRFTWO_${DOMAIN}_${FCST_TIME}.tm00 > WRFPRS_${DOMAIN}_${FCST_TIME}.tm00.new failed!"
#  ${MPIRUN} ${EXIT_CALL} 1
#  exit
#fi
#${MV} WRFPRS_${DOMAIN}_${FCST_TIME}.tm00.new WRFPRS_${DOMAIN}_${FCST_TIME}.tm00

# Interpolate WRFPRS unipost output onto wrfprs (copygb step)
${ECHO} "Interpolating WRFPRS_${DOMAIN}_${FCST_TIME}.tm00..."
${COPYGB} -xg"'${GRIDSPEC}'" WRFPRS_${DOMAIN}_${FCST_TIME}.tm00 wrfprs_${DOMAIN}_${FCST_TIME}.tm00
error=$?
if [ ${error} -ne 0 ]; then
  ${ECHO} "${COPYGB} crashed!  Exit status=${error}"
  ${MPIRUN} ${EXIT_CALL} ${error}
  exit
fi
${ECHO}
${ECHO} "Checking wrfprs_${DOMAIN}_${FCST_TIME}.tm00..."
${ECHO}
${WGRIB} wrfprs_${DOMAIN}_${FCST_TIME}.tm00
error=$?
if [ ${error} -ne 0 ]; then
  ${ECHO} "ERROR: ${COPYGB} produced a garbage wrfprs_${DOMAIN}_${FCST_TIME}.tm00 file"
  ${MPIRUN} ${EXIT_CALL} 1
  exit
fi

# Interpolate WRFTWO unipost output onto wrftwo
${ECHO} "Interpolating WRFTWO_${DOMAIN}_${FCST_TIME}.tm00..."
${COPYGB} -xg"'${GRIDSPEC}'" WRFTWO_${DOMAIN}_${FCST_TIME}.tm00 wrftwo_${DOMAIN}_${FCST_TIME}.tm00
error=$?
if [ ${error} -ne 0 ]; then
  ${ECHO} "${COPYGB} crashed!  Exit status=${error}"
  ${MPIRUN} ${EXIT_CALL} ${error}
  exit
fi
${ECHO}
${ECHO} "Checking wrftwo_${DOMAIN}_${FCST_TIME}.tm00..."
${ECHO}
${WGRIB} wrftwo_${DOMAIN}_${FCST_TIME}.tm00
error=$?
if [ ${error} -ne 0 ]; then
  ${ECHO} "ERROR: ${COPYGB} produced a garbage wrftwo_${DOMAIN}_${FCST_TIME}.tm00 file"
  ${MPIRUN} ${EXIT_CALL} 1
  exit
fi

# Check to make sure the output files are there
if [ ! -s "wrfprs_${DOMAIN}_${FCST_TIME}.tm00" ]; then
  echo "wrfprs_${DOMAIN}_${FCST_TIME}.tm00 is missing!"
  ${MPIRUN} ${EXIT_CALL} 1
  exit
fi
if [ ! -s "wrftwo_${DOMAIN}_${FCST_TIME}.tm00" ]; then
  echo "wrftwo_${DOMAIN}_${FCST_TIME}.tm00 is missing!"
  ${MPIRUN} ${EXIT_CALL} 1
  exit
fi

# Append entire wrftwo to wrfprs
${CAT} wrfprs_${DOMAIN}_${FCST_TIME}.tm00 wrftwo_${DOMAIN}_${FCST_TIME}.tm00 > wrfprs_${DOMAIN}_${FCST_TIME}.tm00.new
${MV} wrfprs_${DOMAIN}_${FCST_TIME}.tm00.new wrfprs_${DOMAIN}_${FCST_TIME}.tm00

done # domain

${ECHO} "post_interp.ksh completed at `${DATE}`"
