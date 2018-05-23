use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/richardmoe/4_data/CDL';
use CCH;

sub log {
print ERR "logging: @_\n";
}

open(IN,"../CDL/riv_non_vasc") || die;
while(<IN>){
        chomp;
        $exclude{$_}++;
}


open(OUT, ">new_HUH") || die;
open(IN,"../CDL/alter_names") || warn "no alternative name file\n";
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(IN,"/Users/richardmoe/4_data/taxon_ids/smasch_taxon_ids.txt") || die;
while(<IN>){
	chomp;
($code,$name,@rest)=split(/\t/);
	$taxon{$name}++;
}
#open(IN,"/users/rlmoe/CDL_buffer/buffer/tnoan.out") || die;
#while(<IN>){
	#chomp;
	#($id,$name)=split(/\t/);
	#$taxon{$name}=$id;
#}
open(ERR,">HUH_error");

%seen=();

$file="huh_out.tab";
open (CSV, $file) or die $!;

while (<CSV>) {
$elevation="";
	chomp;
	@fields=split(/\t/,$_, 1000);
	unless($#fields == 49){
		print "$.: $#fields $_\n";
		die;
	}
	foreach(@fields){
		s/^"//;
		s/"$//;
		s/""/"/g;
	}
	($institution, $collectioncode, $collectionid, $catalognumber, $catalognumbernumeric, $dc_type, $basisofrecord, $collectornumber, $collector, $sex, $reproductiveStatus, $preparations, $verbatimdate, $eventdate, $year, $month, $day, $startdayofyear, $enddayofyear, $startdatecollected, $enddatecollected, $habitat, $highergeography, $continent, $country, $stateprovince, $islandgroup, $county, $island, $municipality, $locality, $minimumelevationmeters, $maximumelevationmeters, $verbatimelevation, $decimallatitude, $decimallongitude, $geodeticdatum, $identifiedby, $dateidentified, $identificationqualifier, $identificationremarks, $identificationreferences, $typestatus, $scientificname, $scientificnameauthorship, $family, $informationwitheld, $datageneralizations, $othercatalognumbers,$update)=@fields;
#print "$scientificname  ";
#print "$scientificnameauthorship\n";
#next;
	unless($country=~/United States of America/){
		&log("Country not USA: $country: $ACCESSNO");
		next;
	}
	unless($stateprovince=~/^California$/){
		&log("State not California: $stateprovince $ACCESSNO");
		next;
	}
	if($county){
		$county=~s/ County//;
		#print "$county\n";
	}
	else{
		$county="unknown";
	}
	($Herbarium, $AccessionNo, $name,  $Collectors, $DATE, $CollNumber, $County, $Locality, $Habitat, $Description, $Latitude1, $Longitude1, $datum, $LatLong_Method, $Notes,$elev_min,$elev_max, $elev_units, $type_status, $determiner, $det_date, $verbatim_date)=
	($collectioncode, $catalognumbernumeric, $scientificname, $collector, $eventdate, $collectornumber, $county, "$municipality $locality", $habitat, $datageneralizations, $decimallatitude, $decimallongitude, $geodeticdatum, "", "", $minimumelevationmeters, $maximumelevationmeters, "m", $typestatus, $identifiedby, $dateidentified, $eventdate);

foreach($name){
s/Rhus integrifolia \(Nuttall\) Bentham & Hooker f. ex W. H. Brewer & S. Watson/Rhus integrifolia/;
}
			$name=ucfirst($name);
	$ACCESSNO="$Herbarium$AccessionNo$AccNoSuffix";
	if($seen{$ACCESSNO}++){
		&log("Duplicate $ACCESSNO");
		next;
	}
	$extent="" unless $ExtUnits;
	($decimal_latitude=$Latitude1)=~s/[^0-9.-]//g;
	($decimal_longitude=$Longitude1)=~s/[^0-9.-]//g;




		@collectors=();
		$collector="";
		if($Collectors){
$Collectors=~s/, Jr/ Jr/g;
		@collectors=split(/, /,$Collectors);
		foreach(@collectors){
		s/(.*), (.*)/$2 $1/;
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
			&skip("No accession id", @fields);
		}

		if ($County=~/^N\/?A$/i){
			$County="unknown"
		}
		elsif ($County=~/N\/?A/i){
			#print "$ACCESSNO $County\n";
		}
		unless($County=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|unknown)/i){
			unless ($County=~/^ *$/){
			&log("County set to unknown: $ACCESSNO $County");
			}
			$County="Unknown";
		}
		$name="" if $name=~/^No name$/i;
			unless($name){
				&skip("No name: $ACCESSNO", @fields);
				next;
			}
			($genus=$name)=~s/ .*//;
			if($exclude{$genus}){
				&skip("Non-vascular plant: $ACCESSNO", @fields);
				next;
			}
			$name=ucfirst($name);
$name=~s/st\.-nicolai/sancti-nicolai/ && do{
				&log ("Spelling altered to sancti-nicolai: st.-nicolai");
};
foreach ($name){
s/\303\227/X /g;
#s/Ceanothus .*lobbianus Hooker/Ceanothus X lobbianus/;
#s/Ceanothus .*lorenzenii \(Jepson\) McMinn/Ceanothus X lorenzii/;
#s/Quercus ..ganderi/Quercus X ganderi/;
#s/Quercus ..grandidentata/Quercus X grandidentata/;
#s/Quercus ..macdonaldii/Quercus X macdonaldii/;
#s/Quercus ..morehus/Quercus X morehus/;
#s/Elymus ..hansenii/Elymus X hansenii/;
#s/Elymus ..saundersii/Elymus X saundersii/;
#s/Spiraea ..nobleana/Spiraea X nobleana/;
}
$name=&strip_name($name);
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
s/ sp\.?$//;
				s/ forma / f. /;
				s/ ssp / subsp. /;
				s/ spp\.? / subsp. /;
				s/ var / var. /;
				s/ ssp\. / subsp. /;
				s/ f / f\. /;
				#s/ [xX] / × /;
			}
			if($name=~/([A-Z][a-z-]+ [a-z-]+) × /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/^([A-Z][a-z-]+ [a-z-]+) hybrids?$/){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/([A-Z][a-z-]+ [a-z-]+ .*) × /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
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
						++$badname{"$family $on"};
						next;
					}
				}
				elsif($name=~s/var\./subsp./){
		if($taxon{$name}){
&log("Not yet entered into SMASCH taxon name table: $on entered as $name");
		}
		else{
&skip("Not yet entered into SMASCH taxon name table: $on skipped");
++$badname{"$family $on"};
next;
		}
	}
	else{
&skip("Not yet entered into SMASCH taxon name table: $on skipped");
++$badname{"$family $on"};
	next;
	}
}
#print "$name\t$family\t$scientificnameauthorship\n" unless $scientificnameauthorship=~m/\) /;

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
#$startdatecollected
#$enddatecollected
			if($startdatecollected=~m|^([12][0789]\d\d)-(\d+)-(\d+)$|){
					$year=$1;
					$day_month=$3;
					$monthno=$2;
					$day_month=~s/^0//;
					$monthno=~s/^0//;
					$JD=julian_day($year, $monthno, $day_month);
			}
			else{$JD="";}
			if($enddatecollected=~m|^([12][0789]\d\d)-(\d+)-(\d+)$|){
					$year=$1;
					$day_month=$3;
					$monthno=$2;
					$day_month=~s/^0//;
					$monthno=~s/^0//;
					$LJD=julian_day($year, $monthno, $day_month);
			}
			else{$LJD="";}

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
Max_error_distance: $extent
Max_error_units: $ExtUnits
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
sub _strip_name{
local($_) = @_;
print "$_\t" if m/Quercus/;
s/^ *//;
				s/ forma / f. /;
				s/ ssp / subsp. /;
				s/ spp\.? / subsp. /;
				s/ var / var. /;
				s/ ssp\. / subsp. /;
				s/ f / f\. /;
				#s/ [xX] / × /;
s/ x / X /;
s/Fragaria × ananassa Duchesne var. cuneifolia \(Nutt. ex Howell\) Staudt/Fragaria × ananassa var. cuneifolia/ ||
s/Trifolium variegatum Nutt. phase (\d)/Trifolium variegatum phase $1/ ||
s/^([A-Z][a-z]+) (X?[-a-z]+).*(subsp.) ([-a-z]+).*(var\.) ([-a-z]+).*/$1 $2 $3 $4 $5 $6/ ||
s/^([A-Z][a-z]+ [a-z]+) (× [-A-Z][a-z]+ [a-z]+).*/$1 $2/ ||
s/^([A-Z][a-z]+) (× [-a-z]+).*/$1 $2/ ||
s/^([A-Z][a-z]+) (X?[-a-z]+).*(ssp\.|var\.|f\.|subsp.) ([-a-z]+).*/$1 $2 $3 $4/ ||
s/^([A-Z][a-z]+) (X?[-a-z]+).*/$1 $2/||
s/^([A-Z][a-z]+) [A-Z(].*/$1/;
print "$_\n" if m/Quercus/;
return ($_);
}


#$collectioncode
#$collectionid
#$catalognumber
#$startdayofyear
#$enddayofyear
#$startdatecollected
#$enddatecollected
