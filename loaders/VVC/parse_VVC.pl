#useful one liners for debugging:
#perl -lne '$a++ if /Accession_id: RSA\d+DUP/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id: POM\d+DUP/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id: RSA\d+/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id: POM\d+/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id:/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Decimal_latitude: \d+/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Decimal_longitude: -\d+/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id: (POM|RSA)\d/; END {print $a+0}' RSA_fmp_out.txt
#perl -lne '$a++ if /Combined_coll: $/; END {print $a+0}' RSA_specify_out.txt

#perl -lne '$a++ if /Accession_id:/; END {print $a+0}' PGM_out.txt




#make sure that fields Location (AJ), Physiographic Region (AH) and Habitat (BL) are loading in the out file properly.


use strict;
#use warnings;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
use Text::CSV;
use Geo::Coordinates::UTM;

my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.


$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;

my $id_orig;
my $idAlt;
my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;
my $count_record;
my $GUID;
my %GUID_old;
my %GUID;
my $orig_id;
my $barcode;
my %GUID_barcode;
my %duplicate;

open(OUT, ">VVC_out.txt") || die;


#############
#Any notes about the input file go here
#file sent in UCR filemaker database format exported to csv

#imported to text wrangler and saved as UTF-8
#text below converts to a tab delimited file, but leaves in quotes, these need to be deleted in the script below.

#no Baja records in a separate file.
#many blank records with no accession number
#run this one liner to add the N to the first column as the cultivated field place holder
#perl -pe 's/^/"N",/' VVC_update.csv > VVC_FEB2018.tmp
############

#convert new files from comma delimited to tab one time, then comment out
#my $csv = Text::CSV->new ({ binary => 1 });
#my $tsv = Text::CSV->new ({ binary => 1, sep_char => "\t", eol => "\n" });

#open my $infh,  "<:encoding(utf8)", "VVC_FEB2018.tmp" || die;
#open my $outfh, ">:encoding(utf8)", "VVC_FEB2018.txt"|| die;

#while (my $row = $csv->getline ($infh)) {
#    $tsv->print ($outfh, $row);
#    }


#process converted text file
my $file="VVC_FEB2018.txt";

warn "reading from $file\n";

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


open (IN, $file) or die $!;
Record: while(<IN>){
	chomp;

	$line_store=$_;
	++$count;		

#fix some data quality and formatting problems that make import of fields of certain records problematic
#skipping: problem character detected: s/\xc3\xa9/    /g   é ---> André,	André	
#skipping: problem character detected: s/\xe2\x80\x98/    /g   ‘ ---> ‘petals’	‘fls.	‘shore’	‘vernal’	
#skipping: problem character detected: s/\xe2\x80\x99/    /g   ’ ---> 7.5’Q.	7.5’	7.5’Q	15’	‘petals’	5’	male-female’	7’l	10’s	D’Alcamo	‘shore’	‘vernal’	1000’s	100’s	
#skipping: problem character detected: s/\xe2\x80\x9d/    /g   ” ---> 34”;	
s/é/e/g;
s/‘/'/g;
s/’/'/g;
s/”/"/g;


        #if ($. == 1){#activate if need to skip header lines
		#	next Record;
		#}

			s/\cK/ /g; #delete some hidden windows line breaks that do not remove themselves with saving the file as utf-8


#Skip some odd lines that are interfereing with parsing
	if(m/No specimen recorded/i){
		&log_skip ("ACCESSSION: No specimen recorded\n");
		++$skipped{one};
		next Record;
	}
	
	if(m/Number not used/i){
		&log_skip ("ACCESSSION: Number not used\n");
		++$skipped{one};
		next Record;
	}
	if(m/\nN\t\t\t\t\t\t\t\t+/){
		&log_skip ("ACCESSSION: NULL record $_\n");
		++$skipped{one};
		next Record;
	}


my $id;
my $country;
my $stateProvince;
my $county;
my $tempCounty;
my $locality; 
my $family;
my $scientificName;
my $genus;
my $species;
my $rank;
my $subtaxon;
my $tempName;
my $hybrid_annotation;
my $identifiedBy;
my $dateIdentified;
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
my $CNUM_suffix;
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
my $topo_quad;
my $UTME;
my $UTMN; 
my $zone;
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
my $errorRadiusUnits;
my $coordinateUncertaintyInMeters;
my $coordinateUncertaintyUnits;
my $georeferenceSource;
my $associatedSpecies;	
my $associatedTaxa;
my $cultivated; #add this field to the data table for cultivated processing, place an "N" in all records as default
my $location;
my $localityDetails;
my $commonName;
my $occurrenceRemarks;
my $substrate;
my $plant_description;
my $phenology;
my $abundance;
my $notes;
#unique to this dataset
my $Coll_no_prefix;	
my $Coll_no;
my $Coll_no_suffix;
my $genus_doubted;
my $sp_doubted;
my $family_code;
my $physiographic_region;
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
my $prefix;
my $Coll_no;
my $suffix;	
my $hybrid_annotation;
my $det_orig;
my $decimal_long;
my $decimal_lat;


	my @fields=split(/\t/,$_,100);
	
	unless($#fields == 65){	#if the number of values in the columns array is exactly 66

	&log_skip ("$#fields bad field number $_\n");
	++$skipped{one};
	next Record;
	}

	
#then process the full records	

#cult	id	collector	prefix	Coll_no	suffix	year	month	day	Associated_collectors	family	genus	genus_doubted	species	sp_doubted	subtype	subtaxon	subsp_doubted	hybrid_category	Snd_genus	Snd_genusDoubted	Snd_species	Snd_species_doubted	Snd_subtype	Snd_subtaxon	Snd_subtaxon_doubted	determiner	det_year	det_mo	det_day	field_unknown	country	stateProvince	tempCounty	physiographic_region	topo_quad	locality	lat_degrees	lat_minutes	lat_seconds	N_or_S	decimal_lat	long_degrees	long_minutes	long_seconds	E_or_W	decimal_long	Township	Range	section	Fraction_of_section	Snd_township	Snd_Range	Snd_section	Snd_Fraction_of_section	UTM_grid_zone	UTM_grid_cell	UTM_E	UTM_N	name_of_UTM_cell	low_range_m	top_range_m	low_range_f	top_range_f	ecol_notes	Plant_description

#then process the full records	
($cultivated,
$id,
$collector,
$prefix,
$Coll_no,
$suffix,
$coll_year,
$coll_month,
$coll_day,
$other_coll, #10
$family,
$genus,
$genus_doubted,
$species,
$sp_doubted,
$rank,
$subtaxon,
$subsp_doubted,
$hybrid_category,
$Snd_genus,  #20
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
$CollectorSiteUniquifier,
$country,
$stateProvince,
$tempCounty,
$physiographic_region,
$topo_quad,
$location,
$lat_degrees,
$lat_minutes,
$lat_seconds, #40
$N_or_S,
$decimal_lat,
$long_degrees,
$long_minutes,
$long_seconds,
$E_or_W,
$decimal_long,
$Township,
$Range,
$Section,  #50
$Fraction_of_section,
$Snd_township,
$Snd_Range,
$Snd_section,
$Snd_Fraction_of_section,
$zone,
$UTM_grid_cell,
$UTME,
$UTMN,
$name_of_UTM_cell, #60
$minimumElevationInMeters,
$maximumElevationInMeters,
$minimumElevationInFeet,
$maximumElevationInFeet,
$habitat, #ecol_notes in original data
$plant_description #66
) = @fields;

#the Oct2014 export matches up to ecolNotes, then instead of these last five there is just georef source.


################ACCESSION_ID#############
#check for nulls, remove '-' from ID
$id=~s/-//;
unless($id=~/^VVC\d/){
	&log_skip("ACC: No accession number, skipped: $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space
#skip

#Add prefix 
#skip


#Remove duplicates
if($seen{$id}++){
	warn "Duplicate number: $id<\n";
	&log_skip("ACC: Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	next Record;
}

##########Begin validation of scientific names

##############SCIENTIFIC NAME
#Format name parts
$genus=ucfirst(lc($genus));
$species=lc($species);
$subtaxon=lc($subtaxon);
$rank=lc($rank);

#construct full verbatim name


my $tempName = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;

#Annotations  (use to show verbatim scientific name (annotation 0) when a separate annotation file is present)
	#format det_string correctly
my $det_orig_rank = "current determination (uncorrected)";  #set to zero for original determination

	


#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($tempName){
	s/[uU]nknown/ /g; #added to try to remove the word "unknown" for some records
	s/;$//g;
	s/"//g;
	s/cf.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/[×] /X /;	#change  " x " in genus name to the multiplication sign
	s/  +/ /g;
	s/^ $//g;
	s/^ +//g;
	s/ +$//g;

	
	s/[uU]nknown/ /g;

	if (length($tempName) >=1){
		$det_orig="$det_orig_rank: $tempName";
	}
	else{
		$det_orig="";
	}

}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published

if (($id =~ m/^(VVC2416)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trimorpha lonchophylla var. lonchophylla/Trimorpha lonchophylla/;
	&log_change("Scientific name not published: Trimorpha lonchophylla var. lonchophylla modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(VVC2326)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Oreocarya howellii/Cryptantha howellii/;
	&log_change("Scientific name not published: Oreocarya howellii modified to\t$tempName\t--\t$id\n");
}


#format hybrid names
if($tempName=~m/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation=$tempName;
	warn "Hybrid Taxon: $1 removed from $tempName\n";
	&log_change("Hybrid Taxon: $1 removed from $tempName");
	$tempName=$1;
}
else{
	$hybrid_annotation="";
}

#####process taxon names

$scientificName=&strip_name($tempName);
$scientificName=&validate_scientific_name($scientificName, $id);


#####process cultivated specimens			
# flag taxa that are cultivars, add "P" for purple flag to Cultivated field	

## regular Cultivated parsing
	if ($cultivated !~ m/^P$/){
		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("CULT: specimen likely not cultivated, purple flagging skipped: $scientificName\t--\t$id\n");
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($habitat =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
#add exceptions here to the CCH cultivated routine on a specimen by specimen basis
		#elsif (($id =~ m/^(UCR263222|UCR262468|UCR262466)$/) && ($scientificName =~ m/Enchylaena tomentosa/)){
		#	&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
		#$cultivated = "";

#Check remaining specimens for status with CCH cultivated routine
		else {		
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			#&log_change("Taxon skipped purple flagging: $cultivated\t--\t$scientificName\n");
			$cultivated = "";
			}
		}
	}
	else {
		
		&log_change("CULT: Taxon flagged as cultivated in original database: $cultivated\t--\t$scientificName\n");
		$cultivated = "P";
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
my $eventDateAlt;
my $month;

#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#$coll_month, #three letter month name: Jan, Feb, Mar etc.
#$coll_day,
#$coll_year,
#verbatim date for dwc verbatimEventDate and CCH "Date"

foreach ($coll_year){
	s/"//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}
foreach ($coll_day){
	s/"//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}
foreach ($coll_month){
	s/"//g;
	s/mid //g;
	s/Apr.May/Apr-May/g;
	s/ and /-/g;
	s/&/-/g;
	s/\?//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}


$verbatimEventDate = $eventDateAlt = $coll_year ."-" . $coll_month . "-". $coll_day;	


foreach ($eventDateAlt){
	s/0000//g;
	s/-00-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-00$/-/g;
	s/-0-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-0$/-/g;
	s/-+$//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}

#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#$coll_month, #three letter month name: Jan, Feb, Mar etc.
#$coll_day,
#$coll_year,
#verbatim date for dwc verbatimEventDate and CCH "Date"


	if($eventDateAlt=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)[- ](\d\d)/){	#if eventDate is in the format ####-Abcdef-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1b)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)[- ](\d)/){	#if eventDate is in the format ####-Abcdef-#
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1c)$eventDateAlt\t$id";
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
	#warn "(2)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)-(June?)$/){ #month, year, no day
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)[- ](Ma[rchy])$/){ #month, year, no day
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
	elsif ($eventDateAlt=~/^(([0-9]{4})[- ][A-Za-z]+)$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(5b)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Za-z]+) ([0-9]{2})([0-9]{4})$/){
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
	#warn "(18)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})-([0-9]{1,2})[- ]*$/){
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


#$formatEventDate = "$YYYY-$MM-$DD";
#($YYYY, $MM, $DD)=&atomize_ISO_8601_date($formatEventDate);
#warn "$formatEventDate\t--\t$id";

#$MM2= $DD2 = ""; #set late date to blank since only one date exists
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $MM2, $DD2, $id);
#warn "$formatEventDate\t--\t$EJD, $LJD\t--\t$id";
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);


###############COLLECTORS

	foreach ($collector, $other_coll){
		s/"//g;
		s/, M\. ?D\.//g;
		s/, Jr\./ Jr./g;
		s/, Jr/ Jr./g;
		s/, Esq./ Esq./g;
		s/, Sr\./ Sr./g;
		s/  +/ /;
		s/^ *//;
		s/ *$//;
		
	}


#fix odd format for collectors in other collector field
	if ($other_coll =~ m/([A-Z])([A-Z][a-z-]+)/g){
	$other_coll = $1.". ".$2;
	}
	elsif ($other_coll =~ m/([A-Z])([A-Z])([A-Z][a-z-]+)/g){
	$other_coll = $1.". ".$2.". ".$3;
	}	

	$other_collectors = ucfirst($other_coll);
	
	
if ((length($collector) > 1) && (length($other_collectors) > 1)){
	$recordedBy = &CCH::validate_single_collector($collector, $id);
	$verbatimCollectors = "$collector, $other_collectors";
	#warn "Names 1: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";}
}
elsif ((length($collector) > 1) && (length($other_collectors) == 0)){
	$recordedBy = &CCH::validate_single_collector($collector, $id);
	$verbatimCollectors = "$collector";
	#warn "Names 2: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
}
elsif ((length($collector) == 0) && (length($other_collectors) > 1)){
	$recordedBy = &CCH::validate_single_collector($other_collectors, $id);
	$verbatimCollectors = "$other_collectors";
	&log_change("COLLECTOR: Collector name field missing, using other collector field\t$id\n");
}
elsif ((length($collector) == 0) && (length($other_collectors) == 0)){
	&log_change("Collector name fields NULL\t$id\n");
	$verbatimCollectors = $other_collectors = $recordedBy = "";
}	
else {
		&log_change("Collector name problem\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}

foreach ($verbatimCollectors){
	s/"//g;
	s/'$//g;
	s/  +/ /;
	s/^ *//;
	s/ *$//;
	
}


#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes


foreach ($prefix,$Coll_no,$suffix){
	s/"//g;
	s/  +/ /;
	s/^ *//;
	s/ *$//;
}



$recordNumber = "$prefix$Coll_no$suffix";
$recordNumber =~ s/ +//g; #delete all extra spaces

($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);




####COUNTRY

foreach ($country,$stateProvince){
	s/"//g;
	s/  +/ /;
	s/^ *//;
	s/ *$//;
	
}

$country="USA" if $country=~/U\.?S\.?/;
$country="Mexico" if $country=~/M\.?X\.?/;


	if ($stateProvince=~m/^BCN/i){
		$stateProvince =~ s/.*/Baja California/;
	}
	elsif ($stateProvince=~m/^CA/i){
		$stateProvince =~ s/.*/California/;
	}
	else{
		&log_skip("LOCATION Country and State problem, skipped==>($country)\t($stateProvince)\t($tempCounty)\t ($locality)\t$id");
		++$skipped{one};
		next Record;
	}




######################COUNTY
foreach($tempCounty){
	s/"//g;
	s/'//g;
	s/^ +//g;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries
}


#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);




######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown==>$id ($country)\t($stateProvince)\t($county)\t$location");		
	}

##############validate county
my $v_county;

$county = ucfirst($county);

foreach($county){#for each $county value

	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|Unknown)$/){
		$v_county = &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&log_skip("COUNTY (2): NON-CA COUNTY?\t$_\t--\t$id");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log_change("COUNTY (3): COUNTY $county ==> $v_county--\t$id");		#call the &log function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}


####LOCALITY

foreach ($location,$physiographic_region){
	s/^"//g;
	s/'$//g;
	s/"$//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}
	if((length($location) > 1) && (length($physiographic_region) == 0)){
		$locality = "$location";
				
	}		
	elsif ((length($location) > 1) && (length($physiographic_region) >1)){
		$locality = "$physiographic_region, $location";
		$locality =~ s/'$//;
	}
	elsif ((length($location) == 0) && (length($physiographic_region) >1)){
		$locality = "$physiographic_region";
		$locality =~ s/: *$//;
	}
	elsif ((length($location) == 0) && (length($physiographic_region) == 0)){
		$locality = "";
		&log_change("Locality & physiographic_region NULL, $id\n");
	}
	else {
		&log_change("Locality problem, bad format, $id\t--\t$location\t--\t$physiographic_region\n");		#call the &log function to print this log message into the change log...
	}

####ELEVATION


#########################ELEVATION
#$elevationInMeters is the darwin core compliant value
#verify if elevation fields are just numbers

#process verbatim elevation fields into CCH format
if ((length($minimumElevationInMeters) >= 1) && (length($maximumElevationInMeters) >= 1)){
#there are decimal values in elevation field, convert to integer
	if ($maximumElevationInMeters =~ m/^\.([0-9]+)$/){
		$maximumElevationInMeters = "0.$1";
	}
	if ($maximumElevationInMeters =~ m/^-?[0-9.]+$/){
		$elevationInMeters = int($maximumElevationInMeters); #there are decimal elevations in these data
		$elevationInFeet = int($elevationInMeters * 3.2808);
		$CCH_elevationInMeters = "$maximumElevationInMeters m";
		$verbatimElevation = "$minimumElevationInMeters - $maximumElevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$maximumElevationInMeters' not numeric\t$id");
		$elevationInMeters="";
	}	
}

elsif ((length($minimumElevationInMeters) == 0) && (length($maximumElevationInMeters) >= 1)){

	if ($maximumElevationInMeters =~ m/^-?[0-9.]+$/){
		$elevationInMeters = int($maximumElevationInMeters); #there are decimal elevations in these data
		$elevationInFeet = int($elevationInMeters * 3.2808);
		$CCH_elevationInMeters = "$maximumElevationInMeters m";
		$verbatimElevation = "$maximumElevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$maximumElevationInMeters' not numeric\t$id");
		$elevationInMeters="";
	}	
}

elsif ((length($minimumElevationInMeters) >= 1) && (length($maximumElevationInMeters) == 0)){

	if ($minimumElevationInMeters =~ m/^-?[0-9.]+$/){
		$elevationInMeters = int($minimumElevationInMeters);
		$elevationInFeet = int($elevationInMeters * 3.2808);
		$CCH_elevationInMeters = "$minimumElevationInMeters m";
		$verbatimElevation = "$minimumElevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$minimumElevationInMeters' not numeric\t$id");
		$elevationInMeters="";
	}	
}
elsif ((length($minimumElevationInFeet) >= 1) && (length($maximumElevationInFeet) >= 1)){

	if ($maximumElevationInFeet =~ m/^-?[0-9.]+$/){
		$elevationInFeet = int($maximumElevationInFeet);
		$elevationInMeters = int($maximumElevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$minimumElevationInFeet - $maximumElevationInFeet ft";
	}
	else {
		&log_change("Check elevation in feet: '$maximumElevationInFeet' not numeric\t$id");
		$elevationInFeet="";
	}		
}
elsif ((length($minimumElevationInFeet) == 0) && (length($maximumElevationInFeet) >= 1)){

	if ($maximumElevationInFeet =~ m/^-?[0-9.]+$/){
		$elevationInFeet = int($maximumElevationInFeet);
		$elevationInMeters = int($maximumElevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$maximumElevationInFeet ft";
	}
	else {
		&log_change("Check elevation in feet: '$maximumElevationInFeet' not numeric\t$id");
		$elevationInFeet="";
	}		
}
elsif ((length($minimumElevationInFeet) >= 1) && (length($maximumElevationInFeet) == 0)){

	if ($minimumElevationInFeet =~ m/^-?[0-9.]+$/){
		$elevationInFeet = int($minimumElevationInFeet);
		$elevationInMeters = int($minimumElevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$minimumElevationInFeet ft";
	}
	else {
		&log_change("Check elevation in feet: '$minimumElevationInFeet' not numeric\t$id");
		$elevationInFeet="";
	}		
}
else {
	$CCH_elevationInMeters = "";
}


#this code was originally in consort_bulkload.pl, but it was moved here so that the county elevation maximum test can be performed on these data, which consort_bulkload.pl does not do
#this being in consort_bulkload instead of here may be adding to elevation anomalies that have been found in records with no elevations
my $pre_e;
my $e;

if (length($CCH_elevationInMeters) == 0){

		if($locality=~m/(\b[Ee]lev\.?:? [,0-9 -]+ *[MFmf'])/ || $locality=~m/([Ee]levation:? [,0-9 -]+ *[MFmf'])/ || $locality=~m/([,0-9 -]+ *(feet|ft|ft\.|m|meter|meters|'|f|f\.) *[Ee]lev)/i || $locality=~m/\b([Ee]lev\.? (ca\.?|about) [0-9, -]+ *[MmFf])/|| $locality=~m/([Ee]levation (about|ca\.) [0-9, -] *[FfmM'])/){
#		# print "LF: $locality: $1\n";
				$pre_e=$e=$1;
				foreach($e){
					s/Elevation[.:]* *//i;
					s/Elev[.:]* *//i;
					s/(about|ca\.?)//i;
					s/ ?, ?//g;
					s/(feet|ft|f|ft\.|f\.|')/ ft/i;
					s/(m\.|meters?|m\.?)/ m/i;
					s/  +/ /g;
					s/^ +//;
					s/[. ]*$//;
					s/ *- */-/;
					s/-ft/ ft/;
					s/(\d) (\d)/$1$2/g;
					next unless m/\d/;
					if (m/^(-?[0-9]+) ?m/){
						$elevationInMeters = $1;
						$elevationInFeet = int($elevationInMeters * 3.2808);
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation in meters found within $id\t$locality\t$id");
					}
					elsif (m/^(-?[0-9]+) ?f/){
						$elevationInFeet = $1;
						$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation in feet found within $id\t$locality");
					}
					elsif (m/^-?[0-9]+-(-?[0-9]+) ?f/){
						$elevationInFeet = $1;
						$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation range in feet found within $id\t$locality");
					}
					elsif (m/^-?[0-9]+-(-?[0-9]+) ?m/){
						$elevationInMeters = $1;
						$elevationInFeet = int($elevationInMeters * 3.2808);
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation in meters found within $id\t$locality\t$id");
					}
					else {
						&log_change("Elevation in $locality has missing units, is non-numeric, or has typographic errors\t$id");
						$elevationInFeet = "";
						$elevationInMeters="";
						$CCH_elevationInMeters = "";
					}	
				}
		}
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

#########COORDS, DATUM, ER, SOURCE#########

#right now the Latitude and Longitude fields are always in DMS or DDM. Will probably include decimal degrees in the future
#Datum and uncertainty are not recorded.
#Datum is assumed to be NAD83/WGS84 for the purposes of utm_to_latlon conversion (i.e. $ellipsoid=23)
#but otherwise datum is not reported
#remove symbols and put it in a standard format, spaces delimiting
my $ellipsoid;
my $northing;
my $easting;
my $hold;
my $lat_decimal;
my $long_decimal;
my $zone_number;


####TRS
$TRS="$Township$Range$Section $Fraction_of_section";


#######Latitude and Longitude
	foreach ($decimal_lat, $decimal_long, $lat_degrees,$lat_minutes,$lat_seconds,$long_degrees,$long_minutes,$long_seconds){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^ $//;
	}
if ((length($lat_degrees) >= 1) || (length($long_degrees) >= 1)){
$verbatimLatitude = "$lat_degrees $lat_minutes $lat_seconds";
#print "$verbatimLatitude\n";
$verbatimLongitude = "$long_degrees $long_minutes $long_seconds";
#print "$verbatimLongitude\n";
}
else{
$verbatimLatitude = $verbatimLongitude = "";
}





foreach ($decimal_lat, $verbatimLatitude){
		s/ø/ /g;
		s/'/ /g;
		s/^3403371/34.03371/;
		s/^3403776/34.03776/;
		s/^3634747/36.34747/;
		s/^364829/36.4829/;
		s/"/ /g;
		s/,/ /g;
		s/-//g; #remove negative latitudes, we dont map specimens from southern hemisphere, so if "-" is present, it is an error
		s/deg\.?/ /;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
		
}

foreach ($decimal_long, $verbatimLongitude){
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/^11742/117 42/;
		s/^117 42 42 37/117 42 37/;
		s/,/ /g;
		s/deg\.?/ /;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
		
}

if ((length($decimal_lat) == 0) || (length($decimal_long) == 0)){
#check to see if lat and lon reversed, THIS IS UNIQUE TO RSA due to the 3 sets of coordinates that are not consistent

	if (($verbatimLatitude =~ m/^-?1\d\d\./) && ($verbatimLongitude =~ m/^\d\d\./)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		print "COORDINATE 2 $id\n";
		&log_change("COORDINATE (2) decimals apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d +\d/) && ($verbatimLongitude =~ m/^\d\d +\d/)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		print "COORDINATE 3 $id\n";
		&log_change("COORDINATE (3) apparently reversed, switching latitude with longitude\t$id");
	}	
	elsif (($verbatimLatitude =~ m/^-?1\d\d$/) && ($verbatimLongitude =~ m/^\d\d/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 4 $id\n";
		&log_change("COORDINATE (4) longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d/) && ($verbatimLongitude =~ m/^\d\d$/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 5 $id\n";
		&log_change("COORDINATE (5) longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^\d\d\./) && ($verbatimLongitude =~ m/^-?1\d\d\./)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
			print "COORDINATE 6a $id\n";
	}
	elsif (($verbatimLatitude =~ m/^\d\d \d/) && ($verbatimLongitude =~ m/^-?1\d\d \d/)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
			print "COORDINATE 6b $id\n";
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
		#print "COORDINATE NULL $id\n";
	}
	else {
		&log_change("COORDINATE: partial coordinates only for $id\t($verbatimLatitude)\t($verbatimLongitude)\t($decimal_lat)\t($decimal_long)\n");
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}
}
elsif (($decimal_lat =~ m/^-?\.\d/) || ($decimal_long =~ m/^-?\.\d/)){
	if (($verbatimLatitude =~ m/^-?1\d\d\./) && ($verbatimLongitude =~ m/^\d\d\./)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		print "COORDINATE 2b $id\n";
		&log_change("COORDINATE (2) decimals apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d +\d/) && ($verbatimLongitude =~ m/^\d\d +\d/)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		print "COORDINATE 3b $id\n";
		&log_change("COORDINATE (3) apparently reversed, switching latitude with longitude\t$id");
	}	
	elsif (($verbatimLatitude =~ m/^-?1\d\d$/) && ($verbatimLongitude =~ m/^\d\d/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 4b $id\n";
		&log_change("COORDINATE (4) longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d/) && ($verbatimLongitude =~ m/^\d\d$/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 5b $id\n";
		&log_change("COORDINATE (5) longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^\d\d\./) && ($verbatimLongitude =~ m/^-?1\d\d\./)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
			print "COORDINATE 6c $id\n";
	}
	elsif (($verbatimLatitude =~ m/^\d\d \d/) && ($verbatimLongitude =~ m/^-?1\d\d \d/)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
			print "COORDINATE 6d $id\n";
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
		#print "COORDINATE NULL $id\n";
	}
	else {
		&log_change("COORDINATE: partial coordinates only for $id\t($verbatimLatitude)\t($verbatimLongitude)\t($decimal_lat)\t($decimal_long)\n");
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}
}
else {
	if (($decimal_lat =~ m/-?1\d\d\./) && ($decimal_long =~ m/^\d\d\./)){
		$hold = $decimal_lat;
		$latitude = $decimal_long;
		$longitude = $hold;
		&log_change("COORDINATE (9): Coordinates apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($decimal_lat =~ m/^\d\d\./) && ($decimal_long =~ m/-?1\d\d\./)){
			$latitude = $decimal_lat;
			$longitude = $decimal_long;
	}
	elsif (($decimal_lat =~ m/^1\d\d$/) && ($decimal_long =~ m/^\d\d/)){
		$hold = $decimal_lat;
		$latitude = sprintf ("%.3f",$decimal_long); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 10 $id";
		&log_change("COORDINATE (10) longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($decimal_lat =~ m/^1\d\d/) && ($decimal_long =~ m/^\d\d&/)){
		$hold = $decimal_lat;
		$latitude = sprintf ("%.3f",$decimal_long); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 10 $id";
		&log_change("COORDINATE (11) longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($decimal_lat =~ m/^\d\d$/) && ($decimal_long =~ m/^-?1\d\d/)){
			$latitude = sprintf ("%.3f",$decimal_lat); #convert to decimal, should report cf. 38.000
			$longitude = $decimal_long; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
			&log_change("COORDINATE (12) latitude integer degree only: $decimal_lat converted to $latitude==>$id");
	}
	elsif (($decimal_lat =~ m/^\d\d/) && ($decimal_long =~ m/^-?1\d\d$/)){
			$latitude = $decimal_lat; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
			$longitude = sprintf ("%.3f",$decimal_long); #convert to decimal, should report cf. 122.000
			&log_change("COORDINATE (13) longitude integer degree only: $decimal_long converted to $longitude==>$id");
	}
	elsif ((length($decimal_lat) == 0) && (length($decimal_long) == 0)){
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}
	else {
	&log_change("COORDINATE: Coordinate conversion problem for $id\t($verbatimLatitude)\t($verbatimLongitude)\t($decimal_lat)\t($decimal_long)\n");
	$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}
}	
	
#NULL coordinates that are only integer degrees, these are highly inaccurate and not useful for mapping
	if (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
		$decimalLatitude=$latitude = "";
		$decimalLongitude=$longitude = "";
		&log_change("COORDINATE verbatim Lat/Long only to degree, now NULL: $verbatimLatitude\t--\t$verbatimLongitude\n");
	}

	if (($decimal_lat =~ m/^\d\d$/) && ($decimal_long =~ m/^-?1\d\d$/)){
		$decimalLatitude=$latitude = "";
		$decimalLongitude=$longitude = "";
		&log_change("COORDINATE decimal Lat/Long only to degree, now NULL: $decimal_lat\t--\t$decimal_long\n");
	}


foreach ($latitude, $longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s$//;
}	

#use combined Lat/Long field format for UCR

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
					#print "1b)$decimalLatitude\t--\t$id\n";
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
					#print "2d) $decimalLatitude\t--\t$id\n";
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
					#print "5b) $decimalLongitude\t--\t$id\n";
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
				#print "6d) $decimalLongitude\t--\t$id\n";
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
elsif ((length($latitude) == 0) || (length($longitude) == 0)){
#utm are mostly in military coordinates which are not numeric.  skipping conversion of UTM and reporting if there are cases where UTM is present and lat/long is not

foreach ($UTME,$UTMN){
		s/[nsew]//i; #eliminate directions
		s/m//i; #eliminate meters
		s/z10//i; #eliminate zones put into coordinates
		s/z11//i; #eliminate zones put into coordinates
		s/-//g; #should be no negative UTMs in these data
		s/,//g;
		s/ //g;
		s/^0//;
}
foreach ($zone){
		s/027//; #bad zone number tripping up conversion module
		s/ //g;
}	

#process zone fields
		if ((length($UTME) > 1 ) && (length($UTMN) > 1 )){
			&log_change("10) Lat & Long null but UTM is present, checking for valid coordinates: $UTME, $UTMN, $zone, $id\n");
		
			#$zone = $UTM_grid_cell; #zone is this field in this dataset
			if((length($zone) == 0) && ($location =~ m/(San Miguel Island|Santa Rosa Island)/i)){
				$zone = "10S"; #Zone for these data are this, using UTMWORLD.gif in DATA directory
			}
			elsif ((length($zone) == 0) && ($location !~ m/(San Miguel Island|Santa Rosa Island)/i)){
			#set zone based on county boundary, rough estimate, but better than nothing since most UTM's do not include zone and row on plant specimens
				if($county =~ m/(Ensenada)/){
					$zone = "11R"; #Zone for these estimated using GIS overlay, not exact, some will fall outside this zone
				}
				elsif($county =~ m/(Del Norte|Siskiyou|Modoc|Lassen|Shasta|Tehama|Trinity|Humboldt)/){
					$zone = "10T";
				}
				elsif($county =~ m/(Rosarito, Playas de|Tecate|Tijuana|Alpine|Fresno|Imperial|Inyo|Kern|Kings|Los Angeles|Madera|Mariposa|Mono|Orange|Riverside|San Bernardino|San Diego|Ventura|Tuolumne)/){
						$zone = "11S";
				}
				elsif($county =~ m/(Alameda|Amador|Butte|Calaveras|Colusa|Contra Costa|El Dorado|Glenn|Lake|Marin|Mendocino|Merced|Monterey|Napa|Nevada|Placer|Plumas|Sacramento|San Benito|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Sierra|Solano|Sonoma|Stanislaus|Sutter|Tulare|Yolo|Yuba)/){
						$zone = "10S";
				}
				elsif($county =~ m/Mexicali/){
					$zone = ""; #Mexicali is in a small part of CA-FP Baja and it has sections in two zones, so UTM without zone is not convertable
					}
				else{
						&log_change("COORDINATE 11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone\t(CELL:$UTM_grid_cell NAME:$name_of_UTM_cell)\t$id\n");
						
					$zone = "";
				}
			}
			else{
				if ($zone =~ m/^(\d\d[A-Z])/){
					$zone = $1;
				}	
				elsif ($zone =~ m/^11[a-z]?$/){
					$zone = "11S";
				}				
				elsif ($zone =~ m/^10[a-z]?$/){
					$zone = "10S";	
				}	
				else{					
					&log_change("COORDINATE 11c) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone\t(CELL:$UTM_grid_cell NAME:$name_of_UTM_cell)\t$id\n");
						
					$zone = "";
				}
			}
		}
		if ((length($UTME) >= 5) && (length($UTMN) >= 5)){
#leading zeros need to be removed before this step
#Northing is always one digit more than easting. sometimes they are apparently switched around.
			if (($UTME =~ m/^(\d{7}$)/) && ($UTMN =~ /^(\d{6})$/)){
					$easting = $UTMN;
					$northing = $UTME;
					&log_change("UTM coordinates apparently reversed; switching northing with easting: $id");
			}
			else{
					$easting = $UTME;
					$northing = $UTMN;
			}
			if (($UTME > 0) && ($UTMN > 0)) {
				($decimalLatitude,$decimalLongitude)=utm_to_latlon(23,$zone,$easting,$northing);
				&log_change("Decimal degrees derived from UTM for $id: $decimalLatitude, $decimalLongitude");
				$georeferenceSource = "UTM to Lat/Long conversion by CCH loading script";
				$datum = "WGS84";
			}
		}
		elsif ((length($UTME) == 0) && (length($UTMN) == 0)){
				$decimalLatitude = $decimalLongitude = "";
		}
		else{
				&log_change("11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone, $id\n");
				$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
		}
}
elsif($latitude==0 && $longitude==0 && $UTME==0 && $UTMN==0){
	$datum = "";
	$georeferenceSource = "";
	$decimalLatitude =$decimalLongitude = "";
		&log_change("COORDINATE coordinates entered as '0', changed to NULL $id\n");
}

else {
		&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
		$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
}

#check datum
foreach ($datum){
		s/'$//;
		s/  +/ /g;
		s/^ *//g;
		s/ *$//g;
}

if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	if ($datum=~m/(WGS84|NAD83|NAD27)/){ #report is datum is present
		s/  +/ /g;
		s/^ *//g;
		s/ *$//g;

	}
	else {
		$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
	}
}
# check UNCERTAINTY AND UNITS
	if((length($lat_uncertainty) >= 1) && (length($long_uncertainty) >= 1)){ 
		$errorRadius = "Lat: $lat_uncertainty; Long: $long_uncertainty";
		$errorRadius =~ s/ *$//;
		$errorRadius =~ s/  +/ /;
		$coordinateUncertaintyUnits = "m";
	}		
	elsif ((length($lat_uncertainty) >= 1) && (length($long_uncertainty) == 0)){ 
		$errorRadius = "$lat_uncertainty";
		$errorRadius =~ s/ *$//;
		$errorRadius =~ s/  +/ /;
		$coordinateUncertaintyUnits = "m";
	}
	elsif ((length($lat_uncertainty) == 0) && (length($long_uncertainty) >= 1)){
		$errorRadius = "$long_uncertainty";
		$errorRadius =~ s/ *$//;
		$errorRadius =~ s/  +/ /;
		$coordinateUncertaintyUnits = "m";
	}
	else {
		$errorRadius = "not recorded";
		$coordinateUncertaintyUnits = "";
	}

#final check of Longitude
	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			&log_change("Longitude made negative\t--\t$id");
	}
#final check for rough out-of-boundary coordinates
if((length($decimalLatitude) >= 2)  && (length($decimalLongitude) >= 3)){ 
	if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114.0 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california and northern Baja...
	###was 32.5 for California, now 30.0 to include CFP-Baja
		if ($decimalLatitude < 30.0){ #if the specimen is in Baja California Sur or farther south
			&log_skip("COORDINATE: Mexico specimen mapping to south of the CA-FP boundary?\t$stateProvince\t\t$county\t$locality\t--\t$id>$decimalLatitude< >$decimalLongitude<\n");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		else{
		&log_change("coordinates set to null for $id, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude = $decimalLongitude = $georeferenceSource = $datum="";	#and set $decLat and $decLong to ""  
		}
	}
}
else{
		if((length($decimalLatitude) == 0)  && (length($decimalLongitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}

#######Plant Description (dwc ??) and Abundance (dwc occurrenceRemarks)

foreach ($plant_description){
		s/"//g;
		s/'$//;
		s/  +/ /g;
}


#######Habitat and Assoc species (dwc habitat and associatedTaxa)

#free text fields

foreach ($habitat){
		s/"/'/g;
		s/'$//;
		s/^'//;
		s/  +/ /g;
}

###ASSOCIATED SPECIES FROM ECOLOGY NOTES
my $habitat_rev;

if($habitat=~s/^(.*[;.]) +([Aa]ssoc.*)//){
	$associatedTaxa=$2;
	$habitat_rev=$1
}
else {
$associatedTaxa = "";
$habitat_rev = $habitat;
}

foreach ($associatedTaxa){
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}
foreach ($habitat_rev){
		s/"/'/g;
		s/'$//;
		s/^'//;
		s/  +/ /g;
}


print OUT <<EOP;
Accession_id: $id
Name: $scientificName
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
Collector: $recordedBy
Other_coll: $other_collectors
Combined_coll: $verbatimCollectors
CNUM_prefix: $CNUM_prefix
CNUM: $CNUM
CNUM_suffix: $CNUM_suffix
Country: $country
State: $stateProvince
County: $county
Location: $locality
Habitat: $habitat_rev
Associated_species: $associatedTaxa
T/R/Section: $TRS
USGS_Quadrangle: $topo_quad
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance: $errorRadius
Max_error_units: $coordinateUncertaintyUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Macromorphology: $plant_description
Hybrid_annotation: $hybrid_annotation
Cultivated: $cultivated
Annotation: $det_orig

EOP


#add one to the count of included records
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


    my $file_in = 'VVC_out.txt';	#the file this script will act upon is called 'CATA.out'
open(IN,"$file_in" ) || die;

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
