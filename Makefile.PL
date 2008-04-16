use inc::Module::Install;

name('Data-SExpression');
license('Perl');

version_from('lib/Data/SExpression.pm');

requires('Class::Accessor::Fast');
requires('Parse::Yapp');

build_requires('Test::More');
build_requires('Test::Deep');

postamble(<<"END_MAKEFILE");
lib/Data/SExpression/Parser.pm: lib/Data/SExpression/Parser.yp
\tyapp -m Data::SExpression::Parser -o \$@ \$<
END_MAKEFILE

WriteAll;
