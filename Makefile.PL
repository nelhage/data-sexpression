use inc::Module::Install;

name('Data-SExpression');
license('Perl');

version_from('lib/Data/SExpression.pm');

requires('Parse::RecDescent');
requires('Class::Accessor::Fast');

WriteAll;
