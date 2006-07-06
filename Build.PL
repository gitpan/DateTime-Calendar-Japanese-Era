#!perl
# $Id: /mirror/DateTime-Calendar-Japanese-Era/Build.PL 1675 2006-07-05T10:57:54.532994Z lestrrat  $
#
# Copyright (c) 2004-2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

use strict;
use Module::Build;

my $build = Module::Build->new(
	module_name => 'DateTime::Calendar::Japanese::Era',
	dist_name => 'DateTime-Calendar-Japanese-Era',
	license => 'perl',
	requires => {
		'DateTime'                      => 0,
		'Params::Validate'              => 0,
	},
	recommends => {
		'perl' => '5.6.1',
	},
    create_readme => 1,
    create_makefile_pl => 'traditional'
);
$build->create_build_script;
