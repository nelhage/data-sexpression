#!/usr/bin/env perl
use strict;
use warnings;

=head1 DESCRIPTION

Test parsing of scalar types

=cut

use Test::More tests => 9;
use Symbol;

use Data::SExpression;

my $ds = Data::SExpression->new();

can_ok($ds, 'read');

is($ds->read('123'), 123, "Read int ok");
is($ds->read('-32'), -32, "Negative number ok");
is($ds->read('1.5'), 1.5, "Decimal ok");
is($ds->read('"Hello, World"'), "Hello, World", "Read string OK");
is($ds->read('"Hello, \"World\""'), "Hello, \"World\"", "Escaped backslashes OK");
is($ds->read('""'), "", "Empty string OK");
cmp_ok($ds->read('foobar'), "==", qualify_to_ref('foobar', 'main'), "Read symbol OK");
cmp_ok($ds->read('foo!'), "==", qualify_to_ref('foo!','main'), "Weird symbol OK");
