
use Geo::Coordinates::UTM;
use strict;
#use warnings;
use lib '/Users/davidbaxter/DATA';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.

$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;

open(OUT,">CATA_out.txt") || die;

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;


my $file = 'CATA_OCT2015_mod.tab';

#####process the file
#CATA file arrives as a comma-separated csv with double-quotes as text qualifiers
#convert to tab delimited text file using csv2tab.pl
#Then open in TextWrangler and make sure to save as UTF-8 with Unix line breaks
###############


open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	
	$line_store=$_;
	++$count;



#fix some data quality and formatting problems that make import of fields of certain records impossible
s/\xc3\x80\xc3\x9c/au/g;   #ÀÜ ---> BÀÜrner	
s/\xc2\xbb/e/g;   #» ---> N»e	L'H»r.	
s/\xc3\x80/e/g;   #À ---> CambessÀdes	LagrÀze-Fossat	
s/\xe2\x80\x9a\xc3\xa0\xc3\xbb/ deg. /g;   #‚àû ---> (315‚àû)	210‚àû	12‚àû,	60‚àû,	
s/\xe2\x80\x9a\xc3\xb3\xc3\xa4//g;   #‚óä ---> ‚óäpiperita	‚óähortorum	‚óämacdonaldii	‚óähybrida	
s/\xe2\x88\x9a\xc3\xb5/o/g;   #√õ ---> Pav√õn)
s/\xe2\x82\xac/o/g;   #€ ---> Pav€n
	s/ñ/n/g;
#	s/ //g;
#	s/Ø//g;
#	s/§//g;
#	s/î//g;
#	s/æ//g;
#	s/¦//g;
#	s/¢//g;
#	s/¡//g;
#	s/¬//g;
#	s/Â//g;
#	s/Æ//g;
#	s///g;
#	s/•//g;
#	s/…//g;
#	s/﻿//g;
#	s/º/ deg. /g;
#	s/°/ deg. /g;
#	s/Á/ deg. /g;
#	s/Ã/ deg. /g;
#	s/©//g;
	s/×/ X /g;
	s/˚/ deg. /g;
	s/¼/1\/4/g;
	s/¾/3\/4/g;
	s/½/1\/2/g;
	s/±/+-/g;
	s/»/>/g;
	s/«=/<=/g;
	s/”/'/g;
	s/“/'/g;
	s/’/'/g;
	s/‘/'/g;
	s/´/'/g;
	s/—/-/g;
	s/ö/o/g;
	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ä/a/g;
	s/á/a/g;
	s/ú/u/g;
	s/í/i/g;


s/  +/ /g;
 
#remove artifacts of CSV conversion, @ was set as escape character instead of problematic ""
s/@+/@/g;
s/@"/'/g;
s/"+/"/g;
s/"/'/g;
s/'+/'/g;

        if ($. == 1){#activate if need to skip header lines
			next;
		}
#Accession Number	Title	Subtitle	Country	State symbol	County symbol	Physical terrane	Family Name	Accepted Name	Locality	Elev Ft	Elev M	Longitude	Latitude	UTM E	UTM N	Plt Description	Habitat	Abundance	Assoc species	Assoc species 2	Collector	Prefix	Collection #	Other Collector(s)	Month	Day	Year

		
my $id;
my $country;
my $stateProvince;
my $county;
my $tempCounty;
my $locality; 
my $family;
my $scientificName;
my $name;
my $hybrid_annotation;
my $recordedby;
my $recordedBy;
my $Collector_full_name;
my $eventDate;
my $verbatimEventDate;
my $collector;
my $collectors;
my %collectors;
my %coll_seen;
my $other_collectors;
my $other_coll;
my $Associated_collectors;
my $verbatimCollectors; 
my $coll_month; 
my $coll_day;
my $coll_year;
my $recordNumber;
my $CNUM;
my $CNUM_prefix;
my $verbatimElevation;
my $elevation;
my $elev_feet;
my $elev_meters;
my $CCH_elevationInMeters;
my $elevationInMeters;
my $elevationInFeet;
my $verbatimLongitude;
my $verbatimLatitude;
my $TRS;
my $UTME;
my $UTMN; 
my $habitat;
my $latitude;
my $decimalLatitude;
my $longitude;
my $decimalLongitude;
my $datum;
my $errorRadius;
my $georeferenceSource;
my $associatedSpecies;	
my $plant_description;
my $abundance;
my $associatedTaxa;
my $cultivated; #add this field to the data table for cultivated processing, place an "N" in all records as default
my $location;
my $localityDetails;
my $commonName;
#unique to this dataset
my $labelHeader;
my $labelSubHeader;
my $name_w_author;
my $associatedTaxa2;
my $main_collector;
my $island;

my @columns=split(/\t/,$_,100);
		unless($#columns==29){ #30 fields but first field is field 0 in perl
		&log_skip("$#columns bad field number $_");
		++$skipped{one};
		next Record;
	}	
		
($id,
$labelHeader,
$labelSubHeader,
$country,
$stateProvince,
$tempCounty,
$island, #followed by a colon; concatenate with location to get dwc locality
$family,
$name_w_author, #with author; need to strip author.
$location, 
$elev_feet,
$elev_meters, #elevations are one or the other: use $meters_to_feet conversion to put all into meters
$verbatimLatitude, #lat is called long and vice versa in column headers. Convert them to DD and call source "DMS conversion"
$verbatimLongitude,	#in the format DDø MM' SS", or sometimes DDøMM'SS" DDøMM.MMM' or DDøMM'SS.SSS"
$UTME,
$UTMN, #figure out zone; convert if possible. Call source "UTM conversion"
$plant_description, #plant description
$habitat,
$abundance,
$associatedTaxa,
$associatedTaxa2, #new field Oct2015
$main_collector,
$CNUM_prefix,
$CNUM, #can concat with prefix to make dwc recordNumber
$other_coll, #can concatenate with $main_collector to make dwc recordedBy
$coll_month, #three letter month name: Jan, Feb, Mar etc.
$coll_day,
$coll_year,
$cultivated,
$verbatimCollectors
)=@columns;

################ACCESSION_ID#############
#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space
foreach($id){
	s/^0+//g;
	s/  +/ /;
	s/^ +//g;
	s/ +$//g;
}

#Add prefix, 
$id="CATA$id";

#Remove duplicates
if($seen{$id}++){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}

#####Annotations  (use when no separate annotation field)
	#format det_string correctly
my $det_date;
my $det_rank = "current determination (uncorrected)";  #set for current determination
my $det_name = $name_w_author;
my $det_determiner;
my $det_date;
my $det_stet;	
	
	if ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}	
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($det_stet) > 1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet, $det_determiner";
	}	
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($det_stet) == 0) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_date";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($det_stet) > 1) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name   $det_stet, $det_determiner, $det_date";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name, $det_date";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="";
	}
	else{
		&log_change("det problem: $det_rank: $det_name   $det_stet, $det_determiner, $det_date==>$id\n");
		$det_string="";
	}

##########Begin validation of scientific names


###########SCIENTIFICNAME
#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($name_w_author){
	s/ sp\.//g;
	s/ species$//g;
	s/ sp$//g;
	s/ spp / subsp. /g;
	s/ spp. / subsp. /g;
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/;$//g;
	s/cf.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
	
	}


#format hybrid names
if($name_w_author=~s/([A-Z][a-z-]+ [a-z-]+) [A-Za-z-. ]* X /$1 X /){
	$hybrid_annotation=$name_w_author;
	warn "Hybrid Taxon: $1 removed from $name_w_author\n";
	&log_change("Hybrid Taxon: $1 removed from $name_w_author");
	$name_w_author=$1;
}
else{
	$hybrid_annotation="";
}


#####process taxon names

$scientificName = &strip_name($name_w_author);

$scientificName = &validate_scientific_name($scientificName, $id);

#####process cultivated specimens			
# flag taxa that are known cultivars that should not be added to the Jepson Interchange, add "P" for purple flag to Cultivated field	

# the title/subtitle is used to determine cultivated-ness


## dedicated Cultivated field parsing
		if ($labelHeader=~ m/Cultivated/i){
			$cultivated = "P"; #P for purple flag
			&log_change ("Record marked as cultivated because of label header: $scientificName\t--\t$labelHeader\t--\t$id");
		}
## regular Cultivated parsing
		elsif (($labelHeader !~ m/Cultivated/i) && ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i)){
			&log_change("specimen likely not cultivated, purple flagging skipped: $scientificName\t--\t$id\n");
		}
		elsif (($labelHeader !~ m/Cultivated/i) && (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($habitat =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental\.|ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i))){
		    $cultivated = "P";
	   		&log_change("Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
		elsif ($cultivated !~ m/P/){
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			#&log_change("Taxon skipped purple flagging: $cultivated\t--\t$scientificName\n");
			$cultivated = "";
			}
		}

##########COLLECTION DATE##########
my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;
my $eventDateAlt;

#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#$coll_month, #three letter month name: Jan, Feb, Mar etc.
#$coll_day,
#$coll_year,
#verbatim date for dwc verbatimEventDate and CCH "Date"

$eventDateAlt = $coll_day."-".$coll_month."-".$coll_year ;

foreach ($eventDateAlt){
	s/,//g;
	s/^-+//; #remove added dash for the dates without a day value
	s/\.//g;
	s/\//-/g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
	}


	if($eventDateAlt=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	warn "(1)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^(\d\d)-(\d\d)-([0-9]{4})/){	#added to SDSU, if eventDate is in the format ##-##-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(2)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{1})-([0-9]{1,2})-([0-9]{4})/){	#added to SDSU, if eventDate is in the format #-##?-####, most appear that first # is month 
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(3)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([Ss][pP][rR][ing]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "(14)$eventDateAlt\t$id";
	}	
	elsif ($eventDateAlt=~/^([Ss][uU][Mm][mer]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "6";
		$DD = "1";
		$MM2 = "8";
		$DD2 = "31";
	warn "(16)$eventDateAlt\t$id";
	}	
	elsif ($eventDateAlt=~/^([fF][Aa][lL]+)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$DD = "1";
		$MM = "9";
		$DD2 = "30";
		$MM2 = "11";
	warn "(12)$eventDateAlt\t$id";
	}	
	elsif ($eventDateAlt=~/^([0-9]{1,2})[- ]+([A-Za-z]+)[- ]+([0-9]{4})/){
		$DD=$1;
		$MM=$2;
		$YYYY=$3;
		$MM2 = "";
		$DD2 = "";
	#warn "(22)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{1,2})[- ]+([0-9]{1,2})[- ]+([A-Z][a-z]+)[- ]([0-9]{4})/){
		$DD=$1;
		$DD2=$2;
		$MM=$3;
		$MM2=$3;
		$YYYY=$4;
	warn "(4)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Za-z]+)-([0-9]{2})$/){
	warn "Date (6): $eventDateAlt\t$id";
		$eventDateAlt = "";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)-(June?)[- ]$/){ #month, year, no day
		$YYYY = $1;
		$DD = "1";
		$MM = $1;
		$DD2 = "30";
		$MM2 = $2;
	warn "Date (7): $eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Z][a-z]+)[- ](June?)[- ]([0-9]{4})$/){ #month, year, no day
		$YYYY = $3;
		$DD = "1";
		$MM = $1;
		$DD2 = "30";
		$MM2 = $2;
	warn "Date (8): $eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)[- ](Ma[rchy])[- ]$/){ #month, year, no day
		$YYYY = $1;
		$DD = "1";
		$MM = $1;
		$DD2 = "31";
		$MM2 = $3;
	warn "Date (9): $eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Z][a-z]+)[- ](Ma[rchy])[- ]([0-9]{4})/) {#month, year, no day
		$YYYY = $3;
		$DD = "1";
		$MM = $1;
		$DD2 = "31";
		$MM2 = $2;
	warn "Date (10): $eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([fF][Aa][lL]+)/) {
		$YYYY = $1;
		$DD = "1";
		$MM = "9";
		$DD2 = "30";
		$MM2 = "11";
	warn "(11)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "(13)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "(15)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Za-z]+) ([0-9]{4})$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(5)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Za-z]+) ([0-9]{2})([0-9]{4})$/){
		$DD = $2;
		$MM = $1;
		$YYYY= $3;
		$MM2 = "";
		$DD2 = "";
	warn "(20)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([Ss][uU][Mm][mer]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "(17)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]*$/){
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
		$MM="";
	warn "(18)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})-([0-9]{1,2})[- ]*$/){
		$MM=$2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
	warn "(19)$eventDateAlt\t$id";
	}
	elsif (length($eventDateAlt) == 0){
		$YYYY="";
		$MM2 = "";
		$DD2 = "";
		$DD = "";
		$MM="";
		&log_change("Date: date NULL $id\n");
	}
	else{
		&log_change("Date: date format not recognized: $eventDateAlt==>($verbatimEventDate)\t$id\n");
	}


#convert to YYYY-MM-DD for eventDate and Julian Dates
$MM = &get_month_number($MM, $id, %month_hash);
$MM2 = &get_month_number($MM2, $id, %month_hash);

#$formatEventDate = "$YYYY-$MM-$DD";
#($YYYY, $MM, $DD)=&atomize_ISO_8601_date($formatEventDate);
#warn "$formatEventDate\t--\t$id";

if ($MM =~ m/^(\d)$/){ #see note above, JulianDate module needs leading zero's for single digit days and months
	$MM = "0$1";
}
if ($DD =~ m/^(\d)$/){
	$DD = "0$1";
}
if ($MM2 =~ m/^(\d)$/){
	$MM2 = "0$1";
}
if ($DD2 =~ m/^(\d)$/){
	$DD2 = "0$1";
}

#$MM2= $DD2 = ""; #set late date to blank if only one date exists
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $MM2, $DD2, $id);
#warn "$formatEventDate\t--\t$EJD, $LJD\t--\t$id";
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);





###############COLLECTORS



	foreach ($main_collector, $other_coll){
		s/'$//g;
		s/, M\. ?D\.//g;
		s/, Jr\./ Jr./g;
		s/, Jr/ Jr./g;
		s/, Esq./ Esq./g;
		s/, Sr\./ Sr./g;
		s/  +/ /;
		s/^ *//;
		s/ *$//;
		
	
	$other_collectors = ucfirst($other_coll);
	}
	
	
if ((length($main_collector) > 1) && (length($other_collectors) > 1)){	
	$recordedBy = &CCH::validate_single_collector($main_collector, $id);
	$verbatimCollectors = "$main_collector, $other_collectors";
	#warn "Names 1: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
}
elsif ((length($main_collector) > 1) && (length($other_collectors) == 0)){
	$recordedBy = &CCH::validate_single_collector($main_collector, $id);
	$verbatimCollectors = "$main_collector";
	$other_collectors = "";
	#warn "Names 2: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
}
elsif ((length($main_collector) == 0) && (length($other_collectors) == 0)){
	$recordedBy = "";
	$verbatimCollectors = "";
	$other_collectors = "";
	&log_change("COLLECTOR: name NULL\t$id\n");
}
elsif ((length($collector) == 0) && (length($other_collectors) > 1)){
	$recordedBy = &CCH::validate_single_collector($other_collectors, $id);
	$verbatimCollectors = "$other_collectors";
	&log_change("COLLECTOR: Collector name field missing, using other collector field\t$id\n");
}
else {
		&log_change("COLLECTOR: name format problem\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}

foreach ($verbatimCollectors){
	s/'$//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
	
}

#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes
my $CNUM_suffix="";
($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);



####Country and State always U.S.A.[or U. S. A.]/CA, unless left blank, which still means USA/CA
	foreach ($country){
		s/usa/USA/;
		s/USa/USA/;
		s/United States of America/USA/;
		s/UNITED STATES/USA/;
		s/United states/USA/;
		s/united states/USA/;
		s/  +/ /;
		s/^ +//;
		s/ +$//;
				
	}

foreach($stateProvince){#for each $county value
	s/california/California/;
	s/CALIFORNIA/California/;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

foreach($tempCounty){#for each $county value
	s/'//g;
	s/^ +//g;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries

}
#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);

######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}

##############validate county
my $v_county;

foreach($county){#for each $county value
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|Unknown)$/){
		$v_county = &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&log_skip("COUNTY (2): NON-CA COUNTY?\t$_\t--\t$id");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log_change("COUNTY (3): COUNTY $_ ==> $v_county--\t$id");		#call the &log function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}



####LOCALITY

	if((length($location) > 1) && (length($island) == 0)){ 
		$locality = $location;
	}		
	elsif ((length($location) > 1) && (length($island) >1)){
		$locality = "$island $location";
		$locality =~ s/'$//;
		$locality =~ s/ *$//;
		$locality =~ s/  +/ /;
	}
	elsif ((length($location) == 0) && (length($island) >1)){
		$locality = $island;
		$locality =~ s/: *$//;
		$locality =~ s/'$//;
		$locality =~ s/ *$//;
		$locality =~ s/  +/ /;
	}
	else {
		&log_change("Locality problem, bad format, $id\t--\t$location\t--\t$island\n");		#call the &log function to print this log message into the change log...
	}

####ELEVATION
my $feet_to_meters="3.2808";

#$elevationInMeters is the darwin core compliant value
#verify if elevation fields are just numbers

#process verbatim elevation fields into CCH format
if ((length($elev_meters) >= 1) && (length($elev_feet) == 0)){

	if ($elev_meters =~ m/^(-?[0-9]+)$/){
		$elevationInMeters = $elev_meters;
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$elevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$elev_meters' not numeric\t$id");
		$elevationInMeters="";
	}	
}
elsif ((length($elev_meters) == 0) && (length($elev_feet) >= 1)){

	if ($elev_feet =~ m/^(-?[0-9]+)$/){
		$elevationInFeet = $elev_feet;
		$elevationInMeters = int($elev_feet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$elevationInFeet ft";
	}
	else {
		&log_change("Check elevation in feet: '$elev_feet' not numeric\t$id");
		$elevationInFeet="";
	}	
	
}
elsif ((length($elev_meters) >= 1) && (length($elev_feet) >= 1)){
	if ($elev_meters =~ m/^(-?[0-9]+)$/){
		$elevationInMeters = $elev_meters;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$elev_meters' not numeric\t$id");
		$elevationInMeters="";
	}
}
else {
	$CCH_elevationInMeters = "";
}


my $pre_e;
my $e;

if (length($CCH_elevationInMeters) == 0){

		if($locality=~m/(\b[Ee]lev\.?:? [,0-9 -]+ *[MFmf'])/ || $locality=~m/([Ee]levation:? [,0-9 -]+ *[MFmf'])/ || $locality=~m/([,0-9 -]+ *(feet|ft|ft\.|m|meter|meters|'|f|f\.) *[Ee]lev)/i || $locality=~m/\b([Ee]lev\.? (ca\.?|about) [0-9, -]+ *[MmFf])/|| $locality=~m/([Ee]levation (about|ca\.) [0-9, -] *[FfmM'])/){
#		# print "LF: $locality: $1\n";
				$pre_e=$e=$1;
				foreach($e){
					s/Elevation[.:]* *//i;
					s/Elev[.:]* *//i;
					s/(about|ca\.?)//i;
					s/ ?, ?//g;
					s/(feet|ft|f|ft\.|f\.|')/ ft/i;
					s/(m\.|meters?|m\.?)/ m/i;
					s/  +/ /g;
					s/^ +//;
					s/[. ]*$//;
					s/ *- */-/;
					s/-ft/ ft/;
					s/(\d) (\d)/$1$2/g;
					next unless m/\d/;
					if (m/^(-?[0-9]+) ?m/){
						$elevationInMeters = $1;
						$elevationInFeet = int($elevationInMeters * 3.2808);
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation in meters found within $id\t$locality\t$id");
					}
					elsif (m/^(-?[0-9]+) ?f/){
						$elevationInFeet = $1;
						$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation in feet found within $id\t$locality");
					}
					elsif (m/^-?[0-9]+-(-?[0-9]+) ?f/){
						$elevationInFeet = $1;
						$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation range in feet found within $id\t$locality");
					}
					elsif (m/^-?[0-9]+-(-?[0-9]+) ?m/){
						$elevationInMeters = $1;
						$elevationInFeet = int($elevationInMeters * 3.2808);
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation in meters found within $id\t$locality\t$id");
					}
					else {
						&log_change("Elevation in $locality has missing units, is non-numeric, or has typographic errors\t$id");
						$elevationInFeet = "";
						$elevationInMeters="";
						$CCH_elevationInMeters = "";
					}	
				}
		}
}

#####check to see if elevation exceeds maximum and minimum for each county

my $elevation_test = int($elevationInFeet);
	if($elevation_test > $max_elev{$county}){
		&log_change ("ELEV: $county\t$elevation_test ft. ($elevationInMeters m.) greater than $county maximum ($max_elev{$county} ft.): discrepancy=", (($elevation_test)-$max_elev{$county}),"\t$id\n");
		if ((($elevation_test)-$max_elev{$county}) >= 500 ){
			$CCH_elevationInMeters = "";
			&log_change ("ELEV: $county discrepancy=", (($elevation_test)-$max_elev{$county})," greater than 500 ft, elevation changed to NULL\t$id\n");
		}
	}

#########COORDS, DATUM, ER, SOURCE#########

#######Latitude and Longitude
#right now the Latitude and Longitude fields are always in DMS or DDM. Will probably include decimal degrees in the future
#Datum and uncertainty are not recorded.
#Datum is assumed to be NAD83/WGS84 for the purposes of utm_to_latlon conversion (i.e. $ellipsoid=23)
#but otherwise datum is not reported
#remove symbols and put it in a standard format, spaces delimiting
my $ellipsoid;
my $northing;
my $easting;
my $zone;
my $hold;
my $lat_degrees;
my $lat_minutes;
my $lat_seconds;
my $lat_decimal;
my $long_degrees;
my $long_minutes;
my $long_seconds;
my $long_decimal;
my $zone_number;

foreach ($verbatimLatitude, $verbatimLongitude){
		s/ø/ /g;
		s/'/ /g;
		s/;/ /g;
		s/"/ /g;
		s/’/ /g;
		s/”/ /g;
		s/deg./ /g;
		s/^ +//g;
		s/^"//g;
		s/"$//g;
		s/""//g;
		s/[°¡]//g;
		s/N//g;
		s/,/ /g;
		s/W//g;
		s/’/ /g; #this was copied from the error log, must be different character coding than above
		s/”/ /g; #this was copied from the error log, must be different character coding than above
		#s/°/ /g;
		s/  +/ /;
		s/^ +//;
		s/ +$//;
	
}



#check to see if lat and lon reversed
	if (($verbatimLatitude =~ m/^-?1\d\d\./) && ($verbatimLongitude =~ m/^\d\d\./)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		 
		&log_change("COORDINATE decimals apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d +\d/) && ($verbatimLongitude =~ m/^\d\d +\d/)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		 
		&log_change("COORDINATE apparently reversed, switching latitude with longitude\t$id");
	}	
	elsif (($verbatimLatitude =~ m/^\d\d\./) && ($verbatimLongitude =~ m/^-?1\d\d\./)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
	}
	elsif (($verbatimLatitude =~ m/^\d\d \d/) && ($verbatimLongitude =~ m/^-?1\d\d \d/)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
	}
	elsif ((length($verbatimLatitude) == 0) && (length($verbatimLongitude) == 0)){
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}
	elsif (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d/)){
			$latitude = sprintf ("%.3f",$verbatimLatitude); #convert to decimal, should report cf. 38.000
			$longitude = $verbatimLongitude; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
			&log_change("COORDINATE (7) latitude integer degree only: $verbatimLatitude converted to $latitude==>$id");
	}
	elsif (($verbatimLatitude =~ m/^\d\d/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
			$latitude = $verbatimLatitude; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
			$longitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 122.000
			&log_change("COORDINATE (8) longitude integer degree only: $verbatimLongitude converted to $longitude==>$id");
	}	
	elsif ((length($verbatimLatitude) == 0) && (length($verbatimLongitude) == 0)){
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
		print "COORDINATE NULL $id\n";
	}
	else {
		&log_change("COORDINATE: partial coordinates only for $id\t($verbatimLatitude)\t($verbatimLongitude)\n");
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}

#NULL coordinates that are only integer degrees, these are highly inaccurate and not useful for mapping
	if (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
		$decimalLatitude=$latitude = "";
		$decimalLongitude=$longitude = "";
		&log_change("COORDINATE verbatim Lat/Long only to degree, now NULL: $verbatimLatitude\t--\t$verbatimLongitude\n");
	}



foreach ($latitude, $longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;

}	

#use combined Lat/Long field format for CATA

	#convert to decimal degrees
if((length($latitude) >= 2)  && (length($longitude) >= 3)){ 
		if ($latitude =~ m/^(\d\d) +(\d\d?) +(\d\d?\.?\d*)/){ #if there are seconds
				$lat_degrees = $1;
				$lat_minutes = $2;
				$lat_seconds = $3;
				if($lat_seconds == 60){ #translating 60 seconds into +1 minute
					$lat_seconds == 0;
					$lat_minutes += 1;
				}
				if($lat_minutes == 60){
					$lat_minutes == 0;
					$lat_degrees += 1;
				}
				if(($lat_degrees > 90) || $lat_minutes > 60 || $lat_seconds > 60){
					&log_change("COORDINATE 1) Latitude problem, set to null,\t$id\t$latitude\n");
					$lat_degrees=$lat_minutes=$lat_seconds=$decimalLatitude="";
				}
				else{
					#print "1a) $lat_degrees\t-\t$lat_minutes\t-\t$lat_seconds\t-\t$latitude\n";
	  				$lat_decimal = $lat_degrees + ($lat_minutes/60) + ($lat_seconds/3600);
					$decimalLatitude = sprintf ("%.6f",$lat_decimal);
					#print "1b)$decimalLatitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script"; #only needed to be stated once, if lat id converted, so is long
				}
		}
		elsif ($latitude =~ m/^(\d\d) +(\d\d?\.\d*)/){
				$lat_degrees= $1;
				$lat_minutes= $2;
				if($lat_minutes == 60){
					$lat_minutes == 0;
					$lat_degrees += 1;
				}
				if(($lat_degrees > 90) || ($lat_minutes > 60) ){
					&log_change("COORDINATE 2) Latitude problem, set to null,\t$id\t$latitude\n");
					$lat_degrees=$lat_minutes=$decimalLatitude="";
				}
				else{
					#print "2a) $lat_degrees\t-\t$lat_minutes\t-\t$latitude\n";
					$lat_decimal= $lat_degrees+($lat_minutes/60);
					$decimalLatitude=sprintf ("%.6f",$lat_decimal);
					#print "2b) $decimalLatitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($latitude =~ m/^(\d\d) +(\d\d?)/){
				$lat_degrees= $1;
				$lat_minutes= $2;
				if($lat_minutes == 60){
					$lat_minutes == 0;
					$lat_degrees += 1;
				}
				if(($lat_degrees > 90) || ($lat_minutes > 60) ){
					&log_change("COORDINATE 2c) Latitude problem, set to null,\t$id\t$latitude\n");
					$lat_degrees=$lat_minutes=$decimalLatitude="";
				}
				else{
					#print "2a) $lat_degrees\t-\t$lat_minutes\t-\t$latitude\n";
					$lat_decimal= $lat_degrees+($lat_minutes/60);
					$decimalLatitude=sprintf ("%.6f",$lat_decimal);
					print "2d) $decimalLatitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($latitude =~ m/^(\d\d\.\d+)/){
				$lat_degrees = $1;
				if($lat_degrees > 90){
					&log_change("COORDINATE 3) Latitude problem, set to null,\t$id\t$latitude\n");
					$lat_degrees=$latitude=$decimalLatitude="";		
				}
				else{
					$decimalLatitude=sprintf ("%.6f",$lat_degrees);
					print "3a) $decimalLatitude\t--\t$id\n";
				}
		}
		elsif (length($latitude) == 0){
			$decimalLatitude="";
		}
		else {
			&log_change("check Latitude format: ($latitude) $id");	
			$decimalLatitude="";
		}
		
		if ($longitude =~ m/^(-?1\d\d) +(\d\d?) +(\d\d?\.?\d*)/){ #if there are seconds
				$long_degrees = $1;
				$long_minutes = $2;
				$long_seconds = $3;
				if($long_seconds == 60){ #translating 60 seconds into +1 minute
					$long_seconds == 0;
					$long_minutes += 1;
				}
				if($long_minutes == 60){
					$long_minutes == 0;
					$long_degrees += 1;
				}
				if(($long_degrees > 180) || $long_minutes > 60 || $long_seconds > 60){
					&log_change("COORDINATE 5) Longitude problem, set to null,\t$id\t$longitude\n");
					$long_degrees=$long_minutes=$long_seconds=$decimalLongitude="";
				}
				else{				
					#print "5a) $long_degrees\t-\t$long_minutes\t-\t$long_seconds\t-\t$longitude\n";
 	 				$long_decimal = $long_degrees + ($long_minutes/60) + ($long_seconds/3600);
					$decimalLongitude=sprintf ("%.6f",$long_decimal);
					#print "5b) $decimalLongitude\t--\t$id\n";
				}
		}	
		elsif ($longitude =~m /^(-?1\d\d) +(\d\d?\.\d*)/){
				$long_degrees= $1;
				$long_minutes= $2;
				if($long_minutes == 60){
					$long_minutes == 0;
					$long_degrees += 1;
				}
				if(($long_degrees > 180) || ($long_minutes > 60) ){
					&log_change("COORDINATE 6) Longitude problem, set to null,\t$id\t$longitude\n");
					$long_degrees=$long_minutes=$decimalLongitude="";
				}
				else{
					$long_decimal= $long_degrees+($long_minutes/60);
					$decimalLongitude = sprintf ("%.6f",$long_decimal);
					#print "6a) $decimalLongitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($longitude =~m /^(-?1\d\d) +(\d\d?)/){
			$long_degrees= $1;
			$long_minutes= $2;
			if($long_minutes == 60){
				$long_minutes == 0;
				$long_degrees += 1;
			}
			if(($long_degrees > 180) || ($long_minutes > 60) ){
				&log_change("COORDINATE 6c) Longitude problem, set to null,\t$id\t$longitude\n");
				$long_degrees=$long_minutes=$decimalLongitude="";
			}
			else{
				$long_decimal= $long_degrees+($long_minutes/60);
				$decimalLongitude = sprintf ("%.6f",$long_decimal);
				print "6d) $decimalLongitude\t--\t$id\n";
				$georeferenceSource = "DMS conversion by CCH loading script";
			}
		}
		elsif ($longitude =~m /^(-?1\d\d\.\d+)/){
				$long_degrees= $1;
				if($long_degrees > 180){
					&log_change("COORDINATE 7) Longitude problem, set to null,\t$id\t$long_degrees\n");
					$long_degrees=$longitude=$decimalLongitude="";		
				}
				else{
					$decimalLongitude=sprintf ("%.6f",$long_degrees);
					print "7a) $decimalLongitude\t--\t$id\n";
				}
		}
		elsif (length($longitude == 0)) {
			$decimalLongitude="";
		}
		else {
			&log_change("COORDINATE check longitude format: $longitude $id");
			$decimalLongitude="";
		}
}
elsif ((length($latitude) == 0) && (length($longitude) == 0)){ 
		#process zone fields
		if ((length($UTME) >= 1 ) && (length($UTMN) >= 1 )){
			&log_change("10) Lat & Long null but UTM is present, checking for valid coordinates: $UTME, $UTMN, $zone, $id\n");
		
			if((length($zone) == 0) && ($locality =~ m/(San Miguel Island|Santa Rosa Island)/i)){
				$zone = "10S"; #Zone for these data are this, using UTMWORLD.gif in DATA directory
			}
			elsif ((length($zone) == 0) && ($locality !~ m/(San Miguel Island|Santa Rosa Island)/i)){
			#set zone based on county boundary, rough estimate, but better than nothing since most UTM's do not include zone and row on plant specimens
				if($county =~ m/(Ensenada)/){
					$zone = "11R"; #Zone for these estimated using GIS overlay, not exact, some will fall outside this zone
				}
				elsif($county =~ m/(Del Norte|Siskiyou|Modoc|Lassen|Shasta|Tehama|Trinity|Humboldt)/){
					$zone = "10T";
				}
				elsif($county =~ m/(Rosarito, Playas de|Tecate|Tijuana|Alpine|Fresno|Imperial|Inyo|Kern|Kings|Los Angeles|Madera|Mariposa|Mono|Orange|Riverside|San Bernardino|San Diego|Ventura|Tuolumne)/){
					$zone = "11S";
				}
				elsif($county =~ m/(Alameda|Amador|Butte|Calaveras|Colusa|Contra Costa|El Dorado|Glenn|Lake|Marin|Mendocino|Merced|Monterey|Napa|Nevada|Placer|Plumas|Sacramento|San Benito|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Sierra|Solano|Sonoma|Stanislaus|Sutter|Tulare|Yolo|Yuba)/){
					$zone = "10S";
				}
				elsif($county =~ m/(Mexicali|Unknown)/){
					$zone = ""; #Mexicali is in a small part of CA-FP Baja and it has sections in two zones, so UTM without zone is not convertable
				}
				else{
					&log_change("UTM Zone cannot be determined: $id");
					$zone = "";
				}
			}
		}
		if ((length($UTME) >=6 ) && (length($UTMN) >=6 )){
#leading zeros need to be removed before this step
#Northing is always one digit more than easting. sometimes they are apparently switched around.
			if (($UTME =~ m/^\d{7}/) && ($UTMN =~ /^\d{6}/)){
					$easting = $UTMN;
					$northing = $UTME;
					&log_change("UTM coordinates apparently reversed; switching northing with easting: $id");
			}
			elsif (($UTMN =~ m/^\d{7}/) && ($UTME =~ /^\d{6}$/)){
					$easting = $UTME;
					$northing = $UTMN;
			}
			else{
				&log_change("11a) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone, $id\n");
				$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
			}
			$ellipsoid = int(23);
			($decimalLatitude,$decimalLongitude)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
			&log_change("Decimal degrees derived from UTM for $id: $decimalLatitude, $decimalLongitude");
			$georeferenceSource = "UTM conversion by CCH loading script";
		}
		elsif ((length($UTME) == 0) && (length($UTMN) == 0)){
			$easting = $northing = "";
			&log_change("coordinates NULL for $id\n");
		}
		else{
				&log_change("11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone, $id\n");
				$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
		}
}
elsif($latitude==0 && $longitude==0 && $UTME==0 && $UTMN==0){
	$datum = "";
	$georeferenceSource = "";
	$decimalLatitude =$decimalLongitude = "";
		&log_change("COORDINATE coordinates entered as '0', changed to NULL $id\n");
}
else {
			&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
}


#check datum

if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	#$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
#$coordinateUncertaintyInMeters none in these data
#$UncertaintyUnits none in these data

	if ($datum){
		s/  +/ /gg;
		s/^ +//g;
		s/ +$//g;
	}
	else {$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
	}
}




#final check of Longitude

	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			&log_change("Longitude made negative\t--\t$id");
	}

#final check for rough out-of-boundary coordinates
if((length($decimalLatitude) >= 2)  && (length($decimalLongitude) >= 3)){ 
	if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114.0 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california and northern Baja...
	###was 32.5 for California, now 30.0 to include CFP-Baja
		&log_change("coordinates set to null for $id, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude = $decimalLongitude = $georeferenceSource = $datum="";	#and set $decLat and $decLong to ""  
	}
}
else {
		if((length($decimalLatitude) == 0)  && (length($decimalLongitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}


#######Plant Description (dwc ??) and Abundance (dwc occurrenceRemarks)

foreach ($plant_description){
		s/'$//;
		s/  +/ /g;
}

foreach ($abundance){
		s/'$//;
		s/  +/ /g;
}

#######Habitat and Assoc species (dwc habitat and associatedTaxa)

#free text fields
foreach ($associatedTaxa){
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/'$//;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;

}


foreach ($associatedTaxa2){
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/'$//;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}

	if((length($associatedTaxa) > 1) && (length($associatedTaxa2) == 0)){ 
		$associatedSpecies = $associatedTaxa
	}		
	elsif ((length($associatedTaxa) > 1) && (length($associatedTaxa2) >1)){
		$associatedSpecies = "$associatedTaxa $associatedTaxa2";
	}
	else {
		$associatedSpecies = "";
	}

foreach ($habitat){
		s/'$//;
		s/  +/ /g;
}


print OUT <<EOP;
Accession_id: $id
Name: $scientificName
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
Collector: $recordedBy
Other_coll: $other_collectors
Combined_coll: $verbatimCollectors
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Country: $country
State: $stateProvince
County: $county
Location: $locality
Habitat: $habitat
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance:
Max_error_units:
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Associated_species: $associatedSpecies
Macromorphology: $plant_description
Population_biology: $abundance
Notes: $labelHeader
Cultivated: $cultivated
Hybrid_annotation: $hybrid_annotation
Annotation: $det_string

EOP
++$included;
}

my $skipped_taxa = $count-$included;
print <<EOP;
INCL: $included
EXCL: $skipped{one}
TOTAL: $count

SKIPPED TAXA: $skipped_taxa
EOP


close(IN);
close(OUT);
#####Check final output for characters in problematic formats (non UTF-8), this is Dick's accent_detector.pl
my @words;
my $word;
my $store;
my $match;
my %store;
my %match;
my %seen;
%seen=();


    my $file_in = 'CATA_out.txt';	#the file this script will act upon is called 'CATA.out'
open(IN,"$file_in" ) || die;

while(<IN>){
        chomp;
#split on tab, space and quote
        @words=split(/["        ]+/);
        foreach (@words){
                $word=$_;
#as long as there is a non-ascii string to delete, delete it
                while(s/([^\x00-\x7F]+)//){
#store the word it occurs in unless you've seen that word already

                        unless ($seen{$word . $1}++){
                                $store{$1} .= "$word\t";
                        }
                }
        }
}

	foreach(sort(keys(%store))){
#Get the hex representation of the accent
		$match=  unpack("H*", "$_"), "\n";
#add backslash-x for the pattern
		$match=~s/(..)/\\x$1/g;
#Print out the hex representation of the accent as it occurs in a pattern, followed by the accent, followed by the list of words the accent occurs in
				&log_skip("problem character detected: s/$match/    /g   $_ ---> $store{$_}\n\n");
	}
close(IN);

