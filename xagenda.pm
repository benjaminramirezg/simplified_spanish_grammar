package xagenda;

use warnings;
use strict;
use locale;
use xedge;

#####################
# VARIABLES DE CLASE
##################### 

##########
# MÉTODOS
##########

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

# La agenda es una lista de edges
# pendientes de procesamiento
# Se puede usar como pila o como
# fila, según el parser que la usa 
# sea de uno u otro tipo.

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->edges([]);

    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

sub edges {       
                     
    my $self = shift;
    if ( @_ ) { $self->{edges} = shift };
    return $self->{edges};
}

############################
## MÉTODO DE RECONOCIMIENTO
############################

# Se añade un edge en modo pila
# (en el lugar desde el que será
# el primer elemento en salir)

sub add_edge_in_stack {

    my $self = shift;
    my $edge = shift;

    push @{$self->edges}, $edge;
} 

# Se añade un edge en modo fila
# (en el lugar desde el que será
# el último elemento en salir)

sub add_edge_in_line {

    my $self = shift;
    my $edge = shift;

    unshift @{$self->edges}, $edge;
} 

# Se extrae un elemento de la agenda
# Siempre se extraen desde el mismo
# sitio: el modo fina o pila depende
# de cómo se intriducen los elementos

sub get_edge {

    my $self = shift;

    return pop (@{$self->edges});
} 


sub start_edges {

    my $self = shift;

    $self->edges([]);
} 

1;
