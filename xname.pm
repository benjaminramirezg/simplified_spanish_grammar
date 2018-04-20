package xname;

use warnings;
use strict;
use locale;

##########
# MÉTODOS
##########

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

# Tiene un identificador. No se especifica,
# porque es un literal

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->parents({});
    $self->common_sub({});

    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

# El string del nombre

sub id {       
                     
    my $self = shift;
    if ( @_ ) { $self->{id} = shift; }
    return $self->{id};               
}

# Los padres (mediatos e inmediatos) del tipo
# Se colocan como literales, no como objetos

sub parents {       
                     
    my $self = shift;
    if ( @_ ) { $self->{parents} = shift; }
    return $self->{parents};               
}

# Los subtipos del tipo comunes a otros supertipos
# inmediatos.Es un hash de estructura 
# supertipo_hermano->subtipo_comun = 1;

sub common_sub {       
                     
    my $self = shift;
    if ( @_ ) { $self->{common_sub} = shift; }
    return $self->{common_sub};               
}

#############################
### GESTIÓN DE LOS PADRES ###
#############################


#############################################
# MÉTODOS DE ACCESO Y GESTIÓN DE LOS PADRES #
#############################################

# Devuelve la lista de identificadores
# de padres del nombre

sub get_parents_id_as_list {       
                     
    my $self = shift;

    return keys %{$self->parents};
}

# Devuelve la lista de identificadores
# de nombres hermanos que tienen algún 
# subtipo en común el nombre

sub get_common_sub_id_as_list {       
                     
    my $self = shift;

    return keys %{$self->common_sub};
}


# Decide si el nombre que se le pasa como argumento
# se ha declarado como padre

sub there_is_parent {

    my $self = shift;
    my $parent_id = shift;

    if (defined $self->parents->{$parent_id})
      { return 1; }
    return 0;
}

# Decide si el nombre que se le pasa como argumento
# se ha declarado como hermano con un subtipo común
# Devuelve el subtipo común

sub there_is_common_sub {

    my $self = shift;
    my $common_sub_id = shift;

    if (defined $self->common_sub->{$common_sub_id})
      { return $self->common_sub->{$common_sub_id}; }
    return 0;
}

# Añade un padre al nombre

sub add_parent {

    my $self = shift;
    my $parent = shift;

    $self->parents->{$parent} = 1;
} 

# Añade un hermano con el que tiene un subtipo común

sub add_common_sub {

    my $self = shift;
    my $brother = shift;
    my $daughter = shift;

    $self->common_sub->{$brother} = $daughter;
} 


1;
