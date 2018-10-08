#!/usr/bin/perl
$CP{"JEPS101133"}=qq{http://calphotos.berkeley.edu/cgi/img_query?query_src=photos_custom&seq_num=263479&one=T};
$detail="new_detail.pl";
$start_time=time;
$begin_time=times();

$null_search_warning="";
$comment_day="";
$reg="";
$bad_coords="";
$caller="";
$end_time="";
$before="";
$bgcount="";

$axxxxx="";
%CULT_nos=();
@residue=();
$cult_id="";
$stop_word_warning="";
$search_hints="";
$because="";
$searched_for="";
$current_request="";
$county="";
$req_source="";
$lookfor="";
$collector="";
$aid="";
$year="";
$month="";
$day="";
$loc="";
$coll_num="";
$max_return="";
$make_tax_list="";
$before_after="";
$last_comments="";
$v_restrict="";
$include_nn="";
$include_vtm="";
$include_cult="";
$geo_only="";
$geo_no="";
$include_CNPS="";
$include_weed="";
$include_baja="";
$sugg_loc="";
%fips_string=();
use CGI;
$query = new CGI;                        # create new CGI object
if($ENV{'REMOTE_ADDR'} && $ENV{'REMOTE_ADDR'}=~ /(216\.52\.28\.197|207\.46\.55\.27|207\.46\.55\.30|207\.46\.55\.28|207\.46\.55\.31|207\.46\.55\.29|207\.46\.92\.19|207\.46\.92\.17|207\.46\.92\.16|207\.46\.92\.18|216\.52\.28\.200)/){
print $query->header unless $header_printed++;                    # create the HTTP header

print<<EOP;
<h2>The Consortium interface is undergoing repairs. Sorry for the
inconvenience.</h2>
<a href="http://ucjeps.berkeley.edu/consortium/about.html">Contact us if
you're seeing this notice</a>
EOP

}
else{
#Output file to store data for Berkeley Mapper
	$Search_page="/consortium/index.html";
$tab_file_name="CHC_" . substr($start_time,6,4) . $$ . ".txt";
$YF_tab_file_name="CHC_" . substr($start_time,6,4) . $$ . ".txt";
$map_file_path="/BerkeleyMapper/";
$map_file_out="$map_file_path$tab_file_name";
$map_file_URL="http://ucjeps.berkeley.edu$map_file_out";
$YF_map_file_out="$map_file_path$YF_tab_file_name";
$YF_map_file_URL="http://ucjeps.berkeley.edu$YF_map_file_out";

#data files
$data_path	="/usr/local/web/ucjeps_data/ucjeps_data/";
$comment_hash	="${data_path}suggs_tally";
$CDL_nomsyn_file	="${data_path}CDL_nomsyn";
$CDL_DBM_file	="${data_path}CDL_DBM";
$CDL_taxon_id_file	="${data_path}CDL_TID_TO_NAME";
$CDL_coll_number_file	="${data_path}CDL_coll_number";
$CDL_date_simple_file	="${data_path}CDL_date_simple";
$CDL_date_range_file	="${data_path}CDL_date_range";
$CDL_county_file	="${data_path}CDL_county";
$image_file	="${data_path}SMASCH_IMAGES";
$CDL_date_recno_file	= "${data_path}CDL_date_recno";
$CDL_bad_coords	= "${data_path}all_bad_coords.cch";

###I think "riverside" refers to the "R" checkbox
#$riverside=1;
 if($query->param('DL')=~/UCR/){
$riverside=1;
}

if(!defined ($query->param('collyear'))){
	$year = "";
}
$axxxxx = $query->param('collyear');


###The Yellow Flag field, which comes from the search page
if($query->param('YF')=~/1/){
	$YF=1; 
}
else{
	$YF=0;
}

###I think tns refers to taxonomic synonyms
$tns=$query->param('tns');
$tns=lc($tns);

###high elevation and low elevation parameters, which can come from the search page
if($query->param('hi_e')=~/\d/){
	$hi_e= $query->param('hi_e');
	$hi_e=~s/[^.0-9]-//g;
}
if($query->param('lo_e')=~/\d/){
	$lo_e= $query->param('lo_e');
	$lo_e=~s/[^.0-9]-//g;
}
$hi_e=$lo_e unless $hi_e=~/\d/;
$lo_e=$hi_e unless $lo_e=~/\d/;
%elev_acc=&get_elev_acc($lo_e, $hi_e) if $hi_e;

###The lat_min and lat_max do not come from the index search page, unless they somehow come from "sugg_loc"
if($query->param('lat_min')){
print $query->header unless $header_printed++;                    # create the HTTP header
$lat_min=sprintf("%.2f", $query->param('lat_min'));
$lat_max=sprintf("%.2f", $query->param('lat_max'));
$long_min=sprintf("%.2f", $query->param('long_min'));
$long_max=sprintf("%.2f", $query->param('long_max'));
$q_coords="&lat_min=$lat_min&lat_max=$lat_max&long_min=$long_min&long_max=$long_max";
$current_request.=$q_coords;
}
else{$q_coords="";}

###This "non-native" list apparently comes from GBIF, and has not been updated since 2008
###something should probably be done about that
if($query->param('non_native')){
	$include_nn=1;
	open(IN,"${data_path}gbif_tid.txt") || die $!;
	while(<IN>){
		chomp;
		$gbif_nn{$_}++;
	}
	close(IN);
}
else{
	$include_nn=0;
}

###for the VTM checkbox. List probably never needs to be updated
if($query->param('VTM')){
	$include_vtm=1;
	open(IN,"${data_path}VTM_nos.txt") || die $!;
	while(<IN>){
		chomp;
		$VTM_nos{$_}++;
	}
	close(IN);
}
else{
	$include_vtm=0;
}

###for the cultivated checkbox. List updated by consort_bulkload.pl
if($query->param('cultivated')){
	$include_cult=1;
		open(IN,"${data_path}CDL_cultivated_ids.txt") || die $!;
	while(<IN>){
		chomp;
		($cult_id,@residue)=split(/\t/);
		$CULT_nos{$cult_id}++;
	}
	close(IN);
}
else{
	$include_cult=0;
}


###fips is used the "County Map" at "get_smasch_county.pl", which uses five digit codes for counties instead of county names.
###for example, one would draw Alameda and Alpine county with "http://ucjeps.berkeley.edu/cgi-bin/get_smasch_county.pl?fips=0600306001"
###Although I have removed that option from this script, get_smash_county.pl is still linked from the Interchange (get JOI) and at least one person still uses it (Feb 2015)
###so I have to keep the fips_trans functionality for now
%fips_trans=&load_fips;
%CTF=reverse(%fips_trans);

$chc_header= &load_header;
$consortium_footer=&load_footer;

$common_html_head=<<EOH;
<html>
<head>
<Meta NAME="ROBOTS" CONTENT="NOINDEX, NOFOLLOW">
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>UC/JEPS: Consortium Search Results</title>
<link href="http://ucjeps.berkeley.edu/consortium/style_consortium.css" rel="stylesheet" type="text/css">
</head>
<body>
EOH


#multiplication sign for hybridity
$times=CGI::Util::unescape("%D7") || "flabba";
use BerkeleyDB;
tie(%suggs, "BerkeleyDB::Hash", -Filename=>"$comment_hash", -Flags=>DB_RDONLY)|| die "$!";

tie(%image_location, "BerkeleyDB::Hash", -Filename=>"$image_file", -Flags=>DB_RDONLY)|| die "$!";

@result=();
@QLOG=();
@map_results=();


###CNPS list file, which should be updated and/or integrated with the eFlora's CNPS taxon indication
if($query->param('CNPS_listed')){
	$include_CNPS=1;
	open(IN,"${data_path}cnps_taxon_ids.txt") || die $!;
	while(<IN>){
		chomp;
		$CNPS_tid{$_}++;
	}
	close(IN);
}
else{
	$include_CNPS=0;
}

###Cal-IPC weed file. Same deal as CNPS list
if($query->param('weed')){
	$include_weed=1;
	open(IN,"${data_path}CDL_weed_tid") || die $!;
	while(<IN>){
		chomp;
		$weed_tid{$_}++;
	}
	close(IN);
}
else{
	$include_weed=0;
}

if($query->param('baja')){
	$include_baja=1;
}
else{
	$include_baja=0;
}


$last_comments=$query->param('last_comments') if $query->param('last_comments');
$make_tax_list=$query->param('make_tax_list') if $query->param('make_tax_list');

my $pers;
my $nonprofit;
my $fed;
my $state;
my $consult;
my $profit;


#$pers = $query->param('personal') if $query->param('personal');
#$nonprofit = $query->param('nonprofit') if $query->param('nonprofit');
#$fed = $query->param('federal') if $query->param('federal');
#$state = $query->param('state') if $query->param('state');
#$consult = $query->param('consult') if $query->param('consult');
#$profit = $query->param('private') if $query->param('private');
if($query->param('personal')){
	$pers = $query->param('personal');
}
else{
	$pers = "";
}

if($query->param('nonprofit')){
	$nonprofit = $query->param('nonprofit');
}
else{
	$nonprofit = "";
}

if($query->param('federal')){
	$fed = $query->param('federal');
}
else{
	$fed = "";
}

if($query->param('state')){
	$state = $query->param('state');
}
else{
	$state = "";
}

if($query->param('consult')){
	$consult = $query->param('consult');
}
else{
	$consult = "";
}

if($query->param('private')){
	$profit = $query->param('private');
}
else{
	$profit = "";
}

###This is the "Geographic Region" box. I think I'm going to hide it from the search page for now, and see if anyone misses it
###and then maybe lose it
###except some of this code supports the "search by bounding box", which is linked somewhere else
if($mapper_loc=$query->param('sugg_loc')){
	print $query->header unless $header_printed++;                    # create the HTTP header

	$sugg_loc=$mapper_loc;
	open(IN,"${data_path}CDL_region_list.txt") || die $!;

	{
		local($/)="";
		while(<IN>){
			if(m!^$mapper_loc!o){
				if(m/Error Radius/){
					($reg,$lat,$long,$error)=split(/\n/,$_);
					$mapper_loc=join(" ",$lat, $long, $error);
				}
			else{
				if(m/Latitude: (.*)\nLongitude: (.*)/){
					$mapper_loc=join(" ",$1, $2);
				}
			}
			last;
			}
		}
	}
	#print "I see you're using BerkeleyMapper and it's saying $mapper_loc";
	if($mapper_loc=~/de: ([0-9.]+)[^0-9]+Longitude: ([0-9.-]+)[^0-9]+Meters: (\d+)/){
		$clone_lat=$1;
		$clone_long=$2;
		$clone_extent=$3;
		$degrees_per_meter= 1/(40000000/360);
		$lat_extent= $clone_extent * $degrees_per_meter;
		$long_extent=$lat_extent / cos((3.14/180) * $clone_lat);
		$lat_min=sprintf("%.2f", $clone_lat - $lat_extent);
		$lat_max=sprintf("%.2f", $clone_lat + $lat_extent);
		$long_min=sprintf("%.2f", $clone_long - $long_extent);
		$long_max=sprintf("%.2f", $clone_long + $long_extent);
		$sugg_loc="&lat_min=$lat_min&lat_max=$lat_max&long_min=$long_min&long_max=$long_max";
	}
	#Coordinate: 37.87654 / -121.93076 (3077 meters radius)
	elsif($mapper_loc=~/([0-9.]+)[^0-9]+ *\/ *(-?[0-9.]+)[^0-9]+[ (]+(\d+) *[mM]eter/){
		$clone_lat=$1;
		$clone_long=$2;
		$clone_extent=$3;
		$degrees_per_meter= 1/(40000000/360);
		$lat_extent= $clone_extent * $degrees_per_meter;
		$long_extent=$lat_extent / cos((3.14/180) * $clone_lat);
		$lat_min=sprintf("%.2f", $clone_lat - $lat_extent);
		$lat_max=sprintf("%.2f", $clone_lat + $lat_extent);
		$long_min=sprintf("%.2f", $clone_long - $long_extent);
		$long_max=sprintf("%.2f", $clone_long + $long_extent);
		$sugg_loc="&lat_min=$lat_min&lat_max=$lat_max&long_min=$long_min&long_max=$long_max";
	}
	elsif ($mapper_loc=~/([0-9.]+) ([0-9.-]+) ([0-9.-]+) ([0-9.-]+)/){
		$lat_min=sprintf("%.2f", $2);
		$lat_max=sprintf("%.2f", $1);
		$long_min=sprintf("%.2f", $4);
		$long_max=sprintf("%.2f", $3);
		$sugg_loc="&lat_min=$lat_min&lat_max=$lat_max&long_min=$long_min&long_max=$long_max";
	}#old berkeley mapper format?
	elsif($mapper_loc=~/te: ([0-9.]+)[^0-9-]+([0-9.-]+)[^0-9]+(\d+) meters/){
		$clone_lat=$1;
		$clone_long=$2;
		$clone_extent=$3;
		$degrees_per_meter= 1/(40000000/360);
		$lat_extent= $clone_extent * $degrees_per_meter;
		$long_extent=$lat_extent / cos((3.14/180) * $clone_lat);
		$lat_min=sprintf("%.2f", $clone_lat - $lat_extent);
		$lat_max=sprintf("%.2f", $clone_lat + $lat_extent);
		$long_min=sprintf("%.2f", $clone_long - $long_extent);
		$long_max=sprintf("%.2f", $clone_long + $long_extent);
		$sugg_loc="&lat_min=$lat_min&lat_max=$lat_max&long_min=$long_min&long_max=$long_max";
	}
	else{
		print "mapper_loc : $mapper_loc <<";
	}
	my %h_long ;
	my %h_lat;
	tie %h_long, 'BerkeleyDB::Hash', -Filename   => "${data_path}CDL_long", -Flags      => DB_RDONLY
	or print "Cannot open ${data_path}CDL_long: $!\n" ;
	tie %h_lat, 'BerkeleyDB::Hash',
	-Filename   => "${data_path}CDL_lat",
	-Flags      => DB_RDONLY
	or print "Cannot open ${data_path}CDL_lat: $!\n" ;

	if($lat_max - $lat_min > 3 || $long_max - $long_min > 3){
		print <<EIO;
		<h2>Make the box dimensions less than 3 degrees, please</h2>
EIO
	}
	elsif( $long_min > $long_max || $lat_min > $lat_max){
	print <<EIO;
	<h2>Are your coordinates reversed?</h2>
EIO
	}
	else{
		foreach(keys(%h_lat)){
			if($_ >= $lat_min && $_ <=$lat_max){
				grep($cumulat{$_}++,split(/\t/,$h_lat{$_}));
			}
		}
		foreach(keys(%h_long)){
			if($_ >= $long_min && $_ <=$long_max){
				grep($cumulong{$_}++,split(/\t/,$h_long{$_}));
			}
		}
		while(($key,$value)=each(%cumulat)){
			if ($cumulong{$key}){
				#print $key;
				$region{$key}++ ;
			}
		}
	}
}

###$geo_only and $geo_no are the "specimens with coordinates" and "specimens without coordinates" checkboxes
$geo_only=$query->param('geo_only') if $query->param('geo_only');
$geo_no=$query->param('geo_no') if $query->param('geo_no');
if($geo_only || $geo_no){
	tie %CDL_GEO, "BerkeleyDB::Hash", -Filename => "${data_path}CDL_GEO", -Flags=>DB_RDONLY or die "Cannot open file CDL_GEO: $! $BerkeleyDB::Error\n" ;
	#print "GEO: ",$CDL_GEO{'SBBG6141'};
}

%taxonomic_list=();

###"county" comes in as a fips number from get_smaschcounty.pl
###Which is still in the interchange (get_cpn.pl) and evidently at least one person still uses (Feb 2015)
###So it stays for now
if( $query->param('county')){
@county= $query->param('county');
	if($query->param('county')=~/^\d+$/){
		foreach(@county){
			$_=$fips_trans{$_};
		}
	}
}

grep(s/[^A-Za-z ]//g,@county);
grep(ucfirst($_),@county);
if(@county){
	$county=join("&county=",@county);
}
else{
	$county="";
}
$lookfor	=$query->param('taxon_name') || "";

$lookfor="Apiaceae" if $lookfor=~/Umbelliferae/i;
$lookfor="Arecaceae" if $lookfor=~/Palmae/i;
$lookfor="Asteraceae" if $lookfor=~/Compositae/i;
$lookfor="Brassicaceae" if $lookfor=~/Cruciferae/i;
$lookfor="Clusiaceae" if $lookfor=~/Guttiferae/i;
$lookfor="Fabaceae" if $lookfor=~/Leguminosae/i;
$lookfor="Lamiaceae" if $lookfor=~/Labiatae/i;
$lookfor="Poaceae" if $lookfor=~/Gramineae/i;
$lookfor=~s/moreh[usa]+$/moreh/i;
$lookfor=~s/Quercus moreh$/Quercus x moreh/i;
$lookfor=uc($lookfor) if $lookfor=~/aceae$/i;
#print "$lookfor";

if($query->param('source')){
@source	=$query->param('source');
$source	=$source[$#source];
}
$collector	=$query->param('collector') if $query->param('collector');
$aid	=$query->param('accn_num') if $query->param('accn_num');

$sort_field	=$query->param('SO') || "0" ;
if($sort_field=~s/-//){
$sort_direction="reverse";
}
else{
$sort_direction="forward";
$SD[$sort_field]="-";
}

###sort parameters
if($query->param('sort_submit')){
	$sort_submit_number=$query->param('sort_submit');
	%sort_submit=("Accession ID"=>10,"Determination"=>0,"Collector"=>1,"Collection Date"=>5,"Collection Number"=>3,"County"=>8,"Locality"=>20,"Elevation in meters"=>9);
	$sort_field=$sort_submit{$sort_submit_number};
}

if($query->param('collyear')){
	$year = $query->param('collyear');
}
else{
	$year = "";
}

if($query->param('collmonth')){
	$month = $query->param('collmonth');
}
else{
	$month = "";
}

if($query->param('collday')){
	$day = $query->param('collday');
}
else{
	$day = "";
}

#$year	= $query->param('year') if $query->param('year');
#$month	= $query->param('month') if $query->param('month');
#$day	= $query->param('day') if $query->param('day');
$loc	= $query->param('loc') if $query->param('loc');
$ejdate	= $query->param('ejdate') if $query->param('ejdate');
$before_after	= $query->param('before_after') if $query->param('before_after');
#$before	=$query->param('before') if $query->param('before');
$check_all	= $query->param('check_all') if $query->param('check_all');

#Array containing accession_ids of all checked lines in form
@checked	= $query->param('checked_AID') if $query->param('checked_AID');
$sugg	= $query->param('sugg') if $query->param('sugg');
$coll_num	= $query->param('coll_num') if $query->param('coll_num');
$select_georef	= $query->param('georef_only') || 0;

###check all box
grep($checked{$_}++,@checked);
if($check_all){
$check_all="checked" if $check_all == 1;
}

###max return settings
$max_return=$query->param('max_rec') || "2000";
$max_return=2000 unless $max_return=~/^100001$/;
$max_return=10000 if $make_tax_list;

###search hints prints if no records are retrieved. This is assembered here. &search_hints is at the end of this script
$search_hints=&search_hints;

###if herbarium source is provided; this is for the URL
if(@source){
	$req_source=join("&source=",@source);
}
else{
	$req_source="";
}
if($loc){
($quote_loc=$loc)=~s/"/%22/g;
}
else{
$quote_loc="";
}
if($query->param('current_request')){
$current_request=$query->param('current_request');
}
else{
$current_request= qq{/cgi-bin/get_consort.pl?county=$county&source=$req_source&taxon_name=$lookfor&collector=$collector&aid=$aid&year=$year&month=$month&day=$day&loc=$quote_loc&coll_num=$coll_num&max_rec=$max_return&make_tax_list=$make_tax_list&before_after=$before_after&last_comments=$last_comments&VV=$v_restrict&non_native=$include_nn&geo_only=$geo_only&geo_no=$geo_no&CNPS_listed=$include_CNPS&weed=$include_weed&sugg_loc=$sugg_loc$q_coords&tns=$tns&lo_e=$lo_e&hi_e=$hi_e&YF=$YF&VTM=$include_vtm&baja=$include_baja&cultivated=$include_cult};
}

if($query->param(adj_num)){
$current_request.="&adj_num=1";
}
$current_request=~s/&/&amp;/g;
if($month && not( $year || $day)){

	%date_acc=&get_season_acc($month);
	$season=1;
}

###basically, if these things are looked for, performing the following subroutines
if($lookfor){
	if($lookfor=~/ACEAE$/){
		#print $lookfor;
        	%name_acc=&get_fam_acc($lookfor);
	}
	else{
		$lookfor=~s/ X / x /;
   		tie(%nomsyns, "BerkeleyDB::Hash", -Filename=>"$CDL_nomsyn_file", -Flags=>DB_RDONLY)|| die "$!";
    		($ns_lookfor=$lookfor)=~s/ (var\.|nothosubsp\.|subsp\.|ssp\.|f\.|forma)//;
    		if($nomsyns{lc($ns_lookfor)}){
        		@nomsyns=split(/\t/,$nomsyns{lc($ns_lookfor)});
				push(@nomsyns);
		        foreach(@nomsyns){
        			%acc_buffer=&get_name_acc($_);
				while(($ns_key,$ns_value)=each(%acc_buffer)){
					$name_acc{$ns_key}=$ns_value;
            			}
        		}
    		}
		else{
			%name_acc=&get_name_acc($lookfor);
		}
		untie(%nomsyns);
	}
}

if($coll_num){
	%coll_num_acc=&get_coll_num_acc($coll_num);
}

if($collector){
	%coll_acc=&get_coll_acc($collector);
}

if(@county){
	%county_acc=&get_county_acc(@county);
}

if($loc){
	if($loc=~s/^"([^ ]+ [^"]+)"$/\L$1/){
		$loc= qq{"$loc"};
		%loc_acc=&get_loc_acc($loc);
	}
	else{
		%loc_acc=&get_loc_acc("$loc");
	}
}

if($year){
	%date_acc=&get_date_acc($year, $month, $day);
}
if($ejdate){
	%date_acc=&get_date_acc($ejdate);
}

tie %CDL, "BerkeleyDB::Hash", -Filename=>"$CDL_DBM_file", -Flags=>DB_RDONLY or die "Cannot open file CDL_DBM: $! $BerkeleyDB::Error\n" ;
tie(%TID_TO_NAME, "BerkeleyDB::Hash", -Filename=>"$CDL_taxon_id_file", -Flags=>DB_RDONLY)|| die "$!";

###how to create the set of results based on different search combinations, up to the max return
if(@checked){
	foreach(keys(%checked)){
			&push_result($_);
	}
}
elsif(($year || $month) && $loc && $county && $collector){
	foreach(keys(%loc_acc)){

		if((scalar(@result) < $max_return) && ($date_acc{$_} && $county_acc{$_} && $coll_acc{$_}) && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $loc && $county){
	foreach(keys(%loc_acc)){

		if((scalar(@result) < $max_return) && ($date_acc{$_} && $county_acc{$_}) && &source_wanted($_) && &num_wanted($_)){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $collector && $county){
	foreach(keys(%date_acc)){
		if((scalar(@result) < $max_return) && ($county_acc{$_} && $coll_acc{$_})&& &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $loc && $collector){
	foreach(keys(%loc_acc)){

		if((scalar(@result) < $max_return) && ($date_acc{$_} && $coll_acc{$_}) && &num_wanted($_) && &source_wanted($_)  ){
			&push_result($_);
		}
	}
}
elsif($collector && $loc && $county){
	foreach(keys(%loc_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && ($county_acc{$_} && $coll_acc{$_})){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $loc){
	foreach(keys(%loc_acc)){

		if((scalar(@result) < $max_return) && $date_acc{$_} && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $collector){
	foreach(keys(%date_acc)){

		if((scalar(@result) < $max_return) && $coll_acc{$_} && &num_wanted($_) && &source_wanted($_)  ){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $loc){
	foreach(keys(%loc_acc)){

		if((scalar(@result) < $max_return) && $date_acc{$_} && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $county){
	foreach(keys(%date_acc)){

		if((scalar(@result) < $max_return) && $county_acc{$_} && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($collector && $county){
	foreach(keys(%coll_acc)){

		if((scalar(@result) < $max_return) && $county_acc{$_} && &num_wanted($_) && &source_wanted($_)  ){
			&push_result($_);
		}
	}
}
elsif($loc && $county){
	foreach(keys(%loc_acc)){

		if((scalar(@result) < $max_return) && $county_acc{$_} && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($loc && $collector){
	foreach(keys(%loc_acc)){

		if((scalar(@result) < $max_return) && $coll_acc{$_} && &num_wanted($_) && &source_wanted($_)  ){
			&push_result($_);
		}
	}
}
elsif($year){
	foreach(keys(%date_acc)){

		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($ejdate){
	foreach(keys(%date_acc)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($county){
	foreach(keys(%county_acc)){
	if( $lookfor){
		next unless  $name_acc{$_};
	}
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($collector){
	foreach(keys(%coll_acc)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($loc){
	foreach(keys(%loc_acc)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($lookfor){
	foreach(keys(%name_acc)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_)  ){
			&push_result($_);
		}
	}
}
elsif($coll_num){
	foreach(keys(%coll_num_acc)){
		if( (scalar(@result) < $max_return) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}

elsif($query->param('dup')){
	@dup=$query->param('dup');
	foreach(@dup){
		&push_result($_);
	}
}
elsif( $query->param('dups')){
	@dup=split(/[^0-9A-Z.-]+/,$query->param('dups'));
	foreach(@dup){
		next unless m/^[A-Z][A-Z0-9.-]+$/;
		&push_result($_);
	}
}
elsif($query->param('last_comments')){
	$last_comments=$query->param('last_comments');
	$multiplier=$last_comments;
	$multiplier="0.14" if $multiplier eq "today";
	$now=time();
	use Time::Local;
	tie(%suggs, "BerkeleyDB::Hash", -Filename=>"${data_path}suggs_tally")|| die "$!";

%mo=(
"Jan"=>0,
"Feb"=>1,
"Mar"=>2,
"Apr"=>3,
"May"=>4,
"Jun"=>5,
"Jul"=>6,
"Aug"=>7,
"Sep"=>8,
"Oct"=>9,
"Nov"=>10,
"Dec"=>11
);
#UC485711: Thu May  3 11:06:18 2007
while(($key, $value)=each(%suggs)){
	next unless $key=~/^[A-Z]/;
	if($value=~m/([A-Z][a-z]+) ([A-Z][a-z]+) *(\d+) (\d+):(\d+):(\d+) *(\d+)/){
		$comment_day=$1;
		$comment_mo=$2;
		$comment_mday=$3;
		$comment_hour=$4;
		$comment_min=$5;
		$comment_sec=$6;
		$comment_year=$7;
		$time=timelocal($comment_sec, $comment_min, $comment_hour, $comment_mday, $mo{$comment_mo}, $comment_year);
		$comment_week="604800";
		if($now - $time < $comment_week * $multiplier){
			&push_result($key) unless $key eq "";
		}
	}
}
}
elsif($query->param('get_bad_coords')){
	$bad_coords= 1;
	open(IN,$CDL_bad_coords)|| print "couldnt open $CDL_bad_coords $!\n";
	while(<IN>){
		if($source){
			next unless m/$source\d/o;
		}
		chomp;
		s/,.*//;
		&push_result($_) if $CDL{$_};
}
close(IN);
}

elsif($lat_min){
my %h_long ;
my %h_lat;
tie %h_long, 'BerkeleyDB::Hash',
-Filename   => "${data_path}CDL_long",
-Flags=>DB_RDONLY 
or print "Cannot open ${data_path}CDL_long: $!\n" ;
tie %h_lat, 'BerkeleyDB::Hash',
-Filename   => "${data_path}CDL_lat",
-Flags=>DB_RDONLY 
or print "Cannot open ${data_path}CDL_lat: $!\n" ;

print <<EOP;
$lat_min
$lat_max
$long_min
$long_max
EOP
if($lat_max - $lat_min > 3 || $long_max - $long_min > 3){
print <<EIO;
<h2>Make the box dimensions less than 3 degrees, please</h2>
EIO
}
elsif( $long_min > $long_max || $lat_min > $lat_max){
print <<EIO;
<h2>Are your coordinates reversed?</h2>
EIO
}
else{
foreach(keys(%h_lat)){
if($_ >= $lat_min && $_ <=$lat_max){
grep($cumulat{$_}++,split(/\t/,$h_lat{$_}));
}
}
foreach(keys(%h_long)){
if($_ >= $long_min && $_ <=$long_max){
grep($cumulong{$_}++,split(/\t/,$h_long{$_}));
}
}
while(($key,$value)=each(%cumulat)){
if ($cumulong{$key}){
#print $key;
&push_result($key) ;
}
}
}
}
elsif($mapper_loc){
	foreach $key (keys (%region)){
		&push_result($key);
	}
}
else{
$null_search_warning= <<EOP;
<span class="pageSubheading">
Searching without specifying
county,
collector,
date,
locality,
region,
collector number,
or scientific name
isn't implemented yet.
</span>
<br>
EOP
}
$returns= scalar(@result);
&print_table_header($returns);
$end_time=times();

###Adding a column to the end of the data downloads called "citation" which will contain the standard CCH citation
###I was going to also add rights, but I want to wait until we update our terms

###Originally I had it print the timestamp into the citation, but that really isn't useful since we are not versioning the data
#$today=localtime(); #note that $today is used later to print the date above the display table
$citation = "Data provided by the participants of the Consortium of California Herbaria (ucjeps.berkeley.edu/consortium/)";

if(@checked){
	print $query->header( -type => 'text/plain' );

###If the riverside box ("R") is checked, print the header with these extra fields
	if($riverside){
		print join("\t", (
	"specimen_number",
	"taxon name",
	"collector",
	"associated_collectors",
	"coll_number_prefix",
	"coll_number",
	"coll_number_suffix",
	"collection_date",
	"late_collection_date",
	"verbatim_date",
	"county",
	"elevation_in_meters",
	"locality",
	"latitude",
	"longitude",
	"datum",
	"source",
	"T_R_S",
	"error_distance_in_meters",
	"habitat",
	"associated_species",
	"annotations",
	"notes",
	"citation"
	)),"\n";

	}
	else{
		print join("\t", (
	"specimen_number",
	"taxon name",
	"collector",
	"coll_number_prefix",
	"coll_number",
	"coll_number_suffix",
	"collection_date",
	"late_collection_date",
	"verbatim_date",
	"county",
	"elevation",
	"locality",
	"latitude",
	"longitude",
	"datum",
	"source",
	"error_distance",
	"units",
	"citation"
	)),"\n";
	}

	foreach(@checked){
		$anno=$ass_sp= $habitat="";
		@CDL_fields=split(/\t/,$CDL{$_}, 20);
		grep(s/>/&gt;/g,@CDL_fields);
		grep(s/</&lt;/g,@CDL_fields);
		
		#if there is a julian date, change it to YYYY-MM-DD
		foreach($fields[5]){
			($start_y, $start_m, $start_d)=inverse_julian_day($CDL_fields[5]);
			###add leading zero to month and say where appropriate
			if (length($start_m)==1) { $start_m = "0$start_m"; }
			if (length($start_d)==1) { $start_d = "0$start_d"; }
			$CDL_fields[5] = "$start_y-$start_m-$start_d";
		}
		#same for late j date
		foreach($fields[6]){
			($lstart_y, $lstart_m, $lstart_d)= inverse_julian_day($CDL_fields[6]);
			###add leading zero to month and say where appropriate
			if (length($lstart_m)==1) { $lstart_m = "0$lstart_m"; }
			if (length($lstart_d)==1) { $lstart_d = "0$lstart_d"; }
			$CDL_fields[6]= "$lstart_y-$lstart_m-$lstart_d";
		}

#######in progress
		if($riverside){
			$CDL_fields[1]=~s/,* and /, /g;
			$CDL_fields[1]=~s/, Jr\./ Jr./g;
			$CDL_fields[1]=~s/, /\t/ ||
			$CDL_fields[1]=~s/$/\t/ ;	

			foreach($CDL_fields[9]){
#convert Elevation to meters
				s/\342\200\223/-/;
	
				s/^\~//g;
				s/,//g;
				s/zero/0/;
				s/[Ss]ea [Ll]evel/0/;
				s/[Cc]a?\.? //;
				s/[Cc]a\.//;
				s/[<>]//g;
				s/&[lg]t;//g;

				if(s/(\d) *[Ff].*/$1/){
					unless(s!(\d+) *(to|-) *(\d+)!int($1/3.28) . "-" .int($3/3.28)!e){
						$_=int($_/3.281);
					}
					s/ ?\(.*//;
					s/^(about|above|near|above|below) //;
				}
				s/ -.*//;
				s/ ?[mM].*//;
			}
			foreach($CDL_fields[16]){
#convert ER to meters
#feet
				if($CDL_fields[17]=~/[Ff]/){
					$_=int($_/3.281);
				}
#kilometer
				elsif($CDL_fields[17]=~/[Kk]/){
					$_*=1000;
				}
#miles
				elsif($CDL_fields[17]=~/[Mm]i/){
					$_=int((5280 * $_)/3.281);
				}
				else{
					$_="";
				}
			}

 			tie(%VOUCHER, "BerkeleyDB::Hash", -Filename=>"${data_path}CDL_voucher", -Flags=>DB_RDONLY)|| die "$!";
			%voucher=split(/\t/,$VOUCHER{$_});
			untie(%VOUCHER);
			if($voucher{52}){
				$habitat=$voucher{52};
			}
			if($voucher{53}){
				$ass_sp=$voucher{53};
			}
tie(%CDL_notes, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/ucjeps_data/CDL_notes", -Flags=>DB_RDONLY);
$notes=$CDL_notes{$_};
untie(%CDL_notes);

#annotations
 			tie(%ANNO_HIST, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/ucjeps_data/CDL_annohist", -Flags=>DB_RDONLY)|| die "$!";
			@anno=split(/\n/,$ANNO_HIST{$_});
			untie(%ANNO_HIST);
			if(@anno){
				$anno="";
				foreach(sort(@anno)){
					@anno_unit=split(/; /, $_, 4);
					$anno_unit[1]=~s|[uU]nknown|<font size="-2">Annotator unknown</font>|;
					$anno_unit[2]=~s|[uU]nknown||;
					$anno_unit[3]=~s|;||;
					foreach($anno_unit[3]){
						s/\bnocl\b/Name on collection label/;
						s/\bdip\b/data in packet/;
					}
					$anno .="$anno_unit[0]; $anno_unit[1]; $anno_unit[2]; $anno_unit[3]|";
				}
				$anno=~s/\303\251/&eacute;/g;
			}
			else{
				$anno="";
			}
			print "$_\t$TID_TO_NAME{$CDL_fields[0]}\t", join("\t",@CDL_fields[1 .. 16], $habitat, $ass_sp, $anno, $notes, $citation), "\n";
		}
		else{
			print "$_\t$TID_TO_NAME{$CDL_fields[0]}\t", join("\t",@CDL_fields[1 .. 14, 16,17], $citation), "\n";
		}
	}
	#print "</pre></html>";
}
else{
open(QLOG, ">>${data_path}cch_query_log");
print QLOG join("\n",time(),@QLOG),"\n";
close(QLOG);
if($sort_direction eq "reverse"){
        @sorted_result=reverse(sort(@result));
    }
    else{
        @sorted_result=sort (@result);
    }

	foreach(@sorted_result){
			if (++$bgcount %2){
				$bgc="#ffffff" ;
			}
			else{
				$bgc="#dddddd" ;
			}
	#s/‚Äú/"/g;
	#s/À&ouml;/&deg;/g;
	s/<tr/<tr bgcolor=$bgc/;
	#s/\+\\-/&plusmn;/g;
	#s/¬∫:/&deg;/g;
	#s/¬Ω:/1\/2/g;
	#s/¬º:/1\/4/g;
	#s/√´</&euml;/g;
	#s/¬±:/&plusmn;/g;
	#s/√©:/&eacute;/g;
	#s/\xc3\xa9/&eacute;/g;
	#s/‚Äô/'/g;
	#s/√±o/&ntilde;/g;
	#s/√É¬í/"/g;
	#s/√É¬ì/"/g;
	print "$_";
	}
$ccview= "<a href=\"/cgi-bin/clone_coords.pl?$current_request\">Clone coords view</a>";
$elapsed= sprintf "%.2f processing seconds\n", $end_time - $begin_time;
$dss= $query->param('sort_submit');
$dso= $query->param('SO');
print <<EOP;
</table></form>
$consortium_footer
<!-- Begin footer -->
$elapsed<br /><br />

$axxxxx<br />

<?php include($_SERVER['DOCUMENT_ROOT'].'/common/php/cch_footer.php'); ?>
<!-- End footer -->

<!-- $ccview-->
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-1304595-1";
urchinTracker();
</script>
</body></html>
EOP
}
open (SEARCHES, ">>${data_path}CCH_searches.txt");
$this_search= "$ENV{REQUEST_METHOD} $start_time ${current_request}&SO=$sort_field\n";
$this_search=~s/&amp;/&/g;
$this_search=~s/[_A-Za-z]+=&//g;
print SEARCHES $this_search,@dups;
close(SEARCHES);

open (SURVEY, ">>${data_path}CCH_survey.txt");
$this_survey= "$ENV{REQUEST_METHOD}\t$start_time\t$pers\t$nonprofit\t$fed\t$state\t$consult\t$profit\n";
print SURVEY $this_survey;
close(SURVEY);

}




sub inverse_julian_day {
	use integer;
        my($jd) = @_;
        my($jdate_tmp);
        my($m,$d,$y);

        $jdate_tmp = $jd - 1721119;
        $y = (4 * $jdate_tmp - 1)/146097;
        $jdate_tmp = 4 * $jdate_tmp - 1 - 146097 * $y;
        $d = $jdate_tmp/4;
        $jdate_tmp = (4 * $d + 3)/1461;
        $d = 4 * $d + 3 - 1461 * $jdate_tmp;
        $d = ($d + 4)/4;
        $m = (5 * $d - 3)/153;
        $d = 5 * $d - 3 - 153 * $m;
        $d = ($d + 5) / 5;
        $y = 100 * $y + $jdate_tmp;
        if($m < 10) {
                $m += 3;
        }
	else {
                $m -= 9;
                ++$y;
        }
        return ($y, $m, $d);
}

sub print_table_header {
	$number_of_records=shift;
	$Search_page="http://ucjeps.berkeley.edu/consortium/index.html";
	$plural="";
	if($county){
		$searched_for ="County=" . join(", ",@county). "; ";
	}
	if($lookfor){
		if(@nomsyns){
			$searched_for .="Scientific name=$lookfor (including nomenclatural synonyms); ";
		}
		else{
			$searched_for .="Scientific name=$lookfor; ";
		}
($sci_name=$lookfor)=~s/ /+/g;
if($sci_name=~/[A-Z][a-z-]+\+[a-z-]+/){
$interchange_link="<a href=\"/cgi-bin/get_cpn.pl?$sci_name\">More information: Jepson Online Interchange</a>";
}
	}
	if($query->param('source')){
		$searched_for .="Source=" .  join(", ",@source);
		$searched_for .="; ";
	}
	if($query->param('collector')){
		$searched_for .="Collector=$collector; ";
	}
	if($query->param('coll_num')){
		$searched_for .="Collector number=$coll_num; ";
	}
	if($query->param('accn_num')){
		$searched_for .="Accession number=$aid; ";
	}
	if($query->param('collyear')){
		$searched_for .="Year=$year; ";
	}
	if($query->param('collmonth')){
		$searched_for .="Month=$month; ";
	}
	if($query->param('collday')){
		$searched_for .="Day=$day; ";
	}
	if($query->param('loc')){
		$searched_for .="Locality=$loc; ";
	}
	if($query->param('non_native')){
		$searched_for .="Return only non-natives; ";
	}
	if($query->param('cultivated')){
		$searched_for .="include cultivated specimens; ";
	}
	if($query->param('VTM')){
		$searched_for .="Return only VTM specimens; ";
	}
	if($query->param('weed')){
		$searched_for .="Return only registered weeds; ";
	}
	if($geo_only){
		$searched_for .="Return specimens with coords; ";
	}
	if($sugg_loc){
		$searched_for .="Return specimens with coords in $sugg_loc; ";
	}
	if($query->param('CNPS_listed')){
		$searched_for .="Return taxa from CNPS Inventory; ";
	}
	if($query->param('make_tax_list')){
		$searched_for .="Return name list; ";
	}
	if($query->param('baja')){
		$searched_for .="Include records from CFP Baja; ";
	}
	if($number_of_records > 0){
		$plural="s" if $number_of_records > 1;
	if(@checked){
		#print <<EOP;
#<html>
#<pre>
#EOP
	}
	else{

###Table is printed differently if results are mappable or not. The get_smasch_county.pl map was used if there were no mappable coordinates
		if(@map_results){
			grep(s/\|/_/g,@map_results);
			$record_number=scalar(@map_results) . " record";
			$record_number .="s" if $#map_results > 0;

###The "red or black points" options are no longer available as a default in BerkeleyMapper
###and the get_smasch_county.pl map is antiquated
###so both have been retired

###I have created a separate BMapper config file which includes a KMZ for for CFP Baja
###It is called "baja_bmapper_config.xml"
###It is only accessed when users are doing a search that includes Baja
if($include_baja){
			$mappable=<<EOP;
<table width="100%" cellpadding="5" class="bodyText"><tr><td width="50%" valign="top">
<span class="pageSubheading"><br>Mapping Options:</span>
<br>
<a href="http://berkeleymapper.berkeley.edu/index.html?ViewResults=tab&tabfile=$map_file_URL&configfile=http%3A%2F%2Fucjeps.berkeley.edu%2Fconsortium%2Fbaja_bmapper_config.xml&sourcename=Consortium+of+California+Herbaria+result+set&maptype=Terrain&pointDisplay=pointMarkersBlack">BerkeleyMapper with county and bioregion layers</a> <br>
<a href="http://berkeleymapper.berkeley.edu/index.html?ViewResults=tab&tabfile=$map_file_URL&configfile=http%3A%2F%2Fucjeps.berkeley.edu%2Fucjeps_nolayers.xml&sourcename=Consortium+of+California+Herbaria+result&pointDisplay=pointMarkersBlack">BerkeleyMapper without layers.</a> <br>
<a href="/cgi-bin/x_to_k.pl?tabfile=$map_file_URL"> KML export</a> <br>
(Note: only records with coordinates are mappable)
</td>
EOP
}
else{
			$mappable=<<EOP;
<table width="100%" cellpadding="5" class="bodyText"><tr><td width="50%" valign="top">
<span class="pageSubheading"><br>Mapping Options:</span>
<br>
<a href="http://berkeleymapper.berkeley.edu/index.html?ViewResults=tab&tabfile=$map_file_URL&configfile=http%3A%2F%2Fucjeps.berkeley.edu%2Fucjeps.xml&sourcename=Consortium+of+California+Herbaria+result+set&maptype=Terrain&pointDisplay=pointMarkersBlack">BerkeleyMapper with county and bioregion layers</a> <br>
<a href="http://berkeleymapper.berkeley.edu/index.html?ViewResults=tab&tabfile=$map_file_URL&configfile=http%3A%2F%2Fucjeps.berkeley.edu%2Fucjeps_nolayers.xml&sourcename=Consortium+of+California+Herbaria+result&pointDisplay=pointMarkersBlack">BerkeleyMapper without layers.</a> <br>
<a href="/cgi-bin/x_to_k.pl?tabfile=$map_file_URL"> KML export</a> <br>
(Note: only records with coordinates are mappable) 
</td>
EOP
}
			if($YF){
				$mappable=<<EOP;
<span class="pageSubheading"><br>Map/download results:</span>
<br>
<a href="http://berkeleymapper.berkeley.edu/index.html?ViewResults=tab&tabfile=$YF_map_file_URL&configfile=http%3A%2F%2Fucjeps.berkeley.edu%2FYF.xml&sourcename=Consortium+of+California+Herbaria+result+set&maptype=Terrain&pointDisplay=pointMarkersBlack">BerkeleyMapper with layers and yellow flags</a> 
EOP
open(MAPFILE, ">/data/tmp/$YF_map_file_out") || print "cant open map file /data/tmp$map_file_out $!";
				print MAPFILE join("\n",@map_results);
				close(MAPFILE);
			}
			else{
open(MAPFILE, ">/data/tmp/$map_file_out") || print "cant open map file /data/tmp$map_file_out $!";
				print MAPFILE join("\n",@map_results);
				close(MAPFILE);
			}
		}
		
		###No YF processing because there can't be yellow flags if there are no mappable records
		else{
			$fips_string=join("", keys(%fips_string));
			$mappable=qq{<br>No results can be mapped from coordinates. <a href="/cgi-bin/get_smasch_county.pl?fips=$fips_string">County Map</a>};
		}

if($number_of_records =~/2000/){
$default_max_warning= qq{<br>(<font color="red">That's the default maximum</font>. Contact Jason Alexander for larger data requests.)};
}
else{
$default_max_warning= "";
}

###I don't know where this CalFlora search comes from.
if ($query->param('dups')){
	$CF_search=$query->param('dups');
	$CF_search=<<EOP;
<input type="hidden" name="dups" value="
$CF_search
">
EOP

$searched_for="CalFlora search";
$column_headers=<<EOC;
<tr><td></td><td colspan="9">
Click on column header to sort data (* sorts by family); click in leftmost checkbox to select record. <a href="http://ucjeps.berkeley.edu/detail_help.html">CCH Help Page</a>.
</td>
</tr>
<tr bgcolor="#ffffff">
<th></th>
<th></th>
<th><input type=submit name=sort_submit value="Specimen ID"></th>
<th><input type=submit name=sort_submit value="Determination"></th>
<th><input type=submit name=sort_submit value="Collector"></th>
<th><input type=submit name=sort_submit value="Collection Date"></th>
<th><input type=submit name=sort_submit value="Collection Number"></th>
<th><input type=submit name=sort_submit value="County"></th>
<th><input type=submit name=sort_submit value="Locality"></th>
<th><input type=submit name=sort_submit value="Elevation in meters"></th>
<th>&nbsp;</th>
</tr>
EOC
}
else{
$CF_search="";
if($YF){
$Yellow_warning=<<EOW;
A yellow cell in the column headed "<b>?</b>",  for records with coordinates, indicates a discrepancy with respect to range as specified in the eFlora.
EOW
}
else{
($add_yellow=$current_request)=~s/YF=0/YF=1/;
$Yellow_warning=qq{<a href="$add_yellow">Turn on yellow flags</a> to show possible range discrepancies.};
}

$column_headers=<<EOC;
<tr><td colspan="11">
Click on column header to sort data (* sorts by family); click in leftmost checkbox to select record. <a href="http://ucjeps.berkeley.edu/detail_help.html">CCH Help Page</a>.
<br>
$Yellow_warning
<a href="http://ucjeps.berkeley.edu/consortium/about_yellow.html">Read more ... </a>
</td>
</tr>
<tr bgcolor="#cccccc">
<th></th>
<th bgcolor=#eeeeee><a href="${current_request}&amp;SO=21$SD[21]">?</a></th>
<th><a href="${current_request}&amp;SO=10$SD[10]">Specimen ID</a></th>
<th><a href="${current_request}&amp;SO=0$SD[0]">Determination</a><a href="${current_request}&amp;SO=11"> *</a></th>
<th><a href="${current_request}&amp;SO=1$SD[1]">Collector</a></th>
<th><a href="${current_request}&amp;SO=5$SD[5]">Collection Date</a></th>
<th><a href="${current_request}&amp;SO=3$SD[3]">Collection Number</a></th>
<th><a href="${current_request}&amp;SO=8$SD[8]">County</a></th>
<th><a href="${current_request}&amp;SO=20$SD[20]">Locality</a></th>
<th><a href="${current_request}&amp;SO=9$SD[9]">Elevation in meters</a></th>
<th><a href="${current_request}&amp;SO=25$SD[25]">Feedback</a></th>
</tr>
EOC
}

print $query->header unless $header_printed++;                    # create the HTTP header
$today=localtime(); #$today used to be printed at the end of the citation, but I decided it is not useful
print <<EOP;
$common_html_head

$chc_header
<br />
<table width="100%" cellpadding="5" class="bodyText"><tr><td>
<span class="pageName">Search Results</span>
<span class="pageSubheading"> &mdash; $number_of_records specimen record$plural retrieved ($record_number with coordinates)$default_max_warning</span>
EOP

if(%taxonomic_list){
tie (%G_T_F, "BerkeleyDB::Hash", -Filename =>"/usr/local/web/ucjeps_data/ucjeps_data/G_T_F", -Flags => DB_RDONLY);
	print "<P><b>List of unique names</b> <table>";
	foreach(sort(keys(%taxonomic_list))){
($fam_for_g=$_)=~s/ .*//;
	print <<EOP;
<tr><td><a href="/cgi-bin/get_cpn.pl?$_">$_</a></td><td>$G_T_F{$fam_for_g}</td></tr>
EOP
	}
print "</table>";
untie (%G_T_F);
die;
}
print <<EOP;
<br />
<span class="bodyText">Results for search: $searched_for &nbsp;&nbsp;$interchange_link</span>
$stop_word_warning
$mappable
</span>
<td width = "50%" valign="top">
<span class="pageSubheading"><br>Download Options:</span>
<form method="post" action="/cgi-bin/get_consort.pl">
$CF_search
<a href="${current_request}&amp;check_all=1&amp;SO=$sort_field">Select all records</a>
&middot;
<a href="${current_request}&amp;georef_only=1">Select records with coordinates</a><br>
<input type="submit" value="Retrieve selected records as tab-separated list"> <br>
<input type="checkbox" name="DL" value="UCR">Include annotations and voucher information <br />
<br />
PLEASE NOTE: Due to changes in newer versions of Excel, directly copying text from the above selected results does not produce a usable table.<br />
&nbsp;&nbsp;&nbsp;&nbsp;Follow these steps:<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;1. The contents of the selected results window must be copied into a text editor like TextEdit for Mac or WordPad for Windows<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;2. The selected results must be saved as a new text document.<br />
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;3. This new text document can now be copied into Excel or imported as a tab delimited text file.<br />
<br />
(For large data reqests, please contact Jason Alexander, <a href="mailto:jason_alexander&#64;berkeley.edu">jason_alexander&#64;berkeley.edu</a>.)<br />
</td></tr>
</td></tr></table>

<hr>
<table width="100%" cellpadding="0" cellspacing="0" class="bodyText">
<tr><td>&nbsp;</td><td>Please cite data retrieved from this page: Data provided by the participants of the Consortium of California Herbaria (ucjeps.berkeley.edu/consortium/).
</td></tr>
<tr><td>&nbsp;</td><td>Records are made available under the <a href="http://ucjeps.berkeley.edu/consortium/data_use_terms.html">CCH Data Use Terms</a>.</td></tr>
<?php include '/common/php/cch_footer.php'); ?>
</table>
<hr>

<table width="100%" cellpadding="5" cellspacing="0" class="bodyText">
$column_headers

EOP
		}
	}
	elsif($sugg && $sugg=~/^[A-Z-]+[0-9-]+[A-Za-z.0-9]?$/){
		@CDL_fields=split(/\t/,$CDL{$sugg}, 20);
		grep(s/>/&gt;/g,@CDL_fields);
		grep(s/</&lt;/g,@CDL_fields);
print $query->header unless $header_printed++;                    # create the HTTP header
		print <<EOP;
$common_html_head
$chc_header
<br />
<!-- <table width="94%"> -->
<span class="pageName">Comment on this record.</span><br />
<span class="bodyText">You can alter some of the fields in the form below to make your comment.<br /></span>
<span class="bodyText"><a href="$Search_page">Return to main search page</a><br /></span>
<br>
<form action="/cgi-bin/chc_comment.pl" method="POST">
<input type=hidden name=sugg value=$sugg>


<table class=bodyText cellpadding="0" border=1 align="center"><tr>
<td><a href="/cgi-bin/$detail?$sugg&related=yes">$sugg</a></td>
<td>$TID_TO_NAME{$CDL_fields[0]}</td>
<td><textarea name="sugg_coll" cols=20 rows=3>$CDL_fields[1]</textarea></td>
<td><input type=text name="sugg_date" value="$CDL_fields[7]"></td>
<td>$CDL_fields[2] $CDL_fields[3] $CDL_fields[4]</td>
<td>
<select name="sugg_county">
 <option value = "$CDL_fields[8]">$CDL_fields[8]</option>
EOP
#generate select list of capitalized counties
foreach(sort(keys(%fips_trans))){
print qq{<option value = "}, uc($fips_trans{$_}), qq{">}, $fips_trans{$_}, qq{</option>\n};
}
print <<EOP;
 <option value = "UNKNOWN">unknown</option>
		</select>
</td>
<td><textarea name="sugg_loc" cols="30" rows="3">$CDL_fields[10]</textarea></td>
</tr>
</table>
<!-- </tr> -->
<table>
<tr>
<td colspan=3>My name: <input type="text" name="sugg_feedback_name" value=""</td>
<TD colspan=3>
<select name="sugg_reason">
<option selected>What I did</option>
<option>Unknown county supplied</option>
<option>County changed or questioned</option>
<option>Date made more precise</option>
<option>Collector name corrected</option>
<option>Typo in locality corrected</option>
<option>Identification questioned</option>
<option>Revised or added coordinates</option>
<option>Commented on georeferencing</option>
<option>Multiple corrections</option>
<option>Commented on type status</option>
<option>Other</option>
</select>
</td>
<td colspan=4>Comments: <br><textarea name="sugg_feedback_comments" cols=40></textarea></td>
<td colspan=4>Revised coords from BerkeleyMapper: <br><textarea name="sugg_coords" cols=40></textarea></td>
</tr>
<tr>
<td><input type="submit" value="Submit comment"></td>
</tr>
</table>
</form>
<!-- </table> -->
<P>
<hr width="30%">
<P>

<table width="60%"><tr><td></td><td>
We welcome comments and corrections of the specimen data. Action on the comments will be taken by the curators of the participating herbaria. You should provide helpful explanatory information if you can. Incorporating the comments into the database is time-consuming because in most cases it is necessary to examine the specimen label before amending the database. Often a discrepancy can be caused by more than one error, and investigation of an error sometimes reveals related problems.
</td><td></td></tr></table>
EOP
	}
else{

print $query->header unless $header_printed++;                    # create the HTTP header
if($searched_for=~s/<script.*//g){
$searched_for="your search seemed strange";
}
		print <<EOP;
$common_html_head
$chc_header
<table cellpadding="20" class="bodyText"><tr><td>
<span class="pageName">Search Results</span><br /><br />
<span class="pageSubheading">$stop_word_warning
<br>
No records were retrieved$because</span>
<P>
$null_search_warning

<span class="bodyText">$searched_for
$search_hints
<P>
<a href="$Search_page">Return to main search page</a>
</span>
</td></tr></table>
EOP
	}
}

sub get_name_acc {
%found_names=();
	my $lookfor=shift;
	$lookfor=~s/(var\.|nothosubsp\.|subsp\.|ssp\.|f\.|forma) //;
$lookfor=~s/◊/X /;
$lookfor=~s/&times;/X /;
$lookfor=~s/  +/ /g;
	use Search::Dict;
	open(NAMES,"${data_path}CDL_name_list.txt") || die $!;
	$lookfor=lc($lookfor);
	look(\*NAMES, $lookfor);
	while(<NAMES>){
		if(m/^$lookfor/){
			chomp;
			s/^.* ([A-Z])/$1/;
			s/	+$//;
			@acc=split(/\t/);
			foreach(@acc){
				$found_names{$_}++ if $_;
				$found_names{$_}++ unless (m/^$_$/);
			}
		}
		else{
			last;
		}
	}
	close(NAMES);
	return %found_names;
}

sub get_coll_acc {
	my $collector= shift;
$collector="Doux" if $collector eq "La Doux";
$collector="Doux" if $collector eq "LaDoux";
	$collector=ucfirst(lc($collector));

	open(COLLS,"${data_path}CDL_collectors.txt") || print "$!couldnt open COLLS\n";
		use Search::Dict;
		look(\*COLLS, $collector);
		while(<COLLS>){
			if(m/^$collector/){
				chomp;
				s/^[^ ]+ //;
				s/	*$//;
				@acc=split(/ *\t/);
				grep($found_coll{$_}++,@acc);
			}
			else{
				last;
			}
		}
	close(COLLS);
	return %found_coll;
}


sub get_county_acc {
	my @county = @_;
	tie %county, "BerkeleyDB::Hash", -Filename => "$CDL_county_file",-Flags=>DB_RDONLY or die "Cannot open file CDL_county: $! $BerkeleyDB::Error\n" ;
	foreach $county (@county){
	$county=uc($county);

foreach(split(/\t/,$county{"$county"})){
    if($lo_e){
    $county_acc{$_}++ if $elev_acc{$_};
    }
    else{
    $county_acc{$_}++;
    }
}




	}
	return %county_acc;
}
sub get_date_acc {
	my $year = shift;
	my $month = shift;
	my $day = shift;
	#subroutine was modified to accommodate the "exact date" button
	if($before_after=~/^[12]/ || (($year=~/^[12][890]\d\d$/) && not ($month || $day))){


           my @date_recno ;
           tie @date_recno, 'BerkeleyDB::Recno', -Filename   => "$CDL_date_recno_file", -Flags      => DB_RDONLY or die "Cannot open $filename: $! $BerkeleyDB::Error\n" ;
		if($before_after ==2){
			grep($date_acc{$_}++, split(/\t/, join("\t", @date_recno[$year .. $#date_recno]))); #this used to be $year+1,  but if you searched any dates with month or day in a year, you only returned next year, e.g. 1 Jan 2010 only returned 2011+ dates, which is not correct and gets comments by users that search is broken
		}
		elsif($before_after ==1){
			grep($date_acc{$_}++, split(/\t/,join("\t",@date_recno[1800 .. $year-1])));#this used to be $year
		}
		else{
			grep($date_acc{$_}++, split(/\t/,$date_recno[$year]));
		}
	}
	else{
		if($year=~/2\d\d\d\d\d\d/){
			$lookfor_date=$year;
		}
		elsif($year && $month && $day){
			$ejd=julian_day($year, $month, $day);
			$ljd=$ejd;
			$lookfor_date=$ejd;
		}
		elsif($year && $month){
			$ejd=julian_day($year, $month, 1);
			if($month == 12){
				$ljd=$ejd + 30;
			}
			else{
				$ljd=julian_day($year, $month +1, 1);
				$ljd = $ljd -1;
			}
		}
		else{
			$ejd=julian_day($year, 1, 1);
			$ljd=julian_day($year +1, 1, 1);
			$ljd = $ljd -1;

warn "1 $ejd   $ljd\n";


		}
#######$before_after==3 is the new radio button for "exact date"
#######so the date_range hash is skipped when that value is used
unless ($before_after==3){
    		tie %date_range, "BerkeleyDB::Hash", -Filename => "$CDL_date_range_file", -Flags=>DB_RDONLY or die "Cannot open file CDL_date_range: $! $BerkeleyDB::Error\n" ;
}
unless ($before_after==3){
		foreach $key (sort(keys(%date_range))){
			if($key=~m/^(\d+)-(\d+)/){
				$begin=$1; $end=$2;
			}
			foreach $d ($ejd .. $ljd){
				if($d >= $begin && $d <=$end){
					grep($date_acc{$_}++, split(/\t/,$date_range{$key}));
				}
			}
		}
}
    		tie %date, "BerkeleyDB::Hash", -Filename => "$CDL_date_simple_file", Flags=>DB_RDONLY or die "Cannot open file CDL_date_simple: $! $BerkeleyDB::Error\n" ;
 		foreach $d ($ejd .. $ljd){
			grep($date_acc{$_}++, split(/\t/,$date{$d}));
		}
	
		if($lookfor_date){
unless ($before_after==3){			
			foreach (sort(keys(%date_range))){
				$key=$_;
				($begin,$end)=m/^(\d+)-(\d+)/;
				next if $lookfor_date < $begin;
				if($lookfor_date >= $begin && $lookfor_date <=$end){
					grep($date_acc{$_}++, split(/\t/,$date_range{$key}));
				}
			}
}		
		}
	}
	
delete($date_acc{""});
	return %date_acc;
}

sub julian_day
{
use integer;
    my($year, $month, $day) = @_;
    my($tmp);
    my($secs);

    use Carp;

    $tmp = $day - 32075
      + 1461 * ( $year + 4800 - ( 14 - $month ) / 12 )/4
      + 367 * ( $month - 2 + ( ( 14 - $month ) / 12 ) * 12 ) / 12
      - 3 * ( ( $year + 4900 - ( 14 - $month ) / 12 ) / 100 ) / 4
      ;

    return($tmp);

}

sub get_look_loc_acc {
	use Search::Dict;
	open(LOCS,"${data_path}CDL_look_loc.txt") || do{
	print qq{<H2>Sorry. I can't open the geographic binary names file.</H2><h4>Contact Jason Alexander about this problem</h4>};
	die;
	};
	$locs=shift;
	$complete_locs=$locs;
	$locs=~s/  +/ /g;
			seek(LOCS, 0, 1);
			look(\*LOCS, $locs);
			while(<LOCS>){
				if(m/^$locs/){
					chomp;
					s/.*\t//;
					s/ *$//;
					@acc=split(/ /);
					foreach(@acc){
						$found{$_}++ unless $seen{$locs.$_}++;
					}
				}
				else{
					last;
				}
			}
	close(LOCS);
	foreach(keys( %found)){
		$wanted{$_}++;
	}
	return %wanted;
}
sub get_loc_acc {

	use Search::Dict;
	open(LOCS,"${data_path}CDL_location_words.txt") || do{
	print qq{<H2>Sorry. I can't open the geographic names file.</H2><h4>Contact Jason Alexander about this problem</h4>};
die;
	};
	$locs=shift;
	if($locs=~s/"([^"]+)"/$1/){
	$complete_locs=$locs;
		$quoted=$1;
		$quoted=quotemeta($quoted);
  		tie %CDL, "BerkeleyDB::Hash", -Filename=>"${data_path}CDL_DBM", -Flags=>DB_RDONLY or die "Cannot open file CDL_DBM: $! $BerkeleyDB::Error\n" ;
}
else{
}
$locs=~s/ . / /g;
$locs=~s/^ *//g;
$locs=~s/"//g;
	$locs=~s/  +/ /g;
	$complete_locs=$locs;
	$locs=~s/\b(road|junction|san|near|the|and|along|hwy|side|from|nevada|above|north|south|between|county|end|about|miles|just|hills|area|quad|slope|west|east|state|air|northern|below|region|quadrangle|cyn|with|mouth|head|old|base|collected|city|lower|beach|line|mile|california|edge|del|off|ave|..)\b *//ig; 
	unless($locs eq $complete_locs){
		if(length($locs) > 2){
			$stop_word_warning= qq{<br> Note: <span class="bodyText">$complete_locs contains one or more common words: using $locs</span>};
		}
		else{

			$stop_word_warning= qq{<br> Note: <span class="bodyText">$complete_locs contains  only words too common to search for.</span>};
		}
	}

	#print "sub: $locs\n";
	@name_items=split(/ /,$locs);
	#print "sub: @name_items\n";
	if(@name_items){
		$locs_wanted=scalar(@name_items);
		while(@name_items){
			$locs=lc(pop(@name_items));
			seek(LOCS, 0, 1);
			look(\*LOCS, $locs);
			while(<LOCS>){
				if(m/^$locs/){
					chomp;
					s/.*? //;
					s/	*$//;
					@acc=split(/\t/);
					foreach(@acc){
						$found{$_}++ unless $seen{$locs.$_}++;
					}
				}
				else{
					last;
				}
			}
		}
	}
	close(LOCS);
	foreach(keys( %found)){
		$wanted{$_}++ if $found{$_} == $locs_wanted;
	}
							if($quoted){
foreach(keys(%wanted)){
#warn "$_ $quoted $CDL{$_} ";
								unless($CDL{$_}=~/$quoted/i){
delete($wanted{$_});
								}
							}
}
	return %wanted;
}

sub source_wanted {
	my $accession_id=shift;
	($inst=$accession_id)=~s/\d.*//;

	if(grep(/^$inst$/,@source) || $inst eq $source || $source eq "All" || $source eq ""){
		return 1;
	}
	return 0;
}

sub push_result {
my $checked="";
	my $accession_id=shift;
	return 0 unless $CDL{$accession_id};
	if($season){
	return 0 unless $date_acc{$accession_id};
	}
	if($mapper_loc){
	return 0 unless $region{$accession_id};
	}
	if($geo_no){
	return 0 if $CDL_GEO{$accession_id};
	}
	if($geo_only){
	return 0 unless $CDL_GEO{$accession_id};
	}

	if( $lookfor){
		return 0 unless  $name_acc{$accession_id};
	}
if($source){
return 0 unless &source_wanted($accession_id) ;
}
	@CDL_fields=split(/\t/,$CDL{$accession_id}, 20);
$fips_string{$CTF{$CDL_fields[8]}}++;
	if($include_nn){
		return 0 unless $gbif_nn{$CDL_fields[0]};
	}
	if($include_vtm){
	return 0 unless $VTM_nos{$accession_id};
	}
	if($include_CNPS){
		return 0 unless $CNPS_tid{$CDL_fields[0]};
	}
	if($include_weed){
		return 0 unless $weed_tid{$CDL_fields[0]};
	}
	if($include_cult==1){
		#include all records, i.e. do nothing
	}
	else {
		return 0 if $CULT_nos{$accession_id};
	}
	if($include_baja==1){
		#include all counties, i.e. do nothing
	}
	else {
		return 0 if ($CDL_fields[8]=~/Ensenada|Mexicali|Rosarito|Tecate|Tijuana/);
	}


$elev=$CDL_fields[9];

if($lo_e=~/\d/){
return 0 unless $elev_acc{$accession_id};
}


$elev=~s/\342\200\223/-/;

$elev=~s/^\~//g;
$elev=~s/,//g;
$elev=~s/zero/0/;
$elev=~s/[Ss]ea [Ll]evel/0/;
$elev=~s/[Cc]a?\.? //;
$elev=~s/[Cc]a\.//;
$elev=~s/[<>]//g;
$elev=~s/&[lg]t;//g;

if($elev=~s/(\d) *[Ff].*/$1/){
	unless($elev=~s!(\d+) *(to|-) *(\d+)!int($1/3.28) . "-" .int($3/3.28)!e){
		$elev=int($elev/3.281);
	}

	$elev=~s/ ?\(.*//;
	$elev=~s/^(about|above|near|above|below) //;

}
$elev=~s/ -.*//;
$elev=~s/ ?[mM].*//;

	if ((length($CDL_fields[2]) >=1) && (length($CDL_fields[3]) >=1) && (length($CDL_fields[4]) == 0)){
		$collno_string="$CDL_fields[2] $CDL_fields[3]";
	}
	elsif ((length($CDL_fields[2]) >=1) && (length($CDL_fields[3]) >=1) && (length($CDL_fields[4]) >= 1)){
		$collno_string="$CDL_fields[2] $CDL_fields[3] $CDL_fields[4]";
	}
	elsif ((length($CDL_fields[2]) == 0) && (length($CDL_fields[3]) >=1) && (length($CDL_fields[4]) >= 1)){
		$collno_string="$CDL_fields[3] $CDL_fields[4]";
	}
	elsif ((length($CDL_fields[2]) >=1) && (length($CDL_fields[3]) == 0) && (length($CDL_fields[4]) == 0)){
		$collno_string="$CDL_fields[2]";
	}	
	elsif ((length($CDL_fields[2]) == 0) && (length($CDL_fields[3]) >=1) && (length($CDL_fields[4]) == 0)){
		$collno_string="$CDL_fields[3]";
	}	
	elsif ((length($CDL_fields[2]) >=1) && (length($CDL_fields[3]) == 0) && (length($CDL_fields[4]) >=1)){
		$collno_string="$CDL_fields[2] $CDL_fields[4]";
	}
	elsif ((length($CDL_fields[2]) == 0) && (length($CDL_fields[3]) == 0) && (length($CDL_fields[4]) >=1)){
		$collno_string="$CDL_fields[4]";
	}
	else {
		$collno_string="";
	}


	grep(s/>/&gt;/g,@CDL_fields);
	grep(s/</&lt;/g,@CDL_fields);

	$date=$CDL_fields[7];
	$CDL_fields[10]=~s/^[ \|]+//;
	$CDL_fields[10]=~s/[ -]*$//;
	$CDL_fields[10]=~s/\[\]//;

	($location_key=$CDL_fields[10])=~s/^[^A-Z]+//;
	if($sort_field==0){
		$sort_string=$TID_TO_NAME{$CDL_fields[$sort_field]};
	}
	elsif($sort_field==11){
tie (%G_T_F, "BerkeleyDB::Hash", -Filename =>"/usr/local/web/ucjeps_data/ucjeps_data/G_T_F", -Flags => DB_RDONLY);
($sort_string=$TID_TO_NAME{$CDL_fields[0]})=~s/ .*//;
$sort_string="$G_T_F{$sort_string} $sort_string";
}
	elsif($sort_field==1){
		$sort_string=&get_coll_last_name($CDL_fields[$sort_field]);
	}
	elsif($sort_field==10){
		$sort_string=$accession_id;
	}
	elsif($sort_field==3){
		$sort_string=sprintf("%06d", $CDL_fields[3]);
	}
	elsif($sort_field==9){
		$sort_string=~s/^~ *//;
		$sort_string=sprintf("%04d", $elev);
	}
	elsif($sort_field==20){
		$sort_string=$location_key;
	}
	elsif($sort_field==21){
		if($CDL_fields[-1]=~/^[01]/){
			$sort_string= "-1";
		}
		else{
			$sort_string= 0;
		}
	}
	elsif($sort_field==25){
		$sort_string=&get_comment_date($suggs{$accession_id});
	}
	else{
		$sort_string=$CDL_fields[$sort_field];
	}
###########remove > 200 to restore image links
#this code needs to be check against for the new Image links file, I have no idea how the links were generated in SMASH_IMAGES
	if($image_location{$accession_id}){
if($accession_id=~/SDSU/){
	$image_link= $image_location{$accession_id };
	$image_link=~s/\.jpg.*/.html"/;
	$image_link=qq{$image_link <br /><img src="/common/images/ico_camera.gif" alt="Image available" border="0"></a>};
}
elsif($accession_id=~/SD\d/){
	$image_link= "$image_location{$accession_id}";
$image_link=~s!$accession_id!<img src="/common/images/ico_camera.gif" alt="Image available" border="0">!;

}
elsif($accession_id=~/UCR\d/){
	$image_link= "$image_location{$accession_id}";
	$image_link=~s!$accession_id!<img src="/common/images/ico_camera.gif" alt="Image available" border="0">!;
}

else{	
####hide image links to UC/JEPS while we move over to CSpace
#Hide E. truncatum
		$image_link="" if $accession_id eq "UC692153";
		$image_link="" if $accession_id eq "JEPS26640";
		$image_link="" if $accession_id eq "JEPS27371";
		$image_link="" if $accession_id eq "UC1212010";
		$image_link= "$image_location{$accession_id}";
		$image_link=~s!$accession_id!<img src="/common/images/ico_camera.gif" alt="Image available" border="0">!;

}
	}
	elsif($CP{$accession_id}){
		$image_link=qq{<a href="http://calphotos.berkeley.edu/cgi/img_query?query_src=&seq_num=263479&one=T"><img src="/common/images/ico_camera.gif" alt="Image available" border="0"></a>};
}
else{
	$image_link="";
}
	if($suggs{$accession_id}){
		($sugg_suffix=$accession_id)=~s/\d.*//;
		$sugg_suffix=lc($sugg_suffix);
		$sugg_suffix="rsa" if $sugg_suffix eq "pom";
		$sugg_suffix="ucb" if $sugg_suffix eq "uc";
		$sugg_suffix="ucb" if $sugg_suffix eq "jeps";
($sugg_date= $suggs{$accession_id})=~s/\d\d:\d\d:\d\d//;
$sugg_date=~s/^[A-Z]...//;
		$seen_sugg=<<EOP;
<a href="/cgi-bin/display_chc_comment.pl?comment_id=$accession_id"><br>Read comments</a> $sugg_date
EOP
	}
	else{
		$seen_sugg="";
	}
	if($CDL_fields[11] && $CDL_fields[12]){
		$check_bgcolor=" bgcolor=\"#AAffAA\"";
		if($select_georef==1){
			$checked="checked";
		}
		else{
			$checked="";
		}
	}
	elsif($CDL_new_coords{$accession_id}){
	@new_coords=split(/\t/,$CDL_new_coords{$accession_id});
		$check_bgcolor=" bgcolor=\"#ffAAAA\"";
		if($select_georef==1){
			$checked="checked";
		}
		else{
			$checked="";
		}
	@CDL_fields[11,12,13,14,16,17]=@new_coords;
	}
	else{
		$check_bgcolor="";
	}
	($tax_name=$TID_TO_NAME{$CDL_fields[0]})=~s/$times /$times/o;

if($make_tax_list){
    if($taxonomic_list{$tax_name}++){return 0;}
    }

$checked=$check_all unless $checked;

($ejdate,$ljdate,$date)=@CDL_fields[5,6,7];
if($ejdate==$ljdate){
		($year,$month,$day)=inverse_julian_day($ejdate);
$formattedDate = "$year-$month-$day";
}
elsif($ljdate - $ejdate > 31){
		($year,$month,$day)=inverse_julian_day($ejdate);
$day=0;
$formattedDate = "$year-$month";
}
elsif($ljdate - $ejdate > 365){
		($year,$month,$day)=inverse_julian_day($ejdate);
$day=0;
$month=0;
$formattedDate = "$year";
}
else{
#$formattedDate = $date;
	if (length($ejdate) == 0){
	 	if ($date =~ m/\d\d?[- ]\d\d?[- ]\d\d?/){ #makes bad dates with unconvertible years 19-04-19   20/5/56   5 7 36   into null values for sorting purposes
		$formattedDate = "";

		}
		else{
			$formattedDate = $date;
		}
	}
	else{
		$formattedDate = $date;
	}
	
};

if($formattedDate =~ m/-4712-/){
		#$formattedDate = ""; #fix problem dates that are not parsing in inverse julian date properly
	 	if ($date =~ m/^\d\d?[- ]\d\d?[- ]\d\d?$/){ #makes bad dates with unconvertible years 19-04-19   20/5/56   5 7 36   into null values for sorting purposes
		$formattedDate = "";

		}
		else{
			$formattedDate = $date;
		}
}


#with the old code here, the QLOG was skipping CLARK and YM-YOSE specimens because the old code did not match the accession format.  Also it will skip specimens from RSA with DUP at the end, as it allowed only 1 letter after the digits.
if($accession_id=~m/^(CAS-BOT-BC|CDA|CHSC|CSUSB|SACT|HSC|HREC|BFRS|IRVC|JEPS|PGM|POM|RSA|SBBG|SD|SDSU|SJSU|UC|UCD|UCR|UCSB|UCSC|NY|GH|AMES|A|ECON|YM-YOSE|SCFS|OBI|GMDRC|JOTR|VVC|SFV|LA|CLARK-A|SEINET|BLMAR|JROH|PASA|CATA|MACF)\d+-?[0-9]*[A-Z-]*$/){
	push(@QLOG,$accession_id);
}
if($CDL_fields[-1]=="1" && $YF){
$geo_warning="<td bgcolor=yellow>&nbsp;</td>";
}
else{
$geo_warning="<td bgcolor=#eeeeee>&nbsp;</td>";
}
	push(@result, <<EOP
<!-- $sort_string --><tr>
<td $check_bgcolor><input type ="checkbox" name="checked_AID" value=$accession_id $checked></td>
$geo_warning
<td><a href="/cgi-bin/$detail?$accession_id&YF=$YF">$accession_id</a>&nbsp;$image_link</td>
<td>$tax_name</td>
<td>$CDL_fields[1]</td>
<td>$formattedDate</td>
<td>$collno_string</td>
<td>$CDL_fields[8]</td>
<td>$CDL_fields[10]</td>
<td>$elev</td>
<td valign="top"><a href="/cgi-bin/get_consort.pl?sugg=$accession_id">Comment</a> $seen_sugg</td>
</tr>
EOP
);

#old line with problem coll num fields that shoved everything into a single line without breaks
#12345 would be the same as 123 45 if 45 was in the suffix CNUM field 4, this is causes a discrepancy with the data display and data output (which has all 3 fields separate).
#<td>$CDL_fields[2]$CDL_fields[3]$CDL_fields[4]</td>
#this was placed below the data field above

	if($CDL_fields[11] && $CDL_fields[12]){
		($institution=$accession_id)=~s/\d.*//;
if($YF){
if($CDL_fields[-1]==1){
$institution="YF";
}
else{
$institution="BLUE";
}
		push(@map_results, join("\t", $institution, $accession_id, $TID_TO_NAME{$CDL_fields[0]}, @CDL_fields[1 .. $#CDL_fields]));
}
else{
		push(@map_results, join("\t", $institution, $accession_id, $TID_TO_NAME{$CDL_fields[0]}, @CDL_fields[1 .. $#CDL_fields]));
}
	}
	else{
	#print "no $accession_id";
	}
}

sub get_date{
	my $date=shift;
	my ($year,$month,$day)=inverse_julian_day($date);
	$month=("",Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$month];
	return "$month $day $year";
}
sub inverse_julian_day
{
use integer;
        my($jd) = @_;
        my($jdate_tmp);
        my($m,$d,$y);

        $jdate_tmp = $jd - 1721119;
        $y = (4 * $jdate_tmp - 1)/146097;
        $jdate_tmp = 4 * $jdate_tmp - 1 - 146097 * $y;
        $d = $jdate_tmp/4;
        $jdate_tmp = (4 * $d + 3)/1461;
        $d = 4 * $d + 3 - 1461 * $jdate_tmp;
        $d = ($d + 4)/4;
        $m = (5 * $d - 3)/153;
        $d = 5 * $d - 3 - 153 * $m;
        $d = ($d + 5) / 5;
        $y = 100 * $y + $jdate_tmp;
        if($m < 10) {
                $m += 3;
        } else {
                $m -= 9;
                ++$y;
        }
        return ($y, $m, $d);
}
sub get_coll_num_acc {
	my $number= shift;
	tie %CN, "BerkeleyDB::Hash", -Filename => "$CDL_coll_number_file",-Flags=>DB_RDONLY or die "Cannot open file CDL_coll_number: $! $BerkeleyDB::Error\n" ;
$coll_list=$query->param(adj_num);
if($coll_list){
foreach $one_number ($number-5 .. $number+5){
	grep($coll_num_acc{$_}++, split(/ ?\t ?/,$CN{$one_number}));
}
}
else{
	grep($coll_num_acc{$_}++, split(/ ?\t ?/,$CN{$number}));
}
	untie(%CN);
	return %coll_num_acc;
}
sub num_wanted {
	my $number_acc= shift;
	return 1 unless $coll_num;
	if ($coll_num_acc{$number_acc}){
		return 1;
	}
	else {
		return 0;
	}

}

sub load_fips{
return (
"06001","Alameda",
"06003","Alpine",
"06005","Amador",
"06007","Butte",
"06009","Calaveras",
"06011","Colusa",
"06013","Contra Costa",
"06015","Del Norte",
"06017","El Dorado",
"06019","Fresno",
"06021","Glenn",
"06023","Humboldt",
"06025","Imperial",
"06027","Inyo",
"06029","Kern",
"06031","Kings",
"06033","Lake",
"06035","Lassen",
"06037","Los Angeles",
"06039","Madera",
"06041","Marin",
"06043","Mariposa",
"06045","Mendocino",
"06047","Merced",
"06049","Modoc",
"06051","Mono",
"06053","Monterey",
"06055","Napa",
"06057","Nevada",
"06059","Orange",
"06061","Placer",
"06063","Plumas",
"06065","Riverside",
"06067","Sacramento",
"06069","San Benito",
"06071","San Bernardino",
"06073","San Diego",
"06075","San Francisco",
"06077","San Joaquin",
"06079","San Luis Obispo",
"06081","San Mateo",
"06083","Santa Barbara",
"06085","Santa Clara",
"06087","Santa Cruz",
"06089","Shasta",
"06091","Sierra",
"06093","Siskiyou",
"06095","Solano",
"06097","Sonoma",
"06099","Stanislaus",
"06101","Sutter",
"06103","Tehama",
"06105","Trinity",
"06107","Tulare",
"06109","Tuolumne",
"06111","Ventura",
"06113","Yolo",
"06115","Yuba"
);
}
sub load_header{
return <<EOH;



<!-- COMMON HEADER -->
<table width="100%" class="banner" border="0" cellpadding="0" cellspacing="0">
  <tr><td width="80" align="center"><a href="/consortium/"><img src="/consortium/images/CCH_logo_02_80.png" width="80" height="82"></a></td>
  <td>
        <table class="banner" width="100%" border="0">
        <tr>
        <td align="center">Consortium of California Herbaria</td>
        </tr>
        <tr><td>
                <table width="100%" border="0" cellspacing="0" cellpadding="0">
                <tr>
                <td height="21" width="640" align="center">
                <a href="http://ucjeps.berkeley.edu/consortium/participants.html" class="horizMenuActive">Participants</a>
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href="http://ucjeps.berkeley.edu/consortium/news.html" class="horizMenuActive">News</a>
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href="http://ucjeps.berkeley.edu/consortium/" class="horizMenuActive">Search</a>
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href="http://ucjeps.berkeley.edu/consortium/about.html" class="horizMenuActive">About</a>
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href="http://ucjeps.berkeley.edu/detail_help.html" class="horizMenuActive">Help</a>
                &nbsp;&nbsp;&nbsp;&nbsp;&nbsp; <a href="http://give.berkeley.edu/fund/?f=FU1259000" class="horizMenuActive">Donate</a>
                    </td></tr>
                </table>
        </td></tr>
        </table>
</td></tr>
</table>
<!-- COMMON HEADER ENDS -->



EOH
}
sub load_footer{
#get date of most recent update of CDL files
	if (-f "${data_path}CDL_name_list.txt"){
	@updated= localtime((stat("${data_path}CDL_name_list.txt"))[9]);
$thisyear=$updated[5];
$thisyear +=1900;
$update=$updated[4]+1  . "/". $updated[3] . "/" . $thisyear;
}
else{
$update="Jan 1 2000";
}
	return <<EOH;

<!-- Begin footer -->
$elapsed<br /><br />

$axxxxx<br />
<?php include '/common/php/cch_footer.php'); ?>
<!-- End footer -->

EOH
}


sub search_hints {
	return <<EOS;
<P>
For geographic, collector, or scientific name searches you might try searching
for less of a word (e.g., Mokel instead of Mokelumne;
Coral instead of Corallorhiza;
Baci instead of Bacigalupi), or searching for one word rather than several
(e.g., Tennessee instead of Tennessee Valley Trail).
<P>
Regional searches depend on coordinates; if records lack coordinates or have erroneous
coordinates, they will not be returned in these searches. Try searching by locality word or county.
<P>
You might try selecting "County unknown" or "County all" since sometimes records do not contain correct county information.
<P>
Wildcard characters are not recognized.
<P>
Scientific names and names of collectors are spelled consistently. Geographic names are not: they retain the spelling on the specimen label. Therefore, the same peak may appear as Mount Linn, Mt. Linn, South Yollo Bolly, or South Yolla Bolly.
EOS
}

sub get_coll_last_name {
local($_)=@_;
my $residue="";
#Harold and Virginia Bailey
                        s/^([A-Z][a-z]+) and ?([A-Z][a-z-]+) ([A-Z][a-z-]+$)/$3$1$2/ ||
                        s/^([A-Z]\.) ?([A-Z]\.) and ([A-Z]\.) ?([A-Z]\.) (.*)/$5$1$2$3$4/ ||
                        s/^([A-Z]\.) and ([A-Z]\.) (.*)/$3$1$21/ ;
s/([^,]) Jr/$1, Jr/;
		#if(s/ ?\(?(with|and|&) (.*)//){
		if(s! ?\(?(with|and|&|w/) (.*)!!){
$residue=$2;
}
		if(s/, (.*)//){
$residue=$1;
}
		s/^ *//;
		s/(.+) (.+)/$2$1/;
s/$/$residue/;
s/ //g;
$_;
}

sub get_fam_acc {
%found_names=();
@NS=();
    my $lookfor=shift;
#print $lookfor;
           tie @h, 'BerkeleyDB::Recno',
                          -Filename   => "${data_path}CDL_AID_recno",
                         -Flags=>DB_RDONLY,
                -Property   => DB_RENUMBER
             or print "Cannot open $filename: $!\n" ;
 $dbm_file="${data_path}CDL_family_vec_hash";

         tie %FV, "BerkeleyDB::Hash",
                 -Filename => $dbm_file,
                         -Flags=>DB_RDONLY
         or print "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;
          my $vec = $FV{$lookfor};
          my @ints;

               use integer;
               my $bits = unpack "b*", $vec;
               push @ints, 0 if $bits =~ s/^(\d)// && $1;
               push @ints, pos $bits while($bits =~ /1/g);

           grep($found_names{$h[$_ -1]}++,@ints);
if($season){
foreach(keys(%found_names)){
#print "D $date_acc{$_}";
delete($found_names{$_}) unless $date_acc{$_};
}
}

return %found_names;
}

sub get_season_acc {
	%found_names=();
	use BerkeleyDB;
	@NS=();
	my $month=shift;
	$month=("",Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$month];
	#print $month;
	tie @h, 'BerkeleyDB::Recno',
		-Filename   => "${data_path}CDL_AID_recno",
		-Flags=>DB_RDONLY,
		-Property   => DB_RENUMBER
		or print "Cannot open $filename: $!\n" ;
	$dbm_file="${data_path}CDL_date_vec_hash";

	tie %FV, "BerkeleyDB::Hash",
		-Filename => $dbm_file,
		-Flags=>DB_RDONLY
		or print "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;
	my $vec = $FV{$month};
	my @ints;
	use integer;
	my $bits = unpack "b*", $vec;
	push @ints, 0 if $bits =~ s/^(\d)// && $1;
	push @ints, pos $bits while($bits =~ /1/g);
	grep($found_names{$h[$_ -1]}++,@ints);

	return %found_names;
}

sub get_comment_date {
#Mon Oct 25 10:54:44 2010
%jmo=(
"Jan"=>1,
"Feb"=>2,
"Mar"=>3,
"Apr"=>4,
"May"=>5,
"Jun"=>6,
"Jul"=>7,
"Aug"=>8,
"Sep"=>9,
"Oct"=>10,
"Nov"=>11,
"Dec"=>12
);
$_=shift;
if(m/^[A-Z][a-z][a-z] ([A-Z][a-z][a-z]) +(\d+) +\d\d:\d\d:\d\d (\d+)$/){
return (7777777 - julian_day($3, $jmo{$1}, $2));
}
else{
return("7777777");
}
}

sub get_elev_acc {
    open(ELEVS,"${data_path}CDL_elevation.txt") || die "$!";
    my $lookfor_low=shift;
    my $lookfor_high=shift;
    return unless $lookfor_high >= $lookfor_low;
        while(<ELEVS>){
            chomp;
            ($elev=$_)=~s/\t.*//;
            if($elev < $lookfor_low){
            next;
            }
            if($elev > $lookfor_high){
            last;
            }
            if($elev >=$lookfor_low && $elev <=$lookfor_high){
            #print <<EOP;
#$lookfor_low  > $elev and $lookfor_high > $elev
#EOP
            ($elev,@aids)=split(/[\t, ]+/);
                grep($found_elev{$_}++,@aids);
            }
    }
    return %found_elev;
}

