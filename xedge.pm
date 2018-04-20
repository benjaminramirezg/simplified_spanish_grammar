package xedge;

use warnings;
use strict;
use locale;
use Clone;
push @xedge::ISA, 'Clone';
use Data::Dumper;
#####################
# VARIABLES DE CLASE
##################### 

##########
# MÉTODOS
##########

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

# Un edge es un análsis parcial
# de la secuencia de entrada
# Contiene:

# a) Indicadores relativos a las POSICIONES de
#    de la secuencia de entrada que cubre (start
#    es la posición más a la izquierda, finish es
#    la posición más a la derecha, y location es
#    el conjunto de todas las posiciones que cubre

# b) LABEL. Es el sintagma mismo que el edge representa

# c) TO_FIND. Es la lista de los constituyentes que faltan
#    por encontrar la cadena de entrada para poder crear
#    el sintagma representado por el edge  

# d) FOUND. Es la lista de los edges que representan a los
#    constituyentes ya encontrados para la creación del sin-
#    tagma que representa el edge en cuestión.

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->found([]);
    $self->to_find([]);
    $self->location({});

    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

# UBICACIÓN EN LA CADENA DE ENTRADA

sub start {       
                     
    my $self = shift;
    if ( @_ ) { $self->{start} = shift; }
    return $self->{start};
}

sub finish {       
                     
    my $self = shift;
    if ( @_ ) { $self->{finish} = shift; }
    return $self->{finish};
}

sub location {       
                     
    my $self = shift;
    if ( @_ ) { $self->{location} = shift };
    return $self->{location};
}

# SINTAGMA QUE REPRESENTA EL EDGE
 
sub label {       
                     
    my $self = shift;
    if ( @_ ) { $self->{label} = shift };
    return $self->{label};
}

# EDGES ENCONTRADOS COMO CONSTITUYENTES DEL
# SINTAGMA QUE REPRESENTA EL EDGE

sub found {       
                     
    my $self = shift;
    if ( @_ ) { $self->{found} = shift };
    return $self->{found};
}

# CONSTITUYENTES PENDIENTES DE ENCONTRAR EN
# LA CADENA DE ENTRADA 

sub to_find {       
                     
    my $self = shift;
    if ( @_ ) { $self->{to_find} = shift };
    return $self->{to_find};
}

############################
## MÉTODO DE RECONOCIMIENTO
############################

# AÑADEN ELEMENTOS PENDIENTES DE
# ENCONTRAR O ENCONTRADOS

# Téngase en cuenta que los to_find
# son objetos 'type', perl los 
# found son edges que, a su vez, tienen
# otros edges en found

sub add_found {

    my $self = shift;
    my $found = shift;
    $found or return 1;
    push @{$self->found}, $found;
} 

sub add_to_find {

    my $self = shift;
    my $tofind = shift;
    $tofind or return 1;
    push @{$self->to_find}, $tofind;
}


sub get_found_as_list {

    my $self = shift;
    return @{$self->found};
}

# RECUPERA EL PRIMER CONSTITUYENTE
# PENDIENTE DE ENCONTRAR

sub first_to_find {

    my $self = shift;
    return @{$self->to_find}[0];
}

# RECUPERA EL RESTO DE CONSTITUYENTES
# PENDIENTES DE ENCONTRAR
## - !Cuidado, no vale con pasar a otra variable escalar: apunta a la
## - misma dirección de memoria!

sub rest_to_find {

    my $self = shift;

    my @tofind = @{$self->to_find};
    shift @tofind;
    return [@tofind];
}

## GESTIÓN DE LOCATION

### BÁSICOS

# Añade un 'place' al location

sub add_to_location {

    my $self = shift;
    my $place = shift;

    $self->location->{"$place"} = 1; 
}

# Devuelve la lista de 'places' de un
# location

sub get_location_as_list {

    my $self = shift;

    return keys %{$self->location};
}

# Comprueba si un 'place' es parte de
# un 'location'

sub get_location_by_place {

    my $self = shift;
    my $place = shift;

    (defined $self->location->{"$place"}) or return 0;
    return 1;
}

### COMPROBACIONES ÚTILES

### Determina si un edge cubre un elemento continuo

sub continuous_edge {

    my $self = shift;

    foreach my $place ($self->start .. $self->finish) {

	unless ($self->get_location_by_place($place)) { return 0; }
    }
    return 1;
}

### Determina si un edge cubre la secuencia entera

sub covers_full_string {

    my $self = shift;
    my $lenght_string = shift;

    if ($self->start eq 1 and             
	$self->finish eq $lenght_string and      
	$self->continuous_edge) { return 1; }

    return 0;
}

# Crea una location continua a partir de los
# valores de inicio y final

sub create_continuous_location {

    my $self = shift;
    my $start = shift;
    my $finish = shift;

    $self->start($start);
    $self->finish($finish);

    foreach my $place ($self->start .. $self->finish) {

	$self->add_to_location($place);
    }
    return 1;
}

# Se le aplican a un edge los places de otro edge

sub add_to_location_from_edge {

    my $self = shift;
    my $edge = shift;

    foreach my $place ($edge->get_location_as_list) {

	$self->add_to_location($place);
    }

    $self->update_start_and_finish;
}

# Método auxiliar que actualiza start y finish
# tras recibir un edge 'places'

sub update_start_and_finish {

    my $self = shift;
    my $flag = 0;

    foreach my $place (sort { $a <=> $b } $self->get_location_as_list) {

	unless ($flag) { $self->start($place); }
	$self->finish($place);
	$flag = 1;
    }
}

### FUNCIÓN PARA DETERMINAR SI EL LHS DE UN EDGE
### UNIFICA CON UNA CIERTA DESCRIPCIÓN GRAMATICAL

sub merge {

    my $self = shift;
    my $path = shift;
    my $value = shift;

    $self->label->get_feature_by_id($path) or return 0;
    ($self->label->get_feature_by_id($path)->value->name->id eq $value) and
    return 0;

    return 1;
}

1;
