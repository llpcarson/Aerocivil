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
#Script Name: wrf_wps.ksh
# 
#     Author: Christopher Harrop
#             Forecast Systems Laboratory
#             325 Broadway R/FST
#             Boulder, CO. 80305
#
# Purpose: This is a complete rewrite of the run_wrf.pl script that is 
#          distributed with the WRF Standard Initialization.  This script 
#          may be run on the command line, or it may be submitted directly 
#          to a batch queueing system.  A few environment variables must be 
#          set before it is run:
#
#               WRF_ROOT = The full path of WRFV1 directory
#          MOAD_DATAROOT = Top level directory of wrf output
#          MOAD_DATAHOME = Top level directory of wrf configuration data
#            FCST_LENGTH = The length of the forecast in hours.  If not set,
#                          the default value of 48 is used.
#          FCST_INTERVAL = The interval, in hours, between each forecast.
#                          If not set, the default value of 3 is used.
#             START_TIME = The cycle time to use for the initial time. 
#                          If not set, the system clock is used.
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
#$ -pe ncomp 128
#$ -l h_rt=6:00:00
#$ -N wrf_wps
#$ -j y
#$ -V

# Make sure $SCRIPTS/constants.ksh exists
if [ ! -x "${CONSTANT}" ]; then
  ${ECHO} "ERROR: ${CONSTANT} does not exist or is not executable"
  exit 1
fi

# Read constants into the current shell
. ${CONSTANT}

# Set up some constants
if [ "${WRF_CORE}" ]; then
  if [ "${WRF_CORE}" == "ARW" ]; then
    WRF=${WRF_ROOT}/main/wrf.exe
  else
    ${ECHO} "ERROR: Unsupported WRF_CORE: ${WRF_CORE}"  
    exit 1
  fi
else
  WRF=${WRF_ROOT}/main/wrf.exe
fi

# Initialize an array of WRF input dat files that need to be linked
set -A WRF_DAT_FILES ${WRF_ROOT}/run/LANDUSE.TBL            \
                     ${WRF_ROOT}/run/RRTM_DATA              \
                     ${WRF_ROOT}/run/RRTMG_LW_DATA          \
                     ${WRF_ROOT}/run/RRTMG_SW_DATA          \
                     ${WRF_ROOT}/run/VEGPARM.TBL            \
                     ${WRF_ROOT}/run/GENPARM.TBL            \
                     ${WRF_ROOT}/run/SOILPARM.TBL           \
                     ${WRF_ROOT}/run/ETAMPNEW_DATA          \
                     ${WRF_ROOT}/run/tr49t85                \
                     ${WRF_ROOT}/run/tr49t67                \
                     ${WRF_ROOT}/run/tr67t85                \
                     ${WRF_ROOT}/run/gribmap.txt            \
                     ${WRF_ROOT}/run/ozone_plev.formatted   \
                     ${WRF_ROOT}/run/ozone_lat.formatted    \
                     ${WRF_ROOT}/run/ozone.formatted        \
                     ${WRF_ROOT}/run/aerosol.formatted      \
                     ${WRF_ROOT}/run/aerosol_lat.formatted  \
                     ${WRF_ROOT}/run/aerosol_lon.formatted  \
                     ${WRF_ROOT}/run/aerosol_plev.formatted \
                     ${WRF_ROOT}/run/co2_trans        
##                     ${MOAD_DATAROOT}/static/co2_trans
##                     ${WRF_ROOT}/run/eta_micro_lookup.dat 


# Check to make sure the wrf executable exists
if [ ! -x ${WRF} ]; then
  ${ECHO} "ERROR: ${WRF} does not exist, or is not executable"
  exit 1
fi

# Check to make sure the number of processors for running WRF was specified
if [ -z "${WRFPROC}" ]; then
  ${ECHO} "ERROR: The variable $WRFPROC must be set to contain the number of processors to run WRF"
  exit 1
fi

# Check to make sure that the MOAD_DATAHOME exists
if [ ! -d ${MOAD_DATAHOME} ]; then
  ${ECHO} "ERROR: ${MOAD_DATAHOME} does not exist"
  exit 1
fi

# Make sure the forecast length is defined
if [ ! ${FCST_LENGTH} ]; then
  ${ECHO} "ERROR: \$FCST_LENGTH is not defined!"
  exit 1
fi

# Make sure the forecast interval is defined
if [ ! ${FCST_INTERVAL} ]; then
  ${ECHO} "ERROR: \$FCST_INTERVAL is not defined!"
  exit 1
fi

# Make sure START_TIME is specified
if [ ! "${START_TIME}" ]; then
  ${ECHO} "ERROR: \$START_TIME is not defined"
  exit 1
fi

# Check to make sure WRF DAT files exist
for file in ${WRF_DAT_FILES[@]}; do
  if [ ! -s ${file} ]; then
    ${ECHO} "ERROR: ${file} either does not exist or is empty"
    exit 1
  fi
done

ANAL_TIME=$START_TIME

# Convert START_TIME from 'YYYYMMDDHH' format to Unix date format, e.g. "Fri May  6 19:50:23 GMT 2005"
if [ `${ECHO} "${START_TIME}" | ${AWK} '/^[[:digit:]]{10}$/'` ]; then
  START_TIME=`${ECHO} "${START_TIME}" | ${SED} 's/\([[:digit:]]\{2\}\)$/ \1/'`
else
  ${ECHO} "ERROR: start time, '${START_TIME}', is not in 'yyyymmddhh' or 'yyyymmdd hh' format"
  exit 1
fi
START_TIME=`${DATE} -d "${START_TIME}"`

# Get the end time string
END_TIME=`${DATE} -d "${START_TIME} ${FCST_LENGTH} hours"`

# Print run parameters
${ECHO}
${ECHO} "wrf.ksh started at `${DATE}`"
${ECHO}
${ECHO} "WRF_ROOT      = ${WRF_ROOT}"
${ECHO} "MOAD_DATAHOME = ${MOAD_DATAHOME}"
${ECHO} "MOAD_DATAROOT = ${MOAD_DATAROOT}"
${ECHO}
${ECHO} "FCST LENGTH   = ${FCST_LENGTH}"
${ECHO} "FCST INTERVAL = ${FCST_INTERVAL}"
${ECHO}
${ECHO} "START TIME = "`${DATE} +"%Y/%m/%d %H:%M:%S" -d "${START_TIME}"`
${ECHO} "  END TIME = "`${DATE} +"%Y/%m/%d %H:%M:%S" -d "${END_TIME}"`
${ECHO}

# Check to make sure the wrf_input file exists
if [ ! -r ${MOAD_DATAROOT}/wrfprd/wrfinput_d01 ]; then
  ${ECHO} "ERROR: ${MOAD_DATAROOT}/wrfprd/wrfinput_d01 does not exist, or is not readable"
  exit 1
fi
if [ ${MAX_DOM} -ge "2" ]; then
    if [ ! -r ${MOAD_DATAROOT}/wrfprd/wrfinput_d02 ]; then
	${ECHO} "ERROR: ${MOAD_DATAROOT}/wrfprd/wrfinput_d02 does not exist, or is not readable"
	exit 1
    fi
fi
if [ ${MAX_DOM} -ge "3" ]; then
    if [ ! -r ${MOAD_DATAROOT}/wrfprd/wrfinput_d03 ]; then
	${ECHO} "ERROR: ${MOAD_DATAROOT}/wrfprd/wrfinput_d03 does not exist, or is not readable"
	exit 1
    fi
fi

# Check to make sure the wrfbdy_d01 file exists
if [ ! -r ${MOAD_DATAROOT}/wrfprd/wrfbdy_d01 ]; then
  ${ECHO} "ERROR: ${MOAD_DATAROOT}/wrfprd/wrfbdy_d01 does not exist, or is not readable"
  exit 1
fi

# Set up the work directory and cd into it
workdir=${MOAD_DATAROOT}/wrfprd
${MKDIR} -p ${workdir}
cd ${workdir}

# Copy the wrf namelist to the static dir
${CP} ${MOAD_DATAHOME}/namelist.input .

# Make links to the WRF DAT files
for file in ${WRF_DAT_FILES[@]}; do
  ${RM} -f `basename ${file}`
  ${LN} -s ${file}
done

# Get the start and end time components
start_year=`${DATE} +%Y -d "${START_TIME}"`
start_month=`${DATE} +%m -d "${START_TIME}"`
start_day=`${DATE} +%d -d "${START_TIME}"`
start_hour=`${DATE} +%H -d "${START_TIME}"`
start_minute=`${DATE} +%M -d "${START_TIME}"`
start_second=`${DATE} +%S -d "${START_TIME}"`
end_year=`${DATE} +%Y -d "${END_TIME}"`
end_month=`${DATE} +%m -d "${END_TIME}"`
end_day=`${DATE} +%d -d "${END_TIME}"`
end_hour=`${DATE} +%H -d "${END_TIME}"`
end_minute=`${DATE} +%M -d "${END_TIME}"`
end_second=`${DATE} +%S -d "${END_TIME}"`

# Compute number of days and hours for the run
(( run_days = ${FCST_LENGTH} / 24 ))
(( run_hours = ${FCST_LENGTH} % 24 ))

# Create patterns for updating the wrf namelist
run=[Rr][Uu][Nn]
equal=[[:blank:]]*=[[:blank:]]*
start=[Ss][Tt][Aa][Rr][Tt]
end=[Ee][Nn][Dd]
year=[Yy][Ee][Aa][Rr]
month=[Mm][Oo][Nn][Tt][Hh]
day=[Dd][Aa][Yy]
hour=[Hh][Oo][Uu][Rr]
minute=[Mm][Ii][Nn][Uu][Tt][Ee]
second=[Ss][Ee][Cc][Oo][Nn][Dd]
interval=[Ii][Nn][Tt][Ee][Rr][Vv][Aa][Ll]
history=[Hh][Ii][Ss][Tt][Oo][Rr][Yy]

# Update the run_days in wrf namelist.input
${CAT} namelist.input | ${SED} "s/\(${run}_${day}[Ss]\)${equal}[[:digit:]]\{1,\}/\1 = ${run_days}/" \
   > namelist.input.new
${MV} namelist.input.new namelist.input

# Update the run_hours in wrf namelist
${CAT} namelist.input | ${SED} "s/\(${run}_${hour}[Ss]\)${equal}[[:digit:]]\{1,\}/\1 = ${run_hours}/" \
   > namelist.input.new
${MV} namelist.input.new namelist.input

# Update the start time in wrf namelist (for three domains)
${CAT} namelist.input | ${SED} "s/\(${start}_${year}\)${equal}[[:digit:]]\{4\},[[:blank:]]*[[:digit:]]\{4\},/\1 = ${start_year}, ${start_year}, ${start_year},/" \
   | ${SED} "s/\(${start}_${month}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_month}, ${start_month}, ${start_month},/"                   \
   | ${SED} "s/\(${start}_${day}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_day}, ${start_day}, ${start_day},/"                       \
   | ${SED} "s/\(${start}_${hour}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_hour}, ${start_hour}, ${start_hour},/"                     \
   | ${SED} "s/\(${start}_${minute}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_minute}, ${start_minute}, ${start_minute},/"                 \
   | ${SED} "s/\(${start}_${second}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_second}, ${start_second}, ${start_second},/"                 \
   > namelist.input.new
${MV} namelist.input.new namelist.input

# Update end time in namelist (for three domains)
${CAT} namelist.input | ${SED} "s/\(${end}_${year}\)${equal}[[:digit:]]\{4\},[[:blank:]]*[[:digit:]]\{4\},/\1 = ${end_year}, ${end_year}, ${end_year},/" \
   | ${SED} "s/\(${end}_${month}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${end_month}, ${end_month}, ${end_month},/"                   \
   | ${SED} "s/\(${end}_${day}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${end_day}, ${end_day}, ${end_day},/"                       \
   | ${SED} "s/\(${end}_${hour}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${end_hour}, ${end_hour}, ${end_hour},/"                     \
   | ${SED} "s/\(${end}_${minute}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${end_minute}, ${end_minute}, ${end_minute},/"                 \
   | ${SED} "s/\(${end}_${second}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${end_second}, ${end_second}, ${end_second},/"                 \
   > namelist.input.new
${MV} namelist.input.new namelist.input

# Update interval in namelist
(( fcst_interval_sec = ${FCST_INTERVAL} * 3600 ))
${CAT} namelist.input | ${SED} "s/\(${interval}${second}[Ss]\)${equal}[[:digit:]]\{1,\}/\1 = ${fcst_interval_sec}/" \
   > namelist.input.new 
${MV} namelist.input.new namelist.input

if [ "${WRITE_INPUT}" ]; then
${CAT} namelist.input | ${SED} "s/\(write_input\)${equal}.false./\1 = .true./" \
   > namelist.input.new
${MV} namelist.input.new namelist.input
(( history_begin_h = ${FCST_INTERVAL} + 1))
${CAT} namelist.input | ${SED} "s/\(history_begin_h\)${equal}[[:digit:]]\{1,\}/\1 = ${history_begin_h}/" \
   > namelist.input.new
${MV} namelist.input.new namelist.input
fi

# Move existing rsl files to a subdir if there are any
${ECHO} "Checking for pre-existing rsl files"
if [ -f "rsl.out.0000" ]; then
  rsldir=rsl.`${LS} -l --time-style=+%Y%m%d%H%M%S rsl.out.0000 | ${CUT} -d" " -f 7`
  ${MKDIR} ${rsldir}
  ${ECHO} "Moving pre-existing rsl files to ${rsldir}"
  ${MV} rsl.out.* ${rsldir}
  ${MV} rsl.error.* ${rsldir}
else
  ${ECHO} "No pre-existing rsl files were found"
fi

# Get the current time
now=`${DATE} +%Y%m%d%H%M%S`

# Run wrf
export TARGET_CPU_LIST=-1
${MPIRUN} ${WRF}
#${MPIRUN} /usr/local/bin/launch ${WRF}
#${MPIRUN} ${WRF}

error=$?

# Save a copy of the RSL files
rsldir=rsl.wrf.${now}
${MKDIR} ${rsldir}
mv rsl.out.* ${rsldir}
mv rsl.error.* ${rsldir}

# Look for successful completion messages in rsl files
nsuccess=`${CAT} ${rsldir}/rsl.* | ${AWK} '/SUCCESS COMPLETE WRF/' | ${WC} -l`
(( ntotal=WRFPROC * 2 ))
${ECHO} "Found ${nsuccess} of ${ntotal} completion messages"
if [ ${nsuccess} -ne ${ntotal} ]; then
  ${ECHO} "ERROR: ${WRF} did not complete sucessfully"
  if [ ${error} -ne 0 ]; then
    ${MPIRUN} ${EXIT_CALL} ${error}
    exit
  else
    ${MPIRUN} ${EXIT_CALL} 1
    exit
  fi
fi

# Check to see if all the expected output is there:
fcst=0
while [ ${fcst} -le ${FCST_LENGTH} ]; do
  datestr=`${DATE} +%Y-%m-%d_%H:%M:%S -d "${START_TIME} ${fcst} hours"`
  if [ ! -s "wrfout_d01_${datestr}" ]; then
    ${ECHO} "${WRF} failed to complete.  wrfout_d01_${datestr} is missing or empty!"
    ${MPIRUN} ${EXIT_CALL} 1
    exit
  fi
  if [ ${MAX_DOM} == 2 ]; then
      if [ ! -s "wrfout_d02_${datestr}" ]; then
	  ${ECHO} "${WRF} failed to complete.  wrfout_d02_${datestr} is missing or empty!"
	  ${MPIRUN} ${EXIT_CALL} 1
	  exit
      fi
  fi
  if [ ${MAX_DOM} == 3 ]; then
      if [ ! -s "wrfout_d03_${datestr}" ]; then
	  ${ECHO} "${WRF} failed to complete.  wrfout_d03_${datestr} is missing or empty!"
	  ${MPIRUN} ${EXIT_CALL} 1
	  exit
      fi
  fi
  (( fcst = fcst + ${FCST_INTERVAL} ))
done

${ECHO} "wrf.ksh completed successfully at `${DATE}`"
