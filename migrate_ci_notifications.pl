#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Kernel::System::ObjectManager;

# --- CONFIGURATION (MAPPING) ---
# Add any missing mappings here if names differ between systems
my %RoleMapOverride = (
    'office_manager' => 'office_manager',
);

# --- DATA FROM OLD SYSTEM ---
my $NotificationsRaw = <<'JSON_DATA';
[DATA_PLACEHOLDER]
JSON_DATA

local $Kernel::OM = Kernel::System::ObjectManager->new();
my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');
my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
my $CIONotif   = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
my $UserObject = $Kernel::OM->Get('Kernel::System::User');
my $GCObject   = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
my $RoleObject = $Kernel::OM->Get('Kernel::System::Role');
my $ValidObject = $Kernel::OM->Get('Kernel::System::Valid');

my $Notifications = $JSONObject->Decode(Data => $NotificationsRaw);
my $ValidID = $ValidObject->ValidLookup(Valid => 'valid');

# Pre-fetch Class IDs
my %ClassMap;
my $ClassList = $GCObject->ItemList(Class => 'ITSM::ConfigItem::Class');
for my $ID (keys %$ClassList) {
    $ClassMap{$ClassList->{$ID}} = $ID;
}

# Pre-fetch DeplState IDs
my %DeplStateMap;
my $DeplStateList = $GCObject->ItemList(Class => 'ITSM::ConfigItem::DeploymentState');
for my $ID (keys %$DeplStateList) {
    $DeplStateMap{$DeplStateList->{$ID}} = $ID;
}

print "Starting migration of " . scalar(@$Notifications) . " notifications...\n";

for my $Notif (@$Notifications) {
    print "Processing: $Notif->{name}... ";

    # 1. Resolve ClassID
    my $ClassID = $ClassMap{$Notif->{class_name}};
    if (!$ClassID) {
        # Try fallback or partial match
        print "ERROR: Class '$Notif->{class_name}' not found! Skipping.\n";
        next;
    }

    # 2. Resolve UserID
    my %UserData = $UserObject->GetUserData(User => $Notif->{create_by_login});
    my $UserID = $UserData{UserID} || 1; # Fallback to root

    # 3. Handle JSON fields (Filter and Recipients)
    my $Filter = $JSONObject->Decode(Data => $Notif->{filter});
    for my $Key (keys %$Filter) {
        if ($Key =~ /DeplStateIDs/) {
            my @NewIDs;
            for my $StateName (@{$Filter->{$Key}}) {
                if ($DeplStateMap{$StateName}) {
                    push @NewIDs, $DeplStateMap{$StateName};
                } else {
                    print "Warning: DeplState '$StateName' not found. ";
                }
            }
            $Filter->{$Key} = \@NewIDs if @NewIDs;
        }
    }

    my $Recipients = $JSONObject->Decode(Data => $Notif->{recipients});
    if ($Recipients->{'Recipient.Agents'}) {
        my @NewUserIDs;
        for my $Login (@{$Recipients->{'Recipient.Agents'}}) {
            my %U = $UserObject->GetUserData(User => $Login);
            push @NewUserIDs, $U{UserID} if $U{UserID};
        }
        $Recipients->{'Recipient.Agents'} = \@NewUserIDs if @NewUserIDs;
    }
    if ($Recipients->{'Recipient.Roles'}) {
        my @NewRoleIDs;
        for my $RoleName (@{$Recipients->{'Recipient.Roles'}}) {
            my $RID = $RoleObject->RoleLookup(Role => $RoleMapOverride{$RoleName} || $RoleName);
            push @NewRoleIDs, $RID if $RID;
        }
        $Recipients->{'Recipient.Roles'} = \@NewRoleIDs if @NewRoleIDs;
    }

    # 4. Prepare params for NotificationAdd
    my %NotifData = (
        Name       => $Notif->{name},
        ClassID    => $ClassID,
        ValidID    => $ValidID,
        UserID     => $UserID,
        Events     => $JSONObject->Decode(Data => $Notif->{events}),
        Filter     => $Filter,
        Recipients => $Recipients,
        Subject    => $Notif->{subject},
        Body       => $Notif->{body},
        Comment    => $Notif->{comments} || '',
        MaxMail    => $Notif->{max_mail} || '',
        Eventname  => $Notif->{eventname} || '',
        CronData   => $JSONObject->Decode(Data => $Notif->{cron} || '{}'),
    );

    # 5. Check if exists and Add/Update
    if ($CIONotif->NotificationLookup(Name => $Notif->{name})) {
        print "Exists, updating... ";
        $CIONotif->NotificationUpdate(
            %NotifData,
            OldName => $Notif->{name},
        );
    } else {
        print "Adding... ";
        $CIONotif->NotificationAdd(%NotifData);
    }
    print "DONE.\n";
}

print "\nMigration finished.\n";
