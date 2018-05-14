#CAS input has 3 date fields: start date, end date, verbatim date
#apparently the verbatim date is not the most accurate depiction of the date
#This script put the start date into EJD and the end date into LJD and the verbatim date into date.
#This leads to dates apparently sorting out of order when JD and verbatimDate don't agree
# 536  iconv -f utf-16 -t utf-8 *export* >CAS_utf8.tab
print "fix type variables in this script\n";
use Geo::Coordinates::UTM;
use Time::JulianDay;
use Time::ParseDate;
use HTML::Entities;

use lib '/Users/davidbaxter/DATA';
use CCH; #loads non-vascular plant names list ("mosses"), alter_names table, and max_elev values
&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array

open(OUT, ">CAS.out") || die;

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $file = 'newest_dump/CASBotanyCCH2016-01-12.txt';

open (CSV, $file) or die $!;
while(<CSV>){
	s/\cM//g;
	chomp;
	&CCH::check_file;
	@fields=split(/\t/,$_,100);
	next unless $fields[1];
	$aid=join("",@fields[0,1]);
	$seen{$aid}++;

}
close(CSV);


open (CSV, $file) or die $!;

while (<CSV>) {
s/\cM//g;
	chomp;
	s/\c@//;
	s/\cK/ /g;
	s/\^//g;

my @columns = split(/\t/,$_,100);
grep(s/ *$//,@columns);
if ($#columns !=31){
	&log_skip("Not 32 fields: $_", @columns);
	warn "bad record $#columns not 32  $_\n";
	next;
	}
#Herbarium	AccessionNumber	FullTaxonName	Collectors	StartDate	CollectionNumber	County	Locality	Habitat	SpecimenDescription	TRS	UTM	latitude1	longitude1	LatLongMethod	Notes	ElevMin	ElevMax	ElevUnits	TypeStatus	Determiner	DetDate	OrigTypeName	CollectionObjectID	EndDate	VerbatimDate	Barcode	datum	GeorefUncertainty	GeorefUncertaintyUnit	GUID	GeoRefSource
	($Herbarium, 
	$AccessionNo, 
	$scientificName,  
	$Collectors, 
	$DATE, 
	$CollNumber, 
	$County, 
	$Locality, 
	$Habitat, 
	$Description, 
	$Geo_Township, 
	$UTM, 
	$Latitude1, 
	$Longitude1, 
	$LatLong_Method, 
	$notes,
	$elev_min,
	$elev_max, 
	$elev_units, 
	$type_status, 
	$determiner, 
	$det_date, 
	$type_name, 
	$CollectionObjectID, #field not present in Aug2014 load, but included in following load
	$end_date, 
	$verbatim_date, 
	$barcode, 
	$datum,	
	$GeorefUncertainty,	
	$GeorefUncertaintyUnit,
	$GUID,
	$georefSource )=@columns;

$GUID{$id}=$GUID;

########ACCESSION NUMBER
#This if-elsif statement is used to remove byte order marks (BOMs)
#I tried using open_bom in File::BOM but it messed with the times signs
if ($Herbarium =~ /DS/) {
	$Herbarium = "DS";
}
elsif ($Herbarium =~ /CAS/) {
	$Herbarium = "CAS";
}

next if $AccessionNo=~m/marin/;
$id="$Herbarium$AccessionNo";

unless($id){
	&log_skip("No accession id", @columns);
}

if($seen{$id}>1){
	&log_skip("Duplicate number", @columns);
	print "Duplicate number";
	next;
}
#This bit used to skip cultivated plants
#Although now we don't want to skip cultivated plants, so I've commented it out
#still useful information for indicating cultivatedness
#	if($id=~/^(CAS20685|CAS924364|CAS1154629)$/){
#		&log_skip("Alleged cultivated plant", @columns);
#		next;
#	}





###########Georeference Source
if ($georefSource){
	$source=$georefSource;
}
elsif($LatLong_Method){
	$source=$LatLong_Method;
}
else{
	$source="";
}


########COORDINATES
$GeorefUncertainty="" unless $GeorefUncertaintyUnit;


#######UTM
#calculates coordinates if no Latitude
if($UTM){
	$zone= $easting= $northing="";
	unless ($Latitude1){
		if($UTM=~m/Zone (\d+) (\d\d\d\d\d\d)E (\d\d\d\d\d\d\d)N/){
			$zone=$1;
			$easting=$2;
			$northing=$3;
		}
		if($zone){
			$zone="11S" if $zone==11;
			$zone="10S" if $zone==10;
			$ellipsoid=23;
			if($zone=~/9|10|11|12/ && $easting=~/^\d\d\d\d\d\d/ && $northing=~/^\d\d\d\d\d\d/){
				($decimal_latitude,$decimal_longitude)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
				&log_change( "decimal derived from UTM $decimal_latitude, $decimal_longitude\t$id");
			}
			else{
				&log_change("UTM problem $zone $easting $northing\t$id");
			}
			$decimal_longitude="-$decimal_longitude" if $decimal_longitude > 0;
		}
	}
	else{
		&log_change("using latitude and longitude, not UTM\t$id");
	}
}

($decimal_latitude=$Latitude1)=~s/[^0-9.-]//g;
($decimal_longitude=$Longitude1)=~s/[^0-9.-]//g;


if(($decimal_latitude==0  || $decimal_longitude==0)){
	$decimal_latitude =$decimal_longitude="";
}
if(($decimal_latitude=~/\d/  || $decimal_longitude=~/\d/)){
	$decimal_longitude="-$decimal_longitude" if $decimal_longitude > 0;
	if($decimal_latitude > 42.1 || $decimal_latitude < 30.0 || $decimal_longitude > -114 || $decimal_longitude < -124.5){
		&log_change("coordinates set to null, Outside California: $id: >$decimal_latitude< >$decimal_longitude< $latitude $longitude");
		$decimal_latitude =$decimal_longitude="";
	}
}

#######DATUM
$datum="" if $datum=~/^Unk$/i;

########TRS
$TRS="$Geo_Township";
$TRS="" if $TRS=~s/NoTRS//i;


#############COLLECTORS
		@collectors=();
		$collector="";
		if($Collectors){
			@collectors=split(/; /,$Collectors);
			foreach(@collectors){
s/, Jr/_Jr/g;
				s/(.*), (.*)/$2 $1/;
s/_Jr/, Jr/g;
			}
			$collector=$collectors[0];
			if($#collectors >0){
				$other_coll=join(", ", @collectors[1 .. $#collectors]);
				$combined_collector=join(", ", @collectors);
			}
			else{
				$combined_collector="";
			}
		}



########COUNTY


#########################COUNTY/MPIO
if ($County=~/^N\/?A$/i){
	$County="unknown"
}
elsif ($County=~/N\/?A/i){
	#print "$id $County\n";
}
$County=~s/ *County//;
$County=~s/ *Municipality//;

foreach($County){
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown)$/){
		$v_county= &verify_co($_);
		if($v_county=~/SKIP/){
			&log_skip("NON-CA county? $_");
			++$skipped{one};
			next;
		}

		unless($v_county eq $_){
			&log_change("county spelling: $_ -> $v_county\t$id");
			$_=$v_county;
		}
	}
}

#		unless($County=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown)$/i){
#			unless ($County=~/^ *$/){
#			&log_change("County set to unknown: $County\t$id");
#			}
#			$County="Unknown";
#		}


#######SCIENTIFIC NAME
$scientificName="" if $scientificName=~/^No name$/i;
unless($scientificName){
	&log_skip("No name: $id", @columns);
	next;
}
foreach($scientificName){
	s/ sp\.//;
	s/ forma / f. /;
	s/ ssp / subsp. /;
	s/ spp\.? / subsp. /;
	s/ var / var. /;
	s/ ssp\. / subsp. /;
	s/ f / f\. /;
	s/ × / X /;
	s/ x / X /;
	s/\?$//;
	s/ var\. *$//;
	s/ subsp\. *$//;
	s/ ssp\. *$//;
	s/\(ined\.\)//g;
	s/ined\.//g;
	s/NULL//;
	s/ *$//;
	s/  */ /g;

}
	
$scientificName=ucfirst($scientificName);
if($scientificName=~/  /){
	if($scientificName=~/^[A-Z][a-z]+ [a-z]+ +[a-z]+$/){
		&log_change("$scientificName: var. added $id");
		$scientificName=~s/^([A-Z][a-z]+ [a-z]+) +([a-z]+)$/$1 var. $2/;
	}
}
if($scientificName=~/CV\.? /i){
	&log_skip("Can't deal with cultivars yet: $id", $scientificName);
	next;
}

#make hybrid annotation from name
if($scientificName=~/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation=$scientificName;
	$scientificName=$1;
}
elsif($scientificName=~/^([A-Z][a-z-]+ [a-z-]+) (var\.|subsp\.) hybrids?$/){
	$hybrid_annotation=$scientificName;
	$scientificName=$1;
}
elsif($scientificName=~/^([A-Z][a-z-]+ [a-z-]+) hybrids?$/){
	$hybrid_annotation=$scientificName;
	$scientificName=$1;
}
elsif($scientificName=~/([A-Z][a-z-]+ [a-z-]+ .*) X /){
	$hybrid_annotation=$scientificName;
	$scientificName=$1;
}
elsif($scientificName=~/(.*) hybrids?/){
	$hybrid_annotation=$scientificName;
	$scientificName=$1;
}
else{
	$hybrid_annotation="";
}

########Validate scientific name
($genus=$scientificName)=~s/ .*//;
if($exclude{$genus}){
	&log_skip("Non-vascular plant: $id", @columns);
	next;
}

$scientificName = &validate_scientific_name($scientificName, $id);




#####TYPE STATUS AND NOTES
###type status is concatenated into notes for now, since right now it appears that
###The field called "Type Status" does not actually go anywhere in consort_bulkload.pl
###or anywhere after that.
##
if($type_name){
	$type_status=$type_name;
	warn "TYPE $type_name\n";
}
elsif($type_status){
	warn "TYPE $type_status\n";
}
else{
	$type_status="";
}

$type_status=~s/<\\?em>//g;


$notes="" if $notes=~/^None$/;

if ($notes && $type_status){
	$notes="$type_status; notes";
}
elsif ($type_status) { $notes=$type_status; }
elsif ($notes) { $notes=$notes }
else { $notes=""; }


#######ELEVATION AND UNITS#######
$elevation="";
$elev_max=~s/\.00//;
$elev_min=~s/\.00//;

if ($elev_units eq "unspecified" && $elev_min > 4400) {
	$elevation="$elev_min ft";
	&log_change ("Elevation <4400, units assumed to be feet: $elev_min $elev_units\t$id");
}
elsif ($elev_units eq "unspecified") {
	$elevation="";
	&log_change ("Elevation nulled because units unspecified: $elev_min $elev_max $elev_units\t$id");
}
###########
elsif($elev_min && $elev_max && ($elev_max > $elev_min)){
$elevation="$elev_min-$elev_max $elev_units";
}
elsif($elev_min){
$elevation="$elev_min $elev_units";
}
elsif($elev_max){
$elevation="$elev_max $elev_units";
}

$elevation="" unless $elevation;
$elevation=~s/\.0//g;


#########COLLECTOR
$collector= "" unless $collector;
$collector= "" if $collector=~/^None$/i;
$collector=~s/^ *//;
$collector=~s/  +/ /g;
$collector=~s/([A-Z]\.)([A-Z]\.)([A-Z][a-z])/$1 $2 $3/g;
$collector=~s/([A-Z]\.)([A-Z]\.) ([A-Z][a-z])/$1 $2 $3/g;
		$collector= $alter_coll{$collector} if $alter_coll{$collector};
if($combined_collector){
	$combined_collector=~s/et al$/et al./;
	$combined_collector=~s/([A-Z]\.)([A-Z]\.)([A-Z][a-z])/$1 $2 $3/g;
	$combined_collector=~s/([A-Z]\.)([A-Z]\.) ([A-Z][a-z])/$1 $2 $3/g;
	$combined_collector=~s/([A-Z]\.)([A-Z][a-z])/$1 $2/g;
	$combined_collector=~s/  +/ /g;
		$combined_collector= $alter_coll{$combined_collector} if $alter_coll{$combined_collector};
}
else{
$combined_collector="";
$other_coll="";
}

if($CollNumber){
	$collector= "Anonymous" unless $collector;
}



#######COLLECTION DATE
$date=$verbatim_date;
foreach($DATE, $end_date){
	s/ 00:.*//;
	s/^00//;
	s/__//;
	s/Unknown//i;
	s/ *$//;
}
if($DATE=~m|^([12][0789]\d\d)-(\d+)-(\d+)$|){
	$year=$1;
	$day_month=$3;
	$monthno=$2;
	$day_month=~s/^0//;
	$monthno=~s/^0//;
	$JD=julian_day($year, $monthno, $day_month);
}
else{$JD="";}
if($end_date=~m|^([12][0789]\d\d)-(\d+)-(\d+)$|){
	$year=$1;
	$day_month=$3;
	$monthno=$2;
	$day_month=~s/^0//;
	$monthno=~s/^0//;
	$LJD=julian_day($year, $monthno, $day_month);

	if($JD==$LJD){
		#CAS doesn't treat 1901 (for instance) as a range
		if($date=~m/^([12][0789]\d\d)$/){
					$LJD=julian_day($1, 12, 31);
		}
		if($date=~m/^[A-Z][a-z.]+ ([12][0789]\d\d)$/){
			unless ($date=~/Summer|Spring|Fall/i){
				if($monthno==12){
					$LJD+=30;
				}
				else{
					$LJD=julian_day($year, $monthno +1, 1);
					$LJD -= 1;
				}
			}
		}
	}
}
else{$LJD="";}


######CollNumber
if($CollNumber){
	($PREFIX, $CNUM,$SUFFIX)=&parse_CNUM($CollNumber);
}
else{
	$PREFIX=$CNUM=$SUFFIX="";
}


++$count_record;
warn "$count_record\n" unless $count_record % 5000;

if($Description=~s/(Fl.*(white|maroon|green|cream|yellow|red|blue|purple|orange|pink|lavender).*)//){
$color=$1;
}
else{
$color="";
}
if($Habitat=~m/ (with .*)/){
$Associates=$1;
}
else{
$Associates="";
}


#########Determination and Date
if($determiner){
	$annotation="$scientificName; $determiner";
	if($det_date){
		$det_date=~s/ 00:.*//;
		$annotation .="; $det_date";
	}
}
else{
	$annotation="";
}




            print OUT <<EOP;
Date: $date
EJD: $JD
LJD: $LJD
CNUM: $CNUM
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Name: $scientificName
Accession_id: $id
Country: USA
State: California
County: $County
Location: $Locality
T/R/Section: $TRS
Collector: $collector
Other_coll: $other_coll
Combined_collector: $combined_collector
Habitat: $Habitat
Associated_species: $Associates
Color: $color
Macromorphology: $Description
Latitude: $latitude
Longitude: $longitude
Decimal_latitude: $decimal_latitude
Decimal_longitude: $decimal_longitude
UTM: $UTM
Notes: $notes
Source: $source $LatLong_Method
Datum: $datum
Elevation: $elevation
Max_error_distance: $GeorefUncertainty
Max_error_units: $GeorefUncertaintyUnit
Hybrid_annotation: $hybrid_annotation
Annotation: $annotation
Type_status: 

EOP
}

warn "$count_record\n";
    close CSV;

open(OUT,">AID_GUID_CAS.txt") || die;
foreach(keys(%GUID)){
print OUT "$_\t$GUID{$_}\n";
}
sub skip {
print ERR "skipping: @_\n"
}
sub log {
print ERR "logging: @_\n";
}
