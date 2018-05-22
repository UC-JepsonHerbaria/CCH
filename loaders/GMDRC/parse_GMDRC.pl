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
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $file = 'CCHexport03FEB2017.txt'; #change to name of the current text file export from GMDRC
my $file_out = 'GMDRC.out'; #GMDRC out file, for accent detector script at bottom
open(IN,"$file" ) || die;

Record: while(<IN>){
	chomp;
	@fields=split(/\t/,$_,100);
	
    	 
		unless($#fields==33){
			&log_skip("$#fields bad field number $_");
			next Record;
		}

foreach (@fields){	
	s/\0//g;
	s/\x00//g; #remove null bytes
	s/^ *//g;
	s/ *$//g;

##	s/\x8e/&eacute;/g;
#s/\xa1/&deg;/g; #think about how you will parse, like, will this degree sign get in the way of calculations? Do you display it?
	s/\xc2\xb0/&deg;/g;	
	s/\xc3\xa9/&eacute/g;	#a different character coding than above
#	s/\xc9/. /g;
#	s/\xd2/"/g;
#	s/\xd3/"/g;
#	s/\xd5/'/g;
	#because MS Excel likes to export double quotes around cells with commas in them:
	s/\t"/\t/g;
	s/"\t/\t/g;
	s/\t"/\t/g;
	s/"\t/\t/g;
	s/\n"\t/\t/g;
	s/^"//g;
	s/"$//g;
	s/\xe2\x80\x9c/"/g;
	s/\xe2\x80\x9d/"/g;
	s/\xe2\x80\x99/'/g;
	s/\xe2\x80\xa6/... /g;
	s/var\. c\.f elongatum/var. elongatum/g; #fix a badly formatted name



	
}

($id,
$scientificName, # species name
$identificationQualifier, # Qualifier
$previousDeterminations, # AnnotationNotes
$TRS_combined, # TRS Comb
$identifiedBy, #Identified By
$dateIdentified, #Ident Year
$stateProvince, #State
$recordNumber, #Collection #
$Collector_First_Name, #Collector First Name
$Collector_Last_Name, #Collector Last Name
$county,
$USGS_Quadrangle, #GeoreferenceResources
$Collection_Month,
$Collection_Day,
$Collection_Year,
$Other_Collectors, #Associated collectors
$geodeticDatum, #Datum
$locality, #SEINet Locality
$Latitude_Degrees, #Latitude
$Latitude_Minutes, #Latitude2; decimal minutes and integer
$Latitude_Seconds, #Latitude3; present only when minutes is an integer
$Longitude_Degrees, #Longitude; needs to be made negative
$Longitude_Minutes, #Longitude2; decimal minutes and integer
$Longitude_Seconds, #Longitude3; present only when minutes is an integer
$UTMZ, #UTM Zone
$UTMN,
$UTME,
$habitat,
$associatedTaxa, #Assoc Spec
$minimumElevationInMeters, #Elevation in meters
$occurrenceRemarks, #SEINet occurrenceremarks; usually abundance, but sometimes "Other Notes")
$substrate, #SEINet substrate
$phenology
) = @fields;


####ACCESSION ID####
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	next Record;
}
#remove duplicates
if($seen{$id}++){
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate accession number\t$id");
	next Record;
}

#######scientificName
foreach ($scientificName) {
	s/ ssp\. / subsp. /g;
}

$scientificName = &strip_name($scientificName);
$scientificName = &validate_scientific_name($scientificName, $id);


#####previous determinations and current det information
foreach ($previousDeterminations) {
	s/ ssp\. / subsp. /g;
}
if ($identifiedBy || $dateIdentified){
	$current_annotation = "$scientificName; $identifiedBy; $dateIdentified";
	$current_annotation =~s/; $//;
}

elsif ($identificationQualifier){
	$current_annotation = "$scientificName $identificationQualifier; $Collector_First_Name $Collector_Last_Name";
	$current_annotation =~s/; $//;
}
else { $current_annotation = ""; }

#####STATE, COUNTY
#check that state = California
unless ($stateProvince eq "California"){
	&log_skip("State '$state' not California");
	next Record;
}

#validate county
$county=&CCH::format_county($county);
foreach ($county){	#for each $county value
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
		$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&log_skip("$id NON-CA COUNTY? $_");	#run the &log_skip function, printing the following message to the error log
			next Record;
		}
		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log_change("$id COUNTY $_ -> $v_county");		#call the &log_change function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}


####Collector number/recordNumber
unless ($recordNumber=~/^([\d]+)$/ || $recordNumber eq ""){
	&log_change ("collector number '$recordNumber' not numeric\t--\t$id\n");
}


#####Collectors
if ($Collector_First_Name && $Collector_Last_Name){
	$main_collector = "$Collector_First_Name $Collector_Last_Name";
}
elsif($Collector_Last_Name){
	$main_collector = "$Collector_Last_Name";
}
else {
	$main_collector = "Unknown";
	&log_change("Collector entered as 'Unknown'\t$id");
}

if ($Other_Collectors){
	$recordedBy = "$main_collector; $Other_Collectors";
}
else{
	$recordedBy = $main_collector;
}


####### Collection Date
$verbatimEventDate = "$Collection_Month $Collection_Day $Collection_Year";

$Collection_Month = &get_month_number($Collection_Month, $id, %month_hash);
($EJD, $LJD)=&make_julian_days($Collection_Year, $Collection_Month, $Collection_Day, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);


########Coordinates
if ($Latitude_Degrees && $Longitude_Degrees){
	#Convert DMS coordinates to decimal degrees
	$decimalLatitude = $Latitude_Degrees + $Latitude_Minutes/60 + $Latitude_Seconds/3600;
	$decimalLongitude = $Longitude_Degrees + $Longitude_Minutes/60 + $Longitude_Seconds/3600;
	$decimalLongitude = "-$decimalLongitude" if $decimalLongitude > 0;
	$error_radius="30";
	$ER_units="m"; ###30 m according to Tasha La Doux's GPS
	$georeferenceSources="Collector GPS (DMS conversion by CCH loading script)";
}

elsif ((length($Latitude_Degrees) == 0) && (length($Longitude_Degrees) == 0)){
	$zone = ""; #zone is Null in this dataset
	if (length($zone) == 0){
		$zone = "11S"; #Zone for these data are this, using UTMWORLD.gif in DATA directory
	}
	
	
	if ((length($UTME) > 5) && (length($UTMN) > 5)){ #parse UTM and convert to Lat/Long

#Northing is always one digit more than easting. sometimes they are apparently switched around.
		if (($UTME =~ m/^(\d{7}$)/) && ($UTMN =~ /^(\d{6})$/)){
			$easting = $UTMN;
			$northing = $UTME;
			&log_change("UTM coordinates apparently reversed; switching northing with easting: $id");
		}
		elsif (($UTMN =~ m/^(\d{7}$)/) && ($UTME =~ /^(\d{6})$/)){
			$easting = $UTME;
			$northing = $UTMN;
		}
		else{
			$easting = $northing = "";
		}
	$ellipsoid = int(23);
	($decimalLatitude,$decimalLongitude)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
	&log_change("decimal degrees derived from UTM $decimalLatitude, $decimalLongitude; $id");
	$coordinateUncertaintyInMeters="30"; #according to Tasha La Doux's GPS
	$georeferenceSources="GPS (UTM conversion by CCH loading script)";
	
	}
	elsif ((length($UTME) == 0) && (length($UTMN) == 0)){
		$decimalLatitude = $decimalLongitude = $georeferenceSources = "";
	}
	else{
		&log_change("8 Poorly formatted UTM coordinates, Lat & Long nulled: $easting, $northing, $zone, $id\n");
		$decimalLatitude = $decimalLongitude = $georeferenceSources = "";
	}

}
else {
	if ($verbatimLatitude || $verbatimLongitude || $UTME || $UTMN ){
	$decimalLatitude=$decimalLongitude=$coordinateUncertaintyInMeters=$georeferenceSources="";
	&log_change("incomplete coordinates for $id: $verbatimLatitude\t--\t$verbatimLongitude\t--\t$UTME\t--\t$UTMN");
}

if ($coordinateUncertaintyInMeters){
	$CCH_Error_Units = "m";
}
else { $CCH_Error_Units = ""; }


#check boundaries
if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
	}	
	if($decimalLatitude > 42.1 || $decimalLatitude < 32.5 || $decimalLongitude > -114 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
		&log_change("coordinates set to null for $id, Outside California: >$decimalLatitude< >$decimalLongitude<");	#print this message in the error log...
		$decimalLatitude =$decimalLongitude="";	#and set $decLat and $decLong to ""
	}
}

####Elevation
if($minimumElevationInMeters){
	if ($minimumElevationInMeters=~/^(-?[0-9]+)$/){
		$CCH_elevationInMeters = "$minimumElevationInMeters m";
	}
	else {
		&log_change("check elevation in meters: '$minimumElevationInMeters' not numeric\t$id");
		$CCH_elevationInMeters="";
	}
my $elevation_test = ($minimumElevationInMeters * 3.28);	
	if($elevation_test > $max_elev{$county}){
		&log_change ("ELEV $county\t ELEV: $elevation_test ft. ($minimumElevationInMeters m.) greater than max: $max_elev{$county} discrepancy=", (($elevation_test)-$max_elev{$county})," $id\n");
		$CCH_elevationInMeters="";
	}

}
my $elevation_test = ($elevationInMeters * 3.28);
	if($elevation_test > $max_elev{$county}){
		&log_change ("ELEV $county\t ELEV: $elevation_test ft. ($elevationInMeters m.) greater than max: $max_elev{$county} discrepancy=", (($elevation_test)-$max_elev{$county})," $id\n");
		$CCH_elevationInMeters = "";
	}


#####FIELDS REQUIRING NO PROCESSING:
#$identificationQualifier  add as current annotation
#$TRS_combined

#$Township
#$Range
#$Section
#$Quarter
#$geodeticDatum
#$locality
#$habitat
#$verbatimCoordinates
#$verbatimElevation
#$associatedTaxa     add this  and substrate
#$occurrenceRemarks
#$reproductiveCondition


print OUT <<EOP;
Accession_id: $id
Name: $scientificName
Collector: $main_collector
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
CNUM: $recordNumber
CNUM_prefix: 
CNUM_suffix: 
Country: USA
State: $stateProvince
County: $county
Location: $locality
T/R/Section: $TRS_combined
USGS_Quadrangle: $USGS_Quadrangle
Elevation: $CCH_elevationInMeters
Other_coll: $Other_Collectors
Combined_coll: $recordedBy
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Lat_long_ref_source: $georeferenceSources
Datum: $geodeticDatum
Max_error_distance: $coordinateUncertaintyInMeters
Max_error_units: $CCH_Error_Units
Hybrid_annotation: $hybrid_annotation
Habitat: $habitat
Physical_environment: $substrate
Notes: $occurrenceRemarks
Phenology: $phenology
Associated_species: $associatedTaxa
Annotation: $current_annotation
Annotation: $previousDeterminations

EOP

}
close(IN);


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