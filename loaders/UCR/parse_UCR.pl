######N.B. The UCR parser still has some major issues
######In particular, julian days are not being computed
######And the coordinate processing is very convoluted and probably needs to be redone

#use Carp; #to use "croak" instead of "die"
use utf8;
use Text::Unidecode; #to transliterate unicode characters to plan ASCII
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


####INSERT NAMES OF RIVERSIDE FILES
#Note that most recent time Riverside data came with MS line breaks
#Open them in TextWrangler and Save As with Unix line breaks
my $images_file="UCRImages20170303.tab";
my $dets_file="UCRDetHis20170303.tab";
my $records_file="UCRData20170303.tab";


my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
#unique to this dataset
my $Img_ID;
my $IMG;
my $ANNO;
my $Accession_Number;
my $det_AID;
my $det_rank;
my $det_family;
my $det_name,
my $det_determiner;
my $det_year;
my $det_month;
my $det_day;
my $det_stet;



open(OUT,">UCR.out.txt") || die;

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";



#process the images
#Note that the file might have Windows line breaks
open(IN, "$images_file") || die;
while(<IN>){

my $Img_URL="";

	chomp;
	
	#UCR_7	UCR-17017	http://ucr.ucr.edu/specimens/Dicots/Onagraceae/Gayophytum/heterozygum/UCR0000006m.png
	#$Accession_Number refers to the AID within the context of working on the images file (cf. "$id)
	($Img_ID,
	$Accession_Number,
	$Img_URL) = split(/\t/);

	#can't deal with halves and thirds yet
	next if ($Img_URL =~/( top| middle| bottom)/i);
	$Accession_Number=~s/-//;
	$IMG{$Accession_Number} = "$Img_URL";
}


###process the determinations
#Note that the file might have Windows line breaks
open(IN, "$dets_file") || die;
while(<IN>){

my $det_string="";

	chomp;
	($det_AID,
	$det_rank,
	$det_family,
	$det_name,
	$det_determiner,
	$det_year,
	$det_month,
	$det_day,
	$det_stet) = split(/\t/);
	
my $det_AID=~s/-//;
	
	if ($det_year && $det_month && $det_day) {
		$det_date = "$det_month $det_day, $det_year";
	}
	elsif ($det_year && $det_month) {
		$det_date = "$det_month $det_year";
	}
	elsif ($det_year) {
		$det_date = "$det_year";
	}
	else {
		$det_date = "";
	}
	
	$det_string="$det_name, $det_determiner, $det_date, $det_stet";
	$ANNO{$det_AID}.="Annotation: $det_string\n";
}

	


open(IN,$records_file ) || die;


#fix some data quality and formatting problems that make import of fields of certain records impossible
#in this data see the &prune_fields foreach statement below



Record: while(<IN>){
	chomp;
	
	$line_store=$_;
	++$count;


&CCH::check_file;	
my $id;
my $country;
my $stateProvince;
my $county;
my $locality; 
my $family;
my $scientificName;
my $name;
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
my $UTME;
my $UTMN; 
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
my $georeferenceSources;
my $associatedSpecies;	
my $plant_description;
my $phenology;
my $abundance;
my $associatedTaxa;
my $cultivated; #add this field to the data table for cultivated processing, place an "N" in all records as default
my $location;
my $localityDetails;
my $commonName;
#unique to this dataset
my $Coll_no_prefix;	
my $Coll_no;
my $Coll_no_suffix;
my $genus_doubted;
my $sp_doubted;
my $family_code;
my $physiographic_region;
my $topo_quad;
my $lat_uncertainty;
my $long_uncertainty;
my $Snd_township;
my $Snd_Range;
my $Snd_section;
my $Snd_Fraction_of_section;
my $subsp_doubted;
my $hybrid_category;
my $Snd_genus;
my $Snd_genusDoubted;
my $Snd_species;
my $Snd_species_doubted;
my $Snd_subtype;
my $Snd_subtaxon;
my $Snd_subtaxon_doubted;
my $determiner;
my $det_year;
my $det_mo;
my $det_day;
my $CollectorSiteUniquifier;
my $UTM_grid_cell;
my $name_of_UTM_cell;
my $E_or_W;
my $N_or_S;
my $origin;
	
	my @fields=split(/\t/,$_,100);
	
	unless($#fields == 71){	#if the number of values in the columns array is exactly 72

	&log_skip ("$#fields bad field number $_\n");
	}

#fix more data quality and formatting problems
	foreach $i (0 .. $#fields){
		$fields[$i]=&prune_fields($fields[$i]);
	}
	
#then process the full records	
(
$id,
$collector,
$Coll_no_prefix,
$Coll_no,
$Coll_no_suffix,
$coll_year,
$coll_month,
$coll_day,
$Associated_collectors,
$family, #10
$family_code,
$genus,
$genus_doubted,
$species,
$sp_doubted,
$rank,
$subtaxon,
$subsp_doubted,
$hybrid_category,
$Snd_genus, #20
$Snd_genusDoubted,
$Snd_species,
$Snd_species_doubted,
$Snd_subtype,
$Snd_subtaxon,
$Snd_subtaxon_doubted,
$determiner,
$det_year,
$det_mo,
$det_day, #30
$CollectorSiteUniquifier, # unique locality ID added by Ed Plummer 2015-09. Not using for anything yet
$country,
$stateProvince,
$county, #$county_mpio in original data
$physiographic_region,
$topo_quad,
$locality,
$lat_degrees,
$lat_minutes,
$lat_seconds, #40
$N_or_S,
$verbatimLatitude, #$decimal_lat in original data
$lat_uncertainty,
$long_degrees,
$long_minutes,
$long_seconds,
$E_or_W,
$verbatimLongitude, #$decimal_lon in original data
$long_uncertainty,
$Township, #50
$Range,
$Section,
$Fraction_of_section,
$Snd_township,
$Snd_Range,
$Snd_section,
$Snd_Fraction_of_section,
$zone,
$UTM_grid_cell,
$UTME, #60
$UTMN,
$name_of_UTM_cell,
$minimumElevationInMeters,
$maximumElevationInMeters,
$minimumElevationInFeet,
$maximumElevationInFeet,
$habitat, #ecol_notes in original data
$georeferenceSources,
$plant_description,
$phenology, #70
$cultivated, #original data is Culture field, coopted for the Cultivated processing, field nulled and 'P' added for cultivated specimens
$origin,
) = @fields;

########Not processing Baja data, for now
#They always have State recorded, either as CA or BCN
#If you want the names, do this after the names are processed
#unless ($state=~/^CA$/){
#        &log_skip("not publishing Baja California records yet: $id");
#		++$skipped{one};
#		next Record;
#}
#############

#######ACCESSION IDS
$id=~s/-//;
unless($id=~/^UCR\d/){
	&log_skip("No UCR accession number, skipped: $_");
	++$skipped{one};
	next Record;
}
if($seen{$fields[0]}++){
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate accession number, skipped: $id");
	++$skipped{one};
	next Record;
}


$plant_description{$plant_description}++;
#$plant{$plant}++;
$phenology{$phenology}++;
$culture{$culture}++ if $culture;
$origin{$origin}++ if $origin;

$orig_lat_min=$lat_minutes;
$orig_long_min=$long_minutes;
$decimal_lat="" if $decimal_lat eq 0;
$decimal_long="" if $decimal_long eq 0;


##############SCIENTIFIC NAME
#Format name parts
$genus=ucfirst(lc($genus));
$species=lc($species);
$subtaxon=lc($subtaxon);
$subtype=~s/ssp\.?/subsp./;

#construct name
$scientificName=$genus ." " .  $species . " ".  $subtype . " ".  $subtaxon;
$scientificName=~s/Unknown//;
$scientificName=~s/ *$//;
#added to try to remove the word "unknown" for some records

#format hybrid names
if($scientificName=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
	$hybrid_annotation=$scientificName;
	#warn "$1 from $scientificName\n";
	&log_change("Hybrid Taxon: $1 removed from $scientificName");
	$scientificName=$1;
}
else{
	$hybrid_annotation="";
}

$scientificName=&strip_name($scientificName);
$scientificName=&validate_scientific_name($scientificName, $id);


########################COLLECTORS
$Collector_full_name=$collector;
($Collector_full_name,$Associated_collectors)=&munge_collectors ($Collector_full_name,$Associated_collectors);





#####COLLECTOR NUMBERS
#clean up collector numbers, prefixes and suffixes
$Coll_no=~s/ *$//;
$Coll_no=~s/^ *//;
if($Coll_no=~s/-$//){
	$Coll_no_suffix="-$Coll_no_suffix";
}
if($Coll_no=~s/^-//){
	$Coll_no_prefix.="-";
}
if($Coll_no=~s/^([0-9]+)(-[0-9]+)$/$2/){
	$Coll_no_prefix.=$1;
}
if($Coll_no=~s/^([0-9]+)(\.[0-9]+)$/$1/){
	$Coll_no_suffix=$2 . $Coll_no_suffix;
}
if($Coll_no=~s/^([0-9]+)([A-Za-z]+)$/$1/){
	$Coll_no_suffix=$2 . $Coll_no_suffix;
}
if($Coll_no=~s/^([0-9]+)([^0-9])$/$1/){
	$Coll_no_suffix=$2 . $Coll_no_suffix;
}
if($Coll_no=~s/^(S\.N\.|s\.n\.)$//){
	$Coll_no_suffix=$1 . $Coll_no_suffix;
}
if($Coll_no=~s/^([0-9]+-)([0-9]+)([A-Za-z]+)$/$2/){
	$Coll_no_suffix=$3 . $Coll_no_suffix;
	$Coll_no_prefix.=$1;
}
if($Coll_no=~m/[^\d]/){
	$Coll_no=~s/(.*)//;
	$Coll_no_suffix=$1 . $Coll_no_suffix;
}



####COUNTRY
$country="USA" if $country=~/U\.?S\.?/;
$country="Mexico" if $country=~/M\.?X\.?/;

#########################COUNTY/MPIO





	foreach($county_mpio){
	
	
	s/Unknown/unknown/;
	
	if((length($county_mpio) == 0) && ($country{$id} =~m/Mexico/)){
		&log_change("Mexico record with unknown or blank county field\t$id\t--\t$locality");
			++$skipped{one};
			next Record;
	}
	if(($county_mpio=~m/unknown/) && ($country{$id} =~m/Mexico/)){
		&log_change("Mexico record with unknown or blank county field\t$id\t--\t$locality");
			++$skipped{one};
			next Record;
	}
	
	s/^$/unknown/;	
		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown)$/){
			$v_county= &verify_co($_);
			if($v_county=~/SKIP/){
				&log_skip("NON-CA county? $_");
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){
				&log_change("county spelling: $_ -> $v_county\t$fields[0]");
				$_=$v_county;
			}


		}
		$county{$_}++;
	}


######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}


###ASSOCIATED SPECIES FROM ECOLOGY NOTES
if($ecol_notes=~s/[;.] +([Aa]ssoc.*)//){
	$assoc=$1;
}
else {$assoc="";}

#########################ELEVATION
$elevation="";

if($low_range_m){
	if($top_range_m){
		$elevation="$low_range_m - $top_range_m m";
	}
	else{
		$elevation="$low_range_m m";
	}
}
elsif($low_range_f){
	#these incorrectly labelled "m" first loading!
	if($top_range_f){
		$elevation="$low_range_f - $top_range_f ft";
	}
	else{
		$elevation="$low_range_f ft";
	}
}
$elev_test=$elevation;
$elev_test=~s/.*- *//;
$elev_test=~s/ *\(.*//;
$elev_test=~s/ca\.? *//;
if($elev_test=~s/ (meters?|m)//i){
	$metric="(${elev_test} m)";
	$elev_test=int($elev_test * $meters_to_feet);
	$elev_test.= " feet";
}
else{
	$metric="";
}
if($elev_test=~s/ +(ft|feet)//i){
	if($elev_test > $max_elev{$county_mpio}){
		$discrep=$elev_test-$max_elev{$county_mpio};
		$discrep="$id\t$county_mpio $elev_test vs $max_elev{$county_mpio}: elevation discrepancy=$discrep";
		&log_change($discrep);
		warn "$id\t$county_mpio $elev_test vs $max_elev{$county_mpio}: discrepancy=", $elev_test-$max_elev{$county_mpio},"\n";
	}
}


######COORDINATES
$lat_degrees= $lat_minutes= $lat_seconds= $N_or_S= $long_degrees= $long_minutes= $long_seconds= "";


$long_minutes=~ s/['`]//g;
$lat_minutes=~ s/['`]//g;
$lat_degrees=~ s/^(\d\d)[^\d]$/$1/g;
$long_degrees=~ s/^(\d\d\d)[^\d]$/$1/g;
if($long_minutes=~ s/^(\d*)(\.\d+)$/$1/){
	$long_minutes="00" if $long_minutes eq "";
	$minute_decimal=$2;
	$long_seconds= int($minute_decimal * 60);
}
if($lat_minutes=~ s/^(\d*)(\.\d+)$/$1/){
	$lat_minutes="00" if $lat_minutes eq "";
	$minute_decimal=$2;
	$lat_seconds= int($minute_decimal * 60);
}

if($lat_seconds=~/(\d+)\.[01234].*/){ #rounding down lat seconds
	$lat_seconds=$1;
}
elsif($lat_seconds=~/(\d+)\.[56789].*/){ #rounding up lat seconds
	$lat_seconds=${1}+1;
}
if($long_seconds=~/(\d+)\.[01234].*/){
	$long_seconds=$1;
}
elsif($long_seconds=~/(\d+)\.[56789].*/){
	$long_seconds=${1}+1;
}
if($lat_seconds && $lat_seconds==60){ #translating 60 seconds into +1 minute
	$lat_seconds="00";
	$lat_minutes +=1;
	if($lat_minutes==60){
		$lat_minutes="00";
		$lat_degrees +=1;
	}
}
if($long_seconds && $long_seconds==60){
	$long_seconds="00";
	$long_minutes +=1;
	if($long_minutes==60){
		$long_minutes="00";
		$long_degrees +=1;
	}
}
$lat_minutes=~ s/^ *(\d)\./0$1./;
$lat_seconds=~ s/^ *(\d)\./0$1./;
$long_minutes=~ s/^ *(\d)\./0$1./;
$long_seconds=~ s/^ *(\d)\./0$1./;
$lat_minutes=~ s/^ *(\d) *$/0$1/;
$lat_seconds=~ s/^ *(\d) *$/0$1/;
$long_minutes=~ s/^ *(\d) *$/0$1/;
$long_seconds=~ s/^ *(\d) *$/0$1/;
unless($lat_minutes eq $orig_lat_min){ #if lat minutes were modified, report it
	$coord_alter{"$orig_lat_min -> $lat_minutes $lat_seconds"}++;
}
unless($long_minutes eq $orig_long_min){
	$coord_alter{"$orig_long_min -> $long_minutes $long_seconds"}++;
}


$lat=$long="";
($lat= "${lat_degrees} ${lat_minutes} ${lat_seconds}$N_or_S")=~s/ ([EWNS])/$1/;
($long= "${long_degrees} ${long_minutes} ${long_seconds}$E_or_W")=~s/ ([EWNS])/$1/;
$lat=~s/^ *([EWNS])//;
$long=~s/^ *([EWNS])//;
$lat=~s/^ *//;
$long=~s/^ *//;

if($long){
	unless ($long=~/\d\d\d \d\d? \d\d?W/ || $long=~/\d\d\d \d\d?W/ || $long=~/\d\d\d \d\d? \d\d?\.\dW/){
		&log_change("$id: Longitude $long config problem; lat and long nulled");
		$long="";
		$lat="";
	}
	unless($lat =~ /\d/){
		$long="";
		&log_change("$id: Longitude no latitude config problem; long nulled");
	}
}
if($lat){
	unless ($lat=~/\d\d \d\d? \d\d?N/ || $lat=~/\d\d \d\d?N/ || $lat=~/\d\d \d\d? \d\d?\.\dN/){
		&log_change("$id: Latitude $lat config problem; Lat and long nulled");
		$lat="";
		$long="";
	}
	unless($long=~/\d/){
		$lat="";
		&log_change("$id: Latitude no longitude config problem; lat nulled");
	}
}

#UTM ZONE
#convert UTM to decimal only if no other coordinate format was provided
$zone=$easting=$northing="";
unless(($decimal_lat || $decimal_long)){
	if($UTM_grid_zone){
		use Geo::Coordinates::UTM;
		$easting=$UTM_E;
		$northing=$UTM_N;
		$zone=$UTM_grid_zone;
		$zone=uc($zone);
		$ellipsoid=23;
		if($zone=~/(9|10|11|12)S/ && $easting=~/\d\d\d\d\d\d/ && $northing=~/\d\d\d\d\d/){
			#warn "$ellipsoid,$zone,$easting,$northing\n";
			($decimal_lat,$decimal_long)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
			warn  "$id UTM $decimal_lat, $decimal_long\n";
		}
		else{
			&log_change( "$id UTM problem $zone $easting $northing");
		}


		$decimal_long="-$decimal_long" if $decimal_long > 0;
	}  
}

###Finally, check that coordinates are inside the California box
if($decimal_lat){
	if($decimal_lat > 42.1 || $decimal_lat < 30.0 || $decimal_long > -114 || $decimal_long < -124.5){
		if($zone){
			&log_change("$id coordinates set to null, Outside California: $accession_id: UTM is $zone $easting $northing --> $decimal_lat $decimal_long");
		}
		else{
			&log_change("$id coordinates set to null, Outside California: D_lat is $decimal_lat D_long is $decimal_long lat is $lat long is $long");
		}
		$decimal_lat =$decimal_long="";
	}   
}

########UNCERTAINTY AND UNITS
if($long_uncertainty || $lat_uncertainty){
	$extent= ($long_uncertainty || $lat_uncertainty);
	$ExtUnits="m";
}
else{
	$extent= "";
	$ExtUnits="";
}

####TRS
$Unified_TRS="$Township$Range$section $Fraction_of_section";


##########DATES
foreach($month){
	s/August/Aug/;
	s/July/Jul/;
	s/April/Apr/;
	s/\.//;
}
$year=~s/ ?\?$//;
$year=~s/^['`]+//;
$year=~s/['`]+$//;
unless($year=~/^(1[789]\d\d|20\d\d)$/){
	&log_change("$id: Date config problem $year $month $day: date nulled");
	$year=$month=$day="";
}
unless($day=~/(^[0-3]?[0-9]$)|(^[0-3]?[0-9]-[0-3]?[0-9]$)|(^$)/){
	&log_change("$id: Date config problem $year $month $day: date nulled");
	$year=$month=$day="";
}


#"Annotation: $annotation" was removed
#because now the full det history is available (see below EOP)
#$family_code


print OUT <<EOP;
Accession_id: $id
Country: $country
Date: $month $day $year
CNUM_prefix: ${Coll_no_prefix}
CNUM: ${Coll_no}
CNUM_suffix: ${Coll_no_suffix}
Name: $scientificName
State: $state
County: $county_mpio
Location: $locality
T/R/Section: $Unified_TRS
USGS_Quadrangle: $topo_quad
Elevation: $elevation
Collector: $collector
Other_coll: $Associated_collectors
Combined_coll: $combined_collectors
Habitat: $ecol_notes
Associated_species: $assoc
Notes: $Plant_description
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Lat_long_ref_source: $georefSource
Max_error_distance: $extent
Max_error_units: $ExtUnits
Hybrid_annotation: $hybrid_annotation
Image: $IMG{$id}
Notes: $plant_description
Phenology: $phenology
Other: $physiographic_region
EOP

#usually, the blank line is included at the end of the block above
#but since the $ANNO{$id} is printed outside the block, the \n is after
print OUT $ANNO{$id};
print OUT "\n";

#print TABFILE $IMG{$id};
#print TABFILE "\n";

#add one to the count of included records
++$included;
}


print <<EOP;
INCL: $included
EXCL: $skipped{one}
EOP

open(OUT,">ucr_field_check") || die;
foreach(sort(keys(%plant_description))){
	print OUT "PD: $_\n";
}
#foreach(sort(keys(%plant))){
#	print OUT "P: $_\n";
#}
foreach(sort(keys(%phenology))){
	print OUT "Phen: $_\n";
}
foreach(sort(keys(%culture))){
	print OUT "C: $_\n";
}
foreach(sort(keys(%origin))){
	print OUT "O: $_\n";
}
