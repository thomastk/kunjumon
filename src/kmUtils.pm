#!/usr/bin/perl

package kmUtils;

use strict;
use warnings;

use Data::Dumper; #for debug

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

   $CHECK_NAME=$check->{name};
   my $value_label=$check->{sql}->[0]->{value_label};

   my $compare_type=$check->{validation}->[0]->{type};
   if ($compare_type eq 'string')  {
      my $threshold_val=$check->{validation}->[0]->{thresholds}->[0]->{ok};
      if ($curr_val eq $threshold_val) {
         $ALERT_TEXT.="$CHECK_NAME:O:$curr_val==$threshold_val.";
         return($NAGIOS_OK);
      }
      else {
         $ALERT_TEXT.="$CHECK_NAME:C:The query result doesn't match with the expected value. $curr_val <=> $threshold_val.";
         return($NAGIOS_CRITICAL);
      }
   }
   elsif ($compare_type eq 'regex')  {
      my $threshold_val=$check->{validation}->[0]->{thresholds}->[0]->{ok};
      if ($curr_val=~/$threshold_val/) {
         $ALERT_TEXT.="$CHECK_NAME:O:$curr_val <=> regex/$threshold_val/";
         return($NAGIOS_OK);
      }
      else {
         $ALERT_TEXT.="$CHECK_NAME:C:The query result doesn't match with the expected value. $curr_val <=> regex/$threshold_val/";
         return($NAGIOS_CRITICAL);
      }
   }
   elsif ($compare_type eq 'number')  {
      my $op=$check->{validation}->[0]->{operator};
      my $val_ok=$check->{validation}->[0]->{thresholds}->[0]->{ok};
      my $val_warning=$check->{validation}->[0]->{thresholds}->[0]->{warning};
      my $val_critical=$check->{validation}->[0]->{thresholds}->[0]->{critical};

      if ($op eq 'LT') { #lesser the better
         if ($curr_val < $val_ok) {
            $ALERT_TEXT.="$CHECK_NAME:O:$value_label: $curr_val < $val_ok.";
            return($NAGIOS_OK);
         }
         elsif ($curr_val < $val_warning) {
            $ALERT_TEXT.="$CHECK_NAME:W:$value_label: $curr_val < $val_warning.";
            return($NAGIOS_WARNING);
         }
         else {
            $ALERT_TEXT.="$CHECK_NAME:C:$value_label: $curr_val.";
            return($NAGIOS_CRITICAL);
         }
      }
      elsif ($op eq 'EQ') {
         if ($curr_val==$val_ok) {
            $ALERT_TEXT.="$CHECK_NAME:O:$value_label: $curr_val = $val_ok.";
            return($NAGIOS_OK);
         }
         else {
            $ALERT_TEXT.="$CHECK_NAME:C:$value_label: $curr_val.";
            return($NAGIOS_CRITICAL);
         }
      }
      elsif ($op eq 'GT') { #greater the better
         if ($curr_val > $val_ok) {
            $ALERT_TEXT.="$CHECK_NAME: $value_label:O:$curr_val > $val_ok.";
            return($NAGIOS_OK);
         }
         elsif ($curr_val > $val_warning) {
            $ALERT_TEXT.="$CHECK_NAME:W:$value_label: $curr_val > $val_warning.";
            return($NAGIOS_WARNING);
         }
         else {
            $ALERT_TEXT.="$CHECK_NAME:C:$value_label: $curr_val.";
            return($NAGIOS_CRITICAL);
         }
      }
      else {
         $ALERT_TEXT.="$CHECK_NAME:U:Unsupported operation ($op) for comparison.";
         return($NAGIOS_UNKNOWN);
      }
   }
}

1;
