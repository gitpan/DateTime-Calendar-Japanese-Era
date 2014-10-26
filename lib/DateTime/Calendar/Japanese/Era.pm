# $Id: /mirror/DateTime-Calendar-Japanese-Era/lib/DateTime/Calendar/Japanese/Era.pm 1672 2005-09-06T00:55:49.000000Z lestrrat  $
#
# Copyright (c) 2004-2005 Daisuke Maki <dmaki@cpan.org>
# All rights reserved.

package DateTime::Calendar::Japanese::Era;
use strict;
use vars qw(@ISA @EXPORT_OK $VERSION);
use Exporter;
my $HAS_ENCODE;
BEGIN
{
    @ISA       = 'Exporter';
    @EXPORT_OK = qw(SOUTH_REGIME NORTH_REGIME);
    $VERSION   = '0.06';

    $HAS_ENCODE = eval { require Encode };
}
use DateTime;
use DateTime::Infinite;
use Params::Validate();
use constant +{
    NORTH_REGIME       => 1,
    SOUTH_REGIME       => 2,
    SOUTH_REGIME_START => DateTime->new(
        year => 1331, 
        month => 11, 
        day => 7, 
        time_zone => 'Asia/Tokyo'),
    SOUTH_REGIME_END => DateTime->new(
        year => 1392, 
        month => 11, 
        day => 27,
        time_zone => 'Asia/Tokyo'),
};

my(%ERAS_BY_ID, %ERAS_BY_NAME, @ERAS_BY_CENTURY, @SOUTH_REGIME_ERAS);

my %NewValidate = (
    id => { type => Params::Validate::SCALAR() },
    name => { type => Params::Validate::SCALAR() },
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
sub name  { $_[0]->{name}  }

sub clone
{
    my $self = shift;
    return ref($self)->new(
        id    => $self->id,
        name  => $self->name,
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

    return exists $ERAS_BY_ID{ $args{id} } ?
        $ERAS_BY_ID{ $args{id} }->clone : ();
}

sub lookup_by_name
{
    my $class = shift;
    my %args  = Params::Validate::validate(@_, {
        name => { type => Params::Validate::SCALAR() },
        encoding => { optional => 1 },
    });
    my $name = $args{encoding} && $HAS_ENCODE ?
        Encode::decode($args{encoding}, $args{name}) : $args{name};

    return exists $ERAS_BY_NAME{ $name } ?
         $ERAS_BY_NAME{ $name }->clone : ();
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
        name   => { type => Params::Validate::SCALAR(), optional => 1 },
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

    $ERAS_BY_NAME{ $era->name } = $era;

    my $start_century = int($era->start->year() / 100);
    my $end_century   = int($era->end->year() / 100);

    $ERAS_BY_CENTURY[ $start_century ] ||= [];
    push @{ $ERAS_BY_CENTURY[ $start_century ] }, $era;

    if ($start_century != $end_century && $end_century !~ /^-?inf/) {
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

    my $ID    = 0;
    my $NAME  = 1;
    my $START = 2;
    my $END   = 3;
    my @predefined_eras = (
        # ID                NAME        START           END
        [ 'TAIKA',          '�粽',     [ 645, 8, 18 ]],
        [ 'HAKUCHI',        '���',     [ 650, 4, 23 ], [ 654, 11, 26 ]],
        [ 'SHUCHOU',        '��Ļ',     [ 686, 9, 15 ]],
        [ 'TAIHOU',         '����',     [ 701, 6, 5 ]],
        [ 'KEIUN',          '�ı�',     [ 704, 7, 19 ]],
        [ 'WADOU',          '��Ƽ',     [ 708, 2, 10 ]],
        [ 'REIKI',          '�',     [ 715, 11, 6 ]],
        [ 'YOUROU',         '��Ϸ',     [ 717, 12, 27 ]],
        [ 'JINKI',          '����',     [ 724, 4, 5 ]],
        [ 'TENPYOU',        'ŷʿ',     [ 729, 10, 5 ]],
        [ 'TENPYOUKANPOU',  'ŷʿ����', [ 749, 6, 7 ]],
        [ 'TENPYOUSHOUHOU', 'ŷʿ����', [ 749, 8, 22 ]],
        [ 'TENPYOUJOUJI',   'ŷʿ����', [ 757, 10, 9 ]],
        [ 'TENPYOUJINGO',   'ŷʿ����', [ 765, 2, 5 ]],
        [ 'JINGOKEIUN',     '����ʱ�', [ 767, 10, 16 ]],
        [ 'HOUKI',          '����',     [ 770, 11, 26 ]],
        [ 'TENNOU',         'ŷ��',     [ 781, 2, 2 ]],
        [ 'ENRYAKU',        '����',     [ 782, 10, 4 ]],
        [ 'DAIDOU',         '��Ʊ',     [ 806, 7, 11 ]],
        [ 'KOUNIN',         '����',     [ 810, 11, 22 ]],
        [ 'TENCHOU',        'ŷĹ',     [ 823, 2, 22 ]],
        [ 'JOUWA1',         '����',     [ 834, 2, 18 ]],
        [ 'KASHOU',         '�ž�',     [ 848, 8, 18 ]],
        [ 'NINJU',          '�μ�',     [ 851, 7, 4 ]],
        [ 'SAIKOU',         '�ƹ�',     [ 855, 1, 25 ]],
        [ 'TENNAN',         'ŷ��',     [ 857, 4, 22 ]],
        [ 'JOUGAN',         '���',     [ 859, 6, 22 ]],
        [ 'GANGYOU',        '����',     [ 877, 6, 4 ]],
        [ 'NINNA',          '����',     [ 885, 4, 13 ]],
        [ 'KANPYOU',        '��ʿ',     [ 889, 7, 2 ]],
        [ 'SHOUTAI',        '����',     [ 898, 6, 22 ]],
        [ 'ENGI',           '���',     [ 901, 9, 5 ]],
        [ 'ENCHOU',         '��Ĺ',     [ 923, 6, 2 ]],
        [ 'JOUHEI',         '��ʿ',     [ 931, 6, 19 ]],
        [ 'TENGYOU',        'ŷ��',     [ 938, 7, 26 ]],
        [ 'TENRYAKU',       'ŷ��',     [ 947, 6, 18 ]],
        [ 'TENTOKU',        'ŷ��',     [ 957, 12, 25 ]],
        [ 'OUWA',           '����',     [ 961, 4, 8 ]],
        [ 'KOUHOU',         '����',     [ 964, 8, 24 ]],
        [ 'ANNA',           '����',     [ 968, 10, 12 ]],
        [ 'TENROKU',        'ŷϽ',     [ 970, 6, 6 ]],
        [ 'TENNEN',         'ŷ��',     [ 974, 1, 20 ]],
        [ 'JOUGEN1',        '�縵',     [ 976, 9, 13 ]],
        [ 'TENGEN',         'ŷ��',     [ 979, 2, 3 ]],
        [ 'EIKAN',          '�ʴ�',     [ 983, 6, 3 ]],
        [ 'KANNA',          '����',     [ 985, 6, 22 ]],
        [ 'EIEN',           '�ʱ�',     [ 987, 6, 8 ]],
        [ 'EISO',           '���',     [ 989, 10, 14 ]],
        [ 'SHOURYAKU',      '����',     [ 990, 12, 31 ]],
        [ 'CHOUTOKU',       'Ĺ��',     [ 995, 4, 28 ]],
        [ 'CHOUHOU',        'Ĺ��',     [ 999, 2, 6 ]],
        [ 'KANKOU',         '����',     [ 1004, 9, 12 ]],
        [ 'CHOUWA',         'Ĺ��',     [ 1013, 1, 14 ]],
        [ 'KANNIN',         '����',     [ 1017, 6, 25 ]],
        [ 'JIAN',           '����',     [ 1021, 3, 23 ]],
        [ 'MANJU',          '����',     [ 1024, 9, 23 ]],
        [ 'CHOUGEN',        'Ĺ��',     [ 1028, 9, 21 ]],
        [ 'CHOURYAKU',      'Ĺ��',     [ 1037, 6, 12 ]],
        [ 'CHOUKYU',        'Ĺ��',     [ 1040, 12, 21 ]],
        [ 'KANTOKU',        '����',     [ 1045, 1, 20 ]],
        [ 'EISHOU1',        '�ʾ�',     [ 1046, 6, 26 ]],
        [ 'TENGI',          'ŷ��',     [ 1053, 2, 7 ]],
        [ 'KOUHEI',         '��ʿ',     [ 1058, 10, 24 ]],
        [ 'JIRYAKU',        '����',     [ 1065, 10,  9 ]],
        [ 'ENKYUU',         '���',     [ 1069, 6, 10 ]],
        [ 'JOUHOU',         '����',     [ 1074, 10, 21 ]],
        [ 'JOURYAKU',       '����',     [ 1078, 1, 9 ]],
        [ 'EIHOU',          '����',     [ 1081, 4, 27 ]],
        [ 'OUTOKU',         '����',     [ 1084, 4, 19 ]],
        [ 'KANJI',          '����',     [ 1087, 6, 15 ]],
        [ 'KAHOU',          '����',     [ 1095, 1, 29 ]],
        [ 'EICHOU',         '��Ĺ',     [ 1097, 1, 8 ]],
        [ 'JOUTOKU',        '����',     [ 1098, 1, 1 ]],
        [ 'KOUWA',          '����',     [ 1099, 10, 20 ]],
        [ 'CHOUJI',         'Ĺ��',     [ 1104, 4, 13 ]],
        [ 'KAJOU',          '�ž�',     [ 1106, 6, 18 ]], # XXX - KASHOU?
        [ 'TENNIN',         'ŷ��',     [ 1108, 10, 15 ]],
        [ 'TENNEI',         'ŷ��',     [ 1110, 9, 5 ]],
        [ 'EIKYU',          '�ʵ�',     [ 1113, 9, 1 ]],
        [ 'GENNEI',         '����',     [ 1118, 5, 31 ]],
        [ 'HOUAN',          '�ݰ�',     [ 1120, 6, 14 ]],
        [ 'TENJI',          'ŷ��',     [ 1124, 5, 24 ]],
        [ 'DAIJI',          '�缣',     [ 1126, 2, 22 ]],
        [ 'TENSHOU1',       'ŷ��',     [ 1131, 3, 6 ]],
        [ 'CHOUSHOU',       'Ĺ��',     [ 1132, 9, 28 ]],
        [ 'HOUEN',          '�ݱ�',     [ 1135, 6, 16 ]],
        [ 'EIJI',           '�ʼ�',     [ 1141, 9, 18 ]],
        [ 'KOUJI1',         '����',     [ 1142, 6, 29 ]],
        [ 'TENNYOU',        'ŷ��',     [ 1144, 5, 4 ]],
        [ 'KYUAN',          '�װ�',     [ 1145, 9, 17 ]],
        [ 'NINPEI',         '��ʿ',     [ 1151, 2, 20 ]],
        [ 'KYUJU',          '�׼�',     [ 1154, 12, 11 ]],
        [ 'HOUGEN',         '�ݸ�',     [ 1156, 6, 23 ]],
        [ 'HEIJI',          'ʿ��',     [ 1159, 6, 14 ]],
        [ 'EIRYAKU',        '����',     [ 1160, 2, 25 ]],
        [ 'OUHOU',          '����',     [ 1161, 10, 30 ]],
        [ 'CHOUKAN',        'Ĺ��',     [ 1163, 6, 9 ]],
        [ 'EIMAN',          '����',     [ 1165, 7, 21 ]],
        [ 'NINNAN',         '�ΰ�',     [ 1166, 10, 29 ]],
        [ 'KAOU',           '�ű�',     [ 1169, 6, 11 ]],
        [ 'SHOUAN1',        '����',     [ 1171, 7, 2 ]],
        [ 'ANGEN',          '�¸�',     [ 1175, 9, 21 ]],
        [ 'JISHOU',         '����',     [ 1177, 10, 3 ]],
        [ 'YOUWA',          '����',     [ 1181, 9, 1 ]],
        [ 'JUEI',           '����',     [ 1182, 8, 4 ]],
        [ 'GENRYAKU',       '����',     [ 1184, 6, 2 ]],
        [ 'BUNJI',          'ʸ��',     [ 1185, 10, 15 ]],
        [ 'KENKYU',         '����',     [ 1190, 6, 21 ]],
        [ 'SHOUJI',         '����',     [ 1199, 6, 28 ]],
        [ 'KENNIN',         '����',     [ 1201, 5, 23 ]],
        [ 'GENKYU',         '����',     [ 1204, 4, 28 ]],
        [ 'KENNEI',         '����',     [ 1206, 7, 11 ]],
        [ 'JOUGEN2',        '����',     [ 1207, 12, 22 ]],
        [ 'KENRYAKU',       '����',     [ 1211, 4, 29 ]],
        [ 'KENPOU',         '����',     [ 1214, 1, 24 ]],
        [ 'JOUKYU',         '����',     [ 1219, 6, 2 ]],
        [ 'JOUOU1',         '���',     [ 1222, 5, 31 ]],
        [ 'GENNIN',         '����',     [ 1225, 1, 7 ]],
        [ 'KAROKU',         '��Ͻ',     [ 1225, 7, 3 ]],
        [ 'ANTEI',          '����',     [ 1228, 1, 24 ]],
        [ 'KANKI',          '����',     [ 1229, 5, 6 ]],
        [ 'JOUEI',          '���',     [ 1232, 5, 29 ]],
        [ 'TENPUKU',        'ŷʡ',     [ 1233, 6, 30 ]],
        [ 'BUNRYAKU',       'ʸ��',     [ 1235, 1, 2 ]],
        [ 'KATEI',          '����',     [ 1235, 11, 7 ]],
        [ 'RYAKUNIN',       '���',     [ 1239, 1, 6 ]],
        [ 'ENNOU',          '���',     [ 1239, 4, 18 ]],
        [ 'NINJI',          '�μ�',     [ 1240, 9, 10 ]],
        [ 'KANGEN',         '����',     [ 1243, 4, 23 ]],
        [ 'HOUJI',          '����',     [ 1247, 5, 11 ]],
        [ 'KENCHOU',        '��Ĺ',     [ 1249, 5, 8 ]],
        [ 'KOUGEN',         '����',     [ 1256, 11, 29 ]],
        [ 'SHOUKA',         '����',     [ 1257, 5, 6 ]],
        [ 'SHOUGEN',        '����',     [ 1259, 5, 26 ]],
        [ 'BUNNOU',         'ʸ��',     [ 1260, 5, 30 ]],
        [ 'KOUCHOU',        '��Ĺ',     [ 1261, 4, 27 ]],
        [ 'BUNNEI',         'ʸ��',     [ 1264, 5, 2 ]],
        [ 'KENJI',          '��',     [ 1275, 6, 26 ]],
        [ 'KOUAN1',         '����',     [ 1278, 4, 28 ]],
        [ 'SHOUOU',         '����',     [ 1288, 7, 4 ]],
        [ 'EININ',          '�ʿ�',     [ 1293, 10, 12 ]],
        [ 'SHOUAN2',        '����',     [ 1299, 6, 30 ]],
        [ 'KENGEN',         '����',     [ 1303, 1, 17 ]],
        [ 'KAGEN',          '�Ÿ�',     [ 1303, 9, 24 ]],
        [ 'TOKUJI',         '����',     [ 1307, 1, 26 ]],
        [ 'ENKYOU1',        '���',     [ 1308, 11, 30 ]],
        [ 'OUCHOU',         '��Ĺ',     [ 1311, 6, 23 ]],
        [ 'SHOUWA1',        '����',     [ 1312, 6, 3 ]],
        [ 'BUNPOU',         'ʸ��',     [ 1317, 3, 24 ]],
        [ 'GENNOU',         '����',     [ 1319, 6, 24 ]],
        [ 'GENKOU',         '����',     [ 1321, 4, 28 ]],
        [ 'SHOUCHU',        '����',     [ 1325, 1, 2 ]],
        [ 'KARYAKU',        '����',     [ 1326, 7, 4 ]],
        [ 'GENTOKU',        '����',     [ 1329, 10, 29 ]],
        [ 'SHOUKEI',        '����',     [ 1332, 6, 29 ]],
        [ 'RYAKUOU',        '���',     [ 1338, 10, 19 ]],
        [ 'KOUEI',          '����',     [ 1342, 7, 7 ]],
        [ 'JOUWA2',         '����',     [ 1345, 12, 22 ]],
        [ 'KANNOU',         '�ѱ�',     [ 1350, 5, 11 ]],
        [ 'BUNNNA',         'ʸ��',     [ 1352, 11, 12 ]], # XXX - BUNWA ?
        [ 'ENBUN',          '��ʸ',     [ 1356, 6, 5 ]],
        [ 'KOUAN2',         '����',     [ 1361, 6, 10 ]],
        [ 'JOUJI',          '�缣',     [ 1362, 11, 17 ]],
        [ 'OUAN',           '����',     [ 1368, 4, 13 ]],
        [ 'EIWA',           '����',     [ 1375, 5, 5 ]],
        [ 'KOURYAKU',       '����',     [ 1379, 5, 16 ]],
        [ 'EITOKU',         '����',     [ 1381, 4, 26 ]],
        [ 'SHITOKU',        '����',     [ 1384, 4, 25 ]],
        [ 'KAKEI',          '�ŷ�',     [ 1387, 10, 13 ]],
        [ 'KOUOU',          '����',     [ 1389, 4, 13 ]],
        [ 'MEITOKU',        '����',     [ 1390, 5, 18 ]],
        [ 'OUEI',           '����',     [ 1394, 9, 8 ]],
        [ 'SHOUCHOU',       '��Ĺ',     [ 1428, 6, 18 ]],
        [ 'EIKYOU',         '�ʵ�',     [ 1429, 11, 10 ]],
        [ 'KAKITSU',        '�ŵ�',     [ 1441, 4, 16 ]],
        [ 'BUNNAN',         'ʸ��',     [ 1444, 4, 1 ]],
        [ 'HOUTOKU',        '����',     [ 1449, 9, 23 ]],
        [ 'KYOUTOKU',       '����',     [ 1452, 9, 17 ]],
        [ 'KOUSHOU',        '����',     [ 1455, 9, 15 ]],
        [ 'CHOUROKU',       'ĹϽ',     [ 1457, 11, 23 ]],
        [ 'KANSHOU',        '����',     [ 1461, 1, 10 ]],
        [ 'BUNSHOU',        'ʸ��',     [ 1466, 4, 21 ]],
        [ 'OUNIN',          '����',     [ 1467, 5, 16 ]],
        [ 'BUNMEI',         'ʸ��',     [ 1469, 6, 16 ]],
        [ 'CHOUKYOU',       'Ĺ��',     [ 1487, 9, 15 ]],
        [ 'ENTOKU',         '����',     [ 1489, 10, 23 ]],
        [ 'MEIOU',          '����',     [ 1492, 9, 19 ]],
        [ 'BUNKI',          'ʸ��',     [ 1501, 4, 26 ]],
        [ 'EISHOU2',        '����',     [ 1504, 4, 24 ]],
        [ 'DAIEI',          '���',     [ 1521, 11, 1 ]],
        [ 'KYOUROKU',       '��Ͻ',     [ 1528, 10, 12 ]],
        [ 'TENBUN',         'ŷʸ',     [ 1532, 10, 7 ]],
        [ 'KOUJI2',         '����',     [ 1555, 12, 16 ]],
        [ 'EIROKU',         '��Ͻ',     [ 1558, 4, 26 ]],
        [ 'GENKI',          '����',     [ 1570, 7, 5 ]],
        [ 'TENSHOU2',       'ŷ��',     [ 1573, 10, 3 ]],
        [ 'BUNROKU',        'ʸϽ',     [ 1593, 1, 9 ]],
        [ 'KEICHOU',        '��Ĺ',     [ 1596, 12, 16 ]],
        [ 'GENNA',          '����',     [ 1615, 9, 5 ]],
        [ 'KANNEI',         '����',     [ 1624, 5, 16 ]],
        [ 'SHOUHOU',        '����',     [ 1645, 1, 13 ]],
        [ 'KEIAN',          '�İ�',     [ 1648, 4, 7 ]],
        [ 'JOUOU2',         '����',     [ 1652, 11, 18 ]],
        [ 'MEIREKI',        '����',     [ 1655, 6, 16 ]],
        [ 'MANJI',          '����',     [ 1658, 9, 19 ]],
        [ 'KANBUN',         '��ʸ',     [ 1661, 6, 21 ]],
        [ 'ENPOU',          '����',     [ 1673, 11, 28 ]],
        [ 'TENNA',          'ŷ��',     [ 1681, 12, 8 ]],
        [ 'JOUKYOU',        '���',     [ 1684, 5, 4 ]],
        [ 'GENROKU',        '��Ͻ',     [ 1688, 11, 22 ]],
        [ 'HOUEI',          '����',     [ 1704, 5, 15 ]],
        [ 'SHOUTOKU',       '����',     [ 1711, 7, 10 ]],
        [ 'KYOUHOU',        '����',     [ 1716, 8, 9 ]],
        [ 'GENBUN',         '��ʸ',     [ 1736, 7, 6 ]],
        [ 'KANPOU',         '����',     [ 1741, 5, 11 ]],
        [ 'ENKYOU2',        '���',     [ 1744, 5, 2 ]],
        [ 'KANNEN',         '����',     [ 1748, 9, 4 ]],
        [ 'HOUREKI',        '����',     [ 1751, 12, 14 ]],
        [ 'MEIWA',          '����',     [ 1764, 7, 29 ]],
        [ 'ANNEI',          '�±�',     [ 1773, 1, 8 ]],
        [ 'TENMEI',         'ŷ��',     [ 1781, 5, 24 ]],
        [ 'KANSEI',         '����',     [ 1801, 3, 16 ]],
        [ 'KYOUWA',         '����',     [ 1802, 3, 17 ]],
        [ 'BUNKA',          'ʸ��',     [ 1804, 4, 3 ]],
        [ 'BUNSEI',         'ʸ��',     [ 1818, 6, 20 ]],
        [ 'TENPOU',         'ŷ��',     [ 1831, 1, 21 ]],
        [ 'KOUKA',          '����',     [ 1845, 1, 8 ]],
        [ 'KAEI',           '�ű�',     [ 1848, 4, 30 ]],
        [ 'ANSEI',          '����',     [ 1855, 1, 14 ]],
        [ 'MANNEI',         '����',     [ 1860, 5, 8 ]],  # XXX - MAN-EN?
        [ 'BUNKYU',         'ʸ��',     [ 1861, 4, 28 ]],
        [ 'GENJI',          '����',     [ 1864, 4, 25 ]],
        [ 'KEIOU',          '�ı�',     [ 1865, 6, 23 ]],
        [ 'MEIJI',          '����',     [ 1868, 10, 23 ] ],
        [ 'TAISHO',         '����',     [ 1912,  7, 30 ] ],
        [ 'SHOUWA2',        '����',     [ 1926, 12, 25 ] ],
        [ 'HEISEI',         'ʿ��',     [ 1989,  1,  8 ] ],
    );
    my @south_regime_eras = (
        [ 'S_GENKOU',       '����',     [ 1331, 11, 7 ]],
        [ 'S_KENMU',        '����',     [ 1334, 3, 12 ]],
        [ 'S_EIGEN',        '�丵',     [ 1336, 4, 19 ]], # XXX - EN-GEN?
        [ 'S_KOUKOKU',      '����',     [ 1340, 7, 1 ]],
        [ 'S_SHOUHEI',      '��ʿ',     [ 1347, 1, 27 ]],
        [ 'S_KENTOKU',      '����',     [ 1370, 9, 21 ]],
        [ 'S_BUNCHU',       'ʸ��',     [ 1372, 6, 10 ]],
        [ 'S_TENJU',        'ŷ��',     [ 1375, 8, 2 ]],
        [ 'S_KOUWA',        '����',     [ 1381, 4, 12 ]],
        [ 'S_GENCHU',       '����',     [ 1384, 6, 24 ], [ 1392, 11, 27 ]],
    );

    for(0..$#predefined_eras) {
        my $this_era = $predefined_eras[$_];
    
        my $start_date = DateTime->new(
            year      => $this_era->[$START]->[0],
            month     => $this_era->[$START]->[1],
            day       => $this_era->[$START]->[2],
            time_zone => 'Asia/Tokyo'
        );

        my $end_date;
        if ($_ == $#predefined_eras) {
            $end_date = DateTime::Infinite::Future->new();
        } else {
            my $next_era = $predefined_eras[$_ + 1];
            if ($this_era->[$END]) {
                $end_date = DateTime->new(
                    year      => $this_era->[$END]->[0],
                    month     => $this_era->[$END]->[1],
                    day       => $this_era->[$END]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            } else {
                $end_date = DateTime->new(
                    year      => $next_era->[$START]->[0],
                    month     => $next_era->[$START]->[1],
                    day       => $next_era->[$START]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            }
        }

        # we create the dates in Asia/Tokyo time, but for calculation
        # we really want them to be in UTC.
#        $start_date->set_time_zone('UTC');
#        $end_date->set_time_zone('UTC');
    
        __PACKAGE__->register_era(
            id    => $this_era->[$ID],
            name  => $HAS_ENCODE ? Encode::decode('euc-jp', $this_era->[$NAME]) : $this_era->[$NAME],
            start => $start_date,
            end   => $end_date
        );
        push @EXPORT_OK, $this_era->[$ID];
        constant->import( $this_era->[$ID], $this_era->[$ID]);
    }

    for(0..$#south_regime_eras) {
        my $this_era = $south_regime_eras[$_];
    
        my $start_date = DateTime->new(
            year      => $this_era->[$START]->[0],
            month     => $this_era->[$START]->[1],
            day       => $this_era->[$START]->[2],
            time_zone => 'Asia/Tokyo'
        );

        my $end_date;
        if ($_ == $#south_regime_eras) {
            $end_date = DateTime::Infinite::Future->new();
        } else {
            my $next_era = $south_regime_eras[$_ + 1];
            if ($this_era->[$END]) {
                $end_date = DateTime->new(
                    year      => $this_era->[$END]->[0],
                    month     => $this_era->[$END]->[1],
                    day       => $this_era->[$END]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            } else {
                $end_date = DateTime->new(
                    year      => $next_era->[$START]->[0],
                    month     => $next_era->[$START]->[1],
                    day       => $next_era->[$START]->[2],
                    time_zone => 'Asia/Tokyo'
                );
            }
        }

        # we create the dates in Asia/Tokyo time, but for calculation
        # we really want them to be in UTC.
#        $start_date->set_time_zone('UTC');
#        $end_date->set_time_zone('UTC');
        push @SOUTH_REGIME_ERAS, __PACKAGE__->new(
            id => $this_era->[$ID],
            name => $HAS_ENCODE ? Encode::decode('euc-jp', $this_era->[$NAME]) : $this_era->[$NAME],
            start => $start_date, 
            end => $end_date, 
        );
        push @EXPORT_OK, $this_era->[$ID];
        constant->import( $this_era->[$ID], $this_era->[$ID]);
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
  my $era = DateTime::Calendar::Japanese::Era->lookup_by_name(
    name => "ʿ��"
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

=head1 METHODS

=head2 new

=head2 id

=head2 name

=head2 start

=head2 end

=head2 clone

=head1 FUNCTIONS

=head2 register_era

Registers a new era object in the lookup table.

=head2 lookup_by_id

  $heisei = DateTime::Calendar::Japanese::Era->lookup_by_id(
    id => HEISEI
  );

Returns the era associated with the given era id. The IDs are provided by
DateTime::Calendar::Japanese::Era as constants.

=head2 lookup_by_name

  $heisei = DateTime::Calendar::Japanese::Era->lookup_by_name(
    name => 'ʿ��',
    encoding => 'euc-jp',
  );

Returns the era associated with the given era name. By default UTF-8 is
assumed for the name parameter. You can override this by specifying the
'encoding' parameter.

=head2 lookup_by_date

  my $dt = DateTime->new(year => 1990);
  $heisei = DateTime::Calendar::Japanese::Era->lookup_by_date(
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

