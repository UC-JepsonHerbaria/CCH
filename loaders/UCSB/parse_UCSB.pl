use utf8;
use Text::Unidecode; #to transliterate unicode characters to plan ASCII
use Geo::Coordinates::UTM;
#use strict;
#use warnings;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #loads alter_names has %alter, non-vascular genus has %exclude, county %max_elev hash, and various processing subroutines
my $today_JD = &get_today_julian_day;
&load_noauth_name; #load taxonID-to-scientificName hash %TID

open(OUT,">UCSB.out") || die;
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

#my $file = 'UCSB_103014.txt';
my $file = 'CCBER_CCH_20160425';

open(IN,$file) || die;

Record: while(<IN>){
	chomp;
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
$id="UCSB$catalogNumber"; #add "UCSB" prefix

####DATE####
###eventDate comes in properly formatted, so just put it through the subroutines
($YYYY, $MM, $DD)=&atomize_ISO_8601_date($eventDate);
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);

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
$scientificName=unidecode($scientificName);
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
$collector="";
$combined_colls="";
foreach($recordedBy){
	s/  ,/,/g;
	@colls=split(/; */,$_);
	foreach(@colls){
		s/(.*), *(.*)/$2 $1/;
	}
}
$collector=$colls[0];
$other_coll=join(", ",@colls[1 .. $#colls]);
$combined_colls=join(", ",@colls);

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
}
close OUT;

####create GUID file for GBIF processing
open(OUT,">AID_GUID_UCSB.txt") || die;
foreach(keys(%GUID)){
	print OUT "$_\t$GUID{$_}\n";
}
