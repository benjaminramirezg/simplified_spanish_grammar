package state;
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
    $self->methods([]);
    return $self;

}

##############################
## métodos de acceso sencillos
##############################


sub name {      
                     
    my $self = shift;
    if ( @_ ) { $self->{name} = shift };
    return $self->{name};
}

# - Marcamos a un estado como final. 

sub final {      
                     
    my $self = shift;
    if ( @_ ) { $self->{final} = shift };
    return $self->{final};
}

sub initial {      
                     
    my $self = shift;
    if ( @_ ) { $self->{initial} = shift };
    return $self->{initial};
}

sub methods {      
                     
    my $self = shift;
    if ( @_ ) { $self->{methods} = shift };
    return $self->{methods};
}

##############################
## métodos de acceso complejos
##############################

sub get_methods_list {

    my $self = shift;
    return @{$self->methods};
}

sub append_method {

    my $self = shift;
    my $arc = shift;
    push @{$self->methods}, $arc;
}

1;
