package Kernel::System::PerlServices::CINotificationsSend;

use strict;
use warnings;

use base 'Kernel::System::EventHandler';

our @ObjectDependencies = qw(
    Kernel::Config
    Kernel::System::DB
    Kernel::System::Log
    Kernel::System::Main
    Kernel::System::PerlServices::CINotificationsUtils
    Kernel::System::Time
    Kernel::System::Email
    Kernel::System::Group
    Kernel::System::ITSMConfigItem
    Kernel::System::CustomerUser
    Kernel::System::User
    Kernel::System::Queue
    Kernel::System::Ticket
    Kernel::System::Ticket::Article
    Kernel::System::LinkObject
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    # init of event handler
    $Self->EventHandlerInit(
        Config => 'CINotifications::EventModulePost',
    );

    return $Self;
}

sub Send {
    my ($Self, %Param) = @_;

    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject           = $Kernel::OM->Get('Kernel::System::DB');
    my $GroupObject        = $Kernel::OM->Get('Kernel::System::Group');
    my $UserObject         = $Kernel::OM->Get('Kernel::System::User');
    my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');
    my $ConfigItemObject   = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');
    my $UtilsObject        = $Kernel::OM->Get('Kernel::System::PerlServices::CINotificationsUtils');
    my $CustomerUserObject = $Kernel::OM->Get('Kernel::System::CustomerUser');
    my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');
    my $EmailObject        = $Kernel::OM->Get('Kernel::System::Email');
    my $QueueObject        = $Kernel::OM->Get('Kernel::System::Queue');
    my $TicketObject       = $Kernel::OM->Get('Kernel::System::Ticket');
    my $ArticleObject      = $Kernel::OM->Get('Kernel::System::Ticket::Article');
    my $LinkObject         = $Kernel::OM->Get('Kernel::System::LinkObject');

    my $DEBUG = $ConfigObject->Get('CINotifications::Debug');

    for my $Needed ( qw/Notification ConfigItemIDs/ ) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my %Notification    = %{ $Param{Notification} };
    my %NotifRecipients = %{ $Notification{Recipients} || {} };
    my %Recipients;

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => $MainObject->Dump( $Param{ConfigItemIDs} ),
        );
    }

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => $MainObject->Dump( \%Notification ),
        );
    }

    # get all the recipient mail addresses
    for my $GroupID ( @{ $NotifRecipients{'Recipient.Groups'} || [] } ) {
        my @UserIDs = $GroupObject->GroupMemberList(
            GroupID => $GroupID,
            Type    => 'ro',
            Result  => 'ID',
        );

        push @{ $NotifRecipients{'Recipient.Agents'} }, @UserIDs;
    }

    for my $RoleID ( @{ $NotifRecipients{'Recipient.Roles'} || [] } ) {
        my @UserIDs = $GroupObject->GroupUserRoleMemberList(
            RoleID => $RoleID,
            Result => 'ID',
        );

        push @{ $NotifRecipients{'Recipient.Agents'} }, @UserIDs;
    }

    my %UsersSeen;

    USERID:
    for my $UserID ( @{ $NotifRecipients{'Recipient.Agents'} || [] } ) {

        next USERID if $UsersSeen{$UserID}++;

        my %User = $UserObject->GetUserData(
            UserID => $UserID,
        );

        $Recipients{ $User{UserEmail} } = 1;
    }

    if ( $NotifRecipients{'RecipientEmail'} ) {
        my $Address = $NotifRecipients{RecipientEmail};
        $Recipients{ $Address } = 1;
    }

    my $NotificationName = $Notification{Name};
    my $Now              = $TimeObject->SystemTime();
    my $SendDiff         = $Notification{MaxMail} || 'daily';

    my %DiffMap = (
        immediately => 0,
        daily       => 86_400,
        weekly      => 7 * 86_400,
    );

    if ( !defined $DiffMap{$SendDiff} ) {
        my ( $Sec, $Min, $Hour, $Day, $Month, $Year) = $TimeObject->SystemTime2Date(
            SystemTime => $Now,
        );

        if ( $SendDiff eq 'monthly' ) {
            $Month--;

            if ( $Month == 0 ) {
                $Month = 12;
                $Year--;
            }

            my $LastDayOfMonth = $Self->_GetLastDayOfMonth(
                Month => $Month,
                Year  => $Year,
            );

            $Day = $LastDayOfMonth if $Day > $LastDayOfMonth;;

            my $TargetEpoche = $TimeObject->Date2SystemTime(
                Year   => $Year,
                Month  => $Month,
                Day    => $Day,
                Hour   => $Hour,
                Minute => $Min,
                Second => 0,
            );

            $DiffMap{monthly} = $Now - $TargetEpoche;
        }
        elsif ( $SendDiff eq 'monthly_first' ) {
            return if $Day != 1;
        }
        elsif ( $SendDiff eq 'monthly_last' ) {
            my $LastDayOfMonth = $Self->_GetLastDayOfMonth(
                Month => $Month,
                Year  => $Year,
            );

            return 1 if $Day != $LastDayOfMonth;
        }
        elsif ( $SendDiff eq 'quarterly_first' ) {
            return 1 if !( $Day == 1 && (  $Month % 3 == 1 ) );
        }
        elsif ( $SendDiff eq 'quarterly_last' ) {
            my $LastDayOfMonth = $Self->_GetLastDayOfMonth(
                Month => $Month,
                Year  => $Year,
            );

            return 1 if $Day != $LastDayOfMonth || $Month % 3;
        }
        elsif ( $SendDiff eq 'quarterly_middle' ) {
            return 1 if !( $Day == 15 && ($Month % 3 == 2 ) );
        }
    }

    my $MinDiff = defined $DiffMap{$SendDiff} ? $DiffMap{$SendDiff} : $DiffMap{daily};

    my $NotificationAddress = sprintf '"%s"<%s>',
        $ConfigObject->Get('NotificationSenderName')  || 'OTRS Notification Master',
        $ConfigObject->Get('NotificationSenderEmail') || 'otrs@localhost';

    my %TypesConfig = %{ $ConfigObject->Get('CINotifications::RecipientFieldTypes') || {} };

    my $Priority = $ConfigObject->Get('CINotifications::Priority') || '3 normal';
    my $State    = $ConfigObject->Get('CINotifications::State')    || 'new';
    my $Owner    = $ConfigObject->Get('CINotifications::Owner')    || 'root@localhost';
    my $OwnerID  = $UserObject->UserLookup( UserLogin => $Owner );
    
    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'notice',
            Message  => $MainObject->Dump( [ $Priority, $State, $Owner, $OwnerID ] ),
        );
    }

    my $UseCIOwnerAsCustomer = $ConfigObject->Get('CINotifications::UseCIOwnerAsCustomer');
    my $DefaultCustomer      = $ConfigObject->Get('CINotifications::CustomerDefault')  || 'root@localhost';
    my $CIOwnerAttribute     = $ConfigObject->Get('CINotifications::CIOwnerAttribute') || 'Owner';
    my $LinkType             = $ConfigObject->Get('CINotifications::LinkType')         || 'RelevantTo';

    for my $ConfigItemID ( @{ $Param{ConfigItemIDs} || [] } ) {
        my $CI = $ConfigItemObject->VersionGet(
            ConfigItemID => $ConfigItemID,
            XMLDataGet   => 1,
        );
    
        my $CustomerUserID = $CI->{XMLData}->[1]->{Version}->[1]->{$CIOwnerAttribute}->[1]->{Content} ||
            $DefaultCustomer;

        $CustomerUserID = $DefaultCustomer if !$UseCIOwnerAsCustomer;

        my %Customer = $CustomerUserObject->CustomerUserDataGet(
            User => $CustomerUserID,
        );

        my $CustomerID = $Customer{UserCustomerID} || $CustomerUserID;

        my %XMLData = $Self->_CreateXMLData( CI => $CI );

        my $Subject = $Notification{Subject};
        my $Body    = $Notification{Body};
    
        for my $Elem ( $Subject, $Body ) {
            $Elem = $Self->_Replace(
                String       => $Elem,
                Notification => $Param{Notification},
                ConfigItem   => $CI,
                XMLData      => \%XMLData,
            );
        }
   
        my %CIRecipients;

        FIELD:
        for my $Field ( @{ $NotifRecipients{'Recipient.Field'} || [] } ) {
            my $Type = $UtilsObject->_FieldType(
                ClassID => $Notification{ClassID},
                Field   => $Field,
            );
    
            next FIELD if !$Type;

            $Field =~ s!###![1]{'Version'}[1]{'!;
            $Field =~ s!([^#])#!$1'}!g;
            $Field =~ s!##![%]{'!g;
            $Field .= "'}[%]{'Content'}";

            my $XMLType = 'ITSM::ConfigItem::' . $Notification{ClassID};

            my $SQL = 'SELECT xml_content_value FROM xml_storage s '
                . '     INNER JOIN configitem_version v ON v.id = s.xml_key '
                . ' WHERE xml_content_key LIKE ? '
                . '     AND s.xml_type = ? '
                . '     AND v.configitem_id = ?';

            next FIELD if !$DBObject->Prepare(
                SQL   => $SQL,
                Limit => 1,
                Bind  => [
                    \$Field,
                    \$XMLType,
                    \$ConfigItemID,
                ],
            );

            my $FieldValue;
            while ( my @Row = $DBObject->FetchrowArray() ) {
                $FieldValue = $Row[0];
            }

            next FIELD if !$FieldValue;
    
            if ( $Type eq 'Customer' ) {
                my %CustomerUser = $CustomerUserObject->CustomerUserDataGet(
                    User => $FieldValue,
                );

                $CIRecipients{ $CustomerUser{UserEmail} } = 1;
            }
            elsif ( $Type eq 'Agent' ) {
                my %User = $UserObject->GetUserData(
                    UserID => $FieldValue,
                );

                $CIRecipients{ $User{UserEmail} } = 1;
            }
            else {
                my $Module = $TypesConfig{ $Type };
                next FIELD if !$Module;

                next FIELD if !$MainObject->Require( $Module );

                my $Object = $Module->new( %{$Self} );
                next FIELD if !$Object;

                my $Value  = $Object->GetAddress( $FieldValue );
                next FIELD if !$Value;

                $CIRecipients{$Value} = 1;
            }
        }

        my %History = $Self->_GetHistory(
            Name         => $NotificationName,
            ConfigItemID => $ConfigItemID,
        );
    
        ADDRESS:
        for my $Address ( keys %Recipients, keys %CIRecipients ) {
            my $LastMail = $History{$NotificationName}->{$Address} || '-1';
            my $TimeDiff = $Now - $LastMail;
            next ADDRESS if $TimeDiff < $MinDiff;

            $EmailObject->Send(
                From     => $NotificationAddress,
                To       => $Address,
                Subject  => $Subject,
                Charset  => 'utf-8',
                MimeType => 'text/plain', # "text/plain" or "text/html"
                Body     => $Body,
            );

            $ConfigItemObject->HistoryAdd(
                ConfigItemID => $ConfigItemID,
                HistoryType  => 'CINotificationSend',
                Comment      => join( '%%', $NotificationName, $Now, $Address ),
                UserID       => 1,
            );
        }

        QUEUE:
        for my $QueueID ( @{ $NotifRecipients{'Recipient.Queues'} || [] } ) {

            my $LastTicket = $History{$NotificationName}->{"Queue: $QueueID"} || '-1';
            my $TimeDiff   = $Now - $LastTicket;
            next QUEUE if $TimeDiff < $MinDiff;

            my $TicketID = $TicketObject->TicketCreate(
                QueueID      => $QueueID,
                Title        => $Subject,
                Lock         => 'unlock',
                Priority     => $Priority,
                State        => $State,
                OwnerID      => $OwnerID,
                CustomerUser => $CustomerUserID,
                CustomerID   => $CustomerID,
                UserID       => $Param{UserID} || 1,
            );

            next QUEUE if !$TicketID;

            my %To = $QueueObject->GetSystemAddress( QueueID => $QueueID );

            my $BackendObject = $ArticleObject->BackendForChannel( ChannelName => 'Email' );

            $BackendObject->ArticleCreate(
                From                 => $NotificationAddress,
                To                   => $To{Email},
                TicketID             => $TicketID,
                IsVisibleForCustomer => 0,
                SenderType           => 'system',
                Subject              => $Subject,
                Body                 => $Body,
                MimeType             => $Notification{ContentType} || 'text/plain',
                Charset              => 'utf-8',
                HistoryType          => 'AddNote',
                HistoryComment       => '%%',
                UserID               => $Param{UserID} || 1,
            );

            $ConfigItemObject->HistoryAdd(
                ConfigItemID => $ConfigItemID,
                HistoryType  => 'CINotificationSend',
                Comment      => join( '%%', $NotificationName, $Now, "Queue: $QueueID" ),
                UserID       => 1,
            );

            $LinkObject->LinkAdd(
                SourceObject => 'Ticket',
                SourceKey    => $TicketID,
                TargetObject => 'ITSMConfigItem',
                TargetKey    => $ConfigItemID,
                Type         => $LinkType,
                State        => 'Valid',
                UserID       => $Param{UserID} || 1,
            );

        }

        if ( $Notification{Eventname} ) {

            # trigger event
            $Self->EventHandler(
                Event => 'CINotification_' . $Notification{Eventname},
                Data  => {
                    ConfigItemID => $ConfigItemID,
                    ConfigItem   => $CI,
                },
                UserID => $Param{UserID} || 1,
            );
        }
    }

    return 1;
}

sub _Replace {
    my ($Self, %Param) = @_;

    my $LogObject    = $Kernel::OM->Get('Kernel::System::Log');
    my $ConfigObject = $Kernel::OM->Get('Kernel::Config');

    for my $Needed ( qw/String Notification ConfigItem/ ) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my $Text = $Param{String};

    my $Start = '<';
    my $End   = '>';

    my $Tag = $Start . 'OTRS_CI_XML_';

    my %XMLData = %{ $Param{XMLData} || {} };

    KEY:
    for my $Key ( sort keys %XMLData ) {
        my $Value = $XMLData{$Key};

        next KEY if !defined $Value;

        $Text =~ s{ $Tag \Q$Key\E $End }{$Value}gxmsi;
    }

    # cleanup
    $Text =~ s{ $Tag .+? $End}{-}xmsgi;

    $Tag = $Start . 'OTRS_CI_';

    KEY:
    for my $Key ( sort keys %{ $Param{ConfigItem} } ) {
        my $Value = $Param{ConfigItem}->{$Key};

        next KEY if !defined $Value;

        $Text =~ s{ $Tag $Key $End }{$Value}gxmsi;
    }

    # cleanup
    $Text =~ s{ $Tag .+? $End}{-}xmsgi;

    $Tag = $Start . 'OTRS_CINOTIFICATION_';

    KEY:
    for my $Key ( sort keys %{ $Param{Notification} } ) {
        my $Value = $Param{Notification}->{$Key};

        next KEY if !defined $Value;

        $Text =~ s{ $Tag $Key $End }{$Value}gxmsi;
    }

    $Tag = $Start . 'OTRS_CONFIG_';
    $Text =~ s{$Tag(.+?)$End}{$ConfigObject->Get($1)}egx;

    # cleanup
    $Text =~ s/$Tag.+?$End/-/gi;


    return $Text;
}

sub _CreateXMLData {
    my ($Self, %Param) = @_;

    my %Data;

    my $Version     = $Param{CI}->{XMLData}->[1]->{Version}->[1];
    my $TypeMapping = $Self->_BuildTypeMapping( Definition => $Param{CI}->{XMLDefinition} );

    KEY:
    for my $Key ( keys %{ $Version } ) {
        %Data = (
            %Data,
            $Self->_XMLDataSub(
                Key   => $Key,
                Data  => $Version->{$Key},
                Types => $TypeMapping,
            ),
        );
    }

    return %Data;
}

sub _XMLDataSub {
    my ($Self, %Param) = @_;
    
    my %Data;

    my $Counter = 1;

    return if 'ARRAY' ne ref $Param{Data};

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $CIObject     = $Kernel::OM->Get('Kernel::System::ITSMConfigItem');

    ELEM:
    for my $Elem ( @{ $Param{Data} || [] } ) {
        next ELEM if !defined $Elem;

        my $Key        = sprintf '%s.[%s]', $Param{Key}, $Counter;
        my $MappingKey = sprintf '%s.[1]',  $Param{Key}, $Counter;

        $Data{$Key} = delete $Elem->{Content};
        delete $Elem->{TagKey};

        if ( $Param{Types}->{$MappingKey} && $Param{Types}->{$MappingKey}->{Type} !~ m{\A Text (?:Area)? \z}xms ) {

            # create output string
            $Data{$Key} = $CIObject->XMLValueLookup(
                Value => $Data{$Key},
                Item  => $Param{Types}->{$MappingKey}->{Item},
            );
        }

        for my $SubKey ( keys %{ $Elem } ) {
            %Data = (
                %Data,
                $Self->_XMLDataSub(
                    Key   => $Key . '.' . $SubKey,
                    Data  => $Elem->{$SubKey},
                    Types => $Param{Types},
                ),
            );
        }

        $Counter++;
    }

    return %Data;
}

sub _BuildTypeMapping {
    my ($Self, %Param) = @_;

    my %Mapping = $Self->_WalkDefinition(
        %Param,
        Key => '',
    ) ;

    return \%Mapping;
}

sub _WalkDefinition {
    my ($Self, %Param) = @_;

    my $Definition = $Param{Definition};
    my $Path       = $Param{Key};

    my %Data;

    for my $Elem ( @{ $Definition } ) {
        my $LocalPath = $Path ? $Path . '.' : '';
        $LocalPath   .= $Elem->{Key} . '.[1]';

        $Data{$LocalPath}->{Type} = $Elem->{Input}->{Type} // 'Text';
        $Data{$LocalPath}->{Item} = $Elem;

        if ( $Elem->{Sub} && ref $Elem->{Sub} eq 'ARRAY' ) {
            %Data = (
                %Data,
                $Self->_WalkDefinition(
                    Definitioin => $Elem->{Sub},
                    Key         => $LocalPath,
                )
            )
        }
    }

    return %Data;
}

sub _GetHistory {
    my ($Self, %Param) = @_;

    my $LogObject = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject  = $Kernel::OM->Get('Kernel::System::DB');

    for my $Needed ( qw/Name ConfigItemID/ ) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my $SQL = 'SELECT content FROM configitem_history ch '
        . '     INNER JOIN configitem_history_type cht ON ch.type_id = cht.id '
        . ' WHERE cht.name = \'CINotificationSend\' '
        . '     AND ch.configitem_id = ? '
        . ' ORDER BY ch.id';

    return if !$DBObject->Prepare(
        SQL  => $SQL,
        Bind => [ \$Param{ConfigItemID} ],
    );

    my %History;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        my $Content = $Row[0];

        my ($EventName,$Time,$Address) = $Content =~ m{
            ([^\%]+) \%\%
            ([0-9]+) \%\%
            (.*)
        }xms;

        $History{$EventName}->{$Address} = $Time;
    }

    return %History;
}

sub _GetLastDayOfMonth {
    my ($Self, %Param) = @_;

    my ($Month, $Year) = @Param{qw/Month Year/};

    my %DayMap = (
        1 => 31, 3 => 31, 4 => 30, 5 => 31, 6 => 30, 7 => 31,
        8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31,
    );

    my $Day = $DayMap{$Month+0};
    return $Day if defined $Day;

    # february is a special case... in leap years feb has 29 days, 28 otherwise
    if ( ($Year % 400 && ( $Year % 100 == 0 ) ) || $Year % 4 ) {
        return 28;
    }

    return 29;
}

1;
