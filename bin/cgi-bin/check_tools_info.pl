#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Kernel::System::ObjectManager;
print "Content-type: text/plain; charset=utf-8\n\n";

local $Kernel::OM = Kernel::System::ObjectManager->new();
my $GCO = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
my $CIO = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

# Get CI classes
my $Items = $GCO->ItemList( Class => 'ITSM::ConfigItem::Class' );

for my $Item (@$Items) {
    next unless $Item->{Name} =~ /^(Tools|MeasuringTools|СИЗ)$/;
    
    my $ClassID = $Item->{ItemID};
    my $ClassName = $Item->{Name};
    
    print "=== $ClassName (ClassID: $ClassID) ===\n";
    
    # Get definition
    my $Def = $CIO->DefinitionGet( ClassID => $ClassID );
    if ($Def && $Def->{DefinitionID}) {
        print "  DefinitionID: $Def->{DefinitionID}\n";
        print "  CreateTime: $Def->{CreateTime}\n";
        
        # Count existing CIs
        my $List = $CIO->ConfigItemSearch( ClassIDs => [$ClassID] );
        print "  Existing CIs: " . scalar(@$List) . "\n";
    } else {
        print "  NO DEFINITION\n";
    }
    print "\n";
}
