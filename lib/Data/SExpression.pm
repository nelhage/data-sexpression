use warnings;
use strict;

our $VERSION = '0.0.1';

=head1 NAME

Data::SExpression -- Parse Lisp S-Expressions into perl data
structures.

=head1 DESCRIPTION

=cut

package Data::SExpression;

use base qw(Class::Accessor::Fast);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(parser));
__PACKAGE__->mk_accessors(qw(fold_lists fold_alists));

use Symbol;
use Parse::RecDescent;
use Data::SExpression::Cons;

my $grammar;

sub new {
    my $class = shift;
    my $args  = shift || {};

    $::RD_HINT = 1;
    #$::RD_TRACE = 1;
    
    my $parser = Parse::RecDescent->new($grammar);

    my $self = {
        fold_lists  => 1,
        fold_alists => 0,
        %$args,
        parser      => $parser,
       };
    return bless($self, $class);
}

sub read {
    my $self = shift;
    my $string = shift;
    my $value = $self->get_parser->sexpression($string);

    die("Parse error: ???") unless defined($value);

    return $value;
}

sub extract_string {
    my $str =  shift;
    $str = substr $str, 1, ((length $str)-2);

    $str =~ s/\\"/"/g;
    
    return $str;
}

$grammar = q{

  sexpression:          number | symbol | string | list

  # Scalar types

  number:               /[+-]?\\d+(?:[.]\\d*)?/

  symbol:               /[!\\$\\w-][!\\$\\w+-]*/     {$return = Symbol::qualify_to_ref($item[1],"main")} 

  string:               /".*?[^\\\\]"/               {$return = Data::SExpression::extract_string($item[1])}
                      | '""'                         {$return = ""}

  list:                 "(" list_interior ")"        {$return = $item[2]}

  list_interior:         sexpression list_interior   {$return = Data::SExpression::Cons->new($item[1], $item[2])}
                      | sexpression ... ")"          {$return = Data::SExpression::Cons->new($item[1], undef)}
                      | sexpression "." sexpression  {$return = Data::SExpression::Cons->new($item[1], $item[3])}

};

=head1 AUTHOR

Nelson Elhage <nelhage@mit.edu> 

=cut

1;
