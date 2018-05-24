#This script was a mess, and I only half cleaned it up.
#My apologies
use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA';	
use CCH; #loads non-vascular plant names list ("mosses"), alter_names table, and max_elev values
&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array %TID
$today_JD = &get_today_julian_day;
my %month_hash = &month_hash;

open(OUT, ">SDSU.out") || die;

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

#SDSU sends file as an XLS file containing many smart quotes
#Open in OpenOffice, save as UTF-8 tab-delimited CSV with no quotes around fields
#Then open in TextWrangler and use "Straighten Quotes" Text option
$current_file="CCH-SDSU-11Jan2016.txt";
open(IN, $current_file) || die;
while(<IN>){
	chomp;
	s/\cK/ /g;
	&CCH::check_file;
}
close(IN);

open(IN, $current_file) || die;
Record: while(<IN>){
	chomp;
	(@fields)=split(/\t/,$_,100);
	unless( $#fields==17){
		&log_skip("$#fields Fields not 19 $_");
		next;
	}

$hybrid_annotation=$annotation=$PREFIX=$SUFFIX="";

($id, 
$scientificName, 
$collector, 
$verbatimDate, 
$NUMBER, 
$county, 
$LOCALITY, 
$elevation, 
$decimal_latitude, 
$decimal_longitude, 
$coordinate_accuracy, 
$Geology, 
$Community, 
$PlantDescr, 
$identifiedBy, 
$dateIdentified, 
$notes, 
$image)=@fields;


################ACCESSION_ID#############
#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes
foreach($id){
	s/^0+//g;
}

#Remove duplicates
if($seen{$id}++){
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate accession number, skipped:\t$id");
	next Record;
}


###############SCIENTIFIC NAME
$scientificName="" if $scientificName=~/^No name$/i;

foreach($scientificName){
	s/^ *//;
	s/ *$//;
	s/  */ /g;
	s/ c\.?f\.//g;
	s/ [Ss]sp / subsp. /;
	s/ spp\.? / subsp. /;
	s/ var / var. /;
	s/ [Ss]sp\. / subsp. /;
	s/ Subsp\. / subsp. /;
	s/ f / f\. /;
	s/ [xX] / X /;
	s/ sp\.//;
	s/\?//;
	s/, nov\.$//;
	s/ nov\.$//;
	s/, nova$//;
}

unless($scientificName){
	&log_skip("No name: $id", @columns);
	next;
}

###Exclude non-vascular genera
($genus=$scientificName)=~s/ .*//;
if($exclude{$genus}){
	&log_skip("Non-vascular plant: $id", @columns);
	next;
}

####Make hybrid annotations
if($scientificName=~/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation=$scientificName;
	warn "$1 from $scientificName\n";
	$scientificName=$1;
}

###validate names
$scientificName=ucfirst($scientificName);
$scientificName = &strip_name($scientificName);
$scientificName = &validate_scientific_name($scientificName, $id);





#########COLLECTION DATE
if ($verbatimDate=~/([0-9]+)\/([0-9]+)\/([0-9]+)/){
	$MM=$1;
	$DD=$2;
	$YYYY=$3;
}
elsif ($verbatimDate=~/([0-9]+)-([0-9]+)-([0-9]+)/){
	$MM=$1;
	$DD=$2;
	$YYYY=$3;
}

$MM = &get_month_number($MM, $id, %month_hash);
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);




###########COUNTY###########
$county=&CCH::format_county($county);
foreach ($county){	#for each $county value
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
		$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&log_skip("$id NON-CA COUNTY? $_");	#run the &log_skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log_change("$id COUNTY $_ -> $v_county");		#call the &log_change function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}
	
	
	
	
######ElEVATION
$elevation="" if $elevation=~/N\/?A/i;

if($elevation && ($elevation > 5000 || $elevation < -300)){
	&log_change("Elevation set to null: $id: $elevation");
	$elevation="";
}
$elevation .= " m" if $elevation;
$elevation="" unless $elevation;


#######COLLECTOR
$collector= "" unless $collector;
$collector= "" if $collector=~/^None$/i;
$collector=~s/^ *//;
$collector=~s/  +/ /g;
$collector=~s/([A-Z]\.)([A-Z]\.)([A-Z][a-z])/$1 $2 $3/g;
$collector=~s/([A-Z]\.)([A-Z]\.) ([A-Z][a-z])/$1 $2 $3/g;

$combined_collector= $collector;
unless($collector=~s/, .*// || $collector=~s/ and .*//){
	$combined_collector="";
}


#COLLECTOR NUMBER
if($NUMBER=~/^(\d+)$/){
	$PREFIX=$SUFFIX="";
}
elsif($NUMBER=~/^(\d+)(\D+)$/){
	$SUFFIX=$2; $NUMBER=$1;
}
elsif($NUMBER=~/^(\D+)(\d+)$/){
	$PREFIX=$1; $NUMBER=$2;
}
elsif($NUMBER=~/^(\D+)(\d+)(.*)/){
	$PREFIX=$1; $NUMBER=$2; $SUFFIX=$3;
}
else{
	$SUFFIX=$NUMBER;
	$NUMBER="";
}
if($NUMBER || $PREFIX || $SUFFIX){
	$collector= "Anonymous" unless $collector;
}



#####COORDINATES, DATUM
		if(($decimal_latitude==0  || $decimal_longitude==0)){
			$decimal_latitude =$decimal_longitude="";
		}
		if(($decimal_latitude=~/\d/  || $decimal_longitude=~/\d/)){
			$decimal_longitude="-$decimal_longitude" if $decimal_longitude > 0;
			if($decimal_latitude > 42.1 || $decimal_latitude < 32.5 || $decimal_longitude > -114 || $decimal_longitude < -124.5){
		&log_change("coordinates set to null, Outside California: $id: >$decimal_latitude< >$decimal_longitude< $latitude $longitude");
		$decimal_latitude =$decimal_longitude="";
		}
	}
#datum not recorded, so if there's coordinates, set datum to "Not Recorded
if ($decimal_latitude && $decimal_longitude){
	$geodeticDatum="Not recorded";
}
else { $geodeticDatum = ""; }


#########COORDINATE UNCERTAINTY
foreach($coordinate_accuracy){
	s!\+/-!!;
	s/'/ ft/;
	s/  / /g;
}
if($coordinate_accuracy=~/([0-9.]+) (.*)/){
	$extent=$1; $ExtUnits=$2;
}
else{
	$extent=$ExtUnits="";
}


########ANNOTATION
if($identifiedBy){
    $annotation="$scientificName; $identifiedBy; $dateIdentified";
}
else{
    $annotation="";
}



#####NOTES; COLOR AND MACROMORPHOLOGY FROM Plant Description
$notes="" if $notes=~/^None$/;
$color="";
@descr=split(/\.  /,$PlantDescr);
$PlantDescr="";
foreach $i (0 .. $#descr){
	if($descr[$i]=~m/\b(red|green|blue|yellow|orange|purple|cream|white|brown|violet|reddish|pink|pinkish)\b/){
		$color .= "$descr[$i]. ";
	}
	else{
		$PlantDescr .= "$descr[$i]. ";
	}
}	
$PlantDescr=~s/[. ]+$//;
$color=~s/[. ]+$//;


###Count up
++$count_record;
warn "$count_record\n" unless $count_record % 5000;

				
     print OUT <<EOP;
Date: $verbatimDate
CNUM: $NUMBER
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Name: $scientificName
Accession_id: $id
Country: USA
State: California
County: $county
Location: $LOCALITY
Elevation: $elevation
Collector: $collector
Other_coll: 
Combined_collector: $combined_collector
Habitat: $Geology
Associated_species: $Community
Color: $color
Macromorphology: $PlantDescr
Latitude: $latitude
Longitude: $longitude
Decimal_latitude: $decimal_latitude
Decimal_longitude: $decimal_longitude
Notes: $notes
Datum: $geodeticDatum
Max_error_distance: $extent
Max_error_units: $ExtUnits
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation
Image: $image

EOP
}

warn "$count_record\n";
