#CAS input has 3 date fields: start date, end date, verbatim date
#apparently the verbatim date is not the most accurate depiction of the date
#This script put the start date into EJD abd the end date into LJD and the verbatim date into date.
#This leads to dates apparently sorting out of order sometimes.
# 536  iconv -f utf-16 -t utf-8 *export* >CAS_utf8.tab
print "fix type variables in this script\n";
#die;
		use Geo::Coordinates::UTM;

use Time::JulianDay;
use Time::ParseDate;



open(OUT, ">new_CAS") || die;


open(IN,"/Users/richardmoe/4_CDL_BUFFER/smasch/mosses") || die;
while(<IN>){
        chomp;
next if m/^#/;
        s/\s.*//;
        $exclude{$_}++;
}




open(IN,"../CDL/alter_names") || warn "no alternative name file\n";
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
	open(IN,"/Users/richardmoe/4_DATA/taxon_ids/smasch_taxon_ids.txt") || die;
	while(<IN>){
	chomp;
	($id,$name, $residue)=split(/\t/);
	$taxon{$name}=$id;
}
open(ERR,">CAS_error");

#Herbarium	AccessionNumber	AccessionSuffix	FullTaxonName	Collectors	StartDate	CollectionNumber	County	Locality	Habitat	Description	Township	Range	Section	latitude1	longitude1	LatLongMethod	Notes	ElevMin	ElevMax	ElevUnits	TypeStatus	Determiner	DetDate	OrigTypeName	OrigTypeStatus	CollectionObjectID
#CAS	264638		Carex nigricans	Cooke, William Bridge	1938-07-18 00:00:00.000	11484	Siskiyou	Springs, Mt. Shasta. 										8200.0	8200.0	ft		Reznicek, A.A. 	2003-01-01 00:00:00.000			-2110174089
	#new fields
	#June 6 2011
#Herbarium       AccessionNumber AccessionSuffix FullTaxonName   Collectors      StartDate       CollectionNumber        County  Locality        Habitat Description     Township        Range   Section latitude1       longitude1      LatLongMethod   Notes   ElevMin ElevMax ElevUnits       TypeStatus      Determiner      DetDate OrigTypeName    OrigTypeStatus  CollectionObjectID      EndDate VerbatimDate
	#CAS     1118164         Pholistoma membranaceum York, Dana      1996-03-14 00:00:00     329     Kern    Ca. 11 km NE of Bakersfield, adjacent to Hwy 178 at the mouth of the Kern River Canyon.         Around the base of shoulders and in cracks in the rock outcrop S of highway. Associates: Bromus diandrus, Calandrinia ciliata, Encelia actoni, Lamarckia aurea, Mirabilis multiflora var. pubescens, Pentagramma pallida, Phacelia cicutaria, and Scrophularia californica var. floribunda.     A common vine.  28S     30E     31, SW 1/4 of SE 1/4                                    230     230     m                                               -2147317839     1996-03-14 00:00:00     14 March 1996
	#CAS     845831          Linanthus harknessii    Bartholomew, Bruce; Anderson, Barrett   1990-07-20 00:00:00     5517    Modoc   Tamarack Flat, E side of Warner Mts.    Moist meadow in Lodgepole Pine forest.  Annual. 46N     15E     2       41.8866000000   -120.2181000000 TRS             2150    2150    m                                               -2147078542     1990-07-20 00:00:00     20 Jul 1990

#Herbarium	AccessionNumber	FullTaxonName	Collectors	StartDate	CollectionNumber	County	Locality	Habitat	SpecimenDescription	TRS	UTM	latitude1	longitude1	LatLongMethod	Notes	ElevMin	ElevMax	ElevUnits	TypeStatus	Determiner	DetDate	OrigTypeName	CollectionObjectID	EndDate	VerbatimDate	Barcode
#CAS	1118164	Pholistoma membranaceum	Dana York	1996-03-14	329	Kern County	Ca. 11 km NE of Bakersfield, adjacent to Hwy 178 at the mouth of the Kern River Canyon.	Around the base of shoulders and in cracks in the rock outcrop S of highway. Associates: Bromus diandrus, Calandrinia ciliata, Encelia actoni, Lamarckia aurea, Mirabilis multiflora var. pubescens, Pentagramma pallida, Phacelia cicutaria, and Scrophularia californica var. floribunda.	A common vine.							230	230	m					14	1996-03-14	14 March 1996	000065174



	##my $file = 'CAS_CCHexport/CAS_utf8.tab';
	#my $file = 'june_6.txt';
    #open (CSV, $file) or die $!;
#while(<CSV>){
	#chomp;
	#@fields=split(/\t/,$_,100);
	#next unless $fields[1];
	#$aid=join("",@fields[0,1,2]);
	#$seen{$aid}++;
	#$long_aid{$aid} .="$fields[-3];";
	#$long_aid=$aid . "-" . $fields[-3];
	#$store{$fields[-3]}=$long_aid;
#
#}



	my $file = 'CAS_MAY.txt';
	#my $file = 'CASBotanyCCH.txt';
	#my $file = 'CAS_noret.txt';
    open (CSV, $file) or die $!;
while(<CSV>){
s/\cM//g;
	chomp;
	@fields=split(/\t/,$_,100);
#print "$aid: $fields[-4]  $fields[-3] $fields[-2] $fields[-1]\n";
	next unless $fields[1];
next if $fields[1]=~m/marin/;
	$aid=join("",@fields[0,1]);
	$seen{$aid}++;
if($fields[-1]){
	$long_aid{$aid} .="$fields[-1];";
	$long_aid=$aid . "-" . $fields[-1];
	$store{$fields[-1]}=$long_aid;
}
else{
	$long_aid{$aid} .="$fields[-4];";
	$long_aid=$aid . "-" . $fields[-4];
	$store{$fields[-4]}=$long_aid;
}

}




close(CSV);
foreach(sort(keys(%seen))){
	if($seen{$_} > 1){
		foreach $la (split(/;/,$long_aid{$_})){
			$disamb{$la}=$_ . "-$la";
			print "new number $disamb{$la}\n";
		}
	}
}
die;
%seen=();


open (CSV, $file) or die $!;

while (<CSV>) {
s/\cM//g;
$edm="";
	$elevation="";
	chomp;
	s/\c@//;
	s/\cK/ /g;
	s/\^//g;
s/Ã±/&ntilde;/g;
    my @columns = split(/\t/,$_,100);
	grep(s/ *$//,@columns);
    if ($#columns !=29){
		&skip("Not 30 fields: $_", @columns);
		warn "bad record $#columns not 29  $_\n";
		next;
	}
##Herbarium	AccessionNumber	AccessionSuffix	FullTaxonName	Collectors	StartDate	CollectionNumber	County	Locality	Habitat	Description	Township	Range	Section	latitude1	longitude1	LatLongMethod	Notes	ElevMin	ElevMax	ElevUnits	TypeStatus	Determiner	DetDate	OrigTypeName	OrigTypeStatus	CollectionObjectID
	#Herbarium	AccessionNumber	FullTaxonName	Collectors	StartDate	CollectionNumber	County	Locality	Habitat	              SpecimenDescription	TRS	UTM	latitude1	longitude1	LatLongMethod	Notes	ElevMin	ElevMax	ElevUnits	TypeStatus	Determiner	DetDate	OrigTypeName	CollectionObjectID	EndDate	VerbatimDate	Barcode
#Herbarium	AccessionNumber	FullTaxonName	Collectors	StartDate	CollectionNumber	County	Locality	Habitat	SpecimenDescription	TRS	UTM	latitude1	longitude1	LatLongMethod	Notes	ElevMin	ElevMaxElevUnits	TypeStatus	Determiner	DetDate	OrigTypeName	CollectionObjectID	EndDate	VerbatimDate	Barcode	datum	GeorefUncertainty	GeorefUncertaintyUnit

	($Herbarium, $AccessionNo, $name,  $Collectors, $DATE, $CollNumber, $County, $Locality, $Habitat, $Description, $Geo_Township, $UTM, $Latitude1, $Longitude1, $LatLong_Method, $Notes,$elev_min,$elev_max, $elev_units, $type_status, $determiner, $det_date, $type_name, $CollectionObjectID, $end_date, $verbatim_date, $barcode, $datum,	$GeorefUncertainty,	$GeorefUncertaintyUnit )=@columns;
#next;
#if($type_status){
#print "$AccessionNo $name status: $type_status TN: $type_name\n";
#}
#next;

next if $AccessionNo=~m/marin/;
	$ACCESSNO="$Herbarium$AccessionNo";
	if($seen{$ACCESSNO}++){
		&skip("Duplicate number", @columns);
		print "Duplicate number";
		next;
	}
	if($disamb{$barcode}){
		$ACCESSNO= $disamb{$barcode};
		&log("using $ACCESSNO to disambiguate duplicate herbarium number");
		print "using $ACCESSNO to disambiguate duplicate herbarium number\n";
	}
	elsif($disamb{$CollectionObjectID}){
		$ACCESSNO= $disamb{$CollectionObjectID};
		&log("using $ACCESSNO to disambiguate duplicate herbarium number");
		print "using $ACCESSNO to disambiguate duplicate herbarium number\n";
	}
	#if($seen{$ACCESSNO}++){
		#&skip("Duplicate record", @columns);
		#print "Duplicate record  $_\n";
		#next;
	#}
	$extent="" unless $ExtUnits;
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
					&log( "$ACCESSNO decimal derived from UTM $decimal_latitude, $decimal_longitude\n");
				}
				else{
					&log("$ACCESSNO UTM problem $zone $easting $northing\n");
				}


				$decimal_long="-$decimal_long" if $decimal_long > 0;
			}


		}
		else{
			&log("$ACCESSNO using latitude, not UTM\n");
		}
	}
#$Geo_Township=~s/T//;
#$Geo_Range=~s/R//;
$TRS="$Geo_Township";
	($decimal_latitude=$Latitude1)=~s/[^0-9.-]//g;
	($decimal_longitude=$Longitude1)=~s/[^0-9.-]//g;
#foreach $i ( 0 .. $#columns){
#print "$i $columns[$i]\n";
#}
#next;
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

		unless($ACCESSNO){
			&skip("No accession id", @columns);
		}

		if ($County=~/^N\/?A$/i){
			$County="unknown"
		}
		elsif ($County=~/N\/?A/i){
			#print "$ACCESSNO $County\n";
		}
$County=~s/ *County//;
		unless($County=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|unknown)/i){
			unless ($County=~/^ *$/){
			&log("County set to unknown: $ACCESSNO $County");
			}
			$County="Unknown";
		}
		$name="" if $name=~/^No name$/i;
			unless($name){
				&skip("No name: $ACCESSNO", @columns);
				next;
			}
			($genus=$name)=~s/ .*//;
			if($exclude{$genus}){
				&skip("Non-vascular plant: $ACCESSNO", @columns);
				next;
			}
			$name=ucfirst($name);
			if($name=~/  /){
				if($name=~/^[A-Z][a-z]+ [a-z]+ +[a-z]+$/){
					&log("$name: var. added $ACCESSNO");
					$name=~s/^([A-Z][a-z]+ [a-z]+) +([a-z]+)$/$1 var. $2/;
				}
				$name=~s/  */ /g;
			}
			if($name=~/CV\.? /i){
				&skip("Can't deal with cultivars yet: $ACCESSNO", $name);
				#$badname{$name}++;
				next;
			}
			foreach($name){
s/ sp\.//;
				s/ forma / f. /;
				s/ ssp / subsp. /;
				s/ spp\.? / subsp. /;
				s/ var / var. /;
				s/ ssp\. / subsp. /;
				s/ f / f\. /;
s/ × / X /;
				s/ x / X /;
				#s/ [xX] / × /;
s/\?$//;
s/ var\. *$//;
s/ subsp\. *$//;
s/ ssp\. *$//;
			}
			if($name=~/([A-Z][a-z-]+ [a-z-]+) X /){
				$hybrid_annotation=$name;
				#warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/^([A-Z][a-z-]+ [a-z-]+) (var\.|subsp\.) hybrids?$/){
				$hybrid_annotation=$name;
				#warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/^([A-Z][a-z-]+ [a-z-]+) hybrids?$/){
				$hybrid_annotation=$name;
				#warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/([A-Z][a-z-]+ [a-z-]+ .*) X /){
				$hybrid_annotation=$name;
				#warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/(.*) hybrids?/){
				$hybrid_annotation=$name;
				#warn "$1 from $name\n";
				$name=$1;
			}
			else{
				$hybrid_annotation="";
			}

			if($alter{$name}){
				&log ("Spelling altered to $alter{$name}: $name");
				$name=$alter{$name};
			}
			unless($taxon{$name}){
				$on=$name;
				if($name=~s/subsp\./var./){
					if($taxon{$name}){
						&log("Not yet entered into SMASCH taxon name table: $on entered as $name");
					}
					else{
						&skip("Not yet entered into SMASCH taxon name table: $on skipped");
						++$badname{$name};
						next;
					}
				}
				elsif($name=~s/var\./subsp./){
		if($taxon{$name}){
&log("Not yet entered into SMASCH taxon name table: $on entered as $name");
		}
		else{
&skip("Not yet entered into SMASCH taxon name table: $on skipped");
++$badname{$name};
next;
		}
	}
	else{
&skip("Not yet entered into SMASCH taxon name table: $on skipped");
++$badname{$name};
	next;
	}
}

#unless($taxon{$name}){
#&skip("$name not in SMASCH, skipped: $ACCESSNO");
#$badname{$name}++;
#next;
#}
$TRS="" if $TRS=~s/NoTRS//i;
$notes="" if $Notes=~/^None$/;
$elev_max=~s/\.00//;
$elev_min=~s/\.00//;
if($elev_min && $elev_max && ($elev_max > $elev_min)){
$elevation="$elev_min-$elev_max $elev_units";
}
elsif($elev_min){
$elevation="$elev_min $elev_units";
}
elsif($elev_max){
$elevation="$elev_max $elev_units";
}
#if($elevation && ($elevation > 15000 || $elevation < -1000)){
#&log("Elevation set to null: $ACCESSNO: $elevation");
#$elevation="";
#}
#$elevation= "$elevation ft" if $elevation;
$elevation="" unless $elevation;
$elevation=~s/\.0//g;
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
$badcoll{$collector}++ unless $COLL{$collector};
$badcoll{$combined_collector}++ unless $COLL{$combined_collector};
if($CollNumber){
$collector= "Anonymous" unless $collector;
}
if(($decimal_latitude==0  || $decimal_longitude==0)){
$decimal_latitude =$decimal_longitude="";
}
if(($decimal_latitude=~/\d/  || $decimal_longitude=~/\d/)){
$decimal_longitude="-$decimal_longitude" if $decimal_longitude > 0;
if($decimal_latitude > 42.1 || $decimal_latitude < 32.5 || $decimal_longitude > -114 || $decimal_longitude < -124.5){
&log("coordinates set to null, Outside California: $ACCESSNO: >$decimal_latitude< >$decimal_longitude< $latitude $longitude");
$decimal_latitude =$decimal_longitude="";
}
}
$datum="" if $datum=~/^Unk$/i;
#$LOCALITY=~s/^"(.*)"$/$1/;
#$HABDESCR=~s/^"(.*)"$/$1/;
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
$edm=$3;
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
#CAS doesn't treat Apr. 1901 (for instance) as a range
#if($day_month==1 && $edm==1){
	#unless($date=~/ 1[, ]/){
		#if($monthno==12){
			#$LJD+=30;
		#}
		#else{
			#$LJD=julian_day($year, $monthno +1, 1);
			#$LJD -= 1;
		#}
	#}
#}
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
if ($LJD != $JD){
	#warn "3 $ACCESSNO $DATE, $end_date, $date, $JD, $LJD\n" if $DATE eq $end_date;
}
if ($LJD == $JD){
	#warn "4 $ACCESSNO $DATE, $end_date, $date, $JD, $LJD\n" if $DATE ne $end_date;
}
if ($DATE ne $end_date){
	#warn "1 $ACCESSNO $DATE, $end_date, $date, $JD, $LJD\n" if $JD == $LJD;
}
if ($DATE eq $end_date){
	#warn "2 $ACCESSNO $DATE, $end_date, $date, $JD, $LJD\n" if $JD != $LJD;
}
#unless ($DATE && $end_date){
	#warn "5 $ACCESSNO $DATE, $end_date, $date, $JD, $LJD\n";
#}
#next;

$PREFIX= $CNUM= $SUFFIX="";
foreach($CollNumber){
if(s| *1/2||){
$SUFFIX="1/2";
}
if(m/^(\d+)(.*)/){
$PREFIX="";
$CNUM=$1;
$SUFFIX=$2;
}
elsif(m/(.*[^0-9])(\d+)(.*)/){
$PREFIX=$1;
$CNUM=$2;
$SUFFIX=$3;
}
else{
$PREFIX=$_;
$CNUM="";
$SUFFIX="";
}
}
++$count_record;
warn "$count_record\n" unless $count_record % 5000;
#($Herbarium, $AccessionNo, $AccNoSuffix, $name, $Collectors, $DATE, $CollNumber, $County, $Locality, $Locality_continued, $Habitat, $Description, $Geo_Township, $Geo_Range, $Geo_Section, $Latitude1, $Longitude1, $LatLong_Method, $Notes)=@columns;
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
if($determiner){
$annotation="$name; $determiner";
if($det_date){
$det_date=~s/ 00:.*//;
$annotation .="; $det_date";
}
}
else{
$annotation="";
}


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
            print OUT <<EOP;
Date: $date
EJD: $JD
LJD: $LJD
CNUM: $CNUM
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Name: $name
Accession_id: $ACCESSNO
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
Notes: $Notes
Source: $LatLong_Method
Datum: $datum
Elevation: $elevation
Max_error_distance: $GeorefUncertainty
Max_error_units: $GeorefUncertaintyUnit
Hybrid_annotation: $hybrid_annotation
Annotation: $annotation
Type_status: $type_status

EOP
        }
warn "$count_record\n";
    close CSV;

open(OUT,">CSV_badcoll") || die;
foreach(sort(keys(%badcoll))){
print OUT "$_: $badcoll{$_}\n";
}
open(OUT,">CSV_badname") || die;
foreach(sort(keys(%badname))){
print OUT "$_: $badname{$_}\n";
}
sub skip {
print ERR "skipping: @_\n"
}
sub log {
print ERR "logging: @_\n";
}
