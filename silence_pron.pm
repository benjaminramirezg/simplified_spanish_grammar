package silence_pron;

use warnings;
use strict;
use locale;
use token;
use segment;
use text;
use analysis;
use rule;
use Data::Dumper;

#### VARIABLES

my $V1SG = 0;
my $V1PL = 0;
my $V2SG = 0;
my $V2PL = 0;

my $VME = 0;
my $VTE = 0;
my $VNOS = 0;
my $VOS = 0;

my $YO = 0;
my $TU = 0;
my $NOSOTROS = 0;
my $VOSOTROS = 0;

my $AMI = 0;
my $ATI = 0;
my $ANOSOTROS = 0;
my $AVOSOTROS = 0;

my $PRON = 0;

##############
# Constructor
##############

sub new {

    my $class = shift;
    my $self =  {@_};
    bless ( $self, $class );
    return $self;
}

sub last_id {      
                     
    my $self = shift;
    if ( @_ ) { $self->{last_id} = shift };
    return $self->{last_id};
}

sub current_segment {      
                     
    my $self = shift;
    if ( @_ ) { $self->{current_segment} = shift };
    return $self->{current_segment};
}


#########################
## MÉTODOS DE ANÁLISIS ##
#########################

sub parse {

    my $self = shift;
    my $segment = shift;

    foreach my $token_key ($segment->get_tokens_list) {
	my $token = $segment->get_token_by_key($token_key);
	my ($id, $form, $flex) = 
	    ($token->id, $token->form, []);

	foreach my $ana_key ($token->get_analysis_list) {
	    my $analysis = $token->get_analysis_by_key($ana_key);

	    foreach my $rule_key ($analysis->get_rules_list) {
		my $rule = $analysis->get_rule_by_key($rule_key);
		push @{$flex}, $rule->stem;
	    }
	}
	$self->update_info($id,$form,$flex);
    }

    $self->add_pronouns;
    $self->del_values;
}

sub update_info {

    my $self = shift;
    my $id = shift;
    my $form = shift;
    my $flex = shift;

    $self->last_id($id);
    $self->there_are_pronouns($form);
    $self->check_verbal_flex($flex);
    $self->fix_pronominals;
}

sub there_are_pronouns {

    my $self = shift;
    my $form = $self->uncapitalize_form(shift);

    if ($form =~ /^yo$/) { $YO = 1; }
    if ($form =~ /^tú$/) { $TU = 1; }
    if ($form =~ /^nosotr[oa]s$/) { $NOSOTROS = 1;}
    if ($form =~ /^vosotr[oa]s$/) { $VOSOTROS = 1;}
    if ($form =~ /^a\s+mí$/) { $AMI = 1;}
    if ($form =~ /^a\s+ti$/) { $ATI = 1;}
    if ($form =~ /^a\s+nosotr[oa]s$/) { $ANOSOTROS = 1;}
    if ($form =~ /^a\s+vosotr[oa]s$/) { $AVOSOTROS = 1;}

}

sub check_verbal_flex {

    my $self = shift;
    my $rules = shift;

    foreach my $rule (@{$rules}) {

	if ($rule =~ /^verb-1-sg/) { $V1SG = 1;}
	if ($rule =~ /^verb-1-pl/) { $V1PL = 1;}
	if ($rule =~ /^verb-2-sg/) { $V2SG = 1;}
	if ($rule =~ /^verb-2-pl/) { $V2PL = 1;}
	if ($rule =~ /^verb.*-me-/) { $VME = 1;}
	if ($rule =~ /^verb.*-te-/) { $VTE = 1;}
	if ($rule =~ /^verb.*-nos-/) { $VNOS = 1;}
	if ($rule =~ /^verb.*-os-/) { $VOS = 1;}

	if ($rule =~ /-pronominal-/) { $PRON = 1;}
    }
}


# No lo estamos usando, pq aquí no llega class.

sub fix_pronominals {

    my $self = shift;

    if ($PRON) {

	if ($V1SG and $VME) { $VME = 0; }
	if ($V2SG and $VTE) { $VTE = 0; }
	if ($V1PL and $VNOS) { $VNOS = 0; }
	if ($V2PL and $VOS) { $VOS = 0; }
    }
}

sub uncapitalize_form {       
                     
    my $self = shift;
    my $form = shift;
    $form =~ tr/[A-Z]|Ñ|Á|É|Í|Ó|Ú|Ü)/[a-z]|ñ|á|é|í|ó|ú|ü/;
    return $form;
}

sub del_values {

    my $self = shift;

    $PRON = 0;

    $V1SG = 0;
    $V1PL = 0;
    $V2SG = 0;
    $V2PL = 0;

    $VME = 0;
    $VTE = 0;
    $VNOS = 0;
    $VOS = 0;

    $YO = 0;
    $TU = 0;
    $NOSOTROS = 0;
    $VOSOTROS = 0;

    $AMI = 0;
    $ATI = 0;
    $ANOSOTROS = 0;
    $AVOSOTROS = 0;
}

sub add_pronouns {

    my $self = shift;

    $V1SG and ($YO or $self->add_pronoun('1','sg','nom', 'yo'));
    $V2SG and ($TU or $self->add_pronoun('2','sg','nom', 'tu'));
    $V1PL and ($NOSOTROS or $self->add_pronoun('1','pl','nom', 'nosotros'));
    $V2PL and ($VOSOTROS or $self->add_pronoun('2','pl','nom', 'vosotros'));

    $VME and ($AMI or $self->add_pronoun('1','sg','acc', 'a mí'));
    $VTE and ($ATI or $self->add_pronoun('2','sg','acc', 'a ti'));
    $VNOS and ($ANOSOTROS or $self->add_pronoun('1','pl','acc', 'a nosotros'));
    $VOS and ($AVOSOTROS or $self->add_pronoun('2','pl','acc', 'a vosotros'));
}

sub add_pronoun {

    my $self = shift;
    my $per = shift;
    my $num = shift;
    my $case = shift;
    my $form = shift;

    my $token = token->new();
    $token->form($form);
    $token->from('Z');
    $token->to('Z');
    $token->id($self->get_id);

    my $analysis = analysis->new;
    $analysis->stem($self->get_lemma($case));

    my $rule = rule->new;
    $rule->form($form);
    $rule->stem($self->get_rule($per,$num));

    $analysis->append_rule($rule);
    $token->append_analysis($analysis);
    $self->current_segment->append_token($token);
}

sub get_rule {

    my $self = shift;
    my $per = shift;
    my $num = shift;

    return "chunk-$per-$num-irule";
}

sub get_lemma {

    my $self = shift;
    my $case = shift;

    if ($case eq 'nom') {  return '***-Ta***'; }
    if ($case eq 'acc') {  return '***aTa***'; }
}


sub get_id {

    my $self = shift;
    my $id = $self->last_id; 
    $id++;
    $self->last_id($id);
    return $id;
}

1;
