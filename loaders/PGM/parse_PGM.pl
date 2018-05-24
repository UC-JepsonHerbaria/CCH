#useful one liners for debugging:
#perl -lne '$a++ if /Accession_id: RSA\d+DUP/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id: POM\d+DUP/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id: RSA\d+/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id: POM\d+/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id:/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Decimal_latitude: \d+/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Decimal_longitude: -\d+/; END {print $a+0}' RSA_specify_out.txt
#perl -lne '$a++ if /Accession_id: (POM|RSA)\d/; END {print $a+0}' RSA_fmp_out.txt
#perl -lne '$a++ if /Combined_coll: $/; END {print $a+0}' RSA_specify_out.txt

#perl -lne '$a++ if /Accession_id:/; END {print $a+0}' PGM_out.txt

use strict;
#use warnings;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
use Text::CSV;

my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.


$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;

my $id_orig;
my $idAlt;
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
my $orig_id;
my $barcode;
my %GUID_barcode;
my %duplicate;

open(OUT, ">PGM_out.txt") || die;


#############
#Any notes about the input file go here
#file sent in access database format

#converted in chrome to csv, imported to text wrangler and saved as UTF-8
#text below converts to a tab delimited file, but leaves in quotes, these need to be deleted in the script below.

#no Baja records in a separate file.
#
#run this one liner to add the N to the first column as the cultivated field place holder
#perl -pe 's/^/"N",/' PGM_NOV2017.csv > PGM_NOV2017.tmp
############

#convert from comma delimited to tab
#my $csv = Text::CSV->new ({ binary => 1 });
#my $tsv = Text::CSV->new ({ binary => 1, sep_char => "\t", eol => "\n" });

#open my $infh,  "<:encoding(utf8)", "PGM_NOV2017.tmp" || die;
#open my $outfh, ">:encoding(utf8)", "PGM_NOV2017.txt"|| die;

#while (my $row = $csv->getline ($infh)) {
#    $tsv->print ($outfh, $row);
#    }


#process converted text file
my $file="PGM_NOV2017.txt";

warn "reading from $file\n";

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


open (IN, $file) or die $!;
Record: while(<IN>){
	chomp;

	$line_store=$_;
	++$count;		

#fix some data quality and formatting problems that make import of fields of certain records problematic


        if ($. == 1){#activate if need to skip header lines
			next Record;
		}

#Skip some odd lines that are interfereing with parsing
	if(m/No specimen recorded/i){
		&log_skip ("ACCESSSION: No specimen recorded\n");
		++$skipped{one};
		next Record;
	}
	
	if(m/Number not used/i){
		&log_skip ("ACCESSSION: Number not used\n");
		++$skipped{one};
		next Record;
	}
	if(m/\nN\t\t\t\t\t+/){
		&log_skip ("ACCESSSION: NULL record $_\n");
		++$skipped{one};
		next Record;
	}

	if(m/END OF BEATRICE HOWITT COLLECTION/i){
		&log_skip ("ACCESSSION: NULL record $_\n");
		++$skipped{one};
		next Record;
	}


			s/\cK/ /g; #delete some hidden windows line breaks that do not remove themselves with saving the file as utf-8



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
my $Locality1;
my $region;
my $det_orig;

		my @fields=split(/\t/,$_,100);

        unless( $#fields == 10){  #if the number of values in the columns array is exactly 11

	&log_skip ("$#fields bad field number $_\n");
	++$skipped{one};
	next Record;
	}
#cult	Scientific Name,Family,CO,R,GENERAL SITE,SPECIFIC SITE,SOIL,DATE,COLLECTOR,HERB #

($cultivated, #sequential number
$tempName, #
$family,
$tempCounty, #this is an abbreviation field for the county
$region,
$Locality1, #i.e. "general site"
$location, #i.e. "specific site"
$habitat,
$verbatimEventDate, 
$verbatimCollectors, #10
$id
) = @fields;




########ACCESSION NUMBER

#Remove duplicates in cchId, this needs to be unique, and duplicates are errors


#remove leading zeroes, remove any white space
foreach($id){
	s/"//g;
	s/ +//g;
	s/H-?0+/PGM/g;
	s/H-/PGM/g;
	s/-+//g;
}

#find duplicates
if($seen{$id}++){
	warn "Duplicate ID: $id\n";
	&log_skip("ACCESSSION: Duplicate ID, skipped: $id\n");
	++$skipped{one};
	next Record;
}


##################Exclude known problematic specimens by id numbers, most from outside California and Baja California
#	if(($id=~/^(CAS-BOT-BC305449)$/) && ($tempCounty=~m/San/)){ #skip, out of state
#		&log_skip("County/State problem==>San Bernardino Ranch, Arizona, is in Cochise County, not in California ($barcode: $tempCounty, $locality)\n");	
#		++$skipped{one};
#		next Record;
#	}


##########Begin validation of scientific names

##############SCIENTIFIC NAME


#Annotations  (use to show verbatim scientific name (annotation 0) when a separate annotation file is present)
	#format det_string correctly
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
my $det_name_position;
my $det_string="";
my $det_orig_rank = "current determination (uncorrected)";  #set to zero for original determination

	if (length($tempName) >=1){
		$det_orig = "$det_orig_rank: $tempName";
		$det_orig = s/"//g;
	}
	else{
		$det_orig = "";
	}


#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach($tempName){
	s/"//g;
	s/([a-z-]+[^()]+) *\([A-Za-z. -]+\)?/$1/;
	s/\)$//;
	s/Grindelia h\. ?\(.*/Grindelia hirsutula/;
	s/Grindelia h\..*/Grindelia hirsutula/;
	s/Grindelia hirsutula *\(.*/Grindelia hirsutula/;
	s/Solidago velutina ssp\. californica S\. californica/Solidago velutina subsp. californica/;
	s/Atriplexcanescens/Atriplex canescens/;
	s/\*.*//; #delete the asterisks that are stopping parsing
	s/einandra corymbosa ssp\. c\.\(macrocephala\)?/einandra corymbosa subsp. macrocephala/;
	s/einandra corymbosa ssp\. c\./einandra corymbosa subsp. corymbosa/;
	s/osackia oblongifolia var\.? o\.?/osackia oblongifolia var. oblongifolia/;
	s/cespitosa subsp\.? c\./cespitosa subsp. cespitosa/;
	s/osackia crassifolia var\.? c\.?/osackia crassifolia var. crassifolia/;
	s/eschampsia cespitosa holciformis/eschampsia cespitosa subsp. holciformis/;
	s/^sw$/Chenopodiaceae/;
	s/estuca ponticusThinopyrum ponticum/estuca ponticus/;
	s/eanothus thyrs\. var\. ?griseus X rigidus/eanothus thyrsiflorus var. griseus/;
	s/\.$//;
#s/ssp\.?/subsp./;
#s/ var / var. /;
#s/ var\.$//;
#s/var\./var. /;
#s/subsp\./subsp. /;
#s/ *TOPOT.*//;
#s/ *Comb\..*//;
#s/subsp\. .\. f\./f./;
#s/subsp\. [a-z]+ f\./f./;
#s/ [a-z]\. f\./f./;
#s/subsp\. ___.*//;
#s/ toward .*//;
#s/ >.*//;
s/ spp\.?$//;
#s/,.*//;
#s/\.$//;
#s/\+-.*//;
#s/([a-z])f\. ([a-z])/$1 f. $2/;
	s/[uU]nknown/ /g; #added to try to remove the word "unknown" for some records
	s/;$//g;
	s/cf.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/[×] /X /;	#change  " x " in genus name to the multiplication sign
	s/  +/ /g;
	s/^ $//g;
	s/^ +//g;
	s/ +$//g;
}


#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published

#if (($id =~ m/^(RSA749784|RSA750186|RSA751051|RSA752009|RSA761037|RSA764200|RSA764252|RSA782687|RSA800225)$/) && (length($TID{$tempName}) == 0)){ 
#	$tempName =~ s/Cryptantha lepida/Cryptantha/;
#	&log_change("Scientific name not published: Cryptantha lepida modified to\t$tempName\t--\t$id\n");
#}

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


		if ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("CULT: specimen likely not cultivated, purple flagging skipped: $scientificName\t--\t$id\n");
		}
		elsif (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection)/i) || ($habitat =~ m/(cultivated from|planted from seed|planted from a seed)/i)){
		    $cultivated = "P";
	   		&log_change("CULT: Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
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
				&log_change("CULT: Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
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
my $month;

	foreach ($verbatimEventDate){
		s/"//g;
		s/  +/ /g;
		s/ +$//g;
		s/^ +//g;
	}

$eventDate = $verbatimEventDate;

	foreach ($eventDate){
		s/"//g;
		s/ 0+:0+:.*//;
		s/ ?- ?/-/g;
		s/  +/ /g;
		s/ +$//g;
		s/^ +//g;
		s/NULL//g;
	}	

	if($eventDate=~/^([0-9]{4})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; 
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM2 = "";
		$DD2 = "";
	#warn "Date (1)$eventDate\t$id";
	}
	elsif($eventDate=~/^(\d\d)-(\d\d)-([0-9]{4})/){	#added to SDSU, if eventDate is in the format ##-##-####, most appear that first ## is month
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	warn "Date (2)$eventDate\t$id";
	}
	elsif($eventDate=~/^([0-9]{1})-([0-9]{1,2})-([0-9]{4})/){	#added to SDSU, if eventDate is in the format #-##?-####, most appear that first # is month 
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	warn "Date (3)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([Ss][pP][rR][ing]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (14)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([Ss][uU][Mm][mer]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "6";
		$DD = "1";
		$MM2 = "8";
		$DD2 = "31";
	warn "Date (16)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([fF][Aa][lL]+)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$DD = "1";
		$MM = "9";
		$DD2 = "30";
		$MM2 = "11";
	warn "Date (12)$eventDate\t$id";
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
	warn "Date (11)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (13)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([Ss][pP][rR][ing]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (15)$eventDate\t$id";
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
	warn "Date (20)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]([Ss][uU][Mm][mer]*)/) {
		$YYYY = $1;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	warn "Date (17)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})[- ]*$/){
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
		$MM="";
	#warn "Date (18)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{4})-([0-9]{1,2})[- ]*$/){
		$MM=$2;
		$YYYY=$1;
		$MM2 = "";
		$DD2 = "";
		$DD = "";
	#warn "Date (19)$eventDate\t$id";
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
	s/"//g;
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

	foreach($collector){
		s/(.*), ?(.*)/$2 $1/;
	}


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
	s/"//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;

}
$other_collectors = ucfirst($other_coll);


#############CNUM##################COLLECTOR NUMBER####
#the only collection numbers in this database are in the habitat field

my $collnum = $habitat;


		if ($collnum=~s/^#-?([H\d+].*)$//){
			$recordNumber=$1;
		}
		elsif ($collnum=~s/^#?-?([^0-9]+)//){
			$recordNumber=$1;
		}
		else{
			$recordNumber="";
		}

foreach ($recordNumber){
	s/#//;
	s/"//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;
}

my $CNUM_suffix="";
($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);


####COUNTRY

		$country="USA";

		$stateProvince ="California";


#########################County/MPIO
#delete some problematic Mexico specimens

######################COUNTY
foreach($tempCounty){
	s/00//;
	s/CCA/Contra Costa/;
	s/ExtemMNT/Monterey/;
	s/FRE/Fresno/;
	s/INY/Inyo/;
	s/KNG/Kings/;
	s/KRN/Kern/;
	s/MNT 7/Monterey/;
	s/MNT /Monterey/;
	s/MNT/Monterey/;
	s/Mnt/Monterey/;
	s/SBN/San Bernardino/;
	s/SBT/San Benito/;
	s/SCL/Santa Clara/;
	s/SCR/Santa Cruz/;
	s/SLO/San Luis Obispo/;
	s/SMT/San Mateo/;
	s/'//g;
	s/"//g;
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
	foreach($region){
		s/"//g;
		s/00//;
		s/0//;
	}

if ($region =~ m/^$/){
	&log_change("LOCAT: region NULL:\t$id");
	$region="";
}
elsif ($region =~ m/^(1|2|3|4|5|6|7|8)$/){
	#do nothing
}
else{
	warn "Unknown region value: $region\n";
	&log_change("LOCAT: region NULLED, unknown region value: $region\t$id");
	$region="";
}

	foreach($region){
		s/^1$/Northern Monterey County/;
		s/^2/Monterey Peninsula/;
		s/^3/Sierra de Salinas/;
		s/^4/Santa Lucia Mountains/;
		s/^5/Salinas Valley/;
		s/^6/Gabilan Range/;
		s/^7/Diablo Range/;
		s/^8/Southeast Monterey County/;
	}



foreach($location,$Locality1){
	s/^"//g;
	s/"$//g;
	s/"/'/g;
s/Cml\b/Carmel/g;
s/outcrps/outcrops/g;
s/\bQd\b/Quad/;
s/LPNF/Los Padres National Forest/;
s/\bLP\b/ Los Padres/;
s/St Pk/State Park/;
s/\bPk\b/Peak/g;
s/ Cr / Creek /g;
s/ Nat For / National Forest /;
s/ nr / near /g;
s/ nr$/ near /;
s/ rd / road /g;
s/ Tr / Trail /g;
s/ jct / junction /;
s/ Jct / Junction /;
s/ Jctn / Junction /;
s/ Cp / Camp /;
s/ N F / National Forest /;
s/ Cyn / Canyon /;
s/ cyn / canyon /;
s/ Gr / Grade /;
s/ Sch / School /;
   s/\(Cultavated/(Cultivated/;
   s/Botancial\b/Botanical/;
  s/Bottchsers\b/Bottchers/;
   s/Bradlely\b/Bradley/;
   s/Brandley\b/Bradley/;
  s/CVVillage\b/Carmel Valley Village/;
  s/\bCV\b/Carmel Valley/;
   s/Cemetary\b/Cemetery/;
   s/FRE-MNT\b/Fresno-Monterey/;
s/FRE-SBT\b/Fresno-San Benito/;
 s!FRE/SBT\b!Fresno-San Benito!;
  s!\bFRE\b!Fresno!;
s/Hwy\b/Highway/;
  s/Jackhammr\b/Jackhammer/;
   s/Jamemsburg\b/Jamesburg/;
   s/Jamsburg\b/Jamesburg/;
 s/Junepero\b/Junipero/;
   s/Junipeor\b/Junipero/;
   s/Liggitt\b/Liggett/;
  s/MNT-FRE\b/Monterey-Fresno/;
  s/MNT-SBT\b/Monterey-San Benito/;
  s/MNT-SLO\b/Monterey-San Luis Obispo/;
   s/MNT\/SBT\b/Monterey-San Benito/;
  s/\bMNT\b/Monterey/;
s/Reservatiion\b/Reservation/;
s/Reservatin\b/Reservation/;
s/Reservaton\b/Reservation/;
 s/Reservat\b/Reservation/;
  s/\bSBT\b/San Benito/;
  s/Tassajaara/Tassajara/;
   s/Tassajasra/Tassajara/;
s/Valleu\b/Valley/;
   s/Vallley\b/Valley/;
   s/Vallly\b/Valley/;
   s/Washingtn\b/Washington/;
   s/conflluence\b/confluence/;
}


	if((length($Locality1) > 1) && (length($location) == 0) && (length($region) == 0)){
		$locality = $Locality1;
				
	}		
	elsif ((length($Locality1) > 1) && (length($location) >1) && (length($region) == 0)){
		$locality = "$Locality1, $location";
		
	}
	elsif ((length($Locality1) == 0) && (length($location) > 1) && (length($region) > 1)){
		$locality = "$region, $location";
	}
	elsif ((length($Locality1) > 1) && (length($location) > 1) && (length($region) > 1)){
		$locality = "$region, $Locality1, $location";
	}
	elsif ((length($Locality1) > 1) && (length($location) == 0) && (length($region) > 1)){
		$locality = "$region, $Locality1";
	}
	elsif ((length($Locality1) == 0) && (length($location) > 1) && (length($region) == 0)){
		$locality = "$location";
	}
	elsif ((length($Locality1) == 0) && (length($location) == 0) && (length($region) > 1)){
		$locality = $region;
	}
	elsif ((length($Locality1) == 0) && (length($location) == 0) && (length($region) == 0)){
		$locality = "";
		&log_change("LOCAT: Locality1 & location & region NULL, $id\n");
	}
	else {
		&log_change("LOCAT: Locality problem, bad format, $id===>($Locality1)\t($location)\t($region)\n");		#call the &log function to print this log message into the change log...
	}


#process verbatim elevation fields into CCH format
#skipping normal elevation processing, elevation is only in locality2 field

$CCH_elevationInMeters = "";

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
#no coordinates in these data

####TRS
#no TRS in these data


#######Habitat and Assoc species (dwc habitat and associatedTaxa)


	foreach($habitat){
		s/"//g;
		s/^[#H]?-?\d+$//i;
		s/^X$//i;
		s/00//;
		s/[cC]halk Rk/Chalk Rock/;
		s/DG/Decomposed granite/;
		s/Serp\b/Serpentine/;
	}


++$count_record;
warn "$count_record\n" unless $count_record % 10000;

print OUT <<EOP;

Accession_id: $id
Other_label_numbers: 
Name: $scientificName
Date: $eventDate
EJD: $EJD
LJD: $LJD
Collector: $collector
Other_coll: $other_collectors
Combined_coll: $collector
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Country: $country
State: $stateProvince
County: $county
Location: $locality
Habitat: $habitat
T/R/Section: 
Decimal_latitude: 
Decimal_longitude: 
Lat_long_ref_source: 
Datum: 
Max_error_distance: 
Max_error_units: 
Elevation: $CCH_elevationInMeters
Verbatim_elevation: 
Verbatim_county: $tempCounty
Hybrid_annotation: $hybrid_annotation
Cultivated: $cultivated
Annotation: $det_orig

EOP

#add one to the count of included records
++$included;
}


close (IN);

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


    my $file_in = 'PGM_out.txt';	#the file this script will act upon is called 'CATA.out'
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

