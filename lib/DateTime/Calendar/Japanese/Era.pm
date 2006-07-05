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
        [ 'TAIKA',          'Âç²½',     [ 645, 8, 18 ]],
        [ 'HAKUCHI',        'Çòðµ',     [ 650, 4, 23 ], [ 654, 11, 26 ]],
        [ 'SHUCHOU',        '¼ëÄ»',     [ 686, 9, 15 ]],
        [ 'TAIHOU',         'ÂçÊõ',     [ 701, 6, 5 ]],
        [ 'KEIUN',          '·Ä±À',     [ 704, 7, 19 ]],
        [ 'WADOU',          'ÏÂÆ¼',     [ 708, 2, 10 ]],
        [ 'REIKI',          'Îîµµ',     [ 715, 11, 6 ]],
        [ 'YOUROU',         'ÍÜÏ·',     [ 717, 12, 27 ]],
        [ 'JINKI',          '¿Àµµ',     [ 724, 4, 5 ]],
        [ 'TENPYOU',        'Å·Ê¿',     [ 729, 10, 5 ]],
        [ 'TENPYOUKANPOU',  'Å·Ê¿´¶Êõ', [ 749, 6, 7 ]],
        [ 'TENPYOUSHOUHOU', 'Å·Ê¿¾¡Êõ', [ 749, 8, 22 ]],
        [ 'TENPYOUJOUJI',   'Å·Ê¿Êõ»ú', [ 757, 10, 9 ]],
        [ 'TENPYOUJINGO',   'Å·Ê¿¿À¸î', [ 765, 2, 5 ]],
        [ 'JINGOKEIUN',     '¿À¸î·Ê±À', [ 767, 10, 16 ]],
        [ 'HOUKI',          'Êõµµ',     [ 770, 11, 26 ]],
        [ 'TENNOU',         'Å·±þ',     [ 781, 2, 2 ]],
        [ 'ENRYAKU',        '±äÎñ',     [ 782, 10, 4 ]],
        [ 'DAIDOU',         'ÂçÆ±',     [ 806, 7, 11 ]],
        [ 'KOUNIN',         '¹°¿Î',     [ 810, 11, 22 ]],
        [ 'TENCHOU',        'Å·Ä¹',     [ 823, 2, 22 ]],
        [ 'JOUWA1',         '¾µÏÂ',     [ 834, 2, 18 ]],
        [ 'KASHOU',         '²Å¾Í',     [ 848, 8, 18 ]],
        [ 'NINJU',          '¿Î¼÷',     [ 851, 7, 4 ]],
        [ 'SAIKOU',         'ÀÆ¹Õ',     [ 855, 1, 25 ]],
        [ 'TENNAN',         'Å·°Â',     [ 857, 4, 22 ]],
        [ 'JOUGAN',         'Äç´Ñ',     [ 859, 6, 22 ]],
        [ 'GANGYOU',        '¸µ·Ä',     [ 877, 6, 4 ]],
        [ 'NINNA',          '¿ÎÏÂ',     [ 885, 4, 13 ]],
        [ 'KANPYOU',        '´²Ê¿',     [ 889, 7, 2 ]],
        [ 'SHOUTAI',        '¾»ÂÙ',     [ 898, 6, 22 ]],
        [ 'ENGI',           '±ä´î',     [ 901, 9, 5 ]],
        [ 'ENCHOU',         '±äÄ¹',     [ 923, 6, 2 ]],
        [ 'JOUHEI',         '¾µÊ¿',     [ 931, 6, 19 ]],
        [ 'TENGYOU',        'Å··Ä',     [ 938, 7, 26 ]],
        [ 'TENRYAKU',       'Å·Îñ',     [ 947, 6, 18 ]],
        [ 'TENTOKU',        'Å·ÆÁ',     [ 957, 12, 25 ]],
        [ 'OUWA',           '±þÏÂ',     [ 961, 4, 8 ]],
        [ 'KOUHOU',         '¹¯ÊÝ',     [ 964, 8, 24 ]],
        [ 'ANNA',           '°ÂÏÂ',     [ 968, 10, 12 ]],
        [ 'TENROKU',        'Å·Ï½',     [ 970, 6, 6 ]],
        [ 'TENNEN',         'Å·±ä',     [ 974, 1, 20 ]],
        [ 'JOUGEN1',        'Äç¸µ',     [ 976, 9, 13 ]],
        [ 'TENGEN',         'Å·¸µ',     [ 979, 2, 3 ]],
        [ 'EIKAN',          '±Ê´Ñ',     [ 983, 6, 3 ]],
        [ 'KANNA',          '´²ÏÂ',     [ 985, 6, 22 ]],
        [ 'EIEN',           '±Ê±ä',     [ 987, 6, 8 ]],
        [ 'EISO',           '±Êã¯',     [ 989, 10, 14 ]],
        [ 'SHOURYAKU',      'ÀµÎñ',     [ 990, 12, 31 ]],
        [ 'CHOUTOKU',       'Ä¹ÆÁ',     [ 995, 4, 28 ]],
        [ 'CHOUHOU',        'Ä¹ÊÝ',     [ 999, 2, 6 ]],
        [ 'KANKOU',         '´²¹°',     [ 1004, 9, 12 ]],
        [ 'CHOUWA',         'Ä¹ÏÂ',     [ 1013, 1, 14 ]],
        [ 'KANNIN',         '´²¿Î',     [ 1017, 6, 25 ]],
        [ 'JIAN',           '¼£°Â',     [ 1021, 3, 23 ]],
        [ 'MANJU',          'Ëü¼÷',     [ 1024, 9, 23 ]],
        [ 'CHOUGEN',        'Ä¹¸µ',     [ 1028, 9, 21 ]],
        [ 'CHOURYAKU',      'Ä¹Îñ',     [ 1037, 6, 12 ]],
        [ 'CHOUKYU',        'Ä¹µ×',     [ 1040, 12, 21 ]],
        [ 'KANTOKU',        '´²ÆÁ',     [ 1045, 1, 20 ]],
        [ 'EISHOU1',        '±Ê¾µ',     [ 1046, 6, 26 ]],
        [ 'TENGI',          'Å·´î',     [ 1053, 2, 7 ]],
        [ 'KOUHEI',         '¹¯Ê¿',     [ 1058, 10, 24 ]],
        [ 'JIRYAKU',        '¼£Îñ',     [ 1065, 10,  9 ]],
        [ 'ENKYUU',         '±äµ×',     [ 1069, 6, 10 ]],
        [ 'JOUHOU',         '¾µÊÝ',     [ 1074, 10, 21 ]],
        [ 'JOURYAKU',       '¾µÎñ',     [ 1078, 1, 9 ]],
        [ 'EIHOU',          '±ÊÊÝ',     [ 1081, 4, 27 ]],
        [ 'OUTOKU',         '±þÆÁ',     [ 1084, 4, 19 ]],
        [ 'KANJI',          '´²¼£',     [ 1087, 6, 15 ]],
        [ 'KAHOU',          '²ÅÊÝ',     [ 1095, 1, 29 ]],
        [ 'EICHOU',         '±ÊÄ¹',     [ 1097, 1, 8 ]],
        [ 'JOUTOKU',        '¾µÆÁ',     [ 1098, 1, 1 ]],
        [ 'KOUWA',          '¹¯ÏÂ',     [ 1099, 10, 20 ]],
        [ 'CHOUJI',         'Ä¹¼£',     [ 1104, 4, 13 ]],
        [ 'KAJOU',          '²Å¾µ',     [ 1106, 6, 18 ]], # XXX - KASHOU?
        [ 'TENNIN',         'Å·¿Î',     [ 1108, 10, 15 ]],
        [ 'TENNEI',         'Å·±Ê',     [ 1110, 9, 5 ]],
        [ 'EIKYU',          '±Êµ×',     [ 1113, 9, 1 ]],
        [ 'GENNEI',         '¸µ±Ê',     [ 1118, 5, 31 ]],
        [ 'HOUAN',          'ÊÝ°Â',     [ 1120, 6, 14 ]],
        [ 'TENJI',          'Å·¼£',     [ 1124, 5, 24 ]],
        [ 'DAIJI',          'Âç¼£',     [ 1126, 2, 22 ]],
        [ 'TENSHOU1',       'Å·¾µ',     [ 1131, 3, 6 ]],
        [ 'CHOUSHOU',       'Ä¹¾µ',     [ 1132, 9, 28 ]],
        [ 'HOUEN',          'ÊÝ±ä',     [ 1135, 6, 16 ]],
        [ 'EIJI',           '±Ê¼£',     [ 1141, 9, 18 ]],
        [ 'KOUJI1',         '¹¯¼£',     [ 1142, 6, 29 ]],
        [ 'TENNYOU',        'Å·ÍÜ',     [ 1144, 5, 4 ]],
        [ 'KYUAN',          'µ×°Â',     [ 1145, 9, 17 ]],
        [ 'NINPEI',         '¿ÎÊ¿',     [ 1151, 2, 20 ]],
        [ 'KYUJU',          'µ×¼÷',     [ 1154, 12, 11 ]],
        [ 'HOUGEN',         'ÊÝ¸µ',     [ 1156, 6, 23 ]],
        [ 'HEIJI',          'Ê¿¼£',     [ 1159, 6, 14 ]],
        [ 'EIRYAKU',        '±ÊÎñ',     [ 1160, 2, 25 ]],
        [ 'OUHOU',          '±þÊÝ',     [ 1161, 10, 30 ]],
        [ 'CHOUKAN',        'Ä¹´²',     [ 1163, 6, 9 ]],
        [ 'EIMAN',          '±ÊËü',     [ 1165, 7, 21 ]],
        [ 'NINNAN',         '¿Î°Â',     [ 1166, 10, 29 ]],
        [ 'KAOU',           '²Å±þ',     [ 1169, 6, 11 ]],
        [ 'SHOUAN1',        '¾µ°Â',     [ 1171, 7, 2 ]],
        [ 'ANGEN',          '°Â¸µ',     [ 1175, 9, 21 ]],
        [ 'JISHOU',         '¼£¾µ',     [ 1177, 10, 3 ]],
        [ 'YOUWA',          'ÍÜÏÂ',     [ 1181, 9, 1 ]],
        [ 'JUEI',           '¼÷±Ê',     [ 1182, 8, 4 ]],
        [ 'GENRYAKU',       '¸µÎñ',     [ 1184, 6, 2 ]],
        [ 'BUNJI',          'Ê¸¼£',     [ 1185, 10, 15 ]],
        [ 'KENKYU',         '·úµ×',     [ 1190, 6, 21 ]],
        [ 'SHOUJI',         'Àµ¼£',     [ 1199, 6, 28 ]],
        [ 'KENNIN',         '·ú¿Î',     [ 1201, 5, 23 ]],
        [ 'GENKYU',         '¸µµ×',     [ 1204, 4, 28 ]],
        [ 'KENNEI',         '·ú±Ê',     [ 1206, 7, 11 ]],
        [ 'JOUGEN2',        '¾µ¸µ',     [ 1207, 12, 22 ]],
        [ 'KENRYAKU',       '·úÎñ',     [ 1211, 4, 29 ]],
        [ 'KENPOU',         '·úÊÝ',     [ 1214, 1, 24 ]],
        [ 'JOUKYU',         '¾µµ×',     [ 1219, 6, 2 ]],
        [ 'JOUOU1',         'Äç±þ',     [ 1222, 5, 31 ]],
        [ 'GENNIN',         '¸µ¿Î',     [ 1225, 1, 7 ]],
        [ 'KAROKU',         '²ÅÏ½',     [ 1225, 7, 3 ]],
        [ 'ANTEI',          '°ÂÄç',     [ 1228, 1, 24 ]],
        [ 'KANKI',          '´²´î',     [ 1229, 5, 6 ]],
        [ 'JOUEI',          'Äç±Ê',     [ 1232, 5, 29 ]],
        [ 'TENPUKU',        'Å·Ê¡',     [ 1233, 6, 30 ]],
        [ 'BUNRYAKU',       'Ê¸Îñ',     [ 1235, 1, 2 ]],
        [ 'KATEI',          '²ÅÄ÷',     [ 1235, 11, 7 ]],
        [ 'RYAKUNIN',       'Îñ¿Î',     [ 1239, 1, 6 ]],
        [ 'ENNOU',          '±ä±þ',     [ 1239, 4, 18 ]],
        [ 'NINJI',          '¿Î¼£',     [ 1240, 9, 10 ]],
        [ 'KANGEN',         '´²¸µ',     [ 1243, 4, 23 ]],
        [ 'HOUJI',          'Êõ¼£',     [ 1247, 5, 11 ]],
        [ 'KENCHOU',        '·úÄ¹',     [ 1249, 5, 8 ]],
        [ 'KOUGEN',         '¹¯¸µ',     [ 1256, 11, 29 ]],
        [ 'SHOUKA',         'Àµ²Å',     [ 1257, 5, 6 ]],
        [ 'SHOUGEN',        'Àµ¸µ',     [ 1259, 5, 26 ]],
        [ 'BUNNOU',         'Ê¸±þ',     [ 1260, 5, 30 ]],
        [ 'KOUCHOU',        '¹°Ä¹',     [ 1261, 4, 27 ]],
        [ 'BUNNEI',         'Ê¸±Ê',     [ 1264, 5, 2 ]],
        [ 'KENJI',          '·ò¼£',     [ 1275, 6, 26 ]],
        [ 'KOUAN1',         '¹°°Â',     [ 1278, 4, 28 ]],
        [ 'SHOUOU',         'Àµ±þ',     [ 1288, 7, 4 ]],
        [ 'EININ',          '±Ê¿Î',     [ 1293, 10, 12 ]],
        [ 'SHOUAN2',        'Àµ°Â',     [ 1299, 6, 30 ]],
        [ 'KENGEN',         '´¥¸µ',     [ 1303, 1, 17 ]],
        [ 'KAGEN',          '²Å¸µ',     [ 1303, 9, 24 ]],
        [ 'TOKUJI',         'ÆÁ¼£',     [ 1307, 1, 26 ]],
        [ 'ENKYOU1',        '±ä·Ä',     [ 1308, 11, 30 ]],
        [ 'OUCHOU',         '±þÄ¹',     [ 1311, 6, 23 ]],
        [ 'SHOUWA1',        'ÀµÏÂ',     [ 1312, 6, 3 ]],
        [ 'BUNPOU',         'Ê¸ÊÝ',     [ 1317, 3, 24 ]],
        [ 'GENNOU',         '¸µ±þ',     [ 1319, 6, 24 ]],
        [ 'GENKOU',         '¸µµü',     [ 1321, 4, 28 ]],
        [ 'SHOUCHU',        'ÀµÃæ',     [ 1325, 1, 2 ]],
        [ 'KARYAKU',        '²ÅÎñ',     [ 1326, 7, 4 ]],
        [ 'GENTOKU',        '¸µÆÁ',     [ 1329, 10, 29 ]],
        [ 'SHOUKEI',        'Àµ·Ä',     [ 1332, 6, 29 ]],
        [ 'RYAKUOU',        'Îñ±þ',     [ 1338, 10, 19 ]],
        [ 'KOUEI',          '¹¯±Ê',     [ 1342, 7, 7 ]],
        [ 'JOUWA2',         'ÄçÏÂ',     [ 1345, 12, 22 ]],
        [ 'KANNOU',         '´Ñ±þ',     [ 1350, 5, 11 ]],
        [ 'BUNNNA',         'Ê¸ÏÂ',     [ 1352, 11, 12 ]], # XXX - BUNWA ?
        [ 'ENBUN',          '±äÊ¸',     [ 1356, 6, 5 ]],
        [ 'KOUAN2',         '¹¯°Â',     [ 1361, 6, 10 ]],
        [ 'JOUJI',          'Äç¼£',     [ 1362, 11, 17 ]],
        [ 'OUAN',           '±þ°Â',     [ 1368, 4, 13 ]],
        [ 'EIWA',           '±ÊÏÂ',     [ 1375, 5, 5 ]],
        [ 'KOURYAKU',       '¹¯Îñ',     [ 1379, 5, 16 ]],
        [ 'EITOKU',         '±ÊÆÁ',     [ 1381, 4, 26 ]],
        [ 'SHITOKU',        '»êÆÁ',     [ 1384, 4, 25 ]],
        [ 'KAKEI',          '²Å·Ä',     [ 1387, 10, 13 ]],
        [ 'KOUOU',          '¹¯±þ',     [ 1389, 4, 13 ]],
        [ 'MEITOKU',        'ÌÀÆÁ',     [ 1390, 5, 18 ]],
        [ 'OUEI',           '±þ±Ê',     [ 1394, 9, 8 ]],
        [ 'SHOUCHOU',       'ÀµÄ¹',     [ 1428, 6, 18 ]],
        [ 'EIKYOU',         '±Êµý',     [ 1429, 11, 10 ]],
        [ 'KAKITSU',        '²ÅµÈ',     [ 1441, 4, 16 ]],
        [ 'BUNNAN',         'Ê¸°Â',     [ 1444, 4, 1 ]],
        [ 'HOUTOKU',        'ÊõÆÁ',     [ 1449, 9, 23 ]],
        [ 'KYOUTOKU',       'µýÆÁ',     [ 1452, 9, 17 ]],
        [ 'KOUSHOU',        '¹¯Àµ',     [ 1455, 9, 15 ]],
        [ 'CHOUROKU',       'Ä¹Ï½',     [ 1457, 11, 23 ]],
        [ 'KANSHOU',        '´²Àµ',     [ 1461, 1, 10 ]],
        [ 'BUNSHOU',        'Ê¸Àµ',     [ 1466, 4, 21 ]],
        [ 'OUNIN',          '±þ¿Î',     [ 1467, 5, 16 ]],
        [ 'BUNMEI',         'Ê¸ÌÀ',     [ 1469, 6, 16 ]],
        [ 'CHOUKYOU',       'Ä¹µý',     [ 1487, 9, 15 ]],
        [ 'ENTOKU',         '±äÆÁ',     [ 1489, 10, 23 ]],
        [ 'MEIOU',          'ÌÀ±þ',     [ 1492, 9, 19 ]],
        [ 'BUNKI',          'Ê¸µµ',     [ 1501, 4, 26 ]],
        [ 'EISHOU2',        '±ÊÀµ',     [ 1504, 4, 24 ]],
        [ 'DAIEI',          'Âç±Ê',     [ 1521, 11, 1 ]],
        [ 'KYOUROKU',       'µýÏ½',     [ 1528, 10, 12 ]],
        [ 'TENBUN',         'Å·Ê¸',     [ 1532, 10, 7 ]],
        [ 'KOUJI2',         '¹°¼£',     [ 1555, 12, 16 ]],
        [ 'EIROKU',         '±ÊÏ½',     [ 1558, 4, 26 ]],
        [ 'GENKI',          '¸µµµ',     [ 1570, 7, 5 ]],
        [ 'TENSHOU2',       'Å·Àµ',     [ 1573, 10, 3 ]],
        [ 'BUNROKU',        'Ê¸Ï½',     [ 1593, 1, 9 ]],
        [ 'KEICHOU',        '·ÄÄ¹',     [ 1596, 12, 16 ]],
        [ 'GENNA',          '¸µÏÂ',     [ 1615, 9, 5 ]],
        [ 'KANNEI',         '´²±Ê',     [ 1624, 5, 16 ]],
        [ 'SHOUHOU',        'ÀµÊÝ',     [ 1645, 1, 13 ]],
        [ 'KEIAN',          '·Ä°Â',     [ 1648, 4, 7 ]],
        [ 'JOUOU2',         '¾µ±þ',     [ 1652, 11, 18 ]],
        [ 'MEIREKI',        'ÌÀÎñ',     [ 1655, 6, 16 ]],
        [ 'MANJI',          'Ëü¼£',     [ 1658, 9, 19 ]],
        [ 'KANBUN',         '´²Ê¸',     [ 1661, 6, 21 ]],
        [ 'ENPOU',          '±äÊõ',     [ 1673, 11, 28 ]],
        [ 'TENNA',          'Å·ÏÂ',     [ 1681, 12, 8 ]],
        [ 'JOUKYOU',        'Äçµý',     [ 1684, 5, 4 ]],
        [ 'GENROKU',        '¸µÏ½',     [ 1688, 11, 22 ]],
        [ 'HOUEI',          'Êõ±Ê',     [ 1704, 5, 15 ]],
        [ 'SHOUTOKU',       'ÀµÆÁ',     [ 1711, 7, 10 ]],
        [ 'KYOUHOU',        'µýÊÝ',     [ 1716, 8, 9 ]],
        [ 'GENBUN',         '¸µÊ¸',     [ 1736, 7, 6 ]],
        [ 'KANPOU',         '´²ÊÝ',     [ 1741, 5, 11 ]],
        [ 'ENKYOU2',        '±äµý',     [ 1744, 5, 2 ]],
        [ 'KANNEN',         '´²±ä',     [ 1748, 9, 4 ]],
        [ 'HOUREKI',        'ÊõÎñ',     [ 1751, 12, 14 ]],
        [ 'MEIWA',          'ÌÀÏÂ',     [ 1764, 7, 29 ]],
        [ 'ANNEI',          '°Â±Ê',     [ 1773, 1, 8 ]],
        [ 'TENMEI',         'Å·ÌÀ',     [ 1781, 5, 24 ]],
        [ 'KANSEI',         '´²À¯',     [ 1801, 3, 16 ]],
        [ 'KYOUWA',         'µýÏÂ',     [ 1802, 3, 17 ]],
        [ 'BUNKA',          'Ê¸²½',     [ 1804, 4, 3 ]],
        [ 'BUNSEI',         'Ê¸À¯',     [ 1818, 6, 20 ]],
        [ 'TENPOU',         'Å·ÊÝ',     [ 1831, 1, 21 ]],
        [ 'KOUKA',          '¹°²½',     [ 1845, 1, 8 ]],
        [ 'KAEI',           '²Å±Ê',     [ 1848, 4, 30 ]],
        [ 'ANSEI',          '°ÂÀ¯',     [ 1855, 1, 14 ]],
        [ 'MANNEI',         'Ëü±ä',     [ 1860, 5, 8 ]],  # XXX - MAN-EN?
        [ 'BUNKYU',         'Ê¸µ×',     [ 1861, 4, 28 ]],
        [ 'GENJI',          '¸µ¼£',     [ 1864, 4, 25 ]],
        [ 'KEIOU',          '·Ä±þ',     [ 1865, 6, 23 ]],
        [ 'MEIJI',          'ÌÀ¼£',     [ 1868, 10, 23 ] ],
        [ 'TAISHO',         'ÂçÀµ',     [ 1912,  7, 30 ] ],
        [ 'SHOUWA2',        '¾¼ÏÂ',     [ 1926, 12, 25 ] ],
        [ 'HEISEI',         'Ê¿À®',     [ 1989,  1,  8 ] ],
    );
    my @south_regime_eras = (
        [ 'S_GENKOU',       '¸µ¹°',     [ 1331, 11, 7 ]],
        [ 'S_KENMU',        '·úÉð',     [ 1334, 3, 12 ]],
        [ 'S_EIGEN',        '±ä¸µ',     [ 1336, 4, 19 ]], # XXX - EN-GEN?
        [ 'S_KOUKOKU',      '¶½¹ñ',     [ 1340, 7, 1 ]],
        [ 'S_SHOUHEI',      'ÀµÊ¿',     [ 1347, 1, 27 ]],
        [ 'S_KENTOKU',      '·úÆÁ',     [ 1370, 9, 21 ]],
        [ 'S_BUNCHU',       'Ê¸Ãæ',     [ 1372, 6, 10 ]],
        [ 'S_TENJU',        'Å·¼ø',     [ 1375, 8, 2 ]],
        [ 'S_KOUWA',        '¹°ÏÂ',     [ 1381, 4, 12 ]],
        [ 'S_GENCHU',       '¸µÃæ',     [ 1384, 6, 24 ], [ 1392, 11, 27 ]],
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
    name => "Ê¿À®"
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
    name => 'Ê¿À®',
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

