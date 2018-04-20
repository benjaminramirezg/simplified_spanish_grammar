package xsharing_manager;

use warnings;
use strict;
use locale;
use xsharing;
use xfeature;

#############
# VARIABLES #
#############

## Contador para renombrar ids de sharing
## No se pone a cero nunca para evitar la
## identidad espúrea de sharings vistos en
## unificaciones anteriores con los vistos
## en la presente

my $counter = 0;

###############
# CONSTRUCTOR #
###############

## El objeto tiene dos repositorios fundamentales

## El de sharings de target (seen_target_shs) tiene claves
## que son los distintos ids de sharing de target
## vistos. Su valor es el sharing correspondiente.

## El repositorio de specif tiene una estructura ad
## hoc, pensada para llevar cuenta (sin modificar el
## tipo) de las identidades encontradas entre ids de
## sharing de target y specif.

## La clase va recibiendo información de los sharings
## cotejados en la unificación, y, mediante estos re-
## positorios, va identificando los sharings de target
## que, dados los sharings de specif, deben aglutinarse

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );
    $self->seen_target_shs({});
    $self->seen_specif_shs({});

    return $self;
}

sub DESTROY {

    my $self = shift;
}

###############
### GET-SET ###
###############

## REPOSITORIO DE SHARINGS DEL TARGET

sub seen_target_shs {       
                     
    my $self = shift;
    if ( @_ ) { $self->{seen_target_shs} = shift };
    return $self->{seen_target_shs};
}

## REPOSITORIO DE SHARINGS DEL SPECIF

sub seen_specif_shs {       
                     
    my $self = shift;
    if ( @_ ) { $self->{seen_specif_shs} = shift };
    return $self->{seen_specif_shs};
}

## VARIABLE QUE DEFINE EL MODO DE COTEJO DE
## SHARINGS QUE DEBE USARSE, DE ACUERDO CON 
## CÓMO SON LOS SHARINGS COMPARADOS

sub method {       
                     
    my $self = shift;
    if ( @_ ) { $self->{method} = shift };
    return $self->{method};
}

## IDENTIFICAN QUIÉNES HAN DE SER LOS
## TIPOS SPECIF Y TARGET A UNIFICAR
## DE ACUERDO CON LA INFORMACIÓN DE
## SHARINGS

## Desde unification se activan los procesos de
## cotejo de sharings, y, una vez hecho esto, se
## presupone que esta clase ha dejado en estos
## métodos quiénes deben ser, en consecuencia, los
## tipos target y especif que deben unificarse como
## valores de los rasgos de los sharings comparados

sub target {       
                     
    my $self = shift;
    if ( @_ ) { $self->{target} = shift };
    return $self->{target};
}

sub specif {       
                     
    my $self = shift;
    if ( @_ ) { $self->{specif} = shift };
    return $self->{specif};
}

###############################
# GESTIÓN DE LOS REPOSITORIOS #
###############################

## PONEN A CERO LOS REPOSITORIOS

## Se aplican por cada unificación

sub start_seen_target_shs {

    my $self = shift;
    $self->seen_target_shs({});
}

sub start_seen_specif_shs {

    my $self = shift;
    $self->seen_specif_shs({});
}

## CONSULTAN SI UN SHARING
## SE HA CODIFICADO YA EN LOS
## REPOSITORIOS

## Cuando se busca en seen_target_shs, se devuelve el objeto sharing
## de target con el identificador correspondiente

## Si no tiene id, es su primera unificación, y, originalmente, no 
## comparte estructura. Esto pedirá que se renombre como cualquier
## primer sharing de target (return 0)
 
sub in_seen_target_shs {

    my $self = shift;
    my $sharing = shift;

    $sharing->id or return 0; 
    defined $self->seen_target_shs->{$sharing->id}
    and return $self->seen_target_shs->{$sharing->id};
    return 0;
}

## Cuando se busca en seen_specif_shs, se consulta si en specif  
## se ha nombrado ya a algún sharing con un determinado id. Pero,
## specif_shs no guarda los sharings mismos (no se van a modificar).
## Por ello, en caso positivo, solo se devuelve el id de target con
## el que se relacionó el id de specif en cuestión

## Si un sharing nuevo de specif (#a) se cotejó con un sharing ya visto
## de target (#b), en seen_specif_shs se traduce #a => #b. De este modo,
## sin cambiar specif, se puede buscar la correspondencia en target a un
## sharing de specif (que, como se ve, no siempre es  trivial)

sub in_seen_specif_shs {

    my $self = shift;
    my $sharing = shift;

    $sharing->id or return 0;
    my $id;

    defined $self->seen_specif_shs->{$sharing->id}            and
    defined $self->seen_specif_shs->{$sharing->id}->{'name'} and
    return $self->seen_specif_shs->{$sharing->id}->{'name'};
    return 0;
}

# Método equivalente al anterior, que devuelve
# no el name del sharing virtual sino el related

sub related_specif_shs {

    my $self = shift;
    my $sharing = shift;

    $sharing->id or return 0;
    my $id;

    defined $self->seen_specif_shs->{$sharing->id}            and
    defined $self->seen_specif_shs->{$sharing->id}->{'related'} and
    return $self->seen_specif_shs->{$sharing->id}->{'related'};
    return 0;
}

##############################
# RENOMBRAMIENTO DE SHARINGS #
##############################

# A PARTIR DE LA VARIABLE COUNTER
# CREA UN NUEVO NOMBRE DE SHARING

sub get_new_sharing_id {

    my $self = shift;
    return "#".$counter++;
}

# CAMBIA EN UN SHARING EL NOMBRE
# POR UNO QUE SE LE PASA COMO 
# ARGUMENTO

sub rename {

    my $self = shift;
    my $sharing = shift;
    my $new_id = shift;

    $sharing->id($new_id);
}

# Los métodos de actualizaión de los repositorios
# también enmascaran procesos distintos

# El de seen_target_shs, sencillamente, añade un objeto sharings

sub update_seen_target_shs {

    my $self = shift;
    my $sharing = shift;

    $self->seen_target_shs->{$sharing->id} = $sharing;
}

# El de seen_specif_shs crea un HASH (sharing virtual)
# donde regulará a qué sharing de target corresponde
# el id del sharing de specif que se le pasa como
# argumento

# El sharing virtual es un HASH con una clave 'name'
# y una clave 'related'. En 'name' se coloca el id
# correspondiente en seen_target_shs. En 'related' se coloca
# el conjunto de claves de specif que llevan esa clave
# de target asociada. 

# Cuando un sharing #a de target aparece por segunda vez, frente
# a un sharing #b de specif nuevo, habría que aglutinar esos dos
# sharings distintos de specif en uno (téngase en cuenta que la
# aparición de #a repetida en target supone que también ha aparecido 
# ya un #a, real o virtual, de specif). Como ese cambio no puede operarse
# realmente en specif (no queremos que la unificación lo altere)
# hay que crear un aglutinamiento virtual de los #a y #b de specif. 
# Para ello, a #b se le crea una entrada en seen_specif_shs, que lo traduce 
# ('name') a #a (el #a specif ya tendría una entrada que se traduce a sí misma). 

# Para que esta traducción virtual permita identificar con #a y #b un tercer
# cuarto, etc. sharing, a #a y #b hay que colocarles una clave anidada
# 'related' cuyo valor es el conjunto de claves de seen_specif_shs
# que tienen la misma traducción en 'name' (que se consideran virtualmente
# neutralizadas en una). Para #a y para #b, ese conjunto sería {#a, #b}
# Si se quiere neutralizar a continuación #b y #c, habría que poner el
# mismo 'name' a todas las claves del 'related' de #b y #c (es decir,
# a #a, #b y #c, suponiendo que #c aparece por primera vez). Para que este 
# proceso sea recursivo, los related de todas esas claves (#a, #b y #c) 
# deben ser la unión de los 'related' de #b y #c = {#a, #b, #c}

sub update_seen_specif_shs {

    my $self = shift;
    my $specif_sh = shift;

    my $virtual_sharing = $self->new_virtual_sharing;

    $self->add_virtual_name($virtual_sharing,$specif_sh->id);
    $self->add_virtual_related($virtual_sharing,$specif_sh->id);
    $self->seen_specif_shs->{$specif_sh->id} = $virtual_sharing;
}

# Creación del sharing virtual

sub new_virtual_sharing {

    my $self = shift;
    my $name = shift;

    my $sharing = {};
    $sharing->{'name'} = 0;
    $sharing->{'related'} = {};

    return $sharing;
}

sub add_virtual_name {

    my $self = shift;
    my $virtual_sharing = shift;
    my $name = shift;

    $virtual_sharing->{'name'} = $name;
}

sub add_virtual_related {

    my $self = shift;
    my $virtual_sharing = shift;
    my $related = shift;

    $virtual_sharing->{'related'}->{$related} = 1;
}

##########################
### PROCESOS CENTRALES ###
##########################

## DECIDE EN QUÉ SITUACIÓN DE COTEJO SE
## ENCUENTRAN LOS SHARINGS COMPARADOS

sub select_method {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    $self->both_new($specif,$target)   and return 1;
    $self->specif_new($specif,$target) and return 1;
    $self->target_new($specif,$target) and return 1;
    $self->both_old($specif,$target)   and return 1;
}

## a) Ambos aparecen por primera vez en la unificación:
##    en tal caso, para cada uno se creará en su repositorio
##    una entrada nueva, pero AMBAS TIENEN EL MISMO NOMBRE

sub both_new {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    ($self->in_seen_target_shs($target)           or 
     $self->in_seen_specif_shs($specif))          and
    return 0;

    $self->method('update_both_new');
    return 1;
}

## b) Ambos son ya conocidos en la unificación: en tal caso,
##    a menos que sean el mismo sharing, el de target se 
##    renombrará hacia el de spefic
##    Ese proceso creará una neutralización real de lo que
##    antes eran sharings (y tipos) distintos

sub both_old {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    ($self->in_seen_target_shs($target)           and 
     $self->in_seen_specif_shs($specif))          and
     $self->method('update_both_old')  and
    return 1;

    return 0;
}

## c) Target es nuevo y specif ya conocido: en este caso, 
##    target se renombra hacia specif
##    Ese proceso creará una neutralización real de lo que
##    antes eran sharings (y tipos) distintos

sub target_new {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    $self->in_seen_target_shs($target)              or 
    ($self->in_seen_specif_shs($specif)             and 
     $self->method('update_target_new')  and
     return 1);
	
    return 0;
}

## d) Specif es nuevo y target conocido. Solo en este caso,
##    el specif se renombra hacia target. Este renombramiento
##    tiene que ser virtual, porque la unificación no debe
##    modificar nunca specif.
##    En este caso, a specif se le pone un sharing real nuevo,
##    pero en seen_specif_shs ese sharing se 'traduce' al id
##    del sharing de target. En seen_specif_shs se aglutinan
##    de forma virtual sharings distintos de specif para recrear
##    las identidades de target ajenas a specif.

sub specif_new {

    my $self = shift;
    my $specif = shift;
    my $target = shift;

    $self->in_seen_specif_shs($specif)              or 
    ($self->in_seen_target_shs($target)             and 
     $self->method('update_specif_new')  and
     return 1);
	
    return 0;
}

### MÉTODOS DE REVISIÓN DE LOS SHARINGS
### UNA VEZ COMPROBADA LA SITUACIÓN DE
### COTEJO EN LA QUE SE ENCUENTRAN

### Se lanza un método u otro, en función
### de la situación (method) observada

sub update {

    my $self = shift;
    my $specif = shift;
    my $target = shift;
    my $method = $self->method;

    $self->$method($specif,$target);
}

# REVISIÓN DE SHARINGS CUANDO LOS DOS SON NUEVOS

# Hay que renombrarlos. Se crea un mismo nombre
# que se asociará a cada sharing por separado
# Se actualizan los repositorios en consecuencia

# En este caso, los unificandos que saca la clase
# son los tipos de los sharings (situación natural)

sub update_both_new {

    my $self = shift;
    my $specif_sh = shift;
    my $target_sh = shift;

    my $id = $self->get_new_sharing_id;

    $self->rename($specif_sh,$id);
    $self->rename($target_sh,$id);

    $self->update_seen_specif_shs($specif_sh);
    $self->update_seen_target_shs($target_sh);

    $self->normal_output($specif_sh,$target_sh); # Crea los tipos para la unificación
}                                                # conforme al patrón normal

# REVISIÓN DE SHARINGS CUANDO AMBOS SON VIEJOS

# Si son el mismo, no hay nada que identificar

# Si no, el sharing de target se neutraliza con
# el sharing de target correspondiente al id de
# specif

sub update_both_old {

    my $self = shift;
    my $specif_sh = shift;
    my $target_sh = shift;

    ($specif_sh->id eq $target_sh->id) and
     return $self->seen_output; # Da señal de que no hay nuevos tipos a unificar

    my $related_target_sh = $self->get_related_target_sh($specif_sh);
    $self->neutralize_output($related_target_sh,$target_sh); 
    $self->neutralize_target($related_target_sh,$target_sh); # Crea los tipos para la unificación
}                                                            # conforme al patrón propio de la neutralización


# REVISIÓN DE SHARINGS CUANDO EL TARGET ES NUEVO
# PERO EL SPECIF YA ES CONOCIDO

# A efectos prácticos, es el mismo caso que el anterior

sub update_target_new {

    my $self = shift;
    my $specif_sh = shift;
    my $target_sh = shift;

    my $related_target_sh = $self->get_related_target_sh($specif_sh);
    $self->neutralize_output($related_target_sh,$target_sh); 
    $self->neutralize_target($related_target_sh,$target_sh); # Crea los tipos para la unificación
}                                                            # conforme al patrón propio de la neutralización

# REVISIÓN DE SHARINGS CUANDO EL SPECIF ES NUEVO
# PERO EL TARGET YA ES CONOCIDO

# Este es el único caso en que es specif el que debería
# cambiar su nombre para convertirse en el de target
# Pero esto es imposible, porque specif no puede cambiarse
# nunca. Por tanto, neutralize_specif enmascara un proceso
# distinto al de neutralize_target. En este caso, no se
# cambian los sharings de specif, sino sus sharings virtuales
# del repositorio seen_specif_shs. 

sub update_specif_new {

    my $self = shift;
    my $specif_sh = shift;
    my $target_sh = shift;

    my $id = $self->get_new_sharing_id;
    $self->rename($specif_sh,$id);
    $self->update_seen_specif_shs($specif_sh);

    $self->neutralize_specif($target_sh,$specif_sh);
    $self->normal_output($specif_sh,$target_sh);# Crea los tipos para la unificación
}                                               # conforme al patrón normal

## MÉTODOS AUXILIARES PARA LA NEUTRALIZACIÓN

# A partir del sharing de specif se devuelve el
# sharing correspondiente en target, de acuerdo
# con las neutralizaciones virtuales que esconde
# in_seen_specif_sh

sub get_related_target_sh {

    my $self = shift;
    my $specif_sh = shift;

    my $related_target_sh_id = $self->in_seen_specif_shs($specif_sh);
    return $self->seen_target_shs->{$related_target_sh_id};
}

# Métodos para crear la salida de tipos de un modo u otro
# El caso normal en el que cada rasgo da su tipo original
# como nuevo input

sub normal_output {

    my $self = shift;
    my $specif_sh = shift;
    my $target_sh = shift;

    $self->specif($specif_sh->type);
    $self->target($target_sh->type);
}

# Cuando los dos sharings se han identificado
# como ya vistos, se deja a cero la salida

sub seen_output {

    my $self = shift;

    $self->specif('0');
    $self->target('0');
}

# Cuando hay neutralización, el nuevo specif será el tipo de
# target original con el cual se aglutina el nuevo tipo visto
# El nuevo target será el tipo de target

sub neutralize_output {

    my $self = shift;
    my $related_target_sh = shift;
    my $target_sh = shift;

    $self->target($target_sh->type);
    $self->specif($related_target_sh->type);
}

# MÉTODOS DE NEUTRALIZACIÓN DE SHARINGS DE
# TARGETS Y DE SHARINGS VIRTUALES DE SPECIF

# NEUTRALIZACIÓN DE SHARINGS DE TARGET

# Se aglutinan el sharing relacionado y el
# original del siguiente modo
# a) El sharing resultante para todos los
#    rasgos aglutinados será el relacionado
# b) El tipo de todos esos sharings y el de los
#    rasgos será el original

sub neutralize_target {

    my $self = shift;
    my $related_target_sh = shift;
    my $target_sh = shift;

    $related_target_sh->add_features($target_sh);
    $related_target_sh->change_type($target_sh); 
}                                                

# NEUTRALIZACIÓN DE SHARINGS VIRTUALES

sub neutralize_specif {

    my $self = shift;
    my $target_sh = shift;
    my $source_sh = shift;

    my $t_sh_related = $self->related_specif_shs($target_sh);
    my $s_sh_related = $self->related_specif_shs($source_sh);

    my $neutralized_related = $self->neutralize_related($s_sh_related,$t_sh_related);
    my $neutralized_name = $target_sh->id;

    $self->neutralize_specif_aux($neutralized_related,$neutralized_name);
}

sub neutralize_related {

    my $self = shift;
    my $related_target_sh = shift;
    my $related_source_sh = shift;

    foreach my $id (keys %{$related_source_sh}) {

	$related_target_sh->{$id} = 1;
    }

    return $related_target_sh;
}

sub neutralize_specif_aux {

    my $self = shift;
    my $related = shift;
    my $name = shift;

    foreach my $id (keys %{$related}) {

	$self->seen_specif_shs->{$id}->{'name'} = $name;
	$self->seen_specif_shs->{$id}->{'related'} = $related;
    }
}

### COMENZAR TODO

sub start {

    my $self = shift;

    $self->start_seen_target_shs;
    $self->start_seen_specif_shs;
}

sub rename_in_type {

    my $self = shift;
    my $type = shift;

    foreach my $feature_id ($type->get_features_id_as_list) {

	my $feature = $type->get_feature_by_id($feature_id);
	my $id = $self->get_new_sharing_id;
	$self->rename($feature->sharing,$id);
	$self->rename_in_type($feature->value);
    }
}

1;
