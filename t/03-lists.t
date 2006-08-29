#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test the parsing of lists, without folding.

=cut

use Test::More tests => 4;
use Test::Deep;
use Symbol;

use Data::SExpression;

my $ds = Data::SExpression->new({
    fold_lists  => 0,
    fold_alists => 0
});

cmp_deeply(
    $ds->read("(1 2 3 4)"),
    methods(
        car => 1,
        cdr => methods(
            car => 2,
            cdr => methods(
                car => 3,
                cdr => methods(
                    car => 4,
                    cdr => undef)))),
    "Read a simple list");

cmp_deeply(
    $ds->read("(1 2 3 . 4)"),
    methods(
        car => 1,
        cdr => methods(
            car => 2,
            cdr => methods(
                car => 3,
                cdr => 4))),
    "Read an improper list");

cmp_deeply(
    $ds->read("((1 2) (3 4))"),
    methods(
        car => methods(
            car => 1,
            cdr => methods(
                car => 2,
                cdr => undef)),
        cdr => methods(
            car => methods(
                car => 3,
                cdr => methods(
                    car => 4,
                    cdr => undef)))),
    "Read a tree");

no warnings 'once';     #For the symbol globs

cmp_deeply(
    $ds->read("((fg . red) (bg . black) (weight . bold))"),
    methods(
        car => methods(
            car => \*fg,
            cdr => \*red),
        cdr => methods(
            car => methods(
                car => \*bg,
                cdr => \*black),
            cdr => methods(
                car => methods(
                    car => \*weight,
                    cdr => \*bold),
                cdr => undef))),
    "Read an alist");
