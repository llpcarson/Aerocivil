#!/bin/ksh -l

# Set the SGE queueing options
#$ -S /bin/ksh
#$ -pe ncomp 1
#$ -l h_rt=6:00:00
#$ -N done
#$ -j y
#$ -V

# Make sure $SCRIPTS/constants.ksh exists
if [ ! -x "${CONSTANT}" ]; then
  ${ECHO} "ERROR: ${CONSTANT} does not exist or is not executable"
  exit 1
fi

# Read constants into the current shell
. ${CONSTANT}

if [ ! "${MOAD_DATAROOT}" ]; then
  ${ECHO} "ERROR: MOAD_DATAROOT was not set"
  exit 1
fi
if [ ! -d ${MOAD_DATAROOT} ]; then
  ${ECHO} "ERROR: MOAD_DATAROOT, ${MOAD_DATAROOT}, does not exist"
  exit 1
fi

dirname=`${DIRNAME} ${MOAD_DATAROOT}`
basename=`${BASENAME} ${MOAD_DATAROOT}`
${TOUCH} "${dirname}/.${basename}.done"
error=$?
if [ ${error} -ne 0 ]; then
  ${ECHO} "ERROR: ${TOUCH} ${MOAD_DATAROOT}.done failed!"
  exit 1
fi
