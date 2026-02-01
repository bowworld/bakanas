#!/usr/bin/perl
use strict;
use warnings;
use JSON;
use Encode;

my $file = '/Users/sabyrzhanzhakipov/znuny-mount/old_otrs_cmdb_export_v2.csv';
# Raw read
open my $fh, '<:raw', $file or die $!;

# Files to write
open my $tools_fh, '>:utf8', '/Users/sabyrzhanzhakipov/znuny-mount/tools_ready.csv' or die $!;
open my $mtools_fh, '>:utf8', '/Users/sabyrzhanzhakipov/znuny-mount/measuring_tools_ready.csv' or die $!;

print $tools_fh "Name;DeplState;InciState;ToolsType;SerialNumber;Vladelec;Vendor;Object;Notes\n";
print $mtools_fh "Name;DeplState;InciState;ToolsType;SerialNumber;Vladelec;Object;Notes\n";

sub fix_val {
    my $str = shift;
    return "" if !$str;
    
    # The value from JSON might be double-encoded UTF-8.
    # In OTRS export, it often looks like bytes are stored as chars.
    
    # First, if it's already a string, we treat it as bytes if possible
    # But JSON->decode already produced a string.
    
    # If the string contains characters like \x{D0}, we want to treat them as bytes.
    my $bytes = encode("iso-8859-1", $str);
    eval {
        $str = decode("utf-8", $bytes);
    };
    return $str;
}

while (my $line_bytes = <$fh>) {
    # The line itself is UTF-8 encoded in the file.
    # But the content *inside* the JSON strings might be double/triple encoded.
    
    my $line = decode("utf-8", $line_bytes);
    chomp $line;
    next if $. == 1; # Header
    
    if ($line =~ /^"([^"]+)","([^"]*)","([^"]*)","(.*)"$/) {
        my ($class, $name, $status, $json_str) = ($1, $2, $3, $4);
        
        $json_str =~ s/""/"/g;
        
        my $data;
        eval {
            $data = decode_json($json_str);
        };
        next if $@;
        
        if ($class eq 'Tools' || $class eq 'MeasuringTools') {
            my $v = $data->[1]->{Version}->[1];
            
            my $item_name = fix_val($name);
            my $item_status = $status;
            $item_status =~ s/.*:://;
            
            my $tools_type = $v->{ToolsType}->[1]->{ResolvedName} || "";
            $tools_type = fix_val($tools_type);
            
            my $serial = $v->{SerialNumber}->[1]->{Content} || "";
            my $owner_id = $v->{Vladelec}->[1]->{Content} || "";
            
            my $vendor = $v->{Vendor}->[1]->{ResolvedName} || $v->{Vendor}->[1]->{Content} || "";
            $vendor = fix_val($vendor);
            
            my $object = $v->{Object}->[1]->{Content} || "";
            $object = fix_val($object);
            
            my $notes = $v->{Notes}->[1]->{Content} || "";
            $notes = fix_val($notes);
            $notes =~ s/\r?\n/ /g;
            
            if (!$item_name || $item_name eq "" || $item_name =~ /^\s+$/) {
                $item_name = "$tools_type ($serial)";
            }
            
            if ($class eq 'Tools') {
                print $tools_fh "$item_name;$item_status;Ok;$tools_type;$serial;$owner_id;$vendor;$object;$notes\n";
            } else {
                print $mtools_fh "$item_name;$item_status;Ok;$tools_type;$serial;$owner_id;$object;$notes\n";
            }
        }
    }
}

close $fh;
close $tools_fh;
close $mtools_fh;

print "Done! Generated with manual double-decoding.\n";
