package Tree;

use warnings;
use strict;
use locale;
use GraphViz;
use Data::Dumper;

#####################
# VARIABLES DE CLASE
##################### 

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

    return $self;
}

sub DESTROY {

    my $self = shift;
}

###########
# GET-SET #
###########

sub current_node {       
                     
    my $self = shift;
    if ( @_ ) { $self->{current_node} = shift; }
    return $self->{current_node};
}

sub graph {       
                     
    my $self = shift;
    if ( @_ ) { $self->{graph} = shift; }
    return $self->{graph};
}

######

sub print {

    my $self = shift;
    my $edge = shift;
    my $ANALYSIS = shift;
 
    $self->current_node('0');
    $self->create_graph($edge);
    $self->graph->as_png("./TREES/$ANALYSIS.png");
}

sub create_graph_aux {

    my $self = shift;
    my $mother_edge = shift;
    my $mother_node = $self->current_node;

    foreach my $daughter_edge ($mother_edge->get_found_as_list) {

	my $daughter_node = $self->create_node($daughter_edge);
	$self->graph->add_edge($mother_node => $self->current_node);
	$self->create_graph_aux($daughter_edge);
    }
}

sub create_graph {

    my $self = shift;
    my $edge = shift;

    $self->graph(GraphViz->new());
    $self->create_node($edge);
    $self->create_graph_aux($edge);
}

sub create_node {

    my $self = shift;
    my $edge = shift;

    my $n = $self->current_node;
    $n++;
    $self->current_node($n);

    my $name = $self->get_name($edge);
    my $cat = $self->get_cat($edge);
    my $per = $self->get_per($edge);
    my $num = $self->get_num($edge);
    my $case = $self->get_case($edge);

    $self->graph->add_node($n, label => "$cat\n$name\n$per $num $case");
}

sub get_cat {

    my $self = shift;
    my $edge = shift;
    my $feature = $edge->label->get_feature_by_id('SYNSEM#LOCAL#HEAD');

    if ($feature) { return " ".$feature->value->name->id; } else { return ''; }
}

sub get_per {

    my $self = shift;
    my $edge = shift;
    my $feature = $edge->label->get_feature_by_id('SYNSEM#LOCAL#AGR#PER');

    if ($feature) { return " ".$feature->value->name->id; } else { return ''; }
}

sub get_num {

    my $self = shift;
    my $edge = shift;
    my $feature = $edge->label->get_feature_by_id('SYNSEM#LOCAL#AGR#NUM');

    if ($feature) { return " ".$feature->value->name->id; } else { return ''; }
}

sub get_case {

    my $self = shift;
    my $edge = shift;
    my $feature = $edge->label->get_feature_by_id('SYNSEM#LOCAL#HEAD#CASE');

    if ($feature) { return " ".$feature->value->name->id; } else { return ''; }
}

sub get_name {

    my $self = shift;
    my $edge = shift;

    my $name = $edge->label->name->id;
    if ($name) { $name =~ s/-i?rule//; }
    if ($name) { return " ".$name; } else { return ''; }
}


1;
