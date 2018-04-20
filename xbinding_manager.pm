package xbinding_manager;

use warnings;
use strict;
use locale;
use xsharing;
use xfeature;

#############
# VARIABLES #
#############

###############
# CONSTRUCTOR #
###############

sub new () {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->patterns({});
    $self->edges([]);
    $self->semOBJ({});

    return $self;
}

sub DESTROY {

    my $self = shift;
}

###############
### GET-SET ###
###############

## REPOSITORIO DE SHARINGS DEL TARGET

sub patterns {       
                     
    my $self = shift;
    if ( @_ ) { $self->{patterns} = shift };
    return $self->{patterns};
}


sub edges {       
                     
    my $self = shift;
    if ( @_ ) { $self->{edges} = shift };
    return $self->{edges};
}

sub semOBJ {       
                     
    my $self = shift;
    if ( @_ ) { $self->{semOBJ} = shift };
    return $self->{semOBJ};
}

sub path {       
                     
    my $self = shift;
    if ( @_ ) { $self->{path} = shift };
    return $self->{path};
}

sub current_semOBJ {       
                     
    my $self = shift;
    if ( @_ ) { $self->{current_semOBJ} = shift };
    return $self->{current_semOBJ};
}


## PONEN A CERO LOS REPOSITORIOS

## Se aplican por cada unificación

sub start_patterns {

    my $self = shift;
    $self->edges({});
}

sub add_pattern {

    my $self = shift;
    my $edge = shift;

    my $name_id = $edge->label->name->id;
    $self->patterns->{$name_id} = $edge;
}

sub start_edges {

    my $self = shift;
    $self->edges([]);
}

sub add_edge {

    my $self = shift;
    my $edge = shift;

    push @{$self->edges}, $edge;
}

sub get_semOBJ_as_list {

    my $self = shift;

    return keys %{$self->semOBJ};
}

sub isNP {

    my $self = shift;
    my $edge = shift;
    my $path = shift;

    my $feature = $edge->label->get_feature_by_id($path);
    my $name_id = $feature->value->name->id;

    foreach my $semOBJ ($self->get_semOBJ_as_list) {

	($name_id eq $semOBJ) and return  
	$self->current_semOBJ($semOBJ);
    }

    return 0;
}

sub values {

    my $self = shift;
    my $values = shift;
    
    foreach my $value (split '#', $values) {
	
	$self->semOBJ->{$value} = 1;
    }
}

1;
