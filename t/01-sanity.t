#!perl
use strict;
use Test::More qw(no_plan);
BEGIN
{
    use_ok("DateTime::Calendar::Japanese::Era", qw(SOUTH_REGIME NORTH_REGIME) );
}

my $e = DateTime::Calendar::Japanese::Era->lookup_by_date(
    datetime => DateTime->new(year => 1990));

isa_ok($e, 'DateTime::Calendar::Japanese::Era');
ok($e->start->compare( DateTime->new(year => 1989, month => 1,  day => 8, time_zone => 'Asia/Tokyo')) == 0);
ok($e->end->compare( DateTime::Infinite::Future->new() ) == 0);
is($e->id, 'HEISEI');


my $dt = DateTime->new(year => 1335);

my $e_south = DateTime::Calendar::Japanese::Era->lookup_by_date(
    datetime => $dt,
    regime   => SOUTH_REGIME
);
my $e_north = DateTime::Calendar::Japanese::Era->lookup_by_date(
    datetime => $dt,
    regime   => NORTH_REGIME
);

is($e_south->id, 'S_KENMU');
is($e_north->id, 'SHOUKEI');

