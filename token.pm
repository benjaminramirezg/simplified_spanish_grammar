package token;
use warnings;
use strict;
use locale;
use analysis;
use Data::Dumper;

###
# - Variable de identificador de análisis
###

my $anaid = 0;

##################################
# GRAMÁTICA DE UNIDADES TEXTUALES
##################################


###########
# Núcleos.
###########


# - Alfabéticos.

my $COREl = qr/(?:[[:lower:]]|ñ|á|é|í|ó|ú|ü)+/; 
my $COREc = qr/(?:[[:upper:]]|Ñ|Á|É|Í|Ó|Ú|Ü)(?:[[:lower:]]|ñ|á|é|í|ó|ú|ü)*/; 
my $COREu = qr/(?:[[:upper:]]|Ñ|Á|É|Í|Ó|Ú|Ü)+/; 

# - Combinaciones alfanuméricas y de símbolos.

my $COREan = qr/(?:(?:[[:alpha:]]|Ñ|Á|É|Í|Ó|Ú|Ü|ñ|á|é|í|ó|ú|ü)|[[:digit:]])+/; 
my $COREs = qr/[@#$%&\/{}\[\]\\~<>°ºª—ｯ―=+*|±×·_^]+/; 
my $COREans = qr/(?:$COREan|$COREs)+/; 

# - Numéricos.

my $COREn = qr/[[:digit:]]+/;
my $COREnf = qr/$COREn(?:(?:\.|,)$COREn)+/;


##################
# Unidades básicas.
##################


# - Palabras.

my $WORDl = qr/$COREl(?=[[:punct:]]*(?:\s|$))/;
my $WORDc = qr/$COREc(?=[[:punct:]]*(?:\s|$))/;
my $WORDu = qr/$COREu(?=[[:punct:]]*(?:\s|$))/;
my $WORDhl = qr/$COREl(?:-$COREl)+/;
my $WORDhc = qr/$COREc(?:-(?:$COREc|$COREl))+(?=[[:punct:]]*(?:\s|$))/;

my $WORD = qr/$WORDl|$WORDc|$WORDu|$WORDhl|$WORDhc/;

# - Números.

my $NUMn = qr/$COREn(?=[[:punct:]]*(?:\s|$))/;
my $NUMf = qr/$COREnf(?=[[:punct:]]*(?:\s|$))/;
my $NUMpc= qr/(?:$COREn|$COREnf)%(?=[[:punct:]]*(?:\s|$))/;
my $NUMs = qr/(?:\+|-)(?:$COREn|$COREnf)(?=[[:punct:]]*(?:\s|$))/;
my $NUMr = qr/(?:$COREn|$COREnf)\/(?:$COREn|$COREnf)(?=[[:punct:]]*(?:\s|$))/;

my $NUM = qr/$NUMn|$NUMf|$NUMpc|$NUMs|$NUMr/;

# - KKs.

my $KK = qr/$COREans[^\s]*$COREans|$COREs(?=[[:punct:]]*(?:\s|$))/;


####################
# Unidades complejas.
####################


# - Enamex.

my $apstr_Enamex = qr/(?:[[:alpha:]]|Ñ|Á|É|Í|Ó|Ú|Ü|ñ|á|é|í|ó|ú|ü)'$WORDc/;
my $nexus = qr/(?:(?:de(?:\s+el|la|los|las)?)|(?:del))/;

my $Enamex_simple = qr/$WORDhc|$apstr_Enamex|$WORDc/;
my $Enamex_complex = qr/$Enamex_simple(?:\s+$Enamex_simple)+/;
my $Enamex_nexus = qr/(?:$Enamex_simple\s+)+$nexus(?:\s+$Enamex_simple)+/;

my $ENAMEX = qr/$Enamex_nexus|$Enamex_complex|$Enamex_simple/;


##############
# Puntuación.
##############

my $PUNCTx = qr/[?!:]/;
my $PUNCTo = qr/[¿¡]/;
my $PUNCTc = qr/[.]/;
my $PUNCTp = qr/["'-]/;
my $PUNCTop = qr/[(«]/;
my $PUNCTcp = qr/[)»]/;
my $PUNCTm = qr/[,;]/;

my $PUNCT = qr/$PUNCTx|$PUNCTo|$PUNCTc|$PUNCTm|$PUNCTp|$PUNCTop|$PUNCTcp/;

###############
# Abreviaturas.
###############

# - Solo recojo abreviaturas simples. Las complejas que se creen en un módulo.

my $ABBR = qr/(?:[[:alpha:]]+\.)(?![[:punct:]]*(?:\s|$))/;


# - ER ESTRATÉGICAS

my $AMALGAMA = qr/([Dd]e|[Aa])l/;

my $TEXT_UNIT = qr/$ABBR|$WORDl|$WORDc|$PUNCTx|$PUNCTo|$PUNCTc|$PUNCTm|$PUNCTp|$PUNCTop|$PUNCTcp|$NUM|$KK/;

my %text_unit = (  'abbr'    => "$ABBR",
		   'wordl'   => "$WORDl",
		   'wordc'   => "$WORDc",
		   'punctx'  => "$PUNCTx",
		   'puncto'  => "$PUNCTo",
		   'punctc'  => "$PUNCTc",
		   'punctm'  => "$PUNCTm",
		   'punctp'  => "$PUNCTp",
		   'punctop' => "$PUNCTop",
		   'punctcp' => "$PUNCTcp",
		   'num'     => "$NUM",
		   'kk'      => "$KK"  );

###############
## Constructor
###############

sub new {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );
    $self->analysis({});
    return $self;

}

##############################
## métodos de acceso sencillos
##############################


sub form {       
                     
    my $self = shift;
    if ( @_ ) { $self->{form} = shift };
    return $self->{form};
}

sub from {       
                     
    my $self = shift;
    if ( @_ ) { $self->{from} = shift };
    return $self->{from};
}

sub to {       
                     
    my $self = shift;
    if ( @_ ) { $self->{to} = shift };
    return $self->{to};
}

sub id {      
                     
    my $self = shift;
    if ( @_ ) { $self->{id} = shift };
    return $self->{id};
}

sub type {       
                     
    my $self = shift;
    if ( @_ ) { $self->{type} = shift };
    unless ($self->{type}) { $self->type_aux;}
    return $self->{type};
}


sub analysis {       
                     
    my $self = shift;
    if ( @_ ) { $self->{analysis} = shift };
    return $self->{analysis};
}

####

sub type_aux {

    my $self = shift;
    my $form = $self->form;

    foreach (keys %text_unit) {

	my $regexp = $text_unit{$_};
	if ($form =~ /^$regexp$/) {$self->{type} = $_; last;}
    }

    unless ($self->{type}) {print STDERR "TIPO DESCONOCIDO: ".$self->form."\n";}
}


##################################
## destructor de claves del objeto
##################################

# - Para ciertos formatos, no se admiten claves determinadas.
# - Por ejemplo, en 'sppp',  no existe 'type' y hay que quitarlo
# - antes de convertirlo en XML.

sub delete_key {

    my $self = shift;
    my $key = shift;

    delete $self->{$key};
}

# - Actualizador.

sub update_token {

    my $self = shift;
    my $input = shift; 

    for my $attribute ( keys %$input ) {

	$self->$attribute( $input->{$attribute} );
    }
}

################################################
## MÉTODOS DE ACCESO A LAS EXPRESIONES REGULARES
################################################

sub wordl {       
                     
    my $self = shift;
    return $WORDl;
}

sub wordc {       
                     
    my $self = shift;
    return $WORDc;
}

sub word {       
                     
    my $self = shift;
    return $WORD;
}

sub num {       
                     
    my $self = shift;
    return $NUM;
}

sub kk {       
                     
    my $self = shift;
    return $KK;
}

sub enamex {       
                     
    my $self = shift;
    return $ENAMEX;
}

sub punct {       
                     
    my $self = shift;
    return $PUNCT;
}

sub abbr {       
                     
    my $self = shift;
    return $ABBR;
}

sub text_unit {       
                     
    my $self = shift;
    return $TEXT_UNIT;
}

sub amalgama {       
                     
    my $self = shift;
    return $AMALGAMA;
}

##############################
## mÃ©todos de acceso complejos
##############################


sub get_analysis_list {

    my $self = shift;
    return keys %{$self->analysis};
}

sub get_analysis_by_key {

    my $self = shift;
    my $key = shift;
    return $self->analysis->{$key};
}

sub append_analysis {

    my $self = shift;
    my $analysis = shift;
    $analysis->id($anaid++);
    $self->analysis->{$analysis->id} = $analysis;
}

sub delete_analysis {

    my $self = shift;
    my $analysis = shift;

    delete $self->analysis->{$analysis->id};
}

1;
