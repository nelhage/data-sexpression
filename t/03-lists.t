#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test the parsing of lists, without folding.

=cut

use Test::More no_plan => 1;
use Test::Deep;
use Symbol;

use Data::SExpression;

my $ds = Data::SExpression->new({fold_lists => 0});

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
