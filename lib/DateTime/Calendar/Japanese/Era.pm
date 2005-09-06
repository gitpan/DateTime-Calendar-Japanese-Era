# $Id: Era.pm,v 1.2 2005/09/06 00:55:49 lestrrat Exp $
#
# Copyright (c) 2004-2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package DateTime::Calendar::Japanese::Era;
use strict;
use vars qw(@ISA @EXPORT_OK $VERSION);
use Exporter;
BEGIN
{
    @ISA       = 'Exporter';
    @EXPORT_OK = qw(SOUTH_REGIME NORTH_REGIME);
    $VERSION   = '0.05';
}
use DateTime;
use DateTime::Infinite;
use Params::Validate();
use constant NORTH_REGIME  => 1;
use constant SOUTH_REGIME  => 2;
use constant SOUTH_REGIME_START => DateTime->new(
    year => 1331, month => 11, day => 7, time_zone => 'Asia/Tokyo')->set_time_zone('UTC');
use constant SOUTH_REGIME_END => DateTime->new(
    year => 1392, month => 11, day => 27, time_zone => 'Asia/Tokyo')->set_time_zone('UTC');

my(%ERAS_BY_ID, @ERAS_BY_CENTURY, @SOUTH_REGIME_ERAS);

my %NewValidate = (
    id => { type => Params::Validate::SCALAR() },
    start => { isa => 'DateTime' },
    end => { isa => 'DateTime' },
);

sub new
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, \%NewValidate);

    bless \%args, $class;
}

sub id    { $_[0]->{id}    }
sub start { $_[0]->{start} }
sub end   { $_[0]->{end}   }

sub clone
{
    my $self = shift;
    return ref($self)->new(
        id    => $self->id,
        start => $self->start->clone,
        end   => $self->end->clone
    );
}

sub lookup_by_id
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, {
        id => { type => Params::Validate::SCALAR() }
    });

    return $ERAS_BY_ID{ $args{id} }->clone;
}

sub lookup_by_date
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, {
        datetime => { can => 'utc_rd_values' },
        regime   => { type => Params::Validate::SCALAR(), default => NORTH_REGIME }
    } );

    my $dt_utc = DateTime->from_object(object => $args{datetime});
#    $dt_utc->set_time_zone('UTC');

    my @candidates;
    if ($args{regime} == SOUTH_REGIME && $dt_utc >= SOUTH_REGIME_START && $dt_utc <= SOUTH_REGIME_END) {
        @candidates = @SOUTH_REGIME_ERAS;
    } else {
        my $century = int($dt_utc->year() / 100);
        my $r = $century >= $#ERAS_BY_CENTURY ?
            $ERAS_BY_CENTURY[$#ERAS_BY_CENTURY] :
            $ERAS_BY_CENTURY[$century];
        if (! defined($r) ) {
            return;
        }
        @candidates = @$r;
    }

    foreach my $era (@candidates) {
        if ($era->start <= $dt_utc && $era->end > $dt_utc) {
            return $era->clone;
        }
    }
    return;
}

sub register_era
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, {
        object => { isa => __PACKAGE__, optional => 1 },
        id     => { type => Params::Validate::SCALAR(), optional => 1 },
        start  => { isa => 'DateTime', optional => 1 },
        end    => { isa => 'DateTime', optional => 1 },
    });

    my $era = delete $args{object};
    if (!exists $args{object}) {
        $era = __PACKAGE__->new(%args);
    }

    if (exists $ERAS_BY_ID{ $era->id }) {
        Carp::croak("Era with id = " . $era->id() . " already exists!");
    }
    $ERAS_BY_ID{ $era->id } = $era;

    my $start_century = int($era->start->year() / 100);
    my $end_century   = int($era->end->year() / 100);

    $ERAS_BY_CENTURY[ $start_century ] ||= [];
    push @{ $ERAS_BY_CENTURY[ $start_century ] }, $era;
    if ($start_century != $end_century) {
        $ERAS_BY_CENTURY[ $end_century ] ||= [];
        push @{ $ERAS_BY_CENTURY[ $end_century ] }, $era;
    }
}

#BEGIN
{
    # XXX - these dates were scoured from all over the net, and while
    # I chose those dates that seemed to be most widely supported,
    # I have a nagging feeling that these dates (not the years, just
    # month/day) are from the traditional calendar, not gregorian...

    my @predefined_eras = (
        [ 'TAIKA', [ 645, 8, 18 ]],
        [ 'HAKUCHI', [ 650, 4, 23 ], [ 654, 11, 26 ]],
        [ 'SHUCHOU', [ 686, 9, 15 ]],
        [ 'TAIHOU', [ 701, 6, 5 ]],
        [ 'KEIUN', [ 704, 7, 19 ]],
        [ 'WADOU', [ 708, 2, 10 ]],
        [ 'REIKI', [ 715, 11, 6 ]],
        [ 'YOUROU', [ 717, 12, 27 ]],
        [ 'JINKI', [ 724, 4, 5 ]],
        [ 'TENPYOU', [ 729, 10, 5 ]],
        [ 'TENPYOUKANPOU', [ 749, 6, 7 ]],
        [ 'TENPYOUSHOUHOU', [ 749, 8, 22 ]],
        [ 'TENPYOUJOUJI', [ 757, 10, 9 ]],
        [ 'TENPYOUJINGO', [ 765, 2, 5 ]],
        [ 'JINGOKEIUN', [ 767, 10, 16 ]],
        [ 'HOUKI', [ 770, 11, 26 ]],
        [ 'TENNOU', [ 781, 2, 2 ]],
        [ 'ENRYAKU', [ 782, 10, 4 ]],
        [ 'DAIDOU', [ 806, 7, 11 ]],
        [ 'KOUNIN', [ 810, 11, 22 ]],
        [ 'TENCHOU', [ 823, 2, 22 ]],
        [ 'JOUWA1', [ 834, 2, 18 ]],
        [ 'KASHOU', [ 848, 8, 18 ]],
        [ 'NINJU', [ 851, 7, 4 ]],
        [ 'SAIKOU', [ 855, 1, 25 ]],
        [ 'TENNAN', [ 857, 4, 22 ]],
        [ 'JOUGAN', [ 859, 6, 22 ]],
        [ 'GANGYOU', [ 877, 6, 4 ]],
        [ 'NINNA', [ 885, 4, 13 ]],
        [ 'KANPYOU', [ 889, 7, 2 ]],
        [ 'SHOUTAI', [ 898, 6, 22 ]],
        [ 'ENGI', [ 901, 9, 5 ]],
        [ 'ENCHOU', [ 923, 6, 2 ]],
        [ 'JOUHEI', [ 931, 6, 19 ]],
        [ 'TENGYOU', [ 938, 7, 26 ]],
        [ 'TENRYAKU', [ 947, 6, 18 ]],
        [ 'TENTOKU', [ 957, 12, 25 ]],
        [ 'OUWA', [ 961, 4, 8 ]],
        [ 'KOUHOU', [ 964, 8, 24 ]],
        [ 'ANNA', [ 968, 10, 12 ]],
        [ 'TENROKU', [ 970, 6, 6 ]],
        [ 'TENNEN', [ 974, 1, 20 ]],
        [ 'JOUGEN1', [ 976, 9, 13 ]],
        [ 'TENGEN', [ 979, 2, 3 ]],
        [ 'EIKAN', [ 983, 6, 3 ]],
        [ 'KANNA', [ 985, 6, 22 ]],
        [ 'EIEN', [ 987, 6, 8 ]],
        [ 'EISO', [ 989, 10, 14 ]],
        [ 'SHOURYAKU', [ 990, 12, 31 ]],
        [ 'CHOUTOKU', [ 995, 4, 28 ]],
        [ 'CHOUHOU', [ 999, 2, 6 ]],
        [ 'KANKOU', [ 1004, 9, 12 ]],
        [ 'CHOUWA', [ 1013, 1, 14 ]],
        [ 'KANNIN', [ 1017, 6, 25 ]],
        [ 'JIAN', [ 1021, 3, 23 ]],
        [ 'MANJU', [ 1024, 9, 23 ]],
        [ 'CHOUGEN', [ 1028, 9, 21 ]],
        [ 'CHOURYAKU', [ 1037, 6, 12 ]],
        [ 'CHOUKYU', [ 1040, 12, 21 ]],
        [ 'KANTOKU', [ 1045, 1, 20 ]],
        [ 'EISHOU1', [ 1046, 6, 26 ]],
        [ 'TENGI', [ 1053, 2, 7 ]],
        [ 'KOUHEI', [ 1058, 10, 24 ]],
        [ 'JIRYAKU', [ 1065, 10, 9 ]],
        [ 'ENKYUU', [ 1069, 6, 10 ]],
        [ 'JOUHOU', [ 1074, 10, 21 ]],
        [ 'JOURYAKU', [ 1078, 1, 9 ]],
        [ 'EIHOU', [ 1081, 4, 27 ]],
        [ 'OUTOKU', [ 1084, 4, 19 ]],
        [ 'KANJI', [ 1087, 6, 15 ]],
        [ 'KAHOU', [ 1095, 1, 29 ]],
        [ 'EICHOU', [ 1097, 1, 8 ]],
        [ 'JOUTOKU', [ 1098, 1, 1 ]],
        [ 'KOUWA', [ 1099, 10, 20 ]],
        [ 'CHOUJI', [ 1104, 4, 13 ]],
        [ 'KAJOU', [ 1106, 6, 18 ]],
        [ 'TENNIN', [ 1108, 10, 15 ]],
        [ 'TENNEI', [ 1110, 9, 5 ]],
        [ 'EIKYU', [ 1113, 9, 1 ]],
        [ 'GENNEI', [ 1118, 5, 31 ]],
        [ 'HOUAN', [ 1120, 6, 14 ]],
        [ 'TENJI', [ 1124, 5, 24 ]],
        [ 'DAIJI', [ 1126, 2, 22 ]],
        [ 'TENSHOU1', [ 1131, 3, 6 ]],
        [ 'CHOUSHOU', [ 1132, 9, 28 ]],
        [ 'HOUEN', [ 1135, 6, 16 ]],
        [ 'EIJI', [ 1141, 9, 18 ]],
        [ 'KOUJI1', [ 1142, 6, 29 ]],
        [ 'TENNYOU', [ 1144, 5, 4 ]],
        [ 'KYUAN', [ 1145, 9, 17 ]],
        [ 'NINPEI', [ 1151, 2, 20 ]],
        [ 'KYUJU', [ 1154, 12, 11 ]],
        [ 'HOUGEN', [ 1156, 6, 23 ]],
        [ 'HEIJI', [ 1159, 6, 14 ]],
        [ 'EIRYAKU', [ 1160, 2, 25 ]],
        [ 'OUHOU', [ 1161, 10, 30 ]],
        [ 'CHOUKAN', [ 1163, 6, 9 ]],
        [ 'EIMAN', [ 1165, 7, 21 ]],
        [ 'NINNAN', [ 1166, 10, 29 ]],
        [ 'KAOU', [ 1169, 6, 11 ]],
        [ 'SHOUAN1', [ 1171, 7, 2 ]],
        [ 'ANGEN', [ 1175, 9, 21 ]],
        [ 'JISHOU', [ 1177, 10, 3 ]],
        [ 'YOUWA', [ 1181, 9, 1 ]],
        [ 'JUEI', [ 1182, 8, 4 ]],
        [ 'GENRYAKU', [ 1184, 6, 2 ]],
        [ 'BUNJI', [ 1185, 10, 15 ]],
        [ 'KENKYU', [ 1190, 6, 21 ]],
        [ 'SHOUJI', [ 1199, 6, 28 ]],
        [ 'KENNIN', [ 1201, 5, 23 ]],
        [ 'GENKYU', [ 1204, 4, 28 ]],
        [ 'KENNEI', [ 1206, 7, 11 ]],
        [ 'JOUGEN2', [ 1207, 12, 22 ]],
        [ 'KENRYAKU', [ 1211, 4, 29 ]],
        [ 'KENPOU', [ 1214, 1, 24 ]],
        [ 'JOUKYU', [ 1219, 6, 2 ]],
        [ 'JOUOU1', [ 1222, 5, 31 ]],
        [ 'GENNIN', [ 1225, 1, 7 ]],
        [ 'KAROKU', [ 1225, 7, 3 ]],
        [ 'ANTEI', [ 1228, 1, 24 ]],
        [ 'KANKI', [ 1229, 5, 6 ]],
        [ 'JOUEI', [ 1232, 5, 29 ]],
        [ 'TENPUKU', [ 1233, 6, 30 ]],
        [ 'BUNRYAKU', [ 1235, 1, 2 ]],
        [ 'KATEI', [ 1235, 11, 7 ]],
        [ 'RYAKUNIN', [ 1239, 1, 6 ]],
        [ 'ENNOU', [ 1239, 4, 18 ]],
        [ 'NINJI', [ 1240, 9, 10 ]],
        [ 'KANGEN', [ 1243, 4, 23 ]],
        [ 'HOUJI', [ 1247, 5, 11 ]],
        [ 'KENCHOU', [ 1249, 5, 8 ]],
        [ 'KOUGEN', [ 1256, 11, 29 ]],
        [ 'SHOUKA', [ 1257, 5, 6 ]],
        [ 'SHOUGEN', [ 1259, 5, 26 ]],
        [ 'BUNNOU', [ 1260, 5, 30 ]],
        [ 'KOUCHOU', [ 1261, 4, 27 ]],
        [ 'BUNNEI', [ 1264, 5, 2 ]],
        [ 'KENJI', [ 1275, 6, 26 ]],
        [ 'KOUAN1', [ 1278, 4, 28 ]],
        [ 'SHOUOU', [ 1288, 7, 4 ]],
        [ 'EININ', [ 1293, 10, 12 ]],
        [ 'SHOUAN2', [ 1299, 6, 30 ]],
        [ 'KENGEN', [ 1303, 1, 17 ]],
        [ 'KAGEN', [ 1303, 9, 24 ]],
        [ 'TOKUJI', [ 1307, 1, 26 ]],
        [ 'ENKYOU1', [ 1308, 11, 30 ]],
        [ 'OUCHOU', [ 1311, 6, 23 ]],
        [ 'SHOUWA1', [ 1312, 6, 3 ]],
        [ 'BUNPOU', [ 1317, 3, 24 ]],
        [ 'GENNOU', [ 1319, 6, 24 ]],
        [ 'GENKOU', [ 1321, 4, 28 ]],
        [ 'SHOUCHU', [ 1325, 1, 2 ]],
        [ 'KARYAKU', [ 1326, 7, 4 ]],
        [ 'GENTOKU', [ 1329, 10, 29 ]],
        [ 'SHOUKEI', [ 1332, 6, 29 ]],
        [ 'RYAKUOU', [ 1338, 10, 19 ]],
        [ 'KOUEI', [ 1342, 7, 7 ]],
        [ 'JOUWA2', [ 1345, 12, 22 ]],
        [ 'KANNOU', [ 1350, 5, 11 ]],
        [ 'BUNNNA', [ 1352, 11, 12 ]],
        [ 'ENBUN', [ 1356, 6, 5 ]],
        [ 'KOUAN2', [ 1361, 6, 10 ]],
        [ 'JOUJI', [ 1362, 11, 17 ]],
        [ 'OUAN', [ 1368, 4, 13 ]],
        [ 'EIWA', [ 1375, 5, 5 ]],
        [ 'KOURYAKU', [ 1379, 5, 16 ]],
        [ 'EITOKU', [ 1381, 4, 26 ]],
        [ 'SHITOKU', [ 1384, 4, 25 ]],
        [ 'KAKEI', [ 1387, 10, 13 ]],
        [ 'KOUOU', [ 1389, 4, 13 ]],
        [ 'MEITOKU', [ 1390, 5, 18 ]],
        [ 'OUEI', [ 1394, 9, 8 ]],
        [ 'SHOUCHOU', [ 1428, 6, 18 ]],
        [ 'EIKYOU', [ 1429, 11, 10 ]],
        [ 'KAKITSU', [ 1441, 4, 16 ]],
        [ 'BUNNAN', [ 1444, 4, 1 ]],
        [ 'HOUTOKU', [ 1449, 9, 23 ]],
        [ 'KYOUTOKU', [ 1452, 9, 17 ]],
        [ 'KOUSHOU', [ 1455, 9, 15 ]],
        [ 'CHOUROKU', [ 1457, 11, 23 ]],
        [ 'KANSHOU', [ 1461, 1, 10 ]],
        [ 'BUNSHOU', [ 1466, 4, 21 ]],
        [ 'OUNIN', [ 1467, 5, 16 ]],
        [ 'BUNMEI', [ 1469, 6, 16 ]],
        [ 'CHOUKYOU', [ 1487, 9, 15 ]],
        [ 'ENTOKU', [ 1489, 10, 23 ]],
        [ 'MEIOU', [ 1492, 9, 19 ]],
        [ 'BUNKI', [ 1501, 4, 26 ]],
        [ 'EISHOU2', [ 1504, 4, 24 ]],
        [ 'DAIEI', [ 1521, 11, 1 ]],
        [ 'KYOUROKU', [ 1528, 10, 12 ]],
        [ 'TENBUN', [ 1532, 10, 7 ]],
        [ 'KOUJI2', [ 1555, 12, 16 ]],
        [ 'EIROKU', [ 1558, 4, 26 ]],
        [ 'GENKI', [ 1570, 7, 5 ]],
        [ 'TENSHOU2', [ 1573, 10, 3 ]],
        [ 'BUNROKU', [ 1593, 1, 9 ]],
        [ 'KEICHOU', [ 1596, 12, 16 ]],
        [ 'GENNA', [ 1615, 9, 5 ]],
        [ 'KANNEI', [ 1624, 5, 16 ]],
        [ 'SHOUHOU', [ 1645, 1, 13 ]],
        [ 'KEIAN', [ 1648, 4, 7 ]],
        [ 'JOUOU2', [ 1652, 11, 18 ]],
        [ 'MEIREKI', [ 1655, 6, 16 ]],
        [ 'MANJI', [ 1658, 9, 19 ]],
        [ 'KANBUN', [ 1661, 6, 21 ]],
        [ 'ENPOU', [ 1673, 11, 28 ]],
        [ 'TENNA', [ 1681, 12, 8 ]],
        [ 'JOUKYOU', [ 1684, 5, 4 ]],
        [ 'GENROKU', [ 1688, 11, 22 ]],
        [ 'HOUEI', [ 1704, 5, 15 ]],
        [ 'SHOUTOKU', [ 1711, 7, 10 ]],
        [ 'KYOUHO', [ 1716, 8, 9 ]],
        [ 'GENBUN', [ 1736, 7, 6 ]],
        [ 'KANPOU', [ 1741, 5, 11 ]],
        [ 'ENKYOU2', [ 1744, 5, 2 ]],
        [ 'KANNEN', [ 1748, 9, 4 ]],
        [ 'HOUREKI', [ 1751, 12, 14 ]],
        [ 'MEIWA', [ 1764, 7, 29 ]],
        [ 'ANNEI', [ 1773, 1, 8 ]],
        [ 'TENMEI', [ 1781, 5, 24 ]],
        [ 'KANSEI', [ 1801, 3, 16 ]],
        [ 'KYOUWA', [ 1802, 3, 17 ]],
        [ 'BUNKA', [ 1804, 4, 3 ]],
        [ 'BUNSEI', [ 1818, 6, 20 ]],
        [ 'TENPOU', [ 1831, 1, 21 ]],
        [ 'KOUKA', [ 1845, 1, 8 ]],
        [ 'KAEI', [ 1848, 4, 30 ]],
        [ 'ANSEI', [ 1855, 1, 14 ]],
        [ 'MANNEI', [ 1860, 5, 8 ]],
        [ 'BUNKYU', [ 1861, 4, 28 ]],
        [ 'GENJI', [ 1864, 4, 25 ]],
        [ 'KEIOU', [ 1865, 6, 23 ]],
        [ 'MEIJI',      [ 1868, 10, 23 ] ],
        [ 'TAISHO',     [ 1912,  7, 30 ] ],
        [ 'SHOUWA2',    [ 1926, 12, 25 ] ],
        [ 'HEISEI',     [ 1989,  1,  8 ] ],
    );
    my @south_regime_eras = (
        [ 'S_GENKOU', [ 1331, 11, 7 ]],
        [ 'S_KENMU', [ 1334, 3, 12 ]],
        [ 'S_EIGEN', [ 1336, 4, 19 ]],
        [ 'S_KOUKOKU', [ 1340, 7, 1 ]],
        [ 'S_SHOUHEI', [ 1347, 1, 27 ]],
        [ 'S_KENTOKU', [ 1370, 9, 21 ]],
        [ 'S_BUNCHU', [ 1372, 6, 10 ]],
        [ 'S_TENJU', [ 1375, 8, 2 ]],
        [ 'S_KOUWA', [ 1381, 4, 12 ]],
        [ 'S_GENCHU', [ 1384, 6, 24 ], [ 1392, 11, 27 ]],
    );

    for(0..$#predefined_eras) {
        my $this_era = $predefined_eras[$_];
    
        my $start_date = DateTime->new(
            year      => $this_era->[1]->[0],
            month     => $this_era->[1]->[1],
            day       => $this_era->[1]->[2],
            time_zone => 'Asia/Tokyo'
        );

        my $end_date;
        if ($_ == $#predefined_eras) {
            $end_date = DateTime::Infinite::Future->new();
        } else {
            my $next_era = $predefined_eras[$_ + 1];
            if ($this_era->[2]) {
                $end_date = DateTime->new(
                    year      => $this_era->[2]->[0],
                    month     => $this_era->[2]->[1],
                    day       => $this_era->[2]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            } else {
                $end_date = DateTime->new(
                    year      => $next_era->[1]->[0],
                    month     => $next_era->[1]->[1],
                    day       => $next_era->[1]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            }
        }

        # we create the dates in Asia/Tokyo time, but for calculation
        # we really want them to be in UTC.
#        $start_date->set_time_zone('UTC');
#        $end_date->set_time_zone('UTC');
    
        __PACKAGE__->register_era(
            id    => $this_era->[0],
            start => $start_date,
            end   => $end_date
        );
        push @EXPORT_OK, $this_era->[0];
        constant->import( $this_era->[0], $this_era->[0]);
    }

    for(0..$#south_regime_eras) {
        my $this_era = $south_regime_eras[$_];
    
        my $start_date = DateTime->new(
            year      => $this_era->[1]->[0],
            month     => $this_era->[1]->[1],
            day       => $this_era->[1]->[2],
            time_zone => 'Asia/Tokyo'
        );

        my $end_date;
        if ($_ == $#south_regime_eras) {
            $end_date = DateTime::Infinite::Future->new();
        } else {
            my $next_era = $south_regime_eras[$_ + 1];
            if ($this_era->[2]) {
                $end_date = DateTime->new(
                    year      => $this_era->[2]->[0],
                    month     => $this_era->[2]->[1],
                    day       => $this_era->[2]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            } else {
                $end_date = DateTime->new(
                    year      => $next_era->[1]->[0],
                    month     => $next_era->[1]->[1],
                    day       => $next_era->[1]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            }
        }

        # we create the dates in Asia/Tokyo time, but for calculation
        # we really want them to be in UTC.
#        $start_date->set_time_zone('UTC');
#        $end_date->set_time_zone('UTC');
        push @SOUTH_REGIME_ERAS, __PACKAGE__->new(
            start => $start_date, end => $end_date, id => $this_era->[0]
        );
        push @EXPORT_OK, $this_era->[0];
        constant->import( $this_era->[0], $this_era->[0]);
    }
}

1;

__END__

=head1 NAME

DateTime::Calendar::Japanese::Era - DateTime Extension for Japanese Eras

=head1 SYNOPSIS

  use DateTime::Calendar::Japanese::Era;
  my $era = DateTime::Calendar::Japanese::Era->lookup_by_date(
    datetime => DateTime->new(year => 1990)
  );
  my $era = DateTime::Calendar::Japanese::Era->lookup_by_id(
    id => HEISEI_ERA
  );

  my $era = DateTime::Calendar::Japanese::Era->new(
    id => ...,
    start => ...,
    end   => ...
  );

  $era->id;
  $era->start;
  $era->end;

=head1 DESCRIPTION

Japan traditionally used an "era" system since 645. In modern days
(since the Meiji era) eras can only be renewed when a new emperor succeeds his
predecessor. Until then new eras were proclaimed for various reasons,
including the succession of the shogunate during the Tokugawa shogunate.

=head1 NORTH AND SOUTH REGIMES

During the 60 years between 1331 and 1392, there were two regimes in Japan
claiming to be the rightful successor to the imperial throne. During this
period of time, there were two sets of eras in use.

This module by default uses eras from the North regime, but you can get the
South regime's eras if you explicitly specify it:

  use DateTime::Calendar::Japanese::Era qw(SOUTH_REGIME);
  my $dt = DateTime->new( year => 1342 );
  $era = DateTime::Calendar::Japanese::Era->lookup_by_date(
    datetime => $dt,
    regime   => SOUTH_REGIME
  );

=head1 FUNCTIONS

=head2 lookup_by_id

  $heisei = DateTime::Calendar::Japanese::Era->lookup_by_id(
    id => HEISEI
  );

Returns the era associated with the given era id. The IDs are provided by
DateTime::Calendar::Japanese::Era as constants.

=head2 lookup_by_datetime

  my $dt = DateTime->new(year => 1990);
  $heisei = DateTime::Calendar::Japanese::Era->lookup_by_datetime(
     datetime => $dt
  );

Returns the era associate with the given date. 

=head1 CONSANTS

Below are the list of era IDs that are known to this module:

  TAIKA
  HAKUCHI
  SHUCHOU
  TAIHOU
  KEIUN
  WADOU
  REIKI
  YOUROU
  JINKI
  TENPYOU
  TENPYOUKANPOU
  TENPYOUSHOUHOU
  TENPYOUJOUJI
  TENPYOUJINGO
  JINGOKEIUN
  HOUKI
  TENNOU
  ENRYAKU
  DAIDOU
  KOUNIN
  TENCHOU
  JOUWA
  KASHOU
  NINJU
  SAIKOU
  TENNAN
  JOUGAN
  GANGYOU
  NINNA
  KANPYOU
  SHOUTAI
  ENGI
  ENCHOU
  SHOUHEI
  TENGYOU
  TENRYAKU
  TENTOKU
  OUWA
  KOUHOU
  ANNA
  TENROKU
  TENNEN
  JOUGEN1
  TENGEN
  EIKAN
  KANNA
  EIEN
  EISO
  SHOURYAKU
  CHOUTOKU
  CHOUHOU
  KANKOU
  CHOUWA
  KANNIN
  JIAN
  MANJU
  CHOUGEN
  CHOURYAKU
  CHOUKYU
  KANTOKU
  EISHOU1
  TENGI
  KOUHEI
  JIRYAKU
  ENKYUU
  JOUHOU
  JOURYAKU
  EIHOU
  OUTOKU
  KANJI
  KAHOU
  EICHOU
  JOUTOKU
  KOUWA
  CHOUJI
  KAJOU
  TENNIN
  TENNEI
  EIKYU
  GENNEI
  HOUAN
  TENJI
  DAIJI
  TENSHOU1
  CHOUSHOU
  HOUEN
  EIJI
  KOUJI1
  TENNYOU
  KYUAN
  NINPEI
  KYUJU
  HOUGEN
  HEIJI
  EIRYAKU
  OUHOU
  CHOUKAN
  EIMAN
  NINNAN
  KAOU
  SHOUAN1
  ANGEN
  JISHOU
  YOUWA
  JUEI
  GENRYAKU
  BUNJI
  KENKYU
  SHOUJI
  KENNIN
  GENKYU
  KENNEI
  JOUGEN2
  KENRYAKU
  KENPOU
  JOUKYU
  JOUOU1
  GENNIN
  KAROKU
  ANTEI
  KANKI
  JOUEI
  TENPUKU
  BUNRYAKU
  KATEI
  RYAKUNIN
  ENNOU
  NINJI
  KANGEN
  HOUJI
  KENCHOU
  KOUGEN
  SHOUKA
  SHOUGEN
  BUNNOU
  KOUCHOU
  BUNNEI
  KENJI
  KOUAN1
  SHOUOU
  EININ
  SHOUAN2
  KENGEN
  KAGEN
  TOKUJI
  ENKYOU1
  OUCHOU
  SHOUWA1
  BUNPOU
  GENNOU
  GENKOU
  SHOUCHU
  KARYAKU
  GENTOKU
  SHOUKEI
  RYAKUOU
  KOUEI
  JOUWA1
  KANNOU
  BUNNNA
  ENBUN
  KOUAN2
  JOUJI
  OUAN
  EIWA
  KOURYAKU
  EITOKU
  SHITOKU
  KAKEI
  KOUOU
  MEITOKU
  OUEI
  SHOUCHOU
  EIKYOU
  KAKITSU
  BUNNAN
  HOUTOKU
  KYOUTOKU
  KOUSHOU
  CHOUROKU
  KANSHOU
  BUNSHOU
  OUNIN
  BUNMEI
  CHOUKYOU
  ENTOKU
  MEIOU
  BUNKI
  EISHOU2
  DAIEI
  KYOUROKU
  TENBUN
  KOUJI2
  EIROKU
  GENKI
  TENSHOU2
  BUNROKU
  KEICHOU
  GENNA
  KANNEI
  SHOUHOU
  KEIAN
  JOUOU2
  MEIREKI
  MANJI
  KANBUN
  ENPOU
  TENNA
  JOUKYOU
  GENROKU
  HOUEI
  SHOUTOKU
  KYOUHO
  GENBUN
  KANPOU
  ENKYOU2
  KANNEN
  HOUREKI
  MEIWA
  ANNEI
  TENMEI
  KANSEI
  KYOUWA
  BUNKA
  BUNSEI
  TENPOU
  KOUKA
  KAEI
  ANSEI
  MANNEI
  BUNKYU
  GENJI
  KEIOU
  MEIJI
  TAISHO
  SHOUWA2
  HEISEI

These are the eras from the South regime during 1331-1392

  S_GENKOU
  S_KENMU
  S_EIGEN
  S_KOUKOKU
  S_SHOUHEI
  S_KENTOKU
  S_BUNCHU
  S_TENJU
  S_KOUWA
  S_GENCHU

=head1 AUTHOR

Daisuke Maki E<lt>daisuke@cpan.orgE<gt>

=cut

