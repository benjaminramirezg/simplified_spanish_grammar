#! /usr/bin/perl -w
use warnings;
use strict;
use locale;
use xgrammar;
use xunification;

my $grammar = xgrammar->new;

print 'Nombre de la gramática [ssg o nssg]: ';
my $gname = <>;
chomp $gname;

until ($gname =~ /^n?ssg$/) {

    print "Nombre de gramática incorrecto. Escribe ssg o nssg: ";
    $gname = <>;
    chomp $gname;
}

$grammar->name($gname);

print 'Usuario de MySQL: ';
my $user = <>;
chomp $user;
$grammar->user_DB($user);

print 'Contraseña de MySQL: ';
my $password = <>;
chomp $password;
$grammar->password_DB($password);






my $unification = xunification->new;

## Se va a cargar la gramática. Para ello 
## se necesita un unificador que ayude a 
## la expansión 

$grammar->unification($unification);

## Se dota al unificador de información
## gramatical

$unification->types($grammar->types);

## Se carga la gramática

$grammar->load_tdl_grammar;

