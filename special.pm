package special;

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

my $numbers1 = {'cero' => 1,
		'uno' => 1,
		'una' => 1,
		'dos' => 1,
		'tres' => 1,
		'cuatro' => 1,
		'cinco' => 1,
		'seis' => 1,
		'siete' => 1,
		'ocho' => 1,
		'nueve' => 1 };

my $numbers10 = {'diez' => 1,
		 'once' => 1,
		 'doce' => 1,
		 'trece' => 1,
		 'catorce' => 1,
		 'quince' => 1,
		 'dieciséis' => 1,
		 'diecisiete' => 1,
		 'dieciocho' => 1,
		 'diecinueve' => 1,
		 'veinte' => 1,
		 'veintiuno' => 1,
		 'veintidos' => 1,
		 'veintitrés' => 1,
		 'veinticuatro' => 1,
		 'veinticinco' => 1,
		 'veintiséis' => 1,
		 'veintisiete' => 1,
		 'veintiocho' => 1,
		 'veintinueve' => 1,
		 'treinta' => 1,
		 'cuarenta' => 1,
		 'cincuenta' => 1,
		 'sesenta' => 1,
		 'setenta' => 1,
		 'ochenta' => 1,
		 'noventa' => 1};

my $numbers100 = {'cien' => 1,
		  'doscientos' => 1,
		  'trescientos' => 1,
		  'cuatrocientos' => 1,
		  'quinientos' => 1,
		  'seiscientos' => 1,
		  'setecientos' => 1,
		  'ochocientos' => 1,
		  'novecientos' => 1,
		  'mil' => 1};

my $numbers1000 = {'mil' => 1};

my $numbers1000000 = {'millón' => 1,
		      'millones' => 1};

my $coins = {'dólar' => 1,
	     'dólares' => 1,
	     'euro' => 1,
	     'euros' => 1,
	     '$' => 1,
	     '€' => 1};

my $seasons = {'primavera' => 1,
	       'verano' => 1,
	       'otoño' => 1,
	       'invierno' => 1};

my $week_dats = {'lunes' => 1,
		 'martes' => 1,
		 'miércoles' => 1,
		 'jueves' => 1,
		 'viernes' => 1,
		 'sábado' => 1,
		 'domingo' => 1};

my $months = {'enero' => 1,
	      'febrero' => 1,
	      'marzo' => 1,
	      'abril' => 1,
	      'mayo' => 1,
	      'junio' => 1,
	      'julio' => 1,
	      'agosto' => 1,
	      'septiembre' => 1,
	      'octubre' => 1,
	      'noviembre' => 1,
	      'diciembre' => 1};

my $street = { 'calle' => 1,
	       'avenida' => 1,
	       'C/' => 1,
	       'Av/' => 1 };

my $house = { 'número' => 1,
	      'nº' => 1 };

my $from = { 'de' => 1,
	     'desde' => 1 };

my $to = { 'a' => 1,
	   'hasta' => 1 };

my $in_hour = { 'a' => 1 };

my $in_season = { 'en' => 1 };


###########
## AutÃ³mata
###########

my $automata = Automata->new();

my $input = { 'INIT' => { 'in_hour' => '1', 
	                  'from'    => '4',
                          'to'      => '7',
                          'number'  => '10',
                          'article' => 'INIT',
                          'hour'    => 'INIT',
			  'coin'    => 'INIT',
			  'other'   => 'INIT'},
               '1'   => { 'in_hour' => '12',
                          'from'    => '12',
                          'to'      => '12',
                          'number'  => '12',
                          'article' => '2',
                          'hour'    => '3',
			  'coin'    => 'INIT',
			  'other'   => 'INIT'},
               '2'   => { 'in_hour' => '12',
                          'from'    => '12',
                          'to'      => '12',
                          'number'  => '12',
                          'article' => 'INIT',
                          'hour'    => '3',
			  'coin'    => 'INIT',
			  'other'   => 'INIT'},
               '3'   => {},
               '4'   => { 'in_hour' => '12',
                          'from'    => '12',
                          'to'      => '12',
                          'number'  => '12',
                          'article' => '5',
                          'hour'    => '6',
			  'coin'    => 'INIT',
			  'other'   => 'INIT'},
               '5'   => { 'in_hour' => '12',
                          'from'    => '12',
                          'to'      => '12',
                          'number'  => '12',
                          'article' => 'INIT',
                          'hour'    => '6',
			  'coin'    => 'INIT',
			  'other'   => 'INIT'},
               '6'   => { 'in_hour' => '12',
                          'from'    => '12',
                          'to'      => '7',
                          'number'  => '12',
                          'article' => 'INIT',
                          'hour'    => 'INIT',
			  'coin'    => 'INIT',
			  'other'   => 'INIT'},
               '7'   => { 'in_hour' => '12',
                          'from'    => '12',
                          'to'      => '12',
                          'number'  => '12',
                          'article' => '8',
                          'hour'    => '9',
			  'coin'    => 'INIT',
			  'other'   => 'INIT'},
               '8'   => { 'in_hour' => '12',
                          'from'    => '12',
                          'to'      => '12',
                          'number'  => '12',
                          'article' => 'INIT',
                          'hour'    => '9',
			  'coin'    => 'INIT',
			  'other'   => 'INIT'},
               '9'   => {},
               '10'  => { 'in_hour' => '12',
                          'from'    => '12',
                          'to'      => '12',
                          'number'  => '12',
                          'article' => 'INIT',
                          'hour'    => 'INIT',
			  'coin'    => '11',
			  'other'   => 'INIT'},
               '11'  => {},
               '12'  => {}};

$automata->make_automata_from_hash($input);
$automata->present_state($automata->get_state_by_key('INIT'));
$automata->present_state->initial('yes');
$automata->get_state_by_key('3')->final('yes');
$automata->get_state_by_key('9')->final('yes');
$automata->get_state_by_key('11')->final('yes');

$automata->get_state_by_key('INIT')->append_method('empty_store');
$automata->get_state_by_key('INIT')->append_method('del_form');
$automata->get_state_by_key('INIT')->append_method('del_from');
$automata->get_state_by_key('INIT')->append_method('del_to');
$automata->get_state_by_key('INIT')->append_method('del_id');
$automata->get_state_by_key('INIT')->append_method('del_lemma');
$automata->get_state_by_key('INIT')->append_method('del_num');

$automata->get_state_by_key('1')->append_method('update_form_from_to_id');
$automata->get_state_by_key('1')->append_method('append_simple_token');

$automata->get_state_by_key('2')->append_method('update_form_from_to_id');
$automata->get_state_by_key('2')->append_method('append_simple_token');

$automata->get_state_by_key('3')->append_method('update_form_from_to_id');
$automata->get_state_by_key('3')->append_method('append_simple_token');
$automata->get_state_by_key('3')->append_method('lemma_TIME');
$automata->get_state_by_key('3')->append_method('make_chunk');
$automata->get_state_by_key('3')->append_method('manage_final_situation');
$automata->get_state_by_key('3')->append_method('restart');

$automata->get_state_by_key('4')->append_method('update_form_from_to_id');
$automata->get_state_by_key('4')->append_method('append_simple_token');

$automata->get_state_by_key('5')->append_method('update_form_from_to_id');
$automata->get_state_by_key('5')->append_method('append_simple_token');

$automata->get_state_by_key('6')->append_method('update_form_from_to_id');
$automata->get_state_by_key('6')->append_method('append_simple_token');

$automata->get_state_by_key('7')->append_method('update_form_from_to_id');
$automata->get_state_by_key('7')->append_method('append_simple_token');

$automata->get_state_by_key('8')->append_method('update_form_from_to_id');
$automata->get_state_by_key('8')->append_method('append_simple_token');

$automata->get_state_by_key('9')->append_method('update_form_from_to_id');
$automata->get_state_by_key('9')->append_method('append_simple_token');
$automata->get_state_by_key('9')->append_method('lemma_TIME');
$automata->get_state_by_key('9')->append_method('make_chunk');
$automata->get_state_by_key('9')->append_method('manage_final_situation');
$automata->get_state_by_key('9')->append_method('restart');

$automata->get_state_by_key('10')->append_method('update_form_from_to_id');
$automata->get_state_by_key('10')->append_method('append_simple_token');

$automata->get_state_by_key('11')->append_method('update_form_from_to_id');
$automata->get_state_by_key('11')->append_method('append_simple_token');
$automata->get_state_by_key('11')->append_method('lemma_PRIZE');
$automata->get_state_by_key('11')->append_method('make_chunk');
$automata->get_state_by_key('11')->append_method('manage_final_situation');
$automata->get_state_by_key('11')->append_method('restart');

$automata->get_state_by_key('12')->append_method('empty_store');
$automata->get_state_by_key('12')->append_method('new_values');
$automata->get_state_by_key('12')->append_method('new_state');

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

    my $rule = rule->new;
    $rule->form($form);
    $rule->stem($self->get_chunk_rule($form));

    $analysis->append_rule($rule);
    $token->append_analysis($analysis);
    $self->complex_token($token);
}

sub get_tag {

    my $self = shift;
    my $token = shift;
    my $form = $self->uncapitalize_form($token->form);

    $self->is_in_hour($form) and return 'in_hour';
    $self->is_from($form) and return 'from';
    $self->is_to($form) and return 'to';
    $self->is_article($form) and return 'article';
    $self->is_hour($form) and return 'hour';
    $self->is_coin($form) and return 'coin';
    $self->is_number($form) and return 'number';
    return 'other';
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


sub lemma {       
                     
    my $self = shift;
    if ( @_ ) { $self->{lemma} = shift };
    return $self->{lemma};
}

sub num {       
                     
    my $self = shift;
    if ( @_ ) { $self->{num} = shift };
    return $self->{num};
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



sub add_to_form {

    my $self = shift;
    my $new_form = shift;
    $new_form = $self->uncapitalize_form($new_form);
    my $old_form = $self->form;
    unless ($old_form) { return $self->form($new_form); }
    return $self->form($old_form." ".$new_form);
}


sub del_lemma {

    my $self = shift;

    $self->lemma('');
} 


sub del_num {

    my $self = shift;
    
    $self->num('');
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


sub get_chunk_lemma {

    my $self = shift;

    return $self->lemma;
}

sub get_chunk_rule {

    my $self = shift;

    my ($lemma,$num) = ($self->lemma, $self->num);

    if ($lemma eq '***TIME***') { return 'adv-constant-irule'; }
    if ($lemma eq '***PRIZE***' and $self->num eq 'sg') { return 'noun-masc-sg-irule'; }
    if ($lemma eq '***PRIZE***' and $self->num eq 'pl') { return 'noun-masc-pl-irule'; }
}



sub is_in_hour {

    my $self = shift;
    my $form = shift;

    if ($in_hour->{$form}) { return 1;}
    return 0;
}


sub is_from {

    my $self = shift;
    my $form = shift;

    if ($from->{$form}) { return 1;}
    return 0;
}

sub is_to {

    my $self = shift;
    my $form = shift;
    if ($to->{$form}) { return 1;}
    return 0;
}

sub is_article {

    my $self = shift;
    my $form = shift;
    if ($form =~ /^(el|los|las?)$/) { return 1;}
    return 0;
}

sub is_hour {

    my $self = shift;
    my $form = shift;
    if ($form =~ /^[0-9][0-9]:[0-9][0-9]$/) { return 1;}
    return 0;
}

sub is_number {

    my $self = shift;
    my $form = shift;
    unless ($form =~ /^[0-9]+(,[0-9]+)?$/) { return 0;}
    if ($form =~ /^1$/) { $self->num_SG;} else { $self->num_PL; }

    return 1;
}

sub is_coin {

    my $self = shift;
    my $form = shift;
    if ($coins->{$form}) { return 1;}
    return;
}

sub lemma_PRIZE {

    my $self = shift;
    $self->lemma('***PRIZE***');
}

sub lemma_TIME {

    my $self = shift;
    $self->lemma('***TIME***');
}

sub num_SG {

    my $self = shift;
    $self->num('sg');
}

sub num_PL {

    my $self = shift;
    $self->num('pl');
}

sub new_values {

    my $self = shift;
    my $token = shift;
    $self->del_id;
    $self->del_form;
    $self->del_from;
    $self->del_to;
    $self->del_lemma;
    $self->del_num;
}

sub new_state {

    my $self = shift;
    my $token = shift;
    my $tag = $self->get_tag($token);

    if ($tag eq 'in_hour') { $automata->present_state($self->automata->get_state_by_key('1')); }
    if ($tag eq 'to') { $automata->present_state($self->automata->get_state_by_key('7')); }
    if ($tag eq 'from') { $automata->present_state($self->automata->get_state_by_key('4')); }
    if ($tag eq 'number') { $automata->present_state($self->automata->get_state_by_key('10')); }

    $self->execute_state_methods($token);
}

1;
