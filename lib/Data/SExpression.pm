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
use Data::SExpression::Cons qw(cons consp scalarp);
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

Alists will only be folded if they are a list of conses, all of which
have scalars as both their C<car> and C<cdr> (See
L<Data::SExpression::Cons/scalar)

This option implies C<fold_lists>

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
    $value = $self->_fold_alists($value) if $self->get_fold_alists;

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

sub for_all(&@) {$_[0]() or return 0 foreach (@_[1..$#_]); 1;}

sub _fold_alists {
    my $self = shift;
    my $thing = shift;

    #Assume $thing has already been list-folded

    if(ref($thing) eq "ARRAY") {
        if( for_all {consp $_ && scalarp $_->car && scalarp $_->cdr} @{$thing} ) {
            return {map {$_->car => $_ -> cdr} @{$thing}};
        } else {
            return [map {$self->_fold_alists($_)} @{$thing}];
        }
    } elsif(consp $thing) {
        return cons($self->_fold_alists($thing->car),
                    $self->_fold_alists($thing->cdr));
    } else {
        return $thing;
    }
}

$grammar = q{

  sexpression:          number | symbol | string | list | <error>

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
