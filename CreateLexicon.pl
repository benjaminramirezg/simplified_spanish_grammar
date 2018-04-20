#! /usr/bin/perl -w
use warnings;
use strict;
use locale;
use xgrammar;
use xunification;
use DBI;

print 'Usuario de MySQL: ';
my $user = <>;
chomp $user;

print 'Contraseña de MySQL: ';
my $password = <>;
chomp $password;

my $dbh = DBI->connect("dbi:mysql:","$user","$password") ||
    die "Error opening database: $DBI::errstr\n";

$dbh->do("CREATE DATABASE lexicon;");
$dbh->do("USE lexicon;");
$/ = ";";

open LEXICON, "./lexicon.sql" or die;

while (<LEXICON>) {

    $dbh->do("$_");
}
close LEXICON;
$/ = "\n";

