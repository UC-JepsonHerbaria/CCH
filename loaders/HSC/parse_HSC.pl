use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
$today_JD = &get_today_julian_day;

&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array
my %month_hash = &month_hash;

open(TABFILE,">HSC.out") || die;

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


##The data comes as an Excel spreadsheet with in-cell line breaks

#open(IN,"HSC_2015_02.txt") || die;
#open(IN,"TEST.txt") || die;
open(IN,"HSC_2016-02.txt") || die;

#$/="\cM";
#open(IN,"probs") || die;
Record: while(<IN>){
	s/‚Äô/'/g;
	s/\cK+$//;
	s/\cK//g;
	s/\cM/ /g;
	s/\xcd/'/g;
	s/\xc1/'/g;
	s/\x9e/'/g;
	s/\xef/'/g;

	s/í/'/g;
	s/’/'/g;
	s/’/'/g;
	s/“/"/g;
	s/”/"/g;
	s/\xf1/"/g;
	s/\xee/"/g;

	s/\[//;
	s/\]//;
	s/  / /g;
	s/’/'/g;

chomp;
@fields=split(/\t/);

#remove leading and trailing spaces from all fields
foreach $i (0 .. $#fields){
	$_=$fields[$i];
	s/^ *//;
	s/ *$//;
	$fields[$i]=$_;
}

#NOTE: Many fields were excluded since the Feb 2015 export, so they are commented out
(
$id,
$collector,
#$Coll_no_prefix,
$Coll_no,
#$Coll_no_suffix,
$year,
$month,
$day,
$Associated_collectors,
$family,
$genus,
#$genus_doubted,
$species,
#$sp_doubted,
$subtype,
$subtaxon,
#$subsp_doubted,
#$hybrid_category,
#$Snd_genus,
#$Snd_genusDoubted,
#$Snd_species,
#$Snd_species_doubted,
#$Snd_subtype,
#$Snd_subtaxon,
#$Snd_subtaxon_doubted,
$determiner,
$det_year,
$det_mo,
$det_day,
$country,
$state,
$county_mpio,
#$physiographic_region,
#$topo_quad,
$locality,
$lat_degrees,
$lat_minutes,
$lat_seconds,
$N_or_S,
$decimalLatitude,
$long_degrees,
$long_minutes,
$long_seconds,
$E_or_W,
$decimalLongitude,
$Township,
$Range,
$section,
$Fraction_of_section,
#$Snd_township,
#$Snd_Range,
#$Snd_section,
#$Snd_Fraction_of_section,
$UTM_grid_zone,
$UTM_grid_cell,
$UTM_E,
$UTM_N,
#$name_of_UTM_cell,
#$low_range_m,
#$top_range_m,
$elev_meters,
#$low_range_f,
#$top_range_f,
$elev_feet,
$ecol_notes,
#$plant,
#$phenology,
#$culture,
#$origin,
) = @fields;

###################ACCESSION IDS
foreach ($id){
	s/-//;
}

if($id=~/^ *$/){
	++$skipped{one};
	&log_skip("Record with no accession id $_");
	next Record;
}
	
if($seen{$id}++){
	++$skipped{one};
	warn "Duplicate number $id<\n";
	&log_skip("Duplicate accession number, skipped:\t$id");
	next Record;
}

#HSC100361 maps to out of state
###################collector numbers
#######Most recent load (2015-02) I didn't get any prefixes or suffix fields
#######should deal with this
	$Coll_no_prefix=$Coll_no_suffix="";
	$Coll_no=~s/ *$//;
	$Coll_no=~s/^ *//;
	$Coll_no=~s/,//;

	if($Coll_no=~s/^([0-9]+)-([0-9]+)$/$2/){
		$Coll_no_prefix="$1-";
	}
	if($Coll_no=~s/^([0-9]+)(\.[0-9]+)$/$1/){
		$Coll_no_suffix=$2;
	}
	if($Coll_no=~s/^([0-9]+)([A-Za-z]+)$/$1/){
		$Coll_no_suffix=$2;
	}
	if($Coll_no=~s/^([0-9]+)([^0-9])$/$1/){
		$Coll_no_suffix=$2;
	}
	if($Coll_no=~s/^(S\.N\.|s\.n\.)$//){
		$Coll_no_suffix=$1;
	}
	if($Coll_no=~s/^([0-9]+-)([0-9]+)([A-Za-z]+)$/$2/){
		$Coll_no_suffix=$3;
		$Coll_no_prefix.=$1;
	}
	if($Coll_no=~m/[^\d]/){
	$Coll_no=~s/(.*)//;
		$Coll_no_suffix=$1;
	}


########################COLLECTORS
$combined_collectors="";
$Collector_full_name=$collector;
foreach($Collector_full_name){
	s/ \./\./g;
	s/([A-Z]\.)([A-Z]\.)([A-Z]\.)/$1 $2 $3 /g;
	s/([A-Z]\.)([A-Z]\.)/$1 $2 /g;
	s/([A-Z]\.)([A-Z][a-z])/$1 $2/g;
	s/([A-Z]\.) ([A-Z]\.)([A-Z])/$1 $2 $3/g;
	s/([A-Z]\.)([A-Z])/$1 $2/g;
	s/,? (&|and) /, /;
	s/([A-Z])([A-Z]) ([A-Z][a-z])/$1. $2. $3/g;
	s/([A-Z]) ([A-Z][a-z])/$1. $2/g;
	s/,([^ ])/, $1/g;
	s/ *, *$//;
	s/, ,/,/g;
	s/  */ /g;
	s/^J\. ?C\. $/J. C./;
	s/John A. Churchill M. ?D. $/John A. Churchill M. D./;
	s/L\. *F\. *La[pP]r./L. F. LaPre/;
	s/L\. *F\. *La[pP]r√©/L. F. LaPre/;
	s/B\. ?G\. ?Pitzer/B. Pitzer/;
	s/J. AndrÈ/J. Andre/;
	s/Jim AndrÈ/Jim Andre/;
	s/ *$//;
	$_= $alter_coll{$_} if $alter_coll{$_};
	if($Associated_collectors){
		$Associated_collectors=~s/^, *//;
		$Associated_collectors=~s/D. *Charlton, *B. *Pitzer, *J. *Kniffen, *R. *Kniffen, *W. *W. *Wright, *Howie *Weir, *D. *E. *Bramlet/D. Charlton, et al./;
		$Associated_collectors=~s/Mark *Elvin, *Cathleen *Weigand, *M. *S. *Enright, *Michelle *Balk, *Nathan *Gale, *Anuja *Parikh, *K. *Rindlaub/Mark Elvin, et al./;
		$Associated_collectors=~s/P. *Mackay/P. MacKay/;
		$Associated_collectors=~s/P. *J. *Mackay/P. J. MacKay/;
		$Associated_collectors=~s/.*Boyd.*Bramlet.*Kashiwase.*LaDoux.*Provance.*Sanders.*White/et al./;
		$Associated_collectors=~s/.*Boyd.*Bramlet.*Kashiwase.*LaDoux.*Provance.*Sanders.*White/et al./;
		$Associated_collectors=~s/.*Boyd.*Kashiwase.*LaDoux.*Provance.*Sanders.*White.*Bramlet/et al./;
		$Associated_collectors=~s/ \./\./g;
		$Associated_collectors=~s/^w *\/ *//;
		$Associated_collectors=~s/([A-Z]\.)([A-Z]\.)([A-Z]\.)/$1 $2 $3 /g;
		$Associated_collectors=~s/([A-Z]\.)([A-Z]\.)/$1 $2 /g;
		$Associated_collectors=~s/([A-Z]\.)([A-Z]\.)/$1 $2/g;
		$Associated_collectors=~s/([A-Z]\.) ([A-Z]\.)([A-Z])/$1 $2 $3/g;
		$Associated_collectors=~s/([A-Z]\.)([A-Z])/$1 $2/g;
		$Associated_collectors=~s/,? (&|and) /, /g;
		$Associated_collectors=~s/([A-Z])([A-Z]) ([A-Z][a-z])/$1. $2. $3/g;
		$Associated_collectors=~s/([A-Z]) ([A-Z][a-z])/$1. $2/g;
		$Associated_collectors=~s/, ,/,/g;
		$Associated_collectors=~s/,([^ ])/, $1/g;
		$Associated_collectors=~s/et\. ?al/et al/;
		$Associated_collectors=~s/et all/et al/;
		$Associated_collectors=~s/et al\.?/et al./;
		$Associated_collectors=~s/etal\.?/et al./;
		$Associated_collectors=~s/([^,]) et al\./$1, et al./;
		$Associated_collectors=~s/ & others/, et al./;
		$Associated_collectors=~s/, others/, et al./;
		$Associated_collectors=~s/L\. *F\. *La[pP]r√©/L. F. LaPre/;
		$Associated_collectors=~s/B\. ?G\. ?Pitzer/B. Pitzer/;
		$Associated_collectors=~s/ +,/, /g;
		$Associated_collectors=~s/  */ /g;
		$Associated_collectors=~s/,,/,/g;
		$Associated_collectors=~s/J. AndrÈ/J. Andre/;
		$Associated_collectors=~s/Jim AndrÈ/Jim Andre/;
		if(length($_) > 1){
			$combined_collectors="$_, $Associated_collectors";
			if($alter_coll{$combined_collectors}){
				$combined_collectors= $alter_coll{$combined_collectors};
			}
		}
		else{
			if($alter_coll{$Associated_collectors}){
				$Associated_collectors= $alter_coll{$Associated_collectors};
			}
		}
	}
}


####################COLLECTION DATE
$YYYY = $year;
$MM = $month;
$DD = $day;

$MM = &get_month_number($MM, $id, %month_hash);
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);

####################Scientific Name
if ($species =~ /sp\.$/){
	$species="";
}
unless ($genus){
	&log_skip("No generic name: $_");
	++$skipped{one};
	next;
}
if ($subtype){
	unless ($subtaxon){
		&log_change("no subtaxon for $genus $species $subtype; '$subtype' removed\t$id");
		$subtype="";
	}
}

$scientificName=$genus ." " .  $species . " ".  $subtype . " ".  $subtaxon;
$scientificName=ucfirst(lc($scientificName));
foreach($scientificName){
	s/'//g;
	s/`//g;
	s/\?//g;
	s/ *$//g;
	s/  +/ /g;
	s/ssp\./subsp./;
	s/ [x×] / X /;
}

if($scientificName=~/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation=$scientificName;
	warn "$1 from $scientificName\n";
	&log_change("$scientificName recorded as hybrid annotation; name recorded as $1\t$id");
    $scientificName=$1;
}
else{
	$hybrid_annotation="";
}

$scientificName = &validate_scientific_name($scientificName, $id);


##########################################
##################COUNTY AND COUNTRY
$country="USA" if $country=~/U\.?S\.?/;

foreach($county_mpio){
	s/East //;
	s/ County.*//;
	s/^ *$/unknown/;
	s/-.*//;
	s/\/.*//;	

	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
		$v_county= &verify_co($_);
		if($v_county=~/SKIP/){
			&log_skip("NON-CA COUNTY? $_\t$id");
			++$skipped{one};
			next Record;
		}
		unless($v_county eq $_){
			&log_change("COUNTY $_ -> $v_county\t$id");
			$_=$v_county;
		}
	}
}


###########################################
#####ELEVATION
#$elev_meters always there when $elev_feet is, so use $elev_meters
if ($elev_meters){
	$elevation = "$elev_meters m";
}
else {
	$elevation = "";
}


#######ECOL NOTES AND ASSOC SPP
if($ecol_notes=~s/[;.] +([Aa]ssoc.*)//){
	$associatedTaxa=$1;
}
else { $associatedTaxa = ""; }


#####################LAT AND LONG AND TRS
###since they have DD recorded wherever there is also DMS, DMS processing not required
###However, the DMS contents are put together as verbatimLatitude and verbatimLongitude
###should we start publishing in Darwin Core
$verbatimLatitude="$lat_degrees $lat_minutes $lat_seconds $N_or_S";
$verbatimLatitude=~s/  +/ /g;
$verbatimLongitude=~"$long_degrees $long_minutes $long_seconds $E_or_W";
$verbatimLongitude=~s/  +/ /g;

#TRS
$Unified_TRS="$Township$Range$section";

#decimal degrees
$decimalLatitude="" if $decimalLatitude eq 0;
$decimalLongitude="" if $decimalLongitude eq 0;

if(($decimalLatitude=~/\d/ || $longitude=~/\d/)){
	if ($decimalLongitude > 0) {
		$decimalLongitude="-$decimalLongitude";
	}
	if($decimalLatitude > 42.1 || $decimalLatitude < 32.5 || $decimalLongitude > -114 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
				&log_change("coordinates set to null, Outside California: >$decimalLatitude< >$decimalLongitude< $id");	#print this message in the error log...
				$decimalLatitude =$decimalLongitude="";	#and set $decLat and $decLong to ""
	}
}


#################ANNOTATIONS
if($determiner){
	$annotation="$scientificName; $determiner; $det_year $det_mo $det_day";
}
else{
	$annotation="";
}


print TABFILE <<EOP;
Date: $month $day $year
EJD: $EJD
LJD: $LJD
CNUM_prefix: ${Coll_no_prefix}
CNUM: ${Coll_no}
CNUM_suffix: ${Coll_no_suffix}
Name: $scientificName
Accession_id: $id
Family_Abbreviation: $family
Country: $country
State: $state
County: $county_mpio
Location: $locality
T/R/Section: $Unified_TRS
Elevation: $elevation
Collector: $Collector_full_name
Other_coll: $Associated_collectors
Combined_collector: $combined_collectors
Habitat: $ecol_notes
Associated_species: $associatedTaxa
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation

EOP

#####Taken out of the print:
#Loc_other: $physiographic_region
#Latitude: $verbatimLatitude
#Longitude: $verbatimLongitude
#USGS_Quadrangle: $topo_quad
#Notes: $Plant_description

}
