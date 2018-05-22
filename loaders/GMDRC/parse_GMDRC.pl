
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


open(OUT,">GMDRC_out.txt") || die;


my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;
my %ANNO;

my $file = 'CCHexport03FEB2017b.txt';


#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


open(IN,$file ) || die;



Record: while(<IN>){
	chomp;
	
	$line_store=$_;
	++$count;


#fix some data quality and formatting problems that make import of fields of certain records impossible

	s/\0//g;
	s/\x00//g; #remove null bytes	
	s/var\. c\.f elongatum/var. elongatum/g; #fix a badly formatted name
	s/°/ deg. /g;
	s/…/, /g;
	s/“/'/g;
	s/’/'/g;
	s/“/'/g;
	s/”/'/g;
	s/  +/ /g;


#        if ($. == 1){#activate if need to skip header lines
#			next;
#		}	
			
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
my $name;
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
my $Fraction_of_section;
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
my $plant_description;
my $phenology;
my $abundance;
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
my $Collector_First_Name;
my $Collector_Last_Name;
my $identificationQualifier;
my $current_annotation;
my $previousDeterminations;
my $lat_deg;
my $lat_min;
my $lat_sec;
my $long_deg;
my $long_min;
my $long_sec;
my $det_prev;

	my @fields=split(/\t/,$_,100);
	
    	 
		unless($#fields==34){  #35 fields but first field is field 0 in perl
			&log_skip("$#fields bad field number $_");
			next Record;
		}



#then process the full records
($cultivated,
$id,
$name, # species name
$identificationQualifier, # Qualifier
$previousDeterminations, # AnnotationNotes
$TRS, # TRS Comb
$identifiedBy, #Identified By
$dateIdentified, #Ident Year
$stateProvince, #State
$recordNumber, #Collection #
$Collector_First_Name, #Collector First Name  #10
$Collector_Last_Name, #Collector Last Name
$tempCounty,
$topo_quad, #GeoreferenceResources
$coll_month,
$coll_day,
$coll_year,
$other_coll, 
$datum, #Datum
$locality, #SEINet Locality
$lat_deg, #Latitude    #20
$lat_min, #Latitude2; decimal minutes and integer
$lat_sec, #Latitude3; present only when minutes is an integer
$long_deg, #Longitude; needs to be made negative
$long_min, #Longitude2; decimal minutes and integer
$long_sec, #Longitude3; present only when minutes is an integer
$zone, #UTM Zone
$UTMN,
$UTME,
$habitat,
$associatedTaxa, #Assoc Spec   #30
$elev_meters, #Elevation in meters
$notes, #usually abundance, but sometimes "Other Notes")
$substrate, #SEINet substrate
$phenology
) = @fields;

################ACCESSION_ID#############
#check for nulls, remove '-' from ID
unless($id=~/^GMDRC\d/){
	&log_skip("No GMDRC accession number, skipped: $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space
foreach($id){
	s/^GMDRC0+/GMDRC/g;
	s/  +/ /;
	s/^ +//g;
	s/ +$//g;
}


#Add prefix 
#skip


#Remove duplicates
if($seen{$fields[1]}++){
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	next Record;
}

#####Annotations  (use when no separate annotation field)
	#format det_string correctly
my $det_rank = "current determination (uncorrected)";  #set to zero in data with only a single determination
my $det_name = $name;
my $det_determiner = $identifiedBy;
my $det_date = $dateIdentified;
my $det_stet = $identificationQualifier;	
	
	if ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) >=1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet";
		print "$det_string\n";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet, $det_determiner";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) >=1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_date";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) >=1)){
		$det_string="$det_rank: $det_name, $det_date";
	}
	else{
		$det_string="$det_rank: $det_name $det_stet, $det_determiner,  $det_date";
	}

	if (length($previousDeterminations) >= 1){
		$det_prev="1: $previousDeterminations";
	}
	else{
		$det_prev="";
	}

##########Begin validation of scientific names

###########SCIENTIFICNAME
#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($name){
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
	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
	}

#format hybrid names
if($name=~m/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation=$name;
	warn "Hybrid Taxon: $1 removed from $name\n";
	&log_change("Hybrid Taxon: $1 removed from $name");
	$name=$1;
}
else{
	$hybrid_annotation="";
}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published
if (($id =~ m/^GMDRC3802$/) && ($name =~ m/Aliciella monoensis subsp. brecciarum/)){ 
	$name =~ s/Aliciella monoensis subsp. brecciarum/Aliciella monoensis/;
	&log_change("Scientific name not published: Aliciella monoensis subsp. brecciarum, modified to just species:\t$name\t--\t$id\n");
}
if (($id =~ m/^GMDRC3382$/) && ($name =~ m/Penstemon albomarginatus var. floridus/)){ 
	$name =~ s/Penstemon albomarginatus var. floridus/Penstemon floridus var. floridus/;
	&log_change("Scientific name not published: Penstemon albomarginatus var. floridus, probably a typo, species assumed to be P. floridus and not P. albomarginatus:\t$name\t--\t$id\n");
}
if (($id =~ m/^GMDRC4730$/) && ($name =~ m/Tauschia parishii var. californicus/)){ 
	$name =~ s/Tauschia parishii var. californicus/Tauschia parishii/;
	&log_change("Scientific name not published: Tauschia parishii var. californicus, modified to just species:\t$name\t--\t$id\n");
}
if (($id =~ m/^(GMDRC6862|GMDRC6877)$/) && ($name =~ m/Cryptantha lepida/)){ 
	$name =~ s/Cryptantha lepida/Cryptantha/;
	&log_change("Scientific name not published: Cryptantha lepida, modified to just genus:\t$name\t--\t$id\n");
}


#####process taxon names

$scientificName = &strip_name($name);

$scientificName = &validate_scientific_name($scientificName, $id);


#####process cultivated specimens			
# flag taxa that are known cultivars that should not be added to the Jepson Interchange, add "P" for purple flag to Cultivated field	

## regular Cultivated parsing
		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("specimen likely not cultivated, purple flagging skipped: $scientificName\t--\t$id\n");
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($habitat =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental\.|ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
		elsif ($cultivated =~ m/N/){
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			#&log_change("Taxon skipped purple flagging: $cultivated\t--\t$scientificName\n");
			$cultivated = "";
			}
		}

###############DATES###############
my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;
my $eventDateAlt;

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



$eventDateAlt = $coll_day."-".$coll_month."-".$coll_year ;

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



	foreach ($Collector_First_Name){
		s/'$//g;
		s/^ *//g;
		s/ *$//g;
		s/  +/ /g;
	}
	foreach ($Collector_Last_Name){
		s/'$//g;
		s/^ *//;
		s/ *$//;
		s/  +/ /g;
#this is sometimes not removing Andre with an e as a special character. 
#remports as s/\xc3\xa9/    /g   √© ---> Andr√© in accent_detector 
#It is proving to be resistent to removal by normal 
#must remove manually in text file before each upload if this persists
#also check for errors in the collectors name file

	}	
	foreach ($other_coll){
		s/"//g;
		s/'$//g;
		s/^ *//;
		s/ *$//;
		s/  +/ /g;
	}	
	
	
	$collector = "$Collector_First_Name $Collector_Last_Name";
	$other_collectors = ucfirst($other_coll);
		if ($collector =~ m/^ +Andr..?$/){ #fix a specific error where there is nothing in Collector_First_Name	
			$collector = "J. Andre";
		}

if ((length($collector) > 1) && (length($other_collectors) > 1)){	
	$recordedBy = &CCH::validate_single_collector($collector, $id);
	$verbatimCollectors = "$collector, $other_collectors";
	#warn "Names 1: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
}
elsif ((length($collector) > 1) && (length($other_collectors) == 0)){
	$collector = ucfirst($collector);
	$recordedBy = &CCH::validate_single_collector($collector, $id);
	$verbatimCollectors = "$collector";
	#warn "Names 2: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
}
elsif ((length($collector) == 0) && (length($other_collectors) > 1)){
	$recordedBy = &CCH::validate_single_collector($other_collectors, $id);
	$verbatimCollectors = $other_collectors;
	&log_change("COLLECTOR: Collector name field missing, using other collector field\t$id\n");
}
else {
		&log_change("Collector name problem\t$id\n");
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


####Country and State 
$country = "USA";


foreach($stateProvince){#for each $county value
	s/california/California/;
	s/CALIFORNIA/California/;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

###########COUNTY###########

foreach($tempCounty){#for each $county value
	s/"//g;
	s/'//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;

	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries

}

$county=&CCH::format_county($tempCounty,$id);


######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}

##############validate county
my $v_county;

foreach($county){

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

foreach ($locality){
	s/"/'/g;
	s/'$//g;
	s/^'//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
	
}

###############ELEVATION########
foreach($elev_meters){
	s/'$//g;
	s/~//g;
	s/,//g;
	s/\>//g;
	s/\<//g;
	s/±//g;
	s/\+//g;
	s/^ +//;
	s/ +$//;
	s/ //g;
	s/\.//g;
	s/^ +//;
	s/ +$//;
	s/  +/ /;
}


if (length($elev_meters) >= 1){

	if ($elev_meters =~ m/^(-?[0-9]+)$/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$elevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$elev_meters' not numeric\t$id");
		$elevationInFeet = $CCH_elevationInMeters = $elevationInMeters="";
	}	
}
else {
	$CCH_elevationInMeters = "";
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
		&log_change ("ELEV\t$county:\t $elevation_test ft. ($elevationInMeters m.) greater than $county maximum ($max_elev{$county} ft.): discrepancy=", (($elevation_test)-$max_elev{$county}),"\t$id\n");
		if ((($elevation_test)-$max_elev{$county}) >= 500 ){
			$CCH_elevationInMeters = "";
			&log_change ("ELEV\t$county: discrepancy=", (($elevation_test)-$max_elev{$county})," greater than 500 ft, elevation changed to NULL\t$id\n");
		}
	}



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



##############TRS
foreach($TRS){
	s/NULL//;
	s/,/ /g;
	s/\./ /g;
	s/[Ss]ecf/Sec/g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;

}

foreach($topo_quad){
	s/NULL//;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;

}

#######Latitude and Longitude
###make verbatim fields from separate fields


foreach ($UTMN, $UTME){
		s/,//;
		s/^0+//g; #remove leading zeros
		s/  +//g;
		s/^ +//g;
		s/ +$//g;
		}

$verbatimLatitude = $lat_deg." ".$lat_min." ".$lat_sec;

$verbatimLongitude = $long_deg." ".$long_min." ".$long_sec;


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
	else {
		&log_change("COORDINATE: Coordinate conversion problem for $id\t$verbatimLatitude\t--\t$verbatimLongitude\n");
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}


#NULL coordinates that are only integer degrees, these are highly inaccurate and not useful for mapping
	if (($verbatimLatitude =~ m/^\d\d$/) || ($verbatimLongitude =~ m/^-?1\d\d$/)){
		$decimalLatitude=$latitude = "";
		$decimalLongitude=$longitude = "";
		&log_change("COORDINATE decimal Lat/Long only to degree, now NULL: $verbatimLatitude\t--\t$verbatimLongitude\n");
	}



foreach ($latitude, $longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s$//;
}	


#use combined Lat/Long field format for GMDRC

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
					print "2d) $decimalLatitude\t--\t$id\n";
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
elsif ((length($latitude) == 0) || (length($longitude) == 0)){ 
#changed to OR in this dataset, some have blanks but UTMS are present
		#process zone fields
		if ((length($UTME) >5 ) && (length($UTMN) >5 )){
			&log_change("COORDINATE 10) Lat & Long null but UTM is present, checking for valid coordinates: $UTME, $UTMN, $zone, $id\n");
		
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
				&log_change("COORDINATE 11a) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone, $id\n");
				$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
			}

			if (($UTME > 0) && ($UTMN > 0)) {
				($decimalLatitude,$decimalLongitude)=utm_to_latlon(23,$zone,$easting,$northing);
				&log_change("Decimal degrees derived from UTM for $id: $decimalLatitude, $decimalLongitude");
				$georeferenceSource = "UTM to Lat/Long conversion by CCH loading script";
				$datum = "WGS84";
			}
		}
		elsif ((length($UTME) == 0) && (length($UTMN) == 0)){
				$easting = $northing = "";
		}
		else{
				&log_change("COORDINATE 11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone, $id\n");
				$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
		}
}
elsif(($latitude==0) && ($longitude==0)){
		$decimalLatitude = $decimalLongitude = $georeferenceSource = $datum = "";
		&log_change("COORDINATE coordinates entered as '0', changed to NULL $id\n");
}
else {
			&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
}



#check datum
if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	$coordinateUncertaintyInMeters="30";
	$coordinateUncertaintyUnits="m"; ###30 m according to Tasha La Doux's GPS
	$georeferenceSource="GPS (DMS/UTM conversion by CCH loading script)";

	if ($datum){ #report is datum is present
		s/  +/ /g;
		s/^ *//g;
		s/ *$//g;
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

#######Plant Description (dwc ??) and Phenology (dwc occurrenceRemarks)


foreach ($phenology){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/^ *//g;
		s/  +/ /g;
}


#######Habitat and Assoc species (dwc habitat and associatedTaxa)

#free text fields

foreach ($habitat){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/^ *//g;
		s/  +/ /g;
}

foreach ($associatedTaxa){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/with / /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
}


###ABUNDANCE FROM NOTES

	if($notes =~ m/^([aA]bundance:.*)[;,.] +([oO]ther [nN]otes:.* +[iI]mpacts:.*)/){
		$occurrenceRemarks = $2;
		$abundance = $1;
	}
	elsif($notes =~ m/^([aA]bundance:.*)[;,.] +([oO]ther [nN]otes:.*)/){
		$occurrenceRemarks = $2;
		$abundance = $1;
	}
	elsif($notes =~ m/^([aA]bundance:.*)[;,.] +([iI]mpacts:.*)/){
		$occurrenceRemarks = $2;
		$abundance = $1;
	}
	elsif($notes =~ m/^([iI]mpacts:.*)/){
		$occurrenceRemarks = $1;
		$abundance = "";
	}
	elsif($notes =~ m/^([oO]ther [nN]otes:.*)/){
		$occurrenceRemarks = $1;
		$abundance = "";
	}
	else {
		$occurrenceRemarks = "";
		$abundance = "";
	}

foreach ($occurrenceRemarks){
	s/"/'/g;
	s/'$//g;
	s/^'//g;
	s/^ *//g;
	s/  +/ /g;
}
foreach ($abundance){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/  +/ /g;
}

foreach ($substrate){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
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
Associated_species: $associatedTaxa
T/R/Section: $TRS
USGS_Quadrangle: $topo_quad
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Lat_long_ref_source: $georeferenceSource
Datum: $datum
Max_error_distance: $coordinateUncertaintyInMeters
Max_error_units: $coordinateUncertaintyUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Physical_environment: $substrate
Phenology: $phenology
Population_biology: $abundance
Notes: $occurrenceRemarks
Hybrid_annotation: $hybrid_annotation
Cultivated: $cultivated
Annotation: $det_string
Annotation: $det_prev

EOP

#add one to the count of included records
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


    my $file_in = 'GMDRC_out.txt';	#the file this script will act upon is called 'CATA.out'

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


