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
__PACKAGE__->mk_ro_accessors(qw(parser fold_lists fold_alists));

use Symbol;
use Parse::RecDescent;
use Data::SExpression::Cons qw(consp);
use Carp qw(croak);

my $grammar;

=head2 new [\%args]

Returns a new Data::SExpression object. Possibly args are:

=over 4

=item fold_lists

If true, fold lisp lists (e.g. "(1 2 3)") into Perl listrefs, e.g. [1, 2, 3]

=item fold_alists

If true, fold lisp alists into perl hashrefs. e.g.

"((fg . red) (bg . black) (weight . bold))"

would become

{
    \*fg       => \*red,
    \*bg       => \*black,
    \*weight   => \*bold
}

Implies C<fold_lists>

=back

=cut

sub new {
    my $class = shift;
    my $args  = shift || {};

    $::RD_HINT = 1;
    #$::RD_TRACE = 1;
    
    my $parser = Parse::RecDescent->new($grammar);

    $args->{fold_lists} = 1 if $args->{fold_alists};

    my $self = {
        fold_lists  => 1,
        fold_alists => 0,
        %$args,
        parser      => $parser,
       };
    return bless($self, $class);
}

=head2 read STRING

Returns the parsed SExpression from STRING, or dies with an error if
the parse fails.

=cut

sub read {
    my $self = shift;
    my $string = shift;
    my $value = $self->get_parser->sexpression($string);

    croak("SExp Parse error") unless defined($value);

    $value = $self->_fold_lists($value) if $self->get_fold_lists;

    return $value;
}

=head2 extract_string STRING

Internal use only.

=cut

sub extract_string {
    my $str =  shift;
    $str = substr $str, 1, ((length $str)-2);

    $str =~ s/\\"/"/g;
    
    return $str;
}

sub _fold_lists {
    my $self = shift;
    my $thing = shift;

    if(consp $thing) {
        # Recursively fold 
        $thing->set_car($self->_fold_lists($thing->car));
        $thing->set_cdr($self->_fold_lists($thing->cdr));

        if(ref($thing->cdr) eq "ARRAY") {
            my $array = $thing->cdr;
            unshift @{$thing->cdr}, $thing->car;
            return $array;
        } elsif (!defined($thing->cdr)) {
            return [$thing->car];
        }
    }

    return $thing;
}

$grammar = q{

  sexpression:          number | symbol | string | list

  # Scalar types

  number:               /[+-]?\\d+(?:[.]\\d*)?/

  symbol:               /[!\\$\\w-][!\\$\\w+-]*/     {$return = Symbol::qualify_to_ref($item[1],"main")} 

  string:               /".*?[^\\\\]"/               {$return = Data::SExpression::extract_string($item[1])}
                      | '""'                         {$return = ""}

  list:                 "(" list_interior ")"        {$return = $item[2]}

  list_interior:        sexpression list_interior    {$return = Data::SExpression::Cons->new($item[1], $item[2])}
                      | sexpression ... ")"          {$return = Data::SExpression::Cons->new($item[1], undef)}
                      | sexpression "." sexpression  {$return = Data::SExpression::Cons->new($item[1], $item[3])}

};

=head1 AUTHOR

Nelson Elhage <nelhage@mit.edu> 

=cut

1;
