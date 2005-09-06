#!perl
# $Id: Build.PL,v 1.2 2005/09/06 00:55:48 lestrrat Exp $
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
    create_makefile_pl => 'traditional'
);
$build->create_build_script;
