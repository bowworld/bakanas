# --
# Kernel/System/PerlServices/CINotification.pm
# Copyright (C) 2014 - 2016 Perl-Services.de, http://perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::PerlServices::CINotification;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::System::DB
    Kernel::System::Log
    Kernel::System::Cache
    Kernel::System::Valid
    Kernel::System::JSON
    Kernel::System::GeneralCatalog
);

=head1 NAME

Kernel::System::PerlServices::CINotification - CI notification lib

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    $Self->{Cache} = {
        Type => 'PerlServicesCINotification',
        TTL  => 60 * 60 * 24 * 20,
    };

    return $Self;
}

=item NotificationList()

return a notification list as hash

    my %List = $NotificationObject->NotificationList(
        Valid => 0,
    );

=cut

sub NotificationList {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # create cachekey
    my $CacheKey;
    if ( $Param{Valid} ) {
        $CacheKey = 'PerlServicesCINotificationList::Valid';
    }
    else {
        $CacheKey = 'PerlServicesCINotificationList::All';
    }

    for my $Key (qw/Cron Events/ ) {
        if ( $Param{$Key} ) {
            $CacheKey = '::' . $Key;
        }
    }

    # check cache
    my $Cache = $CacheObject->Get(
        Type => $Self->{Cache}->{Type},
        Key  => $CacheKey,
    );

    return %{$Cache} if $Cache;

    # create sql
    my @Bind;
    my @Where;
    my $SQL = 'SELECT name FROM ps_ci_notifications ';
    if ( $Param{Valid} ) {
        my @ValidIDs = $ValidObject->ValidIDsGet();
        my $BindStrg = join ', ', ('?') x @ValidIDs;

        push @Where, " valid_id IN ( $BindStrg ) ";
        @Bind = map{ \$_ }@ValidIDs;
    }

    if ( $Param{Cron} ) {
        push @Where, " cron IS NOT NULL ";
        push @Where, " cron != '{}' ";
    }

    if ( $Param{Events} ) {
        push @Where, " events IS NOT NULL ";
        push @Where, " events != '{}' ";
    }

    if ( @Where ) {
        $SQL .= " WHERE " . join ' AND ', @Where;
    }

    return if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => \@Bind,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[0];
    }

    # set cache
    $CacheObject->Set(
        Type  => $Self->{Cache}->{Type},
        Key   => $CacheKey,
        Value => \%Data,
        TTL   => $Self->{Cache}->{TTL},
    );

    return %Data;
}

=item NotificationGet()

get a notification

    my %Notification = $NotificationObject->NotificationGet(
        Name => 'test_notification',
    );

=cut

sub NotificationGet {
    my ( $Self, %Param ) = @_;

    my $CacheObject          = $Kernel::OM->Get('Kernel::System::Cache');
    my $DBObject             = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject            = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject           = $Kernel::OM->Get('Kernel::System::JSON');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');

    # check needed stuff
    for my $Needed (qw(Name)) {
        if ( !$Param{$Needed} ) {
            if ( !$Param{LogNo} ) {
                $LogObject->Log(
                    Priority => 'error',
                    Message  => "Need $Needed!",
                );
            }

            return;
        }
    }

    # check cache
    my $Cache = $CacheObject->Get(
        Type => $Self->{Cache}->{Type},
        Key  => 'PerlServicesCINotificationGet' . $Param{Name},
    );

    return %{$Cache} if $Cache;

    # ask database
    return if !$DBObject->Prepare(
        SQL => 'SELECT name, class_id, valid_id, create_time, create_by, change_time, change_by, '
            . ' events, filter, recipients, subject, body, comments, max_mail, eventname, cron '
            . ' FROM ps_ci_notifications WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my %Data;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Data{Name}           = $Row[0];
        $Data{ClassID}        = $Row[1];
        $Data{ValidID}        = $Row[2];
        $Data{CreateTime}     = $Row[3];
        $Data{CreateBy}       = $Row[4];
        $Data{ChangeTime}     = $Row[5];
        $Data{ChangeBy}       = $Row[6];
        $Data{EventsJSON}     = $Row[7];
        $Data{FilterJSON}     = $Row[8];
        $Data{RecipientsJSON} = $Row[9];
        $Data{Subject}        = $Row[10];
        $Data{Body}           = $Row[11];
        $Data{Comment}        = $Row[12];
        $Data{MaxMail}        = $Row[13];
        $Data{Eventname}      = $Row[14];
        $Data{CronJSON}       = $Row[15];
    }

    return if !$Data{Name};

    $Data{Events} = $JSONObject->Decode(
        Data => $Data{EventsJSON},
    );

    $Data{Recipients} = $JSONObject->Decode(
        Data => $Data{RecipientsJSON},
    );

    $Data{Filter} = $JSONObject->Decode(
        Data => $Data{FilterJSON},
    );

    $Data{CronData} = $JSONObject->Decode(
        Data => $Data{CronJSON} || '{}',
    );

    $Data{Valid} = $ValidObject->ValidLookup( ValidID => $Data{ValidID} );

    my $Class = $GeneralCatalogObject->ItemGet(
        ItemID => $Data{ClassID},
    );

    $Data{Class} = $Class->{Name};

    # set cache
    $CacheObject->Set(
        Type  => $Self->{Cache}->{Type},
        Key   => 'PerlServicesCINotificationGet' . $Param{Name},
        Value => \%Data,
        TTL   => $Self->{Cache}->{TTL},
    );

    return %Data;
}

=item NotificationDelete()

delete a notification

    my %Notification = $NotificationObject->NotificationDelete(
        Name => 'test_notification',
    );

=cut

sub NotificationDelete {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    for my $Needed (qw(Name)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    return if !$DBObject->Do(
        SQL => 'DELETE FROM ps_ci_notifications WHERE name = ?',
        Bind => [
            \$Param{Name},
        ],
    );

    my $Cache = $CacheObject->CleanUp(
        Type => $Self->{Cache}->{Type},
    );

    return 1;
}

=item NotificationAdd()

add a notification

    my $True = $NotificationObject->NotificationAdd(
        Name    => 'Prio',
        ValidID => 1,
        Events
        UserID  => 1,
    );

=cut

sub NotificationAdd {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');

    # check needed stuff
    for my $Needed (qw(Name ClassID ValidID UserID Events Filter Recipients Subject Body)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    $Param{EventsJSON} = $JSONObject->Encode(
        Data => $Param{Events},
    );

    $Param{RecipientsJSON} = $JSONObject->Encode(
        Data => $Param{Recipients},
    );

    $Param{FilterJSON} = $JSONObject->Encode(
        Data => $Param{Filter},
    );

    $Param{CronJSON} = $JSONObject->Encode(
        Data => $Param{CronData},
    );

    return if !$DBObject->Do(
        SQL => 'INSERT INTO ps_ci_notifications ( name, class_id, valid_id, create_time, create_by, change_time, change_by, '
            . ' events, filter, recipients, subject, body, comments, max_mail, eventname, cron ) '
            . ' VALUES (?, ?, ?, current_timestamp, ?, current_timestamp, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
        Bind => [
            \$Param{Name},
            \$Param{ClassID},
            \$Param{ValidID},
            \$Param{UserID},
            \$Param{UserID},
            \$Param{EventsJSON},
            \$Param{FilterJSON},
            \$Param{RecipientsJSON},
            \$Param{Subject},
            \$Param{Body},
            \$Param{Comment},
            \$Param{MaxMail},
            \$Param{Eventname},
            \$Param{CronJSON},
        ],
    );

    # delete cache
    $CacheObject->CleanUp(
        Type => $Self->{Cache}->{Type},
    );

    return 1;
}

=item NotificationUpdate()

update a existing ticket priority

    my $True = $NotificationObject->NotificationUpdate(
        NotificationID     => 123,
        Name           => 'New Prio',
        ValidID        => 1,
        CheckSysConfig => 0,   # (optional) default 1
        UserID         => 1,
    );

=cut

sub NotificationUpdate {
    my ( $Self, %Param ) = @_;

    my $CacheObject = $Kernel::OM->Get('Kernel::System::Cache');
    my $DBObject    = $Kernel::OM->Get('Kernel::System::DB');
    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');
    my $JSONObject  = $Kernel::OM->Get('Kernel::System::JSON');

    for my $Needed (qw(Name ClassID ValidID UserID Events Filter Recipients Subject Body OldName)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    $Param{EventsJSON} = $JSONObject->Encode(
        Data => $Param{Events},
    );

    $Param{RecipientsJSON} = $JSONObject->Encode(
        Data => $Param{Recipients},
    );

    $Param{FilterJSON} = $JSONObject->Encode(
        Data => $Param{Filter},
    );

    $Param{CronJSON} = $JSONObject->Encode(
        Data => $Param{CronData},
    );

    return if !$DBObject->Do(
        SQL => 'UPDATE ps_ci_notifications '
            . ' SET name = ?, class_id = ?, valid_id = ?, change_time = current_timestamp, change_by = ?, '
	    . ' events = ?, filter = ?, recipients = ?, subject = ?, body = ?, comments = ?, max_mail = ?, '
            . ' eventname = ?, cron = ? '
            . ' WHERE name = ?',
        Bind => [
            \$Param{Name},
            \$Param{ClassID},
            \$Param{ValidID},
            \$Param{UserID},
            \$Param{EventsJSON},
            \$Param{FilterJSON},
            \$Param{RecipientsJSON},
            \$Param{Subject},
            \$Param{Body},
            \$Param{Comment},
            \$Param{MaxMail},
            \$Param{Eventname},
            \$Param{CronJSON},
            \$Param{OldName},
        ],
    );

    # delete cache
    $CacheObject->CleanUp(
        Type => $Self->{Cache}->{Type},
    );

    return 1;
}

=item NotificationLookup()

returns true if a notification of a given name already exists

    my $NotificationExists = $NotificationObject->NotificationLookup(
        Notification => '3 normal',
    );

=cut

sub NotificationLookup {
    my ( $Self, %Param ) = @_;

    my $LogObject   = $Kernel::OM->Get('Kernel::System::Log');

    # check needed stuff
    if ( !$Param{Name} ) {
        if ( !$Param{LogNo} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need Name!",
            );
        }

        return;
    }

    # get (already cached) priority list
    my %NotificationList = $Self->NotificationList(
        Valid => 0,
    );

    return $NotificationList{ $Param{Name} };
}

sub NotificationLastRunGet {
    my ($Self, %Param) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    if ( !$Param{Name} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need Name!",
        );

        return;
    }

    my $SQL = qq~
        SELECT last_run
        FROM ps_ci_notifications_run
        WHERE name = ?
    ~;

    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    my $LastRun = 0;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $LastRun = $Row[0];
    }

    return $LastRun;
}

sub NotificationLastRunSet {
    my ($Self, %Param) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    # check needed stuff
    for my $Key ( qw/Name LastRun/ ) {
        if ( !$Param{$Key} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Key!",
            );

            return;
        }
    }

    my $Delete = qq~
        DELETE FROM ps_ci_notifications_run
        WHERE name = ?
    ~;

    return if !$DBObject->Do(
        SQL  => $Delete,
        Bind => [ \$Param{Name} ],
    );

    my $Insert = qq~
        INSERT INTO ps_ci_notifications_run (name, last_run)
        VALUES ( ?, ? )
    ~;

    return if !$DBObject->Do(
        SQL  => $Insert,
        Bind => [ \$Param{Name}, \$Param{LastRun} ],
    );

    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut
