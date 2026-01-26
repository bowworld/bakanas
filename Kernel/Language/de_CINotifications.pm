# --
# Kernel/Language/de_CINotifications.pm - the german translation of CINotifications
# Copyright (C) 2013 - 2016 Perl-Services, http://www.perl-services.de
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::Language::de_CINotifications;

use strict;
use warnings;

use utf8;

our $VERSION = 0.04;

sub Data {
    my $Self = shift;

    my $Lang = $Self->{Translation};

    return if ref $Lang ne 'HASH';

    $Lang->{"CI Notifications"}        = 'Benachrichtigung (CI)';
    $Lang->{"Manage CI Notifications"} = 'Beanchrichtigungen für CIs verwalten';
    $Lang->{"Do not use this field."}  = 'Dieses Feld nicht berücksichtigen';
    $Lang->{"Date reached"}            = 'Datum erreicht';
    $Lang->{"Date reached between"}    = 'Datum erreicht zwischen';
    $Lang->{"Mail Frequency"}          = 'Häufigkeit der Mails';

    $Lang->{'once a month'} = 'einmal im Monat';
    $Lang->{'once a week'}  = 'einmal in der Woche';
    $Lang->{'once a day'}   = 'einmal am Tag';
    $Lang->{'each match'}   = 'bei jedem Treffer';

    $Lang->{'first day of a quarter'} = 'am ersten Tag eines Quartals';
    $Lang->{'mid of a quarter'}       = 'in der Mitte eines Quartals';
    $Lang->{'last day of a quarter'}  = 'am letzten Tag eines Quartals';

    $Lang->{'last day of a month'}  = 'am letzten Tag des Monats';
    $Lang->{'first day of a month'} = 'am ersten Tag des Monats';

    $Lang->{'CIHistory::CINotificationSend'} = 'Benachrichtigung (%s) verschickt (Timestamp: %s, Empfänger: %s)';

    return 1;
}

1;
