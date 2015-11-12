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
#Script Name: bucket.ksh
#
#     Author: Christopher Harrop
#             Forecast Systems Laboratory
#             325 Broadway R/FST  
#             Boulder, CO. 80305
#
#   Released: 10/30/2003
#    Version: 1.0
#    Changes: 05/31/2011 John Halley Gotway
#               Modify to call the MET PCP-Combine tool instead of bucket. 
#
# Purpose: This script bucket processes wrf output.  It is based on scripts
#          whose authors are unknown.
#
#           MET_EXE_ROOT = The full path to the MET executables
#          MOAD_DATAROOT = Top level directory of wrf output and
#                          configuration data.
#             START_TIME = The cycle time to use for the initial time.
#                          If not set, the system clock is used.
#              FCST_TIME = The three-digit forecast that is to be bucketed
#             ACCUM_TIME = The two-digit accumulation time: 03 or 24
#            DOMAIN_LIST = A list of domains to run.
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
#$ -l h_rt=6:00:00
#$ -N bucket_arw
#$ -j y
#$ -V

# Set path for manual testing of script
#export SCRIPTS=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE/bin

# Make sure $SCRIPTS/constants.ksh exists
if [ ! -x "${CONSTANT}" ]; then
  ${ECHO} "ERROR: ${CONSTANT} does not exist or is not executable"
  exit 1
fi

# Read constants into the current shell
. ${CONSTANT}

# Set core specific variables
if [ "${WRF_CORE}" ]; then
  CORE=${WRF_CORE}
else
# Set the default to ARW 
  CORE="ARW"
fi
${ECHO} "core" ${CORE}

# Vars used for manual testing of the script
#export MOAD_DATAROOT=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE/OUTPUT/RAPps_12km_3km_v3.6.1/DOMAINS/2013072912
#export MET_EXE_ROOT=/glade/p/ral/jnt/Aerocivil/CODE/MET/v5.1_beta/met-5.1beta1/bin
#export START_TIME=2013072912
#export FCST_TIME=03
#export ACCUM_TIME=03
#export DOMAIN_LIST="d01 d02"
#export CORE=ARW

# Loop through the domain list
for DOMAIN in ${DOMAIN_LIST}; do

# Print run parameters
${ECHO}
${ECHO} "bucket.ksh started at `${DATE}`"
${ECHO}
${ECHO} "MOAD_DATAROOT = ${MOAD_DATAROOT}"
${ECHO} " MET_EXE_ROOT = ${MET_EXE_ROOT}"
${ECHO} "     CORE     = ${CORE}"
${ECHO} "  DOMAIN_LIST = ${DOMAIN_LIST}"

# Check to make sure the MET_EXE_ROOT var was specified
if [ ! -d ${MET_EXE_ROOT} ]; then
  ${ECHO} "ERROR: MET_EXE_ROOT, '${MET_EXE_ROOT}', does not exist"
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

# Make sure FCST_TIME was specified
if [ ! "${FCST_TIME}" ]; then
  ${ECHO} "ERROR: \$FCST_TIME is not defined!"
  exit 1
fi

# Make sure ACCUM_TIME was specified
if [ ! "${ACCUM_TIME}" ]; then
  ${ECHO} "ERROR: \$ACCUM_TIME is not defined!"
  exit 1
fi

# Make sure a valid CORE was specified
if [ "${CORE}" == "ARW" ]; then
  :
else
  ${ECHO} "ERROR: Unsupported CORE, '${CORE}'"
  exit 1
fi

# Set the prefix for the input filename created by wrfpost
PREFIX=wrftwo_${DOMAIN}

# Make sure START_TIME is in the correct format
if [ `${ECHO} "${START_TIME}" | ${AWK} '/^[[:digit:]]{10}$/'` ]; then
  START_TIME=`${ECHO} "${START_TIME}" | ${SED} 's/\([[:digit:]]\{2\}\)$/ \1/'`
elif [ ! "`${ECHO} "${START_TIME}" | ${AWK} '/^[[:digit:]]{8}[[:blank:]]{1}[[:digit:]]{2}$/'`" ]; then
  ${ECHO} "ERROR: start time, '${START_TIME}', is not in 'yyyymmddhh' or 'yyyymmdd hh' format"
  exit 1
fi
START_TIME=`${DATE} -d "${START_TIME}"`

# Print out times
${ECHO} "   START_TIME = "`${DATE} +%Y%m%d%H -d "${START_TIME}"`
${ECHO} "    FCST_TIME = ${FCST_TIME}"
${ECHO} "   ACCUM_TIME = ${ACCUM_TIME}"

# Set up the outdir directory
OUTDIR=${MOAD_DATAROOT}/metprd/pcp_combine
${MKDIR} -p ${OUTDIR}

# Create an output file name
OUTFILE="${OUTDIR}/wrfpcp_${DOMAIN}_${ACCUM_TIME}_${FCST_TIME}.nc"

# Run PCP-Combine for ARW output that contains runtime accumulations

# Get the previous forecast time
PRV_FCST_TIME=`${EXPR} ${FCST_TIME} - ${ACCUM_TIME}`
typeset -Z2 PRV_FCST_TIME

# Compute input file names
CUR_FILE=${MOAD_DATAROOT}/postprd/${PREFIX}_${FCST_TIME}.tm00
PRV_FILE=${MOAD_DATAROOT}/postprd/${PREFIX}_${PRV_FCST_TIME}.tm00

# Set up the PCP-Combine command line arguments
PCP_COMBINE_ARGS="-subtract ${CUR_FILE} ${FCST_TIME} ${PRV_FILE} ${PRV_FCST_TIME} ${OUTFILE}"

# Run the PCP-Combine subtraction command
${ECHO} "CALLING: ${MET_EXE_ROOT}/pcp_combine ${PCP_COMBINE_ARGS}"

${MET_EXE_ROOT}/pcp_combine ${PCP_COMBINE_ARGS}
error=$?
if [ ${error} -ne 0 ]; then
  ${ECHO} "${MET_EXE_ROOT}/pcp_combine crashed!  Exit status=${error}"
  exit ${error}
fi

# Change START_TIME back to yyyymmddhh format for next domain
START_TIME=`${DATE} +%Y%m%d%H -d "${START_TIME}"`
${ECHO} "   START_TIME = ${START_TIME}"

done

${ECHO} "bucket.ksh completed at `${DATE}`"

