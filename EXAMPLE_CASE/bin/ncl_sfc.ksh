#!/bin/ksh -l
#dis
#dis    Open Sourc License/Disclaimer, Forecast Systems Laboratory
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
#Script Name: ncl_sfc.ksh
# 
#     Author: Christopher Harrop
#             Forecast Systems Laboratory
#             325 Broadway R/FST
#             Boulder, CO. 80305
#
#   Released: 10/30/2003
#    Version: 1.0
#    Changes: None
#   Modified: 10/28/2010 to run all forecast lead times in one call to reduce number of serial jobs on bluefire
#
# Purpose: This script generates NCL graphics from wrf output.  
#
#               EXE_ROOT = The full path of the ncl executables
#          MOAD_DATAROOT = Top level directory of wrf output and
#                          configuration data.
#             START_TIME = The cycle time to use for the initial time. 
#                          If not set, the system clock is used.
#         FCST_TIME_LIST = The three-digit forecasts that are to be ncled
#            DOMAIN_LIST = A list of domains to be verified.
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
#$ -N ncl_rr
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

# Vars used for manual testing of the script
#export EXE_ROOT=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE/bin/ncl
#export MODEL=RAPps
#export MOAD_DATAROOT=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE/OUTPUT/RAPps_12km_3km_v3.6.1/DOMAINS/2013072912
#export START_TIME=2013072912
#export FCST_TIME_LIST="00 03 06 09 12 15 18 21 24 27 30 33 36 39 42 45 48" 
#export DOMAIN_LIST="d01 d02"

# Print run parameters
${ECHO}
${ECHO} "ncl_sfc.ksh started at `${DATE}`"
${ECHO}
${ECHO} "MOAD_DATAROOT = ${MOAD_DATAROOT}"
${ECHO} "  DOMAIN_LIST = ${DOMAIN_LIST}"
${ECHO} "     EXE_ROOT = ${EXE_ROOT}"

# Check to make sure the EXE_ROOT var was specified
if [ ! -d ${EXE_ROOT} ]; then
  ${ECHO} "ERROR: EXE_ROOT, '${EXE_ROOT}', does not exist"
  exit 1
fi

# Check to make sure that the MOAD_DATAROOT exists
if [ ! -d ${MOAD_DATAROOT} ]; then
  ${ECHO} "ERROR: MOAD_DATAROOT, '${MOAD_DATAROOT}', does not exist"
  exit 1
fi

# If START_TIME is not defined, use the current time
if [ ! "${START_TIME}" ]; then
  START_TIME=`${DATE} +"%Y%m%d %H"`
else
  if [ `${ECHO} "${START_TIME}" | ${AWK} '/^[[:digit:]]{10}$/'` ]; then
    START_TIME=`${ECHO} "${START_TIME}" | ${SED} 's/\([[:digit:]]\{2\}\)$/ \1/'`
  elif [ ! "`${ECHO} "${START_TIME}" | ${AWK} '/^[[:digit:]]{8}[[:blank:]]{1}[[:digit:]]{2}$/'`" ]; then
    ${ECHO} "ERROR: start time, '${START_TIME}', is not in 'yyyymmddhh' or 'yyyymmdd hh' format"
    exit 1
  fi
  START_TIME=`${DATE} -d "${START_TIME}"`
fi

# Print out times
${ECHO} "   START TIME = "`${DATE} +%Y%m%d%H -d "${START_TIME}"`
${ECHO} "   FCST_TIME_LIST = ${FCST_TIME_LIST}"

# Loop through the forecast times
for FCST_TIME in ${FCST_TIME_LIST}; do

# Loop through the domain list
for DOMAIN in ${DOMAIN_LIST}; do

if [ ${DOMAIN} == "d01" ]; then
  POINT1=${POINT1_d01}
  POINT2=${POINT2_d01}
  NXIN=${NX_d01}
  NYIN=${NY_d01}
  STRIDE=${STRIDE_d01}
  RES=${GRIDSPEC_d01}
elif [ ${DOMAIN} == "d02" ]; then
  POINT1=${POINT1_d02}
  POINT2=${POINT2_d02}
  NXIN=${NX_d02}
  NYIN=${NY_d02}
  STRIDE=${STRIDE_d02}
  RES=${GRIDSPEC_d02}
elif [ ${DOMAIN} == "d03" ]; then
  POINT1=${POINT1_d03}
  POINT2=${POINT2_d03}
  NXIN=${NX_d03}
  NYIN=${NY_d03}
  STRIDE=${STRIDE_d03}
  RES=${GRIDSPEC_d03}
else
  ${ECHO} "NCL crashed! DOMAIN not properly specified."
  exit 1
fi

export POINT1
export POINT2
export NXIN
export NYIN
export STRIDE
export RES

# Set up the work directory and cd into it
workdir=${MOAD_DATAROOT}/nclprd/${FCST_TIME}_${DOMAIN}
${RM} -rf ${workdir}
${MKDIR} -p ${workdir}
cd ${workdir}

# Link to input file
if [[ ${MODEL} == "ARW" || ${MODEL} == "NMM" ]]; then
  ${LN} -s ${MOAD_DATAROOT}/postprd/wrfprs_${DOMAIN}_${FCST_TIME}.tm00 file.grb
  ${ECHO} "${LN} -s ${MOAD_DATAROOT}/postprd/wrfprs_${DOMAIN}_${FCST_TIME}.tm00 file.grb"
  ${ECHO} "file.grb" > arw1_file.txt
elif [ ${MODEL} == "NMB" ]; then
  ${LN} -s ${MOAD_DATAROOT}/postprd/nmbprs_${DOMAIN}_${FCST_TIME}.tm00 file.grb
  ${ECHO} "${LN} -s ${MOAD_DATAROOT}/postprd/nmbprs_${DOMAIN}_${FCST_TIME}.tm00 file.grb"
  ${ECHO} "file.grb" > arw1_file.txt
else
  ${ECHO} "ncl_sfc crashed! file.grb undefined."
  exit 1
fi

set -A ncgms  sfc_temp  \
              sfc_wind  \
              sfc_pwtr  \
              sfc_ptyp  \
              sfc_cape  \
              sfc_cin   \
              sfc_weasd \
              sfc_dewp

set -A pngs sfc_temp.png  \
            sfc_wind.png  \
            sfc_pwtr.png  \
            sfc_ptyp.png  \
            sfc_cape.png  \
            sfc_cin.png   \
            sfc_weasd.png \
            sfc_dewp.png

set -A webnames temp_sfc  \
                wind_sfc  \
                pwtr_sfc  \
                ptyp_sfc  \
                cape_sfc  \
                cin_sfc   \
                weasd_sfc \
                dewp_sfc

ncl_error=0

# Run all the NCL scripts to generate images
i=0
while [ ${i} -lt ${#ncgms[@]} ]; do

  plot=${ncgms[${i}]}
  ${ECHO} "Starting ${plot}.ncl at `${DATE}`"
  ncl < ${EXE_ROOT}/${plot}.ncl
  error=$?
  if [ ${error} -ne 0 ]; then
    ${ECHO} "ERROR: ${plot} crashed!  Exit status=${error}"
    ncl_error=${error}
  fi
  ${ECHO} "Finished ${plot}.ncl at `${DATE}`"

  (( i=i + 1 ))
  
done

# Run ctrans on all the .ncgm files to translate them into Sun Raster files
# NOTE: ctrans ONLY works for 32-bit versions of NCL
i=0
while [ ${i} -lt ${#ncgms[@]} ]; do

  plot=${ncgms[${i}]}
  ${ECHO} "Starting ctrans for ${plot}.ncgm at `${DATE}`"
  ${CTRANS} -d sun ${plot}.ncgm -resolution 1510x1208 > ${plot}.ras  
  error=$?
  if [ ${error} -ne 0 ]; then
    ${ECHO} "ERROR: ctrans ${plot}.ncgm crashed!  Exit status=${error}"
    ncl_error=${error}
  fi
  ${ECHO} "Finished ctrans for ${plot}.ncgm at `${DATE}`"
  (( i=i + 1 ))
  
done

# Run ImageMagick convert to convert the Sun Raster files into .png files
${ECHO} "$PATH"
i=0
while [ ${i} -lt ${#ncgms[@]} ]; do

  plot=${ncgms[${i}]}
  ${ECHO} "Starting convert for ${plot}.ncgm at `${DATE}`"
#  if [ ${plot} == "sfc_cref" ]; then
#    ${CONVERT} +adjoin -trim -border 25x25 -bordercolor white -resize 820x700! ${plot}.ras ${plot}.png
#     ${CONVERT} +adjoin -shave 120x70 -border 25x25 -bordercolor white -scale 820x700! ${plot}.ras ${plot}.png
#  else
#    ${CONVERT} +adjoin -trim -border 25x25 -bordercolor black -resize 820x700! ${plot}.ras ${plot}.png
     ${CONVERT} +adjoin -shave 120x70 -border 25x25 -bordercolor black -scale 820x700! ${plot}.ras ${plot}.png 
#  fi
  error=$?
  if [ ${error} -ne 0 ]; then
    ${ECHO} "ERROR: convert ${plot}.ras crashed!  Exit status=${error}"
    ncl_error=${error}
  fi
  ${ECHO} "Finished convert for ${plot}.ras at `${DATE}`"

  (( i=i + 1 ))
  
done

# Copy png files to their proper names
i=0
while [ ${i} -lt ${#pngs[@]} ]; do
  pngfile=${pngs[${i}]}
  webfile=${MOAD_DATAROOT}/nclprd/${webnames[${i}]}_${DOMAIN}_f${FCST_TIME}.png
  ${MV} ${pngfile} ${webfile}
  ncl_error=$?

  (( i=i + 1 ))
done

# Remove the workdir
cd ${MOAD_DATAROOT}/nclprd
${RM} -rf ${workdir}

done

done

${ECHO} "ncl_sfc.ksh completed at `${DATE}`"

exit ${ncl_error}
