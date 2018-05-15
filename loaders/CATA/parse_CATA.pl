use Time::JulianDay;
use Time::ParseDate;
use Geo::Coordinates::UTM;
use lib '/Users/davidbaxter/DATA';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
$today_JD=julian_day($today_y, $today_m, $today_d);
my %month_hash = &month_hash;

&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array
foreach(keys(%TID)){
#print "$_: $TID{$_}\n";
}
#die;
open(OUT,">CATA.out") || die;
open(ERR,">CATA_log.txt") || die;

open(IN,"/Users/davidbaxter/DATA/mosses") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}

##feet to meters conversion
#$meters_to_feet="3.2808";
$feet_to_meters="0.3048";

#####process the file
#BLMAR file arrives as a comma-separated csv with double-quotes as text qualifiers
#I import into Excel, save as tab-delimited text
#Then open in TextWrangler and save as UTF-8 with Unix line breaks
#then removing enclosing quotes and fix escaped quotes in vim
#there's got to be a better way to deal with enclosing quotes
###############

	my $file = 'CATA_data_2015-10.txt';
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless($#columns==27){
		print ERR "$#columns bad field number $_\n";
	}
	
($id,
$labelHeader,
$labelSubHeader,
$country,
$stateProvince,
$county,
$island, #followed by a colon; concatenate with location to get dwc locality
$family,
$name_w_author, #with author; need to strip author.
$location, 
$elev_feet,
$elev_meters, #elevations are one or the other: use $meters_to_feet conversion to put all into meters
$verbatim_long,	#lat is called long and vice versa in column headers. Convert them to DD and call source "DMS conversion"
$verbatim_lat, 	#in the format DDø MM' SS", or sometimes DDøMM'SS" DDøMM.MMM' or DDøMM'SS.SSS"
$UTME,
$UTMN, #figure out zone; convert is possible. Call source "UTM conversion"
$plant_description, #plant description
$habitat,
$abundance,
$associatedTaxa,
$associatedTaxa2, #new field Oct2015
$main_collector,
$CNUM_prefix,
$CNUM, #can concat with prefix to make dwc recordNumber
$other_collectors, #can concatenate with $main_collector to make dwc recordedBy
$coll_month, #three letter month name: Jan, Feb, Mar etc.
$coll_day,
$coll_year,
)=@columns;


######Accession ID
#check for nulls
if ($id=~/^ *$/){
	&skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
		}

#Remove duplicates
	if($seen{$id}++){
		++$skipped{one};
		warn "Duplicate number: $fields[0]<\n";
		print ERR<<EOP;

Duplicate accession number, skipped: $fields[0]
EOP
		next;
	}

#Add prefix, remove any white space
foreach ($id){
	s/^ *//;
	s/ *$//;
	s/^/CATA/;
	}

####We don't publish label title/subtitle
#but the title is used to determine cultivated-ness
$cultivated= "";
		if($labelHeader=~/Cultivated/i){
			$cultivated="yes";
			&log_change ("Record marked as cultivated because of label header \"$labelHeader\"\t$id");
		}


####Country and State always U.S.A.[or U. S. A.]/CA, unless left blank, which still means USA/CA

####COUNTY
#All counties properly formatted, for now.
foreach ($county){
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
		$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&skip("$id NON-CA COUNTY? $_");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}

		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log("$id COUNTY $_ -> $v_county");		#call the &log function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}



####LOCALITY
$locality = "$island $location";
# andin case it only has $island
$locality =~ s/: *$//;
$locality =~ s/ *$//;


###########SCIENTIFICNAME
$scientificName=&strip_name($name_w_author);
$scientificName=~s/^ *//;
$scientificName = &validate_scientific_name($scientificName, $id);


####ELEVATION
if ($elev_meters){
	$elevationInMeters = $elev_meters;
}
elsif ($elev_feet){
	$elevationInMeters = int($elev_feet * $feet_to_meters) #make it int to remove false precision
}
else {
	$elevationInMeters = "";
}

#$elevationInMeters is the darwin core compliant value
#$elevation adds the units to make it CCH compliant
if ($elevationInMeters){
	$elevation = "$elevationInMeters m";
}
else {
	$elevation = "";
}


#######Latitude and Longitude
#right now the Latitude and Longitude fields are always in DMS or DDM. Will probably include decimal degrees in the future
#Datum and uncertainty are not recorded.
#Datum is assumed to be NAD83/WGS84 for the purposes of utm_to_latlon conversion (i.e. $ellipsoid=23)
#but otherwise datum is not reported
#remove symbols and put it in a standard format, spaces delimiting
if ($verbatim_lat && $verbatim_long){
	foreach ($verbatim_lat){
		s/ø/ /;
		s/\xc3\xb8/ /; #decimal byte representation for ø
		s/'/ /;
		s/"/ /;
		s/,/ /;
		s/N/ /;
		s/  */ /;
		s/^ *//;
		s/ *$//;
	}

#I attempted to round to decimal places using sprintf, but it doesn't seem to be working
#The CCH rounds on display, and the source is included in downloads, so it's kind of moot anyway	
	if ($verbatim_lat =~m /([\d.]+) ([\d.]+) ([\d.]+)/){ #if there are seconds
		$decimalLatitude = sprintf("%.5f", ($1)+($2/60)+($3/3600)); #sprintf to round to 5 decimal places
	}	
	elsif ($verbatim_lat =~m /([\d.]+) ([\d.]+)/){
		$decimalLatitude = sprintf("%.3f", ($1)+($2/60)); #sprintf to round to 3 decimal places
	}
	else {
		&log("check latitude format: $verbatim_lat $id");
		$decimalLatitude = "";
	}
#print "$verbatim_lat\t$decimalLatitude\n";


	foreach ($verbatim_long){
		s/ø/ /;
		s/'/ /;
		s/"/ /;
		s/,/ /;
		s/W/ /;
		s/  */ /;
		s/^ *//;
		s/ *$//;
	}
	if ($verbatim_long =~m /([\d.]+) ([\d.]+) ([\d.]+)/){ #if there are seconds
		$decimalLongitude = sprintf("%.5f", ($1)+($2/60)+($3/3600));
	}	
	elsif ($verbatim_long =~m /([\d.]+) ([\d.]+)/){
		$decimalLongitude = sprintf("%.3f", ($1)+($2/60));
	}
	else {
		&log("check longitude format: $verbatim_long $id");
		$decimalLongitude = "";
	}
	
	$georeferenceSources = "DMS conversion";

}
elsif ($UTME && $UTMN){
	#Northing is always one digit more than easting. sometimes they are apparently switched around.
	if ($UTME =~ /(\d\d\d\d\d\d\d)/ && $UTMN =~ /(\d\d\d\d\d\d)/){
		$easting = $UTMN;
		$northing = $UTME;
		&log ("UTM coordinates apparently reversed; switching northing with easting: $id");
	}
	else {
		$easting = $UTME;
		$northing = $UTMN;
	}
	
	#set UTM Zone based on island name
	if ($island =~ /(San Miguel|Santa Rosa)/){
		$zone = "10N";
	}
	else {
		$zone = "11N";
	}
	$ellipsoid = 23;
	($decimalLatitude,$decimalLongitude)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
	$decimalLatitude = sprintf("%.5f", $decimalLatitude); #round to 5 decimal places for UTM conversion
	$decimalLongitude = sprintf("%.5f", $decimalLongitude);
	&log("coordinates derived from UTM for $id: $decimalLatitude, $decimalLongitude");

	$georeferenceSources = "UTM conversion";
}
elsif ($verbatim_lat || $verbatim_long || $UTME || $UTMN ){
	&log("incomplete coordinates for $id: $verbatim_lat $verbatim_long $UTME $UTMN");
	$decimalLatitude = $decimalLongitude = $georeferenceSources = "";
}

else{
	$decimalLatitude = $decimalLongitude = $georeferenceSources = "";
}

#check boundaries
if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
	}	
	if($decimalLatitude > 42.1 || $decimalLatitude < 32.5 || $decimalLongitude > -114 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
		&log("coordinates set to null for $id, Outside California: >$decimalLatitude< >$decimalLongitude<");	#print this message in the error log...
		$decimalLatitude =$decimalLongitude="";	#and set $decLat and $decLong to ""
	}
}


#######Plant Description and Abundance (dwc occurrenceRemarks; CCH "Notes")
$occurrenceRemarks = "$plant_description; $abundance";
$occurrenceRemarks =~ s/^; //;
$occurrenceRemarks =~ s/; $//;


#######Habitat and Assoc species (dwc habitat and associatedTaxa; CCH "Habitat")
$habitat_incl_associates = "$habitat; Associates: $associatedTaxa";
$habitat_incl_associates =~ s/Associates: $//; #if there is no associatedTaxa
$habitat_incl_associates =~ s/^; //;
$habitat_incl_associates =~ s/; $//;


######COLLECTORS
#recordedBy = combined collectors ($main_collector plus $other_collectors)
foreach ($main_collector){
	s/USC Wrigley Interns: //;
}

if ($main_collector && $other_collectors){
	$recordedBy = "$main_collector, $other_collectors";
}
else {
	$recordedBy = $main_collector;
}


#####COLLECTOR NUMBER
#parse suffix out of cnum
#CNUM
#CNUM_prefix
if ($CNUM =~ /(\d+)-(.*)/){
	$CNUM = $1;
	$CNUM_suffix = "-$2";
}
elsif ($CNUM =~ /(\d+)([A-Za-z]+)/){
	$CNUM = $1;
	$CNUM_suffix = $2;
}
else {
	$CNUM = $CNUM;
	$CNUM_suffix = "";
}

#process prefix to remove trailing zeros, then to add hyphens where absent
if ($CNUM_prefix) {
	foreach ($CNUM_prefix){
		s/-(0+)/-/;
		s/$/-/;
		s/--/-/;
	}
}
#recordNumber = all parts together
$recordNumber = "$CNUM_prefix$CNUM$CNUM_suffix";

#####DATES
#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#$coll_month, #three letter month name: Jan, Feb, Mar etc.
#$coll_day,
#$coll_year,
#verbatim date for dwc verbatimEventDate and CCH "Date"
if ($coll_year && $coll_month && $coll_day) { $verbatimEventDate = "$coll_month $coll_day, $coll_year"; }
elsif ($coll_year && $coll_month) { $verbatimEventDate = "$coll_month $coll_year"; }
elsif ($coll_year) { $verbatimEventDate = "$coll_year"; }
else {
	$verbatimEventDate = "";
	&log ("No date: $id")
}

#convert to YYYY-MM-DD for eventDate and JD
$YYYY=$coll_year;
$DD=$coll_day;
$MM = &get_month_number($coll_month, $id, %month_hash);

($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);


print OUT <<EOP;
Accession_id: $id
Name: $scientificName
Collector: $main_collector
Other_coll: $other_collectors
Combined_coll: $recordedBy
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
County: $county
Location: $locality
Elevation: $elevation
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Lat_long_ref_source: $georeferenceSources
Habitat: $habitat_incl_associates
Notes: $occurrenceRemarks
Cultivated: $cultivated

EOP
}

sub skip {	#for each skipped item...
	print ERR "skipping: @_\n"	#print into the ERR file "skipping: "+[item from skip array]+new line
}
sub log {	#for each logged change...
	print ERR "logging: @_\n";	#print into the ERR file "logging: "+[item from log array]+new line
}