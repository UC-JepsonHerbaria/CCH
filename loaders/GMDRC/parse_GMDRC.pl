use Time::JulianDay;
use Time::ParseDate;
use Geo::Coordinates::UTM;
use lib '/Users/davidbaxter/DATA';
use CCH; #loads alter_names hash %alter, non-vascular hash %exclude, and county max elevation hash %max_elev
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
$today_JD=julian_day($today_y, $today_m, $today_d);

&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array
my %month_hash = &month_hash;


open(OUT,">GMDRC.out") || die;
open(ERR,">granite_log") || die;
$date=localtime();
print ERR <<EOP;
$date
Report from running parse_granite.pl
Name alterations from file ~/DATA/alter_names
Name comparisons made against ~/DATA/smasch_taxon_ids.txt (SMASCH taxon names, which are not necessarily correct)
Genera to be excluded from "mosses"

EOP

#####process the file
#GMDRC arrives as an xlsx file, with some in-cell line breaks
#To handle this, I add a column at the end called "DUMMYCOLUMN" and populate that all the way down
#Save as txt, open in vi
#remove ALL MS line breaks --> :%s/[Ctrl+V][Ctrl+M]//g
#then replace the dummycolumn with a line break -> :%s/\tDUMMYCOLUMN/[Ctrl+V][Ctrl+M]/g;
#if you don't do this, either CCH::checkfile will yell at you or you'll only get one line

#also, because MS Excel likes to export double quotes around cells with commas in them:
#:%s/\t"/\t/g;
#:%s/"\t/\t/g;
#:%s/^"//;
#:%s/"$//;

#	my $file = 'CCHexport24NOV2014.txt';
#	my $file = 'CCHexport25JAN2015.txt';
	my $file = 'CCHexport03Feb2015.txt';

open(IN,"$file" ) || die;

Record: while(<IN>){
	chomp;
#	CCH::&check_file;
	@fields=split(/\t/,$_,100);
		unless($#fields==65){
			print ERR "$#fields bad field number $_\n";
		}

foreach (@fields){	
	s/\0//g;
	s/\x00//g; #remove null bytes
}
	s/Ž/&eacute/g;
	s/\x8e/&eacute;/;
	s/\xa1/&deg;/; #think about how you will parse, like, will this degree sign get in the way of calculations? Do you display it?
	s/\xc9/.../;
	s/\xd2/"/;
	s/\xd3/"/;
	s/\xd5/'/;
	#because MS Excel likes to export double quotes around cells with commas in them:
	s/\t"/\t/g;
	s/"\t/\t/g;
	s/^"//;
	s/"$//;


($CCH, #used on their end for export purposes. No use here.
$id, #GMDRC####
$Family,
$Genus,
$idQualifier,
$Species,
$SpeciesAuthor,
$infra_type,
$infra_epithet,
$infra_author,
$hybrid_orig_det,
$genus_hybrid_OD,
$species_hybrid_OD,
$species_hybrid_author_OD,
$identified_by,
$ID_month,
$ID_day,
$ID_year,
$state,
$coll_num,
$coll_first_name,
$coll_last_name,
$county,
$topo_scale,
$coll_month,
$coll_day,
$coll_year,
$topo_quad,
$other_coll,
$T,
$R,
$S,
$Quarter,
$T2,
$R2,
$S2,
$Quarter2,
$desert_region, #probably won't use
$datum,
$physiographic_locality, #not needed, as it's included in $locality
$lat_deg,
$lat_min, #sometimes is in degree decimal minutes
$lat_sec,
$long_deg, #needs to be made negative
$long_min,
$long_sec,
$locality,
$UTMZ,
$UTMN,
$UTME,
$habitat,
$elev,
$elev_range, #Assumed it meant "max elevation if a range", but usually there is a value in $elev or $elev_range but not both
$elev_units, #almost always feet, so when blank assume feet
$assoc_species,
$management_authority,
$specimen_notes,
$parent_rock,
$geologic_format,
$soil_type,
$phenology,
$abundance,
$impacts, #impacted by e.g. fire, soil disturbance, threatened by solar energy, etc.
$annotation_notes, # = previous determinations
$CCH_current_det, #NEED TO ASK TASHA ABOUT THIS VS THE TAXONOMY FIELDS
$BLANK_FIELD #...at the end of their Excel sheet
) = @fields;


####ACCESSION ID####
if ($id=~/^ *$/){
	&skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
		}
#Remove duplicates
	if($seen{$id}++){
		++$skipped{one};
		warn "Duplicate number: $id<\n";
		print ERR<<EOP;
Duplicate accession number, skipped: $id
EOP
		next Record;
	}


##########Scientific Name
if ($infra_type eq "cf\."){ #one case
	$idQualifier = $infra_type;
	$infra_type="";
}
foreach ($Species){
	s/cf\. nova//;
	s/sp\. nova//;
	s/sp\. nov\.//;
	s/sp\.//;
}
foreach ($infra_type){
	s/ //;
	s/ssp\./subsp./;
}

if ($Genus && $Species && $infra_type && $infra_epithet){
	$ScientificName = "$Genus $Species $infra_type $infra_epithet";
}
elsif ($Genus && $Species && $infra_type){
	$ScientificName = "$Genus $Species";
	&log("$ScientificName $infra_type truncated to $ScientificName: $id");
}
elsif ($Genus && $Species){
	$ScientificName = "$Genus $Species";
}
elsif ($Genus){
	$ScientificName = $Genus;
}
else {
	&skip("no generic name: $id");
	++$skipped{one};
	next Record;
}

foreach ($ScientificName){
	s/"//g;
	s/\?//g;
	s/cf\.//;
	s/c\.f//;
	s/^ *//;
	s/ *$//;
	s/  */ /g;
}

$ScientificName = &validate_scientific_name($ScientificName, $id);


####IDENTIFICATION QUALIFIER
#I'm not actually doing anything with it right now
#Since it's covered in the annotations
foreach ($idQualifier) {
	s/^ined$/ined./;
}

##########HYBRID NAME
if ($hybrid_orig_det){
	$hybrid_annotation = "$ScientificName X $genus_hybrid_OD $species_hybrid_OD";
}
else {
	$hybrid_annotation = "";
}


########DETERMINER AND DATE, FOR ANNOTATIONS
#parse out year from determiner, then clear it out
if ($identified_by =~ /(\d\d\d\d)/){
	$ID_year = $1;
	}
foreach ($identified_by){
	s/,.*//;
	s/ \d\d\d\d$//;
}

#months are strings, which is okay as det date is just a string
if ($ID_year && $ID_month && $ID_day){
	$determined_date = "$ID_month ID_day, $ID_year";
}
elsif ($ID_year && $ID_month){
	$determined_date = "$ID_month $ID_year";
}
elsif ($ID_year){
	$determined_date = "$ID_year";
}
else {
	$determined_date = "";
}


######STATE AND COUNTY
unless ($state =~ /^California$/){
	&skip("State not California: $state");
	next Record;
}

foreach ($county){
	s/"//;
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown|Unknown)$/){
		$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&skip("NON-CA COUNTY? $_");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log("COUNTY $_ -> $v_county: $id");		#call the &log function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}




#####COLLECTORS AND NUMBER
unless ($coll_first_name && $coll_last_name){
	&log("collector name missing or incomplete: $coll_first_name $coll_last_name: $AccessionID")
}
if ($coll_first_name && $coll_last_name){
	$main_collector = "$coll_first_name $coll_last_name"
}
elsif ($coll_last_name){
	$main_collector = $coll_last_name;
}
else {
	$main_collector = "unknown";
}

foreach ($other_coll) {
	s/^ *//;
	s/ *$//;
	s/  */ /;
}

if ($main_collecter && $other_coll){
	$combined_coll = "$main_collector, $other_coll";
}
else {
	$combined_coll = $main_collector;
}

#Collector numbers are all perfectly numerical, so no processing needs to be done
#still, check if numerical in case something comes in in the future
unless ($coll_num =~ /^(\d+)$/){
	&skip("Collector number non-numerical; loading script needs to be updated: $coll_num $id");
	next Record;
}


#########COLLECTION DATE
if ($coll_day eq "0"){
	$coll_day = "";
}

#if ($coll_day = /^0$/){
#	$coll_day = "";
#}

#make verbatim dates
if ($coll_year && $coll_month && $coll_day){
	$verbatimEventDate = "$coll_month $coll_day, $coll_year";
}
elsif ($coll_year && $coll_month){
	$verbatimEventDate = "$coll_month $coll_year"
}
elsif ($coll_year){
	$verbatimEventDate = $coll_year;
}
else {
	$verbatimEventDate = "unknown";
	&log("No collection date: $id");
}

#translate month strings to numbers
$coll_month = &get_month_number($coll_month, $id, %month_hash);

#then assemble Julian days
($EJD, $LJD)=&make_julian_days($coll_year, $coll_month, $coll_day, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);


#######TOWNSHIP RANGE SECTION
if ($T){
	$TRS = "$T $R $S $Quarter; $T2 $R2 $S2 $Quarter2";
}
foreach ($TRS){
	s/ *$//;
	s/^ *//;
	s/  *//g;
	s/;$//;
}

##########TOPO, DATUM AND COORDINATES
#no processing needed for topo, just concatenation
if ($topo_quad){
	$usgs_quad = "$topo_quad $topo scale";
}
else {
	$topo_quad = "";
}

#datums are all NAD27, NAD83, and WGS84 for now
foreach ($datum){
	s/ *//g;
}
if ($datum){
	unless ($datum =~ /^WGS84$|^NAD83$|^NAD27$/){
		&log("Datum format unrecognized: $datum $id");
	}
}

#If DMS, use DMS, otherwise use UTM
if ($lat_deg && $long_deg){
	#Convert DMS coordinates to decimal degrees
	$decimal_lat = $lat_deg + $lat_min/60 + $lat_sec/3600;
	$decimal_long = $long_deg + $long_min/60 + $long_sec/3600;
	$decimal_long = "-$decimal_long" if $decimal_long > 0;
	$error_radius="30";
	$ER_units="m";
	$coord_source="Collector GPS (converted from DMS)";
}

elsif ($UTME && $UTMN){
#convert UTM to decimal, 
	$easting = $UTME;
	$northing = $UTMN;
	$easting=~s/[^0-9]*$//;
	$northing=~s/[^0-9]*$//;
	$zone = "11S"; #UTMZ is rarely recorded, but can be assumed to be 11S for GM's extent
	$ellipsoid=23;
	if($zone=~/9|10|11|12/ && $easting=~/^\d\d\d\d\d\d/ && $northing=~/^\d\d\d\d\d/){
		($decimal_lat,$decimal_long)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
		&log("decimal degrees derived from UTM $decimal_lat, $decimal_long; $id\n");
		$error_radius="30";
		$ER_units="m";
		$coord_source="GPS (converted from UTM)";
	}
	else{
		&log("$CCH_Specimen_ID UTM problem $zone $easting $northing\n");
		$error_radius="";
		$ER_units="";
		$coord_source="";
	}
}
else {
	$decimal_lat=$decimal_long=$error_radius=$ER_units=$coord_source="";
}
########LOCALITY, HABITAT, AND ASSOCIATES
#Locality has lots of extra junk in it, like USGS Quad, DMS coords, and elevation, but I can't really parse them out
#still, locality is concatenated with "$physiographic_locality", which is the general area
#$locality
if ($physiographic_locality && $locality){
	$locality = "$physiographic_locality, $locality";
}
elsif ($physiographic_locality){
	$locality = $physiographic_locality;
}
elsif ($locality){
	$locality = $locality;
}
else {
	$locality = "";
}

#Habitat also has some weird stuff in it, like USGS Quads, that I can't really do anything about
if ($soil_type){
	$habitat = "$habitat; soil type: $soil_type";
	$habitat =~ s/^; //;
}

#Associated Species is fine as is
#$assoc_species



#####ELEVATION
foreach ($elev_range){
	s/^0$//;
}
foreach ($elev_units){
	s/Feet/ft/;
	s/Meters/m/;
}

#if there is elevation but no units, assume feet
unless ($elev_units){
	if ($elev || $elev_range){
		$elev_units = "ft";
	}
	else {
		$elev_units = "";
	}
}

#if there's units but no elevations, log then null units
unless ($elev || $elev_range){
	if ($elev_units){
		&log("Elevation units but no measurement: $id");
		$elev_units = "";
	}
}

if ($elev && $elev_range){
	$elevation = "$elev-$elev_range";
}
elsif ($elev){
	$elevation = $elev;
}
elsif ($elev_range){
	$elevation = $elev_range;
}
else {
	$elevation = "";
}


############SPECIMEN NOTES
#Phenology is added as a separate voucher information type
#Abundance is under population biology
#Specimen Notes and Impacts concatenated as "Notes"
#$phenology
#$abundance
if ($specimen_notes && $impacts){
	$notes = "$specimen_notes; Impacts: $impacts";
}
elsif ($specimen_notes){
	$notes = $specimen_notes;
}
elsif ($impacts){
	$notes = "Impacts: $impacts";
}
else {
	$notes = "";
}

#############ANNOTATIONS
#$annotation_notes represents previous determinations
#right now it only ever contains one determination, so I don't process them.
#if it did, I'd need to write a loop to print multiple "Annotation:" lines
#$CCH_current_det is the current determination. It contains the same info as in the taxonomy fields, plus the determination info.
#both are in the format "[scientific name]; [determiner] [date string], which works fine
#I don't think it matters what order these go in in the print OUT, since CCH seems to just shuffle them up
foreach ($CCH_current_det) {
	s/ ssp\. / subsp. /g;
}
foreach ($annotation_notes) {
	s/ ssp\. / subsp. /g;
}

if ($annotation_notes =~ /;.*;/){
	&log("Check AnnotationNotes format: $id")
}

print OUT <<EOP;
Accession_id: $id
Name: $ScientificName
Collector: $main_collector
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
CNUM: $coll_num
CNUM_prefix: 
CNUM_suffix: 
Country: USA
State: $state
County: $county
Location: $locality
T/R/Section: $TRS
USGS_Quadrangle: $usgs_quad
Elevation: $elevation $elev_units
Other_coll: $other_coll
Combined_coll: $combined_coll
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Lat_long_ref_source: $coord_source
Datum: $datum
Max_error_distance: $error_radius
Max_error_units: $ER_units
Hybrid_annotation: $hybrid_annotation
Habitat: $habitat
Notes: $notes
Phenology: $phenology
Population_biology: $abundance
Associated_species: $assoc_species
Annotation: $CCH_current_det
Annotation: $annotation_notes

EOP
}



sub skip {	#for each skipped item...
	print ERR "skipping: @_\n"	#print into the ERR file "skipping: "+[item from skip array]+new line
}
sub log {	#for each logged change...
	print ERR "logging: @_\n";	#print into the ERR file "logging: "+[item from log array]+new line
}
