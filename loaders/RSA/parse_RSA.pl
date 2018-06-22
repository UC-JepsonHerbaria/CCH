
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


#perl -lne '$a++ if /JOMU\d+/; END {print $a+0}' 4solr.ucjeps.public.csv

use Geo::Coordinates::UTM;
#use strict;
#use warnings;
use Data::GUID;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev

use utf8; #use only when original has problems with odd character substitutions
use Text::Unidecode;
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
my $Locality2;
my $Locality1;
my $occurrenceID;
my $herb;
my $UTM;
my $elevationUnits;
my $det_determiner;
my $typeStatus;
my $det_date;
my $Accession_Suffix;
my $Position;
my $fullName;
my $subspecies;
my $variety;
my $Accession_Number;
my $cchId;
my $identificationQualifier;
my $Culture;
my $establishmentMeans;
my $Preparations;
my $det_orig;



open(OUT, ">/JEPS-master/CCH/Loaders/RSA/RSA_out.txt") || die;
open(OUT2, ">/JEPS-master/CCH/Loaders/RSA/RSA_ID.txt") || die;
open(OUT3, ">/JEPS-master/CCH/Loaders/RSA/RSA_GIS.txt") || die;
open(OUT4, ">/JEPS-master/CCH/Loaders/RSA/AID_GUID_RSA.txt") || die;




#############
#Any notes about the input file go here
#file appears to be un UTF-8

#need to change in text wrangler to UTF8, usually has UNIX line breaks though, save as .txt file


#RSA specify file used to have erroneous vertical tab codes that show up as red '?' in text files.  These need to be deleted because they are also in the accesion number field, making linking specimens impossible
# or x{Ob} or \x0b

#In Some cases, the incorrect formatting of special characters happens during the conversion of a windows-based file to a mac-based file here at UC, but this is not the case for RSA
#It appears that in thier specif output to text, the special characters entered into fields are not being converted correctly and are coming out a mis-coded and mixed combinations of nonsensical gibberish
#in the processing below, each of these cases are changed to a non-special character through interpretation of the data from the original file.  
#Undoubtedly, some of the genrealized interpretations will be incorrect.

#'Bryophyte packet - 1' specimens with this in the record should be skipped, some are without taxon names

#in the dump (2016-04), RSA sends Baja records in a separate file.
#David concatenated the two files into RSA_latest_file.tab
#the new format within also concatenates into one, manually 
############

my $file="/JEPS-master/CCH/Loaders/RSA/data_files/2018.06.07_RSA_CCH_mod.txt";



warn "reading from $file\n";

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


open (IN, $file) or die $!;
Record: while(<IN>){

	s/ ◊ / X /g;  #this odd code may be correcting oddly using the unidecode


	chomp;

	$line_store=$_;
	++$count;		

#fix some data quality and formatting problems that make import of fields of certain records problematic
		s/°/ deg. /g;
		s/˚/ deg. /g;
	s/±/+-/g;
	s/·/a/g;
	s/È/e/g;
	s/Ì/i/g;
	s/Ì/i/g;
	s/Ò/n/g;
	s/Û/o/g;
	s/Ó/i/g;

	s/ñ/n/g;
	s/ë/'/g;
	s/í/ /g;
	s/í/'/g;
	s/î/ /g;
	s/˙/ /g; #unknown error
	s/”/"/g;
	s/∞/ deg. /g;


#RSA specify file has erroneous vertical tab codes that show up as red '?' in text files.  These need to be deleted because they are also in the accesion number field, making linking specimens impossible
# or x{Ob} or \x0b
s///g; # or x{Ob} or \x0b

#skipping: problem character detected: s/\xc2\xb1/    /g   ± ---> ±	
#skipping: problem character detected: s/\xc2\xb7/    /g   · ---> M·rtir,	Ju·rez.	M·rtir.	Tom·s,	Ju·rez	M·rtir:	Tom·s	Ju·rez:	M·rtir	precret·cicas.	m·s	Jap·.	Ju·rez,	mediterr·neo.	Tom·s.	
#skipping: problem character detected: s/\xc3\x88/    /g   È ---> ErÈndira,	ErÈndira	DemÈrÈ	AlamacÈn,	JosÈ	LÈon.	JosÈ.	CafÈ	desÈrtico	cafÈ.	cafÈ-rojizo.	JosÈ,	JosÈ).	ErÈndira.	InÈs.	
#skipping: problem character detected: s/\xc3\x8c/    /g   Ì ---> QuintÌn].	RodrÌguez,	RodrÌguez	MarÌa.	Ìgneas	QuintÌn,	RÌo	AmerÌca.	
#skipping: problem character detected: s/\xc3\x92/    /g   Ò ---> CaÒon,	CaÒon	CaÒada	CaÒada[Canyon].	VillaseÒor	PeÒasco)	piÒon-juniper	PiÒon,	CaÒada.	
#skipping: problem character detected: s/\xc3\x92\xc3\x9b/    /g   ÒÛ ---> CaÒÛn	
#skipping: problem character detected: s/\xc3\x93/    /g   Ó ---> BahÓa	MarÓa,	QuintÓn,	
#skipping: problem character detected: s/\xc3\x9b/    /g   Û ---> PabellÛn.	ex-MisiÛn	RincÛn.	xerÛfilo	SimÛn	ConcepciÛn	
#skipping: problem character detected: s/\xc3\xab/    /g   ë ---> ëCorral	ë2828,í	ëRiverollí	ëMeta	
#skipping: problem character detected: s/\xc3\xab\xc3\xad/    /g   ëí ---> ëíCorral	
#skipping: problem character detected: s/\xc3\xac/    /g   ì ---> ìCorral	ìHalfway	
#skipping: problem character detected: s/\xc3\xad/    /g   í ---> OíBrien	OíBrien,	Meadow.í	Pedroís	ë2828,í	Samís	Johnsonís	Hamiltonís	6í	4í;	4í	(Hamiltonís	2í	ëRiverollí	campoí.	Honeyís	
#skipping: problem character detected: s/\xc3\xad\xc3\xad/    /g   íí ---> Meadowíí	meadow.íí	
#skipping: problem character detected: s/\xc3\xae/    /g   î ---> Meadow.î	Houseî,	30î	
#skipping: problem character detected: s/\xc3\xb1/    /g   ñ ---> ñ	
#skipping: problem character detected: s/\xcb\x99/    /g   ˙ ---> Cant˙	
#skipping: problem character detected: s/\xe2\x80\x9d/    /g   ” ---> 12”	
#skipping: problem character detected: s/\xe2\x88\x9e/    /g   ∞ ---> 28∞	114∞	30∞	115∞95'W.	80∞	
$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8



        if ($. == 1){#activate if need to skip header lines
			next Record;
		}






		my @fields=split(/\t/,$_,100);

        unless( $#fields == 43){  #if the number of values in the columns array is exactly 44

	&log_skip ("$#fields bad field number $_\n");
	++$skipped{one};
	next Record;
	}
#normal headers	
#cchId	Barcode	Herbarium	Accession_Number	Accession_Suffix	Family	Genus	Species	Subspecies	Variety	
#Full_Name	Qualifier	Position	Determiner	Determined_Date	Type_Status	Collectors	Collector_Number	Collection_Start_Date	Verbatim_Date	
#Country	State	County	Locality	Locality_Continued	Latitude	Longitude	Datum	Township	Range	
#Section	Error_Radius	Error_Radius_Unit	Georeferencing_Source	Min_Elevation_(m)	Max_Elevation_(m)	Verbatim_Elev_(ft)	Site_Description___Habitat	Phenology	Specimen_Description	
#Culture	Origin	Preparations	GUID

($cchId, #sequential number
$barcode, #different from Accession number.
$herb, #RSA or POM
$Accession_Number, #Numeric portion of accession number
$Accession_Suffix, #A, B, etc.
$family, #CCH doesn't use, but is Darwin Core
$genus,
$species,
$subspecies,
$variety, #10   subspecies and variety together make the infraspecificEpithet dwc term
$fullName, #full name, I'll use this instead of concatenating the previous fields. substitute subsp. for ssp.
$identificationQualifier,
$Position, #as in, position of the id qualifier. Use this to make an annotation name
$identifiedBy,
$dateIdentified,
$typeStatus,
$verbatimCollectors, #collectors, comma delimited
$recordNumber, #coll num
$eventDate, #collection date in beautiful YYYY-MM-DD
$verbatimEventDate, #20
$country, #always United States, so no action required
$stateProvince, #always California, no action required
$tempCounty,
$Locality1,
$Locality2, #i.e. "Locality Continued"
$verbatimLatitude,
$verbatimLongitude,
$datum,
$Township,
$Range,  #30
$Section, #concatenate into a string but don't bother doing anything with converting
$errorRadius,
$errorRadiusUnits,
$georeferenceSource, #knock out weird ones: ones that start with [/[/(0-9]
$minimumElevationInMeters,
$maximumElevationInMeters,
$verbatimElevation,
$habitat,
$phenology, #i.e. phenology
$occurrenceRemarks, #i.e. plant description #40
$Culture, #what they call "Culture". Currently not a CCH field
$establishmentMeans, #Native, Introduced, or cultivated
$Preparations, #Herbarium sheet, etc. doesn't need to be published 
$occurrenceID 
) = @fields;



##################Exclude known problematic localities from other States in Mexico outside CA-FP	
 	if ($Locality1 =~/(Cedros Island|Cerros Island|Campeche|Tuxpe.*a, Camp\.|Clarion Island|Isla del Carmen|Esc.?rcega|HopelchTn|Cd\. del C.?rmen|Mamantel|Xpujil|Ciudad del Carmen|Tuxpe.?a, Camp\.)/){
		#print  ("Mexico record outside CA-FP\t$id");
		&log_skip("Mexico record outside CA-FP\t$Locality1\t$cchId");
		++$temp_skipped{one};
		next Record;
	}
	elsif ($Locality2 =~/(Cedros Island|Cerros Island|Campeche|Tuxpe.*a, Camp\.|Clarion Island|Isla del Carmen|Esc.?rcega|HopelchTn|Cd\. del C.?rmen|Mamantel|Xpujil|Ciudad del Carmen|Tuxpe.?a, Camp\.)/){
		#print  ("Mexico record outside CA-FP\t$id");
		&log_skip("Mexico record outside CA-FP\t$Locality1\t$cchId");
		++$temp_skipped{one};
		next Record;
	}
	elsif((length($tempCounty) == 0) && ($country=~m/Mexico/i)){
		&log_skip("Mexico record with unknown or blank county field==>$cchId ($country)\t($stateProvince)\t($tempCounty)\t$Locality1");
			++$skipped{one};
			next Record;
	}
	elsif(($tempCounty=~m/unknown/i) && ($country=~m/Mexico/i)){
		&log_skip("Mexico record with unknown or blank county field==>$cchId ($country)\t($stateProvince)\t($tempCounty)\t$Locality1");
			++$skipped{one};
			next Record;
	}

########ACCESSION NUMBER

#Remove duplicates in cchId, this needs to be unique, and duplicates are errors
if($seen{$cchId}++){
	warn "Duplicate CCHID: $cchId\t$id\t$barcode\n";
	&log_skip("ACC: Duplicate CCHID, skipped: $cchId\t\t$id\t$barcode");
	++$skipped{one};
	next Record;
}



#remove leading zeroes, remove any white space
foreach($barcode){
	s/ +//g;
}
foreach($Accession_Number,$Accession_Suffix,$herb){
	s/ +//g;
}

$id_orig = $herb . $Accession_Number . $Accession_Suffix;

$id = $id_orig;

foreach ($id_orig){
		s/ +//g;
}



#Use barcode number for those with one
	if ($barcode =~ m/^(RSA|POM)\d/){ #check if barcode is NULL
				&log_change("ACC: Barcode field not NULL, using barcode for ID $id==>$barcode<\n");
		$id = $barcode;
		#print OUT2 "$id\tBARCODE\t$fullName\t$tempCounty\t$cchId\t$occurrenceID\n"; #print all other unchanged barcodes
	}
	else{
		$barcode = "";
	}

#find duplicates
if($duplicate{$id}++){
	#$id =~ s/^(RSA|POM)(\d+[A-Z]?)$/$1$2DUP/g;
	#print OUT2 "$id\tDUP\t$fullName\t$tempCounty\t$cchId\t$occurrenceID\n";
	#warn "Duplicate accession found: $id<\n";
	&log_skip("ACC: Duplicate accession number found, $id==>$occurrenceID");
		++$skipped{one};
		next Record;
}

	if ($barcode =~ m/^(RSA|POM)\d/){ #check if barcode is NULL
		print OUT2 "$id\tBARCODE\t$id_orig\t$fullName\t$tempCounty\t$cchId\t$occurrenceID\n";
	}
	else{
		if ($id =~ m/^(RSA|POM)\d+DUP/){ #check if a duplicate
			print OUT2 "$id\tDUP\t$id_orig\t$fullName\t$tempCounty\t$cchId\t$occurrenceID\n";
		}
		else{		
			print OUT2 "$id\tNON\t$id_orig\t$fullName\t$tempCounty\t$cchId\t$occurrenceID\n";
		}
	}

#change duplicates to alternative ID
	if ($id =~ m/^(RSA|POM)0+$/){ #check to see if modified ID matches the correct format, delete accessions with all numbers as zeros
		warn "Problem ID number: $cchId\t$id\t$barcode\n";
		&log_skip("ACC: Problem ID number, all zero's: $cchId\t$id\t$barcode\n");
		++$skipped{one};
		next Record;
	}
	elsif ($id !~ m/^(RSA|POM)\d+/){ #check to see if modified ID matches the correct format
		warn "Problem ID number: $cchId\t$id\t$barcode\n";
		&log_skip("ACC: Problem ID number: $cchId\t$id\t$barcode\n");
		++$skipped{one};
		next Record;
	}


	#print OUT3 "$id_orig\t$idAlt\t$cchId\t$barcode\t$fullName\t$tempCounty\n"; #print accessions with all variants

#Create GUID table
if (length ($occurrenceID) > 1){
	$GUID_barcode{$barcode}=$occurrenceID;
	$GUID{$id}=$occurrenceID;

	print OUT4 "$barcode\t".$GUID_barcode{$barcode}."\n";
	print OUT4 "$id\t".$GUID{$id}."\n";
}



##################Exclude known problematic specimens by id numbers, most from outside California and Baja California
#	if(($id=~/^(CAS-BOT-BC305449)$/) && ($tempCounty=~m/San/)){ #skip, out of state
#		&log_skip("County/State problem==>San Bernardino Ranch, Arizona, is in Cochise County, not in California ($barcode: $tempCounty, $locality)\n");	
#		++$skipped{one};
#		next Record;
#	}

#fix some really problematic records with data that is misleading and causing georeference errors

if (($id =~ m/^(RSA460787)$/) && ($tempCounty=~m/^(Modoc)/i)){
	$tempCounty = "Fresno";
			$latitude = ""; #delete persistently bad georeference due to misleading county
			$longitude = "";
	&log_change("COUNTY: county error, See also Dean Taylor Comments from 2013, this plant is not known from Modoc County and this does not appear to be a Detmer's collection, the date corresponds to collections by Albert J. Perkins who was in Kings River region on June 19, 1920, therefore it is likely that the locality is 'lake shore above Rambaud Peak, Fresno County' and the county is wrongly entered as Modoc, changed to ==>$tempCounty\t$location\t--\t$id\n");
	#Dean Taylor comment:The county for this specimen is out of range and suspect, largely because elevations in the Warner Mountains do not approach 10000 ft in proximity to the very few lakes present; the specimen location possibly corresponds to the drainage of Rambaud Creek, tributary to Middle Fork Kings River, Fresno County (ca. 37.04899/-118.61401) in the Sierra Nevada.
	#441572		RSA	460787		Primulaceae	Primula	suffrutescens			Primula suffrutescens					Not type	Freda Detmers	14543	1920-07-19		United States	California	Modoc County	Lake shore above Ramband.											2744	3049	9000-10000		flowers & fruits		Native/naturalizing		Herbarium sheet - 1	31ecfd57-eb3b-4e7b-a2e2-33a2fd5f52fa
}





##########Begin validation of scientific names

##############SCIENTIFIC NAME
#Format name parts
#This is messing up some names, I would rather do this as alter_names then here
#$genus=ucfirst(lc($genus));  
#$species=lc($species);
#$subspecies=lc($subspecies);
#$variety=lc($variety);

#$fullName=ucfirst(lc($fullName));
foreach ($fullName){
	s/ ssp\.? / subsp. /;
}

#construct full verbatim name
if (length ($subspecies) > 1){
	$tempName = $genus ." " .  $species . " subsp. ".  $subspecies;
}
elsif(length ($variety) > 1){
	$tempName = $genus ." " .  $species . " var. ".  $variety;
}
elsif ((length ($variety) == 0) && (length ($subspecies) == 0) && (length ($species) > 1)){
	$tempName = $genus ." " .  $species;
}
else{
	$tempName = $fullName;
}

if (($id =~ m/^(POM256932|RSA0033897|RSA762509)$/) && (length($TID{$tempName}) == 0)){ 
	print "NAME CHECK(1): $tempName\n";
}

#Annotations  (use to show verbatim scientific name (annotation 0) when a separate annotation file is present)
	#format det_string correctly
my $det_AID;
my $det_rank;
my $det_family;
my $det_name;
my $det_determiner;
my $det_year;
my $det_month;
my $det_day;
my $det_stet;
my $det_date;
my $det_name_position;
my $det_string="";
my $det_orig_rank = "current determination (uncorrected)";  #set to zero for original determination

	if (length($tempName) >=1){
		$det_orig="$det_orig_rank: $tempName";
	}
	else{
		$det_orig="";
	}
	

#make verbatim name for determination

	if (length($Position) >=1){
		$det_name = "$tempName; $identificationQualifier $Position";
	}
	else {
		$det_name = $tempName;
	}



$det_determiner = $identifiedBy;
$det_date = $dateIdentified;

#format det_string correctly
	if ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_date) == 0) && (length($det_name_position) >= 1)){
		$det_string="$det_rank: $det_name_position";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_date) == 0) && (length($det_name_position) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_date) >=1) && (length($det_name_position) == 0)){
		$det_string="$det_rank: $det_name, $det_date";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_date) >=1) && (length($det_name_position) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner,  $det_date";
	}
	elsif ((length($det_name) ==0) && (length($det_determiner) >=1) && (length($det_date) >=1) && (length($det_name_position) == 0)){
		$det_string="$det_rank: $det_determiner,  $det_date";
	}
	elsif ((length($det_name) ==0) && (length($det_determiner) >=1) && (length($det_date) ==0) && (length($det_name_position) == 0)){
		$det_string="$det_rank: $det_determiner";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) >=1) && (length($det_date) == 0) && (length($det_name_position) >= 1)){
		$det_string="$det_rank: $det_name_position, $det_determiner";
	}	
	elsif ((length($det_name)  == 0) && (length($det_determiner) == 0) && (length($det_date) >=1) && (length($det_name_position) >= 1)){
		$det_string="$det_rank: $det_name_position, $det_date";
	}
	elsif ((length($det_name)  == 0) && (length($det_determiner) >=1) && (length($det_date) >=1) && (length($det_name_position) >= 1)){
		$det_string="$det_rank: $det_name_position, $det_determiner,  $det_date";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($det_date) == 0) && (length($det_name_position) == 0)){
		$det_string="";
	}
	elsif ((length($det_name) >= 1) && (length($det_determiner) == 0) && (length($det_date) == 0) && (length($det_name_position) == 0)){
		$det_string="";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($det_date) == 0) && (length($det_name_position) >= 1)){
		$det_string="$det_name_position";
	}
	else{
		print "det problem: $det_rank: $det_name (position:$det_name_position), $det_determiner, $det_date==>".$id."\n";
		$det_string="";
	}


#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($tempName){
	s/[uU]nknown/ /g; #added to try to remove the word "unknown" for some records
	s/;$//g;
	s/cf.//g;
	s/ ssp\.? / subsp. /;
	s/ [xX×] / X /;	#change  " x " or " X " from the multiplication sign
	s/ [Aa]-+[Ss] / X /;	#change  "a--s" a bad conversion to " X " from the multiplication sign
	s/^[Aa]-+[Ss] /X /;	#change  "a--s" a bad conversion to " X " from the multiplication sign
	s/[×] /X /;	#change  " x " in genus name from the multiplication sign
	s/  +/ /g;
	s/^ $//g;
	s/^ +//g;
	s/ +$//g;
	}



#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published
if (($id =~ m/^(RSA495405|RSA495794)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Artemisia californica subsp\. triangularis/Artemisia californica/;
	&log_change("Scientific name not published: Artemisia californica subsp\. triangularis not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA697863)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Brunellia vulgaris var\. lanceolata/Prunella vulgaris var. lanceolata/;
	&log_change("Scientific name not published: No published 'vulgaris' epithet in genus Brunellia (Brunelliaceae), this is an error for the genus Prunella (Lamiaceae), modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0001205|RSA717284)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Arabis yorkii/Boechera yorkii/;
	&log_change("Scientific name not published: No published 'yorkii' epithet in genus Arabis, this is an error for the genus Boechera, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA500546)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Asclepias californica subsp\. glaucus/Asclepias californica/;
	&log_change("Scientific name not published: Asclepias californica subsp. glaucus in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA754833)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Bromus tectorum subsp\. rubens/Bromus tectorum/;
	&log_change("Scientific name not published: Bromus tectorum subsp. rubens in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA229736)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Asclepias eriocarpa subsp\. capitatum/Asclepias eriocarpa/;
	&log_change("Scientific name not published: Asclepias eriocarpa subsp. capitatum not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA302526)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Atriplex rosea subsp\. platyota/Atriplex rosea/;
	&log_change("Scientific name not published: Atriplex rosea subsp. platyota not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0082891)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lepidium lasiocarpum subsp\. aurantiaca/Lepidium lasiocarpum/;
	&log_change("Scientific name not published: Lepidium lasiocarpum subsp. aurantiaca not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0060658|RSA0060370|RSA0060365|RSA0060364|RSA0060363)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Gilia maculata subsp\. emaculatus/Gilia maculata/;
	&log_change("Scientific name not published: Gilia maculata subsp. emaculatus not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA65664)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Claytonia parviflora subsp\. exigua/Claytonia parviflora/;
	&log_change("Scientific name not published: Claytonia parviflora subsp. exigua not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}	
if (($id =~ m/^(RSA755736)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Claytonia exigua subsp\. grandiflora/Claytonia exigua/;
	&log_change("Scientific name not published: Claytonia exigua subsp. grandiflora not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}	
if (($id =~ m/^(RSA0074689|RSA0059523)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Claytonia gabrielensis subsp\. viridis/Claytonia/;
	&log_change("Scientific name not published: Claytonia gabrielensis subsp. viridis not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}	
if (($id =~ m/^(RSA495803)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Rhus ovata subsp\. triangularis/Rhus ovata/;
	&log_change("Scientific name not published: Rhus ovata subsp. triangularis not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}	
if (($id =~ m/^(RSA0019492)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Thinopyrum intermedium var\. trichophorum/Thinopyrum intermedium/;
	&log_change("Scientific name not published: Thinopyrum intermedium var. trichophorum not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}	
if (($id =~ m/^(RSA654784|RSA660399|RSA661304)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Thinopyrum intermedium subsp\. hispidus/Thinopyrum intermedium/;
	&log_change("Scientific name not published: Thinopyrum intermedium subsp. hispidus not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0027714|RSA640885|RSA802053|RSA802424)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Thinopyrum ponticum subsp\. pontica/Thinopyrum ponticum/;
	&log_change("Scientific name not published: Thinopyrum ponticum subsp. pontica not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0021821)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Thinopyrum junceiforme subsp\. boreo-atlanticus/Thinopyrum junceiforme/;
	&log_change("Scientific name not published: Thinopyrum junceiforme subsp. boreo-atlanticus not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}	
if (($id =~ m/^(RSA65714)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Silene bridgesii subsp. bernardina/Silene bridgesii/;
	&log_change("Scientific name not published: Silene bridgesii subsp\. bernardina not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}	
if (($id =~ m/^(RSA539341|RSA542360|RSA548876|RSA589242|RSA599824|RSA639112|RSA673498|RSA703101|RSA773562)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Achnatherum coronatum var. coronata/Achnatherum coronatum/;
	&log_change("Scientific name not published: Achnatherum coronatum var. coronata not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}	
if (($id =~ m/^(POM231276|RSA597451|RSA597742|RSA642085)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Achnatherum coronatum var\. depauperata/Achnatherum parishii subsp. depauperatum/;
	&log_change("Scientific name not published: Achnatherum coronatum var. depauperata not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA600583)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Achnatherum coronatum subsp\. depauperata/Achnatherum parishii subsp. depauperatum/;
	&log_change("Scientific name not published: Achnatherum coronatum subsp. depauperata not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA387706|RSA618091|RSA619710)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Achnatherum coronatum var\. parishii/Achnatherum parishii/;
	&log_change("Scientific name not published: Achnatherum coronatum var. parishii not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA539341|RSA542360|RSA548876|RSA589242|RSA599824|RSA639112|RSA673498|RSA703101|RSA773562)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trisetum canescens var. canescens/Trisetum canescens/;
	&log_change("Scientific name not published: Trisetum canescens var. canescens not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA500535)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Acourtia microcephala var\. weedii/Acourtia microcephala/;
	&log_change("Scientific name not published: Acourtia microcephala var. weediii not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA126401)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Aira elegans var\. capillaris/Aira elegans/;
	&log_change("Scientific name not published: Aira elegans var. capillaris not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0027800)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Ambrosia platyspina var\. dumosa/Ambrosia X platyspina/;
	&log_change("Scientific name not published: Ambrosia platyspina var. dumosa not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA603698)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Amaranthus tricolor var\. angustior/Amaranthus tricolor/;
	&log_change("Scientific name not published: Amaranthus tricolor var. angustior not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0000712)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lomatium californicum var\. platycarpa/Leptotaenia californica var. platycarpa/;
	&log_change("Scientific name not published: Lomatium californicum var. platycarpa not in TROPICOS, combination only made in Leptotaenia, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA169390|RSA712866)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lomatium donnellii var\. plummerae/Lomatium donnellii/;
	&log_change("Scientific name not published: Lomatium donnellii var. plummerae not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA271913|RSA452590)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lomatium donnellii var\. sonnei/Lomatium donnellii/;
	&log_change("Scientific name not published: Lomatium donnellii var. sonnei not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0000726)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lomatium vaginatum var\. anthemifolium/Lomatium donnellii/;
	&log_change("Scientific name not published: Lomatium vaginatum var. anthemifolium not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0105316)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lomatium lucidum var\. capitatum/Lomatium lucidum/;
	&log_change("Scientific name not published: Lomatium lucidum var. capitatum not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA69918)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Apocynum floribundum var\. floribundum/Apocynum X floribundum/;
	&log_change("Scientific name not published: Apocynum floribundum var. floribundum not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA69918)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Apocynum floribundum var\. floribundum/Apocynum X floribundum/;
	&log_change("Scientific name not published: Apocynum floribundum var. floribundum not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA696474)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Toxicodendron tribolata/Toxicodendron/;
	&log_change("Scientific name not published: neither Toxicodendron tribolata nor trilobata in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA795842)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Anredera cordifolia var\. pseudocaselloides/Anredera cordifolia/;
	&log_change("Scientific name not published: Anredera cordifolia var. pseudocaselloides not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA195356)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Arabis oregana var\. modesta/Arabis oregana/;
	&log_change("Scientific name not published: Arabis oregana var. modesta not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM219015)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Arabis platysperma var\. oligantha/Arabis platysperma/;
	&log_change("Scientific name not published: Arabis platysperma var. oligantha not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA160569)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Aster subspicatus var\. ligulatus/Aster subspicatus/;
	&log_change("Scientific name not published: Aster subspicatus var. ligulatus not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA790242)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Athyrium americanum var\. americanum/Athyrium americanum/;
	&log_change("Scientific name not published: Athyrium americanum var. americanum not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA15288|RSA377723|RSA377724|RSA377725|RSA377726|RSA377728|RSA377729|RSA377730|RSA377731|RSA569206|RSA670)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Maianthemum stellatum var\. sessilifolium/Maianthemum stellatum/;
	&log_change("Scientific name not published: Maianthemum stellatum var. sessilifolium not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0028786|RSA377696|RSA377697|RSA377698|RSA377699|RSA377700|RSA377701|RSA377702|RSA377703|RSA377704)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Maianthemum racemosum var\. glabra/Maianthemum racemosum/;
	&log_change("Scientific name not published: Maianthemum racemosum var. glabra not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM110457|POM118765|POM221998|POM257224|RSA589935)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Zigadenus venenosus var\. fontanus/Zigadenus venenosus/;
	&log_change("Scientific name not published: Zigadenus venenosus var. fontanus not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM368122|POM368124|POM368125|POM368126|POM368127|RSA201776|RSA359914|RSA518404|RSA626613|RSA639042|RSA639318)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Amsinckia floribunda/Amsinckia/;
	&log_change("Scientific name not published: Amsinckia floribunda not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA452373)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Atriplex fremontii/Atriplex/;
	&log_change("Scientific name not published: Atriplex fremontii not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0000939)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Baeria subciliata/Baeria/;
	&log_change("Scientific name not published: Baeria subciliata not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA495446)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Carex peninsular[ise]+/Carex/;
	&log_change("Scientific name not published: Carex peninsulare or Carex peninsularis not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0110916)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Cryptantha lepida/Cryptantha/;
	&log_change("Scientific name not published: Cryptantha lepida not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA184790)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Elymus hordeum/Elymus/;
	&log_change("Scientific name not published: Elymus hordeum not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0001817)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Krynitzkia lentiformis/Krynitzkia/;
	&log_change("Scientific name not published: Krynitzkia lentiformis not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0001829)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Krynitzkia unilateralis/Krynitzkia/;
	&log_change("Scientific name not published: Krynitzkia unilateralis not in TROPICOS, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA749784|RSA750186|RSA751051|RSA752009|RSA761037|RSA764200|RSA764252|RSA782687|RSA800225)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Cryptantha lepida/Cryptantha/;
	&log_change("Scientific name not published: Cryptantha lepida modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA500135|RSA500108|RSA500110|RSA500110|RSA500140)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Sambucus mexicana var\. jepsonii/Sambucus mexicana/;
	&log_change("Scientific name not published: Sambucus mexicana var. jepsonii modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(UCR58860)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lupinus elatus var\. viridulus/Lupinus elatus/;
	&log_change("Scientific name not published: Lupinus elatus var. viridulus modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM9815|POM96973|POM11039|POM11044|POM11046|POM11096|POM11103|POM123537|POM128664|POM145415|POM158394|POM173545|POM184296|POM19097|POM203092|POM23753|POM2437|POM2483|POM2484|POM24844|POM2513|POM2586|POM2618|POM2657|POM26693|POM27641|POM276450|POM276454|POM299296|POM299298|POM305479|POM305673|POM305955|POM306279|POM306353|POM307717|POM310146|POM312120|POM312127|POM6955|POM88476|RSA102271|RSA104452|RSA113198|RSA113353|RSA118045|RSA124211|RSA160413|RSA167055|RSA169163|RSA171372|RSA17253|RSA182300|RSA219973|RSA33606|RSA34555|RSA372148|RSA39051|RSA430281|RSA430282|RSA430283|RSA430284|RSA430285|RSA430286|RSA430287|RSA430288|RSA430289|RSA430392|RSA430395|RSA430406|RSA431059|RSA431079|RSA503808|RSA503811|RSA503815|RSA503816|RSA519402|RSA584262|RSA584264|RSA6710|RSA6724|RSA78781|RSA87206|RSA91191)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lupinus formosus var\. proximus/Lupinus formosus/;
	&log_change("Scientific name not published: Lupinus formosus var. proximus modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA552704|RSA557777|RSA560504)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Guillenia lasiophylla var\. inalienus/Caulanthus lasiophyllus var. inalienus/;
	&log_change("Scientific name combination not published, only Guillenia inaliena is valid for this taxon in Guillenia; modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA599523|RSA599611|RSA615654|RSA616355|RSA616365|RSA653249|RSA701909|RSA701943|RSA749311)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Guillenia lasiophylla var\. lasiophylla/Guillenia lasiophylla/;
	&log_change("Scientific name combination not published, only Guillenia lasiophylla is valid for this taxon in Guillenia; modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA599523|RSA599611|RSA615654|RSA616355|RSA616365|RSA653249|RSA701909|RSA701943|RSA749311)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Guillenia lasiophylla var\. lasiophyllus/Guillenia lasiophylla/;
	&log_change("Scientific name combination not published, only Guillenia lasiophylla is valid for this taxon in Guillenia; modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM95608|POM11961|POM204441|RSA500186|RSA527664|RSA527665|RSA527666|RSA527667|RSA543133|RSA543134|RSA559936|RSA559937|RSA562428|RSA564042|RSA574732|RSA593696)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Guillenia lasiophylla var\. rigidus/Caulanthus lasiophyllus var. rigidus/;
	&log_change("Scientific name combination not published: only Guillenia rigida is valid for this taxon in Guillenia; modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA517596|RSA549547|RSA549602|RSA676283)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Guillenia lasiophylla var\. utahensis/Caulanthus lasiophyllus var. utahensis/;
	&log_change("Scientific name combination not published: no valid name for this taxon in Guillenia; modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA620948)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Guillenia lasiophylla var\. utahense/Caulanthus lasiophyllus var. utahensis/;
	&log_change("Scientific name combination not published: no valid name for this taxon in Guillenia; modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM198622|RSA129122|RSA138204|RSA141230|RSA184784|RSA238355|RSA238972|RSA238973|RSA285058|RSA299128|RSA299129|RSA758491)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trisetum canescens var\. canescens/Trisetum canescens/;
	&log_change("Scientific name combination not published: Trisetum canescens var. canescens not in Tropicos, modified to:==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0105707)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Gilia lottiae subsp\. sabulosa/Gilia lottiae/;
	&log_change("Scientific name combination not published: Gilia lottiae subsp. sabulosa not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA732212|RSA732992)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Boechera sparsiflora var\. californica/Boechera californica/;
	&log_change("Scientific name combination not published: Boechera sparsiflora var. californica not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA778928)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Cryptantha clokeyi var\. rigida/Cryptantha clokeyi/;
	&log_change("Scientific name combination not published: Cryptantha clokeyi var. rigida not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA244990)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Cryptantha flaccida var\. rostellata/Cryptantha flaccida/;
	&log_change("Scientific name combination not published: Cryptantha flaccida var. rostellata not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM304536|RSA26601)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Cryptantha flaccida var\. spithamea/Cryptantha flaccida/;
	&log_change("Scientific name combination not published: Cryptantha flaccida var. spithamea not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA786564)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Isolepis cernua var. californicus/Isolepis cernua/;
	&log_change("Scientific name combination not published: Isolepis cernua var. californicus not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA795988)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Cusickiella douglasii var. crockeri/Cusickiella douglasii/;
	&log_change("Scientific name combination not published: Cusickiella douglasii var. crockeri not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM98558)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Triteleia laxa var\. candida/Triteleia laxa/;
	&log_change("Scientific name combination not published: Triteleia laxa var. candida not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA378032)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Triteleia laxa var\. nimia/Triteleia laxa/;
	&log_change("Scientific name combination not published: Triteleia laxa var. nimia not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM229652|RSA0098392|RSA0098399)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Spergularia macrotheca var\. scariosa/Spergularia macrotheca/;
	&log_change("Scientific name combination not published: Spergularia macrotheca var. scariosa not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA753927)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Suaeda calceoliformis var\. depressa/Suaeda calceoliformis/;
	&log_change("Scientific name combination not published: Suaeda calceoliformis var. depressa not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(POM260374|RSA787673)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Suaeda moquinii var\. ramosissma/Suaeda moquinii/;
	&log_change("Scientific name combination not published: Suaeda moquinii var. ramosissma not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA786477)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Pinus remorata var\. remorata/Pinus remorata/;
	&log_change("Scientific name combination not published: Pinus remorata var. remorata not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA524480)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Tauschia arguta var\. capitatum/Tauschia arguta/;
	&log_change("Scientific name combination not published: Tauschia arguta var. capitatum not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0000236)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Eleocharis parvula var\. johnstonii/Eleocharis parvula/;
	&log_change("Scientific name combination not published: Eleocharis parvula var. johnstonii not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA610548)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Elymus stebbinsii var\. laeve/Elymus stebbinsii/;
	&log_change("Scientific name combination not published: Elymus stebbinsii var. laeve not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA502503)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Encelia actoni var\. intermedius/Encelia actoni/;
	&log_change("Scientific name combination not published: Encelia actoni var. intermedius not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0082892)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Heliotropium curassavicum var\. californicum/Heliotropium curassavicum/;
	&log_change("Scientific name combination not published: Heliotropium curassavicum var. californicum not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA51433)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Hordeum brachyantherum var\. sitanion/Hordeum brachyantherum/;
	&log_change("Scientific name combination not published: Hordeum brachyantherum var. sitanion not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA0001812)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Krynitzkia decipiens var\. longiloba/Krynitzkia decipiens/;
	&log_change("Scientific name combination not published: Krynitzkia decipiens var. longiloba not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA368348)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Juncus circumscissa var\. occidentalis/Juncus occidentalis/;
	&log_change("Scientific name combination not published: Juncus circumscissa var. occidentalis not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}
if (($id =~ m/^(RSA127232)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Leymus pacificus var\. vancouvernsis/Leymus pacificus/;
	&log_change("Scientific name combination not published: Leymus pacificus var. vancouvernsis not in Tropicos, modified to==>$tempName\t==>\t$id\n");
}

#format hybrid names
if($tempName=~m/^([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation=$tempName;
	warn "Hybrid Taxon: $1 removed from $tempName\n";
	&log_change("Scientific name: Hybrid Taxon==>$1 removed from $tempName");
	$tempName=$1;
}
elsif($tempName=~m/^([A-Z][a-z-]+) [Xx×] [A-Z][a-z-]+/){ #Hymenoclea X Ambrosia, two genera
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

if ($id =~ m/^(POM256932|RSA0033897|RSA762509)$/){ 
	print "NAME CHECK(2): $scientificName\n";
}

$scientificName=&validate_scientific_name($scientificName, $id);

#####process cultivated specimens			
# flag taxa that are cultivars, add "P" for purple flag to Cultivated field	
if ($establishmentMeans=~ m/^[Cc]ult[a-z]+/){
	$cultivated = "P";
	&log_change("CULT: Taxon flagged as cultivated in original database: $cultivated\t==>\t$scientificName\n");
}
else{
		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("CULT: specimen likely not cultivated, purple flagging skipped: $scientificName\t--\t$id\n");
			$cultivated = "";
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($habitat =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("CULT: Cultivated specimen found and purple flagged ($cultivated)\t--\t$scientificName\t--\t$id\n");
		}
#add exceptions here to the CCH cultivated routine on a specimen by specimen basis
#		elsif (($id =~ m/^(UCR263222|UCR262468|UCR262466)$/) && ($scientificName =~ m/Enchylaena tomentosa/)){
#			&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
#		$cultivated = "";
#		}

#Check remaining specimens for status with CCH cultivated routine
		else {		
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			#&log_change("Taxon skipped purple flagging: ($cultivated)\t--\t$scientificName\n");
			$cultivated = "";
			}
		}
	
}

##########COLLECTION DATE##########

######COLLECTION DATE#######
#$verbatimEventDate doesn't need to be processed
#although RSA has requested that the formatted start date ($eventDate) be used as the verbatimEventDate for now if available,
#since CCH currently only displays the verbatim event date
my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;
my $month;

	foreach ($verbatimEventDate){
	s/  +/ /g;
	s/ +$//g;
	s/^ +//g;
}


	foreach ($eventDate){
	s/ ?- ?/-/g;
	s/  +/ /g;
	s/ +$//g;
	s/^ +//g;
	s/NULL//g;
	}	


	if($eventDate=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "Date (1)$eventDate\t$id";
	}
	elsif($eventDate=~/^(\d\d)-(\d\d)-([0-9]{4})/){	#added to SDSU, if eventDate is in the format ##-##-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	warn "Date (2)$eventDate\t$id";
	}
	elsif($eventDate=~/^([0-9]{1})-([0-9]{1,2})-([0-9]{4})/){	#added to SDSU, if eventDate is in the format #-##?-####, most appear that first # is month 
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	warn "Date (3)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([Ss][pP][rR][ing]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (14)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([Ss][uU][Mm][mer]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "6";
		$DD = "1";
		$MM2 = "8";
		$DD2 = "31";
	warn "Date (16)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([fF][Aa][lL]+)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$DD = "1";
		$MM = "9";
		$DD2 = "30";
		$MM2 = "11";
	warn "Date (12)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([0-9]{1,2}) ([A-Za-z]+) ([0-9]{4})/){
		$DD=$1;
		$MM=$2;
		$YYYY=$3;
		$MM2 = "";
		$DD2 = "";
	warn "(2)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{1,2})[- ]+([0-9]{1,2})[- ]+([A-Z][a-z]+)[- ]([0-9]{4})/){
		$DD=$1;
		$DD2=$2;
		$MM=$3;
		$MM2=$3;
		$YYYY=$4;
	warn "(4)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([A-Za-z]+)-([0-9]{2})$/){
	warn "Date (6): $eventDate\t$id";
		$eventDate = "";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([A-Z][a-z]+)-(June?)[- ]$/){ #month, year, no day
		$YYYY = $1;
		$DD = "1";
		$MM = $1;
		$DD2 = "30";
		$MM2 = $2;
	warn "Date (7): $eventDate\t$id";
	}
	elsif ($eventDate=~/^([A-Z][a-z]+)[- ](June?)[- ]([0-9]{4})$/){ #month, year, no day
		$YYYY = $3;
		$DD = "1";
		$MM = $1;
		$DD2 = "30";
		$MM2 = $2;
	warn "Date (8): $eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([A-Z][a-z]+)[- ](Ma[rchy])[- ]$/){ #month, year, no day
		$YYYY = $1;
		$DD = "1";
		$MM = $1;
		$DD2 = "31";
		$MM2 = $3;
	warn "Date (9): $eventDate\t$id";
	}
	elsif ($eventDate=~/^([A-Z][a-z]+)[- ](Ma[rchy])[- ]([0-9]{4})/) {#month, year, no day
		$YYYY = $3;
		$DD = "1";
		$MM = $1;
		$DD2 = "31";
		$MM2 = $2;
	warn "Date (10): $eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([fF][Aa][lL]+)/) {
		$YYYY = $1;
		$DD = "1";
		$MM = "9";
		$DD2 = "30";
		$MM2 = "11";
	warn "Date (11)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (13)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (15)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([A-Za-z]+) ([0-9]{4})$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(5)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([A-Za-z]+) ([0-9]{2})([0-9]{4})$/){
		$DD = $2;
		$MM = $1;
		$YYYY= $3;
		$MM2 = "";
		$DD2 = "";
	warn "Date (20)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([Ss][uU][Mm][mer]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (17)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]*$/){
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
		$MM="";
	#warn "Date (18)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})-([0-9]{1,2})[- ]*$/){
		$MM=$2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
	#warn "Date (19)$eventDate\t$id";
	}
	elsif (length($eventDate) == 0){
		$YYYY="";
		$MM2 = "";
		$DD2 = "";
		$DD = "";
		$MM="";
		&log_change("Date: date NULL $id\n");
	}
	else{
		&log_change("Date: date format not recognized: $eventDate==>($verbatimEventDate)\t$id\n");
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

#$MM2= $DD2 = ""; #set late date to blank if only one date exists
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
		s/AndrA./Andre/g;
		s/PeAalosa/Penalosa/g;
		s/LaPrA/LaPre/g;
		s/OrdoAez/Ordonez/g;
	
		s/  +/ /;
		s/^ +//;
		s/ +$//;
}
$collector = ucfirst($verbatimCollectors);

	
	if ($collector =~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
#		$recordedBy = &CCH::validate_collectors($collector, $id);	
	#D Atwood; K Thorne
		$other_coll=$2;
		#warn "Names 1: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
		&log_change("COLLECTOR (): modified: $verbatimCollectors==>$collector--\t$recordedBy\t--\t$other_coll\t$id\n");	
	}
	
	elsif ($collector !~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
#		$recordedBy = &CCH::validate_collectors($collector, $id);
		#warn "Names 2: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
		$other_coll="";
	}
	elsif (length($collector == 0)) {
		$recordedBy = "Unknown";
		$other_coll="";
		&log_change("COLLECTOR (2): modified from NULL to $recordedBy\t$id\n");
	}	
	else{
		&log_change("COLLECTOR (3): name format problem: $verbatimCollectors==>$collector\t--$id\n");
		$verbatimCollectors = $collector;
		$other_coll="";
	}

###further process other collectors
foreach ($other_coll){
	s/'$//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;

}
$other_collectors = ucfirst($other_coll);





#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes
foreach ($recordNumber){
	s/#//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

my $CNUM_suffix="";
($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);


####COUNTRY
	if ($country=~/^United States/){
		$country="USA";
	}
	else{
		&log_change("COUNTRY: unknown Country value");
	}


	if ($stateProvince=~m/^BCN$/i){
		$stateProvince =~ s/.*/Baja California/;
	}
	elsif ($stateProvince=~m/^Baja California$/){
		#do nothing
	}
	elsif ($stateProvince=~m/^(CA|California)$/i){
		$stateProvince =~ s/.*/California/;
	}
	else{
		&log_skip("LOCATION Country and State problem, skipped==>($country)\t($stateProvince)\t($tempCounty)\t($Locality1)\t$id");
		++$skipped{one};
		next Record;
	}


#########################County/MPIO
#delete some problematic Mexico specimens

my %country;



######################COUNTY
foreach($tempCounty){
	s/'//g;
	s/^ +//g;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries
}


#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);


######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown==>$id ($country)\t($stateProvince)\t($tempCounty)\t$Locality1");		
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

foreach ($Locality2,$Locality1){
	s/'$//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}
	if((length($Locality1) > 1) && (length($Locality2) == 0)){
		$locality = $Locality1;
				
	}		
	elsif ((length($Locality1) > 1) && (length($Locality2) >1)){
		$locality = "$Locality1, $Locality2";
		$locality =~ s/'$//;
	}
	elsif ((length($Locality1) == 0) && (length($Locality2) >1)){
		$locality = $Locality2;
		$locality =~ s/: *$//;
	}
	elsif ((length($Locality1) == 0) && (length($Locality2) == 0)){
		$locality = "";
		&log_change("LOCAT: Locality1 & Locality2 NULL, $id\n");
	}
	else {
		&log_change("Locality problem, bad format, $id\t--\t$Locality1\t--\t$Locality2\n");		#call the &log function to print this log message into the change log...
		$locality = "";
	}

#########################ELEVATION
#$elevationInMeters is the darwin core compliant value
#verify if elevation fields are just numbers
###############ELEVATION########
foreach($verbatimElevation){
	s/  +/ /g;		#collapse consecutive whitespace as many times as possible
	s/ +$//;
	s/^ +//;
	
}


foreach($minimumElevationInMeters){

	s/-9999+//;		#change the symbiota defualt or missing value -9999 to null

	s/  +/ /g;		#collapse consecutive whitespace as many times as possible
	s/^ +//;
	s/ +$//;
}

	if ((length($verbatimElevation) >= 1) && (length($minimumElevationInMeters) == 0) && (length($maximumElevationInMeters) == 0)){
		$elevation = $verbatimElevation."ft"; #RSA states that the verbatim elevation field is in feet
	}		
	elsif ((length($verbatimElevation) >= 1) && (length($minimumElevationInMeters) >= 1) && (length($maximumElevationInMeters) == 0)){
		$elevation = "$minimumElevationInMeters m";
	}
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevationInMeters) >= 1) && (length($maximumElevationInMeters) == 0)){
		$elevation = "$minimumElevationInMeters m";
	}
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevationInMeters) >= 1) && (length($maximumElevationInMeters) >= 1)){
		$elevation = "$minimumElevationInMeters m";
	}
	elsif ((length($verbatimElevation) >= 1) && (length($minimumElevationInMeters) >= 1) && (length($maximumElevationInMeters) >= 1)){
		$elevation = "$minimumElevationInMeters m";
	}
	elsif ((length($verbatimElevation) >= 1) && (length($minimumElevationInMeters) == 0) && (length($maximumElevationInMeters) >= 1)){
		$elevation = "$maximumElevationInMeters m";
	}
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevationInMeters) == 0) && (length($maximumElevationInMeters) >= 1)){
		$elevation = "$maximumElevationInMeters m";
	}
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevationInMeters) == 0) && (length($maximumElevationInMeters) == 0)){
		$elevation = "";
		&log_change("Elevation NULL\t$id");
	}
	else {
		&log_change("Elevation problem, elevation non-numeric or poorly formatted, $id\t--\t($minimumElevationInMeters)($maximumElevationInMeters)\t--\t($verbatimElevation)\n");		#call the &log function to print this log message into the change log...
		$elevation = "";
	}


#process elevation fields into CCH format
foreach($elevation){
	s/\.\d+//; #remove decimals from elevations
	s/ [eE]lev.*//;	#remove trailing content that begins with [eE]lev
	s/feet/ft/;	#change feet to ft
#	s/\d+ *m\.? \((\d+).*/$1 ft/;
#	s/\(\d+\) \((\d+).*/$1 ft/;
	s/'/ft/;	#change ' to ft
	s/FT/ft/;	#change FT to ft
	s/Ft/ft/;	#change Ft to ft
	s/NULL//g;
	s/sea.?level$/0 m/i;
	s/sealevel/0 m/i;
	s/ca?\.? ?//i;
	s/irc?\.? *//i;
	s/near ?//;
	s/Close to ?//i;
	s/approx\.//g;
	s/Below ?//i;
	s/^o m/0 m/i;
	s/- *ft/ft/;
	s/meters/m/;
	s/summit//i;
	s/sealevelto//i;
	s/alt\.? ?//i;
	s/apx\.? ?//i;
	s/bet\.? *//i;
	s/abt\.? *//i;
	s/about\.? *//i;
	s/\(\)//;
	s/~//g;
	s/∞//g;
	s/\[//g;
	s/\]//g;
	s/\?//g;
	s/,//g;
	s/\+\/-//g;
	s/\>//g;
	s/\<//g;
	s/\@//g;
	s/[Mm]\.? *$/m/;	#substitute M/m/M./m., followed by anything, with "m"
	s/ft?\.? *$/ft/;	#subst. f/ft/f./ft., followed by anything, with ft
	s/ft/ ft/;		#add a space before ft
	s/m *$/ m/;		#add a space before m
	s/^0+$/0 m/;
	s/\+-//g;
	s/ //g;		#collapse space as many times as possible
}

if (length($elevation) >= 1){

	if ($elevation =~ m/^(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation =~ m/^(-?[0-9]+)([fFtT]+)/){ #added <? to fix elevation in BLMAR421 being skipped
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation =~ m/^(1\d{4})$/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation =~ m/^([456789]\d{3})$/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation =~ m/^(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = $elevation;
	}
	elsif ($elevation =~ m/^(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = $elevation;
		$CCH_elevationInMeters =~ s/m$/ m/;
	}
	elsif ($elevation =~ m/^[A-Za-z ]+(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevation =~ m/^(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevation =~ m/^(-?[0-9]+)-(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation =~ m/^[A-Za-z ]+(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevation =~ m/^[A-Za-z]+(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("Elevation: elevation '$elevation' has problematic formatting or is missing units\t$id");
		$elevationInFeet = $CCH_elevationInMeters = $elevationInMeters = "";
	}	
}
elsif (length($elevation) == 0){
		$elevationInFeet = $CCH_elevationInMeters = "";
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
		&log_change ("ELEV: $county\t$elevation_test ft. ($elevationInMeters m.) greater than $county maximum ($max_elev{$county} ft.): discrepancy=", (($elevation_test)-$max_elev{$county}),"\t$id\n");
		if ((($elevation_test)-$max_elev{$county}) >= 500 ){
			$CCH_elevationInMeters = "";
			&log_change ("ELEV: $county discrepancy=", (($elevation_test)-$max_elev{$county})," greater than 500 ft, elevation changed to NULL\t$id\n");
		}
	}

#########COORDS, DATUM, ER, SOURCE#########
my $lat_sum;
my $long_sum;
my $Check;
my $hold;
my $hold;
my $lat_degrees;
my $lat_minutes;
my $lat_seconds;
my $lat_decimal;
my $long_degrees;
my $long_minutes;
my $long_seconds;
my $long_decimal;

####TRS
if ($Township && $Range && $Section) {
	$TRS = "$Township $Range $Section";
}
elsif ($Township && $Range) {
	$TRS = "$Township $Range";
}
elsif ($Township || $Range || $Section) { 
	&log_change("TRS data missing township and/or range. TRS nulled: $id"); #TRS needs both township and range
	$TRS = "";
}
else { #else all three are blank
	$TRS = "";
}


#######Latitude and Longitude
foreach ($verbatimLatitude){
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/,/ /g;
		s/-//g; #remove negative latitudes, we dont map specimens from southern hemisphere, so if "-" is present, it is an error
		s/deg\.?/ /;
		s/ 17 1.218/ 17.5/;#fix a series of bad latitudes
		s/ 35682/ 35.682/;
		s/^341832/34.1832/;
		s/ 1213/ 12.5/;
		s/ 4241/ 42 41/;
		s/ 4750/ 47 50/;
		s/ 47\.+50/ 47 50/;
		s/ 4748/ 47 48/;
		s/^32 7112/ 32.7112/;
		s/ 5153.5\.5/ 52/; 
		s/^3440/34 40/;
		s/ 51\.+53\.5/ 52/;
		s/ 910.5/ 10/;
		s/ 5657/ 56.5/;

	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
		
}

foreach ($verbatimLongitude){
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/,/ /g;
		s/deg\.?/ /;
		s/^-?12208983/122.08983/;#fix a series of bad longitudes
		s/^-?1173836/-117.3836/;
		s/^-?11655/116 55/;
		s/^-?12025/120 25/;
		s/ 6\.5-7/ 6.75/;
		s/ 51-52/ 51.5/;
		s/ 55 3.4/55.5/;
		s/ 53-54\.5/53.5/;
		s/^-?17 /117 /;
		s/^-?14 /114 /;
		s/^-?118\.+119/118.5/;
		s/ 53-54/ 53.5/;
		s/ 52-54/ 53/;
		s/ 35433/ 35 43.3/;
		s/ 17-22/ 17 22/;
		s/ 17\.+22/ 17 22/;
	s/  +/ /;
	s/^ $//;
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

}	


#fix some really problematic records with data that is misleading and causing georeference errors

if (($id =~ m/^(RSA649688|RSA648655|RSA648656|RSA653414|RSA653416|RSA0008326|RSA660597)$/) && ($county=~m/^Orange/) && ($latitude=~m/^34.3186/)){
			$latitude = "33.7915"; #delete the persistently bad georeference if it maps to anything but this latitude, currently mapping to Lat 34.3186
			$longitude = "-117.7217";
	&log_change("COORD: LAT_LONG error, the original coordinates ($verbatimLatitude,$verbatimLongitude) maps to Tujunga Canyon in Los Angeles County, the locality states this specimen is from Fremont Canyon in Orange County, changed to ==>($latitude, $longitude)\t$county\t$locality\t--\t$id\n");
}

if (($id =~ m/^(RSA691538)$/) && ($county=~m/^(Unknown| *)/i) && ($latitude=~m/.*/) && ($Locality1=~m/^S\. Cal\./i)){
			$latitude = ""; #delete the persistently bad georeference if it maps to anything
			$longitude = "";
	&log_change("COORD: LAT_LONG error, the original coordinates ($verbatimLatitude,$verbatimLongitude) maps to the San Bernardino mountains, the locality states this specimen is from 'S. CAL' without a county, so it should not be mapped, coordinates changed to NULL ==>$county\t$locality\t--\t$id\n");
}

if (($id =~ m/^(RSA642293)$/) && ($county=~m/Barbara/) && ($longitude=~m/^-?115\./)){
#366375		RSA	642293		Myrtaceae	Eucalyptus	globulus			Eucalyptus globulus					Not type	Steven  A. Junak	SC-2977	1991-09-19		United States	California	Santa Barbara County	Santa Cruz Island. Lower portion of Scorpion Canyon, upstream from Scorpion Ranch		33.7125	-115.4013889								37		120		fruits			Introduced	Herbarium sheet - 1	9e48718f-0d1c-4952-a31a-d9da357b8f27
#SBBG101581==>34.0475	-119.566
			$latitude = "34.0475"; 
			$longitude = "-119.566";
	&log_change("COORD: LAT_LONG error, the original coordinates ($verbatimLatitude,$verbatimLongitude) maps to Cuckwalla Valley in Riverside County, the locality states this specimen is from Santa Cruz Island, coordinates copied from a dup SBBG101581, changed to ==>($latitude, $longitude)\t$county\t$locality\t--\t$id\n");
}
if (($id =~ m/^(RSA651675)$/) && ($county=~m/Angeles/) && ($longitude=~m/^-?115\./)){
#352497		RSA	651675		Lamiaceae	Salvia	columbariae			Salvia columbariae			Orlando Mistretta	2005-05	Not type	R. Carlson	78	1961-05-04		United States	California	Los Angeles County	San Dimas Canyon.		33.7125	-115.4013889							Unknown								Native	Herbarium sheet - 1	376fefaa-72b3-43b5-a44b-21244c2764b8
#POM211787==>34.1655556	-117.7691667
			$latitude = "34.1655556"; 
			$longitude = "-117.7691667";
	&log_change("COORD: LAT_LONG error, the original coordinates ($verbatimLatitude,$verbatimLongitude) maps to Cuckwalla Valley in Riverside County, the locality states this specimen is from San Dimas Canyon, new coordinated copied from POM211787, changed to ==>($latitude, $longitude)\t$county\t$locality\t--\t$id\n");
}


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
		s/ +//g;
	}
	else {$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
	}
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
		&log_change("coordinates set to null for $id, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude = $decimalLongitude = $georeferenceSource = $datum="";	#and set $decLat and $decLong to ""  
	}
}
else {
		if((length($decimalLatitude) == 0)  && (length($decimalLongitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $id: ($verbatimLatitude) \t($verbatimLongitude)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}


###########ERROR RADIUS AND UNITS#####
foreach ($errorRadius,$errorRadiusUnits) {
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

#######Georeference Source#############
#RSA has some weird ones that start with brackets or numbers. Null these
foreach ($georeferenceSource) {
	s/^"//;
	s/"$//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}
if ($georeferenceSource =~ /^\(|^\[|^(\d+)$/){
	&log_change("Nulling strange georeference source \"$georeferenceSource\": $id");
	$georeferenceSource = "";
}


#######Habitat and Assoc species (dwc habitat and associatedTaxa)
 
 foreach ($habitat){
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}


#######Notes and phenology fields
 foreach ($occurrenceRemarks){
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}
 foreach ($phenology){
	s/  +/ /;
	s/^ +//;
	s/ +$//;
} 
 
 
#####Type status###############
#remove "Not type"
if ($typeStatus eq "Not type"){
	$typeStatus = "";
}

 foreach ($typeStatus){
	s/  +/ /;
	s/^ +//;
	s/ +$//;
} 

#########Skeletal Records
	if((length($recordNumber) < 1) && (length($typeStatus) < 2) && (length($locality) < 2) && (length($eventDate) == 0) && (length($habitat) < 2) && (length($decimalLatitude) == 0) && (length($decimalLongitude) == 0)){ #exclude skeletal records
			&log_skip("VOUCHER: skeletal records without data in most fields including locality and coordinates\t$id");	#run the &log_skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
	}

++$count_record;
warn "$count_record\n" unless $count_record % 10000;

print OUT <<EOP;

Accession_id: $id
Other_label_numbers: $occurrenceID
Name: $scientificName
Date: $eventDate
EJD: $EJD
LJD: $LJD
Collector: $collector
Other_coll: $other_collectors
Combined_coll: $verbatimCollectors
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Country: $country
State: $stateProvince
County: $county
Location: $locality
Habitat: $habitat
T/R/Section: $TRS
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Lat_long_ref_source: $georeferenceSource
Datum: $datum
Max_error_distance: $errorRadius
Max_error_units: $errorRadiusUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation ft
Verbatim_county: $tempCounty
Phenology: $phenology
Notes: $occurrenceRemarks
Hybrid_annotation: $hybrid_annotation
Cultivated: $cultivated
Type_status: $typeStatus
Annotation: $det_orig
Annotation: $det_string

EOP

#add one to the count of included records
++$included;
}


close (IN);

my $skipped_taxa = $count-$included;
print <<EOP;
INCL: $included
EXCL: $skipped{one}
TOTAL: $count

SKIPPED TAXA: $skipped_taxa
EOP





close(OUT);
close(OUT2);
close(OUT3);
close(OUT4);

#####Check final output for characters in problematic formats (non UTF-8), this is Dick's accent_detector.pl
my @words;
my $word;
my $store;
my $match;
my %store;
my %match;
my %seen;
%seen=();


    my $file_in = '/JEPS-master/CCH/Loaders/RSA/RSA_out.txt';	#the file this script will act upon is called 'CATA.out'
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


