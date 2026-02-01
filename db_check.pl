use strict;
use warnings;
use DBI;

# Load DB info from Config.pm
my $Home = '/Users/sabyrzhanzhakipov/znuny-mount';
my $ConfigFile = "$Home/Kernel/Config.pm";

open my $fh, '<', $ConfigFile or die "Can't open $ConfigFile: $!";
my $Content = do { local $/; <$fh> };
close $fh;

my ($DBHost) = $Content =~ /\$Self->\{'DatabaseHost'\} = '([^']+)';/;
my ($DBName) = $Content =~ /\$Self->\{'Database'\} = "([^"]+)";/;
my ($DBUser) = $Content =~ /\$Self->\{'DatabaseUser'\} = "([^"]+)";/;
my ($DBPw) = $Content =~ /\$Self->\{'DatabasePw'\} = '([^']+)';/;

print "Connecting to $DBName at $DBHost...\n";

my $dsn = "DBI:mysql:database=$DBName;host=$DBHost";
my $dbh = DBI->connect($dsn, $DBUser, $DBPw, { RaiseError => 1, PrintError => 0 });

print "\n--- Available Deployment States ---\n";
my $sth = $dbh->prepare("SELECT name FROM general_catalog WHERE general_catalog_class = 'ITSM::ConfigItem::DeploymentState'");
$sth->execute();
while (my @row = $sth->fetchrow_array) {
    print "State: $row[0]\n";
}

print "\n--- Available Incident States ---\n";
$sth = $dbh->prepare("SELECT name FROM general_catalog WHERE general_catalog_class = 'ITSM::Core::IncidentState'");
$sth->execute();
while (my @row = $sth->fetchrow_array) {
    print "State: $row[0]\n";
}

print "\n--- Available Tools Types ---\n";
$sth = $dbh->prepare("SELECT name FROM general_catalog WHERE general_catalog_class = 'ITSM::ConfigItem::Tools::Type'");
$sth->execute();
while (my @row = $sth->fetchrow_array) {
    print "Type: $row[0]\n";
}

$dbh->disconnect();
