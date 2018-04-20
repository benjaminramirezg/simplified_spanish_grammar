package CreateNssgTestSuite;
use warnings;
use strict;
use locale;

my $FLEX = qr/-(indicative|subjuntive|imperative|ger|inf|part)-/;
my $CLITICS = qr/(-([mts]e|l[oa]s?|les?|n?os))+-/;
my $OUT;
##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    return $self;
}


sub DESTROY {

    my $self = shift;
}

sub changeTestSuitetoNssg {

    my $self = shift;
    my $INPUT = shift;
    $OUT = "";
    foreach (split "\n", $INPUT) {

	$_ .= "\n";
	if (find_flex_verb($_)) { $OUT .= $_; print_inversion($_); }
	elsif (find_clitic_verb($_)) { $OUT .= $_; print_scrambling($_); }
	elsif (find_transitive($_)) { print_transitive($_); }
	elsif (find_dative($_)) { print_dative($_); }
	elsif (find_obliq($_)) { print_obliq($_); }
	else { $OUT .= $_; }
    }
    return $OUT;
}

sub find_flex_verb {

    my $line = shift;
    if ($line =~ /$FLEX/) { return 1; }
    return 0;
}

sub find_clitic_verb {

    my $line = shift;
    if ($line =~ /$CLITICS/) { return 1; }
    if ($line =~ /-non-clitic/) { return 1; }
    return 0;

}

sub find_transitive {

    my $line = shift;
    if ($line =~ /v-transitive/) { return 1; }
    return 0;
}

sub find_dative {

    my $line = shift;
    if ($line =~ /v-dative/) { return 1; }
    return 0;
}

sub find_obliq {

    my $line = shift;
    if ($line =~ /v-obliq/) { return 1; }
    return 0;
}

sub print_inversion {

    my $line = shift;

    $line =~ s/^(.+id=")[^"]+(".+)$/$1inversion-rule$2/;
    $line =~ s/^(.+class=")irule(".+)$/$1lrule$2/;
    $OUT .= $line;
}

sub print_scrambling {

    my $line = shift;
    $line =~ s/^(.+class=")irule(".+)$/$1lrule$2/;

    foreach my $affix ('one', 'two', 'three', 'four', 'five', 'six') {
    
	$line =~ s/^(.+id=")[^"]+(".+)$/$1scrambling-rule-$affix$2/;
	$OUT .= $line;
    }
}

sub print_transitive {

    my $line = shift;
    
    foreach my $affix ('comp-rule', 'np-rule', 'clitization-pron-rule', 'clitization-topic-rule') {
    
	$line =~ s/^(.+id=")[^"]+(".+)$/$1v-transitive-$affix$2/;
	$OUT .= $line;
    }
}

sub print_dative {

    my $line = shift;

    foreach my $affix ('np-rule', 'clitization-pron-rule', 'clitization-topic-rule') {
    
	$line =~ s/^(.+id=")[^"]+(".+)$/$1v-dative-$affix$2/;
	$OUT .= $line;
    }
}

sub print_obliq {

    my $line = shift;
    
    foreach my $affix ('np-rule', 'comp-rule') {
    
	$line =~ s/^(.+id=")[^"]+(".+)$/$1v-obliq-$affix$2/;
	$OUT .= $line;
    }
}

1;
