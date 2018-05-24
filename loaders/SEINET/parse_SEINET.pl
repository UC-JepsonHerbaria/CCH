
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

####INSERT NAMES OF SEINET FILES and assign variables

my $images_file='/JEPS-master/CCH/Loaders/SEINET/SEINET_Downloads/images.tab';
my $dets_file='/JEPS-master/CCH/Loaders/SEINET/SEINET_Downloads/identifications.tab';
my $records_file='/JEPS-master/CCH/Loaders/SEINET/SEINET_Downloads/occurrences.tab';
my $temp_file='/JEPS-master/CCH/Loaders/SEINET/SEINET_temp.txt'; #file without the large number of unwanted records filtered from step 1

my $included;
my %skipped;
my %temp_skipped;
my $count_record;
my %count_record;
my $line_store;
my $temp_line_store;
my $count;
my $temp_count;
my $seen;
my %seen;
my %IMAGE;
my $IMAGE;
my $imageURL;
my $IMG;
my %IMG;
my $ANNO;
my %ANNO;
my $tempCounty;
my $GUID;
my %GUID;
my $id_non;

open(OUT,">/JEPS-master/CCH/Loaders/SEINET/SEINET_out.txt") || die;
open(OUT3,">/JEPS-master/CCH/Loaders/SEINET/AID_GUID_SEINET.txt") || die; #text file for SEINET accession conversion 
open(TEMP,">/JEPS-master/CCH/Loaders/SEINET/SEINET_temp.txt") || die;
#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";



#process the images
#Note that the file might have Windows line breaks
open (IN, "<", $images_file) or die $!;
while(<IN>){

my $IMG_id;
#unique to this dataset
my $url1;
my @rest;

 	chomp;		#remove trailing new line /n
 			s/  +/ /g;
($IMG_id,$url1,$imageURL,@rest) = split(/\t/);	#split each line into $id and $imageURL 
$IMG{$IMG_id}=$imageURL;	#set $IMAGE for each "SEINET[$id]" to $imageURL
}
close(IN);




#############ANNOTATIONS

###process the determinations
#Note that the file might have Windows line breaks
open (IN, "<", $dets_file) or die $!;
while(<IN>){

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
my $det_string="";
#unique to this dataset
my $IDa;
my $IDg;
my $IDs;
my $IDr;
my $IDi;
my $IDref;
my $det_identificationRemarks;
my $IDrec_ID;
my $null1;

#Field List Oct2016
#coreid	identifiedBy	identifiedByID	dateIdentified	identificationQualifier	scientificName	identificationIsCurrent	scientificNameAuthorship	genus	specificEpithet	taxonRank	infraspecificEpithet	identificationReferences	identificationRemarks	recordId


	chomp;
	
	#fix some data quality and formatting problems that make import of fields of certain records problematic
#see also the &correct_format 'foreach' statement below	for more formatting corrections	
 		s/  +/ /g;


 		
($det_AID,$det_determiner,$null1,$det_date,$det_stet,$det_name,
$det_rank,$IDa,$IDg,$IDs,$IDr,$IDi,$IDref,$det_identificationRemarks,$IDrec_ID
) = split(/\t/);	#split 

	if($det_rank=~m/^0$/){ #change rank numbers to start with 1
		$det_rank = "1";
	}
	elsif($det_rank=~m/^1$/){
		$det_rank = "2";
	}
	else{
		$det_rank = "";
	}


#format det_string correctly
	if ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) >=1)){
		$det_string="$det_rank: $det_name, $det_identificationRemarks";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) >=1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_identificationRemarks";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) == 0) && (length($det_identificationRemarks) == 0)){
		$det_string="$det_rank: $det_name   $det_stet, $det_determiner";
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
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) >=1) && (length($det_identificationRemarks) >=1)){
		$det_string="$det_rank: $det_name   $det_stet, $det_determiner $det_stet, $det_date, $det_identificationRemarks";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0) && (length($det_identificationRemarks) == 0)){
		$det_string="";
	}
	else{
		$det_string="";
	}



$ANNO{"SEINET$det_AID"}.="Annotation: $det_string\n"; #for $ANNO for each "SEINET$id", print the following into and a new line. ".=" Means accumulate entries, if there are multiple ANNOs per SEINET$id
}
close(IN);



###################STEP 1: PROCESS observations.tab file to filter out a large number of unwanted records
print "Skipping unwanted records...\n\n\n";

open (IN, "<", $records_file) or die $!;
Record: while(<IN>){
	chomp;



#SEINET file downloaded as Symbiota Native, with all images and determinations tables, and UTF-8 coding
#DWC had fewer fields, not sure if that means less data or that the data is combined into other fields
#Field List Oct2016

#id
#institutionCode
#collectionCode
#ownerInstitutionCode
#basisOfRecord
#occurrenceID
#catalogNumber
#otherCatalogNumbers
#kingdom
#phylum   10
#class
#order
#family
#scientificName
#scientificNameAuthorship
#genus
#specificEpithet
#taxonRank
#infraspecificEpithet
#identifiedBy    20
#dateIdentified
#identificationReferences
#identificationRemarks
#taxonRemarks
#identificationQualifier
#typeStatus
#recordedBy
#recordedByID
#associatedCollectors
#recordNumber   30
#eventDate
#year
#month
#day
#startDayOfYear
#endDayOfYear
#verbatimEventDate
#occurrenceRemarks
#habitat
#substrate      40
#verbatimAttributes
#fieldNumber
#informationWithheld
#dataGeneralizations
#dynamicProperties
#associatedTaxa
#reproductiveCondition
#establishmentMeans
#cultivationStatus
#lifeStage      50
#sex
#individualCount
#samplingProtocol
#samplingEffort
#preparations
#country
#stateProvince
#county
#municipality
#locality      60
#locationRemarks
#localitySecurity
#localitySecurityReason
#decimalLatitude
#decimalLongitude
#geodeticDatum
#coordinateUncertaintyInMeters
#verbatimCoordinates
#georeferencedBy
#georeferenceProtocol      70
#georeferenceSources
#georeferenceVerificationStatus
#georeferenceRemarks
#minimumElevationInMeters
#maximumElevationInMeters
#minimumDepthInMeters
#maximumDepthInMeters
#verbatimDepth
#verbatimElevation
#disposition     80
#language
#recordEnteredBy
#modified
#sourcePrimaryKey
#collId
#recordId
#references      87

my $GUID;
my $id;
my $country;
my $stateProvince;
my $county;
my $locality; 
my $family;
my $scientificName;
my $genus;
my $species;
my $rank;
my $subtaxon;
my $name;
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
my $hybrid_annotation;
#unique to this dataset
my $institutionCode;
my $collectionCode;
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
my $reproductiveCondition;
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

		my @fields=split(/\t/,$_,100);

        unless( $#fields == 86){  #if the number of values in the columns array is exactly 87

	warn "$#fields bad field number $_\n";

	next Record;
	}


#note that if the fields change. The field headers can be found in the occurrences.tab file
		$temp_line_store=$_;
		++$temp_count;

($id,
$institutionCode,
$collectionCode,
$ownerInstitutionCode,	#added 2016
$basisOfRecord,
$occurrenceID,
$catalogNumber,
$otherCatalogNumbers,
$kingdom,
$phylum,
#10
$class,
$order,
$family,
$scientificName,
$scientificNameAuthorship,
$genus,
$specificEpithet,
$taxonRank,
$infraspecificEpithet,
$identifiedBy,
#20
$dateIdentified,
$identificationReferences,	#added 2015, not processed
$identificationRemarks,	#added 2015, not processed
$taxonRemarks,	#added 2015
$identificationQualifier,
$typeStatus,
$recordedBy,
$recordedByID,			#added 2016, not in 2017 download
$associatedCollectors,	#added 2016, not in 2017 download, combined within recorded by with a ";"
$recordNumber,
#30
$eventDate,
$year,
$month,
$day,
$startDayOfYear,
$endDayOfYear,
$verbatimEventDate,
$occurrenceRemarks,
$habitat,
$substrate,			#added 2016
#40
$verbatimAttributes, #added 2016
$fieldNumber,
$informationWithheld,
$dataGeneralizations,	#added 2015, not processed, field empty as of 2016
$dynamicProperties,	#added 2015, not processed
$associatedTaxa,
$reproductiveCondition,
$establishmentMeans,	#added 2015, not processed
$cultivationStatus,	#added 2016
$lifeStage,
#50
$sex,	#added 2015, not processed
$individualCount,	#added 2015, not processed
$samplingProtocol,	#added 2015, not processed
$samplingEffort,	#added 2015, not processed
$preparations,	#added 2015, not processed
$country,
$stateProvince,
$county,
$municipality,
$locality,
#60
$locationRemarks, #newly added 2015-10, not processed
$localitySecurity,		#added 2016, not processed
$localitySecurityReason,	#added 2016, not processed
$verbatimLatitude,
$verbatimLongitude,
$geodeticDatum,
$coordinateUncertaintyInMeters,
$verbatimCoordinates,
$georeferencedBy,	#added 2015, not processed
$georeferenceProtocol,	#added 2015, not processed
#70
$georeferenceSource,
$georeferenceVerificationStatus,	#added 2015, not processed
$georeferenceRemarks,	#added 2015, not processed
$minimumElevationInMeters,
$maximumElevationInMeters, #not processed for now
$minimumDepthInMeters, #newly added 2015-10, not processed
$maximumDepthInMeters, #newly added 2015-10, not processed
$verbatimDepth, #newly added 2015-10, not processed
$verbatimElevation,
$disposition,	#added 2015, not processed
#80
$language,	#added 2015, not processed
$recordEnteredBy, #newly added 2015-10, not processed
$modified,	#added 2015, not processed
$sourcePrimaryKey,  #added 2016, not processed
#$rights,	#deleted in 2015
#$rightsHolder,	#deleted in 2015
#$accessRights,	#deleted in 2015
$collID,	#added 2016, not processed
$recordId,	#added 2015, not processed
$references	#added 2016, not processed
)=@fields;	#The array @columns is made up on these 87 scalars, in this order



#########################Process records to eliminate specimens not needed in CCH, unique to SEINET downloads

##################Exclude known problematic specimens by id numbers, most from outside California and Baja California
 if ($id =~/^(3239055|12651038|6786882|903063|5542516|5553080|5559939|5560204|5564409|5571451|5578463|5578464|5579706|881193|881194|946792|946795|958356|13936935|13951195|13184339|8482435|3145188|3165281|8551641|2063694|6010380|3143301|6010483|3288631|5999431|6009962|3828429|3128756|891892|947111|6901995|3236890|3349408|5556965|3920225|3920384|7358734|949278|947283|953299|1910899|960031|7887537|901900|950642|885247|2139875|3236890|7880474|7880475|3349409|3156500|955884|5578801|5578802|8111276|901887|10964957|10899737|10612927|523075|2139878|947426|949080|952106|3840903|10450011|7878637|3350112|5574540|2140016|206575|8094686|6919312|10587155|6059833|6053609|6078071|6084883|6038783|6080815|6092926|6077290|6084618|6090271|6067228|6078439|6062798|6061904|6053009|6048333|6081870|3831133|5578807|957986|948347|7987520|3156332|5585640|5585641|3828429|780313|947147|932794|4090498|5556964|10492513|756181|8892781|10476365|2030103|3131301|5554619|3127702|5578808|5547519|5556946|954279|10789840|892491|952443|4557750|4557751|4134703|8071906|7067885|10791260|8099704|10546522|1004641|7293869|3130961|3158166|8100447|10905080|4041567|7096710|7096711|10789688|7880493|7880446|5556963|10484529|8696461|7096697|7096696|7572142|7579661|6900851|5585639|10731649|5519952|10848658|8215883)$/){
	#print ("excluded problem record or record known to be not from California\t$locality\t--\t$id");
		++$temp_skipped{one};
		next Record;
	}
	
	
##################Exclude known problematic from Baja California and other States in Mexico with "California" as state
 if ($id =~/^(10615070|8720137|3132405|1939552|1939555|9372982|3157806|4182802|982039|982186|986591|10570608|10929212|3150102|3269779|904990|10571329|1940962|957093|4962440|5001448|10593214|10572572|10678657|3129513|903956|10932808|8735151|7718784|10796230|3148362|10678725|10743352|10500255|5501463|3132653|1912776|7247972|3145054|10550870|10546591|10531453|10755578|10794450|10794455|10969903|6165250|10870828|178669|4177487|10846560|1939654|10727925|1939566|3132654|6165302|3132655|5501705|5501448|5501418|5501427|6165662|5500734|6165216|1939553|6165097)$/){
	#print  ("Baja California record with California as state\t$id\t--\t$locality");
		++$temp_skipped{one};
		next Record;
	}
	
##################Exclude known problematic localities from other States in Mexico with "California" as state	
 if ($locality =~/(Cedros Island|Cerros Island|Campeche|Tuxpe.*a, Camp\.|Clarion Island|Isla del Carmen|Esc.?rcega|HopelchTn|Cd\. del C.?rmen|Mamantel|Xpujil|Ciudad del Carmen|Tuxpe.?a, Camp\.)/){
	#print  ("Mexico record with California as state\t$id");
		++$temp_skipped{one};
		next Record;
	}	
	
##################Exclude certain institutions,
 if ($institutionCode =~/^(BCMEX|ISTC|CLEMS|NBYC|BRIT|KE|GAS|SCIR|KNFY|GMDRC|SEINet|GEO|UNCA|iNaturalist|Nicotiana - RSA|RHNM|MABA-Plants|GreaterGood|Sonoran Atlas|NCZP|BUT-IPA|NY|SENEY|SWANER|SIM|TAWES|OBI|UCSC|DAV|SDSU|UCR|SCFS|ALA|HUNT|SAU)$/){
	#print  ("excluding records from certain Portal institutions\t$institutionCode");
#GAS,KE,BRIT,CLEMS,ISTC    all have county repeated in location and are skipped
#excluding CA herbaria that are downloaded separately as CCH participants
#NY,GH downloaded in CCH as participants, skipped here

#BCMEX has a rediculously high error rare including labellling all Baja California Records as just the state "California" and mistyping hundreds of coordinates as degrees and minutes when the format on the label was decimal degrees
#eliminating this collection elimiates many yellow flag records, besudes most of the California material are duplicates from Rebman that are already mapped in SD and SDSU

		++$temp_skipped{one};
		next Record;
	}
	
##################Exclude institutionsthat are processed in parse_tab2.pl and parse_tab3.pl
# if ($institutionCode =~/^(ARIZ|ASU|ASC|DES|BRY|OSC|NCSC|MO|ILLS|BDI|F|RENO|HCIB|BCMEX|NMC)$/){
#		++$skipped{one};
#		next Record;
#	}	
	

##################Exclude non-vascular plants
	if($family =~ /(Psoraceae|Bryaceae|Wrangeliaceae|Sargassaceae|Ralfsiaceae|Chordariaceae|Porrelaceae|Mielichhoferiaceae Schimp.|Mielichhoferiaceae|Lessoniaceae|Laminariaceae|Dictyotaceae)/){	#if $family is equal to one of the values in this block
	#print  ("Non-vascular herbarium specimen (1) $_\t$id");	#skip it, printing this error message
		++$temp_skipped{one};
		next Record;
	}
	
	if($class =~ /^(Anthocero|Ascomycota|Bryophyta|Chlorophyta|Rhodophyta|Marchant)/){	#if $class is equal to one of the values in this block
	#print  ("Non-vascular herbarium specimen (2) $_\t$id");	#skip it, printing this error message
		++$temp_skipped{one};
		next Record;
	}
	
# if collection code contains the word "NONVASC", "OSCB" [OSC Bryophyte Herbarium], etc., skip the record
	if($collectionCode=~/(NONVASC|OSCB)/){
	#print  ("Non-vascular herbarium specimen (4) $_\t$id");	#&log_skip is a function that skips a record and writes to the error log
		++$temp_skipped{one};
		next Record;
	}

#####process cultivated specimens			
# flag taxa that are cultivars, add "P" for purple flag to Cultivated field	

## Seinet Cultivated parsing, changing this instance to removing cultivated specimens, dur in part to the extreme number, but also due to the future state of excluding them entirely from CCH
#Future instance will only have cultivated taxa in Symbiota
foreach ($cultivationStatus){
	s/ //g; #eliminate all white space

}


	if ($cultivationStatus !~ m/^(1|P)$/){
		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			#&log_change("CULT: specimen likely not cultivated, purple flagging skipped==>$scientificName\t$id\n");
			$cultivationStatus = "";
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($occurrenceRemarks =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    #$cultivationStatus = "P";
	   		&log_skip("CULT: Cultivated specimen found and purple flagged==>($cultivationStatus)\t($scientificName)\t$id\n");
			++$temp_skipped{one};
			next Record;
		}
		else {		
			if($cult{$scientificName}){
				$cultivationStatus = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_skip("CULT: Documented cultivated taxon, now purple flagged==>($cultivationStatus)\t($scientificName)\t$id\n");	
			++$temp_skipped{one};
			next Record;
			}
			else {
			#&log_change("Taxon skipped purple flagging: $cultivationStatus\t--\t$scientificName\n");
			$cultivationStatus = "";
			}
		}
	}
	else {
		&log_skip("CULT: Taxon flagged as cultivated in original database==>($cultivationStatus)\t($scientificName)\n");
		++$temp_skipped{one};
		next Record;
	}


# flag known problematic cultivated specimens that have been missed in the past, add "P" for purple flag to Cultivated field in case it is still being skipped	
	if(($cultivationStatus !~ m/^(1|P)$/) && ($id =~ m/^(4604252|6328916|10887586|10719982|5581928|863212|893304|768990|10609192|10894381|10948816|10520203|10604471|10604540|4133804|10546740|10546609|892656|892658|10485622|4604252|10532490|10531499|10794454|10612368|10825513|7880454|7880453|1907402|1907440|955757|10717813|956247|10970534|10870705|10745264|5765061|741645|956162)$/)){
		#$cultivationStatus = "P";
		&log_skip("CULT: Cultivated specimen with problematic locality data, now purple flagged==>$cultivationStatus)\t($scientificName)\t$id\n");	
		++$temp_skipped{one};
		next Record;
	}





print TEMP join("\t",
$id,
$institutionCode,
$collectionCode,
$ownerInstitutionCode,	#added 2016
$basisOfRecord,
$occurrenceID,
$catalogNumber,
$otherCatalogNumbers,
$kingdom,
$phylum,
#10
$class,
$order,
$family,
$scientificName,
$scientificNameAuthorship,
$genus,
$specificEpithet,
$taxonRank,
$infraspecificEpithet,
$identifiedBy,
#20
$dateIdentified,
$identificationReferences,	#added 2015, not processed
$identificationRemarks,	#added 2015, not processed
$taxonRemarks,	#added 2015
$identificationQualifier,
$typeStatus,
$recordedBy,
$recordedByID,			#added 2016
$associatedCollectors,	#added 2016
$recordNumber,
#30
$eventDate,
$year,
$month,
$day,
$startDayOfYear,
$endDayOfYear,
$verbatimEventDate,
$occurrenceRemarks,
$habitat,
$substrate,			#added 2016
#40
$verbatimAttributes, #added 2016
$fieldNumber,
$informationWithheld,
$dataGeneralizations,	#added 2015, not processed, field empty as of 2016
$dynamicProperties,	#added 2015, not processed
$associatedTaxa,
$reproductiveCondition,
$establishmentMeans,	#added 2015, not processed
$cultivationStatus,	#added 2016
$lifeStage,
#50
$sex,	#added 2015, not processed
$individualCount,	#added 2015, not processed
$samplingProtocol,	#added 2015, not processed
$samplingEffort,	#added 2015, not processed
$preparations,	#added 2015, not processed
$country,
$stateProvince,
$county,
$municipality,
$locality,
#60
$locationRemarks, #newly added 2015-10, not processed
$localitySecurity,		#added 2016, not processed
$localitySecurityReason,	#added 2016, not processed
$verbatimLatitude,
$verbatimLongitude,
$geodeticDatum,
$coordinateUncertaintyInMeters,
$verbatimCoordinates,
$georeferencedBy,	#added 2015, not processed
$georeferenceProtocol,	#added 2015, not processed
#70
$georeferenceSource,
$georeferenceVerificationStatus,	#added 2015, not processed
$georeferenceRemarks,	#added 2015, not processed
$minimumElevationInMeters,
$maximumElevationInMeters, #not processed for now
$minimumDepthInMeters, #newly added 2015-10, not processed
$maximumDepthInMeters, #newly added 2015-10, not processed
$verbatimDepth, #newly added 2015-10, not processed
$verbatimElevation,
$disposition,	#added 2015, not processed
#80
$language,	#added 2015, not processed
$recordEnteredBy, #newly added 2015-10, not processed
$modified,	#added 2015, not processed
$sourcePrimaryKey,  #added 2016, not processed
$collID,	#added 2016, not processed
$recordId,	#added 2015, not processed
$references	#added 2016, not processed
), "\n";
}

print <<EOP;
Records Processed: $temp_count
Records skipped:   $temp_skipped{one}

EOP

close(IN);
close(TEMP);




###################STEP 2: PROCESS Filtered records with normal script from temp file
print "Processing Main Tables...\n\n\n";

open (IN, "<", $temp_file) or die $!;
Record: while(<IN>){
	chomp;

#fix some character formatting problems
	s/Haplo?½sthes/Haploesthes/g;
	s/ndr/ndre/g;
	s/abb/abbe/g;
	s/ion/ion/g;
	s/a/an/g;
	s/o/on/g;
	s/ñ/n/g;
	s/ //g;
	s/Ø//g;
	s/§//g;
	s/î//g;
	s/æ//g;
	s/¦//g;
	s/¢//g;
	s/¡//g;
	s/¬//g;
	s/Â//g;
	s/Æ//g;
	s///g;
	s/•//g;
	s/…//g;
	s/﻿//g;
	s/167�/167/;
	s/â\?/ ?/g;
	s/°°//g;
	s/º/ deg. /g;
	s/°/ deg. /g;
	s/Á/ deg. /g;
	s/Ã/ deg. /g;
	s/©//g;
	s/â/'/g;
	s/×/ X /g;
	s/˚/ deg. /g;
	s/¼/1\/4/g;
	s/¾/3\/4/g;
	s/½/1\/2/g;
	s/±/+-/g;
	s/»/>/g;
	s/«=/<=/g;
	s/”/'/g;
	s/“/'/g;
	s/’/'/g;
	s/‘/'/g;
	s/´/'/g;
	s/Í/'/g;
	s/Ò/'/g;
	s/Ó/'/g;
	s/Ô/'/g;
	s/Õ/'/g;
	s/—/-/g;
	s/Ð/-/g;
	s/ø//g;
	s/ö/o/g;
	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ä/a/g;
	s/á/a/g;
	s/ao>/'/g;	
	s/aoÖ/'/g;	
	s/ú/u/g;
	s/í/i/g;
	s/aoì([A-Za-z]+)ao/'$1'/g;	
	s/aoì/'/g;		
		
#fix some more text and formatting problems
s/redacted/redacted by SEINET/g;		#substitute "redacted" with "redacted by SEINet" so users dont think CCH deleted the information in locality and coordinate fields for some rare taxa
s/(â?¦)/ /g; #substitute weird formatting code "â?¦" with ""
s/"+/"/g;
s/&apos;/'/g;
s/[nN]\/[aA]//g;
#s/\|/, /g;
s/\<p/Mo/g;
s/\( A Opentia\) roots one locality.//g;
s/" ty/ ty/g;	#substitute problem "" in records so that it does not impact the import process
s/" in/ in/g;
s/and "/and /g;
s/"Ac\./AC./g;
s/" ty/ ty/g;
s/" in/ in/g;
s/and "/and /g;
s/NNNNN+//g; #fix a record where clearly someone was a bit heavy on the keys
s/"White Plains"/'White Plains'/g;
s/"wash"/'wash'/g;
s/"Wild Oats"/'Wild Oats'/g;
s/"Wild Plum"/'Wild Plum'/g;
s/"Blue-eyed grass"/'Blue-eyed grass'/g;
s/"Wild Parsnip"/'Wild Parsnip'/g;
s/"Old Man's Whiskers"/'Old Man's Whiskers'/g;
s/"Yellow mock aster"/'yellow mock aster'/g;
s/"Buffalo Grass; Short-hair grass"/'Buffalo Grass'; 'Short-hair grass'/g;
s/"Indian onion or Onion Lily"/'Indian onion' or 'Onion Lily'/g;
s/'bioblitz"/'bioblitz'/g;
s/"Summit"/'Summit'/g;
s/"Huckleberry Trail"/'Huckleberry Trail'/g; 
s/"SSheep Corral"/'Sheep Corral'/g;
s/"individuals"/'individuals'/g;
s/"The Potrero"/'The Potrero'/g;
s/"Kathyrn"//g;
s/5" Q/5 min Q/g;
s/6'11", X/6'11" X/g;
s/"\(probably = A\. uva ursi X A\. columbiana, as it occurs only where they are found together\.\)"/probably = A. uva ursi X A. columbiana, as it occurs only where they are found together./g;
s/"Chiricahua Mtns\. Coronado Natl\. Forest\- El Coronado Ranch"/Chiricahua Mountains, Coronado National Forest, El Coronado Ranch/g;
s/"cotton"/'cotton'/g;
s/"Fir Canyon"/'Fir Canyon'/g;
s/"A"/'A'/g;
s/"B"/'B'/g;
s/"C"/'C'/g;
s/"D"/'D'/g;
s/"E"/'E'/g;
s/"G"/'G'/g;
s/"Liana, fruto color naranja 2 cm de diametro\."/Liana, fruto color naranja 2 cm de diametro./g;
s/"no name"/'no name'/g;
s/"Sunset Cove"/'Sunset Cove'/g;
s/"D St\. Fill"/'D St. Fill'/g;
s/"desert pavement\."/'desert pavement'/g;
s/"Weak leaf"/'Weak leaf'/g;
s/"4-pond Valley"/'4-pond Valley'/g;
s/"Brazilian Plume", "Plume Flower"/'Brazilian Plume', 'Plume Flower'/g;
s/"wedding mesa"/'wedding mesa'/g;
s/"Hog Wallow"/'Hog Wallow'/g;
s/"Mrs\. Vivian Doney, Vista California 3 December 1971"/Mrs. Vivian Doney, Vista California 3 December 1971/g;
s/"Johnson's Cactus Garden, Paramount, California, 22 November 1965"/Johnson's Cactus Garden, Paramount, California, 22 November 1965/g;
s/"Mineral Spring"/'Mineral Spring'/g;
s/"bioblitz"/'bioblitz'/g;
s/"Greene"/'Greene'/g;
s/"Race Track"/'Race Track'/g;
s/"Female shrub\, with male flowers olny acc\. - Herbart L\. Mason\, Bot\. 112\."/Female shrub, with male flowers only acc. - Herbert L. Mason, Bot. 112./g;
s/"Sea Fig"/'Sea Fig'/g;
s/""Dwarf Lupine""/'Dwarf Lupine'/g;
s/"roadise"/'roadise'/g;
s/"Round-leaved Moort"/'Round-leaved Moort'/g;
s/"troyer citrange"/'troyer citrange'/g;
s/"The Ranch"/'The Ranch'/g;
s/"banner"/'banner'/g;
s/"block"/'block'/g;
s/"Sonoran Desert Wildflower"/'Sonoran Desert Wildflower'/g;
s/"skunky\."/'skunky'./g;
s/"Forest Home"/'Forest Home'/g;
s/"West Canyon, western edge of the Colorado Desert\."/West Canyon, western edge of the Colorado Desert./g;
s/"Little Volcano"/'Little Volcano'/g;
s/"Salix franciscana Seemen lectotype female shoot\."/Salix franciscana Seemen lectotype female shoot./g;
s/"St Johnswort"/'St Johnswort'/g;
s/"Mouse-ear Chickweed"/'Mouse-ear Chickweed'/g;
s/"White sweet"/'White sweet'/g;
s/"sunken area"/'sunken area'/g;
s/"very young"/'very young'/g;
s/"Lake Prairie"/'Lake Prairie'/g;
s/"Silk Tassle"/'Silk Tassle'/g;
s/"badlands"/'badlands'/g;
s/11"\-18"/11-18"/g;

#declare field name variables
my $id;
my $country;
my $stateProvince;
my $county;
my $locality; 
my $family;
my $scientificName;
my $genus;
my $species;
my $rank;
my $subtaxon;
my $name;
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
my $hybrid_annotation;
#unique to this dataset
my $institutionCode;
my $collectionCode;
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
my $reproductiveCondition;
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



		$line_store=$_;
		++$count;		
		

        if ($. == 1){#activate if need to skip header lines
			next;
		}

		my @fields=split(/\t/,$_,100);

        unless( $#fields == 86){  #if the number of values in the columns array is exactly 87

	&log_skip ("$#fields bad field number $_\n");
	++$skipped{one};
	next Record;
	}

#then process the full records
#note that if the fields change. The field headers can be found in the occurrences.tab file
($id,
$institutionCode,
$collectionCode,
$ownerInstitutionCode,	#added 2016
$basisOfRecord,
$occurrenceID,
$catalogNumber,
$otherCatalogNumbers,
$kingdom,
$phylum,
#10
$class,
$order,
$family,
$name,
$scientificNameAuthorship,
$genus,
$specificEpithet,
$taxonRank,
$infraspecificEpithet,
$identifiedBy,
#20
$dateIdentified,
$identificationReferences,	#added 2015, not processed
$identificationRemarks,	#added 2015, not processed
$taxonRemarks,	#added 2015
$identificationQualifier,
$typeStatus,
$collector,
$recordedByID,			#added 2016
$associatedCollectors,	#added 2016
$recordNumber,
#30
$eventDate,
$year,
$month,
$day,
$startDayOfYear,
$endDayOfYear,
$verbatimEventDate,
$occurrenceRemarks,
$habitat,
$substrate,			#added 2016
#40
$verbatimAttributes, #added 2016
$fieldNumber,
$informationWithheld,
$dataGeneralizations,	#added 2015, not processed, field empty as of 2016
$dynamicProperties,	#added 2015, not processed
$associatedTaxa,
$reproductiveCondition,
$establishmentMeans,	#added 2015, not processed
$cultivationStatus,	#added 2016
$lifeStage,
#50
$sex,	#added 2015, not processed
$individualCount,	#added 2015, not processed
$samplingProtocol,	#added 2015, not processed
$samplingEffort,	#added 2015, not processed
$preparations,	#added 2015, not processed
$country,
$stateProvince,
$tempCounty,
$municipality,
$locality,
#60
$locationRemarks, #newly added 2015-10, not processed
$localitySecurity,		#added 2016, not processed
$localitySecurityReason,	#added 2016, not processed
$verbatimLatitude,
$verbatimLongitude,
$geodeticDatum,
$coordinateUncertaintyInMeters,
$verbatimCoordinates,
$georeferencedBy,	#added 2015, not processed
$georeferenceProtocol,	#added 2015, not processed
#70
$georeferenceSource,
$georeferenceVerificationStatus,	#added 2015, not processed
$georeferenceRemarks,	#added 2015, not processed
$minimumElevationInMeters,
$maximumElevationInMeters, #not processed for now
$minimumDepthInMeters, #newly added 2015-10, not processed
$maximumDepthInMeters, #newly added 2015-10, not processed
$verbatimDepth, #newly added 2015-10, not processed
$verbatimElevation,
$disposition,	#added 2015, not processed
#80
$language,	#added 2015, not processed
$recordEnteredBy, #newly added 2015-10, not processed
$modified,	#added 2015, not processed
$sourcePrimaryKey,  #added 2016, not processed
#$rights,	#deleted in 2015
#$rightsHolder,	#deleted in 2015
#$accessRights,	#deleted in 2015
$collID,	#added 2016, not processed
$recordId,	#added 2015, not processed
$references	#added 2016, not processed
)=@fields;	#The array @columns is made up on these 87 scalars, in this order



##################Exclude non-vascular plants
	if($scientificName =~ /^(Gemmabryum |Nogopterium |Rosulabryum |Dichelyma |Aulacomnium |Antitrichia |Alsia )/){	#if genus is equal to one of the values in this block
		&log_skip("TAXON: Non-vascular herbarium specimen (3) $_\t$id");	#skip it, printing this error message
		++$skipped{one};
		next Record;
	}	
##################Exclude problematic specimens with certain locality issues
# if locality or habitat contain the word "cultivated" etc., skip the record
	if($locality=~/^(TBD|PHOTO|Unknown$|Unspecified\.)/){
		&log_skip("LOCATION: Specimen with problematic locality that is unresolvable $_\t$id");	#&log_skip is a function that skips a record and writes to the error log
		++$skipped{one};
		next Record;
	}

##################Exclude non-herbarium specimens
# if collection code contains the word "pollen" or "seeds" or etc., skip the record
	if($collectionCode=~/(Pollen|Seeds)/){
				&log_skip("VOUCHER: Record not a herbarium specimen $_\t$id");	#&log_skip is a function that skips a record and writes to the error log
				++$skipped{one};
				next Record;
	}


###########informationWithheld
foreach ($informationWithheld){
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
}	


	if($informationWithheld=~m/field values redacted/i){ #if there is text in informationWithheld (case insensitive), use the string
	 &log_change("VOUCHER: specimen redacted by SEINET\t$id");
	 }
	 else{
	 $informationWithheld = "";
	 }


#########Skeletal Records
	if((length($informationWithheld) == 0) && (length($municipality) < 2) && (length($locality) < 2) && (length($occurrenceRemarks) < 2) && (length($eventDate) == 0) && (length($habitat) < 2) && (length($decimalLatitude) == 0) && (length($decimalLongitude) == 0) && (length($verbatimCoordinates) < 2)){ #exclude skeletal records
			&log_skip("VOUCHER: skeletal records without data in most fields including locality and coordinates\t$id");	#run the &log_skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
	}

#########Skip certain collections until Locality data is entered, mostly Skeletal Records that may have images
	if($institutionCode !~ m/^(F|PH|MO)$/){# do not exclude Field Museum, Philadelphia, or Missouri specimens because these are mostly very old types that do not have locality information
		if((length($informationWithheld) < 2) && (length($locality) < 2) && (length($verbatimCoordinates) == 0) && (length($decimalLatitude) == 0) && (length($decimalLongitude) == 0)){ #exclude skeletal records
				&log_skip("VOUCHER: skeletal records from $institutionCode are without data in most fields including locality and coordinates\t$id");	#run the &log_skip function, printing the following message to the error log
				++$skipped{one};
				next Record;
		}
	}


###############Fix records from UCSH (University of South Carolina Herbarium where all localities are "UNK" or some other non-locality text and locality data erroneously entered into Habitat field
	if(($institutionCode=~/^USCH$/) && ($locality=~m/^UNK$/)){ #fix some really problematic county records
		$locality=$habitat;
		$habitat=~s/^.*$//;
		&log_change("LOCATION: USCH location problem modified: $id\t($county)\t($locality)\t($habitat)\n");	
	}



################ACCESSION_ID#############
#check for nulls

unless($id=~/^\d+/){
	&log_skip("No SEINET ID number, skipped: $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space
#skip

#Add prefix 
$id_non="SEINET$id";



#Remove duplicates
if($seen{$id}++){
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate ID number, skipped:\t$id");
	++$skipped{one};
	next Record;
}

#There are some errors in the GUID fields downloaded from SEINet.  These need to be unique and are causing the IPT to fail.
#The following code deletes the erroneous occurrence ID from the AID table.
#these records will then have the default URL guid
	if(($id_non =~ m/^SEINET2449266$/) && ($occurrenceID =~ m/^BRY:V:0136336$/)){ 
		$occurrenceID = "";
		&log_change("GUID: duplicate found and made NULL\t$id\n");	
	}
	if(($id_non =~ m/^SEINET2449582$/) && ($occurrenceID =~ m/^BRY:V:0136338$/)){ 
		$occurrenceID = "";
		&log_change("GUID: duplicate found and made NULL\t$id\n");	
	}


#processes remaining unique GUID's, do not print records without GUID'S or with GUID's of a single character

if (length ($occurrenceID) > 1){
	$GUID{'$id_non'}=$occurrenceID;

	print OUT3 "$id_non\t".$GUID{'$id_non'}."\n";
}
##########Begin validation of scientific names

#####Annotations  (use to show verbatim scientific name (annotation 0) when a separate annotation file is present)
	#format det_string correctly
my $det_orig_rank = "current determination (uncorrected)";  #set to zero for original determination
my $det_orig_name = $name;

	
	if ((length($det_orig_name) >=1) && (length($taxonRemarks) == 0) && (length($identificationRemarks) == 0)){
		$det_orig="$det_orig_rank: $det_orig_name";
	}
	elsif ((length($det_orig_name) >=1) && (length($taxonRemarks) >=1) && (length($identificationRemarks) == 0)){
		$det_orig="$det_orig_rank: $det_orig_name; $taxonRemarks";
	}
	elsif ((length($det_orig_name) >=1) && (length($taxonRemarks) >=1) && (length($identificationRemarks) >=1)){
		$det_orig="$det_orig_rank: $det_orig_name; $taxonRemarks; $identificationRemarks";
	}
	elsif ((length($det_orig_name) >=1) && (length($taxonRemarks) == 0) && (length($identificationRemarks) >=1)){
		$det_orig="$det_orig_rank: $det_orig_name; $identificationRemarks";
	}
	elsif ((length($det_orig_name) == 0) && (length($taxonRemarks) == 0) && (length($identificationRemarks) == 0)){
		$det_orig="";
	}
	else{
		&log_change("ANNOT: det string problem:\t$det_orig_rank: $det_orig_name, $taxonRemarks, $identificationRemarks\n");
		$det_orig="";
	}



###########NAME


my $verbatimScientificName = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;


#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($name,$verbatimScientificName){
	s/ sp\.//g;
	s/ sp+$//g;
	s/^Plantae/ /;
	s/Plantae$/ /;
	s/unknown/ /i; #added to try to remove the word "unknown" for some records
	s/ hybrid ?$/ /i;
	s/;$//g;
	s/ cf.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/[×] /X /;	#change  " x " in genus name to the multiplication sign
s/unidentified/ /i;
	s/No name/ /i;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;

	
	}
		
unless($name){ #if there's no scientificName, use the verbatimScientificName
	if($verbatimScientificName){
		$name = $verbatimScientificName;
	}
	else{
		&log_skip("TAXON: Taxon problem, name NULL==>($name)\t($verbatimScientificName)\t$id");
		++$skipped{one};
		next Record;
		#$name = "";
	}
}


#format hybrid names
if($name=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
	$hybrid_annotation=$name;
	warn "Hybrid Taxon: $1 removed from $name\n";
	&log_change("TAXON: Hybrid Taxon $1 removed from $name");
	$name=$1;
}
else{
	$hybrid_annotation="";
}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published
	if($name=~/Medicago polycarpa/){ #fix some really specimen records
		$name=~s/^Medicago polycarpa/Medicago polymorpha/;
		&log_change("TAXON: Scientific Name 'Medicago polycarpa' likely an error, this is an old synonym, corrected to  $name\t$id\n");	
	}

	if(($id=~/^4855229$/) && (length($TID{$name}) == 0)){  #fix some really problematic type specimen records
			$name = "Delphinium parishii";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4855083$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Claytonia chenopodina";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4854784$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Navarretia pauciflora";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4854670$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Glyceria californica";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4854370$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Mimulus nasutus var. insignis";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4854361$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Mimulus guttatus var. insignis";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4853966$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Mentzelia oreophila";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4853970$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Mentzelia reflexa";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4853780$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Trifolium anodon";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4853784$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Trifolium decodon";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4853751$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Phaca davidsonii";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^(4853159|4853158|4853156)$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Minuartia stolonifera";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4853055$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Vesicaria occidentalis";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4855347$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Crataegus gaylussacia";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4853504$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Cystium tehatchapiense";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}
	if(($id=~/^4853612$/) && (length($TID{$name}) == 0)){ #fix some really problematic type specimen records
		$name="Lupinus crassulus";
		&log_change("TAXON: Scientific Name empty fields corrected to $name\t$id\n");	
	}	
	if(($id=~/^13095152$/) && ($name=~/Keck\. For Lagophylla minor/i)){ #fix some really problematic type specimen records
		$name=~s/^.+$/Lagophylla minor/;
		&log_change("TAXON: Scientific Name fields with erroenous data corrected to $name\t$id\n");	
	}	
	if(($id=~/^13095723$/) && ($name=~/Greene subsp\. <i>anil/i)){ #fix some really problematic type specimen records
		$name=~s/^.+$/Triteleia ixioides subsp. anilina/;
		&log_change("TAXON: Scientific Name fields with erroenous data corrected to  $name\t$id\n");	
	}
	if(($id=~/^13095423$/) && ($name=~/^Pilg/i)){ #fix some really problematic type specimen records
		$name=~s/^.+$/Plantago subnuda/;
		&log_change("TAXON: Scientific Name fields with erroenous data corrected to  $name\t$id\n");	
	}
	if(($id=~/^13095385$/) && ($name=~/^Jeps/i)){ #fix some really problematic type specimen records
		$name=~s/^.+$/Phacelia corymbosa/;
		&log_change("TAXON: Scientific Name fields with erroenous data corrected to  $name\t$id\n");	
	}
	if(($id=~/^13095392$/) && ($name=~/Heller/i)){ #fix some really problematic type specimen records
		$name=~s/^.+$/Phaeostoma mildredae/;
		&log_change("TAXON: Scientific Name fields with erroenous data corrected to  $name\t$id\n");	
	}
	if(($id=~/^13095743$/) && ($name=~/Mastrog/i)){ #fix some really problematic type specimen records
		$name=~s/^.+$/Carex tiogana/;
		&log_change("TAXON: Scientific Name fields with erroenous data corrected to  $name\t$id\n");	
	}
	if(($id=~/^13094839$/) && ($name=~/Eastw/i)){ #fix some really problematic type specimen records
		$name=~s/^.+$/Delphinium californicum var. interius/;
		&log_change("TAXON: Scientific Name fields with erroenous data corrected to  $name\t$id\n");	
	}
	if(($id=~/^13094843$/) && ($name=~/Greene/i)){ #fix some really problematic type specimen records
		$name=~s/^.+$/Delphinium gracilentum/;
		&log_change("TAXON: Scientific Name fields with erroenous data corrected to  $name\t$id\n");	
	}




#####process taxon names

$scientificName=&strip_name($name);

$scientificName=&validate_scientific_name($scientificName, $id);

#####double check for cultivated specimens
		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("CULT: specimen likely not cultivated, purple flagging skipped==>$scientificName\n");
			$cultivationStatus = "";
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($occurrenceRemarks =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    #$cultivationStatus = "P";
	   		&log_skip("CULT: Cultivated specimen found and purple flagged==>($cultivationStatus)\t($scientificName)\t$id\n");
			++$temp_skipped{one};
			next Record;
		}
		else {		
			if($cult{$scientificName}){
				$cultivationStatus = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_skip("CULT: Documented cultivated taxon, now purple flagged==>($cultivationStatus)\t($scientificName)\t$id\n");	
				++$skipped{one};
				next Record;
			}
			else {
			&log_change("Taxon skipped purple flagging: $cultivationStatus\t--\t$scientificName\n");
			$cultivationStatus = "";
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
my $eventDateAlt;
my $eventDate_parse;
my $month_rev;

foreach ($eventDate){
	s/0000//g;
	s/-00-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-00$/-/g;	#julian date processor cannot handle 00 as filler for missing values
	s/,/ /g;
	s/\./ /g;
		s/\/\/N//g;
	s/^ *//g;
	s/ *$//g;
	s/  +//g;
	}
	
foreach ($verbatimEventDate){
	s/0000//g;
	s/,/ /g;
	s/\./ /g;
		s/\/\/N//g;
	s/  +//g;
	s/^ +//g;
	s/ +$//g;

	}

foreach ($year){
	s/ //g;
		s/\/\/N//g;
}
foreach ($day){
	s/^0$//g;
		s/\/\/N//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;

}
foreach ($month){
	s/^0$//g;
		s/\/\/N//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}	

#combine dates for values that are in the split date fields, and to a 3rd date field
	if((length($year) > 1) && (length($day) >= 1) && (length($month_rev) >= 1)){
		$eventDate_parse = $year ."-" . $month_rev . "-". $day;
		}
	elsif((length($year) > 1) && (length($day) == 0) && (length($month_rev) >= 1)){
		$eventDate_parse = $year ."-" . $month_rev;
		}
	elsif((length($year) > 1) && (length($day) == 0) && (length($month_rev) == 0)){
		$eventDate_parse = $year;
		}
	elsif((length($year) > 1) && (length($day) >= 1) && (length($month_rev) == 0)){
		$eventDate_parse = $year;
		}
	elsif((length($year)== 0) && (length($day) == 0) && (length($month_rev) == 0)){
		$eventDate_parse = "";
		&log_change("Date: YYYY-MM-DD fields NULL\t$id\n");
		}
	else{
		&log_change("Date: YYYY-MM-DD fields missing values, cannot process: Y($year)-M($month)-D($day)\t$id\n");
		$eventDate_parse = "";
	}

foreach ($eventDate_parse){
	s/0000//g;
	s/-00-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-00$/-/g;
	s/-0-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-0$/-/g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;

}	


#find what fields have a date value, choose one and add to $eventDateAlt
	if((length($eventDate) > 1) && (length($verbatimEventDate) > 1) && (length($eventDate_parse) > 1)){
		$eventDateAlt = $eventDate_parse;
		&log_change("Date (1): eventDate selected for\t$id\n");
		}
	elsif((length($eventDate) > 1) && (length($verbatimEventDate) == 0) && (length($eventDate_parse) == 0)){
		$eventDateAlt = $eventDate;
		&log_change("Date (2): eventDate selected for\t$id\n");
		}
	elsif((length($eventDate) == 0) && (length($verbatimEventDate) > 1) && (length($eventDate_parse) == 0)){
		$eventDateAlt = $verbatimEventDate;
		&log_change("Date (3): alternate fields empty, verbatimEventDate selected for\t$id\n");
		}
	elsif((length($eventDate) == 0) && (length($verbatimEventDate) == 0) && (length($eventDate_parse) > 1)){
		$eventDateAlt = $eventDate_parse;
		&log_change("Date (4): alternate fields empty, eventDate_parse selected for\t$id\n");
		}
	elsif((length($eventDate) > 1) && (length($verbatimEventDate) == 0) && (length($eventDate_parse) > 1)){
		$eventDateAlt = $eventDate;
		&log_change("Date (5): verbatimEventDate empty, eventDate selected for\t$id\n");
		}
	elsif((length($eventDate) > 1) && (length($verbatimEventDate) >= 1) && (length($eventDate_parse) == 0)){
		$eventDateAlt = $eventDate;
		&log_change("Date (6): eventDate selected for\t$id\n");
		}
	elsif((length($eventDate) == 0) && (length($verbatimEventDate) == 0) && (length($eventDate_parse) == 0)){
		$eventDateAlt = "";
		&log_change("Date NULL: all date fields without data\t$id\n");
		}
	else{
		&log_change("Date problem, cannot process: ($eventDate)\t($verbatimEventDate)\t($eventDate_parse)\t$id\n");
		$eventDateAlt="";
	}

#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#$coll_month, #three letter month name: Jan, Feb, Mar etc.
#$coll_day,
#$coll_year,
#verbatim date for dwc verbatimEventDate and CCH "Date"
	foreach ($eventDateAlt){
	s/ and /-/g;
	s/\//-/g;
	s/-+/-/g;
	s/&/-/g;
	s/ ?- ?/-/g;
	s/^ +//g;
	s/ +$//g;
	s/  +/ /g;
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
	#warn "(5)$eventDateAlt\t$id";
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

	if(($id=~/^3837360$/) && ($collector=~/10/)){ #fix some really problematic collector records
		$collector=~s/10/J.P. Tracy/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
	
	if(($id=~/^3837354$/) && ($collector=~/200/)){ #fix some really problematic collector records
		$collector=~s/200/P.A. Munz/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
	
	if(($id=~/^891651$/) && ($collector=~/Lower Rochester/)){ #fix some really problematic collector records
		$collector=~s/Lower Rochester/Percy Train/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
	
	if(($id=~/^5628320$/) && ($collector=~/^Fry Canal/)){ #fix some really problematic collector records
		$collector=~s/Fry Canal/C.W. Fallass/;
		$locality=~s/From 8th Calif Fry/Fry Canal/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
	
	if(($id=~/^9655845$/) && ($collector=~/L\. Scattered/)){ #fix some really problematic collector records
		$collector=~s/L\. Scattered/Marla Daily/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
	
	if(($id=~/^9655840$/) && ($collector=~/Santa Cruz/)){ #fix some really problematic collector records
		$collector=~s/Santa Cruz/Marla Daily/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
		
	if(($id=~/^9655856$/) && ($collector=~/Santa Cruz/)){ #fix some really problematic collector records
		$collector=~s/Santa Cruz/Marla Daily/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}		
	
	if(($id=~/^8753990$/) && ($collector=~/9356/)){ #fix some really problematic collector records
		$collector=~s/9356/Richard R. Halse/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}

	if(($id=~/^2444728$/) && ($associatedCollectors=~/^Steven A\. Junak; Tina J\. Ayers/)){ #fix some really problematic collector records
		$collector=~s//Steven A. Junak/;
		$associatedCollectors=~s/Steven A\. Junak; Tina J\. Ayers/Tina J. Ayers/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
	
	if(($id=~/^1906967$/) && ($collector=~/Shrub\./)){ #fix some really problematic collector records
		$collector=~s/Shrub\./Naomi Fraga/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
	if(($id=~/^3404050$/) && ($collector=~/UTC00094980/)){ #fix some really problematic collector records
		$collector=~s/UTC00094980/Peter H. Raven/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
	
	if(($id=~/^3243471$/) && ($collector=~/West Parcel/)){ #fix some really problematic collector records
		$collector=~s/West Parcel/Virginia Moran/;
		&log_change("Collector problem modified: $collector\t$id\n");
	}
		
	if(($id=~/^192712$/) && ($collector=~/Wolf 10/)){ #fix some really problematic collector records
		$collector =~ s/^Wolf 10/Carl B. Wolf/;
		$recordNumber =~ s/^.*$/10/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}

	if(($id=~/^6194880$/) && ($collector=~/^Residio/)){ #fix some really problematic collector records
		$collector=~s/^Residio//;
		$locality=~s/\s?/Presidio/;
		&log_change("Collector problem modified: $collector\t$id\n");
	}	

	if(($id=~/^514961$/) && ($collector=~/W\. Roderick\/ R\.L\. Prothro 71\.0599$/)){ #fix some really problematic collector records
		$collector=~s/W\. Roderick\/ R\.L\. Prothro 71\.0599$/W. Roderick/;
		$associatedCollectors = "R.L. Prothro";
		$recordNumber =~ s/^$/71.0599/;
		&log_change("Collector problem modified: $collector\t$id\n");	
	}		
		
	if(($id=~/^9655826$/) && ($collector=~/Valley Anchorage/) && ($associatedCollectors=~/Santa Cruz; Marla Daily/)){ #fix some really problematic collector records
		$collector=~s/Valley Anchorage$/Marla Daily/;
		$associatedCollectors = "";
		&log_change("Collector problem modified: $collector\t$id\n");	
	}
	
	if(($id=~/^6090529$/) && ($collector=~/Thornes', K,etal/) && (length($associatedCollectors) == 0)){ #fix some really problematic collector records
		$collector=~s/Thornes', K,etal$/K. Thorne/;
		$associatedCollectors = "et al";
		&log_change("Collector problem modified: $collector\t$id\n");	
	}	
	if(($id=~/^477540$/) && ($collector=~/J\.T\. Rothrock 211\/522/)){ #fix some really problematic collector records
		$collector=~s/J\.T\. Rothrock 211\/522/J.T. Rothrock/;
		$recordNumber=~s/^$/211-522/;
		&log_change("Collector and number problem, modified: $collector\t$recordNumber\t$id\n");	
	}	
	if(($id=~/^477540$/) && ($collector=~/.Cummings. Fr. Callum./)){ #fix some really problematic collector records
		$collector=~s/.Cummings. Fr. Callum./Cummings; McCallum/;

		&log_change("Collector and number problem, modified: $collector\t$recordNumber\t$id\n");	
	}



foreach($collector){	#fix some really problematic formats for collector names
	s/'$//g;
	s/"//g;
	s/\./. /g;
	s/ \././g;
	s/ *\[/ /g;
	s/\] */ /g;
	s/[()]]+/ /g;
	s/\?//g;
	s/^\*//g;
	s/\*$//g;
	s/,\*$//g;
	s/, \* ?//g;
	s/,+ */, /g;
	s/ ; */, /g;
	s/ ; */, /g;
	s/ *-+ */, /g;
	s/, with/ with/;
	s/EK, Lenz/EK; Lenz/;
	s/JL, Smith/JL; Smith/;
	s/Welshs', SL, SL/S. L. Welsh; S. L. Welsh/;
	s/Andr deg.*([A-Z])/Andre, $1/g;
	s/ w\/ ?/ with /g;
	s/, M\. ?D\.//g;
	s/, A\. ?M\.//g;
	s/, Jr\./ Jr./g;
	s/, Jr/ Jr./g;
	s/, Esq./ Esq./g;
	s/, Sr\./ Sr./g;
	s/, (I+)/ $1/g;
	s/^'//g;
	s/, & /, /g;
	s/ , */, /g;
	s/ \+ */, /g;
	s/ -+ */, /g;
	s/\.+ */. /g;
	s/ *\| */; /g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
	
}

	if ((length($collector) > 1) && (length($associatedCollectors) == 0)){
		if ($collector =~ m/^([A-Za-z]{2,}), ([A-Z][. ]{1,2}[A-Z][. ]{1,2})$/){
			$recordedby = "$2 $1";
			$recordedBy = &CCH::validate_single_collector($recordedby, $id);
			#warn "Names 1: $verbatimCollectors===>($collector)\t($recordedBy)\n";
		}
		elsif ($collector =~ m/^([A-Za-z]{2,}), ([A-Z] ?[A-Z] ?)$/){
			$recordedby = "$2 $1";
			$recordedBy = &CCH::validate_single_collector($recordedby, $id);
			#warn "Names 2: $verbatimCollectors===>($collector)\t($recordedBy)\n";
		}		
		elsif ($collector =~ m/^([A-Za-z]{2,}), ([A-Z][. ]{1,2}[A-Z][. ]{1,2}) ?(;|:|,| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
			$other_coll = $4;
			$collectors = "$2 $1";
			$recordedBy = &CCH::validate_collectors($collectors, $id);	
			#warn "Names 3: $verbatimCollectors===>($collector)\t($recordedBy)\t($other_coll)\n";
			&log_change("COLLECTOR (3): modified: $verbatimCollectors==>($collector)\t($recordedBy)\t($other_coll)\t$id\n");	
		}
		elsif ($collector =~ m/^([A-Za-z]{2,}), ([A-Z] ?[A-Z] ?) ?(;|:|,| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
			$other_coll = $4;
			$collectors = "$2 $1";
			$recordedBy = &CCH::validate_collectors($collectors, $id);	
			#warn "Names 4: $verbatimCollectors===>($collector)\t($recordedBy)\t($other_coll)\n";
			&log_change("COLLECTOR (4): modified: $verbatimCollectors==>($collector)\t($recordedBy\)\t($other_coll)\t$id\n");	
		}
		elsif ($collector =~ m/(;|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
			$collectors = $collector;
			$recordedBy = &CCH::validate_collectors($collectors, $id);	
		#D Atwood; K Thorne
			$other_coll=$2;
			#warn "Names 5: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
			&log_change("COLLECTOR (5): modified: $verbatimCollectors==>($collector)\t($recordedBy\)\t($other_coll)\t$id\n");		
		}
		elsif ($collector !~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
			$collectors = $collector;
			$recordedBy = &CCH::validate_collectors($collectors, $id);
			#warn "Names 6: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
			&log_change("COLLECTOR (6): not modified: ($collector)\t($recordedBy\)\t($other_coll)\t$id\n");	
		}
		elsif (length($collector == 0)) {
			$recordedBy = "Unknown";
			&log_change("COLLECTOR (7): modified from NULL to $recordedBy\t$id\n");
		}	
		else{
			&log_change("COLLECTOR (8): name format problem: $verbatimCollectors==>$collector\t--$id\n");
			$recordedBy = "Unknown";
		}
	}
	elsif ((length($collector) == 0) && (length($associatedCollectors) == 0)){
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
		&log_change("COLLECTOR (10): names NULL\t$id\n");
	}
	else {
	$recordedBy = &CCH::validate_single_collector($collector, $id);
	&log_change("COLLECTOR (9): $verbatimCollectors\t--\t$recordedBy\t--\t$associatedCollectors\n");
	#warn "Names 9: $verbatimCollectors\t--\t$recordedBy\t--\t$associatedCollectors\n";
	}







###further process other collectors
foreach ($other_coll,$associatedCollectors){
	s/'$//g;
	s/^ +//;
	s/ +$//;
	s/  +/ /;
}

$other_collectors = ucfirst($other_coll);

if ((length($recordedBy) > 1) && (length($other_collectors) > 1) && (length($associatedCollectors) > 1)){
	#warn "Names 1: ($verbatimCollectors)\t($recordedBy)\t($other_collectors)\t($associatedCollectors)\n";
		$other_collectors = $associatedCollectors;
		$verbatimCollectors = "$recordedBy, $associatedCollectors";
}
elsif ((length($recordedBy) > 1) && (length($other_collectors) == 0) && (length($associatedCollectors) > 1)){
	#warn "Names 2: ($verbatimCollectors)\t($recordedBy)\t($other_collectors)\t($other_collectors)\t($associatedCollectors)\n";
		$other_collectors = $associatedCollectors;
		$verbatimCollectors = "$recordedBy, $associatedCollectors";
}
elsif ((length($recordedBy) > 1) && (length($other_collectors) == 0) && (length($associatedCollectors) == 0)){
		$other_collectors = "";
		$verbatimCollectors = "$recordedBy";
	#warn "Names 3: ($verbatimCollectors)\t($recordedBy)\t($other_collectors)\n";
}
elsif ((length($recordedBy) > 1) && (length($other_collectors) > 1) && (length($associatedCollectors) == 0)){
	#warn "Names 4: ($verbatimCollectors)\t($recordedBy)\t($other_collectors)\t($other_collectors)\t($associatedCollectors)\n";
		$verbatimCollectors = "$recordedBy, $other_collectors";
}
elsif ((length($collector) == 0) && (length($other_collectors) == 0) && (length($associatedCollectors) == 0)){
	$recordedBy =  $other_collectors = $verbatimCollectors = "Unknown";
	&log_change("COLLECTOR: names NULL\t$id\n");
}
else {
		&log_change("COLLECTOR: name fields missing data, cannot process $id\t($verbatimCollectors)\t($recordedBy)\t($other_collectors)\t($associatedCollectors)\n");
		$recordedBy = "Unknown";
}

#############CNUM##################


($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);

###########COUNTRY

# fix records where something other than USA was entered erroneously for California specimens
	foreach ($country){
		s/San Diego/USA/;
		s/California/USA/;
		s/Saint Helena/USA/;
		s/Reunion/USA/;
		s/EE\. UU\./USA/;
		s/usa/USA/;
		s/USa/USA/;
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




#####Fix bad country records

	if (($country =~ m/Antigua and Barbuda|Argentina|Australia|Anguilla|Belize|Brunei Darussalam|Costa Rica|French Guiana|United Arab Emirates|Mexico|Paraguay|Peru|Honduras|Sierra Leone/ ) && ($stateProvince =~ m/California/) && ($tempCounty =~ m/[A-Z].*/)){
		$country = "USA";#(because there are many where Country is not USA, State = California and County is from California)
		&log_change("COUNTRY: bad country name entered for specimen (1)\t($country)\t($stateProvince)\t($tempCounty)\t$id");
	}
	elsif (($country =~ m/Antigua and Barbuda|Argentina|Australia|Anguilla|Belize|Brunei Darussalam|Costa Rica|French Guiana|United Arab Emirates|Mexico|Paraguay|Peru|Honduras|Sierra Leone/ ) && ($stateProvince =~ m/California/) && (length($tempCounty) == 0)){
		++$skipped{one};#(because there are many where State = California but locations are from another country)
		next Record;
		&log_change("COUNTRY: bad country name entered for specimen (2)\t($country)\t($stateProvince)\t($tempCounty)\t$id");
	}
	elsif (($country =~ m/(U\. S\. A\.|U\.S\.A\.|United States|USA)/) && ($stateProvince =~ m/California/) && ($tempCounty =~ m/[A-Z].*/)){
		#&log_change("Specimen geography passed:\t($country)\t($stateProvince)\t($tempCounty)\t$id");
	}
	elsif (($country =~ m/(U\. S\. A\.|U\.S\.A\.|United States|USA)/) && ($stateProvince =~ m/California/) && (length($tempCounty) == 0)){
		$tempCounty =  "Unknown";
		&log_change("COUNTY: specimen geography modified, county NULL, changed to $tempCounty:\t($country)\t($stateProvince)\t($tempCounty)\t$id");
	}
	elsif (($country =~ m/.*/) && ($stateProvince =~ m/(U\. S\. A\.|U\.S\.A\.|United States|USA)/) && (length($tempCounty) == 0)){
		$country = "USA";
		$tempCounty =  "Unknown";
		$stateProvince = "California";
		&log_change("STATE: Specimen geography modified, USA entered state field, now:\t($country)\t($stateProvince)\t($tempCounty)\t$id");
	}
	elsif (($country =~ m/(U\. S\. A\.|U\.S\.A\.|United States|USA)/) && ($stateProvince =~ m/California/) && (length($tempCounty) > 1)){
		#&log_change("COUNTY: Specimen geography passed:\t($country)\t($stateProvince)\t($tempCounty)\t$id");
	}

	else {
		&log_skip("COUNTRY: bad geographic names entered for specimen, specimen skipped (2)\t($country)\t($stateProvince)\t($tempCounty)\t$id"); 
		next Record;
	}



#fix additional problematic counties
	if(($id=~/^8104815$/) && ($tempCounty=~m/Natural forest Yosemite/)){ #fix some really problematic county records
		$tempCounty=~s/Natural forest Yosemite/Alpine/;
		$locality=~s/^.*$/Ebbet Pass Toyabe Natural forest Yosemite/;	
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}

	if(($id=~/^3831368$/) && ($tempCounty=~m/Reedly/)){ #fix some really problematic county records
		$tempCounty=~s/Reedly/Unknown/;
		$locality=~s/^.*$/Reedly, Canal Bank./;	
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}	

	if(($id=~/^8099705$/) && ($tempCounty=~m/Blue Lake/)){ #fix some really problematic county records
		$tempCounty=~s/Blue Lake/Humboldt/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}

	if(($id=~/^8103425$/) && ($tempCounty=~m/Plaster city/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Imperial/;
		$locality=~s/^.*$/Plaster City, along Painted George Road./;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}

	if(($id=~/^4288260$/) && ($tempCounty=~m/Kiber/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Unknown/;
		&log_change("COUNTY: County error, changed to Unknown ($tempCounty)\t($locality)\t$id\n");	
	}

	if(($id=~/^8103504$/) && ($tempCounty=~m/Coyote Mountains/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Imperial/;
		$locality=~s/^.*$/Coyote Mountains, along Painted George Road./;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
	
	if(($id=~/^3130265$/) && ($tempCounty=~m/[Rrm]+/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Kern/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");
	}	
	
	if(($id=~/^(3129414|3143225|4692151|951709)$/) && ($tempCounty=~m/(Pasadena|Pasadena County)/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Los Angeles/;
		&log_change("COUNTY: County/Location problem modified to $tempCounty\t$id\n");
	}
	
	if(($id=~/^4558813$/) && ($tempCounty=~m/Pasadena/)){ #fix some really problematic county records
		$tempCounty=~s/Pasadena/Los Angeles/;
		$locality=~s/^.*$/Pasadena Lisson loleal/;	
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
	
	if(($id=~/^7547025$/) && ($tempCounty=~m/Pasadena/)){ #fix some really problematic county records
		$tempCounty=~s/Pasadena/Los Angeles/;
		$locality=~s/^.*$/Pasadena/;	
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
		
	if(($id=~/^(901459|903482)$/) && ($tempCounty=~m/(Pasadena|Pasadena County)/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Los Angeles/;
		$locality=~s/^.*$/Pasadena/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");
	}	
	
	if(($stateProvince=~m/^California/) &&($tempCounty=~m/Isla San Clemente/)){ #fix some really problematic county records
		$tempCounty=~s/Isla San Clemente/Los Angeles/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
	
	if(($stateProvince=~m/^California/) &&($tempCounty=~m/San Clemente Island/)){ #fix some really problematic county records
		$tempCounty=~s/San Clemente Island/Los Angeles/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
		
	if(($stateProvince=~m/^California/) &&($tempCounty=~m/Isla Santa Cruz/)){ #fix some really problematic county records
		$tempCounty=~s/Isla Santa Cruz/Los Angeles/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}

	if(($stateProvince=~m/^California/) &&($tempCounty=~m/Santa Cruz Island/)){ #fix some really problematic county records
		$tempCounty=~s/Santa Cruz Island/Los Angeles/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}

	if(($id=~/^8101880$/) && ($tempCounty=~m/^California/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Marin/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
	
	if(($id=~/^6744629$/) && ($tempCounty=~m/Pine/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Siskiyou/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");
	}

	if(($id=~/^(13944562|13947233)$/) && ($locality=~m/Victorville/)){ #fix some really problematic county records
		$tempCounty=~s/^Mojave/San Bernardino/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
	
	if(($id=~/^175724$/) && ($tempCounty=~m/Santa Rosa/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Sonoma/;
		$locality=~s/^.*$/Santa Rosa/;
		&log_change("COUNTY: County/Location problem modified to $tempCounty\t$id\n");	
	}
	
	if(($id=~/^3358234$/) && ($tempCounty=~m/San Jocinto/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Riverside/;
		$locality=~s/^.*$/San Jacinto/;
		&log_change("COUNTY: County/Location problem modified to $tempCounty\t$id\n");	
	}

	if(($stateProvince=~m/^California/) && ($tempCounty=~m/Bernardino Basin\s.*/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Bernardino/;
		&log_change("COUNTY: County problem modified to $tempCounty\t$id\n");	
	}	

	if(($id=~/^3292360$/) && ($tempCounty=~m/San Francisco, California/)){ #fix some really problematic county records
		$tempCounty=~s/San Francisco, California/San Francisco/;
		$locality=~s/^.*$/Lake Merced, San Francisco, California/;	
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
	
	if(($id=~/^4013256$/) && ($tempCounty=~m/Vallejo/)){ #fix some really problematic county records
		$tempCounty=~s/Vallejo/Solano/;
		$locality=~s/^.*$/Vallejo, roadside of Hwy 29/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}

	if(($id=~/^8100470$/) && ($tempCounty=~m/Iron Mountain/)){ #fix some really problematic county records
		$tempCounty=~s/Iron Mountain/Santa Barbara/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}

	if(($id=~/^(8103720|8103721|8103722|8103723|8103724)$/) && ($tempCounty=~m/Mesa Otay/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Diego/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}

	if(($id=~/^(8100605|8100604|8100601)$/) && ($tempCounty=~m/Jacumba Jim/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Diego/;
		$locality=~s/^.*$/Jacumba Jim Canyon, off of Carrizo Canyon; aprox. 5.1 mi up Carrizo Canyon from Hwy S2./;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
		
	if(($id=~/^(8100489|8100492|8100496)$/) && ($tempCounty=~m/Rancho del Cielo/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Diego/;
		$locality=~s/^.*$/Rancho del Cielo, Iron Mountain area, south of Ramona./;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
		
	if(($id=~/^(8098264|8102290|8100472)$/) && ($tempCounty=~m/(Corte Madera Ranch|Pine Valley)/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Diego/;
		$locality=~s/^.*$/Corte Madera Ranch, south of Pine Valley./;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
		
	if(($id=~/^(8100662|8100670|8100671|8100675|8101754|8105440)$/) && ($tempCounty=~m/San Felipe Valley/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Diego/;
		$locality=~s/^.*$/San Felipe Valley/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
		
	if(($id=~/^7572182$/) && ($tempCounty=~m/Adobe Flats/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Diego/;
		$locality=~s/^.*$/Adobe Flats/;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}
		
	if(($id=~/^8103294$/) && ($tempCounty=~m/Cuyamaca/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Diego/;
		$locality=~s/^.*$/Cuyamaca, Along outlet stream below Dam./;
		&log_change("COUNTY: County/Location problem modified ($tempCounty)\t($locality)\t$id\n");	
	}		
	
	if(($stateProvince=~m/^California/) && ($tempCounty=~m/(Y.?cora|Buena Vista|Moonlight|San Antonio|Switzer|Cuyamaca|Los .e.+quitos)/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Diego/;
		&log_change("COUNTY: County problem modified to $tempCounty\t$id\n");	
	}
	
	if(($id=~/^8003721$/) && ($tempCounty=~m/Y.+cora/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/San Diego/;
		&log_change("COUNTY: County problem modified to $tempCounty\t$id\n");	
	}		
	
	if(($id=~/^(4604252|6328916)$/) && ($tempCounty=~/[wW]eld/)){ #fix some really problematic county records
		$tempCounty=~s/^.*$/Unknown/;
		&log_change("COUNTY: County/Location problem modified $tempCounty)\t($locality)\t$id\n");	
	}


######################Unknown County List

	if($tempCounty=~m/(unknown|Unknown)/){	#list each $tempCounty with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$tempCounty\t--\t$locality\t$id");		
	}

#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);

##############validate county
my $v_county;


foreach($county){#for each $county value
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|Unknown)$/){
		$v_county = &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&log_skip("COUNTY (2): NON-CA COUNTY?==>$_\t$id");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log_change("COUNTY (3): COUNTY $_ ==> $v_county\t$id");		#call the &log function to print this log message into the change log...
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
		&log_change("Locality NULL, $id\t($locality)\t($municipality)\n");		#call the &log function to print this log message into the change log...
	}
	elsif ((length($locality) == 0) && (length($municipality) == 0) && (length($informationWithheld) > 2)){
		&log_change("Locality Redacted by SEINET\t$id\n");		#call the &log function to print this log message into the change log...
	}
	else {
		&log_change("Locality problem, missing data, $id\t($locality)\t($municipality)\n");		#call the &log function to print this log message into the change log...
	}




###############ELEVATION########

foreach( $verbatimElevation){
	s/ [eE]lev.*//;	#remove trailing content that begins with [eE]lev
	s/feet/ft/;	#change feet to ft
	s/\d+ *m\.? \((\d+).*/$1 ft/;
	s/\(\d+\) \((\d+).*/$1 ft/;
	s/'/ft/;	#change ' to ft
	s/FT/ft/;	#change FT to ft
	s/Ft/ft/;	#change Ft to ft
	s/\/\/N-\/\/N//g;
	s/NULL//g;
	s/sea.?level$/0 m/i;
	s/ca\.? ?//i;
	s/near ?//;
	s/Close to ?//i;
	s/approx\.//g;
	s/Below ?//i;
	s/^o m/0 m/i;
	s/- *ft/ft/;
	s/meters/m/;
	s/,//g;
	s/\>//g;
	s/\<//g;
	s/\@//g;
	s/[Mm]\.? *$/m/;	#substitute M/m/M./m., followed by anything, with "m"
	s/ft?\.? *$/ft/;	#subst. f/ft/f./ft., followed by anything, with ft
	s/ft/ ft/;		#add a space before ft
	s/m *$/ m/;		#add a space before m
	s/^0+$/0 m/;
	s/  +/ /g;		#collapse consecutive whitespace as many times as possible
	s/^ +//;
	s/ +$//;

}


foreach($minimumElevationInMeters){

	s/-9999+/0/;		#change the symbiota defualt or missing value -9999 to 0
	s/..N-..N//g; #delete the odd placeholder '\\N-\\N'
	s/  +/ /g;		#collapse consecutive whitespace as many times as possible
	s/^ +//;
	s/ +$//;
}

	if ((length($verbatimElevation) >= 1) && (length($minimumElevationInMeters) == 0)){
		$elevation = $verbatimElevation;
	}		
	elsif ((length($verbatimElevation) >= 1) && (length($minimumElevationInMeters) >= 1)){
		$elevation = "$minimumElevationInMeters m";
	}
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevationInMeters) >= 1)){
		$elevation = "$minimumElevationInMeters m";
	}
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevationInMeters) == 0)){
		$elevation = "";
		&log_change("Elevation NULL\t$id");
	}
	else {
		&log_change("Elevation problem, elevation non-numeric or poorly formatted, $id\t--\t($minimumElevationInMeters)\t--\t($verbatimElevation)\n");		#call the &log function to print this log message into the change log...
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

#######Latitude and Longitude
my $hold;
my $lat_degrees;
my $lat_minutes;
my $lat_seconds;
my $lat_decimal;
my $long_degrees;
my $long_minutes;
my $long_seconds;
my $long_decimal;

foreach ($verbatimLatitude, $verbatimLongitude){
		s/'/ /;
		s/"/ /;
		s/,/ /;
		s/\/\/N//g;
		s/-+//g;
		s/deg./ /;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		
}
my $coordinates;

	if ((length($verbatimCoordinates) >= 1) && (length($verbatimLatitude) == 0) && (length($verbatimLongitude) == 0)){
		$coordinates = $verbatimCoordinates;
	}		
	elsif ((length($verbatimCoordinates) >= 1) && (length($verbatimLatitude) >= 1) | (length($verbatimLongitude) >= 1)){
		$coordinates = "$verbatimCoordinates ($verbatimLatitude, $verbatimLongitude)";
	}
	elsif ((length($verbatimCoordinates) == 0) && (length($verbatimLatitude) >= 1) && (length($verbatimLongitude) >= 1)){
		$coordinates = "$verbatimLatitude, $verbatimLongitude";
	}
	elsif ((length($verbatimCoordinates) == 0) && (length($verbatimLatitude) == 0) && (length($verbatimLongitude) == 0)){
		$coordinates = "";
	}
	else {
		$coordinates = "$verbatimCoordinates ($verbatimLatitude, $verbatimLongitude)";
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
		&log_change("COORDINATE: partial coordinates only for $id\t($verbatimLatitude)\t($verbatimLongitude)\n");
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}


#NULL coordinates that are only integer degrees, these are highly inaccurate and not useful for mapping
	if (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
		$latitude = "";
		$longitude = "";
		&log_change("COORDINATE decimal Lat/Long only to degree, now NULL: $verbatimLatitude\t--\t$verbatimLongitude\n");
	}



foreach ($latitude, $longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s$//;
}	


#fix some problematic records with bad latitude and longitude in home database, mostly detected because they are yellow flags

if (($id =~ m/^(10881842|10794076)$/) && ($longitude =~ m/114\./)){ 
	$latitude = "34.45";
	$longitude = "-119.7095";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) does not map within boundary of county and/or state on the label, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
#the original is in error and maps to I-40, W of Needles, San Bernardino County, coords erroneously copied from Abbott 9297 which is from W of Needles
}

if (($id =~ m/^(2049369|2051199|2053747|3084025|3084168|2054640|3563011)$/) && ($longitude =~ m/117\.9/)){ 
	$latitude = "33.58455";
	$longitude = "-116.97649";
	$georeferenceSource = "(copied from SEINET3084025/DES00034842)";
	$coordinateUncertaintyInMeters = "5000";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) maps to the Pacific Ocean and within boundary of county and/or state on the label, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
#the original longitude on the label, 117d 58m, is in error and maps to the Pacific Ocean, not Riverside County
}

if (($id =~ m/^(4676150)$/) && ($longitude =~ m/121\./)){ 
	$latitude = "36.3204";
	$longitude = "-116.3777";
	$georeferenceSource = "";
	$coordinateUncertaintyInMeters = "";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) does not map within boundary of county and/or state on the label, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
#the original is in error and maps to Plumas County, coords erroneously converted from TRS using the wrong baseline
}
if (($id =~ m/^(224307)$/) && ($longitude =~ m/117\./)){
	$latitude = "37.178";
	$longitude = "-118.31";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) does not map within boundary of county and/or state on the label, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
#the original is in error and maps to Panamint Range, new coords copied from UC127089 which is a duplicate
}


#use combined Lat/Long field format for SEINET


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
elsif ((length($latitude) == 0) && (length($longitude) == 0)){
#UTM is not present in these data, skipping conversion of UTM and reporting if there are cases where lat/long is problematic only
		&log_change("COORDINATE No coordinates for $id\n");
}
elsif(($latitude==0 && $longitude==0)){
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
if(($verbatimLatitude=~/\d/  || $verbatimLongitude=~/\d/)){ #If decLat and decLong are both digits


	if ($geodeticDatum =~ m /^([NADnadWGSwgs]+[ -19]*[23478]+)$/){ #report if true datum is present, toss out all erroneous data
		s/19//g;
		s/-//g;
		s/ //g;
		$datum = $1;
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
foreach ($coordinateUncertaintyInMeters){
	s/  +/ /g;
		s/^ +//;
		s/ +$//;
}

#Error radius Units
$errorRadiusUnits = "m";




#final check of Longitude
	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			&log_change("COORDINATE Longitude made negative\t--\t$id");
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


#######Habitat and Assoc species (dwc habitat and associatedTaxa)

#free text fields

foreach ($habitat){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/^ +//g;
		s/  +/ /g;
}

foreach ($associatedTaxa){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/with / /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/^ +//g;
	s/ +$//g;
	s/  +/ /g;
}


#######Notes and phenology fields species

#free text fields
my $note_string;


foreach ($informationWithheld, $occurrenceRemarks,$dynamicProperties,$establishmentMeans,$locationRemarks){
	s/'$//g;
	s/^ +//;
	s/ +$//;
	s/  +/ /;
}


#format det_string correctly
	if ((length($informationWithheld) > 1) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) == 0) && (length($establishmentMeans) == 0) && (length($locationRemarks) == 0)){
		$note_string="$informationWithheld";
	}
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) == 0) && (length($establishmentMeans) == 0) && (length($locationRemarks) == 0)){
		$note_string="";
	}
	elsif ((length($informationWithheld) > 1) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties) == 0) && (length($establishmentMeans) == 0) && (length($locationRemarks) == 0)){
		$note_string="$informationWithheld| Occurrence Remarks: $occurrenceRemarks";
	}
	elsif ((length($informationWithheld) > 1) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties) > 1) && (length($establishmentMeans) == 0) && (length($locationRemarks) == 0)){
		$note_string="$informationWithheld| Occurrence Remarks: $occurrenceRemarks; Other Notes: $dynamicProperties";
	}
	elsif ((length($informationWithheld) > 1) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties) > 1) && (length($establishmentMeans) > 1) && (length($locationRemarks) == 0)){
		$note_string="$informationWithheld| Occurrence Remarks: $occurrenceRemarks; Other Notes: $dynamicProperties; $establishmentMeans";
	}
	elsif ((length($informationWithheld) > 1) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) > 1) && (length($establishmentMeans) > 1) && (length($locationRemarks) == 0)){
		$note_string="$informationWithheld| Other Notes: $dynamicProperties; $establishmentMeans";
	}
	elsif ((length($informationWithheld) > 1) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) == 0) && (length($establishmentMeans) > 1) && (length($locationRemarks)  > 1)){
		$note_string="$informationWithheld| Other Notes: $establishmentMeans| Location Remarks: $locationRemarks";
	}
	elsif ((length($informationWithheld) > 1) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) == 0) && (length($establishmentMeans) == 0) && (length($locationRemarks)  > 1)){
		$note_string="$informationWithheld| Location Remarks: $locationRemarks";
	}
	elsif ((length($informationWithheld) > 1) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) > 1) && (length($establishmentMeans) > 1) && (length($locationRemarks) == 0)){
		$note_string="$informationWithheld| Other Notes: $dynamicProperties; $establishmentMeans";
	}
	elsif ((length($informationWithheld) > 1) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) > 1) && (length($establishmentMeans) == 0) && (length($locationRemarks) == 0)){
		$note_string="$informationWithheld| Other Notes: $dynamicProperties";
	}
	elsif ((length($informationWithheld) > 1) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) == 0) && (length($establishmentMeans) > 1) && (length($locationRemarks) == 0)){
		$note_string="$informationWithheld| Other Notes: $establishmentMeans";
	}
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) > 1) && (length($establishmentMeans) > 1) && (length($locationRemarks) > 1)){
		$note_string="Other Notes: $dynamicProperties, $establishmentMeans| Location Remarks: $locationRemarks";
	}
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) == 0) && (length($establishmentMeans) > 1) && (length($locationRemarks) > 1)){
		$note_string="Other Notes: $establishmentMeans| Location Remarks: $locationRemarks";
	}
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) == 0) && (length($establishmentMeans) == 0) && (length($locationRemarks) > 1)){
		$note_string="Location Remarks: $locationRemarks";
	}
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties) == 0) && (length($establishmentMeans) > 1) && (length($locationRemarks) > 1)){
		$note_string="Occurrence Remarks: $occurrenceRemarks| Other Notes: $establishmentMeans| Location Remarks: $locationRemarks";
	}	
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties) == 0) && (length($establishmentMeans) == 0) && (length($locationRemarks) > 1)){
		$note_string="Occurrence Remarks: $occurrenceRemarks| Location Remarks: $locationRemarks";
	}	
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties) == 0) && (length($establishmentMeans) == 0) && (length($locationRemarks) == 0)){
		$note_string="Occurrence Remarks: $occurrenceRemarks";
	}	
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties) > 1) && (length($establishmentMeans) == 0) && (length($locationRemarks) > 1)){
		$note_string="Occurrence Remarks: $occurrenceRemarks| Other Notes: $dynamicProperties| Location Remarks: $locationRemarks";
	}	
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) > 1) && (length($establishmentMeans) == 0) && (length($locationRemarks) > 1)){
		$note_string="Other Notes: $dynamicProperties| Location Remarks: $locationRemarks";
	}
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) > 1) && (length($establishmentMeans) == 0) && (length($locationRemarks) == 0)){
		$note_string="Other Notes: $dynamicProperties";
	}	
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) > 1) && (length($establishmentMeans) > 1) && (length($locationRemarks) > 1)){
		$note_string="Other Notes: $dynamicProperties, $establishmentMeans| Location Remarks: $locationRemarks";
	}	
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties) > 1) && (length($establishmentMeans) == 0) && (length($locationRemarks) == 0)){
		$note_string="Occurrence Remarks: $occurrenceRemarks| Other Notes: $dynamicProperties";
	}		
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties) == 0) && (length($establishmentMeans) > 1) && (length($locationRemarks) == 0)){
		$note_string="Occurrence Remarks: $occurrenceRemarks| Other Notes: $establishmentMeans";
	}		
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) > 1) && (length($establishmentMeans) > 1) && (length($locationRemarks) == 0)){
		$note_string="Other Notes: $dynamicProperties, $establishmentMeans";
	}	
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) > 1) && (length($dynamicProperties)  > 1) && (length($establishmentMeans) > 1) && (length($locationRemarks) == 0)){
		$note_string="Occurrence Remarks: $occurrenceRemarks| Other Notes: $dynamicProperties, $establishmentMeans";
	}
	elsif ((length($informationWithheld) == 0) && (length($occurrenceRemarks) == 0) && (length($dynamicProperties) == 0) && (length($establishmentMeans) > 1) && (length($locationRemarks) == 0)){
		$note_string="Other Notes: $establishmentMeans";
	}
	else{
		&log_change("NOTES: problem with notes field\t$id($informationWithheld| Occurrence Remarks: $occurrenceRemarks| Other Notes: $dynamicProperties, $establishmentMeans| Location Remarks: $locationRemarks");
		$note_string="";
	}


##phenology
my $phenology;

foreach ($reproductiveCondition,$lifeStage){
	s/'$//g;
	s/^ +//;
	s/ +$//;
	s/  +/ /;
}
	if((length($reproductiveCondition) > 1) && (length($lifeStage) == 0)){
		$phenology = $reproductiveCondition;
	}		
	elsif ((length($reproductiveCondition) > 1) && (length($lifeStage) > 1)){
		$phenology = "$reproductiveCondition, $lifeStage";
	}
	elsif ((length($reproductiveCondition) == 0) && (length($lifeStage) > 1)){
		$phenology = $lifeStage;
	}
	elsif ((length($reproductiveCondition) == 0) && (length($lifeStage) == 0)){
		$phenology = $lifeStage;
		#&log_change("Phenology NULL, $id\n");		#call the &log function to print this log message into the change log...
	}
	else {
		&log_change("Phenology problem, data format issues, $id\t--\t$reproductiveCondition\t--\t$lifeStage\n");		#call the &log function to print this log message into the change log...
		$phenology = "";
	}


++$count_record;
warn "$count_record\n" unless $count_record % 10000;

##########################OTHER LABEL NUMBERS
foreach ($institutionCode,$catalogNumber,$otherCatalogNumbers){
	s/USU-UTC/USU/;
	s/Barcode: *//i;
	s/\.//g; #some MNA accessions have periods
	s/ +//g;
}

	if((length($catalogNumber) == 0) && ($otherCatalogNumbers=~m/^[A-Za-z]+-?[A-Z]?-?\d+[A-Z]*/)){
		$catalogNumber="$otherCatalogNumbers";
		&log_change("Catalog Number Modified 1: $id\t($otherCatalogNumbers)\n");
	}
	elsif((length($catalogNumber) == 0) && ($otherCatalogNumbers=~m/^\d+/)){
		$catalogNumber="$institutionCode$otherCatalogNumbers";
		&log_change("Catalog Number Modified 2: $id\t($institutionCode)($otherCatalogNumbers)\n");
	}	
	elsif(($catalogNumber=~m/^\d+$/) && (length($otherCatalogNumbers) == 0)){
		$catalogNumber="$institutionCode$catalogNumber";
		&log_change("Catalog Number Modified 3: $id\t($institutionCode)($catalogNumber)\n");
	}
	elsif((length($catalogNumber) == 0) && (length($otherCatalogNumbers) == 0)){
		$catalogNumber="$institutionCode";
		&log_change("Catalog Number NULL, Institution Code used: $id\t($institutionCode)\n");
	}
	elsif(($catalogNumber=~m/^[A-Z]+-?[A-Z]?-?\d+[A-Z]*/) && ($otherCatalogNumbers=~m/^\d+/)){
		&log_change("Catalog Number NOT Modified (1): $id\t($catalogNumber)\n");
	}
	elsif(($catalogNumber=~m/^\d+$/) && ($otherCatalogNumbers=~m/^[A-Za-z]+-?[A-Z]?-?\d+[A-Z]*/)){
		$catalogNumber="$otherCatalogNumbers";
		&log_change("Catalog Number Modified 6: $id\t($institutionCode)($catalogNumber)\n");
	}	
	elsif(($catalogNumber=~m/^[A-Za-z]+-?[A-Z]?-?\d+[A-Z]*/) && ($otherCatalogNumbers=~m/^[A-Za-z]+-?[A-Z]?-?\d+[A-Z]*/)){
		&log_change("Catalog Number NOT Modified (2): $id\t($catalogNumber)\n");
	}
	elsif(($catalogNumber=~m/^[A-Za-z]+-?[A-Z]?-?\d+[A-Z]*/) && (length($otherCatalogNumbers) == 0)){
		&log_change("Catalog Number NOT Modified (3): $id\t($catalogNumber)\n");
	}	
	else{
		&log_change("Catalog Number problem: $id\t($institutionCode)\t($catalogNumber)\t($otherCatalogNumbers)\n");
	}


			print OUT <<EOP;
Accession_id: $id_non
Other_label_numbers: $catalogNumber
Name: $scientificName
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
Collector: $recordedBy
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
Associated_species: $associatedTaxa
T/R/Section:
USGS_Quadrangle: 
Verbatim_coordinates: $coordinates
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Lat_long_ref_source: $georeferenceSource
Datum: $datum
Max_error_distance: $coordinateUncertaintyInMeters
Max_error_units: $errorRadiusUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Physical_environment: $substrate
Phenology: $phenology
Population_biology: $verbatimAttributes
Notes: $note_string
Hybrid_annotation: $hybrid_annotation
Cultivated: $cultivationStatus
Image: $IMG{$id}
Annotation: $det_orig
EOP

#usually, the blank line is included at the end of the block above
#but since the $ANNO{$id} is printed outside the block, the \n is after
print OUT $ANNO{$id};
print OUT "\n";


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


    my $file_in = '/JEPS-master/CCH/Loaders/SEINET/SEINET_out.txt';	#the file this script will act upon is called 'CATA.out'
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
				&log_skip("Z) problem character detected: s/$match/    /g   $_ ---> $store{$_}\n\n"); #Z) so this sorts last
	}
close(IN);

