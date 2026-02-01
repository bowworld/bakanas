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
[
    {
        "name": "1 месяц до истечения ключа на Eaton",
        "class_id": "281",
        "valid_id": "1",
        "events": "{\"Event.###KeysValidtillDate.TimePoint\":\"1\",\"Event.###KeysValidtillDate.TimePointStart\":\"Last\",\"Event.###KeysValidtillDate.SearchType\":\"TimePoint\",\"Event.###KeysValidtillDate.TimePointFormat\":\"month\"}",
        "cron": "{}",
        "filter": "{\"Filter.###Vendor\": \"EATON\"}",
        "recipients": "{\"Recipient.Agents\": [\"bz\", \"idedik\", \"sz\"]}",
        "subject": "Истекает срок лицензии на ПО Eaton",
        "body": "Внимание!\nИстекает срок лицензии на ПО EATON: <OTRS_CI_Name>.\nЛицензия действительна до: <OTRS_CI_XML_KeysValidtillDate.[1]>.\nЛицензия установлена на компьютере: <OTRS_CI_XML_Computer.[1]>.",
        "max_mail": "daily",
        "comments": null,
        "eventname": null,
        "create_time": "2022-09-13 16:02:31",
        "create_by": "2",
        "change_time": "2022-09-13 16:02:31",
        "change_by": "2",
        "class_name": "Keys",
        "create_by_login": "sz",
        "change_by_login": "sz"
    },
    {
        "name": "Истек срок медсправки для офис-менеджера",
        "class_id": "198",
        "valid_id": "1",
        "events": "{\"Event.###EndDate.SearchType\":\"TimePoint\",\"Event.###EndDate.TimePoint\":\"1\",\"Event.###EndDate.TimePointFormat\":\"week\",\"Event.###EndDate.TimePointStart\":\"Before\"}",
        "cron": "{}",
        "filter": "{\"Filter.DeplStateIDs\": [\"Approvals::разрешено\"]}",
        "recipients": "{\"Recipient.Agents\": [\"office\"]}",
        "subject": "Истек срок медсправки для <OTRS_CI_XML_Reciever.[1]>",
        "body": "Внимание,\nистек срок медицинской справки, оформленной на <OTRS_CI_XML_Reciever.[1]>.\nМедицинская справка была действительна до: <OTRS_CI_XML_EndDate.[1]>\n\nПожалуйста,\nне забудьте направить сотрудника на повторный медицинский осмотр!\n------------------\nOTRS Vicom Plus",
        "max_mail": "weekly",
        "comments": "Истек срок медицинской справки для офис-менеджера",
        "eventname": null,
        "create_time": "2021-10-07 11:14:02",
        "create_by": "2",
        "change_time": "2021-10-08 15:47:22",
        "change_by": "2",
        "class_name": "Medical",
        "create_by_login": "sz",
        "change_by_login": "sz"
    },
    {
        "name": "Истекает срок идентификационного документа",
        "class_id": "184",
        "valid_id": "1",
        "events": "{\"Event.###ExpDate.TimePointStart\":\"Last\",\"Event.###ExpDate.SearchType\":\"TimePoint\",\"Event.###ExpDate.TimePoint\":\"1\",\"Event.###ExpDate.TimePointFormat\":\"month\"}",
        "cron": "{}",
        "filter": "{\"Filter.DeplStateIDs\": [\"Approvals::разрешено\"]}",
        "recipients": "{\"Recipient.Roles\": [\"office_manager\"]}",
        "subject": "Истекает срок действия идентификацонного документа для <OTRS_CI_XML_Vladelec.[1]>",
        "body": "<OTRS_CI_XML_ExpDate.[1]> истекает срок действия идентификационного документа, оформленного на <OTRS_CI_XML_Vladelec.[1]>.\n\nПожалуйста,\nЗаблаговременно направьте сотрудника на замену идентификационного документа.\n-----------------\nOTRS Vicom Plus",
        "max_mail": "daily",
        "comments": "за месяц до истечения срока",
        "eventname": null,
        "create_time": "2021-10-08 10:08:20",
        "create_by": "2",
        "change_time": "2022-04-14 10:30:25",
        "change_by": "2",
        "class_name": "Passport",
        "create_by_login": "sz",
        "change_by_login": "sz"
    },
    {
        "name": "Истекает срок лицензий ПО Schneider Electric",
        "class_id": "281",
        "valid_id": "1",
        "events": "{\"Event.###KeysValidtillDate.TimePoint\":\"15\",\"Event.###KeysValidtillDate.TimePointStart\":\"Last\",\"Event.###KeysValidtillDate.SearchType\":\"TimePoint\",\"Event.###KeysValidtillDate.TimePointFormat\":\"day\"}",
        "cron": "{}",
        "filter": "{\"Filter.###Vendor\": \"Schneider Electric\"}",
        "recipients": "{\"Recipient.Agents\": [\"bz\", \"idedik\", \"sz\"]}",
        "subject": "Истекает срок лицензии ПО Schneider Electric",
        "body": "Истекает срок лицензии на ПО Schneider Electric:\n<OTRS_CI_Name>.\nЛицензия действительна до: <OTRS_CI_XML_KeysValidtillDate.[1]>.\nЛицензия установлена на компьютере: <OTRS_CI_XML_Computer.[1]>.",
        "max_mail": "daily",
        "comments": null,
        "eventname": null,
        "create_time": "2022-09-12 17:08:58",
        "create_by": "2",
        "change_time": "2022-09-13 15:58:17",
        "change_by": "2",
        "class_name": "Keys",
        "create_by_login": "sz",
        "change_by_login": "sz"
    },
    {
        "name": "Медицинская справка - за неделю до истечения срока для ответственного",
        "class_id": "198",
        "valid_id": "1",
        "events": "{\"Event.###EndDate.SearchType\":\"TimePoint\",\"Event.###EndDate.TimePoint\":\"1\",\"Event.###EndDate.TimePointFormat\":\"week\",\"Event.###EndDate.TimePointStart\":\"Last\"}",
        "cron": "{}",
        "filter": "{\"Filter.DeplStateIDs\": [\"Approvals::разрешено\"]}",
        "recipients": "{\"Recipient.Roles\": [\"office_manager\"]}",
        "subject": "Срок медсправки для <OTRS_CI_XML_Reciever.[1]> истекает через неделю!",
        "body": "Внимание,\nМедицинская справка для <OTRS_CI_XML_Reciever.[1]> действительна до: <OTRS_CI_XML_EndDate.[1]>.\n\nПожалуйста,\nне забудьте заблаговременно направить сотрудника для прохождения медицинского осмотра!\n------------------\nOTRS Vicom Plus.",
        "max_mail": "weekly",
        "comments": "медицинская справка за неделю до истечения срока для ответственного",
        "eventname": null,
        "create_time": "2021-10-08 15:46:36",
        "create_by": "2",
        "change_time": "2021-10-08 15:46:36",
        "change_by": "2",
        "class_name": "Medical",
        "create_by_login": "sz",
        "change_by_login": "sz"
    },
    {
        "name": "Разрешения - за семь дней до истечения срока",
        "class_id": "141",
        "valid_id": "2",
        "events": "{\"Event.###EndDate.TimePointFormat\":\"week\",\"Event.###EndDate.TimePoint\":\"1\",\"Event.###EndDate.TimePointStart\":\"Last\",\"Event.###EndDate.SearchType\":\"TimePoint\"}",
        "cron": "{}",
        "filter": "{\"Filter.DeplStateIDs\": [\"Approvals::разрешено\", \"Maintenance\"]}",
        "recipients": "{\"Recipient.Agents\": [\"bz\"]}",
        "subject": "Истекает срок действия разрешения типа <OTRS_CI_XML_Type.[1]> для <OTRS_CI_XML_Owner.[1]>",
        "body": "<OTRS_CI_XML_Responsible.[1]>,\n\nИстекает срок действия разрешения типа - <OTRS_CI_XML_Type.[1]>,\nоформленное на <OTRS_CI_XML_Owner.[1]>.\nРазрешение действительно до <OTRS_CI_XML_EndDate.[1]>\n----------------\nOTRS Vicom Plus",
        "max_mail": "daily",
        "comments": "разрешения - за семь дней до истечения срока",
        "eventname": null,
        "create_time": "2021-10-08 15:44:37",
        "create_by": "2",
        "change_time": "2023-11-27 00:13:36",
        "change_by": "55",
        "class_name": "Approvals",
        "create_by_login": "sz",
        "change_by_login": "bz"
    },
    {
        "name": "Разрешения - истек срок",
        "class_id": "141",
        "valid_id": "2",
        "events": "{\"Event.###EndDate.TimePointFormat\":\"day\",\"Event.###EndDate.TimePoint\":\"1\",\"Event.###EndDate.TimePointStart\":\"Before\",\"Event.###EndDate.SearchType\":\"TimePoint\"}",
        "cron": "{}",
        "filter": "{\"Filter.DeplStateIDs\": [\"Approvals::разрешено\"]}",
        "recipients": "{\"Recipient.Agents\": [\"bz\"]}",
        "subject": "Истек срок действия <OTRS_CI_XML_Type.[1]> для <OTRS_CI_XML_Owner.[1]>",
        "body": "<OTRS_CI_XML_Responsible.[1]>,\n\nИстек срок действия для разрешения типа - <OTRS_CI_XML_Type.[1]>,\nоформленное на агента <OTRS_CI_XML_Owner.[1]>.\nСрок действия до - <OTRS_CI_XML_EndDate.[1]>.\n-------------------\nOTRS Vicom Plus",
        "max_mail": "weekly",
        "comments": "прошло более одного дня",
        "eventname": null,
        "create_time": "2021-10-06 13:08:55",
        "create_by": "2",
        "change_time": "2023-11-27 00:13:18",
        "change_by": "55",
        "class_name": "Approvals",
        "create_by_login": "sz",
        "change_by_login": "bz"
    },
    {
        "name": "Тюнеры ABB за две недели до окончания",
        "class_id": "281",
        "valid_id": "1",
        "events": "{\"Event.###KeysValidtillDate.SearchType\":\"TimePoint\",\"Event.###KeysValidtillDate.TimePointStart\":\"Last\",\"Event.###KeysValidtillDate.TimePoint\":\"15\",\"Event.###KeysValidtillDate.TimePointFormat\":\"day\"}",
        "cron": "{}",
        "filter": "{\"Filter.###Vendor\": \"ABB\"}",
        "recipients": "{\"Recipient.Agents\": [\"bz\", \"idedik\", \"sz\"]}",
        "subject": "Заканчивается ABB NewSET license",
        "body": "Внимание,\nзаканчивается ABB NewSET license.\nПожалуйста, направьте уведомление об оплате в местное представительство ABB (контакт: Омар Таспай). Партномер для заказа: 4NWP101322R0001 - NewSET yearly license fee. Цена за одну лицензию: 178 долларов США.",
        "max_mail": "daily",
        "comments": null,
        "eventname": null,
        "create_time": "2022-09-12 15:25:33",
        "create_by": "2",
        "change_time": "2022-09-12 15:25:33",
        "change_by": "2",
        "class_name": "Keys",
        "create_by_login": "sz",
        "change_by_login": "sz"
    }
]
JSON_DATA

local $Kernel::OM = Kernel::System::ObjectManager->new(
    'Kernel::Config' => {
        Home => '/opt/znuny',
    },
);
my $JSONObject = $Kernel::OM->Get('Kernel::System::JSON');
my $DBObject   = $Kernel::OM->Get('Kernel::System::DB');
my $CIONotif   = $Kernel::OM->Get('Kernel::System::PerlServices::CINotification');
my $UserObject = $Kernel::OM->Get('Kernel::System::User');
my $GCObject   = $Kernel::OM->Get('Kernel::System::GeneralCatalog');
my $RoleObject = $Kernel::OM->Get('Kernel::System::Group');
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
