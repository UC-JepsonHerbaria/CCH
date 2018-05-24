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
open(OUT,">SJSU.out") || die;
open(ERR,">SJSU_log") || die;

##meters to feet conversion
#$meters_to_feet="3.2808";


#####process the file
#SJSU sends a tab-delimited text file
#That has "^M" line breaks instead of newlines
#open the file in vi then do ":%s/[Ctrl+V][Ctrl+M]/[Ctrl+V][Ctrl+M]/g"
#before running this script

#	my $file = 'SJSU_20140714.tab';
#	my $file = 'SJSU_Sharsmith_29jan2015_UTF8.txt';
#	my $file = 'SJSU_Sharsmith_11sep2015_UTF8.txt';
#	my $file = 'SJSU_Sharsmith_15sep2015_UTF8.csv';
	my $file = 'sjsu_cch_export_17mar2016.txt';

open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless($#columns==16){
		print ERR "$#columns bad field number $_\n";
	}
	
($eventDate,
$recordNumber,
$recordedBy,
$coord_source,
$county,
$cultivated,
$datum,
$scientificName,
$elevation,
$error_radius,
$habitat,
$latitude,
$locality,
$longitude,
$id,
$trs,
$voucher_info
)=@columns;

#ACCESSION_ID#
#check for nulls
if ($id=~/^ *$/){
	&skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
		}

#remove spaces
foreach($id){
	s/ //g;
	}

#Remove duplicates
	if($seen{$id}++){
		++$skipped{one};
		warn "Duplicate number: $id<\n";
		print ERR<<EOP;
Duplicate accession number, skipped: $id
EOP
		next;
	}
	

#SJSU does not deliver any records from cultivation, so this routine is unnecessary
##################Exclude cult
# if locality starts with "cultivated" etc., skip the record. There are many other localities describing "next to cultivated field" etc.
#	if($locality=~/^(Cultivated|cultivated|Small cultivated|Tree cultivated)/){
#				&skip("$id Specimen from cultivation $_\n");	#&skip is a function that skips a record and writes to the error log
#				++$skipped{one};
#				next Record;
#			}





#############CNUM##################
#CNUM is used for sorting, with PREFIX and SUFFIX displayed accordingly
 		if($recordNumber=~/^(\d+)$/){	#if recordNumber is a digit...
                        $CNUM=$1; $PREFIX=$SUFFIX="";	#CNUM is just that number
                }
                elsif($recordNumber=~/^(\d+)-(\d+)$/){	#if two numbers separated by a dash...
                        $CNUM=$1; $SUFFIX="-$2";		#Add the number before the dash (plus the dash) as a prefix
                }
                elsif($recordNumber=~/^(\d+)-(.+)$/){
                		$CNUM=$1; $SUFFIX="-$2";
                }
                elsif($recordNumber=~/^(\d+)\.(.+)$/){
                		$CNUM=$1; $SUFFIX="\.$2";
                }
                 elsif($recordNumber=~/^(\d+),(.+)$/){
                		$CNUM=$1; $SUFFIX=",$2";
                }
                elsif($recordNumber=~/^(\d+) (\(.+)$/){ #e.g. "181 (dupl)"
                		$CNUM=$1;						# we don't want to show "dupl" CNUM 
                }
                elsif($recordNumber=~/^(\D+)(\d+)$/){	#if a non-number followed by a number
                        $PREFIX=$1; $CNUM=$2;			#non-number added as a prefix
                }
                else{	#else show the number as a SUFFIX, but CNUM is blank so it doesn't sort by the value displayed
                        $SUFFIX=$recordNumber;
                        $CNUM="";
                }
                if($CNUM || $PREFIX || $SUFFIX){	#if there is any of these values, set recordedBy to Anonymous if recordedBy is blank 
                        $recordedBy= "Anonymous" unless $recordedBy;
                }

###############COLLECTORS
foreach($recordedBy){
	s/, Jr/ Jr/; #"J.B. Willis, Jr" throws off my comma separation
}

$recordedBy=ucfirst($recordedBy);
if ($recordedBy=~/Leguminosae/){
&log("collector name is a plant name: $recordedBy\t$id");
	$recordedBy="";
}
elsif ($recordedBy=~/([A-Z]\.[A-Z]\.) & ([A-Z]\.[A-Z]\.) ([A-Za-z]+)/){ #e.g. "F.H. & A.M. Wendell"
	$recordedBy="$1 $3";
	$otherColl="$2 $3";
}
elsif ($recordedBy=~/([A-Z]\.[A-Z]\.) & ([A-Z]\.) ([A-Za-z]+)/){ #e.g. "J.H. & F. Rondeau"
	$recordedBy="$1 $3";
	$otherColl="$2 $3";
}
elsif ($recordedBy=~/([A-Z]\.) & ([A-Z]\.) ([A-Za-z]+)/){ #e.g. "R. & F. Wells"
	$recordedBy="$1 $3";
	$otherColl="$2 $3";
}
elsif ($recordedBy=~/(.*), & (.*)/){
	$recordedBy=$1;
	$otherColl=$2;
}
elsif ($recordedBy=~/(.*), (.*)/){
	$recordedBy=$1;
	$otherColl=$2;
}
elsif ($recordedBy=~/(.*) & (.*)/){
	$recordedBy=$1;
	$otherColl=$2;
}
else{
	$otherColl="";
}


$recordedBy =~ s/^ *//;
$recordedBy =~ s/ *$//;
$recordedBy =~ s/  */ /;

$otherColl =~ s/^ *//;
$otherColl =~ s/ *$//;
$otherColl =~ s/  */ /;

##########COLLECTION DATE##########
if ($eventDate=~/(\d\d?)\/(\d\d?)\/(\d\d\d\d)/){
	$MM=$1;
	$DD=$2;
	$YYYY=$3;
	$DD=~s/^0//;
	$MM=~s/^0//;
}

elsif($eventDate=~/(\d\d?)\/(\d\d\d\d)/){
	$MM=$1;
	$YYYY=$2;
	$MM=~s/^0//;
}

elsif ($eventDate=~/.+/){
&log("date format not recognized: $eventDate\t$id");
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

	$DATE=$eventDate;
	if ($LJD > $today_JD){	#If $LJD is later than today's JD (calculated at the top of the script)
		&log("DATE nulled, $eventDate ($LJD)  is later than today's date ($today_JD)\t$id");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD="";	#...then null the date
	}
	elsif($YYYY < 1800){	#elsif the year is earlier than 1800
		&log("DATE nulled, $eventDate ($YYYY) earlier than 1800\t$id");	#Add this error message to the log, then start a new line on the log...
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
		s/Trinity NW/Trinity/; #I couldn't get this particular substitution to work in &verify_co in CCH.pm, so I did it here
		
		#print "$_\n";

		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
			$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
			if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
				&skip("NON-CA COUNTY? $_\t$id");	#run the &skip function, printing the following message to the error log
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
				&log("COUNTY $_ -> $v_county\t$id");		#call the &log function to print this log message into the change log...
				$_=$v_county;	#and then set $county to whatever the verified $v_county is.
			}


		}
	}


########Cultivation Status#########
if ($cultivated=~/Yes/){
	$cultivated="yes";
}
else{
	$cultivated="";
	}


#########COORDS AND DATUM##########

#no problems with datum now, but sanity check for the future
$datum=~s/ //g; #remove all spaces
unless ($datum=~m/(NAD83|NAD27|WGS84|^$)/){
	&log("check datum format: $datum\t$id");
}

#lats and longs are in perfect DD format, except a few that are preceded with N or W
foreach ($latitude){
	s/N//;
	s/^ *//;
}
foreach ($longitude){
	s/W/-/;
	s/^- */-/;
}

#There's one pesky record formatted like this
if ($latitude=~/(\d+)º (\d+)'/){
		$lat_sum=$1+($2/60);
		$latitude=$lat_sum;
	}
if ($longitude=~/- (\d+)º (\d+)'/){
		$long_sum=($1+($2/60));
		$longitude="-$long_sum";
	}

		if(($latitude=~/\d/  || $longitude=~/\d/)){ #If decLat and decLong are both digits
			if ($longitude > 0) {
				$longitude="-$longitude";	#make decLong = -decLong if it is greater than zero
			}	
			if($latitude > 42.1 || $latitude < 30.0 || $longitude > -114 || $longitude < -124.5){ #if the coordinate range is not within the rough box of california...
				&log("coordinates set to null, Outside California: >$latitude< >$longitude<\t$id");	#print this message in the error log...
				$latitude =$longitude="";	#and set $decLat and $decLong to ""
			}
		}

#Check for future errors
unless (($latitude=~/[0-9\.]*/ | $longitude=~/[0-9\.-]*/)){ #if lat or long match a non-digit character
	&log("check coord format: $latitude $longitude\t$id");
}

######ERROR RADIUS#############
#Always in meters
#if error radius contains anything besides digits and periods, log a warning
unless ($error_radius=~/[\d\.]*/){
	&log("check ER format: $error_radius\t$id");
	}

######COORD SOURCE#############
#no need to process $coord_source at this time

##########NAME
$scientificName=ucfirst(lc($scientificName)); #needed because of poorly formatted hybrid formulas

foreach ($scientificName){
	s/ sp\.$//; #remove " sp." when species unknown
	s/ ssp / subsp. /g;
	s/ ssp\. / subsp. /g;
	s/ nothossp\. / notho subsp. /g;
	s/ var / var. /g;
	s/×/ X /g;
	s/ x / X /g;
	s/^ *//g;
	s/ *$//g;
	s/  / /g;
	s/\?//g;
	
	s/ a\. gray$//;
	s/ vasey$//;
	}




unless($scientificName){	#if no value, skip the line
				&skip("No name: $id", @columns);
				next Record;
		}

($genus=$scientificName)=~s/ .*//;	#copy the first word of $sciName into $genus
		if($exclude{$genus}){
				&skip("Non-vascular plant: $id", @columns);
				next Record;
		}

if ($scientificName=~/(.*) and (.*)/){ #e.g. "Potentilla pseudosericea and Potentilla pensylvanica"
	&log ("contains two names: $scientificName altered to $1\t$id");
	$scientificName=$1;
}

if ($scientificName=~/(.*) - (.*)/){ #e.g. "Ericameria nauseosa - need to verify var."
	&log ("note in name field moved to notes. $scientificName altered to $1\t$id");
	$scientificName=$1;
	$name_note=$2;
}
elsif ($scientificName=~/(.*) (need to confirm ssp\. ?)/){ #e.g."Chloropyron molle need to confirm ssp."
	&log ("note in name field moved to notes. $scientificName altered to $1\t$id");
	$scientificName=$1;
	$name_note=$2;
}
else {
	$name_note="";
}

if ($scientificName=~s/ notho / /){ #e.g. "Elymus triticoides notho subsp. multiflorus"
	&log ("'notho' removed from scientific name\t$id");
}

#dealing with hybrid formulas
if ($scientificName=~/([A-Z][a-z-]+) ([a-z-]+) X ([a-z-]+) ([a-z-]+)/){ #e.g. Balsamorhiza hookeri X balsamorhiza sagittata
		$secondGenus = ucfirst(lc($3));
		$hybridFormula="$1 $2 x $secondGenus $4";
		$scientificName="$1 $2";
	&log("Hybrid: $hybridFormula name entered as $scientificName; Full hybrid formula recorded in annotation field\t$id");
}
elsif ($scientificName=~/([A-Z][a-z-]+) ([a-z-]+) X ([a-z-]+)/){ #e.g. Monardella follettii X sheltonii
	$hybridFormula="$1 $2 X $3";
	$scientificName="$1 $2";
	&log("Hybrid: $hybridFormula name entered as $scientificName; Full hybrid formula recorded in annotation field\t$id");
}
else {
	$hybridFormula = ""; 
}
	

if($alter{$scientificName}){
				&log ("Spelling altered to $alter{$scientificName}: $scientificName\t$id");
				$scientificName=$alter{$scientificName};
			}
			
			unless($TID{$scientificName}){
				$on=$scientificName;
				if($scientificName=~s/subsp\./var./){
					if($TID{$scientificName}){
						&log("subsp. changed to var.: $on entered as $scientificName\t$id");
					}
					else{
						&skip("Not yet entered into SMASCH taxon name table: $on skipped\t$id");
						++$badname{"$on"};
						next Record;
					}
				}
				elsif($scientificName=~s/var\./subsp./){
					if($TID{$scientificName}){
						&log("var. changed to subsp.: $on entered as $scientificName\t$id");
					}
					else{
						&skip("Not yet entered into SMASCH taxon name table: $on skipped\t$id");
						++$badname{"$on"};
						next Record;
					}
				}			
				else{
					&skip("Not yet entered into SMASCH taxon name table: $on skipped\t$id");
					++$badname{"$on"};
					next Record;
				}
			}


###############ELEVATION########
foreach($elevation){
	s/ft/ ft/g;
	s/m/ m/g;
	s/ - /-/g;
	s/  / /g;
}


if ($elevation=~"#"){
	&log("Elevation value ($elevation) not recognized as elevation\t$id");
	$elevation="";
}

###########HABITAT#########
#habitats are in good condition, but contain associated species is many different configurations
#going to leave associates in habitat, as is done in many UCJEPS records
foreach ($habitat){
	s/^ *//g;
	s/ *$//g;
	s/  / /g;
}



##########LOCALITY#########
#Locality is all in one field and seems to have no problems, besides some strange characters
foreach($locality){
	s/ß/S/g;
	s/ñ/n/g;
	s/é/e/g;
	
	s/^ *//g;
	s/ *$//g;
	s/  / /g;
	}

##############VOUCHER INFORMATION##############
#The contents of this field is varied: macromorphology incl. color, common names, abundance. associated species
#putting it all in notes, and subbing some weird characters
foreach ($voucher_info){
	s/^ *//g;
	s/ *$//g;
	s/  / /g;
	
	s/^\.$//g;
	s/45°-60°/45-60 degrees/; #(that's the only form the degrees sign shows up in, so I'm kludging it.
}

if ($voucher_info=~m/^[0-9\.]+$/){ #there are some decimal number values that don't make sense
	&log("voucher information does not compute: $voucher_info\t$id");
	$voucher_info="";
}

#concatenate $voucher_info with $name_note
if ($voucher_info && $name_note){
	$notes="$voucher_info; $name_note";
}
elsif ($voucher_info){
	$notes=$voucher_info;
}
elsif ($name_note){
	$notes=$name_note;
}
else {
	$notes="";
}


	print OUT <<EOP;
Accession_id: $id
CNUM_prefix: $PREFIX
CNUM: $CNUM
CNUM_suffix: $SUFFIX
Name: $scientificName
Date: $eventDate
EJD: $JD
LJD: $LJD
Country: USA
State: California
County: $county
Location: $locality
T/R/Section: $trs
Collector: $recordedBy
Other_coll: $otherColl
Habitat: $habitat
Notes: $notes
Decimal_latitude: $latitude
Decimal_longitude: $longitude
Source: $coord_source
Datum: $datum
Max_error_distance: $error_radius
Elevation: $elevation
Annotation: $hybridFormula

EOP
}

sub skip {	#for each skipped item...
	print ERR "skipping: @_\n"	#print into the ERR file "skipping: "+[item from skip array]+new line
}
sub log {	#for each logged change...
	print ERR "logging: @_\n";	#print into the ERR file "logging: "+[item from log array]+new line
}