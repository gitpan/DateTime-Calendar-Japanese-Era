use strict;
use inc::Module::Install;

name('DateTime-Calendar-Japanese-Era');
all_from('lib/DateTime/Calendar/Japanese/Era.pm');
requires('Class::Accessor::Fast');
requires('Class::Data::Inheritable');
requires('DateTime');
requires('DateTime::Infinite');
requires('Encode');
requires('Exporter');
requires('File::ShareDir', '1.00');
requires('Params::Validate');

install_share 'module' => 'DateTime::Calendar::Japanese::Era', 'share';
auto_include;
WriteAll;