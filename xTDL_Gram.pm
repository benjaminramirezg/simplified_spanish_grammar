package TDL_Gram;

use warnings;
use strict;
use locale;
use xchart;

#####################
# VARIABLES DE CLASE
##################### 

my $CORE = qr/(?:(?:[[:alnum:]]|'|_|-|\*|\+)+)/;
my $STRING = qr/\"$CORE(?:\s+$CORE)*\"/;
my $NAME = qr/(?:$CORE|$STRING)/;
my $OPEN = qr/\[/;
my $CLOSE = qr/\]/;
my $SUM = qr/\&/;
my $IMPLICATION = qr/:=/;
my $COMMA = qr/,/;
my $DOT = qr/\./;
my $SHARING = qr/(?:#(?:[[:alnum:]]|_|-|\*|\+)+)/;
my $DOTS = qr/(?:$NAME$DOT)+$NAME/;
my $ADD = qr/:+/;
my $DISY = qr/\|/;

# - ER ESTRATÉGICAS

# - Es importante que $DOTS vaya antes de $NAME y $STRING, pues lo incluye
# - Es importante que $STRING vaya antes de $NAME, pues lo incluye

my $TEXT_UNIT = qr/$DOTS|$NAME|$OPEN|$CLOSE|$COMMA|$SUM|$SHARING|$DOT|$IMPLICATION|$ADD|$DISY/;

my %text_unit = (  'name'         => "$NAME",
		   'sum'          => "$SUM",
		   'open'         => "$OPEN",
		   'close'        => "$CLOSE",
		   'comma'        => "$COMMA",
		   'dot'          => "$DOT",
		   'sum'          => "$SUM",
		   'sharing'      => "$SHARING",
		   'implication'  => "$IMPLICATION",
                   'dots'         => "$DOTS",
                   'add'          => "$ADD",
                   'disy'         => "$DISY");

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

    $self->name($NAME);
    $self->implication($IMPLICATION);
    $self->sum($SUM);
    $self->open($OPEN);
    $self->sharing($SHARING);
    $self->comma($COMMA);
    $self->close($CLOSE);
    $self->dot($DOT);
    $self->dots($DOTS);
    $self->add($ADD);
    $self->disy($DISY);
    $self->text_unit($TEXT_UNIT);

    return $self;
}

sub DESTROY {

    my $self = shift;
}

####################
# MÉTODOS DE ACCESO
####################

sub name {       
                     
    my $self = shift;
    if ( @_ ) { $self->{name} = shift };
    return $self->{name};
}

sub implication {       
                     
    my $self = shift;
    if ( @_ ) { $self->{implication} = shift };
    return $self->{implication};
}

sub sum {       
                     
    my $self = shift;
    if ( @_ ) { $self->{sum} = shift };
    return $self->{sum};
}


sub open {       
                     
    my $self = shift;
    if ( @_ ) { $self->{open} = shift };
    return $self->{open};
}


sub sharing {       
                     
    my $self = shift;
    if ( @_ ) { $self->{sharing} = shift };
    return $self->{sharing};
}


sub comma {       
                     
    my $self = shift;
    if ( @_ ) { $self->{comma} = shift };
    return $self->{comma};
}


sub close {       
                     
    my $self = shift;
    if ( @_ ) { $self->{close} = shift };
    return $self->{close};
}


sub dot {       
                     
    my $self = shift;
    if ( @_ ) { $self->{dot} = shift };
    return $self->{dot};
}

sub dots {       
                     
    my $self = shift;
    if ( @_ ) { $self->{dots} = shift };
    return $self->{dots};
}

sub add {       
                     
    my $self = shift;
    if ( @_ ) { $self->{add} = shift };
    return $self->{add};
}


sub disy {       
                     
    my $self = shift;
    if ( @_ ) { $self->{disy} = shift };
    return $self->{disy};
}

sub text_unit {       
                     
    my $self = shift;
    if ( @_ ) { $self->{text_unit} = shift };
    return $self->{text_unit};
}


###############

sub type {       
                     
    my $self = shift;
    my $form = shift;

    foreach my $tag ( keys %text_unit ) {

	my $regexp = $text_unit{$tag};
	
	$form =~ /^$regexp$/ and return $tag;
    }
}


1;
