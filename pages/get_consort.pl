#!/usr/bin/perl
$detail="new_detail.pl";
$start_time=time;

#Output file to store data for Berkeley Mapper
$tab_file_name="CHC_" . substr($start_time,6,4) . $$ . ".txt";
$map_file_path="/usr/local/web/ucjeps_web/";
$map_file_out = "tmp/ms_tmp/$tab_file_name";
$map_file_URL= "http://ucjeps.berkeley.edu/$map_file_out";

#data files
$data_path	="/usr/local/web/ucjeps_data/";
$comment_hash	="${data_path}suggs_tally";
$CDL_name_list_file	="${data_path}CDL_name_list.txt";
$CDL_nomsyn_file	="${data_path}CDL_nomsyn";
$CDL_DBM_file	="${data_path}CDL_DBM";
$CDL_taxon_id_file	="${data_path}CDL_TID_TO_NAME";
$CDL_coll_number_file	="${data_path}CDL_coll_number";
$CDL_date_simple_file	="${data_path}CDL_date_simple";
$CDL_date_range_file	="${data_path}CDL_date_range";
$CDL_county_file	="${data_path}CDL_county";
$image_file	="${data_path}SMASCH_IMAGES";

%fips_trans=&load_fips;
$chc_header= &load_header;
$consortium_footer=&load_footer;

$common_html_head=<<EOH;
<html>
<head>
<Meta NAME="ROBOTS" CONTENT="NOINDEX, NOFOLLOW">
<title>UC/JEPS: Consortium Accession Results</title>
<link href="../consortium/style_consortium.css" rel="stylesheet" type="text/css">
</head>
<body>
EOH

use CGI;

#multiplication sign for hybridity
$times=CGI::Util::unescape("%D7") || "flabba";
use BerkeleyDB;
tie(%suggs, "BerkeleyDB::Hash", -Filename=>"$comment_hash", -Flags=>DB_RDONLY)|| die "$!";
tie(%image_location, "BerkeleyDB::Hash", -Filename=>"$image_file", -Flags=>DB_RDONLY)|| die "$!";
$query = new CGI;                        # create new CGI object
print $query->header;                    # create the HTTP header
@result=();
@map_results=();

 $make_tax_list=$query->param('make_tax_list');
    %taxonomic_list=();



@county= $query->param('county');
if($query->param('county')=~/^\d+$/){
	foreach(@county){
		$_=$fips_trans{$_};
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
@source	=$query->param('source');
#@source=grep(s/H-/PGM/,@source);
$source	=$source[$#source];
$collector	=$query->param('collector');
$excl_collector	=$query->param('excl_collector');
$aid	=$query->param('accn_num');
$sort_field	=$query->param('SO');
$year	=$query->param('year');
$month	=$query->param('month');
$day	=$query->param('day');
$loc	=$query->param('loc');
$ejdate	=$query->param('ejdate');
$check_all	=$query->param('check_all');
#Array containing accession_ids of all checked lines in form
@checked	=$query->param('checked_AID');
$sugg	=$query->param('sugg');
$coll_num	=$query->param('coll_num');
$select_georef	=$query->param('georef_only') || 0;

grep($checked{$_}++,@checked);
$check_all="checked" if $check_all == 1;

$max_return=$query->param('max_rec');
$max_return=2000 unless $max_return=~/^10000$/;
$max_return=9000 if $make_tax_list;

$search_hints=&search_hints;

if(@source){
	$req_source=join("&source=",@source);
}
else{
	$req_source="";
}
$current_request=$query->param('current_request') ||
qq{/cgi-bin/get_consort.pl?county=$county&source=$req_source&taxon_name=$lookfor&collector=$collector&excl_collector=$excl_collector&aid=$aid&year=$year&month=$month&day=$day&loc=$loc&coll_num=$coll_num&max_rec=$max_return};


if($lookfor){
	$lookfor=~s/ [xX] / $times /;
	$lookfor=~s/ $times([a-z])/ $times $1/;
	tie(%nomsyns, "BerkeleyDB::Hash", -Filename=>"$CDL_nomsyn_file", -Flags=>DB_RDONLY)|| die "$!";
	if($nomsyns{lc($lookfor)}){
		@nomsyns=split(/\t/,$nomsyns{lc($lookfor)});
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
	%loc_acc=&get_loc_acc("$loc");
}

if($year){
	%date_acc=&get_date_acc($year, $month, $day);
}
if($ejdate){
	%date_acc=&get_date_acc($ejdate);
}

tie %CDL, "BerkeleyDB::Hash", -Filename=>"$CDL_DBM_file", -Flags=>DB_RDONLY or die "Cannot open file CDL_DBM: $! $BerkeleyDB::Error\n" ;
tie(%TID_TO_NAME, "BerkeleyDB::Hash", -Filename=>"$CDL_taxon_id_file", -Flags=>DB_RDONLY)|| die "$!";

if(@checked){
	foreach(keys(%checked)){
			&push_result($_);
	}
}
elsif($year && $loc && $county && $collector){
	foreach(keys(%loc_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && ($date_acc{$_} && $county_acc{$_} && $coll_acc{$_})){
			&push_result($_);
		}
	}
}
elsif($year && $loc && $county){
	foreach(keys(%loc_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && ($date_acc{$_} && $county_acc{$_})){
			&push_result($_);
		}
	}
}
elsif($year && $collector && $county){
	foreach(keys(%date_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && ($county_acc{$_} && $coll_acc{$_})){
			&push_result($_);
		}
	}
}
elsif($year && $loc && $collector){
	foreach(keys(%loc_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && ($date_acc{$_} && $coll_acc{$_})){
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
elsif($year && $loc){
	foreach(keys(%loc_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $date_acc{$_}){
			&push_result($_);
		}
	}
}
elsif($year && $collector){
	foreach(keys(%date_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $coll_acc{$_}){
			&push_result($_);
		}
	}
}
elsif($year && $loc){
	foreach(keys(%loc_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $date_acc{$_}){
			&push_result($_);
		}
	}
}
elsif($year && $county){
	foreach(keys(%date_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $county_acc{$_}){
			&push_result($_);
		}
	}
}
elsif($collector && $county){
	foreach(keys(%coll_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $county_acc{$_}){
			&push_result($_);
		}
	}
}
elsif($loc && $county){
	foreach(keys(%loc_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $county_acc{$_}){
			&push_result($_);
		}
	}
}
elsif($loc && $collector){
	foreach(keys(%loc_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return) && $coll_acc{$_}){
			&push_result($_);
		}
	}
}
elsif($year){
	foreach(keys(%date_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($ejdate){
	foreach(keys(%date_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($county){
	foreach(keys(%county_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($collector){
	foreach(keys(%coll_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($loc){
	foreach(keys(%loc_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($lookfor){
	foreach(keys(%name_acc)){
		if(&num_wanted($_) && &source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
elsif($coll_num){
	foreach(keys(%coll_num_acc)){
		if(&source_wanted($_) && (scalar(@result) < $max_return)){
			&push_result($_);
		}
	}
}
else{}
$returns= scalar(@result);
&print_table_header($returns);
$end_time=times();
#printf "%.2f CPU seconds\n", $end_time - $start_time;
if(@checked){
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
	print "</pre></html>";
}
else{
	foreach(sort(@result)){
			if (++$bgcount %2){
				$bgc="#ffffff" ;
			}
			else{
				$bgc="#dddddd" ;
			}
	s/<tr/<tr bgcolor=$bgc/;
	s/\+\\-/&plusmn;/g;
	s/º:/&degr;/g;
	s/½:/1\/2/g;;
	s/¼:/1\/4/g;;
	s/ë</&euml;/g;
	s/±:/&plusmn;/g;
	s/é:/&eacute;/g;
	s/’/'/g;
	s/ño/&ntilde;/g;
	print "$_";
	}
print <<EOP;
</table></form>
$consortium_footer
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-1304595-1";
urchinTracker();
</script>
</body></html>
EOP
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
	$Search_page="../consortium/index.html";
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
	}
	if($source){
		$searched_for .="Source=" .  join(", ",@source). "; ";
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
	if($number_of_records > 0){
		$plural="s" if $number_of_records > 1;
	if(@checked){
		print <<EOP;
<html>
<pre>
EOP
	}
	else{
		if(@map_results){
			grep(s/\|/_/g,@map_results);
			$record_number=scalar(@map_results) . " record";
			$record_number .="s" if $#map_results > 0;
			#grep(s/\t/|/g,@map_results);
			$mappable=<<EOP;
<br><a href="http://berkeleymapper.berkeley.edu/run.php?ViewResults=tab&tabfile=$map_file_URL&configfile=http%3A%2F%2Fucjeps.berkeley.edu%2Fucjeps.xml&sourcename=Consortium+of+California+Herbaria+result+set&">Map the results using BerkeleyMapper ($record_number with coordinates [those with a <font color=\"#00FF00\">light green</font> checkbox])</a>
EOP
			open(MAPFILE, ">$map_file_path$map_file_out") || die;
			print MAPFILE join("\n",@map_results);
			close(MAPFILE);
		}
		else{
			$mappable="<br>No results can be mapped";
		}
		print <<EOP;
$common_html_head

$chc_header
<table width="100%" cellpadding="20" class="bodyText"><tr><td>
<span class="pageName">Accession Results</span>
<span class="pageSubheading"> &mdash; $number_of_records record$plural retrieved</span>
<br />
<span class="bodyText">Results for search: $searched_for</span>
$mappable
<form method="post" action="/cgi-bin/get_consort.pl">
<br>
<a href="${current_request}&check_all=1">Select all records</a>
<br>
<a href="${current_request}&georef_only=1">Select records with coordinates</a>
<br>
<input type="submit" value="Retrieve selected records">
</td></tr></table>


<table width="100%" cellpadding="5" class="bodyText">
<tr><td colspan="9">
Click on accession number to display detailed record; click on column header to sort data; click in leftmost checkbox to select record.
</td>
</tr>
<tr bgcolor="#cccccc">
<th></th>
<th><a href="${current_request}&SO=10">Accession ID</a></th>
<th><a href="${current_request}&SO=0">Determination</a></th>
<th><a href="${current_request}&SO=1">Collector</a></th>
<th><a href="${current_request}&SO=5">Collection Date</a></th>
<th><a href="${current_request}&SO=3">Collection Number</a></th>
<th><a href="${current_request}&SO=8">County</a></th>
<th><a href="${current_request}&SO=20">Locality</a></th>
<th><a href="${current_request}&SO=9">Elevation in meters</a></th>
<th>Feedback</th>
</tr>

EOP
		}
	}
	elsif($sugg){
		@CDL_fields=split(/\t/,$CDL{$sugg});
		grep(s/>/&gt;/g,@CDL_fields);
		grep(s/</&lt;/g,@CDL_fields);
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
<option>Multiple corrections</option>
</select>
</td>
</tr>
<tr>
<td colspan=4>Comments: <textarea name="sugg_feedback_comments" cols=50></textarea></td>
<td><input type="submit"></td>
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

		print <<EOP;
$common_html_head
$chc_header
<table cellpadding="20" class="bodyText"><tr><td>
<span class="pageName">Accession Results</span><br /><br />
<span class="pageSubheading">No records were retrieved</span>
<P>

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
	my $lookfor=shift;
	$lookfor=~s/(var\.|subsp\.) //;
	use Search::Dict;
	open(NAMES,"/usr/local/web/ucjeps_data/CDL_name_list.txt") || die;
	$lookfor=lc($lookfor);
	look(\*NAMES, $lookfor);
	while(<NAMES>){
		if(m/^$lookfor/){
			chomp;
			s/^.* ([A-Z])/$1/;
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

	open(COLLS,"/usr/local/web/ucjeps_data/CDL_collectors.txt") || print "$!couldnt open COLLS\n";
	if($excl_collector){
		while(<COLLS>){
			unless(m/^$collector/){
				chomp;
				s/^[^ ]+ //;
				s/	*$//;
				@acc=split(/ *\t/);
				grep($found_coll{$_}++,@acc);
			}
		}
	}
	else{
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
	}
	close(COLLS);
	return %found_coll;
}


sub get_county_acc {
	my @county = @_;
	tie %county, "BerkeleyDB::Hash", -Filename => "$CDL_county_file",-Flags=>DB_RDONLY or die "Cannot open file CDL_county: $! $BerkeleyDB::Error\n" ;
	foreach $county (@county){
	$county=uc($county);
	grep($county_acc{$_}++, split(/\t/,$county{"$county"}));
	}
	return %county_acc;
}
sub get_date_acc {
	my $year = shift;
	my $month = shift;
	my $day = shift;
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
	}
    tie %date_range, "BerkeleyDB::Hash", -Filename => "$CDL_date_range_file", -Flags=>DB_RDONLY
        or die "Cannot open file CDL_date_range: $! $BerkeleyDB::Error\n" ;

	foreach $key (sort(keys(%date_range))){
#print "<br>K$key";
		if($key=~m/^(\d+)-(\d+)/){
			$begin=$1; $end=$2;
		}
		if($ejd < $begin || $ljd > $end){
			#next;
		}
		foreach $d ($ejd .. $ljd){
			#print " B$begin E$end D$d<br>";
			if($d >= $begin && $d <=$end){
				grep($date_acc{$_}++, split(/\t/,$date_range{$key}));
			}
		}
		foreach(keys(%date_acc)){
			#print "<br>RANGE: $_: $date_acc{$_}";
		}
	}

    tie %date, "BerkeleyDB::Hash", -Filename => "$CDL_date_simple_file", Flags=>DB_RDONLY
        or die "Cannot open file CDL_date_simple: $! $BerkeleyDB::Error\n" ;
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

sub get_loc_acc {
	use Search::Dict;
	open(LOCS,"/usr/local/web/ucjeps_data/CDL_location_words.txt") || do{
	print qq{<H2>Sorry. I can't open the geographic names file.</H2><h4><a href="mailto:rlmoe\@uclink4.berkeley.edu">Maybe we should tell someone</a></h4>};
	die;
	};
	$locs=shift;
	$complete_locs=$locs;
	$locs=~s/\b(road|junction|san|near|the|and|along|hwy|side|from|nevada|above|north|south|between|county|end|about|miles|just|hills|area|quad|slope|west|east|state|air|northern|below|region|quadrangle|cyn|with|mouth|head|old|base|collected|city|lower|beach|line|mile|california|edge|del|off|ave)\b *//ig; 
	unless($locs eq $complete_locs){
		if(length($locs) > 2){
			print "$complete_locs contains one or more common words: using $locs";
		}
		else{
			print "$complete_locs contains only words too common to search for";
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
if( $lookfor){
return 0 unless  $name_acc{$accession_id};
}
	@CDL_fields=split(/\t/,$CDL{$accession_id});


$elev=$CDL_fields[9];
$elev=~s/,//g;
$elev=~s/zero/0/;
$elev=~s/[Ss]ea [Ll]evel/0/;
$elev=~s/ca?\.? //;
$elev=~s/ca\.//;
$elev=~s/[<>]//g;
if($elev=~s/(\d) ?[Ff].*/$1/){
unless($elev=~s!(\d+) *(to|-) *(\d+)!int($1/3.28) . "-" .int($3/3.28)!e){
$elev=int($elev/3.3);
}
#$elev=~s/([0-9])(to|-).*/$1/;
$elev=~s/ ?\(.*//;
$elev=~s/^(about|above|near|above|below) //;
#$elev=int($elev/3.3);
}
$elev=~s/ -.*//;
$elev=~s/ ?[mM].*//;




	grep(s/>/&gt;/g,@CDL_fields);
	grep(s/</&lt;/g,@CDL_fields);
	$date=$CDL_fields[7];
	$CDL_fields[10]=~s/^[ \|]+//;
	($location_key=$CDL_fields[10])=~s/^[^A-Z]+//;
	if($sort_field==0){
		$sort_string=$TID_TO_NAME{$CDL_fields[$sort_field]};
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
	elsif($sort_field==9){
		$sort_string=sprintf("%04d", $elev);
	}
	elsif($sort_field==20){
		$sort_string=$location_key;
	}
	else{
		$sort_string=$CDL_fields[$sort_field];
	}
###########remove > 200 to restore image links
	if($image_location{$accession_id}){
		$image_link=qq{<a href="/cgi-bin/display_smasch_img.pl?smasch_accno=$accession_id"><br /><img src="/common/images/ico_camera.gif" alt="Image available" border="0"></a>};
#Hide E. truncatum
		$image_link="" if $accession_id eq "UC692153";
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
		$seen_sugg=<<EOP;
<a href="/cgi-bin/display_chc_comment.pl?comment_id=$accession_id"><br>Read comments</a>
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
	else{
		$check_bgcolor="";
	}
	($tax_name=$TID_TO_NAME{$CDL_fields[0]})=~s/$times /$times/o;

if($make_tax_list){
    if($taxonomic_list{$tax_name}++){return 0;}
    }

$checked=$check_all unless $checked;
	push(@result, <<EOP
<!--$sort_string --><tr>
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
}

sub get_date{
	my $date=shift;
	($year,$month,$day)=inverse_julian_day($date);
	$month=("",Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$month];
	return "$month $day $year";
}

sub get_coll_num_acc {
	my $number= shift;
	tie %CN, "BerkeleyDB::Hash", -Filename => "$CDL_coll_number_file",-Flags=>DB_RDONLY
        or die "Cannot open file CDL_coll_number: $! $BerkeleyDB::Error\n" ;
	grep($coll_num_acc{$_}++, split(/ ?\t ?/,$CN{$number}));
	return %coll_num_acc;
	untie(%CN);
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

<table class="banner" width="100%" border="0">
  <tr>
    <td align="center">Consortium of California Herbaria</td>
  </tr>
  <tr>
    <td class="bannerHerbs" align="center">
	<a class="bannerHerbs" href="http://ucjeps.berkeley.edu/active.html">JEPS</a> &middot; 	
	<a class="bannerHerbs" href="http://www.sbbg.org/">SBBG</a> &middot; 
	<a class="bannerHerbs" href="http://www.csuchico.edu/biol/Herb/index.html">CHSC</a> &middot; 
	<a class="bannerHerbs" href="http://herbarium.ucdavis.edu/">DAV</a> &middot; 
	<span>IRVC</span> &middot; 
	<a class="bannerHerbs" href="http://www.herbarium.ucr.edu/">UCR</a> &middot; 
	<a class="bannerHerbs" href="http://www.lifesci.ucsb.edu/~mseweb/index.html">UCSB</a> &middot; 
	<a class="bannerHerbs" href="http://mnhc.ucsc.edu/">UCSC</a> &middot; 
	<a class="bannerHerbs" href="http://ucjeps.berkeley.edu/ucherb.html">UC</a>  &middot; 
	<a class="bannerHerbs" href="http://www.rsabg.org/">RSA-POM</a> &middot; 
	<a class="bannerHerbs" href="http://www2.sjsu.edu/depts/herbarium/">SJSU</a> &middot;
	<a class="bannerHerbs" href="http://www.sdnhm.org/research/botany/">SD</a> &middot; 
        <a class="bannerHerbs" href="http://www.pgmuseum.org/"> PGM</a> 
    </td>
  </tr>
</table>

<!-- Beginning of horizontal menu -->
<table class=horizMenu width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td height="21" width="640" align="right"> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/participants.html" class="horizMenuActive">
	    Participants</a> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/news.html" class="horizMenuActive">News</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/" class="horizMenuActive">Search</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/about.html" class="horizMenuActive">About</a>
	  </td>
	<td />
  </tr>
 <tr>
    <td colspan="6" bgcolor="#9FBFFF"><img src="../common/images/common_spacer.gif" alt="" width="1" height="1" border="0" /></td>
  </tr>
</table>
<!-- End of horizontal menu -->

EOH
}
sub load_footer{
#get date of most recent update of CDL files
	@updated= localtime((stat("/usr/local/web/ucjeps_data/CDL_name_list.txt"))[9]);
$thisyear=$updated[5];
$thisyear +=1900;
$update=$updated[4]+1  . "/". $updated[3] . "/" . $thisyear;
	return <<EOH;

<!-- Footer begins -->
<table width="100%" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td height="18" bgcolor="9090AA"><img src="../common/images/common_spacer.gif" alt="" width="1" height="1" border="0" /></td>
  </tr>
  <tr>
    <td height="20"><span class="copyrightText">&nbsp;&nbsp;Copyright &copy; 2006 Regents of the University of California &mdash; Database extract updated $update 
<br>
Please cite data retrieved from this page: Data provided by the participants of the Consortium of California Herbaria (ucjeps.berkeley.edu/consortium/).</span>
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
