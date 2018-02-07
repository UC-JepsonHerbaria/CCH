use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA';
use CCH; #loads non-vascular plant names list ("mosses"), alter_names table, and max_elev values
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
$today_JD=julian_day($today_y, $today_m, $today_d);

&load_noauth_name;

###Dick used to maintain a list of collectors to call out inconsistencies
###We don't provide that service anymore
#open(IN,"../CDL/collectors_id") || die;
#while(<IN>){
#	if(m/\cM/){
#	die;
#	}
#	chomp;
#s/\t.*//;
#	$coll_comm{$_}++;
#}

#CHSC evidently keeps changing the record delimiter tag
$/=qq{<CurrentName_with_all_fields>};
#$/=qq{<chico>};
#$/= "<CHSC_for_CalHerbConsort>";
#$/="<CHSC_for_x0020_CalHerbConsort>";

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";
open(ERROR, ">Chico_error") || die; #note that the print ERROR often includes all content in XML tabs separated by Windows line breaks, which can be confusing if opened not in vi. Consider revising

open(OUT, ">CHSC.out") || die; 
open(IN,"chico.xml") || die;
#open(IN,"chico_2014-03-21.xml") || die;
#open(IN,"CHSC_for_CalHerbConsort.xml") || die;
#open(IN,"chico_test") || die;
while(<IN>){
	s/\cM//g;
	chomp;
	&CCH::check_file;



#This was in here, and made the parser die
#so I commented it out
#	if(m/\cM/){
#	die "$_\n";
#	}


	next if m/<Division>.*(Myxomycetes|Anthocerotae|Hepaticae|lichens|Musci)/;
  #18 <Division>Anthocerotae (hornworts)</Division>
#66797 <Division>Anthophyta (flowering plants)</Division>
 #514 <Division>Coniferophyta (conifers)</Division>
  #39 <Division>Gnetophyta (gnetae)</Division>
 #255 <Division>Hepaticae (liverworts)</Division>
 #177 <Division>Lycophyta (club mosses)</Division>
#1612 <Division>Musci (mosses)</Division>
#7644 <Division>Myxomycetes (slime molds)</Division>
#1209 <Division>Pterophyta (ferns)</Division>
 #149 <Division>Sphenophyta (horsetails)</Division>
 #918 <Division>lichens</Division>

	($err_line=$_)=~s/\n/\t/g;
$CNUM_PREFIX= $CNUM_SUFFIX=
$comb_coll=$assoc=$genus=$LatitudeDirection=$LongitudeDirection=$date=
$collnum= $coll_num_prefix= $coll_num_suffix= $name= $accession_id=
$county= $locality= $Unified_TRS= $elevation= $collector= $other_coll=
$ecology= $color= $lat= $long= $decimal_lat= $decimal_long=$annotation="";
$hybrid_annotation="";
s/&quot;/"/g;
s/&apos;/'/g;
s/&amp;/&/g;
s/&lt;/</g;
s/&gt;/>/g;
		$state="CA";
	unless(m/<Accession>\d+<\/Accession>/){
		print ERROR "No Id, skipped $err_line\n";
		next;
	}
	($accession_id)=m/<Accession>(.*)</;
	$accession_id="CHSC$accession_id";
	if($seen{$accession_id}++){
		++$skipped{one};
		warn "Duplicate number: $accession_id<\n";
		print ERROR<<EOP;

Duplicate accession number, skipped: $accession_id
EOP
		next;
	}


#################SCIENTIFIC NAME PROCESSING
	if(m|<CGenus>(.+)</CGenus>|){
		$name=$1;
		$genus=$1;
		unless($genus){
			print ERROR "No generic name, skipped: $err_line\n";
			next;
		}
	}
	if(m|<CSpecificEpithet>(.+)</CSpecificEpithet>|){
		$name.=" " . lc($1);
		$name=~s/ +l\.$//; #some records in CHSC have the author included in SpecificEpithet. This at least fixes Linnaeus
	}
	if(m|<CRank>(.+)</CRank>|){
		$rank=$1;
		$rank=~s/form.*/f./;
		$rank.=".";
		$rank=~s/\.\././;
		$name.=" $rank";
	}
	if(m|<CInfraspecificName>(.+)</CInfraspecificName>|){
		$name.=" " . lc($1);
	}


$name=~s/  */ /g;
			if($name=~s/([A-Z][a-z-]+ [a-z-]+) × /$1 X /){
			#if($name=~/([A-Z][a-z-]+ [a-z-]+) × /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/([A-Z][a-z-]+ [a-z-]+) [Xx]\.? /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/([A-Z][a-z-]+ [a-z-]+ var. [a-z-]+) × /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
		$name=~s/ × / X /;
		$name=~s/ x / X /;
		$name=~s/ssp\./subsp./;
		$name=~s/<!\[CDATA\[(.*)\]\]>/$1/i;
		$name=~s/ cultivar\. .*//;
		$name=~s/ (cf\.|affn?\.|sp\.)//;
		$name=~s/ subsp\.$//;
		$name=~s/ var\.$//;
		$name=~s/`//;
		$name=~s/'//;
		$name=~s/~//;
		$name=~s/ *\?//;

#$name = &strip_name($name); #this should be included. Make sure it works
$name = &validate_scientific_name($name, $accession_id);




##############Det Date
if(m/<DeterminedDate>(.*)<\/Det/){
	($det_date=$1)=~s/T.*//;;
}
else{
	$det_date="";
}
if(m/<CDeterminedBy>(.*)<\/CDet/){
	$det_by=$1;
	$det_by="" if $det_by =~/erbarium/;
	if($det_by){
		$annotation="$name; $det_by; $det_date";
	}
}
else{
	$det_by="";
}
	if(m|<Elevation>(.+)</Elevation>|){
		$elevation=$1;
		if(m|<ElevationUnits>(.*)</ElevationUnits>|){
			$elevation.=" $1";
			$elevation=~s/\. *//;
		}
	}
	elsif(s/ *(Elevation|Elev\.) (\d+) *//i){
		$elevation="$2 ft";
	}
	elsif(s/ *(Elevation|Elev\.) (\d+) *ft\.?//i){
		$elevation="$2 ft";
	}
	elsif(s/ *(Elevation|Elev\.) (\d+) *feet\.?//i){
		$elevation="$2 ft";
	}
	elsif(s/ *(Elevation|Elev\.) (\d+) *m\.?//i){
		$elevation="$2 m";
	}
	else{
		$elevation="";
	}
	if(($locality)=m|<Locality>(.+)</Locality>|){
		$locality=~s/<!\[CDATA\[(.*)\]\]>/$1/;
		$locality=~s/CALIFORNIA[:,.] .*(CO|County)[.:;,]+//i;
$locality=~s/^ *[,.:;] *//;
$locality=~s/[,.:; ]+$//;
		#print "$locality\n";
	}
	else{
		$locality="";
	}
	
	if($locality=~"Strybing Arb|Chico Tree Improvement Center"){
		print ERROR "Specimen from cultivation, skipped: $locality $err_line\n";
		next;
	}
	
	if(m|<Date>(.*)</Date>|){
		$date=$1;
		$date=~s/T\d.*//;
		$date=~s/<!\[CDATA\[ *(.*)\]\]>/$1/;
#Note ells in date
		$date=~s/l(9\d\d)/1$1/;
=other date formats
		if($date=~m/(\d\d\d\d)-(\d+)-(\d+)/){
			$month=$2; $day=$3; $year=$1;
		}
		elsif($date=~m/^/){
		elsif($date=~m/^\d+[- ]+[A-Za-z.]+[ -]+\d\d\d\d/){
			($day,$month,$year)=split(/[- .]+/,$date);
			$month=substr($month,0,3);
			unless($month=~/[A-Za-z][a-z][a-z]/){
				warn "1 Date problem:  $date\n";
			}
		}
		elsif($date=~m/([A-Za-z.]+) +(\d+),? +(\d\d\d\d)/){
			$month=$1; $day=$2; $year=$3;
		}
		elsif($date=~m/^([A-Za-z.,]+) +(\d\d\d\d)/){
			$month=$1; $year=$2; $day="";
		}
		elsif($date=~m|\d+/\d+/\d\d\d\d|){
			#date is OK;
		}
		elsif($date=~m|^(\d\d\d\d)\??|){
			$date=$1;
		}
		elsif($date=~m|(\d+)[/ ]*([A-Za-z,.]+)[/ ]*(\d\d\d\d)|){
				$day=$1; $month=$2;$year=$3;
		}
		elsif($date=~m|(\d+)[/ ]*([A-Za-z,.]+)[/ ]*([1-9]\d)$|){
				$day=$1; $month=$2;$year="19$3";
		print ERROR "Y2K problem, $date = $year?: $err_line\n";
		}
		elsif($date=~m|(\d+)/(\d+)/([1-9]\d)$|){
				$day=$1; $month=$2;$year="19$3";
		print ERROR "Y2K problem, $date = $year?: $err_line\n";
		}
		elsif($date=~m|(\d+)[/ ]*([A-Za-z,.]+)[/ ]*(0\d)$|){
				$day=$1; $month=$2;$year="20$3";
		print ERROR "Y2K problem, $date = $year?: $err_line\n";
		}
		elsif($date=~m|(\d+)/(\d+)/(0\d)$|){
				$day=$1; $month=$2;$year="20$3";
		print ERROR "Y2K problem, $date = $year?: $err_line\n";
		}
		elsif($date=~m|(\d+-\d+)[- ]+([A-Za-z.])+[ -]+(\d\d\d\d)|){
				$day=$1; $month=$2;$year=$3;
			}
		elsif($date=~m|19(\d)_\?|){
			$year="19${1}0s";
			}
		elsif($date=~m|19__\?|){
			$year="1900s";
			}
		else{
			print ERROR "Fall thru Date problem: $date made null $err_line\n";
			$date="";
		}
=cut
		if($date=~/^([12][0789]\d\d)-(\d\d)-(\d\d)$/){
			$month=$2; $day=$3; $year=$1;
			if(m|<DatePrecision>Month</DatePrecision>|){
				$day="";
				
			}
			elsif(m|<DatePrecision>Year</DatePrecision>|){
				$day=""; $month="";
			}
		}
		else{
			print ERROR "Date format problem: $date made null $err_line\n";
			$date="";
		}

$day="" if $day eq "00";
			$month=substr($month,0,3);
$date = "$month $day $year";
$date=~s/  */ /g;


#This is the date-checking code from newer loaders, which uses JD
		if($year && $month && $day){	#If a year, month, and day value are present,
					$JD=julian_day($year, $month, $day);	#create the Julian Day ($JD) based on that year, month, and day
					$LJD=$JD;	#Then set the late Julian Day ($LJD) to $JD because there is no range
		}
		elsif($year && $month){	#elsif there is only a year and month present
			if($month=12){		#if the month is december...
					$JD=julian_day($year, $month, 1);		#Set $JD to Dec 1
					$LJD=julian_day($year, $month, 31);	#Set $LJD to Dec 31
			}
			else{		#else (if it's not december)
					$JD=julian_day($year, $month, 1);	#Set $JD to the 1st of this month
					$LJD=julian_day($year, $month+1, 1);	#Set $LJD to the first of the next month...
						$LJD -= 1;						#...Then subtract one day (to get the last dat of this month)
			}
		}
		elsif($year){	#elsif there is only year
					$JD=julian_day($year, 1, 1);	#Set $JD to Jan 1 of that year
					$LJD=julian_day($year, 12, 31);	#Set $LJD to Dec 31 of that year 
		}
	}
	else{	#else (there is no $eventDate)
		$JD=$LJD=""; #Set $JD and $LJD to null
	}

	if ($LJD > $today_JD){	#If $LJD is later than today's JD (calculated at the top of the script)
		print ERROR <<EOP;
		$accession_id DATE nulled, $date ($LJD)  greater than today ($today_JD)\n
EOP

		$JD=$LJD="";	#...then null the date
	}
	elsif($year < 1800){	#elsif the year is earlier than 1800
		print ERROR <<EOP;
		$accession_id DATE nulled, $date ($year) less than 1800\n
EOP
		$JD=$LJD=""; #...then null the date
	}

###This is the old date-checking code, which as of 2014 is definitely out of date
#		if($year > 2012 || $year < 1800){
#			print ERROR "Date bounds problem: $year $date made null $err_line\n";
#			$date="";
#		}


	if(m|<Ecology>(.*)</Ecology>|){
		$ecology=$1;
		$ecology=~s/<!\[CDATA\[(.*)\]\]>/$1/;
		if($ecology=~s/(Assoc.*)//){
			$assoc=$1;
			foreach($assoc){
				s/Associated? [Ss]pecies://;
				s/Associated? sp+.?://;
				s/Associate[ds]?[:;]? //;
				s/Associations?[:;]? //;
				s/Assoc. [Ss]pp\.?: //;
				s/Assoc. [Ss]pecies: //;
				s/Assoc. [Ss]p\.?: //;
				s/Assoc[.,:]+ //;
				s/^ *//;
	if(length($assoc) > 255){
$overage=length($assoc)- 255;
#$assoc=substr($assoc, 0,252) . "...";
#warn "Too long by $overage: $assoc\n";
	}
			}
		}
	}
	else{
		$ecology=""
	}
	if ($ecology=~"[Oo]rnamental|[Cc]ultivated|[Gg]reenhouse"){
	print ERROR "Specimen from cultivation: $ecology $err_line\n";
	next;
	}
	
	if(m|<Habitat>(.*)</Habitat>|){
		$habitat=$1;
	}
	else{
		$habitat=""
	}
	if(m|<Collector>(.*)</Collector>|){
		$collector=$1;
		if ($collector=~/\d/){
		warn "$collector\n";
print ERROR "Collector problem: $collector $err_line\n";
$collector=~s/.*1996/G. F. Hrusa/;
$collector=~s/Carpenter 16/Carpenter/;
$collector=~s/J. R. Nelson'14/J. R. Nelson/;
$collector=~s/Janet Beckman 34/Janet Beckman/;
$collector=~s!7/16/1996!!;
		warn "$collector\n" if $collector=~/\d/;
		}
		$collector=~s/<!\[CDATA\[(.*)\]\]>/$1/;
		if(m|<MoreCollectors>(.*)</MoreCollectors>|){
			$other_coll=$1;
			$other_coll=~s/<!\[CDATA\[(.*)\]\]>/$1/i;
			$other_coll=~s/^ *and //;
			$other_coll=~s/^ *[Ww]ith //;
		}
		#$collector=~s/([A-Z]\.[A-Z]\.)([A-Z][a-z])/$1 $2/g;
		#$collector=~s/([A-Z]\.)([A-Z]\.)/$1 $2/g;
		#$other_coll=~s/([A-Z]\.[A-Z]\.)([A-Z][a-z])/$1 $2/g;
		#$other_coll=~s/([A-Z]\.)([A-Z]\.)/$1 $2/g;
		$comb_coll="$collector, $other_coll" if $other_coll;
	foreach($collector, $comb_coll){
		s/([A-Z]\.)/$1 /g;
		s/^ *//;
		s/ *$//;
		s/ +/ /g;
#processing chico collectors
#read all collectors into %smasch_coll
#alters misspellings, generates isql statements for needed collectors
#
s/  / /g;
s/: .*//;
s/ \./. /g;
s/, & /, /g;
s/ & /, /g;
s/&apos;/'/g;
s/^B\. Castro, L\. P\. Janeway, G\. Kuenster, S\. Innecker, J\. Lacey$/B. Castro, L. P. Janeway, G. Kuenster, S. Innecken, J. Lacey/;
s/^Samatha Mackey Hillaire, Katya Yarosevich, Joe Yarosevich$/Samantha Mackey Hillaire, Katya Yarosevich, Joe Yarosevich/;
s/^V\. H\. Oswald, Lowell Ahart and Robin Ondricek-Fallscheer$/V. H. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer/;
s/^C\. Macdonald, P\. Powers, C\. Raley, J\. Spitler, D\. Stamp$/C. Macdonald, P. Powers, C. Raley, J. Spitler, and D. Stamp/;
s/^Vernon H\. Oswald, B\. Corbin, K\. Earll, G\. Schoolscraft$/Vernon H. Oswald, B. Corbin, K. Earll, G. Schoolcraft/;
s/^V\. H\. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer\.$/V. H. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer/;
s/^V\. H\. Oswald, Lowell Ahart, Robin Ordricek-Fallscheer$/V. H. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer/;
s/^V\. H\. Oswald, Lowell Ahart, Robin Ondricek-Fallsheer$/V. H. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer/;
s/^B\. Castro, M\. A\. Griggs, Plumas NF [Bb]otanists\.$/B. Castro, M. A. Griggs, Plumas NF botanists/;
s/^B\. Castro, M\. A\. Griggs, Plumas NF [bB]otanists?$/B. Castro, M. A. Griggs, Plumas NF botanists/;
s/^Vernon H\. Oswald, Mike Wolder, Joe Silveira\.$/Vernon H. Oswald, Mike Wolder, Joe Silveira/;
s/^J\. D\. Jokerst, T\. B\. Devine, D\. Greenstein$/J. D. Jokerst, T. B. Devine, D. Greemstein/;
s/^Banchero, Fuller, Merryman, R\. A\. Schlising$/R. Banchero, J. Fuller, M. Merryman, R. Schlising/;
s/^Vernon H\. Oswald, Mike Wolder, Joe Silveria$/Vernon H. Oswald, Mike Wolder, Joe Silveira/;
s/^Robert A\. Schlising, N\. Lewsten, L\. Thurman$/Robert A. Schlising, N. Lersten, L. Thurman/;
s/^Robert A\. Schlising, N\. Lerston, L\. Thurman$/Robert A. Schlising, N. Lersten, L. Thurman/;
s/^H\. H\. Schmidt, M\. Merello & L\. Woodruff$/H. H. Schmidt, M. Merello, L. Woodruff/;
s/^D\. E\. Anderson, J\. O\. Sawyer, J\. P\. Smith$/D. E. Anderson, J. O. Sawyer, J. P. Smith, Jr./;
s/^Vernon H\. Oswald, Beth Corbin, Mike Dolan$/Vernon H. Oswald, Beth Corbin, Michael Dolan/;
s/^B\. Castro, Gail Kuentster, Loren Gehrung$/B. Castro, G. Kuenster, L. Gehrung/;
s/^J\. P\. Smith, J\. O\. Swayer, T\. W\. Nelson$/J. P. Smith, J. O. Sawyer, T. W. Nelson/;
s/^H\. H\. Sshmidt, James S\. Miller, A\. Pool$/H. H. Schmidt, James S. Miller, A. Pool/;
s/^Samatha Mackey Hillaire, Charles Hooks$/Samantha Mackey Hillaire, Charles Hooks/;
s/^Samatha Mackey Hillaire, Brian Elliott$/Samantha Mackey Hillaire, Brian Elliott/;
s/^K\. R\. Stern, D\. B\. Joley, J\. G\. Gescke$/K. R. Stern, D. B. Joley, J. G. Geschke/;
s/^Mike O&apos;Bryan, Robert A\. Schlising$/Mike O'Bryan, Robert A. Schlising/;
s/^B\. Castro, R\. Zebell and R\. Fallscheer$/B. Castro, R. Zebell, R. Fallscheer/;
s/^K R\. Stern, D\. B\. Joley, J\. G\. Geschke$/K. R. Stern, D. B. Joley, J. G. Geschke/;
s/^Coleta A\. Lawler, Robert A\. Schlising$/Coleta Lawler, Robert A. Schlising/;
s/^Niall F\. McCarten, Roxanne L\. Bittman$/Niall McCarten, Roxanne Bittman/;
s/^B\. Castro, Robin Ondricek-Fallscheer$/B. Castro, R. Fallscheer/;
s/^B\. Castro, L\. Gehrung & H\. Durio$/B. Castro, L. Gehrung, H. Durio/;
s/^B\. Castro, J\. Witzman, B\. Henrickson$/B. Castro, J. Witzman, B. Hendrickson/;
s/^B\. CAStro, R\. Zebell, R\. Fallscheer$/B. Castro, R. Zebell, R. Fallscheer/;
s/^B\. Castro, R\. Fallscherr, R\. Zebell$/B. Castro, R. Fallscheer, R. Zebell/;
s/^M\. S\. Taylor, J\. Prouty, E Heinitz\.$/M. S. Taylor, J. Prouty, E. Heinitz/;
s/^Timothy Spira, Robert A\. Schlising$/Timothy Spira, Robert Schlising/;
s/^Vernon H\. Oswald, Vernon H\. Oswald$/Vernon H. Oswald/;
s/^Robert A\. Schlising, Lloyd Thurman$/Robert A. Schlising, Lloy Thurman/;
s/^B\. Castro, L\. Janeway, S\. Innecken$/B. Castro, L. P. Janeway, S. Innecken/;
s/^J\. P\. Smith, J\. O\. Sawyer, J\. cole$/J. P. Smith, J. O. Sawyer, J. Cole/;
s/^M\. S\. Taylor, W\. Dakon, T\. Griggs\.$/M. S. Taylor, W. Dakon, T. Griggs/;
s/^Vernon H\. Oswald, Joseph Silveira\.$/Vernon H. Oswald, Joseph Silveira/;
s/^C\. A\. Lawler, Robert A\. Schlising$/C. A. Lawler, R. A. Schlising/;
s/^J\. Lacey, R\. Ondricek-Fallscheer\.$/J. Lacey, R. Ondricek-Fallscheer/;
s/^Barbara Ertter, James R\. Shevock$/Barbara Ertter, J. R. Shevock/;
s/^Robert F\. Thorne, C\. W\. Tolforth$/Robert F. Thorne, C. W. Tilforth/;
s/^J\. Lacey, R\. Oncricek-Fallscheer$/J. Lacey, R. Ondricek-Fallscheer/;
s/^Rober F\. Thorne, C\. W\. Tilforth$/Robert F. Thorne, C. W. Tilforth/;
s/^Coleta Lawler, Robert Schlising$/Coleta Lawler, Robert A. Schlising/;
s/^Vernon H\. Oswald, Lowelll Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^V\. Oswald, W\. Dempsey, D Perske$/V. Oswald, W. Dempsey, D. Perske/;
s/^Timothy Spora, Robert Schlising$/Timothy Spira, Robert Schlising/;
s/^Vernon H\. Oswald, Lowell Ahart\.$/Vernon H. Oswald, Lowell Ahart/;
s/^Vernin H\. Oswald, Lowell Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^R\. A\. Schlising, Lloyd Thurman$/R. A. Schlising, Lloy Thurman/;
s/^Dieter H\. Wilken, Gary Wallace$/Dieter H. Wilken, Gary D. Wallace/;
s/^Tim Spira, Robert A\. Schlising$/Timothy Spira, Robert Schlising/;
s/^Vernn H\. Oswald, Lowell Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^Venon H\. Oswald, Lowell Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^Mike Foster, Pauleen Broyles\.$/Mike Foster, Pauleen Broyles/;
s/^Vernon H\. Oswald, Wes Dempsey$/Vernon H. Oswald, W. Dempsey/;
s/^G\. Dougla Barbe, T\. C\. Fuller$/G. Douglas Barbe, T. C. Fuller/;
s/^Vernon H\. Oswald, Jim Snowden$/Vernon H. Oswald, James Snowden/;
s/^Vernon H\. Owald, Lowell Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^G\. Douglas Barbe, Ed\. W\. Hale$/G. Douglas Barbe, Ed W. Hale/;
s/^Vernon Oswald, Lowelll Ahart$/Vernon Oswald, Lowell Ahart/;
s/^D\. E\. Brink Jr\., L\. M\. Mayer$/D. E. Brink, Jr., L. M. Mayer/;
s/^Vernon Oswald\., Lowell Ahart$/Vernon Oswald, Lowell Ahart/;
s/^L\. Constance, J\. L\. Morrison$/L. Constance and J. L. Morrison/;
s/^F\. J\. Fuler, R\. A\. Schlising$/F. J. Fuller, R. A. Schlising/;
s/^C\. A\. Janeway, J\. P\. Janeway$/C. A. Janeway, L. P. Janeway/;
s/^M\. R\. Crosby, Nancy R\. Morin$/M. R. Crosby and Nancy Morin/;
s/^Ira W\. Clokey, B\. Templeton$/Ira W. Clokey and B. Templeton/;
s/^Frederic Hrusa, L\. Serafini$/G. F. Hrusa, L. Serafini/;
s/^Vernon oswald, Lowell Ahart$/Vernon Oswald, Lowell Ahart/;
s/^L\. P\. janeway, Jean Witzman$/L. P. Janeway, Jean Witzman/;
s/^B\. Castro, Robin Fallscheer$/B. Castro, R. Fallscheer/;
s/^C\. A\. Janewy, L\. P\. Janeway$/C. A. Janeway, L. P. Janeway/;
s/^L\. P\. Janway, C\. A\. Janeway$/L. P. Janeway, C. A. Janeway/;
s/^B\. Castro, Shirley Innecken$/B. Castro, S. Innecken/;
s/^M\. R\. Crosby, Nancy Morin$/M. R. Crosby and Nancy Morin/;
s/^Vernn Oswald, Lowell Ahart$/Vernon Oswald, Lowell Ahart/;
s/^Tim Spira, Rober Schlising$/Timothy Spira, Robert Schlising/;
s/^G\. F\. Hursa, T\. D\. Wilfred$/G. F. Hrusa, T. D. Wilfred/;
s/^C\. A\. Lawler, R\. Schlising$/C. A. Lawler, R. A. Schlising/;
s/^M\. S> Taylor, J\. Lacey$/M. S. Taylor, J. Lacey/;
s/^L\. Constance, H\. L\. Mason$/L. Constance and H. L. Mason/;
s/^C\. A\. Janeway, L\. Janeway$/C. A. Janeway, L. P. Janeway/;
s/^M\. R\. Crosby, Mancy Morin$/M. R. Crosby and Nancy Morin/;
s/^H\. H Schmidt, L\. Woodruff$/H. H. Schmidt, L. Woodruff/;
s/^Susie Urie, Eric Schroder$/Susi Urie, Eric Schroder/;
s/^Reid Moran, Chas\. Quibell$/Reid Moran and Chas. Quibell/;
s/^R\. L\. Ondricek-Fallsheer$/R. L. Ondricek-Fallscheer/;
s/^L\. J\. Janeway, B\. Castro$/L. P. Janeway, B. Castro/;
s/^Jeffreyi Thomas Gautschi$/Jeffrey Thomas Gautschi/;
s/^B\. Castro, Gail Kuenster$/B. Castro, G. Kuenster/;
s/^B\. Castro, J\. D\. Jokerst$/B. Castro and J. D. Jokerst/;
s/^M\. Pranther, N\. Pranther$/M. Prather, N. Prather/;
s/^C\. Epling, W\. M\. Robison$/C. Epling, Wm. Robison/;
s/^B\. Castro, R\. Fallsheer$/B. Castro, R. Fallscheer/;
s/^Vernon Oswald, L\. Ahart$/Vernon Oswald, Lowell Ahart/;
s/^B\. Castro, B\. Henderson$/B. Castro, B. Hendrickson/;
s/^Samatha Mackey Hillaire$/Samantha Mackey Hillaire/;
s/^M\. S Taylor, W\. Overton$/M. S. Taylor, W. Overton/;
s/^Gary Wallace, L\. Debuhr$/Gary Wallace, L. DeBuhr/;
s/^C\. Janeway, L\. Janeway$/C. A. Janeway, L. P. Janeway/;
s/^Phillip A\. Silverstone$/Philip A. Silverstone/;
s/^B\. Castro, J\. Jurewiez$/B. Castro, J. Jurewicz/;
s/^James Payne Smith, JR\.$/James Payne Smith, Jr./;
s/^B\. Castro, L\. Janeway$/B. Castro, L. P. Janeway/;
s/^D\. E\. Brink, L\. Mayer$/D. E. Brink, Jr., L. M. Mayer/;
s/^f\. t\. Griggs, A\. Pass$/F. T. Griggs, A. Pass/;
s/^F\. T\. Briggs, A\. Pass$/F. T. Griggs, A. Pass/;
s/^M\. S Taylor, M\. Hayes$/M. S. Taylor, M. Hayes/;
s/^Edward Laidlaw Smith$/Edward L. Smith/;
s/^James Payne Smith, Jr$/James Payne Smith, Jr./;
s/^Ted\. H\. Thorsted, Jr\.$/Ted H. Thorsted, Jr./;
s/^James Payne Smith Jr\.$/James Payne Smith, Jr./;
s/^M\. &. N\. Pranther$/M. Prather, N. Prather/;
s/^Robert A\. Schlisingc$/Robert A. Schlising/;
s/^Roberst A\. Schlising$/Robert A. Schlising/;
s/^B\. Castro, L\. Hanson$/B. Castro, Linnea Hanson/;
s/^F\. T\. Giggs, A\. Pass$/F. T. Griggs, A. Pass/;
s/^Thomas E\. Lewis\. Jr\.$/Thomas E. Lewis, Jr./;
s/^B\. Castro, R\. Zabell$/B. Castro, R. Zebell/;
s/^N\. Morin, J\. Griffin$/N. Morin and J. Griffin/;
s/^Lichael P\. Crivello$/Michael P. Crivello/;
s/^Sonia A\. Westerberg$/Sonia R. Westerberg/;
s/^Thomas E\. Lewis Jr\.$/Thomas E. Lewis, Jr./;
s/^L\. Oliver, D\. Slaon$/L. Oliver, D. Sloan/;
s/^Sona R\. Westerberg$/Sonia R. Westerberg/;
s/^Robin L\. Ondericek$/Robin L. Ondricek/;
s/^Robert A\. Schising$/Robert A. Schlising/;
s/^Robert A Schlising$/Robert A. Schlising/;
s/^Robert A\. Schlisng$/Robert A. Schlising/;
s/^Carol G\. Getzinger$/Carol C. Getzinger/;
s/^R\. A> Schlising$/R. A. Schlising/;
s/^Aurthur C\. Barrett$/Arthur C. Barrett/;
s/^Arthur C\. Barrett\.$/Arthur C. Barrett/;
s/^Arthur O\. Barrett$/Arthur C. Barrett/;
s/^Fobin L\. Ondricek$/Robin L. Ondricek/;
s/^W\. Micheal Foster$/W. Michael Foster/;
s/^James D\. Jokerst\.$/James D. Jokerst/;
s/^James D Jokerst$/James D. Jokerst/;
s/^Robert\. F\. Thorne$/Robert F. Thorne/;
s/^Gary J\. Stebbings$/Gary J. Stebbins/;
s/^Virginiga Hagaman$/Virginia Hagaman/;
s/^Mike Carpenter$/Mike Carpenter/;
s/^Dierter H\. Wilken$/Dieter H. Wilken/;
s/^G\. C\. Strausbaugh$/G. Ctrausbaugh/;
s/^James R\. Brownell$/James Brownell/;
s/^Mike O&apos;Bryan$/Mike O'Bryan/;
s/^Dibble and Griggs$/Dibble, Griggs/;
s/^David m\. Thompson$/David M. Thompson/;
s/^M\. A> Callahan$/M. A. Callahan/;
s/^Arthur G\. Barrett$/Arthur C. Barrett/;
s/^Suesie Boergadine$/Sue Boergadine/;
s/^Marria Ulloa-Cruz$/Maria Ulloa-Cruz/;
s/^Michaelle Snipes$/Michelle Snipes/;
s/^Beverly J\. Wise$/Beverley J. Wise/;
s/^Maria Ulloa-Crus$/Maria Ulloa-Cruz/;
s/^Arthur C\. Barret$/Arthur C. Barrett/;
s/^Coleta A\. Lawler$/Coleta Lawler/;
s/^Mary Mac Arthur$/Mary MacArthur/;
s/^Virignia Hagaman$/Virginia Hagaman/;
s/^Gary J\. Sebbings$/Gary J. Stebbins/;
s/^Charles Crannell$/Charlie Crannell/;
s/^Sandra C\. Morey\.$/Sandra C. Morey/;
s/^P\. Delaplane, eb$/P. Delaplane/;
s/^Jomes D\. Jokerst$/James D. Jokerst/;
s/^Vernin H\. Oswald$/Vernon H. Oswald/;
s/^Kath Sommarstrom$/Kathy Sommarstrom/;
s/^Rober F\. Thorne$/Robert F. Thorne/;
s/^Sadie Gaultieri$/Sadie Gualtieri/;
s/^Vernon H Oswald$/Vernon H. Oswald/;
s/^Robin Ondricek$/Robin L. Ondricek/;
s/^G\. Dougla Barbe$/G. Douglas Barbe/;
s/^Roberta A\. Boen$/Roberta A. Boer/;
s/^Pamela Cladwell$/Pamela Caldwell/;
s/^James\. P\. Smith$/James P. Smith/;
s/^Carol Getzinger$/Carol C. Getzinger/;
s/^Vernon H\. Owald$/Vernon H. Oswald/;
s/^Thomas E\. Lewis$/Thomas E. Lewis, Jr./;
s/^D\. E\. Brink Jr\.$/D. E. Brink, Jr./;
s/^Donald M\. Burke$/Donald M. Burk/;
s/^Venon H\. Oswald$/Vernon H. Oswald/;
s/^Veron H\. Oswald$/Vernon H. Oswald/;
s/^Margie Ceollins$/Margie Collins/;
s/^Thomes Chastain$/Thomas Chastain/;
s/^M\. S> Taylor$/M. S. Taylor/;
s/^Jerry Sullivan\.$/Jerry Sullivan/;
s/^H\. E\. MacLennan$/H. E. Mac Lennan/;
s/^Donna Kingsford$/Dona Kingsford/;
s/^G\. Schoolcraft\.$/G. Schoolcraft/;
s/^Paulenn Broyles$/Pauleen Broyles/;
s/^Dibble, Griggs\.$/Dibble, Griggs/;
s/^J\. P\. Kroessing$/J. P. Kroessig/;
s/^Heffrey R\. Peek$/Jeffrey R. Peek/;
s/^Mary Mae Arthur$/Mary MacArthur/;
s/^Lynn R\. Thomas$/Lynn R Thomas/;
s/^Jame D\. Jokerst$/James D. Jokerst/;
s/^David Cherrtham$/David Cheetham/;
s/^Vernn H\. Oswald$/Vernon H. Oswald/;
s/^R\. A\. Schisling$/R. A. Schlisling/;
s/^Theresa Coasta$/Theresa Costa/;
s/^J\. D\. Jokerst`$/J. D. Jokerst/;
s/^Pauleen Broyes$/Pauleen Broyles/;
s/^Puleen Broyles$/Pauleen Broyles/;
s/^Sue Boerqadine$/Sue Boergadine/;
s/^Vernon Oswald\.$/Vernon Oswald/;
s/^Edward L Smith$/Edward L. Smith/;
s/^Frederic Hrusa$/G. F. Hrusa/;
s/^James t\. Nicol$/James T. Nicol/;
s/^J\. D\. Jokerst\.$/J. D. Jokerst/;
s/^Cona Kingsford$/Dona Kingsford/;
s/^H\. Durio, s\.n\.$/H. Durio/;
s/^Jeffrey M Lund$/Jeffrey M. Lund/;
s/^Jerry Sndgrass$/Jerry Snodgrass/;
s/^Sue Boergadino$/Sue Boergadine/;
s/^Vernon Oswalf$/Vernon Oswald/;
s/^Timothy Spora$/Timothy Spira/;
s/^Don Kroessing$/Don Kroessig/;
s/^Robert Jaegal$/Robert Jaegel/;
s/^Eric J\. Miler$/Eric J. Miller/;
s/^Shuan E\. Sims$/Shaun E. Sims/;
s/^M\. A Callahan$/M. A. Callahan/;
s/^S\. Westenberg$/S. Westerberg/;
s/^George Deriso$/George Deniso/;
s/^G\. Stausbaugh$/G. Strausbaugh/;
s/^l\. P\. Janeway$/L. P. Janeway/;
s/^John La Salle$/John LaSalle/;
s/^Edna Caufield$/Edna Canfield/;
s/^Terrance Finn$/Terrence Finn/;
s/^Jomes Jokerst$/James Jokerst/;
s/^Eric Hartwell$/Eric G. Hartwell/;
s/^G\. Straubaugh$/G. Strausbaugh/;
s/^Nancy Mosman\.$/Nancy Mosman/;
s/^A\. W\. Harilik$/A. W. Harvilik/;
s/^Jones Jokerst$/James Jokerst/;
s/^Vernon oswald$/Vernon Oswald/;
s/^Jenifer Estep$/Jennifer Estep/;
s/^Ahart-Jokerst$/Ahart, Jokerst/;
s/^Steven Triana$/Steven Triano/;
s/^Fredric Hrusa$/G. F. Hrusa/;
s/^Ted Edminston$/Ted Edmiston/;
s/^M\. S\. Taylor\.$/M. S. Taylor/;
s/^R\. Cliquennoi$/R. Clicquennoi/;
s/^M\. MacAurther$/M. MacArthur/;
s/^H\. H\. Sshmidt$/H. H. Schmidt/;
s/^R\. Pierce Jr\.$/R. Pierce, Jr./;
s/^Shelly A Kirn$/Shelly A. Kirn/;
s/^L\. J\. Janeway$/L. P. Janeway/;
s/^J\. R\. Neslon$/J. R. Nelson/;
s/^C\. A\. Janewy$/C. A. Janeway/;
s/^W\. Fitswater$/W. Fitzwater/;
s/^Roger Jaegal$/Roger Jaegel/;
s/^Julie Jenson$/Julie Jensen/;
s/^L\. P\. Janewy$/L. P. Janeway/;
s/^H\. H Schmidt$/H. H. Schmidt/;
s/^C\. E\. Leaver$/C. E. Laver/;
s/^C\. F\. Sonnee$/C. F. Sonne/;
s/^D\. G\. Miller$/D. G. Miller III/;
s/^Vernn Oswald$/Vernon Oswald/;
s/^M\. MacSrthur$/M. MacArthur/;
s/^W\. Follettee$/W. Follette/;
s/^Paula Minton$/Paula J. Minton/;
s/^Darci Fields$/Darci Field/;
s/^Sam Poolswat$/Sam Poolsawat/;
s/^Jannae Pitts$/Jeanne Pitts/;
s/^F\. T\. Briggs$/F. T. Griggs/;
s/^f\. t\. Griggs$/F. T. Griggs/;
s/^Rober Jaegel$/Robert Jaegel/;
s/^A\. K\. Reverd$/A. K. Revard/;
s/^L\. P\. Janway$/L. P. Janeway/;
s/^Terence Finn$/Terrence Finn/;
s/^Michaul Ward$/Michael Ward/;
s/^Phil Bulmert$/Phil Blumert/;
s/^C\. E\. Iaver$/C. E. Laver/;
s/^K, R\. Stern$/K. R. Stern/;
s/^G\. F\. Hursa$/G. F. Hrusa/;
s/^P\. Delplane$/P. Delaplane/;
s/^E\. Parreno$/E. P. Parreno/;
s/^Susie Urie$/Susi Urie/;
s/^Susie Uri$/Susi Urie/;
s/^Susi Uri$/Susi Urie/;
s/^F\. J\. Fuler$/F. J. Fuller/;
s/^M\. S Taylor$/M. S. Taylor/;
s/^D\. E\. Brink$/D. E. Brink, Jr./;
s/^C\. Janeway$/C. A. Janeway/;
s/^Agnus Riker$/Agnes Riker/;
s/^Sori H Shad$/Sori H. Shad/;
s/^F\. T\. Giggs$/F. T. Griggs/;
s/^Gail Bufton$/Gail A. Bufton/;
s/^G\. Nielson$/G. Nielsen/;
s/^Bryon Case$/Bryan Case/;
s/^K\. Heneger$/K. Henegar/;
s/^K R\. Stern$/K. R. Stern/;
s/^NEH Prouty$/N. E. H. Prouty/;
s/^D\. Crummet$/D. Crummett/;
s/^Cark Pejsa$/Carl Pejsa/;
s/^A\. Revard$/A. K. Revard/;
s/^M\. Hiller$/M. Hillier/;
s/^NE Heiken$/N. E. Heiken/;
s/^m\. Robbie$/M. Robbie/;
s/^B\. CAStro$/B. Castro/;
s/^R\. Jaegal$/R. Jaegel/;
s/^B\. Castrp$/B. Castro/;
s/^E Parreno$/E. Parreno/;
s/^Kenn Cole$/Ken Cole/;
s/^N\. Jaekal$/N. Jaekel/;
s/^Linda Osborn$/Linda Osborne/;
s/^Ben Mhre$/Ben Myhre/;
s/^Kenn Cole$/Ken Cole/;
s/^H\. Durio, s\.n\.$/H. Durio/;
s/^Wayne \) Baum$/Wayne Baum/;
s/^Waynes O\. Baum$/Wayne O. Baum/;
s/^Z\. Parkenvich$/Z. Parkevich/;
s/^Z\. Barkevich$/Z. Parkevich/;
s/^V\. holt$/V. Holt/;
s/Wesley O\. Griesal$/Wesley O. Griesel/;
s/^V\. H\. Oswald, B\. Corbin, A Sanger, G\. Schoolcraft$/V. H. Oswald, B. Corbin, A. Sanger, G. Schoolcraft/;
s/^Heidi West, Jenny Marr, Caroline Warren, Joyce Lacey-Rickert,$/Heidi West, Jenny Marr, Caroline Warren, Joyce Lacey-Rickert/;
s/^L\. P\. Janeway, Eric Schroder, Katherine Murrell, Todd Adams\.$/L. P. Janeway, Eric Schroder, Katherine Murrell, Todd Adams/;
s/^L\. P\. Janeway, R\. A\. Schlising, B\. Castro, Pauleen Broyles\.$/L. P. Janeway, R. A. Schlising, B. Castro, Pauleen Broyles/;
s/^Caroline Warren, Jenny Marr, Julie Cunningham, Heidi Westq$/Caroline Warren, Jenny Marr, Julie Cunningham, Heidi West/;
s/^Heidi West, Jenny Marr, C\. Warren,J\. Cunningham, N\. Wight$/Heidi West, Jenny Marr, C. Warren, J. Cunningham, N. Wight/;
s/^Lowell Ahart, Barbara Castro, Dan Barth, Diane Mastalir\.$/Lowell Ahart, Barbara Castro, Dan Barth, Diane Mastalir/;
s/^Lowell Ahart, Barbare Castro, Dan Barth, Diane Mastalir$/Lowell Ahart, Barbara Castro, Dan Barth, Diane Mastalir/;
s/^L\. P\. Janeway, B\. Castro, Linnea Hanson, Hal Durio\.$/L. P. Janeway, B. Castro, Linnea Hanson, Hal Durio/;
s/^Robert A\. Schlising, Anna Eagel, Dick Rosenzweig$/Robert A. Schlising, Anna Eagle, Dick Rosenzweig/;
s/^D\. Boud, M\. Eichelberger, T\. Messick, T\. Ranker$/D. Boyd, M. Eichelberger, T. Messick, T. Ranker/;
s/^Julie Cunningham, Heidi West, Caroline Warren\.$/Julie Cunningham, Heidi West, Caroline Warren/;
s/^Robert A\. Schlising, Ben Lilies, Gina Purelis$/Robert A. Schlising, Ben Liles, Gina Purelis/;
s/^L\. P\. Janeway, Lela Burdett, Bernard Burdett\.$/L. P. Janeway, Lela Burdett, Bernard Burdett/;
s/^J\. D\. Jokerst, R\. A\., Schlising, B\. Banchero$/J. D. Jokerst, R. A. Schlising, B. Banchero/;
s/^L\. P\. Janeway, Linnea Hanson, Perrie Cobb\.$/L. P. Janeway, Linnea Hanson, Perrie Cobb/;
s/^Heidi West, Caroline Warren, Jenny Marr`$/Heidi West, Caroline Warren, Jenny Marr/;
s/^M\. S\. Taylor, M\. Hayes, R\. Schlising\.$/M. S. Taylor, M. Hayes, R. Schlising/;
s/^Lowel Ahart, Vernon H\. Oswald$/Lowell Ahart, Vernon H. Oswald/;
s/^L\. M\. Mayer, D\. E\. Brink Jr\.$/L. M. Mayer, D. E. Brink, Jr./;
s/^J\. D\. Jokerst, R\. A\.$/J. D. Jokerst, R. A. Schlising/;
s/^Roberta G\. Roberston$/Roberta G. Robertson/;
s/^Herb Allan Mc Lane$/Herb Allan McLane/;
s/^James Hendrickson$/James Henrickson/;
s/^Herb Allen McLane$/Herb Allan McLane/;
s/^Robert F\. thorne$/Robert F. Thorne/;
s/^Herber G\. Baker$/Herbert G. Baker/;
s/^J\. D> Prouty$/J. D. Prouty/;
s/^G\. Ctrausbaugh$/G. Strausbaugh/;
s/^M\.\. S\. Taylor$/M. S. Taylor/;
s/^Lynn R Thomas$/Lynn R. Thomas/;
s/^Lowell Ahart\.$/Lowell Ahart/;
s/^K\. B\. McShea\.$/K. B. McShea/;
s/^Steve Alverez$/Steve Alvarez/;
s/^Marsha Caount$/Marsha Count/;
s/^L\. P\. janeway$/L. P. Janeway/;
s/^Pauline kunst$/Pauline Kunst/;
s/^Lowell Ahart`$/Lowell Ahart/;
s/^Lowelll Ahart$/Lowell Ahart/;
s/^T\. N\. Cassale$/T. N. Casale/;
s/^Marsha Caunt$/Marsha Count/;
s/^Loweel Ahart$/Lowell Ahart/;
s/^V\. S\. Jacson$/V. S. Jackson/;
s/^Lowel Ahart$/Lowell Ahart/;
s/^K\. Mckenzie$/K. McKenzie/;
s/^M S\. Taylor$/M. S. Taylor/;
s/^K\. Bandegee$/K. Brandegee/;
s/^N\. Jeakel$/N. Jaekel/;
s/^K\. Jaekal$/K. Jaekel/;
s/^M\. yoder$/M. Yoder/;
s/^D\. Boud$/D. Boyd/;
		s/\([^)]+\)//g;
		s/([A-Z]), ([A-Z][a-z])/$1. $2/g;
		#s/([A-Z])\. ([A-Z]) /$1. $2./g;
		s/ ,/,/g;
		s/,,/,/g;

	}
$seen_coll{$collector}++;
$seen_coll{$comb_coll}++ if $other_coll;
	if(m|<CollectionNumber>(.*)</CollectionNumber>|){
		$collnum=$1;
		$collnum=~s/<!\[CDATA\[ *(.*)\]\]>/$1/;
		if(m|<Prefix>(.*)</Prefix>|){
			$coll_num_prefix=$1;
warn "Explicit prefix problem\n";
		}
		if(m|<Suffix>(.*)</Suffix>|){
			$coll_num_suffix=$1;
warn "Explicit suffix problem\n";
		}
unless ($collnum=~/^\d+$/){
#print "$collnum\n";
 if($collnum=~s/^([0-9]+)-([0-9]+)([A-Za-z]*)/$2/){
                $CNUM_PREFIX="$1-";
                $CNUM_SUFFIX=$3;
        }
 if($collnum=~s/^([A-Z]*[0-9]+)-([0-9]+)([A-Za-z]+)/$2/){
                $CNUM_PREFIX="$1-";
                $CNUM_SUFFIX=$3;
        }
        if($collnum=~s/^([A-Z]*[0-9]+-)([0-9]+)(-.*)/$2/){
                $CNUM_PREFIX=$1;
                $CNUM_SUFFIX=$3;
        }
        if($collnum=~s/^([^0-9]+)//){
                $CNUM_PREFIX=$1;
        }
        if($collnum=~s/^(\d+)([^\d].*)/$1/){
                $CNUM_SUFFIX=$2;
        }

                #print <<EOP;
#C: $collnum
#P: $CNUM_PREFIX
#S: $CNUM_SUFFIX
#
#EOP
	}
}
}
if(m|<LongitudeDegree>(.+)</LongitudeDegree>|){
	$long=$1;
	$long=~s/^ //;
	if(m|<LongitudeMinutes>(.+)</LongitudeMinutes>|){
		$minutes=$1;
		$minutes="0$minutes" if $minutes=~/^.$/;
		$long.=" $minutes";
		if(m|<LongitudeSeconds>(.+)</LongitudeSeconds>|){
			$long.=" $1";
		}
	}
	elsif(m|<LongitudeSeconds>(.+)</LongitudeSeconds>|){
		$long.=" 00 $1";
		}
($LongitudeDirection)=m|<LongitudeDirection>(.*)</LongitudeDirection>|;
if($LongitudeDirection eq "N"){
$LongitudeDirection="W";
print ERROR "Longitude problem: $err_line\n";
}
$LongitudeDirection="W" unless $LongitudeDirection;
$long .= $LongitudeDirection;
$long=~s/  */ /g;
}
else{
$long="";
}
if(m|<LatitudeDegree>(.+)</LatitudeDegree>|){
	$lat=$1;
	$lat=~s/^ //;
	if(m|<LatitudeMinutes>(.+)</LatitudeMinutes>|){
		$minutes=$1;
		$minutes="0$minutes" if $minutes=~/^.$/;
		$lat.=" $minutes";
		if(m|<LatitudeSeconds>(.+)</LatitudeSeconds>|){
			$lat.=" $1";
		}
	}
	elsif(m|<LatitudeSeconds>(.+)</LatitudeSeconds>|){
		$lat.=" 00 $1";
		}
($LatitudeDirection)=m|<LatitudeDirection>(.*)</LatitudeDirection>|;
$LatitudeDirection="N" unless $Latitude_Direction;
$lat .= $LatitudeDirection;
$lat=~s/  */ /g;
}
else{
$lat="";
}


if(m|<LatitudeDecimal>([\d.]+)</LatitudeDecimal>|){
$decimal_lat=$1;
}
else{
$decimal_lat="";
}
if(m|<LongitudeDecimal>(-[\d.]+)</LongitudeDecimal>|){
$decimal_long=$1;
}
else{
$decimal_long="";
}
if(m!<LatLongPrecision>(.+)</LatLongPrecision>!){
$extent=$1;
}
else{
$extent="";
}
if(m!<LatLongPrecisionUnits>(.+)</LatLongPrecisionUnits>!){
$ExtUnits = lc($1);
}
else{
$ExtUnits = "";
}
if(m!<Notes>(.+)</Notes>!){
	$notes=$1;
}
else{
$notes="";
}
if(m!<USGSQuadrangle>(.+)</USGSQuadrangle>!){
	$quad="USGS quad $1";
	if(m!<USGSQuadrangleScale>(.+)</USGSQuadrangleScale>!){
		$quad.= " $1";
	}
}
else{
$quad="";
}
if(m!<LatLongDatum>(.+)</LatLongDatum>!){
$datum=$1;
foreach($datum){
s/NAD 1927/NAD27/;
s/NAD 1983/NAD83/;
s/WGS 1984/WGS84/;
s/\'//
}
}
else{
$datum="";
}

###COORD SOURCE
if(m!<LatLongAddedCheck>(.+)</LatLongAddedCheck!){
$LatLongAdded=$1;
	if($LatLongAdded=m/yes/){
		$coordSource="Coordinates added by herbarium";
	}
	elsif($LatLongAdded=m/no/){
		if($lat || $long || $decimal_lat || $decimal_long){
			$coordSource="Coordinates from specimen label";
		}
		else{
			$coordSource="";
		}
	}
	else{
		$coordSource="";
	}

}

		if( m!<TownshipAndRange>([^<]+)</TownshipAndRange>!){
#if(m|<TownshipAndRange>T.*(\d+).*(N).*R.*(\d+).*(E).*Sect.*(\d+)</TownshipAndRange>|){
$Unified_TRS="$1";
}
else{
$Unified_TRS="";
}
if(m/<GeoTertiaryDivision>(.+)</){
$county=$1;
$county=~s/ *County//i;
	}
else{
$county="Unknown";
}

#the rest of this required code should be made into a separate subroutine that uses &verify_co

		unless ($county=~m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
			$v_county= &verify_co($county);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
			if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
				&log_skip("$id NON-CA COUNTY? $county");	#run the &skip function, printing the following message to the error log
				++$skipped{one};
				next;
			}

			unless($v_county eq $county){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
				&log_change("$id COUNTY $county -> $v_county");		#call the &log function to print this log message into the change log...
				$county=$v_county;	#and then set $county to whatever the verified $v_county is.
			}
		}




if($ecology=~s/[.,;] *([Ff]lowers [^.]+)\././){
$color=$1;
}
else{
$color="";
}









	if(length($locality) > 555){
		foreach($locality){
			s/[Aa]bout /ca. /g;
			s/Highway/Hwy/g;
			s/River/R./g;
			s/[eE]ast-north-?east/NE/g;
			s/[Nn]orth-?west/NW/g;
			s/north-?east/NE/g;
			s/south-?east/SE/g;
			s/south-?west/SW/g;
			s/\b[Ss]outh\b/S/g;
			s/\b[Nn]orth\b/N/g;
			s/ &amp; / & /g;
			s/National Forest/N.F./g;
			s/National Wildlife/N.W./g;
			s/\bRoad\b/Rd/g;
			s/ miles / mi /g;
			s/ mile / mi /g;
			s/\byards\b/yd/g;
			s/ west / W /g;
			s/ east / E /g;
			s/Campground/Cpgd/g;
			s/\bvery\b//g;
			s/DUE TO CONCERNS.*/MORE INFORMATION IS AVAILABLE ON THE SPECIMEN LABEL/;
			s/Western Transverse Range/WTR/;
			s/Thomas Creek Ecol/Thomes Creek Ecol/;
		s/  */ /g;
		s/\.\././g;
		s/ the / /;
		s/ a / /g;
		s/Northern High Sierra Nevada Range/n SNH/;
		s/High Sierra Nevada Range/SNH/;
		s/Sierra Nevada Range/SN/;
		}
	if(length($locality) > 255){
$overage=length($locality)- 255;
#$locality=substr($locality, 0,252) . "...";
#warn "Too long by $overage: $locality\n";
	}
	}
	
print OUT <<EOP;
Date: $date
EJD: $JD
LJD: $LJD
CNUM: $collnum
CNUM_prefix: $CNUM_PREFIX
CNUM_suffix: $CNUM_SUFFIX
Name: $name
Accession_id: $accession_id
Country: USA
State: California
County: $county
Location: $locality
T/R/Section: $Unified_TRS
Elevation: $elevation
Collector: $collector
Other_coll: $other_coll
Combined_collector: $comb_coll
Habitat: $ecology
Associated_species: $assoc
Color: $color
Latitude: $lat
Longitude: $long
Max_error_distance: $extent
Max_error_units: $ExtUnits
Lat_long_ref_source: $coordSource
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Datum: $datum
Hybrid_annotation: $hybrid_annotation
Annotation: $annotation
Notes: $notes
USGS_Quadrangle: $quad

EOP
}

############SOME OLD CODE from when we processed collectors
#foreach(sort(keys(%seen_coll))){
#if($coll_comm{$_}){
	##warn "$_ seen\n";
#}
#else{
	##print "$_\n";
#print <<EOP;
#print "$_\n";
#insert into committee (chair_id, committee_func, committee_abbr, comments, data_src_id) values(0,"coll","$_","Chico bload",6)
#go
#EOP
#}
#}

sub skip {	#for each skipped item...
	print ERR "skipping: @_\n"	#print into the ERR file "skipping: "+[item from skip array]+new line
}
sub log {	#for each logged change...
	print ERR "logging: @_\n";	#print into the ERR file "logging: "+[item from log array]+new line
}



__END__
<CHSC_for_CalHerbConsort>
<Accession>
<Division>
<CFamily>
<CGenus>
<CSpecificEpithet>
<Collector>
<Date>
<DatePrecision>
<GeoTertiaryDivision>
<Elevation>
<ElevationUnits>
<Locality>
<LatLongAddedCheck>
<Notes>
<AnnoYesNo>
</CHSC_for_CalHerbConsort>
<CRank>
<CInfraspecificName>
<CDeterminedBy>
<LatitudeDegree>
<LatitudeMinutes>
<LatitudeSeconds>
<LatitudeDirection>
<LongitudeDegree>
<LongitudeMinutes>
<LongitudeSeconds>
<LongitudeDirection>
<LatLongPrecision>
<LatLongPrecisionUnits>
<DeterminedDate>
<Ecology>
<MoreCollectors>
</Collector>
<CollectionNumber>
<TownshipAndRange>
<USGSQuadrangle>
<USGSQuadrangleScale>
</GeoTertiaryDivision>
</Notes>
</MoreCollectors>
</Ecology>
</dataroot>
