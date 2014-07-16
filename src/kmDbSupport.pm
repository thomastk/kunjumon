#!/usr/bin/perl

package kmDbSupport;

use DBI;

use strict;
use warnings;

use kmUtils;

#06/13/2014 Thomas T. Original version.
#kmDbSupport.pm - Module for routines that provide interfaces to databases.

sub runDatabaseCheck
{
   my $check=shift;

   $kmUtils::CHECK_NAME=$check->{name};

   my $db_connection=$check->{db_connection};
   my $db_config=$kmUtils::INSTANCE_CONFIG->{db_connections}->[0]->{db_connection}->{$db_connection};


   my $dsn_str=$db_config->{dsn};
   my $db_host_name=$db_config->{db_host_name};
   my $db_host_port=$db_config->{db_host_port};
   my $db_system=$db_config->{db_system};
   my $db_version=$db_config->{db_version};
   my $db_name=$db_config->{db_name}; #SID for Oracle
   my $user_name=$db_config->{user_name};
   my $user_pass=$db_config->{user_pass};

   my $dsn=undef;

   if (defined $dsn_str) {$dsn=$dsn_str}
   else {
      if ($db_system eq 'mysql') {
         $dsn="dbi:mysql:$db_name;host=$db_host_name";
      }
      elsif ($db_system eq 'oracle') {
         $dsn="dbi:Oracle:host=$db_host_name;sid=$db_name";
      }
      elsif ($db_system eq 'odbc') {
         $dsn="dbi:ODBC:DSN=$db_name";
      }
      elsif ($db_system eq 'mssql') { #supports the FreeTds driver to support access from Linux -> Windows
         $dsn = "dbi:Sybase:server=$db_host_name"; #db_host_name must be configured in freetds.conf
      }
      elsif ($db_system eq 'sqlite') {
         $dsn="dbi:SQLite:dbname=$db_name"; #db_name has to be the database file in this case.
      }
      elsif ($db_system eq 'postgres') {
         $dsn="dbi:Pg:dbname=$db_name;host=$db_host_name"; 
      }
      else {
         $kmUtils::ALERT_TEXT=$kmUtils::CHECK_NAME.':'."Unsupported database type: $db_system.";
         return($kmUtils::NAGIOS_UNKNOWN);
      }
   
      #Specify port in the DNS string if that is provided in the configuration.
      if (defined $db_host_port && $db_host_port ne '') {$dsn.=";port=$db_host_port"}
   }

   my $dbh=undef;
   eval { $dbh=DBI->connect($dsn,$user_name,$user_pass) };
   if ($@) {
      $kmUtils::ALERT_TEXT=$kmUtils::CHECK_NAME.':'."Database connection problem. ".$@;
      return($kmUtils::NAGIOS_UNKNOWN);
   }
   if (!defined $dbh) {
      $kmUtils::ALERT_TEXT=$kmUtils::CHECK_NAME.':'."Database connection problem. ".$DBI::errstr;
      return($kmUtils::NAGIOS_UNKNOWN);
   }

   #For some database systems database cannot be set as part of connect
   if ($db_system eq 'mssql') {
      if (!$dbh->do("use $db_name")) {
         $kmUtils::ALERT_TEXT=$kmUtils::CHECK_NAME.':'."Cannot set database $db_name.".$dbh->errstr;
         return($kmUtils::NAGIOS_UNKNOWN);
      }
   }

   my $sth=$dbh->prepare($check->{sql}->[0]->{content});
   if (!defined $sth) {
      $kmUtils::ALERT_TEXT=$kmUtils::CHECK_NAME.':'."Problem preparing the sql statement for the check.";
      return($kmUtils::NAGIOS_UNKNOWN);
   }
   
#print Dumper($check->{sql})."\n";
#exit;

   if (!$sth->execute()) {
      $kmUtils::ALERT_TEXT=$kmUtils::CHECK_NAME.':'."Problem executing the sql statement for the check.";
      return($kmUtils::NAGIOS_UNKNOWN);
   }
   my $value_label=$check->{sql}->[0]->{value_label};
   my ($db_val)=$sth->fetchrow_array;
   if (!defined $db_val) {
      $kmUtils::ALERT_TEXT=$kmUtils::CHECK_NAME.':'."No result returned by the query.";
      return($kmUtils::NAGIOS_CRITICAL);
   }
   $sth->finish;
   $dbh->disconnect;

   return kmUtils::validateStatus($db_val,$check);
}

1;
