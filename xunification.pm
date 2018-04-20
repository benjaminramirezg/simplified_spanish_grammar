package xunification;

use warnings;
use strict;
use locale;
use xtype;
use xfeature;
use xsharing_manager;
use Data::Dumper;

#############
# VARIABLES #
#############

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

    $self->sharing_manager(xsharing_manager->new());

    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

## La relación de unificación es asimétrica
## El método recibe dos unificandos, cada
## uno con un rol diferente:
## a) target es el destinatario de la unificación
## b) specif es el tipo que especifica al destinatario

sub target {       
                     
    my $self = shift;
    if ( @_ ) { $self->{target} = shift; }
    return $self->{target};               
}

sub specif {       
                     
    my $self = shift;
    if ( @_ ) { $self->{specif} = shift; }
    return $self->{specif};
}


## Se coloca aquí al gestor de sharings

sub sharing_manager {       
                     
    my $self = shift;
    if ( @_ ) { $self->{sharing_manager} = shift; }
    return $self->{sharing_manager};
}

## Este método referencia un HASH con una colección
## de tipos: la gramática. Debe introducirse desde fuera

sub types {       
                     
    my $self = shift;
    if ( @_ ) { $self->{types} = shift; }
    return $self->{types};
}

## Bandera para evitar la aplicación de los procesos
## generales de sharing

sub no_sharings {       
                     
    my $self = shift;
    if ( @_ ) { $self->{no_sharings} = shift; }
    return $self->{no_sharings};
}

## Bandera para evitar el añadido de rasgos nuevos
## al target

sub no_features {       
                     
    my $self = shift;
    if ( @_ ) { $self->{no_features} = shift; }
    return $self->{no_features};
}

sub report {       
                     
    my $self = shift;
    if ( @_ ) { $self->{report} = shift; }
    return $self->{report};
}

sub test {       
                     
    my $self = shift;
    if ( @_ ) { $self->{test} = shift; }
    return $self->{test};
}

sub flag {       
                     
    my $self = shift;
    if ( @_ ) { $self->{flag} = shift; }
    return $self->{flag};
}


######################
### MÉTODO CENTRAL ###
######################

sub unify {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    $self->report('');
    if ($specif) { $self->specif($specif); }
    if ($target) { $self->target($target); }

    $self->specif or die "No specif in unification.pm";
    $self->target or die "No target in unification.pm";

    $self->no_sharings('0'); # Es el método normal. No se activa ninguna
    $self->no_features('0'); # bandera especial: se aplican todos los procesos

    $self->sharing_manager->start; # Pone a punto para nueva unificación
                                   # al gestor

    $self->unify_types($self->specif,$self->target) or return 0;

    return 1;
}

#############################################
### MÉTODOS DEL PROCESO RECURSIVO CENTRAL ###
#############################################

sub unify_types {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    $self->unify_names($specif,$target) or return 0;
    $self->unify_features($specif,$target) or return 0;

    return 1;
}

# UNIFICACIÓN DE NOMBRES

# Dos nombres unifican si son iguales (are_the_same),
# si uno es subtipo del otro (is_subtype), o si
# ambos tienen un sibtipo en común (common_subty)

sub unify_names {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    $self->are_the_same($specif,$target) and return 1;
    $self->is_subtype($specif,$target)   and return 1;
    $self->is_supertype($specif,$target) and return 1;
    $self->common_subty($specif,$target) and return 1;

    $self->report('Incompatible names '.$specif->name->id.' '.$target->name->id);

    return 0;
}

# MÉTODOS DE COMPROBACIÓN DE SUPUESTOS
# PARA LA UNFICACIÓN DE NOMBRES.
# Si un método tiene éxito, él mismo
# actualiza en consecuencia el nombre 
# del target

# Comprueba si dos nombres son el mismo

sub are_the_same {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    if ($specif->name->id eq $target->name->id) 
    { return 1; }
    return 0;
}

# Comprueba si el especificador es subtipo del target

sub is_subtype {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    if ($specif->name->there_is_parent($target->name->id)) 
    { $target->name($specif->name); 
      return 1; }
    return 0;
}

# Comprueba si el target es subtipo del specific

sub is_supertype {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    if ($target->name->there_is_parent($specif->name->id)) 
    { return 1; }
    return 0;
}

# Comprueba si target y specific tienen un subtipo en común

sub common_subty {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    my $common_sub_name = $target->name->there_is_common_sub($specif->name->id);
    if ($common_sub_name) 
    { $target->name($common_sub_name); 
      return 1; }
    return 0;
}

# UNIFICACIÓN DE RASGOS

# Proceso recursivo que va recorriendo la estructura
# de rasgos del especificador. Cuando esa misma estruc-
# tura aparece en el target, se unifica con unify_types; 
# cuando no, se añade la estructura al target con 
# (add_feature_structure) 

# Se unifican los rasgos del esprcificador 
# de los dos tipos

sub unify_features {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    foreach my $feature_id ($specif->get_features_id_as_list) {

	$self->unify_feature($specif,$target,$feature_id) or 
	return 0;
    }
    return 1;
}

# Se unifica un rasgo en particular. Este rasgo
# ha sido tomado del especificador. Si no
# está en el target, se crea add hoc (add_feature)

# La unificación de los rasgos, en sí, es trivial: dos
# rasgos unifican si unifican sus valores (tipos).
# Pero para ver qué tipos anidados habrá que unificar
# hay que atender a los sharings de los rasgos comparados

# Por tanto, es unify_sharings el método que determina
# los tipos anidados que deben unificar

sub unify_feature {

    my $self = shift;
    my $specif = shift;
    my $target = shift;
    my $feature_id = shift;

    if ($self->flag) { print Dumper $feature_id . " "; }

    $self->no_features                       and # Si target no tiene el rasgo y está activada
    ($target->get_feature_by_id($feature_id) or  # esta bandera, se acaba aquí el proceso
     return 1);

    $target->get_feature_by_id($feature_id) or       # Si target no tiene el rasgo y no hay bandera 
    $self->add_feature($specif,$target,$feature_id); # Se le añade. Se confía en que la unificación
                                                     # anidada continúe la unificación recursivamente
    my $specif_f = $specif->get_feature_by_id($feature_id);
    my $target_f = $target->get_feature_by_id($feature_id);

    my ($nested_s,$nested_t) = $self->unify_sharings($specif_f,$target_f); 
    unless  ($nested_s and $nested_t) { return 1; }

    $self->unify_types($nested_s,$nested_t) 
    or return 0;

    return 1;
}

# Se añade al target estructura de rasgos 
# del especificador

sub add_feature {

    my $self = shift;
    my $specif = shift;
    my $target = shift;
    my $feature_id = shift;

    my $specif_f = $specif->get_feature_by_id($feature_id);
    my $target_f = xfeature->new;
    $target_f->attribute($specif_f->attribute);
    $self->add_value($specif_f,$target_f);
    $target->add_feature($target_f);
}

sub add_value {

    my $self = shift;
    my $specif_f = shift;
    my $target_f = shift;

    my $seen_sharing = 
    $self->sharing_manager->in_seen_target_shs($specif_f->sharing);

    if ($seen_sharing) {

	$target_f->sharing($seen_sharing);
	$target_f->value($seen_sharing->type);
	$seen_sharing->add_feature($target_f);

    } else {

	$target_f->value->name($specif_f->value->name);
    }
}

# Coteja los sharings de dos rasgos comparados mediante
# el gestor sharing_manager. Primero valora qué relación
# se establece entre esos sharings (los dos tienen, ninguno,
# solo el target, solo el specif...): select_method
# En función de cómo se haya valorado, el método update
# actualiza los unificandos de un modo u otro: neutralizando
# tipos si hace falta, o no...

# Fruto de esos cálculos, el gestor ha colocado en ->specif y 
# ->target los que considera que deben ser los nuevos specif
# y target que deben mandarse a unificar. 

sub unify_sharings {

    my $self = shift;
    my $specif_f = shift;
    my $target_f = shift;

    $self->no_sharings and                                    # Si está activada la bandera de no sharings
    return $self->simple_unify_sharings($specif_f,$target_f); # se lanza solo un método alternativo 
                                                              # sencillo
    my $specif_sh = $specif_f->sharing;
    my $target_sh = $target_f->sharing;

    $self->sharing_manager->select_method($specif_sh,$target_sh);
    $self->sharing_manager->update($specif_sh,$target_sh);

    return ($self->sharing_manager->specif,$self->sharing_manager->target);
}




# Método alternativo de gestión de sharings
# Solo es válido si se sabe a ciencia cierta que
# los sharings que se puedan encontrar para
# la neutralización van a llevar el mismo nombre

# Con este método es posible aplicar un sharing #a  
# a un sharing sin id, o dar por buena la identidad 
# de dos sharings, si son #a y #a. Pero no se permite
# relacionar #a y #b 

sub simple_unify_sharings {

    my $self = shift;
    my $specif_f = shift;
    my $target_f = shift;

    $specif_f->sharing->id or 
    return ($specif_f->value, $target_f->value); 

    my $old_target = $target_f->value;

    $target_f->value($specif_f->value);
    $specif_f->sharing->add_feature($target_f);
    $target_f->sharing($specif_f->sharing);
    return ($old_target, $target_f->value); 
}

##########################################
### OTRAS FORMAS DE ACCEDER A LA CLASE ###
##########################################

##

sub unify_test {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    $self->test or return 1;

    my $specif_f = $specif->get_feature_by_id($self->test); 
    my $target_f = $target->get_feature_by_id($self->test); 
 
    $specif_f or return 1;
    $target_f or return 1;

    $specif = $specif_f->value;
    $target = $target_f->value;

    $self->are_the_same($specif,$target) and return 1;
    $self->is_subtype($specif,$target)   and return 1;
    $self->is_supertype($specif,$target) and return 1;
    $self->common_subty($specif,$target) and return 1;

    return 0;
}


## UNIFICAR SIN SHARINGS

sub simple_unify {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    if ($specif) { $self->specif($specif); }
    if ($target) { $self->target($target); }

    $self->specif or die "No specif in unification.pm";
    $self->target or die "No target in unification.pm";

    $self->no_sharings('1');
    $self->no_features('0');

    $self->unify_types($self->specif,$self->target) or return 0;

    return 1;
}

## UNIFICAR SIN AÑADIDO DE RASGOS

sub unify_without_features {

    my $self = shift;
    my $pattern = shift;
    my $target = shift;

    if ($pattern) { $self->specif($pattern); }
    if ($target) { $self->target($target); }

    $self->specif or die "No pattern in unification.pm";
    $self->target or die "No target in unification.pm";

    $self->no_sharings('0');
    $self->no_features('1');

    $self->unify_types($self->specif,$self->target) or return 0;

    return 1;
}

sub unify_with_patterns {

    my $self = shift;
    my $target = shift;
    my $name_id = $target->name->id;

    my $pattern = $self->get_pattern_by_id($name_id);

    $self->unify($pattern,$target) or return 0;
    $self->unify_with_patterns_rec($target) or return 0;
    return 1;
}

sub unify_with_patterns_rec {

    my $self = shift;
    my $target = shift;

    foreach my $feature_id ($target->get_features_id_as_list) {

	my $nested_target = $target->get_feature_by_id($feature_id)->value;
	$self->unify_with_patterns($nested_target) or return 0;
    }
    return 1;
}

sub get_pattern_by_id {

    my $self = shift;
    my $name_id = shift;

    my $pattern = $self->types->{$name_id}->{'type'}; 
    $pattern and $self->sharing_manager->rename_in_type($pattern);
    return $pattern;
}

1;
