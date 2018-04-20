package clitic;

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
## AutÃ³mata
###########

my $automata = Automata->new();

my $input = { 'INIT'        => {'clitic_article'         => '1',
	                        'clitic'                 => '2',
	                        'verb_noun'              => 'INIT',
	                        'verb'                   => 'INIT',
	                        'none'                   => 'INIT'},

              '1'           => {'verb'                   => '4',
	                        'clitic'                 => 'INIT',
	                        'clitic_article'         => 'INIT',
	                        'verb_noun'              => 'INIT',
                                'none'                   => 'INIT' },

              '2'           => {'clitic'                 => '3',
                                'clitic_article'         => '3',
	                        'verb_noun'              => '4',
	                        'verb'                   => '4',
                                'none'                   => 'INIT'},

	      '3'           => {'verb_noun'              => '4',
                                'verb'                   => '4',
	                        'clitic_article'         => 'INIT',
	                        'clitic'                 => 'INIT',
                                'none'                   => 'INIT'},

	      '4'           => {'clitic_article'         => 'INIT',
	                        'clitic'                 => 'INIT',
	                        'verb_noun'              => 'INIT',
	                        'verb'                   => 'INIT',
	                        'none'                   => 'INIT'},
};

$automata->make_automata_from_hash($input);
$automata->present_state($automata->get_state_by_key('INIT'));
$automata->present_state->initial('yes');
$automata->get_state_by_key('4')->final('yes');

$automata->get_state_by_key('1')->append_method('make_clitic');
$automata->get_state_by_key('2')->append_method('make_clitic');
$automata->get_state_by_key('3')->append_method('append_clitic');
$automata->get_state_by_key('4')->append_method('append_verb');

$automata->get_state_by_key('1')->append_method('append_simple_token');
$automata->get_state_by_key('2')->append_method('append_simple_token');
$automata->get_state_by_key('3')->append_method('append_simple_token');
$automata->get_state_by_key('4')->append_method('append_simple_token');

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

##################################################
## extracciÃ³n de informaciÃ³n de los tokens simples
##################################################

sub get_tag {

    my $self = shift;
    my $token = shift;
    my ( $verb, $noun );

    foreach my $analysis ($token->get_analysis_list) {
	    $analysis = $token->get_analysis_by_key($analysis);
	foreach my $rule ($analysis->get_rules_list) {
	    $rule = $analysis->get_rule_by_key($rule);
	    if ( $rule->stem =~ /^verb/ ) { $verb = 1; }
	    if ( $rule->stem =~ /^(noun|adj)/ ) { $noun = 1; }
	}

    }
    $token->form =~ /^([Ll](o|es?)|[mtsMTS]e|[Nn]?[Oo]s)$/ && return $self->tag('clitic');
    $token->form =~ /^([Ll](as?|os))$/ && return $self->tag('clitic_article');
    $verb && $noun  && return $self->tag('verb_noun');
    $verb &&  return $self->tag('verb');

    return $self->tag('none');
}

#####################
## MÃ©todos complejos
#####################

sub make_clitic {

    my $self = shift;
    my $token = shift;

    my $verb = token->new; 
    $verb->form($token->form);
    $verb->from($token->from);
    $verb->id($token->id);
    $verb->type;
    $self->complex_token($verb);
}

sub append_clitic {

    my $self = shift;
    my $token = shift;

    my $form = $self->complex_token->form . " " . $token->form;
    $self->complex_token->form($form);
}

sub append_verb {

    my $self = shift;
    my $token = shift;

    my $clitic = $self->complex_token->form; 
    $clitic =~ s/ /-/g;

    $self->complex_token->form($self->complex_token->form . " " . $token->form);
    $self->complex_token->to($token->to);

    foreach my $analysis( $token->get_analysis_list ) {

	$analysis = $token->get_analysis_by_key($analysis);
	$self->verb_analysis($analysis) or
	$token->delete_analysis($analysis) and
	next;

	foreach my $rule ($analysis->get_rules_list) {

	    $rule = $analysis->get_rule_by_key($rule);
	    $self->clitic_rule($rule) and
	    $self->update_clitic_rule($rule,$clitic);
	}
	$self->complex_token->append_analysis($analysis);
    }
}

sub clitic_rule {

    my $self = shift;
    my $rule = shift;
    my $stem = $rule->stem;

    if ($stem eq "verb-non-clitic-irule") { return 1; }
}

sub verb_rule {

    my $self = shift;
    my $rule = shift;
    my $stem = $rule->stem;

    if ($stem =~ /^verb/) { return 1; }
}


sub verb_analysis {

    my $self = shift;
    my $analysis = shift;
    my $flag = 0;

    foreach my $rule ($analysis->get_rules_list) {

	$rule = $analysis->get_rule_by_key($rule);
	if ($self->verb_rule($rule)) { $flag = 1; }
    }

    return $flag;
}

sub update_clitic_rule {

    my $self = shift;
    my $rule = shift;
    my $clitic = shift;
    $clitic = $self->uncapitalize_form($clitic);
    my $stem = "verb-$clitic-irule";
    $rule->stem($stem);
}


sub uncapitalize_form {       
                     
    my $self = shift;
    my $form = shift;
    $form =~ tr/[A-Z]|Ñ|Á|É|Í|Ó|Ú|Ü)/[a-z]|ñ|á|é|í|ó|ú|ü/;
    return $form;
}


1;
