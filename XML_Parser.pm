package XML_Parser;

use warnings;
use strict;
use locale;
use Encode 'encode', 'decode', 'is_utf8';
use XML::XPath;
use XML::XPath::XMLParser;


#####################
# VARIABLES DE CLASE
##################### 

my $XP;

##########
# MÉTODOS
##########

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );
    $self->code('utf-8');
    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

# Entrada XML

sub input {       
                     
    my $self = shift;
    if ( @_ ) { $self->{input} = shift };
    return $self->{input};
}

sub code {       
                     
    my $self = shift;
    if ( @_ ) { $self->{code} = shift };
    return $self->{code};
}

#######################
### PARSING DE SPPP ###
#######################

sub get_sppp_segments {

    my $self = shift;
    my $input = $self->input;
    $XP = XML::XPath->new( xml => "$input");
    my $set = $XP->find('/text/segment'); 

    return $set->get_nodelist;
}

sub get_sppp_tokens {

    my $self = shift;
    my $segment = shift;
    my $set = $segment->find('./token[@from!="Z"]'); 

    return $set->get_nodelist;
}

sub get_sppp_silence_tokens {

    my $self = shift;
    my $segment = shift;
    my $set = $segment->find('./token[@from="Z"]'); 

    return $set->get_nodelist;
}


sub get_sppp_analysis {

    my $self = shift;
    my $token = shift;
    my $set = $token->find('./analysis'); 

    return $set->get_nodelist;
}


sub get_sppp_rules {

    my $self = shift;
    my $analysis = shift;
    my $set = $analysis->find('./rule'); 

    return $set->get_nodelist;
}

sub get_sppp_form {

    my $self = shift;
    my $obj = shift;
    my $code = $self->code;
    my $form = encode($code,$obj->findvalue('./@form')->value);

    return $form;
}

sub get_sppp_from {

    my $self = shift;
    my $obj = shift;
    my $code = $self->code;
    my $from = encode($code,$obj->findvalue('./@from')->value);

    return $from;
}

sub get_sppp_to {

    my $self = shift;
    my $obj = shift;
    my $code = $self->code;
    my $to = encode($code,$obj->findvalue('./@to')->value);

    return $to;
}

sub get_sppp_stem {

    my $self = shift;
    my $analysis = shift;
    my $code = $self->code;
    my $stem = encode($code,$analysis->findvalue('./@stem')->value);

    return $stem;
}

sub get_sppp_rule_id {

    my $self = shift;
    my $rule = shift;
    my $code = $self->code;
    my $id = encode($code,$rule->findvalue('./@id')->value);

    return $id;
}

sub get_sppp_rule_class {

    my $self = shift;
    my $rule = shift;
    my $code = $self->code;
    my $id = encode($code,$rule->findvalue('./@class')->value);

    return $id;
}

sub is_irule {

    my $self = shift;
    my $rule = shift;

    my $class = $self->get_sppp_rule_class($rule);
    ($class eq 'irule') or return 0;
    return 1;
}

1;
