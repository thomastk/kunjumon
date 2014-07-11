#!/usr/bin/perl

package kmUtils;

use strict;
use warnings;

#06/13/2014 Thomas T. Original version.
#kmUtils.pm - Module for utility routines and global variables to be used in kunjumon.pl

#Global constants
our $NAGIOS_OK=0;
our $NAGIOS_WARNING=1;
our $NAGIOS_CRITICAL=2;
our $NAGIOS_UNKNOWN=3;

#Global variables
our $INSTANCE_CONFIG;
our $MONITOR_NAME='';
our $CHECK_NAME='';
our $ALERT_TEXT='';

sub validateStatus   
{
   my ($curr_val,$check)=@_;

   $CHECK_NAME=$check->{check_name};
   my $value_label=$check->{sql}->{value_label};

   my $compare_type=$check->{validation}->{type};
   if ($compare_type eq 'string')  {
      my $threshold_val=$check->{validation}->{thresholds}->{ok};
      if ($curr_val ne $threshold_val) {
         $ALERT_TEXT.="$CHECK_NAME: The query result doesn't match with the expected value. $curr_val <=> $threshold_val.";
         return($NAGIOS_CRITICAL);
      }
   }
   elsif ($compare_type eq 'regex')  {
      my $threshold_val=$check->{validation}->{thresholds}->{ok};
      if ($curr_val=~/$threshold_val/) {
      }
      else {
         $ALERT_TEXT.="$CHECK_NAME: The query result doesn't match with the expected value. $curr_val <=> regex/$threshold_val/";
         return($NAGIOS_CRITICAL);
      }
   }
   elsif ($compare_type eq 'number')  {
      my $op=$check->{validation}->{operator};
      my $val_ok=$check->{validation}->{thresholds}->{ok};
      my $val_warning=$check->{validation}->{thresholds}->{warning};
      my $val_critical=$check->{validation}->{thresholds}->{critical};

      if ($op eq 'LT') { #lesser the better
         if ($curr_val < $val_ok) {
            $ALERT_TEXT.="$CHECK_NAME: $value_label: $curr_val < $val_ok.";
            return($NAGIOS_OK);
         }
         elsif ($curr_val < $val_warning) {
            $ALERT_TEXT.="$CHECK_NAME: $value_label: $curr_val < $val_warning.";
            return($NAGIOS_WARNING);
         }
         else {
            $ALERT_TEXT.="$CHECK_NAME: $value_label: $curr_val.";
            return($NAGIOS_CRITICAL);
         }
      }
      elsif ($op eq 'EQ') {
         if ($curr_val==$val_ok) {
            $ALERT_TEXT.="$CHECK_NAME: $value_label: $curr_val = $val_ok.";
            return($NAGIOS_OK);
         }
         else {
            $ALERT_TEXT.="$CHECK_NAME: $value_label: $curr_val.";
            return($NAGIOS_CRITICAL);
         }
      }
      elsif ($op eq 'GT') { #greater the better
         if ($curr_val > $val_ok) {
            print "$CHECK_NAME: $value_label: $curr_val > $val_ok.\n";
            return($NAGIOS_OK);
         }
         elsif ($curr_val > $val_warning) {
            $ALERT_TEXT.="$CHECK_NAME: $value_label: $curr_val > $val_warning.";
            return($NAGIOS_WARNING);
         }
         else {
            $ALERT_TEXT.="$CHECK_NAME: $value_label: $curr_val.";
            return($NAGIOS_CRITICAL);
         }
      }
      else {
         $ALERT_TEXT.="$CHECK_NAME: Unsupported operation ($op) for comparison.";
         return($NAGIOS_UNKNOWN);
      }
   }
}

1;
