# --
# Kernel/System/PerlServices/CINotification/Event/SetIncidentState.pm
# Copyright (C) 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PerlServices::CINotification::Event::SetIncidentState;

use strict;
use warnings;

use List::Util qw(first);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::ITSMConfigItem
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $CIObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $GCObject     = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    my $DEBUG = $ConfigObject->Get('CINotifications::Debug');

    # check needed stuff
    for my $NeededParam (qw(Data Event Config UserID)) {
        if ( !$Param{$NeededParam} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $NeededParam!",
            );

            return;
        }
    }

    for my $NeededData (qw(ConfigItemID ConfigItem)) {
        if ( !$Param{Data}->{$NeededData} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $NeededData!",
            );

            return;
        }
    }

    my $NewState = $ConfigObject->Get('CINotifications::IncidentState') || 'Incident';

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => "Event: $Param{Event}",
        );
    }

    my $CI = $CIObject->VersionGet(
        ConfigItemID => $Param{Data}->{ConfigItemID},
        XMLDataGet   => 1,
    );

    my $InciStateList = $GCObject->ItemList(
        Class => 'ITSM::Core::IncidentState',
    );

    my %Map = reverse %{ $InciStateList || {} };

    $CI->{InciStateID} = $Map{$NewState};

    $CIObject->VersionAdd(
        %{$CI},
        UserID => $Param{UserID},
    );

    return 1;
}

1;
