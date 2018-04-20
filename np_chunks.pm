package np_chunks;

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

my ($PREP_RULE, $DET_RULE, $NOUN_RULE, $COMP_RULE); # Reglas flexivas de los constituyentes
my ($PREP, $DET, $NOUN) = ('-', 'd', '-'); # Posiciones del lema
my $PERSONAL_PRONOUN =  qr/(yo|tú|[ms]í|ti|él|ell[oa]s?|[vn]osotr[oa]s)/;

# Los lemas tienen 3 posiciones
# 1ª Preposición: - (no hay prep), a ("a"), e ("en"), c ("con"), h ("hasta"), d ("de").
# 2ª Determinante: - (no hay det), d (determinante), p (pronombre personal), i (interrogativo).
# 3ª Nombre: - (no hay), a (animado), u (inanimado).

my ($ID, $FORM, $FROM, $TO); # Valores del token complejo.

my ($GEND, $NUM, $PER); # Valores de concordancia.

###########
## Autómata
###########

my $automata = Automata->new();
my $empty = $automata->empty_tag;

my $input = { 'INIT' => { 'prep'  => '2',
			  'det'   => '3',
                          'noun'  => '4',
                          'comp'  => '5',
	                  'other' => 'INIT'},
              '2'    => { 'prep'  => '2',
			  'det'   => '3',
                          'noun'  => '4',
                          'comp'  => '5',
	                  'other' => 'INIT'},
	      '3'    => { $empty  => '6',
                          'noun'  => '4' },
	      '4'    => {},
	      '5'    => {},
              '6'    => {}};

$automata->make_automata_from_hash($input);
$automata->present_state($automata->get_state_by_key('INIT'));
$automata->present_state->initial('yes');
$automata->get_state_by_key('4')->final('yes');
$automata->get_state_by_key('5')->final('yes');

$automata->get_state_by_key('INIT')->append_method('empty_store');
$automata->get_state_by_key('INIT')->append_method('del_values');

$automata->get_state_by_key('2')->append_method('append_simple_token');
$automata->get_state_by_key('2')->append_method('update_form_from_to_id');
$automata->get_state_by_key('2')->append_method('update_prep_det_noun');
$automata->get_state_by_key('3')->append_method('append_simple_token');
$automata->get_state_by_key('3')->append_method('update_form_from_to_id');
$automata->get_state_by_key('3')->append_method('update_prep_det_noun');
$automata->get_state_by_key('4')->append_method('append_simple_token');
$automata->get_state_by_key('4')->append_method('update_form_from_to_id');
$automata->get_state_by_key('4')->append_method('update_prep_det_noun');
$automata->get_state_by_key('5')->append_method('append_simple_token');
$automata->get_state_by_key('5')->append_method('update_form_from_to_id');
$automata->get_state_by_key('5')->append_method('update_prep_det_noun');

$automata->get_state_by_key('4')->append_method('make_chunk');
$automata->get_state_by_key('4')->append_method('manage_final_situation');
$automata->get_state_by_key('4')->append_method('restart');

$automata->get_state_by_key('5')->append_method('make_chunk');
$automata->get_state_by_key('5')->append_method('manage_final_situation');
$automata->get_state_by_key('5')->append_method('restart');

$automata->get_state_by_key('6')->append_method('make_chunk');
$automata->get_state_by_key('6')->append_method('manage_final_situation');
$automata->get_state_by_key('6')->append_method('restart');

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

sub last_token {       
                     
    my $self = shift;
    if ( @_ ) { $self->{last_token} = shift };
    return $self->{last_token};
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

sub make_chunk {

    my $self = shift;

    my $token = token->new();
    $token->form($FORM);
    $token->from($FROM);
    $token->to($TO);
    $token->id($ID);

    my $analysis = analysis->new;
    $analysis->stem($self->get_chunk_lemma);

    my $rule = rule->new;
    $rule->form($FORM);
    $rule->stem($self->get_chunk_rule);

    $analysis->append_rule($rule);
    $token->append_analysis($analysis);
    $self->complex_token($token);
}

sub get_tag {

    my $self = shift;
    my $token = shift;
    $self->last_token($token);

    foreach my $ana_key ($token->get_analysis_list) {
	my $analysis = $token->get_analysis_by_key($ana_key);

	foreach my $rule_key ($analysis->get_rules_list) {
	    my $rule = $analysis->get_rule_by_key($rule_key);
	    my $r_name = $rule->stem;

	    if ($r_name =~ /^noun-/) { return 'noun'; }
	    if ($r_name =~ /^det-/) { return 'det'; }
	    if ($r_name =~ /^comp-/) { return 'comp'; }
	    if ($r_name =~ /^prep-/) { return 'prep'; }
	}
    }
    return 'other';
}

sub update_prep_det_noun {

    my $self = shift;
    my $token = $self->last_token;

    foreach my $ana_key ($token->get_analysis_list) {
	my $analysis = $token->get_analysis_by_key($ana_key);
	my $stem = $analysis->stem;
	my $class = $analysis->class;

	foreach my $rule_key ($analysis->get_rules_list) {
	    my $rule = $analysis->get_rule_by_key($rule_key);
	    my $r_name = $rule->stem;

	    if ($r_name =~ /^noun-/) { $self->update_noun($stem,$r_name,$class); }
	    if ($r_name =~ /^det-/) { $self->update_det($stem,$r_name,$class); }
	    if ($r_name =~ /^comp-/) { $self->update_comp($stem,$r_name,$class); }
	    if ($r_name =~ /^prep-/) { $self->update_prep($stem,$r_name,$class); }
	}
    }
}


sub update_noun {

    my $self = shift;
    my $stem = shift;
    my $r_name = shift;
    my $class = shift;

    $NOUN_RULE = $r_name;
    if ($class eq 'person') { $NOUN = 'a'; } else { $NOUN = 'u'; }

    if ($NOUN_RULE =~ /-(sg|pl)-/) { $NUM = $1; }
    if ($NOUN_RULE =~ /-(masc|fem)-/) { $GEND = $1; }
    if ($NOUN_RULE =~ /-(1|2)-/) { $PER = $1; }
}

sub update_comp {

    my $self = shift;
    my $stem = shift;
    my $r_name = shift;
    my $class = shift;

    $COMP_RULE = $r_name;
    $DET = '-'; 
    $NOUN = '-';
}


sub update_prep {

    my $self = shift;
    my $stem = shift;
    my $r_name = shift;
    my $class = shift;

    $PREP_RULE = $r_name;

    if    ($stem eq 'a')     { $PREP = 'a'; } 
    elsif ($stem eq 'de')    { $PREP = 'd'; } 
    elsif ($stem eq 'con')   { $PREP = 'c'; } 
    elsif ($stem eq 'hasta') { $PREP = 'h'; } 
    elsif ($stem eq 'en')    { $PREP = 'e'; } 
}

sub update_det {

    my $self = shift;
    my $stem = shift;
    my $r_name = shift;
    my $class = shift;

    $DET_RULE = $r_name;
    if ($self->is_personal_pronoun($stem)) { $DET = 'p'; $NOUN = 'a'; }
    elsif ($stem =~ /^qué$/) { $DET = 'i'; $NOUN = 'u'; }
    elsif ($stem =~ /^quién$/) { $DET = 'i'; $NOUN = 'a'; }
    else { $DET = 'd'; $NOUN = 'u'; }

    if ($DET_RULE =~ /-(sg|pl)-/) { $NUM = $1; }
    if ($DET_RULE =~ /-(masc|fem)-/) { $GEND = $1; }
    if ($DET_RULE =~ /-(1|2)-/) { $PER = $1; }
}

sub update_form_from_to_id {

    my $self = shift;
    my $token = $self->last_token;

    $self->update_form($token->form);
    $TO = $token->to;
    unless ($FROM) { $FROM = $token->from; }
    unless ($ID) { $ID = $token->id; }
}

sub update_form {

    my $self = shift;
    my $new_form = shift;
    $new_form = $self->uncapitalize_form($new_form);

    if ($FORM) { $FORM .= " $new_form"; } 
    else { $FORM = $new_form; } 

}

sub uncapitalize_form {       
                     
    my $self = shift;
    my $form = shift;
    $form =~ tr/[A-Z]|Ñ|Á|É|Í|Ó|Ú|Ü)/[a-z]|ñ|á|é|í|ó|ú|ü/;
    return $form;
}

sub restart {

    my $self = shift;
    my $token = shift;
    $automata->present_state($automata->get_state_by_key('INIT'));
    $self->execute_state_methods($token);
}

sub del_values {

    my $self = shift;

    ($PREP_RULE, $DET_RULE, $NOUN_RULE, $COMP_RULE, $PREP, $DET, $NOUN, $FORM, $ID, $FROM, $TO, $GEND, $PER, $NUM) =
	(undef, undef, undef, undef, '-', '-', '-', undef, undef, undef, undef, undef, undef, undef);
}

sub is_personal_pronoun {

    my $self = shift;
    my $form = $self->uncapitalize_form(shift);
    if ($form =~ /^$PERSONAL_PRONOUN$/) { return 1; }

    return 0;
}

sub get_chunk_lemma {

    my $self = shift;

    return "***$PREP$DET$NOUN***";
}

sub get_chunk_rule {

    my $self = shift;

    if ($COMP_RULE) { return 'chunk-constant-irule'; }

    my $rule = "chunk";

    if ($PER) { $rule .= "-$PER"; }
    if ($GEND) { $rule .= "-$GEND"; }
    if ($NUM) { $rule .= "-$NUM-irule"; }

    return $rule;
}

1;

