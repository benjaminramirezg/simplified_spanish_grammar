package complex_token;

use warnings;
use strict;
use locale;
use Automata;
use arc;
use state;
use token;
use segment;
use text;
use Data::Dumper;

#############
# VARIABLES #
#############

my $SEGMENT;
### - USO DE LA CLASE: 

###    + Se necesitan las librerías 'Automata', 'arc', 'state', 'text', 'segment' y 'token'.

###    + Crear el autómata y colocarlo en la clave 'automata'. Téngase en cuenta que
###      este solo se inicia una vez por 'segment' (una vez identificado un elemento
###      complejo, no pasa automáticamente a INIT). Esto es útil para identificar el
###      inicio absoluto de oración en el reconocedor de nombres propios. Además, el
###      estado final no puede ser también estado de tránsito, pues en cuanto el autó-
###      mata entrada en estado inicial considera que ha encontrado el token complejo
###      completo. Por último, es importante introducir como método de estado el método
###      que guarda el identificador del token simple que ha de ser borrado si hay éxito.
###      Esto no se ha hecho directamente pues es posible que el autómata tenga que reconocer
###      tokens que no formen parte del token complejo resultante (condiciones de contexto). 

###    + Crear un método 'get_tag' que devuelva para cada token
###      de entrada una tag (conforme al autómata).

###    + Crear los métodos asociados a los estados del autómata.

##############
# Constructor
##############

sub new {

    my $class = shift;
    my $self = {};
    bless ( $self, $class );
    $self->simple_tokens_list([]);
    return $self;
}


####################
## métodos de acceso
####################

sub automata {       
                     
    my $self = shift;
    if ( @_ ) { $self->{automata} = shift };
    return $self->{automata};
}

sub tag {       
                     
    my $self = shift;
    if ( @_ ) { $self->{tag} = shift };
    return $self->{tag};
}

sub complex_token {       
                     
    my $self = shift;
    if ( @_ ) { $self->{complex_token} = shift };
    return $self->{complex_token};
}

sub simple_tokens_list {       
                     
    my $self = shift;
    if ( @_ ) { $self->{simple_tokens_list} = shift };
    return $self->{simple_tokens_list};
}

sub get_simple_tokens_list {

    my $self = shift;
    return @{$self->simple_tokens_list};
}

sub append_simple_token {

    my $self = shift;
    my $token = shift;

    push @{$self->simple_tokens_list}, $token->id;
}

sub pop_simple_token {

    my $self = shift;
    my $token = shift;
    pop @{$self->simple_tokens_list};
}


#####################
## Métodos complejos
#####################

sub get_tag {

    my $self = shift;
}

sub parse {

    my $self = shift;
    my $segment = shift;
    $SEGMENT = $segment;
    foreach my $token ( $segment->get_tokens_list ) {

	$self->tag($self->get_tag($segment->get_token_by_key($token)));

	$self->automata->parser($self->tag);

	if ($self->automata->success) {

	    $self->execute_state_methods($segment->get_token_by_key($token));

	} elsif ($self->automata->empty_flag) {

	    $self->execute_state_methods;
	    $self->automata->parser($self->tag);
	    $self->automata->success and 
	    $self->execute_state_methods($segment->get_token_by_key($token));
	}

	$self->automata->present_state->final and
	$self->manage_final_situation($segment);

	$self->automata->present_state->initial and
	$self->simple_tokens_list([]);

    }
    $self->automata->present_state($self->automata->get_state_by_key('INIT'));
    $self->simple_tokens_list([]);
}

sub manage_final_situation {

    my $self = shift;
    my $segment = $SEGMENT;

    foreach ( $self->get_simple_tokens_list ) {

	$segment->delete_token($segment->get_token_by_key($_));
    }

    $segment->append_token($self->complex_token);
    $self->simple_tokens_list([]);
}

sub execute_state_methods {

    my $self = shift;
    my $token = shift;

    foreach my $method ( $self->automata->present_state->get_methods_list ) {

	$self->$method($token); 	    
    }
}

1;
