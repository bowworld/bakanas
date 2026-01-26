# --
# Kernel/Modules/AdminCINotifications.pm
# Copyright (C) 2014 - 2018 Perl-Services.de, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Modules::AdminCINotifications;

use strict;
use warnings;

our @ObjectDependencies = qw(
    Kernel::Output::HTML::Layout
    Kernel::System::User
    Kernel::System::Web::Request
    Kernel::System::PerlServices::CINotificationsUtils
    Kernel::System::PerlServices::CINotification
    Kernel::System::Group
    Kernel::System::Valid
    Kernel::System::GeneralCatalog
    Kernel::System::CronEvent
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $ParamObject          = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $NotificationObject   = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $LogObject            = $Kernel::OM->Get('Kernel::System::Log');
    my $MainObject           = $Kernel::OM->Get('Kernel::System::Main');

    my @Params = (qw(ClassID Name OldName ValidID Subject Body Comment MaxMail ID Eventname));
    my %GetParam;
    for my $Field (@Params) {
        my $Value = $ParamObject->GetParam( Param => $Field );
        $GetParam{$Field} = $Value if length $Value;
    }

    if ( !$GetParam{ClassID} && !$GetParam{ID} ) {
        $LayoutObject->Block( Name => 'OverviewResult' );

        my %List = $NotificationObject->NotificationList( Valid => 0 );
        for my $Name ( sort keys %List ) {
            my %Notification = $NotificationObject->NotificationGet( Name => $Name );
            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => \%Notification,
            );
        }

        if ( !%List ) {
            $LayoutObject->Block( Name => 'NoDataFoundMsg' );
        }
    }
    elsif ( $Self->{Subaction} eq 'Edit' ) {
        $Self->_Mask(
            %GetParam,
            OldName => $GetParam{OldName} || $GetParam{Name},
        );
    }
    elsif ( $Self->{Subaction} eq 'Delete' ) {
        $NotificationObject->NotificationDelete(
            Name  => $GetParam{ID},
        );

        return $LayoutObject->Redirect(
            OP => 'Action=AdminCINotifications',
        );
    }
    else {
        # save or update notification
        my @ParamNames = $ParamObject->GetParamNames();

        my @FilterNames = grep{ $_ =~ m{\AFilter\.}xms }@ParamNames;
        my %Filter      = map{
            my $Value = $ParamObject->GetParam( Param => $_ );

            if ( $_ eq 'Filter.InciStateIDs' || $_ eq 'Filter.DeplStateIDs' ) {
                my @Values = $ParamObject->GetArray( Param => $_ );
                $Value = @Values ? \@Values : undef;
            }

            $Value ? ($_ => $Value) : ();
        }@FilterNames;

        $GetParam{Filter} = \%Filter;

        my @EventNames = map{
                my $Value   = $ParamObject->GetParam( Param => $_ );
                my ($Field) = $_ =~ m{Event\.(.*)\.+SearchType}xms;

                $Value = "Time(Start|Stop)" if $Value eq 'TimeSlot';

                ( $Value && $Value ne 'None' ) ?
                    ( "Event.$Field.SearchType", grep{ $_ =~ m{\AEvent\.$Field\.$Value} }@ParamNames ) :
                    ();
            } grep{
                $_ =~ m{\AEvent\..*?SearchType\z}xms
        }@ParamNames;

        my %Events = map{
            my $Value = $ParamObject->GetParam( Param => $_ );
            $Value ? ($_ => $Value) : ();
        }@EventNames;

        $GetParam{Events} = \%Events;

        my @RecipientNames = grep{ $_ =~ m{\ARecipient\.}xms }@ParamNames;
        my %Recipients     = map{
            my @Value = $ParamObject->GetArray( Param => $_ );
            @Value ? ($_ => \@Value) : ();
        }@RecipientNames;

        my $Email = $ParamObject->GetParam( Param => 'RecipientEmail' );
        $Recipients{RecipientEmail} = $Email if $Email;

        $GetParam{Recipients} = \%Recipients;

        # check for Errors
        my %Error;

        my $NameExists = $NotificationObject->NotificationLookup(
            Name  => $GetParam{Name},
            LogNo => 1,
        );

        if ( !$GetParam{Name} ) {
            $Error{NameInvalid} = ' ServerError';
        }
        elsif ( !$GetParam{OldName} && $NameExists ) {
            $Error{NameInvalid} = ' ServerError';
        }
        elsif ( $GetParam{OldName} && $GetParam{OldName} ne $GetParam{Name} && $NameExists ) {
            $Error{NameInvalid} = ' ServerError';
        }

        if ( $GetParam{Name} =~ m{[\%\#]} ) {
            $Error{NameInvalid} = ' ServerError';
        }

        # collect cron data
        my %Cron;

        CRONPARAM:
        for my $CronParam ( qw/Minutes Hours Days/ ) {
            my @Values = $ParamObject->GetArray( Param => "Cron" . $CronParam );

            next CRONPARAM if !@Values;

            $Cron{"Cron" . $CronParam} = \@Values;
        }

        my $CronString;
        if ( 3 == keys %Cron ) {
            my $Object  = $Kernel::OM->Get('Kernel::System::CronEvent');
            $CronString = $Object->GenericAgentSchedule2CronTab(
                ScheduleMinutes => $Cron{CronMinutes},
                ScheduleHours   => $Cron{CronHours},
                ScheduleDays    => $Cron{CronDays},
            );
        }

        $CronString ||= $ParamObject->GetParam( Param => 'CronString' ) || '';

        $Cron{CronString} = $CronString if $CronString;

        $GetParam{CronData} = \%Cron;

        if ( !$GetParam{Subject} ) {
            $Error{SubjectInvalid} = ' ServerError';
        }

        if ( !$GetParam{Body} ) {
            $Error{BodyInvalid} = ' ServerError';
        }

        if ( !$GetParam{ValidID} ) {
            $Error{ValidIDInvalid} = ' ServerError';
        }

        if ( %Error ) {
            for my $Key ( @ParamNames ) {
                $GetParam{$Key} = $ParamObject->GetParam( Param => $Key );
            }

            for my $Key ( keys %Recipients ) {
                $GetParam{$Key} = $Recipients{$Key};
            }

            delete $GetParam{Action};

            $Self->_Mask(
                %GetParam,
                %Error,
                OldName => $GetParam{OldName},
            );
        }
        else {
            my $Action = 'NotificationAdd';
            if ( $GetParam{OldName} ) {
                $Action = 'NotificationUpdate';
            }

            $NotificationObject->$Action(
                %GetParam,
                UserID => $Self->{UserID},
            );

            return $LayoutObject->Redirect(
                OP => 'Action=AdminCINotifications',
            );
        }
    }

    my $ClassList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    );

    $Param{ClassSelect} = $LayoutObject->BuildSelection(
        Data         => $ClassList,
        Name         => 'ClassID',
        PossibleNone => 1,
        Translation  => 0,
        Class        => 'Modernize',
    );
    
    my $Output = $LayoutObject->Header( Title => 'CI-Notifications' );

    $Output .= $LayoutObject->NavigationBar();
    $Output .= $LayoutObject->Output(
        TemplateFile => 'AdminCINotifications',
        Data         => \%Param,
    );

    $Output .= $LayoutObject->Footer();

    return $Output;
}

sub _Mask {
    my ($Self, %Param) = @_;

    my $LayoutObject         = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $NotificationObject   = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
    my $GeneralCatalogObject = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
    my $ValidObject          = $Kernel::OM->Get('Kernel::System::Valid');
    my $GroupObject          = $Kernel::OM->Get('Kernel::System::Group');
    my $QueueObject          = $Kernel::OM->Get('Kernel::System::Queue');
    my $UserObject           = $Kernel::OM->Get('Kernel::System::User');
    my $UtilsObject          = $Kernel::OM->Get('Kernel::System::PerlServices::CINotificationsUtils');

    $LayoutObject->Block( Name => 'ActionOverview' );

    my %Notification = $NotificationObject->NotificationGet(
        Name  => $Param{OldName} || $Param{Name},
        LogNo => 1,
    );

    my %Valids = $ValidObject->ValidList();
    $Param{ValidSelect} = $LayoutObject->BuildSelection(
        Name        => 'ValidID',
        Data        => \%Valids,
        SelectedID  => $Param{ValidID} || $Notification{ValidID} || 1,
        Translation => 1,
        Class       => 'Modernize',
    );

    $Param{MaxMailSelect} = $LayoutObject->BuildSelection(
        Name => 'MaxMail',
        Data => [ 
            { Key => 'immediately'      , Value => 'each match'             },
            { Key => 'daily'            , Value => 'once a day'             },
            { Key => 'weekly'           , Value => 'once a week'            },
            { Key => 'monthly'          , Value => 'once a month'           },
            { Key => 'monthly_first'    , Value => 'last day of a month'    },
            { Key => 'monthly_last'     , Value => 'first day of a month'   },
            { Key => 'quarterly_first'  , Value => 'first day of a quarter' },
            { Key => 'quarterly_middle' , Value => 'mid of a quarter'       },
            { Key => 'quarterly_last'   , Value => 'last day of a quarter'  },
        ],
        SelectedID  => $Param{MaxMail} || $Notification{MaxMail} || 'daily',
        Translation => 1,
        Class       => 'Modernize',
    );

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => { %Notification, %Param },
    );

    my $Block = 'Add';
    if ( $Param{OldName} ) {
        $Block = 'Edit';
    }

    my $ClassList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::Class',
    );

    $LayoutObject->Block(
        Name => 'Header' . $Block,
        Data => {
            ClassName => $ClassList->{ $Param{ClassID} },
        },
    );

    # show cron related fields
    $Param{CronData} ||= {};

    my $CronString  = $Param{CronData}->{CronString} || $Notification{CronData}->{CronString};

    my %Hours;
    for my $Number ( 0 .. 23 ) {
        $Hours{$Number} = sprintf( "%02d", $Number );
    }
    my $CronHours = $LayoutObject->BuildSelection(
        Data        => \%Hours,
        Name        => 'CronHours',
        Size        => 6,
        Multiple    => 1,
        Translation => 0,
        SelectedID  => $Param{CronData}->{CronHours} || $Notification{CronData}->{CronHours},
        Class       => 'Modernize',
    );

    my %Minutes;

    NUMBER:
    for my $Number ( 0 .. 55 ) {
        next NUMBER if $Number % 5;

        $Minutes{$Number} = sprintf( "%02d", $Number );
    }
    my $CronMinutes = $LayoutObject->BuildSelection(
        Data        => \%Minutes,
        Name        => 'CronMinutes',
        Size        => 6,
        Multiple    => 1,
        Translation => 0,
        SelectedID  => $Param{CronData}->{CronMinutes} || $Notification{CronData}->{CronMinutes},
        Class       => 'Modernize',
    );

    my $CronDays = $LayoutObject->BuildSelection(
        Data => {
            1 => 'Mon',
            2 => 'Tue',
            3 => 'Wed',
            4 => 'Thu',
            5 => 'Fri',
            6 => 'Sat',
            0 => 'Sun',
        },
        Sort       => 'NumericKey',
        Name       => 'CronDays',
        Size       => 7,
        Multiple   => 1,
        SelectedID => $Param{CronData}->{CronDays} || $Notification{CronData}->{CronDays},
        Class      => 'Modernize',
    );

    $LayoutObject->Block(
        Name => 'Cron',
        Data => {
            CronString          => $CronString,
            ScheduleMinutesList => $CronMinutes,
            ScheduleHoursList   => $CronHours,
            ScheduleDaysList    => $CronDays,
        },
    );

    # filter fields
    my %Fields = $UtilsObject->FieldsByClass(
        ClassID          => $Param{ClassID},
        NotificationName => $Param{Name},
    );

    for my $Field ( sort keys %{ $Fields{Date} } ) {
        my %FieldData = %{ $Fields{Date}->{$Field} };

        my $Type = 'Event.' . $FieldData{Path} . '.';

        my $SearchType = $Type . 'SearchType';
        if ( !$FieldData{$SearchType} ) {
            $FieldData{ 'SearchType::None' } = 'checked="checked"';
        }
        elsif ( $FieldData{$SearchType} eq 'TimePoint' ) {
            $FieldData{ 'SearchType::TimePoint' } = 'checked="checked"';
        }
        elsif ( $FieldData{$SearchType} eq 'TimeSlot' ) {
            $FieldData{ 'SearchType::TimeSlot' } = 'checked="checked"';
        }

        my %Counter = map{ $_ => sprintf "%02d", $_ }( 1 .. 60 );

        $FieldData{RadioName} = $SearchType;

        # time
        $FieldData{'TimePoint'} = $LayoutObject->BuildSelection(
            Data       => \%Counter,
            Name       => $Type . 'TimePoint',
            SelectedID => $Param{ $Type . 'TimePoint' } || $FieldData{ $Type . 'TimePoint' },
        );

        $FieldData{'TimePointStart'} = $LayoutObject->BuildSelection(
            Data => {
                Last   => 'within the last ...',
                Next   => 'within the next ...',
                Before => 'more than ... ago',
            },
            Name       => $Type . 'TimePointStart',
            SelectedID => $Param{ $Type . 'TimePointStart' } || $FieldData{ $Type . 'TimePointStart' } || 'Last',
        );

        my $Long = $FieldData{Type} eq 'DateTime' ? 'Long' : '';

        my %FormatOpts;

        if ( $Long ) {
            %FormatOpts = (
                minute => 'minute(s)',
                hour   => 'hour(s)',
            );
        }

        $FieldData{'TimePointFormat'} = $LayoutObject->BuildSelection(
            Data => {
                %FormatOpts,
                day    => 'day(s)',
                week   => 'week(s)',
                month  => 'month(s)',
                year   => 'year(s)',
            },
            Name       => $Type . 'TimePointFormat',
            SelectedID => $Param{ $Type . 'TimePointFormat' } || $FieldData{ $Type . 'TimePointFormat' },
        );

        $FieldData{'TimeStart'} = $LayoutObject->BuildDateSelection(
            %FieldData,
            %Param,
            Prefix   => $Type . 'TimeStart',
            Format   => 'DateInputFormat' . $Long,
            DiffTime => -( 60 * 60 * 24 ) * 30,
            Validate => 1,
        );

        $FieldData{'TimeStop'} = $LayoutObject->BuildDateSelection(
            %FieldData,
            %Param,
            Prefix   => $Type . 'TimeStop',
            Format   => 'DateInputFormat' . $Long,
            Validate => 1,
        );


        $LayoutObject->Block(
            Name => 'DateField',
            Data => {
                %FieldData,
            },
        );
    }

    $LayoutObject->Block(
        Name => 'FilterFieldName',
        Data => {
            Name  => 'Filter.Name',
            Value => $Param{'Filter.Name'} || $Notification{Filter}->{'Filter.Name'},
            Label => 'Name',
        },
    );

    my $DeplStateList = $GeneralCatalogObject->ItemList(
        Class => 'ITSM::ConfigItem::DeploymentState',
    );

    my $DeploymentState = $LayoutObject->BuildSelection(
        Name         => 'Filter.DeplStateIDs',
        Data         => $DeplStateList,
        Translation  => 1,
        Multiple     => 1,
        SelectedID   => $Param{'Filter.DeplStateIDs'} || $Notification{Filter}->{'Filter.DeplStateIDs'},
        Class        => 'Modernize',
    );

    $LayoutObject->Block(
        Name => 'FilterFieldSelect',
        Data => {
            Name   => 'Filter.DeplStateIDs',
            Select => $DeploymentState,
            Label  => 'Deployment State',
        },
    );

    my $InciStateList = $GeneralCatalogObject->ItemList(
        Class       => 'ITSM::Core::IncidentState',
        Preferences => {
            Functionality => [ 'operational', 'incident' ],
        },
    );

    my $IncidentState = $LayoutObject->BuildSelection(
        Name         => 'Filter.InciStateIDs',
        Data         => $InciStateList,
        Translation  => 1,
        Multiple     => 1,
        SelectedID   => $Param{'Filter.InciStateIDs'} || $Notification{Filter}->{'Filter.InciStateIDs'},
        Class        => 'Modernize',
    );

    $LayoutObject->Block(
        Name => 'FilterFieldSelect',
        Data => {
            Name   => 'Filter.InciStateIDs',
            Select => $IncidentState,
            Label  => 'Incident State',
        },
    );

    for my $Field ( @{ $Fields{Filter} } ) {
        $Field->{Name} = 'Filter.' . $Field->{Path};

        $Field->{Value} = $Param{ $Field->{Name} } || $Notification{Filter}->{ $Field->{Name} };

        $LayoutObject->Block(
            Name => 'FilterField',
            Data => $Field,
        );
    }

    my $FieldsInfo = $Fields{RecipientFields};
    $Param{RecipientFields} = $LayoutObject->BuildSelection(
        Name       => 'Recipient.Field',
        Data       => $FieldsInfo->{Data},
        SelectedID => $Param{'Recipient.Field'} || $Notification{Recipients}->{'Recipient.Field'},
        Multiple   => 1,
        Size       => 3,
        Class      => 'Modernize',
    );

    my %Groups = $GroupObject->GroupList( Valid => 1 );
    $Param{GroupsSelect} = $LayoutObject->BuildSelection(
        Name       => 'Recipient.Groups',
        Data       => \%Groups,
        SelectedID => $Param{'Recipient.Groups'} || $Notification{Recipients}->{'Recipient.Groups'},
        Multiple   => 1,
        Size       => 3,
        Class      => 'Modernize',
    );

    my %Roles = $GroupObject->RoleList( Valid => 1 );
    $Param{RolesSelect} = $LayoutObject->BuildSelection(
        Name       => 'Recipient.Roles',
        Data       => \%Roles,
        SelectedID => $Param{'Recipient.Roles'} || $Notification{Recipients}->{'Recipient.Roles'},
        Multiple   => 1,
        Size       => 3,
        Class      => 'Modernize',
    );

    my %Agents = $UserObject->UserList( Valid => 1, Type => 'Long' );
    $Param{AgentsSelect} = $LayoutObject->BuildSelection(
        Name       => 'Recipient.Agents',
        Data       => \%Agents,
        SelectedID => $Param{'Recipient.Agents'} || $Notification{Recipients}->{'Recipient.Agents'},
        Multiple   => 1,
        Size       => 3,
        Class      => 'Modernize',
    );

    $Param{RecipientEmail} ||= $Notification{Recipients}->{RecipientEmail};

    my %Queues = $QueueObject->QueueList( Valid => 1 );
    $Param{QueuesSelect} = $LayoutObject->BuildSelection(
        Name       => 'Recipient.Queues',
        Data       => \%Queues,
        SelectedID => $Param{'Recipient.Queues'} || $Notification{Recipients}->{'Recipient.Queues'},
        Multiple   => 1,
        Size       => 3,
        TreeView   => 1,
        Class      => 'Modernize',
    );

    $LayoutObject->Block(
        Name => 'Recipients',
        Data => \%Param,
    );
}

1;
