
#use Carp; #to use "croak" instead of "die"
#use utf8;
#use Text::Unidecode; #to transliterate unicode characters to plan ASCII
use Geo::Coordinates::UTM;
use strict;
#use warnings;
use Data::GUID;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH;
use utf8;
use Text::CSV qw( csv );
my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.

$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;

open(OUT,">/JEPS-master/CCH/Loaders/JOTR/JOTR_out.txt") || die;
open(OUT2,">/JEPS-master/CCH/Loaders/JOTR/JOTR_dwc.txt") || die;

print OUT2 "Accession_id\tscientificName\tverbatimEventDate\tEJD\tLJD\trecordedBy\tother_coll\tverbatimCollectors\tCNUM\tCNUM_prefix\tCNUM_suffix\tcountry\tstateProvince\tcounty\tlocality\thabitat\tTRS\tdecimalLatitude\tdecimalLongitude\tdatum\tgeoreferenceSource\terrorRadius\terrorUnits\tCCH_elevationInMeters\tverbatimElevation\tverbatim_county\tMacromorphology\tNotes\tCultivated\tHybrid_annotation\tAnnotation\tGUID\n";

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;
my $annid;
my %ANNO;


#my $csv = Text::CSV->new ({ binary => 1, diag_verbose => 1, auto_diag => 1, allow_whitespace => 1}) ;
#my $tsv = Text::CSV->new ({ diag_verbose => 1, auto_diag => 1, binary => 1, sep_char => "\t", eol => "\n" }) or die "".Text::CSV->error_diag ();


#open my $infh,  "<:encoding(utf8)", "CCH_25AUG2017_mod.csv" || die;
#open my $outfh, ">:encoding(utf8)", "CCH_25AUG2017_mod.txt"|| die;

#while (my $row = $csv->getline ($infh)) {
#$csv =~ s/\x00$//;
    #$tsv->print ($outfh, $row);
    #}
#my $eof = $csv->eof ();
 #print $eof;

#my ($outfh, $row) = $csv->error_diag ();
# print "$outfh, $row\n";



#process converted text file
my $file = '/JEPS-master/CCH/Loaders/JOTR/CCH_25AUG2017_mod.txt';

#####process the file
###File arrives as an Excel xlsx file, with a lot of unfortunate in-cell line breaks
### it is also sorted alphabetically by columns, which is awkward to work with
#tried resorting, but it is just too time consuming to fix
#likely have to re-order the loading script each time the file is sent if the column order is changed regularly.

#some fields hav bad tabs at the end, which messes up the field order for 20 some records. 
#In the CSV version before conversion, search for an eliminate all instance of ==> tab+"
###############

open(IN,$file) || die;
Record: while(<IN>){

	chomp;

	$line_store=$_;
	++$count;


#fix some data quality and formatting problems that make import of fields of certain records impossible
# or x{Ob} or \x0b
s///g;
s///g;
s/\x00$//;
	s/  +/ /g;

	
        if ($. == 1){#activate if need to skip header lines
			next;
		}
		
my $id;
my $GUID;
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
my $tempName;
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
my $lat_deg;
my $lat_min;
my $lat_sec;
my $decimalLatitude;
my $longitude;
my $decimalLongitude;
my $long_deg;
my $long_min;
my $long_sec;
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
my $hybrid_annotation;
#unique to this dataset	
my $localityDetails;
my $dateIdentified2;
my $identifiedBy2;
my $tempCounty;
my $elevation_units;
my $det_string;

	
	my @fields=split(/\t/,$_,100);
		unless($#fields==37){ #38 fields but first field is field 0 in perl
		&log_skip("$#fields bad field number $_");
		++$skipped{one};
		next Record;
	}
	
#note that if the fields change. The field headers can be found in Excel file
#Scientific name	Common name	Locality	T/R/S	Latitude	Longitude	Datum	Locality Details	Habitat Description	Plant Description	Elevation	County	Collection number	Collection Code	Collection date	Collecter
	
($cultivated,
$associatedSpecies,
$other_coll,
$det_string,
$locality,
$id,
$recordNumber,
$verbatimEventDate,
$collector,
$tempCounty, #10
$datum,
$phenology,
$elevation,
$family, #not used
$genus,
$habitat,
$dateIdentified, #repeated in det_string?
$identifiedBy, #repeated in det_string?
$lat_deg,
$lat_min, #20
$lat_sec,
$long_deg,
$long_min,
$long_sec,
$Fraction_of_section,
$Range,
$Section,
$species,
$notes,
$stateProvince, #30
$subtaxon,
$rank,
$Township,
$topo_quad,
$elevation_units,
$UTME,
$UTMN,
$zone #38
)=@fields;


################ACCESSION_ID#############
#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space

  #my $value = Data::GUID->get_value_from_ether;

  
foreach($id){
	s/ +//g;
}

#$GUID = Data::GUID->new;
#Add prefix, 
#prefix already added in file
	

#Remove duplicates
if($seen{$id}++){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}


#####Annotations
	#format det_string correctly
my $det_orig_rank = "current determination (uncorrected)";  #set to text in data with only a single determination
my $det_orig_name = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;
my $det_orig_string;

	
	if ((length($det_orig_name) >=1)){
		$det_orig_string="$det_orig_rank: $det_orig_name";
	}
	else{
		&log_change("DET: Bad det string\t$det_orig_rank: $det_orig_name");
		$det_orig_string="";
	}


foreach ($det_string){
	s/["']+$//;
	s/^["']+//;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;

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
	s/["']+$//;
	s/^["']+//;
	s/;//g;
	s/cf.//g;
	s/ [xX××] / X /;	#change  " x " or " X " to the multiplication sign
	s/× /X /;	#change  " x " in genus name to the multiplication sign
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



###############DATES###############
my $eventDateAlt;
my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;


foreach ($verbatimEventDate){
	s/["']+$//;
	s/^["']+//;
	s/,/ /g;
	s/\./ /g;
	s/\//-/g;
	s/  */ /g;
	}

	if((length($verbatimEventDate) > 1) ){
		$eventDateAlt=$verbatimEventDate;
	}
	else{
		&log_change("DATE problem: $verbatimEventDate\t$id\n");		
		$eventDateAlt="";
		$verbatimEventDate="";
	}

	if($eventDateAlt=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^(\d\d)-(\d\d)-([0-9]{4})/){	#added to SDSU, if eventDate is in the format ##-##-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(2)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([0-9]{1,2}) ([A-Za-z]+) ([0-9]{4})/){
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

	foreach ($collector, $other_coll){
		s/"//g;
		s/'$//g;
		s/, M\. ?D\.//g;
		s/, Jr\./ Jr./g;
		s/, Jr/ Jr./g;
		s/, Esq./ Esq./g;
		s/, Sr\./ Sr./g;
		s/\(label illegible\)/Unknown/;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;

	$other_collectors = ucfirst($other_coll);

	}

#continue parsing
if ((length($collector) == 0) && (length($other_collectors) == 0)){
	$recordedBy = "";
	$verbatimCollectors = "";
	&log_change("COLLECTOR: Collector name and Other Collector fields missing, changed to NULL\t$id\n");
}
elsif ((length($collector) == 0) && (length($other_collectors) > 1)){
	#$recordedBy = &CCH::validate_single_collector($other_collectors, $id);
	$recordedBy = "$other_collectors"; #temp
	$verbatimCollectors = "$other_collectors";
	&log_change("COLLECTOR: Collector name field missing, using other collector field\t$id\n");
}
elsif ((length($collector) > 1) && (length($other_collectors) == 0)){
	#$recordedBy = &CCH::validate_single_collector($collector, $id);
	$recordedBy = "$collector"; #temp
	$verbatimCollectors = "$collector";
	&log_change("COLLECTOR: Other Collector field missing, using only Collector\t$id\n");
}
elsif ((length($collector) > 1) && (length($other_collectors) > 1)){
	#$recordedBy = &CCH::validate_single_collector($collector, $id);
	$recordedBy = "$collector"; #temp
	$verbatimCollectors = "$collector, $other_collectors";
	#warn "Names 1: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";}
}
else {
		&log_change("COLLECTOR: Collector name problem\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}

foreach ($verbatimCollectors){
	s/'$//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	
}


#############CNUM##################COLLECTOR NUMBER####



#my $CNUM_suffix;
#my $CNUM;
#my $CNUM_prefix;


#####COLLECTOR NUMBER####

foreach ($recordNumber){
	s/["']+$//;
	s/^["']+//;
	s/#//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

my $CNUM_suffix="";
($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);


####COUNTRY

####Country and State always U.S.A.[or U. S. A.]/CA, unless left blank, which still means USA/CA
my $country="USA";

foreach ($stateProvince){
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

###########COUNTY###########

	foreach ($tempCounty){
	s/"//g;
	s/'//g;
	s/^ *//g;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries
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
    
    
##########LOCALITY#########

foreach ($locality){
	s/["']+$//;
	s/^["']+//;
	s/"/'/;
	s/'$//g;
	s/^'//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;

}
    
###############ELEVATION########
foreach($elevation){
	s/["']+$//;
	s/^["']+//;
	s/~//g;
	s/,//g;
	s/^ +//;
	s/ +$//;
	s/ //g;
	s/\.//g;
}

foreach($elevation_units){
	s/["']+$//;
	s/^["']+//;
	s/,//g;
	s/`//g;
	s/`//g;
	s/'//g;
	s/^ +//;
	s/ +$//;
	s/ //g;
	s/\.//g;
}

$verbatimElevation = $elevation.$elevation_units;


if (length($elevation) >= 1){

	if ($verbatimElevation =~ m/^(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+)([fFtT]+)/){ #added <? to fix elevation in BLMAR421 being skipped
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = $elevation;
		$CCH_elevationInMeters =~ s/m$/ m/;
	}
	elsif ($verbatimElevation =~ m/^[A-Za-z ]+(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+)-(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^[A-Za-z ]+(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($verbatimElevation =~ m/^[A-Za-z]+(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("Elevation: elevation '$elevation' has problematic formatting or is missing units\t$id");
		$elevationInFeet = $CCH_elevationInMeters = $elevationInMeters = "";
	}	
}
elsif (length($verbatimElevation) == 0){
		$elevationInFeet = $CCH_elevationInMeters = "";
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
foreach ($Fraction_of_section){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;		
}

$TRS = $Township." ".$Range." ".$Section." ".$Fraction_of_section;

#######Latitude and Longitude
#right now the Latitude and Longitude fields are mostly DDM. Will probably include decimal degrees in the future
#Datum and uncertainty are not recorded.
#Datum is assumed to be NAD83/WGS84 for the purposes of utm_to_latlon conversion (i.e. $ellipsoid=23)
#but otherwise datum is not reported
#remove symbols and put it in a standard format, spaces delimiting
my $ellipsoid;
my $northing;
my $easting;
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

#coordinates that were decimals not dms
		s/^115 59 688/115 59.688/;#JOTR30628
		s/^116 1 604/116 1.604/;#JOTR30631	
		s/^115 58 266/115 58.266/;#	
		s/^15 16.87/115 16.87/;#JOTR30679

		s/^33 58 263/33 58.263/;#JOTR30628
		s/^34 3 185/34 3.185/;#JOTR30633
		s/^33 56 542/33 56.542/;#JOTR30633

	
	
}
	foreach ($zone,$UTME,$UTMN){
		s/^6747892/647892/;
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
		s/^\s$//;
}	

#use combined Lat/Long field format for BLMAR

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

		if ((length($UTME) > 1 ) && (length($UTMN) > 1 )){
			&log_change("10) Lat & Long null but UTM is present, checking for valid coordinates: $UTME, $UTMN, $zone, $id\n");
		
			#$zone = $UTM_grid_cell; #zone is this field in this dataset
			if($zone =~ m/^ *$/){
			
				if ($locality =~ m/(San Miguel Island|Santa Rosa Island)/i){
					$zone = "10S"; #Zone for these data are this, using UTMWORLD.gif in DATA directory
				}
				else{
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
					elsif($county =~ m/Mexicali/){
					$zone = ""; #Mexicali is in a small part of CA-FP Baja and it has sections in two zones, so UTM without zone is not convertable
					}
					else{
						&log_change("COORDINATE 11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone\t$id\n");
						
					#$zone = "";
					}
				}
			}
			else{
				if ($zone =~ m/^(\d\d[A-Z])/){
					$zone = $1;
				}	
				elsif ($zone =~ m/^11[a-z]?$/){
					$zone = "11S";
				}				
				elsif ($zone =~ m/^10[a-z]?$/){
					$zone = "10S";	
				}	
				else{					
					&log_change("COORDINATE 11c) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone\t$id\n");
						
					$zone = "";
				}
			}
		}
		if ((length($UTME) >= 5) && (length($UTMN) >= 5)){
#leading zeros need to be removed before this step
#Northing is always one digit more than easting. sometimes they are apparently switched around.
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
				$zone = $decimalLatitude = $decimalLongitude = $georeferenceSource = "";
			}
				($decimalLatitude,$decimalLongitude)=utm_to_latlon(23,$zone,$easting,$northing);
				&log_change("Decimal degrees derived from UTM for $id: $decimalLatitude, $decimalLongitude");
				$georeferenceSource = "UTM to Lat/Long conversion by CCH loading script";
				$datum = "WGS84";
			
		}
		elsif ((length($UTME) == 0) && (length($UTMN) == 0)){
				$decimalLatitude = $decimalLongitude = "";
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
		$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
}



##check Datum
if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	#$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
#$coordinateUncertaintyInMeters none in these data
#$UncertaintyUnits none in these data

	if ($datum){
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

#######Habitat and Assoc species (dwc habitat and associatedTaxa)

#free text fields

foreach ($habitat){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/^ *//g;
		s/  +/ /g;
}

foreach ($associatedSpecies){
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

#######Plant Description (dwc ??) and Abundance (dwc occurrenceRemarks)


foreach ($phenology){
	s/["']+$//;
	s/^["']+//;
		s/  +/ /;
}

#######notes
foreach ($notes){
	s/["']+$//;
	s/^["']+//;
		s/  +/ /;
}



#print OUT2 join("\t",$id,$scientificName,$verbatimEventDate,$EJD,$LJD,$recordedBy,$other_coll,$verbatimCollectors,$CNUM,$CNUM_prefix,$CNUM_suffix,$country,$stateProvince
#,$county
#,$locality
#,$habitat
#,$TRS
#,$decimalLatitude
#,$decimalLongitude
#,$datum
#,$georeferenceSource,$errorRadius,$errorUnits
#,$CCH_elevationInMeters
#,$verbatimElevation
#,$tempCounty
#,$plant_description
#,$notes
#,$cultivated
#,$hybrid_annotation
#,$det_string
#,$GUID), "\n";

	print OUT <<EOP;
Accession_id: $id
Other_label_numbers:
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
T/R/Section: $TRS
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Lat_long_ref_source: $georeferenceSource
Datum: $datum
Max_error_distance:
Max_error_units:
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Associated_species: $associatedSpecies
Phenology: $phenology
Notes: $notes
Hybrid_annotation: $hybrid_annotation
Cultivated: $cultivated
Annotation: $det_string

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

    my $file_out = '/JEPS-master/CCH/Loaders/JOTR/JOTR_out.txt';	#the file this script will act upon is called 'BLMAR.out'
open(IN,"$file_out" ) || die;

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
close(OUT);

