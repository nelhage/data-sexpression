use warnings;
use strict;

=head1 NAME

Data::SExpression::Cons -- Representation of a Lisp cons as read by
Data::SExpression.

=head1 DESCRIPTION

=cut

package Data::SExpression::Cons;
use base qw(Class::Accessor::Fast Exporter);
__PACKAGE__->mk_accessors(qw(car cdr));

our @EXPORT_OK = qw(cons consp);

=head2 new CAR CDR

Construct a new C<Cons> with the given C<car> and C<cdr>

=cut

sub new {
    my $class = shift;
    my ($car, $cdr) = @_;

    my $self = {car => $car, cdr => $cdr};
    return bless($self, $class);
}

=head2 car, cdr

Returns the C<car> or C<cdr> of this C<Cons>.

=head2 set_car CAR, set_cdr CDR

Set the C<car> or C<cdr> of this C<Cons> object.

=cut

sub mutator_name_for {
    my $self = shift;
    my $name = shift;
    return "set_$name";
}

=head1 NON-METHOD FUNCTIONS

These are all generic methods to make operating on cons's easier in
perl. You can ask for any of these in the export list, e.g.

    use Data::SExpression::Cons qw(cons consp);

=head2 cons CAR CDR

Convenience method for Data::SExpression->new(CAR, CDR)

=cut

sub cons ($$) {
    my ($car, $cdr) = @_;
    return __PACKAGE__->new($car, $cdr);
}

=head2 consp THING

Returns true iff C<THING> is a reference to a
C<Data::SExpression::Cons>

=cut

sub consp ($) {
    my $thing = shift;
    return ref($thing) && UNIVERSAL::isa($thing, __PACKAGE__);
}

=head1 SEE ALSO

L<Data::Sexpression>

=head1 AUTHOR

Nelson Elhage <nelhage@mit.edu> 

=cut

1;
