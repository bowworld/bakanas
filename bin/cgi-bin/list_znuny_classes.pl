#!/usr/bin/perl
use strict;
use warnings;
use Kernel::System::ObjectManager;
print "Content-type: text/plain\n\n";
local $Kernel::OM = Kernel::System::ObjectManager->new();
my $GCO = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
my $List = $GCO->ItemList( Class => 'ITSM::ConfigItem::Class' );
for my $Item (@$List) {
    print "$Item->[0]: $Item->[1]\n";
}
