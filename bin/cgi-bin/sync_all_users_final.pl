#!/usr/bin/perl
use strict;
use warnings;
use utf8;
use Kernel::System::ObjectManager;
require JSON;

print "Content-type: text/plain; charset=utf-8\n\n";

my $Raw = <<'JSON_DATA';
[{"Lastname":"ÐÑÐºÑÑÐ½Ð¾Ð²","Login":"glukyanov","Email":"glukyanov@vicomplus.kz","Firstname":"ÐÑÐ¸Ð³Ð¾ÑÐ¸Ð¹"},{"Firstname":"ÐÐ»ÐµÐºÑÐ°Ð½Ð´Ñ","Email":"adorogov@vicomplus.kz","Login":"adorogov","Lastname":"ÐÐ¾ÑÐ¾Ð³Ð¾Ð²"},{"Firstname":"ÐÐ»ÐµÐºÑÐµÐ¹","Lastname":"ÐÐ¸ÑÐµÐ½ÐºÐ¾","Login":"ami","Email":"amichsenko@vicomplus.kz"},{"Lastname":"ÐÑÑÐ¼Ð°Ð½Ð³Ð°Ð»Ð¸ÐµÐ²","Login":"ekurm","Email":"ekurmangaliyev@vicomplus.kz","Firstname":"ÐÑÐ¸Ðº"},{"Lastname":"Ð¨Ð¸ÑÑÐ¾Ð²","Email":"yshirshov@vicomplus.kz","Login":"yshirshov","Firstname":"ÐÐ²Ð³ÐµÐ½Ð¸Ð¹"},{"Lastname":"ÐÐ°Ð´ÐµÐ¹ÑÐ¸ÐºÐ¾Ð²","Email":"sladeishchikov@vicomplus.kz","Login":"sladeishchikov","Firstname":"Ð¡ÐµÑÐ³ÐµÐ¹"},{"Email":"akalabashkin@vicomplus.kz","Login":"akalabashkin","Lastname":"ÐÐ°Ð»Ð°Ð±Ð°ÑÐºÐ¸Ð½","Firstname":"ÐÐ»ÐµÐºÑÐ°Ð½Ð´Ñ"},{"Login":"sstacenko","Email":"sstacenko@vicomplus.kz","Lastname":"Ð¡ÑÐ°ÑÐµÐ½ÐºÐ¾","Firstname":"Ð¡ÐµÑÐ³ÐµÐ¹"},{"Firstname":"ÐÐ¾ÑÐ¸Ñ","Email":"bsidorov@vicomplus.kz","Login":"bsidorov","Lastname":"Ð¡Ð¸Ð´Ð¾ÑÐ¾Ð²"},{"Email":"ylevin@vicomplus.kz","Login":"ylevin","Lastname":"ÐÐµÐ²Ð¸Ð½","Firstname":"Ð®ÑÐ¸Ð¹"},{"Lastname":"ÐÐ¾Ð³Ð°Ð´Ð°ÐµÐ²","Email":"mpogadayev@vicomplus.kz","Login":"mpog","Firstname":"ÐÐ¸ÑÐ°Ð¸Ð»"},{"Firstname":"ÐÐ°Ð²ÐµÐ»","Lastname":"ÐÑÑÐ°Ð¹","Email":"pmukhai@vicomplus.kz","Login":"pmukhai"},{"Firstname":"ÐÐ»ÐµÐºÑÐµÐ¹","Lastname":"Ð¡Ð¾Ð»Ð¾Ð´Ð¾Ð²Ð½Ð¸ÐºÐ¾Ð²","Email":"asolodovnikov@vicomplus.kz","Login":"asolodovnikov"},{"Lastname":"Ð Ð°Ð¼Ð°Ð·Ð°Ð½Ð¾Ð²","Login":"bz","Email":"bramazanov@vicomplus.kz","Firstname":"ÐÐ°ÐºÑÑÐ¶Ð°Ð½"},{"Firstname":"ÐÐ»ÐµÐ³","Lastname":"Ð¡Ð¾Ð»Ð¾Ð²ÑÐµÐ²","Login":"os","Email":"osolovyov@vicomplus.kz"},{"Login":"akulygin","Email":"akulygin@viomplus.kz","Lastname":"ÐÑÐ»ÑÐ³Ð¸Ð½","Firstname":"ÐÐ»ÐµÐºÑÐµÐ¹"},{"Lastname":"Ð¡ÑÐ»ÑÐ°Ð½Ð¾Ð²","Login":"tsultanov","Email":"tsultanov@vicomplus.kz","Firstname":"Ð¢Ð°Ð»Ð³Ð°Ñ"},{"Lastname":"ÐÑÑÐµÐ½ÐºÐ¾","Email":"ylyssenko@vicomplus.kz","Login":"ylyssenko","Firstname":"ÐÐ²Ð³ÐµÐ½Ð¸Ð¹"},{"Email":"office@vicomplus.kz","Login":"office","Lastname":"Ð¡Ð¸ÑÐ¾ÐºÐ°","Firstname":"ÐÐ°ÑÐ¸ÑÐ°"},{"Firstname":"Ð¡Ð°Ð±ÑÑ","Lastname":"ÐÐ°ÐºÐ¸Ð¿Ð¾Ð²","Email":"sz@vicomplus.kz","Login":"sz"},{"Login":"ddolotin","Email":"ddolotin@vicomplus.kz","Lastname":"ÐÐ¾Ð»Ð¾ÑÐ¸Ð½","Firstname":"ÐÐ°Ð½Ð¸Ð»"},{"Firstname":"ÐÐ»Ð¼Ð°Ð·","Login":"adokdyrkhan","Email":"adokdyrkhan@vicomplus.kz","Lastname":"ÐÐ¾ÐºÐ´ÑÑÑÐ°Ð½"},{"Email":"dzaikovvskiy@vicomplus.kz","Login":"dz","Lastname":"ÐÐ°Ð¹ÐºÐ¾Ð²ÑÐºÐ¸Ð¹","Firstname":"ÐÐµÐ½Ð¸Ñ"},{"Login":"durussov","Email":"durussov@vicomplus.kz","Lastname":"Ð£ÑÑÑÐ¾Ð²","Firstname":"ÐÐµÐ½Ð¸Ñ"},{"Firstname":"ÐÐ±Ð°Ð¹","Lastname":"ÐÐ²Ð³ÑÐ¼Ð±Ð°ÐµÐ²","Email":"aavgumbayev@vicomplus.kz","Login":"aavgumbayev"},{"Lastname":"ÐÐ¾ÑÐ±Ð°ÑÐµÐ²","Email":"sgorbachev@vicomplus.kz","Login":"sgorbachev","Firstname":"CÑÐ°Ð½Ð¸ÑÐ»Ð°Ð²"},{"Login":"kurussov","Email":"kurussov@vicomplus.kz","Lastname":"Ð£ÑÑÑÐ¾Ð²","Firstname":"ÐÐ¾Ð½ÑÑÐ°Ð½ÑÐ¸Ð½"},{"Firstname":"ÐÑÐ»Ð¸Ðº","Lastname":"ÐÐ°ÑÐºÐ°Ð±Ð°ÐµÐ²","Email":"emarkabayev@vicomplus.kz","Login":"emarkabayev"},{"Email":"ykoshenov@vicomplus.kz","Login":"ykoshenov","Lastname":"ÐÐ¾ÑÐµÐ½Ð¾Ð²","Firstname":"ÐÑÐ±Ð¾Ð»"},{"Firstname":"ÐÐµÐ½Ð½Ð°Ð´Ð¸Ð¹","Login":"ggaak","Email":"ggaak@vicomplus.kz","Lastname":"ÐÐ°Ð°Ðº"},{"Login":"arusskikh","Email":"arusskikh@vicomplus.kz","Lastname":"Ð ÑÑÑÐºÐ¸Ñ","Firstname":"ÐÐ»ÐµÐºÑÐ°Ð½Ð´Ñ"},{"Login":"vzh","Email":"vzhiltsov@vicomplus.kz","Lastname":"ÐÐ¸Ð»ÑÑÐ¾Ð²","Firstname":"ÐÐ¸ÑÐ°Ð»Ð¸Ð¹"},{"Lastname":"ÐÑÐ¾Ð¿Ð°ÑÐµÐ²","Login":"mkropachev","Email":"mkropachev@vicomplus.kz","Firstname":"ÐÐ¸ÑÐ°Ð¸Ð»"},{"Login":"vbauer","Email":"victorbauer@vicomplus.kz","Lastname":"ÐÐ°ÑÑÑ","Firstname":"ÐÐ¸ÐºÑÐ¾Ñ"},{"Email":"sz@vicomplus.kz","Login":"root","Lastname":"OTRS","Firstname":"Admin"},{"Lastname":"ÐÐ·Ð¸Ð¼Ð±Ð°ÐµÐ²","Email":"aazimbayev@vicomplus.kz","Login":"azv","Firstname":"ÐÑÐ¼Ð°Ð½"},{"Firstname":"ÐÐ¸ÑÐ°Ð¸Ð»","Login":"mvedelyanchikov","Email":"mvedelyanchikov@vicomplus.kz","Lastname":"ÐÐµÐ´ÐµÐ»ÑÐ½ÑÐ¸ÐºÐ¾Ð²"},{"Firstname":"Ð®ÑÐ¸Ð¹","Lastname":"ÐÐ¾ÑÐ¾Ð·Ð¾Ð²","Login":"ymorozov","Email":"ymorozov@vicomplus.kz"},{"Lastname":"Ð¨Ð¸ÑÑÐ¾Ð²","Login":"ashirshov","Email":"ashirshov@vicomplus.kz","Firstname":"ÐÐ»ÐµÐºÑÐ°Ð½Ð´Ñ"},{"Firstname":"ÐÑÐ¸Ð½Ð°","Lastname":"ÐÐµÐ´Ð¸Ðº","Email":"idedik@vicomplus.kz","Login":"idedik"},{"Firstname":"ÐÐ»ÑÑ","Login":"iolkhovoy","Email":"iolkhovoy@vicomplus.kz","Lastname":"ÐÐ»ÑÑÐ¾Ð²Ð¾Ð¹"},{"Firstname":"Ð¢Ð¸Ð¼Ð¾ÑÐµÐ¹","Lastname":"ÐÐ°ÑÐ¼Ð¾Ð²","Login":"tnaumov","Email":"tnaumov@vicomplus.kz"},{"Firstname":"ÐÐ°ÑÑÐ°Ð½","Lastname":"ÐÐ¾Ð»Ð´Ð°ÑÐ±Ð°ÐµÐ²","Login":"dzd","Email":"dzholdasbayev@vicomplus.kz"},{"Firstname":"ÐÑÐµÑ","Lastname":"ÐÐ°Ð½Ð´Ð¸Ð»ÑÐ´Ð¸Ð½","Email":"azhandildin@vicomplus.kz","Login":"aset"},{"Email":"bgaliullin@vicomplus.kz","Login":"bgaliullin","Lastname":"ÐÐ°Ð»Ð¸ÑÐ»Ð»Ð¸Ð½","Firstname":"ÐÑÐ»Ð°Ñ"}]
JSON_DATA

local $Kernel::OM = Kernel::System::ObjectManager->new();
my $UO = $Kernel::OM->Get('Kernel::System::User');

my $Users = JSON->new()->utf8()->decode($Raw);

for my $U (@$Users) {
    print "Syncing $U->{Login}... ";
    my %Exist = $UO->GetUserData( User => $U->{Login} );
    if ($Exist{UserID}) {
        print "Exists (ID $Exist{UserID})\n";
    } else {
        my $UserID = $UO->UserAdd(
            UserFirstname => $U->{Firstname},
            UserLastname  => $U->{Lastname},
            UserLogin     => $U->{Login},
            UserEmail     => $U->{Email} || "$U->{Login}\@vicomplus.kz",
            ValidID       => 1,
            ChangeUserID  => 1,
        );
        if ($UserID) {
            $UO->SetPassword( UserLogin => $U->{Login}, PW => 'Vicom_2026!' );
            print "CREATED (ID $UserID)\n";
        } else {
            print "FAILED\n";
        }
    }
}
