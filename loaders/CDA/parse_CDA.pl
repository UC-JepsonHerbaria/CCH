
use Geo::Coordinates::UTM;
use strict;
#use warnings;
use Data::GUID;
use utf8; #use only when original has problems with odd character substitutions
use Text::Unidecode;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.

$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;


my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;
my $count_record;


open(OUT, ">/JEPS-master/CCH/Loaders/CDA/CDA_out.txt") || die;
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $file = '/JEPS-master/CCH/Loaders/CDA/CDAtoCCH4_16_mod.txt';
###File arrives as an Excel xlsx file, with a lot of unfortunate in-cell line breaks
#Some latmin and longmin are emtpy, sort the excel spreadsheet and add 0.001 to the minute field, otherwise these will not parse.  it is assumed a zero should have been entered into these fields

#Some problem specimens:
###CDA29638	M. Beyers	105, is a duplicate with the wrong accession number, change to CDA29638b
###CDA33958	M. Beyers	823A id'd to just Agrostis is a duplicate of the next record, change to CDA33958b
###CDA24566	M. Beyers	865 is a duplicate with the wrong accession number, change to CDA24566b
###CDA30254	G.F. Hrusa	16650 is a duplicate with the wrong accession number, change to CDA30254b
###CDA41051	T.C. Fuller	33b-58 is a duplicate with the wrong accession number, change to CDA41051b
###CDA6208 Unknown	s.n.	Jan	1	1906 is two mostly similar records, delete the second, incomplete record
###CDA20081	T. Gibson	PDR 1089395 is two identical records, delete one

open(IN,$file) || die;
Record: while(<IN>){
	chomp;

	$line_store=$_;
	++$count;

#fix some data quality and formatting problems that make import of fields of certain records problematic
	s///g; #x{0B} hidden character
	s/Å/ /g; #U+00C5	Å	\xc3\x85

	s/ //g;
	s/ñ/n/g;
	s/×/ X /g;
	s/˚/ deg. /g;
	s/°/ deg. /g;#U+00B0	°	\xc2\xb0
	s/º/ deg. /g;#U+00BA	º	\xc2\xba
	s/±/+-/g;
	s/”/'/g;
	s/“/'/g;
	s/’/'/g;
	s/‘/'/g;
	s/´/'/g;
	s/—/-/g;
	s/é/e/g;
	s/á/a/g;


	s/&apos;/'/g;

        if ($. == 1){#activate if need to skip header lines
			next Record;
		}


my $GUID;
my $id;
my $country;
my $stateProvince;
my $county;
my $tempCounty;
my $locality; 
my $family;
my $scientificName;
my $genus;
my $species;
my $rank;
my $subtaxon;
my $tempName;
my $hybrid_annotation;
my $identifiedBy;
my $dateIdentified;
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
my $CNUM_suffix;
my $verbatimElevation;
my $elevation;
my $elev_feet;
my $elev_meters;
my $CCH_elevationInMeters;
my $elevationInMeters;
my $elevationInFeet;
my $minimumElevationInMeters;
my $maximumElevationInMeters;
my $minimumElevationInFeet;
my $maximumElevationInFeet;
my $verbatimLongitude;
my $verbatimLatitude;
my $TRS;
my $Township;
my $Range;
my $Section;
my $Fraction;
my $topo_quad;
my $UTME;
my $UTMN; 
my $zone;
my $habitat;
my $latitude;
my $lat_degrees;
my $lat_minutes;
my $lat_seconds;
my $decimalLatitude;
my $longitude;
my $decimalLongitude;
my $long_degrees;
my $long_minutes;
my $long_seconds;
my $datum;
my $errorRadius;
my $errorRadiusUnits;
my $coordinateUncertaintyInMeters;
my $coordinateUncertaintyUnits;
my $georeferenceSource;
my $associatedSpecies;	
my $associatedTaxa;
my $cultivated; #add this field to the data table for cultivated processing, place an "N" in all records as default
my $location;
my $localityDetails;
my $commonName;
my $occurrenceRemarks;
my $substrate;
my $plant_description;
my $phenology;
my $abundance;
my $notes;
#unique to this dataset
my $labelSubHeader;
my $lat_deg;
my $lat_min;
my $lat_sec;
my $long_deg;
my $long_min;
my $long_sec;
my $lat_hem;
my $long_hem;
my $tempCounty;
my $elevation_units;
my $bm;


$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8

	my @fields=split(/\t/,$_,100);

	unless($#fields==33){
		&log_skip("Fields should be 34; I count $#fields\t$_");
		next Record;
	}
#ACCESSION	COLLECTOR	COL_NUM	OTHR_COLLS	MONTH	DAY	DATE_YEAR	GENUS	SPECIFIC	VAR_SSP	INTRASPEC	DET_BY	SUBHEAD	LOCALITY	HABITAT	PLCHARS	COUNTY	ELEV	ELEV_UNIT	
#LAT_DEGN	LAT_MINN	LAT_SECN	LAT_HEMIS	LON_DEGN	LON_MINN	LON_SECN	LON_HEMIS	TWNSHP	RANGE	SEC	Quarter	BM	QUAD
($cultivated,
$id, 
$collector, 
$recordNumber, 
$other_coll, 
$coll_month, 
$coll_day, 
$coll_year, 
$genus, 
$species,  #10
$rank,	
$subtaxon,
$identifiedBy,
$labelSubHeader, #i.e. "Plants of $label_subhead". Generally not published
$locality,
$habitat,
$occurrenceRemarks, #called PLCHARS for plant characteristics
$tempCounty,
$elevation,
$elevation_units, #20
$lat_deg,	
$lat_min,
$lat_sec,
$lat_hem,
$long_deg,
$long_min,
$long_sec,
$long_hem,
$Township, #so far not processed
$Range,#30
$Section,
$Fraction,
$bm, #TRS meridian
$topo_quad #name of quad map
)=@fields;


################ACCESSION_ID#############
#check for nulls
if ($id=~/^ *$/){
	&log_skip("ACC: Record with no accession id $_");
	++$skipped{one};
	next Record;
}


#Remove duplicates
if($seen{$id}++){
	&log_skip("ACC: Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}


#####Annotations
	#format det_string correctly
my $det_orig_rank = "current determination (uncorrected)";  #set to text in data with only a single determination
my $det_orig_name = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;
my $det_orig_string;
my $det_identifier = $identifiedBy;
	
	if ((length($det_orig_name) > 1) && (length($det_identifier) > 1)){
		$det_orig_string="$det_orig_rank: $det_orig_name, $det_identifier";
	}
	elsif ((length($det_orig_name) > 1) && (length($det_identifier) == 0)){
		$det_orig_string="$det_orig_rank: $det_orig_name";
	}
	else{
		&log_change("DET: Bad det string\t$det_orig_rank: $det_orig_name, $det_identifier");
		$det_orig_string="";
	}


##############SCIENTIFIC NAME

#Format name parts
$genus=ucfirst(lc($genus));
$species=lc($species);
$subtaxon=lc($subtaxon);
$rank=lc($rank);

#construct full verbatim name
	foreach ($genus){
		s/NULL//g;
		s/^×/X /;
		s/^ +//g;
		s/ +$//g;
	}	
	foreach ($species){
		s/NULL//g;
		s/^ +//g;
		s/ +$//g;
	}	
	foreach ($rank){
		s/NULL//g;
		s/^ +//g;
		s/ +$//g;
	}	
	foreach ($subtaxon){
		s/NULL//g;
		s/^ +//g;
		s/ +$//g;
	}

my $tempName = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;


#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($tempName){
	s/NULL//gi;
	s/[uU]nknown//g; #added to try to remove the word "unknown" for some records
	s/;//g;
	s/cf.//g;
	s/ [xX××] / X /;	#change  " x " or " X " to the multiplication sign
	s/× /X /;	#change  " x " in genus name to the multiplication sign
	s/;$//g;
	s/No name/ /g;
	s/[uU]nknown/ /g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}


#format hybrid names
if($tempName =~ m/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation = $tempName;
	warn "Hybrid Taxon: $1 removed from $tempName\n";
	&log_change("Hybrid Taxon: $1 removed from $tempName");
	$tempName=$1;
}
else{
	$hybrid_annotation="";
}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames


if (($id =~ m/^(CDA8134)$/) && (length($TID{$tempName}) == 0)){ 
#CDA8134	T.C. Fuller	434-58		May	21	1958	Layia	chrysanthemoides	 var. 	oligochaeta	T.C. Fuller		2 miles north of Novato. 			Marin																
	$tempName =~ s/Layia chrysanthemoides var\. oligochaeta/Layia chrysanthemoides/;
	&log_change("Scientific name not published: Layia chrysanthemoides var. oligochaeta, probably previously determined as Layia calliglossa var. oligochaeta and annotated without updating subtaxon, modified to to just the species rank:\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CDA5477)$/) && (length($TID{$tempName}) == 0)){ 
#CDA5477	G.D. Barbe	2484		Apr	10	1979	Anagallis	arvensis	 f.	azurea			Point Reyes National Seashore.  Along road to Coast Camp from Limantour Parking Lot. 		Locally common with the coral-colored form. [=A. a. var. coerulea Ledeb.]	Marin																
	$tempName =~ s/Anagallis arvensis f\. azurea/Anagallis arvensis/;
	&log_change("Scientific name not published: Anagallis arvensis f. azurea, not a published form name, modified to just the species rank:\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CDA28907)$/) && (length($TID{$tempName}) == 0)){ 
#CDA28907	D.G. Kelch	9.369		Jun	9	2009	Deinandra	pungens				East SF Bay.	Union City, nr intersection of Horner and Veasy Sts in waste areas near diked salt marsh.		Local roadside annual w/ Malva spp., Distichlis spicata, Convolvulus arvensis, & Malvella leprosa. Fls yellow.	Alameda	2	meters	37	35	44.48	N	122	5	25.02	W						
	$tempName =~ s/Deinandra pungens/Centromadia pungens/;
	&log_change("Scientific name not published: Deinandra pungens, not a published combination, modified to:\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CDA3026)$/) && (length($TID{$tempName}) == 0)){ 
#CDA3026	A.C. Sanders	23685	Mitch Provance	Oct	1	2000	Chenopodium	album	 var. 	mediterraneum	S. E. Clemants	San Bernardino Mtns.	Hwy 330 at turnout 4.3 miles above City Creek Station, 4.2 mi. below W end of Fredalba Rd., slopes above Little Mill Creek	Burned chaparral (except patches) w/Quercus wislizenii, Arctostaphylos, Pinus attentuata, Turricula p., etc.	Fairly common annual on loose roadside fill; 0.5-1.5 m tall.  Erect central axis w/ green stripes; basal branches spreading then ascending, upper all ascending; infl. branches somewhat drooping.  Flowers green.  Determined by Clemants as C. album cf. var. mediterraneum Aellen, not in IPNI.	San Bernardino	1235	meters	34	11.88		N	117	8.78		W	1N	3W	12			Harrison Mtn. 7.5’ Q.
	$tempName =~ s/Chenopodium album var\. mediterraneum/Chenopodium album/;
	&log_change("Scientific name not published: Chenopodium album var. mediterraneum, modified to just the species rank:\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CDA27432)$/) && (length($TID{$tempName}) == 0)){ 
#CDA27432	G.D. Barbe	3002	J.T. Howell, T.C. Fuller	Jul	16	1980	Lupinus	elatus	 ssp. 	elatus		Kern Plateau	North and below crest of west-northwest ridge from Bald Mountain summit (lookout tower).			Tulare	2805	meters														
	$tempName =~ s/Lupinus elatus ssp\. elatus/Lupinus elatus/;
	&log_change("Scientific name not published: Lupinus elatus ssp. elatus, not a published combination, modified to just the species rank:\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CDA43219)$/) && (length($TID{$tempName}) == 0)){ 
#CDA43219	David B. Dunn, LeDoux & Keeney	20719a		Jun	11	1973	Lupinus	formosus	 ssp. 	proximus	Melvin L. Conrad		Along the Lockwood Valley Road, 3 miles west and south of Kern County line.	In a grove of pinyon pines.		Ventura	1677	meters														
	$tempName =~ s/Lupinus formosus ssp\. proximus/Lupinus formosus/;
	&log_change("Scientific name not published: Lupinus formosus ssp. proximus, not a published combination, modified to just the species rank:\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CDA1547|CDA1546)$/) && (length($TID{$tempName}) == 0)){ 
#CDA1547	E.C. Whitney	s.n.		Jun	3	1971	Cirsium	remotifolium	 var. 	mendocinum	David J. Keil		Bear River Ridge County roadside, Johnson Corrals, NE of Capetown.	County roadside.	In bud, county roadside near Johnson Corrals.(Label states “Sec. 10”, in error. Corral is in Sec. 8, road runs Sec. 9- Sec.16)Cirsium remotifolium var. mendocinum (Petrak) Keil,Annotated by David J. Keil, Flora of North America, 2002.	Humboldt	366	meters	40	28	36	N	124	18	40	W	1N	2W	8		H	
	$tempName =~ s/Cirsium remotifolium var\. mendocinum/Cirsium remotifolium/;
	&log_change("Scientific name not published: Cirsium remotifolium var. mendocinum, not a published combination, modified to just the species rank:\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CDA6710|CDA6711|CDA6712|CDA6713|CDA6714|CDA6715)$/) && (length($TID{$tempName}) == 0)){ 
#N	CDA6710	T.C. Fuller	12815		Nov	6	1964	Citrullus	colocynthis	 var. 	citroides	G.D. Barbe		2.5 miles northwest of Holt. 	In sandy soil on levee above maize and asparagus fields. 	Abundant. 	San Joaquin			37	57	33.5	N	121	23	40.9	W						
	$tempName =~ s/Citrullus colocynthis var\. citroides/Citrullus lanatus var. citroides/;
	&log_change("Scientific name not published: Citrullus colocynthis var. citroides, not a published combination, modified to just the species rank:\t$tempName\t--\t$id\n");
}

##########Begin validation of scientific names



#####process taxon names

$scientificName=&strip_name($tempName);
$scientificName=&validate_scientific_name($scientificName, $id);



#####process cultivated specimens			
# flag taxa that are known cultivars that should not be added to the Jepson Interchange, add "P" for purple flag to Cultivated field	


## regular Cultivated parsing

	if ($cultivated !~ m/^P$/){
		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("CULT: specimen likely not cultivated, purple flagging skipped\t$scientificName\t--\t$id\n");
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($habitat =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental\.|ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("CULT: Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
#add exceptions here to the CCH cultivated routine on a specimen by specimen basis
		elsif (($id =~ m/^(CDA23144)$/) && ($scientificName =~ m/Ozothamnus diosmifolius/)){
			&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location  (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
		$cultivated = "";
		}
#Check remaining specimens for status with CCH cultivated routine		
		else {		
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			#&log_change("Taxon skipped purple flagging (1) $cultivated\t--\t$scientificName\n");
			$cultivated = "";
			}
		}
	}
	else {
		&log_change("CULT: Taxon flagged as cultivated in original database: $cultivated\t--\t$scientificName\n");
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
foreach ($coll_year){
	s/before 1920//g;
	s/\?$//g;
	s/s$//g;
}

foreach ($coll_day){
	s/late//g;
	s/'//g;
	s/,//g;
	s/0+//g;    

}


$eventDateAlt = $coll_year."-".$coll_month."-".$coll_day;

#assemble a date for a correctly formatted verbatim date
	if ((length($coll_day) == 0) && (length($coll_month) >= 1) && (length($coll_year) >= 2)){
		$verbatimEventDate = $coll_month." ".$coll_year;
	}
	elsif ((length($coll_day) >= 1) && (length($coll_month) >= 1) && (length($coll_year) == 0)){
		$verbatimEventDate = $coll_day." ".$coll_month." [year missing]";
		warn "(1) date missing year==>$verbatimEventDate\t$id";
	}	
	elsif ((length($coll_day) >= 1) && (length($coll_month) >= 1) && (length($coll_year) >= 2)){
		$verbatimEventDate = $coll_day." ".$coll_month." ".$coll_year;
	}	
	elsif ((length($coll_day) >= 1) && (length($coll_month) == 0) && (length($coll_year) >= 2)){
		$verbatimEventDate = $coll_day." [month missing] ".$coll_year;
		warn "(2) date missing month==>$verbatimEventDate\t$id";
	}
	elsif ((length($coll_day) == 0) && (length($coll_month) == 0) && (length($coll_year) >= 2)){
		$verbatimEventDate = $coll_year;
	}
	elsif ((length($coll_day) == 0) && (length($coll_month) == 0) && (length($coll_year) == 0)){
		$verbatimEventDate="";
	}
	else{
		&log_change("DATE: problem, missing or incompatible values==>day: $coll_day\tmonth: $coll_month\tyear: $coll_year\t$id\n");
		$verbatimEventDate="";
	}


#finish parsing the modified event date

foreach ($eventDateAlt){
	s/`//g;	
	s/,//g;
	s/^-+//; #remove added dashes for the dates without a day value or month value
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
	elsif($eventDateAlt=~/^([0-9]{4})-(\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	warn "(1a)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{4})-([A-Za-z]+)-(\d\d?)/){	#if eventDate is in the format ####-AAA-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1b)$eventDateAlt\t$id";
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
	warn "(22)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)-(June?|July?)[- ]$/){ #month, year, no day
		$YYYY = $1;
		$DD = "1";
		$MM = $1;
		$DD2 = "30";
		$MM2 = $2;
	warn "Date (7): $eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Z][a-z]+)[- ](June?|July?)[- ]([0-9]{4})$/){ #month, year, no day
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
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]([0-9]{4})$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(5)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Za-z]+)-$/){
		$DD = "";
		$MM = $2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
	#warn "(5a)$eventDateAlt\t$id";
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
	#warn "(18)$eventDateAlt\t$id";
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

	foreach ($collector, $other_coll){
		s/'$//g;
		s/, M\. ?D\.//g;
		s/, Jr\./ Jr./g;
		s/, Jr/ Jr./g;
		s/, Esq./ Esq./g;
		s/, Sr\./ Sr./g;
		s/  +/ /;
		s/^ *//;
		s/ *$//;
		
	}
	$other_collectors = ucfirst($other_coll);


if ((length($collector) > 1) && (length($other_collectors) > 1)){
	#$recordedBy = &CCH::validate_single_collector($collector, $id);
	$recordedBy = $collector;
	$verbatimCollectors = "$collector, $other_collectors";
	#warn "Names 1: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";}
}
elsif ((length($collector) > 1) && (length($other_collectors) == 0)){
	#$recordedBy = &CCH::validate_single_collector($collector, $id);
	$recordedBy = $collector;
	$verbatimCollectors = $collector;
	#warn "Names 2: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
}
elsif ((length($collector) == 0) && (length($other_collectors) > 1)){
	#$recordedBy = &CCH::validate_single_collector($other_collectors, $id);
	$recordedBy = $other_collectors;
	$verbatimCollectors = $other_collectors;
	&log_change("COLLECTOR: Collector name field missing, using other collector field\t$id\n");
}
elsif ((length($collector) == 0) && (length($other_collectors) == 0)){
	&log_change("Collector name fields NULL\t$id\n");
	$verbatimCollectors = $other_collectors = $recordedBy = "";
}	
else {
		&log_change("Collector name problem\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}

foreach ($verbatimCollectors){
	s/'$//g;
	s/  +/ /;
	s/^ *//;
	s/ *$//;
	
}


#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes
my $CNUM_suffix="";
($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);



####Country and State 
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

###########COUNTY###########

	foreach ($tempCounty){
	s/"//g;
	s/'//g;
	s/\//-/g;
	s/unknown/Unknown/;
	s/NULL/Unknown/;
	s/San Bernadino/San Bernardino/; #CCH.pm does not seem to fix this one in these data 
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	s/Playas [dD]e Rosarito/Rosarito, Playas de/g; 
}
#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);



#Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}
	
#validate county
		my $v_county;

	foreach ($county){ #for each $county value
        unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|Unknown)$/){
            $v_county= &verify_co($_); #Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
            if($v_county=~/SKIP/){ #If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
                &log_skip("COUNTY (2): NON-CA COUNTY?\t$_\t--\t$id"); #run the &skip function, printing the following message to the error log
                ++$skipped{one};
                next Record;
            }

            unless($v_county eq $_){ #unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
                &log_change("COUNTY (3): COUNTY $_ ==> $v_county--\t$id"); #call the &log function to print this log message into the change log...
                $_=$v_county; #and then set $county to whatever the verified $v_county is.
            }
        }
    }
    
    
    
my $verbatimCounty = "";
#format verbatim county properly
	if($county !~m/^$tempCounty$/){
		$verbatimCounty = $tempCounty;
	}
    
##########LOCALITY#########

foreach ($locality){
	s/NULL//;
	s/"/'/g;
	s/'$//g;
	s/^'//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
}

foreach ($labelSubHeader){
		s/'$//;
		s/  +/ /g;
		s/^ +//g;
		s/ +$//g;
}


if ((length($locality) > 1) && (length($labelSubHeader) > 1)){	#$recordedBy = &CCH::validate_single_collector($collector, $id);
	$location = "$labelSubHeader; $locality";

}
elsif ((length($locality) > 1) && (length($labelSubHeader) == 0)){
	$location = $locality;

}
elsif ((length($locality) == 0) && (length($labelSubHeader) > 1)){
	$location = $labelSubHeader;
	&log_change("LOCALITY: locality field NULL, using only subheader field==>$labelSubHeader\t$id\n");
}
elsif ((length($locality) == 0) && (length($labelSubHeader) == 0)){
	&log_change("LOCALITY: locality fields NULL\t$id\n");
	$location = "";
}	
else {
		&log_change("LOCALITY: locality field data problem==>($labelSubHeader)($locality)\t$id\n");
		$location = "";
}



###############ELEVATION########
foreach($elevation){
	s/~//g;
	s/,//g;
	s/\>//g;
	s/\<//g;
	s/±//g;
	s/\+//g;
	s/^ +//;
	s/ +$//;
	s/ //g;

	s/A-//g; #badly converted ±
}

foreach($elevation_units){
	s/,//g;
	s/`//g;
	s/`//g;
	s/'//g;
	s/^ +//;
	s/ +$//;
	s/ //g;
	s/\.//g;
}

$verbatimElevation = "$elevation $elevation_units";
my $elevationAlt;
my $elevationINT;
$elevationINT = int($elevation); #there are some elevations that are decimals in these data
$elevationAlt = "$elevationINT$elevation_units";

if (length($elevationAlt) >= 1){

	if ($elevationAlt =~ m/^(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevationAlt =~ m/^(-?[0-9]+)([fFtT]+)/){ #added <? to fix elevation in BLMAR421 being skipped
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevationAlt =~ m/^(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = $elevation;
		$CCH_elevationInMeters =~ s/m$/ m/;
	}
	elsif ($elevationAlt =~ m/^(-?0+ *[mMersfFtT]*)/){
		$elevationInMeters == 0;
		$elevationInFeet == 0; #make it an integer to remove false precision		
		$CCH_elevationInMeters = "0 m";
	}

	elsif ($elevationAlt =~ m/^[A-Za-z ]+(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevationAlt =~ m/^(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevationAlt =~ m/^(-?[0-9]+)-(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevationAlt =~ m/^[A-Za-z ]+(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevationAlt =~ m/^[A-Za-z]+(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("ELEV(1): calculated elevation '$elevationAlt'  has problematic formatting or is missing units==>$elevation\t$elevation_units\t$id");
		$elevationInFeet = $CCH_elevationInMeters = $elevationInMeters = "";
	}	
}
elsif (length($elevationAlt) == 0){
		$elevationInFeet = $CCH_elevationInMeters = $elevationInMeters = "";
}
else{
		&log_change("ELEV(2): calculated elevation '$elevationAlt' has problematic formatting or is missing units==>$elevation\t$elevation_units\t$id");
		$elevationInFeet = $CCH_elevationInMeters = $elevationInMeters = "";
}

#this code was originally in consort_bulkload.pl, but it was moved here so that the county elevation maximum test can be performed on these data, which consort_bulkload.pl does not do
#this being in consort_bulkload instead of here may be adding to elevation anomalies that have been found in records with no elevations
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
my $lat_sum;
my $long_sum;
my $Check;



#### TRS,

foreach ($Township){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;		
}
foreach ($Range){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;		
}
foreach ($Section){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;		
}
foreach ($Fraction){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;		
}

$TRS = $Township." ".$Range." ".$Section." ".$Fraction;


#########COORDS, DATUM, ER, SOURCE#########
my $lat_sum;
my $long_sum;
my $Check;
my $hold;

#######Latitude and Longitude

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

#long stadning problem here is that the database at CDA does not allow '0' as a value in a number field, so when the minutes are '0' the field is blank.  This leads to bad errors in the the conversion below.
# zero seconds are not really a problem because that should be equivalent to just degrees and minutes.
#zero degrees are an error for California coordinates
#this error is creating thousands of yellow flags

if ((length($lat_deg) >= 1) && (length($lat_min) == 0) && (length($lat_sec) >= 1)){
	$lat_min = "0";
	$verbatimLatitude = $lat_deg," ",$lat_min," ",$lat_sec;
	warn "NULL value for lat minutes found, converting to a value of '0': $verbatimLatitude ($lat_deg)\t($lat_min)\t($lat_sec)\n";
}
elsif ((length($lat_deg) >= 1) && (length($lat_min)>= 1) && (length($lat_sec) >= 1)){
	$verbatimLatitude = $lat_deg." ".$lat_min." ".$lat_sec;
}
elsif ((length($lat_deg) >= 1) && (length($lat_min)>= 1) && (length($lat_sec) == 0)){
	$verbatimLatitude = $lat_deg." ".$lat_min;
}
else {
		&log_change("COORDINATE: Latitude not mappable, null values present==>($lat_deg)\t($lat_min)\t($lat_sec)\n");
	$verbatimLatitude = "";
}

if ((length($long_deg) >= 1) && (length($long_min) == 0) && (length($long_sec) >= 1)){
	$long_min = "0";
	$verbatimLongitude = $long_deg." ".$long_min." ".$long_sec;
	warn "NULL value for lat minutes found, converting to a value of '0': $verbatimLongitude ($long_deg)\t($long_min)\t($long_sec)\n";
}
elsif ((length($long_deg) >= 1) && (length($long_min)>= 1) && (length($long_sec) >= 1)){
	$verbatimLongitude = $long_deg." ".$long_min." ".$long_sec;
}
elsif ((length($long_deg) >= 1) && (length($long_min)>= 1) && (length($long_sec) == 0)){
	$verbatimLongitude = $long_deg." ".$long_min;
}
else {
		&log_change("COORDINATE: Longitude not mappable, null values present==>($long_deg)\t($long_min)\t($long_sec)\n");
	$verbatimLongitude = "";
}



foreach ($verbatimLatitude, $verbatimLongitude){
		s/ø/ /g;
		s/\xc3\xb8/ /g; #decimal byte representation for ø
		s/'/ /g;
		s/;/ /g;
		s/"/ /g;
		s/’/ /g;
		s/”/ /g;
		s/,/ /g;
		s/deg./ /g;
		s/^ +//g;
		s/^"//g;
		s/"$//g;
		s/""//g;
		s/[°¡]//g;
		s/N//g;
		s/W//g;
		s/  +/ /;
		s/^ +//;
		s/ +$//;
	
}

	if (($verbatimLatitude =~ m/^-?1\d\d\./) && ($verbatimLongitude =~ m/^\d\d\./)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		print "COORDINATE 2 $id\n";
		&log_change("COORDINATE (2) decimals apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d +\d/) && ($verbatimLongitude =~ m/^\d\d +\d/)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		print "COORDINATE 3 $id\n";
		&log_change("COORDINATE (3) apparently reversed, switching latitude with longitude\t$id");
	}	
	elsif (($verbatimLatitude =~ m/^-?1\d\d$/) && ($verbatimLongitude =~ m/^\d\d/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 4 $id\n";
		&log_change("COORDINATE (4) longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d/) && ($verbatimLongitude =~ m/^\d\d$/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 5 $id\n";
		&log_change("COORDINATE (5) longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^\d\d\./) && ($verbatimLongitude =~ m/^-?1\d\d\./)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
			#print "COORDINATE 6a $id\n";
	}
	elsif (($verbatimLatitude =~ m/^\d\d \d/) && ($verbatimLongitude =~ m/^-?1\d\d \d/)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
			#print "COORDINATE 6b $id\n";
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
		#print "COORDINATE NULL $id\n";
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
		s/^\s$//;
}	


#fix some problematic records with bad latitude and longitude in home database
if (($id =~ m/^(CDA42382)$/) && ($verbatimLongitude =~ m/119[ .]+/)){ 
	$latitude = "39.815";
	$longitude = "-121.4748";
	$georeferenceSource = "DMS conversion by CCH loading script"
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) does not map within boundary of county and/or state on the label, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
	#the original is in error and maps Nevada, W of Reno 39	27	48.6	N	119	52	58.1	W
}

if (($id =~ m/^(CDA43423|CDA42423|CDA42424|CDA42421|CDA42422|CDA42425|CDA43419)$/) && ($verbatimLongitude =~ m/119[ .]+/)){ 
	$latitude = "39.7933";
	$longitude = "-121.4535";
	$georeferenceSource = "DMS conversion by CCH loading script"
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) does not map within boundary of county and/or state on the label, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
	#the original is in error and maps Nevada, W of Reno 39	27	48.6	N	119	52	58.1	W
}


#use combined Lat/Long field format for CDA

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
					&log_change("COORDINATE 1) Latitude problem, set to null,\t$id\t$verbatimLatitude\n");
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
					#print "2d) $decimalLatitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($latitude =~ m/^(\d\d\.\d+)/){
				$lat_degrees = $1;
				if($lat_degrees > 90){
					&log_change("COORDINATE 3) Latitude problem, set to null,\t$id\t$lat_degrees\n");
					$lat_degrees=$latitude=$decimalLatitude="";		
				}
				else{
					$decimalLatitude=sprintf ("%.6f",$lat_degrees);
					#print "3a) $decimalLatitude\t--\t$id\n";
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
				#print "6d) $decimalLongitude\t--\t$id\n";
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
					#print "7a) $decimalLongitude\t--\t$id\n";
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
#UTM is not present in these data, skipping conversion of UTM and reporting if there are cases where lat/long is problematic only
		&log_change("COORDINATE: No coordinates for $id\n");
		$decimalLatitude = $decimalLongitude = $georeferenceSource = $datum = "";
}
else {
			&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = $datum = "";
}


##check Datum
if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	#$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
#$coordinateUncertaintyInMeters none in these data
#$UncertaintyUnits none in these data


	if ($datum){
		s/WGS 1984/WGS84/g;
		s/NAD 1927/NAD27/;
		s/NAD 1983/NAD83/g;
		s/  +/ /g;
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

foreach ($occurrenceRemarks){
		s/'$//;
		s/  +/ /g;
		s/^ +//g;
		s/ +$//g;
}



#######Habitat and Assoc species (dwc habitat and associatedTaxa)

#free text fields

foreach ($habitat){
		s/'$//;
		s/  +/ /g;
		s/^ +//g;
		s/ +$//g;
}



#print out the final printout
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
Location: $location
Habitat: $habitat
T/R/Section: $TRS
USGS_Quadrangle: $bm  $topo_quad
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance:
Max_error_units:
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $verbatimCounty
Notes: $occurrenceRemarks
Cultivated: $cultivated
Hybrid_annotation: $hybrid_annotation
Annotation: $det_orig_string

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


    my $file_in = '/JEPS-master/CCH/Loaders/CDA/CDA_out.txt';	#the file this script will act upon is called 'CATA.out'
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
