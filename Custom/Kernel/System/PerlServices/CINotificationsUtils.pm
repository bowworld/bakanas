package Kernel::System::PerlServices::CINotificationsUtils;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our @ObjectDependencies = qw(
    Kernel::System::PerlServices::CINotification
    Kernel::System::Time
    Kernel::System::Log
    Kernel::System::DB
    Kernel::System::Main
    Kernel::System::YAML
    Kernel::Config
    Kernel::Language
);

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub FieldsByClass {
    my ($Self, %Param) = @_;

    my $NotificationObject = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $YAMLObject         = $Kernel::OM->Get('Kernel::System::YAML');
    my $DBObject           = $Kernel::OM->Get('Kernel::System::DB');

    for my $Needed (qw(ClassID)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my $SQL = 'SELECT configitem_definition FROM configitem_definition WHERE class_id = ? ORDER BY id DESC';
    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Param{ClassID} ],
        Limit => 1,
    );

    my $Definition;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Definition = $Row[0];
    }

    return if !$Definition;

    my $DefinitionData = $YAMLObject->Load( Data => $Definition );

    return if !$DefinitionData;

    my %Opts;
    if ( $Param{NotificationName} ) {
        my %Notification = $NotificationObject->NotificationGet(
            Name => $Param{NotificationName},
        );

        $Opts{Values} = \%Notification;
    }

    my $Path   = '';
    my %Fields = $Self->_WalkDefinition(
        %Opts,
        Data => $DefinitionData,
        Path => $Path,
    );

    return %Fields;
}

sub _WalkDefinition {
    my ($Self, %Param) = @_;

    my $LanguageObject = $Kernel::OM->Get('Kernel::Language');
    my $ConfigObject   = $Kernel::OM->Get('Kernel::Config');

    my %Data;

    my $Path = $Param{Path};
    for my $Index ( 0 .. $#{ $Param{Data} } ) {
        my $Item = $Param{Data}->[$Index];

        my $SubPath = $Path . '###' . $Item->{Key};
        my $Label   = $LanguageObject->Translate( $Item->{Name} );

        my $LeveledLabel = $Param{LeveledLabel} ? $Param{LeveledLabel} . ' -> ' . $Label : $Label;

        my %ItemInfo = (
            Key          => $Item->{Key},
            Label        => $Label,
            LeveledLabel => $LeveledLabel,
            Path         => $SubPath,
            Type         => $Item->{Input}->{Type},
        );

        if ( $Item->{Input}->{Type} eq 'Date' || $Item->{Input}->{Type} eq 'DateTime' ) {
            my @Keys = grep{ $_ =~ m{\AEvent\.\Q$SubPath\E\.} }keys %{ $Param{Values}->{Events} };

            for my $Key ( @Keys ) {
                $ItemInfo{$Key} = $Param{Values}->{Events}->{$Key};
            }

            $ItemInfo{Type} = $Item->{Input}->{Type};

            $Data{Date}->{$SubPath} = \%ItemInfo,
        }
        else {
            $ItemInfo{Value} = $Param{Values}->{Filter}->{ "Filter." . $SubPath };
            push @{ $Data{Filter} }, \%ItemInfo;
        }

        my $RecipientFieldTypes = $ConfigObject->Get( 'CINotifications::RecipientFieldTypes' ) || {};
        if ( $RecipientFieldTypes->{ $Item->{Input}->{Type} } ) {
            $Data{RecipientFields}->{Data}->{$SubPath} = $LeveledLabel;
        }

        if ( $Item->{Sub} && ref $Item->{Sub} eq 'ARRAY' ) {
            my %SubData = $Self->_WalkDefinition(
                Data         => $Item->{Sub},
                Path         => $SubPath,
                Values       => $Param{Values},
                LeveledLabel => $LeveledLabel,
            );

            for my $Type ( qw(Date RecipientFields) ) {
                for my $Key ( keys %{ $SubData{$Type} } ) {
                    $Data{$Type}->{$Key} = $SubData{$Type}->{$Key};
                }
            }

            push @{ $Data{Filter} }, @{ $SubData{Filter} || [] };
        }
    }

    return %Data;
}

sub BuildSearch {
    my ($Self, %Param) = @_;

    my $NotificationObject = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
    my $LogObject          = $Kernel::OM->Get('Kernel::System::Log');
    my $TimeObject         = $Kernel::OM->Get('Kernel::System::Time');
    my $MainObject         = $Kernel::OM->Get('Kernel::System::Main');
    my $ConfigObject       = $Kernel::OM->Get('Kernel::Config');

    my $DEBUG = $ConfigObject->Get('CINotifications::Debug');

    if ( !$Param{Name} && !$Param{Notification} ) {
        $LogObject->Log(
            Priority => 'error',
            Message  => "Need either Name or Notification!",
        );

        return;
    }

    my %Notification = %{ $Param{Notification} || {} };

    if ( $Param{Name} ) {
        %Notification = $NotificationObject->NotificationGet(
            Name => $Param{Name},
        );
    }

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'debug',
            Message  => $MainObject->Dump( \%Notification ),
        );
    }

    my @Where;

    KEY:
    for my $Key ( keys %{ $Notification{Filter} || {} } ) {
        my $Filter = $Key;

        next KEY if $Filter !~ m{\#\#\#};

        $Filter =~ s{\AFilter\.}{};
        $Filter =~ s!###![1]{'Version'}[1]{'!;
        $Filter =~ s!([^#])#!$1'}!g;
        $Filter =~ s!##![%]{'!g;
        $Filter .= "'}[%]{'Content'}";

        push @Where, +{$Filter => $Notification{Filter}->{$Key} };
    }

    my $Other = {};

    KEYBASE:
    for my $KeyBase ( keys %{ $Notification{Filter} || {} } ) {
        my $Filter = $KeyBase;

        next KEYBASE if $Filter =~ m{\#\#\#};

        $Filter =~ s/Filter\.//;

        $Other->{$Filter} = $Notification{Filter}->{$KeyBase};
    }

    my %EventsHash;
    for my $Key ( keys %{ $Notification{Events} } ) {
        my $Event = $Key;

        $Event =~ s{\AEvent\.}{};
        my ($Field, $Info) = $Event =~ m{\A(.*)\.(\w+)\z};

        my $OrigField = $Field;

        $Field =~ s!###![1]{'Version'}[1]{'!;
        $Field =~ s!([^#])#!$1'}!g;
        $Field =~ s!##![%]{'!g;
        $Field .= "'}[%]{'Content'}";

        $EventsHash{$OrigField}->{$Info}    = $Notification{Events}->{$Key};
        $EventsHash{$OrigField}->{XMLField} = $Field;
    }

    my $MINUTE = 60;
    my $HOUR   = 60 * $MINUTE;
    my $DAY    = 24 * $HOUR;
    my $WEEK   = 7 * $DAY;

    FIELD:
    for my $Field ( keys %EventsHash ) {
        my $Type = $Self->_FieldType(
            ClassID => $Notification{ClassID},
            Field   => $Field,
        );
        
        my $FieldInfo = $EventsHash{$Field};
        my $Op        = '-between';

        if ( $FieldInfo->{SearchType} eq 'TimePoint' ) {
            my $CurrentTime = $TimeObject->SystemTime();

            my $Amount    = $FieldInfo->{TimePoint} || 1;
            my $Format    = lc $FieldInfo->{TimePointFormat} || 'minute';
            my $Direction = $FieldInfo->{TimePointStart};

            my $Factor    = lc $Direction eq 'next' ? 1 : -1;

            my @CurrentInfo = $TimeObject->SystemTime2Date(
                SystemTime => $CurrentTime,
            );

            my $TargetEpoche;
            if ( $Format eq 'minute' ) {
                $TargetEpoche = $CurrentTime + ( $Factor * $Amount * $MINUTE );
            }
            elsif ( $Format eq 'hour' ) {
                $TargetEpoche = $CurrentTime + ( $Factor * $Amount * $HOUR );
            }
            elsif ( $Format eq 'day' ) {
                $TargetEpoche = $CurrentTime + ( $Factor * $Amount * $DAY );
            }
            elsif ( $Format eq 'week' ) {
                $TargetEpoche = $CurrentTime + ( $Factor * $Amount * $WEEK );
            }
            elsif ( $Format eq 'month' ) {
                my $Years  = int ( $Amount / 12 );
                my $Months = $Amount % 12;

                my $Month  = $CurrentInfo[4] + ( $Factor * $Months );
                if ( $Month > 12 ) {
                    $Years++;
                    $Month -= 12;
                }
                elsif ( $Month <= 0 ) {
                    $Years++;
                    $Month = 12 + $Month;
                }

                my $Year           = $CurrentInfo[5] + ( $Factor * $Years );
                my $LastDayOfMonth = $Self->_GetLastDayOfMonth(
                    Month => $Month,
                    Year  => $Year,
                );

                my $Day = $CurrentInfo[3];
                $Day    = $LastDayOfMonth if $Day > $LastDayOfMonth;

                $TargetEpoche = $TimeObject->Date2SystemTime(
                    Year   => $Year,
                    Month  => $Month,
                    Day    => $Day,
                    Hour   => $CurrentInfo[2],
                    Minute => $CurrentInfo[1],
                    Second => 0,
                );
            }
            elsif ( $Format eq 'year' ) {
                my $Year           = $CurrentInfo[5] + ( $Factor * $Amount );
                my $LastDayOfMonth = $Self->_GetLastDayOfMonth(
                    Month => $CurrentInfo[4],
                    Year  => $Year,
                );

                my $Day = $CurrentInfo[3];
                $Day    = $LastDayOfMonth if $Day > $LastDayOfMonth;

                $TargetEpoche = $TimeObject->Date2SystemTime(
                    Year   => $Year,
                    Month  => $CurrentInfo[4],
                    Day    => $Day,
                    Hour   => $CurrentInfo[2],
                    Minute => $CurrentInfo[1],
                    Second => 0,
                );
            }

            my @TargetInfo = $TimeObject->SystemTime2Date(
                SystemTime => $TargetEpoche,
            );

            my @Keys = qw/
                TimeStartSecond TimeStartMinute TimeStartHour TimeStartDay TimeStartMonth TimeStartYear
                TimeStopSecond TimeStopMinute TimeStopHour TimeStopDay TimeStopMonth TimeStopYear
            /;

            if ( $Factor < 0 ) {
                @{ $FieldInfo }{@Keys} = (
                    @TargetInfo[0 .. 5],
                    @CurrentInfo[0 .. 5],
                );
            }
            else {
                @{ $FieldInfo }{@Keys} = (
                    @CurrentInfo[0 .. 5],
                    @TargetInfo[0 .. 5],
                );
            }

            if ( lc $Direction eq 'before' ) {
                $Op = '<';
            }
        }

        my @Parts  = qw(Year Month Day);
        my $Format = '%04d-%02d-%02d';
        if ( $Type eq 'DateTime' ) {
            push @Parts, qw(Hour Minute Second);
            $Format .= ' %02d:%02d:%02d';
        }

        my @BeginEnd;
        for my $Prefix ( qw/TimeStart TimeStop/ ) {
            my @TmpParts = map{ $Prefix . $_ }@Parts;
            push @BeginEnd, sprintf $Format, @{ $FieldInfo }{@TmpParts};
        }

        my $XMLField = $FieldInfo->{XMLField};
        if ( $Op eq '<' ) {
            push @Where, +{ $XMLField  => { '<' => $BeginEnd[0] } };
        }
        else {
            push @Where, +{ $XMLField  => { '-between' => \@BeginEnd } };
        }
    }

    if ( $DEBUG ) {
        $LogObject->Log(
            Priority => 'debug',
            Message  => $MainObject->Dump( [ \@Where, $Other ] ),
        );
    }

    return \@Where, $Other;
}

sub _FieldType {
    my ($Self, %Param) = @_;

    my $LogObject  = $Kernel::OM->Get('Kernel::System::Log');
    my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
    my $YAMLObject = $Kernel::OM->Get('Kernel::System::YAML');

    for my $Needed (qw(ClassID Field)) {
        if ( !$Param{$Needed} ) {
            $LogObject->Log(
                Priority => 'error',
                Message  => "Need $Needed!",
            );

            return;
        }
    }

    my $SQL = 'SELECT configitem_definition FROM configitem_definition WHERE class_id = ? ORDER BY id DESC';
    return if !$DBObject->Prepare(
        SQL   => $SQL,
        Bind  => [ \$Param{ClassID} ],
        Limit => 1,
    );

    my $Definition;
    while ( my @Row = $DBObject->FetchrowArray() ) {
        $Definition = $Row[0];
    }

    return if !$Definition;

    my $DefinitionData = $YAMLObject->Load( Data => $Definition );

    return if !$DefinitionData;

    my $LoopCounter = 0;
    my $Field       = $Param{Field};
    my $FieldType;

    LOOP:
    while ( 1 ) {
        last LOOP if ++$LoopCounter == 15;

        my ($Level, $Rest) = $Field =~ m{
            \A
            \#\#\#(.*?)
            (\#\#\#.*)?
            \z
        }xms;

        my ($Info) = grep{ $_->{Key} eq $Level }@{ $DefinitionData };

        if ( !$Rest ) {
            $FieldType = $Info->{Input}->{Type};
            last LOOP;
        }

        last LOOP if !$Info->{Sub};

        $DefinitionData = $Info->{Sub};
        $Field          = $Rest;
    }

    return $FieldType;
}

sub _GetLastDayOfMonth {
    my ($Self, %Param) = @_;

    my ($Month, $Year) = @Param{qw/Month Year/};

    my %DayMap = (
        1 => 31, 3 => 31, 4 => 30, 5 => 31, 6 => 30, 7 => 31,
        8 => 31, 9 => 30, 10 => 31, 11 => 30, 12 => 31,
    );

    my $Day = $DayMap{$Month};
    return $Day if defined $Day;

    # february is a special case... in leap years feb has 29 days, 28 otherwise
    if ( ($Year % 400 && ( $Year % 100 == 0 ) ) || $Year % 4 ) {
        return 28;
    }

    return 29;
}

1;
