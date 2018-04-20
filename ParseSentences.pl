#! /usr/bin/perl -w
use warnings;
use strict;
use locale;
use xgrammar;
use xunification;
use xparser;
use Tokenizer;
use CreateNssgTestSuite;
use Encode 'encode';
use Encode 'encode', 'decode', 'is_utf8', 'from_to';
use Encode::Guess;

my $tokenizer = Tokenizer->new();
my $ChangeTestSuite = CreateNssgTestSuite->new(); 
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

my $lname = 'lexicon';

$tokenizer->name($lname);

print 'Usuario de MySQL: ';
my $user = <>;
chomp $user;
$grammar->user_DB($user);
$tokenizer->user_DB($user);

print 'Contraseña de MySQL: ';
my $password = <>;
chomp $password;
$grammar->password_DB($password);
$tokenizer->password_DB($password);

$tokenizer->open_DB;

my $unification = xunification->new;
my $parser = xparser->new;
print "Scrambling [1 o 0]: ";

my $bool = <>;
chomp $bool;

until ($bool =~ /^1|0$/) {

    print "Valor incorrecto. Escribe 1 o 0: ";
    $bool = <>;
    chomp $bool;
}

$parser->scrambling($bool);

## Se va a cargar la gramática. Para ello 
## se necesita un unificador que ayude a 
## la expansión 

$grammar->unification($unification);

## Se dota al unificador de información
## gramatical

$unification->types($grammar->types);

## Se carga la gramática

$grammar->load_grammar;

# El test para ver rápido si un núcleo
# está activo aún o no

$unification->test($grammar->get_globals('TEST'));

## El parser funciona conforme a una gramática
## y haciendo uso de un unificador cargado con
## información gramatical

$parser->grammar($grammar);
$parser->unification($unification);

### EMPEZAMOS

print "Oración: ";

while (<>) {

    my $sentence = $_;

# Nos aseguramos de que la oración viene en utf-8

    if (ref(guess_encoding($sentence,'latin1'))) {

	$sentence = encode('utf8',decode('latin1',$sentence));
    }

# Eliminamos elementos indeseados (saltos de línea, corchetes)

    chomp $sentence;
    $sentence =~ s/(\[\s*|\s*\])//g;
    $sentence =~ s/¿//gu;

# Nos aseguramos de que la oración acaba con un punto.

    unless ($sentence =~ /[[:punct:]]$/) { $sentence .= '.'; }


    $tokenizer->tokenize($sentence);
    $tokenizer->clitic();
    $tokenizer->np_chunks;
    $tokenizer->vp_chunks;
    $tokenizer->left_periphery;
    $tokenizer->silence_pron;

    my $tokenization = $tokenizer->return_sppp();
    print $tokenization;

    if ($gname =~ /nssg|NSSG/) { 

	$tokenization = $ChangeTestSuite->changeTestSuitetoNssg($tokenization);
    }

    $parser->parse($tokenization);
    print "Oración: ";
}	
