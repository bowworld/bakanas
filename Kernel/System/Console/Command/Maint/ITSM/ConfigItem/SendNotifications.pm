# --
# Copyright (C) 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::ITSM::ConfigItem::SendNotifications;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::PerlServices::CINotificationsUtils
    Kernel::System::PerlServices::CINotificationsSend
    Kernel::System::PerlServices::CINotification
    Kernel::System::ITSMConfigItem
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Send notifications for config items.');

    $Self->AddOption(
        Name        => 'job',
        Description => "Specific job to be run",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/,
        Multiple    => 1,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $SendObject         = $Kernel::OM->Get('Kernel::System::PerlServices::CINotificationsSend');
    my $ConfigItemObject   = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $NotificationObject = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
    my $UtilsObject        = $Kernel::OM->Get('Kernel::System::PerlServices::CINotificationsUtils');

    $Self->Print("<yellow>Send checklist notifications...</yellow>\n");

    my $DEBUG = $ConfigObject->Get('CINotifications::Debug');

    my %NotificationList = $NotificationObject->NotificationList( Valid => 1, Events => 1 );

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'debug',
            Message  => $MainObject->Dump( \%NotificationList ),
        );
    }

    my @Jobs =  @{ $Self->GetOption('job') // [] };

    NAME:
    for my $Name ( sort keys %NotificationList ) {

        if ( @Jobs && !grep{ $_ eq $Name }@Jobs ) {
            next NAME;
        }

        my %Notification = $NotificationObject->NotificationGet(
            Name => $Name,
        );

        if ( ! %{ $Notification{Events} || {} } ) {
            if ( $DEBUG ) {
                $LogObject->Log(
                    Priority => 'debug',
                    Message  => "Skipping $Name: Does not define events",
                );
            }
        }

        if ( $DEBUG ) {
            $Self->Print("<yellow>Run $Name...</yellow>\n");

            $LogObject->Log(
                Priority => 'debug',
                Message  => "Run $Name...",
            );
        }

        if ( $DEBUG ) {
            $LogObject->Log(
                Priority => 'debug',
                Message  => $MainObject->Dump( \%Notification ),
            );
        }

        my ($Search,$Opts) = $UtilsObject->BuildSearch(
            Notification => \%Notification,
        );

        if ( $DEBUG ) {
            $LogObject->Log(
                Priority => 'debug',
                Message  => $MainObject->Dump( [ $Search, $Opts ] ),
            );
        }

        my $ConfigItemIDs = $ConfigItemObject->ConfigItemSearchExtended(
            %{ $Opts || {} },
            What     => $Search,
            ClassIDs => [ $Notification{ClassID} ],
        );

        if ( $DEBUG ) {
            $LogObject->Log(
                Priority => 'debug',
                Message  => $MainObject->Dump( $ConfigItemIDs ),
            );
        }

        next NAME if !@{ $ConfigItemIDs || [] };

        $SendObject->Send(
            Notification  => \%Notification,
            ConfigItemIDs => $ConfigItemIDs,
        );
    }


    $Self->Print("<green>Done.</green>\n");
    return $Self->ExitCodeOk();
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
