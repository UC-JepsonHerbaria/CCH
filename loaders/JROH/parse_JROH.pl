
use Geo::Coordinates::UTM;
use strict;
#use warnings;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.

$today_JD = &get_today_julian_day;
my $today=`date "+%Y-%m-%d"`;
warn "today is $today ($today_JD)";
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;

open(OUT,">JROH_out.txt") || die;
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;
my $det_prev;


my $file = 'ConsortiumUpdate9Jan2018_mod.txt';

#####process the file
#JROH file arrives as a tab delimited txt
#Then open in TextWrangler and make sure to save as UTF-8 with Unix line breaks
###############

open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	
	$line_store=$_;
	++$count;


#fix some data quality and formatting problems that make import of fields of certain records impossible
	
#fix some data quality and formatting problems that make import of fields of certain records problematic
		s/\xe2\x80\x99/'/g;
		s/+//g;
	
	
#	&CCH::check_file;
#		s/\cK/ /g;
#        if ($. == 1){#activate if need to skip header lines
#			next;
#		}	
				
my $id;
my $country;
my $stateProvince;
my $county;
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
my $associatedTaxa;
my $cultivated; #add this field to the data table for cultivated processing, place an "N" in all records as default
my $location;
my $localityDetails;
my $commonName;
my $occurrenceRemarks;
my $substrate;
my $plant_description; #i these data, Macromorphology and/or abundance, some phenology
my $phenology;
my $abundance; 
my $notes;
#unique to this dataset
my $annotation;  #$hybridFormula,
my $id;
my $collString; #combination of collector, number, and date. Redundant with other fields so is not processed

	

my @fields=split(/\t/,$_,100);
		unless($#fields==18){ #19 fields but first field is field 0 in perl
		&log_skip("$#fields bad field number $_\n");
		++$skipped{one};
		next Record;
	}

	
#then process the full records		
($cultivated,
$annotation,
$id,
$name,
$verbatimCollectors,
$verbatimEventDate,
$recordNumber,
$county,
$locality,
$verbatimElevation, #10
$collString, #combination of collector, number, and date. Redundant with other fields so not processed
$habitat,
$verbatimLatitude,
$verbatimLongitude,
$datum,
$errorRadius,
$georeferenceSource,  #$hybridFormula, field no longer in output?
$plant_description, #Macromorphology and/or abundance, $voucherInfo
$associatedTaxa)=@fields; #9


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
	s/^ *//g;
	s/ *$//g;
}

#Add prefix, 
$id="JROH$id";

#Remove duplicates
if($seen{$id}++){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}


#####Annotations  (use when no separate annotation field)
	#format det_string correctly
my $det_rank = "current determination (uncorrected)";  #set to zero in data with only a single determination
my $det_name = $name;
my $det_determiner;
my $det_date;
my $det_stet;	
	
	if ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) >=1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet";
		print $det_string;
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

	if (length($annotation) >= 1){
		$det_prev="1: $annotation";
	}
	else{
		$det_prev="";
	}



##########Begin validation of scientific names
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


#####process taxon names

$scientificName = &strip_name($name);

$scientificName = &validate_scientific_name($scientificName, $id);

#####process cultivated specimens			
# flag taxa that are known cultivars that should not be added to the Jepson Interchange, add "P" for purple flag to Cultivated field	


## regular Cultivated parsing

		if ($locality =~ m/(uncultivated|naturalizing|naturalized|cultivated fields?|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("specimen likely not cultivated, purple flagging skipped: $scientificName\t--\t$id\n");
		}
		elsif (($locality =~ m/(cultivated native|cultivated from|cultivated plants|cultivated at |cultivated in |cultivated hybrid|under cultivation|in cultivation|Oxford Terrace Ethnobotany|Internet purchase|artificial hybrid|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection)/i) || ($habitat =~ m/(cultivated from|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
		
		elsif ($cultivated !~ m/^P$/){		
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
		
##########COLLECTION DATE##########
my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;
my $formatEventDate;
my $eventDateAlt;


$eventDate = ucfirst($verbatimEventDate);

foreach ($eventDate){
	s/^ *//g;
	s/  +/ /g;
	s/No date//g;
	s/Unspecified//g;
	s/Unknown//g;
	s/No date given//g;
	s/None given//g;
	s/\//-/g;
	s/\?//g;
	s/about //i;
	s/^ $//g;	
	}

$eventDateAlt = $eventDate;

	if($eventDateAlt=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	warn "(1)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^(\d\d)-(\d\d)-([0-9]{4})/){	#added to SDSU,JROH, if eventDate is in the format ##-##-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(2)$eventDateAlt\t$id";
	}
		elsif($eventDateAlt=~/^(\d\d)-(\d)-([0-9]{4})/){	#added to JROH, if eventDate is in the format ##-#-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(2b)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{1})-([0-9]{1,2})-([0-9]{4})/){	#added to SDSU,JROH, if eventDate is in the format #-##?-####, most appear that first # is month 
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(3)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([0-9]{1,2}) ([A-Za-z]+) ([0-9]{4})/){
		$DD=$1;
		$MM=$2;
		$YYYY=$3;
		$MM2 = "";
		$DD2 = "";
	warn "(2)$eventDateAlt\t$id";
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


if ($MM =~ m/^(\d)$/){ #see note above, JulianDate module needs leading zero's for single digit days and months
	$MM = "0$1";
}
if ($DD =~ m/^(\d)$/){
	$DD = "0$1";
}
#($YYYY, $MM, $DD)=&atomize_ISO_8601_date($formatEventDate);  #this has messed up EJD, so use to check then comment out
#warn "$formatEventDate\t--\t$id";

#$MM2= $DD2 = ""; #set late date to blank if only one date exists
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $MM2, $DD2, $id);
#warn "$formatEventDate\t--\t$EJD, $LJD\t--\t$id";
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);

###############COLLECTORS
#All collectors in the sample dataset are lone collectors
#Additions may be needed if more collectors added



foreach ($verbatimCollectors){
	s/'$//g;
	s/"//g;
	s/\[//g;
	s/\]//g;
	s/\?//g;
	s/s\. n\. / /g;
	s/, with/ with/;
	s/ w\/ ?/ with /g;
	s/, M\. ?D\.//g;
	s/, Jr\./ Jr./g;
	s/, Jr/ Jr./g;
	s/, Esq./ Esq./g;
	s/, Sr\./ Sr./g;
	s/^'//g;
	s/ , /, /g;
	s/^ *//;
	s/ *$//;
	s/  +/ /;
}
$collector = ucfirst($verbatimCollectors);

	
	if ($collector =~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collector, $id);	
	#D Atwood; K Thorne
		$other_coll=$2;
		#warn "Names 1: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_collectors\n";
		&log_change("COLLECTOR (): modified: $verbatimCollectors==>$collector--\t$recordedBy\t--\t$other_collectors\t$id\n");	
	}
	
	elsif ($collector !~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collector, $id);
		#warn "Names 2: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_collectors\n";
	}
	elsif (length($collectors == 0)) {
		$recordedBy = "Unknown";
		&log_change("COLLECTOR (2): modified from NULL to $recordedBy\t$id\n");
	}	
	else{
		&log_change("COLLECTOR (3): name format problem: $verbatimCollectors==>($collector)\t $id\n");
	}




###further process other collectors
foreach ($other_coll){
	s/"//g;
	s/'$//g;
	s/^ *//;
	s/ *$//;
	s/  +/ /;
}

$other_collectors = ucfirst($other_coll);





#############CNUM##################

my $CNUM_suffix;
my $CNUM;
my $CNUM_prefix;

($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);

####COUNTRY
$country="USA"; #all specimens from JROH are from United States
$stateProvince = "CA"; #all specimens from JROH are from California


######################COUNTY
foreach($county){#for each $county value
	s/'//g;
	s/^ *//g;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries
#format county as a precaution
$county=&CCH::format_county($county,$id);




######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}

##############validate county
my $v_county;



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


##########LOCALITY#########
#Locality is all in one field and seems to have no problems, besides some strange characters
foreach($locality){
	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
}


###############ELEVATION########
foreach($verbatimElevation){
	s/feet/ft/g;
	s/ft/ ft/g;
	s/about //g;
	s/ca\.? //g;
	s/m/ m/g;
	s/  +/ /g;
	s/,//g;
	s/\.//g;
#	s/[A-Z]?[a-z]+ (\d+)/$1/g;
	
	}
	
if (length($verbatimElevation) >= 1){

	if ($verbatimElevation =~ m/^(-?[0-9]+) +m/){
		$elevationInMeters = $1;
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+) *f/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^-?[0-9]+ *- *(-?[0-9]+) *f/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$verbatimElevation' has missing units, is non-numeric, or has typographic errors\t$id");
		$elevationInMeters="";
	}	
}
else {
	$CCH_elevationInMeters = "";
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

#########COORDS, DATUM, ER, SOURCE#########
#Source is a free text field so no editing required
my $lat_sum;
my $long_sum;
my $Check;
my $ER_units;

#######Latitude and Longitude
#All coordinates were in perfect DD, but now one DMS was recorded
#e.g. "N37°24'	W122°14'"

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


foreach ($verbatimLatitude, $verbatimLongitude){
		s/ø/ /;
		s/[°¡]//g;
		s/\xc3\xb8/ /; #decimal byte representation for ø
		s/'/ /;
		s/;//;
		s/"/ /;
		s/,/ /;
		s/deg./ /;
		s/  +/ /g;
		s/^ *//;
		s/ *$//;
		
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


#use combined Lat/Long field format for RSA

	#convert to decimal degrees
if((length($latitude) >= 2)  && (length($longitude) >= 3)){ 
		if ($latitude =~ m/^(\d\d) +(\d\d?) (\d\d?\.?\d*) */){ #if there are seconds
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
					print "1b)$decimalLatitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script"; #only needed to be stated once, if lat id converted, so is long
				}
		}
		elsif ($latitude =~ m/^(\d\d) +(\d\d?\.?\d*) */){
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
					print "2b) $decimalLatitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($latitude =~ m/^(\d\d\.\d+)$/){
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
		
		if ($longitude =~ m/^(-?1\d\d) +(\d\d) +(\d\d?\.?\d*).? */){ #if there are seconds
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
					print "5b) $decimalLongitude\t--\t$id\n";
				}
		}	
		elsif ($longitude =~m /^(-?1\d\d) +(\d\d?\.?\d*) */){
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
					print "6a) $decimalLongitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($longitude =~m /^(-?1\d\d\.\d+)$/){
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
		$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
}
else {
			&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
}

#check datum
if(($verbatimLatitude=~/\d/  || $verbatimLongitude=~/\d/)){ #If decLat and decLong are both digits
	if ($datum){ #report is datum is present
		s/WGS 84/WGS84/g;
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
if((length($decimalLatitude) >= 2)  && (length($decimalLongitude) >= 3)){  #If decLat and decLong are both digits
	if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114.0 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california and northern Baja...
	###was 32.5 for California, now 30.0 to include CFP-Baja
		&log_change("coordinates set to null for $id, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude =$decimalLongitude=$datum="";	#and set $decLat and $decLong to ""  
	}
}	
else {
		if((length($verbatimLatitude) == 0)  && (length($verbatimLongitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}	
	

foreach ($errorRadius){
	s/feet/ft/g;
	s/ft/ ft/g;
	s/m/ m/g;
	s/k m/ km/g; #to correct the previous line from turning "km" into "k m"
	s/  / /g;
	s/,//g;
	s/\.//g;
}

#Error radius must be split because of bulkloader format
if ($errorRadius=~/(\d+) (.*)/){
	$ER_units=$2;
	$errorRadius=$1;
}
else {
	$ER_units="";
}

#######Plant Description (dwc ??) and Abundance (dwc occurrenceRemarks)
#Macromorphology, including abundance
foreach ($plant_description){
		s/'$//;
		s/  +/ /g;
}

###########HABITAT#########
#Habitat is all in one field and seems to have no problem
foreach ($habitat){
		s/'$//;
		s/  +/ /g;
}


#####ASSOCIATED SPECIES#####
#free text field
foreach ($associatedTaxa){
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/with / /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
}

#RLM removed JROH prefix from first line : Mon Jun 13 18:18:06 PDT 2016
	print OUT <<EOP;
Accession_id: $id
Name: $scientificName
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
Collector: $recordedBy
Other_coll: $other_collectors
Combined_coll: $verbatimCollectors
CNUM_prefix: $CNUM_prefix
CNUM: $CNUM
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
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance: $errorRadius
Max_error_units: $ER_units
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Macromorphology: $plant_description
Cultivated: $cultivated
Hybrid_annotation: $hybrid_annotation
Annotation: $det_string
Annotation: $det_prev

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


    my $file_in = 'JROH_out.txt';	#the file this script will act upon is called 'CATA.out'
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
