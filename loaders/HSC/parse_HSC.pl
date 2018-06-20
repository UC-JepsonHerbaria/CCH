use Geo::Coordinates::UTM;

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
my $tempCounty;
my $count_record;

open(OUT, ">/JEPS-master/CCH/Loaders/HSC/HSC_out.txt") || die;


#use this command in terminal to add the cultivated field with text N at beginning of each line
#sed 's/^/N@@/' HSC_Sep2017.txt > HSC_Sep2017_MOD.txt
#then replace '\nN@@' with \nN\t in text editor


#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


	my $file = '/JEPS-master/CCH/Loaders/HSC/HSC_Sep2017_MOD.txt';


 open (IN, "<", $file) or die $!;

Record: while(<IN>){
	chomp;

#fix some data quality and formatting problems that make import of fields of certain records problematic
	s///g; #x{0B} hidden character
	s/ñ/n/g;
	s/º/ deg. /g;
	s/°/ deg. /g;
	s/×/ X /g;
	s/˚/ deg. /g;
	s/¼/1\/4/g;
	s/¾/3\/4/g;
	s/½/1\/2/g;
	s/±/+-/g;
	s/”/'/g;
	s/“/'/g;
	s/’/'/g;
	s/‘/'/g;
	s/´/'/g;
	s/ö/o/g;
	s/ó/o/g;
	s/é/e/g;

#skipping: problem character detected: s/\xc2\xb0/    /g   ° ---> N2°E	N20°E	W299°N	E112°S	W359°N	N70°E	N84°E	E144°S	N75°E	115°S	N42°E	W296°N	(303°)	(135°)	(97°)	(31°)	40.82998°	123.71219°	41.69527°	123.28321°	40.78805°	123.51164°	41.15213°	123.88952°	41.14003°	123.85954°	38.84619°	120.37542°	38.86786°	120.81692°	40.69529°	39.77613°	122.91735°	39.76642°	122.91271°	39.79236°	122.93195°	40°	45°W	42°W	20°E	55°	80°	S5°E	75°	60°	50°	35°	78°	85°	55°E	N40°E	40°E	20°S,	N32°E	45°E	65°	5°	45°	10°	112°,	N6°E	9°	N12°W	N1°W	N85°W	N88°W	N85°	N4°W	S10°W	25°W	15°	S37°W	S70°W	S15°W	N8°W	8°	S25°W	N2°W	N31°E	2°	N27°E	N26°E	N36°W	35°S	36°W	N17°W	20°S	N38°E	N7°	15°SSE,	5°E	N7°E	S53°E	N24°W	30°S	20°SSW,	S60°W	N10°E	2°E	S77°W	88°W	N85°E	N60°E	3°S	N80°E	N60°	S50°W	N4°	N7°W	N35°E	N18°E	10°SSW,	N11°E	N6°W	79°E	20°	64°E	7°W,	N18°W	N1°E	15°WNW	S79°E	N80°W	5°E,	83°	3°	25°S	N5°E	N70°W	10°W	7°NE,	S56°	S49°E	S54°E	S15°E	N35°W	S78°W	
#skipping: problem character detected: s/\xc2\xb1/    /g   ± ---> ±2	
#skipping: problem character detected: s/\xc2\xba/    /g   º ---> S16ºW	N6º	N5ºE	5ºW	N13º	35ºSW	
#skipping: problem character detected: s/\xc3\xa9/    /g   é ---> André	André,	André,T.	André,G.L.	André,S.	André,J.O.	André,Tasha	André,Jacob	André,John	LaPré	LaPré,	LaPré,J.	
#skipping: problem character detected: s/\xc3\xb1/    /g   ñ ---> Muñoz	Cañada,	
#skipping: problem character detected: s/\xc3\xb3/    /g   ó ---> Jerónimo	Elder,Jerónimo	
#skipping: problem character detected: s/\xc3\xb6/    /g   ö ---> Sörensen	Sörensen,	
#skipping: problem character detected: s/\xcb\x9a/    /g   ˚ ---> 65˚	S10˚W	N70˚E	20˚NW	S61˚W	N10˚E	S36˚E	10˚S	
#skipping: problem character detected: s/\xe2\x80\x98/    /g   ‘ ---> ‘May	‘Little	‘Shasta	‘G’	‘The	‘79)	‘Cross	‘S’	
#skipping: problem character detected: s/\xe2\x80\x99/    /g   ’ ---> Fender’s	Ave’s.,	Anderson’s	Craig’s	Jarnigan’s	Cox’s	Xavier’s	Liscom’s	Jarnigan’s.	Tulley’s.	Tilley’s	Yard’s	Lyon’s	Jewett’s.	Orcutt’s.	Dobbyn’s	Wood’s	Jarningan’s.	McDaniel’s	Nat’l	Harris’s	Captain’s	Jewett’s	Hooker’s	Asbill’s	Ma-Le’l	Wright’s	Lupton’s	Headland’s,	Brown’s	Lee’s	Ave’s.	Patrick’s	Martin’s	Climber’s	Scott’s	Andy’s	Devil’s	White’s	“Utah’s	Fall’s	Grove’s	Hindley’s	Hell’s	Boye’s	Bailey’s	200’	Crow’s	O’Brien,	Scotty’s	Ma-le’l	O’Byrne	Henniken’s	visitor’s	(Road’s	Dow’s	100’	~2,100’	Ma-l’el	O’Connell	O’Connell,	Lanphere’s,	Lanphere’s	Lanpheres’	Bair’s	BLM’s	Davison’s	Emmerson’s	Packer’s	Clark’s	Prospector’s	Hamilton’s	Switzer’s	Perkin’s	Spicer’s	Dante’s	Morrison’s	Carter’s.	Carter’s	Tryon’s	Lasseck’s	Plowman’s	Ballard’s	Gillem’s	Nat’l.	Devils’	Moore’s	Angwin’s	Week’s	Hough’s	O’Brien	Grant’s	Higgin’s	Duncan’s	O’Meara,	Gray’s	Smith’s	Stewart’s	Skagg’s	Jelly’s	Butler’s	Baker’s	Hanna’s	Campbell’s	Hatch’s	Myer’s	Howard’s	Salmina’s	Drake’s	Camp/O’Brien	Young’s	Blakes’	Blake’s	Miner’s	Field’s	Still’s	Hood’s	Berry’s	Hilary’s	Red’s	Child’s	water’s	Lamphere’s	Founder’s	McMillan’s	Cooper’s	Kelly’s	Skyway’s	McEnespy’s	Murrer’s	King’s	Natl’	Prisoner’	1905’	Robert’s	Penny’s,	O’Meara	Snowman’s	O’Neill	O’Farrill	Angelos’	Tom’s	Abbott’s	Horse’s	Jack’s	Uncle’s	“Horse’s	Mountain’	Pierce’s	Ridge’	Grey’s	Stuart’s	Lake-Abbott’s	Abbot’s	David’s	Tanner’s	O’Brien)	O’Meara,Gary	Wilson’s	Fout’s	Oroville’s	T’ai	5900’	Bevan’s	Eldredge’s	men’s	Butt’s	Gann’s	Eddy’s,	steward’s	Swain’s	Steven’s	Angelo’s	‘G’	Carter’s,	Sawyer’s	Johnson’s	Lem’s	O’Neil	O’Neil,	Bradbrook’s	Brandon’s	Pacific’s	Vann’s	Hull’s	5650’	5708’	Lander’s	it’s	Grogan’s	Fisherman’s	Prisoner’s	Becher’s	road’s	Beacher’s	Buzzard’s	Parrott’s	Camp-O’Brien	Gan’s	Van’s	Butcher’s	Well’s	Andre’	O’brien	Marv’s	O’Brien.	Vicker’s	Barton’s	Mary’s	Hill’s	50’	Reading’s	Beer’s	Hawkin’s	Hobart’s	Bower’s	Symm’s	Hunter’s	Weber’s	Hob’s	(Packer’s	Perk’s	Jone’s	Hopkin’s	Champ’s	Todd’s	5759’	Curtis’s	Owen’s	Green’s	Winter’s	rivers’	river’s	Ward’s	Walker’s	Sailor’s	Jackpeter’s	Park’s	Monk’s	Man’s	Milly’s	O’brien.	Dan’s	Springs’	Water’s	Igo’s	Miller’s	caretaker’s	5’	Mario’s	man’s	Deadman’s	Dead’s	7621’,	manager’s	8918’,	Lassic’s	Tomlinson’s	Tyron’s	Fowler’s	Bob’s	Whitey’s	Crook’s	Sam’s	Shepperd’s	Coomb’s	Bird’s-foot	Palmer’s	Haven’s	Ingram’s	O’Hare-Wade	O’Hare-Wade,S.	Owners’	Owner’s	Billy’s	Ham’s	N/Hell’s	Rick’s	Spring’s	Raven’s	Valley’s.	“Billy’s	Gov’t	Floyd,T’ai	James’	Bunn’s	Edmond’s	20’W	O’Connor-Henry	O’Connor-Henry,	O’Conner-Henry	O’Conner-Henry,	Shepard’s	Sholar’s	Bull’s	Lawson’s	Commbs’	Robertson’s	D’Alcamo,	Walt’s	Murphy’s.	Partick’s	Paine’s	Duffy’s	1950’s	80’	350’	‘S’	Nakamura’s	Jones’	Brady’s	30’	325’	Sportsman’s	O’brien,	Frenchman’s	Fleismann’s	CDFG’s	Bardee’s	Rice’s	Gallagher’s	summer’s	
#skipping: problem character detected: s/\xe2\x80\x9c/    /g   “ ---> “wild	“the	“Linnea	“Roost”.	“east	“big	“deep	“hiking	“Indian	“Picnic	“D”	“Old	“Val”	“TWin	“Utah’s	“Shangrila”.	“Road	“prairie,”	“Magalia	“Clems	“Cold	“Probably	“fire	“Rabbit”	“Type	“Base	“Horse’s	“Little	“Shasta	“Willow	“Bear	“Horses	“Rusty	“Y”	“The	“Sundew	“L”	“Riverside”	“Shop	“Robbers	“North	“Lake	(“Steward”)	“sheep	“5148”	“Flag	(“Coast	“dry	“Feather	“Cabin	“Mud	“middle”	“Maggies	“Billy’s	“Crooked	“Keller	“rock	“Diamond	“Broken	“safe”	“delta”	“Mixed”	“Marsh”,	“S”	“Osito	“Power	“mud	“Sawtooth	“M”	“Sierra	“Superbowl”	“Teh	“Meghdadi	“White	“Ivanpah”	
#skipping: problem character detected: s/\xe2\x80\x9d/    /g   ” ---> grass”.	hills”.	Fen”	Fen,”	“Roost”.	ridge”	bend”	curve”	corridor”	Head”	Area”	“D”	(”Gold”)	School”,	“Val”	Spring”,	Pasture”,	“Shangrila”.	Narrows”	“prairie,”	Serpentine”,	Dam”.	Camp”,	Springs”	locality”.	trail”	“Rabbit”	Keswick”	Meadow,”	Hole”,	Mtn.”	Ridge”	Meadow”,	Hole”	Meadow”	Camp”	Mt.”	“Y”	Cedars”	Bog”	“L”	“Riverside”	Pit”	4”	Rd.”	Ranch,”	Pines”.	Roost”	narrows”	Springs”,	road”	Prairie”	(“Steward”)	camp”	“5148”	Springs,”	1”	Reservation”)	lake”,	Flat”	“middle”	Place”	Bar”	house”	Ranch”	Flats”	Chaparral”	“safe”	“delta”	“Mixed”	“Marsh”,	“S”	Flat,”	Flat”.	Point”	pole”	hole”	“M”	“Superbowl”	Serpentine”	13.50”	Property”	Fang”,	“Ivanpah”	Indians”,	


	$line_store=$_;
	++$count;		
		

	   if ($. == 1){#activate if need to skip header lines
			next;
		}




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
my $det_month; 
my $det_day;
my $det_year;
my $lat_deg;
my $lat_min;
my $lat_sec;
my $long_deg;
my $long_min;
my $long_sec;
my $lat_hem;
my $long_hem;
my $fraction;
my $UTM_grid_cell;
my $det_orig;

	my @fields=split(/\t/,$_,100);
	
	unless($#fields == 41){	#42 fields but first field is field 0 in perl

	&log_skip ("$#fields bad field number\t$_\n");
	++$skipped{one};
	next Record;
	}

#Unified Accession Number	Collector	Collector Number	Year	Month	Day	Associated Collectors	Family	Genus	species	subtype	subtaxon	Determiner	DetYear	DetMonth	DetDay	Collector Sites::Country	Collector Sites::State	Collector Sites::CountyMpio	Collector Sites::Locality	Collector Sites::Lat Degrees	Collector Sites::Lat Minutes	Collector Sites::Lat Seconds	Collector Sites::NorS	Collector Sites::Decimal Latitude	Collector Sites::Long Degrees	Collector Sites::Long Minutes	Collector Sites::Long Seconds	Collector Sites::WorE	Collector Sites::Decimal Longitude	Collector Sites::Township	Collector Sites::Range	Collector Sites::Section	Collector Sites::Quarter	Collector Sites::UTM Zone	Collector Sites::UTM	Collector Sites::UTME	Collector Sites::UTMN	Collector Sites::M	Collector Sites::FT	Collector Sites::Vegetation w soil
#fix more data quality and formatting problems



	
($cultivated,
$id,
$collector,
$recordNumber,
$coll_year,
$coll_month,
$coll_day,
$other_coll,
$family,
$genus, #10
$species,
$rank,
$subtaxon,
$identifiedBy,
$det_month, 
$det_day,
$det_year,
$country,
$stateProvince,
$tempCounty, #20
$locality,
$lat_deg,
$lat_min,
$lat_sec,
$lat_hem,
$verbatimLatitude,
$long_deg,
$long_min,
$long_sec,
$long_hem, #30
$verbatimLongitude,
$Township,
$Range,
$Section,
$fraction,
$zone,
$UTM_grid_cell,
$UTME,
$UTMN,
$elev_meters, #40
$elev_feet,
$habitat
) = @fields;


################ACCESSION_ID#############
#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
}


#remove leading zeroes, remove any white space
	
foreach($id){
	s/-+//g; #delete dashes
	s/ //g;
}

#Add prefix, 

if($id !~ m/^HSC\d+/){
	$id = "HSC$id"; #add prefix
}


#Remove duplicates
if($seen{$id}++){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}

#####Annotations  (use when no separate annotation field)
	#format det_string correctly
$genus, #10
$species,
$rank,
$subtaxon,
$identifiedBy,
$det_month; 
$det_day;
$det_year;


my $det_orig_rank = "current determination (uncorrected)";  #set to zero for original determination
my $det_orig_date = $det_year ."-" . $det_month . "-". $det_day;	
my $det_orig_name = $genus ." " . $species . " ". $rank . " ". $subtaxon;
my $det_orig_by = $identifiedBy;

	if ((length($det_orig_name) > 1) && (length($det_orig_by) == 0) && (length($det_orig_date) == 0)){
		$det_orig="$det_orig_rank: $det_orig_name";
	}
	elsif ((length($det_orig_name) > 1) && (length($det_orig_by) > 1) && (length($det_orig_date) == 0)){
		$det_orig="$det_orig_rank: $det_orig_name, $det_orig_by";
	}
	elsif ((length($det_orig_name) > 1) && (length($det_orig_by) == 0) && (length($det_orig_date) > 1)){
		$det_orig="$det_orig_rank: $det_orig_name, $det_orig_by";
	}
	elsif ((length($det_orig_name) > 1) && (length($det_orig_by) > 1) && (length($det_orig_date) > 1)){
		$det_orig="$det_orig_rank: $det_orig_name, $det_orig_by, $det_orig_date";
	}
	elsif ((length($det_orig_name) == 0) && (length($det_orig_by) == 0) && (length($det_orig_date) == 0)){
		$det_orig="";
	}
	else{
		&log_change("DET: Bad det string\t$det_orig_rank: $det_orig_name, $det_orig_by,  $det_orig_date");
		$det_orig="";
	}


my $name = $genus ." " . $species . " ". $rank . " ". $subtaxon;

foreach ($name){
	s/ sp\.$//; #remove " sp." when species unknown
	s/\?//g;
	s/"//g;
	s/;$//g;
	s/cf\.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;


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

#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#the name is only corrected herein and not global; allows name to pass through to CCH if name is ever published
#the original determination is preserved in the $det_string process above so users can see what name is on original label

if (($id =~ m/^(HSC103150|HSC103168|HSC103169|HSC103269|HSC103724|HSC103726|HSC103727|HSC103728|HSC103729|HSC103730|HSC103731|HSC103732|HSC103755|HSC103758|HSC103759|HSC103760|HSC103761|HSC103762|HSC103765|HSC103776|HSC103778|HSC22032|HSC32302|HSC34255|HSC34559|HSC34682|HSC34837|HSC35096|HSC35208|HSC35252|HSC4193|HSC4194|HSC4195|HSC4196|HSC42299|HSC44400|HSC45617|HSC46986|HSC47570|HSC62966|HSC65903|HSC66144|HSC67250|HSC67330|HSC67332|HSC67384|HSC67544|HSC68117|HSC68813|HSC71205|HSC71665|HSC71702|HSC71746|HSC73460|HSC73819|HSC81879|HSC84049|HSC85432|HSC85907|HSC91342|HSC95383|HSC97675)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Silene nelsonii/Silene/;
	&log_change("Scientific name not published: Silene nelsonii, modified to just genus:\t$name\t--\t$id\n");
}
if (($id =~ m/^HSC100654$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Tellima bolanderi/Lithophragma bolanderi/;
	&log_change("Scientific name not published: Tellima bolanderi, not a published combination, modified to basionym:\t$name\t--\t$id\n");
}
if (($id =~ m/^HSC100465$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Echinocystis mara/Marah/;
	&log_change("Scientific name not published: Tellima bolanderi, not a published combination, modified to basionym:\t$name\t--\t$id\n");
}
if (($id =~ m/^HSC100427$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Cnicus carlinoides/Cirsium/;
	&log_change("Scientific name not in CA: Cnicus carlinoides is a synonym of Cirsium clavatum, a species not found in CA, modified to genus:\t$name\t--\t$id\n");
}
if (($id =~ m/^(HSC43420|HSC43421)$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Ceanothus X smithii/Ceanothus/;
	&log_change("Scientific name not published: Ceanothus X smithii, not a published hybrid combination, modified to genus:\t$name\t--\t$id\n");
}
if (($id =~ m/^HSC100388$/) && (length($TID{$name}) == 0)){ 
	$name =~ s/Aspidium nevadense/Nephrodium nevadense/;
	&log_change("Scientific name illegitimate: Aspidium nevadense D.C. Eaton is an illegitimate name, modified to the legitimate basionym:\t$name\t--\t$id\n");
}

## finish validating names

#####process taxon names

$scientificName = &strip_name($name);

$scientificName = &validate_scientific_name($scientificName, $id);

#####process cultivated specimens			
# flag taxa that are known cultivars that should not be added to the Jepson Interchange, add "P" for purple flag to Cultivated field	
## regular Cultivated parsing
	if ($cultivated !~ m/^P$/){
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
	}
	else {
		&log_change("CULT: Taxon flagged as cultivated in original database==>($cultivated)\t($scientificName)\n");
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


foreach ($coll_year){
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}
foreach ($coll_day){
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}
foreach ($coll_month){
	s/mid //g;
	s/Apr.May/Apr-May/g;
	s/ and /-/g;
	s/&/-/g;
	s/\?//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}


$eventDateAlt = $coll_year."-".$coll_month."-".$coll_day;	


#assemble a date for a correctly formatted verbatim date
	if ((length($coll_day) == 0) && (length($coll_month) >= 1) && (length($coll_year) >= 2)){
		$verbatimEventDate = $coll_month." ".$coll_year;
	}
	elsif ((length($coll_day) >= 1) && (length($coll_month) >= 1) && (length($coll_year) == 0)){
		$verbatimEventDate = $coll_day." ".$coll_month." [year missing]";
		warn "(1) date missing year==>$verbatimEventDate\t$id";
	}	
	elsif ((length($coll_day) >= 1) && (length($coll_month) >= 1) && (length($coll_year) >= 2)){
		$verbatimEventDate = $coll_day." ".$coll_month." ".$coll_year;
	}	
	elsif ((length($coll_day) >= 1) && (length($coll_month) == 0) && (length($coll_year) >= 2)){
		$verbatimEventDate = $coll_day." [month missing] ".$coll_year;
		warn "(2) date missing month==>$verbatimEventDate\t$id";
	}
	elsif ((length($coll_day) == 0) && (length($coll_month) == 0) && (length($coll_year) >= 2)){
		$verbatimEventDate = $coll_year;
	}
	elsif ((length($coll_day) == 0) && (length($coll_month) == 0) && (length($coll_year) == 0)){
		$verbatimEventDate="";
	}
	else{
		&log_change("DATE: problem, missing or incompatible values==>day: $coll_day\tmonth: $coll_month\tyear: $coll_year\t$id\n");
		$verbatimEventDate="";
	}




foreach ($eventDateAlt){
	s/0000//g;
	s/-00-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-00$/-/g;
	s/-0-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-0$/-/g;
	s/-+/-/g;
	s/^-+/ /g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}

foreach ($verbatimEventDate){
	s/  +/ /g;
	s/'//g;
	s/"//g;
	s/ +$//g;
	s/^ +//g;
	
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
	elsif($eventDateAlt=~/^([0-9]{4})-(\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	warn "(1a)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{4})-([A-Za-z]+)-(\d\d?)/){	#if eventDate is in the format ####-AAA-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1b)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)-(June?|July?)[- ]$/){ #month, year, no day
		$YYYY = $1;
		$DD = "1";
		$MM = $1;
		$DD2 = "30";
		$MM2 = $2;
	warn "Date (7): $eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([A-Z][a-z]+)[- ](June?|July?)[- ]([0-9]{4})$/){ #month, year, no day
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
	elsif ($eventDateAlt=~/^([A-Za-z]+)[- ]([0-9]{4})$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	warn "(5)$eventDateAlt\t$id";
	}
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Za-z]+)-$/){
		$DD = "";
		$MM = $2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
	#warn "(5a)$eventDateAlt\t$id";
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


#$MM2= $DD2 = ""; #set late date to blank if only one date exists
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $MM2, $DD2, $id);
#warn "$formatEventDate\t--\t$EJD, $LJD\t--\t$id";
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);

###############COLLECTORS


#assemble a collectors for a correctly formatted verbatim collector field
	if ((length($collector) == 0) && (length($other_coll) > 1)){
		$verbatimCollectors = $other_coll;
		warn "(1) collector field NULL, using only other collector==>($collector, $other_coll)\t$id";
	}
	elsif ((length($collector) > 1) && (length($other_coll) >= 1)){
		$verbatimCollectors = $collector.", ".$other_coll;
		
	}	
	elsif ((length($collector) > 1) && (length($other_coll) == 0)){
		$verbatimCollectors = $collector;
	}	
	elsif ((length($collector) == 0) && (length($other_coll) == 0)){
		$verbatimCollectors="";
	}
	else{
		&log_change("COLLECTOR: missing or incompatible values==>collector: $collector\tother collector: $other_coll\t$id\n");
		$verbatimCollectors="";
	}


foreach ($collector){
	s/'$//g;
	s/"//g;
	s/\[//g;
	s/\]//g;
	s/\?//g;
	s/s\. n\. / /g;
	s/, with/ with/;
	s/ w\/ ?/ with /g;
	s/, M\. ?D\.//g;
	s/, Jr\./ Jr./g;
	s/, Jr/ Jr./g;
	s/, Esq./ Esq./g;
	s/, Sr\./ Sr./g;
	s/^'//g;
	s/ , /, /g;
	s/  +/ /g;
	s/^ +//;
	s/ +$//;
	
#fix some unique problem cases	
	s/. unknown/Unknown/;
	s/, *& */ & /g; #fix a special case
	s/^M ?& ?M$/M. & M./;

}
	
	if ($collector =~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collector, $id);	
		#$recordedBy = $collector;
	#D Atwood; K Thorne
		$other_coll=$2;
		#warn "Names 1: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
		&log_change("COLLECTOR (1): modified: $verbatimCollectors==>$collector--\t$recordedBy\t--\t$other_coll\t$id\n");	
	}
	
	elsif ($collector !~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collector, $id);
		#$recordedBy = $collector;
		#warn "Names 2: $verbatimCollectors===>$collector\t--\t$recordedBy\t--\t$other_coll\n";
	}
	elsif (length($collector == 0)) {
		$recordedBy = "Unknown";
		&log_change("COLLECTOR (2): modified from NULL to Unknown\t$id\n");
	}	
	else{
		&log_change("COLLECTOR (3): name format problem: $verbatimCollectors==>$collector\t--$id\n");
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

$other_collectors = ucfirst($other_coll);

#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes


foreach ($recordNumber){
	s/none//i;
	s/'//g;
	s/"//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
}

($CNUM_prefix,$CNUM,$CNUM_suffix)=&CCH::parse_CNUM($recordNumber);


###########COUNTRY

#No Country field, need to add USA for CA and MEX for Baja, then process problem state and county values

foreach($stateProvince){#for each value
	s/"//g;
	s/california/California/;
	s/CALIFORNIA/California/;
	s/^ +//;
	s/ +$//;
}

	if ($stateProvince=~m/BC/i){
		$country = "MEX";
		$stateProvince =~ s/^BC$/Baja California/;
	}
	elsif ($stateProvince=~m/CA/i){
		$country = "USA";
		$stateProvince =~ s/^CA$/California/;
	}
	else{
		&log_skip("LOCATION Country and State problem, skipped==>($stateProvince) ($tempCounty) ($locality)\t$id");
		++$skipped{one};
		next Record;
	}



foreach($tempCounty){#for each $county value
	s/'//g;
	s/"//g;
	s/NULL/Unknown/i;
	s/\[//g;
	s/\]//g;
	s/\?//g;
	s/none./Unknown/;
	s/County unk./Unknown/;
	s/needs research/Unknown/ig;
	s/^ *$/Unknown/;
	s/  +/ /;	
	s/^ +//;
	s/ +$//;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries
}

#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);

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

foreach ($locality){
	s/'$//;
	s/`$//;
	s/^-//;
	s/^;//;
	s/  +/ /g;	
	s/^ +//;
	s/ +$//;

#fix some unique problem cases	
	s/^[uU]kiah [dD]istrict/Ukiah District [somewhere within the BLM district bounday, see County and TRS for location, not from the city of Ukiah proper]/g;

}


###############ELEVATION########


foreach($elev_feet,$elev_meters){
	s/ - /-/g;
	s/"//g;	

	s/ [eE]lev.*//;	#remove trailing content that begins with [eE]lev
	s/feet/ft/;	#change feet to ft
	s/\d+ *m\.? \((\d+).*/$1 ft/;
	s/\(\d+\) \((\d+).*/$1 ft/;
	s/'/ft/;	#change ' to ft
	s/FT/ft/;	#change FT to ft
	s/Ft/ft/;	#change Ft to ft
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
	s/^0?\.\d+/1/; #convert decimals with or without leading zeros to 1 unit of elevation
	s/\>//g;
	s/\<//g;
	s/\@//g;
	s/[Mm]\.? *$/m/;	#substitute M/m/M./m., followed by anything, with "m"
	s/ft?\.? *$/ft/;	#subst. f/ft/f./ft., followed by anything, with ft
	s/ft/ ft/;		#add a space before ft
	s/m/ m/;		#add a space before m
	s/(\d+)\.\d+/$1/g; #elevation can be only intergers
	s/^0+$/0 m/;
	s/  +/ /g;		#collapse consecutive whitespace as many times as possible
	s/^ +//;
	s/ +$//;
	s/ //;
}


	if ((length($elev_feet) >= 1) && (length($elev_meters) >= 1)){	
		$elevation = $elev_meters."m";
		$verbatimElevation = "$elev_feet ft, $elev_meters m";
		#warn "Elevation 1: $elev_feet\t--\t$elev_meters\t$id\n";
	}
	elsif ((length($elev_feet) >= 1) && (length($elev_meters) == 0)){
		$elevation = $elev_feet."ft";
		$verbatimElevation = "$elev_feet ft";
		#warn "Elevation 2: $elev_feet\t--\t$elev_meters\t$id\n";
	}
	elsif ((length($elev_feet) == 0) && (length($elev_meters) >= 1)){
		$elevation = $elev_meters."m";
		$verbatimElevation = "$elev_meters m";
		#warn "Elevation 3: $elev_feet\t--\t$elev_meters\t$id\n";
	}
	elsif ((length($elev_feet) == 0) && (length($elev_meters) == 0)){
		$elevation = "";
		$verbatimElevation = "";
		#warn "Elevation 4: NULL elevation\t$id\n";
	}
	else {
			&log_change("ELEV problem==>$elev_feet\t--\t$elev_meters\t$id\n");
			$elev_feet =  $elev_meters = $verbatimElevation = $elevation ="";
	}

#process verbatim elevation fields into CCH format

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
my $verbatimCoordinates;


####TRS
$TRS= $Township.$Range.$Section." ".$fraction;

foreach ($verbatimLatitude, $verbatimLongitude){
		s/'/ /;
		s/"/ /;
		s/,/ /;
		s/[NW]//;
		s/^12318247/123.18247/;
		s/deg./ /;
		s/  +/ /g;
		s/^ *//;
		s/ *$//;
		
}


#The excel file from HSC in 2017 has also latitude and longitude split into separate field.
#these separate fields appear mostly ok, but have a few null fields spread throughout, mostly in the seconds field (and just an integer in the minutes).  
#It does not appear that any coordinates are only in these split fields
#just the decimal field is used here, labeled as $verbatimLatitude & $verbatimLongitude.


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
		$decimalLatitude=$latitude = "";
		$decimalLongitude=$longitude = "";
		&log_change("COORDINATE verbatim Lat/Long only to degree, now NULL: $verbatimLatitude\t--\t$verbatimLongitude\n");
	}



foreach ($latitude, $longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;

}	

#fix some problematic records that are not being georeferenced correctly
#most of these are BLM specimens from the Ukiah District BLM from Trinity, Lake, Napa, or Mendocino County, collected by Robert Specht
#many do not have locality information or just a fragment of habitat data erroneously entered as locality data
#others just have Ukiah District as the locality and all of these have erroneously been georeferenced as being from Ukiah proper, despite the county and TRS being clearly not from that city.
#none appear to have the TRS converted to georeferences by HSC in their home database





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
#skipping conversion of UTM and reporting if there are cases where lat/long is problematic only
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

#

#check datum and error radius

foreach($datum, $errorRadius){
		s/ +//; #collapse all white space
	}	

foreach($georeferenceSource){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
	}	
	
if(($decimalLatitude=~/\d/ && $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits


	if ($datum =~ m /^([nadwgs]+[-19]*[23478]+)$/i){ #report if true datum is present, toss out all erroneous data
		s/19//g;
		s/-//g;
		$datum = $1;
	}
	elsif(length($datum) == 0){
		#do nothing
	}
	else {
	&log_change("COORDINATE poorly formatted datum==>($datum) $id");
	$datum = "not recorded"; #
	}

 	if($errorRadius=~/^([0-9.]+) *([mkmetrsift]*)/i) { 
		$errorRadius=$1;
		$errorRadiusUnits=$2;
	}
	elsif(length($errorRadius) == 0){
		#do nothing
	}
	else {
	&log_change("COORDINATE poorly formatted Error Radius==>($errorRadius) $id");
	$errorRadius = "";
	}

	if (length($georeferenceSource) > 1){
		#do nothing
	}
	elsif(length($georeferenceSource) == 0){
		#do nothing
	}
	else {
		&log_change("COORDINATE poorly formatted georef source==>($georeferenceSource) $id");	
		$georeferenceSource = "not recorded";
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
		$decimalLatitude =$decimalLongitude=$datum="";	#and set $decLat and $decLong to ""  
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



#######Habitat and Assoc species (dwc habitat and associatedTaxa)

#free text fields

foreach ($habitat){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
	}	


foreach ($associatedSpecies){
		s/"/'/g;
		s/'$//g;
		s/^'//g;
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/with / /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
	
}


foreach ($plant_description,$occurrenceRemarks){
	s/'$//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

++$count_record;
warn "$count_record\n" unless $count_record % 10000;


	print OUT <<EOP;
Accession_id: $id
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
Location: $locality
Habitat: $habitat
Associated_species: $associatedSpecies
T/R/Section: $TRS
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: 
Lat_long_ref_source: 
Max_error_distance: 
Max_error_units: 
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Macromorphology: $plant_description
Notes: 
Cultivated: $cultivated
Hybrid_annotation: $hybrid_annotation
Annotation: $det_orig

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


    my $file_in = '/JEPS-master/CCH/Loaders/HSC/HSC_out.txt';	#the file this script will act upon is called 'CATA.out'

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

