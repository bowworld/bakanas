#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Kernel::System::ObjectManager;
print "Content-type: text/plain; charset=utf-8\n\n";

local $Kernel::OM = Kernel::System::ObjectManager->new();
my $GCO = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

# Get all CI classes
my $Items = $GCO->ItemList( Class => 'ITSM::ConfigItem::Class' );
my %Classes;
for my $Item (@$Items) {
    $Classes{$Item->{Name}} = $Item->{ItemID};
}

# Check for our target classes
for my $ClassName ('Tools', 'MeasuringTools', 'СИЗ') {
    if ($Classes{$ClassName}) {
        print "$ClassName: EXISTS (ID $Classes{$ClassName})\n";
    } else {
        print "$ClassName: MISSING\n";
    }
}
