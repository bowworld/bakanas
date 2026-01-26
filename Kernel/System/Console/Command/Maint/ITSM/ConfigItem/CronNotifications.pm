# --
# Copyright (C) 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Console::Command::Maint::ITSM::ConfigItem::CronNotifications;

use strict;
use warnings;

use base qw(Kernel::System::Console::BaseCommand);

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::Time
    Kernel::System::PerlServices::CINotificationsUtils
    Kernel::System::PerlServices::CINotificationsSend
    Kernel::System::PerlServices::CINotification
    Kernel::System::ITSMConfigItem
    Kernel::System::CronEvent
);

sub Configure {
    my ( $Self, %Param ) = @_;

    $Self->Description('Send notifications for config items (cron based).');

    $Self->AddOption(
        Name        => 'job',
        Description => "Specific job to be run",
        Required    => 0,
        HasValue    => 1,
        ValueRegex  => qr/.*/xms,
        Multiple    => 1,
    );

    $Self->AddOption(
        Name        => 'skip-by-job',
        Description => "Skip notification where the cron is defined in the job",
        Required    => 0,
        HasValue    => 0,
    );

    $Self->AddOption(
        Name        => 'skip-by-item',
        Description => "Skip notification where the cron is defined in the item",
        Required    => 0,
        HasValue    => 0,
    );

    return;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject   = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');
    my $TimeObject   = $Kernel::OM->Get('Kernel::System::Time');
    my $CronObject   = $Kernel::OM->Get('Kernel::System::CronEvent');

    $Self->Print("<yellow>Send cron based checklist notifications...</yellow>\n");

    my $DEBUG = $ConfigObject->Get('CINotifications::Debug');

    my $CronConfig = $ConfigObject->Get('Daemon::SchedulerCronTaskManager::Task') || {};
    my $ThisConfig = $CronConfig->{CINotificationsCron} || {};;

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'debug',
            Message  => $MainObject->Dump( $CronConfig ),
        );
    }

    my $Schedule = $ThisConfig->{Schedule} || '*/10 * * * *';
    my $Now      = $TimeObject->SystemTime();
    my $Min      = $CronObject->PreviousEventGet(
        Schedule  => $Schedule,
        StartTime => $Now,
    );

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'debug',
            Message  => "Now: $Now, Min: $Min, Schedule: $Schedule",
        );
    }

    my $SkipJobs = $Self->GetOption('skip-by-job');
    if ( !$SkipJobs ) {
        $Self->_SendNotificationsByJob(
            Now => $Now,
            Min => $Min,
        );
    }

    my $SkipItems = $Self->GetOption('skip-by-item');
    if ( !$SkipItems ) {
        $Self->_SendNotificationsByItem(
            Now => $Now,
            Min => $Min,
        );
    }

    return $Self->ExitCodeOk();
}

sub _SendNotificationsByJob {
    my ($Self, %Param) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $SendObject         = $Kernel::OM->Get('Kernel::System::PerlServices::CINotificationsSend');
    my $ConfigItemObject   = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $NotificationObject = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
    my $UtilsObject        = $Kernel::OM->Get('Kernel::System::PerlServices::CINotificationsUtils');
    my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
    my $CronObject         = $Kernel::OM->Get('Kernel::System::CronEvent');

    my %NotificationList = $NotificationObject->NotificationList( Valid => 1, Cron => 1 );

    my $DEBUG = $ConfigObject->Get('CINotifications::Debug');

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'debug',
            Message  => $MainObject->Dump( \%NotificationList ),
        );
    }

    my @Jobs =  @{ $Self->GetOption('job') // [] };

    my $Now = $Param{Now};
    my $Min = $Param{Min};

    NAME:
    for my $Name ( sort keys %NotificationList ) {

        if ( @Jobs && !grep{ $_ eq $Name }@Jobs ) {
            next NAME;
        }

        my %Notification = $NotificationObject->NotificationGet(
            Name => $Name,
        );

        # check if  the job should be run now
        my $PrevRunJob = $CronObject->PreviousEventGet(
            Schedule  => $Notification{CronData}->{CronString},
            StartTime => $Now,
        );

        my $Key     = join '::', 'ByJob', $Name;
        my $LastRun = $NotificationObject->NotificationLastRunGet( Name => $Key );

        my $PrevRunJobEpoch = $TimeObject->TimeStamp2SystemTime(
             String => $PrevRunJob,
        );

        if ( $DEBUG ) {
            $LogObject->Log(
                Priority => 'debug',
                Message  => "PrevRunJob: $PrevRunJob // Epoche: $PrevRunJobEpoch // LastRun: $LastRun",
            );
        }

        if ( $PrevRunJobEpoch <= $LastRun ) {
            if ( $DEBUG ) {
                $LogObject->Log(
                    Priority => 'debug',
                    Message  => "Skip $Name: NextRun not in time frame",
                );
            }

            next NAME;
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

        $NotificationObject->NotificationLastRunSet(
            Name    => $Key,
            LastRun => $Now,
        );
    }


    $Self->Print("<green>Done.</green>\n");
}

sub _SendNotificationsByItem {
    my ($Self, %Param) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $SendObject         = $Kernel::OM->Get('Kernel::System::PerlServices::CINotificationsSend');
    my $ConfigItemObject   = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $NotificationObject = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
    my $UtilsObject        = $Kernel::OM->Get('Kernel::System::PerlServices::CINotificationsUtils');
    my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
    my $CronObject         = $Kernel::OM->Get('Kernel::System::CronEvent');

    my %NotificationList = $NotificationObject->NotificationList( Valid => 1 );

    my $DEBUG = $ConfigObject->Get('CINotifications::Debug');

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'debug',
            Message  => $MainObject->Dump( \%NotificationList ),
        );
    }

    my $Now = $Param{Now};
    my $Min = $Param{Min};

    NAME:
    for my $Name ( sort keys %NotificationList ) {

        my %Notification = $NotificationObject->NotificationGet(
            Name => $Name,
        );

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

        my $Search = [
            {
                "[1]{'Version'}[1]{'CronData'}[%]{'Content'}" => '%',
                "[1]{'Version'}[1]{'CronData'}[%]{'NotificationName'}[1]{'Content'}" => $Name,
            }
        ];

        my $ConfigItemIDs = $ConfigItemObject->ConfigItemSearchExtended(
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

        CONFIGITEMID:
        for my $ConfigItemID ( @{ $ConfigItemIDs } ) {
            my $ConfigItem = $ConfigItemObject->VersionGet(
                ConfigItemID => $ConfigItemID,
            );

            CRONDATA:
            for my $CronData ( @{ $ConfigItem->{XMLData}->[1]->{Version}->[1]->{CronData} || [] } ) {
                next CRONDATA if !$CronData;
                    if ( $DEBUG ) {
                        $LogObject->Log(
                            Priority => 'debug',
                            Message  => $MainObject->Dump( [ $CronData, $Name ] ),
                        );
                    }

                next CRONDATA if $CronData->{NotificationName}->[1]->{Content} ne $Name;

                # check if  the job should be run now
                my $PrevRunJob = $CronObject->PreviousEventGet(
                    Schedule  => $CronData->{Content},
                    StartTime => $Now,
                );

                my $Key     = join '::', 'ByItem', $ConfigItemID, $Name;
                my $LastRun = $NotificationObject->NotificationLastRunGet( Name => $Key );

                my $PrevRunJobEpoch = $TimeObject->TimeStamp2SystemTime(
                     String => $PrevRunJob,
                );
        
                if ( $DEBUG ) {
                    $LogObject->Log(
                        Priority => 'debug',
                        Message  => "PrevRunJob: $PrevRunJob // Epoche: $PrevRunJobEpoch // LastRun: $LastRun",
                    );
                }

                if ( $PrevRunJobEpoch <= $LastRun ) {
                    if ( $DEBUG ) {
                        $LogObject->Log(
                            Priority => 'debug',
                            Message  => "Skip $ConfigItemID: NextRun not in time frame",
                        );
                    }

                    next CRONDATA;
                }

                $SendObject->Send(
                    Notification  => \%Notification,
                    ConfigItemIDs => [ $ConfigItemID ],
                );

                $NotificationObject->NotificationLastRunSet(
                    Name    => $Key,
                    LastRun => $Now,
                );
            }
        }
    }

    $Self->Print("<green>Done.</green>\n");
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
