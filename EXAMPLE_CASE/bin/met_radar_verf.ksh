#!/bin/ksh -l

##########################################################################
#
# Script Name: met_radar_verf_all.ksh
#
#      Author: John Halley Gotway
#              NCAR/RAL/DTC
#
#    Released: 10/26/2010
#
# Description:
#    This script runs the MET/Grid-Stat and MODE tools to verify gridded
#    precipitation forecasts against gridded precipitation analyses.
#    The precipitation fields must first be placed on a common grid prior
#    to running this script.
#
#             START_TIME = The cycle time to use for the initial time.
#         FCST_TIME_LIST = The three-digit forecasts that is to be verified.
#             ACCUM_TIME = The two-digit accumulation time: 03 or 24.
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
#$ -N met_qpf_verf
#$ -j y
#$ -V
#$ -cwd

# Name of this script
SCRIPT=met_radar_verf.ksh

# Set path for manual testing of script
#export CONSTANT=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE/bin/12km_3km_WRF_constants.ksh

# Make sure $SCRIPTS/constants.ksh exists
if [ ! -x "${CONSTANT}" ]; then
  ${ECHO} "ERROR: ${CONSTANT} does not exist or is not executable"
  exit 1
fi

# Read constants into the current shell
. ${CONSTANT}

# Vars used for manual testing of the script
#export START_TIME=2013072912
#export FCST_TIME_LIST="03 06 09 12 15 18 21 24 27 30 33 36 39 42 45 48 51 54 57 60 63 66 69 72 75 78 81 84" 
#export DOMAIN_LIST="d02"
#export MET_EXE_ROOT=/glade/p/ral/jnt/Aerocivil/CODE/MET/v5.1_beta/met-5.1beta1/bin
#export MET_CONFIG=/glade/p/ral/jnt/Aerocivil/DOMAINS/v3.6.1/met_config
#export UPP_EXE_ROOT=/glade/p/ral/jnt/Aerocivil/CODE/UPP/v3.0/UPPV3.0/bin
#export MOAD_DATAROOT=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE/OUTPUT/RAPps_12km_3km_v3.6.1/DOMAINS/2013072912
#export RAW_OBS=/glade/p/ral/jnt/Aerocivil/OBS/RADAR_MOSAIC
#export MODEL=RAPps
#export CORE=ARW

# Specify Experiment name
#PLLN=rrtmg
#typeset -L8 pll3
#pll3=RRTMG
#PLL3=RRTMG

# Print run parameters
${ECHO}
${ECHO} "${SCRIPT} started at `${DATE}`"
${ECHO}
${ECHO} "    START_TIME = ${START_TIME}"
${ECHO} "FCST_TIME_LIST = ${FCST_TIME_LIST}"
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
${ECHO} "MODEL=${MODEL}"
${ECHO} "VERSION=${VERSION}"

# Loop through the forecast times
for FCST_TIME in ${FCST_TIME_LIST}; do

   export FCST_TIME

   # Loop through the domain list
   for DOMAIN in ${DOMAIN_LIST}; do
   
      export DOMAIN
      ${ECHO} "DOMAIN=${DOMAIN}"
      ${ECHO} "FCST_TIME=${FCST_TIME}"

      if [ ${DOMAIN} == "d01" ]; then
        export RES=${GRIDRES_d01}
	export RGD=${GRIDSPEC_d01_RGD}
      elif [ ${DOMAIN} == "d02" ]; then
        export RES=${GRIDRES_d02}
	export RGD=${GRIDSPEC_d02_RGD}
	${ECHO} ${RGD}
      else
        ${ECHO} "ERROR: ${OBS_FILE} not compatible with resolution."
        exit 1
      fi 

      # Specify mask directory structure
      MASKS=${MET_CONFIG}/${RES}/masks
      export MASKS

      # Specify the MET Grid-Stat and MODE configuration files to be used
      GS_CONFIG_LIST="${MET_CONFIG}/${RES}/GridStatConfig_REFC_NBR"
      MD_CONFIG_LIST=""

      # Compute the verification date
      VDATE=`${UPP_EXE_ROOT}/ndate.exe +${FCST_TIME} ${START_TIME}`
      VYYYYMMDD=`${ECHO} ${VDATE} | ${CUT} -c1-8`
      VHH=`${ECHO} ${VDATE} | ${CUT} -c9-10`
      ${ECHO} 'valid time for ' ${FCST_TIME} 'h forecast = ' ${VDATE}

      # Get the forecast to verify
      if [ ${CORE} == "NMB" ]; then
        FCST_FILE=${MOAD_DATAROOT}/postprd/nmbprs_${DOMAIN}_${FCST_TIME}.tm00
      else
        FCST_FILE=${MOAD_DATAROOT}/postprd/wrfprs_${DOMAIN}_${FCST_TIME}.tm00
      fi

      if [ ! -e ${FCST_FILE} ]; then
        ${ECHO} "ERROR: Could not find UPP output file: ${FCST_FILE}"
        exit 1
      fi
      
      # Get the observation file
      if [[ ${DOMAIN} == "d01" ]]; then
	  OBS_FILE=${RAW_OBS}/RADAR_MOSAIC/${RES}/${VYYYYMMDD}/refd3d.t${VHH}z.${RES}.grb
      elif [[ ${DOMAIN} == "d02" ]]; then
	  OBS_FILE=${RAW_OBS}/NATIVE/radar_mosaic/${VYYYYMMDD}/grib/refd3d.t${VHH}z.grbf00
      elif [ ! -e ${OBS_FILE} ]; then
        ${ECHO} "ERROR: Could not find observation file: ${OBS_FILE}"
        exit 1
      fi

      #######################################################################
      #
      #  Run Grid-Stat
      #
      #######################################################################

      for CONFIG_FILE in ${GS_CONFIG_LIST}; do

        # Make sure the Grid-Stat configuration file exists
        if [ ! -e ${CONFIG_FILE} ]; then
          ${ECHO} "ERROR: ${CONFIG_FILE} does not exist!"
          exit 1
        fi

        ${ECHO} "CALLING: ${MET_EXE_ROOT}/grid_stat ${FCST_FILE} ${OBS_FILE} ${CONFIG_FILE} -outdir . -v 2"

        ${MET_EXE_ROOT}/grid_stat \
          ${FCST_FILE} \
          ${OBS_FILE} \
          ${CONFIG_FILE} \
          -outdir . \
          -v 2

        error=$?
        if [ ${error} -ne 0 ]; then
          ${ECHO} "ERROR: For ${MODEL}, ${MET_EXE_ROOT}/grid_stat crashed  Exit status: ${error}"
        exit ${error}
        fi

      done

      #######################################################################
      #
      #  Run MODE
      #
      #######################################################################

      for CONFIG_FILE in ${MD_CONFIG_LIST}; do

        # Make sure the MODE configuration file exists
        if [ ! -e ${CONFIG_FILE} ]; then
          ${ECHO} "ERROR: ${CONFIG_FILE} does not exist!"
          exit 1
        fi

        ${ECHO} "CALLING: ${MET_EXE_ROOT}/mode ${FCST_FILE} ${OBS_FILE} ${CONFIG_FILE} -outdir . -obj_plot -v 2"

        ${MET_EXE_ROOT}/mode \
          ${FCST_FILE} \
          ${OBS_FILE} \
          ${CONFIG_FILE} \
          -outdir . \
          -obj_plot \
          -v 2

        error=$?
        if [ ${error} -ne 0 ]; then
          ${ECHO} "ERROR: For ${MODEL}, ${MET_EXE_ROOT}/mode crashed  Exit status: ${error}"
        exit ${error}
        fi

      done
   done
done

##########################################################################

${ECHO} "${SCRIPT} completed at `${DATE}`"

exit 0
