package rule;
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

sub id {      
                     
    my $self = shift;
    if ( @_ ) { $self->{id} = shift };
    return $self->{id};
}
sub stem {      
                     
    my $self = shift;
    if ( @_ ) { $self->{stem} = shift };
    return $self->{stem};
}

sub form {      
                     
    my $self = shift;
    if ( @_ ) { $self->{form} = shift };
    return $self->{form};
}

sub class {      
                     
    my $self = shift;
    if ( @_ ) { $self->{class} = shift };
    return $self->{class};
}

1;
