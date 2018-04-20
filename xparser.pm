package xparser;

use warnings;
use strict;
use locale;
use xgrammar;
use xunification;
use xagenda;
use xedge;
use xchart;
use XML_Parser;
use Data::Dumper;
use xbinding_manager;
use Benchmark qw(:all);
use Tree;
use DBI;

#####################
# VARIABLES DE CLASE
##################### 

my $COUNTER = 0;
my $NEW_TOKEN = 0;
my $M_COUNTER = 0;

##########
# MÉTODOS
##########

# El parser cuenta con una agenda y un chart
# La entrada es XML y XML_Parser se encarga de
# procesarla

# Para poder separar el procesamiento de reglas
# léxicas del sintáctico, se crea un repositorio
# con los índices de las reglas que se van a usar
# en cada paso: current_rules 

##########################
# CONSTRUCTOR Y DESTRUCTOR 
##########################

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->database('ssg');
    $self->scrambling('1');
    $self->chart(xchart->new());
    $self->agenda(xagenda->new());
    $self->XML_Parser(XML_Parser->new());
    $self->start_current_rules;
    $self->binding_manager(xbinding_manager->new());
    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

sub database {       
                     
    my $self = shift;
    if ( @_ ) { $self->{database} = shift };
    return $self->{database};
}


sub scrambling {       
                     
    my $self = shift;
    if ( @_ ) { $self->{scrambling} = shift };
    return $self->{scrambling};
}

# Gramática (objeto grammar), conforme a la
# cual se analiza

sub grammar {       
                     
    my $self = shift;
    if ( @_ ) { $self->{grammar} = shift };
    return $self->{grammar};
}

# Chart

sub chart {       
                     
    my $self = shift;
    if ( @_ ) { $self->{chart} = shift };
    return $self->{chart};
}

# Agenda

sub agenda {       
                     
    my $self = shift;
    if ( @_ ) { $self->{agenda} = shift };
    return $self->{agenda};
}

# El unificador, usado para comprobar las
# compatibilidades

sub unification {       
                     
    my $self = shift;
    if ( @_ ) { $self->{unification} = shift };
    return $self->{unification};
}

# Parser del XML de entrada

sub XML_Parser {       
                     
    my $self = shift;
    if ( @_ ) { $self->{XML_Parser} = shift };
    return $self->{XML_Parser};
}

# Repositorio de índices de las reglas
# que se van a usar en cada paso

sub current_rules {       
                     
    my $self = shift;
    if ( @_ ) { $self->{current_rules} = shift };
    return $self->{current_rules};
}

sub binding_manager {       
                     
    my $self = shift;
    if ( @_ ) { $self->{binding_manager} = shift };
    return $self->{binding_manager};
}

#############################
### MÉTODO CENTRAL: PARSE ###
#############################

### Este objeto analiza un texto
### con 1 o más segmentos

### Este es el método público. 
### Analiza el XML de entrada y
### busca en él todos los segmentos
### Se lanza el método central 
### 'parse_segment' para cada segmento

sub parse {

    my $self = shift;
    my $input_xml = shift;

    $self->XML_Parser->input($input_xml);

    foreach my $segment ($self->XML_Parser->get_sppp_segments) {
 
	$self->parse_segment($segment);
    }
}

### Método central del análisis

### SE crean las palabras y se flexionan a partir del XML
### (create_words); se aplican a esas palabras las reglas 
### léxicas de la gramática (apply_lrules), y se aplican
### después las reglas gramaticales 

sub parse_segment {

    my $self = shift;
    my $segment = shift;

    my $t0 = new Benchmark;

    $self->start_counter;
    print STDERR "Aplicando reglas léxicas                              \n";
    $self->apply_lrules($segment);
    print  STDERR "Aplicadas reglas léxicas                              \n";
    print  STDERR "Aplicando reglas gramaticales                             \n";
    $self->apply_grules;
    print STDERR  "Aplicadas reglas gramaticales                              \n";

    my $t1 = new Benchmark;

    my $td = timediff($t1, $t0);
    my $sec= timestr($td);
    print  "Tiempo empleado: $sec\n\n";

    print  STDERR "Mostrando resultado                                \n";
    $self->get_output();
    $self->clear;
}

#####################################################
### PRIMER PASO: CREACIÓN DE PALABRAS FLEXIONADAS ###
### Y ESPECIFICADAS CON LAS REGLAS LÉXICAS        ###
#####################################################

### Se analiza el XML de cada segmento buscando todas  
### las unidades léxicas de la gramática cuyo lema sea 
### el stem de un análisis de uno de los tokens del 
### segmento XML. Por cada uno de esos elemenos, se
### colocan en current_rules las reglas léxicas que
### lleva en el análisis XML y se lanza con ese material
### el proceso general de análisis: recognize. 

sub apply_lrules {

    my $self = shift;
    my $segment = shift;

    foreach my $token ($self->XML_Parser->get_sppp_tokens($segment),
	               $self->XML_Parser->get_sppp_silence_tokens($segment)) {

	$self->new_token_on;
	foreach my $analysis ($self->XML_Parser->get_sppp_analysis($token)) {

	    my $stem = $self->XML_Parser->get_sppp_stem($analysis);

	    foreach my $pattern_id ($self->grammar->get_lex_units_as_list($stem)) {

		if ($self->new_token) { $self->add_counter; $self->new_token_off; }
	  
		$self->add_lex_item_to_agenda($stem,$pattern_id);
		$self->add_lrules_to_current_rules($analysis);
		$self->recognize;
	    }   
	}
    }
}

##########################################
### Métodos auxiliares de apply_lrules ###
##########################################

# Crea un edge representativo de la unidad léxica sin flexionar
# correspondiente al lema $stem y al nombre de tipo $pattern_id.
# Lo añade a la agenda 

sub add_lex_item_to_agenda {

    my $self = shift;
    my $stem = shift;
    my $pattern_id = shift;

    my $pattern = $self->grammar->get_lex_unit_by_index($stem,$pattern_id);
    my $edge = $self->create_edge($pattern);

    $edge->create_continuous_location($self->counter,$self->counter);
    $self->agenda->add_edge_in_line($edge);
}

# Por cada regla del análisis XML, añade el id a current_rules

sub add_lrules_to_current_rules {

    my $self = shift;
    my $analysis = shift;

    $self->start_current_rules;

    foreach my $rule ($self->XML_Parser->get_sppp_rules($analysis)) {

	my $id = $self->XML_Parser->get_sppp_rule_id($rule);

	$self->update_current_rules($id);
    }
}

###########################################################
### SEGUNDO PASO: CREACIÓN DE PROYECCIONES GRAMATICALES ###
###########################################################

### Ya creados los edges representativos de las unidades léxicas
### flexionadas y especificadas por patrón de comportamiento, se
### procede a la combinación sintáctica. Para ello, se coloca en
### current_rules las reglas flexivas 

sub apply_grules {

    my $self = shift;

    $self->add_phrases_to_agenda;
    $self->add_grules_to_current_rules;
    $self->recognize;
}

sub add_phrases_to_agenda {

    my $self = shift;

    $self->agenda->start_edges;

    foreach my $edge ($self->chart->get_inactive_edges_as_list) {

	$self->is_phrase($edge) and
	$self->agenda->add_edge_in_line($edge);	    
    }

    $self->chart->start_active_edges;
    $self->chart->start_inactive_edges;
}

sub is_phrase {

    my $self = shift;
    my $edge = shift;

    my $Ipath = $self->grammar->get_globals('INFLECTED');
    my $Cpath = $self->grammar->get_globals('CONSTRUCTION');
    my $Bn = $self->grammar->get_globals('NO');

    $edge->merge($Ipath,$Bn) or return 0;
    $edge->merge($Cpath,$Bn) or return 0;
    return 1;
}

##########################################
### Métodos auxiliares de apply_grules ###
##########################################

# Por cada regla del análisis XML, añade el id a current_rules

sub add_grules_to_current_rules {

    my $self = shift;

    $self->start_current_rules;

    foreach my $rule ($self->grammar->get_grules_id_as_list) {

	$self->update_current_rules($rule);
    }
}

# Falta un método de inicializar la agenda

####################################
### Métodos auxiliares generales ###
####################################

# CREACIÓN DE EDGES

# Crea un edge desde un tipo modelo (un patrón
# de la gramática, u otro edge previo)

# Crea el tipo nuevo a partir del modelo.
# crea un edge: El label será el tipo nuevo
# en to_find se colocarán los RHS que se encuentren
# en ese tipo nuevo. En principio, un edge nuevo
# no ha encontrado ninguno de sus constituyentes,
# si es que los pide.

sub create_edge {

    my $self = shift;
    my $pattern = shift;

    my $type = $pattern->clone;

    my $rhs1 = $self->grammar->get_rhs1($type);
    my $rhs2 = $self->grammar->get_rhs2($type);
    my $lhs  = $self->grammar->get_lhs($type);

    my $edge = xedge->new();
                       
    $edge->label($lhs);
    $rhs1 and $edge->add_to_find($rhs1);
    $rhs2 and $edge->add_to_find($rhs2);

    return $edge;
}

# Crea el edge que es proyección de otro edge, dada
# la satisfacción de la primera de sus necesidades
# Recibe dos edges: el que satisface ($daughter) y el
# que va a ser satisfecho ($rule)

# Crea una nueva versión del edge que va a ser satisfecho.
# A esa nueva versión le aplica la unficación de daughter.
# Se codifica en ella la satisfacción del elemento corres-
# pondiente a daughter con add_found y to_find.

sub create_proyection_edge {

    my $self = shift;
    my $rule_edge = shift->clone;
    my $daughter_edge = shift;

    $self->unification->unify($daughter_edge->label,$rule_edge->first_to_find) or return 0;

    $rule_edge->add_found($daughter_edge);
    $rule_edge->to_find($rule_edge->rest_to_find);

    return $rule_edge;
}

# GESTIÓN DE CURRENT_RULES

# Se pone a cero

sub start_current_rules {

    my $self = shift;
    $self->current_rules([]);
}

# Se le añade un elemento

sub update_current_rules {

    my $self = shift;
    my $rule = shift;

    push @{$self->current_rules}, $rule;
}

# Se devuelve como lista

sub get_current_rules_as_list {

    my $self = shift;
    return @{$self->current_rules};
}

# MÉTODOS CENTRALES DE RECONOCIMIENTO

# Por cada elemento de la agenda, se procede
# a expandir y combinar. Una vez usado, el
# edge se guarda en el repositorio que corres-
# ponda.

# El cómo funcione ese añadido a los repositorios
# puede ser variable, en función de que se use
# uno u otro algoritmo de parsing

sub recognize {

    my $self = shift;

    while (my $edge = $self->agenda->get_edge) {

	$self->expand_edge($edge);
	$self->combine_edge($edge);
	$self->chart->add_edge($edge);
    }
}

# Métodos de combinación de edges
# Los edges combinan de forma diferente
# según sean activos o inactivos. Los edges
# activos combinarían con los inactivos y
# viceversa. Los siguientes métodos regulan
# el modo de combinar el edge en función de
# su carácter activo o inactivo
# En cualquier caso, la combinación consiste 
# en crear una proyección a partir de la satis-
# facción en el edge activo del edge inactivo 

# En caso, de éxito, la nueva proyección (un
# nuevo edge) se añade con add_edge al repositorio
# oportuno

# Se comprueba si el edge es activo o inactivo
# Se lanza el método combine_active_edge en el
# primer caso, combine_inactive_edge en el segundo

sub combine_edge {

    my $self = shift;
    my $edge = shift;

    if ($edge->first_to_find)  { 

	$self->combine_active_edge($edge);

    } else {

	$self->combine_inactive_edge($edge);
    }
}

# Se combina un edge inactivo con todos los activos
# del chart

sub combine_inactive_edge {

    my $self = shift;
    my $inactive_edge = shift;

    foreach my $active_edge ($self->chart->get_active_edges_as_list) {

	$self->combine_edge_aux($active_edge,$inactive_edge);
    }
}

# Se combina un edge activo con todos los inactivos
# del chart

sub combine_active_edge {

    my $self = shift;
    my $active_edge = shift;

    foreach my $inactive_edge ($self->chart->get_inactive_edges_as_list) {

	$self->combine_edge_aux($active_edge,$inactive_edge);
    }
}

# Método de combinación real: se crea una proyección en la que
# el activo es la madre, y el inactivo es la hija. La proyección
# es un tipo nuevo en un edge nuevo. Si se ha logrado, se añade
# al repositorio correspondiente con add_edge.

sub combine_edge_aux {

    my $self = shift;
    my $active_edge = shift;
    my $inactive_edge = shift;

    $self->unification->unify_test($inactive_edge->label,$active_edge->first_to_find) or return 1;
    $self->check_adyacence($active_edge,$inactive_edge) or return 1;

    my $new_edge = $self->create_proyection_edge($active_edge,$inactive_edge);

    if ($new_edge) {

	print STDERR  "Combinando ".$inactive_edge->label->name->id." con ".$active_edge->label->name->id."\n";

	$new_edge->add_to_location_from_edge($inactive_edge);
	$new_edge->add_to_location_from_edge($active_edge);
	$self->add_edge($new_edge);
    } 
}

# Método de expansión de edges
# En principio, solo sería válido
# para edges inactivos. Algún algoritmo
# podría expandir edges activos también

# Habrá que poner una condición al principio,
# o no, según el algoritmo.

sub expand_edge {

    my $self = shift;
    my $edge = shift;

    $edge->first_to_find and return 1;

    foreach my $rule_id ($self->get_current_rules_as_list) {

	my $rule = $self->grammar->get_type_by_id($rule_id);

	unless ($rule) { print STDERR  "\n\n$rule_id not found\n\n"; next; }

#	$self->unification->unify_test($edge->label,$self->grammar->get_rhs1($rule)) or next;

	my $rule_edge = $self->create_edge($rule);
	my $new_edge = $self->create_proyection_edge($rule_edge,$edge);

	if ($new_edge) {
	    print STDERR  "Expandiendo ".$edge->label->name->id." with $rule_id\n";

	    $new_edge->add_to_location_from_edge($edge);
	    $self->add_edge($new_edge);
	} 
    }
}

# Se añade el edge a uno u otro repositorio
# el que se haga de uno u otro modo puede variar
# en función de que se use uno u otro algoritmo de
# parsing

sub add_edge {

    my $self = shift;
    my $edge = shift;

    $self->agenda->add_edge_in_stack($edge);
}

# Métodos de gestión de las condiciones
# de adyacencia. En función de que el 
# parser admita o no constituyentes dis-
# continuos, pueden ser unas u otras las
# condiciones

sub check_adyacence {

    my $self = shift;
    my $active_edge = shift;
    my $inactive_edge = shift;

    if ($self->scrambling) {

	$self->active_starts_first($active_edge,$inactive_edge) or return 0;
	$self->no_overlapping($active_edge,$inactive_edge) or return 0;
	$self->if_last_no_gaps($active_edge,$inactive_edge) or return 0;
	return 1;

    } else {

	(($active_edge->finish + 1) eq $inactive_edge->start) and return 1;
	return 0;
    }
}

sub active_starts_first {

    my $self = shift;
    my $active_edge = shift;
    my $inactive_edge = shift;

    $active_edge->start < $inactive_edge->start or return 0;

    return 1;
}

sub  no_overlapping {

    my $self = shift;
    my $active_edge = shift;
    my $inactive_edge = shift;

    foreach my $inactive_place ($inactive_edge->get_location_as_list) {

        if ($active_edge->get_location_by_place($inactive_place)) { return 0;}
    }

    return 1;
}


sub  if_last_no_gaps {

    my $self = shift;
    my $active_edge = shift;
    my $inactive_edge = shift;

    my $path = $self->grammar->get_globals('LAST');
    my $feat = $active_edge->first_to_find->get_feature_by_id($path); 
    $feat or return 1;
    $feat and ($feat->value->name->id eq 'cons') and return 1;

    (($active_edge->finish + 1) eq $inactive_edge->start) and return 1;

    return 0;
}

############### SALIDA

sub get_output {

    my $self = shift;

    foreach my $edge ($self->chart->get_inactive_edges_as_list) {

	$edge->covers_full_string($self->counter) and
	$self->is_axiom($edge)                    and 
        $self->agenda->add_edge_in_line($edge);
    }

    $self->print_trees();
}

sub print_trees {

    my $self = shift;
    my $ana = 0;

    while (my $result = $self->agenda->get_edge) {
	$ana++;
	Tree->new->print($result,$ana);
    }

    print STDERR  "\n$ana analysis.\n";
}

sub is_axiom {

    my $self = shift;
    my $edge = shift;

    foreach my $axiom_id ($self->grammar->get_axioms_as_list()) {

	my $axiom = $self->grammar->get_axiom_by_index($axiom_id)->clone;
	my $label = $edge->label->clone;
	$axiom->name($label->name); # 'root' no unifica con los signos normales

	$self->unification->unify_without_features($axiom,$label) and 
	return 1;
    }

    return 0;
}

sub new_token_on {

    my $self = shift;
    $NEW_TOKEN = 1;
}

sub new_token_off {

    my $self = shift;
    $NEW_TOKEN = 0;
}

sub new_token {

    my $self = shift;
    return $NEW_TOKEN;
}

sub counter {

    my $self = shift;
    return $COUNTER;
}

sub add_counter {

    my $self = shift;
    $COUNTER++;
    return $COUNTER;
}

sub start_counter {

    my $self = shift;
    $COUNTER = 0;
}

sub clear {

    my $self = shift;

    $self->chart->start_active_edges;
    $self->chart->start_inactive_edges;
    $self->agenda->start_edges;
}

1;
