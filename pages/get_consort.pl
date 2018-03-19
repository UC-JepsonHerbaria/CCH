#!/usr/bin/perl
$detail="new_detail_chignik.pl";
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
$geo_only="";
$include_CNPS="";
$include_weed="";
$sugg_loc="";
use CGI;
$query = new CGI;                        # create new CGI object
if($ENV{'REMOTE_ADDR'} && $ENV{'REMOTE_ADDR'}=~ /(216\.52\.28\.197|207\.46\.55\.27|207\.46\.55\.30|207\.46\.55\.28|207\.46\.55\.31|207\.46\.55\.29|207\.46\.92\.19|207\.46\.92\.17|207\.46\.92\.16|207\.46\.92\.18|216\.52\.28\.200)/){
print $query->header unless $header_printed++;                    # create the HTTP header
#print "<0>";
print<<EOP;
<h2>The Consortium interface is undergoing repairs. Sorry for the
inconvenience.</h2>
<a href="http://ucjeps.berkeley.edu/consortium/about.html">Contact us if
you're seeing this notice</a>
EOP

}
else{
#Output file to store data for Berkeley Mapper
	$Search_page="/consortium/";
$tab_file_name="CHC_" . substr($start_time,6,4) . $$ . ".txt";
$map_file_path="/Library/WebServer/Documents/mapper/";
$map_file_out = "$tab_file_name";
$map_file_URL= "http://herbaria4.herb.berkeley.edu/mapper/$map_file_out";

#data files
$data_path  ="/Library/WebServer/ucjeps_data/";
$comment_hash	="${data_path}suggs_tally";
#$CDL_name_list_file	="${data_path}CDL_name_list.txt";
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

 $tns=$query->param('tns');
$tns=lc($tns);
if($query->param('hi_e')){
$hi_e= $query->param('hi_e');
}
if($query->param('lo_e')){
$lo_e= $query->param('lo_e');
}
$hi_e=$lo_e unless $hi_e;
$lo_e=$hi_e unless $lo_e;
%elev_acc=&get_elev_acc($lo_e, $hi_e) if $hi_e;

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

if($query->param('non_native')){
	$include_nn=1;
	#open(IN,"${data_path}gbif_tid.txt") || die;
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
















%fips_trans=&load_fips;
$chc_header= &load_header;
$consortium_footer=&load_footer;

$common_html_head=<<EOH;
<html>
<head>
<Meta NAME="ROBOTS" CONTENT="NOINDEX, NOFOLLOW">
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>UC/JEPS: Consortium Accession Results</title>
<link href="http://ucjeps.berkeley.edu/consortium/style_consortium.css" rel="stylesheet" type="text/css">
</head>
<body>
EOH


#multiplication sign for hybridity
$times=CGI::Util::unescape("%D7") || "flabba";
use BerkeleyDB;
tie(%suggs, "BerkeleyDB::Hash", -Filename=>"$comment_hash", -Flags=>DB_RDONLY)|| die "$!";
#tie(%suggs, "BerkeleyDB::Hash", -Filename=>"$comment_hash", -Flags=>DB_RDONLY)|| die "$!";

#tie(%image_location, "BerkeleyDB::Hash", -Filename=>"$image_file", -Flags=>DB_RDONLY)|| die "$!";
#tie(%image_location, "BerkeleyDB::Hash", -Filename=>"$image_file", -Flags=>DB_RDONLY)|| die "$!";
#print $query->header;                    # create the HTTP header
#if ($query->param('sugg')){
#print <<EOP;
#$common_html_head
#<h2>Comments have been disabled until the switch to a new machine has been accomplished: Jan 14 2009</h2>
#EOP
#die;
#}
@result=();
@QLOG=();
@map_results=();

if($query->param('VV')){
 $v_restrict=$query->param('VV');
 print "VR=$v_restrict";
 #tie(%VOUCHER, "BerkeleyDB::Hash", -Filename=>"${data_path}CDL_voucher", -Flags=>DB_RDONLY)|| die "$!";
 tie(%VOUCHER, "BerkeleyDB::Hash", -Filename=>"${data_path}CDL_voucher", -Flags=>DB_RDONLY)|| die "$!";
}

if($query->param('CNPS_listed')){
	$include_CNPS=1;
	#open(IN,"${data_path}cnps_taxon_ids.txt") || die;
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

if($query->param('weed')){
	$include_weed=1;
	open(IN,"${data_path}CDL_weed_tid") || die $!;
	#open(IN,"${data_path}CDL_weed_tid") || die;
	while(<IN>){
		chomp;
		$weed_tid{$_}++;
	}
	close(IN);
}
else{
	$include_weed=0;
}
 $last_comments=$query->param('last_comments') if $query->param('last_comments');

 $make_tax_list=$query->param('make_tax_list') if $query->param('make_tax_list');

#if($query->param('img_only')){
#tie(%image_location, "BerkeleyDB::Hash", -Filename=>"$image_file", -Flags=>DB_RDONLY)|| die "$!";
#$img_only=1;
#}
#else{
#$img_only=0;
#}


if($mapper_loc=$query->param('sugg_loc')){
print $query->header unless $header_printed++;                    # create the HTTP header
#print "<1>";
	$sugg_loc=$mapper_loc;
	open(IN,"${data_path}CDL_region_list.txt") || die $!;
	#open(IN,"${data_path}CDL_region_list.txt") || die;
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
#$sugg_loc="&amp;lat_min=$lat_min&amp;lat_max=$lat_max&amp;long_min=$long_min&amp;long_max=$long_max";
	}
	elsif ($mapper_loc=~/([0-9.]+) ([0-9.-]+) ([0-9.-]+) ([0-9.-]+)/){
		$lat_min=sprintf("%.2f", $2);
		$lat_max=sprintf("%.2f", $1);
		$long_min=sprintf("%.2f", $4);
		$long_max=sprintf("%.2f", $3);
$sugg_loc="&lat_min=$lat_min&lat_max=$lat_max&long_min=$long_min&long_max=$long_max";
#$sugg_loc="&amp;lat_min=$lat_min&amp;lat_max=$lat_max&amp;long_min=$long_min&amp;long_max=$long_max";
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


	$geo_only=$query->param('geo_only') if $query->param('geo_only');
	if($geo_only){
tie %CDL_GEO, "BerkeleyDB::Hash", -Filename => "${data_path}CDL_GEO", -Flags=>DB_RDONLY or die "Cannot open file CDL_GEO: $! $BerkeleyDB::Error\n" ;
#tie %CDL_GEO, "BerkeleyDB::Hash", -Filename => "${data_path}CDL_GEO", -Flags=>DB_RDONLY or die "Cannot open file CDL_GEO: $! $BerkeleyDB::Error\n" ;
#print "GEO: ",$CDL_GEO{'SBBG6141'};
}
    %taxonomic_list=();



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
#@source=grep(s/H-/PGM/,@source);
$source	=$source[$#source];
}
$collector	=$query->param('collector') if $query->param('collector');
$aid	=$query->param('accn_num') if $query->param('accn_num');
if($aid=~/SDSU(\d+)/){
$zpad="0" x (5-length($1));
$aid=~s/SDSU/SDSU$zpad/;
}
$sort_field	=$query->param('SO') || "0" ;
if($sort_field=~s/-//){
$sort_direction="reverse";
}
else{
$sort_direction="forward";
$SD[$sort_field]="-";
}







if($query->param('sort_submit')){
	$sort_submit_number=$query->param('sort_submit');
	%sort_submit=("Accession ID"=>10,"Determination"=>0,"Collector"=>1,"Collection Date"=>5,"Collection Number"=>3,"County"=>8,"Locality"=>20,"Elevation in meters"=>9);
	$sort_field=$sort_submit{$sort_submit_number};
}
$year	=$query->param('year') if $query->param('year');
$month	=$query->param('month') if $query->param('month');
$day	=$query->param('day') if $query->param('day');
$loc	=$query->param('loc') if $query->param('loc');
$ejdate	=$query->param('ejdate') if $query->param('ejdate');
$before_after	=$query->param('before_after') if $query->param('before_after');
$before	=$query->param('before') if $query->param('before');
$check_all	=$query->param('check_all') if $query->param('check_all');
#Array containing accession_ids of all checked lines in form
@checked	=$query->param('checked_AID') if $query->param('checked_AID');
$sugg	=$query->param('sugg') if $query->param('sugg');
$coll_num	=$query->param('coll_num') if $query->param('coll_num');
$select_georef	=$query->param('georef_only') || 0;

grep($checked{$_}++,@checked);
if($check_all){
$check_all="checked" if $check_all == 1;
}

$max_return=$query->param('max_rec') || "2000";
$max_return=2000 unless $max_return=~/^100001$/;
$max_return=9000 if $make_tax_list;

$search_hints=&search_hints;

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
$current_request= qq{/cgi-bin/get_consort.pl?county=$county&source=$req_source&taxon_name=$lookfor&collector=$collector&aid=$aid&year=$year&month=$month&day=$day&loc=$quote_loc&coll_num=$coll_num&max_rec=$max_return&make_tax_list=$make_tax_list&before_after=$before_after&last_comments=$last_comments&VV=$v_restrict&non_native=$include_nn&geo_only=$geo_only&CNPS_listed=$include_CNPS&weed=$include_weed&sugg_loc=$sugg_loc$q_coords&tns=$tns&hi_e=$hi_e&lo_e=$lo_e};
}
#open (SEARCHES, ">>${data_path}CCH_searches.txt");
#$this_search= "$ENV{REQUEST_METHOD} $start_time ${current_request}&SO=$sort_field\n";
#$this_search=~s/[_A-Za-z]+=&//g;
##print SEARCHES "$ENV{REQUEST_METHOD} $start_time ${current_request}&SO=$sort_field\n";
#print SEARCHES $this_search;
#close(SEARCHES);

if($query->param(adj_num)){
$current_request.="&adj_num=1";
}
$current_request=~s/&/&amp;/g;
if($month && not( $year || $day)){
	#print "<h2> 1 month</H2>";
	%date_acc=&get_season_acc($month);
	$season=1;
}

if($lookfor){
	if($lookfor=~/ACEAE$/){
#print $lookfor;
        	%name_acc=&get_fam_acc($lookfor);
	}
	else{
		$lookfor=~s/ [xX] / $times /;
		$lookfor=~s/ $times([a-z])/ $times $1/;
   		tie(%nomsyns, "BerkeleyDB::Hash", -Filename=>"/Library/WebServer/ucjeps_data/CDL_nomsyn", -Flags=>DB_RDONLY)|| die "5 $!";
   		#tie(%nomsyns, "BerkeleyDB::Hash", -Filename=>"$CDL_nomsyn_file", -Flags=>DB_RDONLY)|| die "$!";
    ($ns_lookfor=$lookfor)=~s/ (var\.|subsp\.|ssp\.|f\.|forma)//;
    #if($nomsyns{lc($ns_lookfor)}){
        #@nomsyns=split(/\t/,$nomsyns{lc($ns_lookfor)});


#July 30 2009
	#if($nomsyns{lc($lookfor)} || $tns){
		#@nomsyns=split(/\t/,$nomsyns{lc($lookfor)});

	if($nomsyns{lc($ns_lookfor)} || $tns){
		@nomsyns=split(/\t/,$nomsyns{lc($ns_lookfor)});
		push(@nomsyns,$tns) if $tns;




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
	#%loc_acc=&get_look_loc_acc("$loc");
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
#tie %CDL, "BerkeleyDB::Hash", -Filename=>"$CDL_DBM_file", -Flags=>DB_RDONLY or die "Cannot open file CDL_DBM: $! $BerkeleyDB::Error\n" ;
tie(%TID_TO_NAME, "BerkeleyDB::Hash", -Filename=>"$CDL_taxon_id_file", -Flags=>DB_RDONLY)|| die "$!";
#tie(%TID_TO_NAME, "BerkeleyDB::Hash", -Filename=>"$CDL_taxon_id_file", -Flags=>DB_RDONLY)|| die "$!";

if(@checked){
	foreach(keys(%checked)){
			&push_result($_);
	}
}
elsif(($year || $month) && $loc && $county && $collector){
	foreach(keys(%loc_acc)){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && ($date_acc{$_} && $county_acc{$_} && $coll_acc{$_})){
		if((scalar(@result) < $max_return) && ($date_acc{$_} && $county_acc{$_} && $coll_acc{$_}) && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $loc && $county){
	foreach(keys(%loc_acc)){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && ($date_acc{$_} && $county_acc{$_})){
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
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && ($date_acc{$_} && $coll_acc{$_})){
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
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $date_acc{$_}){
		if((scalar(@result) < $max_return) && $date_acc{$_} && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $collector){
	foreach(keys(%date_acc)){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $coll_acc{$_}){
		if((scalar(@result) < $max_return) && $coll_acc{$_} && &num_wanted($_) && &source_wanted($_)  ){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $loc){
	foreach(keys(%loc_acc)){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $date_acc{$_}){
		if((scalar(@result) < $max_return) && $date_acc{$_} && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif(($year || $month) && $county){
	foreach(keys(%date_acc)){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $county_acc{$_}){
		if((scalar(@result) < $max_return) && $county_acc{$_} && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($collector && $county){
	foreach(keys(%coll_acc)){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $county_acc{$_}){
		if((scalar(@result) < $max_return) && $county_acc{$_} && &num_wanted($_) && &source_wanted($_)  ){
			&push_result($_);
		}
	}
}
elsif($loc && $county){
	foreach(keys(%loc_acc)){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $county_acc{$_}){
		if((scalar(@result) < $max_return) && $county_acc{$_} && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($loc && $collector){
	foreach(keys(%loc_acc)){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $coll_acc{$_}){
		if((scalar(@result) < $max_return) && $coll_acc{$_} && &num_wanted($_) && &source_wanted($_)  ){
			&push_result($_);
		}
	}
}
elsif($year){
	foreach(keys(%date_acc)){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($ejdate){
	foreach(keys(%date_acc)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($county){
	foreach(keys(%county_acc)){
	if( $lookfor){
		next unless  $name_acc{$_};
	}
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
			&push_result($_);
		}
	}
}
elsif($collector){
	foreach(keys(%coll_acc)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($loc){
	foreach(keys(%loc_acc)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_) ){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($lookfor){
	foreach(keys(%name_acc)){
		if((scalar(@result) < $max_return) && &num_wanted($_) && &source_wanted($_)  ){
		#if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($coll_num){
	foreach(keys(%coll_num_acc)){
		if( (scalar(@result) < $max_return) && &source_wanted($_) ){
		#if(&source_wanted($_) && (scalar(@result) < $max_return)){
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
if(m/SDSU(\d+)/){
$zpad="0" x (5-length($1));
s/SDSU/SDSU$zpad/;
}
elsif($aid=~/PGM(\d+)/){
$zpad="0" x (4-length($1));
$aid=~s/PGM/PGM$zpad/;
}
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
	#tie(%suggs, "BerkeleyDB::Hash", -Filename=>"${data_path}suggs_tally")|| die "$!";

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
if(@checked){
print $query->header( -type => 'text/plain' );
	print join("\t", (
	"accession_id",
	"taxon name",
	"collector",
	"coll_number_prefix",
	"coll_number",
	"coll_number_suffix",
	"early_jdate",
	"late_jdate",
	"date_string",
	"county",
	"elevation",
	"locality",
	"latitude",
	"longitude",
	"datum",
	"source",
	"error distance",
	"units"
	)),"\n";

	foreach(@checked){
		@CDL_fields=split(/\t/,$CDL{$_});
		grep(s/>/&gt;/g,@CDL_fields);
		grep(s/</&lt;/g,@CDL_fields);
		print "$_\t$TID_TO_NAME{$CDL_fields[0]}\t", join("\t",@CDL_fields[1 .. 14, 16,17]), "\n";
	}
	#print "</pre></html>";
}
else{
#open(QLOG, ">>${data_path}cch_query_log");
#print QLOG join("\n",time(),@QLOG),"\n";
#close(QLOG);
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
	s/“/"/g;
	s/�&ouml;/&deg;/g;
	s/<tr/<tr bgcolor=$bgc/;
	s/\+\\-/&plusmn;/g;
	s/º:/&deg;/g;
	s/½:/1\/2/g;
	s/¼:/1\/4/g;
	s/ë</&euml;/g;
	s/±:/&plusmn;/g;
	s/é:/&eacute;/g;
	s/’/'/g;
	s/ño/&ntilde;/g;
	s/Ã/"/g;
	s/Ã/"/g;
	print "$_";
	}
$ccview= "<a href=\"/cgi-bin/clone_coords.pl?$current_request\">Clone coords view</a>";
$elapsed= sprintf "%.2f processing seconds\n", $end_time - $begin_time;
$dss= $query->param('sort_submit');
$dso= $query->param('SO');
print <<EOP;
</table></form>
$consortium_footer
$elapsed
</body></html>
EOP
}
#open (SEARCHES, ">>${data_path}CCH_searches.txt");
#$this_search= "$ENV{REQUEST_METHOD} $start_time ${current_request}&SO=$sort_field\n";
#$this_search=~s/&amp;/&/g;
#$this_search=~s/[_A-Za-z]+=&//g;
#print SEARCHES "$ENV{REQUEST_METHOD} $start_time ${current_request}&SO=$sort_field\n";
#print SEARCHES $this_search,@dups;
#close(SEARCHES);

}




sub inverse_julian_day {
	use integer;
        my($jd) = @_;
        my($jdate_tmp);
        my($m,$d,$y);

        #carp("warning: julian date $jd pre-dates British use of Gregorian calendar\n") if ($jd < $brit_jd);

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
	$Search_page="http://ucjeps.berkeley.edu/consortium/";
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
$interchange_link="<a href=\"http://ucjeps.berkeley.edu/cgi-bin/get_cpn.pl?$sci_name\">More information: Jepson Online Interchange</a>";
}
if($looked_for_name=~/[a-z] /){
$interchange_link ="$interchange_link<br><a href=\"http://ucjeps.berkeley.edu/cgi-bin/wrap_map.pl?taxon_name=$looked_for_name\">Show elevation/latitude plot for " . ucfirst($looked_for_name) . "</a>";
}
	}
	if($source){
		$searched_for .="Source=" .  join(", ",@source);
		$searched_for .="; ";
	}
	if($collector){
		$searched_for .="Collector=$collector; ";
	}
	if($coll_num){
		$searched_for .="Collector number=$coll_num; ";
	}
	if($aid){
		$searched_for .="Accession number=$aid; ";
	}
	if($year){
		$searched_for .="Year=$year; ";
	}
	if($month){
		$searched_for .="Month=$month; ";
	}
	if($day){
		$searched_for .="Day=$day; ";
	}
	if($loc){
		$searched_for .="Locality=$loc; ";
	}
	if($include_nn){
		$searched_for .="Return only non-natives; ";
	}
	if($include_weed){
		$searched_for .="Return only registered weeds; ";
	}
	if($geo_only){
		$searched_for .="Return specimens with coords; ";
	}
	if($sugg_loc){
		$searched_for .="Return specimens with coords in $sugg_loc; ";
}
	if($include_CNPS){
		$searched_for .="Return taxa from CNPS Inventory; ";
}
	if($make_tax_list){
		$searched_for .="Return name list; ";
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
		if(@map_results){
			grep(s/\|/_/g,@map_results);
			$record_number=scalar(@map_results) . " record";
			$record_number .="s" if $#map_results > 0;
			#grep(s/\t/|/g,@map_results);
			$mappable=<<EOP;
<br><a href="http://berkeleymapper.berkeley.edu/run.php?ViewResults=tab&tabfile=$map_file_URL&configfile=http%3A%2F%2Fucjeps.berkeley.edu%2Fucjeps.xml&sourcename=Consortium+of+California+Herbaria+result+set&maptype=Terrain">Map the results using BerkeleyMapper ($record_number with coordinates [those with a <font color=\"#00FF00\">light green</font> checkbox])</a>
EOP
			open(MAPFILE, ">$map_file_path$map_file_out") || die;
			#open(MAPFILE, ">$map_file_path$map_file_out") || die;
			print MAPFILE join("\n",@map_results);
			close(MAPFILE);
		}
		else{
			$mappable="<br>No results can be mapped";
		}
if($number_of_records =~/2000/){
$default_max_warning= qq{. (<font color="red">That's the default maximum</font>. Contact rlmoe\@berkeley.edu for help with bigger searches.)};
}
else{
$default_max_warning= ".";
}

if ($query->param('dups')){
	$CF_search=$query->param('dups');
	$CF_search=<<EOP;
<input type="hidden" name="dups" value="
$CF_search
">
EOP
$searched_for="CalFlora search";
$column_headers=<<EOC;
<tr><td colspan="9">
Click on accession number to display detailed record; click on column header to sort data (* sorts by family); click in leftmost checkbox to select record. <a href="http://ucjeps.berkeley.edu/detail_help.html">Help</a>
</td>
</tr>
<tr bgcolor="#ffffff">
<th></th>
<th><input type=submit name=sort_submit value="Accession ID"></th>
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
$column_headers=<<EOC;
<tr><td colspan="9">
Click on accession number to display detailed record; click on column header to sort data (* sorts by family); click in leftmost checkbox to select record. <a href="http://ucjeps.berkeley.edu/detail_help.html">Help</a>
</td>
</tr>
<tr bgcolor="#cccccc">
<th></th>
<th><a href="${current_request}&amp;SO=10$SD[10]">Accession ID</a></th>
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
#print "<2>";
$today=localtime();
print <<EOP;
$common_html_head

$chc_header
<br />
<table width="100%" callpadding="10" class="bodyText">
<tr><td>&nbsp;</td><td><a href="/consortium/about.html">The Consortium of California Herbaria</a> is a gateway to information from California vascular plant specimens that are housed in herbaria throughout the state.</td></tr>
<tr><td>&nbsp;</td><td>Please cite data retrieved from this page: Data provided by the participants of the Consortium of California Herbaria (ucjeps.berkeley.edu/consortium/; $today).
</td></tr></table>
<table width="100%" cellpadding="20" class="bodyText"><tr><td>
<span class="pageName">Accession Results</span>
<span class="pageSubheading"> &mdash; $number_of_records record$plural retrieved$default_max_warning</span>
EOP

if(%taxonomic_list){
	print "<br><b>Taxonomic list</b>";
	foreach(sort(keys(%taxonomic_list))){
	print "<br>$_ ($taxonomic_list{$_})";
	}
}
print <<EOP;
<br />
<span class="bodyText">Results for search: $searched_for &nbsp;&nbsp;$interchange_link</span>
$stop_word_warning
$mappable
</span>
<br />
<form method="post" action="/cgi-bin/get_consort.pl">
$CF_search
<br>
<a href="${current_request}&amp;check_all=1&amp;SO=$sort_field">Select all records</a>
<br>
<a href="${current_request}&amp;georef_only=1">Select records with coordinates</a>
<br>
<input type="submit" value="Retrieve selected records as tab-separated list">
</td></tr></table>


<table width="100%" cellpadding="5" class="bodyText">
$column_headers
<!--
<tr><td colspan="9">
Click on accession number to display detailed record; click on column header to sort data; click in leftmost checkbox to select record. <a href="http://ucjeps.berkeley.edu/detail_help.html">Help</a>
</td>
</tr>
<tr bgcolor="#cccccc">
<th></th>
<th><a href="${current_request}&amp;SO=10">Accession ID</a></th>
<th><a href="${current_request}&amp;SO=0">Determination</a></th>
<th><a href="${current_request}&amp;SO=1">Collector</a></th>
<th><a href="${current_request}&amp;SO=5">Collection Date</a></th>
<th><a href="${current_request}&amp;SO=3">Collection Number</a></th>
<th><a href="${current_request}&amp;SO=8">County</a></th>
<th><a href="${current_request}&amp;SO=20">Locality</a></th>
<th><a href="${current_request}&amp;SO=9">Elevation in meters</a></th>
<th><a href="${current_request}&amp;SO=25">Feedback</a></th>
</tr>
-->

EOP
		}
	}
	elsif($sugg && $sugg=~/^[A-Z]+[0-9]+[A-Za-z.0-9]?$/){
		@CDL_fields=split(/\t/,$CDL{$sugg});
		grep(s/>/&gt;/g,@CDL_fields);
		grep(s/</&lt;/g,@CDL_fields);
print $query->header unless $header_printed++;                    # create the HTTP header
#print "<3>";
		print <<EOP;
$common_html_head
$chc_header
<br />
<table width="94%">
<span class="pageName">Comment on or alter this record</span><br /><br />
<span class="bodyText"><a href="$Search_page">Return to main search page</a><br /></span>
<br>
<form action="/cgi-bin/chc_comment.pl" method="POST">
<input type=hidden name=sugg value=$sugg>


<table class=bodyText cellpad="6" border=1 align="center"><tr>
<td><a href="/cgi-bin/$detail?$sugg">$sugg</a></td>
<td>$TID_TO_NAME{$CDL_fields[0]}</td>
<td><textarea name="sugg_coll" cols=20 rows=3>$CDL_fields[1]</textarea></td>
<td><input type=text name="sugg_date" value="$CDL_fields[7]"></td>
<td>$CDL_fields[2]$CDL_fields[3]$CDL_fields[4]</td>
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
</tr>
<tr>
<td colspan=3>My name: <input type="text" name="sugg_feedback_name" value=""</td>
<TD colspan=3>
<select name="sugg_reason">
<option selected>What I did</option>
<option>Unknown county supplied</option>
<option>Date made more precise</option>
<option>Collector name corrected</option>
<option>Typo in locality corrected</option>
<option>Identification questioned</option>
<option>Multiple corrections</option>
</select>
</td>
</tr>
<tr>
<td colspan=4>Comments: <textarea name="sugg_feedback_comments" cols=50></textarea></td>
<td><input type="submit" value="Submit comment"></td>
</tr>
</table>
</form>
</table>
<P>
<hr width="30%">
<P>

<table width="60%"><tr><td></td><td>
We welcome comments and corrections of the specimen data. Action on the comments will be taken by the curators of the participating herbaria. You should provide helpful explanatory information if you can. Incorporating the comments into the database is time-consuming because in most cases it is necessary to examine the specimen label before amending the database. Often a discrepancy can be caused by more than one error, and investigation of an error sometimes reveals related problems.
</td><td></td></tr></table>
EOP
	}
else{
#@names = $query->param;
#print elsewhere  "<h2>You tried to get</h2>";
#foreach $param_name (@names){
#print "$param_name: ", $query->param($param_name), "<br>";
#}
#$searched_for=~s/; *$//;
print $query->header unless $header_printed++;                    # create the HTTP header
#print "<4>";
		print <<EOP;
$common_html_head
$chc_header
<table cellpadding="20" class="bodyText"><tr><td>
<span class="pageName">Accession Results</span><br /><br />
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
	$lookfor=~s/(var\.|subsp\.|ssp\.|f\.|forma) //;
$lookfor=~s/&times;/�/;
	use Search::Dict;
	open(NAMES,"${data_path}CDL_name_list.txt") || die $!;
	#open(NAMES,"${data_path}CDL_name_list.txt") || die;
	$lookfor=lc($lookfor);
	look(\*NAMES, $lookfor);
	while(<NAMES>){
		if(m/^$lookfor/){
			chomp;
			if(s/^(.*) ([A-Z])/$2/){
			$looked_for_name=$1 unless $looked_for_name;
			}
			s/	*$//;
			@acc=split(/\t/);
			foreach(@acc){
				$found_names{$_}++ if $_;
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
	#tie %county, "BerkeleyDB::Hash", -Filename => "$CDL_county_file",-Flags=>DB_RDONLY or die "Cannot open file CDL_county: $! $BerkeleyDB::Error\n" ;
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
	if($before_after || (($year=~/^[12][890]\d\d$/) && not ($month || $day))){
	#if(($after || $before ) && $year){
           my @date_recno ;
           tie @date_recno, 'BerkeleyDB::Recno', -Filename   => "$CDL_date_recno_file", -Flags      => DB_RDONLY or die "Cannot open $filename: $! $BerkeleyDB::Error\n" ;
           #tie @date_recno, 'BerkeleyDB::Recno', -Filename   => "$CDL_date_recno_file", -Flags      => DB_RDONLY or die "Cannot open $filename: $! $BerkeleyDB::Error\n" ;
		if($before_after ==2){
			grep($date_acc{$_}++, split(/\t/, join("\t", @date_recno[$year+1 .. $#date_recno])));
		}
		elsif($before_after ==1){
			grep($date_acc{$_}++, split(/\t/,join("\t",@date_recno[1800 .. $year])));
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
    		tie %date_range, "BerkeleyDB::Hash", -Filename => "$CDL_date_range_file", -Flags=>DB_RDONLY or die "Cannot open file CDL_date_range: $! $BerkeleyDB::Error\n" ;
    		#tie %date_range, "BerkeleyDB::Hash", -Filename => "$CDL_date_range_file", -Flags=>DB_RDONLY or die "Cannot open file CDL_date_range: $! $BerkeleyDB::Error\n" ;

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
	
    		tie %date, "BerkeleyDB::Hash", -Filename => "$CDL_date_simple_file", Flags=>DB_RDONLY or die "Cannot open file CDL_date_simple: $! $BerkeleyDB::Error\n" ;
    		#tie %date, "BerkeleyDB::Hash", -Filename => "$CDL_date_simple_file", Flags=>DB_RDONLY or die "Cannot open file CDL_date_simple: $! $BerkeleyDB::Error\n" ;
		foreach $d ($ejd .. $ljd){
			grep($date_acc{$_}++, split(/\t/,$date{$d}));
		}
	
		if($lookfor_date){
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
#    confess() unless defined $day;

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
	print qq{<H2>Sorry. I can't open the geographic binary names file.</H2><h4><a href="mailto:rlmoe\@uclink4.berkeley.edu">Maybe we should tell someone</a></h4>};
	#die;
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
#warn "FLABBA";
	use Search::Dict;
	open(LOCS,"${data_path}CDL_location_words.txt") || do{
	print qq{<H2>Sorry. I can't open the geographic names file.</H2><h4><a href="mailto:rlmoe\@uclink4.berkeley.edu">Maybe we should tell someone</a></h4>};
	#die;
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
if($inst=~/YM/){
#$inst="YM-YOSE";
}
if($inst=~/^(AMES|GH|ECON|A)/){
$inst="HUH";
}
	if(grep(/^$inst$/,@source) || $inst eq $source || $source eq "All" || $source eq ""){
		return 1;
	}
	return 0;
}

sub push_result {
my $checked="";
	my $accession_id=shift;
@caller=caller;
	return 0 unless $CDL{$accession_id};
	if($season){
	return 0 unless $date_acc{$accession_id};
	}
	if($mapper_loc){
	return 0 unless $region{$accession_id};
	}
	if($geo_only){
	return 0 unless $CDL_GEO{$accession_id};
	}
	if($v_restrict){
	return 0 unless $VOUCHER{$_} =~/\b$v_restrict\t/;
	}
	if( $lookfor){
		return 0 unless  $name_acc{$accession_id};
	}
if($source){
return 0 unless &source_wanted($accession_id) ;
}
	@CDL_fields=split(/\t/,$CDL{$accession_id});
	if($include_nn){
		return 0 unless $gbif_nn{$CDL_fields[0]};
	}
	if($include_CNPS){
		return 0 unless $CNPS_tid{$CDL_fields[0]};
	}
	if($include_weed){
		return 0 unless $weed_tid{$CDL_fields[0]};
	}

$elev=$CDL_fields[9];
if($lo_e=~/\d/){
return 0 unless $elev_acc{$accession_id};
}
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
#$elev=~s/([0-9])(to|-).*/$1/;
	$elev=~s/ ?\(.*//;
	$elev=~s/^(about|above|near|above|below) //;
#$elev=int($elev/3.28);
}
$elev=~s/ -.*//;
$elev=~s/ ?[mM].*//;

#if($lo_e && $lo_e > $elev){
#return 0;
#}
#if($hi_e && $hi_e < $elev){
#return 0;
#}



	grep(s/>/&gt;/g,@CDL_fields);
	grep(s/</&lt;/g,@CDL_fields);
		$CDL_fields[2].="-" if ($CDL_fields[2]=~/\d$/ && $CDL_fields[3]);
	$date=$CDL_fields[7];
	$CDL_fields[10]=~s/^[ \|]+//;
	$CDL_fields[10]=~s/[ -]*$//;
	$CDL_fields[10]=~s/\[\]//;

	($location_key=$CDL_fields[10])=~s/^[^A-Z]+//;
	if($sort_field==0){
		$sort_string=$TID_TO_NAME{$CDL_fields[$sort_field]};
	}
	elsif($sort_field==11){
tie (%G_T_F, "BerkeleyDB::Hash", -Filename =>"/usr/local/web/ucjeps_data/G_T_F", -Flags => DB_RDONLY);
($sort_string=$TID_TO_NAME{$CDL_fields[0]})=~s/ .*//;
$sort_string="$G_T_F{$sort_string} $sort_string";
}
	elsif($sort_field==1){
		$sort_string=&get_coll_last_name($CDL_fields[$sort_field]);
		#($sort_string=$CDL_fields[$sort_field])=~s/ ?\(?(with|and|&) .*//;
		#$sort_string=~s/, .*//;
#Harold and Virginia Bailey
                        #$sort_string=~s/^[A-Z][a-z]+ and ?[A-Z][a-z-]+ ([A-Z][a-z-]+$)/$1/ ||
                        #$sort_string=~s/^[A-Z]\. ?[A-Z]\. and [A-Z]\. ?[A-Z]\. (.*)/$1/ ||
                        #$sort_string=~s/^[A-Z]\. and [A-Z]\. (.*)/$1/ ||
		#($sort_string=$CDL_fields[$sort_field])=~s/ ?\(?(with|and|&) .*//;
		#$sort_string=~s/, .*//;
		#$sort_string=~s/(.*) (.*)/$2 $1/;
		#$sort_string=~s/^ *//;
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
	elsif($sort_field==25){
		$sort_string=&get_comment_date($suggs{$accession_id});
	}
	else{
		$sort_string=$CDL_fields[$sort_field];
	}
###########remove > 200 to restore image links
	if($image_location{$accession_id}){
		$image_link=qq{<a href="/cgi-bin/display_smasch_img.pl?smasch_accno=$accession_id"><br /><img src="/common/images/ico_camera.gif" alt="Image available" border="0"></a>};
#Hide E. truncatum
		$image_link="" if $accession_id eq "UC692153";
$image_link="" if $accession_id eq "JEPS26640";
$image_link="" if $accession_id eq "JEPS27371";
$image_link="" if $accession_id eq "UC1212010";
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
#<a href="/suggs_${sugg_suffix}.html#$suggs{$accession_id}"><br>Read comments</a>
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
		if($select_georef){
			$checked="checked";
		}
		else{
			$checked="";
		}
	}
	elsif($CDL_new_coords{$accession_id}){
	@new_coords=split(/\t/,$CDL_new_coords{$accession_id});
		$check_bgcolor=" bgcolor=\"#ffAAAA\"";
		if($select_georef){
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
if($accession_id=~m/^(CAS|CDA|CHSC|DS|HSC|IRVC|JEPS|PGM|POM|RSA|SBBG|SD|SDSU|SJSU|UC|UCD|UCR|UCSB|UCSC|NY)\d+[A-Z]?$/){
	push(@QLOG,$accession_id);
}
	push(@result, <<EOP
<!-- $sort_string --><tr>
<td $check_bgcolor><input type ="checkbox" name="checked_AID" value=$accession_id $checked></td>
<td><a href="/cgi-bin/$detail?$accession_id">$accession_id</a>&nbsp;$image_link</td>
<td>$tax_name</td>
<td>$CDL_fields[1]</td>
<td>$date</td>
<td>$CDL_fields[2]$CDL_fields[3]$CDL_fields[4]</td>
<td>$CDL_fields[8]</td>
<td>$CDL_fields[10]</td>
<td>$elev</td>
<td valign="top"><a href="/cgi-bin/get_consort.pl?sugg=$accession_id">Comment</a> $seen_sugg</td>
</tr>
EOP
);
	if($CDL_fields[11] && $CDL_fields[12]){
		($institution=$accession_id)=~s/\d.*//;
		push(@map_results, join("\t", $institution, $accession_id, $TID_TO_NAME{$CDL_fields[0]}, @CDL_fields[1 .. $#CDL_fields], "NAD 27"));
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

sub get_coll_num_acc {
	my $number= shift;
	tie %CN, "BerkeleyDB::Hash", -Filename => "$CDL_coll_number_file",-Flags=>DB_RDONLY or die "Cannot open file CDL_coll_number: $! $BerkeleyDB::Error\n" ;
	#tie %CN, "BerkeleyDB::Hash", -Filename => "$CDL_coll_number_file",-Flags=>DB_RDONLY or die "Cannot open file CDL_coll_number: $! $BerkeleyDB::Error\n" ;
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
<table width="100%" class="banner" border="0" cellpadding="0" cellspacing="0">
  <tr><td width="100" align="center"><img src="/consortium/images/CCH_logo_02_80.png" width="80" height="82"></td>
  <td>
<table class="banner" width="100%" border="0">
  <tr>
    <td align="center">Consortium of California Herbaria</td>
  </tr>
  <tr>
    <td class="bannerHerbs" align="center">
          <font  face="Times New Roman, Times, serif" color="#FEFEFE"><b>
        <a href="http://www.calacademy.org/research/botany/" target="_blank" class="bannerHerbs">
          CAS-DS</a> &middot; 
<a href="http://cdfa.ca.gov/phpps/PPD/herbarium.html" target="_blank" class="bannerHerbs">
	  CDA</a> &middot; 
        <a href="http://www.csuchico.edu/biol/Herb/" target="_blank" class="bannerHerbs">
          CHSC</a> &middot; 
        <a href="http://herbarium.ucdavis.edu/" target="_blank" class="bannerHerbs">
          DAV</a> &middot; 
        <a href="http://www.humboldt.edu/herbarium/index.html" target="_blank" class="bannerHerbs">
          HSC</a> &middot; 
        <a href="http://ucjeps.berkeley.edu/consortium/irvc.html" target="_blank" class="bannerHerbs">
          IRVC</a> &middot; 
        <a href="http://www.calpoly.edu/~bio/Herbarium.html" target="_blank" class="bannerHerbs">
          OBI</a> &middot;
        <a href="http://www.pgmuseum.org/" target="_blank" class="bannerHerbs">
          PGM</a> &middot;
        <a href="http://www.rsabg.org/" target="_blank" class="bannerHerbs">
          RSA-POM</a> &middot; 
        <a href="http://www.sbbg.org/" target="_blank" class="bannerHerbs">
          SBBG</a> &middot; 
        <a href="http://www.sdnhm.org/research/botany/" target="_blank" class="bannerHerbs">
          SD</a> &middot; 
<a href="http://www.sci.sdsu.edu/herb" target="_blank" class="bannerHerbs">          SDSU</a> &middot; 
        <a href="http://www2.sjsu.edu/depts/herbarium/" target="_blank" class="bannerHerbs">
          SJSU</a>  &middot; 
        <a href="http://ucjeps.berkeley.edu/" target="_blank" class="bannerHerbs">
          UC-JEPS</a>  &middot; 
        <a href="http://www.herbarium.ucr.edu/" target="_blank" class="bannerHerbs">
          UCR</a> &middot; 
        <a href="http://ccber.lifesci.ucsb.edu/collections/botanical/" target="_blank" class="bannerHerbs">
          UCSB</a> &middot; 
        <a href="http://mnhc.ucsc.edu/" target="_blank" class="bannerHerbs">
          UCSC</a> &middot; 
        <a href="" target="_blank" class="bannerHerbs">
YM</a>
        </b></font>

        </td>
  </tr>
</table>
</td></tr><tr><td colspan="2">

<!-- Beginning of horizontal menu -->
<table class=horizMenu width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td width="1" >&nbsp;</td>
    <td height="21" width="640" align="center">
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/participants.html" class="horizMenuActive">
	    Participants</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/news.html" class="horizMenuActive">News</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/" class="horizMenuActive">Search</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/about.html" class="horizMenuActive ">About</a>
    </td>
	<td></td>
  </tr>
 <tr>
    <td colspan="6" bgcolor="#9FBFFF"><img src="/common/images/common_spacer.gif" alt="" width="1" height="1" border="0" /></td>
  </tr>
</table>
<!-- End of horizontal menu -->
</td></tr></table>

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

<!-- Footer begins -->
<table width="100%" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td height="18" bgcolor="9090AA"><img src="/common/images/common_spacer.gif" alt="" width="1" height="1" border="0" /></td>
  </tr>
  <tr>
    <td height="20"><span class="copyrightText">&nbsp;&nbsp;Copyright &copy; 2010 Regents of the University of California &mdash; Database extract updated $update 
</span>



  </tr>
</table>
<!-- Footer ends -->

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
		if(s/ ?\(?(with|and|&) (.*)//){
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
           #Find null-byte density then select best algorithm
           #if ($vec =~ tr/\0// / length $vec > 0.95) {
               #use integer;
               #my $i;
               # This method is faster with mostly null-bytes
               #while($vec =~ /[^\0]/g ) {
                   #$i = -9 + 8 * pos $vec;
                   #push @ints, $i if vec($vec, ++$i, 1);
                   #push @ints, $i if vec($vec, ++$i, 1);
                   #push @ints, $i if vec($vec, ++$i, 1);
                   #push @ints, $i if vec($vec, ++$i, 1);
                   #push @ints, $i if vec($vec, ++$i, 1);
                   #push @ints, $i if vec($vec, ++$i, 1);
                   #push @ints, $i if vec($vec, ++$i, 1);
                   #push @ints, $i if vec($vec, ++$i, 1);
               #}
           #} else {
               # This method is a fast general algorithm
               use integer;
               my $bits = unpack "b*", $vec;
               push @ints, 0 if $bits =~ s/^(\d)// && $1;
               push @ints, pos $bits while($bits =~ /1/g);
           #}
           #print join (" ",@ints);
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


