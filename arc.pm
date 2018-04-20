package arc;
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

    return $self;

}

##############################
## métodos de acceso sencillos
##############################


sub initial_state {      
                     
    my $self = shift;
    if ( @_ ) { $self->{initial_state} = shift };
    return $self->{initial_state};
}

sub final_state {      
                     
    my $self = shift;
    if ( @_ ) { $self->{final_state} = shift };
    return $self->{final_state};
}

sub tag {       
                     
    my $self = shift;
    if ( @_ ) { $self->{tag} = shift };
    return $self->{tag};
}

1;
