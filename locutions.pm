package locutions;

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

my $input = { 'INIT' => { 'ohhhh' => '2',
                       'ooooo' => 'INIT' },
              '2' => { 'ohhhh' => '2',
		       'oonew' => '4',
                       'match' => '3',
                       'ooooo' => 'INIT'},
              '4' => { 'ohhhh' => '2',
		       'oonew' => '4',
                       'match' => '3',
                       'ooooo' => 'INIT'},
              '3' => {}};

$automata->make_automata_from_hash($input);
$automata->present_state($automata->get_state_by_key('INIT'));
$automata->present_state->initial('yes');
$automata->get_state_by_key('3')->final('yes');
$automata->get_state_by_key('INIT')->append_method('empty_store');
$automata->get_state_by_key('INIT')->append_method('del_form');
$automata->get_state_by_key('INIT')->append_method('del_from');
$automata->get_state_by_key('INIT')->append_method('del_to');
$automata->get_state_by_key('INIT')->append_method('del_id');
$automata->get_state_by_key('2')->append_method('append_simple_token');
$automata->get_state_by_key('3')->append_method('append_simple_token');
$automata->get_state_by_key('3')->append_method('make_locution');
$automata->get_state_by_key('3')->append_method('manage_final_situation');
$automata->get_state_by_key('3')->append_method('empty_store');
$automata->get_state_by_key('3')->append_method('del_form');
$automata->get_state_by_key('3')->append_method('del_from');
$automata->get_state_by_key('3')->append_method('del_to');
$automata->get_state_by_key('3')->append_method('del_id');
$automata->get_state_by_key('3')->append_method('restart');
$automata->get_state_by_key('4')->append_method('empty_store');
$automata->get_state_by_key('4')->append_method('append_simple_token');
$automata->get_state_by_key('4')->append_method('new_values');

##############
# Constructor
##############

sub new {

    my $class = shift;
    my $self = $class->SUPER::new;
    bless ( $self, $class );
    $self->automata($automata);
    $self->locutions({});
    return $self;
}

#########################
## MÉTODOS DE ANÁLISIS ##
#########################

sub empty_store {

    my $self = shift;

    while ($self->get_simple_tokens_list) {

	$self->pop_simple_token;
    }
}

sub make_locution {

    my $self = shift;
    my ($form,$from,$to,$id) = ($self->form, $self->from, $self->to, $self->id);
    $self->make_locution_aux($form,$from,$to,$id);
}

sub make_locution_aux {

    my $self = shift;
    my $form = shift;
    my $from = shift;
    my $to = shift;
    my $id = shift;

    my $token = token->new();
    $token->form($form);
    $token->from($from);
    $token->to($to);
    $token->id($id);

    my $analysis = analysis->new;
    $analysis->stem($self->get_locution_lemma($form));
    $analysis->class($self->get_locution_class($form));

    my $rule = rule->new;
    $rule->form($form);
    $rule->stem($self->get_locution_rule($form));

    $analysis->append_rule($rule);
    $token->append_analysis($analysis);
    $self->complex_token($token);
}

sub get_tag {

    my $self = shift;
    my $token = shift;
    my $form = $token->form;
    $self->add_to_form($form);
    unless (defined $self->from) { $self->from($token->from); }
    unless ($self->id) { $self->id($token->id); }
    $self->to($token->to);
    return $self->form_unify_with_locutions($form);
}


sub form_unify_with_locutions {

    my $self = shift;
    my $form = shift;
    my $RE = $self->form;
    my ($partial_l,$whole_l,$new_l);

    foreach my $locution ($self->get_locutions_as_list){

	if ($locution =~ /^\Q$RE\E.+/) { $partial_l = $locution; }
	if ($locution =~ /^\Q$RE\E$/) { $whole_l = $locution; }
	if ($locution =~ /^\Q$form\E/) { $new_l = $locution; }
    }

    $whole_l and return 'match';
    $partial_l and return 'ohhhh';
    $new_l and return 'oonew';
    return 'ooooo';
}

sub get_locutions_as_list {

    my $self = shift;
    return keys % {$self->locutions;}
}

sub form {       
                     
    my $self = shift;
    if ( @_ ) { $self->{form} = shift };
    return $self->{form};
}


sub id {       
                     
    my $self = shift;
    if ( @_ ) { $self->{id} = shift };
    return $self->{id};
}

sub from {       
                     
    my $self = shift;
    if ( @_ ) { $self->{from} = shift };
    return $self->{from};
}


sub to {       
                     
    my $self = shift;
    if ( @_ ) { $self->{to} = shift };
    return $self->{to};
}

sub locutions {       
                     
    my $self = shift;
    if ( @_ ) { $self->{locutions} = shift };
    return $self->{locutions};
}

sub add_to_form {

    my $self = shift;
    my $new_form = shift;
    $new_form = $self->uncapitalize_form($new_form);
    my $old_form = $self->form;
    unless ($old_form) { return $self->form($new_form); }
    return $self->form($old_form." ".$new_form);
}

sub del_form {

    my $self = shift;
    
    $self->form('');
} 

sub del_from {

    my $self = shift;
    my $undef;
    $self->from($undef);
} 

sub del_to {

    my $self = shift;
    $self->to('');
} 


sub del_id {

    my $self = shift;
    $self->id('');
} 

sub get_locution_lemma {

    my $self = shift;
    my $form = shift;

    if (defined $self->locutions->{$form}) { return $self->locutions->{$form}->{'lemma'}; }
}

sub get_locution_rule {

    my $self = shift;
    my $form = shift;

    if (defined $self->locutions->{$form}) { return $self->locutions->{$form}->{'rule'}; }
}

sub get_locution_class {

    my $self = shift;
    my $form = shift;

    if (defined $self->locutions->{$form}) { return $self->locutions->{$form}->{'class'}; }
}


sub uncapitalize_form {       
                     
    my $self = shift;
    my $form = shift;
    $form =~ tr/[A-Z]|Ñ|Á|É|Í|Ó|Ú|Ü)/[a-z]|ñ|á|é|í|ó|ú|ü/;
    return $form;
}

sub restart {

    my $self = shift;
    $automata->present_state($automata->get_state_by_key('INIT'));
}

sub new_values {

    my $self = shift;
    my $token = shift;
    $self->id($token->id);
    $self->form($token->form);
    $self->from($token->from);
    $self->to($token->to);
}

1;

