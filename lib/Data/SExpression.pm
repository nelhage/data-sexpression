use warnings;
use strict;

our $VERSION = '0.1.0';

=head1 NAME

Data::SExpression -- Parse Lisp S-Expressions into perl data
structures.

=head1 SYNOPSIS

    use Data::SExpression;

    my $ds = Data::SExpression->new;

    $ds->read("(foo bar baz)");          # [\*::foo, \*::bar, \*::baz]

    my @sexps;
    my $sexp;
    while(1) {
        eval {
            ($sexp, $text) = $ds->read($text);
        };
        last if $@;
        push @sexps, $sexp;
    }

    $ds = Data::SExpression->new(fold_alists => 1);

    $ds->read("((top . 4) (left . 5)");  # {\*::top => 4, \*::left => 5}

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

=head1 METHODS

=head2 new [\%args]

Returns a new Data::SExpression object. Possibly args are:

=over 4

=item fold_lists

If true, fold lisp lists (e.g. "(1 2 3)") into Perl listrefs, e.g. [1, 2, 3]

Defaults to true.

=item fold_alists

If true, fold lisp alists into perl hashrefs. e.g.

C<"((fg . red) (bg . black) (weight . bold))">

would become

    {
        \*fg       => \*red,
        \*bg       => \*black,
        \*weight   => \*bold
    }

Alists will only be folded if they are a list of conses, all of which
have scalars as both their C<car> and C<cdr> (See
L<Data::SExpression::Cons/scalarp>)

This option implies L</fold_lists>

Defaults to false.

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

Parse an SExpression from the start of STRING, or die if the parse
fails.

In scalar context, returns the expression parsed as a perl data
structure; In list context, also return the part of STRING left
unparsed. This means you can read all the expressions in a string
with:

    my @sexps;
    my $sexp;
    while(1) {
        eval {
            ($sexp, $text) = $ds->read($text);
        };
        last if $@;
        push @sexps, $sexp;
    }


This method converts Lisp SExpressions into perl data structures by
the following rules:

=over 4

=item Numbers and Strings become perl scalars

Lisp differentiates between the types; perl doesn't.

=item Symbols become globrefs in main::

This means they become something like \*main::foo, or \*::foo for
short. To convert from a string to a symbol, you can use
L<Symbol/qualify_to_ref>, with C<"main"> as the package.

=item Conses become Data::SExpression::Cons objects

See L<Data::SExpression::Cons> for how to deal with these. See also
the C<fold_lists> and C<fold_alists> arguments to L</new>.

=item Quotation is parsed as in scheme

This means that "'foo" is parsed like "(quote foo)", "`foo" like
"(quasiquote foo)", and ",foo" like "(unquote foo)".

=back

=cut

sub read {
    my $self = shift;
    my $string = shift;
    my $value = $self->get_parser->sexpression(wantarray ? \$string : $string);

    croak("SExp Parse error") unless defined($value);

    $value = $self->_fold_lists($value) if $self->get_fold_lists;
    $value = $self->_fold_alists($value) if $self->get_fold_alists;

    return wantarray ? ($value, $string) : $value;
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

  sexpression:          number | symbol | string | list | quoted

  # Scalar types

  number:               /[+-]?\\d+(?:[.]\\d*)?/

  symbol:               /[!\\$\\w-][!\\$\\w+-]*/     {$return = Symbol::qualify_to_ref($item[1],"main")} 

  string:               /".*?[^\\\\]"/               {$return = Data::SExpression::extract_string($item[1])}
                      | '""'                         {$return = ""}

  list:                 "(" list_interior ")"        {$return = $item[2]}

  list_interior:        sexpression list_interior    {$return = Data::SExpression::Cons->new($item[1], $item[2])}
                      | sexpression ... ")"          {$return = Data::SExpression::Cons->new($item[1], undef)}
                      | sexpression "." sexpression  {$return = Data::SExpression::Cons->new($item[1], $item[3])}

  quoted:               quote_form["'","quote"]
                      | quote_form["`","quasiquote"]
                      | quote_form[",","unquote"]

  quote_form:           "$arg[0]" sexpression        {$return = Data::SExpression::Cons->new(Symbol::qualify_to_ref($arg[1], "main"),
                                                                Data::SExpression::Cons->new($item[2], undef))}

};

=head1 AUTHOR

Nelson Elhage <nelhage@mit.edu> 

=cut

1;
