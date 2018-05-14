#useful one liners for debugging:
#perl -lne '$a++ if /Accession_id: CAS-BOT-BC\d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id: CAS\d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id: DS\d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id:/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Decimal_latitude: \d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Cultivated: P/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Cultivated: [^P]+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id: CAS\d+/; END {print $a+0}' CAS_out.txt


#CAS input has 3 date fields: start date, end date, verbatim date
#apparently the verbatim date is not the most accurate depiction of the date
#This script put the start date into EJD and the end date into LJD and the verbatim date into date.
#This leads to dates apparently sorting out of order when JD and verbatimDate don't agree
# 536  iconv -f utf-16 -t utf-8 *export* >CAS_utf8.tab
print "fix type variables in this script\n";

use Geo::Coordinates::UTM;
use strict;
#use warnings;
use Data::GUID;
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
my $count_record;
my $GUID;
my %GUID_old;
my %GUID;
my $old_AID;
my $barcode;


open(OUT, ">/JEPS-master/CCH/Loaders/CAS/CAS_out.txt") || die;
open(OUT2, ">/JEPS-master/CCH/Loaders/CAS/CAS_DS_ID.txt") || die;
open(OUT3, ">/JEPS-master/CCH/Loaders/CAS/CAS_DS_GIS.txt") || die;
open(OUT4, ">/JEPS-master/CCH/Loaders/CAS/AID_GUID_CAS.txt") || die;

#log.txt is used by logging subroutines in CCH.pm
my $error_log = 'log.txt';
unlink $error_log or warn "making new error log file $error_log";


my $file = '/JEPS-master/CCH/Loaders/CAS/CAS2017_BAJA_CA_Mod.txt';	#name on conjoined file produced by merge_CAS.pl
open (IN, $file) or die $!;
Record: while(<IN>){
	chomp;

	$line_store=$_;
	++$count;		

#fix some data quality and formatting problems that make import of fields of certain records problematic
#skipping: Z) problem character detected: s/\xc2\xb0/    /g   ° ---> 45°	5°	20°	45-60°;	2°	30°,	75°	30°	60--65°F.	2°-3°	30°;	3°-4°	10°	3°,	15°	41°	123°	40°;	33°59'47	117°22'57	0°-20°,	S50°E.	East-45°	124°	1°-2°.	17°,	40°	122°	34°	118°	1°	1/2°	120°	10°-15°	8°	34°35'26-28	34°35'34-36.5	118°28'52-54	33°45	116°41-41	5°-8°	33°	114°	≥90°;	5°-8°.	(220°),	25-30°	[°]	22-24°	25-55°	3°-6°	10°-15°.	1°-2°	33°31	117°	33°35'30	114°48'W,	34°...	45°.	60-80°.	20°.	40°.	15°.	3°	2-25°	35°	90°	5°-10°	44°	282°;	10°S	22°	90°,	25°	20-25°	17°.	10-20°	10°.	15-20°	N34°W,	116°41-42'	4°	34°16'N,	118°20-21'W.	2°-4°.	34°18	117°51-52'W.	5-10°	2°-4°	3'-1°	3°.	116°	18'-3°	2°.	N10°E.	50-70°	36°	6°	115°	32°	1°-3°	70°	20°-30°	60°.	80°	16°	13°	39°	25°,	8°,	63°.	~20°,	~17°,	~34°,	2°,	15°,	20°,	0--15°	12°	5°,	
#skipping: Z) problem character detected: s/\xc2\xb1/    /g   ± ---> ±100m.	±1mm.	±suffused	30±	±	±1	±0.5-1.5	±12	±.	±glaucous	±burgundy	±E	±SSE	±white,	±translucent	±shaded	±northeasterly	(±	±uncommon	±erect,	±100m	±1000m	±1000m.	±decumbent,	±7-9	±pyramidal,	±Loose	±Flat,	±bitter	±Flat	±20	±300	±10000m.	±ascending,	±thick	±Succulent,	4±	±compacted	±prostrate;	±8	±3	±1000	±Erect	±13-15	(±driest	±N-facing	±open	±bright	±10000m).	±Open,	±lavender;	±40.	Bracts±	±100	±200m.	25'±	±18	±sessile,	±white.	±elliptic,	±1.3	±ovate,	±common,	±disturbed	±open,	±glabrous	in.±	±buff.	fls±white.	±hairy	ft.±	1'±	1'±;	ft±;	±erect	±prostrate.	±24	10±-disc	±flat,	±60-70	in.±.	±0.8	±visible;	±loose	±pink.	±rounded	(±center)	±5-7	±purple-maroon.	±fleshy	±Shaded	±erect.	scented/±	±blotched,	±lightly	±equal	±purple.	
#skipping: Z) problem character detected: s/\xc2\xb2/    /g   ² ---> 200m²,	m².	200m²	
#skipping: Z) problem character detected: s/\xc2\xb9/    /g   ¹ ---> Greek¹origin	
#skipping: Z) problem character detected: s/\xc2\xbc/    /g   ¼ ---> ¼-1/3	1¼	¼-½	¼	SW¼	SE¼	NE¼	NW¼	¼,	S¼	SNE¼	SNW¼	SESW¼	NESW¼	SSW¼	NE¼\	3SW¼	SE¼NW¼	8¼	
#skipping: Z) problem character detected: s/\xc2\xbd/    /g   ½ ---> 1½	½-1	½	4½	1-1½	2½	3½-4½	1½-2	2-3½	1½-3	3½	8½	2-1½	3½-5	3-4½	2½-3	1½dm	3½-4	2½x½	3-3½	5½	½-2	1-2½	6½	1½-4	1½-2½	4½-9	2½-4½	1½mm	1½-5	2-5½	11½	2½-3½	3-7½	4½-7	4½-8	4½-5½	4½-5	4-6½	1-½	1½',	5½-12	2½x3½	2½'	1½'.	1½-4½	¼-½	To1-1½	1½'	24½	1'-1½'	N½	-1½'	E½	S½	mid-N½	W½	1-1½'	4½',	5-15½'	2-4½	3½'	2½,	1-1½'high,	1-2½'	7½	2-2½	2½ft.	2-2½'	½.	1½'-2'	S11S½	6½-7	1-2½',	2-4½'	2-12½'	
#skipping: Z) problem character detected: s/\xc2\xbd\xc2\xb0/    /g   ½° ---> -1½°	
#skipping: Z) problem character detected: s/\xc2\xbe/    /g   ¾ ---> ¾	¾-1	SE¾	
#skipping: Z) problem character detected: s/\xc3\x85/    /g   Å ---> Å	
#skipping: Z) problem character detected: s/\xc3\x97/    /g   × ---> ×	×kinselae	4×4	
#skipping: Z) problem character detected: s/\xc3\xa1/    /g   á ---> liláceo	Guzmán	Hernández	
#skipping: Z) problem character detected: s/\xc3\xa8/    /g   è ---> Laferrière	
#skipping: Z) problem character detected: s/\xc3\xa9/    /g   é ---> José	roméro	Jorgé	Calamajué	Renée	café	café.	Gagné	[née	Héctor	André	H.Lév.	Francois-André	Née	LaPré	André;	Labbé	Barbé	
#skipping: Z) problem character detected: s/\xc3\xad/    /g   í ---> río	Domínguez	xerofítica.	Holguín	Holguín;	Díaz	María	García	
#skipping: Z) problem character detected: s/\xc3\xaf\xc2\xbb\xc2\xbf/    /g   ï»¿ ---> ï»¿spreading	
#skipping: Z) problem character detected: s/\xc3\xb1/    /g   ñ ---> cañon	Muñoz;	piñon,	piñon	Piñon	Villaseñor	Zuñiga	Peñalosa	Cañon	Peñalosa;	cañons	[cañon]	Piñons.	[piñon]	madroño,	[Cañon]	madroño	Madroño	piñon-juniper	[cañons]	madroño.	Piñons,	Cañons	Piñons	piñons	cañon;	Piñon,	Madroño.	Piñon-juniper	piñons,	cañon-bottom	cañon-side.	Peñalosa,	Muñoz	
#skipping: Z) problem character detected: s/\xc3\xb3/    /g   ó ---> León	Fród.	rosetófilos,	Próo	xerófilo.	López	Bayón	
#skipping: Z) problem character detected: s/\xc3\xb6/    /g   ö ---> Göte	Löben	
#skipping: Z) problem character detected: s/\xc3\xb8/    /g   ø ---> Sørensen	
#skipping: Z) problem character detected: s/\xc3\xba/    /g   ú ---> Común	
#skipping: Z) problem character detected: s/\xc3\xbc/    /g   ü ---> Kük.,	Kük.	Brün;	
#skipping: Z) problem character detected: s/\xe2\x80\x93/    /g   – ---> –Brittonia,	–	
#skipping: Z) problem character detected: s/\xe2\x80\x94/    /g   — ---> 15—30%	
#skipping: Z) problem character detected: s/\xe2\x80\x9c/    /g   “ ---> “The	
#skipping: Z) problem character detected: s/\xe2\x80\x9d/    /g   ” ---> interested.”	
#skipping: Z) problem character detected: s/\xe2\x80\xa6/    /g   … ---> …	
#skipping: Z) problem character detected: s/\xe2\x89\xa4/    /g   ≤ ---> ≤	≤7	
#skipping: Z) problem character detected: s/\xe2\x89\xa5/    /g   ≥ ---> ≥90°;	
#skipping: Z) problem character detected: s/\xe2\x99\x80/    /g   ♀ ---> ♀	♀.	♀,	
#skipping: Z) problem character detected: s/\xe2\x99\x82/    /g   ♂ ---> ♂	♂;			
	s/£/ /g; #unknown character in coordinates
#skipping: Z) problem character detected: s/\xc2\xa3/    /g   £ ---> £20N04	
	s/Í/i/g;
#skipping: Z) problem character detected: s/\xc3\x8d/    /g   Í ---> TÍa	
	s/à/a/g;
#skipping: Z) problem character detected: s/\xc3\xa0/    /g   à ---> à	

		s/Ã/'/g;
#skipping: Z) problem character detected: s/\xc3\x83\xc2\x8d/    /g   Ã ---> CaseyÃs	PrisonerÃs	

	s/¿//g;	#actual 'U+00BF	¿	\xc2\xbf' character
	s///g; #x{0B} hidden character
		s/♂/ male /g;	
		s/♀/ female /g;	
		s/…/./;
	s/×/ X /g;
	s/»/>>/g;
		s/≤/<=/g;
			s/≥/>=/g;
		s/º/ deg. /g;	#masculine ordinal indicator used as a degree symbol
		s/°/ deg. /g;
		s/˚/ deg. /g;
	s/ø/o/g;
	s/ö/o/g;
	s/õ/o/g;
#skipping: Z) problem character detected: s/\xc3\xb5/    /g   õ ---> Canõn
	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ê/e/g;
#skipping: Z) problem character detected: s/\xc3\xaa/    /g   ê ---> Tulê	Rêche	
	s/ä/a/g;
	s/á/a/g;
	s/í/i/g;
	s/ú/u/g;
	s/ü/u/g;	#U+00FC	ü	\xc3\xbc
	s/ñ/n/g;	
		s/–/--/g;	
		s/—/--/g;
		s/`/'/g;		
		s/‘/'/g;
		s/’/'/g;
		s/”/'/g;
		s/“/'/g;
		s/”/'/g;
		s/±/+-/g;	#CHSC28135 and others
		s/²/ squared /g;
		s/¹/ /g;
		
		s/¼/ 1\/4 /g;	
		s/½/ 1\/2 /g;	
		s/¾/ 3\/4 /g;	


#mismatched conversion errors
	s/Å/ /g; #U+00C5	Å	\xc3\x85
		s/ï/ /g; #U+00EF	ï	\xc3\xaf

	
	
	






        if ($. == 1){#activate if need to skip header lines
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
my $occurrenceID;
my $herb;
my $UTM;
my $minimumElevation;
my $maximumElevation;
my $elevationUnits;
my $det_determiner;
my $type_name;
my $type_status;
my $det_date;
my $LatLong_Method;
my $end_date;


		my @fields=split(/\t/,$_,100);

        unless( $#fields == 33){  #if the number of values in the columns array is exactly 34

	&log_skip ("$#fields bad field number $_\n");
	++$skipped{one};
	next Record;
	}
#normal headers	
#Herbarium	AccessionNumber	FullTaxonName	Collectors	StartDate	CollectionNumber	County	Locality	Habitat	SpecimenDescription	TRS	UTM	latitude1	longitude1	LatLongMethod	Notes	ElevMin	ElevMax	ElevUnits	TypeStatus	Determiner	DetDate	OrigTypeName	CollectionObjectID	EndDate	VerbatimDate	Barcode	datum	GeorefUncertainty	GeorefUncertaintyUnit	GUID	GeoRefSource
#Herbarium	AccessionNumber	FullTaxonName	Collectors	StartDate	CollectionNumber	County	Locality	Habitat	SpecimenDescription	TRS	UTM	latitude1	longitude1	LatLongMethod	Notes	ElevMin	ElevMax	ElevUnits	TypeStatus	Determiner	DetDate	OrigTypeName	
#EndDate	VerbatimDate	Barcode	datum	GeorefUncertainty	GeorefUncertaintyUnit	GUID	GeoRefSource
#merge file header:
#cultivated	country	state	herbarium	accession	name	collectors	start_Date	collNumber	county	location	habitat	description	TRS	UTM	latitude	longitude	LatLong_Method	notes	elev_min	elev_max	elev_units	type_status	determiner	det_date	type_name	endDate	verbatimDate	barcode	datum	GeorefUncertainty	GeorefUncertaintyUnit	GUID	georeference_source


	($cultivated,
	$country,
	$stateProvince,
	$herb, 
	$id, 
	$tempName,  
	$verbatimCollectors, 
	$eventDate, 
	$recordNumber, 
	$tempCounty, #10
	$locality, 
	$habitat, 
	$plant_description, 
	$TRS, 
	$UTM, 
	$verbatimLatitude, 
	$verbatimLongitude, 
	$LatLong_Method, #not sure about this field, skip if blank and use source below
	$notes,
	$minimumElevation,	#20
	$maximumElevation, 
	$elevationUnits, 
	$type_status, 
	$det_determiner, 
	$det_date, 
	$type_name, 
#	$CollectionObjectID, #field not present in Aug2014 load, included in 2016, but not included in 2017
	$end_date, 
	$verbatimEventDate, 
	$barcode, 
	$datum,	#30	
	$errorRadius,	
	$errorRadiusUnits,
	$occurrenceID,
	$georeferenceSource)=@fields;

#




########ACCESSION NUMBER
#check for nulls
if ($barcode=~/^ *$/){
	&log_skip("Record with no barcode $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space
foreach($barcode){
	s/^0+//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}


#Remove duplicates
if($seen{$barcode}++){
	warn "Duplicate number: $id\t$barcode\n";
	&log_skip("Duplicate accession number, skipped:\t$id\t$barcode");
	++$skipped{one};
	next Record;
}

#Add prefix to unique identifier field, 
$barcode="CAS-BOT-BC".$barcode;
$old_AID=$herb.$id;

if (length ($occurrenceID) > 1){
	$GUID{$barcode}=$occurrenceID;
	$GUID_old{$old_AID}=$occurrenceID;

	print OUT4 "$barcode\t".$GUID{$barcode}."\n";
	print OUT4 "$old_AID\t".$GUID_old{$old_AID}."\n";
}



##################Exclude known problematic specimens by id numbers, most from outside California and Baja California
	if(($barcode=~/^(CAS-BOT-BC305449)$/) && ($tempCounty=~m/San/)){ #skip, out of state
		&log_skip("County/State problem==>specimen excluded from CCH, San Bernardino Ranch, Arizona, is in Cochise County, not in California ($barcode: $stateProvince, $tempCounty, $locality)\n");	
		++$skipped{one};
		next Record;
	}
	if(($barcode=~/^(CAS-BOT-BC3877|CAS-BOT-BC3878)$/) && ($tempCounty=~m/^( *|[uU]nknown)$/)){ #skip, out of state
		&log_skip("County/State problem==> Specimen from Baja California Sur, specimen excluded from CCH, outside of CA-FP Baja ($barcode: $stateProvince, $tempCounty, $locality)\n");	
		++$skipped{one};
		next Record;
	}

	if ($stateProvince=~m/^Baja California Sur/){
		&log_skip("LOCATION Record Outside Country and State border==>($stateProvince) ($tempCounty) ($locality)\t$id");
		++$skipped{one};
		#print "skipping Baja California Sur specimen\n";
		next Record;
		
	}
	elsif ($stateProvince=~m/^C[Aa]|Baja California|Baja California Norte/){
		#do nothing
	}
	else{
		&log_skip("LOCATION Country and State problem, skipped==>($stateProvince) ($tempCounty) ($locality)\t$id");
		++$skipped{one};
		next Record;
	}




#####Annotations  (use when no separate annotation field)
	#format det_string correctly
my $det_rank = "current determination (uncorrected)";  #set to text in data with only a single determination
my $det_name = $tempName;
my $det_stet;

	
	if ((length($det_name) >= 1) && (length($det_determiner) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) >= 1) && (length($det_determiner) >= 1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}
	elsif ((length($det_name) >= 1) && (length($det_determiner) == 0) && (length($det_date) >= 1)){
		$det_string="$det_rank: $det_name, $det_date";
		#print $det_string."==>".$barcode."\n";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) >= 1) && (length($det_date) >= 1)){
		$det_string="$det_rank: $det_determiner, $det_date";
		#print $det_string."==>".$barcode."\n";
	}	
	elsif ((length($det_name) >= 1) && (length($det_determiner) >= 1) && (length($det_date) >= 1)){
		$det_string="$det_rank: $det_name, $det_determiner $det_date";
	}	
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($det_date) == 0)){
		$det_string="";
	}
	else{
		$det_string="$det_rank: $det_name, $det_determiner,  $det_date";
		print "det problem: ".$det_string."==>".$barcode."\n";
	}

##########Begin validation of scientific names


###########SCIENTIFICNAME
#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($tempName){
	s/\*//g;
	s/\?//g;
	s/\(//g;
	s/\)//g;
	s/;//g;
	s/cf.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/NULL//gi;
	s/[uU]nknown//g; #added to try to remove the word "unknown" for some records
	s/×/X /;	#change  " x " in genus name to the multiplication sign
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
	}


#format hybrid names
if($tempName =~ m/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation = $tempName;
	warn "Hybrid Taxon: $1 removed from $tempName\n";
	&log_change("Hybrid Taxon: $1 removed from $tempName");
	$tempName=$1;
}
else{
	$hybrid_annotation="";
}

#####process taxon names

#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published
if (($barcode =~ m/^(CAS-BOT-BC373925)$/) && (length($TID{$tempName}) == 0)){ 
#N	MX	Baja California	CAS	1014658		T. R. Van Devender; A. L. Reina G.; Mark Alan Dimmitt; J. F. Wiens; M. Sitter	2001-03-20	2001-248		17.7 km east-southeast of El Rosario on Mex. 1	Sonoran desertscrub with Fouquieria columnaris.	Locally common subshrub, fruits inflated with pink reticulated lines.			30.0461111111	-115.5619444444		THis specimen probably has the wrong original label.  Rebman indicates on his annotation that the description on the label is that of Harfordia macroptera.	265		m		Rebman & Vanderplank	2015-01-01		2001-03-20	20 March 2001	373925				urn:catalog:CAS:BOT-BC:373925	
	$tempName =~ s/^$/Harfordia macroptera/; #fix special case
	&log_change("Scientific name error - taxon name mentioned in notes field but no data in taxon name, modified to \t$tempName\t--\t$barcode\n");
}

#####process taxon names

$scientificName=&strip_name($tempName);
$scientificName=&validate_scientific_name($scientificName, $barcode);


#####process cultivated specimens			
# flag taxa that are cultivars, add "P" for purple flag to Cultivated field	

## regular Cultivated parsing
	if ($cultivated !~ m/^P$/){
		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("CULT: specimen likely not cultivated, purple flagging skipped\t$scientificName\t--\t$barcode\n");
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($habitat =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental\.|ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("CULT: Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$barcode\n");
		}
#add exceptions here to the CCH cultivated routine on a specimen by specimen basis
		elsif (($id =~ m/^(CAS-BOT-BC489624)$/) && ($scientificName =~ m/^Enchylaena tomentosa/)){
			&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
		$cultivated = "";
		}
#check remaining specimens for status with CCH cultivated routine
		else {		
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$barcode\n");	
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
my $eventDateAlt;

foreach ($eventDate,$verbatimEventDate){
	s/^ *//g;
	s/'//g;
	s/ *$//g;
	s/  +/ /g;
	
}


foreach ($eventDate){
	s/\*//g;
	s/ 00:.*//;
	s/^00//;
	s/__//;
	s/Unknown//i;
	s/^ *\.//g; 
	s/^ *//g;
	s/ *$//g;
	s/\./ /g;	#delete periods after Month abbreviations
	s/\//-/g;	#convert / to -
	s/No date//i;
	s/Unknown 0000//i;			
	s/Unspecified//i;
	s/Unknown//i;
	s/No date given//i;
	s/None given//i;
	s/none listed//i;
	s/ of / /i;
	s/ ca / /i;   #delete isolated qualifiers
	s/0000//;	
	s/Mid-//i;
	s/Year. *//i;
	s/\?//g;
	s/given//i;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
	}

#fix some really problematic date records
#	if(($id=~/SD249284/) && ($eventDate=~/26 February 14/)){ 
#		$eventDate=~s/26 February 14/26 February 2014/;
#		&log_change("Date problem modified: $eventDate\t$id\n");	
#	}


#continue date parsing



	if($eventDate=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1)$eventDate\t$id";
	}
	elsif($eventDate=~/^(\d\d)-(\d\d)-([0-9]{4})/){	#added to SDSU, if eventDate is in the format ##-##-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(2)$eventDate\t$id";
	}
	elsif($eventDate=~/^([0-9]{1})-([0-9]{1,2})-([0-9]{4})/){	#added to SDSU, if eventDate is in the format #-##?-####, most appear that first # is month 
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(3)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([Ss][pP][rR][ing]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "(14)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([Ss][uU][Mm][mer]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "6";
		$DD = "1";
		$MM2 = "8";
		$DD2 = "31";
	warn "(16)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([fF][Aa][lL]+)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$DD = "1";
		$MM = "9";
		$DD2 = "30";
		$MM2 = "11";
	warn "(12)$eventDate\t$id";
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
	warn "(11)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "(13)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "(15)$eventDate\t$id";
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
	warn "(20)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([Ss][uU][Mm][mer]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "(17)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]*$/){
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
		$MM="";
	warn "(18)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})-([0-9]{1,2})[- ]*$/){
		$MM=$2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
	warn "(19)$eventDate\t$id";
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
		s/^ *//;
		s/ *$//;
}
$collector = ucfirst($verbatimCollectors);

	
	if ($collector =~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
#		$recordedBy = &CCH::validate_collectors($collector, $barcode);	
		$recordedBy = $collector;
	#D Atwood; K Thorne
		$other_coll=$2;
		#warn "Names 1: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
		&log_change("COLLECTOR (): modified: $verbatimCollectors==>$collector--\t$recordedBy\t--\t$other_coll\t$barcode\n");	
	}
	
	elsif ($collector !~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
#		$recordedBy = &CCH::validate_collectors($collector, $barcode);
		$recordedBy = $collector;
		#warn "Names 2: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
	}
	elsif (length($collector == 0)) {
		$recordedBy = "Unknown";
		&log_change("COLLECTOR (2): modified from NULL to $recordedBy\t$barcode\n");
	}	
	else{
		&log_change("COLLECTOR (3): name format problem: $verbatimCollectors==>$collector\t--$barcode\n");
	}


###further process other collectors
foreach ($other_coll){
	s/'$//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;

}
$other_collectors = ucfirst($other_coll);


if ((length($recordedBy) > 1) && (length($other_collectors) > 1)){
	#warn "Names 1: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";}
}
elsif ((length($recordedBy) > 1) && (length($other_collectors) == 0)){
	#warn "Names 2: $verbatimCollectors\t--\t$recordedBy\t--\t$other_collectors\n";
}
elsif ((length($collector) == 0) && (length($other_collectors) == 0)){
	$recordedBy =  $other_collectors = $verbatimCollectors = "";
	&log_change("Collector name NULL\t$id\n");
}
else {
		&log_change("Collector name problem\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}

#############CNUM##################COLLECTOR NUMBER####

foreach ($recordNumber){
	s/\*//g;
	s/#//;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}


($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);





####COUNTRY
foreach ($country){
	s/\*//g;
	s/^MX/MEX/;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

####STATE
foreach ($stateProvince){
	s/\*//g;
	s/Baja California Norte/Baja California/; #colloquial name used before 1952, now just Baja California for the northern part of the penninsula
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}





###########COUNTY###########

	foreach ($tempCounty){
	s/[mM]unicipality//g;
	s/\*//g;
	s/'//g;
	s/^ +//g;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries
}

##################Fix known problematic specimens by id numbers
	if(($barcode=~/^(CAS-BOT-BC165041)$/) && ($tempCounty=~m/San D/)){ 
			$tempCounty=~s/San Diego/San Benito/;
			$verbatimLatitude =~s/^.*$/36.83/;
			$verbatimLongitude =~s/^.*$/-121.52/;
			$LatLong_Method =~s/^.*$/Coordinates copied from UC20288/;
		&log_change("COUNTY: County/State problem==>Brewer log states on July 8, 1861 they were at San Juan Bautista in San Benito County, which is near Gabilan (not Gavilan in San Diego/Riverside County), lat/long copied from  UC20288 ($barcode: $tempCounty, $locality)\n");	

	}
	if(($barcode=~/^(CAS-BOT-BC99184)$/) && ($tempCounty=~m/Yuba/)){ 
			$tempCounty=~s/^.*$/Riverside/;
		&log_change("COUNTY: County/State problem==>Other Grant specimens from fall 1901 and 1902 were all collected in the San Jacinto Mts, Riverside Co., not Yuba County, ($barcode: $tempCounty, $locality)\n");	
			
	}
	if(($barcode=~/^(CAS-BOT-BC357548)$/) && ($tempCounty !~ m/Riverside/)){ 
			$tempCounty=~s/^.*$/Riverside/;
		&log_change("COUNTY: County/State problem==>Other Grant specimens from fall 1901 and 1902 (see CAS-BOT-BC93699, Grant 4441) were all collected in the San Jacinto Mts, Riverside Co., not Yuba County, ($barcode: $tempCounty, $locality)\n");	
			
	}	
	
	

#format county as a precaution
$county=&CCH::format_county($tempCounty,$barcode);


#Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$barcode");		
	}

foreach($GUID){
print OUT2 "$herb$id\t$barcode\t$county\t$scientificName\t$GUID\n";
}

	
#validate county
		my $v_county;

	foreach ($county){ #for each $county value
        unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|Unknown)$/){
            $v_county= &verify_co($_); #Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
            if($v_county=~/SKIP/){ #If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
                &log_skip("COUNTY (2): NON-CA COUNTY?\t$_\t--\t$barcode"); #run the &skip function, printing the following message to the error log
                ++$skipped{one};
                next Record;
            }

            unless($v_county eq $_){ #unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
                &log_change("COUNTY (3): COUNTY $_ ==> $v_county--\t$barcode"); #call the &log function to print this log message into the change log...
                $_=$v_county; #and then set $county to whatever the verified $v_county is.
            }
        }
    }
    
    
##########LOCALITY#########

foreach ($locality){
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

#informationWithheld
		if($locality=~m/^\*/){ #if there is an asterisk at the start of the location data
			$locality = "Field redacted by CAS, contact the data manager for more information";
	 	}



###############ELEVATION########

foreach($elevationUnits){
	s/\*//g;
	s/feet/ft/;	#change feet to ft
	s/'/ft/;	#change ' to ft
	s/FT/ft/;	#change FT to ft
	s/Ft/ft/;	#change Ft to ft
	s/unspecified//i;
	s/NULL//g;
	s/meters/m/;
	s/[Mm]\.? *$/m/;	#substitute M/m/M./m., followed by anything, with "m"
	s/ft?\.? *$/ft/;	#subst. f/ft/f./ft., followed by anything, with ft
	s/  +/ /g;		#collapse consecutive whitespace as many times as possible
	s/^ +//;
	s/ +$//;

}

foreach($minimumElevation,$maximumElevation){
	s/\*//g;
	s/NULL//g;
	s/  +/ /g;		#collapse consecutive whitespace as many times as possible
	s/^ +//;
	s/ +$//;

}

if ($minimumElevation =~ m/^(-?[0-9]+)\.\d+/){ #eliminate decimal elevations, don't bother with rounding
$minimumElevation = $1;
}
if ($maximumElevation =~ m/^(-?[0-9]+)\.\d+/){ #eliminate decimal elevations, don't bother with rounding
$maximumElevation = $1;
}


	if ((length($minimumElevation) >= 1) && (length($maximumElevation) == 0) && (length($elevationUnits) >= 1)){
		$verbatimElevation="$minimumElevation $elevationUnits";
	}
	elsif ((length($minimumElevation) >= 1) && (length($maximumElevation) >= 1) && (length($elevationUnits) >= 1)){
		$verbatimElevation="$minimumElevation-$maximumElevation $elevationUnits";
	}
	elsif ((length($minimumElevation) >= 1) && (length($maximumElevation) >= 1) && (length($elevationUnits) == 0)){
		$verbatimElevation="$minimumElevation-$maximumElevation [units unknown]";
	}
	elsif ((length($minimumElevation) == 0) && (length($maximumElevation) >= 1) && (length($elevationUnits) >= 1)){
		$verbatimElevation="$maximumElevation $elevationUnits";
	}
	elsif ((length($minimumElevation) == 0) && (length($maximumElevation) >= 1) && (length($elevationUnits) == 0)){
		$verbatimElevation="$maximumElevation [units unknown]";
	}
	elsif ((length($minimumElevation) >= 1) && (length($maximumElevation) == 0) && (length($elevationUnits) == 0)){
		$verbatimElevation="$minimumElevation [units unknown]";
	}
	elsif ((length($minimumElevation) == 0) && (length($maximumElevation) == 0) && (length($elevationUnits) == 0)){
		$verbatimElevation="";
		&log_change("ELEVATION elevation fields NULL\t$barcode");
	}
	else{
	print "ELEVATION PROBLEM $barcode\n";
		&log_change("ELEVATION, missing data\t$barcode");
	}
	
	

	if ((length($minimumElevation) >= 1) && (length($maximumElevation) == 0)){
		$elevation = "$minimumElevation$elevationUnits";
	}		
	elsif ((length($minimumElevation) >= 1) && (length($maximumElevation) >= 1)){
		$elevation = "$minimumElevation$elevationUnits";
	}
	elsif ((length($minimumElevation) == 0) && (length($maximumElevation) >= 1)){
		$elevation = "$maximumElevation$elevationUnits";
	}
	elsif ((length($minimumElevation) == 0) && (length($maximumElevation) == 0)){
		$elevation = "";
		&log_change("Elevation NULL\t$elevationUnits\t$barcode");
	}
	else {
		&log_change("Elevation problem, elevation non-numeric or poorly formatted, $barcode\t--\t($minimumElevation)($maximumElevation)($elevationUnits)\t--\t($verbatimElevation)\n");		#call the &log function to print this log message into the change log...
		$elevation = "";
	}


#process verbatim elevation fields into CCH format
foreach($elevation){
	s/ //g;		#collapse space as many times as possible
	s/^-?0+$/0m/; #if elevation is zero, but no units, make it meters by default

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
		&log_change("Elevation: elevation '$elevation' has problematic formatting or is missing units\t$barcode");
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
						&log_change("Elevation in meters found within $barcode\t$locality");
					}
					elsif (m/^(-?[0-9]+) ?f/){
						$elevationInFeet = $1;
						$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation in feet found within $barcode\t$locality");
					}
					elsif (m/^-?[0-9]+-(-?[0-9]+) ?f/){
						$elevationInFeet = $1;
						$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation range in feet found within $barcode\t$locality");
					}
					elsif (m/^-?[0-9]+-(-?[0-9]+) ?m/){
						$elevationInMeters = $1;
						$elevationInFeet = int($elevationInMeters * 3.2808);
						$CCH_elevationInMeters = "$elevationInMeters m";
						&log_change("Elevation in meters found within $barcode\t$locality");
					}
					else {
						&log_change("Elevation in $locality has missing units, is non-numeric, or has typographic errors\t$barcode");
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
		&log_change ("ELEV: $county\t$elevation_test ft. ($elevationInMeters m.) greater than $county maximum ($max_elev{$county} ft.): discrepancy=", (($elevation_test)-$max_elev{$county}),"\t$barcode\n");
		if ((($elevation_test)-$max_elev{$county}) >= 500 ){
			$CCH_elevationInMeters = "";
			&log_change ("ELEV: $county discrepancy=", (($elevation_test)-$max_elev{$county})," greater than 500 ft, elevation changed to NULL\t$barcode\n");
		}
	}

#########COORDS, DATUM, ER, SOURCE#########
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


########COORDINATES

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
		s/-11742.71028/-117 42.71028/; #fix one set of Hrusa collections with a bad longitude
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
		 print "COORDINATE 2 $barcode\n";
		&log_change("COORDINATE decimals apparently reversed, switching latitude with longitude\t$barcode");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d +\d/) && ($verbatimLongitude =~ m/^\d\d +\d/)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		print "COORDINATE 3 $barcode\n"; 
		&log_change("COORDINATE apparently reversed, switching latitude with longitude\t$barcode");
	}	
	elsif (($verbatimLatitude =~ m/^-?1\d\d$/) && ($verbatimLongitude =~ m/^\d\d/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		 print "COORDINATE 4 $barcode\n";
		&log_change("COORDINATE latitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$barcode");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d/) && ($verbatimLongitude =~ m/^\d\d$/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		print "COORDINATE 5 $barcode\n";
		&log_change("COORDINATE longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$barcode");
	}
	elsif (($verbatimLatitude =~ m/^\d\d\./) && ($verbatimLongitude =~ m/^-?1\d\d\./)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
	#print "COORDINATE 6 $barcode\n";
	}
	elsif (($verbatimLatitude =~ m/^\d\d \d/) && ($verbatimLongitude =~ m/^-?1\d\d \d/)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
	print "COORDINATE 7 $barcode\n";
	}
	elsif (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d/)){
			$latitude = sprintf ("%.3f",$verbatimLatitude); #convert to decimal, should report cf. 38.000
			$longitude = $verbatimLongitude; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
	print "COORDINATE 8 $barcode\n";
			&log_change("COORDINATE latitude integer degree only: $verbatimLatitude converted to $latitude==>$barcode");
	}
	elsif (($verbatimLatitude =~ m/^\d\d/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
			$latitude = $verbatimLatitude; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
			$longitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 122.000
	print "COORDINATE 9 $barcode\n";
			&log_change("COORDINATE longitude integer degree only: $verbatimLongitude converted to $longitude==>$barcode");
	}	
	elsif ((length($verbatimLatitude) == 0) && (length($verbatimLongitude) == 0)){
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	#print "COORDINATE NULL $barcode\n";
	}
	else {
		&log_change("COORDINATE: Coordinate conversion problem for $barcode\t$verbatimLatitude\t--\t$verbatimLongitude\n");
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
		#print "COORDINATE PROBLEM \t$verbatimLatitude\t--\t$verbatimLongitude\t$barcode\n";
	}

#NULL coordinates that are only integer degrees, these are highly inaccurate and not useful for mapping
	if (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
		$decimalLatitude=$latitude = "";
		$decimalLongitude=$longitude = "";
		print "COORDINATE DEGREE ONLY\t$barcode\n";
		&log_change("COORDINATE decimal Lat/Long only to degree, now NULL: $verbatimLatitude\t--\t$verbatimLongitude\n");
	}

	foreach ($latitude, $longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s$//;
	}	

	foreach ($UTM){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
	}	


if (($barcode =~ m/^(CAS-BOT-BC33276)$/) && ($latitude =~ m/37\.21/)){ 
	$latitude = "34.216667";
	$longitude = "-116.8";
	&log_change("COORD: latitude and longitude ($verbatimLatitude; $verbatimLongitude) did not map within boundary of county and/or state on the label, coordinates changed to ($latitude; $longitude)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error and maps to west-central Nevada and not in San Bernardino County
}



#fix some problematic records with bad UTM's in home database

#UTM Problem, bad format: 38.0054/-119.28814 at parse_yose_new.pl line 1546, <IN> line 399.
#UTM Problem, bad format: 37.9747/-119.87668 at parse_yose_new.pl line 1754, <IN> line 8103.

	#if ($UTM =~ m/^38\.0054.+28814/){
		#lat long in UTM field
		
	#	$latitude = "38.0054";
	#	$longitude = "-119.28814";
		
	#	&log_change("COORD: LAT-LONG in UTM field, UTM changed to NULL, coordinates changed to $UTM==>$latitude\t$longitude\t$barcode");
	#	$UTM = "";
	#}
#UTM Problem, bad format: UTM 341E 4046N at parse_cas_new.pl line 1485, <IN> line 232884.
if (($UTM =~ m/341E 4046N/)){ 
	$UTM = "Zone 11 341000E 4046000N";
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#UTM ZONE Problem, bad format: UTM Zone 10 4230000E 504650N at parse_cas_new.pl line 1502, <IN> line 228435.
if (($UTM =~ m/Zone 10 4230000E 504650N/)){ 
	$UTM = "Zone 10 504650E 4230000N";
	&log_change("COORD: UTM poorly formatted, easting and northing flipped, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, too many digits in easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM 368E 4058N at parse_cas_new.pl line 1554, <IN> line 23032.
if (($UTM =~ m/368E 4058N/)){ 
	$UTM = "Zone 11 368000E 4058000N";
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM Zone 10 4470070E 393725N at parse_cas_new.pl line 1560, <IN> line 346663.
if (($UTM =~ m/4470070E 393725N/)){ 
	$UTM = "Zone 10 393725E 4470070N";
	&log_change("COORD: UTM poorly formatted, easting & northing flipped, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM Zone 10 508948E 445572N at parse_cas_new.pl line 1560, <IN> line 346641.
if (($UTM =~ m/508948E 445572N/)){ 
	$UTM = "Zone 10 508948E 4455720N";
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM Zone 11 462772E 371066N at parse_cas_new.pl line 1560, <IN> line 318187.
if (($UTM =~ m/462772E 371066N/)){ 
	$UTM = "Zone 11 462772E 3710660N"; 
	&log_change("COORD: UTM poorly formatted, easting & northing flipped, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM Zone 10 64450E 3994700N at parse_cas_new.pl line 1560, <IN> line 294458.
if (($UTM =~ m/64450E 3994700N/)){ 
	$UTM = "Zone 10 644500E 3994700N"; 
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM Zone 10 66247E 3981838N at parse_cas_new.pl line 1591, <IN> line 233156.
if (($UTM =~ m/66247E 3981838N/)){ 
	$UTM = "Zone 10 662470E 3981838N"; 
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM Zone 11 36670E 7422N at parse_cas_new.pl line 1591, <IN> line 196339.
if (($UTM =~ m/36670E 7422N/)){ 
	$UTM = "Zone 11 433670E 4007422N";
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM 354E 4046N at parse_cas_new.pl line 1560, <IN> line 279197.
if (($UTM =~ m/354E 4046N/)){ 
	$UTM = "Zone 11 354000E 4046000N";
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM 341496E 385498N at parse_cas_new.pl line 1591, <IN> line 362519.
if (($UTM =~ m/341496E 385498N/)){ 
	$UTM = "Zone 11 341496E 3854980N";
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM Zone 11 433046E 374903N at parse_cas_new.pl line 1591, <IN> line 363429.
if (($UTM =~ m/433046E 374903N/)){ 
	$UTM = "Zone 11 433046E 3749030N";
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM Zone 4046 340E at parse_cas_new.pl line 1591, <IN> line 165924.
if (($UTM =~ m/4046 340E/)){ 
	$UTM = "Zone 11 340000E 4046000N"; #36.546 -118.7875
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}
#COORDINATE 11d) UTM Problem, bad format: UTM 368E 4057N at parse_cas_new.pl line 1591, <IN> line 180100.
if (($UTM =~ m/368E 4057N/)){ 
	$UTM = "Zone 11 368000E 4057000N"; #36.649 -118.4767
	&log_change("COORD: UTM poorly formatted, missing digits, coordinates changed to ($UTM)==>$county\t$locality\t--\t$barcode\n");
	#the original is in error, zeros were added as the last digit to the northing and easting
}


#use combined Lat/Long field format for CAS

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
					&log_change("COORDINATE 1) Latitude problem, set to null,\t$barcode\t$verbatimLatitude\n");
					$lat_degrees=$lat_minutes=$lat_seconds=$decimalLatitude="";
				}
				else{
					#print "1a) $lat_degrees\t-\t$lat_minutes\t-\t$lat_seconds\t-\t$latitude\n";
	  				$lat_decimal = $lat_degrees + ($lat_minutes/60) + ($lat_seconds/3600);
					$decimalLatitude = sprintf ("%.6f",$lat_decimal);
					print "1b)$decimalLatitude\t--\t$barcode\n";
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
					&log_change("COORDINATE 2) Latitude problem, set to null,\t$barcode\t$latitude\n");
					$lat_degrees=$lat_minutes=$decimalLatitude="";
				}
				else{
					#print "2a) $lat_degrees\t-\t$lat_minutes\t-\t$latitude\n";
					$lat_decimal= $lat_degrees+($lat_minutes/60);
					$decimalLatitude=sprintf ("%.6f",$lat_decimal);
					print "2b) $decimalLatitude\t--\t$barcode\n";
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
					&log_change("COORDINATE 2c) Latitude problem, set to null,\t$barcode\t$latitude\n");
					$lat_degrees=$lat_minutes=$decimalLatitude="";
				}
				else{
					#print "2a) $lat_degrees\t-\t$lat_minutes\t-\t$latitude\n";
					$lat_decimal= $lat_degrees+($lat_minutes/60);
					$decimalLatitude=sprintf ("%.6f",$lat_decimal);
					print "2d) $decimalLatitude\t--\t$barcode\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($latitude =~ m/^(\d\d\.\d+)/){
				$lat_degrees = $1;
				if($lat_degrees > 90){
					&log_change("COORDINATE 3) Latitude problem, set to null,\t$barcode\t$lat_degrees\n");
					$lat_degrees=$latitude=$decimalLatitude="";		
				}
				else{
					$decimalLatitude=sprintf ("%.6f",$lat_degrees);
					#print "3a) $decimalLatitude\t--\t$barcode\n";
				}
		}
		elsif (length($latitude) == 0){
			$decimalLatitude="";
		}
		else {
			&log_change("check Latitude format: ($latitude) $barcode");	
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
					&log_change("COORDINATE 5) Longitude problem, set to null,\t$barcode\t$longitude\n");
					$long_degrees=$long_minutes=$long_seconds=$decimalLongitude="";
				}
				else{				
					#print "5a) $long_degrees\t-\t$long_minutes\t-\t$long_seconds\t-\t$longitude\n";
 	 				$long_decimal = $long_degrees + ($long_minutes/60) + ($long_seconds/3600);
					$decimalLongitude=sprintf ("%.6f",$long_decimal);
					print "5b) $decimalLongitude\t--\t$barcode\n";
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
					&log_change("COORDINATE 6) Longitude problem, set to null,\t$barcode\t$longitude\n");
					$long_degrees=$long_minutes=$decimalLongitude="";
				}
				else{
					$long_decimal= $long_degrees+($long_minutes/60);
					$decimalLongitude = sprintf ("%.6f",$long_decimal);
					print "6a) $decimalLongitude\t--\t$barcode\n";
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
				&log_change("COORDINATE 6c) Longitude problem, set to null,\t$barcode\t$longitude\n");
				$long_degrees=$long_minutes=$decimalLongitude="";
			}
			else{
				$long_decimal= $long_degrees+($long_minutes/60);
				$decimalLongitude = sprintf ("%.6f",$long_decimal);
				print "6d) $decimalLongitude\t--\t$barcode\n";
				$georeferenceSource = "DMS conversion by CCH loading script";
			}
		}
		elsif ($longitude =~m /^(-?1\d\d\.\d+)/){
				$long_degrees= $1;
				if($long_degrees > 180){
					&log_change("COORDINATE 7) Longitude problem, set to null,\t$barcode\t$long_degrees\n");
					$long_degrees=$longitude=$decimalLongitude="";		
				}
				else{
					$decimalLongitude=sprintf ("%.6f",$long_degrees);
					#print "7a) $decimalLongitude\t--\t$barcode\n";
				}
		}
		elsif (length($longitude == 0)) {
			$decimalLongitude="";
		}
		else {
			&log_change("COORDINATE check longitude format: $longitude $barcode");
			$decimalLongitude="";
		}
}
elsif ((length($latitude) == 0) && (length($longitude) == 0)){ 
#utm are in one field.. the following is the original parse code that still needs corrected


	if (length($UTM) >= 5){
	$zone= $easting= $northing="";
	$ellipsoid="23";
	$UTM =~ s/Zone 10 107/Zone 10 7/; #fix an odd typo

		if($UTM =~ m/(\d\d) (\d\d\d\d\d\d)E (\d\d\d\d\d\d\d)N/){
			$zone=$1;
			$easting=$2;
			$northing=$3;
			if(($zone =~ m/10/) && ($locality =~ m/(San Miguel Island|Santa Rosa Island)/i)){
				$zone = "10S"; #Zone for these data are this, using UTMWORLD.gif in DATA directory
			}
			elsif ($zone =~ m/10|11/ && ($locality !~ m/(San Miguel Island|Santa Rosa Island)/i)){
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
						&log_change("COORDINATE 11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone\t$barcode\n");
						
					$zone = "";
				}
			}
			else{
				warn "COORDINATE 11c) UTM Problem, bad ZONE format: $UTM";
			}
		}
		elsif($UTM =~ m/(\d\d\d\d\d\d)E (\d\d\d\d\d\d\d)N/){
			$zone="";
			$easting=$2;
			$northing=$3;
		}
		else{
			warn "COORDINATE 11d) UTM Problem, bad format: $UTM";
		}
		
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
				elsif($county =~ m/Mexicali/){
					$zone = ""; #Mexicali is in a small part of CA-FP Baja and it has sections in two zones, so UTM without zone is not convertable
					}
				else{
						&log_change("COORDINATE 11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone\t$barcode\n");
					$zone = "";
				}
			}
			elsif($zone =~ m/10|11/){
					#do nothing
			}
			else{
				warn "COORDINATE 11e) UTM Problem, bad ZONE format: $UTM";
			}

			if($zone =~ m/9|10|11|12/ && $easting =~ m/^\d\d\d\d\d\d$/ && $northing =~ m/^\d\d\d\d\d\d\d$/){
				($decimalLatitude,$decimalLongitude)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
				&log_change( "decimal derived from UTM $decimalLatitude, $decimalLongitude\t$barcode");
			}
			else{
				&log_change("UTM problem $zone $easting $northing\t$barcode");
			}
	}
	else{
		&log_change("using latitude and longitude, not UTM\t$barcode");
	}
}
elsif($latitude==0 && $longitude==0 && $UTM==0){
	$datum = "";
	$georeferenceSource = "";
	$decimalLatitude = $decimalLongitude = "";
		&log_change("COORDINATE coordinates entered as '0', changed to NULL $barcode\n");
}
else {
		&log_change("COORDINATE poorly formatted or non-numeric coordinates for $barcode: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
		$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
}

#final check of Longitude
	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			&log_change("Longitude made negative\t--\t$barcode");
	}


#final check for rough out-of-boundary coordinates
if((length($decimalLatitude) >= 2)  && (length($decimalLongitude) >= 3)){ 
	if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114.0 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california and northern Baja...
	###was 32.5 for California, now 30.0 to include CFP-Baja
		if ($decimalLatitude < 30.0){ #if the specimen is in Baja California Sur or farther south
			&log_skip("COORDINATE: Mexico specimen mapping to south of the CA-FP boundary?\t$stateProvince\t\t$county\t$locality\t--\t$barcode>$decimalLatitude< >$decimalLongitude<\n");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		else{
		&log_change("coordinates set to null for $barcode, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude = $decimalLongitude = $georeferenceSource = $datum="";	#and set $decLat and $decLong to ""  
		}
	}
}
else{
		if((length($decimalLatitude) == 0)  && (length($decimalLongitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $barcode: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}


#check datum
if(($verbatimLatitude=~/\d/  || $verbatimLongitude=~/\d/)){ #If decLat and decLong are both digits


	if ($datum =~ m /^([NADnadWGSwgs]+[ -19]*[23478]+)$/){ #report if true datum is present, toss out all erroneous data
		s/19//g;
		s/-//g;
		s/ //g;
		$datum = $1;
	}
	else {$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
	}
}	

#georeferenceSource
my $hold;

	if ((length($LatLong_Method) >=1) && (length($georeferenceSource) == 0)){
		$georeferenceSource = $LatLong_Method;
	}
	elsif ((length($LatLong_Method) >=1) && (length($georeferenceSource) >=1)){
		$hold = $georeferenceSource;
		$georeferenceSource = $LatLong_Method."; ".$hold;
	}

foreach($georeferenceSource){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
	}	
	

#Error Units
foreach ($errorRadius){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
}


foreach ($errorRadiusUnits){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
}

#final check of Longitude
if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			&log_change("COORDINATE Longitude made negative\t--\t$barcode");
	}
#final check for rough out-of-boundary coordinates
	if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114.0 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california and northern Baja...
	###was 32.5 for California, now 30.0 to include CFP-Baja
		&log_change("COORDINATE set to null for $barcode, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";	#and set $decLat and $decLong to ""  
	}
}
else {
		if((length($decimalLatitude) == 0)  && (length($decimalLatitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $barcode: ($decimalLatitude) \t($decimalLatitude)\n");
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


#####TYPE STATUS AND NOTES

##

#informationWithheld
		if($notes=~m/(.*) ?Data from these field.*/){ #if there is text stating that text has been redacted, use the string
			$notes = "DUE TO CONCERNS FOR THE PROTECTION OF RARE SPECIES, THE LOCATION AND COORDINATES HAVE BEEN REDACTED BY CAS.";
			&log_change("specimen redacted by CAS\t$barcode");
	 	}



my $hold;
	if ((length($type_name) >= 1) && (length($type_status) == 0)){
		$type_status="$type_name";
	}
	elsif ((length($type_name) >= 1) && (length($type_status) >= 1)){
		$hold = $type_status;
		$type_status="$type_name, $hold";
	}
	elsif ((length($type_name) == 0) && (length($type_status) >= 1)){
		$type_status = $type_status;
	}
	elsif ((length($type_name) == 0) && (length($type_status) == 0)){
		$type_status ="";
	}
	else{
	print "TYPE STATUS PROBLEM $barcode\n";
		&log_change("TYPE STATUS, missing data\t$barcode");
	}

++$count_record;
warn "$count_record\n" unless $count_record % 10000;


#This line added to loader when the main ID code is changed, making all the timestamp reports faulty
#this prints a file that then can be used on the most recent, previous timestamp file to change the ID's to the new accession number format
#for each matched accession record.  This also can make sure the TID's match.  
#If the TID's do not match, either it is a new annotation or it is a duplicate accession.  There is not a way to know the difference yet.
#therefore in both of these cases, the timestamps will report a new record.
#In most cases this is somewhat accurate because these duplicate accessions have been kicked out previously.  
#Now the new unique ID's will pass allow these records to pass through.
#Georeference ID's will also have to be updated using this table.


if((length($verbatimLatitude) == 0) && (length($verbatimLongitude) == 0)){ 
print OUT3 "$herb$id\t$barcode\t$county\t$scientificName\n";
}



            print OUT <<EOP;
Accession_id: $barcode
Other_label_numbers: $old_AID
Name: $scientificName
Date: $eventDate
EJD: $EJD
LJD: $LJD
Collector: $recordedBy
Other_coll: $other_coll
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
Type_status: $type_status

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


    my $file_in = '/JEPS-master/CCH/Loaders/CAS/CAS_out.txt';	#the file this script will act upon is called 'CATA.out'
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



#close(OUT);

