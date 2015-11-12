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
#Script Name: real_wps.ksh
# 
#     Author: Christopher Harrop
#             Forecast Systems Laboratory
#             325 Broadway R/FST
#             Boulder, CO. 80305
#
# Purpose: This is a complete rewrite of the real portion of the 
#          wrfprep.pl script that is distributed with the WRF Standard 
#          Initialization.  This script may be run on the command line, or 
#          it may be submitted directly to a batch queueing system.  
#
##########################################################################
#          REQUIRED Environment variables:
##########################################################################
#
#               WRF_ROOT = The full path of WRFV2 directory
#               WRF_CORE = The core to run (e.g. ARW or NMM)
#          MOAD_DATAHOME = Top level directory of wrf domain data
#          MOAD_DATAROOT = Top level directory of wrf output
#            FCST_LENGTH = The length of the forecast in hours.
#          FCST_INTERVAL = The interval, in hours, between each forecast.
#             START_TIME = The cycle time to use for the initial time.
#              REAL_PROC = The number of processors to run real with
#
##########################################################################
#          OPTIONAL Environment variables:
##########################################################################
#
#         INPUT_DATAROOT = Top level directory containing wpsprd directory
#                          which contains the input files
#                          (If not set, $MOAD_DATAROOT is used)
#           INPUT_FORMAT = NETCDF or BINARY (If not set, NETCDF is assumed)
# 
##########################################################################
#           OPTIONAL Environment variables that relate to cycling:
##########################################################################
#
#            CYCLE_FCSTS = List of previous forecast lengths allowed for 
#                          cycling (e.g. "01 02 03 04 05 06").  The version
#                          of real that is used must support cycling if this
#                          is set!  Defining this variable turns cycling 
#                          mode on
#         WRF_CYCLE_ROOT = The full path of WRFV2 directory for a version
#                          of WRF that supports cycling.  Ignored if
#                          CYCLE_FCSTS is not defined, but REQUIRED if
#                          CYCLE_FCSTS is defined. Can be equal to
#                          WRF_ROOT if the same code supports non-cycling
#                          and cycling modes both.
#      MOAD_DATAHOME_ALT = Alternate MOAD_DATAHOME in which to look for
#                          previous forecasts if one is not found in the
#                          MOAD_DATAHOME.
#               PREPBUFR = Path of the prepbufr obs files used in cycling
#
##########################################################################
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
#$ -pe wcomp 1
#$ -l h_rt=6:00:00
#$ -N real
#$ -j y
#$ -V

# Make sure $SCRIPTS/constants.ksh exists
if [ ! -x "${CONSTANT}" ]; then
  ${ECHO} "ERROR: ${CONSTANT} does not exist or is not executable"
  exit 1
fi

# Read constants into the current shell
. ${CONSTANT}

# Make sure WRF_ROOT is set and that it exists
if [ ! "${WRF_ROOT}" ]; then
  ${ECHO} "ERROR: \$WRF_ROOT is not defined"
  exit 1
fi
if [ ! -d "${WRF_ROOT}" ]; then
  ${ECHO} "ERROR: WRF_ROOT directory, '${WRF_ROOT}', does not exist"
  exit 1
fi

# If CYCLE_FCSTS is set, make sure WRF_CYCLE_ROOT is defined and that it exists
if [ "${CYCLE_FCSTS}" ]; then
  if [ ! "${WRF_CYCLE_ROOT}" ]; then
    ${ECHO} "ERROR: Cycling is enabled, but \$WRF_CYCLE_ROOT is not defined"
    exit 1
  fi
  if [ ! -d ${WRF_CYCLE_ROOT} ]; then
    ${ECHO} "ERROR: WRF_CYCLE_ROOT directory, '${WRF_CYCLE_ROOT}', does not exist"
    exit 1
  fi
fi

# Make sure that WRF_CORE is set to a valid value, and set some core dependent vars
if [ ! "${WRF_CORE}" ]; then
  ${ECHO} "ERROR: \$WRF_CORE is not defined"
  exit 1
elif [ "${WRF_CORE}" == "ARW" ]; then
  REAL_NOCYCLE=${WRF_ROOT}/main/real.exe
  REAL_CYCLE=${WRF_CYCLE_ROOT}/main/real.exe
  real_prefix="met_em"
else
  ${ECHO} "ERROR: Unsupported WRF CORE, '${WRF_CORE}'"
  exit 1
fi

# Make sure the real executable exists
if [ ! -x ${REAL_NOCYCLE} ]; then
  ${ECHO} "ERROR: real executable, '${REAL_NOCYCLE}', does not exist, or is not executable"
  exit 1
fi
if [ "${CYCLE_FCSTS}" ]; then
  if [ ! -x ${REAL_CYCLE} ]; then
    ${ECHO} "ERROR: real executable, '${REAL_CYCLE}', does not exist, or is not executable"
    exit 1
  fi
fi

# Default to the non-cycling version of the executable
# We will modify it later if cycling is turned on
REAL=${REAL_NOCYCLE}

# Make sure that the MOAD_DATAHOME is defined and that it exists
if [ ! "${MOAD_DATAHOME}" ]; then
  ${ECHO} "ERROR: \$MOAD_DATAHOME is not defined"
  exit 1
fi
if [ ! -d "${MOAD_DATAHOME}" ]; then
  ${ECHO} "ERROR: MOAD_DATAHOME directory, '${MOAD_DATAHOME}', does not exist"
  exit 1
fi

# Make sure the MOAD_DATAROOT is defined (it doesn't need to exist yet)
if [ ! "${MOAD_DATAROOT}" ]; then
  ${ECHO} "ERROR: \$MOAD_DATAROOT is not defined"
  exit 1
fi

# If $INPUT_DATAROOT is not set, then make sure MOAD_DATAROOT directory exists
if [ ! "${INPUT_DATAROOT}" ]; then
  INPUT_DATAROOT=${MOAD_DATAROOT}
else
  if [ ! -d "${INPUT_DATAROOT}" ]; then
    ${ECHO} "ERROR: INPUT_DATAROOT directory, '${INPUT_DATAROOT}', does not exist"
    exit 1
  fi
fi
if [ ! -d "${MOAD_DATAROOT}" ]; then
  ${MKDIR} -p ${MOAD_DATAROOT}
fi

# Set the input format
if [ ! "${INPUT_FORMAT}" ]; then
  INPUT_FORMAT=NETCDF
fi
if [ "${INPUT_FORMAT}" == "NETCDF" ]; then
  real_suffix=".nc"
elif [ "${INPUT_FORMAT}" == "BINARY" ]; then :
  real_suffix=""
else
  ${ECHO} "ERROR: Unsupported INPUT_FORMAT, '${INPUT_FORMAT}'"
  exit 1
fi

if [ ! "${START_TIME}" ]; then
  ${ECHO} "ERROR: \$START_TIME is not defined!"
  exit 1
fi

# Make sure the FCST_LENGTH is defined
if [ ! "${FCST_LENGTH}" ]; then
  ${ECHO} "ERROR: \$FCST_LENGTH is not defined"
  exit 1
fi

# Make sure the FCST_INTERVAL is defined
if [ ! "${FCST_INTERVAL}" ]; then
  ${ECHO} "ERROR: \$FCST_INTERVAL is not defined"
  exit 1
fi

# Make sure the max domain is defined
if [ ! ${MAX_DOM} ]; then
  ${ECHO} "ERROR: \$MAX_DOM is not defined!"
  exit 1
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

# Check to make sure WRF DAT files exist
for file in ${WRF_DAT_FILES[@]}; do
  if [ ! -s ${file} ]; then
    ${ECHO} "ERROR: ${file} either does not exist or is empty"
    exit 1
  fi
done

# Make sure START_TIME is defined and in the correct format
if [ `${ECHO} "${START_TIME}" | ${AWK} '/^[[:digit:]]{10}$/'` ]; then
  START_TIME=`${ECHO} "${START_TIME}" | ${SED} 's/\([[:digit:]]\{2\}\)$/ \1/'`
else
  ${ECHO} "ERROR: start time, '${START_TIME}', is not in 'yyyymmddhh' or 'yyyymmdd hh' format"
  exit 1
fi
START_TIME=`${DATE} -d "${START_TIME}"`

# Calculate the forecast end time
END_TIME=`${DATE} -d "${START_TIME} ${FCST_LENGTH} hours"`

# Print run parameters
${ECHO}
${ECHO} "real.ksh started at `${DATE}`"
${ECHO}
${ECHO} "WRF_ROOT       = ${WRF_ROOT}"
${ECHO} "WRF_CORE       = ${WRF_CORE}"
${ECHO}
${ECHO} "MOAD_DATAHOME  = ${MOAD_DATAHOME}"
${ECHO} "MOAD_DATAROOT  = ${MOAD_DATAROOT}"
${ECHO}
${ECHO} "INPUT_DATAROOT = ${INPUT_DATAROOT}"
${ECHO} "INPUT_FORMAT   = ${INPUT_FORMAT}"
${ECHO}
${ECHO} "FCST_LENGTH    = ${FCST_LENGTH}"
${ECHO} "FCST_INTERVAL  = ${FCST_INTERVAL}"
${ECHO}
${ECHO} "MAX_DOM        = ${MAX_DOM}"
${ECHO}
${ECHO} "CYCLING        = ${CYCLING}"
${ECHO}
${ECHO} "START_TIME     = "`${DATE} +"%Y/%m/%d %H:%M:%S" -d "${START_TIME}"`
${ECHO} "END_TIME       = "`${DATE} +"%Y/%m/%d %H:%M:%S" -d "${END_TIME}"`
${ECHO}
if [ "${CYCLE_FCSTS}" ]; then
  ${ECHO} "CYCLE_FCSTS       = ${CYCLE_FCSTS}"
  ${ECHO} "WRF_CYCLE_ROOT    = ${WRF_CYCLE_ROOT}"
  ${ECHO} "MOAD_DATAHOME_ALT = ${MOAD_DATAHOME_ALT}"
  ${ECHO}
fi

# Check to make sure the work directory (wrfprd) exists and cd into it
workdir=${MOAD_DATAROOT}/wrfprd
${MKDIR} -p ${workdir}
cd ${workdir}

# Remove ic/bc in the directory
if [ -s "wrfinput_d01" ]; then
  ${RM} wrfinput_d01
fi
if [ -s "wrfinput_d02" ]; then
  ${RM} wrfinput_d02
fi
if [ -s "wrfinput_d03" ]; then
  ${RM} wrfinput_d03
fi
if [ -s "wrfbdy_d01" ]; then
  ${RM} wrfbdy_d01
fi

# Check to make sure the real input files (e.g. met_em.d01.*) are available
# and make links to them
fcst=0
while [ ${fcst} -le ${FCST_LENGTH} ]; do
  time_str=`${DATE} "+%Y-%m-%d_%H:%M:%S" -d "${START_TIME} ${fcst} hours"`
  if [ ! -r "${INPUT_DATAROOT}/wpsprd/${real_prefix}.d01.${time_str}${real_suffix}" ]; then
    echo "ERROR: Input file '${INPUT_DATAROOT}/wpsprd/${real_prefix}.d01.${time_str}${real_suffix}' is missing"
    exit 1
  fi
  if [ ${MAX_DOM} -ge 2 ]; then
      if [ ! -r "${INPUT_DATAROOT}/wpsprd/${real_prefix}.d02.${time_str}${real_suffix}" ]; then
	  echo "ERROR: Input file '${INPUT_DATAROOT}/wpsprd/${real_prefix}.d02.${time_str}${real_suffix}' is missing"
	  exit 1
      fi
  fi
  if [ ${MAX_DOM} -ge 3 ]; then
      if [ ! -r "${INPUT_DATAROOT}/wpsprd/${real_prefix}.d03.${time_str}${real_suffix}" ]; then
	  echo "ERROR: Input file '${INPUT_DATAROOT}/wpsprd/${real_prefix}.d03.${time_str}${real_suffix}' is missing"
	  exit 1
      fi
  fi
  ${RM} -f ${real_prefix}.d0*.${time_str}${real_suffix}
  ${LN} -s ${INPUT_DATAROOT}/wpsprd/${real_prefix}.d01.${time_str}${real_suffix}
  if [ ${MAX_DOM} -ge 2 ]; then
      ${LN} -s ${INPUT_DATAROOT}/wpsprd/${real_prefix}.d02.${time_str}${real_suffix}
  fi
  if [ ${MAX_DOM} -ge 3 ]; then
      ${LN} -s ${INPUT_DATAROOT}/wpsprd/${real_prefix}.d03.${time_str}${real_suffix}
  fi
  (( fcst = fcst + ${FCST_INTERVAL} ))
done

#***************************************************
#*** Start of code specific to cycling           ***
#*** Will run only if $CYCLE_FCSTS is set.       ***
#*** No need to comment out, even if your        ***
#*** application does not use cycling.           ***
#***************************************************

# Look for the prepbufr file to make sure there are obs to cycle with
if [ "${CYCLE_FCSTS}" ]; then

  prepbufr_file=`${DATE} +"%Y%j%H00.ruc2a.t%Hz.prepbufr.tm00.%Y%m%d" -d "${START_TIME}"`

  # If the prepbufr file exists, link to the most recent previous forecast
  if [ -r "${PREPBUFR}/${prepbufr_file}" ]; then

    wrfout1=wrfout_d01_`${DATE} +"%Y-%m-%d_%H:%M:%S" -d "${START_TIME}"`
    wrfout2=wrfout.d01.`${DATE} +"%Y-%m-%d_%H:%M:%S" -d "${START_TIME}"`
    ${RM} -f ${wrfout1} ${wrfout2}
    found=0
    for fcst in ${CYCLE_FCSTS}; do

      # First look for it in MOAD_DATAHOME
      ${ECHO} -n "Looking for a previous ${fcst}hr forecast in ${MOAD_DATAHOME}...   "
      fcst_file1=${MOAD_DATAHOME}/`${DATE} +"%Y%m%d%H" -d "${START_TIME} ${fcst} hours ago"`/wrfprd/${wrfout1}
      fcst_file2=${MOAD_DATAHOME}/`${DATE} +"%Y%m%d%H" -d "${START_TIME} ${fcst} hours ago"`/wrfprd/${wrfout2}
      if [ -r ${fcst_file1} ]; then
        ${LN} -s ${fcst_file1} ${wrfout2}
        ${ECHO} "Found"
        found=1
        break
      elif [ -r ${fcst_file2} ]; then
        ${LN} -s ${fcst_file2} ${wrfout2}
        ${ECHO} "Found"
        found=1
        break
      else
        ${ECHO} "Not found"
      fi

      # If not found, look for it in MOAD_DATAHOME_ALT if it is defined
      if [ "${MOAD_DATAHOME_ALT}" ]; then
        ${ECHO} -n "Looking for a previous ${fcst}hr forecast in ${MOAD_DATAHOME_ALT}...   "
        fcst_file1=${MOAD_DATAHOME_ALT}/`${DATE} +"%Y%m%d%H" -d "${START_TIME} ${fcst} hours ago"`/wrfprd/${wrfout1}
        fcst_file2=${MOAD_DATAHOME_ALT}/`${DATE} +"%Y%m%d%H" -d "${START_TIME} ${fcst} hours ago"`/wrfprd/${wrfout2}
        if [ -r ${fcst_file1} ]; then
          ${LN} -s ${fcst_file1} ${wrfout2}
          ${ECHO} "Found"
          found=1
          break
      elif [ -r ${fcst_file2} ]; then
        ${LN} -s ${fcst_file2} ${wrfout2}
        ${ECHO} "Found"
        found=1
        break
      else
          ${ECHO} "Not found"
        fi
      fi

    done

    if [ ${found} -eq 0 ]; then
      ${ECHO} "************************************************************************"
      ${ECHO} "* WARNING!  Did not find a previous forecast.  Performing a COLD START *"
      ${ECHO} "************************************************************************"
    else
      # Set the executable to the cycling version since we found a previous forecast
      REAL=${REAL_CYCLE}
    fi

  else
    ${ECHO} "************************************************************************"
    ${ECHO} "* WARNING!  Did not find a prepbufr file.  Performing a COLD START *"
    ${ECHO} "************************************************************************"
  fi

fi

#***************************************
#*** End of code specific to cycling ***
#***************************************


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

# Copy the wrf namelist to the workdir as namelist.input
${CP} ${MOAD_DATAHOME}/namelist.input .

# Update the run_days in wrf namelist.input
${CAT} namelist.input | ${SED} "s/\(${run}_${day}[Ss]\)${equal}[[:digit:]]\{1,\}/\1 = ${run_days}/" \
   > namelist.input.new
${MV} namelist.input.new namelist.input

# Update the run_hours in wrf namelist
${CAT} namelist.input | ${SED} "s/\(${run}_${hour}[Ss]\)${equal}[[:digit:]]\{1,\}/\1 = ${run_hours}/" \
   > namelist.input.new
${MV} namelist.input.new namelist.input


# Update the start time in wrf namelist
${CAT} namelist.input | ${SED} "s/\(${start}_${year}\)${equal}[[:digit:]]\{4\},[[:blank:]]*[[:digit:]]\{4\},/\1 = ${start_year}, ${start_year}, ${start_year},/" \
   | ${SED} "s/\(${start}_${month}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_month}, ${start_month}, ${start_month},/"                   \
   | ${SED} "s/\(${start}_${day}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_day}, ${start_day}, ${start_day},/"                       \
   | ${SED} "s/\(${start}_${hour}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_hour}, ${start_hour}, ${start_hour},/"                     \
   | ${SED} "s/\(${start}_${minute}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_minute}, ${start_minute}, ${start_minute},/"                 \
   | ${SED} "s/\(${start}_${second}\)${equal}[[:digit:]]\{2\},[[:blank:]]*[[:digit:]]\{2\},/\1 = ${start_second}, ${start_second}, ${start_second},/"                 \
   > namelist.input.new
${MV} namelist.input.new namelist.input

# Update end time in namelist
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

# Update the max_dom depending on what domains running GSI over
${CAT} namelist.input | ${SED} "s/\(max_dom\)${equal}[[:digit:]]\{1,\}/\1 = ${MAX_DOM}/" \
   > namelist.input.new
${MV} namelist.input.new namelist.input

# Update cycling depending on whether running GSI 
if [ ${CYCLING} == "FALSE" ]; then
  ${CAT} namelist.input | ${SED} "s/\(cycling\)${equal}.true./\1 = .false./" \
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

# Run real
export TARGET_CPU_LIST=-1
${MPIRUN} ${REAL}
#${MPIRUN} /usr/local/bin/launch ${REAL}
#${MPIRUN} ${REAL}

error=$?

# Save a copy of the RSL files
rsldir=rsl.real.${now}
${MKDIR} ${rsldir}
mv rsl.out.* ${rsldir}
mv rsl.error.* ${rsldir}

# Look for successful completion messages in rsl files
nsuccess=`${CAT} ${rsldir}/rsl.* | ${AWK} '/SUCCESS COMPLETE REAL/' | ${WC} -l`
(( ntotal=REAL_PROC * 2 ))
${ECHO} "Found ${nsuccess} of ${ntotal} completion messages"
if [ ${nsuccess} -ne ${ntotal} ]; then
  ${ECHO} "ERROR: ${REAL} did not complete sucessfully  Exit status=${error}"
  if [ ${error} -ne 0 ]; then
    ${MPIRUN} ${EXIT_CALL} ${error}
    exit
  else
    ${MPIRUN} ${EXIT_CALL} 1
    exit
  fi
fi

# Check to see if the output is there:
if [[ ${MAX_DOM} == "1" ]]; then
  if [ ! -s "wrfbdy_d01" -o ! -s "wrfinput_d01" ]; then
    ${ECHO} "${REAL} failed to complete"
    ${MPIRUN} ${EXIT_CALL} 1
    exit
  fi
elif [[ ${MAX_DOM} == "2" ]]; then
  if [ ! -s "wrfbdy_d01" -o ! -s "wrfinput_d01" -o ! -s "wrfinput_d02" ]; then
    ${ECHO} "${REAL} failed to complete"
    ${MPIRUN} ${EXIT_CALL} 1
    exit
  fi
elif [[ ${MAX_DOM} == "3" ]]; then
  if [ ! -s "wrfbdy_d01" -o ! -s "wrfinput_d01" -o ! -s "wrfinput_d02" -o ! -s "wrfinput_d03" ]; then
    ${ECHO} "${REAL} failed to complete"
    ${MPIRUN} ${EXIT_CALL} 1
    exit
  fi
fi

${ECHO} "real_wps.ksh completed successfully at `${DATE}`"

