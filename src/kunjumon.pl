#!/usr/bin/perl

use Getopt::Long;
use XML::Simple;
use Data::Dumper; #for debug

use strict;
use warnings;

use kmUtils;
use kmDbSupport;

#06/13/2014 Thomas T. Original version.
#kunjmon.pl - A Nagios plugin to define monitors that queries system status from services such as databases and web APIs.
#The configuration file used for defining a monitor contains accees info for the data service that the plugin uses and monitoring thresholds.

#Use this command to define commands in commands.cfg and individual monitors in localhost.cfg
#Syntax: kunjumon.pl config-file monitor-name

my($config_file,$monitor_name)=@ARGV;

$kmUtils::MONITOR_NAME='';
$kmUtils::CHECK_NAME='';
$kmUtils::ALERT_TEXT='';

my $mon_status=$kmUtils::NAGIOS_OK;

if (!defined $config_file || !defined $monitor_name) {
   $kmUtils::ALERT_TEXT="Run the script with correct parameters. kunjumon.pl config-file monitor-name.";
   exitMon($kmUtils::NAGIOS_UNKNOWN);
}
$kmUtils::MONITOR_NAME=$monitor_name;

#parse the config-file to store config info and load needed supporting modules.
eval { $kmUtils::INSTANCE_CONFIG=XMLin($config_file,ForceArray=>1,KeyAttr=>{monitor=>"name",db_connection=>"name"})};
if ($@) {
   $kmUtils::ALERT_TEXT="Problem loading config file $config_file. Check file path, xml syntax etc.";
   exitMon($kmUtils::NAGIOS_UNKNOWN);
}

my $monitor_config=$kmUtils::INSTANCE_CONFIG->{monitors}->[0]->{monitor}->{$monitor_name};

#my $monitor_config;
#my $monitor_ctr=0;
#while ($kmUtils::INSTANCE_CONFIG->{monitors}->[$monitor_ctr]->{monitor}) {
#   if (defined $kmUtils::INSTANCE_CONFIG->{monitors}->[$monitor_ctr]->{monitor}->{$monitor_name}) {
#      $monitor_config=$kmUtils::INSTANCE_CONFIG->{monitors}->[$monitor_ctr]->{monitor}->{$monitor_name};
#      last;
#   }
#   $monitor_ctr++;
#}

if (!defined $monitor_config) {
   $kmUtils::ALERT_TEXT="Cannot find configuration for monitor ($monitor_name) in $config_file.";
   exitMon($kmUtils::NAGIOS_UNKNOWN);
}

#look up which data sources are used by the monitor,load related Perl libs and 
#check availability of supporting tools, and run checks.
foreach my $check (@{$monitor_config->{checks}->[0]->{check}}) {
   my $rc;
   $kmUtils::CHECK_NAME=$check->{name};
   my $source_type=$check->{source_type};
   if ($source_type eq 'database') {
      $rc=kmDbSupport::runDatabaseCheck($check);
   }
   else {
      $kmUtils::ALERT_TEXT.=$kmUtils::CHECK_NAME.':'."Unsupported data source type specified.";
      $rc=$kmUtils::NAGIOS_UNKNOWN;
   }
   #The return values from individual checks could be a mixed-bag
   #The highest value (normally the worst case should be chosen as the 
   #status of the monitor/service
   $mon_status=$rc unless $mon_status>$rc;
}

exitMon($mon_status);

sub exitMon
{
   my $status=shift;

   my $status_label="Unknown";
   if ($status==$kmUtils::NAGIOS_WARNING) {$status_label="Warning"}
   elsif ($status==$kmUtils::NAGIOS_CRITICAL) {$status_label="Critical"}
   elsif ($status==$kmUtils::NAGIOS_OK) {$status_label="OK"}

   print $status_label.':'.$kmUtils::MONITOR_NAME.':'.$kmUtils::ALERT_TEXT."\n";

   exit($status);
}

