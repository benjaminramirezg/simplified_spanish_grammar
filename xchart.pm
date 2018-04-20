package xchart;

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

# El chart tiene dos repositorios: uno de edges activos
# y otro de edges inactivos. Se ofrecen métodos para 
# guardarlos y acceder a ellos. 

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->active_edges([]);
    $self->inactive_edges([]);

    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

# REPOSITORIOS

sub active_edges {       
                     
    my $self = shift;
    if ( @_ ) { $self->{active_edges} = shift };
    return $self->{active_edges};
}

sub inactive_edges {       
                     
    my $self = shift;
    if ( @_ ) { $self->{inactive_edges} = shift };
    return $self->{inactive_edges};
}


# PONE A CERO LOS REPOSITORIOS

sub start_active_edges {       
                     
    my $self = shift;
    $self->active_edges([]); 
}

sub start_inactive_edges {       
                     
    my $self = shift;
    $self->inactive_edges([]); 
}

# MÉTODOS DE AÑADIDO A LOS REPOSITORIOS

sub add_active_edge {

    my $self = shift;
    my $edge = shift;

    push (@{$self->active_edges}, $edge);
} 


sub add_inactive_edge {

    my $self = shift;
    my $edge = shift;

    push (@{$self->inactive_edges}, $edge);
} 

# Este método decide si un edge es de uno
# u otro tipo, y lo coloca en el repositorio
# correspondiente

sub add_edge {

    my $self = shift;
    my $edge = shift;

    if ($edge->first_to_find) {

	$self->add_active_edge($edge);
    } else {

	$self->add_inactive_edge($edge);
    }
}

# Devuelven los edges de uno u otro repositorio 
# como una lista

sub get_active_edges_as_list {

    my $self = shift;

    return @{$self->active_edges};
}


sub get_inactive_edges_as_list {

    my $self = shift;
    my @out;
    return @{$self->inactive_edges};
}

1;
