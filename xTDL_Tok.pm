package xTDL_Tok;

use warnings;
use strict;
use locale;
use xtype;
use xname;
use xattribute;
use xsharing;
use xfeature;
use Automata;
use state;
use arc;
use xTDL_Gram;

#####################
# VARIABLES DE CLASE
##################### 

## NL es Nested Lists. En esta variable se va añadiendo
## como string el resultado del procesamiento del método
## change_shortcuts. Esta variable se enviará después a
## un fichero temporal (->shortcuts_file), desde donde
## leerá el tokenizer central la versión modificada por
## shortcuts del fichero de entrada. 

my $NL_result;

##

## - Creamos el autómata para el reconocimiento de TDL
## - Creamos el objeto

my $automata = Automata->new;

# Autómata

my $tdl = { '1' => {"name"        => '2'},
            '2' => {"implication" => '3',
                    "add"         => '15'},
            '3' => {"name"        =>'4'},
            '4' => {"sum"         => '5',
                    "dot"         => '13'},
            '5' => {"name"        => '4',
                    "open"        => '6'},
            '6' => {"dots"        => '14',
                    "name"        => '7'},
            '7' => {"name"        => '8',
                    "sharing"     => '9',
                    "open"        => '6'},
            '14' => {"name"       => '8',
                    "sharing"     => '9',
                    "open"        => '6'},
            '8' => {"sum"         => '10',
                    "comma"       => '11',
                    "close"       => '12'},
            '9' => {"sum"         => '10',
                    "comma"       => '11',
                    "close"       => '12'},
            '10' => {"name"       => '8',
                     "sharing"    => '9',
                     "open"       => '6'},
            '11' => {"name"       => '7',
                     "dots"        => '14'},
            '12' => {"comma"      => '11',
                     "dot"        => '13'},
	    '15' => {"open"       => '6' },
            '13' => {"name"       => '2'}};

# - Creamos sus estados y transiciones

$automata->make_automata_from_hash($tdl);

# - Establecemos el estado inicial

$automata->present_state($automata->get_state_by_key('1'));

# - Establecemos los estados finales

$automata->get_state_by_key('13')->final("1");

# - Añadimos métodos a los estados

$automata->get_state_by_key('2')->append_method('initialize_tokenizer');
$automata->get_state_by_key('4')->append_method('add_parent');
$automata->get_state_by_key('7')->append_method('add_feature');
$automata->get_state_by_key('14')->append_method('add_feature_with_dots');
$automata->get_state_by_key('8')->append_method('set_name');
$automata->get_state_by_key('9')->append_method('set_sharing');
$automata->get_state_by_key('11')->append_method('del_type_from_types_stack');
$automata->get_state_by_key('11')->append_method('del_feature_from_features_stack');
$automata->get_state_by_key('12')->append_method('del_type_from_types_stack');
$automata->get_state_by_key('12')->append_method('del_feature_from_features_stack');
$automata->get_state_by_key('15')->append_method('set_add');

##########
# MÉTODOS
##########

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

# Se inician los repositorios. Se crea una ruta 
# para el output de change_shortcuts './raw'.
# Se crea una gramática con respecto a la cual 
# tokenizar. Y se toma de ella una expresión 
# regular que define a cualquier token. Se guarda
# en TOKEN.

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );
    
    $self->start_lists;
    $self->shortcuts_file('./shortcuts');

    $self->TDL_Gram(TDL_Gram->new);           # Se crea la gramática para que la use el 
    $self->TOKEN($self->TDL_Gram->text_unit); # autómata

    return $self;
}

sub DESTROY {

    my $self = shift;
}

# Método auxiliar para iniciar las listas

# lists_stack funciona como pila y lleva cuenta
# de las listas anidadas de las estructuras de 
# rasgos, para cambiar el shortcut <>

# En types_stack y features_stack se lleva cuenta
# de los tipos y rasgos anidados en la tokenización
# de los archivos TDL. Es necesario para saben, en
# cada momento, a qué tipo o rasgo hay que añadirle
# un nombre o algo

# La tokenización va añadiendo tipos a result. Es 
# mejor esto que ponerlos todos en DB según se creran
# para evitar meter en DB si hay algún error.

sub start_lists {

    my $self = shift;

    $self->lists_stack([]); 
    $self->types_stack([]); 
    $self->features_stack([]); 
    $self->result([]);
}

####################
# MÉTODOS DE ACCESO
####################

# Lista de tipos procesados

sub result {

    my $self = shift;
    if ( @_ ) { $self->{result} = shift };
    return $self->{result};
}

# Pila de tipos anidados

sub types_stack {       
                     
    my $self = shift;
    if ( @_ ) { $self->{types_stack} = shift };
    return $self->{types_stack};
}

# Pila de rasgos anidados

sub features_stack {       
                     
    my $self = shift;
    if ( @_ ) { $self->{features_stack} = shift };
    return $self->{features_stack};
}

# Gramática de archivos TDL

sub TDL_Gram {

    my $self = shift;
    if ( @_ ) { $self->{TDL_Gram} = shift };
    return $self->{TDL_Gram};
}

# Expresión regular caracterizadora de 
# cualquier token TDL

sub TOKEN {

    my $self = shift;
    if ( @_ ) { $self->{TOKEN} = shift };
    return $self->{TOKEN};
}

# Ruta del archivo temporal en el que se mete
# el resultado de change_shortcuts

sub shortcuts_file {

    my $self = shift;
    if ( @_ ) { $self->{shortcuts_file} = shift };
    return $self->{shortcuts_file};
}


# Clase que hay que poner a cada tipo: type, grule, lrule, etc.

sub class {       
                     
    my $self = shift;
    if ( @_ ) { $self->{class} = shift;} 
    return $self->{class};
}

##############################################
### MÉTODOS DE GESTIÓN DE LOS REPOSITORIOS ###
##############################################

###
# Gestión del resultado
###

# Se añade un tipo al resultado

sub add_type_to_result {

    my $self = shift;
    my $type = shift;
    $self->class || die "There is not class";
    $type->class($self->class);

    unshift (@{$self->result}, $type);
}

# Se devuelven los tipos del resultado 
# como lista

sub get_result_as_list {

    my $self = shift;
    my $type = shift;

    return @{$self->result};
}

# Se vacía el resultado

sub empty_result {

    my $self = shift;

    $self->result([]);
}

###
# Gestión de la pila de tipos
###

# Se consulta el tipo superior de la pila
# Este método no altera la pila

sub get_present_type {

    my $self = shift;
    return @{$self->types_stack}[0];
}

# Se añade un tipo a la parte superior
# de la pila

sub add_type_to_types_stack {

    my $self = shift;
    my $type = shift;

    unshift (@{$self->types_stack}, $type);
}

# Se elimina el tipo superior de la pila

sub del_type_from_types_stack {

    my $self = shift;

    shift @{$self->types_stack};
}

# SE crea una nueva pila

sub empty_types_stack {

    my $self = shift;

    $self->types_stack([]);
}

###
# Gestión de la pila de rasgos
###

# Se consulta el rasgo superior de la pila

sub get_present_feature {

    my $self = shift;

    return @{$self->features_stack}[0];
}

# Se añade un rasgo a la parte superior
# de la pila

sub add_feature_to_features_stack {

    my $self = shift;
    my $feature = shift;

    unshift (@{$self->features_stack}, $feature);
}

# Se elimina el rasgo superior de la pila

sub del_feature_from_features_stack {

    my $self = shift;

    shift @{$self->features_stack};
}

# Se crea una nueva pila

sub empty_features_stack {

    my $self = shift;

    $self->features_stack([]);
}

########################################
## MÁTODOS DE ACTUALIZACIÓN DE LOS TYPES
########################################

# Se añade nombre de sharing al rasgo actual

sub set_sharing {

    my $self = shift;
    my $sharing_id = shift;

    $self->get_present_feature->sharing->id($sharing_id);
}

# Se añade nombre al tipo actual

sub set_name {

    my $self = shift;
    my $name_id = shift;

    my $name = xname->new;
    $name->id($name_id);

    $self->get_present_type->name($name);
}

# Se añade al tipo actual la señal de que es
# un añadido a un tipo que ya existía

sub set_add {

    my $self = shift;

    $self->get_present_type->add('1');
}

# Se añade al nombre del tipo actual un id de
# padre

sub add_parent {

    my $self = shift;
    my $parent = shift;

    $self->get_present_type->name->add_parent($parent);
}

# Se le añade al tipo actual un rasgo

sub add_feature {

    my $self = shift;
    my $attribute_id = shift;

    my $feature = $self->create_feature($attribute_id); 
    $self->add_feature_to_features_stack($feature);
    $self->get_present_type->add_feature($feature);
    $self->add_type_to_types_stack($feature->value);
}

# Alternativa a add_feature cuando en vez de rasgo
# hay una ruta anidada F.F.F etc.

# Se crea la estructura de rasgos en anidación
# y al final se pone como tipo actual el más
# anidado, y como rasgo actual el menos anidado

sub add_feature_with_dots  {

    my $self = shift;
    my $dots = shift;

    my $whole_feature;
    my $current_feature;

    foreach my $attribute_id ($self->get_dots_as_list($dots)) {

	my $feature = $self->create_feature($attribute_id);
	unless ($whole_feature) {$whole_feature = $feature;}
	if ($current_feature) {$current_feature->value->add_feature($feature);}
	$current_feature = $feature;
    }

    $self->get_present_type->add_feature($whole_feature);
    $self->add_type_to_types_stack($current_feature->value);
    $self->add_feature_to_features_stack($current_feature);
}

# Métodos auxiliares a la creación de rasgos

# Crea un rasgo a partir de un id de atributo

sub create_feature {

    my $self = shift;
    my $attribute_id = shift;

    my $feature = xfeature->new;
    my $attribute = xattribute->new;
    $attribute->id($attribute_id);
    $feature->attribute($attribute);

    return $feature;
}

# Parte una ruta de rasgos y devuelve
# el resultado como lista

sub get_dots_as_list {

    my $self = shift;
    my $dots = shift;

    my $DOT = $self->TDL_Gram->dot;

    return split $DOT, $dots;
} 


############################
## MÉTODOS DE RECONOCIMIENTO
############################


# Tokeniza un archivo que se le pasa como argumento

sub tokenize_file {

    my $self = shift;
    my $file = shift;

    my $tdl = $self->get_tdl_from_file($file);
    $tdl = $self->change_shortcuts($tdl);
    $self->add_tdl_to_shortcuts_file($tdl);
    $self->tokenize($self->shortcuts_file);
}

# En cada línea del archivo, el autómata se 
# va comiendo sucesivamente el principio, enten-
# diendo que unificará con alguno de los tokens
# TDL. Por cada uno de esos tokens se busca la 
# tag correspondiente, y se mueve el autómata en 
# consecuencia a esa tag. Se ejecutan los métodos
# asociados al estado resultante del autómata

# En caso de que el autómata no haya consumido
# toda la línea se considera que esta no unificaba
# con la gramática, y se lanza error

sub tokenize {

    my $self = shift;
    my $file = shift;

    my $TOKEN = $self->TOKEN;
    open RAW, "$file" or die $!;

    foreach (<RAW>) {
	while (s/^\s*($TOKEN)\s*//) {

	    my $tag = $self->TDL_Gram->type($1);
	    $automata->parser($tag); 
	    $self->execute_automata_methods($1);
	    $automata->present_state->final and 
            $automata->present_state($automata->get_state_by_key('1'));
	}
	$_ and die "Secuencia desconocida: $_\n";
    }
    close RAW;
}

# Método que ejecuta los métodos propuestos en el estado
# actual del autómata sobre el token encontrado

sub execute_automata_methods {

    my $self = shift;
    my $form = shift;

    foreach my $method ($automata->present_state->get_methods_list) {

	$self->$method($form);
    }
}

# Pone a 0 el tokenizer para analizar un nuevo tipo. 
# Crea el tipo que será el nuevo tipo, vacía las pilas, 
# coloca el nuevo tipo en su pila y en el resultado

sub initialize_tokenizer {

    my $self = shift;
    my $name_id = shift;
    print STDERR "Creando $name_id                          \r";
    my $type = xtype->new;
    my $name = xname->new;
    $name->id($name_id);
    $type->name($name);

    $self->empty_types_stack;
    $self->empty_features_stack;
    $self->add_type_to_types_stack($type);
    $self->add_type_to_result($type);
}

## Métodos auxiliares para gestionar la entrada y salida
## de la información

## Recoge la información del archivo que
## se le pasa al objeto y crea una string

sub get_tdl_from_file {

    my $self = shift;
    my $file = shift;
    my $tdl;

    open FILE, "$file" or die $!;
    foreach (<FILE>) { $tdl .= $_;}
    close FILE;
    return $tdl;
}

# Escribe en un archivo temporal el resultado
# intermedio del procesamiento: el de change_shortcuts

sub add_tdl_to_shortcuts_file {

    my $self = shift;
    my $tdl = shift;

    my $file = $self->shortcuts_file;

    open (SHORTCUTS,">$file") || die $!;
    print SHORTCUTS $tdl;
    close SHORTCUTS;
}

##############################
#### GESTIÓN DE LAS LISTAS <>
##############################

### Esta parte del código está encargada de cambiar el texto
### TDL por otro equivalente sin shortcuts: <>, <!!>.

sub change_shortcuts {

    my $self = shift;
    my $tdl = shift;

# Los tres últimos métodos presuponen los anteriores

    $tdl = $self->delete_tdl_comments($tdl); # Elimina comentarios
    $tdl = $self->change_empty_brackets($tdl); # Cambia [] por *top*
    $tdl = $self->change_empty_list($tdl);     # Cambia <> por null
    $tdl = $self->change_empty_diff_list($tdl); # Cambia <!!> por last null
    $tdl = $self->change_multiple_dots($tdl);   # Cambia múltiples dots por @ (estratégico)
    $tdl = $self->change_open_diff_list($tdl);  # Cambia <! por % (estratégico)
    $tdl = $self->change_close_diff_list($tdl); # Cambia !> por ? (estratégico)

    $tdl = $self->change_nested_lists($tdl);    # Método central para cambiar las listas anidadas 
                                                # < ....> y <! .... !>
    return $tdl;
}

# Borra los comentarios del TDL

sub delete_tdl_comments {

    my $self = shift;
    my $tdl = shift;
    undef $/;
    $tdl =~ s/;+[^\n]*(\n|$)//g;

    return $tdl;
}


# Cambia [] por el axioma

sub change_empty_brackets {

    my $self = shift;
    my $tdl = shift;
    undef $/;
    $tdl =~ s/<\[\s*\]/*top*/g;  # Cambiar [] por *top* 
    return $tdl;
}


# Cambia <> por el tipo de lista vacía

sub change_empty_list {

    my $self = shift;
    my $tdl = shift;
    undef $/;
    $tdl =~ s/<\s*>/null/g;      # Cambiar <> por null
    return $tdl;
}


# Cambia <!!> por el tipo de lista vacía

sub change_empty_diff_list {

    my $self = shift;
    my $tdl = shift;
    undef $/;
    $tdl =~ s/<!\s*!>/ [ LIST null ]/g; # Cambiar <!!> por [LIST null]
    return $tdl;
}

# Cambia f.f.f.f por f@f@f@f

sub change_multiple_dots {

    my $self = shift;
    my $tdl = shift;
    undef $/;
    $tdl =~ s/,\s*\.\s*\.\s*\./@/g; 
    return $tdl;
}


# Cambia f.f.f.f por f@f@f@f

sub change_open_diff_list {

    my $self = shift;
    my $tdl = shift;
    undef $/;
    $tdl =~ s/<\s*!/%/g; # Cambiar <! por %
    return $tdl;
}


# Cambia f.f.f.f por f@f@f@f

sub change_close_diff_list {

    my $self = shift;
    my $tdl = shift;
    undef $/;
    $tdl =~ s/!\s*>/?/g; # Cambiar !> por ?
    return $tdl;
}

##########################################
# Método central del cambio de shortcuts #
##########################################

# El resultado del cambio de cada tipo se colocará
# en una variable de clase. Se pone a 0 esa variable
# con $self->initialize_nl_result.

# Se le pasa un tdl y se cambian en él las listas anidadas
# Mientras haya tdl se repite este proceso:
# - Se reconocen en el tdl tres partes: un signo relevante,
#   la parte del tdl que lo precede y la que lo sigue. La
#   función recognize_nl distingue estas tres partes y se 
#   colocan en $prev, $sign y $rest, respectivamente.
# - En la parte previa no hay que hacer cambios, luego se
#   añade sin más al resultado: update_nl_result
# - Con el signo se hace el procesamiento en sí: manage_nl_sign
#   (se le pasa a este método el resto porque a veces es relevante,
#    aunque nunca se cambia) 
# - el tdl se identifica con el resto de la secuencia tras
#   el signo identificado.

# La función devuelve el resultado guardado en nl_result

sub change_nested_lists {

    my $self = shift;
    my $tdl = shift;

    $self->initialize_nl_result;

    while ($tdl) {

	my ($prev, $sign, $rest) = $self->recognize_nl($tdl);

	$self->update_nl_result($prev);
	$self->manage_nl_sign($sign,$rest);
	$tdl = $rest;
    }
    return $self->return_nl_result;
}


# Gestión de NL_result


sub initialize_nl_result {

    my $self = shift;
    $NL_result = '';
}


sub return_nl_result {

    my $self = shift;
    return $NL_result;
}


sub update_nl_result {

    my $self = shift;
    my $string = shift;
    unless ($string) { return; }
    $NL_result .= $string;
}
	

# Identificación de los signos relevantes del proceso
# Se le pasa un tdl y lo devuelve en tres partes
# - La previa al primer signo encontrado
# - el primer signo encontrado
# - el resto.

sub recognize_nl {

    my $self = shift;
    my $tdl = shift;
    $tdl =~ s/^([^,<>[\]@%?.]+)*([,[\]<>@%?.])?//;

    my $prev = $1;
    my $sign = $2;

    unless ($prev) { $prev = ''; }
    unless ($sign) { $sign = ''; }
    return ($prev,$sign,$tdl);
}

# Método central que regula los cambios en el tdl
# Se le pasa el signo identificao (y el resto, que
# a veces determina el contexto)
# get_nl_tag identifica el tipo de signo que es
# Según el tipo de signo, se emprenderá una acción.
# Esa acción la determina, a partir del tipo de signo
# el método get_nl_method.
# Se aplica el método encontrado con el resto, que, a
# veces, es relevante

sub manage_nl_sign {

    my $self = shift;
    my $sign = shift;
    my $rest = shift;
    unless ($sign) { return; }
    my $tag = $self->get_nl_tag($sign);
    my $method = $self->get_nl_method($tag);
    $self->$method($rest);
}

# Crea un nombre de método a partir de una secuencia 
# se le pasa

sub get_nl_method {

    my $self = shift;
    my $affix = shift;
    my $method = 'manage_nl_' . "$affix";
    return $method;
}

# Identifica el tipo de signo que se le ha pasado

sub get_nl_tag {

    my $self = shift;
    my $sign = shift;
    my $tag = '';

    ($sign eq ".") and ($tag = 'dot');
    ($sign eq "@") and ($tag = 'mdots');
    ($sign eq ",") and ($tag = 'comma');
    ($sign eq ",") and ($tag = 'comma');
    ($sign eq "[") and ($tag = 'obracket');
    ($sign eq "]") and ($tag = 'cbracket');
    ($sign eq "<") and ($tag = 'olist');
    ($sign eq ">") and ($tag = 'clist');
    ($sign eq "%") and ($tag = 'odlist');
    ($sign eq "?") and ($tag = 'cdlist');

    return $tag;
}


##### MÉTODOS DE GESTIÓN DEL TDL      #####
##### EN FUNCIÓN DEL SIGNO ENCONTRADO #####


# Cuando se encuentra un punto

sub manage_nl_dot {

    my $self = shift;
    my $tdl = shift;

    if ($tdl =~ /^\s+/){ 
	$self->manage_nl_dot_aux($tdl); 
    } else {
	$self->update_nl_result('.');
    }
}

sub manage_nl_dot_aux {

    my $self = shift;
    my $tdl = shift;

    $self->get_present_list    and 
    $self->undef_LISTS_STACK   and
    $self->update_nl_result(', REST ') and
    return 1;

    $self->update_nl_result('.');
    return 0;
}


# Cuando se encuentra una coma

sub manage_nl_comma {

    my $self = shift;
    my $tdl = shift;

    $self->update_nl_result(',');
    $self->add_rest_to_LISTS_STACK and 
    $self->update_nl_result(' REST [FIRST ');
}

# Cuando se encuentra un [

sub manage_nl_obracket {

    my $self = shift;
    my $tdl = shift;

    $self->add_bracket_to_LISTS_STACK;
    $self->update_nl_result(' [ ');	    
}

# Cuando se encuentra un ]

sub manage_nl_cbracket {

    my $self = shift;
    my $tdl = shift;

    $self->del_bracket_from_LISTS_STACK;
    $self->update_nl_result(' ] ');
}

# Cuando se encuentra un <

sub manage_nl_olist {

    my $self = shift;
    my $tdl = shift;

    $self->add_item_to_LISTS_STACK;

    $self->update_nl_result(' [FIRST ');	    
}

# Cuando se encuentra un >

sub manage_nl_clist {

    my $self = shift;
    my $tdl = shift;

    if ($self->present_list_is_null) {$self->update_nl_result(', REST null ');}

    my $n = $self->del_item_from_LISTS_STACK;
    $self->update_nl_with_n_cbrackets($n);
}

# Cuando se encuentra un <!

sub manage_nl_odlist {

    my $self = shift;
    my $tdl = shift;

    $self->add_item_to_LISTS_STACK;
    $self->undef_LISTS_STACK;
    $self->update_nl_result(' [ LIST [FIRST ');
}

# Cuando se encuentra un !>

sub manage_nl_cdlist {

    my $self = shift;
    my $tdl = shift;

    $self->update_nl_result(', REST ');
    my $null_or_list = $self->get_present_list->{NULL_OR_LIST};
    $self->update_nl_result($null_or_list);
    my $n =  $self->del_item_from_LISTS_STACK;
    $self->update_nl_with_n_cbrackets($n);
    $self->update_nl_result(', LAST list ]');
}

# Cuando se encuentra un f.f.f.f.

sub manage_nl_mdots {

    my $self = shift;
    my $tdl = shift;

    $self->undef_LISTS_STACK;
}

### MÉTODOS DE GESTIÒN DE LA PILA DE LISTAS ANIDADAS

sub add_rest_to_LISTS_STACK {

    my $self = shift;
    unless ($self->get_present_list) { return 0; }
    if ($self->get_present_list->{BRACKET}) { return 0; }
    $self->get_present_list->{REST}++;
}

sub add_bracket_to_LISTS_STACK {

    my $self = shift;
    unless ($self->get_present_list) { return 0; }
    $self->get_present_list->{BRACKET}++;
}

sub del_bracket_from_LISTS_STACK {

    my $self = shift;
    unless ($self->get_present_list) { return 0; }
    $self->get_present_list->{BRACKET}--;
}

sub add_item_to_LISTS_STACK {

    my $self = shift;
    my $list = { 'BRACKET' => '0',
		 'REST'    => '1',
                 'NULL_OR_LIST'    => ' null '};

    unshift (@{$self->lists_stack}, $list);
}

sub del_item_from_LISTS_STACK {

    my $self = shift;
    my $rest = $self->get_present_list->{REST};
    shift @{$self->lists_stack};
    return $rest;
}

sub undef_LISTS_STACK {

    my $self = shift;
    unless ($self->get_present_list) { return 0; }
    $self->get_present_list->{NULL_OR_LIST} = ' list ';
}

sub get_present_list {

    my $self = shift;

    unless (@{$self->lists_stack}[0]) { return 0; }

    return @{$self->lists_stack}[0];
}

sub lists_stack {       
                     
    my $self = shift;
    if ( @_ ) { $self->{lists_stack} = shift };
    return $self->{lists_stack};
}

###########################################
############ MÉTODOS AUXILIARES ###########
###########################################

# Determina si la lista presente de una pila de listas
# tiene valor null

sub present_list_is_null {

    my $self = shift;

    if ($self->get_present_list->{NULL_OR_LIST} eq ' null ') { return 1; } # CUIDADO con los espacios
    return 0;
}

# Lanza el método update_nl_result con 'n' cierres que
# se le pasan

sub update_nl_with_n_cbrackets {

    my $self = shift;
    my $n_brackets = shift;

    while ($n_brackets) {

	$self->update_nl_result(' ] ');
	$n_brackets--;
    }
}

1;
