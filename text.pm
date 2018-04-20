package text;
use warnings;
use strict;
use locale;
use Data::Dumper;

###############
## Constructor
###############

sub new {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );
    $self->segment({});
    return $self;
}

##############################
## métodos de acceso sencillos
##############################


sub segment {      
                     
    my $self = shift;
    if ( @_ ) { $self->{segment} = shift };
    return $self->{segment};
}

##############################
## métodos de acceso complejos
##############################

sub get_segments_list {

    my $self = shift;
    return sort { $a <=> $b } keys %{$self->segment};
}

sub get_segment_by_key {

    my $self = shift;
    my $key = shift;
    return $self->segment->{$key};
}

sub append_segment {

    my $self = shift;
    my $segment = shift;

    $self->segment->{$segment->id} = $segment;
}

sub delete_segment {

    my $self = shift;
    my $segment = shift;

    delete $self->segment->{$segment->id};
}

1;
