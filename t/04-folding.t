#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test the folding of Lisp lists and alists into perl lists and hashes.

=cut

use Test::More 'no_plan';
use Test::Deep;

use Data::SExpression;

my $ds = Data::SExpression->new({fold_lists => 1});

cmp_deeply(
    $ds->read('(1 2 3 4)'),
    [1, 2, 3, 4],
    "Folded a simple list");

cmp_deeply(
    $ds->read('(1 2 . 3)'),
    methods(
        car => 1,
        cdr => methods(
            car => 2,
            cdr => 3)),
    "Didn't fold an improper list");

no warnings 'once';

cmp_deeply(
    $ds->read('((fg . red) (bg . black) (weight . bold))'),
    [
        methods(car => \*fg, cdr => \*red),
        methods(car => \*bg, cdr => \*black),
        methods(car => \*weight, cdr => \*bold)
       ],
    "Read an alist");
