use utf8;
use Text::Unidecode; #to transliterate unicode characters to plan ASCII
use Geo::Coordinates::UTM;
#use strict;
#use warnings;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #loads alter_names has %alter, non-vascular genus has %exclude, county %max_elev hash, and various processing subroutines
my $today_JD = &get_today_julian_day;
&load_noauth_name; #load taxonID-to-scientificName hash %TID

my %month_hash = &month_hash;

open(OUT,">UCSB.out") || die;
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

#my $file = 'UCSB_103014.txt';
my $file = 'CCBER_CCH_20160425.txt';

open(IN,$file) || die;

Record: while(<IN>){
	chomp;
	
	$line_store=$_;
	++$count;
	
	s/\x9a/&ouml;/g;
	s/\x96/&ntilde;/g;
	s/\xca//g;
	@fields=split(/\t/, $_, 100);
	unless($#fields==23){
		die   "$_\n Fields should be 23; I count $#fields\n";
	}
($cchuploadId, #unique ID for the CCH upload. Not sure if persistent, so I don't use
$catalogNumber, 
$fieldNumber, 
$eventDate,
$stateProvince,
$county, 
$locality, 
$eventRemarks, 
$organismRemarks, #specimen description
$verbatimElevation, # Without units. Units are assumed to be meters
$verbatimLatitude, #always decimal degrees, so no processing
$verbatimLongitude,#always decimal degrees, so no processing except checking for minus sign
$georeferenceSources,
$coordinateUncertaintyInMeters,
$remarks, 
$family, #currently not used in CCH
$genus, 
$specificEpithet, 
$subspecies, 
$variety, 
$recordedBy,
$organismID, #GUID for %GUID hash
$Cataloged_Date, #currently not used in CCH
$Cultivated #currently not used; all blank in 2016-03 export
)=@fields; #GUID added. Not used for CCH but will be useful for GBIF export


####CATALOG NUMBER
$catalogNumber=~s/ //g;
unless($catalogNumber=~/\d/){
	&log_skip("No UCSB Catalog Number number\t$_");
	next Record;
}
$id="UCSB$catalogNumber";

#Remove duplicates
if($seen_id{$id}){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}

####DATE####

$eventDateAlt=$eventDate;

#attempt to fix the bad event dates (see notes below)
	foreach($eventDateAlt){
		s/1061-04/1961-04/;
		s/2028-08/1928-08/;
		s/1004-04-20/2004-04-20/;
		s/1077-04/1977-04/;
		s/1080-05/1980-05/;
		s/1060-07/1960-07/;
		s/1061-04/1961-04/;
		
	}
	
###eventDate comes in properly formatted, so just put it through the subroutines
	if($eventDateAlt=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{4})$/){	#if eventDate is in the format 1957
		$YYYY=$1; 
		$MM = "Jan"; 
		$DD= "1";
		$MM2 = "Dec";
		$DD2 = "30";
	#warn "Date (00-6)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]([0-9]{4})$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(5)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]([0-9]{2})([0-9]{4})$/){
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([0-9]{1,2})[- ]*$/){
		$MM=$2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
	#warn "(19)$eventDateAlt\t$id";
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



#bad eventDates (from consort_bulkload screen output
#5. BAD YEAR (no EJD) 1061 Accession: UCSB11937
#Name: Ceanothus cuneatus var. cuneatus
#Collector: A. Stern
#Date: 1061-04-30
#EJD: 
#LJD: 

#5. BAD YEAR (no EJD) 1061 Accession: UCSB10856
#Name: Dicentra formosa
#Collector: A. Stern
#Date: 1061-04-30
#EJD: 
#LJD: 

#6. BAD YEARav1988 Accession: UCSB51511
#Name: Ericameria nauseosa var. mohavensis
#Collector: John Hodgson
#Date: 2028-08-16
#EJD: 
#LJD: 

#5. BAD YEAR (no EJD) 1004 Accession: UCSB69513
#Name: Gamochaeta ustulata
#Collector: Clark Cowan
#Date: 1004-04-20
#EJD: 
#LJD: 

#5. BAD YEAR (no EJD) 1077 Accession: UCSB32537
#Name: Agoseris apargioides
#Collector: Owen Smith
#Date: 1077-04-27
#EJD: 
#LJD: 

#5. BAD YEAR (no EJD) 1080 Accession: UCSB54438
#Name: Achillea millefolium
#Collector: Martin Fletcher
#Date: 1080-05-10
#EJD: 
#LJD: 

#5. BAD YEAR (no EJD) 1061 Accession: UCSB10793
#Name: Asclepias vestita
#Collector: Joseph Keefe
#Date: 1061-04-22
#EJD: 
#LJD: 

#5. BAD YEAR (no EJD) 1060 Accession: UCSB106
#Name: Pinus monticola
#Collector: John Haller
#Date: 1060-07-11
#EJD: 
#LJD: 


#######make GUID hash
$GUID{$id}=$organismID;
#######

####Construct scientific name from fields
$scientificName="$genus $specificEpithet";
if($subspecies){
	$scientificName .= " subsp. $subspecies";
}
elsif($variety){
	$scientificName .= " var. $variety";
}
$scientificName=~s/  */ /g;
$scientificName=~s/^ *//g;
$scientificName=~s/ *$//g;

###validate name
$scientificName=&strip_name($scientificName);

$scientificName = &validate_scientific_name($scientificName, $id);


########ELEVATIONS
foreach($verbatimElevation){
	s/\.\d+//; #remove the decimal place and everything after it
	s/ elev.*//;
	s/ <([^>]+)>/ $1/;
	s/^\+//;
	s/^\~/ca. /;
	s/zero/0/;
	s/,//g;
	s/(Ft|ft|FT|feet|Feet)/ ft/;
	s/(m|M|meters?|Meters?)/ m/;
	s/\.$//;
	s/  +/ /g;
	s/ *$//;
	}
$verbatimElevation .=" m" if $verbatimElevation;

####COLLECTOR NUMBER
if($fieldNumber){
	($prefix, $CNUM,$suffix)=&parse_CNUM($fieldNumber);
}
else{
	$prefix= $CNUM=$suffix="";
}

######COUNTY
foreach($county){
	s/^$/Unknown/;
   	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown)$/){
		$v_county= &verify_co($_);
		if($v_county=~/SKIP/){
			&log_skip("SKIPPED NON-CA county? $_\t$id");
			next Record;
		}   
		unless($v_county eq $_){
			&log_change("$_ -> $v_county\t$id");
			$_=$v_county;
	    }   
	}
}   

#####Latitude, Longitude, Datum, source, error radius
$Datum="";

if($verbatimLatitude=~/^-?1\d\d/){
	$hold=$verbatimLatitude;
	$verbatimLatitude=$verbatimLongitude;
	$verbatimLatitude=$hold;
	&log_change("lat and long reversed; corrected for CCH\t$id");
}

if(($verbatimLatitude=~/\d/  || $verbatimLongitude=~/\d/)){ #If decLat and decLong are both digits
	$Datum = "not recorded"; #since they aren't sending a datum yet, set it for records with coords

	if ($verbatimLongitude > 0) {
		$verbatimLongitude="-$verbatimLongitude";	#make decLong negative if positive
		&log_change("longitude made negative\t$id")
	}
	if($verbatimLatitude > 42.1 || $verbatimLatitude < 32.5 || $verbatimLongitude > -114 || $verbatimLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
		&log_change("coordinates set to null, Outside California: >$verbatimLatitude< >$verbatimLongitude<\t$id");	#print this message in the error log...
		$verbatimLatitude =$verbatimLongitude=$Datum=$georeferenceSources="";	#null everything
	}
}
elsif ($verbatimLatitude || $verbatimLongitude){
	&log_change("non-numeric or incomplete coordinates >$verbatimLatitude< >$verbatimLongitude< nulled\t$id");
	$verbatimLatitude =$verbatimLongitude=$Datum=$georeferenceSources="";
}

if ($coordinateUncertaintyInMeters){
	$coordinateUncertaintyInMeters=~s/\..*//; #remove decimal places
	$UncertaintyUnits = "meters";
}
else {$UncertaintyUnits = ""; }


#####COLLECTORS#######

$collector=$recordedBy;
$other_coll="";
$combined_colls=$recordedBy;

#print ti output file
		print OUT <<EOP;
Accession_id: $id
Name: $scientificName
Collector: $collector
Date: $eventDate
EJD: $EJD
LJD: $LJD
CNUM: $CNUM
CNUM_prefix: $prefix
CNUM_suffix: $suffix
Country: USA
State: $stateProvince
County: $county
Location: $locality
Elevation: $verbatimElevation
Other_coll: $other_coll
Combined_coll: $combined_colls
Decimal_latitude: $verbatimLatitude
Decimal_longitude: $verbatimLongitude
Lat_long_ref_source: $georeferenceSources
Datum: $Datum
Max_error_distance: $coordinateUncertaintyInMeters
Max_error_units: $UncertaintyUnits
Hybrid_annotation: $hybrid_annotation
Habitat: $eventRemarks
Annotation: $remarks

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

####create GUID file for GBIF processing
open(OUT,">AID_GUID_UCSB.txt") || die;
foreach(keys(%GUID)){
	print OUT "$_\t$GUID{$_}\n";
}

close(IN);
close(OUT);



open(IN,"/JEPS-master/CCH/loaders/UCSB/CCBER_CCH_20160425.txt") || die;
while(<IN>){
	chomp;
next if (m/^#/);
	($cchuploadId, $catalogNumber,$fieldNumber,$eventDate,$stateProvince,$county,@rest)=split(/\t/);
	
	$alt_id = "UCSB$catalogNumber$county";
	$ACC_ID{$alt_id}=$catalogNumber;
}
close(IN);




open(OUT,">>UCSB.out") || die;
my $error_log = "log.txt";

#my $file = 'UCSB_103014.txt';
my $file = 'UCSB_SMASCH_TAB.txt';

open(IN,$file) || die;

Record: while(<IN>){
	chomp;
	
	$line_store=$_;
	++$count;
	
	@fields=split(/\t/, $_, 100);
	unless($#fields==26){
		die   "$_\n Fields should be 26; I count $#fields\n";
	}
($cchuploadId, 
$catalogNumber, 
$fieldNumber, 
$eventDate,
$stateProvince,
$county, 
$locality, 
$eventRemarks, 
$organismRemarks, #specimen description
$verbatimElevation, # Without units. Units are assumed to be meters
$verbatimLatitude, #always decimal degrees, so no processing
$verbatimLongitude,#always decimal degrees, so no processing except checking for minus sign
$georeferenceSources,
$coordinateUncertaintyInMeters,
$remarks, 
$family, #currently not used in CCH
$genus, 
$specificEpithet, 
$subspecies, 
$variety, 
$recordedBy,
$organismID, #GUID for %GUID hash
$Cataloged_Date, #currently not used in CCH
$Cultivated, #currently not used; all blank in 2016-03 export
$name,
$EJD,
$LJD
)=@fields; #GUID added. Not used for CCH but will be useful for GBIF export


####CATALOG NUMBER
$catalogNumber=~s/ //g;
unless($catalogNumber=~m/^UCSB\d+/){
	&log_skip("No UCSB Catalog Number number\t$_");
	next Record;
}
$add_id="$catalogNumber$county"; 
$id = $catalogNumber; 
#Remove duplicates
if ($ACC_ID{$add_id}){
	++$skipped_2{one};
	warn "Specimen already added: $id<\n";
	next Record;
}
elsif($seen_id{$id}++){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}

####DATE####

$eventDateAlt=$eventDate;

#attempt to fix the bad event dates (see notes below)
	foreach($eventDateAlt){
		s/1061-04/1961-04/;
		s/2028-08/1928-08/;
		s/1004-04-20/2004-04-20/;
		s/1077-04/1977-04/;
		s/1080-05/1980-05/;
		s/1060-07/1960-07/;
		s/1061-04/1961-04/;
		
	}
	
###eventDate comes in properly formatted, so just put it through the subroutines
	if($eventDateAlt=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{4})$/){	#if eventDate is in the format 1957
		$YYYY=$1; 
		$MM = "Jan"; 
		$DD= "1";
		$MM2 = "Dec";
		$DD2 = "30";
	#warn "Date (00-6)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]([0-9]{4})$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(5)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]([0-9]{2})([0-9]{4})$/){
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([0-9]{1,2})[- ]*$/){
		$MM=$2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
	#warn "(19)$eventDateAlt\t$id";
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



####Construct scientific name from fields
$scientificName=$name;

###validate name
$scientificName=&strip_name($scientificName);

$scientificName = &validate_scientific_name($scientificName, $id);


########ELEVATIONS
foreach($verbatimElevation){
	s/\.\d+//; #remove the decimal place and everything after it
	s/ elev.*//;
	s/ <([^>]+)>/ $1/;
	s/^\+//;
	s/^\~/ca. /;
	s/zero/0/;
	s/,//g;
	s/(Ft|ft|FT|feet|Feet)/ ft/;
	s/(m|M|meters?|Meters?)/ m/;
	s/\.$//;
	s/  +/ /g;
	s/ *$//;
	}
$verbatimElevation .=" m" if $verbatimElevation;

####COLLECTOR NUMBER
if($fieldNumber){
	($prefix, $CNUM,$suffix)=&parse_CNUM($fieldNumber);
}
else{
	$prefix= $CNUM=$suffix="";
}

######COUNTY
foreach($county){
	s/^$/Unknown/;
   	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown)$/){
		$v_county= &verify_co($_);
		if($v_county=~/SKIP/){
			&log_skip("SKIPPED NON-CA county? $_\t$id");
			next Record;
		}   
		unless($v_county eq $_){
			&log_change("$_ -> $v_county\t$id");
			$_=$v_county;
	    }   
	}
}   

#####Latitude, Longitude, Datum, source, error radius
$Datum="";

if($verbatimLatitude=~/^-?1\d\d/){
	$hold=$verbatimLatitude;
	$verbatimLatitude=$verbatimLongitude;
	$verbatimLatitude=$hold;
	&log_change("lat and long reversed; corrected for CCH\t$id");
}

if(($verbatimLatitude=~/\d/  || $verbatimLongitude=~/\d/)){ #If decLat and decLong are both digits
	$Datum = "not recorded"; #since they aren't sending a datum yet, set it for records with coords

	if ($verbatimLongitude > 0) {
		$verbatimLongitude="-$verbatimLongitude";	#make decLong negative if positive
		&log_change("longitude made negative\t$id")
	}
	if($verbatimLatitude > 42.1 || $verbatimLatitude < 32.5 || $verbatimLongitude > -114 || $verbatimLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
		&log_change("coordinates set to null, Outside California: >$verbatimLatitude< >$verbatimLongitude<\t$id");	#print this message in the error log...
		$verbatimLatitude =$verbatimLongitude=$Datum=$georeferenceSources="";	#null everything
	}
}
elsif ($verbatimLatitude || $verbatimLongitude){
	&log_change("non-numeric or incomplete coordinates >$verbatimLatitude< >$verbatimLongitude< nulled\t$id");
	$verbatimLatitude =$verbatimLongitude=$Datum=$georeferenceSources="";
}

if ($coordinateUncertaintyInMeters){
	$coordinateUncertaintyInMeters=~s/\..*//; #remove decimal places
	$UncertaintyUnits = "meters";
}
else {$UncertaintyUnits = ""; }


#####COLLECTORS#######

$collector=$recordedBy;
$other_coll="";
$combined_colls=$recordedBy;

#print ti output file
		print OUT <<EOP;
Accession_id: $id
Name: $scientificName
Collector: $collector
Date: $eventDate
EJD: $EJD
LJD: $LJD
CNUM: $CNUM
CNUM_prefix: $prefix
CNUM_suffix: $suffix
Country: USA
State: $stateProvince
County: $county
Location: $locality
Elevation: $verbatimElevation
Other_coll: $other_coll
Combined_coll: $combined_colls
Decimal_latitude: $verbatimLatitude
Decimal_longitude: $verbatimLongitude
Lat_long_ref_source: $georeferenceSources
Datum: $Datum
Max_error_distance: $coordinateUncertaintyInMeters
Max_error_units: $UncertaintyUnits
Hybrid_annotation: $hybrid_annotation
Habitat: $eventRemarks
Annotation: $remarks

EOP
++$added;
}

my $skipped_taxa = $count-$included;
print <<EOP;
INCL: $included
ADD: $added
EXCL: $skipped{one}
EXCL_ADD: $skipped_2{one}
TOTAL: $count

SKIPPED TAXA: $skipped_taxa
EOP




