####################################################################
#
#    This file was generated using Parse::Yapp version 1.05.
#
#        Don't edit this file, use source file instead.
#
#             ANY CHANGE MADE HERE WILL BE LOST !
#
####################################################################
package Data::SExpression::Parser;
use vars qw ( @ISA );
use strict;

@ISA= qw ( Parse::Yapp::Driver );
use Parse::Yapp::Driver;

#line 9 "lib/Data/SExpression/Parser.yp"

use Data::SExpression::Cons;


sub new {
        my($class)=shift;
        ref($class)
    and $class=ref($class);

    my($self)=$class->SUPER::new( yyversion => '1.05',
                                  yystates =>
[
	{#State 0
		ACTIONS => {
			"(" => 5,
			'SYMBOL' => 1,
			'NUMBER' => 8,
			'STRING' => 4,
			'QUOTE' => 3
		},
		GOTOS => {
			'expression' => 7,
			'sexpression' => 6,
			'quoted' => 2,
			'list' => 9
		}
	},
	{#State 1
		DEFAULT => -3
	},
	{#State 2
		DEFAULT => -6
	},
	{#State 3
		ACTIONS => {
			"(" => 5,
			'SYMBOL' => 1,
			'NUMBER' => 8,
			'STRING' => 4,
			'QUOTE' => 3
		},
		GOTOS => {
			'expression' => 10,
			'quoted' => 2,
			'list' => 9
		}
	},
	{#State 4
		DEFAULT => -4
	},
	{#State 5
		ACTIONS => {
			"(" => 5,
			'SYMBOL' => 1,
			'NUMBER' => 8,
			'STRING' => 4,
			'QUOTE' => 3
		},
		GOTOS => {
			'expression' => 11,
			'quoted' => 2,
			'list_interior' => 12,
			'list' => 9
		}
	},
	{#State 6
		ACTIONS => {
			'' => 13
		}
	},
	{#State 7
		DEFAULT => -1
	},
	{#State 8
		DEFAULT => -2
	},
	{#State 9
		DEFAULT => -5
	},
	{#State 10
		DEFAULT => -11
	},
	{#State 11
		ACTIONS => {
			'SYMBOL' => 1,
			'STRING' => 4,
			'QUOTE' => 3,
			"(" => 5,
			'NUMBER' => 8,
			"." => 15
		},
		DEFAULT => -10,
		GOTOS => {
			'expression' => 11,
			'quoted' => 2,
			'list_interior' => 14,
			'list' => 9
		}
	},
	{#State 12
		ACTIONS => {
			")" => 16
		}
	},
	{#State 13
		DEFAULT => 0
	},
	{#State 14
		DEFAULT => -9
	},
	{#State 15
		ACTIONS => {
			"(" => 5,
			'SYMBOL' => 1,
			'NUMBER' => 8,
			'STRING' => 4,
			'QUOTE' => 3
		},
		GOTOS => {
			'expression' => 17,
			'quoted' => 2,
			'list' => 9
		}
	},
	{#State 16
		DEFAULT => -7
	},
	{#State 17
		DEFAULT => -8
	}
],
                                  yyrules  =>
[
	[#Rule 0
		 '$start', 2, undef
	],
	[#Rule 1
		 'sexpression', 1,
sub
#line 15 "lib/Data/SExpression/Parser.yp"
{ $_[0]->YYAccept; return $_[1]; }
	],
	[#Rule 2
		 'expression', 1, undef
	],
	[#Rule 3
		 'expression', 1,
sub
#line 19 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_symbol($_[1]) }
	],
	[#Rule 4
		 'expression', 1,
sub
#line 20 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_string($_[1]) }
	],
	[#Rule 5
		 'expression', 1, undef
	],
	[#Rule 6
		 'expression', 1, undef
	],
	[#Rule 7
		 'list', 3,
sub
#line 26 "lib/Data/SExpression/Parser.yp"
{ $_[2] }
	],
	[#Rule 8
		 'list_interior', 3,
sub
#line 31 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_cons($_[1], $_[3]) }
	],
	[#Rule 9
		 'list_interior', 2,
sub
#line 32 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_cons($_[1], $_[2]) }
	],
	[#Rule 10
		 'list_interior', 1,
sub
#line 33 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_cons($_[1], undef) }
	],
	[#Rule 11
		 'quoted', 2,
sub
#line 38 "lib/Data/SExpression/Parser.yp"
{ $_[0]->handler->new_cons($_[0]->handler->new_symbol($_[1]),
                                                                    $_[0]->handler->new_cons($_[2], undef))}
	]
],
                                  @_);
    bless($self,$class);
}

#line 42 "lib/Data/SExpression/Parser.yp"


sub set_input {
    my $self = shift;
    my $input = shift or die(__PACKAGE__ . "::set_input called with 0 arguments");
    $self->YYData->{INPUT} = $input;
}

sub set_handler {
    my $self = shift;
    my $handler = shift or die(__PACKAGE__ . "::set_handler called with 0 arguments");
    $self->YYData->{HANDLER} = $handler;
}

sub handler {
    my $self = shift;
    return $self->YYData->{HANDLER};
}

sub unparsed_input {
    my $self = shift;
    return substr($self->YYData->{INPUT}, pos($self->YYData->{INPUT}));
}


my %quotes = (q{'} => 'quote',
              q{`} => 'quasiquote',
              q{,} => 'unquote');


sub lexer {
    my $self = shift;

    $self->YYData->{INPUT} or return ('', undef);

    my $symbol_char = qr{[*!\$[:alpha:]\?<>=/+-]};

    for($self->YYData->{INPUT}) {
        $_ =~ /\G \s* (?: ; .* \s* )* /gcx;

        /\G ([+-]? \d+ (?:[.]\d*)?) /gcx
        || /\G ([+-]? [.] \d+) /gcx
          and return ('NUMBER', $1);

        /\G ($symbol_char ($symbol_char | \d )*)/gcx
          and return ('SYMBOL', $1);

        /\G " ([^"\\]* (?: \\. [^"\\]*)*) "/gcx
          and return ('STRING', $1 || "");

        /\G ([().])/gcx
          and return ($1, $1);

        /\G ([`',]) /gcx
          and return ('QUOTE', $quotes{$1});

        return ('', undef);
    }
}

sub error {
    my $self = shift;
    my ($tok, $val) = $self->YYLexer->($self);
    die("Parse error near: '" . $self->unparsed_input . "'");
    return undef;
}

sub parse {
    my $self = shift;
    return $self->YYParse(yylex => \&lexer, yyerror => \&error);
}

1;
