#!/bin/ksh
pathnam=/glade/p/ral/jnt/Aerocivil/EXAMPLE_CASE
pathroc=/glade/p/ral/jnt/tools/rocoto
cycle=2015091800

pwd 
${pathroc}/bin/rocotostat -w ${pathnam}/xml/example_case_v3.6.1.xml -d ${pathnam}/OUTPUT/example_case_v3.6.1/store/example_case.store
