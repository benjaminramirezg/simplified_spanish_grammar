package vp_chunks;

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

my $AC = qr/(l[oa]s?)/;
my $DAT = qr/-(([mts]e|n?os)-$AC|les?)-/;
my $SE = qr/-(se)-(?!(l([oa]|[oa]s)))/;
my $SER = qr/^(ser)$/;
my $FIN = qr/((indica|subjun|impera)tive)/;
my $GER = qr/(ger)/;
my $INF = qr/(inf)/;
my $PART = qr/(part)/;
my $CLITICS = qr/(-([mts]e|l[oa]s?|les?|n?os))+-/;
my $CATS = {};
my $VARS = {};

my @LRULES = ();

###########
## Autómata
###########

my $automata = Automata->new();

my $input = { 'INIT' => { 'fin'   => '2',
			  'inf'   => 'INIT',
			  'ger'   => 'INIT',
			  'part'  => 'INIT',
			  'prep'  => 'INIT',
	                  'other' => 'INIT'},
	      '2'    => { 'fin'   => '9',
			  'inf'   => '4',
			  'ger'   => '3',
			  'part'  => '5',
			  'prep'  => '6',
	                  'other' => '8'},
	      '3'    => { 'fin'   => '9',
			  'inf'   => '4',
			  'ger'   => '9',
			  'part'  => '5',
			  'prep'  => '6',
	                  'other' => '8'},
	      '4'    => { 'fin'   => '9',
			  'inf'   => '4',
			  'ger'   => '9',
			  'part'  => '5',
			  'prep'  => '6',
	                  'other' => '8'},
	      '5'    => { 'fin'   => '9',
			  'inf'   => '9',
			  'ger'   => '9',
			  'part'  => '7',
			  'prep'  => '9',
	                  'other' => '8'},
	      '6'    => { 'fin'   => '9',
			  'inf'   => '4',
			  'ger'   => '9',
			  'part'  => '9',
			  'prep'  => '6',
	                  'other' => '8'},	
	      '7'    => {},      
	      '8'    => {},      
	      '9'    => {}};


$automata->make_automata_from_hash($input);
$automata->present_state($automata->get_state_by_key('INIT'));
$automata->present_state->initial('yes');
$automata->get_state_by_key('7')->final('yes');
$automata->get_state_by_key('8')->final('yes');
$automata->get_state_by_key('9')->final('yes');

$automata->get_state_by_key('INIT')->append_method('empty_store');
$automata->get_state_by_key('INIT')->append_method('del_form');
$automata->get_state_by_key('INIT')->append_method('del_from');
$automata->get_state_by_key('INIT')->append_method('del_to');
$automata->get_state_by_key('INIT')->append_method('del_id');
$automata->get_state_by_key('INIT')->append_method('del_lemma');
$automata->get_state_by_key('INIT')->append_method('del_class');
$automata->get_state_by_key('INIT')->append_method('del_clitics_irule');
$automata->get_state_by_key('INIT')->append_method('del_active_irule');
$automata->get_state_by_key('INIT')->append_method('del_passive_irule');
$automata->get_state_by_key('INIT')->append_method('initialize_VARS');

$automata->get_state_by_key('2')->append_method('update_form_from_to_id');
$automata->get_state_by_key('2')->append_method('append_simple_token');
$automata->get_state_by_key('2')->append_method('update_active_irule_VARS');
$automata->get_state_by_key('2')->append_method('update_clitics_irule_VARS');
$automata->get_state_by_key('2')->append_method('update_lemma_VARS');

$automata->get_state_by_key('3')->append_method('update_form_from_to_id');
$automata->get_state_by_key('3')->append_method('append_simple_token');
$automata->get_state_by_key('3')->append_method('update_clitics_irule_VARS');
$automata->get_state_by_key('3')->append_method('update_lemma_VARS');

$automata->get_state_by_key('4')->append_method('update_form_from_to_id');
$automata->get_state_by_key('4')->append_method('append_simple_token');
$automata->get_state_by_key('4')->append_method('update_clitics_irule_VARS');
$automata->get_state_by_key('4')->append_method('update_lemma_VARS');

$automata->get_state_by_key('5')->append_method('update_form_from_to_id');
$automata->get_state_by_key('5')->append_method('append_simple_token');
$automata->get_state_by_key('5')->append_method('update_passive_irule_VARS');
$automata->get_state_by_key('5')->append_method('update_lemma_VARS');

$automata->get_state_by_key('6')->append_method('update_form_from_to_id');
$automata->get_state_by_key('6')->append_method('append_simple_token');

$automata->get_state_by_key('7')->append_method('update_form_from_to_id');
$automata->get_state_by_key('7')->append_method('append_simple_token');
$automata->get_state_by_key('7')->append_method('update_passive_irule_VARS');
$automata->get_state_by_key('7')->append_method('update_lemma_VARS');
$automata->get_state_by_key('7')->append_method('make_chunk');
$automata->get_state_by_key('7')->append_method('manage_final_situation');
$automata->get_state_by_key('7')->append_method('restart');

$automata->get_state_by_key('8')->append_method('make_chunk');
$automata->get_state_by_key('8')->append_method('manage_final_situation');
$automata->get_state_by_key('8')->append_method('restart');

$automata->get_state_by_key('9')->append_method('empty_store');
$automata->get_state_by_key('9')->append_method('initialize_VARS');
$automata->get_state_by_key('9')->append_method('new_values');
$automata->get_state_by_key('9')->append_method('new_state');



##############
# Constructor
##############

sub new {

    my $class = shift;
    my $self = $class->SUPER::new;
    bless ( $self, $class );
    $self->automata($automata);
    $self->initialize_VARS;
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

sub make_chunk {

    my $self = shift;
    my ($form,$from,$to,$id) = ($self->form, $self->from, $self->to, $self->id);
    $self->make_chunk_aux($form,$from,$to,$id);
}

sub make_chunk_aux {

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
    $analysis->stem($self->get_chunk_lemma($form));

    $self->append_irules($analysis,$form);
    $self->append_lrules($analysis,$form);

    $token->append_analysis($analysis);
    $self->complex_token($token);
}

sub get_tag {

    my $self = shift;
    my $token = shift;

    $self->initialize_CATS;
    $self->update_CATS($token);

    return $self->decide_CAT;
}

sub update_form_from_to_id {

    my $self = shift;
    my $token = shift;

    my $form = $token->form;
    $self->form($self->add_to_form($form));
    $self->to($token->to);
    unless (defined $self->from) { $self->from($token->from); }
    unless ($self->id) { $self->id($token->id); }
}

sub update_CATS {

    my $self = shift;
    my $token = shift;

    foreach my $ana_key ($token->get_analysis_list) {
	my $analysis = $token->get_analysis_by_key($ana_key);
	my $stem = $analysis->stem;
	my $class = $analysis->class;

	foreach my $rule_key ($analysis->get_rules_list) {
	    my $rule = $analysis->get_rule_by_key($rule_key);
	    my $r_name = $rule->stem;

	    $self->update_CATS_aux($stem,$r_name,$class);
	}
    }
}

sub update_CATS_aux {

    my $self = shift;
    my $stem = shift;
    my $r_name = shift;
    my $class = shift;

    $self->lemma($stem);
    $class and $self->class($class);
    
    if ($r_name =~ /^(comp|prep)-/) { $self->add_to_CATS($1);}
    if ($r_name =~ /^(verb)-.*$FIN-/) { $self->add_to_CATS('fin'); 
					 $self->active_irule($r_name);}
    if ($r_name =~ /^(verb)-.*$INF-/) { $self->add_to_CATS('inf');}
    if ($r_name =~ /^(verb)-.*$GER-/) { $self->add_to_CATS('ger');}
    if ($r_name =~ /^(verb)-.*$PART-/) { $self->add_to_CATS('part');
                                          $self->passive_irule($r_name);}

    
    if ($r_name =~ /$CLITICS/) { my $cl_rule = $self->clitics_irule; 
				 $cl_rule .= $r_name; 
				 $cl_rule =~ s/(.+)-iruleverb(.+)/$1$2/;
				 $self->clitics_irule($cl_rule); }
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

sub lemma {       
                     
    my $self = shift;
    if ( @_ ) { $self->{lemma} = shift };
    return $self->{lemma};
}


sub class {       
                     
    my $self = shift;
    if ( @_ ) { $self->{class} = shift };
    return $self->{class};
}


sub clitics_irule {       
                     
    my $self = shift;
    if ( @_ ) { $self->{clitics_irule} = shift };
    return $self->{clitics_irule};
}

sub active_irule {       
                     
    my $self = shift;
    if ( @_ ) { $self->{active_irule} = shift };
    return $self->{active_irule};
}

sub passive_irule {       
                     
    my $self = shift;
    if ( @_ ) { $self->{passive_irule} = shift };
    return $self->{passive_irule};
}

sub add_to_form {

    my $self = shift;
    my $new_form = shift;
    $new_form = $self->uncapitalize_form($new_form);
    my $old_form = $self->form;
    unless ($old_form) { return $self->form($new_form); }
    return $self->form($old_form." ".$new_form);
}


sub del_fin {       
                     
    my $self = shift;
    
    $self->fin('');
}


sub del_lemma {

    my $self = shift;
    
    $self->lemma('');
} 

sub del_class {

    my $self = shift;
    
    $self->class('');
} 


sub del_clitics_irule {

    my $self = shift;
    
    $self->clitics_irule('');
} 


sub del_active_irule {

    my $self = shift;
    
    $self->active_irule('');
} 

sub del_passive_irule {

    my $self = shift;
    
    $self->passive_irule('');
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

sub initialize_CATS {

    my $self = shift;

    $CATS->{'prep'} = 0;
    $CATS->{'fin'} = 0;
    $CATS->{'part'} = 0;
    $CATS->{'ger'} = 0;
    $CATS->{'inf'} = 0;
}

sub add_to_CATS {

    my $self = shift;
    my $CAT = shift;

    $CATS->{$CAT} = 1;
}

sub decide_CAT {

    my $self = shift;

    if ($self->automata->present_state->name eq 'INIT') { return $self->decide_CAT_INIT; }
    if ($self->automata->present_state->name eq '2') { return $self->decide_CAT_2; }
    if ($self->automata->present_state->name eq '3') { return $self->decide_CAT_3; }
    if ($self->automata->present_state->name eq '4') { return $self->decide_CAT_4; }
    if ($self->automata->present_state->name eq '5') { return $self->decide_CAT_5; }
    if ($self->automata->present_state->name eq '6') { return $self->decide_CAT_6; }

    return 'other';
}

sub decide_CAT_INIT {

    my $self = shift;

    if ( $CATS->{'prep'} ) { return 'prep'; }
    if ( $CATS->{'fin'} ) {  return 'fin'; }
    if ( $CATS->{'part'} ) { return 'part'; }
    if ( $CATS->{'ger'} ) { return 'ger'; }
    if ( $CATS->{'inf'} ) { return 'inf'; }

    return 'other';
}

sub decide_CAT_2 {

    my $self = shift;

    if ( $CATS->{'prep'} ) { return 'prep'; }
    if ( $CATS->{'fin'} ) {  return 'fin'; }
    if ( $CATS->{'part'} ) { return 'part'; }
    if ( $CATS->{'ger'} ) { return 'ger'; }
    if ( $CATS->{'inf'} ) { return 'inf'; }

    return 'other';
}

sub decide_CAT_3 {

    my $self = shift;

    if ( $CATS->{'prep'} ) { return 'prep'; }
    if ( $CATS->{'fin'} ) {  return 'fin'; }
    if ( $CATS->{'part'} ) { return 'part'; }
    if ( $CATS->{'ger'} ) { return 'ger'; }
    if ( $CATS->{'inf'} ) { return 'inf'; }

    return 'other';
}

sub decide_CAT_4 {

    my $self = shift;

    if ( $CATS->{'prep'} ) { return 'prep'; }
    if ( $CATS->{'fin'} ) {  return 'fin'; }
    if ( $CATS->{'part'} ) { return 'part'; }
    if ( $CATS->{'ger'} ) { return 'ger'; }
    if ( $CATS->{'inf'} ) { return 'inf'; }

    return 'other';
}

sub decide_CAT_5 {

    my $self = shift;

    if ( $CATS->{'prep'} ) { return 'prep'; }
    if ( $CATS->{'fin'} ) {  return 'fin'; }
    if ( $CATS->{'part'} ) { return 'part'; }
    if ( $CATS->{'ger'} ) { return 'ger'; }
    if ( $CATS->{'inf'} ) { return 'inf'; }

    return 'other';
}

sub decide_CAT_6 {

    my $self = shift;

    if ( $CATS->{'prep'} ) { return 'prep'; }
    if ( $CATS->{'fin'} ) {  return 'fin'; }
    if ( $CATS->{'part'} ) { return 'part'; }
    if ( $CATS->{'ger'} ) { return 'ger'; }
    if ( $CATS->{'inf'} ) { return 'inf'; }

    return 'other';
}


sub initialize_VARS {

    my $self = shift;

    $VARS->{'active_irule'} = 0;
    $VARS->{'passive_irule'} = 0;
    $VARS->{'clitics_irule'} = 0;
    $VARS->{'lemma'} = 0;
    $VARS->{'ser'} = 0;

    $VARS->{'v-passive-rule'} = 0;
    $VARS->{'v-rpass-rule'} = 0;
    $VARS->{'v-pronominal-rule'} = 0;
    $VARS->{'v-transitive-rule'} = 0;
    $VARS->{'v-dative-rule'} = 0;
    $VARS->{'v-obliq-rule'} = 0;
    $VARS->{'v-unaccusative-rule'} = 0;
    $VARS->{'v-unergative-rule'} = 0;
    $VARS->{'v-predicative-rule'} = 0;
}

sub add_to_VARS {

    my $self = shift;
    my $VAR = shift;

    $VARS->{$VAR} = 1;
}

sub update_active_irule_VARS {

    my $self = shift;

    $VARS->{'active_irule'} = $self->active_irule;
}

sub update_passive_irule_VARS {

    my $self = shift;

    $VARS->{'passive_irule'} = $self->passive_irule;
}

sub update_clitics_irule_VARS {

    my $self = shift;

    $VARS->{'clitics_irule'} = $self->clitics_irule; 
}


sub update_lemma_VARS {

    my $self = shift;

    $VARS->{'lemma'} = $self->lemma;
    if ($self->lemma eq 'ser') { $VARS->{'ser'} = 1; }
}


sub get_chunk_lemma {

    my $self = shift;
    my $form = shift;

    return $VARS->{'lemma'};
}


sub append_irules {

    my $self = shift;
    my $analysis = shift;
    my $form = shift;
    $self->append_active_irule($analysis,$form);
    $self->append_passive_irule($analysis,$form);
    $self->append_clitics_irule($analysis,$form);
}

sub append_clitics_irule {

    my $self = shift;
    my $analysis = shift;
    my $form = shift;
    my $r_name = 'verb-non-clitic-irule';
    if ($VARS->{'clitics_irule'}) { $r_name = $VARS->{'clitics_irule'}; }
    my $rule = rule->new;
    $rule->form($form);
    $rule->stem($r_name);
    $rule->class('irule');
    $analysis->append_rule($rule);
}


sub append_active_irule {

    my $self = shift;
    my $analysis = shift;
    my $form = shift;

    my $rule = rule->new;
    $rule->form($form);
    $rule->stem($VARS->{'active_irule'});
    $rule->class('irule');
    $analysis->append_rule($rule);
}

sub append_passive_irule {

    my $self = shift;
    my $analysis = shift;
    my $form = shift;
    $VARS->{'passive_irule'} or return;
    my $rule = rule->new;
    $rule->form($form);
    $rule->stem($VARS->{'passive_irule'});
    $rule->class('irule');
}

sub append_lrules {

    my $self = shift;
    my $analysis = shift;
    my $form = shift;

    $self->decide_LRULES;

    foreach my $r_name (@LRULES) {
	my $rule = rule->new;
	$rule->form($form);
	$rule->stem($r_name);
	$rule->class('lrule');
	$analysis->append_rule($rule);
    }
}

sub decide_LRULES {

    my $self = shift;

#    $self->decide_all_LRULES;
    $self->decide_LRULES_with_class;
    $self->make_LRULES;
}

sub decide_all_LRULES {

    my $self = shift;

    $VARS->{'v-passive-rule'} = 1;
    $VARS->{'v-rpass-rule'} = 1;
    $VARS->{'v-pronominal-rule'} = 1;
    $VARS->{'v-transitive-rule'} = 1;
    $VARS->{'v-dative-rule'} = 1;
    $VARS->{'v-obliq-rule'} = 1;
    $VARS->{'v-unaccusative-rule'} = 1;
    $VARS->{'v-unergative-rule'} = 1;
    $VARS->{'v-predicative-rule'} = 1;
}


sub decide_LRULES_with_class {

    my $self = shift;
    my $class = $self->class;

    my ($Type, $Pron, $Pred, $Obl, $Tr, $Dat) = $class =~ m/(.)/g;

    if ($Type eq 'R') { $self->decide_LRULES_Accomplishment($Pron, $Pred, $Obl, $Tr, $Dat); }
    if ($Type eq 'L') { $self->decide_LRULES_Achivement($Pron, $Pred, $Obl, $Tr);     }
    if ($Type eq 'A') { $self->decide_LRULES_Activity($Pron, $Pred, $Obl, $Tr);       }
    if ($Type eq 'E') { $self->decide_LRULES_State($Pron, $Pred, $Obl, $Tr);          }
    if ($Type eq 'C') { $self->decide_LRULES_Change($Pron, $Pred, $Obl, $Tr);         }

    if ($self->dative) { $self->dative_pattern; }

}

# Cambios de estado que admiten tanto uso
# transitivo como intransitivo:

# 

sub decide_LRULES_Change {

    my $self = shift;
    my $Pron = shift;
    my $Pred = shift;
    my $Obl =  shift;
    my $Tr =   shift;

    $VARS->{'v-unaccusative-rule'} = 1;
    $VARS->{'v-transitive-rule'} = 1;

    if ($self->rpass) { $self->rpass_pattern; }
    if ($self->passive) { $self->passive_pattern; }
    if ($self->transitive) { $self->transitive_pattern; }
    if ($self->dative) { $self->dative_pattern; }

    if ($Pron eq 's') { $VARS->{'v-pronominal-rule'} = 1; }
    if ($Pred eq 's') { $VARS->{'v-predicative-rule'} = 1; }
    if ($Obl eq 's')  { $VARS->{'v-obliq-rule'} = 1;       }
}

sub decide_LRULES_Accomplishment {

    my $self = shift;
    my $Pron = shift;
    my $Pred = shift;
    my $Obl =  shift;
    my $Tr =   shift;
    my $Dat = shift;

    $VARS->{'v-transitive-rule'} = 1;

    if ($self->rpass) { $self->rpass_pattern; }
    if ($self->passive) { $self->passive_pattern; }
    if ($self->transitive) { $self->transitive_pattern; }
    if ($self->dative) { $self->dative_pattern; }

    if ($Pred eq 's') { $VARS->{'v-predicative-rule'} = 1; }
    if ($Obl eq 's') { $VARS->{'v-obliq-rule'} = 1; }
    if ($Dat eq 's') { $VARS->{'v-dative-rule'} = 1; }
}

sub decide_LRULES_Achivement {

    my $self = shift;
    my $Pron = shift;
    my $Pred = shift;
    my $Obl = shift;
    my $Tr = shift;

    if ($Pron eq 's') { $VARS->{'v-pronominal-rule'} = 1; }
    else { $VARS->{'v-unaccusative-rule'} = 1; }
    if ($Pred eq 's') { $VARS->{'v-predicative-rule'} = 1; }
    if ($self->dative) { $self->dative_pattern; }
}

sub decide_LRULES_Activity {

    my $self = shift;
    my $Pron = shift;
    my $Pred = shift;
    my $Obl =  shift;
    my $Tr =   shift;

    if    ($Tr eq 's') { $VARS->{'v-transitive-rule'} = 1;
                         $VARS->{'v-unergative-rule'} = 1; }
    elsif ($Tr eq 'e') { $VARS->{'v-unaccusative-rule'} = 1; }
    elsif ($Tr eq 'i') { $VARS->{'v-unergative-rule'} = 1; }

    if ($Pron eq 's') { $VARS->{'v-pronominal-rule'} = 1; }
    if ($Pred eq 's') { $VARS->{'v-predicative-rule'} = 1; }
    if ($Obl eq 's') { $VARS->{'v-obliq-rule'} = 1; }

    if ($self->rpass) { $self->rpass_pattern; }
}

sub decide_LRULES_State {

    my $self = shift;
    my $Pron = shift;
    my $Pred = shift;
    my $Obl =  shift;
    my $Tr =   shift;

    if    ($Tr eq 's') { $VARS->{'v-transitive-rule'} = 1;
                         $VARS->{'v-unergative-rule'} = 1; }
    elsif ($Tr eq 'e') { $VARS->{'v-unaccusative-rule'} = 1; }
    elsif ($Tr eq 'i') { $VARS->{'v-unergative-rule'} = 1; }

    if ($Pron eq 's') { $VARS->{'v-pronominal-rule'} = 1; }
    if ($Pred eq 's') { $VARS->{'v-predicative-rule'} = 1; }
    if ($Obl eq 's') { $VARS->{'v-obliq-rule'} = 1; }

    if ($self->rpass) { $self->rpass_pattern; }
}

sub passive {

    my $self = shift;
    my $ser = $VARS->{'ser'};
    my $passive_irule = $VARS->{'passive_irule'};

    if ($ser and $passive_irule) { return 1; }
    return 0;
}

sub rpass {

    my $self = shift;
    my $clitics_rule = $VARS->{'clitics_irule'};
    if ($clitics_rule and $clitics_rule =~ /$SE/ and
	$self->class and $self->class =~ /^.n..[ts].$/) { return 1; }
    return 0;
}

sub transitive {

    my $self = shift;
    my $clitics_rule = $VARS->{'clitics_irule'};
    if ($clitics_rule and $clitics_rule =~ /$AC/) { return 1; }
    return 0;
}


sub dative {

    my $self = shift;
    my $clitics_rule = $VARS->{'clitics_irule'};

    if ($clitics_rule and $clitics_rule =~ /$DAT/) { return 1; }
    if ($clitics_rule and $clitics_rule =~ /-[mt]e|n?os-/) { return 1; }

    return 0;
}

sub passive_pattern {

    my $self = shift;

    $VARS->{'v-passive-rule'} = 1;
    $VARS->{'v-transitive-rule'} = 0;
    $VARS->{'v-unaccusative-rule'} = 0;
    $VARS->{'v-unergative-rule'} = 0;
    $VARS->{'v-obliq-rule'} = 0;
}

sub rpass_pattern {

    my $self = shift;
    $VARS->{'v-rpass-rule'} = 1;
    $VARS->{'v-transitive-rule'} = 0;
    $VARS->{'v-unaccusative-rule'} = 0;
    $VARS->{'v-unergative-rule'} = 0;
    $VARS->{'v-obliq-rule'} = 0;
}

sub transitive_pattern {

    my $self = shift;

    $VARS->{'v-transitive-rule'} = 1;
    $VARS->{'v-unaccusative-rule'} = 0;
    $VARS->{'v-unergative-rule'} = 0;
    $VARS->{'v-obliq-rule'} = 0;
}

sub dative_pattern {

    my $self = shift;
    
    $VARS->{'v-dative-rule'} = 1;
}

sub make_LRULES {

    my $self = shift;

    @LRULES = ();

    if ($VARS->{'v-passive-rule'}) { push @LRULES, 'v-passive-rule'; }
    if ($VARS->{'v-rpass-rule'}){ push @LRULES, 'v-rpass-rule'; }
    if ($VARS->{'v-pronominal-rule'}){ push @LRULES, 'v-pronominal-rule'; }
    if ($VARS->{'v-transitive-rule'}){ push @LRULES, 'v-transitive-rule'; }
    if ($VARS->{'v-dative-rule'}){ push @LRULES, 'v-dative-rule'; }
    if ($VARS->{'v-obliq-rule'}){ push @LRULES, 'v-obliq-rule'; }
    if ($VARS->{'v-unaccusative-rule'}){ push @LRULES, 'v-unaccusative-rule'; }
    if ($VARS->{'v-unergative-rule'}){ push @LRULES, 'v-unergative-rule'; }
    if ($VARS->{'v-predicative-rule'}){ push @LRULES, 'v-predicative-rule'; }
}

sub new_values {

    my $self = shift;
    my $token = shift;
    $self->del_id;
    $self->del_form;
    $self->del_from;
    $self->del_to;
}

sub new_state {

    my $self = shift;
    my $token = shift;
    my $cat = $self->decide_CAT;

    $automata->present_state($self->automata->get_state_by_key('INIT'));
    if ($cat eq 'fin') { $self->execute_state_methods($token); }
    
}

1;

