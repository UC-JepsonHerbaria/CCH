#useful one liners for debugging:
#perl -lne '$a++ if /Accession_id: UCD\d+/; END {print $a+0}' DAV_out.txt
#perl -lne '$a++ if /Other_label_numbers: DAV\d+/; END {print $a+0}' DAV_out.txt
#perl -lne '$a++ if /Other_label_numbers: AHUC\d+/; END {print $a+0}' DAV_out.txt
#perl -lne '$a++ if /Other_label_numbers: POM\d+/; END {print $a+0}' DAV_out.txt
#perl -lne '$a++ if /County: .*/; END {print $a+0}' DAV_out.txt
#perl -lne '$a++ if /Decimal_latitude: \d+/; END {print $a+0}' DAV_out.txt




use Geo::Coordinates::UTM;
use strict;
#use warnings;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.

$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;


my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;
my $det_count;
my $ANNO;
my %ANNO;



my $xml_file = '/JEPS-master/CCH/Loaders/UCD/UCConsortium_14Feb2018/UCConsortium.xml';
my $tab_file= '/JEPS-master/CCH/Loaders/UCD/DAV_xml.txt';
my $dets_file='/JEPS-master/CCH/Loaders/UCD/ANNO_out.txt';

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
#unlink $error_log or warn "making new error log file $error_log";

#save as UTF-8 with UNIX line breaks in Text Wrangler



#place these here instead of after "while(<IN>){" so that they are usable by both the parsing and the correcting stages
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
my $name;
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
my $cult;
my $AnnoRank;
my $NONV_count;
my $NONV_line_store;
my $informationWithheld;
my $h_gen;
my $h_sp1;
my $h_sp2;
my $HerbID;
my $Accession;
my $catalogNumber;
my $Genus;
my $SpecificEpithet;
my $Rank;
my $InfraspecificName;
my $HybridGenus;
my $hybridspp1;
my $hybridspp2;
my $Collector;
my $MoreCollectors;
my $Prefix;
my $Suffix;
my $CollectionNumber;
my $Date;
my $CorrectedDate;
my $GeoPrimaryDivision;
my $GeoSecondaryDivision;
my $GeoTertiaryDivision;
my $TownshipAndRange;
my $Elevation;
my $ElevationUnits;
my $Locality;
my $LatitudeDecimal;
my $LongitudeDecimal;
my $LatitudeDegree;
my $LatitudeMinutes;
my $LatitudeSeconds;
my $LatitudeDirection;
my $LongitudeDegree;
my $LongitudeMinutes;
my $LongitudeSeconds;
my $LongitudeDirection;
my $Datum;
my $LatLongAccuracy;
my $USGSQuadrangle;
my $Ecology;
my $DeterminedBy;
my $UTMZone;
my $easting;
my $nothing;
my $Elevation2;
my $TypeStatus;
my $typeStatus;
my $elevHigh;
my $coordinateUncertainty;
my $elev_units;
my $lat_dir;
my $long_dir;
my $decimal_lat; 	
my $decimal_long;




open(OUT, ">/JEPS-master/CCH/Loaders/UCD/DAV_xml.txt") || die; 

#Stage 1, XML parsing

    open (IN, "<", $xml_file) or die $!;

local $/=qq{<qryUCConsortium>};

Record: while(<IN>){
	chomp;

#fix some data quality and formatting problems that make import of fields of certain records problematic
	#fix some data quality and formatting problems that make import of fields of certain records problematic
	
		s/♂/ male /g;	#CHSC109941 & others: ♀ stems prostrate, ♂ stems erect
		s/♀/ female /g;	#CHSC109941 & others: ♀ stems prostrate, ♂ stems erect
		s/§/Section/; #CHSC114149
		s/€//; #CHSC112018, unknown formatting problem
		s/…/./;	#CHSC45980	
		s/º/ deg. /g;	#CHSC82997 and others, masculine ordinal indicator used as a degree symbol
		s/–/--/g;	#CHSC82527 and others
		s/‘/'/g;
		s/’/'/g;
		s/”/'/g;
		s/“/'/g;
		s/”/'/g;
		s// /g;
		s/±/+-/g;	#CHSC28135 and others
		s/°/ deg. /g;	#CHSC42341 and others, convert degree symbol to deg. abbrev.
		s/¼/ 1\/4 /g;	#CHSC34682 and others
		s/½/ 1\/2 /g;	#CHSC34680 and others
		s/¾/ 3\/4 /g;	#CHSC82639
		s/è/e/;	#CHSC23565
		s/é/e/;	#CHSC52770 and others
		s/ë/e/;	#CHSC35479	Monanthochloë	Boër		
		s/ñ/n/;	#CHSC34617 and others
		s/Č/C/;	#CHSC114355
		
#CHSC is an xml file and these html replacements have been inserted into the text, replacing characters in original data

s/&quot;/'/g; #use single quotes here to no interfere with parsing and cleanup
s/&apos;/'/g;
s/&amp;/ and /g;
s/&lt;/</g;
s/&gt;/>/g;

s/  +/ /g;

########SKIP nonvascular taxa
	if (m/<Division>.*(Myxomycetes|Anthocerotae|Hepaticae|lichens|Musci)/){;
		$NONV_line_store=$_;
		++$NONV_count;
		next;
	}

  #18 <Division>Anthocerotae (hornworts)</Division>
#66797 <Division>Anthophyta (flowering plants)</Division>
 #514 <Division>Coniferophyta (conifers)</Division>
  #39 <Division>Gnetophyta (gnetae)</Division>
 #255 <Division>Hepaticae (liverworts)</Division>
 #177 <Division>Lycophyta (club mosses)</Division>
#1612 <Division>Musci (mosses)</Division>
#7644 <Division>Myxomycetes (slime molds)</Division>
#1209 <Division>Pterophyta (ferns)</Division>
 #149 <Division>Sphenophyta (horsetails)</Division>
 #918 <Division>lichens</Division>

#example file format:
#<Accession>7</Accession>
#<Division>Sphenophyta (horsetails)</Division>
#<CFamily>Equisetaceae</CFamily>
#<CGenus>Equisetum</CGenus>
#<CSpecificEpithet>telmateia</CSpecificEpithet>
#<CRank>ssp.</CRank>
#<CInfraspecificName>braunii</CInfraspecificName>
#<Collector>V. Holt</Collector>
#<Date>1941-04-01T00:00:00</Date>
#<DatePrecision>Month</DatePrecision>
#<GeoPrimaryDivision>United States</GeoPrimaryDivision>
#<GeoSecondaryDivision>California</GeoSecondaryDivision>
#<GeoTertiaryDivision>Marin</GeoTertiaryDivision>
#<LatitudeDegree>38</LatitudeDegree>
#<LatitudeMinutes>7</LatitudeMinutes>
#<LatitudeSeconds>26</LatitudeSeconds>
#<LatitudeDirection>N</LatitudeDirection>
#<LongitudeDegree>122</LongitudeDegree>
#<LongitudeMinutes>48</LongitudeMinutes>
#<LongitudeSeconds>30</LongitudeSeconds>
#<LongitudeDirection>W</LongitudeDirection>
#<LatLongDatum>NAD 1983</LatLongDatum>
#<LatLongAddedCheck>yes</LatLongAddedCheck> #this field no in 2018 data
#<LatLongPrecision>15</LatLongPrecision>
#<LatLongPrecisionUnits>mi.</LatLongPrecisionUnits>
#<AnnoYesNo>1</AnnoYesNo>
#<CDeterminedBy>herbarium</CDeterminedBy>
#<EntryDate>2001-01-23T00:00:00</EntryDate>

#full list of field names, from 'check_xml_fields' script
#Accession
#Authority
#CollectionNumber
#Collector
#CorrectedDate
#dataroot
#Date
#Datum
#DeterminedBy
#easting
#Ecology
#Elevation
#Elevation2
#ElevationUnits
#Genus
#GeoPrimaryDivision
#GeoSecondaryDivision
#GeoTertiaryDivision
#HerbID
#HybridAuthor1
#HybridAuthor2
#HybridGenus
#hybridspp1
#hybridspp2
#InfraspecificAuthority
#InfraspecificName
#LatitudeDecimal
#LatitudeDegree
#LatitudeDirection
#LatitudeMinutes
#LatitudeSeconds
#LatLongAccuracy
#LatLongDatum
#Locality
#LongitudeDecimal
#LongitudeDegree
#LongitudeDirection
#LongitudeMinutes
#LongitudeSeconds
#MoreCollectors
#northing
#Prefix
#Rank
#SpecificEpithet
#Suffix
#TownshipAndRange
#TypeStatus
#USGSQuadrangle
#USGSQuadrangleScale
#UTMZone



#lines not parsed
#HybridAuthor1
#HybridAuthor2
#InfraspecificAuthority
#Authority
#dataroot
#<DatePrecision>Day</DatePrecision>
#<AccessionDate>2015-04-01T00:00:00</AccessionDate>
#<EntryDate>2015-04-01T00:00:00</EntryDate>
#<Division>Anthophyta (flowering plants)</Division>
#<CFamily>Plantaginaceae</CFamily>
#<USGSQuadrangleScale>5100</USGSQuadrangleScale>


#These tags have dedicated "&get" subroutines"
	$HerbID= &get_id($_);
	$Accession= &get_accession($_);
	$Genus=&get_genus($_);
	$SpecificEpithet=&get_species($_);
	$Rank=&get_rank($_);
	$InfraspecificName=&get_subtaxon($_);
	$HybridGenus=&get_hybridgenus($_);
	$hybridspp1=&get_hybrid_epithet($_);
	$hybridspp2=&get_hybrid_epithet2($_);
	$Collector=&get_collector($_);
	$MoreCollectors=&get_other_coll($_);
	$Prefix=&get_prefix($_);
	$Suffix=&get_suffix($_);
	$CollectionNumber=&get_recordNumber($_);
	$Date=&get_verbatim_eventDate($_);
	$CorrectedDate=&get_eventDate($_);
	$GeoPrimaryDivision=&get_country($_);
	$GeoSecondaryDivision=&get_stateProvince($_);
	$GeoTertiaryDivision=&get_county($_);
	$TownshipAndRange=&get_TRS($_);
	$Elevation=&get_elevation($_);
	$ElevationUnits=&get_elev_units($_);
	$Locality=&get_locality($_);
	$LatitudeDecimal=&get_lat_dec($_);
	$LongitudeDecimal=&get_long_dec($_);
	$LatitudeDegree=&get_lat_degrees($_);
	$LatitudeMinutes=&get_lat_minutes($_);
	$LatitudeSeconds=&get_lat_seconds($_);
	$LatitudeDirection=&get_lat_dir($_);
	$LongitudeDegree=&get_long_degrees($_);
	$LongitudeMinutes=&get_long_minutes($_);
	$LongitudeSeconds=&get_long_seconds($_);
	$LongitudeDirection=&get_long_dir($_);
	$Datum=&get_datum($_);
	$LatLongAccuracy=&get_coordinateUncertainty($_);
	$USGSQuadrangle=&get_topo_quad($_);
	$Ecology=&get_habitat($_);
	$DeterminedBy=&get_identifiedBy($_);

	#$dateIdentified=&get_dateIdentified($_);#this field not in 2018 data
	#$other=&get_other($_);#this field not in 2018 data
	#$AnnoYesNo=&get_AnnoRank($_);#this field not in 2018 data
	#$LatLongAdded=&get_LatLongAdded($_);#this field not in 2018 data$
	#$errorRadius=&get_errorRadius($_);#this field not in 2018 data$	
	#$errorRadiusUnits=&get_errorRadiusUnits($_);#this field not in 2018 data$

	#new for 2018
	$UTMZone=&get_zone($_);
	$easting=&get_UTME($_);
	$nothing=&get_UTMN($_);
	$Elevation2=&get_elevationHigh($_);
	$TypeStatus=&get_typeStatus($_);
	
print OUT join("\t", "N", $HerbID, $Accession, $Genus, $SpecificEpithet, $Rank, $InfraspecificName, $HybridGenus, $hybridspp1, $hybridspp2, $Collector, $MoreCollectors, $CollectionNumber, $Prefix, $Suffix, $Date, $CorrectedDate, $GeoPrimaryDivision, $GeoSecondaryDivision, $GeoTertiaryDivision, $TownshipAndRange, $Elevation, $Elevation2, $ElevationUnits, $Locality, $Ecology, $LatitudeDecimal, $LongitudeDecimal, $LatitudeDegree, $LatitudeMinutes, $LatitudeSeconds, $LatitudeDirection, $LongitudeDegree, $LongitudeMinutes, $LongitudeSeconds, $LongitudeDirection, $Datum, $LatLongAccuracy, $UTMZone, $easting, $nothing, $USGSQuadrangle, $TypeStatus, $DeterminedBy), "\n";
}
close(OUT);


#die;
#Stage 2, Normal data loading and flat file creation
#############ANNOTATIONS

###process the determinations
#Note that the file might have Windows line breaks
open (IN, "<", $dets_file) or die $!;

local $/="\n";

while(<IN>){

my $det_AID;
my $det_rank;
my $det_family;
my $det_name;
my $det_determiner;
my $det_identificationRemarks;
my $det_year;
my $det_month;
my $det_day;
my $det_stet;
my $det_date;
my $det_string="";
#unique to this dataset



	chomp;
#Field List 2016

#fix some data quality and formatting problems that make import of fields of certain records problematic

	
	#fix some data quality and formatting problems that make import of fields of certain records problematic


#see also the &correct_format 'foreach' statement below	for more formatting corrections	


	$line_store=$_;
	++$det_count;		
		
	#&CCH::check_file;
#		s/\cK/ /g;
#        if ($. == 1){#activate if need to skip header lines
#			next;
#		}

my @fields=split(/\t/,$_,100);
	unless($#fields==2){ #3 fields but first field is field 0 in perl
		&log_skip("$#fields bad field number $_\n");
		++$skipped{one};
		next Record;
	}


#then process the full records
(
$det_AID,
$det_rank, 
$det_name 
)=@fields;

#$anno_id\t$anno_orig_det\t$det_string\n";






#format det_string correctly
	if (length($det_name) >=1){
		$det_string="$det_rank: $det_name";
	}
	else {
		$det_string="";
	}

foreach ($det_string){
	s/NULL//g;
	s/'$//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;

}


$ANNO{"$det_AID"}.="Annotation: $det_string\n"; #for $ANNO for each "$id", print the following into and a new line. ".=" Means accumulate entries, if there are multiple ANNOs per $id
}
close(IN);





	open(OUT, ">UCD_out.txt") || die;
	
	 
    open (IN, "<", $tab_file) or die $!;
    
local $/="\n";

Record: while(<IN>){
	chomp;

#fix some data quality and formatting problems that make import of fields of certain records problematic
	s///g; #x{0B} hidden character
	s/±/+-/g;
	s/ñ/n/g;
	s/º/ deg. /g;
	s/°/ deg. /g;
	s/˚/ deg. /g;
	s/¼/1\/4/g;
	s/ö/o/g;
	s/ú/u/g;
	s/í/i/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ä/a/g;
	s/á/a/g;
	s/à/a/g;	#U+00E0	à	\xc3\xa0
	s/ü/u/g;	#U+00F6	ö	\xc3\xb6
	s/ó/o/g;
	s/ [xX×] / X /;
	s/×/X /;	#change  " x " in genus name to the multiplication sign
#mismatched conversion errors
	s/÷/ /g;
	s/®/ /g;
	s/≈/ /g;
	s/¡/ deg. /g;
#skipping: problem character detected: s/\xc2\xa1/    /g   ¡ ---> 30¡	
#skipping: problem character detected: s/\xc2\xae/    /g   ® ---> ®,.	
#skipping: problem character detected: s/\xc3\x97/    /g   × ---> ×hispanica	×Pseudelymus	×Agropogon	×bloomeri	×acutidens	×saundersii	×occidentalis	×gracilis	×rotundifolia	×smithiana	×elata	×crocosmiiflora	×ferrissii	×chasei	×piperita	
#skipping: problem character detected: s/\xc3\xa0/    /g   à ---> Sànchez-Mata	Sànchez-Mata,	
#skipping: problem character detected: s/\xc3\xa1/    /g   á ---> András	Andrásfalvy	González	González,	Jáuregui	Rejmánek	
#skipping: problem character detected: s/\xc3\xa9/    /g   é ---> Café.	Relevé	
#skipping: problem character detected: s/\xc3\xad/    /g   í ---> Alegría	
#skipping: problem character detected: s/\xc3\xb1/    /g   ñ ---> Cañon,	piñon-juniper	Cañon	
#skipping: problem character detected: s/\xc3\xb3/    /g   ó ---> Bayón	Bayón,	Ordónez	Sissón.	Hanlyó,	
#skipping: problem character detected: s/\xc3\xb6/    /g   ö ---> Hölzer	Stöhr	
#skipping: problem character detected: s/\xc3\xb7/    /g   ÷ ---> ÷1	
#skipping: problem character detected: s/\xc3\xba/    /g   ú ---> Ivalú	
#skipping: problem character detected: s/\xc3\xbc/    /g   ü ---> Kühne,	
#skipping: problem character detected: s/\xcb\x9a/    /g   ˚ ---> 5˚.	
#skipping: problem character detected: s/\xe2\x89\x88/    /g   ≈ ---> ≈2.5	≈	trunk≈5	(≈8	≈0.1

	$line_store=$_;
	++$count;		
		
	#&CCH::check_file;
#		s/\cK/ /g;
#        if ($. == 1){#activate if need to skip header lines
#			next;
#		}

my @fields=split(/\t/,$_,100);
	unless($#fields==43){ #44 fields but first field is field 0 in perl
		&log_skip("$#fields bad field number $_\n");
		++$skipped{one};
		next Record;
	}



#N	13099	DAV170544	Marah	fabaceus	NULL	NULL	NULL	NULL	NULL	R. Fernau	NULL	38	NULL	NULL	22 Apr 1974	1974-04-22T00:00:00	United States	California	Yolo County	NULL	NULL	NULL	NULL	
#CALIFORNIA: YOLO COUNTY Under Rd. 98 bridge along Putah Creek twisted around base of a cottonwood tree. Elevation 50'.	Riparian woodland. near cottonwood, oak and grasses. Sandy loam soil. Vine, 4 ft. high. Scattered locally. Shaded.	
#38.526667	-121.803611	38	31	36	N	121	48	13	W	WGS84	NULL	NULL	NULL	NULL	NULL	NULL	NULL

#then process the full records
(
$cultivated,
$id,
$catalogNumber,
$genus,
$species,
$rank,
$subtaxon,
$h_gen,
$h_sp1,
$h_sp2,  #10
$collector,
$other_collectors,
$recordNumber,	
$CNUM_prefix,
$CNUM_suffix,
$verbatimEventDate,  
$eventDate,
$country, 
$stateProvince,
$tempCounty,  #20
$TRS,
$elevation,
$elevHigh,
$elev_units,
$locality,
$habitat, 
$decimal_lat, 	
$decimal_long,
$lat_degrees,	
$lat_minutes,	#30
$lat_seconds, 
$lat_dir,  
$long_degrees,
$long_minutes,
$long_seconds,
$long_dir, 
$datum,	
$coordinateUncertainty,	
$zone, 
$UTME, #40
$UTMN,
$topo_quad,    
$typeStatus,  
$identifiedBy  #44
)=@fields;


################ACCESSION_ID#############

#check for nulls
if ($id=~/^[ NULL]*$/){
	&log_skip("ACC: Record with no record id $_");
	++$skipped{one};
	next Record;
}

#remove any white space
foreach($id){
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}

#Add prefix to unique identifier field, 
$id="UCD$id";

#Remove duplicates
if($seen{$id}++){
	warn "Duplicate number: $id<\n";
	&log_skip("ACC: Duplicate accession number, skipped\t$id");
	++$skipped{one};
	next Record;
}



foreach ($catalogNumber){
	s/NULL//;
	s/'$//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;

}

##################Exclude known problematic specimens by id numbers, most from outside California and Baja California
 if ($id =~ m/^(UCD98097|UCD86865|UCD87290)$/){
	#print ("excluded problem record or record known to be not from California\t$locality\t--\t$catalogNumber");
		++$skipped{one};
		next Record;
	}


##########Begin validation of scientific names

#####Annotations
	#format det_string correctly
my $det_rank = "current determination (uncorrected)";  
my $det_name = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;
my $det_determiner = $identifiedBy;

	foreach ($det_name){
	s/NULL//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	}

	foreach ($det_determiner){
	s/NULL//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	}

	if ((length($det_name) > 1) && (length($det_determiner) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0)){
		$det_string="";
	}
	else{
		&log_change("DET Bad string==>RANK:$det_rank  NAME:$det_name  DET:$det_determiner");
		$det_string="";
	}

##############SCIENTIFIC NAME
#Format name parts

#construct full verbatim name
	foreach ($genus){
		s/NULL//g;
		s/^×/X /;
		s/^ +//g;
		s/ +$//g;
	}	
	foreach ($species){
		s/NULL//g;
		s/^ +//g;
		s/ +$//g;
	}	
	foreach ($rank){
		s/NULL//g;
		s/^ +//g;
		s/ +$//g;
	}	
	foreach ($subtaxon){
		s/NULL//g;
		s/^ +//g;
		s/ +$//g;
	}


	foreach ($h_gen){
		s/NULL//g;
		s/^×/X /;
		s/^ +//g;
		s/ +$//g;
	}	
	foreach ($h_sp1){
		s/NULL//g;
		s/^ +//g;
		s/ +$//g;
	}	
	foreach ($h_sp2){
		s/NULL//g;
		s/^ +//g;
		s/ +$//g;
	}	

$h_gen,
$h_sp1,
$h_sp2,

my $tempName = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;

my $hybridName;
	if ((length($h_gen) > 1) && (length($h_sp1) > 1) && (length($h_sp2) == 0)){
		$hybridName = $h_gen ." X " .  $h_sp1;
	}
	elsif ((length($h_gen) > 1) && (length($h_sp1) > 1) && (length($h_sp2) > 1)){
		$hybridName = $h_gen ." " .  $h_sp1 . " X ".  $h_gen . " ".  $h_sp2;
	}
	elsif ((length($h_gen) == 0) && (length($h_sp1) == 0) && (length($h_sp2) == 0)){
		$hybridName="";
	}
	else{
		&log_change("DET Bad hybrid string==>HGEN:$h_gen  NAME1:$h_sp1  NAME2:$h_sp2");
		$hybridName="";
	}





#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($tempName){
	s/NULL/ /gi;
	s/[uU]nknown/ /g; #added to try to remove the word "unknown" for some records
	s/;/ /g;
	s/cf./ /g;
	s/ [xX××] / X /;	#change  " x " or " X " to the multiplication sign
	s/× /X /;	#change  " x " in genus name to the multiplication sign
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}

	if ((length($hybridName) > 1) && (length($tempName) > 1)){
		$tempName= $hybridName;
		#print "hybrid name found==>$tempName\n";
	} 
	elsif ((length($hybridName) > 1) && (length($tempName) == 0)){	
		$tempName= $hybridName;
	}
	else{
		$hybridName = "";
		#use tempName
	}
	
#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published

if (($id =~ m/^(UCD94426)$/) && (length($TID{$tempName}) == 0)){ 
#<HerbID>94426</HerbID><Genus>Vahlodea</Genus><SpecificEpithet>(Wahlemb.) Hartm.</SpecificEpithet>
	$tempName =~ s/Vahlodea \(.+/Vahlodea atropurpurea/; #fix special case
	&log_change("TAXON Scientific name error: the authority,(Wahlemb.) Hartm., is entered into species field, modified to current annotation==>$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD53325|UCD53454|UCD53460)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Arctostaphylos</Genus><Rank>ssp.</Rank><InfraspecificName>elegans</InfraspecificName><InfraspecificAuthority>(Jepson) P. Wells</InfraspecificAuthority>
	$tempName =~ s/Arctostaphylos ssp\. elegans/Arctostaphylos manzanita subsp. elegans/; #fix special case
	&log_change("TAXON Scientific name error: species NULL, name from Annotation table==> the authority,(Jepson) P. Wells, is for A. manzanita subsp. elegans,  modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD50661)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Arctostaphylos</Genus><Rank>ssp.</Rank><InfraspecificName>laevigata</InfraspecificName><InfraspecificAuthority>(Eastw.)  Roof</InfraspecificAuthority>
	$tempName =~ s/Arctostaphylos ssp\. laevigata/Arctostaphylos pungens subsp. laevigata/; #fix special case
	&log_change("TAXON Scientific name error: species NULL, name from Annotation table==>the authority,(Eastw.) Roof, is for A. pungens subsp. laevigata,  modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD45158|UCD45181|UCD45183|UCD45194|UCD45195)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Quercus</Genus><SpecificEpithet>Xalvordiana</SpecificEpithet><Authority>Eastwood (pro. sp.)</Authority><Rank>ssp.</Rank><InfraspecificName>californica</InfraspecificName><InfraspecificAuthority>Tucker</InfraspecificAuthority>
	$tempName =~ s/Quercus [Xx] ?alvordiana ssp\. californica/Quercus turbinella subsp. californica/; #fix special case
	&log_change("TAXON Scientific name not published: Quercus xalvordiana ssp. californica, species name not updated to new, modified to current annotation\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD46771|UCD46779|UCD46783)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Quercus</Genus><Rank>var.</Rank><InfraspecificName>breweri</InfraspecificName>
	$tempName =~ s/Quercus [Xx] ?kinselae var\. kinselae/Quercus dumosa var. kinseliae/; #fix special case
	&log_change("TAXON Scientific name not published: Quercus xkinselae var. kinselae, species from old annotation not updated to new, modified to current annotation\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD45654)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Quercus</Genus><Rank>var.</Rank><InfraspecificName>breweri</InfraspecificName>
	$tempName =~ s/Quercus var\. breweri/Quercus lobata/; #fix special case
	&log_change("TAXON Scientific name error: species NULL, comb. for var. breweri is in Q. garrayana, modified to current annotation==> $tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD46153)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Quercus</Genus><Rank>var.</Rank><InfraspecificName>breweri</InfraspecificName>
	$tempName =~ s/Quercus var\. breweri/Quercus garryana X sadleriana/; #fix special case
	&log_change("TAXON Scientific name error: species NULL, erroneous data added to subtaxon name that is not in annotation table, modified to current annotation\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD46184)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Quercus</Genus><Rank>var.</Rank><InfraspecificName>breweri</InfraspecificName>
	$tempName =~ s/^Quercus var\. breweri$/Quercus garryana X dumosa/; #fix special case
	&log_change("TAXON Scientific name error: species NULL, name in annotation table is an error, Q. dumosa var. breweri, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD150428)$/) && (length($TID{$tempName}) == 0)){ 
#<SpecificEpithet>filipes</SpecificEpithet><Authority>A. Gray</Authority>
	$tempName =~ s/^filipes/Astragalus filipes$/; #fix special case
	&log_change("TAXON Scientific name error:  Genus NULL, modified to current annotation $tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD36842|UCD58527|UCD58528|UCD58529|UCD58530|UCD59305|UCD59453|UCD59454|UCD59460|UCD59461|UCD59462|UCD59467|UCD59473|UCD59479|UCD59480|UCD59486|UCD59487|UCD59488|UCD59498)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Bromus</Genus><SpecificEpithet>diandrus</SpecificEpithet><Authority>Roth</Authority><Rank>var.</Rank><InfraspecificName>gussonei</InfraspecificName><InfraspecificAuthority>(Parl.) Cross &amp; Durieu</InfraspecificAuthority>
	$tempName =~ s/^Bromus diandrus var\. gussonei$/Bromus diandrus/; #fix special case
	&log_change("TAXON Scientific name not published: old name Bromus rigidus var. gussonei, not completely delted from main table, modified to current annotation $tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD52182|UCD53552|UCD53553|UCD53554|UCD53555|UCD53556|UCD53557|UCD53558|UCD53560|UCD53561|UCD53562|UCD53563|UCD53564|UCD53565|UCD53566|UCD53567|UCD53568|UCD53569|UCD53570|UCD53572|UCD53573)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Bromus</Genus><SpecificEpithet>diandrus</SpecificEpithet><Authority>Roth</Authority><Rank>var.</Rank><InfraspecificName>gussonei</InfraspecificName><InfraspecificAuthority>(Parl.) Cross &amp; Durieu</InfraspecificAuthority>
	$tempName =~ s/^Arctostaphylos viridissima var\. viridissima$/Arctostaphylos viridissima/; #fix special case
	&log_change("TAXON Scientific name not published: previous subtaxon name Arctostaphylos pechoensis var. viridissima, not completely delted from main table, modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD50660|UCD50662|UCD51074)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Arctostaphylos</Genus><Rank>form.</Rank><InfraspecificName>cushingiana</InfraspecificName><InfraspecificAuthority>(Eastw.) P. Wells</InfraspecificAuthority>
	$tempName =~ s/^Arctostaphylos form\. cushingiana$/Arctostaphylos glandulosa f. cushingiana X Arctostaphylos tracyi/; #fix special case
	&log_change("TAXON Scientific name error: hybrid species name missing, name not published and likely an error, modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD123500)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Callitriche</Genus><SpecificEpithet>Pursh</SpecificEpithet>
	$tempName =~ s/^[Cc]allitriche [pP]ursh$/Callitriche heterophylla/; #fix special case
	&log_change("TAXON Scientific name error: Authority 'Pursh' entered as species name, modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD37961|UCD49887|UCD49893|UCD49894|UCD49895|UCD49896|UCD49897|UCD49898|UCD49900|UCD49903)$/) && (length($TID{$tempName}) == 0)){ 
#<Genus>Isolepis</Genus><SpecificEpithet>cernua</SpecificEpithet><Authority>(Vahl) Roem. &amp; Schult.</Authority><Rank>var.</Rank><InfraspecificName>californicus</InfraspecificName><InfraspecificAuthority>(Torrey) Beetle</InfraspecificAuthority>
	$tempName =~ s/^Isolepis cernua var\. californicus$/Isolepis cernua/; #fix special case
	&log_change("TAXON Scientific name not published: Isolepis cernua var. californicus not a published var. comb., modified to==>$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD101506)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/^Eriogonum var\. torreyanum$/Eriogonum umbellatum var. torreyanum/; #fix special case
	&log_change("TAXON Scientific name error: species name NULL, modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD37696|UCD37432|UCD37436|UCD37437|UCD37692)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/^Agrostis densiflora var\. punta-reyensis$/Agrostis densiflora/; #fix special case
	&log_change("TAXON Scientific name not published: Agrostis densiflora var. punta-reyensis, variety name from old annotation not deleted, modified to==> $tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD37146|UCD37147|UCD52009|UCD52010|UCD52011|UCD52012|UCD52013|UCD52014|UCD52016|UCD52017|UCD52018)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/^Agrostis densiflora var\. punta-reyesensis$/Agrostis densiflora/; #fix special case
	&log_change("TAXON Scientific name not published: Agrostis densiflora var. punta-reyesensis, variety name from old annotation not deleted, modified to==> $tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD37118|UCD57535|UCD57536|UCD57537)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/^Calamagrostis ophitidis var\. ophitidis$/Calamagrostis ophitidis/; #fix special case
	&log_change("TAXON Scientific name not published: Calamagrostis ophitidis var. ophitidis, variety name from old annotation not deleted, modified to==> $tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD53798)$/) && (length($TID{$tempName}) == 0)){ 
#<HerbID>53798</HerbID><Genus>Arctostaphylos</Genus><SpecificEpithet>pungens</SpecificEpithet><Authority>H.B.K.</Authority><Rank>ssp.</Rank><InfraspecificName>ranvenii</InfraspecificName>
	$tempName =~ s/^Arctostaphylos pungens ssp\. ranvenii$/Arctostaphylos hookeri subsp. ravenii/; #fix special case
	&log_change("TAXON Scientific name error: subtaxon mispelled and Scientific name not published Arctostaphylos pungens ssp. ravenii, modified to basionym at the subsp level==> $tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD50810|UCD53797)$/) && (length($TID{$tempName}) == 0)){ 
#<HerbID>50810</HerbID><Genus>Arctostaphylos</Genus><SpecificEpithet>pungens</SpecificEpithet><Authority>H.B.K.</Authority><Rank>ssp.</Rank><InfraspecificName>ravenii</InfraspecificName>
	$tempName =~ s/^Arctostaphylos pungens ssp\. ravenii$/Arctostaphylos hookeri subsp. ravenii/; #fix special case
	&log_change("TAXON Scientific name error: Scientific name not published Arctostaphylos pungens ssp. ravenii, modified to basionym at the subsp level==> $tempName\t--\t$id\n");
}
if (($id =~ m/^(UCD73114)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/^Wyethia heterophyllum$/Wyethia helenioides/; #fix special case
	&log_change("TAXON Scientific name error: species nme passed down from previous record,  Wyethia heterophyllum not published name, modified to nme on duplicate UCD72445==> $tempName\t--\t$id\n");
}






#format hybrid names
if($tempName =~ m/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation = $tempName;
	#warn "Hybrid Taxon: $1 removed from $tempName\n";
	&log_change("Scientific name - HYBRID: $1 removed from $tempName");
	$tempName = $1;
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
			&log_change("CULT: specimen likely not cultivated, purple flagging skipped\t$scientificName\t--\t$id\n");
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($occurrenceRemarks =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental\.|ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("CULT: Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName=>$id\r$locality\n");
		}
		else {		
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName=>$id\r$locality\n");
			}
			else {
			#&log_change("Taxon skipped purple flagging (1) $cultivated\t--\t$scientificName\n");
			$cultivated = "";
			}
		}
	}
	else {
		&log_change("CULT: Taxon flagged as cultivated in original database: $cultivated\t--\t$scientificName==>$id\r$locality\n");
	}



##########COLLECTION DATE##########

my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;
my $eventDateAlt;

#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#verbatim date for dwc verbatimEventDate and CCH "Date"
#<Date>2004-05-24T00:00:00</Date> CHSC format

	foreach ($verbatimEventDate){
	s/NULL//g;
	#s/Apr 2997/Apr 1997/;
	s/  +/ /g;
	s/ +$//g;
	s/^ +//g;
	}	

	foreach ($eventDate){
	s/NULL//g;
	s/  +/ /g;
	s/ +$//g;
	s/^ +//g;
	}


#find what fields have a date value, choose one and add to $eventDateAlt
	if((length($eventDate) > 1) && (length($verbatimEventDate) > 1)){
		$eventDateAlt = $eventDate;
		&log_change("Date (1): eventDate selected for\t$id\n");
		}
	elsif((length($eventDate) > 1) && (length($verbatimEventDate) == 0)){
		$eventDateAlt = $eventDate;
		&log_change("Date (2): eventDate selected for\t$id\n");
		}
	elsif((length($eventDate) == 0) && (length($verbatimEventDate) > 1)){
		$eventDateAlt = $verbatimEventDate;
		&log_change("Date (3): alternate fields empty, verbatimEventDate selected for\t$id\n");
		}
	elsif((length($eventDate) == 0) && (length($verbatimEventDate) == 0)){
		$verbatimEventDate = $eventDateAlt = "";
		&log_change("Date NULL: all date fields without data\t$id\n");
		}
	else{
		&log_change("Date problem, cannot process: ($eventDate)\t($verbatimEventDate)\t$id\n");
		$eventDateAlt="";
	}


#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#$coll_month, #three letter month name: Jan, Feb, Mar etc.
#$coll_day,
#$coll_year,
#verbatim date for dwc verbatimEventDate and CCH "Date"
	foreach ($eventDateAlt){
	s/[Date ]*[ Unkow]+//i;
	s/no date//i;
	s/Early //i;
	s/^ca //i;
	s/NULL//g;
	s/T[0:]+$//g;
	s/\?/ /g;
	s/\(/ /g;
	s/\)/ /g;
	s/ and /-/g;
	s/\//-/g;
	s/-+/-/g;
	s/&/-/g;
	s/,/ /g;
	s/\./ /g;
	s/ ?- ?/-/g;
	s/([A-Z][a-z]+)(19\d\d)/$1 $2/; #May1980
	s/^(\d+)([A-Z][a-z]+)/$1 $2/; #21Jul
	s/2997-04/1997-04/;
	s/  +/ /g;
	s/ +$//g;
	s/^ +//g;

	}	


#Fix some problem dates first
	if($eventDateAlt=~/^(Feb|May|Jul|Nov)[- ](Apr|Aug|Dec|Oct|Sep)[- ]([0-9]{4})/){	#if eventDate is in the format Feb-Apr ####,Jul-Aug ####,May-Aug ####,May-Oct ####,Nov-Dec ####
		$YYYY=$3; 
		$MM=$1; 
		$DD= "1";
		$MM2 = $2;
		$DD2 = "30";
	warn "Date (00-1)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([Mm[iI][dD])[- ]?([A-Z][a-z]+)[- ]([0-9]{4})/) {#if eventDate is in the format mid-Aug 2008
		$YYYY = $4;
		$MM = $2;
		$DD = "10";
		$MM2 = $2;
		$DD2 = "20";
	warn "Date (00-2)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^(Apr|Jun)[- ](\d+)[- ](Sep|Jul)[- ]([0-9]{4})/){	#if eventDate is in the format Jun-5 Jul 1903, Apr-15 Sep 1949
		$YYYY=$4; 
		$MM=$1; 
		$DD= 1;
		$MM2 = $3;
		$DD2 = $2;
	warn "Date (00-3)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^(\d+)[- ](Apr|Jun)[- ](\d+)[- ](Sep|Jul)[- ]([0-9]{4})/){	#if eventDate is in the format 29Jun-11Jul1912
		$YYYY=$5; 
		$MM=$2; 
		$DD= $1;
		$MM2 = $4;
		$DD2 = $3;
	warn "Date (00-4)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^(\d+)[- ]([A-Z])[- ]([a-z]+)[- ]([0-9]{4})/){	#if eventDate is in the format 5 J un 1957
		$YYYY=$4; 
		$MM = "$2$3"; 
		$DD= $1;
		$MM2 = "";
		$DD2 = "";
	warn "Date (00-5)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{4})$/){	#if eventDate is in the format 1957
		$YYYY=$1; 
		$MM = "Jan"; 
		$DD= "1";
		$MM2 = "Dec";
		$DD2 = "30";
	warn "Date (00-6)$eventDateAlt\t$id";
	}
#then run the rest of the normal processing
	elsif($eventDateAlt=~/^([0-9]{4})[- ](\d\d)[- ](\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "Date (1)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^(\d\d)[- ](\d\d)[- ]([0-9]{4})/){	#added to SDSU, if eventDate is in the format ##-##-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "Date (2)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{1})[- ]([0-9]{1,2})[- ]([0-9]{4})/){	#added to SDSU, if eventDate is in the format #-##?-####, most appear that first # is month 
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "Date (3)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([Ss][pP][rR][ing]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	#warn "Date (14)$eventDateAlt\t$id";
	}	
	elsif ($eventDateAlt=~/^([Ss][uU][Mm][mer]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "6";
		$DD = "1";
		$MM2 = "8";
		$DD2 = "31";
	#warn "Date (16)$eventDateAlt\t$id";
	}	
	elsif ($eventDateAlt=~/^([fF][Aa][lL]+)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$DD = "1";
		$MM = "9";
		$DD2 = "30";
		$MM2 = "11";
	#warn "Date (12)$eventDateAlt\t$id";
	}	
	elsif ($eventDateAlt=~/^([0-9]{1,2})[- ]([A-Za-z]+)[- ]([0-9]{4})/){
		$DD=$1;
		$MM=$2;
		$YYYY=$3;
		$MM2 = "";
		$DD2 = "";
	#warn "(2)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]([0-9]{1,2})[- ]([0-9]{4})/){#added to DAV 
		$DD=$2;
		$MM=$1;
		$YYYY=$3;
		$MM2 = "";
		$DD2 = "";
	#warn "(2b)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{1,2})[- ]([A-Za-z]+)([0-9]{4})/){
		$DD=$1;
		$MM=$2;
		$YYYY=$3;
		$MM2 = "";
		$DD2 = "";
	warn "(2c)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{1,2})[- ]+([0-9]{1,2})[- ]+([A-Z][a-z]+)[- ]([0-9]{4})/){
		$DD=$1;
		$DD2=$2;
		$MM=$3;
		$MM2=$3;
		$YYYY=$4;
	#warn "(4)$eventDateAlt\t$id";
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
	#warn "Date (8): $eventDateAlt\t$id";
	}
		elsif ($eventDateAlt=~/^([A-Z][a-z]+)[- ](July?)[- ]([0-9]{4})$/){ #month, year, no day, added to DAV
		$YYYY = $3;
		$DD = "1";
		$MM = $1;
		$DD2 = "31";
		$MM2 = $2;
	#warn "Date (8b): $eventDateAlt\t$id";
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
	#warn "Date (10): $eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([fF][Aa][lL]+)/) {
		$YYYY = $1;
		$DD = "1";
		$MM = "9";
		$DD2 = "30";
		$MM2 = "11";
	warn "Date (11)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (13)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (15)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]([0-9]{4})$/){
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
	warn "Date (20)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([Ss][uU][Mm][mer]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (17)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]*$/){
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
		$MM="";
	#warn "Date (18)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([0-9]{1,2})[- ]*$/){
		$MM=$2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
	#warn "Date (19)$eventDateAlt\t$id";
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

#fix some special julian date ranges that cannot be parsed
#logging: Date: date format not recognized: Jul 1926-1928==>(Jul 1926/1928)	UCD94017
#logging: Date: date format not recognized: Winter1919-1920==>(Winter1919-1920)	UCD56043
#logging: Date: date format not recognized: 1995-1996==>(1995-1996)	UCD80847
#logging: Date: date format not recognized: 1995-1996==>(1995-1996)	UCD80855
#logging: Date: date format not recognized: 1959-1960==>(1959-1960)	UCD73856
#logging: Date: date format not recognized: 1970'==>(1970's)	UCD20285
	if ($eventDateAlt=~ m/^Jul 1926-1928/){
		$EJD = "2424697";
		$LJD = "2425457";
	}
	elsif ($eventDateAlt=~ m/^Winter1919-1920/){
		$EJD = "2422263";
		$LJD = "2422382";
	}
	elsif ($eventDateAlt=~ m/^1995-1996/){
		$EJD = "2449718";
		$LJD = "2450447";
	}
	elsif ($eventDateAlt=~ m/^1959-1960/){
		$EJD = "2436569";
		$LJD = "2437298";
	}
	elsif ($eventDateAlt=~ m/^1970\'s/){
		$EJD = "2440587";
		$LJD = "2444237";
	}

###############COLLECTORS

	foreach ($collector){
		s/NULL//g;
		s/'$//g;
		s/, M\. ?D\.//g;
		s/, Jr\./ Jr./g;
		s/, Jr/ Jr./g;
		s/, Esq./ Esq./g;
		s/, Sr\./ Sr./g;
		s/5.29.2015/Richard R. Halse/; #CHSC113816
		s/\(label illegible\)/Unknown/;
		s/^ +//;
		s/ +$//;
		s/  +/ /g;
	}

	foreach ($other_collectors){
		s/NULL//g;
		s/, Jr\./ Jr./g;
		s/, Jr/ Jr./g;
		s/, Esq./ Esq./g;
		s/, Sr\./ Sr./g;
		s/^ +//;
		s/ +$//;
		s/  +/ /g;
	}

$collectors = "";
$other_coll = "";
$recordedBy = "";
$verbatimCollectors = "";

#test records
if ($collector =~ m/ Dean/){
	&log_change("COLLECTOR: Ellen Dean specimens for checking:\t$collector\t$county\t$scientificName\t$id\n");
}

#continue parsing
if ((length($collector) == 0) && (length($other_collectors) == 0)){
	$recordedBy = "";
	$other_collectors = "";
	$verbatimCollectors = "";
	&log_change("COLLECTOR: Collector name and Other Collector fields missing, changed to NULL\t$id\n");
}
elsif ((length($collector) == 0) && (length($other_collectors) > 1)){
	$collectors = $other_collectors;
	$recordedBy = &CCH::validate_collectors($collectors, $id);
	$verbatimCollectors = "$other_collectors";
	&log_change("COLLECTOR: Collector name field missing, using other collector field\t$id\n");
}
elsif ((length($collector) > 1) && (length($other_collectors) == 0)){
		if ($collector =~ m/(;|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
			my $other_coll=$2;
			$other_collectors = $other_coll;
			$collectors = $collector;
			$recordedBy = &CCH::validate_collectors($collectors, $id);	
		#D Atwood; K Thorne
			$verbatimCollectors = "$collectors";
			warn "Names 5: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_collectors\n";
			&log_change("COLLECTOR (5b): modified: $verbatimCollectors==>($collector)\t($recordedBy\)\t($other_collectors)\t$id\n");		
		}
		else{
			$collectors = $collector;
			$recordedBy = &CCH::validate_collectors($collectors, $id);
			$verbatimCollectors = "$collector";
			$other_collectors = "";
			#warn "Names 6: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_collectors\n";			
			&log_change("COLLECTOR: Other Collector field missing, using only Collector\t$id\n");
		}
}
elsif ((length($collector) > 1) && (length($other_collectors) > 1)){
	$collectors = $collector;
	$recordedBy = &CCH::validate_collectors($collectors, $id);
	$verbatimCollectors = "$collector; $other_collectors";
	#warn "Names 1: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";}
}
elsif ((length($collector) == 0) && (length($other_collectors) == 0)){
		&log_change("COLLECTOR: Collector name NULL\t$id\n");
		$recordedBy =  $other_collectors = "";
		$verbatimCollectors = "Unknown";
}
else {
		&log_change("COLLECTOR: Collector name problem\t$id\n");
		$recordedBy = "";
		$verbatimCollectors = "$collector|$other_collectors";
}

foreach ($verbatimCollectors){
	s/NULL//g;
	s/'$//g;
	#s/\| *$//g;
	#s/^ *\|$//g;
	s/^ +//;
	s/ +$//;
	s/  +/ /g;
}


#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes
#prefix nd suffix are not a field in these data

my $CNUM;


foreach ($recordNumber){
	s/NULL//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	s/I439I/14391/;
	s/[Ss],?[Nn][,.]?/s.n./;
}
foreach ($CNUM_prefix){
	s/NULL//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
}
foreach ($CNUM_suffix){
	s/NULL//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
}


	if ($recordNumber){
		$CNUM = $recordNumber;
	}
	else{
		if ((length($CNUM_suffix)>= 1) || (length($CNUM_prefix)>= 1)){
			&log_change("COLL NUMB: prefix or suffix present, but collection number is NULL==>PRE:$CNUM_prefix  NUM:$recordNumber  SUF:$CNUM_suffix\t$id\n");
			$CNUM = "";
		}
		else{
			$CNUM = $CNUM_suffix = $CNUM_prefix = "";
		}
	}


####COUNTRY
foreach ($country){
	s/  +/ /g;
	s/^ +//;
	s/ +$//;

}

####STATE
foreach ($stateProvince){
	s/  +/ /g;
	s/^ +//;
	s/ +$//;

}
######################COUNTY
foreach($tempCounty){
	s/"//g;
	s/'//g;
	s/\//-/g;
	s/unknown/Unknown/;
	s/NULL/Unknown/;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	s/Playas [dD]e Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries
}



$county=&CCH::format_county($tempCounty,$id);


#fix additional problematic counties
	if(($id=~/^(UCD91338|UCD91339|UCD91340)$/) && ($county=~m/Santa.*/i)){ #fix some really problematic county records
		$county=~s/^Santa.*/Sonoma/;
		$locality=~s/^.*$/Santa Rosa; Field -- Campus -- Berkeley/;	
		&log_change("COUNTY: County/Location problem modified to: ($county)\t($locality)\t$id\n");	
	}
	if(($id=~/^(UCD57712)$/) && ($county=~m/Marico.*/i)){ #fix some really problematic county records
		$county=~s/^.*$/Mariposa/;
		&log_change("COUNTY: County/Location problem modified to: ($county)\t($locality)\t$id\n");	
	}
	if(($id=~/^(UCD22725)$/) && ($county=~m/Santo.*/i)){ #fix some really problematic county records
		$county=~s/^.*$/Santa Cruz/;
		&log_change("COUNTY: County/Location problem modified to: ($county)\t($locality)\t$id\n");	
	}


######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY (1):unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
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

my $verbatimCounty = "";
#format verbatim county properly
	if($county !~m/^$tempCounty$/){
		$verbatimCounty = $tempCounty;
	}



####LOCALITY

foreach ($locality){
	s/NULL//;
	s/^C?[aA]?[lL]?[iI]?[fF]?[oO]?[rR]?[Nn]?[iI]?[Aa]? *[A-Z-a-z]+ [A-Z-a-z]* *[Cc][oO]\.?[ounty]*: *(.+)/$1/;
	s/CALIFORNIA: ?//;
	s/"/'/g;
	s/'$//g;
	s/^'//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;

}

#informationWithheld
		if($locality=~m/([^<]+) ?DUE TO CONCERNS .*/){ #if there is text stating that text has been redacted, use the string
			$locality = "$1... Fields redacted by UCD, contact the data manager for more information";
			$informationWithheld = "DUE TO CONCERNS FOR THE PROTECTION OF CERTAIN RARE OR COLLECTIBLE SPECIES, FOR THIS SPECIES THE LOCATION INFO HAS BEEN TRUNCATED, SECTION INFO HAS BEEN DELETED FROM THE TOWNSHIP AND RANGE FIELD, AND SECONDS HAVE BEEN REMOVED FROM LATITUDE AND LONGITUDE.";
			&log_change("specimen redacted by UCD\t$id");
	 	}
		else{
			$informationWithheld="";
		}
	
	
####ELEVATION

#$elevationInMeters is the darwin core compliant value
#verify if elevation fields are just numbers

#process verbatim elevation fields into CCH format


####Elevation

foreach($elevation){
	s/,//g;
	s/^ +//;
	s/ +$//;
	s/ //g;
	s/\.//g;
}

foreach($elevHigh){
	s/,//g;
	s/^ +//;
	s/ +$//;
	s/ //g;
	s/\.//g;
}

foreach($elev_units){
	s/,//g;
	s/`//g;
	s/`//g;
	s/'//g;
	s/^ +//;
	s/ +$//;
	s/ //g;
	s/Mm/m/g; #fix an error
	s/\.//g;
}

	if(($elevation =~ m/^NULL/) && ($elev_units =~ m/^NULL/) && ($elevHigh =~ m/^NULL/)){
		$elev_units = $verbatimElevation=$CCH_elevationInMeters=$elevationInFeet=$elevationInMeters="";
		&log_change("ELEV elvation fields NULL, $id\n");		#call the &log function to print this log message into the change log...
	}		
	elsif(($elevation =~ m/^-?[0-9]+/) && ($elev_units =~ m/^NULL/) && ($elevHigh =~ m/^NULL/)){
		$elev_units = $CCH_elevationInMeters = $elevationInFeet = $elevationInMeters="";
		$verbatimElevation = $elevation;
		&log_change("ELEV elevation missing units, $id\n");		#call the &log function to print this log message into the change log...
	}		
	elsif(($elevation =~ m/^NULL/) && ($elev_units =~ m/.+/) && ($elevHigh =~ m/^NULL/)){
		$verbatimElevation = $CCH_elevationInMeters = $elevationInFeet = $elevationInMeters="";
		&log_change("ELEV elevation fields NULL, but Units field contains partial data\t($elev_units)\t$id\n");		#call the &log function to print this log message into the change log...
	}
	elsif(($elevation =~ m/^-?[0-9]+/) && ($elev_units =~ m/^[MmFfeEtTRrSs]+$/) && ($elevHigh =~ m/^NULL/)){
		$verbatimElevation = "$elevation $elev_units";
	}
	elsif(($elevation =~ m/^NULL/) && ($elev_units =~ m/^[MmFfeEtTRrSs]+$/) && ($elevHigh =~ m/^-?[0-9]+/)){
		$verbatimElevation = "$elevHigh $elev_units";
	}
	elsif(($elevation =~ m/^-?[0-9]+/) && ($elev_units =~ m/[^MmFfeEtTRrSs]+$/) && ($elevHigh =~ m/^-?[0-9]+/)){
		$verbatimElevation = "$elevation - $elevHigh $elev_units";
	}		
	else {
		&log_change("ELEV verbatim elevation problem==>ELEV: $elevation  ELEV2:$elevHigh  UNITS:$elev_units)\t$id\n");
		$verbatimElevation = "$elevation - $elevHigh $elev_units";
	}

foreach($verbatimElevation){
	s/feet/ ft/g;
	s/ft/ ft/g;
	s/m/ m/g;
	s/`//g;
	s/([A-Za-z]+)/ $1/g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;

}


if (($elevation =~ m/^-?\d+\.?\d*$/) && ($elev_units =~ m/^[metrs.]+$/i)){
		$elevationInMeters = int($elevation);
		$elevationInFeet = int($elevationInMeters * 3.2808);
		$CCH_elevationInMeters = "$elevationInMeters m";
}
elsif (($elevation =~ m/^-?\d+\.?\d*$/) && ($elev_units =~ m/^[fet.]+$/i)){
		$elevationInFeet = int($elevation);
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
}
elsif (($elevation =~ m/NULL/) && ($elev_units =~ m/^[fet.]+$/i)){#this is a case where the elevation is NULL but there is a value in 2nd elevation field that has a unit
	if (length($elevHigh) >= 1){
		$elevationInFeet = int($elevHigh);
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else{
		$CCH_elevationInMeters = $elevationInFeet = $elevationInMeters="";
		&log_change("ELEV elevation has missing units, is non-numeric, or has typographic errors(1)==>ELEV: $elevation  ELEV2:$elevHigh  UNITS:$elev_units)\t$id\n");
	}
}
elsif (($elevation =~ m/NULL/) && ($elev_units =~ m/^[metrs.]+$/i)){#this is a case where the elevation is NULL but there is a value in 2nd elevation field that has a unit
	if (length($elevHigh) >= 1){
		$elevationInMeters = int($elevHigh);
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else{
		$CCH_elevationInMeters = $elevationInFeet = $elevationInMeters="";
		&log_change("ELEV elevation has missing units, is non-numeric, or has typographic errors(2)==>ELEV: $elevation  ELEV2:$elevHigh  UNITS:$elev_units)\t$id\n");
	}
}
elsif (($elevation =~ m/^0+$/) && (length($elev_units) == 0)){
		$elevationInFeet = "0";
		$elevationInMeters = "0";
		$CCH_elevationInMeters = "$elevationInMeters m";
}
elsif (($elevation =~ m/^(1[0-9]{4})$/) && (length($elev_units) == 0)){ #elevations above 4000 in value are feet, by default, do no change elevations below 4000 to feet
		$elevationInFeet = int($elevation);
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
}
elsif (($elevation =~ m/^(4[0-9]{3})$/) && (length($elev_units) == 0)){ #elevations above 4000 in value are feet, by default, do no change elevations below 4000 to feet
		$elevationInFeet = int($elevation);
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
}
elsif (($elevation =~ m/^(1[0-9]{4})$/) && ($elev_units =~ m/NULL/)){ #this is a case where the elevation range does not have a unit and NULL is still present from XML parsing
		$elevationInFeet = int($elevation);
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
}
elsif (($elevation =~ m/^(4[0-9]{3})$/) && ($elev_units =~ m/NULL/)){ #this is a case where the elevation range does not have a unit and NULL is still present from XML parsing
		$elevationInFeet = int($elevation);
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
}
else {
		&log_change("ELEV elevation has missing units, is non-numeric, or has typographic errors(3)==>ELEV: $elevation  ELEV2:$elevHigh  UNITS:$elev_units\t$id\n");
		$elev_units = $CCH_elevationInMeters = $elevationInFeet = $elevationInMeters="";
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
#Source is a free text field so no editing required
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
my $lat_sum;
my $long_sum;
my $Check;
my $hold;

#######Latitude and Longitude

	foreach ($lat_degrees,$lat_minutes,$lat_seconds,$long_degrees,$long_minutes,$long_seconds){
		s/NULL//g;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
	}

$verbatimLatitude = $lat_degrees ." " .  $lat_minutes . " ".  $lat_seconds;

$verbatimLongitude = $long_degrees ." " .  $long_minutes . " ".  $long_seconds;


foreach ($decimal_lat, $verbatimLatitude){
		s/NULL//g;
		s/ø/ /g;
		s/'/ /g;
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
		s/NULL//g;
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/,/ /g;
		s/deg\.?/ /;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
		
}



if ((length($decimal_lat) == 0) || (length($decimal_long) == 0)){
#check to see if lat and lon reversed, THIS IS UNIQUE TO DAV due to the 3 sets of coordinates that are not consistent

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
		#print "COORDINATE NULL(1) $id\n";
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
		print "COORDINATE NULL(2) $id\n";
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


foreach ($latitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s+$//;
}	


foreach ($longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s+$//;
}	


#fix some problematic records with bad latitude and longitude in home database

if (($id =~ m/^(UCD100204)$/) && ($longitude =~ m/121\./)){ 
#<HerbID>100204</HerbID><GeoPrimaryDivision>United States</GeoPrimaryDivision><GeoSecondaryDivision>California</GeoSecondaryDivision><GeoTertiaryDivision>San Luis Obispo County</GeoTertiaryDivision><Genus>Calandrinia</Genus><SpecificEpithet>ciliata</SpecificEpithet><Authority>(Ruiz &amp; Pav.) DC.</Authority><CollectionNumber>12196</CollectionNumber><Collector>G. F. Hrusa</Collector><Date>28 May 1995</Date><Locality>San Luis Obispo County: Black Buttes Research Natural Area.</Locality><Ecology>Occasional on burned sites, usually in vicinity of Pnus attenuata or chaparral. Flowers dark pink. Plant annual.</Ecology><LatitudeDegree>35</LatitudeDegree><LatitudeMinutes>19</LatitudeMinutes><LatitudeSeconds>0</LatitudeSeconds><LatitudeDirection>N</LatitudeDirection><LatitudeDecimal>35.316667</LatitudeDecimal><LongitudeDegree>121</LongitudeDegree><LongitudeMinutes>36</LongitudeMinutes><LongitudeSeconds>0</LongitudeSeconds><LongitudeDirection>W</LongitudeDirection><LongitudeDecimal>-121.6</LongitudeDecimal><Elevation>600</Elevation><ElevationUnits>m.</ElevationUnits>
	$latitude = "35.316667";
	$longitude = "-120.6";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) maps in the Pacific Ocean, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
	#the original is in error and maps to far out into the Pacific Ocean, causing a yellow flag.  The longitude was off by one degree, probably a typo
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
elsif(($latitude==0  && $longitude==0)){
	$datum = $georeferenceSource = $decimalLatitude = $decimalLongitude = "";
	&log_change("COORDINATE entered as '0', changed to NULL $id\n");
}
elsif ((length($latitude) == 0) || (length($longitude) == 0)){
		#some coordinates are entered with the value of 0, so the basic coordinate parser had to be modified
		
		$UTME = int($UTME); #make it an integer because the converter cannot handle decimal UTM
		$UTMN = int($UTMN); #make it an integer because the converter cannot handle decimal UTM
		
			&log_change("COORDINATE Lat & Long null but UTM is present, checking for valid coordinates: $UTME, $UTMN, $zone, $id\n");
		
		#process zone fields
			if((length($zone) == 0) && ($locality =~ m/(San Miguel Island|Santa Rosa Island)/i)){
				$zone = "10S"; #Zone for these data are this, using UTMWORLD.gif in DATA directory
			}
			elsif ((length($zone) == 0) && ($locality !~ m/(San Miguel Island|Santa Rosa Island)/i)){
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
				elsif($county =~ m/(Mexicali|Unknown)/){
					$zone = ""; #Mexicali is in a small part of CA-FP Baja and it has sections in two zones, so UTM without zone is not convertable
				}
				else{
					&log_change("COORDINATE UTM Zone cannot be determined: $id");
					$zone = "";
				}
			}
			else{
				#do nothing
			}
			
		if ((length($UTME) >=6 ) && (length($UTMN) >=6 )){
#leading zeros need to be removed before this step
#Northing is always one digit more than easting. sometimes they are apparently switched around.
			if (($UTME =~ m/^\d{7}/) && ($UTMN =~ /^\d{6}/)){
					$easting = $UTMN;
					$northing = $UTME;
					&log_change("COORDINATE UTM coordinates apparently reversed; switching northing with easting: $id");
					#calculate lat long from UTM
					($decimalLatitude,$decimalLongitude)=utm_to_latlon(23,$zone,$easting,$northing);
					&log_change("Decimal degrees derived from UTM for $id: $decimalLatitude, $decimalLongitude");
					$georeferenceSource = "UTM conversion by CCH loading script";
			}
			elsif (($UTMN =~ m/^\d{7}/) && ($UTME =~ /^\d{6}$/)){
					$easting = $UTME;
					$northing = $UTMN;
					#calculate lat long from UTM
					($decimalLatitude,$decimalLongitude)=utm_to_latlon(23,$zone,$easting,$northing);
					&log_change("Decimal degrees derived from UTM for $id: $decimalLatitude, $decimalLongitude");
					$georeferenceSource = "UTM conversion by CCH loading script";
			}
			else{
				&log_change("COORDINATE 11a) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone, $id\n");
				$northing = $easting = $decimalLatitude = $decimalLongitude = $georeferenceSource = $datum = "";
			}

		}
		elsif ((length($UTME) == 0) && (length($UTMN) == 0)){
			$northing = $easting = $decimalLatitude = $decimalLongitude = $georeferenceSource = $datum = "";
			&log_change("COORDINATE coordinates NULL for $id\n");
		}
		else{
				&log_change("COORDINATE 11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone, $id\n");
				$northing = $easting = $decimalLatitude = $decimalLongitude = $georeferenceSource = $datum = "";
		}
}
else {
			&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
}



#check datum
if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	#$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
#$coordinateUncertaintyInMeters none in these data
#$UncertaintyUnits none in these data
foreach ($datum){
		s/WGS 1984/WGS84/g;
		s/NAD 1927/NAD27/;
		s/NAD 1983/NAD83/g;
		s/  +/ /g;
		s/NULL//g;
		s/^ +//g;
		s/ +$//g;
}

		unless ($datum){
		$datum = "not recorded"; #use this only if datum are blank, set it for only records with coords
		}

}	


#final check of Longitude

	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			&log_change("COORDINATE: Longitude made negative\t--\t$id");
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
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}
	
foreach ($coordinateUncertainty){
	s/NULL//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}

		if(length($coordinateUncertainty) == 0){
			$coordinateUncertaintyInMeters = "";
			$coordinateUncertaintyUnits = "";
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			if ($coordinateUncertainty =~ m/(\d+) +([A-Za-z]+)/){
				$coordinateUncertaintyInMeters = $1;
				$coordinateUncertaintyUnits = $2;
			}
			else{
				$coordinateUncertaintyInMeters = $coordinateUncertainty;
				&log_change("COORDINATE uncertainty value or units problems for $id==>$coordinateUncertainty\n");
				$coordinateUncertaintyUnits = "";
			}
		}

##############TRS
foreach($TRS){
	s/NULL//g;
	s/,/ /g;
	s/\./ /g;
	s/[Ss]ecf/Sec/g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;

}

foreach($topo_quad){
	s/NULL//;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;

}



warn "$count\n" unless $count % 10000;

#######Notes (dwc occurrenceRemarks) and Other_Data
#Macromorphology, including abundance
my $note_string;

foreach ($habitat){
	s/NULL//g;
	s/"//g;
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/'$//;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}

foreach ($informationWithheld){
	s/NULL//g;
	s/'$//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
}

#format note_string correctly
	if (length($informationWithheld) >= 1){
		$note_string="$informationWithheld";
	}

            print OUT <<EOP;

Accession_id: $id
Other_label_numbers: $catalogNumber
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
Habitat: $habitat
Associated_species:
T/R/Section: $TRS
USGS_Quadrangle: $topo_quad
UTM: $zone $UTME $UTMN
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance: $coordinateUncertaintyInMeters
Max_error_units: $coordinateUncertaintyUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $verbatimCounty
Notes: $note_string
Cultivated: $cultivated
Type_status: $typeStatus
Hybrid_annotation: $hybrid_annotation
Annotation: $det_string
EOP
++$included;

#usually, the blank line is included at the end of the block above
#but since the $ANNO{$id} is printed outside the block, the \n is after
print OUT $ANNO{$id};
print OUT "\n";

}

my $skipped_taxa = $count-$included;
print <<EOP;
INCL: $included
EXCL: $skipped{one}
TOTAL: $count

SKIPPED TAXA: $skipped_taxa

SKIPPED NON_VASCULAR TAXA: $NONV_count
(these non-vasculars are skipped early and not included in TOTAL above)
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


    my $file_in = '/JEPS-master/CCH/Loaders/UCD/UCD_out.txt';	#the file this script will act upon is called 'CATA.out'
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

	
################SUBROUTINES#############
#original XML file does not have line for fields with no data, these sub's add NULL values for records that do not contain a line for a field, thus producing a table with values (NULL or the original value) in every field for processing
sub get_accession {
#<Accession>114905</Accession>
		my $par = shift;
		
	if($par=~/<Accession>([A-Z]+\d+)<\/Accession>/){
			return $1;
		}
		else{
		return "NULL";
		}		
}
sub get_id {
#<HerbID>114905</HerbID>
		my $par = shift;
		
	if($par=~/<HerbID>(\d+)<\/HerbID>/){
			return $1;
		}
		else{
		return "NULL";
		}		
}
sub get_genus {
#<CGenus>Amelanchier</CGenus>	
		my $par = shift;

	if($par=~/<Genus>([^<]+)<\/Genus>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_species {
#<SpecificEpithet>utahensis</SpecificEpithet>	
		my $par = shift;

	if($par=~/<SpecificEpithet>([^<]+)<\/SpecificEpithet>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_rank {
#<Rank>ssp.</Rank>	
		my $par = shift;

		if($par=~/<Rank>([^<]+)<\/Rank>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_subtaxon {
#<InfraspecificName>montevidensis</InfraspecificName>	
		my $par = shift;

	if($par=~/<InfraspecificName>([^<]+)<\/InfraspecificName>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_hybridgenus {
#<HybridGenus>Juglans</HybridGenus>	
		my $par = shift;

	if($par=~/<HybridGenus>([^<]+)<\/HybridGenus>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_hybrid_epithet {
#<hybridspp1>hindsii</hybridspp1>
		my $par = shift;

	if($par=~/<hybridspp1>([^<]+)<\/hybridspp1>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_hybrid_epithet2 {
#<hybridspp2>californica</hybridspp2>
		my $par = shift;

	if($par=~/<hybridspp2>([^<]+)<\/hybridspp2>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}

sub get_collector {
#<Collector>D.G. Kelch</Collector>
		my $par = shift;

	if($par=~/<Collector>([^<]+)<\/Collector>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_other_coll {
#<MoreCollectors>D. L. Haws</MoreCollectors>
		my $par = shift;

	if($par=~/<MoreCollectors>([^<]+)<\/MoreCollectors>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_recordNumber {
#<CollectionNumber>11510</CollectionNumber>
		my $par = shift;

	if($par=~/<CollectionNumber>([^<]+)<\/CollectionNumber>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_prefix {
#<Prefix>LP-</Prefix>
		my $par = shift;

	if($par=~/<Prefix>([^<]+)<\/Prefix>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_suffix {
#<Suffix>-A</Suffix>
		my $par = shift;

	if($par=~/<Suffix>([^<]+)<\/Suffix>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_verbatim_eventDate {
#<Date>17 Sep 1920</Date>
		my $par = shift;
		my $fix;

	if($par=~/<Date>([^<]+)<\/Date>/){
		$fix = $1;
		$fix =~ s/\s+/ /g; #fix cases where there is a tab in the middle of this field data that is messing with parsing
		return $fix;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_eventDate {
#<CorrectedDate>1957-08-20T00:00:00</CorrectedDate>
		my $par = shift;

	if($par=~/<CorrectedDate>([^<]+)<\/CorrectedDate>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_country {
#<GeoPrimaryDivision>United States</GeoPrimaryDivision>
		my $par = shift;

	if($par=~/<GeoPrimaryDivision>([^<]+)<\/GeoPrimaryDivision>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_stateProvince {
#<GeoSecondaryDivision>United States</GeoSecondaryDivision>
		my $par = shift;

	if($par=~/<GeoSecondaryDivision>([^<]+)<\/GeoSecondaryDivision>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_county {
#<GeoTertiaryDivision>San Francisco</GeoTertiaryDivision>
		my $par = shift;

	if($par=~/<GeoTertiaryDivision>([^<]+)<\/GeoTertiaryDivision>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_TRS {
#<TownshipAndRange>T33N  R04W S24</TownshipAndRange>
		my $par = shift;

	if($par=~/<TownshipAndRange>([^<]+)<\/TownshipAndRange>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_elevation {
#<Elevation>366</Elevation>
		my $par = shift;

	if($par=~/<Elevation>([^<]+)<\/Elevation>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_elevationHigh {
#<Elevation2>366</Elevation2>
		my $par = shift;

	if($par=~/<Elevation2>([^<]+)<\/Elevation2>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_elev_units {
#<ElevationUnits>ft.</ElevationUnits>
		my $par = shift;

	if($par=~/<ElevationUnits>([^<]+)<\/ElevationUnits>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_locality {
#<Locality>Vicinity of Blairsden.</Locality>
		my $par = shift;
		my $fix;

	if($par=~/<Locality>([^<]+)<\/Locality>/){
		$fix = $1;
		$fix =~ s/\s+/ /g; #fix cases where there is a tab in the middle of this field data that is messing with parsing
		return $fix;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_lat_dec {
#<LatitudeDecimal>38.5024999999441</LatitudeDecimal>
		my $par = shift;

	if($par=~/<LatitudeDecimal>([^<]+)<\/LatitudeDecimal>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_long_dec {
#<LongitudeDecimal>-122.099444444602</LongitudeDecimal>
		my $par = shift;

	if($par=~/<LongitudeDecimal>([^<]+)<\/LongitudeDecimal>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_lat_degrees {
#<LatitudeDegree>39</LatitudeDegree>
		my $par = shift;

	if($par=~/<LatitudeDegree>([^<]+)<\/LatitudeDegree>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_lat_minutes {
#<LatitudeMinutes>10</LatitudeMinutes>
		my $par = shift;

	if($par=~/<LatitudeMinutes>([^<]+)<\/LatitudeMinutes>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_lat_seconds {
#LatitudeSeconds>1</LatitudeSeconds>
		my $par = shift;

	if($par=~/<LatitudeSeconds>([^<]+)<\/LatitudeSeconds>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_lat_dir {
#<LatitudeDirection>N</LatitudeDirection>
		my $par = shift;

	if($par=~/<LatitudeDirection>([^<]+)<\/LatitudeDirection>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_long_degrees {
#<LongitudeDegree>122</LongitudeDegree>
		my $par = shift;

	if($par=~/<LongitudeDegree>([^<]+)<\/LongitudeDegree>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_long_minutes {
#<LongitudeMinutes>31</LongitudeMinutes>
		my $par = shift;

	if($par=~/<LongitudeMinutes>([^<]+)<\/LongitudeMinutes>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_long_seconds {
#<LongitudeSeconds>44</LongitudeSeconds>
		my $par = shift;

	if($par=~/<LongitudeSeconds>([^<]+)<\/LongitudeSeconds>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_long_dir {
#<LongitudeDirection>W</LongitudeDirection>
		my $par = shift;

	if($par=~/<LongitudeDirection>([^<]+)<\/LongitudeDirection>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_datum {
#<LatLongDatum>NAD 1983</LatLongDatum>
#<Datum>NAD83</Datum>
		my $par = shift;

	if($par=~/<LatLongDatum>([^<]+)<\/LatLongDatum>/){
		return $1;
	}		
	elsif($par=~/<Datum>([^<]+)<\/Datum>/){
		return $1;
	}
	else{
		return "NULL";
	}		
			
}
sub get_errorRadius {
#<LatLongPrecision>0.25</LatLongPrecision>#no longer a field in 2018
		my $par = shift;

	if($par=~/<LatLongPrecision>([^<]+)<\/LatLongPrecision>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_errorRadiusUnits {
#<LatLongPrecisionUnits>mi.</LatLongPrecisionUnits>#no longer a field in 2018
		my $par = shift;

	if($par=~/<LatLongPrecisionUnits>([^<]+)<\/LatLongPrecisionUnits>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_coordinateUncertainty {
#<LatLongPrecision>0.25</LatLongPrecision>
		my $par = shift;

	if($par=~/<LatLongPrecision>([^<]+)<\/LatLongPrecision>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_LatLongAdded {
#<LatLongAddedCheck>yes</LatLongAddedCheck>#no longer a field in 2018
		my $par = shift;

	if($par=~/<LatLongAddedCheck>([^<]+)<\/LatLongAddedCheck>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_topo_quad {
#<USGSQuadrangle>Kettle Peak</USGSQuadrangle>
		my $par = shift;

	if($par=~/<USGSQuadrangle>([^<]+)<\/USGSQuadrangle>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_habitat { 
#made into notes field, this is not just habitat or ecology, 
#it is associates, macromorphology, plant description, population biology, habitat, and general notes all combined  
#in one field of multiple sentences and phrases, separated by punctuation, mostly periods and spaces
#<Ecology>Ocassional here. Flowers a creamy white- yellow. On Heteromeles arbutifolia.</Ecology>
		my $par = shift;
		my $fix;

	if($par=~/<Ecology>([^<]+)<\/Ecology>/){
		$fix = $1;
		$fix =~ s/\s+/ /g; #fix cases where there is a tab in the middle of this field data that is messing with parsing
		return $fix;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_other { 
#no longer a field in 2018
#misc. information about the label and where the specimen came from, not a typical notes field, placed in Other_data herein 
#<Notes>Label says: California Academy of Sciences.</Notes>
		my $par = shift;

	if($par=~/<Notes>([^<]+)<\/Notes>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}

sub get_AnnoRank { 
#<AnnoYesNo>0</AnnoYesNo>#no longer a field in 2018
		my $par = shift;

	if($par=~/<AnnoYesNo>([^<]+)<\/AnnoYesNo>/){
		return $1;
	}		
	else{
		return "0";
	}		
			
}
sub get_identifiedBy { 
#<DeterminedBy>A. O. Tucker</DeterminedBy>
		my $par = shift;

	if($par=~/<DeterminedBy>([^<]+)<\/DeterminedBy>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_dateIdentified {
#<DeterminedDate>2011-09-09T00:00:00</DeterminedDate>#no longer a field in 2018
		my $par = shift;

	if($par=~/<DeterminedDate>([^<]+)<\/DeterminedDate>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_zone { 
#<UTMZone>Zone 10</UTMZone>
		my $par = shift;

	if($par=~/<UTMZone>([^<]+)<\/UTMZone>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_UTME { 
#<easting>608474</easting>
		my $par = shift;

	if($par=~/<easting>([^<]+)<\/easting>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_UTMN { 
#<northing>4559366</northing>
		my $par = shift;

	if($par=~/<northing>([^<]+)<\/northing>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_typeStatus { 
#<TypeStatus>isotype</TypeStatus>
		my $par = shift;

	if($par=~/<TypeStatus>([^<]+)<\/TypeStatus>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
