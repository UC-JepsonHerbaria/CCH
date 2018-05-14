
use Geo::Coordinates::UTM;
use strict;
#use warnings;
use Data::GUID;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH;
my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.

$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;

open(OUT,">/JEPS-master/CCH/Loaders/BLMAR/BLMAR_out.txt") || die;
open(OUT2,">/JEPS-master/CCH/Loaders/BLMAR/BLMAR_dwc.txt") || die;

print OUT2 "Accession_id\tscientificName\tverbatimEventDate\tEJD\tLJD\trecordedBy\tother_coll\tverbatimCollectors\tCNUM\tCNUM_prefix\tCNUM_suffix\tcountry\tstateProvince\tcounty\tlocality\thabitat\tTRS\tdecimalLatitude\tdecimalLongitude\tdatum\tgeoreferenceSource\terrorRadius\terrorUnits\tCCH_elevationInMeters\tverbatimElevation\tverbatim_county\tMacromorphology\tNotes\tCultivated\tHybrid_annotation\tAnnotation\tGUID\n";

my $error_log = 'log.txt';
unlink $error_log or warn "making new error log file $error_log";

my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;

my $file = '/JEPS-master/CCH/Loaders/BLMAR/data_files/BLMAR_OCT_2017_mod.txt';


#####process the file
###File arrives as an Excel xlsx file, with a lot of unfortunate in-cell line breaks
###Use find replace to remove "\n" to remove in-cell line breaks
###then save as a utf8 tab-delimited text file
###############


open(IN,$file) || die;
Record: while(<IN>){

	chomp;

	$line_store=$_;
	++$count;


#fix some data quality and formatting problems that make import of fields of certain records impossible
	s/\xc2\xb0/ deg. /g;
	s/ lggng/ logging/g;
	s/[Gg]rwng/growing/g;
	s/[Gg]rwing/growing/g;
	s/ begging/ beginning/g;
	s/lf lttr/leaf litter/g;
	s/[Gg]rwng/growing/g;
	s/[Gg]rwing/growing/g;
	s/ cmpgrnd/ campground/g;
	s/ crk/ creek/g;
	s/ rdg/ ridge/g;
	s/,/, /g;
	s/&/ & /g;
	s/'/ ' /g;
	s/:/: /g;
	s/ w\// with /g;
	s/ @ / at /g;
	s/ mxd hrdwd frst/ mixed hardwood forest/g;
	s/thru\/out/throughout/g;
	s/thruout/throughout/g;
	s/ Tbdecommisioned/ to be decommisioned/g;
	s/  +/ /g;

	
#	&CCH::check_file;
		#s/\cK/ /g;
        if ($. == 1){#activate if need to skip header lines
			next;
		}
		
my $id;
my $GUID;
my $country;
my $stateProvince;
my $county;
my $tempCounty;
my $locality; 
my $family;
my $scientificName;
my $name;
my $hybrid_annotation;
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
my $verbatimElevation;
my $elevation;
my $elev_feet;
my $elev_meters;
my $CCH_elevationInMeters;
my $elevationInMeters;
my $elevationInFeet;
my $verbatimLongitude;
my $verbatimLatitude;
my $TRS;
my $UTME;
my $UTMN; 
my $habitat;
my $latitude;
my $decimalLatitude;
my $longitude;
my $decimalLongitude;
my $datum;
my $notes;
my $errorRadius;
my $errorUnits;
my $georeferenceSource;
my $associatedSpecies;	
my $plant_description;
my $abundance;
my $associatedTaxa;
my $cultivated; #add this field to the data table for cultivated processing, place an "N" in all records as default
my $location;
my $commonName;
#unique to this dataset	
my $localityDetails;

	
	my @fields=split(/\t/,$_,100);
		unless($#fields==16){ #17 fields but first field is field 0 in perl
		&log_skip("$#fields bad field number $_");
		++$skipped{one};
		next Record;
	}
	
#note that if the fields change. The field headers can be found in Excel file
#Scientific name	Common name	Locality	T/R/S	Latitude	Longitude	Datum	Locality Details	Habitat Description	Plant Description	Elevation	County	Collection number	Collection Code	Collection date	Collecter
	
($cultivated,
$name,
$commonName,
$location,
$TRS,
$verbatimLatitude,
$verbatimLongitude,
$datum,
$localityDetails,
$habitat,
$plant_description,
$verbatimElevation,
$tempCounty,
$recordNumber,
$id,
$verbatimEventDate,
$verbatimCollectors
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
	s/^0+//g;
	s/ +//;
	s/^ *//g;
	s/ *$//g;

  

}

$GUID = Data::GUID->new;
#Add prefix, 
#prefix already added in file
	

#Remove duplicates
if($seen{$id}++){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}




#####Annotations  (use when no separate annotation field)
	#format det_string correctly
my $det_date;
my $det_rank = "current determination (uncorrected)";  #set to text in data with only a single determination
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
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet, $det_determiner";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) >=1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_date";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) >=1)){
		$det_string="$det_rank: $det_name, $det_date";
	}
	elsif ((length($det_name) >=0) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) >=0)){
		$det_string="$det_rank:";
	}
	else{
		$det_string="$det_rank: $det_name $det_stet, $det_determiner,  $det_date";
	}




##########Begin validation of scientific names


###########SCIENTIFICNAME
#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($name){
	s/\?//g;
	s/\(//g;
	s/\)//g;
	s/;$//g;
	s/cf.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/  +/ /g;
	s/^ *//g;
	s/ *$//g;

	}


#format hybrid names
if($name =~ m/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation = $name;
	warn "Hybrid Taxon: $1 removed from $name\n";
	&log_change("Hybrid Taxon: $1 removed from $name");
	$name=$1;
}
else{
	$hybrid_annotation="";
}

#####process taxon names



$scientificName = &strip_name($name);

if (($id =~ m/^BLMAR345$/) && (length($name) == 0)){ #Fix one record of a monocot with no determination
	$scientificName = "Liliaceae";
	&log_change("Scientific name modified from Null value:\t$scientificName\t--\t$id\n");
}
if (($id =~ m/^BLMAR548$/) && ($name =~ m/^Navarretia pilosissima/)){ #Fix one record of a name that has been a long remained undescribed/problematic determination
	$scientificName = "Navarretia";
	&log_change("Scientific name Navarretia pilosissima not published, modified to just genus:\t$scientificName\t--\t$id\n");
}

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



##########COLLECTION DATE##########
my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;
my $formatEventDate;


$eventDate = $verbatimEventDate;

foreach ($eventDate){
	s/Junly/July/;
	s/,/ /g;
	s/\./ /g;
		s/  +/ /;
		s/^ +//;
		s/ +$//;
	}
	

	if ($eventDate=~/^(\d{1,2}) ([A-Za-z]+) +(\d\d\d\d)/){
		$DD=$1;
		$MM=$2;
		$YYYY=$3;
		$DD=~s/^0//;
	}
	
	elsif ($eventDate=~/^([0-9]{1,2}) ?[-&] ?([0-9]{1,2}) ([A-Za-z]+) +(\d\d\d\d)/){
		$DD=$1;
		$DD2=$2;
		$MM=$3;
		$MM2=$3;
		$YYYY=$4;
		$DD=~s/^0//;
		$DD2=~s/^0//;
	}
	
	elsif ($eventDate=~/^(\d\d*)-([A-Za-z]+)-(\d\d)/){
		$DD=$1;
		$MM=$2;
		$YYYY="20$3";
	}
	elsif ($eventDate=~/^([A-Za-z]+) (\d\d\d\d)/){
		$MM=$1;
		$YYYY=$2;
	}
	elsif ($eventDate=~/^([A-Za-z]+)-(\d\d)/){
		if ($2=~m/82/){
			$MM=$1;
			$YYYY="19$2";
		}
		else{
			$MM=$1;
			$YYYY="20$2";
		}
	}
	elsif ($eventDate=~/.+/){
	&log_change("date format not recognized: $eventDate\t--\t$id\n");
	}
	
	else {
	$eventDate = "";
	$YYYY = "";
	$DD = "";
	$MM = "";
	&log_change("No date: $id")
	}

#convert to YYYY-MM-DD for eventDate and Julian Dates

$MM = &get_month_number($MM, $id, %month_hash);
$MM2 = &get_month_number($MM2, $id, %month_hash);

$formatEventDate = "$YYYY-$MM-$DD";
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




($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $MM2, $DD2, $id);
#warn "$formatEventDate\t--\t$EJD, $LJD\t--\t$id";
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);


###############COLLECTORS

foreach ($verbatimCollectors){
	s/'$//g;
	s/, M\. ?D\.//g;
	s/, Jr\./ Jr./g;
	s/, Jr/ Jr./g;
	s/, Esq./ Esq./g;
	s/, Sr\./ Sr./g;
		s/  +/ /;
		s/^ +//;
		s/ +$//;
}
$collector = ucfirst($verbatimCollectors);

	
	if ($collector =~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collector, $id);	
	#D Atwood; K Thorne
		$other_coll=$2;
		#warn "Names 1: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
		&log_change("COLLECTOR (): modified: $verbatimCollectors==>$collector--\t$recordedBy\t--\t$other_coll\t$id\n");	
	}
	
	elsif ($collector !~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collector, $id);
		#warn "Names 2: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
	}
	elsif (length($collector == 0)) {
		$recordedBy = "Unknown";
		&log_change("COLLECTOR (2): modified from NULL to $recordedBy\t$id\n");
	}	
	else{
		&log_change("COLLECTOR (3): name format problem: $verbatimCollectors==>$collector\t--$id\n");
	}


###further process other collectors
foreach ($other_coll){
	s/'$//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;

}
$other_collectors = ucfirst($other_coll);


if ((length($recordedBy) > 1) && (length($other_collectors) > 1)){
	#warn "Names 1: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";}
}
elsif ((length($recordedBy) > 1) && (length($other_collectors) == 0)){
	#warn "Names 2: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
}
elsif ((length($collector) == 0) && (length($other_collectors) == 0)){
	$recordedBy =  $other_collectors = $verbatimCollectors = "";
	&log_change("Collector name NULL\t$id\n");
}
else {
		&log_change("Collector name problem\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}

#############CNUM##################COLLECTOR NUMBER####

#my $CNUM_suffix;
#my $CNUM;
#my $CNUM_prefix;


#####COLLECTOR NUMBER####

foreach ($recordNumber){
	s/#//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

my $CNUM_suffix="";
($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);





####COUNTRY

####Country and State always U.S.A.[or U. S. A.]/CA, unless left blank, which still means USA/CA
my $stateProvince = "CA"; #all specimens from BLMAR are from California
my $country="USA";

###########COUNTY###########

	foreach ($tempCounty){
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

foreach ($location){
	s/ {2,}/ /g;
}

foreach ($localityDetails){
	s/ {2,}/ /g;
}

if ($location && $localityDetails){
	$locality="$location, $localityDetails";
}
elsif (($localityDetails=~/[a-z]+/) && (length($location) == 0)){
	$locality=$localityDetails;
}
else {
	$locality=$location;
}
    
	if((length($location) > 1) && (length($localityDetails) == 0)){ 
		$locality = $location;
	}		
	elsif ((length($location) > 1) && (length($localityDetails) >1)){
		$locality = "$location, $localityDetails";
		$locality =~ s/'$//;
		$locality =~ s/ +$//;
		$locality =~ s/  +/ /;
	}
	elsif ((length($location) == 0) && (length($localityDetails) >1)){
		$locality = $localityDetails;
		$locality =~ s/: *$//;
		$locality =~ s/'$//;
		$locality =~ s/ +$//;
		$locality =~ s/  +/ /;
	}
	else {
		&log_change("Locality problem, bad format, $id\t--\t$location--\t$localityDetails\n");		#call the &log function to print this log message into the change log...
	}
    
###############ELEVATION########
foreach($verbatimElevation){
	s/,//g;
	s/\.//g;
	s/(\d) (\d+)/$1$2/g;
		s/  +/ /;
		s/^ +//;
		s/ +$//;
}

#verify if elevation fields are just numbers
if ($verbatimElevation=~"#"){
	&log_change("Elevation value ($elevation) not recognized as elevation\t $id\n");
	$verbatimElevation="";
}

my $feet_to_meters="3.2808";

#$elevationInMeters is the darwin core compliant value


#process verbatim elevation fields into CCH format
if (length($verbatimElevation) >= 1){

	if ($verbatimElevation =~ m/^(-?[0-9]+) +([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^<?(-?[0-9]+)([fFtT]+)/){ #added <? to fix elevation in BLMAR421 being skipped
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+) +([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$verbatimElevation";
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$verbatimElevation";
		$CCH_elevationInMeters =~ s/m$/ m/;
	}
	elsif ($verbatimElevation =~ m/^[A-Za-z ]+ +(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$verbatimElevation";
		$CCH_elevationInMeters =~ s/m$/ m/;
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+)-(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^[A-Za-z ]+ +(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^[A-Za-z]+ +(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("Check elevation: '$verbatimElevation' problematic formatting or missing units\t$id");
		$elevationInMeters="";
	}	
}
elsif (length($verbatimElevation) == 0){
		$elevationInMeters=$CCH_elevationInMeters = "";
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


foreach ($verbatimLatitude, $verbatimLongitude){
		s/4589"/ 45.89/;
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
		s/’/ /g; #this was copied from the error log, must be different character coding than above
		s/”/ /g; #this was copied from the error log, must be different character coding than above
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
					print "2b) $decimalLatitude\t--\t$id\n";
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
					print "5b) $decimalLongitude\t--\t$id\n";
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
					print "6a) $decimalLongitude\t--\t$id\n";
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
elsif ((length($latitude) == 0) && (length($longitude) == 0)){ 
#UTM is not present in these data, skipping conversion of UTM and reporting if there are cases where lat/long is problematic only
		&log_change("COORDINATE: No coordinates for $id\n");
		$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
}
else {
			&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
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


foreach($georeferenceSource){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
	}	
	

#Error Units
#none in BLMAR
#foreach ($errorRadius){
#		s/  +/ /g;
#		s/^ +//;
#		s/ +$//;
#}

#none in BLMAR
#foreach ($errorRadiusUnits){
#		s/  +/ /g;
#		s/^ +//;
#		s/ +$//;
#}

#final check of Longitude
if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			&log_change("COORDINATE Longitude made negative\t--\t$id");
	}
#final check for rough out-of-boundary coordinates
	if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114.0 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california and northern Baja...
	###was 32.5 for California, now 30.0 to include CFP-Baja
		&log_change("COORDINATE set to null for $id, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";	#and set $decLat and $decLong to ""  
	}
}
else {
		if((length($decimalLatitude) == 0)  && (length($decimalLatitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $id: ($decimalLatitude) \t($decimalLatitude)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}


##############TRS
foreach($TRS){
	s/(S[0-9][0-9]) *.* *([0-9][0-9]) *.* *([0-9][0-9])/$1S$2S$3/g;
	s/,//g;
	s/\.//g;
	s/[Ss]ecf/Sec/g;
	s/ {1,}//g;
}




#######Plant Description (dwc ??) and Abundance (dwc occurrenceRemarks)


foreach ($plant_description){
		s/'$//;
		s/  +/ /;
}

#######Habitat and Assoc species (dwc habitat and associatedTaxa)
foreach ($habitat){
		s/'$//;
		s/  +/ /;
}



print OUT2 join("\t",
$id,
$scientificName,
$verbatimEventDate,
$EJD,
$LJD,
$recordedBy,
$other_coll,
$verbatimCollectors,
$CNUM,
$CNUM_prefix,
$CNUM_suffix,
$country,
$stateProvince,
$county,
$locality,
$habitat,
$TRS,
$decimalLatitude,
$decimalLongitude,
$datum,
$georeferenceSource,
$errorRadius,
$errorUnits,
$CCH_elevationInMeters,
$verbatimElevation,
$tempCounty,
$plant_description,
$notes,
$cultivated,
$hybrid_annotation,
$det_string,
$GUID), "\n";

	print OUT <<EOP;
Accession_id: $id
Name: $scientificName
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
Collector: $recordedBy
Other_coll: $other_coll
Combined_coll: $verbatimCollectors
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Country: $country
State: $stateProvince
County: $county
Location: $locality
Habitat: $habitat
Associated_species:
T/R/Section: $TRS
USGS_Quadrangle:
UTM:
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance:
Max_error_units:
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Macromorphology: $plant_description
Notes:
Cultivated: $cultivated
Hybrid_annotation: $hybrid_annotation
Annotation: $det_string

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

    my $file_out = '/JEPS-master/CCH/Loaders/BLMAR/BLMAR_out.txt';	#the file this script will act upon is called 'BLMAR.out'
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

