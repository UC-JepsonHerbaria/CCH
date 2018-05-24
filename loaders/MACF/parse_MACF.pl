use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
$today_JD=julian_day($today_y, $today_m, $today_d);

&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array
foreach(keys(%TID)){
#print "$_: $TID{$_}\n";
}
#die;
open(OUT,">MACF.out") || die;
open(ERR,">MACF_log") || die;

#exclude non-vascular plants
open(IN,"/Users/davidbaxter/DATA/mosses") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}

#####process the file
#MACF file arrives as a tab-delimited text file
#line breaks are messed up. Best thing to do is to remove all Unix line breaks
###:%s/\n//g
#then replace MS line breaks with Unix line breaks
###:%s/[Ctrl+V][Ctrl+M]/[Ctrl+V][Ctrl+M]/g
#Also, remove all double quote character "

	my $file = 'MACF_Database.txt';
	
open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless($#columns==30){
		print ERR "$#columns bad field number $_\n";
	}
	
($collectionID, #e.g. "Vascular Plants". Check if not this value, just in case
$id, #need to prepend MACF 
$family, #not needed
$scientificName,
$identificationQualifier,
$OriginalDeterminer,
$OriginalDetDate, #in YYYY-MM-DD (or YYYY-MM or YYYY), except for "July 23, 1935", "08-08-1967" and "1879-12-XX"
$DeterminationNotes,
$AnnotationHistory, #i.e. dets that are newer than the original determination, so current det is this one
$MainCollector,
$OtherCollectors, #combine to make recordedBy
$verbatimDate, #YYYY-MM-DD, YYYY-MM except for "08-08-1967" and "1879-12-XX" and some errors
$EventEarlyDate,
$EventLateDate, #these two are hardly ever used, although sometimes EarlyDate is populated instead of verbatimDate
$recordNumber, #sometimes has suffixes et al, need to be parsed out for CCH
$county,
$stateProvince, #not always California
$country, #not always USA
$locality,
$elevation, #sometimes a range ##-###
$elevationUnits, #m or ft
$habitat,
$occurrenceRemarks, #called Plant Description
$associatedTaxa,
$Comments_Notes, #usually common names, internal notes or label headers, i.e. doesn't need to be published
$verbatimCoordinates,
$latitude, #poorly formatted; very few which pertain to California. May not bother parsing
$longitude, #poorly formatted; very few which pertain to California. May not bother parsing
$datum, #unused so far
$coordinateSource, #unused so far
$coordinateUncertaintyInMeters #unused so far
)=@columns;


##########CollectionID
unless ($collectionID=~m/Vascular Plants/){
	&log("Collection not Vascular plants: $collectionID $scientificName");
	next Record;
}


##########Accession ID
#check for nulls
if ($id=~/^ *$/){
	&skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
}

#remove spaces, prepend herbarium code
foreach($id){
	s/ //g;
	s/^/MACF/g;
}

#Remove duplicates
	if($seen{$id}++){
		++$skipped{one};
		warn "Duplicate number: $id<\n";
		&skip("Duplicate accession number: $id");
		next;
}


##########Higher Geography
#process this first so you don't end up dealing with names from outside California
unless ($country=~m/United States/){
	&skip("Country not USA: $id $country");
	next Record;
}
unless ($stateProvince=~m/^California$/){
	&skip("State not California: $id $stateProvince");
	next Record;
}

foreach ($county){
	s/^ *//g;
	s/ *$//g;
	s/  / /g;

	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
		$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&skip("NON-CA COUNTY? $_\t$id");	#run the &skip function, printing the following message to the error log
			next Record;
		}

		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log("COUNTY $_ -> $v_county\t$id");		#call the &log function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}



##########Scientific Name
foreach($scientificName){
	s/^ *//g;
	s/ *$//g;
	s/  / /g;
}

#strip out authors
$scientificName=&strip_name($scientificName);
$scientificName=ucfirst(lc($scientificName));

#skip if no name
unless($scientificName){
				&skip("No name: $id", @columns);
				next Record;
		}

#skip if non-vascular plant
($genus=$scientificName)=~s/ .*//;
		if($exclude{$genus}){
				&skip("Non-vascular plant: $id", @columns);
				next Record;
		}

#match name to master list
if($alter{$scientificName}){
				&log ("Spelling altered to $alter{$scientificName}: $scientificName\t$id");
				$scientificName=$alter{$scientificName};
			}
			
		unless($TID{$scientificName}){
			$on=$scientificName;
			if($scientificName=~s/subsp\./var./){
				if($TID{$scientificName}){
					&log("$id Not yet entered into SMASCH taxon name table: $on entered as $scientificName");
				}
				else{
					&skip("$id Not yet entered into SMASCH taxon name table: $on skipped");
					++$badname{"$on"};
					next Record;
				}
			}
			elsif($scientificName=~s/var\./subsp./){
				if($TID{$scientificName}){
					&log("$id Not yet entered into SMASCH taxon name table: $on entered as $scientificName");
				}
				else{
					&skip("$id Not yet entered into SMASCH taxon name table: $on skipped");
					++$badname{"$on"};
					next Record;
				}
			}
			else{
				&skip("$id Not yet entered into SMASCH taxon name table: $on skipped");
				++$badname{"$on"};
				next Record;
			}
		}

##########Annotations
###waiting on Sarah Taylor to advise on field use
#$identificationQualifier
#$OriginalDeterminer
#$OriginalDetDate #in YYYY-MM-DD (or YYYY-MM or YYYY), except for "July 23, 1935", "08-08-1967" and "1879-12-XX"
#$DeterminationNotes == Original Determination, if different from current scientificName
#$AnnotationHistory == Current determination (and date), if different from original

#their data for Original Determination is pretty sparse so far, so not putting it in for now
#And the annotation history field is messy too, so I'm going to wait until their next load to format that.
 

##########Collectors
if ($MainCollector=~/(^F\. ?A\. ?M\.?$|^FAM$|^F\. ?A\. McF|^F\. A\. MacF)/){
	$MainCollector = "F. A. MacFadden";
}
unless ($MainCollector){
	&log("No collector recorded: $id $MainCollector");
	$MainCollector = "unknown";
}

if ($OtherCollectors=~/^\d\d/){
	&log("Date recorded in Other Collectors, value nulled: $id $OtherCollectors");
	$OtherCollectors = "";
}

if ($MainCollector && $OtherCollectors){
	$recordedBy = "$MainCollector; $OtherCollectors";
}
elsif ($MainCollector=~/unknown/){
	$recordedBy = "";
}
elsif ($MainCollector){
	$recordedBy = $MainCollector;
}
else {
	$recordedBy = "";
}

##########Collection Date
if ($verbatimDate=~/^$/ && $EventEarlyDate){
	$verbatimDate = $EventEarlyDate;
}

if ($verbatimDate =~ /(\d\d\d\d)-(\d\d)-(\d\d)/){
	$YYYY=$1;
	$MM=$2;
	$DD=$3;
}
elsif ($verbatimDate =~ /(\d\d\d\d)-(\d\d)/){
	$YYYY=$1;
	$MM=$2;
}
elsif ($verbatimDate =~ /(\d\d)-(\d\d)-(\d\d\d\d)/){
	$YYYY=$3;
	$MM=$2;
	$DD=$1;
}
elsif ($verbatimDate =~ /(\d\d\d\d)-(\d\d)-XX/){
	$YYYY=$1;
	$MM=$2;
}
elsif ($verbatimDate=~/.+/){
	&log("$date format not recognized: $id $verbatimDate");
}


	if ($YYYY && $MM && $DD){
		$JD=julian_day($YYYY, $MM, $DD);
		$LJD=$JD;
		}
	elsif($YYYY && $MM){	
			if($MM==12){	
					$JD=julian_day($YYYY, $MM, 1);	
					$LJD=julian_day($YYYY, $MM, 31);
			}
			else{
					$JD=julian_day($YYYY, $MM, 1);
					$LJD=julian_day($YYYY, $MM+1, 1);
						$LJD -= 1;
			}
		}
	else{
		$JD=$LJD="";
}

	$DATE=$verbatimDate;
	if ($LJD > $today_JD){	#If $LJD is later than today's JD (calculated at the top of the script)
		&log("$id DATE nulled, $eventDate ($LJD)  is later than today's date ($today_JD)\n");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD="";	#...then null the date
	}
	elsif($YYYY < 1800){	#elsif the year is earlier than 1800
		&log("$id DATE nulled, $eventDate ($YYYY) earlier than 1800\n");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD=""; #...then null the date
	}


##########Coll Number
foreach ($recordNumber){
	s/\+//;
}
if ($recordNumber =~ /^([^\d]+)([\d]+)([^\d]+)/){
	$CNUM_prefix = $1;
	$CNUM = $2;
	$CNUM_suffix = $3;
}
elsif ($recordNumber =~ /^([^\d]+)([\d]+)/){
	$CNUM_prefix = $1;
	$CNUM = $2;
	$CNUM_suffix = "";
}
elsif ($recordNumber =~ /^([\d]+)([^\d]+)/){
	$CNUM_prefix = "";
	$CNUM = $1;
	$CNUM_suffix = $2;
}
elsif ($recordNumber =~ /^([\d]+)$/){
	$CNUM_prefix = "";
	$CNUM = $1;
	$CNUM_suffix = "";
}
elsif ($recordNumber) {
	$CNUM_prefix = "";
	$CNUM = "";
	$CNUM_suffix = $recordNumber;
}
else {
	$CNUM_prefix = "";
	$CNUM = "";
	$CNUM_suffix = "";
}


#########LOCALITY
#$locality doesn't need any munging


#######ELEVATION
if ($elevation =~ /[^0-9.-]/){
	&log("check elevation value: $elevation $id");
	$elevation = $elevationUnits = "";
}
elsif ($elevationUnits){
	unless ($elevationUnits =~ /^ft$|^m$/){
		&log("check elevation units: $elevationUnits $id");
		$elevation = $elevationUnits = "";
	}
}

if ($elevation || $elevationUnits){
	$verbatimElevation = "$elevation $elevationUnits";
}
elsif ($elevation){
	&log("elevation lacking units: $elevation $id");
	$verbatimElevation = "";
}
elsif ($elevationUnits){
	&log("elevation units only: $elevationUnits $id");
	$verbatimElevation = "";
}
else{
	$verbatimElevation = "";
}


########HABITAT AND ASSOCIATES
if ($habitat && $associatedTaxa){
	$CCH_habitat = "$habitat; Associates: $associatedTaxa";
}
elsif ($habitat){
	$CCH_habitat = $habitat;
}
elsif ($associatedTaxa){
	$CCH_habitat = "Associates: $associatedTaxa";
}
else {
	$CCH_habitat = "";
}


##############PLANT DESCRIPTION
#$occurrenceRemarks: no need to munge




##############COORDINATES
#$verbatimCoordinates,
#$latitude, #poorly formatted; very few which pertain to California. May not bother parsing
#$longitude, #poorly formatted; very few which pertain to California. May not bother parsing



############DATUM, COORD SOURCE, ERROR RADIUS
#$datum, #unused so far
#$coordinateSource, #unused so far
#$coordinateUncertaintyInMeters #unused so far




	print OUT <<EOP;
Accession_id: $id
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Name: $scientificName
Date: $verbatimDate
EJD: $JD
LJD: $LJD
County: $county
Location: $locality
Collector: $MainCollector
Other_coll: $OtherCollectors
Combined_collector: $recordedBy
Habitat: $CCH_habitat
Notes: $PlantDescription
Decimal_latitude: 
Decimal_longitude: 
Datum: 
Elevation: $verbatimElevation
Notes: $occurrenceRemarks

EOP

}



sub skip {	#for each skipped item...
	print ERR "skipping: @_\n"	#print into the ERR file "skipping: "+[item from skip array]+new line
}
sub log {	#for each logged change...
	print ERR "logging: @_\n";	#print into the ERR file "logging: "+[item from log array]+new line
}