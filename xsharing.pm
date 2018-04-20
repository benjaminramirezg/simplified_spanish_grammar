package xsharing;

use warnings;
use strict;
use locale;
use xtype;
use xfeature;
use Clone;
push @xsharing::ISA, 'Clone';

##########
# MÉTODOS
##########

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

# Un sharing es un objeto que
# se contiene a sí mismo

# Tiene un identificador que le
# permite ser etiquetado en la
# unificación (id)

# Tiene un conjunto de rasgos que 
# son los rasgos de un tipo que
# contienen el sharing en cuestión

# Y tiene un tipo que es el tipo
# quedeben tener por valor todos
# los rasgos de su conjunto de rasgos

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->features([]);

    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

# El string del atributo
# Se comprueba que es legítimo

sub id {       
                     
    my $self = shift;
    if ( @_ ) { $self->{id} = shift; }
    return $self->{id};               
}

sub features {       
                     
    my $self = shift;
    if ( @_ ) { $self->{features} = shift; }
    return $self->{features};               
}

sub type {       
                     
    my $self = shift;
    if ( @_ ) { $self->{type} = shift; }
    return $self->{type};               
}

## AÑADE FEATURES

sub add_feature {

    my $self = shift;
    my $feature = shift;

    push @{$self->features}, $feature;
}

# DEVUELVE LA LISTA DE RASGOS

sub get_features_as_list {

    my $self = shift;

    return @{$self->features};
}

# MÉTODOS PARA RECIBIR INFORMACIÓN DE OTRO SHARING

sub add_features {

    my $self = shift;
    my $source_sh = shift;

    foreach my $feature ($source_sh->get_features_as_list) {

	$feature->sharing($self);
	$self->add_feature($feature);
    }
}

sub change_type {

    my $self = shift;
    my $source_sh = shift;

    $self->type($source_sh->type);

    foreach my $feature ($self->get_features_as_list) {

	$feature->value($self->type);
    }
}

1;
