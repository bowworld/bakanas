#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($RealBin);
use lib $RealBin;
use lib "$RealBin/Kernel/cpan-lib";
use lib "$RealBin/Custom";

# Mock RELEASE file check
$ENV{OTRS_HOME} = '/Users/sabyrzhanzhakipov/znuny-mount';
if (! -e "/opt/znuny/RELEASE") {
    # If we can't write to /opt, we might have trouble with ObjectManager if it's hardcoded to /opt/znuny
}

use Kernel::Config;
use Kernel::System::DB;
use Kernel::System::Log;
use Kernel::System::Main;

my $ConfigObject = Kernel::Config->new();
# Force Home to current dir
$ConfigObject->Set(Key => 'Home', Value => $ENV{OTRS_HOME});

my $LogObject = Kernel::System::Log->new(
    ConfigObject => $ConfigObject,
);
my $MainObject = Kernel::System::Main->new(
    ConfigObject => $ConfigObject,
);
my $DBObject = Kernel::System::DB->new(
    ConfigObject => $ConfigObject,
    LogObject    => $LogObject,
    MainObject   => $MainObject,
);

print "Requesting table list...\n";
my @Tables = $DBObject->ListTables();
for my $Table (@Tables) {
    if ($Table =~ /ci_notification/i) {
        print "FOUND: $Table\n";
    }
}
