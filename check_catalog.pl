use strict;
use warnings;
use File::Basename;
use FindBin qw($Bin);
use lib dirname($Bin);
use Kernel::System::VariableCheck qw(:all);
use Kernel::System::ObjectManager;

# Set Home manually
$ENV{OTRS_HOME} = '/Users/sabyrzhanzhakipov/znuny-mount';

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::System::Log' => {
        LogPrefix => 'Znuny-Test',
    },
);

my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
my $ItemList = $GeneralCatalogObject->ItemList(
    Class => 'ITSM::ConfigItem::Tools::Type',
);

if (IsHashRefWithData($ItemList)) {
    print "Found " . scalar(keys %$ItemList) . " items in Tools::Type\n";
    for my $Key (sort keys %$ItemList) {
        print "$Key: $ItemList->{$Key}\n";
    }
} else {
    print "No items found for ITSM::ConfigItem::Tools::Type\n";
}
