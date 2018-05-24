
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


my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
my $det_string;

open(OUT, ">/JEPS-master/CCH/Loaders/SD/SD_out.txt") || die;

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


#####I'm not familiar with the Text::CSV function
#####here's what I do to the SD file to make it parse with this:
###open the file in TextWrangler, Save As with Line Breaks: Unix and Encoding: UTF-8
###Then run it through this and it works

    my $file = '/JEPS-master/CCH/Loaders/SD/CCH_SD_Jan17_mod.txt';
#    my $file = 'Oct2015_SD_original.txt';

    open (IN, "<", $file) or die $!;

Record: while(<IN>){
	chomp;

#&CCH_unidecode ($_);

	$line_store=$_;
	++$count;		


#fix some data quality and formatting problems that make import of fields of certain records problematic
	s///g; #x{0B} hidden character
		s/"(\w+)/'$1/g;  #eliminate leading quotes from excel conversion
		s/(\w+.?)"/$1'/g;
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
	s/—/-/g;
	s/ö/o/g;
	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ä/a/g;
	s/á/a/g;
	s/ú/u/g;
	s/Ì/I/g;
	s/Ë/e/g;
	s/Ò/n/g;
	s/Û/o/g;
	
	
	
#mismatched conversion errors
	s/í/'/g;
	s/ë/'/g;
	s/ñ/ /g;
		s/î/'/g;
		s/ì/'/g;
		s/í/'/g;
		s/Ö/ /g; #weird character, translation indeterminate
		s/Ô/e/g; #\xc3\x94/
		s/È/e/g; #\xc3\x88/
		s/·/a/g;
		s/∞/ deg. /g;
		s/m≤/ m /g; #\xe2\x89\xa4
		s/Ω/ 1\/2 /g; 
		s/º/ 1\/4 /g;  #SD42221 and others; replace ISO-8859-1 one-quarter fraction character that is not showing correctly in Mac UTF8, 
		s/æ/ 3\/4 /g;  #SD200694 and others; replace ISO-8859-1 3-quarter fraction character that is not showing correctly in Mac UTF8, 
		s/Ra˙l/Raul/g;
		s/◊/X/g;	#odd character representing hybrid species "times" sign
		s/  +/ /g;

#skipping: problem character detected: s/\xc2\xba/    /g   º ---> º	2º	4º	1º	Ω-º	seº	~ºmile	~º	º-mi.	3º	5º	º-Ω	º-mile	º'	2'-2º'	-1º	swº	SEº	(º	SWº	
#skipping: problem character detected: s/\xc3\x88/    /g   È ---> AndrÈ	AndrÈ,	'JÈsus	ValdÈs	CafÈ,	MallÈ	Gibson,Faught,Seymour,Winner,RenÈe	MallÈ,	MonsÈ	GutiÈrrez,	FÈ	CotÈ	GuitiÈrrez,	CafÈ	JosÈ,	LaPrÈ	cafÈ.	
#skipping: problem character detected: s/\xc3\x8b/    /g   Ë ---> crËme	
#skipping: problem character detected: s/\xc3\x8c/    /g   Ì ---> Ìsland:	Ìsland,	
#skipping: problem character detected: s/\xc3\x92/    /g   Ò ---> CaÒon	CaÒon,	PeÒalosa	piÒons	CaÒada	CaÒon.	PiÒon	caÒon,	PeÒasquitos,	PeÒasquitos.	PeÒasquitos	PiÒons	caÒon	PeÒa	caÒons	PiÒos	CaÒon;	PeÒalosa,	MontaÒa	VillaseÒor	OrdoÒez,	
#skipping: problem character detected: s/\xc3\x92\xc3\x9b/    /g   ÒÛ ---> CaÒÛn	
#skipping: problem character detected: s/\xc3\x94/    /g   Ô ---> AndrÔ	
#skipping: problem character detected: s/\xc3\x9b/    /g   Û ---> NaciÛn	CanÛn	PinÛn	CanÛn;	canÛn	
#skipping: problem character detected: s/\xc3\xa6/    /g   æ ---> 1æ	æ	3æ	5æ	æ-mi.	4æ	2æ	æmi	
#skipping: problem character detected: s/\xc3\xab/    /g   ë ---> ëchicoryi,	ëpinkedi	
#skipping: problem character detected: s/\xc3\xac/    /g   ì ---> ìrope	ìRope	ìenvironmental	ìrevivedî	ìcreekî	ìfungoidî	ìEco-Campsî	ìescapedî	ì	ìJoe	ìAviaraî	ìrevegetationî	ìFirst	ìHighlands	ìLookoutî	ìQuakeî;	
#skipping: problem character detected: s/\xc3\xae/    /g   î ---> trailî	trail.î	Trailî	campsî.	ìrevivedî	ìcreekî	ìfungoidî	ìEco-Campsî	ìescapedî	trailî.	Westî	18î	19î	ìAviaraî	ìrevegetationî	Groveî.	ìLookoutî	ìQuakeî;	
#skipping: problem character detected: s/\xc3\xb1/    /g   ñ ---> ñ	tips.ñUncommon,	ñ3	7ñ8	
#skipping: problem character detected: s/\xcb\x99/    /g   ˙ ---> 'Ra˙l	
#skipping: problem character detected: s/\xce\xa9/    /g   Ω ---> Ω	1Ω	2Ω	4Ω	3Ω	8Ω	8Ω-9	[3Ω	1-1Ω	E-4Ω	Ω-º	9Ω	+-Ω	3'-3Ω'	7Ω'	1Ω-foot	ca.Ω	2Ω-foot	6Ω	4-4Ω	5Ω	1Ω-2	1'-1Ω';	1Ω-3	1Ω-2mm,	1Ωmm	39Ω	2'-2Ω'	3Ω-foot	10Ω	(Ω	River,1Ω	Ωmiles	11Ω	+-1Ω	º-Ω	Approx.Ω	1Ω-foot-high	1Ω-2Ω-foot	2Ωm	Ωm	1Ωm	Ω'	(3Ω	7Ω	1Ω-3Ω	3Ω'	2Ω-4	Ω-1	+-2Ω	Ωmi.	2Ω'	2Ω-ft.	WΩ	WestΩ	2Ω-ft	2Ω',	(2Ω	12Ω	5'-15Ω';	3Ω-4	1-2Ω	4Ωmi.	+-1-1Ω	2-2Ω	nΩ	1Ω-ft.	to1Ω	4Ω-foot	
#skipping: problem character detected: s/\xe2\x89\xa4/    /g   ≤ ---> 10m≤	



		

        if ($. == 1){#activate if need to skip header lines
			next;
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
my $imageAvailable;
my $color_blank;
my $UTM;
my $georeferencedBy;
my $ER_Units;
my $latitude_orig;
my $longitude_orig;
my $Latitude_blank;
my $Longitude_blank;

	my @fields=split(/\t/,$_,100);
	
	unless($#fields == 31){	#32 fields but first field is field 0 in perl

	&log_skip ("$#fields bad field number\t$_######\n\n");
	++$skipped{one};
	next Record;
	}
#cult	Date	CNUM	CNUM_Prefix	CNUM_Suffix	Name	Accession_ID	Country	STATE	Location	TRS	County	ElevationFt	Collector	Combined_Collector	Habitat	Macromorphology	Color	Associated_species	Latitude	Longitude	Decimal_Latitude	Decimal_Longitude	Datum	ErrorRadius	ErrorRadius_Units	GeoRefBy	CoordinateSource	UTM	Notes	Det_Date	ScanAvailable

#fix more data quality and formatting problems






#then process the full records
(
$cultivated,
$verbatimEventDate,
$CNUM,
$CNUM_prefix,
$CNUM_suffix,
$name,
$id,
$country,
$stateProvince,
$locality, #10
$TRS,
$tempCounty,
$elevationInFeet,
$collector,
$other_coll,
$habitat,
$plant_description,
$color_blank,					#as of March 2017, this field is all "n/a" and is skipped
$associatedTaxa,
$Latitude_blank, #20	#as of March 2017, this field is all "n/a" and is skipped
$Longitude_blank,		#as of March 2017, this field is all "n/a" and is skipped
$verbatimLatitude,				
$verbatimLongitude,				
$datum,
$errorRadius,
$errorRadiusUnits,
$georeferencedBy,		#this field is skipped
$georeferenceSource,
$UTM,					#as of March 2017, this field is all "n/a" and is skipped 
$notes, #30
$identifiedBy,
$imageAvailable
)=@fields;

################ACCESSION_ID#############
#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
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
#prefix already present in these data

#Remove duplicates
if($seen{$id}++){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}


##################Exclude known problematic specimens by id numbers, most from outside California and Baja California

	if(($id=~/^(SD132484)$/) && ($tempCounty=~m/Humboldt/)){ #skip, out of state
		&log_skip("COUNTY: County/State problem: 'ca. 4 mi W of Winnemucca' is in Nevada, not California ($id: $tempCounty, $locality)\n");	
		++$skipped{one};
		next Record;
	}
	if(($id=~/^(SD129283)$/) && ($tempCounty=~m/Riverside/)){ #skip, out of state
		&log_skip("COUNTY: County/State problem: 'Dalzell Canyon, Highway 338, 9.0 miles north of Sweetwater Summit' is in Douglas Co., Nevada (Hwy 338 is Nevada Highway 338), not Riverside Co., California ($id: $tempCounty, $locality)\n");	
		++$skipped{one};
		next Record;
	}
	if(($id=~/^(SD136392)$/) && ($tempCounty=~m/Santa/)){ #skip, out of state
		&log_skip("COUNTY: County/State problem: 'Madera Canyon Recreation Area' is in Santa Cruz Co., AZ, not California ($id: $tempCounty, $locality)\n");	
		++$skipped{one};
		next Record;
	}

#fix some really problematic records with data that is misleading and causing georeference errors

if (($id =~ m/^(SD8210)$/) && ($tempCounty=~m/^(Lassen|Shasta)/i)){
	$tempCounty = "San Diego";
		if ($verbatimLatitude !~ m/32\./){ 
			$latitude = ""; #delete the persistently bad georeference if it maps to anything but this latitude, currently mapping to Lat 40.47
			$longitude = "";
		}
	&log_change("COUNTY: county error, Cleveland was in Cuyamaca on June 19, 1881 in San Diego county, therefore it is likely that this is Eagle Peak, Sand Diego County and the county is wrongly entered as Lassen, changed to ==>$county\t$location\t--\t$id\n");
	#the original is in error and was georeferenced in the buffer to Eagle Peak near Mount Lassen, and others commented to change the County to Shasta, which is out of the range of Umbellularia californica
}
	
#####Annotations  (use when no separate annotation field)
	#format det_string correctly
my $det_rank = "current determination (uncorrected)";  #set to zero in data with only a single determination
my $det_name = $name;
my $det_determiner = $identifiedBy;
my $det_date;
my $det_stet;	
	
	if ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) >=1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet";
		print $det_string;
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet, $det_determiner";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) >=1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_date";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) >=1)){
		$det_string="$det_rank: $det_name, $det_date";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="";
	}
	else{
		&log_change("ANNOT: det string problem:\t$det_rank: $det_name $det_stet, $det_determiner, $det_date\n");
		$det_string="";
	}



##########Begin validation of scientific names
#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($name){
	s/^ *\.//g; #SD only so far.. some records start with a period and period & spaces for some reason
	s/ sp\.//g;
	s/ species$//g;
	s/ sp$//g;
	s/ spp / subsp. /g;
	s/ spp\. / subsp. /g;
	s/ ssp / subsp. /g;
	s/ ssp\. / subsp. /g;
	s/ var / var. /g;
	s/;$//g;
	s/cf\.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/^ *//g;
	s/ *$//g;
	s/  +/ /g;
	}

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

if($name=~m/(Monardella linoides subsp\. anemonoides) X odoratissima/){
	$hybrid_annotation=$name;
	$name = $1;
	&log_change("Oddly formatted Hybrid Taxon: $1 removed from $name");
}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#the name is only corrected herein and not global; allows name to pass through to CCH if name is ever published
#the original determination is preserved in the $det_string process above so users can see what name is on original label

if (($id =~ m/^(SD27856|SD43604|SD48503|SD6100)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Styrax redivivus subsp\. redivivus/Styrax officinalis subsp. redivivus/;
	&log_change("Scientific name not published: Styrax redivivus subsp. redivivus modified to priorable name at same rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD68953|SD90579)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Downingia cuspidata subsp\. cuspidata/Downingia cuspidata/;
	&log_change("Scientific name not published: Downingia cuspidata subsp. cuspidata modified to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD10932|SD10988|SD11371|SD11372|SD17456|SD17477|SD21061|SD24766|SD38203|SD38204|SD38205|SD38206|SD38207|SD42512|SD5043|SD62435|SD6540|SD6541|SD87763)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Downingia cuspidata var\. cuspidata/Downingia cuspidata/;
	&log_change("Scientific name not published: Downingia cuspidata var. cuspidata modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD84209)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Cylindropuntia wolfii var\. wolfii/Opuntia echinocarpa var. wolfii/;
	&log_change("Scientific name not published: Cylindropuntia wolfii var. wolfii modified to priorable name at same rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD157644)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Lupinus formosus var\. proximus proximus/Lupinus formosus/;
	&log_change("Scientific name not published: Lupinus formosus var. proximus proximus modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD21450|SD15305|SD56839|SD72208)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Lupinus formosus subsp\. proximus pasadenensis/Lupinus formosus/;
	&log_change("Scientific name not published: Lupinus formosus subsp. proximus pasadenensismodified to to just the species rank:\t$name\t--\t$id\n");
}

if (($id =~ m/^(SD46399|SD21021|SD126379|SD50784)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Lupinus formosus subsp\. proximus proximus/Lupinus formosus/;
	&log_change("Scientific name not published: Lupinus formosus subsp. proximus proximus modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD133687|SD158876|SD158876|SD164487|SD167649|SD167650|SD171791|SD171806|SD171808|SD172582|SD177186|SD186836|SD189647|SD195051|SD205754|SD205755|SD232234|SD235997)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Comarostaphylis diversifolia subsp\. eglandulosa/Comarostaphylis diversifolia/;
	&log_change("Scientific name not published: Comarostaphylis diversifolia subsp\. eglandulosa modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD53239)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Trifolium virescens var\. boreale/Trifolium virescens/;
	&log_change("Scientific name not published: Trifolium virescens var. boreale modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD251269)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Loeselia glandulosa subsp\. oaxacana/Loeselia glandulosa/;
	&log_change("Scientific name not published: Loeselia glandulosa subsp. oaxacana modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD81033)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Lupinus elatus subsp\. elatus/Lupinus elatus/;
	&log_change("Scientific name not published: Lupinus elatus subsp. elatus modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD125493|SD126375|SD41204)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Lupinus elatus subsp\. viridulus/Lupinus elatus/;
	&log_change("Scientific name not published: Lupinus elatus subsp. viridulus modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD225887)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Navarretia myersii subsp\. campestris/Navarretia myersii/;
	&log_change("Scientific name not published: Navarretia myersii subsp. campestris modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD43747)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Oenothera primiveris subsp\. johnsonii/Oenothera primiveris/;
	&log_change("Scientific name not published: Oenothera primiveris subsp. johnsonii modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD27850|SD4451|SD44649|SD48508|SD53220)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Solanum umbelliferum subsp\. parishii/Solanum umbelliferum/;
	&log_change("Scientific name not published: Solanum umbelliferum subsp. parishii modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD114434|SD114435|SD12587|SD28892|SD29533|SD37191|SD37377|SD37380|SD38292|SD41230|SD41521|SD4433)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Solanum umbelliferum subsp\. xantii/Solanum umbelliferum/;
	&log_change("Scientific name not published: Solanum umbelliferum subsp. xantii modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD53190|SD64413)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Lasthenia macrantha var\. pauciaristata/Lasthenia macrantha/;
	&log_change("Scientific name not published: Lasthenia macrantha var\. pauciaristata modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD77352)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Penstemon deustus var\. floribundus/Penstemon deustus/;
	&log_change("Scientific name not published: Penstemon deustus var\. floribundus modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD27443)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Polystichum aculeatum var\. angulare/Polystichum aculeatum/;
	&log_change("Scientific name not published: Polystichum aculeatum var. angulare modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD147610)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Streptanthus polygaloides var\. iodanthus/Streptanthus polygaloides/;
	&log_change("Scientific name not published: Streptanthus polygaloides var. iodanthus modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD52209)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Vulpia microstachys var\. pacifica/Vulpia microstachys/;
	&log_change("Scientific name not published, modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD58502)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Vulpia microstachys var\. tracyi/Vulpia microstachys/;
	&log_change("Scientific name not published: Vulpia microstachys var. pacifica modified to to just the species rank:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD53402)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Lupinus obtusifolius/Lupinus/;
	&log_change("Scientific name not published: Lupinus obtusifolius modified to to just the genus:\t$name\t--\t$id\n");
}
if (($id =~ m/^(SD77337)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Penstemon symplocophyllus/Penstemon clevelandii/;
	&log_change("Scientific name not published: Penstemon symplocophyllus, Pennell 25287 at NY determined as:\t$name\t--\t$id\n");
}

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
#add exceptions here to the CCH cultivated routine on a specimen by specimen basis
		elsif (($id =~ m/^(SD193238)$/) && ($scientificName =~ m/Ozothamnus diosmifolius/)){
			&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location  (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
		$cultivated = "";
		}
#Check remaining specimens for status with CCH cultivated routine		
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
	s/'//g;
	s/ *$//g;
	s/  +/ /g;
	
}

$eventDate = ucfirst($verbatimEventDate);

foreach ($eventDate){
	s/^ *\.//g; #SD only so far.. some records start with a period and period & spaces for some reason
	s/\./ /g;	#delete periods after Month abbreviations
	s/\//-/g;	#convert / to -
	s/No date//i;
	s/Unknown 0000//i;			#SD52289 with an odd date
	s/Unspecified//i;
	s/Unknown//i;
	s/No date given//i;
	s/None given//i;
	s/none listed//i;
	s/ of / /i;
	s/ ca / /i;   #delete isolated qualifiers
	s/0000//;	#see SD5650, this was entered when a year ws not on the label for some records, this is a problem for the parser, reporting the year as 0 A.D.
	s/Mid-//i;
	s/Year. *//i;
	s/\?//g;
	s/given//i;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;

	}

#fix some really problematic date records
	if(($id=~/SD249284/) && ($eventDate=~/26 February 14/)){ 
		$eventDate=~s/26 February 14/26 February 2014/;
		&log_change("Date problem modified: $eventDate\t$id\n");	
	}
	if(($id=~/SD52315/) && ($eventDate=~/May 93/)){ 
		$eventDate=~s/May 93/May 1893/;
		&log_change("Date problem modified: $eventDate\t$id\n");	
	}
	if(($id=~/SD122906/) && ($eventDate=~/4.29-30.1978/)){ 
		$eventDate=~s/4.29-30.1978/April 29-30, 1978/;
		&log_change("Date problem modified: $eventDate\t$id\n");	
	}

#continue date parsing
$eventDate = $eventDateAlt;


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

	foreach ($collector, $other_coll){
		s/'//g;
		s/"//g;
		s/N\/A//i;
		s/, M\. ?D\.//g;
		s/, Jr\./ Jr./g;
		s/, Jr/ Jr./g;
		s/, Esq./ Esq./g;
		s/, Sr\./ Sr./g;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		
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
elsif ((length($collector) == 0) && (length($other_collectors) == 0)){
	&log_change("Collector name fields NULL\t$id\n");
	$recordedBy = "";
}	
else {
		&log_change("Collector name problem\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}

foreach ($verbatimCollectors){
	s/'$//g;
	s/N\/A//i;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	
}


#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes
$recordNumber = "$CNUM_prefix $CNUM $CNUM_suffix";

foreach ($recordNumber){
	s/none//i;
	s/'//g;
	s/"//g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	
}

($CNUM_prefix,$CNUM,$CNUM_suffix)=&CCH::parse_CNUM($recordNumber);


####COUNTRY
$country="USA" if $country=~/U\.?S\.?/;
$country="Mexico" if $country=~/M\.?E?\.?X\.?/i;


#########################County/MPIO
#delete some problematic Mexico specimens

my %country;

	if((length($county) == 0) && ($country{$id} =~m/Mexico/)){
		&log_change("COUNTRY: Mexico record with unknown or blank county field\t$id\t--\t$locality");
			++$skipped{one};
			next Record;
	}
	if(($county=~m/unknown/) && ($country{$id} =~m/Mexico/)){
		&log_change("COUNTRY: Mexico record with unknown or blank county field\t$id\t--\t$locality");
			++$skipped{one};
			next Record;
	}


######################COUNTY
foreach ($tempCounty){

	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries

#format county as a precaution


}

$county=&CCH::format_county($tempCounty,$id);

######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}

##############validate county
my $v_county;

foreach ($county){
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

foreach($locality){
	s/ "/ '/g; #turn quotes inside text into single
	s/"//g;	#removed remaining quotes, artifacts of excel conversion
	s/^'//;
	s/'$//;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	s/^\.(\d)/0.$1/; #correct mileage where leading zero is missing
	s/^\*\.(\d)/0.$1/; #correct mileage where leading zero is missing
	s/\.+/./g;
}

#fix some really problematic location records
	if(($id=~/SD28038/) && ($locality=~/Left *.* *fork/)){ 
		$locality=~s/eft *.* *fork/eft 'E' fork/;
		&log_change("Locality problem modified: $locality\t$id\n");	
	}
	
	

###############ELEVATION########
foreach($elevationInFeet){
	s/ *$//;
	s/feet/ ft/;
	s/ft/ ft/;
	s/about //;
	s/ca\.? //;
	s/m/ m/;
	s/  +/ /g;
	s/,//g;
	s/\.//g;
	s/^N.?A//i;
	s/^ *//;
#	s/[A-Z]?[a-z]+ (\d+)/$1/g;
	
	}
	
if (length($elevationInFeet) >= 1){

	if ($elevationInFeet =~ m/^(-?[0-9]+) */){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$elevationInFeet ft";
	}
	else {
		&log_change("Elevation: Check elevation in feet\t'$elevationInFeet' has missing units, is non-numeric, or has typographic errors\t$id");
		$elevationInMeters="";
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



#$verbatimLatitude = $latitude_orig;
#$verbatimLongitude = $longitude_orig;

foreach ($verbatimLatitude, $verbatimLongitude){
		s/ø/ /g;
		s/[°¡]//g;
		s/\.000000*//; #this is used as a lat/long placeholder and causes problems with the parser
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
	elsif (($verbatimLatitude =~ m/^\.0/) && ($verbatimLongitude =~ m/^\.0/)){
		$verbatimLatitude = $verbatimLongitude = $decimalLongitude = $decimalLatitude = $latitude = $longitude = $errorRadius = "";
		&log_change("COORDINATE '.00000' changed to NULL\t$id"); #SD enters this into a field instead of leaving it blank
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
		s/^\.0+$//g;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s$//;
}	



#fix some problematic records with bad latitude and longitude in home database, mostly detected because they are yellow flags

if (($id =~ m/^(SD79836|SD79852|SD73601|SD73602|SD86687)$/) && ($longitude =~ m/116\.[83]/)){ 
	$latitude = "33.639";
	$longitude = "-116.642";
	$georeferenceSource = "BerkeleyMapper";
	$errorRadius = "1";
	$errorRadiusUnits = "km";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) does not map to locality on label, specimen was mapped to a locality many miles from Lake Hemet and not near the Palms-to-Pines Highway, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
#SD73602, SD73601, SD79852 maps to the Witham collection locality 20 miles E of Lake Hemet; SD79836 maps to HWY 371 many miles S of Lake Hemet; SD86687 maps to mountains S of Martinez Mountain, many miles S of Lake Hemet and Palms to Pines Hwy
}

if (($id =~ m/^(SD73597|SD73608|SD73623|SD73598|SD73606|SD73630|SD73605|SD73613|SD79811|SD73611|SD73599|SD73629|SD73610|SD73631|SD73618|SD73609|SD73612|SD76206)$/) && ($longitude =~ m/115\.7/)){ 
	$latitude = "33.66667";
	$longitude = "-116.75";
	$georeferenceSource = "(copied from SD73597)";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) does not map to anywhere in the vicinity of Bautista Canyon, specimen was mapped to a locality along I-10, W of Indio, coordinates changed to ($latitude; $longitude)==>$county\t$location\t--\t$id\n");
#the original is in error and maps to I-10, W of Indio, longitude erroneously entered as -115
}


#use combined Lat/Long field format for SD

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

#SD records "coordinates from label" even if there are no coordinates (which they record as 0, 0)
#some of them also have datum=WGS84 if there are no coordinates.
#so we want to null georefsource and datum in addition to coordinates if lat and long are recorded as 0

elsif(($latitude==0  && $longitude==0)){
	$datum = $georeferenceSource = $decimalLatitude = $decimalLongitude = "";
	&log_change("COORDINATE entered as '0', changed to NULL $id\n");
}
elsif ((length($latitude) == 0) || (length($longitude) == 0)){
#just a single UTM field in these dat, skipping
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
if(($latitude=~/\d/  || $longitude=~/\d/)){ #If decLat and decLong are both digits
	if ($datum){ #report is datum is present
		
		s/  +/ /g;
		s/^ *//g;
		s/ *$//g;
		s/ //g;
		$datum="not recorded" if $datum=~/^Unk$/i;

	}
	else {$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
	}
}	
	
#Their georeference source field has this extra stuff in it, ~50 records
#It also had carriage returns, but John takes those out on his end

foreach($georeferenceSource){
	s/By__________Date________/ /i;
	s/'//g;
	s/^N.?A//ig;
	s/  +/ /g;
	}	
	

foreach ($errorRadius){
	s/feet/ft/;
	s/ft/ ft/;
	s/m/ m/;
	s/k m/ km/; #to correct the previous line from turning "km" into "k m"
	s/  +/ /g;
	s/,//g;
}

#skipped the enxt one because these are seperate fields in these data
#Error radius must be split because of bulkloader format
#if ($errorRadius=~/(\d+) (.*)/){
#	$ER_units=$2;
#	$errorRadius=$1;
#}
#else {
#	$ER_units="";
#}

foreach ($errorRadiusUnits){
	s/'//g;
	s/^0$//;
	s/^N.?A//i;
	s/  +/ /g;
	s/,//g;
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
#Macromorphology, including abundance
foreach ($plant_description){
		s/^N.?A//i;
		s/"/'/;
		s/^'//;
		s/'$//;
		s/  +/ /;
		s/^ *//g;
}


foreach ($notes){
		s/"/'/;
		s/^'//;
		s/'$//;
		s/  +/ /g;
		s/^ *//;
		$notes="" if $notes=~/^None$/i;
}



###########HABITAT#########
#Habitat is all in one field and seems to have no problem
foreach ($habitat){
		s/^N.?A//i;
		s/"/'/;
		s/^'//;
		s/'$//;
		s/  +/ /g;
		s/^ *//;
		s/^ *\. *//; #SD only so far.. some records start with a period and period & spaces for some reason
		s/^ *: *//; #SD only so far.. some records start with a punctuation and period & spaces for some reason

}


#####ASSOCIATED SPECIES#####
#free text field
foreach ($associatedTaxa){
		s/"/'/;
		s/^'//;
		s/'$//;
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/with / /g;
	s/120897//;	#fix SD58404 with a number only in Associates
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/^ *//;
	s/ *$//;
	s/  +/ /g;
}



#image URLs
my $aid4url;
my $imageURL;

if ($imageAvailable == 1){ #this field in this dataset is yes=1, no=0;
	$aid4url = $id;
	$aid4url =~ s/SD//;
	$imageURL = 'http://SDPlantAtlas.org/StarZoomPA/HiResSynopticSZ.aspx?H='.$aid4url;
}
else {
	$aid4url=$imageURL="";
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
Habitat: $habitat
Associated_species: $associatedTaxa
T/R/Section: $TRS
USGS_Quadrangle: $topo_quad
UTM: $UTM
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance: $errorRadius
Max_error_units: $errorRadiusUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Macromorphology: $plant_description
Notes: $notes
Cultivated: $cultivated
Hybrid_annotation: $hybrid_annotation
Annotation: $det_string
Image: $imageURL

EOP
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


    my $file_in = '/JEPS-master/CCH/Loaders/SD/SD_out.txt';	#the file this script will act upon is called 'CATA.out'
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







