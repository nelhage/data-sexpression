use inc::Module::Install;

name('Data-SExpression');
license('Perl');

version_from('lib/Data/SExpression.pm');

requires('Class::Accessor::Fast');
requires('Parse::Yapp');

requires_external_bin('yapp');

system('yapp -m Data::SExpression::Parser -o lib/Data/SExpression/Parser.pm lib/Data/SExpression/Parser.yp')
  and die("Failed: Unable to create Data::SExpression::Parser (Is Parse::Yapp appropriately installed on your system?)");

WriteAll;
