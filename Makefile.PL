use strict;
use inc::Module::Install;

name('DateTime-Calendar-Japanese-Era');
all_from('lib/DateTime/Calendar/Japanese/Era.pm');
requires('Class::Accessor::Fast');
requires('Class::Data::Inheritable');
requires('DateTime');
requires('DateTime::Infinite');
requires('Exporter');
requires('File::ShareDir');
requires('Params::Validate');

install_share;
auto_install;
WriteAll;