package Tokenizer;

use warnings;
use strict;
use locale;
use XML::Simple;
use XML::XPath;
use XML::XPath::XMLParser;
use Encode 'encode';
use Encode 'encode', 'decode', 'is_utf8';
use Encode::Guess;
use segment;
use token;
use text;
use Automata;
use arc;
use state;
use DBI;
use IO::File;
use IO::Handle;
use Data::Dumper;
use complex_token;
use enamex;
use clitic;
use locutions;
use np_chunks;
use vp_chunks;
use left_periphery;
use silence_pron;
use special;
use analysis;
use rule;

#########################
## BASES DE DATOS LÉXICAS
#########################

my $dbh;


#####################
# VARIABLES DE CLASE
##################### 

# - Guardamos el número de tokens identificados para avisar por salida
# - de error mientras el proceso está en curso

my $counter;
my $cid; # identificador de caracter
my $tid; # identificador de token
my $sid; # identificador de segment
my $output;


my $GRAMMAR = token->new();
my $TOKEN   = $GRAMMAR->text_unit;
my $ABBR    = $GRAMMAR->abbr;
my $PUNCT  = $GRAMMAR->punct;
my $AMALGAMA = $GRAMMAR->amalgama;


############
## AUTÓMATA
############

# - Creamos un autómata. Le introducimos los estados y transiciones
# - mediante en forma de hash a través del método 'make_automata_from_hash'.

my $automata = Automata->new();

my $input = { 'CLOSED'    => {"punctx|punctc|punctcp"                                         => 'CLOSED',
                              "wordc|wordl|num|kk|abbrt|puncto|punctop|punctp|punctm"         => 'INIT',
                              "abbrg"                                                         => 'AMBIGUOUS' },
              'INIT'      => {"wordc|wordl|num|kk|puncto|punctp|punctop|punctm|punctcp|abbrt" => 'OPENED',
                              "abbrg|punctx"                                                  => 'AMBIGUOUS',
                              "punctc"                                                        => 'AMBIGUOUS' }, 
              'OPENED'    => {"wordc|wordl|num|kk|puncto|punctp|punctop|punctm|punctcp|abbrt" => 'OPENED',
                              "punctc"                                                        => 'CLOSED',
			      "punctx|abbrg"                                                  => 'AMBIGUOUS' },
              'AMBIGUOUS' => {"wordl|num|kk|abbrt|punctm"                                     => 'OPENED', 
                              "wordc|puncto|punctop|punctp"                                   => 'INIT', 
                              "punctcp|punctc"                                                => 'CLOSED',
		              "punctx|abbrg"                                                  => 'AMBIGUOUS' } 
};

# - !!! PROBLEMA que escapa a nuestro planteamiento!!! Cuando estamos en un estado ambiguo
# - (AMBIGUOUS o ABBR) y sigue un puncto, punctp o punctop, la ambigüedad persiste. No se deshace
# - hasta que aparece la primera palabra o número. Esto es un problema, porque estos signos de
# - puntuación, en caso de estar abriendo una nueva oración, pertenecerían a la oración nueva;
# - y en caso de no estar haciéndolo, a la antigua. De momento supongo que puncto, punctp y punctop 
# - siempre abren nueva oración. Esto trata mal casos como 'etc." -Y entonces...',
# - 'etc. ¿por qué' o 'etc. (porque'. Ocurre algo parecedo en un cambio de oración normal. Un 'punctp' no
# - sabemos si pertenece a una oración o a la siguiente. Tanto desde CLOSED como desde AMBIGUOUS, consideramos
# - que es parte de la siguiente oración... Esto requiere un autómata a pila...

$automata->make_automata_from_hash($input);
$automata->present_state($automata->get_state_by_key('INIT'));

# - Colocamos en cada estado del autómata el nombre de los métodos
# - de la clase Tokenizer que queremos ejecutar cuando el autómata
# - se encuentre en el estado en cuestión

# - Las oraciones comienzan desde el estado WHITE. Por tanto, cuando el autómata
# - se encuentre en este estado, crearemos una nueva oración: make_segment.
 
#$automata->get_state_by_key('WHITE')->append_method('make_segment');

# - Estado especial al que van los signos de puntuación a principio de oración

#$automata->get_state_by_key('OPENED_WHITE')->append_method('append_token');

# - En OPENED se crea el token que se acabe de procesar y se añade ala oración en
# - en que nos encontremos.

$automata->get_state_by_key('OPENED')->append_method('append_token');

# - En CLOSED se crea el token que se acabe de procesar: un signo de puntuación.

$automata->get_state_by_key('CLOSED')->append_method('append_token');

$automata->get_state_by_key('INIT')->append_method('make_segment');
$automata->get_state_by_key('INIT')->append_method('append_token');

# - En AMBIGUOUS se crea el token que se acabe de procesar: un signo de puntuación
# - ambiguo (?!) o una abreviatura.

$automata->get_state_by_key('AMBIGUOUS')->append_method('append_token');

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

    unless ( $self->input_file ) { $self->input_file('./'); }

    $self->automata($automata);

    return $self;
}

sub DESTROY {

    my $self = shift;
}


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

    $dbh->do("SET NAMES 'utf8';");
}

####################
# MÉTODOS DE ACCESO
####################

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


sub input_file {       
                     
    my $self = shift;
    if ( @_ ) { $self->{imput_file} = shift };
    return $self->{imput_file};
}

sub automata {       
                     
    my $self = shift;
    if ( @_ ) { $self->{automata} = shift };
    return $self->{automata};
}

# Aquí se guarda el sppp en texto plano

sub sppp {       
                     
    my $self = shift;
    if ( @_ ) { $self->{sppp} = shift };
    return $self->{sppp};
}

sub directory {       
                     
    my $self = shift;
    if ( @_ ) { $self->{directory} = shift };
    return $self->{directory};
}

# Para añadirle cosas.

sub add_to_sppp {       
                     
    my $self = shift;
    my $new = shift;
    my $old = $self->sppp;
    $self->sppp($old.$new);
}

##########################
## MÉTODO DE TOKENIZACIÓN
##########################

# - Este es el método que se usa desde fuera para iniciar la tokenización: lee el input
# - por líneas.

# - Identificamos mediante expresiones regulares los tokens que nos encontramos
# - en el texto. Seguimos una estrategia de 'longest match': primero abreviaturas,
# - luego nombres propios, por último, palabras, números kks y puntuación. 
# - Si pusiésemos los nombres propios antes de las abreviaturas, cualquier secuencia
# - Sr. sería nombre propio + punto. Y si pusiésemos las palabras antes de los nombres propios
# - nunca sería nombre propio Aranda de Duero ('de' siempre sería léxico común)

# - En principio, por cada token identificado se ejecuta el método de esta clase Tokenizer 
# - automata_parser. Este, a su vez ejecutará el método de parsing del autómata: . Se le pasa la etiqueta
# - apropiada en cada caso para que en función de esta el autómata cambie de estado.

# - Además, establecemos en cada caso el 'form' del token identificado, para que lo tengan 
# - a su disposición los métodos que se ejecutarán una vez movido el autómata.

# - Sobre esta situación general, hay ciertas cuestiones que comentar:
#           - Las abreviaturas, para ser identificadas como tal, tenemos que
#             tenerlas recogidas en el lexicón de abreviaturas (de otro modo,
#             cualquier palabra ante punto sería abreviatura).
#           - Los nombres propios se consideran ambiguos entre palabra capitalizada
#             a principio de oración y nombre propio. Por tanto, en vez de lanzar
#             el método de parsing, lanza un método de desambiguación. Este método,
#             una vez desambiguado el token, lanza el método de parsing apropiadamente.
#           - Los espacios se eliminan del input sin ningún impacto sobre el proceso salvo
#           - en un caso de importancia crucial: si estamos en estado CLOSED, un espacio
#             indica el inicio de una nueva oración. Solo en tal caso se ejecuta el método
#             de parsing. Téngase en cuenta que la primera parte del condicional se ejecuta
#             aunque no se cumpla la segunda.

# Se le ha podido pasar antes a la clase con input_file.
# Si no, se pasa ahora como argumento. 

# Se crea de entrada un elemento raíz

sub tokenize {

    my $self = shift;
    my $string = shift;       
    $output = text->new;
    $self->make_segment; 
    $automata->present_state($automata->get_state_by_key('INIT'));

    while ($string) {

	$string =~ s/^\s*($TOKEN)\s*// or $self->report_in_log($string);

	my $form = $1;

	if (ref(guess_encoding($form,'latin1'))) {

	    $form = encode('utf8',decode('latin1',$form));
	}

	my $token = $self->make_token($form);

	$token                                and
	$self->automata->parser($token->type) and
	$self->execute_state_methods($token);
    }
}

sub get_log_file {

    my $self = shift;

    unless ($self->directory) { die "En parser.pm falta el directorio general"; }

    return $self->directory."/log";
}


sub report_in_log {

    my $self = shift;
    my $string = shift;
    if ($string =~ /(....................).+/){ 
	$string =~ s/(....................).+/$1/; }
    my $message = "Tokenizer. Secuencia desconocida: $string";
    print $message . "\n";
    my $log = $self->get_log_file;
    open LOG, ">>$log" or die $!;
    print LOG $message . "\n";
    close LOG;
}

# Esta DB solo tienen una tabla 'abbr' con 'id' integer autoincrement,
# 'form' con varchar(50) uniq y class con 't' o 'g'.  

sub in_abbrt_db {

    my $self = shift;
    my $form = shift;

    my $sth=$dbh->prepare("SELECT form FROM form WHERE form='$form' and class='abbrt';");
    $sth->execute();    
    return $sth->fetchrow_array;
}

sub in_abbrg_db {

    my $self = shift;
    my $form = shift;

    my $sth=$dbh->prepare("SELECT form FROM form WHERE form='$form' and class='abbrg';");
    $sth->execute();    
    return $sth->fetchrow_array;
}


sub abbr {

    my $self = shift;
    my $form = shift;
    my $token;
    my @tokens;

    if    ($self->in_abbrt_db($form)) { $token = $self->make_token($form); $token->type('abbrt'); push @tokens, $token; }
    elsif ($self->in_abbrg_db($form)) { $token = $self->make_token($form); $token->type('abbrg'); push @tokens, $token; }
    else {

	while ($form) {
	    $form =~ s/^([^.]+)(\.)//; 
	    my ( $word, $dot ) = ( $1, $2 );   
	    $token = $self->make_token($word); push @tokens, $token;
	    $token = $self->make_token($dot);  push @tokens, $token;
	}
    }

    foreach my $token ( @tokens ) {

	$self->automata->parser($token->type);
	$self->execute_state_methods($token);
    }

    return 1;
}

sub amalgama {

    my $self = shift;
    my $form = shift;
    my $token;
    my @tokens;

    $form =~ /^(de|a|De|A)(l)$/; 
    my $prep = $1;   
    $token = $self->make_token($prep); push @tokens, $token;
    $token = $self->make_token("el");  push @tokens, $token;

    foreach my $token ( @tokens ) {

	$self->automata->parser($token->type);
	$self->execute_state_methods($token);
    }

    return 1;
}


sub punct {

    my $self = shift;
    my $form = shift;

    my $token = token->new();
    $token->form($form);
    $token->type;
    $self->automata->parser($token->type);
    $self->execute_state_methods($token);
# Lo propio de este método es que no se ejecutan los
# métodos del estado. No se añade un token

    $self->add_punct_analysis($token);
    $self->update_location($token);
    return 1;
}


sub add_punct_analysis {

    my $self = shift;
    my $token = shift;
    my $analysis = analysis->new();
    $analysis->stem('***PUNCT***');
    $token->append_analysis($analysis);
}

sub locutions {

    my $self = shift;
    my $LOC = $self->get_locutions;
    my $locutions = locutions->new();
    $locutions->locutions($LOC);

    foreach my $segment ( $output->get_segments_list ) {

	$locutions->parse($output->get_segment_by_key($segment));
    }
}

sub get_locutions {

    my $self = shift;
    my $LOC = {};

    my $sth=$dbh->prepare("SELECT form, lemma, rule, class FROM form WHERE form regexp ' ' ;");
    $sth->execute();    

    while (my ($form,$lemma,$rule,$class) = $sth->fetchrow_array) {

	$LOC->{$form}->{'lemma'} = $lemma;
	$LOC->{$form}->{'rule'} = $rule;
	$LOC->{$form}->{'class'} = $class;
    }

    return $LOC;
}

sub comp_chunks {

    my $self = shift;
    my $comp_chunks = comp_chunks->new();

    foreach my $segment ( $output->get_segments_list ) {

	$comp_chunks->parse($output->get_segment_by_key($segment));
    }
}

sub np_chunks {

    my $self = shift;
    my $np_chunks = np_chunks->new();

    foreach my $segment ( $output->get_segments_list ) {

	$np_chunks->parse($output->get_segment_by_key($segment));
    }
}

sub vp_chunks {

    my $self = shift;
    my $vp_chunks = vp_chunks->new();
    
    foreach my $segment ( $output->get_segments_list ) {

	$vp_chunks->parse($output->get_segment_by_key($segment));
    }
}


sub special {

    my $self = shift;
    my $special = special->new();

    foreach my $segment ( $output->get_segments_list ) {

	$special->parse($output->get_segment_by_key($segment));
    }
}


sub enamex {

    my $self = shift;
    my $enamex = enamex->new();
    $counter = 0;

    foreach my $segment ( $output->get_segments_list ) {

	$enamex->parse($output->get_segment_by_key($segment));
    }
}

sub clitic {

    my $self = shift;
    my $clitic = clitic->new();
    $counter = 0;

    foreach my $segment ( $output->get_segments_list ) {

	$clitic->parse($output->get_segment_by_key($segment));
    }
}

sub left_periphery {

    my $self = shift;
    my $left_periphery = left_periphery->new();

    foreach my $segment ( $output->get_segments_list ) {

	$left_periphery->parse($output->get_segment_by_key($segment));
    }
}

sub silence_pron {

    my $self = shift;
    my $silence_pron = silence_pron->new();

    foreach my $segment_key ( $output->get_segments_list ) {

	my $segment = $output->get_segment_by_key($segment_key);
	$silence_pron->current_segment($segment);
	$silence_pron->parse($segment);
    }
}


#####################
## MÉTODOS DE SALIDA
#####################

sub return_sppp {

    my $self = shift;

    $self->sppp('');
    $self->add_to_sppp("<?xml version='1.0' encoding='utf-8'?>\n<text>\n");
    $self->return_sppp_segments;
    $self->add_to_sppp("</text>\n");
    return $self->sppp;
}

sub return_sppp_segments {

    my $self = shift;

    foreach ( $output->get_segments_list ) {

	my $segment = $output->get_segment_by_key($_);

	$self->add_to_sppp('<segment>'."\n");
	$self->return_sppp_tokens($segment);
	$self->add_to_sppp('</segment>'."\n");
    }
}
    

sub return_sppp_tokens {

    my $self = shift;
    my $segment = shift;

    foreach ( $segment->get_tokens_list ) {

	my $token = $segment->get_token_by_key($_);
	my $form = $token->form;
	my $from = $token->from;
	my $to = $token->to;

	$self->add_to_sppp("<token form=\"$form\" from=\"$from\" to=\"$to\">\n");
	$self->return_sppp_analysis($token);
	$self->add_to_sppp('</token>'."\n");
    }
}


sub return_sppp_analysis {

    my $self = shift;
    my $token = shift;

    foreach ( $token->get_analysis_list ) {

	my $analysis = $token->get_analysis_by_key($_);
	my $stem = $analysis->stem;

	$self->add_to_sppp("<analysis stem=\"$stem\">\n");
	$self->return_sppp_rule($analysis,$token->form);
	$self->add_to_sppp('</analysis>'."\n");
    }
}

sub return_sppp_rule {

    my $self = shift;
    my $analysis = shift;
    my $form = shift;

    foreach ( $analysis->get_rules_list ) {
	
	my $rule = $analysis->get_rule_by_key($_);
	my $id = $rule->stem;
	my $class = $rule->class;
	unless ($class) { $class = 'irule'; }
	$self->add_to_sppp("<rule class=\"$class\" id=\"$id\" form=\"$form\"/>\n");
    }
}

#############################################
## MÉTODOS DE UTILIDAD INTERIOR A LA CLASE ##
#############################################

# - Creación del token a partir de la 'form' obtenida del parsing
# - de la string.

sub get_analysis_from_DB {

    my $self = shift;
    my $form = shift;
    my $out = {};

    my $sth=$dbh->prepare("SELECT lemma, rule, clitic, class 
                               FROM form WHERE form='$form' ;");
    $sth->execute();
    
    while (my ($lemma,$rule,$clitic,$class) = $sth->fetchrow_array) {

	unless (defined $out->{$lemma}) { $out->{$lemma} = []; } 
	my $analysis = {};
	$analysis->{'rule'} = $rule;
	$analysis->{'clitic'} = $clitic;
	$analysis->{'class'} = $class;
	push @{$out->{$lemma}}, $analysis;
    }
    return $out;
}

sub get_analysis_DB_lemmas {

    my $self = shift;
    my $hash = shift;
    
    return keys %{$hash};
}

sub get_analysis_DB_by_lemma_as_list {

    my $self = shift;
    my $hash = shift;
    my $lemma = shift;
    
    return @{$hash->{$lemma}};
}


sub get_analysis_DB_rule {

    my $self = shift;
    my $hash = shift;

    return $hash->{'rule'};
}


sub get_analysis_DB_class {

    my $self = shift;
    my $hash = shift;

    return $hash->{'class'};
}

sub get_analysis_DB_clitic {

    my $self = shift;
    my $hash = shift;
    my $lemma = shift;

    return $hash->{'clitic'};
}

sub is_punct {

    my $self = shift;
    my $form = shift;

    if ($form =~ /^$PUNCT$/) { return 1; } 
    return 0;
}


sub is_abbr {

    my $self = shift;
    my $form = shift;

    if ($form =~ /^$ABBR$/) { return 1; } 
    return 0;
}


sub is_amalgama {

    my $self = shift;
    my $form = shift;

    if ($form =~ /^$AMALGAMA$/) { return 1; } 
    return 0;
}

# De momento se obvian los signos de puntuación

sub make_token {

    my $self = shift;
    my $form = shift;

# Casos excepcionales

    $self->is_punct($form)    and $self->punct($form) and return 0;
    $self->is_abbr($form)     and $self->abbr($form) and return 0;
    $self->is_amalgama($form) and $self->amalgama($form) and return 0;

    my $token = token->new; 
    $token->form($form); 
    $token->type; # Calcuda, de 'form', el tipo
    $self->make_token_aux($form,$token);

    unless ($self->is_known($token)) { $self->add_unknown_analysis($token);}

    $self->update_location($token);
    return $token;
}

sub make_token_aux {

    my $self = shift;
    my $form = shift;
    my $token = shift;

    my $uncap_form = $self->uncapitalize_form($form);
    my $analysis_DB_set = $self->get_analysis_from_DB($uncap_form);

    foreach my $lemma ($self->get_analysis_DB_lemmas($analysis_DB_set)) {

	$self->create_analysis_in_token($lemma,$analysis_DB_set,$token);
    }
}

sub create_analysis_in_token {

    my $self = shift;
    my $lemma = shift;
    my $analysis_DB_set = shift;
    my $token = shift;

    foreach my $ana ($self->get_analysis_DB_by_lemma_as_list($analysis_DB_set,$lemma)) {

	my $rule_name = $self->get_analysis_DB_rule($ana);
	my $clitic = $self->get_analysis_DB_clitic($ana);
	my $class = $self->get_analysis_DB_class($ana);

	my $analysis = analysis->new;
	$analysis->stem($lemma);
	$analysis->class($class);
	my $rule = rule->new;
	$rule->stem($rule_name);
	$analysis->append_rule($rule);
	$self->add_clitic_rule($analysis,$clitic);
	$token->append_analysis($analysis);
    }
}

sub is_known {

    my $self = shift;
    my $token = shift;

    if ($self->is_punct($token->form)) { return 1; } 
    return $token->get_analysis_list;
}

sub add_unknown_analysis {

    my $self = shift;
    my $token = shift;

    my $analysis = analysis->new;
    $analysis->stem('***UNKNOWN***');
    my $rule = rule->new;
    $rule->stem('unknown-irule');
    $analysis->append_rule($rule);
    $token->append_analysis($analysis);
}

sub update_location {

    my $self = shift;
    my $token = shift;

    unless ($self->is_punct($token->form)) { $cid++; }
    $token->from($cid++);
    $token->to($self->count_characters($token->form));
}

# - Método para añadir la regla de clíticos.

sub add_clitic_rule {

    my $self = shift;
    my $analysis = shift;
    my $clitic = shift;

    unless ($clitic) { return 0; }
    if ($clitic eq 'NULL') { return 0; }

    my $rule = rule->new;
    $rule->stem($clitic);
    $analysis->append_rule($rule);
    return 1;
}

# - Método que ejecuta los métodos presentes en el estado actual del autómata

sub execute_state_methods {

    my $self = shift;
    my $token = shift;

    foreach my $method ( $self->automata->present_state->get_methods_list ) {

	$self->$method($token); 	    
    }
}


# - Creamos un segmento y, directamente lo sumamos al texto tokenizado

sub make_segment {

    my $self = shift;
    my $segment = segment->new();

#    $cid = '-2';  No hay razón para poner a cero el número de caracteres al empezar segmento
    $sid++;
    $tid = 0;
    $segment->id($sid);
    $output->append_segment($segment);
}



# - Creamos un nuevo token y lo sumamos al segmento actual que será de la clase
# - que indique la etiqueta actual del Autómata. Modificamos mínimamente algunas
# - etiquetas para crear el token, pues sus clases tienen nombres más sencillos (word
# - y no wordl/wordc, punct y no punct_close/punct_non_close).

sub append_token {

    my $self = shift;
    my $token = shift;
    $tid++;
    $token->id($tid);
    $output->get_segment_by_key($sid)->append_token($token);
}

sub counter {

    my $self = shift;
    my $message = shift;
    $counter++;
    print STDERR "$counter $message\r";
}


sub count_characters {

    my $self = shift;
    my $form = shift;

    while ( $form =~ /./g ) {

	$cid++;
    }
# Problema con LKB: se obvian los tokens cuyos 'from' y 'to'
# son idénticos... Solución provisional:

    if ( $form =~ /^([[:alpha:]])$/ ) { $cid++; }

    return $cid;
}


sub check_file {

    my $self = shift;
    my $method = shift;

    my $fh = IO::File->new;
    die "No se encuentra " . $self->$method . "\n" unless $fh->open("< " . $self->$method);
    $fh->close;
}


sub uncapitalize_form {       
                     
    my $self = shift;
    my $form = shift;
    $form =~ tr/[A-Z]|Ñ|Á|É|Í|Ó|Ú|Ü)/[a-z]|ñ|á|é|í|ó|ú|ü/;
    return $form;
}

############### => TO IMPROVE

# - La salida debería integrarse en el método de tokenización.

############### CERRAR BASE DE DATOS

sub close_DB {

    my $self = shift;
    $dbh->disconnect || die "Failed to disconnect\n";
}


1;
