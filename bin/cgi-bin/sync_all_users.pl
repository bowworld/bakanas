#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Kernel::System::ObjectManager;
require JSON;

print "Content-type: text/plain; charset=utf-8\n\n";

my $Raw = <<'JSON_DATA';
REPLACE_ME_WITH_JSON
JSON_DATA

local $Kernel::OM = Kernel::System::ObjectManager->new();
my $UO = $Kernel::OM->Get('Kernel::System::User');

my $Users = JSON->new()->utf8()->decode($Raw);

for my $U (@$Users) {
    print "Syncing $U->{Login}... ";
    my %Exist = $UO->GetUserData( User => $U->{Login} );
    if ($Exist{UserID}) {
        print "Exists (ID $Exist{UserID})\n";
    } else {
        my $UserID = $UO->UserAdd(
            UserFirstname => $U->{Firstname},
            UserLastname  => $U->{Lastname},
            UserLogin     => $U->{Login},
            UserEmail     => $U->{Email} || "$U->{Login}\@vicomplus.kz",
            ValidID       => 1,
            ChangeUserID  => 1,
        );
        if ($UserID) {
            $UO->SetPassword( UserLogin => $U->{Login}, PW => 'Vicom_2026!' );
            print "CREATED (ID $UserID)\n";
        } else {
            print "FAILED\n";
        }
    }
}
