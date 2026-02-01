use strict;
use warnings;
use utf8;
use lib '/opt/otrs/';
use lib '/opt/otrs/Kernel/cpan-lib';
use Kernel::Config;
use Kernel::System::ObjectManager;
use JSON;

local $Kernel::OM = Kernel::System::ObjectManager->new();
my $CIO = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
my $GCO = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
my $UO  = $Kernel::OM->Get('Kernel::System::User');

my $IDs = $CIO->ConfigItemSearch( ClassIDs => [200] );
my $Res = [];

for my $ID (@{$IDs || []}) {
    my $CI = $CIO->ConfigItemGet( ConfigItemID => $ID );
    my $Ver = $CIO->VersionGet( VersionID => $CI->{LastVersionID} );
    next if !$Ver || !$Ver->{XMLData};
    
    my $D = $Ver->{XMLData}->[1]->{Version}->[1];
    my $Item = { Name => $CI->{Name} || '' };
    
    # FIO (User ID)
    if ($D->{FIO}->[1]->{Content}) {
        my %U = $UO->GetUserData( UserID => $D->{FIO}->[1]->{Content} );
        $Item->{FIO_Login} = $U{UserLogin} if $U{UserLogin};
    }
    
    # Position (GC Item ID)
    if ($D->{Position}->[1]->{Content}) {
        my $GC = $GCO->ItemGet( ItemID => $D->{Position}->[1]->{Content} );
        $Item->{Position} = $GC->{Name} if $GC;
    }
    
    $Item->{Email}    = $D->{Email}->[1]->{Content}    || '';
    $Item->{Mobile}   = $D->{Mobile}->[1]->{Content}   || '';
    $Item->{Auto}     = $D->{Auto}->[1]->{Content}     || '';
    $Item->{District} = $D->{District}->[1]->{Content} || '';
    $Item->{StartWork}= $D->{StartWork}->[1]->{Content}|| '';
    
    push @$Res, $Item;
}
print encode_json($Res);
