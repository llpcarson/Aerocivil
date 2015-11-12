#!/usr/bin/perl

################################################################################
#
# Script Name: copygb_budget_nn.pl
#
#      Author: John Halley Gotway
#              NCAR/RAL/DTC
#
#    Released: 10/16/2012
#
# Description:
#   Call copygb using the arguments provided.  However, split the call up into
#   separate calls, one using budget interpolation, one using nearest neighbor, 
#   and the last one using the default interpolation.
#
# Dependencies:
#   The VXUTIL_CONST environment variable must be set to the file containing
#   project constants.
#
# Arguments:
#   Arguments for copygb
#
################################################################################

use strict;
use warnings;

use POSIX;
use File::Basename;

################################################################################

# Constants
my $TMP_DIR             = ".";
my $WGRIB_EXEC          = "/glade/apps/opt/wgrib/1.8.1.0b/gnu/4.7.0/wgrib";
my $COPYGB_EXEC         = "/glade/p/ral/jnt/Aerocivil/CODE/UPP/v3.0/UPPV3.0/bin/copygb.exe";
my $COPYGB_BUDGET_VARS  = "ACPCP|NCPCP|APCP|PWAT";
my $COPYGB_NN_VARS      = "REFC|REFD|var240";
my $COPYGB_EXCLUDE_VARS = "ACPCP|NCPCP|APCP|PWAT|REFC|REFD|var240";

################################################################################

# Print begin time
print "\n", $0, " - started at " . strftime("%Y-%m-%d %H:%M:%S", gmtime()) . "\n\n";

# Arguments
my $in_file;
my $out_file;
my @copygb_args;

# Parse command line options
while ( my $arg = shift ) {
  if ( index ( $arg, "-" ) == 0 ) { push @copygb_args, $arg; }
  elsif ( !defined ( $in_file ) ) { $in_file = $arg;         }
  else                            { $out_file = $arg;        }
}

# Check for input/output files
if ( !defined ( $in_file ) || !defined ( $out_file ) ) {
   die "ERROR: Must specify input and output filenames.\n";
}

# Process file names
my ($in_file_name, $in_file_path) = fileparse($in_file);
my $wgrib_budget   = $TMP_DIR . "/" . $in_file_name . "_WGRIB_BUDGET";
my $wgrib_nn   = $TMP_DIR . "/" . $in_file_name . "_WGRIB_NN";
my $wgrib_default  = $TMP_DIR . "/" . $in_file_name . "_WGRIB_DEFAULT";
my $copygb_budget  = $TMP_DIR . "/" . $in_file_name . "_COPYGB_BUDGET";
my $copygb_nn  = $TMP_DIR . "/" . $in_file_name . "_COPYGB_NN";
my $copygb_default = $TMP_DIR . "/" . $in_file_name . "_COPYGB_DEFAULT";

# Run wgrib to subset the input file
vx_run_cmd ( "$WGRIB_EXEC $in_file | egrep    \"" . $COPYGB_BUDGET_VARS .
             "\" | $WGRIB_EXEC $in_file -i -grib -o $wgrib_budget  > /dev/null" );
vx_run_cmd ( "$WGRIB_EXEC $in_file | egrep    \"" . $COPYGB_NN_VARS .
             "\" | $WGRIB_EXEC $in_file -i -grib -o $wgrib_nn  > /dev/null" );
vx_run_cmd ( "$WGRIB_EXEC $in_file | egrep -v \"" . $COPYGB_EXCLUDE_VARS .
             "\" | $WGRIB_EXEC $in_file -i -grib -o $wgrib_default > /dev/null" );

# Run copygb on the subsetted files
vx_run_cmd ( "$COPYGB_EXEC @copygb_args -i3 $wgrib_budget  $copygb_budget  > /dev/null" );
vx_run_cmd ( "$COPYGB_EXEC @copygb_args -i2 $wgrib_nn  $copygb_nn  > /dev/null" );
vx_run_cmd ( "$COPYGB_EXEC @copygb_args     $wgrib_default $copygb_default > /dev/null" );

# Concatenate the two output files
vx_run_cmd ( "cat $copygb_budget $copygb_nn $copygb_default > $out_file" );

# Remove the temporary files
foreach my $tmp_file ( ($wgrib_budget, $wgrib_nn, $wgrib_default, $copygb_budget, $copygb_nn, $copygb_default) ) {
  vx_run_cmd ( "rm -f $tmp_file" );
}

# Print end time
print "\n", $0, " - finished at " . strftime("%Y-%m-%d %H:%M:%S", gmtime()) . "\n\n";

######################################################################
#
# vx_run_cmd()
#
#   This function calls system to run the command passed to it.
#   It will print the command passed to it and then run it.  If the
#   command returns non-zero status, it will die with an error
#   message.
#
#   Arguments:
#     The system command to be executed.
#
#######################################################################

sub vx_run_cmd {

  # retrieve the command
  my $command = shift;

  # run the command
  print "CALLING: $command\n";
  my $status = system ( $command );

  # check for bad return status
  if ( $status != 0 ) {
    print "ERROR: Command returned with non-zero ($status) status...\n",
        "  $command\n";
    exit 1;
  }

  return $status;
}
