#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($RealBin);
use lib $RealBin;
use lib "$RealBin/Kernel/cpan-lib";
use lib "$RealBin/Custom";

$ENV{OTRS_HOME} = '/Users/sabyrzhanzhakipov/znuny-mount';

use Kernel::System::ObjectManager;

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::Config' => {
        Home => $ENV{OTRS_HOME},
    },
);

my $DBObject = $Kernel::OM->Get('Kernel::System::DB');

print "Searching for CI Notification tables...\n";
$DBObject->Prepare(SQL => "SHOW TABLES LIKE 'ci_notification%'");
while (my @Row = $DBObject->FetchrowArray()) {
    print "Table: $Row[0]\n";
}

$DBObject->Prepare(SQL => "SHOW TABLES LIKE 'ps_ci_notification%'");
while (my @Row = $DBObject->FetchrowArray()) {
    print "Table: $Row[0]\n";
}
