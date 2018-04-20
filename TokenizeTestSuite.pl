#! /usr/bin/perl -w
use warnings;
use strict;
use locale;
use Tokenizer;
use CreateNssgTestSuite;

my $TOKENIZER = Tokenizer->new();
my $NSSG = CreateNssgTestSuite->new(); 
my $TestSuite;

print 'Nombre de la gramática [ssg o nssg]: ';
my $gname = <>;
chomp $gname;

until ($gname =~ /^n?ssg$/) {

    print "Nombre de gramática incorrecto. Escribe ssg o nssg: ";
    $gname = <>;
    chomp $gname;
}

my $lname = 'lexicon';
$TOKENIZER->name($lname);

print 'Usuario de MySQL: ';
my $user = <>;
chomp $user;
$TOKENIZER->user_DB($user);

print 'Contraseña de MySQL: ';
my $password = <>;
chomp $password;
$TOKENIZER->password_DB($password);

$TOKENIZER->open_DB;


open TXT, "<./TestSuite.txt";

while (<TXT>) {

    $_ =~ s/(\[\s*|\s*\])//g;
    $_ =~ s/¿//gu;

    $TestSuite .= $_;
}

close TXT;

SplitTokens($TestSuite);

sub SplitTokens {

	my $SENTENCE = shift;
	$TOKENIZER->tokenize($SENTENCE);
	$TOKENIZER->clitic();
	$TOKENIZER->np_chunks;
	$TOKENIZER->vp_chunks;
	$TOKENIZER->left_periphery;
	$TOKENIZER->silence_pron;

	if ($gname =~ /nssg|NSSG/) { 

	    open (NSSG,">./NssgTestSuite.xml") || die $!;
	    print NSSG $NSSG->changeTestSuitetoNssg($TOKENIZER->return_sppp());
	    close NSSG;

	} else {

	    open (SSG,">./SsgTestSuite.xml") || die $!;
	    print SSG $TOKENIZER->return_sppp();
	    close SSG;
	}
}
