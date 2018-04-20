package xfeature;

use warnings;
use strict;
use locale;
use xtype;
use xsharing;
use Clone;
push @xfeature::ISA, 'Clone';

#####################
# VARIABLES DE CLASE
##################### 

##########
# MÉTODOS
##########

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

# Es un par atributo / valor
# El atributo es un elemento 
# 'attribute'. El valor es un
# elemento 'type'
# Se crea directamente el valor
# Pero no el atribto, pues estos
# son un conjunto cerrado creado
# en la gramática

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->value(xtype->new);
    $self->sharing(xsharing->new);
    $self->sharing->type($self->value);
    $self->sharing->add_feature($self);

    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

sub attribute {       
                     
    my $self = shift;
    if ( @_ ) { $self->{attribute} = shift; }
    return $self->{attribute};
}

sub value {       
                     
    my $self = shift;
    if ( @_ ) { $self->{value} = shift; }
    return $self->{value};
}

sub sharing {       
                     
    my $self = shift;
    if ( @_ ) { $self->{sharing} = shift; }
    return $self->{sharing};
}

1;
