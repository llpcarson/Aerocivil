#!/bin/ksh -l

##########################################################################
#
# Script Name: met_point_verf_all.ksh
#
#      Author: John Halley Gotway
#              NCAR/RAL/DTC
#
#    Released: 10/26/2010
#
# Description:
#    This script runs the MET/Point-Stat tool to verify gridded output
#    from the WRF PostProcessor using point observations.  The MET/PB2NC
#    tool must be run on the PREPBUFR observation files to be used prior
#    to running this script.
#
#             START_TIME = The cycle time to use for the initial time.
#             FCST_TIME  = The two-digit forecast that is to be verified.
#            DOMAIN_LIST = A list of domains to be verified.
#           MET_EXE_ROOT = The full path of the MET executables.
#             MET_CONFIG = The full path of the MET configuration files.
#           UPP_EXE_ROOT = The full path of the UPP executables.
#          MOAD_DATAROOT = Top-level data directory of WRF output.
#                RAW_OBS = Directory containing observations to be used.
#                  MODEL = The model being evaluated.
#
##########################################################################

# Set the SGE queueing options
#$ -S /bin/ksh
#$ -pe wcomp 1
#$ -l h_rt=06:00:00
#$ -N met_point_verf
#$ -j y
#$ -V
#$ -cwd

# Name of this script
#SCRIPT=met_point_verf_all.ksh

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
#export START_TIME=2013072912
#export FCST_TIME="03" 
#export DOMAIN_LIST="d01 d02" 
#export MET_EXE_ROOT=/glade/p/ral/jnt/Aerocivil/CODE/MET/v5.1_beta/met-5.1beta1/bin
#export MET_CONFIG=/glade/p/ral/jnt/Aerocivil/DOMAINS/v3.6.1/met_config
#export UPP_EXE_ROOT=/glade/p/ral/jnt/Aerocivil/CODE/v3.0/UPPV3.0/bin
#export MOAD_DATAROOT=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE/OUTPUT/RAPps_12km_3km_v3.6.1/DOMAINS/2013072912
#export RAW_OBS=/glade/p/ral/jnt/Aerocivil/OBS/NDAS_03h
#export MODEL=ARW

# Specify Experiment name
#PLLN=arwref
#typeset -L8 pll3
#pll3=ARWref
#PLL3=ARWref

# Print run parameters/masks
${ECHO}
${ECHO} "${SCRIPT} started at `${DATE}`"
${ECHO}
${ECHO} "    START_TIME = ${START_TIME}"
${ECHO} "     FCST_TIME = ${FCST_TIME}"
${ECHO} "   DOMAIN_LIST = ${DOMAIN_LIST}"
${ECHO} "  MET_EXE_ROOT = ${MET_EXE_ROOT}"
${ECHO} "    MET_CONFIG = ${MET_CONFIG}"
${ECHO} "  UPP_EXE_ROOT = ${UPP_EXE_ROOT}"
${ECHO} " MOAD_DATAROOT = ${MOAD_DATAROOT}"
${ECHO} "       RAW_OBS = ${RAW_OBS}"
${ECHO} "         MODEL = ${MODEL}"
${ECHO} "          CORE = ${CORE}"

# Make sure $MOAD_DATAROOT exists
if [ ! -d "${MOAD_DATAROOT}" ]; then
  ${ECHO} "ERROR: MOAD_DATAROOT, ${MOAD_DATAROOT} does not exist"
  exit 1
fi

# Make sure $MOAD_DATAROOT/postprd exists
if [ ! -d "${MOAD_DATAROOT}/postprd" ]; then
  ${ECHO} "ERROR: MOAD_DATAROOT/postprd, ${MOAD_DATAROOT}/postprd does not exist"
  exit 1
fi

# Make sure RAW_OBS directory exists
if [ ! -d ${RAW_OBS} ]; then
  ${ECHO} "ERROR: RAW_OBS, ${RAW_OBS}, does not exist!"
  exit 1
fi

# Go to working directory
workdir=${MOAD_DATAROOT}/metprd
${MKDIR} -p ${workdir}
cd ${workdir}

export MODEL
export VERSION
export FCST_TIME
${ECHO} "MODEL=${MODEL}"
${ECHO} "VERSION=${VERSION}"
${ECHO} "FCST_TIME=${FCST_TIME}"

# Loop through the domain list
for DOMAIN in ${DOMAIN_LIST}; do
   
   export DOMAIN
   ${ECHO} "DOMAIN=${DOMAIN}"
   ${ECHO} "FCST_TIME=${FCST_TIME}"

   if [ ${DOMAIN} == "d01" ]; then
     RES=${GRIDRES_d01}
     export RES
   elif [ ${DOMAIN} == "d02" ]; then
     RES=${GRIDRES_d02}
     export RES
   elif [ ${DOMAIN} == "d03" ]; then
     RES=${GRIDRES_d03}
     export RES
   else
     ${ECHO} "ERROR: ${MET_CONFIG} not compatible with resolution."
     exit 1
   fi 

   # Specify new mask directory structure
   MASKS=${MET_CONFIG}/${RES}/masks
   export MASKS

   # Specify the MET Point-Stat configuration files to be used
   CONFIG_ADPUPA="${MET_CONFIG}/${RES}/PointStatConfig_ADPUPA"
   CONFIG_ADPSFC="${MET_CONFIG}/${RES}/PointStatConfig_ADPSFC"
   CONFIG_ADPSFC_MPR="${MET_CONFIG}/${RES}/PointStatConfig_ADPSFC_MPR"
   CONFIG_WINDS="${MET_CONFIG}/${RES}/PointStatConfig_WINDS"

   # Make sure the Point-Stat configuration files exists
   if [ ! -e ${CONFIG_ADPUPA} ]; then
       ${ECHO} "ERROR: ${CONFIG_ADPUPA} does not exist!"
       exit 1
   fi
   if [ ! -e ${CONFIG_ADPSFC} ]; then
       ${ECHO} "ERROR: ${CONFIG_ADPSFC} does not exist!"
       exit 1
   fi
   if [ ! -e ${CONFIG_ADPSFC_MPR} ]; then
       ${ECHO} "ERROR: ${CONFIG_ADPSFC_MPR} does not exist!"
       exit 1
   fi
   if [ ! -e ${CONFIG_WINDS} ]; then
       ${ECHO} "ERROR: ${CONFIG_WINDS} does not exist!"
       exit 1
   fi

   # Compute the verification date
   VDATE=`${UPP_EXE_ROOT}/ndate.exe +${FCST_TIME} ${START_TIME}`
   VYYYYMMDD=`${ECHO} ${VDATE} | ${CUT} -c1-8`
   VHH=`${ECHO} ${VDATE} | ${CUT} -c9-10`
   ${ECHO} 'valid time for ' ${FCST_TIME} 'h forecast = ' ${VDATE}

   # Get the forecast to verify
   FCST_FILE=${MOAD_DATAROOT}/postprd/wrfprs_${DOMAIN}_${FCST_TIME}.tm00

   if [ ! -e ${FCST_FILE} ]; then
     ${ECHO} "ERROR: Could not find UPP output file: ${FCST_FILE}"
     exit 1
   fi

   # Get the observation file
   OBS_FILE=`${LS} ${RAW_OBS}/${VYYYYMMDD}/prepbufr.gdas.${VYYYYMMDD}.t${VHH}z.nr | head -1`
   if [ ! -e ${OBS_FILE} ]; then
     ${ECHO} "ERROR: Could not find observation file: ${OBS_FILE}"
     exit 1
   fi

   # Convert prepbufr file to netcdf
   OUTFILE="${RAW_OBS}/${VYYYYMMDD}/prepbufr.gdas.${VYYYYMMDD}.t${VHH}z.nc"
   ${MET_EXE_ROOT}/pb2nc ${OBS_FILE} ${OUTFILE} ${MET_CONFIG}/27km/PB2NCConfig_RefConfig -v 2

   #######################################################################
   #
   #  Run Point-Stat
   #
   #######################################################################

   # Verify upper air variables only at 00Z and 12Z
   if [ "${VHH}" == "00" -o "${VHH}" == "12" ]; then
     CONFIG_FILE=${CONFIG_ADPUPA}
   
     /usr/bin/time ${MET_EXE_ROOT}/point_stat ${FCST_FILE} ${OUTFILE} ${CONFIG_FILE} \
       -outdir . -v 2

     error=$?
     if [ ${error} -ne 0 ]; then
       ${ECHO} "ERROR: For ${MODEL}, ${MET_EXE_ROOT}/point_stat ${CONFIG_FILE} crashed  Exit status: ${error}"
       exit ${error}
     fi
   fi
   
   # Verify surface variables for each forecast hour
   CONFIG_FILE=${CONFIG_ADPSFC}

   ${ECHO} "CALLING: ${MET_EXE_ROOT}/point_stat ${FCST_FILE} ${OUTFILE} ${CONFIG_FILE} -outdir . -v 2"

   /usr/bin/time ${MET_EXE_ROOT}/point_stat ${FCST_FILE} ${OUTFILE} ${CONFIG_FILE} \
      -outdir . -v 2

   error=$?
   if [ ${error} -ne 0 ]; then
     ${ECHO} "ERROR: For ${MODEL}, ${MET_EXE_ROOT}/point_stat ${CONFIG_FILE} crashed  Exit status: ${error}"
     exit ${error}
   fi

   # Verify surface variables for each forecast hour - MPR output
   CONFIG_FILE=${CONFIG_ADPSFC_MPR}

   ${ECHO} "CALLING: ${MET_EXE_ROOT}/point_stat ${FCST_FILE} ${OUTFILE} ${CONFIG_FILE} -outdir . -v 2"

   /usr/bin/time ${MET_EXE_ROOT}/point_stat ${FCST_FILE} ${OUTFILE} ${CONFIG_FILE} \
     -outdir . -v 2

   error=$?
   if [ ${error} -ne 0 ]; then
     ${ECHO} "ERROR: For ${MODEL}, ${MET_EXE_ROOT}/point_stat ${CONFIG_FILE} crashed  Exit status: ${error}"
     exit ${error}
   fi

   # Verify winds for each forecast hour
   CONFIG_FILE=${CONFIG_WINDS}

   ${ECHO} "CALLING: ${MET_EXE_ROOT}/point_stat ${FCST_FILE} ${OUTFILE} ${CONFIG_FILE} -outdir . -v 2"

   /usr/bin/time ${MET_EXE_ROOT}/point_stat ${FCST_FILE} ${OUTFILE} ${CONFIG_FILE} \
     -outdir . -v 2

   error=$?
   if [ ${error} -ne 0 ]; then
     ${ECHO} "ERROR: For ${MODEL}, ${MET_EXE_ROOT}/point_stat ${CONFIG_FILE} crashed  Exit status: ${error}"
     exit ${error}
   fi

done

##########################################################################

${ECHO} "${SCRIPT} completed at `${DATE}`"

exit 0

