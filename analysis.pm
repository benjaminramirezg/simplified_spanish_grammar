package analysis;
use warnings;
use strict;
use locale;
use rule;
use Data::Dumper;

### VARIABLES

my $rid = 1;

###############
## Constructor
###############

sub new {

    my $class = shift;
    my $self = {@_};
    bless ( $self, $class );
    $self->rules({});

    return $self;

}

##############################
## métodos de acceso sencillos
##############################

sub class {      
                     
    my $self = shift;
    if ( @_ ) { $self->{class} = shift };
    return $self->{class};
}


sub rules {      
                     
    my $self = shift;
    if ( @_ ) { $self->{rules} = shift };
    return $self->{rules};
}

sub stem {      
                     
    my $self = shift;
    if ( @_ ) { $self->{stem} = shift };
    return $self->{stem};
}

sub id {      
                     
    my $self = shift;
    if ( @_ ) { $self->{id} = shift };
    return $self->{id};
}

##############################
## métodos de acceso complejos
##############################

sub get_rules_list {

    my $self = shift;
    return sort { $a <=> $b } keys %{$self->rules};
}

sub get_rule_by_key {

    my $self = shift;
    my $key = shift;
    return $self->rules->{$key};
}

sub append_rule {

    my $self = shift;
    my $rule = shift;
    $rule->id($rid++);
    $self->rules->{$rule->id} = $rule;
}

sub delete_analysis {

    my $self = shift;
    my $rule = shift;

    delete $self->rules->{$rule->id};
}


1;
