#!/usr/bin/perl
use strict;
use warnings;
use utf8;
require JSON;

my $File = '/Volumes/znuny/people_data_final.json';
open my $fh, '<:utf8', $File or die $!;
my $Raw = do { local $/; <$fh> };
close $fh;

my $People = JSON->new()->utf8(0)->decode($Raw);

open my $out, '>:utf8', '/Volumes/znuny/people_to_import.csv' or die $!;
# Header depends on whether Znuny expects it. Usually it doesn't if it's not checked.
# We'll use: Name;DeplState;InciState;FIO;Email

for my $P (@$People) {
    my $Login = $P->{FIO_Login};
    my $Name = $P->{Name} || $Login; 
    my $Email = $P->{Email} || "$Login\@vicomplus.kz";
    # Escape semicolon in names if any
    $Name =~ s/;/ /g;
    print $out "$Name;In Use;Operational;$Login;$Email\n";
}
close $out;
print "CSV generated: /Volumes/znuny/people_to_import.csv\n";
