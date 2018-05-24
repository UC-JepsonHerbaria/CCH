use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
$today_JD=julian_day($today_y, $today_m, $today_d);

&load_noauth_name; #loads taxon id master list into an array
foreach(keys(%TID)){
#print "$_: $TID{$_}\n";
}
#die;
open(OUT,">SACT.out") || die;
open(ERR,">SACT_problems") || die;

##meters to feet conversion
#$meters_to_feet="3.2808";


#####process the file

	my $file = 'SACT.tab';

open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless($#columns==20){
		print ERR "$#columns bad field number $_\n";
	}
	
($id,
$record_date,
$reproductiveCondition, #phenology: Put it in notes
$genus,
$species,
$subspecies,
$variety,
$dateIdentified,
$identifiedByLast,
$identifiedByFirst,
$eventDate, #collection date
$recordedByFirst,
$recordedByLast,
$otherCollFirst,
$otherCollLast,
$locality, #locality and habitat in one field, not delimited
$stateProvince,
$county,
$decimalLatitude,
$decimalLongitude,
$elevationInMeters)=@columns;

#print nowhere <<EoP;
#$id,
#$record_date,
#$reproductiveCondition, #phenology: Put it in notes
#$genus,
#$species,
#$subspecies,
#$variety,
#$dateIdentified,
#$identifiedByLastName,
#$identifiedByFirstName,
#$eventDate, #collection date
#$recordedByFirst,
#$recordedByLast,
#$otherCollFirst,
#$otherCollLast,
#$locality, #locality and habitat in one field, not delimited
#$stateProvince,
#$county,
#$decimalLatitude,
#$decimalLongitude,
#$elevationInMeters
#
#EoP

#ACCESSION_ID#
#check for nulls
if ($id=~/^ *$/){
	&skip("Record with no accession id $_\n");
	++$skipped{one};
	next Record;
		}
	

##################Exclude cult
# if locality starts with "cultivated" etc., skip the record. There are many other localities describing "next to cultivated field" etc.
	if($locality=~/^(Cultivated|cultivated|Small cultivated|Tree cultivated)/){
				&skip("$id Specimen from cultivation $_\n");	#&skip is a function that skips a record and writes to the error log
				++$skipped{one};
				next Record;
			}


##########COLLECTION DATE##########
if($eventDate=~/(\d\d\d\d)\/(\d\d)\/(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; $MM=$2; $DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM="" if $MM eq "00";	#If $MM is 00, set it to blank 
		$DD="" if $DD eq "00";	#If $DD is 00, set it to blank
		$MM=~s/^0//;	#if $MM begins with zero, substitute nothing for the zero
		$DD=~s/^0//;	#if $DD begins with zero, substitute nothing for the zero

		if($YYYY && $MM && $DD){	#If a year, month, and day value are present,
					$JD=julian_day($YYYY, $MM, $DD);	#create the Julian Day ($JD) based on that year, month, and day
					$LJD=$JD;	#Then set the late Julian Day ($LJD) to $JD because there is no range
		}
		elsif($YYYY && $MM){	#elsif there is only a year and month present
			if($MM=12){		#if the month is december...
					$JD=julian_day($YYYY, $MM, 1);		#Set $JD to Dec 1
					$LJD=julian_day($YYYY, $MM, 31);	#Set $LJD to Dec 31
			}
			else{		#else (if it's not december)
					$JD=julian_day($YYYY, $MM, 1);	#Set $JD to the 1st of this month
					$LJD=julian_day($YYYY, $MM+1, 1);	#Set $LJD to the first of the next month...
						$LJD -= 1;						#...Then subtract one day (to get the last dat of this month)
			}
		}
		elsif($YYYY){	#elsif there is only year
					$JD=julian_day($YYYY, 1, 1);	#Set $JD to Jan 1 of that year
					$LJD=julian_day($YYYY, 12, 31);	#Set $LJD to Dec 31 of that year 
		}
	}
	else{	#else (there is no $eventDate)
		$JD=$LJD=""; #Set $JD and $LJD to null
	}
	$DATE=$eventDate;
	if ($LJD > $today_JD){	#If $LJD is later than today's JD (calculated at the top of the script)
		&log("$id DATE nulled, $eventDate ($LJD)  greater than today ($today_JD)\n");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD="";	#...then null the date
	}
	elsif($YYYY < 1800){	#elsif the year is earlier than 1800
		&log("$id DATE nulled, $eventDate ($YYYY) less than 1800\n");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD=""; #...then null the date
	}
	
#######DETERMINER AND DATE#######
$identifiedByFirst=ucfirst($identifiedByFirst);
$identifiedByLast=ucfirst($identifiedByLast);	
		
if ($identifiedByFirst=~/^[A-Z]$/){
	$identifiedByFirst = "$identifiedByFirst.";
	}
if ($identifiedByLast=~/^[A-Z]$/){
	$identifiedByLast = "$identifiedByLast.";
	}
$identifiedBy= "$identifiedByFirst $identifiedByLast";
$identifiedBy =~ s/^ *//;
$identifiedBy =~ s/ *$//;
$identifiedBy =~ s/  */ /;

if($dateIdentified=~/(\d\d\d\d)\/(\d\d)\/(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; $MM=$2; $DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM="" if $MM eq "00";	#If $MM is 00, set it to blank 
		$DD="" if $DD eq "00";	#If $DD is 00, set it to blank
		$MM=~s/^0//;	#if $MM begins with zero, substitute nothing for the zero
		$DD=~s/^0//;	#if $DD begins with zero, substitute nothing for the zero

		if($YYYY && $MM && $DD){	#If a year, month, and day value are present,
					$JD=julian_day($YYYY, $MM, $DD);	#create the Julian Day ($JD) based on that year, month, and day
					$LJD=$JD;	#Then set the late Julian Day ($LJD) to $JD because there is no range
		}
		elsif($YYYY && $MM){	#elsif there is only a year and month present
			if($MM=12){		#if the month is december...
					$JD=julian_day($YYYY, $MM, 1);		#Set $JD to Dec 1
					$LJD=julian_day($YYYY, $MM, 31);	#Set $LJD to Dec 31
			}
			else{		#else (if it's not december)
					$JD=julian_day($YYYY, $MM, 1);	#Set $JD to the 1st of this month
					$LJD=julian_day($YYYY, $MM+1, 1);	#Set $LJD to the first of the next month...
						$LJD -= 1;						#...Then subtract one day (to get the last dat of this month)
			}
		}
		elsif($YYYY){	#elsif there is only year
					$JD=julian_day($YYYY, 1, 1);	#Set $JD to Jan 1 of that year
					$LJD=julian_day($YYYY, 12, 31);	#Set $LJD to Dec 31 of that year 
		}
	}
	else{	#else (there is no $eventDate)
		$JD=$LJD=""; #Set $JD and $LJD to null
	}
	$ANNO_DATE= $dateIdentified;
	if($LJD > $today_JD){	#If $LJD is later than today's JD (calculated at the top of the script)
		&log("$id ANNO_DATE nulled, $dateIdentified ($LJD)  greater than today ($today_JD)\n");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD="";	#...then null the date
	}
	elsif($YYYY < 1800){	#elsif the year is earlier than 1800
		&log("$id ANNO_DATE nulled, $dateIdentified ($YYYY) less than 1800\n");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD=""; #...then null the date
	}




###########COUNTY###########

	foreach ($county){	#for each $county value
		s/[()]*//g;	#remove all instances of the literal characters "(" and ")"
		s/ +coun?ty.*//i;	#substitute a space followed by the word "county" with "" (case insensitive, with or without the letter n)
		s/ +co\.//i;	#substitute " co." with "" (case insensitive)
		s/ +co$//i;		#substitute " co" with "" (case insensitive)
		s/ *$//;		
		s/^$/Unknown/;	
		s/County Unknown/unknown/;	#"County unknown" => "unknown"
		s/County unk\./unknown/;	#"County unk." => "unknown"
		s/Unplaced/unknown/;	#"Unplaced" => "unknown"
		#print "$_\n";

		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
			$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
			if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
				&skip("$id NON-CA COUNTY? $_");	#run the &skip function, printing the following message to the error log
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
				&log("$id COUNTY $_ -> $v_county");		#call the &log function to print this log message into the change log...
				$_=$v_county;	#and then set $county to whatever the verified $v_county is.
			}


		}
	}
#########COORDS
	foreach ($decimalLatitude,$decimalLongitude){
				s/[^0-9.]//g;
			}
		if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
			if ($decimalLongitude > 0) {
				$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			}	
			if($decimalLatitude > 42.1 || $decimalLatitude < 32.5 || $decimalLongitude > -114 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
				&log("$id coordinates set to null, Outside California: >$decimalLatitude< >$decimalLongitude<");	#print this message in the error log...
				$decimalLatitude =$decimalLongitude="";	#and set $decLat and $decLong to ""
			}
		}

##########NAME
	if($exclude{$genus}){
				&skip("$id Non-vascular plant: $id", @columns);
				next Record;
				}
	if ($variety !~ /^ *$/){ #if $variety does not match the pattern of the whole range (^ to $, or first to last) being zero or more spaces
		$scientificName="$genus $species var. $variety"; 
		}
		elsif ($subspecies !~ /^ *$/){
			$scientificName="$genus $species subsp. $subspecies";
			}
		elsif ($species !~ /^ *$/){
			$scientificName="$genus $species";
			}
		elsif ($genus !~ /^ *$/){
			$scientificName="$genus";
			}
		else {	
			&skip("$id No name: $id", @columns);
			next Record;
			}
	
$scientificName=ucfirst($scientificName);
if($alter{$scientificName}){
				&log ("$id Spelling altered to $alter{$scientificName}: $scientificName");
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
		
###############COLLECTORS
$recordedByFirst=ucfirst($recordedByFirst);
$recordedByLast=ucfirst($recordedByLast);
$otherCollFirst=ucfirst($otherCollFirst);
$otherCollLast=ucfirst($otherCollLast);	
		
if ($recordedByFirst=~/^[A-Z]$/){
	$recordedByFirst = "$recordedByFirst.";
	}
if ($recordedByLast=~/^[A-Z]$/){
	$recordedByLast = "$recordedByLast.";
	}
if ($otherCollFirst=~/^[A-Z]$/){
	$otherCollFirst = "$otherCollFirst.";
	}
if ($otherCollLast=~/^[A-Z]$/){
	$otherCollLast = "$otherCollLast.";
	}

$recordedBy = "$recordedByFirst $recordedByLast";
$recordedBy =~ s/^ *//;
$recordedBy =~ s/ *$//;
$recordedBy =~ s/  */ /;

$otherColl = "$otherCollFirst $otherCollLast";
$otherColl =~ s/^ *//;
$otherColl =~ s/ *$//;
$otherColl =~ s/  */ /;

###############ELEVATION########
#is in meters according to the metadata, and all properly formatted
if ($elevationInMeters =~ /^ *$/){
	$elevation="";
	}
	else {
	$elevation="$elevationInMeters m";
	}



	print OUT <<EOP;
Accession_id: SACT$id
CNUM: 
Name: $scientificName
Date: $eventDate
EJD: $JD
LJD: $LJD
County: $county
Location: $locality
Collector: $recordedBy
Other_coll: $otherColl
Notes: $reproductiveCondition
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Elevation: $elevation
Annotation: $scientificName; $identifiedBy; $ANNO_DATE

EOP
}

sub skip {	#for each skipped item...
	print ERR "skipping: @_\n"	#print into the ERR file "skipping: "+[item from skip array]+new line
}
sub log {	#for each logged change...
	print ERR "logging: @_\n";	#print into the ERR file "logging: "+[item from log array]+new line
}
