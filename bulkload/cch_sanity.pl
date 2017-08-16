%urls=(
"http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?taxon_name=ramulosissima", "49",
"http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?county=BUTTE=&collector=Cleveland", "24",
"http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?year=1833","44",
"http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?year=1850&make_tax_list=1&before_after=1","77",
"http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?year=1933&month=2&day=5", "28",
"http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?lat_min=41.51&lat_max=41.69&long_min=-122.98&long_max=-122.74","34",
"http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?coll_num=1000", "112",
"http://ucjeps.berkeley.edu/cgi-bin/get_smasch_county.pl?taxon_id=12924","19",
"http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?taxon_name=Amaranthus+hybridus&county=06083","37",
);
use LWP::Simple qw(get);
foreach(keys(%urls)){
$url=$_;
$expected_rows=$urls{$_};
$got=get($url);
$rows=($got=~s/<[lt][ir]//g);
print <<EOP;
$rows rows\texpected $expected_rows\t $_
EOP
}
