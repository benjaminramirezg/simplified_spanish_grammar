package segment;
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
    $self->token({});

    return $self;

}

##############################
## métodos de acceso sencillos
##############################


sub token {      
                     
    my $self = shift;
    if ( @_ ) { $self->{token} = shift };
    return $self->{token};
}

sub id {      
                     
    my $self = shift;
    if ( @_ ) { $self->{id} = shift };
    return $self->{id};
}

##############################
## métodos de acceso complejos
##############################

sub get_tokens_list {

    my $self = shift;
    return sort { $a <=> $b } keys %{$self->token};
}

sub get_token_by_key {

    my $self = shift;
    my $key = shift;
    return $self->token->{$key};
}

sub append_token {

    my $self = shift;
    my $token = shift;

    $self->token->{$token->id} = $token;
}

sub delete_token {

    my $self = shift;
    my $token = shift;

    delete $self->token->{$token->id};
}

1;
