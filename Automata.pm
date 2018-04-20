package Automata;
use warnings;
use strict;
use locale;
use arc;
use state;
use Data::Dumper;

###############
## Constructor
###############

sub new {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );

    $self->states({});
    $self->arcs([]);
    $self->empty_tag('_____');
    return $self;

}

##############################
## mÃ©todos de acceso sencillos
##############################

sub empty_flag {       
                     
    my $self = shift;
    if ( @_ ) { $self->{empty_flag} = shift };
    return $self->{empty_flag};
}

sub empty_tag {       
                     
    my $self = shift;
    if ( @_ ) { $self->{empty_tag} = shift };
    return $self->{empty_tag};
}

sub present_state {       
                     
    my $self = shift;
    if ( @_ ) { $self->{present_state} = shift };
    return $self->{present_state};
}

sub present_tag {       
                     
    my $self = shift;
    if ( @_ ) { $self->{tag} = shift };
    return $self->{tag};
}

sub states {       
                     
    my $self = shift;
    if ( @_ ) { $self->{states} = shift };
    return $self->{states};
}

sub arcs {       
                     
    my $self = shift;
    if ( @_ ) { $self->{arcs} = shift };
    return $self->{arcs};
}

sub success {       
                     
    my $self = shift;
    if ( @_ ) { $self->{success} = shift };
    return $self->{success};
}

sub tags_as_REGEXP {       
                     
    my $self = shift;
    if ( @_ ) { $self->{tags_as_REGEXP} = shift };
    return $self->{tags_as_REGEXP};
}

###############################
## mÃ©todos de acceso complejos
###############################

sub get_state_by_key {

    my $self = shift;
    my $key = shift;

    return $self->states->{$key};
}

sub get_arcs_list {

    my $self = shift;
    return @{$self->arcs};
}

sub append_state {

    my $self = shift;
    my $state = shift;
    my $name = $state->name;

    $self->states->{$name} = $state;
}

sub append_arc {

    my $self = shift;
    my $arc = shift;
    push @{$self->arcs}, $arc;
}

#################################
## Creamos autÃ³mata desde un hash
#################################

sub make_automata_from_hash {

    my $self = shift;
    my $hash = shift;

    foreach my $initial_state ( keys %{$hash} ) {

	my $state = state->new;
	$state->name("$initial_state");
	$self->append_state($state);

	foreach my $tag ( keys %{$hash->{$initial_state}} ) { 

	    my $final_state = $hash->{$initial_state}->{$tag};

	    my $arc = arc->new;
	    $arc->initial_state("$initial_state");
	    $arc->tag("$tag");
	    $arc->final_state("$final_state");
	    $self->append_arc($arc);
	}
    }
}

############
## parser ##
############

sub parser {

    my $self = shift;
    my $input_tag = shift;

    $self->empty_flag('0');
    $self->success('0');

    for my $arc ( $self->get_arcs_list ) {
	my $arc_tag = $arc->tag;

	if ( $arc->initial_state eq $self->present_state->name) {

	    if ($arc_tag eq $self->empty_tag) { 

		$self->empty_flag('1'); 
		$self->present_state($self->get_state_by_key($arc->final_state));
	    }

	    if ($input_tag =~ /^($arc_tag)$/ ) {

		$self->present_state($self->get_state_by_key($arc->final_state));
		$self->success('1');
		last;
	    }
	}
    }

    return 1; # Importante dar señal de que se ha ejecutado
}

1;
