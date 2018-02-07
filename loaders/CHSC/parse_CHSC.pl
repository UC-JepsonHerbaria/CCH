
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
my $tempCounty;




my $xml_file = 'data_files/CHSC_2017-11-16_all_CA_for_CCH.xml';
my $tab_file= 'CHSC_xml.txt';


#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";
#note that the print ERROR often includes all content in XML tabs separated by Windows line breaks, which can be confusing if opened not in vi. Consider revising
#save as UTF-8 with UNIX line breaks in Text Wrangler



#place these here instead of after "while(<IN>){" so that they are usable by both the parsing and the correcting stages
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
my $lat_dir;
my $long_dir;
my $LatLongAddedCheck;
my $topo_quadScale;
my $AnnoYesNo;
my $cult;
my $AnnoRank;
my $NONV_count;
my $NONV_line_store;
my $elev_units;
my $LatLongAdded;
my $other;
my $informationWithheld;



open(OUT, ">CHSC_xml.txt") || die; 

#Stage 1, XML parsing

    open (IN, "<", $xml_file) or die $!;

#local $/=qq{<CurrentName_with_all_fields>}; #old delimiter, these apparently can change

local $/=qq{<CHSC_for_x0020_CalHerbConsort>};

Record: while(<IN>){


	chomp;

#fix some data quality and formatting problems that make import of fields of certain records problematic
		
		s/♂/ male /g;	#CHSC109941 & others: ♀ stems prostrate, ♂ stems erect
		s/♀/ female /g;	#CHSC109941 & others: ♀ stems prostrate, ♂ stems erect
		s/§/Section/g; #CHSC114149
		s/€//g; #CHSC112018, unknown formatting problem
		s/…/./g;	#CHSC45980	
		s/º/ deg. /g;	#CHSC82997 and others, masculine ordinal indicator used as a degree symbol
		s/–/--/g;	#CHSC82527 and others
		s/`/'/g;		
		s/‘/'/g;
		s/’/'/g;
		s/”/'/g;
		s/“/'/g;
		s/”/'/g;
		s/±/+-/g;	#CHSC28135 and others
		s/°/ deg. /g;	#CHSC42341 and others, convert degree symbol to deg. abbrev.
		s/¼/ 1\/4 /g;	#CHSC34682 and others
		s/½/ 1\/2 /g;	#CHSC34680 and others
		s/¾/ 3\/4 /g;	#CHSC82639
		s/è/e/g;	#CHSC23565
		s/é/e/g;	#CHSC52770 and others
		s/ë/e/g;	#CHSC35479	Monanthochloë	Boër		
		s/ñ/n/g;	#CHSC34617 and others
		s/Č/C/g;	#CHSC114355
		
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




#fix more data quality and formatting problems

#example 2017 file format:
#<CHSC_for_x0020_CalHerbConsort>
#<Accession>41458</Accession>
#<Division>Anthophyta (flowering plants)</Division>
#<CFamily>Fabaceae</CFamily>
#<CGenus>Trifolium</CGenus>
#<CSpecificEpithet>bifidum</CSpecificEpithet>
#<CRank>var.</CRank>
#<CInfraspecificName>decipiens</CInfraspecificName>
#<Collector>Lowell Ahart</Collector>
#<CollectionNumber>5255</CollectionNumber>
#<Date>1986-05-04T00:00:00</Date>
#<DatePrecision>Day</DatePrecision>
#<GeoTertiaryDivision>Sutter</GeoTertiaryDivision>
#<Elevation>100</Elevation>
#<ElevationUnits>ft.</ElevationUnits>
#<Locality>On the bottom of a large vernal pool, near the first gate to the Dean Ranch, about 1/2 mile north of the intersection of Mallott Road and Alf Road, about 2 miles north-east of Sutter, Sutters.</Locality>
#<Ecology>Valley Grassland.  On dry dark clay soil, on the bottom of a large vernal pool.  Uncommon.  Flowers pink.</Ecology>
#<LatitudeDegree>39</LatitudeDegree>
#<LatitudeMinutes>11</LatitudeMinutes>
#<LatitudeSeconds>40</LatitudeSeconds>
#<LatitudeDirection>N</LatitudeDirection>
#<LongitudeDegree>121</LongitudeDegree>
#<LongitudeMinutes>43</LongitudeMinutes>
#<LongitudeSeconds>46</LongitudeSeconds>
#<LongitudeDirection>W</LongitudeDirection>
#<LatLongDatum>NAD 1983</LatLongDatum>
#<LatLongAddedCheck>yes</LatLongAddedCheck>
#<LatLongPrecision>0.25</LatLongPrecision>
#<LatLongPrecisionUnits>mi.</LatLongPrecisionUnits>
#<AnnoYesNo>1</AnnoYesNo>
#<CDeterminedBy>Vernon H. Oswald</CDeterminedBy>
#<DeterminedDate>1993-06-07T00:00:00</DeterminedDate>

#example 2014 file format:
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
#<LatLongAddedCheck>yes</LatLongAddedCheck>
#<LatLongPrecision>15</LatLongPrecision>
#<LatLongPrecisionUnits>mi.</LatLongPrecisionUnits>
#<AnnoYesNo>1</AnnoYesNo>
#<CDeterminedBy>herbarium</CDeterminedBy>
#<EntryDate>2001-01-23T00:00:00</EntryDate>


#lines not parsed
#<DatePrecision>Day</DatePrecision>
#<AccessionDate>2015-04-01T00:00:00</AccessionDate>
#<EntryDate>2015-04-01T00:00:00</EntryDate>
#<Division>Anthophyta (flowering plants)</Division>
#<CFamily>Plantaginaceae</CFamily>
#<USGSQuadrangleScale>5100</USGSQuadrangleScale>


#These tags have dedicated "&get" subroutines"
	$cultivated=&get_cult($_);
	$id= &get_id($_);
	$genus=&get_genus($_);
	$species=&get_species($_);
	$rank=&get_rank($_);
	$subtaxon=&get_subtaxon($_);
	$collector=&get_collector($_);
	$other_coll=&get_other_coll($_);
	$recordNumber=&get_recordNumber($_);
	$verbatimEventDate=&get_eventDate($_);
	$country=&get_country($_);
	$stateProvince=&get_stateProvince($_);
	$county=&get_county($_);
	$TRS=&get_TRS($_);
	$elevation=&get_elevation($_);
	$elev_units=&get_elev_units($_);
	$locality=&get_locality($_);
	$lat_degrees=&get_lat_degrees($_);
	$lat_minutes=&get_lat_minutes($_);
	$lat_seconds=&get_lat_seconds($_);
	$lat_dir=&get_lat_dir($_);
	$long_degrees=&get_long_degrees($_);
	$long_minutes=&get_long_minutes($_);
	$long_seconds=&get_long_seconds($_);
	$long_dir=&get_long_dir($_);
	$datum=&get_datum($_);
	$LatLongAdded=&get_LatLongAdded($_);
	$errorRadius=&get_errorRadius($_);	
	$errorRadiusUnits=&get_errorRadiusUnits($_);
	$topo_quad=&get_topo_quad($_);
	$notes=&get_notes($_);
	$other=&get_other($_);
	$AnnoYesNo=&get_AnnoRank($_);
	$identifiedBy=&get_identifiedBy($_);
	$dateIdentified=&get_dateIdentified($_);


print OUT join("\t",$cultivated, $id, $genus, $species, $rank, $subtaxon, $collector, $other_coll, $recordNumber, $verbatimEventDate, $country, $stateProvince, $county, $TRS, $elevation, $elev_units, $locality, $lat_degrees, $lat_minutes, $lat_seconds, $lat_dir, $long_degrees, $long_minutes, $long_seconds, $long_dir, $datum, $LatLongAdded, $errorRadius, $errorRadiusUnits, $topo_quad, $notes, $other, $AnnoYesNo, $identifiedBy, $dateIdentified), "\n";
}
close(OUT);


#die;
#Stage 2, Normal data loading and flat file creation
	open(OUT, ">CHSC_out.txt") || die;
	
	 
    open (IN, "<", $tab_file) or die $!;
    
local $/="\n";

Record: while(<IN>){
	chomp;

#fix some data quality and formatting problems that make import of fields of certain records problematic

	$line_store=$_;
	++$count;		
		

        if ($. == 1){#activate if need to skip header lines
			next;
		}

my @fields=split(/\t/,$_,100);
	unless($#fields==34){ #35 fields but first field is field 0 in perl
		&log_skip("$#fields bad field number $_\n");
		++$skipped{one};
		next Record;
	}




#then process the full records
(
$cultivated,
$id,
$genus,
$species,
$rank,
$subtaxon,
$collector,
$other_coll,
$recordNumber,
$verbatimEventDate,  #10
$country, 
$stateProvince,
$tempCounty,
$TRS,
$elevation,
$elev_units,
$locality,
$lat_degrees,
$lat_minutes,
$lat_seconds, #20
$lat_dir,  
$long_degrees,
$long_minutes,
$long_seconds,
$long_dir,
$datum,
$LatLongAdded,
$errorRadius,
$errorRadiusUnits,
$topo_quad,    #30
$occurrenceRemarks,  
$other,  
$AnnoRank,
$identifiedBy,
$dateIdentified #35
)=@fields;


################ACCESSION_ID#############

#check for nulls
if ($id=~/^[ NULL]*$/){
	&log_skip("ACC: Record with no accession id $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space
foreach($id){
	s/^0+//g;
	s/  +/ /g;
	s/^ *//g;
	s/ *$//g;
}

#Add prefix, 
$id="CHSC$id";

#Remove duplicates
if($seen{$fields[1]}++){
	warn "Duplicate number: $id<\n";
	&log_skip("ACC: Duplicate accession number, skipped\t$id");
	++$skipped{one};
	next Record;
}

##########Begin validation of scientific names

#####Annotations
	#format det_string correctly
my $det_rank = $AnnoRank;  #zero for original determination, 1 for most recent annotation, this is what I assume $AnnoYesNo in original file means
my $det_name = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;
my $det_determiner = $identifiedBy;
my $det_date = $dateIdentified;

$det_rank =~ s/^0$/original determination/;

	foreach ($det_name){
		s/NULL//g;
		s/^ *//g;
		s/  +//g;
	}

	foreach ($det_determiner){
		s/NULL//g;
		s/^ *//g;
		s/  +//g;
	}

	foreach ($det_date){
		s/NULL//g;
		s/^ *//g;
		s/  +//g;
	}

	if ($det_date =~ m/^(\d{4}-\d{2}-\d{2})T\d+/){
		$det_date = $1;
	}
	elsif (length($det_date) == 0){
		&log_change("DET: No date\t$id");
	}
	else {
		&log_change("DET: Bad DET DATE, Check date format\t$det_date\t--\t$id");
		$det_date = "";
	}
	
	
	if ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_date";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name, $det_date";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($det_date) == 0)){
		$det_string="";
	}
	else{
		&log_change("det problem: $det_rank: $det_name, $det_determiner, $det_date==>$id\n");
		$det_string="";
	}

##############SCIENTIFIC NAME
#Format name parts
$genus=ucfirst(lc($genus));
$species=lc($species);
$subtaxon=lc($subtaxon);
$rank=lc($rank);

#construct full verbatim name
	foreach ($genus){
		s/NULL//g;
		s/^ *//g;
		s/ *$//g;
	}	
	foreach ($species){
		s/NULL//g;
		s/^ *//g;
		s/ *$//g;
	}	
	foreach ($rank){
		s/NULL//g;
		s/^ *//g;
		s/ *$//g;
	}	
	foreach ($subtaxon){
		s/NULL//g;
		s/^ *//g;
		s/ *$//g;
	}

my $tempName = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;


#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($tempName){
	s/NULL//gi;
	s/[uU]nknown//g; #added to try to remove the word "unknown" for some records
	s/;//g;
	s/cf.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/[×] /X /;	#change  " x " in genus name to the multiplication sign
	s/  +/ /g;
	s/^ *//g;
	s/ *$//g;
}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published
if (($id =~ m/^(CHSC3279)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>3279</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Trifolium</CFamily><CGenus>willdenovii</CGenus><CSpecificEpithet>Spreng.</CSpecificEpithet>
	$tempName =~ s/[Ww]illdenovii [sS]preng\./Trifolium willdenovii/; #fix special case
	&log_change("Scientific name error - Trifolium entered as Family, CFamily=>'Trifolium', 'CGenus=>'willdenovii' CSpecificEpithet=>'Spreng.', modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC88877)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>88877</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>CyperaceaeCarex</CFamily><CGenus>vesicaria</CGenus><CSpecificEpithet>L.</CSpecificEpithet>
	$tempName =~ s/[Vv]esicaria [lL]\./Carex vesicaria/; #fix special case
	&log_change("Scientific name error - Carex entered into Family, CFamily=>'CyperaceaeCarex', CGenus=>'vesicaria' CSpecificEpithet=>'L.', modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC82545)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>82545</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Fabaceae</CFamily><CGenus>Trifolium</CGenus><CSpecificEpithet>Trifolium</CSpecificEpithet><CRank>Lehm.</CRank>
	$tempName =~ s/[tT]rifolium [tT]rifolium/Trifolium wormskioldii/; #fix special case
	&log_change("Scientific name error - Trifolium entered into Family, CFamily=>'Trifolium', CGenus=>'Trifolium' CSpecificEpithet=>'Lehm.', modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC38627)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>38627</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Portulacaceae</CFamily><CGenus>ciliata</CGenus><CSpecificEpithet>(Ruiz &amp; Pav.) DC.</CSpecificEpithet>
	$tempName =~ s/[Cc]iliata/Calandrinia ciliata/; #fix special case
	&log_change("Scientific name error - species name entered into Genus, <CGenus>=>'ciliata',<CSpecificEpithet>=>(Ruiz &amp; Pav.) DC., modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC92128)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>92128</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Asteraceae</CFamily><CGenus>Aster</CGenus><CSpecificEpithet>tridentata</CSpecificEpithet><CRank>ssp.</CRank><CInfraspecificName>tridentata</CInfraspecificName>
	$tempName =~ s/Aster tridentata ssp\. tridentata/Artemisia tridentata subsp. tridentata/; #fix special case
	&log_change("Scientific name error - corrected name for Aster tridentata, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC42943)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>42943</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Fabaceae</CFamily><CGenus>Acmispon</CGenus><CSpecificEpithet>stipularis</CSpecificEpithet><CRank>var.</CRank><CInfraspecificName>ottleyi</CInfraspecificName>
	$tempName =~ s/Acmispon stipularis var\. ottleyi/Hosackia stipularis var. ottleyi/; #fix special case
	&log_change("Scientific name error - Lotus stipularis in genus Hosackia, no comb for this taxon in Acmispon, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC103790)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>103790</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Polygonaceae</CFamily><CGenus>Eriogonum</CGenus><CSpecificEpithet>nudum</CSpecificEpithet><CRank>var.</CRank><CInfraspecificName>Benth.</CInfraspecificName>
	$tempName =~ s/Eriogonum nudum var\. [bB]enth\./Eriogonum nudum/; #fix special case
	&log_change("Scientific name error - species authority added as subtaxon, CInfraspecificName=>'Benth.', modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC60973)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>60973</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Campanulaceae</CFamily><CGenus>Nemacladus</CGenus><CSpecificEpithet>E. L. Greene</CSpecificEpithet>
	$tempName =~ s/Nemacladus [Ee]\. [Ll]\. [Gg]reene/Nemacladus capillaris/; #fix special case
	&log_change("Scientific name error - species authority added as species CSpecificEpithet=>'E. L. Greene', modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC109756)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Dysphania ambrosioides var\. ambrosioides/Chenopodium ambrosioides var. ambrosioides/; #fix special case
	&log_change("Scientific name error - no subtaxa described within D. ambrosioides, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC88828)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Astragalus suffrutescens/Astragalus/; #fix special case
	&log_change("Scientific name error - Astragalus suffrutescens not a published name, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC85412)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Citrullus colocynthis var\. citroides/Citrullus lanatus var. citroides/; #fix special case
	&log_change("Scientific name error - Citrullus colocynthis var. citroides not a published combination, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC109706)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Polygonum baileyi var\. baileyi/Eriogonum baileyi var. baileyi/; #fix special case
	&log_change("Scientific name error - Polygonum baileyi an error, genus incorrect, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC5101)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Penstemon johnstonii/Mimulus johnstonii/; #fix special case
	&log_change("Scientific name error - Penstemon johnstonii an error, genus incorrect, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC67166)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Layia congdonii/Monolopia congdonii/; #fix special case
	&log_change("Scientific name error - Layia congdonii not a published combination, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC112174)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Panicularia sierrae/Poa sierrae/; #fix special case
	&log_change("Scientific name error - Panicularia sierrae an error, genus incorrect, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC71071)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Eastwoodia nivea/Eatonella nivea/; #fix special case
	&log_change("Scientific name error - Eastwoodia nivea an error, genus incorrect, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC40433)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Angelica caucalis/Anthriscus caucalis/; #fix special case
	&log_change("Scientific name error - Angelica caucalis an error, genus incorrect, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC79237)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Actinostrobus cupressiformis/Callitris cupressiformis/; #fix special case
	&log_change("Scientific name error - Actinostrobus cupressiformis an error, genus incorrect, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC52119)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>52119</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Primulaceae</CFamily><CGenus>Trientalis</CGenus><CSpecificEpithet>latifolia</CSpecificEpithet><CRank>var.</CRank><CInfraspecificName>angustatum</CInfraspecificName>
	$tempName =~ s/Trientalis latifolia var. angustatum/Trientalis latifolia/; #fix special case
	&log_change("Scientific name error - Trientalis latifolia var. angustatum not a published subtaxon name, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^CHSC(9559|9647|9654|9655|9656)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Salix hookeriana var\. piperi/Salix hookeriana/; #fix special case
	&log_change("Scientific name error - not a published name, S. piperi is a synonym of S. hookieriana, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^CHSC(9617)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>9617</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Salicaceae</CFamily><CGenus>Salix</CGenus><CSpecificEpithet>scouleriana</CSpecificEpithet><CRank>var.</CRank><CInfraspecificName>lemmonii</CInfraspecificName>
	$tempName =~ s/Salix scouleriana var\. lemmonii/Salix scouleriana X lemmonii/; #fix special case
	&log_change("Scientific name error - Salix scouleriana var\. lemmonii not a published name, typo for a hybrid of S. scouleriana, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^CHSC(9659|9658)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>9658</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Salicaceae</CFamily><CGenus>Salix</CGenus><CSpecificEpithet>hookeriana</CSpecificEpithet><CRank>var.</CRank><CInfraspecificName>scouleriana</CInfraspecificName>
	$tempName =~ s/Salix hookeriana var\. scouleriana/Salix hookeriana X scouleriana/; #fix special case
	&log_change("Scientific name error - Salix hookeriana var\. scouleriana not a published name, typo for a hybrid of S. hookieriana, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^CHSC(52231)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>52231</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Lamiaceae</CFamily><CGenus>Monardella</CGenus><CSpecificEpithet>pallida</CSpecificEpithet><CRank>ssp.</CRank><CInfraspecificName>pallida</CInfraspecificName>
	$tempName =~ s/Monardella pallida ssp. pallida/Monardella odoratissima subsp. pallida/; #fix special case
	&log_change("Scientific name error - no subtaxa described within Monardella pallida, modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(CHSC111114)$/) && (length($TID{$tempName}) == 0)){ 
#<Accession>111114</Accession><Division>Anthophyta (flowering plants)</Division><CFamily>Apiaceae</CFamily><CGenus>Torilis</CGenus><CSpecificEpithet>arvensis</CSpecificEpithet><CRank>ssp.</CRank><CInfraspecificName>oyroyrea</CInfraspecificName>
	$tempName =~ s/Torilis arvensis ssp\. oyroyrea/Torilis arvensis/; #fix special case
	&log_change("Scientific name error - Torilis arvensis ssp\. oyroyrea not a published subtaxon name, modified to\t$tempName\t--\t$id\n");
}




#format hybrid names
if($tempName =~ m/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation = $tempName;
	warn "Hybrid Taxon: $1 removed from $tempName\n";
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
	   		&log_change("CULT: Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
		else {		
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			#&log_change("Taxon skipped purple flagging (1) $cultivated\t--\t$scientificName\n");
			$cultivated = "";
			}
		}
	}
	else {
		&log_change("CULT: Taxon flagged as cultivated in original database: $cultivated\t--\t$scientificName\n");
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

#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#verbatim date for dwc verbatimEventDate and CCH "Date"
#<Date>2004-05-24T00:00:00</Date> CHSC format


	foreach ($verbatimEventDate){
		s/NULL//;
		s/^ *//g;
		s/  +//g;
	}

	if ($verbatimEventDate =~ m/^(\d{4}-\d{2}-\d{2})T\d+/){
		$eventDate = $1;
	}
	elsif (length($verbatimEventDate) == 0){
		$YYYY = "";
		$DD = "";
		$MM = "";
		&log_change("DATE: No DATE\t$id");
	}
	else {
		&log_change("DATE: Bad DATE, Check date format\t$verbatimEventDate\t--\t$id");
		$eventDate = "";
	}
#CHSC does not need to convert to YYYY-MM-DD for eventDate and Julian Dates
#it is in ISO_8601_date, and needs to be checked

$formatEventDate = $eventDate;
($YYYY, $MM, $DD)=&atomize_ISO_8601_date($formatEventDate);
#warn "$formatEventDate\t--\t$id";

if ($MM =~ m/^00$/){ #this is how original Chico parse script treated the 00 values in Dates, not sure if this works with the JulianDate module
	$MM = "";
}
if ($DD =~ m/^00$/){
	$DD = "";
}

if ($MM =~ m/^(\d)$/){ #see note above, JulianDate module needs leading zero's for single digit days and months
	$MM = "0$1";
}
if ($DD =~ m/^(\d)$/){
	$DD = "0$1";
}


$MM2= $DD2 = ""; #set late date to blank since only one date exists
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $MM2, $DD2, $id);
#warn "$formatEventDate\t--\t$EJD, $LJD\t--\t$id";
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);


###############COLLECTORS

	foreach ($collector, $other_coll){
		s/'$//g;
		s/, M\. ?D\.//g;
		s/, Jr\./ Jr./g;
		s/, Jr/ Jr./g;
		s/, Esq./ Esq./g;
		s/, Sr\./ Sr./g;
		s/5.29.2015/Richard R. Halse/; #CHSC113816
		s/\(label illegible\)/Unknown/;
		s/^ *//;
		s/ *$//;
		s/  +/ /;
	}
	$other_collectors = ucfirst($other_coll);


if (($collector =~ m/^NULL/) && ($other_collectors =~ m/^NULL/)){
	$recordedBy = "";
	$verbatimCollectors = "";
	&log_change("COLLECTOR: Collector name and Other Collector fields missing, changed to NULL\t$id\n");
}
elsif (($collector =~ m/^NULL/) && ($other_collectors !~ m/^NULL/)){
	$recordedBy = &CCH::validate_single_collector($other_collectors, $id);
	$verbatimCollectors = "$other_collectors";
	&log_change("COLLECTOR: Collector name field missing, using other collector field\t$id\n");
}
elsif (($collector !~ m/^NULL/) && ($other_collectors =~ m/^NULL/)){
	$recordedBy = &CCH::validate_single_collector($collector, $id);
	$verbatimCollectors = "$collector";
	&log_change("COLLECTOR: Other Collector field missing, using only Collector\t$id\n");
}
elsif (($collector !~ m/^NULL/) && ($other_collectors !~ m/^NULL/)){
	$recordedBy = &CCH::validate_single_collector($collector, $id);
	$verbatimCollectors = "$collector, $other_collectors";
	#warn "Names 1: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";}
}
elsif ((length($collector) == 0) && (length($other_collectors) == 0)){
		&log_change("COLLECTOR: Collector name NULL\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}
else {
		&log_change("COLLECTOR: Collector name problem\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}

foreach ($verbatimCollectors){
	s/'$//g;
	s/NULL//;
	s/^ *//;
	s/ *$//;
	s/  +/ /;
}


#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes

my $CNUM_suffix;
my $CNUM;
my $CNUM_prefix;

foreach ($recordNumber){
	s/NULL//;
	s/^ *//;
	s/ *$//;
	s/I439I/14391/;
	s/[Ss],?[Nn][,.]?/s.n./;
	s/  +/ /;
}


($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);


####COUNTRY
foreach ($country){
	s/^ *//;
	s/ *$//;
	s/  +/ /;
}

####STATE
foreach ($stateProvince){
	s/^ *//;
	s/ *$//;
	s/  +/ /;
}
######################COUNTY
foreach($tempCounty){#for each $county value
	s/"//g;
	s/'//g;
	s/unknown/Unknown/;
	s/NULL/Unknown/;
	s/^ *//;
	s/  +/ /;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries



######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY (1):unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}

##############validate county
my $v_county;

$county=&CCH::format_county($tempCounty,$id);

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
####LOCALITY

foreach ($locality){
	s/NULL//;
	s/"/'/g;
	s/'$//g;
	s/^'//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

#informationWithheld
		if($locality=~m/(.*) ?DUE TO CONCERNS .*/){ #if there is text stating that text has been redacted, use the string
			$locality = "$1... Field redacted by CHSC, contact the data manager for more information";
			$informationWithheld = "DUE TO CONCERNS FOR THE PROTECTION OF CERTAIN RARE OR COLLECTIBLE  SPECIES, FOR THIS SPECIES THE LOCATION INFO HAS BEEN TRUNCATED, SECTION INFO HAS BEEN DELETED FROM THE TOWNSHIP AND RANGE FIELD, AND SECONDS HAVE BEEN REMOVED FROM LATITUDE AND LONGITUDE.";
			&log_change("specimen redacted by CHSC\t$id");
	 	}
		else{
			$informationWithheld="";
		}
	
}	
####ELEVATION
my $feet_to_meters="3.2808";

#$elevationInMeters is the darwin core compliant value
#verify if elevation fields are just numbers

#process verbatim elevation fields into CCH format


####Elevation

foreach($elevation){
	s/,//g;
	s/^ *//;
	s/ *$//;
	s/ //g;
	s/\.//g;
}

foreach($elev_units){
	s/,//g;
	s/`//g;
	s/`//g;
	s/'//g;
	s/^ *//;
	s/ *$//;
	s/ //g;
	s/Mm/m/g; #fix an error
	s/\.//g;
}

	if(($elevation =~ m/^NULL/) && ($elev_units =~ m/^NULL/)){
		$verbatimElevation=$CCH_elevationInMeters=$elevationInMeters="";
		&log_change("ELEVATION NULL, $id\n");		#call the &log function to print this log message into the change log...
	}		
	elsif(($elevation =~ m/^-?[0-9]+/) && ($elev_units =~ m/^NULL/)){
		$CCH_elevationInMeters = $elevationInMeters="";
		$verbatimElevation = $elevation;
		&log_change("ELEVATION missing units, $id\n");		#call the &log function to print this log message into the change log...
	}		
	elsif(($elevation =~ m/^NULL/) && ($elev_units =~ m/.*/)){
		$verbatimElevation = $CCH_elevationInMeters = $elevationInMeters="";
		&log_change("ELEVATION field NULL, but Units field contains partial data\t($elev_units)\t$id\n");		#call the &log function to print this log message into the change log...
	}
	elsif(($elevation =~ m/^-?[0-9]+/) && ($elev_units =~ m/^[MmFfeEtTRrSs]+$/)){
		$verbatimElevation = $elevation . $elev_units;
	}
	elsif(($elevation !~ m/^-?[0-9]+/) && ($elev_units =~ m/.+/)){
		&log_change("ELEVATION poorly formatted or has only non-numeric data\t($elevation)\t($elev_units)\t$id\n");		#call the &log function to print this log message into the change log...
		$verbatimElevation = $CCH_elevationInMeters = $elevationInFeet = $elevationInMeters="";
	}		
	else {
		&log_change("ELEVATION problem\t($elevation)($elev_units)\t$id\n");
		$verbatimElevation = $CCH_elevationInMeters = $elevationInFeet = $elevationInMeters="";
	}

foreach($verbatimElevation){
	s/feet/ ft/g;
	s/ft/ ft/g;
	s/m/ m/g;
	s/`//g;
	s/([A-Za-z]+)/ $1/g;
	s/  +/ /g;
	s/^ *//;
	s/ *$//;

}


if (length($verbatimElevation) >= 1){

	if ($verbatimElevation =~ m/^(-?[0-9]+) ?m/){
		$elevationInMeters = $1;
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^(-?[0-9]+) ?f/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($verbatimElevation =~ m/^-?[0-9]+ ?- ?(-?[0-9]+) ?f/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("ELEVATION Check: '$verbatimElevation' has missing units, is non-numeric, or has typographic errors\t$id");
		$elevationInMeters="";
		$elevationInFeet="";
		$CCH_elevationInMeters = "";
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
#Source is a free text field so no editing required
my $lat_sum;
my $long_sum;
my $Check;
my $lat_decimal;
my $long_decimal;
my $hold;

#######Latitude and Longitude

	foreach ($lat_degrees,$lat_minutes,$lat_seconds,$long_degrees,$long_minutes,$long_seconds){
		s/NULL//g;
		s/  +/ /g;
		s/^ *//;
		s/ *$//;
	}

$verbatimLatitude = $lat_degrees ." " .  $lat_minutes . " ".  $lat_seconds;

$verbatimLongitude = $long_degrees ." " .  $long_minutes . " ".  $long_seconds;


foreach ($verbatimLatitude){
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/\*//g;
		s/,/ /g;
		s/-//g; #remove negative latitudes, we dont map specimens from southern hemisphere, so if "-" is present, it is an error
		s/deg\.?/ /;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
		
}

foreach ($verbatimLongitude){
		s/ø/ /g;
		s/'/ /g;
		s/\*//g;
		s/"/ /g;
		s/,/ /g;
		s/deg\.?/ /;
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
		 print "COORDINATE 2 $id\n";
		&log_change("COORDINATE decimals apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d +\d/) && ($verbatimLongitude =~ m/^\d\d +\d/)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		print "COORDINATE 3 $id\n"; 
		&log_change("COORDINATE apparently reversed, switching latitude with longitude\t$id");
	}	
	elsif (($verbatimLatitude =~ m/^-?1\d\d$/) && ($verbatimLongitude =~ m/^\d\d/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		 print "COORDINATE 4 $id\n";
		&log_change("COORDINATE latitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d/) && ($verbatimLongitude =~ m/^\d\d$/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 5 $id\n";
		&log_change("COORDINATE longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^\d\d\./) && ($verbatimLongitude =~ m/^-?1\d\d\./)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
	print "COORDINATE 6 $id\n";
	}
	elsif (($verbatimLatitude =~ m/^\d\d \d/) && ($verbatimLongitude =~ m/^-?1\d\d \d/)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
	#print "COORDINATE 7 $id\n";
	}
	elsif (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d/)){
			$latitude = sprintf ("%.3f",$verbatimLatitude); #convert to decimal, should report cf. 38.000
			$longitude = $verbatimLongitude; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
	print "COORDINATE 8 $id\n";
			&log_change("COORDINATE latitude integer degree only: $verbatimLatitude converted to $latitude==>$id");
	}
	elsif (($verbatimLatitude =~ m/^\d\d/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
			$latitude = $verbatimLatitude; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
			$longitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 122.000
	print "COORDINATE 9 $id\n";
			&log_change("COORDINATE longitude integer degree only: $verbatimLongitude converted to $longitude==>$id");
	}	
	elsif ((length($verbatimLatitude) == 0) && (length($verbatimLongitude) == 0)){
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	#print "COORDINATE NULL $id\n";
	}
	else {
		&log_change("COORDINATE: Coordinate conversion problem for $id\t$verbatimLatitude\t--\t$verbatimLongitude\n");
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
		print "COORDINATE PROBLEM \t$verbatimLatitude\t--\t$verbatimLongitude\t$id\n";
	}

#NULL coordinates that are only integer degrees, these are highly inaccurate and not useful for mapping
	if (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
		$decimalLatitude=$latitude = "";
		$decimalLongitude=$longitude = "";
		print "COORDINATE DEGREE ONLY\t$id\n";
		&log_change("COORDINATE decimal Lat/Long only to degree, now NULL: $verbatimLatitude\t--\t$verbatimLongitude\n");
	}


foreach ($latitude, $longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s$//;
}	

#use combined Lat/Long field format for CHSC

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
		&log_change("COORDINATE: No coordinates for $id\n");
		$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
}
else {
			&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
}



#check datum
if(($verbatimLatitude=~/\d/ && $verbatimLongitude=~/\d/)){ #If decLat and decLong are digits
	if ($datum){ #report is datum is present
		s/1984//g;
		s/ +//;
		s/  +/ /g;
		s/NULL/not recorded/g;
		s/^ +//g;
		s/ +$//g;

	}
	else {
		$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
	}
}	

#check georeference source
if ((length($lat_degrees) >= 1) && (length($long_degrees) >= 1) && (length($georeferenceSource) == 0)){
	$georeferenceSource = $LatLongAdded;
		if($LatLongAdded=~m/yes/i){
			$georeferenceSource="Coordinates added by CHSC, DMS conversion by CCH loading script";
		}
		elsif($LatLongAdded=~m/no/i){
			$georeferenceSource="Coordinates from specimen label, DMS conversion by CCH loading script";
		}
		else{
			$georeferenceSource="";
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
		&log_change("coordinates set to null for $id, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude = $decimalLongitude = $georeferenceSource = $datum="";	#and set $decLat and $decLong to ""  
	}
}
else {
		if((length($decimalLatitude) == 0)  && (length($decimalLongitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}
	
	

foreach ($errorRadius){
	s/NULL//;
	s/  +/ /g;
	s/,//g;
	s/^ *//g;
	s/ *$//g;
}
foreach ($errorRadiusUnits){
	s/NULL//;
	s/  +/ /g;
	s/\.//g;
	s/^ *//g;
	s/ *$//g;
}

##############TRS
foreach($TRS){
	s/NULL//;
	s/,/ /g;
	s/\./ /g;
	s/[Ss]ecf/Sec/g;
	s/  +/ /g;
	s/^ *//g;
	s/ *$//g;

}


#######Notes (dwc occurrenceRemarks) and Other_Data
#Macromorphology, including abundance
my $note_string;

foreach ($occurrenceRemarks){
	s/NULL//;
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/×/X/;
	s/^ *//g;
	s/ *$//g;
	s/'$//;
	s/  +/ /g;
}

foreach ($informationWithheld){
	s/NULL//;
	s/'$//g;
	s/^ *//;
	s/ *$//;
	s/  +/ /;
}

foreach ($other){
	s/NULL//;
	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
}

#format note_string correctly
	if ((length($informationWithheld) >= 1) && (length($other) == 0)){
		$note_string="$informationWithheld";
	}
	elsif ((length($informationWithheld) == 0) && (length($other) >= 1)){
		$note_string="Other Notes: $other";
	}
	elsif ((length($informationWithheld) >= 1) && (length($other) >= 1)){
		$note_string="$informationWithheld| Other Notes: $other";
	}
	elsif ((length($informationWithheld) == 0) && (length($other) == 0)){
		$note_string="";
	}
	else{
		&log_change("NOTES: problem with notes field\t$id($informationWithheld| Other Notes: $other");
		$note_string="";
	}

            print OUT <<EOP;

Accession_id: $id
Name: $scientificName
Date: $eventDate
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
Habitat: $occurrenceRemarks
Associated_species:
T/R/Section: $TRS
USGS_Quadrangle: $topo_quad
UTM: 
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance: $errorRadius
Max_error_units: $errorRadiusUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Notes: $note_string
Cultivated: $cultivated
Hybrid_annotation: $hybrid_annotation
Annotation: $det_string

EOP
++$included;
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


    my $file_in = 'CHSC_out.txt';	#the file this script will act upon is called 'CATA.out'
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
sub get_cult {#this section is added for the cultivated processing by adding this line using search and replace after each "<CurrentName_with_all_fields>"
#<CULT>N</CULT>
		my $par = shift;
		
	if($par=~/<CULT>(.*)<\/CULT>/){
			return $1;
		}
	else{
		return "NULL";
	}		
}
sub get_id {
#<Accession>114905</Accession>
		my $par = shift;
		
	if($par=~/<Accession>(\d+)<\/Accession>/){
			return $1;
		}
		else{
		return "NULL";
		}		
}
sub get_genus {
#<CGenus>Amelanchier</CGenus>	
		my $par = shift;

	if($par=~/<CGenus>(.*)<\/CGenus>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_species {
#<CSpecificEpithet>utahensis</CSpecificEpithet>	
		my $par = shift;

	if($par=~/<CSpecificEpithet>(.*)<\/CSpecificEpithet>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_rank {
#<CRank>ssp.</CRank>	
		my $par = shift;

		if($par=~/<CRank>(.*)<\/CRank>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_subtaxon {
#<CInfraspecificName>montevidensis</CInfraspecificName>	
		my $par = shift;

	if($par=~/<CInfraspecificName>(.*)<\/CInfraspecificName>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_collector {
#<Collector>D.G. Kelch</Collector>
		my $par = shift;

	if($par=~/<Collector>(.*)<\/Collector>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_other_coll {
#<MoreCollectors>D. L. Haws</MoreCollectors>
		my $par = shift;

	if($par=~/<MoreCollectors>(.*)<\/MoreCollectors>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_recordNumber {
#<CollectionNumber>11510</CollectionNumber>
		my $par = shift;

	if($par=~/<CollectionNumber>(.*)<\/CollectionNumber>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_eventDate {
#<Date>2004-05-24T00:00:00</Date>
		my $par = shift;

	if($par=~/<Date>(.*)<\/Date>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_country {
#<GeoPrimaryDivision>United States</GeoPrimaryDivision>
		my $par = shift;

	if($par=~/<GeoPrimaryDivision>(.*)<\/GeoPrimaryDivision>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_stateProvince {
#<GeoSecondaryDivision>United States</GeoSecondaryDivision>
		my $par = shift;

	if($par=~/<GeoSecondaryDivision>(.*)<\/GeoSecondaryDivision>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_county {
#<GeoTertiaryDivision>San Francisco</GeoTertiaryDivision>
		my $par = shift;

	if($par=~/<GeoTertiaryDivision>(.*)<\/GeoTertiaryDivision>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_TRS {
#<TownshipAndRange>T33N  R04W S24</TownshipAndRange>
		my $par = shift;

	if($par=~/<TownshipAndRange>(.*)<\/TownshipAndRange>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_elevation {
#<Elevation>366</Elevation>
		my $par = shift;

	if($par=~/<Elevation>(.*)<\/Elevation>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_elev_units {
#<ElevationUnits>ft.</ElevationUnits>
		my $par = shift;

	if($par=~/<ElevationUnits>(.*)<\/ElevationUnits>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_locality {
#<Locality>Vicinity of Blairsden.</Locality>
		my $par = shift;

	if($par=~/<Locality>(.*)<\/Locality>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_lat_degrees {
#<LatitudeDegree>39</LatitudeDegree>
		my $par = shift;

	if($par=~/<LatitudeDegree>(.*)<\/LatitudeDegree>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_lat_minutes {
#<LatitudeMinutes>10</LatitudeMinutes>
		my $par = shift;

	if($par=~/<LatitudeMinutes>(.*)<\/LatitudeMinutes>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_lat_seconds {
#LatitudeSeconds>1</LatitudeSeconds>
		my $par = shift;

	if($par=~/<LatitudeSeconds>(.*)<\/LatitudeSeconds>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_lat_dir {
#<LatitudeDirection>N</LatitudeDirection>
		my $par = shift;

	if($par=~/<LatitudeDirection>(.*)<\/LatitudeDirection>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_long_degrees {
#<LongitudeDegree>122</LongitudeDegree>
		my $par = shift;

	if($par=~/<LongitudeDegree>(.*)<\/LongitudeDegree>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_long_minutes {
#<LongitudeMinutes>31</LongitudeMinutes>
		my $par = shift;

	if($par=~/<LongitudeMinutes>(.*)<\/LongitudeMinutes>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_long_seconds {
#<LongitudeSeconds>44</LongitudeSeconds>
		my $par = shift;

	if($par=~/<LongitudeSeconds>(.*)<\/LongitudeSeconds>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_long_dir {
#<LongitudeDirection>W</LongitudeDirection>
		my $par = shift;

	if($par=~/<LongitudeDirection>(.*)<\/LongitudeDirection>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_datum {
#<LatLongDatum>NAD 1983</LatLongDatum>
		my $par = shift;

	if($par=~/<LatLongDatum>(.*)<\/LatLongDatum>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_errorRadius {
#<LatLongPrecision>0.25</LatLongPrecision>
		my $par = shift;

	if($par=~/<LatLongPrecision>(.*)<\/LatLongPrecision>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_errorRadiusUnits {
#<LatLongPrecisionUnits>mi.</LatLongPrecisionUnits>
		my $par = shift;

	if($par=~/<LatLongPrecisionUnits>(.*)<\/LatLongPrecisionUnits>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_LatLongAdded {
#<LatLongAddedCheck>yes</LatLongAddedCheck>
		my $par = shift;

	if($par=~/<LatLongAddedCheck>(.*)<\/LatLongAddedCheck>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_topo_quad {
#<USGSQuadrangle>Kettle Peak</USGSQuadrangle>
		my $par = shift;

	if($par=~/<USGSQuadrangle>(.*)<\/USGSQuadrangle>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_notes { 
#made into notes field, this is not just habitat or ecology, 
#it is associates, macromorphology, plant description, population biology, habitat, and general notes all combined  
#in one field of multiple sentences and phrases, separated by punctuation, mostly periods and spaces
#<Ecology>Ocassional here. Flowers a creamy white- yellow. On Heteromeles arbutifolia.</Ecology>
		my $par = shift;

	if($par=~/<Ecology>(.*)<\/Ecology>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_other { 
#misc. information about the label and where the specimen came from, not a typical notes field, placed in Other_data herein 
#<Notes>Label says: California Academy of Sciences.</Notes>
		my $par = shift;

	if($par=~/<Notes>(.*)<\/Notes>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}

sub get_AnnoRank { 
#<AnnoYesNo>0</AnnoYesNo>
		my $par = shift;

	if($par=~/<AnnoYesNo>(.*)<\/AnnoYesNo>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_identifiedBy { 
#<CDeterminedBy>A. O. Tucker</CDeterminedBy>
		my $par = shift;

	if($par=~/<CDeterminedBy>(.*)<\/CDeterminedBy>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
sub get_dateIdentified { 
#<DeterminedDate>2011-09-09T00:00:00</DeterminedDate>
		my $par = shift;

	if($par=~/<DeterminedDate>(.*)<\/DeterminedDate>/){
		return $1;
	}		
	else{
		return "NULL";
	}		
			
}
