#useful one liners for debugging:
#perl -lne '$a++ if /Accession_id: CAS-BOT-BC\d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id: CAS\d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id: DS\d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id:/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Decimal_latitude: \d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Cultivated: P/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Cultivated: [^P]+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id: CAS\d+/; END {print $a+0}' CAS_out.txt

#perl -lne '$a++ if /Collector: 1/; END {print $a+0}' YOSE_out.txt
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

open(OUT,">/JEPS-master/CCH/Loaders/YOSE/YOSE_out.txt") || die;
open(OUT2,">/JEPS-master/CCH/Loaders/YOSE/YOSE_dwc.txt") || die;

#print OUT2 "Accession_id\tscientificName\tverbatimEventDate\tEJD\tLJD\trecordedBy\tother_coll\tverbatimCollectors\tCNUM\tCNUM_prefix\tCNUM_suffix\tcountry\tstateProvince\tcounty\tlocality\thabitat\tTRS\tdecimalLatitude\tdecimalLongitude\tdatum\tgeoreferenceSource\terrorRadius\terrorUnits\tCCH_elevationInMeters\tverbatimElevation\tverbatim_county\tMacromorphology\tNotes\tCultivated\tHybrid_annotation\tAnnotation\tGUID\n";

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $count_record;
my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;
my $ACC;
my $YOSE_CO;
my $ALTER;
my %ALTER;

my $file = '/JEPS-master/CCH/Loaders/YOSE/FY2014_CCH_data_MOD.txt';

###open the county conversion file, unique to YOSE
open(IN, "/JEPS-master/CCH/Loaders/YOSE/YM_out_county.txt") || die "couldnt open YM_out_county.txt\n";
while(<IN>){
	chomp;
	($ACC, $YOSE_CO)=split(/\t/);
	$ALTER{$ACC}=$YOSE_CO;

}
close(IN);

#####process the file
###File arrives as an Excel xlsx file, with a lot of unfortunate in-cell line breaks
###Use find replace to remove "\n" to remove in-cell line breaks
###then save as a utf8 tab-delimited text file
###############


open(IN,$file) || die;
Record: while(<IN>){

	chomp;

	$line_store=$_;
	++$count;


#fix some data quality and formatting problems that make import of fields of certain records impossible
	#s/\xc2\xb0/ deg. /g;
	s///g; # or x{Ob} or \x0b
	s/�//g;
	s/°/ deg./g;
	s/Á/A/g;
	s/é/e/g;
	s/’/'/g;
	s/ó|ö/o/g;
#skipping: problem character detected: s/\xc2\xb0/    /g   ° ---> 170°	220°	260°	270°	225°	140°	105°	230°	110°	205°	185°	310°	300°	280°	290°	210°	200°	250°	292°	202°	
#skipping: problem character detected: s/\xc3\x81/    /g   Á ---> Á.	
#skipping: problem character detected: s/\xc3\xa9/    /g   é ---> Hultén,	LHér.	
#skipping: problem character detected: s/\xc3\xb3/    /g   ó ---> López	
#skipping: problem character detected: s/\xc3\xb6/    /g   ö ---> Löve	Löve,	
#skipping: problem character detected: s/\xe2\x80\x99/    /g   ’ ---> HENNESSY’S	WATER’S	


			s/\cK/ /g; #delete some hidden windows line breaks that do not remove themselves with saving the file as utf-8
			
        if ($. == 1){#activate if need to skip header lines
			next;
		}
		
my $GUID;
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
my $accession_number;
my $obj_science;
my $other_number;
my $habitat_type;
my $waterbody;
my $typeStatus;
my $slope;
my $aspect; 
my $tempName;
my $tempCollector;
my $UTM;
my $verbatimCoordinates;
my $combined_collectors;

	my @fields=split(/\t/,$_,100);
	
	unless($#fields == 23){	#24 fields but first field is field 0 in perl

	&log_skip ("$#fields bad field number\t$_\n");
	++$skipped{one};
	next Record;
	}


#CULT	Catalog #	Accession #	Obj/Science	Collector	Collection Date	Collection #	Other Numbers	Identified By	Ident Date	Locality	County	State	Lat LongN/W	UTM Z/E/N	Habitat	Habitat/Comm	Elevation	Watrbody/Drain	Slope	Aspect	Assoc Spec	Type Specimen

#foreach (@columns){
#	s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Not ?[pP]rovided|Not ?[rR]ecorded) *$//;
#}

($other_number,
$cult,
$id,
$accession_number,
$tempName, #Obj/Science is the scientific name field
$tempCollector,
$verbatimEventDate,
$recordNumber,
$notes, #field Other Numbers is more like a notes field than a "alternate accession number" field
$identifiedBy,
$dateIdentified, #10
$location,
$county,
$stateProvince,
$verbatimCoordinates,  #there is only 1 lat/long field, so use this and then parse out longitude below
$UTM,
$habitat_type,
$habitat, #with these two, both go into habitat.
$verbatimElevation, #most have units, dean taylors are without units, but they appear to be all in feet.
$waterbody, #combine with locality
$slope,	#combine slope and aspect into $occurrenceRemarks   #20
$aspect, 
$associatedTaxa,
$typeStatus)=@fields;

################ACCESSION_ID#############
#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space
foreach($id){
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}

#Add prefix, 
#prefix already present in these data
$id=~s/^YOSE/YM-YOSE/;


#Remove duplicates
if($seen{$id}++){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}


##################Exclude known problematic specimens by id numbers, most from outside California and Baja California
#	if(($id=~/^(SD132484)$/) && ($tempCounty=~m/Humboldt/)){ #skip, out of state
#		&log_skip("COUNTY: County/State problem: 'ca. 4 mi W of Winnemucca' is in Nevada, not California ($id: $tempCounty, $locality)\n");	
#		++$skipped{one};
#		next Record;
#	}

#fix some really problematic records with data that is misleading and causing georeference errors

#if (($id =~ m/^(SD8210)$/) && ($tempCounty=~m/^(Lassen|Shasta)/i)){
#	$tempCounty = "San Diego"
#		if ($verbatimLatitude !~ m/32\./)){ 
#			$latitude = ""; #delete the persistently bad georeference if it maps to anything but this latitude, currently mapping to Lat 40.47
#			$longitude = "";
#		}
#	&log_change("COUNTY: county error, Cleveland was in Cuyamaca on June 19, 1881 in San Diego county, therefore it is likely that this is Eagle Peak, Sand Diego County and the county is wrongly entered as Lassen, changed to ==>$county\t$location\t--\t$id\n");
#	#the original is in error and was georeferenced in the buffer to Eagle Peak near Mount Lassen, and others commented to change the County to Shasta, which is out of the range of Umbellularia californica
#}
	
#####Annotations  (use when no separate annotation field)
	#format det_string correctly
my $det_rank = "current determination (uncorrected)";  #set to zero in data with only a single determination
my $det_name = $tempName;
my $det_determiner = $identifiedBy;
my $det_date = $dateIdentified;
my $det_stet;	
	
	if ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_date) == 0)){
		$det_string="$det_name, $det_determiner";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_date) >=1)){
		$det_string="$det_name, $det_determiner, $det_date";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_date) >=1)){
		$det_string="$det_name, $det_date";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($det_date) == 0)){
		$det_string="";
	}
	else{
		&log_change("ANNOT: det string problem:\t$det_rank: $det_name, $det_determiner, $det_date\n");
		$det_string="";
	}

#fix some problem punctuation common to all names in YOSE
foreach ($det_string){
	
	s/_+/ /g;
	s/  +/ /g;
	s/['"]//g;
	s/\(\?\)//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/ ssp\.? / subsp. /g;
	s/ var / var. /g;
}

#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published
if (($id =~ m/(YOSE65315)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE65315	YOSE-04950	Eburophyton __ __stenopetalum __ __ __radiatum	"SHARSMITH, CARL W."	07/13/1944	4888	"SHEET NO. 1971, HERB. ACCESS. NO.  4912"	Not Recorded		CREEK WEST OF TURTLEBACK DOME ABOVE WEST END WAWONA TUNNEL.	MARIPOSA	CA	Not Recorded		BY THE CREEK		5000 FT					
	$tempName =~ s/Eburophyton __ __stenopetalum __ __ __radiatum/Sedum __ __stenopetalum __ __ __radiatum/; #fix special case
	&log_change("TAXON: Scientific name error - genus name is an Orchid while species name is a Sedum, modified to \t$tempName\t--\t$id\n");
}
if (($id =~ m/(YOSE231940)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE231940	YOSE-06990	Isoetes __ __divaricata __ __ __divaricata	"Taylor, Dean --Colwell, Alison --Shevock, James et. al."	2009-28-Jul	20688		"Taylor, Dean"		Yosemite National Park: trail from Turner Meadow to Crescent Lake just E of the Madera County line	Madera	CA	37.57342/-119.56535		"granitics outcrops characterized by Holodiscus, growing on vernally wet sites where annual herb communities occur"		7950					
	$tempName =~ s/Isoetes __ __divaricata __ __ __divaricata/Navarretia __ __divaricata __ __ __divaricata/; #fix special case
	&log_change("TAXON: Scientific name error - genus name is an Isoetes while species name is a Navarretia, modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE231919)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE231919	YOSE-06990	Isoetes __ __viscida x A. nevadensis	"Taylor, Dean --Colwell, Alison --Hutten, M."	2009-10-Jul	20673		"Taylor, Dean"		"Yosemite National Park: Big Creek, about 1 stream mile above the crossing of the Chowchill Mountain Road, westerly side of the stream"	Mariposa	CA	37.51394/-119.66596		understory of mixed conifer forest; single isolated individual amidst a patch of Equisetum telmatia		4630					
	$tempName =~ s/Isoetes __ __viscida x A. nevadensis/Arctostaphylos __ __viscida x A. nevadensis/; #fix special case
	&log_change("TAXON: Scientific name error - genus name is an Isoetes while species name is a Arctostaphylos, modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE59868)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE59868	YOSE-04949	Penstemon __ __parishii __ __ __ __ __ __perideridia	"RODIN, ROBERT J."	08/ 5/1956	6103	SHEET NO. 2917	Not Recorded		TAMARACK FLAT	MARIPOSA	CA	Not Recorded		NOT RECORDED							
	$tempName =~ s/Penstemon __ __parishii __ __ __ __ __ __perideridia/Perideridia __ __parishii/; #fix special case
	&log_change("TAXON: Scientific name error - Penstemon parishii is not from California, species name is a Perideridia, modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE1719)$/) && (length($TID{$tempName}) == 0)){ 
#	YOSE1719	YOSE-00367	Senecio  __ __multiradiata	Unknown	Unknown	Unknown		Unknown	Unknown	Mount Dana		CA	Not Recorded									
	$tempName =~ s/Senecio +__ __multiradiata/Solidago __ __multiradiata/; #fix special case
	&log_change("TAXON: Scientific name error - genus name is an Senecio while species name is a Solidago, modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE119062|YOSE119061)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE119062	YOSE-06861	Erigeron __ __divergens __Torr. & A. Gray __ __ __ __ __hirsutus __Cronq.	"Grossenbacher, Dena - -McGlinchy, Maureen - -Grove, Sara - -Oliver, Martin"	6/27/2006	DG06-95B	UC1949699	"Strother, John"	2011	"East end of Pate Valley on North side of Tuolumne River, Grand Canyon of the Tuolumne. Datum: NAD83."	Tuolumne	CA		11//11/272677/4201492			1344 meters					
#N	YOSE119061	YOSE-06861	Erigeron __ __divergens __Torr. & A. Gray __ __ __ __ __hirsutus __Cronq.	"Grossenbacher, Dena - -McGlinchy, Maureen - -Grove, Sara - -Oliver, Martin"	6/27/2006	DG06-95B		"Strother, John"	2011	"East end of Pate Valley on North side of Tuolumne River, Grand Canyon of the Tuolumne. Datum: NAD83."	Tuolumne	CA		11//11/272677/4201492			1344 meters					
	$tempName =~ s/Erigeron __ __divergens __Torr\. & A\. Gray __ __ __ __ __hirsutus __Cronq\./Erigeron __ __divergens/; #fix special case
	&log_change("TAXON: Scientific name error - UC specimens are det as just E. divergens, hirsutus Cronq. was the variety from the original det and needs to be deleted, modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE118510|YOSE118511)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE118510	YOSE-06861	Erigeron __ __glacialis __(Nutt.) A. Nelson __ __ __ __ __callianthemus __(E. Greene) Cronq.	"Colwell, Alison - -Grossenbacher, Dena - -Grove, Sara - -Ward, Kimiora"	8/17/2006	AC06-380	UC1949584	"Strother, John"	2011	Upper Lyell Canyon about 0.25 mile North of Kuna Creek - Lyell Fork of the Tuolumne River confluence on West edge of meadow. Datum: NAD83. GPS Error: 5 M.	Tuolumne	CA		11/300778/4185575			2706 meters					
#N	YOSE118511	YOSE-06861	Erigeron __ __glacialis __(Nutt.) A. Nelson __ __ __ __ __callianthemus __(E. Greene) Cronq.	"Colwell, Alison - -Grossenbacher, Dena - -Grove, Sara - -Ward, Kimiora"	8/17/2006	AC06-380		"Colwell, Alison"	9/7/2006	Upper Lyell Canyon about 0.25 mile North of Kuna Creek - Lyell Fork of the Tuolumne River confluence on West edge of meadow. Datum: NAD83. GPS Error: 5 M.	Tuolumne	CA		11/300778/4185575			2706 meters					
	$tempName =~ s/Erigeron __ __glacialis __\(Nutt\.\) A\. Nelson __ __ __ __ __callianthemus __\(E\. Greene\) Cronq\./Erigeron __ __glacialis __ __ __ __ __glacialis/; #fix special case
	&log_change("TAXON: Scientific name error - UC specimens are det as just E. glacialis var. glacialis, var. callianthemus was the variety from the original det and needs to be deleted, modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE216972|YOSE216973)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE216972	YOSE-06932	Eurybia __ __integrifolia __(Nutt.) G.L. Nesom __ __ __ __ __occidentalis	"Colwell, Alison - -Grossenbacher, Dena - -Dennis, Lauren"	7/19/2007	07-126	UC1949500	"Strother, John"	2011	Slope above east margin of Benson Lake. Datum: NAD83. GPS Error: 3.2 meters	Tuolumne	CA		11/278695/4210564			2428 meters					
#N	YOSE216973	YOSE-06932	Eurybia __ __integrifolia __(Nutt.) G.L. Nesom __ __ __ __ __occidentalis	"Colwell, Alison - -Grossenbacher, Dena - -Dennis, Lauren"	7/19/2007	07-126		"Strother, John"	2011	Slope above east margin of Benson Lake. Datum: NAD83. GPS Error: 3.2 meters	Tuolumne	CA		11/278695/4210564			2428 meters					
	$tempName =~ s/Eurybia __ __integrifolia __\(Nutt\.\) G\.L\. Nesom __ __ __ __ __occidentalis/Eurybia __ __integrifolia/; #fix special case
	&log_change("TAXON: Scientific name error - UC specimens are det as just E. integrifolia, var. occidentalis was the variety from the original det and needs to be deleted, modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE59751)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE59751	YOSE-04949	Lupinus __ __BICOLOR __ __ __ __ __ __breweri	"FIELD, EUGENE"	08/ 3/1965	10	SHEET NO. 2408	Not Recorded		TUOLUMNE MEADOWS LODGE.	TUOLUMNE	CA	Not Recorded		ABUNDANT IN SANDY SOIL. OPEN SUNNY AREAS. ASSOCIATED WITH GRASSES.		8600  FT					
	$tempName =~ s/Lupinus __ __BICOLOR __ __ __ __ __ __breweri/Lupinus __ __breweri __ __ __ __ __ __breweri/; #fix special case
	&log_change("TAXON: Scientific name error - Other duplicates at YOSE are det as Lupinus breweri, L. bicolor var. breweri is not a published combination, 'bicolor' was likely part of the pervious det, modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE59770|YOSE59771)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE59770	YOSE-04949	Lupinus __ __lobbii __ __ __ __ __ __danaus	"HOOD, MARY V."	07/20/1966	NONE GIVEN	SHEET NO. 2456	Not Recorded		MONO PASS	MONO	CA	Not Recorded		NONE GIVEN		10600 FT					
#N	YOSE59771	YOSE-04949	Lupinus __ __lobbii __ __ __ __ __ __danaus	"THOMAS, W.D."	09/12/1935	485	SHEET NO. 2457	Not Recorded		1/2 MILE S OF IRELAND LAKE.	TUOLUMNE	CA	Not Recorded		NONE GIVEN		11200 FT					
	$tempName =~ s/Lupinus __ __lobbii __ __ __ __ __ __danaus/Lupinus __ __lobbii/; #fix special case
	&log_change("TAXON: Scientific name error - Lupinus lobbii var. danaus is not a published combination, 'danaus' was likely part of the previous det, possibly 'Lupinus lyallii var. danaus', modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE231938|YOSE231941)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE231938	YOSE-06990	Micranthes __ __bryophora __ __ __ __ __ __bryophora	"Taylor, Dean --Colwell, Alison --Shevock, James et. al."	2009-28-Jul	20687		"Taylor, Dean"		Yosemite National Park: trail from Turner Meadow to Crescent Lake just E of the Madera County line	Madera	CA	37.57342/-119.56535		"granitics outcrops characterized by Holodiscus, growing on vernally wet sites where annual herb communities occur"		7950					
#N	YOSE231941	YOSE-06990	Micranthes __ __bryophora __ __ __ __ __ __bryophora	"Taylor, Dean --Colwell, Alison --Shevock, James et. al."	2009-28-Jul	20687	JEPS109368	"Taylor, Dean"		Yosemite National Park: trail from Turner Meadow to Crescent Lake just E of the Madera County line	Madera	CA	37.57342/-119.56535				7950					
	$tempName =~ s/Micranthes __ __bryophora __ __ __ __ __ __bryophora/Micranthes __ __bryophora/; #fix special case
	&log_change("TAXON: Scientific name error - No subtaxa within Micranthes bryophora, the synonym Saxifraga bryophora has subtaxa, and this error is due to a previous det, possibly 'Saxifraga bryophora var. bryophora', modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE67443)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE67443	YOSE-04950	Veronica __ __serpylifolia __ __ __ __ __ __unalaschensis	"MICHAEL, ENID"	07/24/1930	Not Provided	"SHEET NO. 3878, HERB. ACC. NO. 2442"	"SHARSMITH, CARL"	1942	MARIPOSA GROVE	MARIPOSA	CA	Not Recorded		OLD STREAM BED							
	$tempName =~ s/Veronica __ __serpylifolia __ __ __ __ __ __unalaschensis/Veronica __ __serpylifolia/; #fix special case
	&log_change("TAXON: Scientific name error - Veronica serpylifolia var. unalaschensis is not a published combination, 'unalaschensis' was likely was likely part of the previous det, possibly 'Veronica alpina var. unalaschensis', modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE63493)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE63493	YOSE-04950	Ceanothus __ __corymbosa	"ZENTMYER, GEORGE A."	07/ 7/1935	NOT RECORDED	"SHEET NO. 2593,  HERB. ACCESS. NO.  683"	Not Recorded		BOUNDARY HILL	MARIPOSA	CA	Not Recorded		NOT RECORDED							
	$tempName =~ s/Ceanothus __ __corymbosa/Ceanothus/; #fix special case
	&log_change("TAXON: Scientific name error - Ceanothus corymbosa is not a published name in TROPICOS, modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE1695)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE1695	YOSE-00364	Kalimeris __ __integrifolia	Unknown	Unknown	Unknown		Unknown	Unknown	Tenaya Lake		CA	Not Recorded									
	$tempName =~ s/Kalimeris __ __integrifolia/Aster __ __integrifolius/; #fix special case
	&log_change("TAXON: Scientific name error - Kalimeris integrifolia is a basionym of Aster integrifolius (Turcz. ex DC.) Franch., this determination possibly mistaken for Aster integrifolius Nutt., modified to \t$tempName\t--\t$id\n");
}

if (($id =~ m/(YOSE1559)$/) && (length($TID{$tempName}) == 0)){ 
#N	YOSE1559	YOSE-00345	Rubus __ parvifolius	Unknown	7/22/1924	Unknown		Unknown	Unknown	"Yosemite, California"		CA	Not Recorded									
	$tempName =~ s/Rubus __ parvifolius/Rubus __ __parviflorus/; #fix special case
	&log_change("TAXON: Scientific name error - Rubus parvifolius is not known from California, this determination likely a typo for Rubus parviflorus, modified to \t$tempName\t--\t$id\n");
}




##########Begin validation of scientific names
#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($tempName){
	s/ species$//g;
		s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
	s/  +/ /g;
	s/['"]//g;
	s/\(\?\)//g;
	s/;$//g;
	s/cf\.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/ ssp\.? / subsp. /g;
	s/ var / var. /g;
	s/ +var\. +/#%var.#%/g;
	s/ +subsp\. +/#%subsp.#%/g;

#fix some problem names
	s/Oenothera__ elata__ hookeri/Oenothera>>elata__ __ __hookeri/;
	s/Symphyotrichum __spathulatum __ __ __yosemitanum/Symphyotrichum>>spathulatum __ __ __yosemitanum/;
	s/Ericameria monocephala/Ericameria>>monocephala/;
	s/Phacelia __ __hastata __Lehm. __ __compacta/Phacelia>>hastata __ __ __compacta/;
	s/Allium yosemitense/Allium>>yosemitense/;
	s/Rhus trilobata/Rhus>>trilobata/;
	s/Nemophila _ __parviflora/Nemophila>>parviflora/;
	s/Mimulus floribundus/Mimulus>>floribundus/;
	s/Glyceria pauciflora/Glyceria>>pauciflora/;
	s/Poa leptocoma/Poa>>leptocoma/;
	s/Lupinus arbustus/Lupinus>>arbustus/;
	s/Symphoricarpos vaccinioides/Symphoricarpos>>vaccinioides/;
	s/Stuckenia filiformis/Stuckenia>>filiformis/;
	s/Subularia aquatica/Subularia>>aquatica/;
	s/Viola L. __Viola/Viola/;
	s/Lupinus polyphyllus/Lupinus>>polyphyllus/;
	s/Viola purpurea/Viola>>purpurea/;
	s/Viola sheltonii/Viola>>sheltonii/;
	s/Senecio __ __ __clarkianus/Senecio>>clarkianus/;
	s/Senecio __ __ __oreopolus/Senecio>>oreopolus/;
	s/Scutelarria tuberosa/Allium>>yosemitense/;
	s/Haplopappus apargioides/Allium>>yosemitense/;
	s/Lupinus arbustus subsp. silvicola/Lupinus>>arbustus __ __ __silvicola/;
	s/Wyethia angustifolia/Wyethia>>angustifolia/;
	s/Streptanthus __tortuosus/Streptanthus>>tortuosus/;
	s/Rudbeckia __ hirta/Rudbeckia>>hirta/;
	s/Rudbeckia __ californica/Rudbeckia>>californica/;
	s/Agrostis __scabra/Agrostis>>scabra/;
	s/Cerastium _+ _+arvense/Cerastium>>arvense/;
	s/Acer __glabrum/Acer>>glabrum/;
	s/Pinus __monticola/Pinus>>monticola/;
	s/Arabis __[Xx] __divaricarpa __Nelson/Arabis>>divaricarpa __Nelson/;
	s/Ptilagrostis __kingii/Ptilagrostis>>kingii/;
	s/Phacelia __hastata/Phacelia>>hastata/;
	s/brachyphylla __Schultes & Schultes f./brachyphylla __ /;
	s/brachyphylla __Schult. & Schult. __ __f. /brachyphylla __ __ __/;
	s/___ ___/__ __/g;
	s/__ __/ __ __/g;
 	#s/__ __$//;
	

	s/Senecio __Senecio scorzonella/Senecio>>scorzonella/;

	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
	}

#format names that are unique to these data and possible other NPS collections
#the _ character is used to delimit between ssp and var names.  the number of "_" seems to indicate which rank.  
#its possible these are missing data fields in the object fields of the home database but who knows.
#
if($tempName=~s/^([A-Za-z]+) \b__ __ ([a-zA-Z-]+)/$1>>$2/){
	
	#warn "1a. Species found and labeled: $tempName\n";
	&log_change("TAXON: species found and labeled $tempName");

}
elsif($tempName=~s/^([A-Z]+) \b__ __([A-Z-]+)/$1>>$2/){
	
	#warn "1b. Species found and labeled: $tempName\n";
	&log_change("TAXON: species found and labeled $tempName");

}
elsif($tempName=~s/^([A-Z][a-z]+)\b__ __([a-z-]+)/$1>>$2/){
	
	warn "1c. Species found and labeled: $tempName\n";
	&log_change("TAXON: species found and labeled $tempName");

}
elsif($tempName=~s/^([A-Z][a-z]+) \b__ __([a-zA-Z-]+)/$1>>$2/){
	
	#warn "1d. Species found and labeled: $tempName\n";
	&log_change("TAXON: species found and labeled $tempName");

}
elsif($tempName=~s/^([A-Za-z]+)\b__ __ ([a-zA-Z-]+)/$1>>$2/){
	
	warn "1e. Species found and labeled: $tempName\n";
	&log_change("TAXON: species found and labeled $tempName");
}



if($tempName=~s/([a-z]) \b__ \b__ \b__ \b__ \b__ \b__([a-z])/$1#%var.#%$2/){

	#warn "2. Variety Found and labeled: $tempName\n";
	&log_change("TAXON: variety Found and labeled $tempName");

}
elsif($tempName=~s/([a-z]) \b__ \b__ \b__ \b__ \b__([a-z])/$1#%var.#%$2/){

	#warn "3. Variety Found and labeled: $tempName\n";
	&log_change("TAXON: variety Found and labeled $tempName");

}
elsif($tempName=~s/([A-Z]) \b__ \b__ \b__ \b__ \b__ \b__([a-z])/$1#%var.#%$2/){

	#warn "4. Variety Found and labeled: $tempName\n";
	&log_change("TAXON: variety Found and labeled $tempName");

}
elsif ($tempName=~s/([a-z]) \b__ \b__ \b__([a-z])/$1#%subsp.#%$2/){
		#warn "5. Subspecies Found and labeled: $tempName\n";
	&log_change("TAXON: subspecies Found and labeled $tempName");

}
elsif ($tempName=~s/([a-z])\b__ \b__ \b__([a-z])/$1#%subsp.#%$2/){
		warn "6. Subspecies Found and labeled: $tempName\n";
	&log_change("TAXON: subspecies Found and labeled $tempName");

}
elsif ($tempName=~s/([A-Z]+) \b__ \b__ \b__([a-z])/$1#%subsp.#%$2/){
		warn "7. Subspecies Found and labeled: $tempName\n";
	&log_change("TAXON: subspecies Found and labeled $tempName");

}
elsif ($tempName=~s/(>>sp.|>>sp. [Nn]ov\.?| sp\.)$//){
		#warn "8. 'sp.' unknown found and labeled: $tempName\n";
	&log_change("TAXON: subspecies Found and labeled $tempName");

}




#parse name elements
if($tempName =~ m/^([A-Z-]+)>>([A-Za-z-]+)[ _]+([^#%]+)$/){
	$name = "$1 $2 $3";
	$name =~ s/ ?__ ?/ /g; #delete stray __
	#warn "1. Name found and modified: $tempName==>$name\n";
	&log_change("TAXON: name found and modified: $tempName==>$name");
	
}
elsif($tempName =~ m/^([A-Z][a-z-]+)>>([a-z-]+)[ _]+([^#%]+)$/){
	$name = "$1 $2 $3";
	$name =~ s/ ?__ ?/ /g;
	#warn "2. Name found and modified: $tempName==>$name\n";
	&log_change("TAXON: name found and modified: $tempName==>$name");
	
}
elsif ($tempName =~ m/^([A-Z-]+)>>([A-Za-z-]+)[ _]+[^#%]+ ?#%(var.|subsp.)#%(.*)/){
	$name = "$1 $2 $3 $4";
	$name =~ s/ ?__ ?/ /g;
	warn "3. Name found and modified: $tempName==>$name\n";
	&log_change("TAXON: name found and modified: $tempName==>$name");
}
elsif ($tempName =~ m/^([A-Z-]+)>>([A-Za-z-]+)#%(var.|subsp.)#%(.*)/){
	$name = "$1 $2 $3 $4";
	warn "4. Name found and modified: $tempName==>$name\n";
	&log_change("TAXON: name found and modified: $tempName==>$name");
}
elsif ($tempName =~ m/^([A-Z][a-z-]+)>>([A-Za-z-]+)[ _]+[^#%]+ ?#%(var.|subsp.)#%(.*)/){
	$name = "$1 $2 $3 $4";
	$name =~ s/ ?__ ?/ /g;
	#warn "5. Name found and modified: $tempName==>$name\n";
	&log_change("TAXON: name found and modified: $tempName==>$name");
}
elsif ($tempName =~ m/^([A-Z][a-z-]+)>>([A-Za-z-]+)#%(var.|subsp.)#%([a-z]+.*)/){
	$name = "$1 $2 $3 $4";
	$name =~ s/ ?__ ?/ /g;
	#warn "6. Name found and modified: $tempName==>$name\n";
	&log_change("TAXON: name found and modified: $tempName==>$name");
}
elsif($tempName =~ m/^([A-Z][a-z-]+)>>([A-Za-z-]+)$/){
	$name = "$1 $2";
	#warn "7. Name found and modified: $tempName==>$name\n";
	&log_change("TAXON: name found and modified: $tempName==>$name");
}
elsif($tempName =~ m/^([A-Z]+)>>([A-Z-]+)$/){
	$name = "$1 $2";
	warn "8. Name found and modified: $tempName==>$name\n";
	&log_change("TAXON: name found and modified: $tempName==>$name");
}
elsif($tempName =~ m/^([A-Z][a-z-]+)>?>? *$/){#name just a genus or family
	$name = $1;
	#warn "9. Name found and modified: $tempName==>$name\n";
	&log_change("TAXON: name found and modified: $tempName==>$name");
}
else{
	warn "Name problem: $tempName\n";
	&log_change("TAXON: name problem: $tempName");
}

#remove all cap names
$name = ucfirst(lc$name);

#format hybrid names
if($name=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
	$hybrid_annotation=$name;
	warn "Hybrid Taxon: $1 removed from $name\n";
	&log_change("Hybrid Taxon: $1 removed from $name");
	$name=$1;
}
else{
	$hybrid_annotation="";
}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#the name is only corrected herein and not global; allows name to pass through to CCH if name is ever published
#the original determination is preserved in the $det_string process above so users can see what name is on original label

#if (($id =~ m/^(SD27856|SD43604|SD48503|SD6100)$/) && (length($TID{$name}) == 0)){ 
#	$name =~ s/Styrax redivivus subsp\. redivivus/Styrax officinalis subsp. redivivus/;
#	&log_change("Scientific name not published: Styrax redivivus subsp. redivivus modified to priorable name at same rank:\t$name\t--\t$id\n");
#}

## finish validating names

#####process taxon names

$scientificName = &strip_name($name);

$scientificName = &validate_scientific_name($scientificName, $id);

#####process cultivated specimens			
# flag taxa that are known cultivars that should not be added to the Jepson Interchange, add "P" for purple flag to Cultivated field	
## regular Cultivated parsing

		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("specimen likely not cultivated, purple flagging skipped: $scientificName\t--\t$id\n");
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection)/i) || ($habitat =~ m/(cultivated from|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
		
		elsif ($cultivated !~ m/^P$/){		
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			#&log_change("Taxon skipped purple flagging: $cultivated\t--\t$scientificName\n");
			$cultivated = "";
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

foreach ($verbatimEventDate){
	s/^ *//g;
	s/  +/ /g;
	s/'//g;
	s/ *$//g;

	
}

$eventDateAlt = $verbatimEventDate; 

foreach ($eventDateAlt){
		s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
#	s/\./ /g;	#delete periods after Month abbreviations
	s/\//-/g;	#convert / to -

	s/ and /-/g;
	s/&/-/g;
	s/^-+//g;
	s/-+/-/g;
	s/ +//g;
	s/ +$//g;
	s/^ +//g;
	s/\d+-\d+-0000//; #NULL dates with years 0000
	s/07-20-1066/07-20-1966/; #YOSE60061
	s/l936/1936/;
	s/JUL,1939/JUL1939/;
}


#fix some really problematic date records




#continue date parsing


	if($eventDateAlt=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	warn "(1)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^(\d\d)-(\d\d)-([0-9]{4})/){	#added to SDSU, if eventDate is in the format ##-##-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(2)$eventDateAlt\t$id";
	}
		elsif($eventDateAlt=~/^(\d\d)-(\d)-([0-9]{4})/){	#added to YOSE, if eventDate is in the format ##-#-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(2b)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{1})-([0-9]{1,2})-([0-9]{4})/){	#added to SDSU, if eventDate is in the format #-##?-####, most appear that first # is month 
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(3)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{1,2})-([0-9]{4})/){	#added to YOSE, if eventDate is in the format #-####, most appear that first # is month 
		$YYYY=$3; 
		$MM=$1; 
		$DD="1";
		$MM2 = $1;
		$DD2 = "28";
	warn "(3b)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([Ss][uU][Mm]+[Rr])([0-9]{4})/) {#YOSE only
		$YYYY = $2;
		$MM = "6";
		$DD = "1";
		$MM2 = "8";
		$DD2 = "31";
	warn "(16b)$eventDateAlt\t$id";
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
	warn "(2c)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]+([0-9]{4})$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(5)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Z][A-Z][A-Z])([0-9]{4})/){#YOSE only
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(5b)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]+([0-9]{2})[- ]*([0-9]{4})$/){
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
	elsif ($eventDateAlt=~/^([0-9]{4})-([0-9]{1,2})[- ]+([A-Za-z]+)$/){
		$MM=$3;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = $2;
	#warn "(19b)$eventDateAlt\t$id";
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


#$MM2= $DD2 = ""; #set late date to blank if only one date exists
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $MM2, $DD2, $id);
#warn "$formatEventDate\t--\t$EJD, $LJD\t--\t$id";
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);

###############COLLECTORS

foreach ($tempCollector){
	#	s/.*(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
	s/'$//g;
	s/"//g;
	s/\[//g;
	s/\]//g;
	s/\)//g;
	s/\(//g;
	s/\?//g;
	s/ - -/ --/g;
	s/s\. n\. / /g;
	s/, with/ with/;
	s/ w\/ ?/ with /g;
	s/, M\. ?D\.//g;
	s/, Jr\./ Jr./g;
	s/, Jr/ Jr./g;
	s/, Esq./ Esq./g;
	s/, Sr\./ Sr./g;
	s/(a-z) et al./$1, et. al./g;
	s/^'//g;
	s/\./\. /g;
	s/ , /, /g;


#fix some unique problem cases	
	s/McINTYRE, ROBERT/MCINTYRE, ROBERT/;
	s/Eugene\./Eugene/i;
	s/CLAUSEN, ROBERT T\. AND HAROLD TRAPIDO/ROBERT T. CLAUSEN AND HAROLD TRAPIDO CLAUSEN/;
	s/ED. MICHAEL/E. MICHAEL/;
	s/EMIL. ERNST/EMIL ERNST/;
	s/HGW, JAK/H. G. W. & J. A. K./;
	s/HANSEN, SHERMAN\/LINT, HAROLD/HANSEN, SHERMAN --LINT, HAROLD/;
	s/MICHAEL, CHARLES & ENID/MICHAEL, CHARLES & MICHAEL, ENID/;
	s/A\. S\. B\. & MICHAEL, ENID/A. S. B. & Enid Michael/;
	s/ADAMS\. LOWELL/Lowell Adams/;
	s/Alison Colwell --Taylor, Dean --Grossenbacher, Dena/Alison Colwell AND Taylor, Dean --Grossenbacher, Dena/;
	s/BALL, CARLETON, R./Carleton R. Ball/;
	s/BELLUE SP/Bellue/;
	s/BRYANT DR\./Bryant/;
	s/C\. C\. C\. FOR MICHAEL, ENID/Enid Michael/;
	s/CLASUEN, ROB\. T\. & TRAPIDO, HAR\./R. T. Clausen AND H. Trapido/;
	s/COLWELL, ALISON --COULTER, CHARLOTTE --COMPTON, JEFF/Alison Colwell AND COULTER, CHARLOTTE --COMPTON, JEFF/;
	s/COLWELL, ALISON --COULTER, CHARLOTTE --MOORE, PEGGY/Alison Colwell AND COULTER, CHARLOTTE --MOORE, PEGGY/;
	s/COLWELL, ALISON --GROSSENBACHER, DENA --ACREE, LISA/Alison Colwell AND GROSSENBACHER, DENA --ACREE, LISA/;
	s/COLWELL, ALISON --GROSSENBACHER, DENA --DAHLER, DAVID/Alison Colwell AND GROSSENBACHER, DENA --DAHLER, DAVID/;
	s/COLWELL, ALISON --GROSSENBACHER, DENA --MOORE, PEGGY/Alison Colwell AND GROSSENBACHER, DENA --MOORE, PEGGY/;
	s/COLWELL, ALISON --GROSSENBACHER, DENA --MOORE, PEGGY --WANAMAKER, HOLLY/Alison Colwell AND GROSSENBACHER, DENA --MOORE, PEGGY --WANAMAKER, HOLLY/;
	s/COLWELL, ALISON --GROSSENBACHER, DENA --MULLIGAN, ED/Alison Colwell AND GROSSENBACHER, DENA --MULLIGAN, ED/;
	s/COLWELL, ALISON --GROSSENBACHER, DENA --WANAMAKER, HOLLY/Alison Colwell AND GROSSENBACHER, DENA --WANAMAKER, HOLLY/;
	s/COLWELL, ALISON --GROSSENBACHER, DENA --WANAMAKER, HOLLY --MOORE, PEGGY/Alison Colwell AND GROSSENBACHER, DENA --WANAMAKER, HOLLY --MOORE, PEGGY/;
	s/COLWELL, ALISON --GROSSENBACHER, DENA --WANAMAKER, HOLLY --RUSSELL, ANN --BERGAMASCHI, BRIAN --BERGAMASCHI, TOM/Alison Colwell AND GROSSENBACHER, DENA --WANAMAKER, HOLLY --RUSSELL, ANN --BERGAMASCHI, BRIAN --BERGAMASCHI, TOM/;
	s/COLWELL, ALISON --GROSSENBACHER, DENA --WENK, ELIZABETH/Alison Colwell AND GROSSENBACHER, DENA --WENK, ELIZABETH/;
	s/COLWELL, ALISON --MOORE, PEGGY --GROSSENBACHER, DENA/Alison Colwell AND MOORE, PEGGY --GROSSENBACHER, DENA/;
	s/COLWELL, ALISON --MOORE, PEGGY --GROSSENBACHER, DENA --WANAMAKER, HOLLY/Alison Colwell AND MOORE, PEGGY --GROSSENBACHER, DENA --WANAMAKER, HOLLY/;
	s/COLWELL, ALISON --SANDERS, ANGELA --COULTER, CHARLOTTE/Alison Colwell AND SANDERS, ANGELA --COULTER, CHARLOTTE/;
	s/Colwell, Alison --Brown, Paul Martin --Folsom, Stan --Kelley, Brad --Lauri, Robert/Alison Colwell AND Brown, Paul Martin --Folsom, Stan --Kelley, Brad --Lauri, Robert/;
	s/Colwell, Alison --Grossenbacher, Dena --Grove, Sara --McGlinchy, Maureen --Rawlings, Colleen/Alison Colwell AND Grossenbacher, Dena --Grove, Sara --McGlinchy, Maureen --Rawlings, Colleen/;
	s/Colwell, Alison --Ponman, Bruce --Del Favero, Steven/Alison Colwell AND Ponman, Bruce --Del Favero, Steven/;
	s/DUNN,DAVID/David Dunn/;
	s/Del Favero, Steven --Kaiser, Andrew --Dunphy, Alicia/Steven Del Favero AND --Kaiser, Andrew --Dunphy, Alicia/;
	s/FIELD,EUGENE/Eugene Field/;
	s/FRASER, LINT, AND HERKENHAM/FRASER AND LINT, HERKENHAM/;
	s/Foerster, Katharina --Daniel Schaible/Katharina Foerster AND Daniel Schaible/;
	s/Grossenbacher, Dena --Colwell, Alison --Lynds, Steve --Shoenig, Steve --Hillhouse, Carol --Shaneg, Lila --Shaneg, Elliot/Dena Grossenbacher AND Colwell, Alison --Lynds, Steve --Shoenig, Steve --Hillhouse, Carol --Shaneg, Lila --Shaneg, Elliot/;
	s/Grossenbacher, Dena --Colwell, Alison --Moore, Peggy --Grove, Sara --Ward, Kimiora/Dena Grossenbacher AND Colwell, Alison --Moore, Peggy --Grove, Sara --Ward, Kimiora/;
	s/Grossenbacher, Dena --Colwell, Alison --Moore, Peggy --Schevock, Jim --Wilson, Paul/Dena Grossenbacher AND Colwell, Alison --Moore, Peggy --Schevock, Jim --Wilson, Paul/;
	s/Grossenbacher, Dena --Del Favero, Steven/Dena Grossenbacher AND Del Favero, Steven/;
	s/Grossenbacher, Dena --Del Favero, Steven --Krueger, Lori/Dena Grossenbacher AND Del Favero, Steven --Krueger, Lori/;
	s/Grossenbacher, Dena --Del Favero, Steven --Reyes, Tom/Dena Grossenbacher AND Del Favero, Steven --Reyes, Tom/;
	s/Grossenbacher, Dena --Grove, Sara --McGlinchy, Maureen --Oliver, Martin/Dena Grossenbacher AND Grove, Sara --McGlinchy, Maureen --Oliver, Martin/;
	s/Grossenbacher, Dena --McGlinchy, Maureen --Grove, Sara --Oliver, Martin/Dena Grossenbacher AND McGlinchy, Maureen --Grove, Sara --Oliver, Martin/;
	s/H\. G\. W & RUTTER, J. A./H G. W. AND J. A. RUTTER/;
	s/H\. G\. W\. & J\. A\. K\./H G. W. AND J. A. K./;
	s/H\. G\. W\. & RUTTER, J\. A\./H G. W. AND J. A. RUTTER/;
	s/H\., A\./H. A./;
	s/HAINES, A\. L\. --MRS\.  HAINES/A. L. Haines AND Mrs. Haines/;
	s/HALL MATHER/Mather Hall/;
	s/HANKS,CW/C. W. Hanks/;
	s/HOOD,MARY V./Mary V. Hood/;
	s/IBUSS HUSS, J./J. Huss/;
	s/KELLEY, RON --COLWELL, ALSION --GROSSENBACHER, DENA --MOORE, PEGGY/Ron Kelley AND COLWELL, ALSION --GROSSENBACHER, DENA --MOORE, PEGGY/;
	s/MASON., H\. L\./H. L. Mason/;
	s/MICHAEL ENID/Enid Michael/;
	s/MICHAEL, CHARLES & MICHAEL, ENID/Charles Michael AND Enid Michael/;
	s/MONCREIF, V\. AND  MOBRAY, V\./V. Moncreif AND V. Mobray/;
	s/MONCREIF, V\. AND MOBRAY, 11/V. Moncreif AND V. Mobray/;
	s/MONCREIF, V\. AND MOBRAY, V\./V. Moncreif AND V. Mobray/;
	s/MONCREIF, V\. AND MOWBRAY, V\./V. Moncreif AND V. Mobray/;
	s/MONCREIF,V\. AND MOBRAY, V\./V. Moncreif AND V. Mobray/;
	s/MONCRIEF, V\. &  MOWBRAY, V\./V. Moncreif AND V. Mobray/;
	s/MONCRIEF, V\. & MOWBRAY, V\./V. Moncreif AND V. Mobray/;
	s/MONCRIEF, V\., AND MOBRAY, V\./V. Moncreif AND V. Mobray/;
	s/MOORE, PEGGY --COLWELL, ALSION --WANAMAKER, HOLLY --GROSSENBACHER, DENA/Peggy Moore AND COLWELL, ALSION --WANAMAKER, HOLLY --GROSSENBACHER, DENA/;
	s/MOORE, PEGGY --GROSSENBACHER, DENA --COLWELL, ALSION --PATTON, CAROL --CHOW, LES --WANAMAKER, HOLLY/Peggy Moore AND GROSSENBACHER, DENA --COLWELL, ALSION --PATTON, CAROL --CHOW, LES --WANAMAKER, HOLLY/;
	s/MOORE, PEGGY --GROSSENBACHER, DENA --COLWELL, ALSION --WANAMAKER, HOLLY/Peggy Moore AND GROSSENBACHER, DENA --COLWELL, ALSION --WANAMAKER, HOLLY/;
	s/MOORE, PEGGY --GROSSENBACHER, DENA --WANAMAKER, HOLLY/Peggy Moore AND GROSSENBACHER, DENA --WANAMAKER, HOLLY/;
	s/MOORE, PEGGY --WANAMAKER, HOLLY --PATTON, CAROL/Peggy Moore AND WANAMAKER, HOLLY --PATTON, CAROL/;
	s/MOWBRAY, V. & MONCRIEF, V./V. Moncreif AND V. Mobray/;
	s/McGlinchy, Maureen --Grossenbacher, Dena --Grove, Sara --Oliver, Martin/Maureen McGlinchy AND Grossenbacher, Dena --Grove, Sara --Oliver, Martin/;
	s/McINTYRE, ROBERT/Robert McIntyre/;
	s/SAGAL, BERN\. & APPLEGARTH, ARN\./B. Sagal AND A. Applegarth/;
	s/SAGE,PAUL/Paul Sage/;
	s/SCHREIBER[\/ ]BERYL O\./Beryl O. Schreiber/;
	s/SCHREIBER,B\. O\./Beryl O. Schreiber/;
	s/SHARSMITH, CARL W,/Carl W. Sharsmith/;
	s/Taylor, Dean --Colwell Alison/Dean Taylor AND Alison Colwell/;
	s/VOGT, I\. AND ASHCROFT, G\. P\./I. VOGT and G. P. Ashcroft/;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

#parse name elements
if($tempCollector =~ m/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*/i){
	$collectors = $tempCollector;
}
elsif($tempCollector =~ m/^([A-Z]+), ([A-Za-z. ]+)$/){
	$collectors = "$2 $1";
	#warn "1. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^([A-Z][a-z]+), ([A-Za-z. ]+)$/){
	$collectors = "$2 $1";
	#warn "2. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^([A-Z][a-z]+), ([A-Za-z. ]+) +-+ ?-*([A-Z][a-z]+), ([A-Za-z. ]+), ([A-Z][a-z]+), ([A-Za-z. ]+)$/){
	$collectors = "$2 $1";
	$other_coll = "$4 $3, $6 $5";
	warn "3. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^([A-Z][a-z]+), ([A-Za-z. ]+) +-+ ?-*([A-Z][a-z-]+), ([A-Za-z-. ]+) +-+ ?-*([A-Z][a-z]+), ([A-Za-z-. ]+) ?-? ?-*([A-Z]?[a-z]*),? ?([A-Za-z. ]*)$/){
	$collectors = "$2 $1";
	$other_coll = "$4 $3, $6 $5, $8 $7";
	#warn "4. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^([A-Za-z]+), ([A-Za-z. ]+) +-+ ?-*([A-Za-z-]+), ([A-Za-z-. ]+)$/){
	$collectors = "$2 $1";
	$other_coll = "$4 $3";
	#warn "5. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^([A-Za-z]+) (&|AND|and) ([A-Za-z-]+), ([A-Za-z. ]+)$/){
	$collectors = "$1";
	$other_coll = "$4 $3";
	#warn "6. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^([A-Za-z]+) (&|AND|and) ([A-Za-z]+)$/){
	$collectors = "$1";
	$other_coll = "$3";
	#warn "7. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^([A-Za-z]+ [A-Za-z.]+ ?[A-Za-z.]*)$/){
	$collectors = "$1";
	$other_coll = "";
	#warn "8. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS (9) name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^([A-Z]\.? [A-Z]\.? [A-Z]?\.?)$/){
	$collectors = "$1";
	$other_coll = "";
	#warn "8. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS (9) name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^([A-Za-z]+)$/){
	$collectors = "$1";
	$other_coll = "";
	#warn "8. Name found and modified: $tempCollector==>$collectors\n";
	&log_change("COLLECTORS (8) name found and modified: $tempCollector==>$collectors");
	
}
elsif($tempCollector =~ m/^ *$/){
	&log_change("COLLECTOR (4): Collector field NULL\t$id\n");
	$collectors = "";
	$other_coll = "";
}	
else{
	#warn "Name problem: $tempCollector\n";
	&log_change("COLLECTORS name problem:\t$tempCollector");
	$collectors = $tempCollector;
	$other_coll = "";
}



my $collMOD = lc($collectors);
my $collMOD1 = ucfirst($collMOD);

	
	if ($collectors =~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collectors, $id);	
	#D Atwood; K Thorne
		$other_coll=$2;
		#warn "Names 1: $verbatimCollectors===>$collectors\t--\t$recordedBy\t--\t$other_coll\n";
		&log_change("COLLECTOR (1): modified: $verbatimCollectors==>$collectors--\t$recordedBy\t--\t$other_coll\t$id\n");	
	}
	
	elsif ($collectors !~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collectors, $id);
	$other_coll = "";
		#warn "Names 2: $verbatimCollectors===>$collectors\t--\t$recordedBy\t--\t$other_coll\n";
		#&log_change("COLLECTOR (0000):\t$collectors\t$collMOD1");
	}
	elsif($tempCollector =~ m/^ *$/){
		$recordedBy = "Unknown";
		&log_change("COLLECTOR (2): modified from NULL to Unknown\t$id\n");
	}	
	else{
		&log_change("COLLECTOR (3): name format problem: $verbatimCollectors==>$collectors\t--$id\n");
	}




###further process other collectors
foreach ($other_coll){
	s/"//g;
	s/'$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
}

$other_collectors = $other_coll;

#reconstruct verbatim collectors as combined collectors, the collector data is entered non-standardly we dont want to use the unmodified verbatim field
	if((length($recordedBy) > 1) && (length($other_collectors) == 0)){
		$combined_collectors = $recordedBy;
				
	}		
	elsif ((length($recordedBy) > 1) && (length($other_collectors) > 1)){
		$combined_collectors = "$recordedBy, $other_collectors";
		
	}
	elsif ((length($recordedBy) == 0) && (length($other_collectors) > 1)){
		$combined_collectors = $other_collectors;
		
	}
	elsif ((length($recordedBy) == 0) && (length($other_collectors) == 0)){
		$combined_collectors = "";
		&log_change("COLLECTORS NULL, $id\n");
	}
	else {
		&log_change("COLLECTORS bad format: $id\t--\t$recordedBy\t--\t$other_collectors\n");		#call the &log function to print this log message into the change log...
	}



#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes


foreach ($recordNumber){
		s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
	s/'//g;
	s/"//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
}

($CNUM_prefix,$CNUM,$CNUM_suffix)=&CCH::parse_CNUM($recordNumber);


####COUNTRY
$country="USA";
$stateProvince="CA";


#########################County/MPIO
#delete some problematic Mexico specimens



######################COUNTY
foreach ($tempCounty){
	s/["']+//g;
	s/^ +$//;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries

}


#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);



#apply YM_out_county.txt counties to replace unknowns
	if($county=~m/^(unknown| *)$/i){	
		if($ALTER{$id}){
				$county = $ALTER{$id};
				&log_change("COUNTY found in YOSE county file, changed from '$tempCounty'==>$county\t--\t$locality\t$id");		
		}
	}

#Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}

#foreach($GUID){
#print OUT2 "$herb$id\t$id\t$county\t$scientificName\t$GUID\n";
#}

	
#validate county
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
			&log_change("COUNTY (3): COUNTY $county ==> $v_county--\t$id");		#call the &log function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}


####LOCALITY

foreach ($location){
		s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
		s/^"//;
		s/"$//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

foreach ($waterbody){
		s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
		s/^"//;
		s/"$//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

	if((length($waterbody) > 1) && (length($location) == 0)){
		$locality = $waterbody;
				
	}		
	elsif ((length($waterbody) > 1) && (length($location) > 1)){
		$locality = "$waterbody, $location";
		
	}
	elsif ((length($waterbody) == 0) && (length($location) > 1)){
		$locality = $location;
		$locality =~ s/: *$//;
	}
	elsif ((length($waterbody) == 0) && (length($location) == 0)){
		$locality = "";
		&log_change("LOCAT: $waterbody & $location NULL, $id\n");
	}
	else {
		&log_change("Locality problem, bad format, $id\t--\t$waterbody\t--\t$location\n");		#call the &log function to print this log message into the change log...
	}

###############ELEVATION########

$elevation = $verbatimElevation;

foreach($elevation){
		s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
		s/^"//;
		s/"$//;
	s/feet/ft/i;
	s/meters/m/i;
	s/about //;
	s/ca\.? //;
	s/C//;
	s/^H//;
	s/\[//;
	s/\]//;
	s/,//g;
	s/\.//g;
	s/^N.?A//i;
	s/  +/ /g;
	s/42OO FT/42OOft/;
	s/86OO FT/86OOft/;
	}
	
#fix some problematic elevations in Dean Taylor records without units in home database

if (($verbatimCollectors =~ m/^Taylor,/i) && ($verbatimElevation =~ m/^(\d+)$/)){ 
	$elevation = "$1ft";
	&log_change("ELEV: elevation modified ($verbatimElevation), does not include units, but all appear to be in feet, changed to ($elevation)==>$id\n");
}

	
	
#process verbatim elevation fields into CCH format
if (length($elevation) >= 1){

	if ($elevation =~ m/(-?\d+) +[fF][tT]/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation =~ m/(-?\d+)[fF][tT]/){
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
	elsif ($elevation =~ m/(-?[0-9]+) +([mM])/){
		#$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = $elevation;
	}
	elsif ($elevation =~ m/(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = $elevation;
		$CCH_elevationInMeters =~ s/m$/ m/;
	}
	elsif ($elevation =~ m/[A-Za-z ]+ +(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevation =~ m/(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevation =~ m/(-?[0-9]+)-(-?[0-9]+)[fF][tT]/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation =~ m/[A-Za-z ]+ +(-?[0-9]+)-(-?[0-9]+)([mM])/){
		$elevationInMeters = $1;
		$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "$elevation m";
	}
	elsif ($elevation =~ m/[A-Za-z]+ +(-?[0-9]+)[fF][tT]/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("ELEV: Check elevation '$elevation' problematic formatting or missing units\t$id");
		$CCH_elevationInMeters = $elevationInMeters = "";
	}	
}
else{
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
		&log_change ("ELEV\t$county:\t $elevation_test ft. ($elevationInMeters m.) greater than $county maximum ($max_elev{$county} ft.): discrepancy=", (($elevation_test)-$max_elev{$county}),"\t$id\n");
		if ((($elevation_test)-$max_elev{$county}) >= 500 ){
			$CCH_elevationInMeters = "";
			&log_change ("ELEV\t$county: discrepancy=", (($elevation_test)-$max_elev{$county})," greater than 500 ft, elevation changed to NULL\t$id\n");
		}
	}

#########COORDS, DATUM, ER, SOURCE#########

#### TRS
#no TRS in this dataset

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

foreach ($verbatimCoordinates){
		s/^"//;
		s/"$//;
	s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
		s/119,09818/119.09818/;
		s/11988049/119.88049/;
		s/34,84364/34.84364/;
		s/'/ /g;
		s/"/ /g;
		s/,/ /g;
		s/_+/ /g;
		s/deg./ /;
		s/N//;
		s/W//;
		s/^N.?A//i;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		
}


#lat long is in a single field in this dataset, need to parse into N and W


	if ($verbatimCoordinates =~ m/^(\d\d \d+)\/(-?1\d\d \d+)$/){
			$verbatimLatitude = $1;
			$verbatimLongitude = $2;
	}
	elsif ($verbatimCoordinates =~ m/^(\d\d \d+\.\d+) ?\/(-?1\d\d \d+\.\d+)/){
			$verbatimLatitude = $1;
			$verbatimLongitude = $2;
	}
	elsif ($verbatimCoordinates =~ m/^(\d\d \d+\.\d+) ?\/(-?1\d\d \d+)$/){
			$verbatimLatitude = $1;
			$verbatimLongitude = $2;
	}
	elsif ($verbatimCoordinates =~ m/^(\d\d \d+ \d+)\/(-?1\d\d \d+ \d+)/){
			$verbatimLatitude = $1;
			$verbatimLongitude = $2;
	}
	elsif ($verbatimCoordinates =~ m/^(\d\d\.\d+)\/(-?1\d\d\.\d+)/){
			$verbatimLatitude = $1;
			$verbatimLongitude = $2;
	}
	elsif (length($verbatimCoordinates) == 0){
		#warn "COORDINATE NULL $id\n";
	}
	else{
			warn "Lat-Long Problem, bad format: $verbatimCoordinates";
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

#fix some problematic records with bad latitude and longitude in home database

#if (($id =~ m/^(RSA588401)$/) && ($verbatimLatitude =~ m/36\.41/)){ 
#	$latitude = "34.174";
#	$longitude = "-118.044";
#	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) did not map within boundary of county and/or state on the label, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
	#the original is in error and maps to Emigrant Canyon, Death Valley, Inyo County
#}

#fix some problematic records with bad UTM's in home database

#UTM Problem, bad format: 38.0054/-119.28814 at parse_yose_new.pl line 1546, <IN> line 399.
#UTM Problem, bad format: 37.9747/-119.87668 at parse_yose_new.pl line 1754, <IN> line 8103.

	if ($UTM =~ m/^38\.0054.+28814/){
		#lat long in UTM field
		
		$latitude = "38.0054";
		$longitude = "-119.28814";
		
		&log_change("COORD: LAT-LONG in UTM field, UTM changed to NULL, coordinates changed to $UTM==>$latitude\t$longitude\t$id");
		$UTM = "";
	}

	if ($UTM =~ m/^37\.9747.+87668/){
		#lat long in UTM field
		
		$latitude = "37.9747";
		$longitude = "-119.87668";
		
		&log_change("COORD: LAT-LONG in UTM field, UTM changed to NULL, coordinates changed to $UTM==>$latitude\t$longitude\t$id");
		$UTM = "";
	}

if (($UTM =~ m/^11.281132.420842$/)){ 
	$UTM = "11/281132/4208420";
	&log_change("COORD: LAT-LONG in UTM field, UTM change to NULL, coordinates changed to ($UTM)==>$county\t$location\t--\t$id\n");
	#the original is in error, a zero was added as the last digit to the northing
}

if (($UTM =~ m/^11.251800.418253$/)){ 
	$UTM = "11/251800/4182530";
	&log_change("COORD: UTM did not map within boundary of county and/or state on the label, missing last digit in northing, coordinates changed to ($UTM)==>$county\t$location\t--\t$id\n");
	#the original is in error, a zero was added as the last digit to the northing
}

if (($UTM =~ m/^11.281132.420842$/)){ 
	$UTM = "11/281132/4208420";
	&log_change("COORD: UTM did not map within boundary of county and/or state on the label, missing last digit in northing, coordinates changed to ($UTM)==>$county\t$location\t--\t$id\n");
	#the original is in error, a zero was added as the last digit to the northing
}

if (($UTM =~ m/^11.283000.419000$/)){ 
	$UTM = "11/281132/4190000";
	&log_change("COORD: UTM did not map within boundary of county and/or state on the label, missing last digit in northing, coordinates changed to ($UTM)==>$county\t$location\t--\t$id\n");
	#the original is in error, a zero was added as the last digit to the northing
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
					#print "2b) $decimalLatitude\t--\t$id\n";
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
					#print "6a) $decimalLongitude\t--\t$id\n";
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
#utm are in one field.. the following is the original parse code that still needs corrected


	if (length($UTM) >= 5){
	
		#fix some problem cases
			$UTM =~ s/.(253943).521/\/$1/;
			$UTM =~ s/.(4202273).503/\/$1/;
			$UTM =~ s/11\/\/11/11/;
			
#UTM and Lat long are in a single field, so it needs split first
		if($UTM=~m !(\d{6})\/(\d{7})$!){
			$easting=$1;
			$northing=$2;
			$ellipsoid="23";
			$zone="11S";
		}
		elsif($UTM=~m !(11)\/([237]\d{5})\/ ?(4\d{6})$!){
			$easting=$2;
			$northing=$3;
			$ellipsoid="23";
			$zone="11S";
		}
		elsif($UTM=~m !(11)\/(4\d{6})\/([23]\d{5})$!){
			$easting=$3;
			$northing=$2;
			$ellipsoid="23";
			$zone="11S";
		}
		else{
			warn "UTM Problem, bad format: $UTM";
		}
	
			if($zone=~/9|10|11|12/ && $easting=~/^\d\d\d\d\d\d$/ && $northing=~/^\d\d\d\d\d\d\d$/){
				($decimalLatitude,$decimalLongitude)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
				&log_change( "COORDINATE decimal derived from UTM $decimalLatitude, $decimalLongitude\t$id");
			}
			else{
				&log_change("COORDINATE UTM problem $zone $easting $northing\t$id");
			}
	}
	else{
		&log_change("COORD: using latitude and longitude, not UTM\t$id");
	}
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

		if($locality=~s/Datum: (NAD\d+|WGS\d+)//i){
			$datum = $1;
		}

		if ($datum){
			s/ +//g;
		}
		else {$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
		}

###########ERROR RADIUS AND UNITS#####

		if($locality=~s/GPS Error: ([0-9.]+) [Mmetrs.]+//){
			$errorRadius=$1;
			$errorRadiusUnits="m";
		}
		else{
			$errorRadius="";
			$errorRadiusUnits="";
		}

	foreach ($errorRadius,$errorRadiusUnits) {
		s/  +/ /;
		s/^ +//;
		s/ +$//;
	}
}


#final check of Longitude

	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			&log_change("COORDINATE Longitude made negative\t--\t$id");
	}

#final check for rough out-of-boundary coordinates
if((length($decimalLatitude) >= 2)  && (length($decimalLongitude) >= 3)){ 
	if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114.0 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california and northern Baja...
	###was 32.5 for California, now 30.0 to include CFP-Baja
		&log_change("COORDINATE set to null for $id, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
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


#######Georeference Source#############
#RSA has some weird ones that start with brackets or numbers. Null these
foreach ($georeferenceSource) {
	s/^"//;
	s/"$//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}


#######Habitat and Assoc species (dwc habitat and associatedTaxa)
my $habitat_all; 

foreach ($habitat){
		s/^"//;
		s/"$//;
		s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

foreach ($habitat_type){
		s/^"//;
		s/"$//;
		s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

	if((length($habitat_type) > 1) && (length($habitat) == 0)){
		$habitat_all = $habitat_type;
				
	}		
	elsif ((length($habitat_type) > 1) && (length($habitat) > 1)){
		$habitat_all = "$waterbody, $habitat";
		
	}
	elsif ((length($habitat_type) == 0) && (length($habitat) > 1)){
		$habitat_all = $habitat;

	}
	elsif ((length($habitat_type) == 0) && (length($habitat) == 0)){
		$habitat_all = "";
		&log_change("HABITAT: $habitat_type & $habitat NULL, $id\n");
	}
	else {
		&log_change("HABITAT problem, bad format, $id\t--\t$habitat_type\t--\t$habitat\n");		#call the &log function to print this log message into the change log...
	}


foreach ($associatedTaxa){
		s/^"//;
		s/"$//;
	s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Unknown).*//i;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}


#######Notes and phenology fields
 foreach ($slope){
		s/^"//;
		s/"$//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
} 

 foreach ($aspect){
		s/^"//;
		s/"$//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
} 
	if((length($slope) >= 1) && (length($aspect) == 0)){
		$occurrenceRemarks = "slope: $slope";
				
	}		
	elsif ((length($slope) >= 1) && (length($aspect) >= 1)){
		$occurrenceRemarks = "slope: $slope; aspect: $aspect";
		
	}
	elsif ((length($slope) == 0) && (length($aspect) >= 1)){
		$occurrenceRemarks = "aspect: $aspect";

	}
	elsif ((length($slope) == 0) && (length($aspect) == 0)){
		$occurrenceRemarks = "";
		&log_change("SLOPE/ASPECT: slope: $slope & aspect: $aspect NULL, $id\n");
	}
	else {
		&log_change("SLOPE/ASPECT problem, bad format, $id\t--\tslope:$slope\t--\taspect: $aspect\n");		#call the &log function to print this log message into the change log...
	}




 foreach ($occurrenceRemarks){
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

 foreach ($notes){
		s/^"//;
		s/"$//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

	if((length($notes) > 1) && (length($occurrenceRemarks) == 0)){
		$occurrenceRemarks = $notes;
				
	}		
	elsif ((length($notes) > 1) && (length($occurrenceRemarks) > 1)){
		$occurrenceRemarks = "$notes; $occurrenceRemarks";
		
	}
	elsif ((length($notes) == 0) && (length($occurrenceRemarks) > 1)){
		$occurrenceRemarks = $aspect;

	}
	elsif ((length($notes) == 0) && (length($occurrenceRemarks) == 0)){
		$occurrenceRemarks = "";
		&log_change("NOTE: $notes & $occurrenceRemarks NULL, $id\n");
	}
	else {
		&log_change("NOTE problem, bad format, $id\t--\t$notes\t--\t$occurrenceRemarks\n");		#call the &log function to print this log message into the change log...
	}


 
 
#####Type status###############
#remove "Not type"
if ($typeStatus eq "Not type"){
	$typeStatus = "";
}

 foreach ($typeStatus){
		s/^"//;
		s/"$//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
} 

#########Skeletal Records
	if((length($recordNumber) < 1) && (length($collector) < 1) && (length($typeStatus) < 2) && (length($locality) < 2) && (length($eventDate) < 2) && (length($habitat) < 2) && (length($verbatimCoordinates) < 2)){ #exclude skeletal records
			&log_skip("VOUCHER: skeletal records without data in most fields including locality and coordinates\t$id");	#run the &log_skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
	}

++$count_record;
warn "$count_record\n" unless $count_record % 100;


print OUT <<EOP;

Accession_id: $id
Other_label_numbers: 
Name: $scientificName
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
Collector: $recordedBy
Other_coll: $other_collectors
Combined_coll: $combined_collectors
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Country: $country
State: $stateProvince
County: $county
Location: $locality
Habitat: $habitat_all
Associated_species: $associatedTaxa
T/R/Section: 
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Lat_long_ref_source: $georeferenceSource
Datum: $datum
Max_error_distance: $errorRadius
Max_error_units: $errorRadiusUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Notes: $occurrenceRemarks
Hybrid_annotation: $hybrid_annotation
Cultivated: $cultivated
Type_status: $typeStatus
Annotation: $det_string

EOP
#add one to the count of included records
++$included;



print OUT2 <<EOP;
Accession_id: $id
Date: $verbatimEventDate
Name: $scientificName
Collector: $recordedBy
Combined_collector: $combined_collectors
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Location: $locality
Elevation: $CCH_elevationInMeters
Habitat: $habitat_all
Associated_species: $associatedTaxa
County: $county
State: $stateProvince
UTM: $UTM
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Notes: $occurrenceRemarks
Datum: $datum
Max_error_distance: $errorRadius
Max_error_units: $errorRadiusUnits
Annotation: $det_string

EOP
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


#####Check final output for characters in problematic formats (non UTF-8), this is Dick's accent_detector.pl
my @words;
my $word;
my $store;
my $match;
my %store;
my %match;
my %seen;
%seen=();


    my $file_in = '/JEPS-master/CCH/Loaders/YOSE/YOSE_out.txt';	#the file this script will act upon is called 'CATA.out'
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

