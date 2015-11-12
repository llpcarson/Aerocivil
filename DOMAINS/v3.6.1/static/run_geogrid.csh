#!/bin/csh
#
# LSF batch script to run an MPI application
#
#BSUB -P P48503002          # project number
#BSUB -a poe                # select poe
#BSUB -W 0:10               # wall clock time (in minutes)
#BSUB -n 1                  # number of tasks
#BSUB -R "span[ptile=16]"   # run 64 tasks per node
#BSUB -J geogrid            # job name
#BSUB -o geogrid.out        # output filename
#BSUB -e geogrid.err        # error filename
#BSUB -q regular            # queue
#BSUB -x                    # exclusive use of node

mpirun.lsf ./geogrid.exe
exit
