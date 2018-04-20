package xtype;

use warnings;
use strict;
use locale;
use xfeature;
use xname;
use Clone;
push @xtype::ISA, 'Clone';

##########
# MÉTODOS
##########

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

# Se crea el hash de rasgos
# El nombre no, porque los nombres son
# un conjunto de objetos cerrados creado
# en grammar

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->features({});    

    return $self;
}

sub DESTROY {

    my $self = shift;

    foreach my $id ($self->get_features_id_as_list) {

	$self->get_feature_by_id($id) and
	$self->get_feature_by_id($id)->sharing(undef);
    }
}

####################
# MÉTODOS DE ACCESO
####################

## Útil para la creación de tipos desde
## archivos TDL. Es una bandera que dice
## si es un añadido a un tipo previamente
## definido.

sub add {       
                     
    my $self = shift;
    if ( @_ ) { $self->{add} = shift };
    return $self->{add};
}

# Clase del tipo: type, grule, lrule, etc.

sub class {       
                     
    my $self = shift;
    if ( @_ ) { $self->{class} = shift;} 
    return $self->{class};
}

# Nombre del tipo
# Será un objeto 'name'

sub name {       
                     
    my $self = shift;
    if ( @_ ) { $self->{name} = shift;} 
    return $self->{name};
}

# HASH de rasgos del tipo

sub features {       
                     
    my $self = shift;
    if ( @_ ) { $self->{features} = shift; }
    return $self->{features};
}

#############################################
# MÉTODOS DE ACCESO Y GESTIÓN DE LOS RASGOS #
#############################################

# Elimina un rasgo. Útil para podar estructura redundante en el parsing
# (todo lo que se define como USELESS en globals).

sub del_feature_by_id {

    my $self = shift;
    my $feature_id = shift;
    
    if (defined $self->features->{$feature_id}) { 
	delete $self->features->{$feature_id}; }
}

# Devuelve la lista de identificadores de rasgos

sub get_features_id_as_list {       
                     
    my $self = shift;

    return keys %{$self->features};
}

# Obtiene un rasgo a partir de un id
# Si el id es un 'path' complejo se pasa
# a get_feature_by_path. 

# Path complejo: 'attribute_id#attribute_id etc.'

sub get_feature_by_id {       
                     
    my $self = shift;
    my $feature_id = shift;

    $self->is_path($feature_id) and 
    return $self->get_feature_by_path($feature_id);

    unless (defined $self->features->{$feature_id}) { return 0; }
    return $self->features->{$feature_id};
}

# Determina si un identificador es un path complejo

sub is_path {


    my $self = shift;
    my $path = shift;

    if ($path =~ /^([^#]+#)+[^#]+$/) { return 1; }
    return 0;
}

# Devuelve un path como lista

sub get_path_as_list {

    my $self = shift;
    my $path = shift;

    return split "#", $path;
}


# Método auxiliar para casos en que sea
# un path lo que se pasa a get_feature_by_id

sub get_feature_by_path {       
                     
    my $self = shift;
    my $path = shift;
    my @path = $self->get_path_as_list($path);

    my $feature = $self->get_feature_by_id(shift @path);

    foreach my $attribute (@path) {

	unless ($feature) { return 0; }
	$feature = $feature->value->get_feature_by_id($attribute);
    }

    return $feature;
}

# Añade un rasgo
# Se comprueba que sea legítimo.

sub add_feature {       
                     
    my $self = shift;
    my $feature = shift;

    $self->check_feature($feature);
    $self->features->{$feature->attribute->id} = $feature;
}

sub check_feature {

    my $self = shift;
    my $feature = shift;

    $feature or die "No feature in type.pm";
    (ref($feature) eq 'xfeature') or die "Bad feature in type.pm";
}


1;
