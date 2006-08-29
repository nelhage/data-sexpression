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

use base qw(Class::Accessor::Fast Exporter);
__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_ro_accessors(qw(parser fold_lists fold_alists));

our @EXPORT_OK = qw(cons consp scalarp);

use Symbol;
use Data::SExpression::Cons;
use Data::SExpression::Parser;
use Carp qw(croak);


my $grammar;


=head1 LISP-LIKE CONVENIENCE FUNCTIONS

These are all generic methods to make operating on cons's easier in
perl. You can ask for any of these in the export list, e.g.

    use Data::SExpression qw(cons consp);

=head2 cons CAR CDR

Convenience method for Data::SExpression::Cons->new(CAR, CDR)

=cut

sub cons ($$) {
    my ($car, $cdr) = @_;
    return Data::SExpression::Cons->new($car, $cdr);
}

=head2 consp THING

Returns true iff C<THING> is a reference to a
C<Data::SExpression::Cons>

=cut

sub consp ($) {
    my $thing = shift;
    return ref($thing) && UNIVERSAL::isa($thing, 'Data::SExpression::Cons');
}

=head2 scalarp THING

Returns true iff C<THING> is a scalar -- i.e. a string, symbol, or
number

=cut

sub scalarp ($) {
    my $thing = shift;
    return !ref($thing) || ref($thing) eq "GLOB";
}


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
    
    my $parser = Data::SExpression::Parser->new;

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

    $self->get_parser->set_input($string);
    
    my $value = $self->get_parser->parse;

    croak("SExp Parse error") unless defined($value);

    $value = $self->_fold_lists($value) if $self->get_fold_lists;
    $value = $self->_fold_alists($value) if $self->get_fold_alists;

    my $unparsed = $self->get_parser->unparsed_input;

    return wantarray ? ($value, $unparsed) : $value;
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

=head1 AUTHOR

Nelson Elhage <nelhage@mit.edu> 

=cut

1;

