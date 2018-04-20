package xgrammar;

use warnings;
use strict;
use locale;
use xtype;
use xfeature;
use xattribute;
use xname;
use xsharing;
use xunification;
use DBI;
use xTDL_Tok;
use Data::Dumper;

#####################
# VARIABLES DE CLASE
##################### 

# Referencia a la DB

my $dbh;

# Sharings ya vistos en un tipo que se está creando

my $seen_sharings = {};

# Nombres de glbtype

my $glbtype;

##########
# MÉTODOS
##########

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

# El objeto es un repositorio de elemenotos gramaticales
# En orden: a) Nombres de tipos: names
#           b) Nombres de rasgos (atributos): attrs
#           c) Los tipos que forman la gramática: types

# La gramática consiste en el repositorio de tipos 'type' de
# $self->types, indexados con el nombre del tipo como key.

# Los nombres de cada tipo son referencias a objetos únicos
# 'name' guardados en $self->names. Y los atributos de los 
# rasgos son también referencias a objetos únicos 'attribute'
# guardados en 'attrs'. Cada nombre de tipo de la gramática
# se corresponde, entonces, a un único objeto 'name', y cada
# nombre de atributo se corresponde a un único 'attribute'.
# 'name' y 'attribute' cuentan con información relevante
# para la unificación (Cf. name.pm y atribute.pm)  

# Existen, además, métodos para acceder a los tipos como
# reglas: get_lhs, get_rhs1 y get_rhs2

# Además, usa un objeto unificador: unification
# Y usa variables globales tomadas de un archivo: globals.

# Se meten por defecto el nombre de la base de datos
# el nombre del usuario de DB y la contraseña correspondiente

# También se mete un directorio donde la clase buscará
# diversos archivos (globals, script)

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->names({});
    $self->attrs({});
    $self->types({});
    $self->directory('./'); # Importante terminar con "/" para poder  
                                                          # unir este string al nombre de archivo
    $self->globals({});
    $self->TDL_Tok(xTDL_Tok->new()); # Se crea un parser de TDL para cargar gramáticas TDL en DB
    return $self;
}

sub DESTROY {

    my $self = shift;
}

##################################
### MÉTODOS DE INTERACCIÓN CON ###
### ELEMENTOS EXTERNOS         ###
##################################

############ BASE DE DATOS

# Función general para abrir la gramática en BD
# Hay que pasarle el nombre de la gramática, el nombre de
# usuario de base de datos y la contraseña correspondiente
# El constructor mete unos por defecto

sub open_DB {

    my $self = shift;
    my $name = $self->name;
    my $user_DB = $self->user_DB;
    my $password_DB = $self->password_DB;

    unless ($name) { die "No se ha pasado el nombre de la gramática"; }
    unless ($user_DB) { die "No se ha pasado el nombre de usuario de la base de datos"; }
    unless ($password_DB) { die "No se ha pasado contraseña para la base de datos"; }

    $dbh = DBI->connect("dbi:mysql:$name","$user_DB","$password_DB") ||
	die "Error opening database: $DBI::errstr\n";
}

###########  ARCHIVO GLOBALS

# En este archivo se recoge información de la
# gramática que interactúa con la librería

# Cada elemento de este archivo se guarda en 
# $self->globals

sub load_globals {

    my $self = shift;
    my $file = $self->get_globals_file;

    my $RE = qr/^([^\t]+)\t([^\s]+)\n?$/;

    open GLOBALS, "<$file";

    while (<GLOBALS>) {

	if (/$RE/) { $self->globals->{$1} = $2; }
    }
    close GLOBALS;
}

# get_globals_file crea la ruta hasta el archivo
# globals mediante el directorio definido para
# la librería en $self->directory. En ese directorio
# el archivo se debe llamar 'globals'.

# Las claves de globals deben ser:

# TOP        El nombre del tipo raíz de la gramática (vg. *top*)

# STEM       La ruta del signo lingüístico donde se colocan
#            las cadenas de caracteres de este (vg. STEM#LIST#FIRST)

# RHS        La ruta del signo donde se listan los constituyentes
#            sintagmáticos (vg. ARGS)

# RHS1       La ruta donde se encuentra el primer constituyente
#            (vg. ARGS#FIRST)

# RHS2       La ruta donde se encuentra el primer constituyente
#            (vg. ARGS#REST#FIRST)

# LAST       La ruta del signo donde se comprueba si un signo
#            subcategoriza más de un complemento (útil para el
#            scrambling (vg. SYNSEM#LOCAL#VAL#COMPS#REST)

# USELESS    La lista de rasgos que deben obviarse en la
#            unificación (vg. ARG-ST|ARGS|NON-HEAD-DTR|HEAD-DTR|DTR)

# STRING     El nombre del tipo que identifica la presencia de una cadena de
#            caracteres del signo (vg. string)

# RELATION   El nombre del tipo que marca la presencia de un identificador
#            de relación predicativa (relation)

# STRING_RE  Expresión regular identificadora de strings

# RELATION_RE   Expresión regular identificadora de relations

# INFLECTED  Ruta de rasgos para determinar si un signo está flexionado

# CONSTRUCTION   Ruta de rasgos para determinar si un signo está especificado
#                en cuanto a sus reglas léxicas necesarias

# BOOL+      Nombre del tipo que representa al valor booleano positivo

# BOOL-      Nombre del tipo que representa al valor booleano negativo

sub get_globals_file {

    my $self = shift;
    return $self->directory . 'globals';
}

# Devuelve el valor de globals para la
# key que se le pasa como argumento

sub get_globals {

    my $self = shift;
    my $key = shift;
    
    if (defined $self->globals->{$key}) 
    { return $self->globals->{$key}; }
    die "Global $key not found";
}

###           ####
# Archivo script #
###           ####

# Archivo que lista los archivos TDL de la
# gramática para cargar

sub get_script_file {

    my $self = shift;
    return $self->directory . $self->name. '.script';
}

# Archivo con el código SQL para crear
# las tablas de una gramática SQL

sub get_sql_file {

    my $self = shift;
    return $self->directory . 'ssg.sql';
}

#######################
### MÉTODOS GET-SET ###
#######################

# NOMBRE DE LA GRAMÁTICA EN DB

sub name {       
                     
    my $self = shift;
    if ( @_ ) { $self->{name} = shift };
    return $self->{name};
}

# USUARIO DEL SERVIDOR DB

sub user_DB {       
                     
    my $self = shift;
    if ( @_ ) { $self->{user_DB} = shift };
    return $self->{user_DB};
}

# CONTRASEÑA PARA EL USUARIO DEL SERVIDOR DB

sub password_DB {       
                     
    my $self = shift;
    if ( @_ ) { $self->{password_DB} = shift };
    return $self->{password_DB};
}

# - UNIFICADOR

sub unification {       
                     
    my $self = shift;
    if ( @_ ) { $self->{unification} = shift };
    return $self->{unification};
}

# - DIRECTORIO 
# - Donde se pueden colocar archivos que interactúan 
# - con la clase (globals, script)

sub directory {       
                     
    my $self = shift;
    if ( @_ ) { $self->{directory} = shift };
    return $self->{directory};
}

# - REPOSITORIO DE TIPOS DE LA GRAMÁTICA
# - La librería convierte los tipos de DB
# - en objetos 'type' que guarda aquí

# El repositorio 'types' tiene para cada key
# un valor doble: por un lado está el tipo en sí
# ('type'), y por otro un caracterizador del estatus
# del tipo ('expanded'), que establece si el tipo ya
# ha sido expandido o no.

sub types {       
                     
    my $self = shift;
    if ( @_ ) { $self->{types} = shift };
    return $self->{types};
}

# - REPOSITORIO DE ATRIBUTOS DE LA GRAMÁTICA
# - Se convierten los rasgos de DB en tipos
# - attribute que guarda aquí

sub attrs {       
                     
    my $self = shift;
    if ( @_ ) { $self->{attrs} = shift };
    return $self->{attrs};
}

# - REPOSITORIO DE NOMBRES DE LA GRAMÁTICA
# - Se convierten tipos de DB en nombres
# - de tipos que se guardan aquí

sub names {       
                     
    my $self = shift;
    if ( @_ ) { $self->{names} = shift };
    return $self->{names};
}

# - VARIABLES GLOBALES

sub globals {       
                     
    my $self = shift;
    if ( @_ ) { $self->{globals} = shift };
    return $self->{globals};
}

# - Colecciones de tipos clasificados por
# - clases de DB
# - Cada una es un HASH cuyas claves son
# - los nombres de los tipos de tal
# - clase y su valor es 1.

# - Se pueden usar para tomar la lista de
# - reglas o tipos de uno u otro tipo,
# - O para acceder a los tipos de 'types'
# - asegurándonos de que el tipo que pedimos
# - es de una determinada clase 
# - (ver get_grules_id_as_list, etc. y
# - get_grule_by_index, etc.)
 
# - Reglas gramaticales

sub grules {       
                     
    my $self = shift;
    if ( @_ ) { $self->{grules} = shift };
    return $self->{grules};
}

# - Reglas léxicas

sub lrules {       
                     
    my $self = shift;
    if ( @_ ) { $self->{lrules} = shift };
    return $self->{lrules};
}

# - Reglas flexivas

sub irules {       
                     
    my $self = shift;
    if ( @_ ) { $self->{irules} = shift };
    return $self->{irules};
}


# - Axiomas

sub axioms {       
                     
    my $self = shift;
    if ( @_ ) { $self->{axioms} = shift };
    return $self->{axioms};
}


# Unidades léxicas silentes

sub silence_ls {       
                     
    my $self = shift;
    if ( @_ ) { $self->{silence_ls} = shift };
    return $self->{silence_ls};
}


# El repositorio lexicon es especial,
# pq sus elementos no se buscan por el
# nombre del tipo, sino por STEM

# Cada STEM podría tener más de un tipo
# asociado lexicon->{stem}->{type1}
#                         ->{type2}

# (Ver get_lex_units_as_list y
#  get_lex_unit_by_index)

sub lexicon {       
                     
    my $self = shift;
    if ( @_ ) { $self->{lexicon} = shift };
    return $self->{lexicon};
}

# PARSER TDL

sub TDL_Tok {       
                     
    my $self = shift;
    if ( @_ ) { $self->{TDL_Tok} = shift };
    return $self->{TDL_Tok};
}

### MÉTODOS DE ACCESO A LOS REPOSITORIOS

# Devuelve el tipo de la gramática de nombre
# $index, como objeto 'type' guardado en
# $self->types

# El repositorio 'types' tiene para cada key
# un valor doble: por un lado está el tipo en sí
# ('type'), y por otro un caracterizador del estatus
# del tipo ('expanded'), que establece si el tipo ya
# ha sido expandido o no.

sub get_type_by_id {

    my $self = shift;
    my $index = shift;

    if (defined $self->types->{$index} and
	defined $self->types->{$index}->{'type'}) 
    { return $self->types->{$index}->{'type'}; }

#    die "Unfound type $index in grammar.pm";
}

# Devuelve el nombre del tipo de la gramática de id
# $index, como objeto 'name' guardado en
# $self->names

sub get_name_by_id {

    my $self = shift;
    my $index = shift;

    if (defined $self->names->{$index}) 
    { return $self->names->{$index}; }

    die "Unfound name $index in grammar.pm";
}

# Devuelve el atributo del rasgo $index de la gramática
# como objeto 'attribute' guardado en
# $self->attrs


sub get_attr_by_id {

    my $self = shift;
    my $index = shift;

    if (defined $self->attrs->{$index}) 
    { return $self->attrs->{$index}; }

    die "Unfound attribute $index  in grammar.pm";
}


###################################
### MÉTODOS PARA BÚSQUEDA EN DB ###
###################################

####                                         ####
## Listado de todos los rasgos de la gramática ##
####                                         ####

sub get_features_from_DB {

    my $self = shift;
    my @features_id;

    my $sth=$dbh->prepare("SELECT name FROM feature;");
    $sth->execute();

    while (my $feature_id = $sth->fetchrow_array) {

        push @features_id, $feature_id;
    }
    return @features_id;
}

####                               ####
## Devuelven información de un rasgo ##
####                               ####

# declared_in: tipo en el que se declaró
# originalemente un rasgo

sub get_declared_in_from_DB {

    my$self = shift;
    my $attr_id = shift;

    my $sth=$dbh->prepare("SELECT declared_in FROM feature WHERE name='$attr_id';");
    $sth->execute();
    return $sth->fetchrow_array;
}

# value: nombre del tipo que se declaró como
# valor de un rasgo

sub get_value_from_DB {

    my$self = shift;
    my $attr_id = shift;

    my $sth=$dbh->prepare("SELECT value FROM feature WHERE name='$attr_id';");
    $sth->execute();
    return $sth->fetchrow_array;
}

####                        ####
## Listado de todos los tipos ##
####                        ####

sub get_types_from_DB {

    my $self = shift;
    my @types = ();

    my $sth=$dbh->prepare("SELECT name FROM type;");
    $sth->execute();

    while (my $type = $sth->fetchrow_array) {

        push @types, $type;
    }
    return @types;
}

####                                       ####
## Listado de los padres directos de un tipo ##
####                                       ####

# Método básico

sub get_parents_from_DB {

    my $self = shift;
    my $name_id = shift;
    my @parents = ();

    my $sth=$dbh->prepare("SELECT supertype FROM inheritage WHERE subtype = '$name_id';");
    $sth->execute();

    while (my $parent_id = $sth->fetchrow_array) { 

        push @parents, $parent_id;
    }
    return @parents;
}

# Método recursivo para poner en un tipo todos
# sus padres mediatos e inmediatos

# $parents_out es hash para evitar duplicidades (herencia múltiple)

sub get_parents_from_DB_rec {

    my $self = shift;
    my $name_id = shift;

    my @parents_in = $self->get_parents_from_DB($name_id);
    my $parents_out = {}; 

    while (my $parent = shift @parents_in) {

	$parents_out->{$parent} = 1;
	push @parents_in, $self->get_parents_from_DB($parent);
    }
    return keys %{$parents_out};
}

sub get_subtypes_from_DB {

    my $self = shift;
    my $name_id = shift;
    my @subtypes = ();

    my $sth=$dbh->prepare("SELECT subtype FROM inheritage WHERE supertype = '$name_id';");
    $sth->execute();

    while (my $subtype_id = $sth->fetchrow_array) { 

        push @subtypes, $subtype_id;
    }
    return @subtypes;
}


# Listado de los hijos directos de un tipo

sub get_daughters_from_DB {

    my $self = shift;
    my $name_id = shift;
    my @daughters = ();

    my $sth=$dbh->prepare("SELECT subtype FROM inheritage WHERE supertype = '$name_id';");
    $sth->execute();

    while (my $daughter_id = $sth->fetchrow_array) { 

        push @daughters, $daughter_id;
    }
    return @daughters;
}

## Lista los tipos de una determinada clase

sub get_class_types_from_DB {

    my $self = shift;
    my $class = shift;
    my @types = ();

    my $sth=$dbh->prepare("SELECT name FROM type
                           WHERE class='$class';");
    $sth->execute();

    while (my $type = $sth->fetchrow_array) {

        push @types, $type;
    }
    return @types;
}

# stem: devueve el valor de stem de
# una palabra
# Se elimina el identificador de 
# STEM ""

sub get_stem_from_DB {

    my$self = shift;
    my $name = shift;

    my $sth=$dbh->prepare("SELECT stem FROM type WHERE name='$name';");
    $sth->execute();

    my $stem = $sth->fetchrow_array;
    $stem or die "$name is not lexicon or there is a lex unit without stem";
    $stem =~ s/"//g;
    return $stem;
}

######################################
## ACCESO A LOS TIPOS EN MODO REGLA ##
######################################

# Devuelve una madre. Madre es un signo
# desprovisto de sus constituyentes (los
# listados en los rasgos que se definieran
# en globals como USELESS).

sub get_mother {

    my $self = shift;
    my $type = shift;
    my $RE = $self->get_globals('USELESS');

    foreach my $feature_id ($type->get_features_id_as_list) {

	if ($feature_id =~ /^$RE$/) { $type->del_feature_by_id($type->get_feature_by_id($feature_id)); }
    }
    return $type;
}

# Devuelve el LHS

sub get_lhs {

    my $self = shift;
    my $type = shift;

    my $LHS = $self->get_mother($type);

    return $LHS;
}

# Devuelve el primer constituyente de una regla (rhs1)

sub get_rhs1 {

    my $self = shift;
    my $type = shift;

    my $RHS1f = $type->get_feature_by_id($self->get_globals('RHS1'));
    $RHS1f or return 0;
    my $RHS1 = $RHS1f->value;
    return $RHS1;
}

# Devuelve el primer constitutente de una regla (rhs2)

sub get_rhs2 {

    my $self = shift;
    my $type = shift;

    my $RHS2f = $type->get_feature_by_id($self->get_globals('RHS2'));
    $RHS2f or return 0;
    my $RHS2 = $RHS2f->value;
    return $RHS2;
}

### Devuelven la lista de identificadores
### de cada clase: regla gramatical, regla
### léxica, etc.

# Reglas gramaticales

sub get_grules_id_as_list {

    my $self = shift;

    return keys %{$self->grules};

}

# Reglas léxicas

sub get_lrules_id_as_list {

    my $self = shift;

    return keys %{$self->lrules};
}

# Reglas flexivas

sub get_irules_id_as_list {

    my $self = shift;

    return keys %{$self->irules};
}

# Unidades léxicas silentes

sub get_silence_l_as_list {

    my $self = shift;

    return keys %{$self->silence_ls};
}

# Axiomas

sub get_axioms_as_list {

    my $self = shift;

    return keys %{$self->axioms};
}

# Lexicón
# Devuelve la lista de tipos con un determinado
# stem. Es importante para comunicarse con el
# parser, que buscará tipos léxicos en la gramática
# a partir del lema de las formas tokenizadas

sub get_lex_units_as_list {

    my $self = shift;
    my $stem = shift;
    return keys %{$self->lexicon->{$stem}};
}


### Devuelven un tipo de types
### presuponiendo que son de una
### determinada clase. Se comprueba 
### que los sean

# Regla gramatical

sub get_grule_by_index {

    my $self = shift;
    my $index = shift;

    defined $self->grules->{$index} or
    die "$index is not grule";

    return $self->get_type_by_id($index);
}

# Regla léxica


sub get_lrule_by_index {

    my $self = shift;
    my $index = shift;

    defined $self->lrules->{$index} or
    die "$index is not lrule";

    return $self->get_type_by_id($index);
}

# Regla flexiva

sub get_irule_by_index {

    my $self = shift;
    my $index = shift;

    defined $self->irules->{$index} or
    die "$index is not irule";

    return $self->get_type_by_id($index);
}

# Axioma

sub get_axiom_by_index {

    my $self = shift;
    my $index = shift;

    defined $self->axioms->{$index} or
    die "$index is not axiom";

    return $self->get_type_by_id($index);
}


# Unidad léxica silente

sub get_silence_l_by_index {

    my $self = shift;
    my $index = shift;

    defined $self->silence_ls->{$index} or
    die "$index is not silence_l";

    return $self->get_type_by_id($index);
}

# Unidad léxica
# A partir de un STEM, get_lex_units_as_list
# devuelve la lista de tipos con ese STEM
# Con esa información (STEM y tipo), se puede
# buscar en types cada tipo, asegurando
# que es un tipo léxico con tal STEM

sub get_lex_unit_by_index {

    my $self = shift;
    my $stem = shift;
    my $index = shift;

    (defined $self->lexicon->{$stem} and
     defined $self->lexicon->{$stem}->{$index}) or
    die "$index is not lex_unit";

    return $self->get_type_by_id($index);
}

####################################
### CARGAR LA GRAMÁTICA DESDE DB ###
####################################

### - MÉTODO PRINCIPAL: CARGA LA GRAMÁTICA DESDE DB 

sub load_grammar {

    my $self = shift;

    $self->load_globals; # Se cargan las variables generales.
    $self->open_DB; # Se abre la BD con la que se va a operar

    print STDERR "Creando nombres\r";
    $self->create_names; # Crea el respositorio de nombres de tipos (objetos 'name')
    print STDERR "Nombres creados\n";
    print STDERR "Creando rasgos\r";
    $self->create_attrs; # Crea el respositorio de atributos (objetos 'attribute')
    print STDERR "Rasgos creados\n";
    $self->create_types; # Crea el respositorio de tipos de la gramática (objetos 'type')
    print STDERR "Creando tipos\r";
    print STDERR "Tipos creados\n";
    print STDERR "Expandiendo tipos\r";
    $self->expand_grammar; # Espande los tipos
    print STDERR "Tipos expandidos                                  \n";
    $self->create_api;
    print STDERR "Gramática cargada\n";

    return 1; # Importante, da señal de que se cargó la gramática 
}

### - CREACIÓN DEL REPOSITORIO DE NOMBRES

### Solo se crea un objeto por cada nombre de tipo en 
### DB. Este se carga con información sobre cuáles son
### sus padres y si tiene subtipos en común con algún
### otro tipo. Esta es  información relevante para 
### la unificación

### create_root_name crea el nombre del tipo raíz de la 
### jerarquía, a partir de la información de globals

sub create_names {

    my $self = shift;

    $self->create_root_name; 

    foreach my $name_id ($self->get_types_from_DB) {

	$self->set_name($self->create_name($name_id));
    }
}

# Crea el nombre del tipo raíz de la jerarquía, 
# a partir de la información de globals

sub create_root_name {

    my $self = shift;
 
    my $root_id = $self->get_globals('TOP');
    my $root = $self->create_name($root_id);
    $self->set_name($root);
}

# Se crea cada nombre como objeto 'name'

sub create_name {

    my $self = shift;
    my $name_id = shift;

    my $name = xname->new;
    $name->id($name_id);                                    # Se le pone el nombre en id
    $self->add_parents_to_name_from_DB($name); # Se le añaden los padres directos
    $self->add_common_sub_to_name($name);          # Se buscan subtipos directos comunes a otros tipos

    return $name;
}


# Se añade a un nombre la información 
# sobre sus padres en DB

sub add_parents_to_name_from_DB {

    my $self = shift;
    my $name = shift;
    my $id = $name->id;

    foreach my $parent ($self->get_parents_from_DB_rec($id)) {

	$name->add_parent($parent);
    }
}

# Por cada subtipo S de N, se busca si S tiene otros 
# supertipos N' inmediatos a parte de N. 
# Esta información es útil para la unificación, pues
# N y N' unifican si tienen un subtipo inmediato S
# en común

sub add_common_sub_to_name {

    my $self = shift;
    my $name = shift;
    my $myself_id = $name->id;

    foreach my $daughter_id ($self->get_daughters_from_DB($myself_id)) {

	foreach my $brother_id ($self->get_parents_from_DB($daughter_id)) {

	    if ($brother_id eq $myself_id) { next; } 
	    $name->add_common_sub($brother_id,$daughter_id);
	}
    }
}

# Se comprueba si un identificador de nombre es
# de tipo string

sub is_string {

    my $self = shift;
    my $name_id = shift;
    my $RE = $self->get_globals('STRING_RE');
    if ($name_id =~ /$RE/) { return 1; }
    return 0;
}

# Se comprueba si un identificador de nombre es
# de tipo string

sub is_relation {

    my $self = shift;
    my $name_id = shift;
    my $RE = $self->get_globals('RELATION_RE');
    if ($name_id =~ /$RE/) { return 1; }
    return 0;
}

# Se añade a un nombre la información 
# sobre sus padres en DB

# Coloca el nombre en el repositorio 'names'.

sub set_name {

    my $self = shift;
    my $name = shift;
    $self->names->{$name->id} = $name;
}

# - CREACIÓN DEL REPOSITORIO DE ATRIBUTOS

# Se crea un atributo por cada rasgo de DB

sub create_attrs {

    my $self = shift;

    foreach my $attr_id ($self->get_features_from_DB) {

	$self->set_attr($self->create_attr($attr_id));
    }
}

# Se crea un atributo en concreto

sub create_attr {

    my $self = shift;
    my $attr_id = shift;

    my $attr = xattribute->new();
    $attr->id($attr_id);
    $self->add_info_to_attr($attr);

    return $attr;
}

# Se añade  información al atributo: 
# en qué tipo se declaró un rasgo, y cuál fue 
# el valor que se le adscribió en su declaración

sub add_info_to_attr {

    my $self = shift;
    my $attr = shift;
    my $attr_id = $attr->id;

    my $declared_in = $self->get_declared_in_from_DB($attr_id);
    my $value = $self->get_value_from_DB($attr_id);

    $declared_in or die "Feature $attr_id without declared_in"; 
    $value or die "Feature $attr_id without value"; 

    $attr->declared_in($declared_in);
    $attr->value($value);
}

# - Coloca attr en el repositorio attrs

sub set_attr {

    my $self = shift;
    my $attr = shift;
    $self->attrs->{$attr->id} = $attr;
}

# - CREACIÓN DEL REPOSITORIO DE TIPOS


# create_root_type crea el tipo raíz de la jerarquía, 
# a partir de la información de globals

sub create_types {

    my $self = shift;

    $self->create_root_type;

    foreach my $name ($self->get_types_from_DB) {

	$self->set_type($self->create_type_from_DB($name));
    }
}

# Crea el tipo raíz de la jerarquía, 
# a partir de la información de globals

sub create_root_type {

    my $self = shift;
 
    my $root_id = $self->get_globals('TOP');
    my $root = $self->create_type_from_DB($root_id);
    $self->set_type($root);
}

# Coloca type en el repositorio types. Este repositorio
# tiene más estructura de lo esperado. Esta complicación
# es necesaria para llevar cuenta de qué tipos están o no 
# expandidos (junto a 'type' hay 'expanded')

sub set_type {

    my $self = shift;
    my $type = shift;
    my $name_id = $type->name->id;
    $self->types->{$name_id}->{'type'} = $type;
}

# Se crea un objeto type y se le añaden los
# rasgos de los path de DB

sub create_type_from_DB {

    my $self = shift;
    my $name_id = shift;

    my $type = xtype->new();
    $self->start_seen_sharings; # Pone a cero el registro de sharings
    $type->name($self->get_name_by_id($name_id));
    $self->add_feature_structure($type);
    return $type;
}

# Añade a un tipo los paths como estructura de rasgos

sub add_feature_structure {

    my $self = shift;
    my $type = shift;

    my $paths = $self->get_paths_from_DB($type->name->id);
    $self->add_feature_structure_aux($type,$paths);
}

# Crea un HASH 'paths' que recoge toda la información
# de DB para el tipo cuyo nombre se pasa 

sub get_paths_from_DB {

    my $self = shift;
    my $name_id = shift;
    my $paths = {};

    my $sth = $dbh->prepare("SELECT name, sharing, path FROM  path
                             WHERE type='$name_id';");
    $sth->execute;

    while ( my ($value,$sharing,$path) = $sth->fetchrow_array ) {

	$paths->{$path}->{'sharing'} = $sharing;
	$paths->{$path}->{'value'} = $value;
    }

    return $paths;
}

# Añade a un tipo básico la estructura
# de rasgos codificada en un HASH 'paths'
# Se le añade cada path con add_path

sub add_feature_structure_aux {

    my $self = shift;
    my $type = shift;
    my $paths = shift;

    foreach my $path ($self->get_paths_as_list($paths)) {

	my $sharing = $paths->{$path}->{'sharing'};
	my $value = $paths->{$path}->{'value'};

	$self->add_path($type,$path,$sharing,$value);
    }
}

# Se añade un path a un tipo
# Se añaden los rasgos en anidación (add_features_to_type_from_DB)
# Se añaden el nombre y el sharing si los hubiera al rasgo más
# anidado (add_value_to_type_from_DB)

sub add_path {

    my $self = shift;
    my $type = shift;
    my $path = shift;
    my $sharing = shift;
    my $value = shift;

    $self->add_features_to_type_from_DB($path,$type);
    $self->add_value_to_type_from_DB($path,$sharing,$value,$type);
}

# Método recursivo para anidar un rasgo dentro de otro
# A partir de un path de tipo A#B#C...

sub add_features_to_type_from_DB {

    my $self = shift;
    my $path = shift;
    my $root_type = shift;
 
    my $current_type = $root_type;

    foreach my $feature_id ($self->split_path($path)){

	$current_type = $self->add_feature_to_type($feature_id,$current_type);
    }
    return $current_type;
}

# Añade un rasgo a un tipo y devuelve el tipo anidado en
# ese rasgo. Si ese rasgo tuviese por valor un sharing,
# devuelve el tipo que es valor de ese sharing. Para ello,
# se usa get_type.

sub add_feature_to_type {

    my $self = shift;
    my $feature_id = shift;
    my $type = shift;

    $type->get_feature_by_id($feature_id) or
    $type->add_feature($self->create_new_feature($feature_id)); 
    $self->add_name_aux($type,$self->get_attr_by_id($feature_id)->declared_in);

    return $type->get_feature_by_id($feature_id)->value; 
}

# Crea un rasgo nuevo a partir del 
# identificador de su atributo

# Es importante que, al tipo anidado que se crea
# aquí, se le asigna el nombre que se declaró en 
# la gramática como valor del rasgo del que es
# valor: $attribute->value.

# Procesos posteriores podrán especificar este valor:
# add_value_to_type_from_DB. Pero es importante poner 
# aquí este primer valor para asegurar que al final se 
# opta por el nombre más específico posible 

sub create_new_feature {

    my $self = shift;
    my $attr_id = shift;

    my $feature = xfeature->new();
    my $type = $feature->value;
    my $attribute = $self->get_attr_by_id($attr_id);
    my $name = $self->get_name_by_id($attribute->value);

    $type->name($name);
    $feature->attribute($attribute);

    return $feature;
}

# Crea la lista de rasgos a partir de un path A#B#C...

sub split_path {

    my $self = shift;
    my $path = shift;

    return split "#", $path;
}

# Crea una lista de paths a partir de un HASH de paths

sub get_paths_as_list {

    my $self = shift;
    my $paths = shift;

    return sort keys %{$paths}; 
}

# Se añade a un tipo el nombre y el sharing en un rasgo anidado 
# que determina 'path'. La especificación del nombre debe hacer
# frente a cierta complejidad que gestiona add_name

# El sharing, en caso de aparecer, se añade al rasgo más anidado
# del path. Se debe gestionar que la aparición de un sharing pide
# que todos los valores de rasgos con ese sharing sean el mismo.
# Por tanto, también requiere un procesamiento que gestiona
# add_sharing;

sub add_value_to_type_from_DB {

    my $self = shift;
    my $path = shift;
    my $sharing_id = shift;
    my $name_id = shift;
    my $type = shift;

    my $nested_feat = $type->get_feature_by_id($path);
    $sharing_id and $self->add_sharing($nested_feat,$sharing_id);
    $name_id and $self->add_name($nested_feat,$name_id);
}

# La especificación de un nombre debe atender 
# a estas cuestiones:

# Al tipo al que se le pone el nombre ya se le
# puso uno antes, al declararse como valor de un
# rasgo de la estructura (create_new_feature).
# Además, la existencia de sharings hace posible
# que ese tipo ya tuviese un nombre declarado
# explícitamente en otro path

# Por tanto, hay que cotejar el nombre que se propone
# aquí con el que ya se pudo proponer. Hay que elegir 
# el más específico. Esto se soluciona como unificación
# de nombres: unify_names

# Si el id que se pasa a la función unifica con la
# expresión regular que en globals se proporcionó
# como propio de string o relation, el nombre del
# tipo será string o relation

sub add_name {

    my $self = shift;
    my $feature = shift;
    my $new_name_id = shift;
    my $type = $feature->value;

    $self->is_relation($new_name_id) and
	return $self->add_name_string($type);
    
    $self->is_string($new_name_id) and
	return $self->add_name_string($type);

    $self->add_name_aux($type,$new_name_id);
}

sub add_name_aux {

    my $self = shift;
    my $old_type = shift;
    my $new_name_id = shift;
    my $new_type = $self->new_type($new_name_id);

    $self->unification->unify_names($new_type,$old_type) or
    die "Incompatible names ".$new_type->name->id." and ".$old_type->name->id; 
}

sub add_name_relation {

    my $self = shift;
    my $type = shift;
    my $relation_id = $self->get_globals('RELATION');
    my $relation_name = $self->get_name_by_id($relation_id);
    $type->name($relation_name);
    return 1;
}

sub add_name_string {

    my $self = shift;
    my $type = shift;
    my $string_id = $self->get_globals('STRING');
    my $string_name = $self->get_name_by_id($string_id);
    $type->name($string_name);
    return 1;
}

# Funciones para gestionar los sharings en la creación de
# tipos desde DB. Todas las apariciones de 1 sharing requie-
# ren que el tipo de todos los rasgos con ese sharing sea el
# mismo objeto. Por tanto, si se identifica un sharing por
# primera vez, se guarda en seen_sharings para volver a usar-
# las siguientes veces. Si se identifica por 2ª, 3ª, etc. vez,
# se pone como valor del rasgo en cuestión el tipo ya guardado
# en seen_sharings 

sub add_sharing {

    my $self = shift;
    my $feature = shift;
    my $sharing_id = shift;
    my $sharing = $self->in_seen_sharings($sharing_id);

    if ($sharing) { 

	$self->add_old_sharing($feature,$sharing); 

    } else {

	$self->add_new_sharing($feature,$sharing_id)
    }
}

# Cuando se identifica un sharing en DB por segunda vez,
# no se crea para el rasgo en cuestión un nuevo tipo, 
# sino que se le pone el ya visto. Se le pone el sharing
# ya visto y el tipo guardado en ese sharing, que (según
# se crea todo rasgo) es el mismo tipo que es valor del
# rasgo que tiene el sharing.

# ¿No hace falta usar unificación? Esto es así si estamos 
# seguros de que, en caso de haber sharing en un rasgo,
# el sharing se crea siempre antes que su tipo. Si esto
# es así, al tipo de la anterior ocurrencia del sharing
# se le podrá ir añadiendo estructura luego (la unificación
# de nombres se hace en cualquier caso en add_name, y el 
# añadido de rasgos es consustancial al proceso de creación
# de tipos desde DB).

# ¿Estamos seguros de que lo primer que se crea es el sharing?
# Por cómo está construido add_value_to_type_from_DB, para el
# mismo path, se crea siempre primero el sharing. Además, el path 1
# del sharing va a ser siempre anterior a cualquier path 2 que re-
# presente una posición anidada en 1, porque los paths se usan 
# ordenados alfabéticamente: get_paths_as_list. 

# Pero hay un supuesto que pide unificación: un sharing #a podría
# no ser lo primero que se crea en un tipo con ese sharing si #a
# está anidado en #b, y #b ha recibido, dada otra aparición previa
# de #b, la estructura donde aparecerá luego #a.

# simple_unify hace una gestión sencilla de sharings que se adapta
# a las necesidades de esta situación: no va a ser necesario identificar
# sharings con distinto nombre. Para ello, se le pasa el repositorio de
# sharings

# Simple_unify dispara un proceso más sencillo que unify, pq presupone
# que no es necesario identificar sharings distintos: si hay un sharing
# #a en specif, su tipo solo se podrá aglutinar con sharings sin nombre; 
# nuca con un sharing #b de target. Esto es lo necesario aquí, donde 
# los id de sharings de DB son siempre coherentes 

sub add_old_sharing {

    my $self = shift;
    my $feature = shift;
    my $sharing = shift;

    $self->unification->simple_unify($feature->value,$sharing->type);

    $feature->sharing($sharing);
    $sharing->add_feature($feature);
    $feature->value($sharing->type);
}

# El sharing se crea en el rasgo automáticamente
# Aquí solo se le pone el identificador que propo-
# ne DB, y se guarda en seen_sharings. La clase feature
# añade directamente el rasgo y el tipo

sub add_new_sharing {

    my $self = shift;
    my $feature = shift;
    my $sharing_id = shift;
    my $sharing = $feature->sharing;
    $sharing->id($sharing_id);
    $self->add_to_seen_sharings($sharing);
}

## Gestión de $seen_sharing

sub start_seen_sharings {

    my $self = shift;

    $seen_sharings = {};
}

sub in_seen_sharings {

    my $self =  shift;
    my $sharing_id = shift;
    (defined $seen_sharings->{$sharing_id}) and
     return $seen_sharings->{$sharing_id};
     return 0;
} 

sub add_to_seen_sharings {

    my $self = shift;
    my $sharing = shift;
    my $sharing_id = $sharing->id;
    $seen_sharings->{$sharing_id} = $sharing;
}
################################# 
##### EXPANDIR LA GRAMÁTICA #####
#################################

# La expansión total de una gramática merecería
# dos tipos de unificación:

# a) Unificación de cada tipo con sus supertipos
#    mediatos e inmediatos
# b) Unificación de cada tipo 'n' anidado en un tipo 'N' 
#    con la estructura declarada y expandida para 'n'

# El segundo proceso es muy largo, y necesita una gestión
# complicada de la relación entre los sharings de 'n' y los
# de cualquier ámbito mayor a 'n' ('N', entre ellos). Además,
# Da lugar a estructuras muy grandes.

# En esta librería solo se expande en cuanto al proceso a).
# Las restricciones que han de provenir del proceso b) se su-
# plen haciendo uso de la librería de unificación (unification.pm).
# En la unificación, cualquier tipo declarado como de tipo 'n'
# debe cotejar su información con la del tipo 'n' de la gramática
# (tipo este proporcionado por esta librería) 

# Un tipo 'N' unifica con cada uno de sus padres inmediatos
# 'P'. Pero estos padres, antes de unificarlos con 'N' han de
# ser expandidos. Esto crea un proceso recursivo en el que
# la expansión de un tipo dispara previamente la de su supertipo
# hasta llegar al axioma de la gramática. Se determina el estatus
# expandido o no de un tipo en el repositorio 'types'. Los tipos
# expantidos se marcan como ->{'expanded'} = 1. Cuando se requiere
# a un supertipo, se comprueba si ya está expandido o no. Solo si
# no lo está, se expande.

# Método general: por cada tipo de DB se lanza
# la expansión con expand_type.

sub expand_grammar {

    my $self = shift;

    $self->expand_with_parents;
    $self->expand_with_patterns;
}

sub expand_with_parents {

    my $self = shift;

    foreach my $name_id ($self->get_types_from_DB) {

	$self->expand_type($name_id);
    }
}

sub expand_with_patterns {

    my $self = shift;

    foreach my $class ('grule','lrule','irule','axiom','lexicon', 'silence_l') {

	$self->expand_with_patterns_aux($class);
    }
}

sub expand_with_patterns_aux {

    my $self = shift;
    my $class = shift;

    foreach my $name_id ($self->get_class_types_from_DB($class)) {

	print STDERR "Aplicando patrones al tipo ".$name_id."                  \r";
	my $type = $self->get_type_by_id($name_id);
	$self->unification->unify_with_patterns_rec($type);
    }
}

# Método central de expansión de un tipo. Si ya figura como
# expandido en 'types' (->{'expanded'} = 1), se devuelve
# sin cambiarlo; si no, se expande con expand_type_aux. 

sub expand_type {

    my $self = shift;
    my $name_id = shift;
    my $type = $self->get_type_by_id($name_id);

    $self->already_expanded($name_id) and return $type; 
    return $self->expand_type_aux($type);
}

# Método de expansión real de un tipo: cada padre, previamente
# expandido, se unifica sobre el tipo. 

# Además, se añaden los padres del nombre del padre al nombre
# del hijo (add_parents_to_name_from_name). Téngase en cuenta
# que el proceso recursivo de expansión ha aglutinado en el
# nombre del padre todos los padres mediatos e inmediantos de
# este. Por tanto, este método dará al hijo la información de
# todos sus padres mediatos o inmediatos. Esto es muy útil
# para la unificación.

# Una vez expandido un tipo, se marca en 'types' como tal
# (expanded_yes)

sub expand_type_aux {

    my $self = shift;
    my $type = shift;
    print STDERR "Expandiendo tipo ".$type->name->id."                       \r";
    foreach my $parent_id ($type->name->get_parents_id_as_list) {
	
	my $parent = $self->expand_type($parent_id);
	$self->unification->unify($parent,$type);
    }

    $self->expanded_yes($type->name->id);
    return $type;
}

# Se añaden los padres de un tipo al otro
# Útil para que un name gane los padres de
# sus supertipos no inmediatos

sub add_parents_to_name_from_name {

    my $self = shift;
    my $source = shift;
    my $target = shift;

    foreach my $parent ($source->get_parents_id_as_list) {

	$target->add_parent($parent);
    }
}

# Valora si un tipo ya ha sido expandido (información
# guardada en types->{tipo}->{expanded}).

sub already_expanded {

    my $self = shift;
    my $name_id = shift;

    if (defined $self->types->{$name_id} and
	defined $self->types->{$name_id}->{'expanded'} and
	$self->types->{$name_id}->{'expanded'}) { return 1; }
    return 0;
}

# Evalúa a un tipo de types como expandido

sub expanded_yes {

    my $self = shift;
    my $name_id = shift;

    $self->types->{$name_id}->{'expanded'} = 1;
}

#####################################
### SE CREA LA API PARA EL PARSER ###
#####################################

# Último método del método central 
# load_grammar. Crea los repositorios
# necesarios para que el parser busque
# en la gramática la información que
# va necesitando.

sub create_api {

    my $self = shift;

    $self->create_grules;
    $self->create_lrules;
    $self->create_irules;
    $self->create_axioms;
    $self->create_silence_ls;
    $self->create_lexicon;
}

# Crea el repositorio de reglas gramaticales

sub create_grules {

    my $self = shift;
    
    $self->grules({});

    foreach my $grule ($self->get_class_types_from_DB('grule')) {

	$self->grules->{$grule} = 1;
    }
}

# Crea el repositorio de reglas léxicas

sub create_lrules {

    my $self = shift;
    
    $self->lrules({});

    foreach my $lrule ($self->get_class_types_from_DB('lrule')) {

	$self->lrules->{$lrule} = 1;
    }
}

# Crea el repositorio de reglas flexivas

sub create_irules {

    my $self = shift;
    
    $self->irules({});

    foreach my $irule ($self->get_class_types_from_DB('irule')) {

	$self->irules->{$irule} = 1;
    }
}

# Crea el repositorio de axiomas

sub create_axioms {

    my $self = shift;
    
    $self->axioms({});

    foreach my $axiom ($self->get_class_types_from_DB('axiom')) {

	$self->axioms->{$axiom} = 1;
    }
}

# Crea el repositorio de unidades léxicas silentes

sub create_silence_ls {

    my $self = shift;
    
    $self->silence_ls({});

    foreach my $silence_l ($self->get_class_types_from_DB('silence_l')) {

	$self->silence_ls->{$silence_l} = 1;
    }
}

# Crea el repositorio de instancias léxicas
# Las instancias léxicas no se buscan desde el parser
# por nombre de tipo (este no lo conoce el parser). El
# parser busca unidades léxicas por el lema que asigna 
# el tokenizer a las formas flexionadas

# Por eso lexicon tiene la estructura stem->{type1}
#                                         ->{type2}

sub create_lexicon {

    my $self = shift;
    
    $self->lexicon({});

    foreach my $lex_unit ($self->get_class_types_from_DB('lexicon')) {

	my $stem = $self->get_stem_from_DB($lex_unit);
	$self->lexicon->{$stem}->{$lex_unit} = 1;
    }
}

# Crea un nuevo objeto type

sub new_type {

    my $self = shift;
    my $name_id = shift;

    my $type = xtype->new();
    unless ($name_id) { $name_id = $self->get_globals('TOP'); }
    my $name = $self->get_name_by_id($name_id);
    $type->name($name);

    return $type;
}

################################################################
################# CREACIÓN DE LA BASE DE DATOS #################
################################################################

sub load_tdl_grammar {

    my $self = shift;

    print STDERR "Cargando globales\n";
    $self->load_globals;
    print STDERR "Globales cargados\n";
    print STDERR "Creando base de datos\n";
    $self->create_DB;
    print STDERR "Base de datos creada\n";
    print STDERR "Analizando los archivos TDL\n";
    $self->create_grammar_from_tdl;
    print STDERR "Archivos TDL analizados\n";
    print STDERR "Cargando tipos en DB\n";
    $self->load_grammar_in_DB;
    print STDERR "Tipos cargados en DB             \n";
}

sub create_grammar_from_tdl {

    my $self = shift;
    
    open SCRIPT, $self->get_script_file || die $!;

    foreach (<SCRIPT>) {

	my ($class,$file);
	if (/^\s*([^\t]+)\t([^\s]+)\s*/) { 
	    ($class,$file) = ($1,$2);
	    print STDERR "Tokenizando $file\n";
	    $self->TDL_Tok->class($class);
	    $self->TDL_Tok->tokenize_file($file);
	}
    }
    close SCRIPT;
}

sub load_grammar_in_DB {

    my $self = shift;

    $self->load_types_in_DB;
    $self->create_glbtypes_in_grammar;
    $self->add_grammar_features_to_db;
}

sub load_types_in_DB {

    my $self = shift;

    foreach my $type ($self->TDL_Tok->get_result_as_list) {

	print STDERR "Cargando en DB tipo ".$type->name->id."                      \r";
	$self->load_type_in_DB($type);
	$self->load_instance_in_DB($type); # Depende del anterior. Siempre tras él
	$self->load_heritage_in_DB($type);
	$self->load_paths_in_DB($type);
    }
}

sub create_DB {

    my $self = shift;
    my $name = $self->name;
    my $user_DB = $self->user_DB;
    my $password_DB = $self->password_DB;

    unless ($name) { die "No se ha pasado el nombre de la gramática"; }
    unless ($user_DB) { die "No se ha pasado el nombre de usuario de la base de datos"; }
    unless ($password_DB) { die "No se ha pasado contraseña para la base de datos"; }

    $dbh = DBI->connect("dbi:mysql:","$user_DB","$password_DB") ||
	die "Error opening database: $DBI::errstr\n";

    $dbh->do("CREATE DATABASE $name;");
    $dbh->do("USE $name;");

    $self->create_tables_in_DB;
}


sub create_tables_in_DB {

    my $self = shift;

    $/ = ";";

    open SSGSQL, $self->get_sql_file or die;

    while (<SSGSQL>) {

	$dbh->do("$_");
    }
    close SSGSQL;
    $/ = "\n";
}

sub load_type_in_DB {

    my $self = shift;
    my $type = shift;
    $type->add and return 1;
    ($type->class eq 'lexicon') and return 1;

    my $name = $type->name->id;
    my $class = $type->class;

    $dbh->do
        ("INSERT INTO type (name  , class)
           VALUES             ('$name', '$class')")
        || die "Couldn't insert record : $DBI::errstr";
}

sub load_instance_in_DB {

    my $self = shift;
    my $type = shift;
    $type->add and return 1;
    ($type->class eq 'lexicon') or return 1;

    my $name = $type->name->id;
    my $stem = $type->get_feature_by_id($self->get_globals('STEM'))->value->name->id;

    $dbh->do
        ("INSERT INTO type (name  , class, stem)
           VALUES             ('$name', 'lexicon', '$stem')")
        || die "Couldn't insert record : $DBI::errstr";
}

sub load_heritage_in_DB {

    my $self = shift;
    my $type = shift;
    my $name_id = $type->name->id;

    foreach my $parent_id ($type->name->get_parents_id_as_list) {

        $self->load_heritage_rel_in_DB($name_id,$parent_id);
    }
}

sub load_heritage_rel_in_DB {

    my $self = shift;
    my $name = shift;
    my $parent = shift;

    $dbh->do
        ("INSERT INTO inheritage (subtype  ,  supertype)
              VALUES             ('$name', '$parent')")
        || die "Couldn't insert record : $DBI::errstr";
}


sub del_heritage_rel_in_DB {

    my $self = shift;
    my $name_id = shift;
    my $parent_id = shift;

    $dbh->do
	("DELETE FROM inheritage WHERE
            subtype='$name_id' and supertype='$parent_id';")
	|| die "Couldn't insert record : $DBI::errstr";
}


sub load_paths_in_DB {

    my $self = shift;
    my $type = shift;
    my $root = shift;
    my $path = shift;

    unless ($root) { $root = $type->name->id; }

    foreach my $feature_id ($type->get_features_id_as_list) {

	my $nested_path = $self->update_path($path,$feature_id);
	my $nested_feat = $type->get_feature_by_id($feature_id);
	my $nested_type = $nested_feat->value;

	($nested_type->name or $nested_feat->sharing->id) and
	$self->load_path_in_DB($nested_type,$root,$nested_path,$nested_feat);
	$self->load_paths_in_DB($nested_type,$root,$nested_path);
    }
}

sub load_path_in_DB {

    my $self = shift;
    my $type = shift;
    my $root = shift;
    my $path = shift;
    my $feature = shift;

    my ($name_id,$sharing_id) = ('','');
    if ($type->name) { $name_id .= $type->name->id; }
    if ($feature->sharing->id) { $sharing_id .= $feature->sharing->id; }

    $dbh->do
        ("INSERT INTO path (   type,    path,    name,    sharing )
          VALUES           ( '$root', '$path', '$name_id', '$sharing_id' )")
        || die "Couldn't insert record : $DBI::errstr";
}

sub update_path {

    my $self = shift;
    my $path = shift;
    my $attribute = shift;

    if ($path) { 
        
        $path .= "#$attribute"; 

    } else { 

        $path = "$attribute";
    }
    return $path;
}

###############################################
## CREAR GLBTYPES #############################
###############################################

# Cra un nombre nuevo de glbtype a partir de la variable $glbtype.

sub create_glbtype_name {

    my $self = shift;
    my $name = '*glbtype' . $glbtype++ . '*';

    return $name;
}


# Actualiza las relaciones de herencia para evitar 
# las situaciones incorrectas en que 2 o más tipos
# tienen más de un subtipo en común.

# Se lanza para cada tipo de la gramática desde arriba 
# hasta abajo el método create_glbtypes.

sub create_glbtypes_in_grammar {

    my $self = shift;

    my $methods = {};
    $methods->{create_glbtypes} = 1;
    $self->cover_grammar_up_bottom($self->get_globals('TOP'), $methods);
}

sub create_glbtypes {

    my $self = shift;
    my $type = shift;

    print STDERR "Creando glbtypes en $type                        \r";

    my $sth1=$dbh->prepare("select distinct b.supertype from inheritage a, inheritage b
                                      where a.supertype='$type' and b.supertype!='$type' 
                                            and a.subtype=b.subtype;");
    $sth1->execute();

    while (my $sup_b = $sth1->fetchrow_array) {

	$self->create_glbtypes_aux($type,$sup_b);
    }
}


sub create_glbtypes_aux {

    my $self = shift;
    my $sup_a = shift;
    my $sup_b = shift;

    my $glbtypes = $self->create_glb_hash;
    $self->add_glb_sup_to_hash($glbtypes,$sup_a);
    $self->add_glb_sup_to_hash($glbtypes,$sup_b);

    my $sth2=$dbh->prepare("select distinct name from type where
                                  name in (select subtype from inheritage where supertype='$sup_a') and
                                  name in (select subtype from inheritage where supertype='$sup_b');");
    $sth2->execute();

    while (my $sub_x = $sth2->fetchrow_array) {

	$self->add_glb_sub_to_hash($glbtypes,$sub_x);
    }

    $self->glb_situation($glbtypes) and
    $self->update_db_with_glbtypes($glbtypes);
}


sub update_db_with_glbtypes {

    my $self = shift;
    my $glbtypes = shift;
    my $glbtype_id = $self->create_glbtype_name;

    my $glbtype = xtype->new();
    $glbtype->class('type');
    my $name = xname->new();
    $name->id($glbtype_id);
    $glbtype->name($name);
    $self->load_type_in_DB($glbtype);

    foreach my $supertype_id ($self->get_glb_sup_as_list($glbtypes)) {

	$self->load_heritage_rel_in_DB($glbtype_id,$supertype_id);

	foreach my $subtype_id ($self->get_glb_sub_as_list($glbtypes)) {

	    $self->del_heritage_rel_in_DB($subtype_id,$supertype_id);
	    $self->load_heritage_rel_in_DB($subtype_id,$glbtype_id);
	}
    }
}

sub create_glb_hash {

    my $self = shift;
    my $hash = {};
    $hash->{'***COUNTER***'} = 0;
    return $hash;
}

sub add_glb_sup_to_hash {

    my $self = shift;
    my $hash = shift;
    my $sup = shift;

    $hash->{'supertypes'}->{$sup} = 1;
}

sub add_glb_sub_to_hash {

    my $self = shift;
    my $hash = shift;
    my $sub_x = shift;

    $hash->{'subtypes'}->{$sub_x} = 1;
    $hash->{'***COUNTER***'}++;
}

sub glb_situation {

    my $self = shift;
    my $hash = shift;

    if (defined $hash->{'***COUNTER***'} and
	$hash->{'***COUNTER***'} > 1) { return 1; }
    return 0;
}

sub get_glb_sup_as_list {

    my $self = shift;
    my $hash = shift;

    return keys %{$hash->{'supertypes'}}
}

sub get_glb_sub_as_list {

    my $self = shift;
    my $hash = shift;

    return keys %{$hash->{'subtypes'}}
}

################################
### AÑADIR RASGOS A LA GRAMÁTICA
################################

# De nuevo se recorre la gramática de arriba a abajo
# aplicando a cada tipo add_features_to_db

sub add_grammar_features_to_db {

    my $self = shift;
    my $methods = {};
    $methods->{add_features_to_db} = 1;
    $self->cover_grammar_up_bottom($self->get_globals('TOP'), $methods);
}

# Toma un tipo, mira sus rasgos inmediatos, comprueba
# si cada uno ya existe en DB. Si no, lo registra

sub add_features_to_db {

    my $self = shift;
    my $declared_in = shift;
    my $features = $self->get_simple_feat_from_DB($declared_in); # Se toman los paths de DB y se seleccionan
                                                                 # los que no tienen anidación y tienen valor
    foreach my $feature ($self->get_paths_as_list($features)) {

	my $value = $features->{$feature}->{'value'};
	$self->add_features_to_db_aux($declared_in,$feature,$value);
    }                                                 
}

sub add_features_to_db_aux {

    my $self = shift;
    my $declared_in = shift;
    my $feature = shift;
    my $value = shift;

    my $old_declared_in = $self->get_declared_in_from_DB($feature);

    if ($old_declared_in) {

	$self->is_subtype($old_declared_in,$declared_in)           and 
	$self->update_feature_in_db($declared_in,$feature,$value);

    } else {

	$self->add_feature_in_db($declared_in,$feature,$value);
    }
}

# Añade un rasgo a DB

sub add_feature_in_db {

    my $self = shift;
    my $declared_in = shift;
    my $feature = shift;
    my $value = shift;

    print STDERR "Insertando rasgo $feature de $declared_in                                         \r";

    $dbh->do
	("INSERT INTO feature (name, declared_in, value)
              VALUES          ('$feature', '$declared_in', '$value')")
	|| die "Couldn't insert record : $DBI::errstr";
}

# Cambia los valores de value y declared_in en una
# tabla feature


sub update_feature_in_db {

    my $self = shift;
    my $declared_in = shift;
    my $feature = shift;
    my $value = shift;

    print STDERR "Insertando rasgo $feature de $declared_in                                         \r";

    $dbh->do
	("UPDATE feature SET declared_in='$declared_in', value='$value'
              WHERE name='$feature';")
	|| die "Couldn't insert record : $DBI::errstr";
}


#### MÉTODOS AUXILIARES PARA AÑADIR RASGOS

# Crea el hash de paths y le quita los que
# sean paths anidados o no tengan valor
# De este modo, se consiguen solo los
# rasgos que pudieran ser declarados en ese
# tipo 

sub get_simple_feat_from_DB {

    my $self = shift;
    my $type_id = shift;

    my $paths = $self->get_paths_from_DB($type_id);

    foreach my $path ($self->get_paths_as_list($paths)) {

	($path =~ /^[^#]+$/) or (delete $paths->{$path});
	($paths->{$path}->{'value'}) or (delete $paths->{$path});
    }

    return $paths;
}

# Comprueba si un  1º tipo es subtipo de un 2º

sub is_subtype {

    my $self = shift;
    my $subtype = shift;
    my $supertype = shift;

    foreach my $parent ($self->get_parents_from_DB_rec($subtype)) {

	if ($parent eq $supertype) { return 1; }
    }
    return 0;
}

#### MÉTODOS AUXILIARES PARA RECORRER LA GRAMÁTICA

# - Recorre la gramática desde un tipo que se le pasa como
# - argumento hacia sus subtipos sucesivos.

sub cover_grammar_up_bottom {

    my $self = shift;
    my $supertype = shift;
    my $methods = shift;

    foreach my $subtype ($self->get_subtypes_from_DB($supertype)) {
	 
	$methods and 
	$self->execute_methods_from_href($methods,$subtype) and
	next;

	$self->cover_grammar_up_bottom($subtype,$methods);
    }
}

# - Se le pasa un hash con métodos de esta clase
# - y un objeto type. Se aplican a dicho objeto
# - cada uno de los métodos del hash.

sub execute_methods_from_href {

    my $self = shift;
    my $methods = shift;
    my $type = shift;

    foreach my $method (keys %{$methods}) {

	$self->$method($type);
    }
}


1;
