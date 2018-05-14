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

my $images_file='/JEPS-master/CCH/Loaders/UCSC/UCSC_SymbiotaDownloads/images.tab';
my $dets_file='/JEPS-master/CCH/Loaders/UCSC/UCSC_SymbiotaDownloads/identifications.tab';
my $records_file='/JEPS-master/CCH/Loaders/UCSC/UCSC_SymbiotaDownloads/occurrences.tab';
my $temp_file='/JEPS-master/CCH/Loaders/UCSC/UCSC_temp.txt'; #file without the large number of unwanted records filtered from step 1

my $included;
my %skipped;
my %temp_skipped;
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
my %GUID_old;
my %GUID;
my $old_AID;
my $id;
my $id_nonCode;

open(OUT,">/JEPS-master/CCH/Loaders/UCSC/UCSC_out.txt") || die;
open(OUT2,">/JEPS-master/CCH/Loaders/UCSC/UCSC_AID.txt") || die; #text file for UCSC accession conversion from leading zeros to no leading zeros
open(OUT3,">/JEPS-master/CCH/Loaders/UCSC/AID_GUID_UCSC.txt") || die; #text file for OBI accession conversion 
open(TEMP,">$temp_file") || die;
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


#coreid	identifiedBy	identifiedByID	dateIdentified	identificationQualifier	scientificName	identificationIsCurrent	scientificNameAuthorship	genus	specificEpithet	taxonRank	infraspecificEpithet	identificationReferences	identificationRemarks	recordId	modified
 		
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
	else{
		$det_string="$det_rank: $det_name   $det_stet, $det_determiner, $det_date, $det_identificationRemarks";
	}



$ANNO{$det_AID}.="Annotation: $det_string\n"; #for $ANNO for each $det_AID, print the following into and a new line. ".=" Means accumulate entries, if there are multiple ANNOs per SEINET$id
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


my $id;
my $GUID;
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
my $collectionID;
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
 if ($id =~/^(9427999|9427998|9422259|9422257|9428510|9428511|9428513|9428514|9428515|9428516|9428517|9421406|9424807|9430206|9430205|9430204|9430203|10365675|13245612|9421865|9421866|9425315|9427993|9427994|9427995|9427996|9427997|9421550|9421517|13245544|9428510|9428329|9428330|9428331|9428332|9428333|9428831|9428832|9428328|9421450|9425997|9426757|9428327|9428636|9425925|9429632|9425545|9425546|9425552|9425555|9425556|9425557|9425866|9425995|9421876|9421411|9424867|9424866|9422256|9422255|9422261)/){
 	#print ("excluded problem record or record known to be not from California\t$locality\t--\t$id");
		++$temp_skipped{one};
		next Record;
	}
	
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


	
#create intermediate table

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
		s/±/+-/g;	#UCSC007372 and others
		s/°/ deg. /g;	#UCSC007367 and others, convert degree symbol to deg. abbrev.
		s/¼/ 1\/4 /g;	#UCSC007979 and others
		s/½/ 1\/2 /g;	#UCSC008252 and others
		s/é/e/;	#UCSC008115
		s/ñ/n/;	#UCSC009021 and others
		s/—/--/g;	#UCSC010545 and others
		s/‘/'/g;
		s/’/'/g;
		s/”/'/g;
		s/“/'/g;
		s/”/'/g;
		s/…//;	#UCSC011189	


#fix some more text and formatting problems
s/redacted/redacted by UCSC/g;		#substitute "redacted" with "redacted by SEINet" so users dont think CCH deleted the information in locality and coordinate fields for some rare taxa
s/Oak forest.  /Oak forest./g;
s/&apos;/'/g;
s/hindsii\?  perhaps/hindsii? perhaps/;
s/hook, and \?/hook, and ?/;
s/redwood\/tanoak\/CA/redwood-tanoak-CA/;	#UCSC009052

#declare field name variables


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
my $tempName;
my $catnon;
my %GUID_sym;
my $GUID_sym;
my $catnum;

		$line_store=$_;
		++$count;		
		
#	&CCH::check_file;
#		s/\cK/ /g;
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
($id_nonCode,
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
)=@fields;	#The array @fields is made up on these 87 scalars, in this order



##################Exclude non-vascular plants
	if($scientificName =~ /^(Gemmabryum |Nogopterium |Rosulabryum |Dichelyma |Aulacomnium |Antitrichia |Alsia )/){	#if genus is equal to one of the values in this block
		&log_skip("TAXON: Non-vascular herbarium specimen (3) $_\t$id");	#skip it, printing this error message
		++$skipped{one};
		next Record;
	}	
##################Exclude problematic specimens with certain locality issues
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
	 &log_change("VOUCHER: specimen redacted by UCSC\t$id");
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

################ACCESSION_ID#############

$id = $catalogNumber;
$catnum = $catalogNumber;  #the record ID format for all OBI specimens in these data

#remove leading zeroes, 
	if($catnum=~m/UCSC0+/){
		$catnum=~s/UCSC0+/UCSC/;
	}

foreach ($catnum){
	s/ //g;	#remove all spaces 
	s/ucsc/UCSC/;	#fix lower case errors
	s/uCSC/UCSC/;
	s/USCSC/UCSC/;	#fix typo
	s/^00010261/UCSC00010261/;	#fix one case where code is left off	
}


#check for nulls
if($catnum !~ m/^UCSC\d+/){ 
	#$catnum = $idnum; #use only if  herbarium wants to change to the SEINET unique record ID for the catalog number
	warn "Missing catalogNumber number:\t$id\n";
	&log_skip("ACCESSION: Catalog number missing or problematic, skipped==>$_");
	++$skipped{one};
	next Record;
}


#Remove duplicates
if($id =~ m/^UCSC0+/){ 
	if($seen{$catnum}++){
	warn "Catalog number is a duplicate with another record without leading zeros: $catnum\t$id\n";
	&log_skip("ACCESSION: Catalog number is a duplicate with another record without leading zeros, skipped==>$catnum\t$id");
	++$skipped{one};
	next Record;
	}
}
else {
	if($seen{$catnum}++){
	warn "Duplicate number: \t$id\n";
	&log_skip("ACCESSION: Duplicate ID number, skipped==>$id");
	++$skipped{one};
	next Record;
	}
}

foreach ($catalogNumber){
	print OUT2 "$catnum\t".$catalogNumber."\t$id_nonCode\n";
}




$GUID_old{'$id'}=$occurrenceID;

$GUID{'$catnum'}=$occurrenceID;

$GUID_sym{'$id_nonCode'}=$occurrenceID;

print OUT3 "$catnum\t$GUID{'$catnum'}\n";
print OUT3 "$id\t$GUID_old{'$id'}\n";
print OUT3 $institutionCode.$id_nonCode."\t".$GUID_old{'$id_nonCode'}."\n";

##########Begin validation of scientific names

#####Annotations  (use to show verbatim scientific name (annotation 0) when a separate annotation file is present)
	#format det_string correctly
my $det_orig_rank = "current determination (uncorrected)";  #set for current determination
my $det_orig_name = $name;

	
	if ((length($det_orig_name) >=1) && (length($identificationRemarks) == 0)){
		$det_orig="$det_orig_rank: $det_orig_name";
	}
	elsif ((length($det_orig_name) >=1) && (length($identificationRemarks) == 0)){
		$det_orig="$det_orig_rank: $det_orig_name";
	}
	elsif ((length($det_orig_name) >=1) && (length($identificationRemarks) >=1)){
		$det_orig="$det_orig_rank: $det_orig_name; $identificationRemarks";
	}
	elsif ((length($det_orig_name) == 0) && (length($taxonRemarks) == 0)){
		$det_orig="";
	}
	else{
		&log_change("ANNOT: det string problem:\t$det_orig_rank: $det_orig_name, $identificationRemarks\n");
		$det_orig="";
	}



###########NAME


my $verbatimScientificName = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;


#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($name,$verbatimScientificName){
#	s/ sp\.//g;
#	s/ species$//g;
#	s/ sp$//g;
#	s/ spp / subsp. /g;
#	s/ spp. / subsp. /g;
#	s/ ssp / subsp. /g;
#	s/ ssp. / subsp. /g;
	s/pro\. +sp\.//g;
	s/[uU]nknown/ /g; #added to try to remove the word "unknown" for some records
	s/;$//g;
	s/ ined\.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/[×] /X /;	#change  " x " in genus name to the multiplication sign
	s/No name/ /g;
	s/[uU]nknown/ /g;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
	s/subps\./subsp./;#fix some problem names
	s/Trifolium pro\ sp\. imberbe var\. gianonei ined\./Trifolium imberbe var. gianonei/;	
	s/Trifolium pro\. sp\. imberbe/Trifolium imberbe/;

	}

#if there's no scientificName, use the verbatimScientificName		
	if((length($name) >= 1) && (length($verbatimScientificName) >= 1)){ 
		$tempName = $name;
	}
	elsif((length($name) >= 1) && (length($verbatimScientificName) == 0)){ 
		$tempName = $name;
	}
	elsif((length($name) == 0) && (length($verbatimScientificName) >= 1)){ 
		&log_skip("TAXON: Taxon problem, name missing from name field, verbatim $verbatimScientificName only==>($name)\t($verbatimScientificName)\t$id");
		next Record;
		$tempName = "";
	}
	else{
		&log_skip("TAXON: Taxon problem, name NULL==>($name)\t($verbatimScientificName)\t$id");
		++$skipped{one};
		next Record;
		$tempName = "";
	}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published
if (($catnum =~ m/^(UCSC11113|UCSC11112)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Piperia unalascensis subsp\. unalascensis/Platanthera unalascensis subsp\. unalascensis/; #fix special case
	&log_change("Scientific name error - No published subtaxa within Piperia unalascensis, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10667|UCSC10666|UCSC10690|UCSC11160)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium wormskioldii subsp\. spinulosum/Trifolium wormskioldii/; #fix special case
	&log_change("Scientific name error - Trifolium wormskioldii subsp. spinulosum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10515)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium ciliolatum var\. discolor/Trifolium ciliolatum/; #fix special case
	&log_change("Scientific name error - Trifolium ciliolatum var. discolor not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC4759|UCSC5261|UCSC5263|UCSC5301|UCSC5400|UCSC6308|UCSC6309|UCSC6316|UCSC10322|UCSC10323|UCSC10324|UCSC10325|UCSC10326|UCSC10327)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium depauperatum var\. crypticum/Trifolium depauperatum/; #fix special case
	&log_change("Scientific name error - Trifolium depauperatum var. crypticum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC6021|UCSC0*10330|UCSC0*10329|UCSC0*10328|UCSC0*10331|UCSC0*10334|UCSC0*10333|UCSC0*10332)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium fucatum var\. pictum/Trifolium fucatum/; #fix special case
	&log_change("Scientific name error - Trifolium fucatum var. pictum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC4754|UCSC4769|UCSC5276|UCSC5277|UCSC5908|UCSC5909|UCSC6021)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium fucatum var\. grande/Trifolium fucatum/; #fix special case
	&log_change("Scientific name error - Trifolium fucatum var. pictum not a published name, modified to\t$tempName\t--\t$id\n");
}

if (($catnum =~ m/^(UCSC0*10628|UCSC0*10629|UCSC0*10630|UCSC0*10631|UCSC10881)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium imberbe var\. gianonei/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium imberbe var. gianonei not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC0*10632|UCSC0*10633|UCSC0*10634|UCSC0*10635)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium imberbe var\. imberbe/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium imberbe var. imberbe not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC0*10860|UCSC0*8475|UCSC0*10878)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium imberbe/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium imberbe not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC0*10640|UCSC0*10641|UCSC0*10642|UCSC0*10643|UCSC0*10644|UCSC10435|)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium janus var\. jolonense/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium janus var. jolonense not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC0*10441|UCSC0*10434|UCSC0*10435|UCSC0*10442|UCSC0*10440|UCSC0*6092|UCSC0*6091|UCSC0*8287)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium janus/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium janus not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC0*8384|UCSC0*8384|UCSC0*8389|UCSC0*8390|UCSC0*8391|UCSC0*8392|UCSC0*8393|UCSC0*8394|UCSC0*8394)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium junior var\. minor/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium janus not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC0*11028)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium olivaceum var\. viride/Trifolium olivaceum/; #fix special case
	&log_change("Scientific name error - Trifolium olivaceum var. viride not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC9370|UCSC9383|UCSC9507)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium fax/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium fax not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC0*6150|UCSC0*11134|UCSC0*5361|UCSC4758|UCSC5362)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium stenophyllum var\. minutiflorum/Trifolium stenophyllum/; #fix special case
	&log_change("Scientific name error - Trifolium stenophyllum var. minutiflorum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10507|UCSC10508|UCSC10920|UCSC11090|UCSC1701|UCSC4760|UCSC5176|UCSC5280|UCSC5299|UCSC5361|UCSC5369|UCSC5376|UCSC5675|UCSC5745|UCSC6189|UCSC6349|UCSC7080)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium stenophyllum var\. stenophyllum/Trifolium stenophyllum/; #fix special case
	&log_change("Scientific name error - Trifolium stenophyllum var. stenophyllum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC0*11132|UCSC0*11135|UCSC0*6322|UCSC0*6312)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium stenophyllum var\. truncatum/Trifolium stenophyllum/; #fix special case
	&log_change("Scientific name error - Trifolium stenophyllum var. truncatum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10308|UCSC10309|UCSC10310|UCSC10311|UCSC10312)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium willdenovii var\. ahartii/Trifolium willdenovii/; #fix special case
	&log_change("Scientific name error - Trifolium willdenovii var. ahartii not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC0*10570|UCSC0*10568|UCSC0*10569)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium bayense/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium bayense not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10649|UCSC10683|UCSC8626)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium griseum/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium griseum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10588|UCSC10589|UCSC10590|UCSC10591|UCSC10624|UCSC10625|UCSC10626|UCSC10627)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium lazarus/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium lazarus not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC8473|UCSC8476|UCSC9009|UCSC10425|UCSC10426|UCSC10427|UCSC10430|UCSC10433|UCSC10651|UCSC10652|UCSC10653|UCSC10654|UCSC10655|UCSC10679|UCSC10680|UCSC10681|UCSC10682|UCSC10684|UCSC10685|UCSC10699)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium obispoense/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium obispoense not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC6093|UCSC6026|UCSC6020)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium paravirens var\. boreale/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium paravirens not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10053|UCSC10411|UCSC10412|UCSC10509|UCSC10510|UCSC10703|UCSC10704|UCSC4744|UCSC5368|UCSC6007)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium paravirens/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium paravirens not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10558|UCSC10559|UCSC10560|UCSC10562|UCSC10576|UCSC10650|UCSC10656|UCSC10657|UCSC10913)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium rupicola/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium rupicola not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10359)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium sivlestre/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium sivlestre not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10356|UCSC10357|UCSC10358|UCSC10360|UCSC10571|UCSC10572|UCSC10573|UCSC10574|UCSC10575|UCSC11031)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium silvestre/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium silvestre not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10361)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolim silvestre/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolim silvestre not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC9080|UCSC9379|UCSC9381|UCSC9382)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium turbinatum/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium turbinatum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10561|UCSC10563|UCSC10564|UCSC10565|UCSC8436|UCSC8437|UCSC8446|UCSC8447|UCSC8448|UCSC8449|UCSC8450|UCSC8470)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium ultramaficum/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium ultramaficum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC7544|UCSC7421|UCSC7622)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Pseudognaphalium gianonei/Pseudognaphalium/; #fix special case
	&log_change("Scientific name error - Pseudognaphalium gianonei not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC7613|UCSC7611)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Nemophila gianonei/Nemophila/; #fix special case
	&log_change("Scientific name error - Nemophila gianonei not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10089)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Mondardella glomeratum/Monardella undulata/; #fix special case
	&log_change("Scientific name error - Monardella glomeratum not published, probably not Cerastium glomeratum Thuill., modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC8357|UCSC9135)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Quercus X wootteni/Quercus/; #fix special case
	&log_change("Scientific name error - Quercus X wootteni not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10636|UCSC10637|UCSC10638|UCSC10639)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium buckwestiorum var\. nanum/Trifolium buckwestiorum/; #fix special case
	&log_change("Scientific name error - Trifolium buckwestiorum var. nanum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC9380)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium californicum var\. hirsutum/Trifolium californicum/; #fix special case
	&log_change("Scientific name error - Trifolium californicum var. hirsutum not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC11128|UCSC11129)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium obtusiflorum var\. latifolium/Trifolium obtusiflorum/; #fix special case
	&log_change("Scientific name error - Trifolium obtusiflorum var. latifolium not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC6042|UCSC5367|UCSC5385|UCSC6380)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium minor .*/Trifolium/; #fix special case
	&log_change("Scientific name error - Trifolium minor, T. m. var. madonna and T. m. var. major not published names, modified to\t$tempName\t--\t$id\n");
}
if (($catnum =~ m/^(UCSC10645|UCSC10646|UCSC10647|UCSC10648)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium lilacinum var. solano/Trifolium lilacinum/; #fix special case
	&log_change("Scientific name error - Trifolium lilacinum var. solano not a published name, modified to\t$tempName\t--\t$id\n");
}

#format hybrid names
if($tempName=~m/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation=$tempName;
	warn "Hybrid Taxon: $1 removed from $tempName\n";
	&log_change("TAXON: Hybrid Taxon $1 removed from $tempName");
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
foreach ($cultivationStatus){
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
}


	if ($cultivationStatus !~ m/^(1|P)$/){
		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("CULT: specimen likely not cultivated, purple flagging skipped==>$scientificName\t$id\n");
			$cultivationStatus = "";
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|grown in garden|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($occurrenceRemarks =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in garden|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    $cultivationStatus = "P";
	   		&log_change("CULT: Cultivated specimen found and purple flagged==>($cultivationStatus)\t($scientificName)\t$id\n");
		}
		else {		
			if($cult{$scientificName}){
				$cultivationStatus = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged==>($cultivationStatus)\t($scientificName)\t$id\n");	
			}
			else {
			#&log_change("Taxon skipped purple flagging: $cultivationStatus\t--\t$scientificName\n");
			$cultivationStatus = "";
			}
		}
	}
	else {
		&log_change("CULT: Taxon flagged as cultivated in original database==>($cultivationStatus)\t($scientificName)\n");
	}


# flag known problematic cultivated specimens that have been missed in the past, add "P" for purple flag to Cultivated field in case it is still being skipped	
	#if(($cultivationStatus !~ m/^(1|P)$/) && ($id =~ m/^()$/)){
	#	$cultivationStatus = "P";
	#	&log_change("CULT: Cultivated specimen with problematic locality data, now purple flagged==>$cultivationStatus)\t($scientificName)\t$id\n");	
	#}


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
	s/^ *//g;
	s/ *$//g;
	s/  +//g;
	}
	
foreach ($verbatimEventDate){
	s/0000//g;
	s/,/ /g;
	s/\./ /g;
	s/^ *//g;
	s/ *$//g;
	s/  +//g;
	}

foreach ($year){
	s/^ *//g;
	s/ *$//g;
	s/  +//g;
}

foreach ($day){
	s/^0$//g;
	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
}

foreach ($month){
	s/^0$//g;
	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
	}


#fix some odd date errors

#if (($catnum =~ m/^(OBI80566)$/) && ($verbatimEventDate=~m/^2\?3 May 1992/i)){
#	&log_change("Date: error, EventDate and Y M D fields not parsed correctly and an error present in verbatim date ==>$verbatimEventDate\t$eventDate==>$id\n");

#	$verbatimEventDate = "2-3 May 1992";
#	$eventDate = ""; #event date incorrect, now NULL; parser will use corrected verbatim date
#}


#combine dates for values that are in the split date fields, and to a 3rd date field
	if((length($year) > 1) && (length($day) >= 1) && (length($month_rev) >= 1)){
			$eventDate_parse = $year ."-" . $month_rev . "-". $day;
			&log_change("Date parse (1): $year-$month-$day==>$id\n");
		}
	elsif((length($year) > 1) && (length($day) == 0) && (length($month_rev) >= 1)){
		$eventDate_parse = $year ."-" . $month_rev;
			&log_change("Date parse (2): $year-$month-$day==>$id\n");
		}
	elsif((length($year) > 1) && (length($day) == 0) && (length($month_rev) == 0)){
		$eventDate_parse = $year;
			&log_change("Date parse (3): $year-$month-$day==>$id\n");
		}
	elsif((length($year) > 1) && (length($day) >= 1) && (length($month_rev) == 0)){
		$eventDate_parse = $year;
					&log_change("Date parse (4): $year-$month-$day==>$id\n");
		}
	elsif((length($year)== 0) && (length($day) == 0) && (length($month_rev) == 0)){
		$eventDate_parse = "";
		&log_change("Date: YYYY-MM-DD fields NULL==>$id\n");
		}
	else{
		&log_change("Date: YYYY-MM-DD fields missing values, cannot process: Y($year)-M($month)-D($day)==>$id\n");
		$eventDate_parse = "";
	}

foreach ($eventDate_parse){
	s/0000//g;
	s/-00-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-00$/-/g;
	s/-0-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-0$/-/g;
	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
}	


#find what fields have a date value, choose one and add to $eventDateAlt
	if((length($eventDate) > 1) && (length($verbatimEventDate) > 1) && (length($eventDate_parse) > 1)){
		$eventDateAlt = $eventDate;
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
	elsif((length($eventDate) == 0) && ($verbatimEventDate =~ m/^\d+-\d+/) && (length($eventDate_parse) > 1)){
		$eventDateAlt = $verbatimEventDate;
		&log_change("Date (4): date range detected in verbatim date field, Y M D fields skipped, verbatimEventDate selected for\t$id\n");
		}
	elsif((length($eventDate) == 0) && (length($verbatimEventDate) == 0) && (length($eventDate_parse) > 1)){
		$eventDateAlt = $eventDate_parse;
		&log_change("Date (5): alternate fields empty, eventDate_parse selected for\t$id\n");
		}
	elsif((length($eventDate) > 1) && (length($verbatimEventDate) == 0) && (length($eventDate_parse) > 1)){
		$eventDateAlt = $eventDate;
		&log_change("Date (6): verbatimEventDate empty, eventDate selected for\t$id\n");
		}
	elsif((length($eventDate) > 1) && (length($verbatimEventDate) >= 1) && (length($eventDate_parse) == 0)){
		$eventDateAlt = $eventDate;
		&log_change("Date (7): eventDate selected for\t$id\n");
		}
	elsif((length($eventDate) == 0) && (length($verbatimEventDate) == 0) && (length($eventDate_parse) == 0)){
		$eventDateAlt = "";
		&log_change("Date NULL: all date fields without data\t$id\n");
		}
	else{
		&log_change("Date problem, cannot process: ($eventDate)\t($verbatimEventDate)\t($eventDate_parse)\t\t$id\n");
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
	s/&/-/g;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
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
	#warn "(2)$eventDateAlt\t$id";
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
	#warn "(18)$eventDateAlt\t$id";
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

#	if(($id=~/^3837360$/) && ($collector=~/10/)){ #fix some really problematic collector records
#		$collector=~s/10/J.P. Tracy/;
#		&log_change("Collector problem modified: $collector\t$id\n");	
#	}
	



foreach($collector){	#fix some really problematic formats for collector names

	s/\//;/g;

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
	s/ ; */; /g;
	s/ ; */; /g;
	s/ *-+ */; /g;
	s/, with/ with/;
	s/EK, Lenz/EK; Lenz/;
	s/JL, Smith/JL; Smith/;
	s/Welshs', SL, SL/S. L. Welsh; S. L. Welsh/;
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
	s/ \+ */; /g;
	s/ -+ */; /g;
	s/\.+ */. /g;
	s/ *\| */; /g;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;

}

	if ((length($collector) > 1) && (length($associatedCollectors) == 0)){
		if ($collector =~ m/^([A-Za-z]{2,}), ([A-Z][. ]{1,2}[A-Z][. ]{1,2})$/){
			$collector = "$2 $1";
			$recordedBy = &CCH::validate_single_collector($collector, $id);
			#warn "Names 1: $verbatimCollectors===>($collector)\t($recordedBy)\n";
		}
		elsif ($collector =~ m/^([A-Za-z]{2,}), ([A-Z] ?[A-Z] ?)$/){
			$collector = "$2 $1";
			$recordedBy = &CCH::validate_single_collector($collector, $id);
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
			$recordedBy = &CCH::validate_collectors($collector, $id);	
		#D Atwood; K Thorne
			$other_coll=$2;
			#warn "Names 5: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
			&log_change("COLLECTOR (5): modified: $verbatimCollectors==>($collector)\t($recordedBy\)\t($other_coll)\t$id\n");		
		}
		elsif ($collector !~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
			$recordedBy = &CCH::validate_collectors($collector, $id);
			#warn "Names 6: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
			&log_change("COLLECTOR (6): not modified: ($collector)\t($recordedBy\)\t($other_coll)\t$id\n");	
		}
		elsif (length($collector == 0)) {
			$recordedBy = "Unknown";
			&log_change("COLLECTOR (7): modified from NULL to $recordedBy\t$id\n");
		}	
		else{
			&log_change("COLLECTOR (8): name format problem: $verbatimCollectors==>$collector\t--$id\n");
		}

	}
	else {
	$recordedBy = &CCH::validate_single_collector($collector, $id);
	#warn "Names 9: $verbatimCollectors\t--\t$recordedBy\t--\t$associatedCollectors\n";
	}







###further process other collectors
foreach ($other_coll,$associatedCollectors){
	s/'$//g;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;

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
	$recordedBy =  $other_collectors = $verbatimCollectors = "";
	&log_change("COLLECTOR: names NULL\t$id\n");
}
else {
		&log_change("COLLECTOR: name fields missing data, cannot process $id\t($verbatimCollectors)\t($recordedBy)\t($other_collectors)\t($associatedCollectors)\n");
		$verbatimCollectors = $recordedBy =  $other_collectors = "";
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
		s/United Stats/USA/;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;

	}



foreach($stateProvince){#for each $county value
	s/california/California/;
	s/CALIFORNIA/California/;
	s/Califrornia/California/;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
}

foreach($tempCounty){
	s/'//g;
	s/NULL/Unknown/i;
	s/\[//g;
	s/\]//g;
	s/\?//g;
	s/none./Unknown/;
	s/County unk./Unknown/;
	s/\//--/g;
	s/needs research/Unknown/ig;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries

}

	if (($country =~ m/Antigua and Barbuda|Argentina|Australia|Anguilla|Belize|Brunei Darussalam|Costa Rica|French Guiana|United Arab Emirates|Mexico|Paraguay|Peru|Honduras|Sierra Leone/ ) && ($stateProvince =~ m/California/) && ($county =~ m/[A-Z].*/)){
		$country = "USA";#(because there are many where Country is not USA, State = California and County is from California)
		&log_change("COUNTRY: bad country name entered for specimen (1)\t($country)\t($stateProvince)\t($county)\t$id");
	}
	elsif (($country =~ m/Antigua and Barbuda|Argentina|Australia|Anguilla|Belize|Brunei Darussalam|Costa Rica|French Guiana|United Arab Emirates|Mexico|Paraguay|Peru|Honduras|Sierra Leone/ ) && ($stateProvince =~ m/California/) && (length($county) == 0)){
		++$skipped{one};#(because there are many where State = California but locations are from another country)
		next Record;
		&log_change("COUNTRY: bad country name entered for specimen (2)\t($country)\t($stateProvince)\t($county)\t$id");
	}
	elsif (($country =~ m/(U\. S\. A\.|U\.S\.A\.|United States|USA)/) && ($stateProvince =~ m/California/) && ($county =~ m/[A-Z].*/)){
		#&log_change("Specimen geography passed:\t($country)\t($stateProvince)\t($county)\t$id");
	}
	elsif (($country =~ m/(U\. S\. A\.|U\.S\.A\.|United States|USA)/) && ($stateProvince =~ m/California/) && (length($county) == 0)){
		$county =  "Unknown";
		&log_change("COUNTY: specimen geography modified, county NULL, changed to $county:\t($country)\t($stateProvince)\t($county)\t$id");
	}
	elsif (($country =~ m/.*/) && ($stateProvince =~ m/(U\. S\. A\.|U\.S\.A\.|United States|USA)/) && (length($county) == 0)){
		$country = "USA";
		$county =  "Unknown";
		$stateProvince = "California";
		&log_change("STATE: Specimen geography modified, USA entered state field, now:\t($country)\t($stateProvince)\t($county)\t$id");
	}
	elsif (($country =~ m/(U\. S\. A\.|U\.S\.A\.|United States|USA)/) && ($stateProvince =~ m/California/) && (length($county) > 1)){
		#&log_change("COUNTY: Specimen geography passed:\t($country)\t($stateProvince)\t($county)\t$id");
	}

	else {
		&log_skip("COUNTRY: bad geographic names entered for specimen, specimen skipped (2)\t($country)\t($stateProvince)\t($county)\t$id"); 
		next Record;
	}



#fix additional problematic counties
	if(($catnum=~/^UCSC11171$/) && ($tempCounty=~m/Selena/)){ #fix some really problematic county records
#14626935	UCSC			PreservedSpecimen	f1906d65-ae00-4253-9075-2bc4396a50bb	UCSC011171		Plantae	Magnoliophyta		Fabales	Fabaceae	Trifolium willdenovii	Sprengel	Trifolium	willdenovii										Randy Morgan			4370	2005-04-07	2005	4	7	97			Abundant at Coyote Ridge, same form as in Hamilton Range																		USA	California	Selena		Coyote Ridge																						ebarnett	2017-06-15 14:25:50		313	urn:uuid:f1906d65-ae00-4253-9075-2bc4396a50bb	http://swbiodiversity.org/seinet/collections/individual/index.php?occid=14626935
		$tempCounty=~s/Selena/Santa Clara/;
		$locality=~s/^.*$/Selena, Coyote Ridge/;	
		&log_change("COUNTY: County/Location problem modified ($county)\t($locality)\t$id\n");	
	}


#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);


######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
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
			&log_change("COUNTY (3): COUNTY $_ ==> $v_county--\t$id");		#call the &log function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}


##########LOCALITY#########



foreach ($municipality){
	s/'$//g;
	s/^-//g;
	s/^;//g;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;

}
foreach ($locality){
	s/'$//g;
	s/^-//g;
	s/^;//g;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
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
	elsif ((length($locality) == 0) && (length($municipality) == 0) && (length($informationWithheld) == 0)){
		&log_change("Locality NULL, $id\t($locality)\t($municipality)\n");		#call the &log function to print this log message into the change log...
	}
	elsif ((length($locality) == 0) && (length($municipality) == 0) && (length($informationWithheld) > 2)){
		&log_change("Locality Redacted by SEINET\t$id\n");		#call the &log function to print this log message into the change log...
	}
	else {
		&log_change("Locality problem, missing data, $id\t($locality)\t($municipality)\n");		#call the &log function to print this log message into the change log...
	}

####ELEVATION



###############ELEVATION########

foreach( $verbatimElevation){
	s/ [eE]lev.*//;	#remove trailing content that begins with [eE]lev
	s/feet/ft/;	#change feet to ft
	s/\d+ *m\.? \((\d+).*/$1 ft/;
	s/\(\d+\) \((\d+).*/$1 ft/;
	s/'/ft/;	#change ' to ft
	s/FT/ft/;	#change FT to ft
	s/Ft/ft/;	#change Ft to ft
	s/NULL//g;
	s/sea level$/0 m/i;
	s/- *ft/ft/;
	s/meters/m/;
	s/,//g;
	s/[Mm]\.? *$/m/;	#substitute M/m/M./m., followed by anything, with "m"
	s/ft?\.? *$/ft/;	#subst. f/ft/f./ft., followed by anything, with ft
	s/ft/ ft/;		#add a space before ft
	s/m *$/ m/;		#add a space before m
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;

}


foreach($minimumElevationInMeters){

	s/-9999+/0/;		#change the symbiota defualt or missing value -9999 to 0
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;

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
if (length($elevation) >= 1){

	if ($elevation =~ m/^(-?[0-9]+) +([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation =~ m/^<?(-?[0-9]+)([fFtT]+)/){ #added <? to fix elevation in BLMAR421 being skipped
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation =~ m/^(-?[0-9]+) +([mM])/){
		#$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = $elevation;
	}
	elsif ($elevation =~ m/^(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = $elevation;
		$CCH_elevationInMeters =~ s/m$/ m/;
	}
	elsif ($elevation =~ m/^[A-Za-z ]+ +(-?[0-9]+)([mM])/){
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
	elsif ($elevation =~ m/^[A-Za-z ]+ +(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevation =~ m/^[A-Za-z]+ +(-?[0-9]+)([fFtT]+)/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("ELEV: Check elevation '$elevation' problematic formatting or missing units\t$id");
		$CCH_elevationInMeters = $elevationInMeters = "";
	}	
}
elsif (length($elevation) == 0){
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
					s/[. ]*$//;
					s/ *- */-/;
					s/-ft/ ft/;
					s/(\d) (\d)/$1$2/g;
						s/  +/ /g;
					s/^ +//;		
					s/ +$//;	
					s/^ $//;
					
					
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
		s/deg./ /;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
		
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
	if (($verbatimLatitude =~ m/-?1\d\d\./) && ($verbatimLongitude =~ m/^\d\d\./)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		 
		&log_change("COORDINATE decimals apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/-?1\d\d \d/) && ($verbatimLongitude =~ m/^\d\d \d/)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		 
		&log_change("COORDINATE apparently reversed, switching latitude with longitude\t$id");
	}	
	elsif (($verbatimLatitude =~ m/^\d\d\./) && ($verbatimLongitude =~ m/-?1\d\d\./)){
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

}	

#fix some problematic records with bad latitude and longitude in home database

if (($catnum =~ m/^(UCSC8353)$/) && ($longitude =~ m/121\./)){ 
#9428502	UCSC			PreservedSpecimen	802050e1-d75f-4537-8262-682aeb9a95dd	UCSC008353	8353	Plantae	Magnoliophyta		Fabales	Fabaceae	Trifolium monanthum var. monanthum	A. Gray	Trifolium	monanthum	var.	monanthum								Lowell Ahart			11259	2004-07-17	2004	7	17	199		17-Jul-04	On dry soil, near a small stream. Normal size plants, on dry soil. Uncommon, flowers white, mixed evergreen forest.																		United States	California	Nevada		Very upper reaches of Steephollow Creek, about 100 yards west of Highway 20 and Lowell Hill Road, about 2 miles northwest of Bear Valley, about 3 miles southeast of the Omega Rest Area, about 16 air miles northeast of Nevada City				39.306028	-121.714528			T17N, R11E SW 1/4 Section 26						1463					4800 ft			Emily Barnett	2016-05-20 19:58:37		313	urn:uuid:802050e1-d75f-4537-8262-682aeb9a95dd	http://swbiodiversity.org/seinet/collections/individual/index.php?occid=9428502
	$latitude = "39.306028";
	$longitude = "-120.714528";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) in error, maps N of Yuba City in Sutter County, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
	#the original is in error and maps to the Sacramento Valley bioregion, N of Yuba City in Yuba County, causing a yellow flag
}
if (($catnum =~ m/^(UCSC8942)$/) && ($latitude =~ m/36\.0/)){ 
#9429084	UCSC			PreservedSpecimen	f98d3689-4695-4d63-a0ec-deb99ba4d073	UCSC008942	8942	Plantae	Magnoliophyta		Liliales	Liliaceae	Scoliopus bigelovii	Torr.	Scoliopus	bigelovii										Timothy Kang			Kang 013	2015-02-13	2015	2	13	44		13-Feb-15	Plant 19cm tall. On slope with humus, sandy loam soil. In herb layer of grove understory of redwood, Quercus agrifolia, Bay Laurel. Associated species: S. mollis, C. praegracilis, T. ovatum.																		United States	California	Santa Cruz		Santa Cruz, Grove along west side of Empire Grade, near UC Santa Cruz west entrance.				36.059616	-122.124751	WGS84														Plant Systematics			2016-05-20 19:58:37		313	urn:uuid:f98d3689-4695-4d63-a0ec-deb99ba4d073	http://nansh.org/portal/collections/individual/index.php?occid=9429084
#copied from UCSB22607==>36.99480 -122.06922
	$georeferenceSource = "(copied from UCSB22607)";
	$latitude = "36.9948";
	$longitude = "-122.06922";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) in error, maps into the Pacific Ocean, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
	#the original is in error and maps maps into the Pacific Ocean, causing a yellow flag
}




#use combined Lat/Long field format for UCSC

	#convert to decimal degrees
if((length($latitude) >= 2)  && (length($longitude) >= 3)){ 
		if ($latitude =~ m/^(\d\d) +(\d\d?) (\d\d?\.?\d*) */){ #if there are seconds
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
		elsif ($latitude =~ m/^(\d\d) +(\d\d?\.?\d*) */){
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
		elsif ($latitude =~ m/^(\d\d\.\d+)$/){
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
		
		if ($longitude =~ m/^(-?1\d\d) +(\d\d) +(\d\d?\.?\d*).? */){ #if there are seconds
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
		elsif ($longitude =~m /^(-?1\d\d) +(\d\d?\.?\d*) */){
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
		elsif ($longitude =~m /^(-?1\d\d\.\d+)$/){
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
	s/^ $//;
	}	
	

#Error Units
foreach ($coordinateUncertaintyInMeters){
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
}
$errorRadius = $coordinateUncertaintyInMeters;

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
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
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
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;

}


#######Notes and phenology fields species

#free text fields
my $note_string;


foreach ($taxonRemarks,$informationWithheld, $occurrenceRemarks,$dynamicProperties,$establishmentMeans,$locationRemarks){
	s/'$//g;
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;
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
	s/  +/ /g;
	s/^ +//;		
	s/ +$//;	
	s/^ $//;

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



##########################OTHER LABEL NUMBERS
#SKIP for UCSC



			print OUT <<EOP;
Accession_id: $id
Other_label_numbers: $occurrenceID
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
Max_error_distance: $errorRadius
Max_error_units: $errorRadiusUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Physical_environment: $substrate
Phenology: $phenology
Population_biology: $verbatimAttributes
Macromorphology: $taxonRemarks
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


    my $file_in = '/JEPS-master/CCH/Loaders/UCSC/UCSC_out.txt';	#the file this script will act upon is called 'CATA.out'
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

