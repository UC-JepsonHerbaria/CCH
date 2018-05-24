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

open(OUT,">RSA_specify.out") || die;

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

#############
#Any notes about the input file go here
#file appears to be un UTF-8
#in the latest dump (2016-04), RSA sent Baja records in a separate file.
#I concatenated the two files into RSA_latest_file.tab
#############

#$current_file="2015.06.11_RSA_CCH.tab";
#$current_file="2016.04.20_RSA_CCH.tab";
$current_file="RSA_latest_file.tab";

open(IN, "$current_file") || die;
warn "reading from $current_file\n";

while(<IN>){
	chomp;
	&CCH::check_file;
	s/\t.*//;
	if($seen_dup{$_}++){
		++$duplicate{$_};
	}
}
close(IN);



open(IN, "$current_file") || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
	unless ($#columns==43){
		print ERR "$#columns bad field number $_\n";
	}

($cchId, #sequential number; I don't think is used for anything
$Barcode, #different from Accession number. Maybe publish as an "other number"
$Herbarium, #RSA or POM
$Accession_Number, #Numeric portion of accession number
$Accession_Suffix, #A, B, etc.
$family, #CCH doesn't use, but is Darwin Core
$genus,
$specificEpithet,
$subspecies,
$variety, #subspecies and variety together make the infraspecificEpithet dwc term
$scientificName, #full name, I'll use this instead of concatenating the previous fields. substitute subsp. for ssp.
$identificationQualifier,
$Position, #as in, position of the id qualifier. Use this to make an annotation name
$identifiedBy,
$dateIdentified,
$typeStatus,
$recordedBy, #collectors, comma delimited
$recordNumber, #coll num
$eventDate, #collection date in beautiful YYYY-MM-DD
$verbatimEventDate,
$country, #always United States, so no action required
$stateProvince, #always California, no action required
$county,
$Locality1,
$Locality2, #i.e. "Locality Continued"
$decimalLatitude,
$decimalLongitude,
$geodeticDatum,
$Township,
$Range,
$Section, #concatenate into a string but don't bother doing anything with converting
$ErrorRadius,
$ErrorRadiusUnits,
$georeferenceSource, #knock out weird ones: ones that start with [/[/(0-9]
$minimumElevationInMeters,
$maximumElevationInMeters,
$verbatimElevation,
$habitat,
$reproductiveCondition, #i.e. phenology
$occurrenceRemarks, #i.e. plant description, which goes into cch field "Notes"
$Culture, #what they call "Culture". Currently not a CCH field
$establishmentMeans, #Native, Introduced, or cultivated
$Preparations, #Herbarium sheet, etc. doesn't need to be published 
$GUID 
) = @columns;


#######ACCESSION ID#########
#concatenate values into $id
$id = $Herbarium . $Accession_Number . $Accession_Suffix;
$id =~ s/ //g;

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

#remove duplicates
if($seen{$id}++){
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate accession number, skipped: $id");
	next;
}


##################Exclude known problematic specimens by id numbers, most from outside California and Baja California
# if ($id =~/^(12651038|6786882|903063|5542516|5553080|5559939|5560204|5564409|5571451|5578463|5578464|5579706|881193|881194|946792|946795|958356|13936935|13951195|13184339|8482435|3145188|3165281|8551641|2063694|6010380|3143301|6010483|3288631|5999431|6009962|3828429|3128756|891892|947111|6901995|3236890|3349408|5556965|3920225|3920384|7358734|949278|947283|953299|1910899|960031|7887537|901900|950642|885247|2139875|3236890|7880474|7880475|3349409|3156500|955884|5578801|5578802|8111276|901887|10964957|10899737|10612927|523075|2139878|947426|949080|952106|3840903|10450011|7878637|3350112|5574540|2140016|206575|8094686|6919312|10587155|6059833|6053609|6078071|6084883|6038783|6080815|6092926|6077290|6084618|6090271|6067228|6078439|6062798|6061904|6053009|6048333|6081870|3831133|5578807|957986|948347|7987520|3156332|5585640|5585641|3828429|780313|947147|932794|4090498|5556964|10492513|756181|8892781|10476365|2030103|3131301|5554619|3127702|5578808|5547519|5556946|954279|10789840|892491|952443|4557750|4557751|4134703|8071906|7067885|10791260|8099704|10546522|1004641|7293869|3130961|3158166|8100447|10905080|4041567|7096710|7096711|10789688|7880493|7880446|5556963|10484529|8696461|7096697|7096696|7572142|7579661|6900851|5585639|10731649|5519952|10848658|8215883)$/){
#	#print ("excluded problem record or record known to be not from California\t$locality\t--\t$id");
#		++$temp_skipped{one};
#		next Record;
#	}

	if(($id=~/^(RSA165454|RSA165651)$/) && ($county=~m/Mono/)){ #fix some really problematic county records
		&log_skip("COUNTY: County/State problem: buffer coordinates (38.58529	-119.310417) indicate this is from Nevada; also Desert Creek (Sweetwater Mts) inside CA is above 8000 ft, elevations lower than 7000 feet are in Douglas County, Nevada ($id: $county, $Locality1, $Locality2)\n");	
		next Record;
	}

	if(($id=~/^(RSA537260)$/) && ($county=~m/Riverside/)){ #fix some really problematic county records
		&log_skip("COUNTY: County/State problem: '21 miles west of Tonopah along I-10' is in Arizona, not California ($id: $county, $Locality1, $Locality2)\n");	
		next Record;
	}

########Scientific Name#############
#check for names to exclude
if($genus){ #this is done to accomodate vascular plants identified to family (have no genus)
	if($exclude{$genus}){
		&log_skip("Non-vascular plant:\t$id\t", @columns);
		next Record;
	}
}

foreach ($scientificName){ 
	s/ ssp\. / subsp. /;
	s/\cK/ /g;
	s/  */ /g;
	s/ $//;
	
}

#check alter_names table
if($alter{$scientificName}){
				&log_change ("Spelling altered to $alter{$scientificName}: $scientificName\t$id");
				$scientificName=$alter{$scientificName};
}

unless($TID{$scientificName}){
	$oldname=$scientificName;
	if($scientificName=~s/subsp\./var./){
		if($TID{$scientificName}){
			&log_change("Not yet entered into SMASCH taxon name table: $oldname entered as $scientificName\t$id ");
		}
		else{
			&log_skip("Not yet entered into SMASCH taxon name table: $oldname skipped\t$id");
			++$badname{"$oldname"};
			next Record;
		}
	}
	elsif($scientificName=~s/var\./subsp./){
		if($TID{$scientificName}){
			&log_change("Not yet entered into SMASCH taxon name table: $oldname entered as $scientificName\t$id");
		}
		else{
			&log_skip("Not yet entered into SMASCH taxon name table: $oldname skipped\t$id");
			++$badname{"$oldname"};
			next Record;
		}
	}
	else{
		&log_skip("Not yet entered into SMASCH taxon name table: $oldname skipped\t$id");
		++$badname{"$oldname"};
		next Record;
	}
}


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
$YYYY=$MM=$DD="";
if ($eventDate) {
	$verbatimEventDate=$eventDate;
	($YYYY, $MM, $DD)=&atomize_ISO_8601_date($eventDate);
}
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);

############COUNTY########
	foreach ($county){	#for each $county value
		s/ County$//;
#		s/[()]*//g;	#remove all instances of the literal characters "(" and ")"
#		s/ +coun?ty.*//i;	#substitute a space followed by the word "county" with "" (case insensitive, with or without the letter n)
#		s/ +co\.//i;	#substitute " co." with "" (case insensitive)
#		s/ +co$//i;		#substitute " co" with "" (case insensitive)
#		s/ *$//;		
#		s/^$/Unknown/;	
#		s/County Unknown/unknown/;	#"County unknown" => "unknown"
#		s/County unk\./unknown/;	#"County unk." => "unknown"
#		s/Unplaced/unknown/;	#"Unplaced" => "unknown"
#		#print "$_\n";


#fix additional problematic counties


#	if(($id=~/^(3129414|3143225|4692151|951709)$/) && ($county=~m/(Pasadena|Pasadena County)/)){ #fix some really problematic county records
#		$county=~s/^.*$/Los Angeles/;
#		&log_change("COUNTY: County/Location problem modified to $county\t$id\n");
#	}






		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
			$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
			if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
				&log_skip("NON-CA COUNTY? $_: $id");	#run the &log_skip function, printing the following message to the error log
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
				&log_change("COUNTY $_ -> $v_county: $id");		#call the &log function to print this log message into the change log...
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


#############LATITUDE AND LONGITUDE


		if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
			if ($decimalLongitude > 0) {
				$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			}	
			if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
				&log_change("coordinates set to null, Outside California: >$decimalLatitude< >$decimalLongitude< $id");	#print this message in the error log...
				$decimalLatitude =$decimalLongitude="";	#and set $decLat and $decLong to ""
			}
		}


#######DATUM#######
foreach ($geodeticDatum){
	s/ConUS//;
	s/ +//g;
	s/1984/84/;
	s/1983/83/;
	s/1927/27/;
}
if ($geodeticDatum){
	unless ($geodeticDatum =~ /^WGS84$|^NAD83$|^NAD27$|^NAD83\/WGS84$|^Unknown$/){
		&log_change ("strange datum nulled: $geodeticDatum $id");
		$geodeticDatum = "";
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


#fix additional problematic coordinates


	if(($id=~/^(RSA697083|RSA691538)$/) && ($county=~m/(unknown)/i)){ #fix some really problematic georeference records
		&log_change("COORDINATE: georeference problem, yellow flag record, coordinates set to null, collector anonymous, locality inprecise, and county unknown, georeference maps problematically to San Bernardino County, San Gorgonio Mountain $county\t$id\n");
		$decimalLatitude =$decimalLongitude="";	#and set $decLat and $decLong to ""
	#Antennaria media (RSA416669) Artemisia californica (RSA417260) are found at this this location, a note on the Antennaria media label states this although there is no specific location; Asplenium vespertinum (RSA691538) and Psathyrotes ramosissima (RSA697083) are yellow flags for San Gorgonio Mountain and coordinates nulled herein"
	}


############Elevation
#The "Verbatim_Elev_ft" field sometimes includes units; sometimes doesn't
#when it doesn't, the units is assumed to be feet
#to make it darwin core verbatimElevation, I add units when it is just a number or range of numbers
#then make a CCH elevation, preferring the meters over the verbatim elevation
#I process it first so darwinCore verbatimElevation is available if needed
if ($verbatimElevation =~ /^([ 0-9-]+)$/){
	$verbatimElevation = "$verbatimElevation ft";
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
if ($occurrenceRemarks && $reproductiveCondition) {
	$occurrenceRemarks = "$occurrenceRemarks\.";
	$occurrenceRemarks =~ s/\.\.$/./; #add a period at the end, if there isn't one
	$Notes = "$occurrenceRemarks Phenology = $reproductiveCondition";
}
elsif ($occurrenceRemarks){
	$Notes = "$occurrenceRemarks";
}
elsif ($reproductiveCondition){
	$Notes = "Phenology: $reproductiveCondition";
}
else {
	$Notes = "";
}

############ESTABLISHMENTMEANS##########
#$establishmentMeans, #Native, Introduced, or cultivated
#establishmentMeans is not a field in CCH right now
#but it will be useful to use it to differentiate between cultivated and non-cultivated specimens
#which is a desired feature for the CCH



#########GUID 
#write $GUID to a %GUID hash, keyed to the accession ID
#CCH process concatenates separate AID/GUID files and puts them in the extract for GBIF
#CCH itself does not publish GUIDs, yet
$GUID{$id}=$GUID;


print OUT <<EOP;
Accession_id: $id
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
Habitat: $habitat
Notes: $Notes
T/R/Section: $trs
Type_status: $typeStatus
Annotation: $Annotation

EOP
}

close OUT;

open(OUT,">AID_GUID_RSA.txt") || die;
foreach(keys(%GUID)){
	print OUT "$_\t$GUID{$_}\n";
}