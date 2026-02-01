#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Kernel::System::ObjectManager;

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::Config' => {
        Home => '/opt/znuny',
    },
);

my $NotificationObject = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
my %List = $NotificationObject->NotificationList( Valid => 0 );

print "Found " . scalar(keys %List) . " notifications.\n";
for my $Name (sort keys %List) {
    print " - $Name\n";
}
