#!perl
use strict;
my $HAS_ENCODE;
BEGIN
{
    eval { require Encode };
    $HAS_ENCODE = !$@;

    require Test::More;
    Test::More->import(tests => $HAS_ENCODE ? 13 : 7);
}

BEGIN
{
    use_ok("DateTime::Calendar::Japanese::Era", qw(SOUTH_REGIME NORTH_REGIME) );
}

my $class = 'DateTime::Calendar::Japanese::Era';
my @eras =(
    $class->lookup_by_date(datetime => DateTime->new(year => 1990)),
);
if ($HAS_ENCODE) {
    push @eras,
        $class->lookup_by_name(name => Encode::decode('euc-jp', '平成'));
}
    
foreach my $e (@eras) {
    isa_ok($e, 'DateTime::Calendar::Japanese::Era');
    ok($e->start->compare( DateTime->new(year => 1989, month => 1,  day => 8, time_zone => 'Asia/Tokyo')) == 0);
    ok($e->end->compare( DateTime::Infinite::Future->new() ) == 0);
    is($e->id, 'HEISEI');

    if ($HAS_ENCODE) {
        is($e->name, Encode::decode('euc-jp', '平成'));
    }
}


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

