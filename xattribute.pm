package xattribute;

use warnings;
use strict;
use locale;

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

sub declared_in {       
                     
    my $self = shift;
    if ( @_ ) { $self->{declared_in} = shift; }
    return $self->{declared_in};               
}

sub value {       
                     
    my $self = shift;
    if ( @_ ) { $self->{value} = shift; }
    return $self->{value};               
}

1;
