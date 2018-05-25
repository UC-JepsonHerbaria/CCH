

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


####INSERT NAMES OF RIVERSIDE FILES and assign variables
#Note that most recent time Riverside data came with MS line breaks
#Open them in TextWrangler and Save As with Unix line breaks
my $images_file='/JEPS-master/CCH/Loaders/UCR/UCRImages20171115.tab';
my $dets_file='/JEPS-master/CCH/Loaders/UCR/UCRDetHist20171115.tab';
my $records_file='/JEPS-master/CCH/Loaders/UCR/UCRData20171115.tab';


my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;
#unique to this dataset
my $Img_ID;
my $IMG;
my %IMG;
my $ANNO;
my %ANNO;
my $det_string;
my $tempCounty;


open(OUT,">/JEPS-master/CCH/Loaders/UCR/UCR_out.txt") || die;
#open(MEX,">UCR_mexico.txt") || die;
#print MEX ("Accession_id\tscientificName\teventDate\tverbatimCollectors\tCollNUM_prefix\tCollNUM\tCollNUM_suffix\tCountry\tstateProvince\tCounty\tLocation\tHabitat \tAssociatedTaxa\tDecimal_latitude\tDecimal_longitude\tDatum\tgeoreferenceSource\terrorRadius\tcoordinateUncertaintyUnits\tElevation\tMacromorphology\tHybrid_annotation\tCultivated");

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";



#process the images
#Note that the file might have Windows line breaks

open (IN, "<", $images_file) or die $!;
while(<IN>){

my $Img_URL;
my $Accession_Number;

	chomp;
	s/  +/ /g;
	#UCR_7	UCR-17017	http://ucr.ucr.edu/specimens/Dicots/Onagraceae/Gayophytum/heterozygum/UCR0000006m.png
	#$Accession_Number refers to the AID within the context of working on the images file (cf. "$id)
	($Img_ID,
	$Accession_Number,
	$Img_URL) = split(/\t/);

	#can't deal with halves and thirds yet
	next if ($Img_URL =~/( top| middle| bottom)/i);
	$Accession_Number=~s/-//;
	$IMG{$Accession_Number} = "$Img_URL";
}
close(IN);

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

	chomp;
	
	#fix some data quality and formatting problems that make import of fields of certain records problematic
#see also the &correct_format 'foreach' statement below	for more formatting corrections	
			s/n·n/nan/g;
    		s/tÌn/tin/g;
    		s/loÎ/loe/g;
    		s/eÒa/ena/g;
    		s/È/e/g;
    		s/ë/'/g;
    		s/í/'/g;
 			s/  +/ /g;
	
	($det_AID,
	$det_rank,
	$det_family,
	$det_name,
	$det_determiner,
	$det_year,
	$det_month,
	$det_day,
	$det_stet) = split(/\t/);
	
#format det_date correctly	
	if ($det_year && $det_month && $det_day) {
		$det_date = "$det_month $det_day, $det_year";
	}
	elsif ($det_year && $det_month) {
		$det_date = "$det_month $det_year";
	}
	elsif ($det_year) {
		$det_date = "$det_year";
	}
	else {
		$det_date = "";
	}

#format det_string correctly
	if ((length($det_name) >=1) && (length($det_determiner) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner $det_stet";
	}	
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) == 0) && (length($det_date) >=1)){
		$det_string="$det_rank: $det_name, $det_determiner,  $det_date";
	}
	elsif ((length($det_name) >=1) && (length($det_determiner) >=1) && (length($det_stet) >=1) && (length($det_date) >=1)){
		$det_string="$det_rank: $det_name, $det_determiner $det_stet,  $det_date";
	}
	else{
		print "det problem: $det_rank: $det_name   $det_stet, $det_determiner, $det_date==>".$det_AID."\n";
		$det_string="";
	}

	$ANNO{$det_AID}.="Annotation: $det_string\n";
}

close(IN);	


########################################process main data file. 

open (IN, "<", $records_file) or die $!;
Record: while(<IN>){
	chomp;

#fix some data quality and formatting problems that make import of fields of certain records problematic

   		s/"Oak Park"/'Oak Park'/g;
   		s/"Lower Slough"/'Lower Slough'/g;	
   		s/"Noble Pass"/'Noble Pass'/g;
   		s/"Big"/'Big'/g;
   		s/"Halfway House"/'Halfway House'/g;
   		s/Place" a/Place' a/g;
   		s/ick" pop/ick' pop/g;
   		s/1" pop/1' pop/g;
   		s/"dry"/'dry'/g;
   		s/gear"/gear'/g;
   		s/cap"/cap'/g;
   		s/"rat beach"/'rat beach'/g;
   		s/Old"/Old'/g;
   		s/," and/,' and/g;
   		s/," n/,' n/g;
   		s/ne" at/ne' at/g;
   		s/"hot" p/'hot' p/g;
   		s/ot" p/ot' p/g; 		
   		s/flower"/flower'/g;
   		s/"Potrero Mesa,"/'Potrero Mesa,'/g;
   		s/"Airport Mesa,"/'Airport Mesa,'/g;
   		s/Cyn\."/Cyn.'/g;
    	s/"Potrero Mesa"/'Potrero Mesa'/g;
   		s/"Airport Mesa"/'Airport Mesa' /g; 		
      	s/Mesa"/Mesa'/g;	
      	s/"Don Pedro's"/Don Pedro's/g;
   		s/"Long Canyon,"/'Long Canyon,'/g;
   		s/" deb/' deb/g;
   		s/" Deb/' Deb/g;
      	s/"tail"/'tail'/g;
      	s/"Thornmint Hill"/'Thornmint Hill'/g;
      	s/"hiking corridor"/'hiking corridor'/g;
      	s/"elbow"/'elbow'/g;
      	s/"bioblitz"/'bioblitz'/g;
      	s/"Horse Meadows"/'Horse Meadows'/g;
      	s/"Coronado"/'Coronado'/g;
      	s/"no name"/'no name'/g;
      	s/"1-Mile Tree"/'1-Mile Tree'/g;
      	s/"Z"/'Z'/g;
      	s/"the Rapids"/'the Rapids'/g;
      	s/"Aspen Grove"/'Aspen Grove'/g;
      	s/"Plantation on the Lake"/'Plantation on the Lake'/g;
      	s/"Rope Trail"/'Rope Trail'/g;
      	s/"meadow"/'meadow'/g;
			s///g; #x{0B} hidden character
   		s/≈rg/Arg/g;	#UCR123325
   		s/Isla ¡ngel/Isla Angel/g; #UCR236101 and others
   		s/∫/ deg. /g;	#UCR147538 and others
   		s/∞/ deg. /g;	#UCR32365 and others
   		s/‹nc/unc/g;	#UCR17304
   		s/ë/'/g;		#UCR239648 and others
   		s/†/ /g;		#UCR62861 and others
   		s/œlow/Flow/g;	#UCR138251 and others
   		s/ñ/-/g;		#UCR265063 and others
   		s/í/'/g;		#UCR265044 and others
   		s/Õtr/Str/g;	#UCR203893
   		s/Z˙/Zu/g;		#UCR238497 and others
   		s/Ò/n/g;		#UCR201319, UCR74669 and others
   		s/5¥/5' /g;		#UCR180019 and others
   		s/«([ao])/C$1/g; #UCR212888 and others
   		s/·/a/g; #UCR231990 and others
   		s/¸/u/g; #UCR109618 and others
   		s/·/a/g; #UCR231990 and others
   		s/º/1\/4/g; #UCR221440 and others
   		s/bÂc/bac/g; #UCR198335 and others
   		s/È/e/g; #UCR198335 and others
   		s/à/ /g;	#UCR226377 and others
   		s/Ì/i/g; #UCR225749 and others
   		s/Û/o/g; #UCR225750 and others
   		s/ì/'/g;		#UCR228463 and others		
   		s/î/'/g;		#UCR228463 and others
   		s/ò/ /g;	#UCR121172
   		s/ó/-/g;	#UCR224018 		
   	s/±/+-/g;
   		s/÷//g;	#UCR3228
   		s/ˆ//g;	#UCR3228
   		s/fŒense/dense/g;	#UCR20436
   		s/Œist/Dist/g; #UCR57940 and others
		s/  +/ /g;
		
		
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
my $Coll_no_prefix;	
my $Coll_no;
my $Coll_no_suffix;
my $genus_doubted;
my $sp_doubted;
my $family_code;
my $physiographic_region;
my $lat_uncertainty;
my $long_uncertainty;
my $Snd_township;
my $Snd_Range;
my $Snd_section;
my $Snd_Fraction_of_section;
my $subsp_doubted;
my $hybrid_category;
my $Snd_genus;
my $Snd_genusDoubted;
my $Snd_species;
my $Snd_species_doubted;
my $Snd_subtype;
my $Snd_subtaxon;
my $Snd_subtaxon_doubted;
my $determiner;
my $det_year;
my $det_mo;
my $det_day;
my $CollectorSiteUniquifier;
my $UTM_grid_cell;
my $name_of_UTM_cell;
my $E_or_W;
my $N_or_S;
my $origin;
my $Coll_no_prefix;
my $Coll_no;
my $Coll_no_suffix;	
my $hybrid_annotation;
my $det_orig;
my $decimal_long;
my $decimal_lat;

	
	my @fields=split(/\t/,$_,100);
	
	unless($#fields == 71){	#if the number of values in the columns array is exactly 72

	&log_skip ("$#fields bad field number $_\n");
	++$skipped{one};
	next Record;
	}

	
#then process the full records	
(
$id,
$collector,
$Coll_no_prefix,
$Coll_no,
$Coll_no_suffix,
$coll_year,
$coll_month,
$coll_day,
$other_coll,
$family, #10
$family_code,
$genus,
$genus_doubted,
$species,
$sp_doubted,
$rank,
$subtaxon,
$subsp_doubted,
$hybrid_category,
$Snd_genus, #20
$Snd_genusDoubted,
$Snd_species,
$Snd_species_doubted,
$Snd_subtype,
$Snd_subtaxon,
$Snd_subtaxon_doubted,
$determiner,
$det_year,
$det_mo,
$det_day, #30
$CollectorSiteUniquifier, # unique locality ID added by Ed Plummer 2015-09. Not using for anything yet
$country,
$stateProvince,
$tempCounty, #$county_mpio in original data
$physiographic_region,
$topo_quad,
$location,
$lat_degrees,
$lat_minutes,
$lat_seconds, #40
$N_or_S,
$decimal_lat, 
$lat_uncertainty,
$long_degrees,
$long_minutes,
$long_seconds,
$E_or_W,
$decimal_long, 
$long_uncertainty,
$Township, #50
$Range,
$Section,
$Fraction_of_section,
$Snd_township,
$Snd_Range,
$Snd_section,
$Snd_Fraction_of_section,
$zone,
$UTM_grid_cell,
$UTME, #60
$UTMN,
$name_of_UTM_cell,
$minimumElevationInMeters,
$maximumElevationInMeters,
$minimumElevationInFeet,
$maximumElevationInFeet,
$habitat, #ecol_notes in original data
$georeferenceSource,
$plant_description,
$phenology, #70
$cultivated, #original data is Culture field, coopted for the Cultivated processing, field nulled and 'P' added for cultivated specimens
$origin,
) = @fields;


################ACCESSION_ID#############
#check for nulls, remove '-' from ID
$id=~s/-//;
unless($id=~/^UCR\d/){
	&log_skip("No UCR accession number, skipped: $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space
#skip

#Add prefix 
#skip


#Remove duplicates
if($seen{$fields[0]}++){
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	next Record;
}

##########Begin validation of scientific names

##############SCIENTIFIC NAME
#Format name parts
$genus=ucfirst(lc($genus));
$species=lc($species);
$subtaxon=lc($subtaxon);
$rank=lc($rank);

#construct full verbatim name


my $tempName = $genus ." " .  $species . " ".  $rank . " ".  $subtaxon;

#Annotations  (use to show verbatim scientific name (annotation 0) when a separate annotation file is present)
	#format det_string correctly
my $det_orig_rank = "current determination (uncorrected)";  #set to zero for original determination

	


#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($tempName){
	s/[uU]nknown/ /g; #added to try to remove the word "unknown" for some records
	s/;$//g;
	s/cf.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/[×] /X /;	#change  " x " in genus name to the multiplication sign
	s/  +/ /g;
	s/^ $//g;
	s/^ +//g;
	s/ +$//g;

	
	s/[uU]nknown/ /g;

	if (length($tempName) >=1){
		$det_orig="$det_orig_rank: $tempName";
	}
	else{
		$det_orig="";
	}

	}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published

if (($id =~ m/^(UCR280792|UCR110994|UCR100037|UCR110966|UCR111545|UCR120623|UCR126911|UCR127092|UCR139929|UCR144099|UCR148355|UCR155754|UCR155757|UCR157301|UCR157576|UCR157678|UCR162407|UCR162554|UCR163844|UCR177832|UCR18398|UCR193421|UCR193489|UCR196107|UCR202235|UCR208013|UCR225550|UCR23585|UCR239826|UCR25966|UCR261033|UCR275547|UCR276925|UCR277083|UCR47194|UCR47681|UCR47710|UCR50418|UCR79440|UCR83423|UCR86673|UCR86811)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Cryptantha lepida/Cryptantha/;
	&log_change("Scientific name not published: Cryptantha lepida modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCR58860)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lupinus elatus var\. viridulus/Lupinus elatus/;
	&log_change("Scientific name not published: Lupinus elatus var. viridulus modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCR140485|UCR6165)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium ultramaficum/Trifolium/;
	&log_change("Scientific name not published: Trifolium ultramaficum modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCR127447|UCR42813|UCR46231)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium janus/Trifolium/;
	&log_change("Scientific name not published: Trifolium janus modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCR84715)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium virescens ssp\. boreale/Trifolium virescens/;
	&log_change("Scientific name not published: Trifolium virescens ssp. boreale modified to\t$tempName\t--\t$id\n");
}
if (($id =~ m/^(UCR23914)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Trifolium virescens ssp\. virescens/Trifolium virescens/;
	&log_change("Scientific name not published: Trifolium virescens ssp. virescens nodified to\t$tempName\t--\t$id\n");
}
#if (($id =~ m/^(SD157644)$/) && (length($TID{$name}) == 0)){ 
#	$name =~ s/Lupinus formosus var\. proximus/Lupinus formosus/;
#	&log_change("Scientific name not published, modified to to just the species rank:\t$name\t--\t$id\n");
#}
if (($id =~ m/^(UCR88065|UCR88091)$/) && (length($TID{$tempName}) == 0)){ 
	$tempName =~ s/Lupinus formosus ssp\. proximus/Lupinus formosus/;
	&log_change("Scientific name not published: Lupinus formosus ssp. proximus modified to\t$tempName\t--\t$id\n");
}

#format hybrid names
if($tempName=~m/([A-Z][a-z-]+ [a-z-]+) X /){
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
$scientificName=&validate_scientific_name($scientificName, $id);


#####process cultivated specimens			
# flag taxa that are cultivars, add "P" for purple flag to Cultivated field	

## regular Cultivated parsing
	if ($cultivated !~ m/^P$/){
		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("CULT: specimen likely not cultivated, purple flagging skipped: $scientificName\t--\t$id\n");
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection|seed source. |plants grown in)/i) || ($habitat =~ m/(cult.? shrub|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|seed source.? |ornamental plant|ornamental shrub|ornamental tree|horticultural plant|grown in greenhouse|plants grown in|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
#add exceptions here to the CCH cultivated routine on a specimen by specimen basis
		elsif (($id =~ m/^(UCR263222|UCR262468|UCR262466)$/) && ($scientificName =~ m/Enchylaena tomentosa/)){
			&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
		$cultivated = "";
		}
		elsif (($id =~ m/^(UCR274879)$/) && ($scientificName =~ m/Dalbergia sissoo/)){
			&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location  (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
		$cultivated = "";
		}
		elsif (($id =~ m/^(UCR275232)$/) && ($scientificName =~ m/Juniperus virginiana/)){
			&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location  (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
		$cultivated = "";
		}
		elsif (($id =~ m/^(UCR194205)$/) && ($scientificName =~ m/Ozothamnus diosmifolius/)){
			&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location  (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
		$cultivated = "";
		}
		elsif (($id =~ m/^(UCR10734)$/) && ($scientificName =~ m/Portulaca pilosa/)){
			&log_change("CULT: specimen reported to be a waif or naturalized, not cultivated at this location  (confirmed by Andy Sanders): $scientificName\t--\t$id\t--\t$locality\n");
		$cultivated = "";
		}

#Check remaining specimens for status with CCH cultivated routine
		else {		
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("CULT: Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			#&log_change("Taxon skipped purple flagging: $cultivated\t--\t$scientificName\n");
			$cultivated = "";
			}
		}
	}
	else {
		
		&log_change("CULT: Taxon flagged as cultivated in original database: $cultivated\t--\t$scientificName\n");
		$cultivated = "P";
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
my $month;

#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#$coll_month, #three letter month name: Jan, Feb, Mar etc.
#$coll_day,
#$coll_year,
#verbatim date for dwc verbatimEventDate and CCH "Date"

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


$verbatimEventDate = $eventDateAlt = $coll_year ."-" . $coll_month . "-". $coll_day;	


foreach ($eventDateAlt){
	s/0000//g;
	s/-00-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-00$/-/g;
	s/-0-/--/g;	#julian date processor cannot handle 00 as filler for missing values
	s/-0$/-/g;
	s/-+$//g;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}

#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#$coll_month, #three letter month name: Jan, Feb, Mar etc.
#$coll_day,
#$coll_year,
#verbatim date for dwc verbatimEventDate and CCH "Date"


	if($eventDateAlt=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)[- ](\d\d)/){	#if eventDate is in the format ####-Abcdef-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1b)$eventDateAlt\t$id";
	}
	elsif($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)[- ](\d)/){	#if eventDate is in the format ####-Abcdef-#
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "(1c)$eventDateAlt\t$id";
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)-(June?)$/){ #month, year, no day
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
	elsif ($eventDateAlt=~/^([0-9]{4})[- ]([A-Z][a-z]+)[- ](Ma[rchy])$/){ #month, year, no day
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
	elsif ($eventDateAlt=~/^(([0-9]{4})[- ][A-Za-z]+)$/){
		$DD = "";
		$MM = $1;
		$YYYY=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "(5b)$eventDateAlt\t$id";
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

	foreach ($collector, $other_coll){
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
elsif ((length($collector) == 0) && (length($other_collectors) > 1)){
	$recordedBy = &CCH::validate_single_collector($other_collectors, $id);
	$verbatimCollectors = "$other_collectors";
	&log_change("COLLECTOR: Collector name field missing, using other collector field\t$id\n");
}
elsif ((length($collector) == 0) && (length($other_collectors) == 0)){
	&log_change("Collector name fields NULL\t$id\n");
	$verbatimCollectors = $other_collectors = $recordedBy = "";
}	
else {
		&log_change("Collector name problem\t$id\n");
		$recordedBy =  $other_collectors = $verbatimCollectors = "";
}

foreach ($verbatimCollectors){
	s/'$//g;
	s/  +/ /;
	s/^ *//;
	s/ *$//;
	
}


#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes


$recordNumber = "$Coll_no_prefix $Coll_no $Coll_no_suffix";
($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);


####COUNTRY
$country="USA" if $country=~/U\.?S\.?/;
$country="Mexico" if $country=~/M\.?X\.?/;


	if ($stateProvince=~m/^BCN/i){
		$stateProvince =~ s/.*/Baja California/;
	}
	elsif ($stateProvince=~m/^CA/i){
		$stateProvince =~ s/.*/California/;
	}
	else{
		&log_skip("LOCATION Country and State problem, skipped==>($country)\t($stateProvince)\t($tempCounty)\t ($locality)\t$id");
		++$skipped{one};
		next Record;
	}




#########################County/MPIO
#delete some problematic Mexico specimens

my %country;

	if((length($tempCounty) == 0) && ($country=~m/Mexico/)){
		&log_change("Mexico record with unknown or blank county field==>$id ($country)\t($stateProvince)\t($county)\t$location");
	}
	elsif(($tempCounty=~m/unknown/i) && ($country=~m/Mexico/)){
		&log_skip("Mexico record with unknown or blank county field==>$id ($country)\t($stateProvince)\t($county)\t$location");
			++$skipped{one};
			next Record;
	}

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
		&log_change("COUNTY unknown==>$id ($country)\t($stateProvince)\t($county)\t$location");		
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

foreach ($location && $physiographic_region){
	s/'$//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}
	if((length($location) > 1) && (length($physiographic_region) == 0)){
		$locality = "$location";
				
	}		
	elsif ((length($location) > 1) && (length($physiographic_region) >1)){
		$locality = "$physiographic_region, $location";
		$locality =~ s/'$//;
	}
	elsif ((length($location) == 0) && (length($physiographic_region) >1)){
		$locality = "$physiographic_region";
		$locality =~ s/: *$//;
	}
	elsif ((length($location) == 0) && (length($physiographic_region) == 0)){
		$locality = "";
		&log_change("Locality & physiographic_region NULL, $id\n");
	}
	else {
		&log_change("Locality problem, bad format, $id\t--\t$location\t--\t$physiographic_region\n");		#call the &log function to print this log message into the change log...
	}

####ELEVATION


#########################ELEVATION
#$elevationInMeters is the darwin core compliant value
#verify if elevation fields are just numbers

#process verbatim elevation fields into CCH format
if ((length($minimumElevationInMeters) >= 1) && (length($maximumElevationInMeters) >= 1)){
#there are decimal values in elevation field, convert to integer
	if ($maximumElevationInMeters =~ m/^\.([0-9]+)$/){
		$maximumElevationInMeters = "0.$1";
	}
	if ($maximumElevationInMeters =~ m/^-?[0-9.]+$/){
		$elevationInMeters = int($maximumElevationInMeters); #there are decimal elevations in these data
		$elevationInFeet = int($elevationInMeters * 3.2808);
		$CCH_elevationInMeters = "$maximumElevationInMeters m";
		$verbatimElevation = "$minimumElevationInMeters - $maximumElevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$maximumElevationInMeters' not numeric\t$id");
		$elevationInMeters="";
	}	
}

elsif ((length($minimumElevationInMeters) == 0) && (length($maximumElevationInMeters) >= 1)){

	if ($maximumElevationInMeters =~ m/^-?[0-9.]+$/){
		$elevationInMeters = int($maximumElevationInMeters); #there are decimal elevations in these data
		$elevationInFeet = int($elevationInMeters * 3.2808);
		$CCH_elevationInMeters = "$maximumElevationInMeters m";
		$verbatimElevation = "$maximumElevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$maximumElevationInMeters' not numeric\t$id");
		$elevationInMeters="";
	}	
}

elsif ((length($minimumElevationInMeters) >= 1) && (length($maximumElevationInMeters) == 0)){

	if ($minimumElevationInMeters =~ m/^-?[0-9.]+$/){
		$elevationInMeters = int($minimumElevationInMeters);
		$elevationInFeet = int($elevationInMeters * 3.2808);
		$CCH_elevationInMeters = "$minimumElevationInMeters m";
		$verbatimElevation = "$minimumElevationInMeters m";
	}
	else {
		&log_change("Check elevation in meters: '$minimumElevationInMeters' not numeric\t$id");
		$elevationInMeters="";
	}	
}
elsif ((length($minimumElevationInFeet) >= 1) && (length($maximumElevationInFeet) >= 1)){

	if ($maximumElevationInFeet =~ m/^-?[0-9.]+$/){
		$elevationInFeet = int($maximumElevationInFeet);
		$elevationInMeters = int($maximumElevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$minimumElevationInFeet - $maximumElevationInFeet ft";
	}
	else {
		&log_change("Check elevation in feet: '$maximumElevationInFeet' not numeric\t$id");
		$elevationInFeet="";
	}		
}
elsif ((length($minimumElevationInFeet) == 0) && (length($maximumElevationInFeet) >= 1)){

	if ($maximumElevationInFeet =~ m/^-?[0-9.]+$/){
		$elevationInFeet = int($maximumElevationInFeet);
		$elevationInMeters = int($maximumElevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$maximumElevationInFeet ft";
	}
	else {
		&log_change("Check elevation in feet: '$maximumElevationInFeet' not numeric\t$id");
		$elevationInFeet="";
	}		
}
elsif ((length($minimumElevationInFeet) >= 1) && (length($maximumElevationInFeet) == 0)){

	if ($minimumElevationInFeet =~ m/^-?[0-9.]+$/){
		$elevationInFeet = int($minimumElevationInFeet);
		$elevationInMeters = int($minimumElevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
		$verbatimElevation = "$minimumElevationInFeet ft";
	}
	else {
		&log_change("Check elevation in feet: '$minimumElevationInFeet' not numeric\t$id");
		$elevationInFeet="";
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

#right now the Latitude and Longitude fields are always in DMS or DDM. Will probably include decimal degrees in the future
#Datum and uncertainty are not recorded.
#Datum is assumed to be NAD83/WGS84 for the purposes of utm_to_latlon conversion (i.e. $ellipsoid=23)
#but otherwise datum is not reported
#remove symbols and put it in a standard format, spaces delimiting
my $ellipsoid;
my $northing;
my $easting;
my $hold;
my $lat_decimal;
my $long_decimal;
my $zone_number;


####TRS
$TRS="$Township$Range$Section $Fraction_of_section";


#######Latitude and Longitude
	foreach ($decimal_lat, $decimal_long, $lat_degrees,$lat_minutes,$lat_seconds,$long_degrees,$long_minutes,$long_seconds){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^ $//;
	}
if ((length($lat_degrees) >= 1) || (length($long_degrees) >= 1)){
$verbatimLatitude = "$lat_degrees $lat_minutes $lat_seconds";
#print "$verbatimLatitude\n";
$verbatimLongitude = "$long_degrees $long_minutes $long_seconds";
#print "$verbatimLongitude\n";
}
else{
$verbatimLatitude = $verbatimLongitude = "";
}





foreach ($decimal_lat, $verbatimLatitude){
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
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/^11742/117 42/;
		s/^117 42 42 37/117 42 37/;
		s/,/ /g;
		s/deg\.?/ /;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
		
}

if ((length($decimal_lat) == 0) || (length($decimal_long) == 0)){
#check to see if lat and lon reversed, THIS IS UNIQUE TO RSA due to the 3 sets of coordinates that are not consistent

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
		#print "COORDINATE NULL $id\n";
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
		#print "COORDINATE NULL $id\n";
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


foreach ($latitude, $longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s$//;
}	

#use combined Lat/Long field format for UCR

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
elsif ((length($latitude) == 0) || (length($longitude) == 0)){
#utm are mostly in military coordinates which are not numeric.  skipping conversion of UTM and reporting if there are cases where UTM is present and lat/long is not

foreach ($UTME,$UTMN){
		s/[nsew]//i; #eliminate directions
		s/m//i; #eliminate meters
		s/z10//i; #eliminate zones put into coordinates
		s/z11//i; #eliminate zones put into coordinates
		s/-//g; #should be no negative UTMs in these data
		s/,//g;
		s/ //g;
		s/^0//;
}
foreach ($zone){
		s/027//; #bad zone number tripping up conversion module
		s/ //g;
}	

#process zone fields
		if ((length($UTME) > 1 ) && (length($UTMN) > 1 )){
			&log_change("10) Lat & Long null but UTM is present, checking for valid coordinates: $UTME, $UTMN, $zone, $id\n");
		
			#$zone = $UTM_grid_cell; #zone is this field in this dataset
			if((length($zone) == 0) && ($location =~ m/(San Miguel Island|Santa Rosa Island)/i)){
				$zone = "10S"; #Zone for these data are this, using UTMWORLD.gif in DATA directory
			}
			elsif ((length($zone) == 0) && ($location !~ m/(San Miguel Island|Santa Rosa Island)/i)){
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
						&log_change("COORDINATE 11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone\t(CELL:$UTM_grid_cell NAME:$name_of_UTM_cell)\t$id\n");
						
					$zone = "";
				}
			}
			else{
				if ($zone =~ m/^(\d\d[A-Z])/){
					$zone = $1;
				}	
				elsif ($zone =~ m/^11[a-z]?$/){
					$zone = "11S";
				}				
				elsif ($zone =~ m/^10[a-z]?$/){
					$zone = "10S";	
				}	
				else{					
					&log_change("COORDINATE 11c) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone\t(CELL:$UTM_grid_cell NAME:$name_of_UTM_cell)\t$id\n");
						
					$zone = "";
				}
			}
		}
		if ((length($UTME) >= 5) && (length($UTMN) >= 5)){
#leading zeros need to be removed before this step
#Northing is always one digit more than easting. sometimes they are apparently switched around.
			if (($UTME =~ m/^(\d{7}$)/) && ($UTMN =~ /^(\d{6})$/)){
					$easting = $UTMN;
					$northing = $UTME;
					&log_change("UTM coordinates apparently reversed; switching northing with easting: $id");
			}
			else{
					$easting = $UTME;
					$northing = $UTMN;
			}
			if (($UTME > 0) && ($UTMN > 0)) {
				($decimalLatitude,$decimalLongitude)=utm_to_latlon(23,$zone,$easting,$northing);
				&log_change("Decimal degrees derived from UTM for $id: $decimalLatitude, $decimalLongitude");
				$georeferenceSource = "UTM to Lat/Long conversion by CCH loading script";
				$datum = "WGS84";
			}
		}
		elsif ((length($UTME) == 0) && (length($UTMN) == 0)){
				$decimalLatitude = $decimalLongitude = "";
		}
		else{
				&log_change("11b) Poorly formatted UTM coordinates, Lat & Long nulled: $UTME, $UTMN, $zone, $id\n");
				$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
		}
}
elsif($latitude==0 && $longitude==0 && $UTME==0 && $UTMN==0){
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
foreach ($datum){
		s/'$//;
		s/  +/ /g;
		s/^ *//g;
		s/ *$//g;
}

if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	if ($datum=~m/(WGS84|NAD83|NAD27)/){ #report is datum is present
		s/  +/ /g;
		s/^ *//g;
		s/ *$//g;

	}
	else {
		$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
	}
}
# check UNCERTAINTY AND UNITS
	if((length($lat_uncertainty) >= 1) && (length($long_uncertainty) >= 1)){ 
		$errorRadius = "Lat: $lat_uncertainty; Long: $long_uncertainty";
		$errorRadius =~ s/ *$//;
		$errorRadius =~ s/  +/ /;
		$coordinateUncertaintyUnits = "m";
	}		
	elsif ((length($lat_uncertainty) >= 1) && (length($long_uncertainty) == 0)){ 
		$errorRadius = "$lat_uncertainty";
		$errorRadius =~ s/ *$//;
		$errorRadius =~ s/  +/ /;
		$coordinateUncertaintyUnits = "m";
	}
	elsif ((length($lat_uncertainty) == 0) && (length($long_uncertainty) >= 1)){
		$errorRadius = "$long_uncertainty";
		$errorRadius =~ s/ *$//;
		$errorRadius =~ s/  +/ /;
		$coordinateUncertaintyUnits = "m";
	}
	else {
		$errorRadius = "not recorded";
		$coordinateUncertaintyUnits = "";
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

foreach ($plant_description){
		s/'$//;
		s/  +/ /g;
}

foreach ($abundance){
		s/'$//;
		s/  +/ /g;
}

foreach ($phenology){
		s/'$//;
		s/  +/ /g;
}


#######Habitat and Assoc species (dwc habitat and associatedTaxa)

#free text fields

foreach ($habitat){
		s/'$//;
		s/  +/ /g;
}

###ASSOCIATED SPECIES FROM ECOLOGY NOTES
my $habitat_rev;

if($habitat=~s/^(.*[;.]) +([Aa]ssoc.*)//){
	$associatedTaxa=$2;
	$habitat_rev=$1
}
else {$associatedTaxa="";
}

foreach ($associatedTaxa){
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/'$//;
	s/  +/ /g;
	s/^ +//g;
	s/ +$//g;
}
foreach ($habitat_rev){
		s/'$//;
		s/  +/ /g;
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
Habitat: $habitat_rev
Associated_species: $associatedTaxa
T/R/Section: $TRS
USGS_Quadrangle: $topo_quad
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance: $errorRadius
Max_error_units: $coordinateUncertaintyUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Macromorphology: $plant_description
Phenology: $phenology
Hybrid_annotation: $hybrid_annotation
Cultivated: $cultivated
Annotation: $det_orig
Image: $IMG{$id}
EOP

#usually, the blank line is included at the end of the block above
#but since the $ANNO{$id} is printed outside the block, the \n is after
print OUT $ANNO{$id};
print OUT "\n";

#print TABFILE $IMG{$id};
#print TABFILE "\n";

#add one to the count of included records
++$included;
#if ($country =~/mexico/i){
#print MEX join("\t",$id,$scientificName,$verbatimEventDate,$verbatimCollectors,$CNUM_prefix,$CNUM,$CNUM_suffix,$country,$stateProvince,$county,$locality,$habitat_rev,$associatedTaxa,$decimalLatitude,$decimalLongitude,$datum,$georeferenceSource,$errorRadius,$coordinateUncertaintyUnits,$verbatimElevation,$plant_description,$hybrid_annotation,$cultivated),"\n";
#}

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


    my $file_in = '/JEPS-master/CCH/Loaders/UCR/UCR_out.txt';	#the file this script will act upon is called 'CATA.out'
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

