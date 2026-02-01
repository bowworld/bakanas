#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($RealBin);
use lib $RealBin;
use lib "$RealBin/Kernel/cpan-lib";
use lib "$RealBin/Custom";

$ENV{OTRS_HOME} = $RealBin;

use Kernel::Config;
use Kernel::System::Log;
use Kernel::System::Main;
use Kernel::System::DB;
use Kernel::System::JSON;

my $ConfigObject = Kernel::Config->new();
$ConfigObject->Set(Key => 'Home', Value => $RealBin);

my $LogObject = Kernel::System::Log->new(ConfigObject => $ConfigObject);
my $MainObject = Kernel::System::Main->new(ConfigObject => $ConfigObject);
my $DBObject = Kernel::System::DB->new(
    ConfigObject => $ConfigObject,
    LogObject    => $LogObject,
    MainObject   => $MainObject,
);

my %Map;

# Get Classes
print "CLASSES:\n";
$DBObject->Prepare(SQL => "SELECT id, name FROM general_catalog WHERE general_catalog_class = 'ITSM::ConfigItem::Class'");
while (my @Row = $DBObject->FetchrowArray()) {
    print "CLASS: $Row[0]\t$Row[1]\n";
}

# Get Deployment States
print "\nDEPL_STATES:\n";
$DBObject->Prepare(SQL => "SELECT id, name FROM general_catalog WHERE general_catalog_class = 'ITSM::ConfigItem::DeploymentState'");
while (my @Row = $DBObject->FetchrowArray()) {
    print "STATE: $Row[0]\t$Row[1]\n";
}

# Get Users
print "\nUSERS:\n";
$DBObject->Prepare(SQL => "SELECT id, login FROM users");
while (my @Row = $DBObject->FetchrowArray()) {
    print "USER: $Row[0]\t$Row[1]\n";
}

# Get Roles
print "\nROLES:\n";
$DBObject->Prepare(SQL => "SELECT id, name FROM roles");
while (my @Row = $DBObject->FetchrowArray()) {
    print "ROLE: $Row[0]\t$Row[1]\n";
}
