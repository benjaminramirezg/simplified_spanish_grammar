package enamex;

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

my $input = { 'INIT'        => {'enamex'       => '2',
				'wordc'        => '1',
                                'none'         => '1',
                                'punct'        => 'INIT',
                                'de'           => '1',
                                'article'      => '1'},

              '1'           => {'enamex'       => '2',
                                'wordc'        => '2',
                                'none'         => '1',
                                'punct'        => '1',
                                'de'           => '1',
                                'article'      => '1'},

              '2'           => {'enamex'       => '3',
                                'wordc'        => '3',
		                'de'           => '4',
                                'none'         => 'OK',
                                'article'      => 'OK',
                                'punct'        => 'OK'},

              '3'           => {'enamex'       => '3',
                                'wordc'        => '3',
                                'de'           => '4',
                                'none'         => 'OK',
                                'punct'        => 'OK'},

              '4'           => {'article'      => '5',
                                'enamex'       => '3',
                                'wordc'        => '3',
                                'none'         => 'OK*',
                                'punct'        => 'OK*'},

              '5'           => {'enamex'       => '3',
                                'wordc'        => '3',
                                'none'         => 'OK**',
                                'punct'        => 'OK**'},

              'OK'          => {'enamex'       => '2',
                                'wordc'        => '2',
                                'none'         => '1',
                                'punct'        => '1',
                                'de'           => '1',
                                'article'      => '1'},  

              'OK*'         => {'enamex'       => '2',
                                'wordc'        => '2',
                                'none'         => '1',
                                'punct'        => '1',
                                'de'           => '1',
                                'article'      => '1'},  

              'OK**'        => {'enamex'       => '2',
                                'wordc'        => '2',
                                'none'         => '1',
                                'punct'        => '1',
                                'de'           => '1',
                                'article'      => '1'},  
};

$automata->make_automata_from_hash($input);
$automata->present_state($automata->get_state_by_key('INIT'));
$automata->present_state->initial('yes');
$automata->get_state_by_key('OK')->final('yes');
$automata->get_state_by_key('OK*')->final('yes');
$automata->get_state_by_key('OK**')->final('yes');

$automata->get_state_by_key('2')->append_method('make_enamex');
$automata->get_state_by_key('3')->append_method('update_enamex');
$automata->get_state_by_key('4')->append_method('update_enamex');
$automata->get_state_by_key('5')->append_method('update_enamex');

$automata->get_state_by_key('2')->append_method('append_simple_token');
$automata->get_state_by_key('3')->append_method('append_simple_token');
$automata->get_state_by_key('4')->append_method('append_simple_token');
$automata->get_state_by_key('5')->append_method('append_simple_token');

$automata->get_state_by_key('OK*')->append_method('pop_simple_token');
$automata->get_state_by_key('OK**')->append_method('pop_simple_token');
$automata->get_state_by_key('OK**')->append_method('pop_simple_token');

$automata->get_state_by_key('OK*')->append_method('undo_enamex');
$automata->get_state_by_key('OK**')->append_method('undo_enamex');
$automata->get_state_by_key('OK**')->append_method('undo_enamex');

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
    my $unknown = $self->there_is_unknown_irule($token);

    return $self->get_tag_aux($token,$unknown);
}

sub there_is_unknown_irule {

    my $self = shift;
    my $token = shift;

    foreach my $analysis ($token->get_analysis_list) {

	$analysis = $token->get_analysis_by_key($analysis);
	if ($self->is_unknown($analysis)) { return 1; }
    }
    return 0;
}

sub is_unknown {

    my $self = shift;
    my $analysis = shift;

    foreach my $rule ($analysis->get_rules_list) {

	$rule = $analysis->get_rule_by_key($rule);

	if ($rule->stem =~ /^unknown/) { return 1; }
    }
    return 0;
}

sub get_tag_aux {

    my $self = shift;
    my $token = shift;
    my $unknown = shift;

    $token->type =~  /punct/ && return $self->tag('punct');
    $token->form =~ /^(d[eu]s?)$/ && return $self->tag('de');
    $token->form =~ /^(el|las?|los)$/ && return $self->tag('article');
    $token->type eq 'wordc' && $unknown && return $self->tag('enamex');
    $token->type eq 'wordc' && return $self->tag('wordc');
    return $self->tag('none');
}

sub make_enamex {

    my $self = shift;
    my $in = shift;

    my $token = token->new;
    $token->update_token($in);
    $self->delete_analysis($token); # Hay que eliminar análisis previos
    $token->type('enamex');

    my $analysis = analysis->new;
    $analysis->stem('***ENAMEX***');

    my $rule = rule->new;
    $rule->stem('noun-constant-irule');

    $analysis->append_rule($rule);
    $token->append_analysis($analysis);
    $self->complex_token($token);
}

sub update_enamex {

    my $self = shift;
    my $token = shift;
    my $form = $self->complex_token->form . " " . $token->form;
    $self->complex_token->form($form);
    $self->complex_token->to($token->to);
}

sub delete_analysis {

    my $self = shift;
    my $token = shift;

    foreach my $analysis ($token->get_analysis_list) {

	$analysis = $token->get_analysis_by_key($analysis);
	if ($self->is_unknown($analysis)) {  # Análisis desconocidos ya no interesan
	    $token->delete_analysis($analysis); }
    }

}

sub undo_enamex {

    my $self = shift;
    my $token = shift;
    my $form = $self->complex_token->form;
    $form =~ s/^(.+) .+/$1/;
    $self->complex_token->form($form);
    $self->complex_token->to($token->to);
}

1;

