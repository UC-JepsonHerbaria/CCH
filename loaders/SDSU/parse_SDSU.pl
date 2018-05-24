open(OUT, ">SDSU_out_new") || die;
open(IN,"../CDL/alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(IN,"../CDL/riv_non_vasc") || die;
while(<IN>){
	chomp;
	if(m/\cM/){
	die;
	}
	$exclude{$_}++;
}
open(IN,"/Users/richardmoe/4_data/taxon_ids/smasch_taxon_ids.txt") || die;
while(<IN>){
	chomp;
	($id,$name,@residue)=split(/\t/);
	$taxon{$name}=$id;
}
open(ERR,">SDSU_error");
#open(IN,"Jepson_EXPORT_041708.tab") || die;
use utf8;
$file=
"SDSU2013.txt";
#"CCH_SDSU_Export-20120821.txt";
open(IN,"$file") || die;


while(<IN>){
	chomp;
	s/\cK/ /g;
s/Õ/'/g;
$hybrid_annotation=$annotation=$image="";
	$determiner=$PREFIX=$SUFFIX=$PlantDescr="";

#Accession ID    Determination   Collector       Collection Date Collection Number       County  Locality        Elevation in meters     Latitude        Longitude       Lat/Long Accuracy       Geology Community       Plant Description       Determinor      Determination Date      Specimen Notes

#NEW Accession ID	CACounty	Coll. Number	Collect. Date	Collector	Community	Determination	Determination Date	Determinor	Elevation in m.	Geology	Image	Latitude	LatLong Accuracy meters	Local.	Longitude	Plant Descr.	Specimen Notes
#OLD Accession ID    Determination   Collector   Collection Date Collection Number   County  Locality    Elevation in meters Latitude    Longitude   LatLong Accuracy    Geology Community   Plant Description   Determinor  Determination Date  Notes


($ACCESSNO, $name, $collector, $DATE, $NUMBER, $DISTRICT, $LOCALITY, $elevation, $decimal_latitude, $decimal_longitude, $accuracy, $Geology, $Community, $PlantDescr, $determiner,$det_date, $notes, $image)=split(/\t/);
@fields=split(/\t/);
print "$#fields\n" unless $seen{$fields}++;
	foreach
	($ACCESSNO, $collector, $DATE, $NUMBER, $DISTRICT, $Family, $name, $decimal_latitude, $decimal_longitude, $elevation, $PlantDescr, $Geology, $Community, $LOCALITY, $notes, $image, $accuracy){
		s/^"(.*)"$/$1/;
	}
foreach($accuracy){
s!\+/-!!;
s/'/ ft/;
s/  / /g;
}
if($accuracy=~/([0-9.]+) (.*)/){
$extent=$1; $ExtUnits=$2;
}
else{
$extent= $ExtUnits="";
}
	unless($ACCESSNO){
		&skip("No accession id", @columns);
	}
	if ($DISTRICT=~/^N\/?A$/i){
		$DISTRICT="unknown"
	}
	elsif ($DISTRICT=~/N\/?A/i){
		#print "$ACCESSNO $DISTRICT\n";
	}
	foreach($DISTRICT){
s/, .*//;
		s/Eldorado/El Dorado/;
		s/Humbolt/Humboldt/;
		s/Bernadino/Bernardino/;
		s/East San Diego/San Diego/;
	s/ Co\.? ?$//;
	s/ County ?$//;
	}
	unless($DISTRICT=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|unknown)/i){
		&log("County set to unknown: $ACCESSNO $DISTRICT");
		$DISTRICT="Unknown";
	}
	$name="" if $name=~/^No name$/i;
		$name=~s/ *$//;
$name=~s/  */ /g;
		$name=~s/ c\.?f\.//g;
		unless($name){
			&skip("No name: $ACCESSNO", @columns);
			next;
		}
		$name=~s/^ *//;
		($genus=$name)=~s/ .*//;
		$orig_name=$name;
		if($exclude{$genus}){
			&skip("Non-vascular plant: $ACCESSNO", @columns);
			next;
		}
		$name=ucfirst($name);
		foreach($name){
			s/ [Ss]sp / subsp. /;
			s/ spp\.? / subsp. /;
			s/ var / var. /;
			s/ [Ss]sp\. / subsp. /;
			s/ Subsp\. / subsp. /;
			s/ f / f\. /;
			s/ [xX] / X /;
			s/ sp\.//;
			s/\?//;
		}
		if($alter{$name}){
			&log ("Spelling altered to $alter{$name}: $name");
			$name=$alter{$name};
		}
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
		if($name=~/([A-Z][a-z-]+ [a-z-]+) X /){
			$hybrid_annotation=$name;
			warn "$1 from $name\n";
			$name=$1;
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
					++$badname{$orig_name};
					next;
				}
			}
			elsif($name=~s/var\./subsp./){
				if($taxon{$name}){
					&log("Not yet entered into SMASCH taxon name table: $on entered as $name");
				}
				else{
					&skip("Not yet entered into SMASCH taxon name table: $on skipped");
					++$badname{$orig_name};
					next;
				}
			}
			else{
				&skip("Not yet entered into SMASCH taxon name table: $on skipped");
				++$badname{$orig_name};
				next;
			}
		}
	
		$elevation="" if $elevation=~/N\/?A/i;
		$TRS="" if $TRS=~s/NoTRS//i;
		$notes="" if $notes=~/^None$/;
		if($elevation && ($elevation > 5000 || $elevation < -300)){
			&log("Elevation set to null: $ACCESSNO: $elevation");
			$elevation="";
		}
		$elevation .= " m" if $elevation;
		$elevation="" unless $elevation;
		$collector= "" unless $collector;
		$collector= "" if $collector=~/^None$/i;
		$collector=~s/^ *//;
		$collector=~s/  +/ /g;
		$collector=~s/([A-Z]\.)([A-Z]\.)([A-Z][a-z])/$1 $2 $3/g;
		$collector=~s/([A-Z]\.)([A-Z]\.) ([A-Z][a-z])/$1 $2 $3/g;
		#$collector= $alter_coll{$collector} if $alter_coll{$collector};
		#if($combined_collector){
			#$combined_collector=~s/et al$/et al./;
			#$combined_collector=~s/([A-Z]\.)([A-Z]\.)([A-Z][a-z])/$1 $2 $3/g;
			#$combined_collector=~s/([A-Z]\.)([A-Z]\.) ([A-Z][a-z])/$1 $2 $3/g;
			#$combined_collector=~s/([A-Z]\.)([A-Z][a-z])/$1 $2/g;
			#$combined_collector=~s/  +/ /g;
			#$combined_collector= $alter_coll{$combined_collector} if $alter_coll{$combined_collector};
			#if($collector){
				#$combined_collector= "$collector, $combined_collector";
			#}
			#else{
				#$collector=$combined_collector;
				#$combined_collector= "";
			#}
		#}
		#else{
			#$combined_collector="";
		#}
				$combined_collector= $collector;
unless($collector=~s/, .*// || $collector=~s/ and .*//){
			$combined_collector="";
}

		$badcoll{$collector}++ unless $COLL{$collector};
		$badcoll{$combined_collector}++ unless $COLL{$combined_collector};
		if($NUMBER=~/^(\d+)$/){
			$PREFIX=$SUFFIX="";
		}
		elsif($NUMBER=~/^(\d+)(\D+)$/){
			$SUFFIX=$2; $NUMBER=$1;
		}
		elsif($NUMBER=~/^(\D+)(\d+)$/){
			$PREFIX=$1; $NUMBER=$2;
		}
		elsif($NUMBER=~/^(\D+)(\d+)(.*)/){
			$PREFIX=$1; $NUMBER=$2; $SUFFIX=$3;
		}
		else{
			$SUFFIX=$NUMBER;
			$NUMBER="";
		}
		if($NUMBER || $PREFIX || $SUFFIX){
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
	foreach($DATE){
		s/-(0[0-9])$/-20$1/;
		s/-(\d\d)$/-19$1/;
	}
++$count_record;
warn "$count_record\n" unless $count_record % 5000;
		$color="";
		@descr=split(/\.  /,$PlantDescr);
		#print "$PlantDescr\n";
		$PlantDescr="";
		foreach $i (0 .. $#descr){
			#print "$i $descr[$i]\n";
			if($descr[$i]=~m/\b(red|green|blue|yellow|orange|purple|cream|white|brown|violet|reddish|pink|pinkish)\b/){
				$color .= "$descr[$i]. ";
			}
			else{
				$PlantDescr .= "$descr[$i]. ";
			}
		}	
		$PlantDescr=~s/[. ]+$//;
		$color=~s/[. ]+$//;
		#print "$PlantDescr\n";
		#print "$color\n";
		if($determiner){
		    $annotation="$name; $determiner; $det_date";
			}
			else{
			    $annotation="";
				}
     print OUT <<EOP;
Date: $DATE
CNUM: $NUMBER
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Name: $name
Accession_id: $ACCESSNO
Country: USA
State: California
County: $DISTRICT
Location: $LOCALITY
T/R/Section: $TRS
Elevation: $elevation
Collector: $collector
Other_coll: 
Combined_collector: $combined_collector
Habitat: $Geology
Associated_species: $Community
Color: $color
Macromorphology: $PlantDescr
Latitude: $latitude
Longitude: $longitude
Decimal_latitude: $decimal_latitude
Decimal_longitude: $decimal_longitude
UTM: $UTM
Notes: $notes
Datum: $datum
Max_error_distance: $extent
Max_error_units: $ExtUnits
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation
Image: $image

EOP
}
warn "$count_record\n";

open(OUT,">SDSU_badcoll") || die;
foreach(sort(keys(%badcoll))){
print OUT "$_: $badcoll{$_}\n";
}
open(OUT,">SDSU_badname") || die;
foreach(sort(keys(%badname))){
print OUT "$_: $badname{$_}\n";
}
sub skip {
print ERR "skipping: @_\n"
}
sub log {
print ERR "logging: @_\n";
}
__END__
SDSU17322	"Michael G. Simpson, C. Matt Guilliams, Kristen Hasenstab, & Michael Silveira"	30-May-07	2841	Santa Cruz	Crassulaceae	Sedum spathulifolium 	37.14666667	-122.1986111	719	"Perennial herb.  Leaves succulent, lower reddish.  Flowers yellow.  Young fruits red-orange.  "	Silty loam on granitic rocks.	"Open, north-facing slope.  Adjacent to Pinus attenuata / mixed chaparral."	"Dirt service road to Eagle Rock, ca. 0.2 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17279	"Michael G. Simpson, C. Matt Guilliams, Kristen Hasenstab, & Michael Silveira"	30-May-07	2842	Santa Cruz	Lamiaceae	Monardella villosa subsp. franciscana	37.14666667	-122.1986111	719	"Subshrub, ca. 2 dm tall.  Corolla light purple."	"Gravelly, silt soil.  Open, north-facing slope."	Adjacent to Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.2 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17323	"Michael G. Simpson, C. Matt Guilliams, Kristen Hasenstab, & Michael Silveira"	30-May-07	2843	Santa Cruz	Orobanchaceae	Castilleja foliolosa 	37.14666667	-122.1986111	719	"Subshrub, 2-3 dm tall.  Bracts and corolla red."	"Gravel, silt soil.  Open, north-facing slope."	Adjacent to Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.2 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17324	"Michael G. Simpson, C. Matt Guilliams, Kristen Hasenstab, & Michael Silveira"	30-May-07	2844	Santa Cruz	Portulacaceae	Claytonia parviflora subsp. viridis	37.14666667	-122.1986111	719	Annual herb.  Vegetation pink.	"Gravel, silt soil.  Open, north-facing slope."	Adjacent to Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.2 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17325	"Michael G. Simpson, C. Matt Guilliams, Kristen Hasenstab, & Michael Silveira"	30-May-07	2845	Santa Cruz	Ranunculaceae	Delphinium cardinale 	37.14666667	-122.1986111	719	Perennial herb.  Perianth red.	"Gravel, silt soil.  Open, north-facing slope."	Adjacent to Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.2 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17326	"Michael G. Simpson, C. Matt Guilliams, Kristen Hasenstab, & Michael Silveira"	30-May-07	2846	Santa Cruz	Apiaceae	Lomatium dasycarpum subsp. dasycarpum	37.14666667	-122.1986111	719	Perennial herb.	"Gravel, silt soil.  Open, north-facing slope."	Adjacent to Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.2 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17320	"Michael G. Simpson, C. Matt Guilliams"	30-May-07	2847	Santa Cruz	Poaceae	Briza maxima 	37.14666667	-122.1986111	719	Annual herb.	"Gravel, silt soil.  Open, north-facing slope."	Adjacent to Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.2 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17319	"Michael G. Simpson, C. Matt Guilliams"	30-May-07	2848	Santa Cruz	Poaceae	Aira caryophyllea 	37.14666667	-122.1986111	719	Annual herb.	"Gravel, silt soil.  Open, north-facing slope."	Adjacent to Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.2 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17277	"Michael G. Simpson, C. Matt Guilliams"	30-May-07	2849	Santa Cruz	Pteridaceae	Pentagramma triangularis var. triangularis	37.14666667	-122.1986111	719	Perennial herb.	"Gravel, silt soil.  Open, north-facing slope."	Adjacent to Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.2 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17308	"Michael G. Simpson, C. Matt Guilliams"	30-May-07	2850	Santa Cruz	Garryaceae	Garrya elliptica 	37.14722222	-122.1980556	724	"Shrub, ca. 2 m tall."	"Gravel, silt soil."	Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.17 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17307	"Michael G. Simpson, C. Matt Guilliams"	30-May-07	2851	Santa Cruz	Phrymaceae	Mimulus aurantiacus var. aurantiacus	37.14722222	-122.1980556	724	"Shrub, ca. 1.5 m tall.  Corolla light orange."	"Gravel, silt soil.  Open, north-facing slope."	Pinus attenuata / mixed chaparral.	"Edge of dirt service road to Eagle Rock, ca. 0.17 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17306	"Michael G. Simpson, C. Matt Guilliams"	30-May-07	2852	Santa Cruz	Fabaceae	Pickeringia montana var. montana	37.14722222	-122.1980556	724	"Shrub, ca. 1-2 m tall.  Corolla red-purple with yellow spot at adaxial base of banner."	"Gravel, silt soil."	Edge of road.  Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.17 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
SDSU17302	"Michael G. Simpson, C. Matt Guilliams"	31-May-07	2853	Santa Cruz	Hydrophyllaceae	Eriodictyon californicum 	37.14722222	-122.1980556	724	"Shrub, ca. 0.5 m tall.  Corolla violet."	"Gravel, silt soil."	Edge of road.  Pinus attenuata / mixed chaparral.	"Dirt service road to Eagle Rock, ca. 0.17 west-southwest of peak, ca. 0.1 mile west of Big Basin Redwood State Park boundary."
