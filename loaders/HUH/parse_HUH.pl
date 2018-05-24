
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

open(OUT,">/JEPS-master/CCH/Loaders/HUH/HUH_out.txt") || die;

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;
my $count_record;

my $file = '/JEPS-master/CCH/Loaders/HUH/huh_apr2017.txt';

open(IN,$file) || die;	#open the file, die.
Record: while(<IN>){	#while in the file, (Records...)

#fix some data quality and formatting problems that make import of fields of certain records impossible

	chomp;		#remove trailing new line /n

	$line_store=$_;
	++$count;


#fix some data quality and formatting problems that make import of fields of certain records impossible


	s/\xc2//g;
	s/\xc3//g;
	s/\xc5//g;
	s/\xcb//g;
	s/\xce//g;
	s/\xe2//g;
	s/\xc2//g;
	
	
	s/\xaf/o/g;
	s/\xb7/a/g;
	s/\xb8/u/g;
	s/\x81//g;
	s/\x82/a/g;
	s/\x88/e/g;	
	s/\x8b/e/g;
	s/\x8c/i/g;
	s/\x8e/e/g;
	s/\x92/n/g;
	
	
	
	s/’/'/g;
	s/“/"/g;
	s/”/"/g;
	s/\xa1//g;	
	s/\xa9//g;	
	s/\x80//g;
	s/\x97//g;
	s/\x88//g;
	s/\xa6//g;
	s/\xb0//g;
	s/\xbc//g;
	s/\x9a//g;
	s/\x84//g;
	s/\xb4/'/g;
	s/\x86/o/g;
	s/\x9e/ deg./g;
	s/\xab/ deg./g;
	s/\x8a/ X /g;
	s/\xb1/+-/g;

	
#skipping: problem character detected: s/\xc2\xa1/    /g   ¬° ---> ¬°.	
#skipping: problem character detected: s/\xc2\xaf/    /g   ¬Ø ---> Rottb¬Øll	
#skipping: problem character detected: s/\xc2\xb7/    /g    ---> C¬∑rdenas	J¬∑tiva	S¬∑ez	
#skipping: problem character detected: s/\xc2\xb8/    /g   ¬∏ ---> K¬∏kenthal	Niederm¬∏ller	M¬∏ller	
#skipping: problem character detected: s/\xc3\x81/    /g   √Å ---> Mo√Åi√ío	
#skipping: problem character detected: s/\xc3\x82/    /g   √Ç ---> (Forssk√Çl)	
#skipping: problem character detected: s/\xc3\x88/    /g   √à ---> N√àe	Jos√à	L√àveill√à	Pos√à	Demar√àe	Kergu√àlen	Andr√à)	Hult√àn	Hult√àn,	Av√à-Lallemant)	Av√à-Lallemant	(Sess√à	
#skipping: problem character detected: s/\xc3\x8b/    /g   √ã ---> Carri√ãre	Rivi√ãre	
#skipping: problem character detected: s/\xc3\x8c/    /g   √å ---> pen√ånsula,	
#skipping: problem character detected: s/\xc3\x8e/    /g   √é ---> Hierochlo√é	
#skipping: problem character detected: s/\xc3\x92/    /g   √í ---> Madro√ío	Ca√íon	Ca√íones,	ca√íons	I√íez	Ca√íon,	Pi√íos,	ca√íon	A√ío	Ca√íons	Ca√íon-Liebre	Ca√íon.	Ca√íons,	Pi√íon	Se√íores	Mu√íoz	Ca√íada	ca√íon,	Ca√íyon,	Ca√íon:	Ba√íos	Pe√íalosa	Pe√íasquitos	(Madro√ío	Enci√íitas	Ca√í.	Cor√íon	Ca√íon),	Mo√Åi√ío	
#skipping: problem character detected: s/\xc5\x92\xc2\xb1/    /g   ≈í¬± ---> ≈í¬±	
#skipping: problem character detected: s/\xcb\x86/    /g   ÀÜ ---> FrÀÜderstrÀÜm	GÀÜppert)	LÀÜve	LÀÜve)	LÀÜve,	K‚Ä∞llersjÀÜ	WikstrÀÜm	
#skipping: problem character detected: s/\xce\xa9/    /g   Œ© ---> Œ©	
#skipping: problem character detected: s/\xe2\x80\x9a\xc3\x84\xc3\xb4/    /g   ‚Äö√Ñ√¥ ---> California‚Äö√Ñ√¥s	
#skipping: problem character detected: s/\xe2\x80\xa6/    /g   ‚Ä¶ ---> ‚Ä¶.	
#skipping: problem character detected: s/\xe2\x80\xb0/    /g   ‚Ä∞ ---> K‚Ä∞llersjÀÜ	
#skipping: problem character detected: s/\xe2\x88\x9a\xc3\xbc/    /g   ‚àö√º ---> ‚àö√º.	
#skipping: problem character detected: s/\xe2\x88\x9e/    /g   ‚àû ---> 41‚àû49.8'N,	123‚àû38'W,	33‚àû00'N	116‚àû30'W,	35‚àû,	119‚àû	35‚àûN,	35‚àû	119‚àûW	34‚àû06'N,	119‚àû05'W	34‚àû18',	116‚àû55',	52-55‚àû	36‚àû	118‚àû,	37‚àû23'13	121‚àû39'26	N60‚àûE	20‚àûS	S‚àû60	8‚àûSW	N36‚àûW	35‚àûS	S79‚àûE	N88‚àûW	S77‚àûW	N4‚àûW	N9‚àûW	S10‚àûW	S15‚àûW	S60‚àûW	S37‚àûW	32‚àû	1/2'N.116‚àû	34‚àû	118‚àû	N25‚àûW	S25‚àûW	N81‚àûE	N55‚àûE	N78‚àûE	34‚àû;	S41‚àûE	N80‚àûE	S70‚àûW	N40‚àûW	N17‚àûW	N10‚àûE	N1‚àûW	N80‚àû	34.42732‚àûN	119.87121‚àû	128.8‚àû	37‚àû	122‚àû	S50‚àûW	116‚àû	10‚àûW	N70‚àûE	39‚àû	120‚àû	N85‚àûE	N85‚àûW	117‚àû	33‚àû	37‚àû14'08	121‚àû15'37	121‚àû56.5'W.,	37‚àû36.75'N.	N31‚àûE	41‚àû	N18‚àûE	(74‚àû)	41.19254‚àû	120.12107‚àû	39‚àû34.9'N,	121‚àû8.3'W	72839‚àû	118.73530‚àû	32.73637‚àû	116.088779‚àû	114‚àû-121‚àû	38‚àû39.6'N,	120‚àû57.2'W	41.512‚àûN,	123.872‚àûW	
#skipping: problem character detected: s/\xe2\x88\xab/    /g   ‚à´ ---> S79‚à´E	S50‚à´W	37‚à´	122‚à´	N85‚à´W	34‚à´	118‚à´	121‚à´	35‚à´	119‚à´	116‚à´	S53‚à´E	S77‚à´W	65‚à´	39‚à´	
#skipping: problem character detected: s/\xe2\x97\x8a/    /g   ‚óä ---> ‚óäpringlei	‚óänobleana	‚óätownei	‚óäthompsonii	‚óäparryi	‚óächasei	‚óägrandidentata	‚óäjolonensis	‚óäparishii	‚óävanrensselaeri	‚óäalvordiana	‚óäganderi	‚óämacdonaldii	‚óämorehus	‚óähansenii	‚óäsaundersii	‚óäcinerea	‚óämedia	‚óälobbianus	‚óälorenzenii	‚óäregius	‚óärugosus	‚óäsinensis	‚óälimon	‚óäpomerianicum	‚óäbloomeri	‚óärubens	‚óäpiperita	



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
my $tempName;
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
my $catalogNumberNumeric;
my $institutionCode;
my $collectionCode;
my $collectionId;
my $dc_type;
my $ownerInstitutionCode;
my $basisOfRecord;
my $occurrenceID;
my $catalogNumber;
my $otherCatalogNumbers;
my $kingdom;
my $phylum;     
my $class;
my $order;
my $scientificNameAuthorship;
my $specificEpithet;
my $taxonRank;
my $infraspecificEpithet;
my $identificationReferences;
my $identificationRemarks;
my $taxonRemarks;
my $identificationQualifier;
my $typeStatus;
my $recordedByID;
my $associatedCollectors;
my $year;
my $month;
my $day;
my $startDayOfYear;
my $endDayOfYear;
my $verbatimAttributes;
my $fieldNumber;
my $informationWithheld;
my $dataGeneralizations;
my $dynamicProperties;
my $reproductiveStatus;
my $establishmentMeans;
my $cultivationStatus;    #this fields replaces $cultivation found in other CCH loaders
my $lifeStage;      
my $sex;
my $individualCount;
my $samplingProtocol;
my $samplingEffort;
my $preparations;
my $municipality;
my $locality;      
my $locationRemarks;  #same as localityDetails used by other CCH datasets?
my $localitySecurity;
my $localitySecurityReason;
my $geodeticDatum;
my $coordinateUncertaintyInMeters;
my $verbatimCoordinates;
my $georeferencedBy;
my $georeferenceProtocol;      
my $georeferenceSource;
my $georeferenceVerificationStatus;
my $georeferenceRemarks;
my $minimumDepthInMeters;
my $maximumDepthInMeters;
my $verbatimDepth;
my $disposition;      
my $language;
my $recordEnteredBy;
my $modified;
my $sourcePrimaryKey;
my $collID;
my $recordId;
my $references;      
my $identificationRemarks;
my $det_orig;
my $startdatecollected;
my $enddatecollected;
my $highergeography;
my $continent;
my $islandgroup;
my $island;
my $catalogNumberNumeric;
my $minimumElevationInMeters;
my $maximumElevationInMeters;
my $identifiedBy; 
my $dateIdentified; 
my $dateLastUpdated;



	my @fields=split(/\t/,$_,100);
		unless($#fields==49){ #50 fields but first field is field 0 in perl
		&log_skip("$#fields bad field number $_");
		++$skipped{one};
		next Record;
	}
#institution	collectioncode	collectionid	catalognumber	
#catalognumbernumeric	dc_type	basisofrecord	collectornumber	collector	sex	
#reproductiveStatus	preparations	verbatimdate	eventdate	year	month	day	
#startdayofyear	enddayofyear	startdatecollected	enddatecollected	habitat	highergeography	
#continent	country	stateprovince	islandgroup	county	island	municipality	locality	minimumelevationmeters	maximumelevationmeters	verbatimelevation	decimallatitude	decimallongitude	geodeticdatum	identifiedby	dateidentified	identificationqualifier	identificationremarks	identificationreferences	typestatus	scientificname	scientificnameauthorship	family	informationwitheld	datageneralizations	othercatalognumbers	datelastupdated

#note that if the fields change. The field headers can be found in the huh_out.tab file	
	(
$cultivated,
$collectionCode, #not used
	$collectionId, 
	$catalogNumber, #barcode
	$catalogNumberNumeric, 
	$dc_type, 
$basisOfRecord, 
$recordNumber, 
	$verbatimCollectors, 
	$sex, 
$reproductiveStatus, 
	$preparations, 
$verbatimEventDate, #mostly empty
	$eventDate, 
	$year, 
	$month, 
	$day, 
$startDayOfYear,#mostly empty
$endDayOfYear, #mostly empty
	$startdatecollected, 
	$enddatecollected, 
	$habitat, 
	$highergeography, #skip 
	$continent, #skip
	$country, 
	$stateProvince, 
	$islandgroup, #skip for now
	$county, 
	$island, #skip for now
	$municipality, 
	$locality, 
$minimumElevationInMeters, 
$maximumElevationInMeters, 
$verbatimElevation, 
$verbatimLatitude, 
$verbatimLongitude, 
$datum, 
$identifiedBy, 
$dateIdentified, 
$identificationQualifier, 
$identificationRemarks, 
$identificationReferences, 
$typeStatus, 
	$tempName, 
$scientificNameAuthorship, #skip
	$family, #skip
$informationWithheld, 
$dataGeneralizations, 
$otherCatalogNumbers,
	$dateLastUpdated
)=@fields;




################ACCESSION_ID#############

my $id;

	foreach($catalogNumber){

		if($catalogNumber=~m/^barcode-0+(\d+)$/){
			$catalogNumber =~ s/barcode-0+//; #remove extraneous barcode text 

			if ($catalogNumberNumeric =~ m/^$catalogNumber/){
				$id="$collectionCode$catalogNumberNumeric";
				&log_change("Catalog Number NOT Modified: $id\n");
			}
			else{
	 			$id="$collectionCode$catalogNumber";
	 			&log_change("Catalog Number does not match: $catalogNumberNumeric\t--\t$catalogNumber\t--\t$id\n");
	 		}
		}
		else{
	 		&log_skip("Catalog number problem, skipped: $_");
			++$skipped{one};
			next Record;
		}
	}

#Remove duplicates
if($seen{$id}++){
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate ID number==>$id\t($collectionCode)($catalogNumberNumeric)");
	++$skipped{one};
	next Record;
}


##################Exclude known problematic specimens by id numbers, most from outside California and Baja California
	if(($id=~/^GH356696$/) && ($county=~m/Los/)){ #fix some really problematic county records
		&log_skip("COUNTY: County/Location problem, Pyramid Lake is in Washoe Co., NV, not Los Angeles Co., not a CA specimen ($county)\t($locality)\t$id\n");	
		++$skipped{one};
		next Record;
	}	
	if($id=~/^GH347476$/){ #fix some really problematic county records
		&log_skip("COUNTY: County/Location problem, Bill Williams Fork is in La Paz, Co., Arizona, although the vicinity of the mouth in the 1870's was at the California line (San Bernardino Co, not Riverside as in the database, however)==>($county)\t($locality)\t$id\n");	
		++$skipped{one};
		next Record;
	}
	if($id=~/^GH369209$/){ #fix some really problematic county records
		&log_skip("COUNTY: County/Location problem, Oatman is in Mohave Co., AZ, not a CA specimen ($county)\t($locality)\t$id\n");	
		++$skipped{one};
		next Record;
	}
	
	#GH420048
	if($id=~/^GH420048$/){ #fix some really problematic county records
		&log_skip("COUNTY: County/Location problem, Grapevine Peak is in Nye Co., NV, not a CA specimen ($county)\t($locality)\t$id\n");	
		++$skipped{one};
		next Record;
	}	

	if($id=~/^GH93830|GH77898|GH76682|GH66830|GH61130|GH52752|GH403456$/){ #fix some really problematic county records
		&log_skip("COUNTY: County/Location problem, Fort Mojave is in Mohave Co., AZ, not a CA specimen ($county)\t($locality)\t$id\n");	
		++$skipped{one};
		next Record;
	}
	
###########informationWithheld
	if($informationWithheld=~m/^locality redacted(.*)/i){ #if there is text is informationWithheld (case insensitive), use the string
	 	$informationWithheld = "label data redacted by HUH".$1;
		&log_change("label data redacted by HUH\t$id");
	}
	else{
		$informationWithheld = "";
	}


##########Begin validation of scientific names

#####Annotations  (use to show verbatim scientific name (annotation 0) when a separate annotation file is present)
	#format det_string correctly
my $det_rank = "current determination (uncorrected)";  #set for current determination
my $det_name = $tempName;
my $det_stet = $identificationQualifier;
my $det_date = $dateIdentified;
my $det_identificationRemarks = $identificationRemarks;
my $det_determiner = $identifiedBy;

	
#format det_string correctly
	if ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) >=1)){
		$det_string="$det_rank: $det_name, $det_identificationRemarks";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) >= 1) && (length($det_identificationRemarks) >= 1)){
		$det_string="$det_rank: $det_name, $det_date, $det_identificationRemarks";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) >= 1) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name, $det_date";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) >=1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_identificationRemarks";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) >=1)){
		$det_string="$det_rank: $det_name, $det_identificationRemarks";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) == 0) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name   $det_stet, $det_determiner";
	}
		elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) >=1) && (length($det_date) >= 1) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name   $det_stet, $det_date";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) == 0) && (length($det_identificationRemarks) >=1)){
		$det_string="$det_rank: $det_name   $det_stet, $det_determiner, $det_identificationRemarks";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) >=1) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_date";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) >=1) && (length($det_identificationRemarks) >=1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_date, $det_identificationRemarks";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) >=1) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name   $det_stet, $det_determiner $det_stet, $det_date";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) == 0)){
		$det_string="";
	}
	else{
		
		print "det problem: $det_rank: $det_name   $det_stet, $det_determiner, $det_date, $det_identificationRemarks==>".$id."\n";
		$det_string="";
	}



#####process cultivated specimens
	my $cult;
	foreach($catalogNumber){ #repurpose useless first field as the cultivated field
	
	$cultivated =~ s/^.*$/N/;

	}

## regular Cultivated parsing

		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("specimen likely not cultivated, purple flagging skipped: $tempName\t--\t$id\n");
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection)/i) || ($habitat =~ m/(cultivated from|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("Cultivated specimen found and purple flagged: $cultivated\t--\t$tempName\t--\t$id\n");
		}
		
		elsif ($cultivated !~ m/^P$/){		
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged==>$cultivated\t--\t$tempName\t--\t$id\n");	
			}
			else {
			#&log_change("CULT: Taxon skipped purple flagging==>$cultivated\t--\t$tempName\n");
			$cultivated = "";
			}
		}

## finish validating names

#####process taxon names

foreach ($tempName){
	s/ variety / var. /;	#set the full word "variety" to "var." 
	s/var\./ var. /;		#add a space after and before "var."
	s/Hierochlo[^e ] /Hierochloe /;
	s/ sp\.?$//;	#remove "sp" or "sp."
	s/ forma / f. /;	#change forma to f.
	s/ subspecies / subsp. /;	#change subspecies to subsp.
	s/ ssp / subsp. /;	#change ssp to subsp.
	s/ spp\.? / subsp. /;	#change ssp. to subsp.
	s/ var / var. /;	#change var to var.
	s/ ssp\. / subsp. /;	#change ssp. to subsp.
	s/ f / forma /;	#change a lone "f" to forma to root out if this is filius or forma, any will come up as problem name
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/  +/ /g;			#collapse consecutive whitespace as many times as possible

}

$tempName =~ s/([A-Z][a-z]+) [A-Z]\..*/$1/; #fix specimens determined only as Genus but has a type 1 authority abbreviation==> L.
$tempName =~ s/([A-Z][a-z]+) [A-Z][a-z]+\..*/$1/; #fix specimens determined only as Genus but has a type 2 authority==> Dougl.
$tempName =~ s/([A-Z][a-z]+) [A-Z][a-z]+ ..*/$1/; #fix specimens determined only as Genus but has a type 3 authority==> Webb & Bert
$tempName =~ s/([A-Z][a-z]+) \([A-Z].*/$1/; #fix specimens determined only as Genus but has a type 4 authority==> (Nutt. ex Hook.) Copel.
$tempName =~ s/^([A-Z][a-z]+) [A-Z][a-z]+$/$1/; #fix specimens determined only as Genus but has a type 5 authority==> Webb



#####process remaining taxa

$scientificName = &strip_name($tempName);

$scientificName = &validate_scientific_name($scientificName, $id);

###############DATES###############
my $eventDateAlt;
my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;


foreach ($startdatecollected,$enddatecollected){
	s/,/ /g;
	s/\./ /g;
	s/\//-/g;
	s/  +/ /g;
	}

	if((length($eventDate) > 1) && (length($startdatecollected) > 1)){
		$eventDateAlt=$startdatecollected;
		$verbatimEventDate=$startdatecollected;
		}
	elsif((length($eventDate) > 1) && (length($startdatecollected) == 0)){
		$eventDateAlt=$eventDate;
		$verbatimEventDate=$eventDate;
		}
	elsif((length($eventDate) == 0) && (length($startdatecollected) > 1)){
		$eventDateAlt=$startdatecollected;
		$verbatimEventDate=$enddatecollected."-".$enddatecollected;
		}
	else{
		&log_change("DATE problem: $startdatecollected\t--\t$eventDate\t$id\n");		
		$eventDateAlt="";
		$verbatimEventDate="";
		}

		




	if($eventDateAlt=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([0-9]{1,2}) ([A-Za-z]+) ([0-9]{4})/){
		$DD=$1;
		$MM=$2;
		$YYYY=$3;
		$MM2 = "";
		$DD2 = "";
	warn "(22)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)-(June?)[- ]$/){ #month, year, no day
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)[- ](Ma[rchy])[- ]$/){ #month, year, no day
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
	elsif ($eventDateAlt=~/^([A-Za-z]+) ([0-9]{4})$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(5)$eventDateAlt\t$id";
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
	warn "(18)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})-([0-9]{1,2})[- ]*$/){
		$MM=$2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
	warn "(19)$eventDateAlt\t$id";
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
#skip this section
#end date collected has a value even with 1 day collection dates, it is always the first day of the next month
#this messes up searches using dates
			#if($enddatecollected =~ m/^([12][0789]\d\d)-(\d+)-(\d+)$/){
			#		$DD2=$3;
			#		$MM2=$2;
			#}
			#else{
			#		$DD2="";
			#		$MM2="";
			#}

#convert to YYYY-MM-DD for eventDate and Julian Dates
$MM = &get_month_number($MM, $id, %month_hash);
$MM2 = &get_month_number($MM2, $id, %month_hash);

#$formatEventDate = "$YYYY-$MM-$DD";
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


#if ((length($recordedBy) > 1) && (length($other_collectors) > 1)){
	#warn "Names 3: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
#}
#elsif ((length($recordedBy) > 1) && (length($other_collectors) == 0)){
	#warn "Names 4: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
#}
#elsif ((length($collector) == 0) && (length($other_collectors) == 0)){
#	$recordedBy =  $other_collectors = $verbatimCollectors = "";
#	&log_change("Collector name NULL\t$id\n");
#}
#else {
#		&log_change("Collector name problem\t$id\n");
#		$recordedBy =  $other_collectors = $verbatimCollectors = "";
#}

#####COLLECTOR NUMBER####

foreach ($recordNumber){
	s/#//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

my $CNUM_suffix="";
($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);





# fix records where something other than USA was entered erroneously for California specimens
	foreach ($country){
		s/usa/USA/;
		s/USa/USA/;
		s/United States of America/USA/;
		s/UNITED STATES/USA/;
		s/United states/USA/;
		s/united states/USA/;
		s/  +/ /;
		s/^ +//;
		s/ +$//;
				
	}



foreach($stateProvince){#for each $county value
	s/california/California/;
	s/CALIFORNIA/California/;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

foreach($tempCounty){#for each $county value
	s/'//g;
	s/NULL/Unknown/i;
	s/\[//g;
	s/\]//g;
	s/\?//g;
	s/none./Unknown/;
	s/County unk./Unknown/;
	s/\//--/g;
	s/needs research/Unknown/ig;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries
}

#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);

#####Fix bad country records

#	if (($country =~ m/Antigua and Barbuda|Argentina|Australia|Anguilla|Belize|Brunei Darussalam|Costa Rica|French Guiana|United Arab Emirates|Mexico|Paraguay|Peru|Honduras|Sierra Leone/ ) && ($stateProvince =~ m/California/) && ($county =~ m/[A-Z].*/)){
#		$country = "USA";#(because there are many where Country is not USA, State = California and County is from California)
#		&log_change("COUNTRY: bad country name entered for specimen (1)\t($country)\t($stateProvince)\t($county)\t$id");
#	}

#	else {
#		&log_skip("COUNTRY: bad geographic names entered for specimen, specimen skipped (2)\t($country)\t($stateProvince)\t($county)\t$id"); 
#		next Record;
#	}



#fix additional problematic counties
	if(($id=~/^(GH367268)$/) && ($tempCounty !~ m/Tuolumne/)){ 
		$tempCounty=~s/^.*$/Tuolumne/;
		&log_change("COUNTY: County/State problem==>Duplicates of Grant 951 from other herbaria (see JEPS11025) are from Straberry Lake, Tuolumne Co., county changed from unknown ($id: $tempCounty, $locality)\n");	
	}


######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}


##############validate county
my $v_county;


foreach($county){#for each $county value
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|Unknown)$/){
		$v_county = &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&log_skip("COUNTY (2): NON-CA COUNTY?\t$_\t--\t$id");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log_change("COUNTY (3): COUNTY $_ ==> $v_county--\t$id");		#call the &log function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}


##########LOCALITY#########



foreach ($municipality){
	s/'$//;
	s/`$//;
	s/^-//;
	s/^;//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;

}
foreach ($locality){
	s/^\?//g;
	s/\[?No *Additional *Data\]?//i;
	s/\[?no *data *available\]?//i;
	s/\[?no loca[il][il]ty data?\]?//i;
	s/\[?no specific locality data\]?//i;
	s/\[?no verbatim data\]?//i;
	s/\[?no verbatim locality data\]?//i;
	s/'$//;
	s/`$//;
	s/^-//;
	s/^;//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;

}

	if((length($locality) > 1) && (length($municipality) == 0) && (length($informationWithheld) == 0)){
		$location = $locality;
	}		
	elsif ((length($locality) > 1) && (length($municipality) >1) && (length($informationWithheld) == 0)){
		$location = "$municipality, $locality";
	}
	elsif ((length($locality) == 0) && (length($municipality) >1) && (length($informationWithheld) == 0)){
		$location = "$municipality";
	}
	elsif ((length($locality) == 0) && (length($municipality) >1) && (length($informationWithheld) >1)){
		$location = "$municipality";
	}
	elsif ((length($locality) == 0) && (length($municipality) == 0) && (length($informationWithheld) == 0)){
		&log_change("Locality NULL, $id\n");		#call the &log function to print this log message into the change log...
	}
	elsif ((length($locality) == 0) && (length($municipality) == 0) && (length($informationWithheld) > 2)){
		$location ="redacted by HUH";
		&log_change("Locality Redacted by HUH\t$id\n");		#call the &log function to print this log message into the change log...
	}
	elsif ((length($locality) >= 1) && (length($municipality) >= 1) && (length($informationWithheld) > 2)){
		$location ="redacted by HUH";
		&log_change("Locality Redacted by HUH\t$id\n");		#call the &log function to print this log message into the change log...
	}
	elsif ((length($locality) >= 1) && (length($municipality) == 0) && (length($informationWithheld) > 2)){
		$location ="redacted by HUH";
		&log_change("Locality Redacted by HUH\t$id\n");		#call the &log function to print this log message into the change log...
	}
	elsif (($locality =~ m/redacted/i) && (length($informationWithheld) == 0)){
		$location ="redacted by HUH";
		$informationWithheld = "label data redacted by HUH";
		&log_change("Locality Redacted by HUH\t$id\n");		#call the &log function to print this log message into the change log...
	}
	else {
		&log_change("Locality problem, missing data, $id\t($locality)\t($municipality)\t$informationWithheld\n");		#call the &log function to print this log message into the change log...
	}

#fix some really problematic location records


###############ELEVATION########
foreach($verbatimElevation){
	s/ [eE]lev.*//;	#remove trailing content that begins with [eE]lev
	s/feet/ft/;	#change feet to ft
	s/\d+ *m\.? \((\d+).*/$1 ft/;
	s/\(\d+\) \((\d+).*/$1 ft/;
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
	s/  +/ /g;		#collapse consecutive whitespace as many times as possible
	s/  +/ /;
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
		$elevation = $verbatimElevation;
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


#process verbatim elevation fields into CCH format
foreach($elevation){
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



#### TRS
foreach ($TRS){
		s/NoTRS//i;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		
}


#######Latitude and Longitude
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


foreach ($verbatimLatitude,$verbatimLongitude){
		s/ø/ /g;
		s/[°¡]//g;
		s/\xc3\xb8/ /g; #decimal byte representation for ø
		s/'/ /g;
		s/"/ /g;
		s/,/ /g;
		s/deg./ /;
		s/^N.?A//i;
		s/  +/ /g;
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
			&log_change("COORDINATE problems for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}



#######Habitat and Assoc species (dwc habitat and associatedTaxa)

#free text fields

foreach ($habitat){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/  +/ /g;
		s/^ +//g;
		
}


#######Notes and phenology fields

#free text fields
my $note_string;


foreach ($informationWithheld, $dataGeneralizations, $identificationReferences){
	s/  +/ /;
	s/^ +//;
	s/ +$//;

}

#format note_string correctly
	if ((length($informationWithheld) > 1) && (length($dataGeneralizations) == 0) && (length($identificationReferences) == 0)){
		$note_string="$informationWithheld";
	}
	elsif ((length($informationWithheld) == 0) && (length($dataGeneralizations) == 0) && (length($identificationReferences) == 0)){
		$note_string="";
	}
	elsif ((length($informationWithheld) > 1) && (length($dataGeneralizations) > 1) && (length($identificationReferences) == 0)){
		$note_string="$informationWithheld| Other Notes: $dataGeneralizations";
	}
	elsif ((length($informationWithheld) == 0) && (length($dataGeneralizations) > 1) && (length($identificationReferences) == 0)){
		$note_string="Other Notes: $dataGeneralizations";
	}
	elsif ((length($informationWithheld) > 1) && (length($dataGeneralizations) > 1) && (length($identificationReferences) > 1)){
		$note_string="$informationWithheld| Other Notes: $dataGeneralizations| Identification References: $identificationReferences";
	}
	elsif ((length($informationWithheld) == 0) && (length($dataGeneralizations) > 1) && (length($identificationReferences) > 1)){
		$note_string="Other Notes: $dataGeneralizations| Identification References: $identificationReferences";
	}
	elsif ((length($informationWithheld) == 0) && (length($dataGeneralizations) == 0) && (length($identificationReferences) > 1)){
		$note_string="Identification References: $identificationReferences";
	}
	elsif ((length($informationWithheld) > 1) && (length($dataGeneralizations) == 0) && (length($identificationReferences) > 1)){
		$note_string="$informationWithheld| Identification References: $identificationReferences";
	}
	else{
		&log_change("NOTES: problem with notes field\t$id\t$informationWithheld| Other Notes: $dataGeneralizations| Identification References: $identificationReferences");
		$note_string="";
	}

foreach ($typeStatus){
		s/Not *a *type//i;
		s/^ +//g;
		s/ +$//g;
		s/  +/ /g;
}

foreach ($reproductiveStatus){
		s/Not *Determined//i;
		s/^ +//g;
		s/ +$//g;
		s/  +/ /g;
}


#########Skeletal Records
	if((length($recordNumber) < 1) && (length($typeStatus) < 2) && (length($informationWithheld) == 0) && (length($municipality) < 2) && (length($locality) < 2) && (length($dataGeneralizations) < 2) && (length($eventDate) == 0) && (length($habitat) < 2) && (length($decimalLatitude) == 0) && (length($decimalLongitude) == 0) && (length($verbatimCoordinates) < 2)){ #exclude skeletal records
			&log_skip("VOUCHER: skeletal records without data in most fields including locality and coordinates\t$id");	#run the &log_skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
	}


++$count_record;
warn "$count_record\n" unless $count_record % 10000;



print OUT <<EOP;

Accession_id: $id
Name: $scientificName
Date: $verbatimEventDate
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
Location: $location
Habitat: $habitat
T/R/Section: $TRS
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Lat_long_ref_source: $georeferenceSource
Datum: $datum
Max_error_distance: 
Max_error_units: 
Elevation: $CCH_elevationInMeters
Verbatim_elevation: 
Verbatim_county: $tempCounty
Phenology: $reproductiveStatus
Notes: $note_string
Hybrid_annotation: $hybrid_annotation
Cultivated: $cultivated
Type_status: $typeStatus
Annotation: $det_string

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

    my $file_out = '/JEPS-master/CCH/Loaders/HUH/HUH_out.txt';	#the file this script will act upon is called 'HUH_out'
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

