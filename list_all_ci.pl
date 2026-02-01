#!/usr/bin/perl
use strict;
use warnings;
use File::Basename;
use FindBin qw($RealBin);
use lib $RealBin;
use lib "$RealBin/Kernel/cpan-lib";
use lib "$RealBin/Custom";

# Set OTRS_HOME to the current directory (the mount root)
$ENV{OTRS_HOME} = '/Users/sabyrzhanzhakipov/znuny-mount';

use Kernel::System::ObjectManager;

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::Config' => {
        Home => $ENV{OTRS_HOME},
    },
);

my $CIAO = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
my $GCO = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

# Get all classes
my $Classes = $GCO->ItemList( Class => 'ITSM::ConfigItem::Class' );

print "Listing all Configuration Items by Class:\n";
print "=" x 40 . "\n";

for my $Class (values %$Classes) {
    print "\nClass: $Class\n";
    print "-" x 20 . "\n";
    
    my $IDs = $CIAO->ConfigItemSearch(
        Class => $Class,
    );
    
    if ($IDs && @$IDs) {
        for my $ID (@$IDs) {
            my $CI = $CIAO->ConfigItemGet(
                ConfigItemID => $ID,
            );
            print "ID: $CI->{ConfigItemID} | Name: $CI->{Name} | CurDeplState: $CI->{CurDeplState}\n";
        }
    } else {
        print "No items found.\n";
    }
}
