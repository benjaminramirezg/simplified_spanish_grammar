package left_periphery;

use warnings;
use strict;
use locale;
use Automata;
use arc;
use state;
use token;
use segment;
use text;
use analysis;
use rule;
use Data::Dumper;

###########################
# Subtipo de complex_token
###########################

our @ISA = ( 'complex_token' );

###########
## Autómata
###########

my  $automata = Automata->new();

my $input =  { 'INIT' => { 'punct'  => 'INIT',
                           'topic'  => '2',
                           'foci'   => '3',
                           'verb'   => '4' },

	       '2' =>    { 'punct'  => 'INIT',
                           'topic'  => '2',
                           'foci'   => '3',
                           'verb'   => '4' },

	       '3' =>    { 'punct'  => '4',
                           'topic'  => '4',
                           'foci'   => '4',
                           'verb'   => '4' },

               '4' =>    { 'punct' => '4',
                           'topic' => '4',
                           'foci'  => '4',
                           'verb'  => '4',
                           'comp'  => 'INIT'}};

$automata->make_automata_from_hash($input);
$automata->present_state($automata->get_state_by_key('INIT'));
$automata->get_state_by_key('2')->append_method('update_token');
$automata->get_state_by_key('3')->append_method('update_token');

##############
# Constructor
##############

sub new {

    my $class = shift;
    my $self = $class->SUPER::new;
    bless ( $self, $class );
    $self->automata($automata);
    return $self;
}

#########################
## MÉTODOS DE ANÁLISIS ##
#########################

sub get_tag {

    my $self = shift;
    my $token = shift;

    foreach my $ana_key ($token->get_analysis_list) {
	my $analysis = $token->get_analysis_by_key($ana_key);
	my $stem = $analysis->stem;

	if ($stem =~ /^\*\*\*PUNCT\*\*\*$/) { return 'punct'; }
	if ($stem =~ /^\*\*\*.--\*\*\*$/) { return 'comp'; }
	if ($stem =~ /^\*\*\*.[pd-].\*\*\*$/) { return 'topic'; }
	if ($stem =~ /^\*\*\*.i.\*\*\*$/) { return 'foci'; }

	foreach my $rule_key ($analysis->get_rules_list) {
	    my $rule = $analysis->get_rule_by_key($rule_key);
	    my $r_name = $rule->stem;
	    if ($r_name =~ /^verb-/) { return 'verb'; }
	}
    }
}

sub update_token {

    my $self = shift;
    my $token = shift;

    $token->from('Z');
    $token->to('Z');

    foreach my $ana_key ($token->get_analysis_list) {

	my $analysis = $token->get_analysis_by_key($ana_key);
	my $stem = $analysis->stem;
	if ( $stem =~ /^\*\*\*.i.\*\*\*$/) { $stem =~ s/^(\*\*\*.).(.\*\*\*$)/$1Q$2/; }
	if ( $stem =~ /^\*\*\*.[pd-].\*\*\*$/) { $stem =~ s/^(\*\*\*.).(.\*\*\*$)/$1T$2/; }
	$analysis->stem($stem);
    }
}

1;
