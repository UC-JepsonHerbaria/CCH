
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


use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA';
use CCH; #loads non-vascular plant names list ("mosses"), alter_names table, and max_elev values
#$today=`date "+%Y-%m-%d"`;
#chomp($today);
#($today_y,$today_m,$today_d)=split(/-/,$today);
#$today_JD=julian_day($today_y, $today_m, $today_d);
&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array
$today_JD = &get_today_julian_day;

my %month_hash = &month_hash;

open(OUT,">RSA_specify_out.txt") || die;
open(OUT2,">exclude_FMP.txt") || die;
open(OUT3, ">RSA_POM_ID.txt") || die;


my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

#############
#Any notes about the input file go here
#file appears to be un UTF-8

#RSA specify file has erroneous vertical tab codes that show up as red '?' in text files.  These need to be deleted because they are also in the accesion number field, making linking specimens impossible
# or x{Ob} or \x0b
#'Bryophyte packet - 1' specimens with this in the record should be skipped, some are without taxon names

#in the dump (2016-04), RSA sent Baja records in a separate file.
#David concatenated the two files into RSA_latest_file.tab
#############

#$current_file="2017.08.29_RSA_CCH.txt";
#$current_file="2016.04.20_RSA_CCH.tab";
$current_file="RSA_latest_file.tab";

warn "reading from $current_file\n";

open(IN, "$current_file") || die;
Record: while(<IN>){

	chomp;


my @columns=split(/\t/,$_,100);
		unless($#columns==43){ #19 fields but first field is field 0 in perl
		&log_skip("$#fields bad field number $_\n");
		++$skipped{one};
		next Record;
	}


s///g;

($cchId, #sequential number; I don't think is used for anything
$barcode, #different from Accession number. Maybe publish as an "other number"
$Herbarium, #RSA or POM
$Accession_Number, #Numeric portion of accession number
$Accession_Suffix, #A, B, etc.
$family, #CCH doesn't use, but is Darwin Core
$genus,
$specificEpithet,
$subspecies,
$variety, #10   subspecies and variety together make the infraspecificEpithet dwc term
$tempName, #full name, I'll use this instead of concatenating the previous fields. substitute subsp. for ssp.
$identificationQualifier,
$Position, #as in, position of the id qualifier. Use this to make an annotation name
$identifiedBy,
$dateIdentified,
$typeStatus,
$recordedBy, #collectors, comma delimited
$recordNumber, #coll num
$eventDate, #collection date in beautiful YYYY-MM-DD
$verbatimEventDate, #20
$country, #always United States, so no action required
$stateProvince, #always California, no action required
$tempCounty,
$Locality1,
$Locality2, #i.e. "Locality Continued"
$verbatimLatitude,
$verbatimLongitude,
$geodeticDatum,
$Township,
$Range,  #30
$Section, #concatenate into a string but don't bother doing anything with converting
$ErrorRadius,
$ErrorRadiusUnits,
$georeferenceSource, #knock out weird ones: ones that start with [/[/(0-9]
$minimumElevationInMeters,
$maximumElevationInMeters,
$verbatimElevation,
$habitat,
$reproductiveCondition, #i.e. phenology
$occurrenceRemarks, #i.e. plant description
$Culture, #what they call "Culture". Currently not a CCH field
$establishmentMeans, #Native, Introduced, or cultivated
$Preparations, #Herbarium sheet, etc. doesn't need to be published 
$GUID 
) = @columns;


#######ACCESSION ID#########
#concatenate values into $id
$id = $Herbarium . $Accession_Number . $Accession_Suffix;
$id =~ s/ +//g;


#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
}

#check that id has a prefix + number
unless ($id=~/^(RSA|POM)(\d+)/){
	&log_skip("Accession number missing prefix or has prefix problem id:$id $_");
	next Record;
}

#add suffux for some duplicates
#if($duplicate{$id}++){
#$id=~s/^(RSA|POM)(\d+)$/$1$2DUP/g;
#	warn "Duplicate accession modified: $id<\n";
#	&log_change("Duplicate accession number, added a suffix, $id");
#}
#remove duplicates
#if($seen{$id}++){
#	++$skipped{one};
#	warn "Duplicate number: $id<\n";
#	&log_change("Duplicate accession number, skipped: $id");
#	next;
#}


foreach ($id){
		s/ +//g;
		s/RSAw//g; #fix one record with a lower case "w"

print OUT2 "$id\n";

}

########Scientific Name#############
#check for names to exclude
if($genus){ #this is done to accomodate vascular plants identified to family (have no genus)
	if($exclude{$genus}){
		&log_skip("Non-vascular plant:\t$id\t", @columns);
		next Record;
	}
}


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







############Determination############
#process infraspecific epithets
if ($subspecies) {
	$infraspecificEpithet = $subspecies;
	$infra_rank = "subsp.";
}
elsif ($variety) {
	$infraspecificEpithet = $variety;
	$infra_rank = "var.";
}
else {
	$infraspecificEpithet = $infra_rank = "";
}

#make verbatim name for determination
if ($Position eq "after entire name"){
	$verbatim_name = "$scientificName $identificationQualifier";
}

elsif ($Position eq "after infraspecific epithet"){
	$verbatim_name = "$scientificName $identificationQualifier";
}
elsif ($Position eq "after specific epithet"){
	$verbatim_name = "$genus $species $identificationQualifier $infra_rank $infraspecificEpithet";
	$verbatim_name =~ s/ *$//;
	$verbatim_name =~ s/ +//;
}
elsif ($Position eq "before genus"){
	$verbatim_name = "$identificationQualifier $scientificName";
}

elsif ($Position eq "before infraspecific epithet"){
	$verbatim_name = "$genus $species $infra_rank $identificationQualifier $infraspecificEpithet";
	$verbatim_name =~ s/ *$//;
	$verbatim_name =~ s/ +//;
}
elsif ($Position eq "before species" || $Position eq "after genus"){
	$verbatim_name = "$genus $identificationQualifier $species $infra_rank $infraspecificEpithet";
	$verbatim_name =~ s/ *$//;
	$verbatim_name =~ s/ +//;
}
elsif ($Position) {
	&log_change("new id_qualifer position format used. Check it: $Position $id");
	$verbatim_name = $scientificName;
}
else {
	$verbatim_name = $scientificName;
}

#Assemble annotation, if there's something worth noting
if (($verbatim_name ne $scientificName) || $identifiedBy || $dateIdentified) {
	$Annotation = "$verbatim_name; $identifiedBy; $dateIdentified; "; #CCH follow the format "name; determiner; det date; det notes", but RSA provides no det notes
}
else {
	$Annotation = "";
}
 

#####Type status###############
#remove "Not type"
if ($typeStatus eq "Not type"){
	$typeStatus = "";
}


######COLLECTOR##########
#remove extraneous spaces
foreach ($recordedBy){
	s/^ *//;
	s/ *$//;
	s/ +/ /;
}
#split $recordedBy into main collector and other collectors
if ($recordedBy =~ /([^,]+), (.*)/){
	$main_coll = $1;
	$other_coll = $2;
}
elsif ($recordedBy){
	$main_coll = $recordedBy;
	$other_coll = "";
}
else {
	$main_coll = $other_coll = "";
}


###COLLECTOR NUMBER
#use CCH.pm function to split $recordNumber into CNUM prefix, CNUM, CNUM suffix
if($recordNumber){
	($CNUM_prefix, $CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);
	#print "1 $prefix\t2 $CNUM\t3 $suffix\n";
}
else{
	$CNUM_prefix=$CNUM=$CNUM_suffix="";
}


######COLLECTION DATE#######
#$verbatimEventDate doesn't need to be processed
#although RSA has requested that the formatted start date ($eventDate) be used as the verbatimEventDate for now if available,
#since CCH currently only displays the verbatim event date

#process JD from $eventDate

	foreach ($eventDate){
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
	#warn "Date (2)$eventDate\t$id";
	}
	elsif($eventDate=~/^([0-9]{1})-([0-9]{1,2})-([0-9]{4})/){	#added to SDSU, if eventDate is in the format #-##?-####, most appear that first # is month 
		$YYYY=$3; 
		$MM=$1; 
		$DD=$2;
		$MM2 = "";
		$DD2 = "";
	#warn "Date (3)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([Ss][pP][rR][ing]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "3";
		$DD = "1";
		$MM2 = "5";
		$DD2 = "31";
	#warn "Date (14)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([Ss][uU][Mm][mer]*)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$MM = "6";
		$DD = "1";
		$MM2 = "8";
		$DD2 = "31";
	#warn "Date (16)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([fF][Aa][lL]+)[- ]([0-9]{4})/) {
		$YYYY = $2;
		$DD = "1";
		$MM = "9";
		$DD2 = "30";
		$MM2 = "11";
	#warn "Date (12)$eventDate\t$id";
	}	
	elsif ($eventDate=~/^([0-9]{1,2}) ([A-Za-z]+) ([0-9]{4})/){
		$DD=$1;
		$MM=$2;
		$YYYY=$3;
		$MM2 = "";
		$DD2 = "";
	#warn "(2)$eventDate\t$id";
	}
	elsif ($eventDate=~/^([0-9]{1,2})[- ]+([0-9]{1,2})[- ]+([A-Z][a-z]+)[- ]([0-9]{4})/){
		$DD=$1;
		$DD2=$2;
		$MM=$3;
		$MM2=$3;
		$YYYY=$4;
	#warn "(4)$eventDate\t$id";
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
	#warn "Date (8): $eventDate\t$id";
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
	#warn "Date (10): $eventDate\t$id";
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
	#warn "(5)$eventDate\t$id";
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


############COUNTY########
	foreach ($tempCounty){	#for each $county value
#		s/ County$//;
#		s/[()]*//g;	#remove all instances of the literal characters "(" and ")"
#		s/ +coun?ty.*//i;	#substitute a space followed by the word "county" with "" (case insensitive, with or without the letter n)
#		s/ +co\.//i;	#substitute " co." with "" (case insensitive)
#		s/ +co$//i;		#substitute " co" with "" (case insensitive)
		s/^ +//;
		s/ +$//;		
		s/unknown/Unknown/;	
		s/^$/Unknown/;	

#		s/County Unknown/Unknown/;	#"County unknown" => "unknown"
#		s/County unk\./Unknown/;	#"County unk." => "unknown"
#		s/Unplaced/unknown/;	#"Unplaced" => "unknown"
#		#print "$_\n";
}

$county=&CCH::format_county($tempCounty,$id);


foreach($GUID){
print OUT3 "$id\t$GUID\t$cchId\t$county\t$scientificName\t$GUIDx\n";
}

	foreach ($county){

		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|Unknown)$/){
			$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
			if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
				&log_skip("NON-CA COUNTY? $_\t==>$id");	#run the &log_skip function, printing the following message to the error log
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
				&log_change("COUNTY $_ -> $v_county\t==>$id");		#call the &log function to print this log message into the change log...
				$_=$v_county;	#and then set $county to whatever the verified $v_county is.
			}
		}
	}


########Locality String
$locality = "";
if ($Locality1 && $Locality2){
	$locality = "$Locality1, $Locality2";
}
elsif ($Locality1){
	$locality = $Locality1;
}
elsif ($Locality2) {
	$locality = $Locality2;
	&log_change("note: Locality_Continued but no Locality")
}
else {
	$locality = "";
}


foreach ($verbatimLatitude){
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/,/ /g;
		s/-//g; #remove negative latitudes, we dont map specimens from southern hemisphere, so if "-" is present, it is an error
		s/deg\.?/ /;
		s/ 17 1.218/ 17.5/;#fix a series of bad latitudes
		s/ 35682/ 35.682/;
		s/ 1213/ 12.5/;
		s/ 4241/ 42 41/;
		s/ 4750/ 47 50/;
		s/ 47\.+50/ 47 50/;
		s/ 4748/ 47 48/;
		s/^32 7112/ 32.7112/;
		s/ 5153.5\.5/ 52/; 
		s/^3440/34 40/;
		s/ 51\.+53\.5/ 52/;
		s/ 910.5/ 10/;
		s/ 5657/ 56.5/;

	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
		
}

foreach ($verbatimLongitude){
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/,/ /g;
		s/deg\.?/ /;
		s/^-?12208983/122.08983/;#fix a series of bad longitudes
		s/^-?11655/116 55/;
		s/^-?12025/120 25/;
		s/ 6\.5-7/ 6.75/;
		s/ 51-52/ 51.5/;
		s/ 55 3.4/55.5/;
		s/ 53-54\.5/53.5/;
		s/^-?17 /117 /;
		s/^-?14 /114 /;
		s/^-?118\.+119/118.5/;
		s/ 53-54/ 53.5/;
		s/ 52-54/ 53/;
		s/ 35433/ 35 43.3/;
		s/ 17-22/ 17 22/;
		s/ 17\.+22/ 17 22/;
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
	#print "COORDINATE 6 $id\n";
	}
	elsif (($verbatimLatitude =~ m/^\d\d \d/) && ($verbatimLongitude =~ m/^-?1\d\d \d/)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
	print "COORDINATE 7 $id\n";
	}
	elsif (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d/)){
			$latitude = sprintf ("%.3f",$verbatimLatitude); #convert to decimal, should report cf. 38.000
			$longitude = $verbatimLongitude; #parser below will catch variant of this one, except where both lat & long are degree only, 
	print "COORDINATE 8 $id\n";
			&log_change("COORDINATE latitude integer degree only: $verbatimLatitude converted to $latitude==>$id");
	}
	elsif (($verbatimLatitude =~ m/^\d\d/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
			$latitude = $verbatimLatitude; #parser below will catch variant of this one, except where both lat & long are degree only, 
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
	}


#NULL coordinates that are only integer degrees, these are highly inaccurate and not useful for mapping
	if (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
		$decimalLatitude=$latitude = "";
		$decimalLongitude=$longitude = "";
		&log_change("COORDINATE verbatim Lat/Long only to degree, now NULL: $verbatimLatitude\t--\t$verbatimLongitude\n");
	}



#use combined Lat/Long field format for RSA

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
				$long_decimal= $1;
				if($long_decimal > 180){
					&log_change("COORDINATE 7) Longitude problem, set to null,\t$id\t$long_degrees\n");
					$long_decimal=$longitude=$decimalLongitude="";		
				}
				else{
					$decimalLongitude=sprintf ("%.6f",$long_decimal);
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
		&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude)\n");
		$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
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
		s/^ *//;
		s/ *$//;
		
	
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
		&log_change("coordinates set to null for $id, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude = $decimalLongitude = $georeferenceSource = $datum="";	#and set $decLat and $decLong to ""  
	}
}
else {
		if((length($decimalLatitude) == 0)  && (length($decimalLongitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}

###########TRS########
#concatenate into a string but don't bother doing anything with converting
$trs = "";
if ($Township && $Range && $Section) {
	$trs = "$Township $Range $Section";
}
elsif ($Township && $Range) {
	$trs = "$Township $Range";
}
elsif ($Township || $Range || $Section) { 
	&log_change("TRS data missing township and/or range. TRS nulled: $id"); #TRS needs both township and range
	$trs = "";
}
else { #else all three are blank
	$trs = "";
}

###########ERROR RADIUS AND UNITS#####
if ($errorRadiusUnits eq "km") {
	$errorRadius = $errorRadius * 1000;
	$errorRadiusUnits = "m";
}
elsif ($errorRadius){
	unless ($errorRadiusUnits) {
		&log_change("no units for error radius. ER: $errorRadius; $id");
		$errorRadius = "";
	}
	unless ($errorRadiusUnits eq "m") {
		&log ("Error Radius Units (\"$errorRadiusUnits\") not recognized or accounted for. Nulling error radius: $id");
		$errorRadiusUnits=$errorRadius="";
	}
}

#######Georeference Source#############
#RSA has some weird ones that start with brackets or numbers. Null these
foreach ($georeferenceSource) {
	s/^"//;
	s/"$//;
}
if ($georeferenceSource =~ /^\(|^\[|^(\d+)$/){
	&log_change("Nulling strange georeference source \"$georeferenceSource\": $id");
	$georeferenceSource = "";
}


############Elevation
#The "Verbatim_Elev_ft" field sometimes includes units; sometimes doesn't
#when it doesn't, do not include elevation
#to make it darwin core verbatimElevation, I add units when it is just a number or range of numbers
#then make a CCH elevation, preferring the meters over the verbatim elevation
#I process it first so darwinCore verbatimElevation is available if needed
if ($verbatimElevation =~ /^([ 0-9-]+)$/){
	$verbatimElevation = "";
}

if ($minimumElevationInMeters && $maximumElevationInMeters){
	if ($minimumElevationInMeters > $maximumElevationInMeters){
		&log_change("minimum elevation higher than maximum ($minimumElevationInMeters > $maximumElevationInMeters), swapping values: $id");
		($minimumElevationInMeters, $maximumElevationInMeters) = ($maximumElevationInMeters, $minimumElevationInMeters);
	}
	$Elevation = "$minimumElevationInMeters-$maximumElevationInMeters m";
}
elsif ($minimumElevationInMeters) {
	$Elevation = "$minimumElevationInMeters m";
}
elsif ($maximumElevationInMeters) {
	&log_change("Maximum Elevation but no Minimum Elevation. Single elevations should be recorded in Minimum Elevation field: $id");
	$Elevation = "$maximumElevationInMeters m";
}
elsif ($verbatimElevation) {
	$Elevation = "$verbatimElevation";
}
else {
	$Elevation = "";
}

########HABITAT
#no processing required

#########NOTES
#CCH "Notes" includes DwC fields occurrenceRemarks and reproductiveCondition
#if ($occurrenceRemarks && $reproductiveCondition) {
#	$occurrenceRemarks = "$occurrenceRemarks\.";
#	$occurrenceRemarks =~ s/\.\.$/./; #add a period at the end, if there isn't one
#	$Notes = "$occurrenceRemarks Phenology = $reproductiveCondition";
#}
#elsif ($occurrenceRemarks){
#	$Notes = "$occurrenceRemarks";
#}
#elsif ($reproductiveCondition){
#	$Notes = "Phenology: $reproductiveCondition";
#}
#else {
#	$Notes = "";
#}

############ESTABLISHMENTMEANS##########
#$establishmentMeans, #Native, Introduced, or cultivated
#establishmentMeans is not a field in CCH right now
#but it will be useful to use it to differentiate between cultivated and non-cultivated specimens
#which is a desired feature for the CCH



#########GUID 
#write $GUID to a %GUID hash, keyed to the accession ID
#CCH process concatenates separate AID/GUID files and puts them in the extract for GBIF
#CCH itself does not publish GUIDs, yet
#$GUID{$id}=$GUID;


print OUT <<EOP;
Accession_id: $id
Other_label_numbers: $GUID
Name: $scientificName
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
Collector: $main_coll
Other_coll: $other_coll
Combined_coll: $recordedBy
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix 
CNUM_suffix: $CNUM_suffix
County: $county
Location: $locality
Elevation: $Elevation
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
T/R/Section: $trs
Lat_long_ref_source: $georeferenceSource
Datum: $geodeticDatum
Max_error_distance: $errorRadius
Max_error_units: $errorRadiusUnits
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Habitat: $habitat
Phenology: $reproductiveCondition
Population_biology: $occurrenceRemarks
Notes: $origin
Hybrid_annotation: $hybrid_annotation
Cultivated: $establishmentMeans
Annotation: $det_orig
Annotation: $Annotation
Type_status: $typeStatus

EOP
}


#open(OUT,">AID_GUID_RSA.txt") || die;
#foreach(keys(%GUID)){
#	print OUT "$_\t$GUID{$_}\n";
#}