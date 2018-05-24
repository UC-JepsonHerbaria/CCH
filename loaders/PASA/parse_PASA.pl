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
open(OUT,">PASA.out") || die;
open(ERR,">PASA_problems") || die;

#####process the file
#PASA file arrives as an xlsx file
#I opened it in Excel, saved as txt
#Then open in vi, and run the following command
####:%s/[Ctrl+V][Ctrl+M]/[Ctrl+V][Ctrl+M]/g
#also need to run
####:%s/\t"/\t/g
####:%s/"\t/\t/g
#to get rid of pesky quotes that Excel adds to cells containing commas
#I'm sure there's a faster way to do it 

	my $file = 'PASA17JULY2014.txt';
#the file has highlighting, and it doesn't always line up
#approach with caution

open(IN,$file) || die;
Record: while (<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless($#columns==31){
		print ERR "$#columns bad field number$_\n"
	}

	($acc_proposed, #e.g. PASA_0335
	$seq_number, #e.g. 335
	$order_id,
	$shelf_id,
	$major_group,
	$family,
	$genus,
	$species,
	$infra_rank,
	$infra_epithet,
	$species_authority,
	$common_name,
	$locality,
	$county,
	$state,
	$country,
	$habitat,
	$elev_value,
	$elev_units,
	$date_string, #sometimes blank when other date fields populated
	$year, #always four digits
	$month, #not zero-filled
	$day, #not zero-filled
	$collector,
	$coll_num, #incl prefix Y, slashes, question marks for unknown digits, and a name which is probably an other_coll
	$other_coll,
	$anno_note,
	$other_number, #or note
	$another_number,
	$another_anno,
	$blank_column,
	$something_else #either "yes" or "-1"
	)=@columns;


####ACCESSION ID#####
#check for nulls
if ($acc_proposed =~ /^ *$/ || $seq_number =~ /^ *$/){
	&skip("One or both accession columns is blank $_");
	++$skipped{one};
	next Record;
		}

#format both columns, make sure they match, set to $id
foreach ($acc_proposed){
	s/_0+//;
	s/_//;
}
foreach ($seq_number){
	$seq_number="PASA$seq_number";
}

if ($acc_proposed eq $seq_number){
	$id = $acc_proposed;
}
else {
	warn "acc_proposed and seq_number do not match: $acc_proposed $seq_number\n";
	&skip("check accession id columns: $_");
	$id = "";
}

#Remove duplicates
	if($seen{$id}++){
		++$skipped{one};
		warn "Duplicate number: $fields[-3]<\n";
		print ERR<<EOP;

Duplicate accession number, skipped: $fields[-3]
EOP
		next;
	}


####Scientific Name###

#sometimes they have a second genus in brackets, which I'm ignoring
foreach($genus){
	s/\(.*\)//;
}


if ($exclude{$genus}){
	&skip("Non-vascular plant: $genus $id", @columns);
	next Record;
}

if ($genus && $species && $infra_epithet && $infra_rank){
	$scientificName = "$genus $species $infra_rank $infra_epithet";
}
elsif ($genus && $species){
	$scientificName = "$genus $species";
}
elsif ($genus){
	$scientificName = "$genus";
}
else {
	&skip("No scientific name", @columns);
	next Record;
}

foreach ($scientificName){
	s/ var / var. /g;
	s/\?//g;
	s/ sp\. *//g;
	s/^ *//g;
	s/ *$//g;
	s/  */ /g;
	s/\x97/o/g;
}

$scientificName=ucfirst(lc($scientificName));

if ($scientificName =~ /(.*) or (.*)/){
	$oldname=$scientificName;
	$scientificName=$1;
	&log("$oldname entered as $scientificName ($id)");
}

if ($scientificName =~ /(.*) and (.*)/){
	$oldname=$scientificName;
	$scientificName=$1;
	&log("$oldname entered as $scientificName ($id)");
}


#$scientificName=~s/^ *//;

if($alter{$scientificName}){
				&log ("Spelling altered to $alter{$scientificName}: $scientificName ($id)");
				$scientificName=$alter{$scientificName};
			}

			unless($TID{$scientificName}){
				$oldname=$scientificName;
				if($scientificName=~s/\(.*\)//){
					if($TID{$scientificName}){
						&log("$id Not yet entered into SMASCH taxon name table: $oldname entered as $scientificName");
					}
					else{
						&skip("$id Name not yet entered into SMASCH taxon name table: $oldname skipped");
						++$badname{"$oldname"};
						next Record;
					}
				}
				elsif($scientificName=~s/subsp\./var./){
					if($TID{$scientificName}){
						&log("$id Not yet entered into SMASCH taxon name table: $oldname entered as $scientificName");
					}
					else{
						&skip("$id Name not yet entered into SMASCH taxon name table: $oldname skipped");
						++$badname{"$oldname"};
						next Record;
					}
				}
				elsif($scientificName=~s/var\./subsp./){
					if($TID{$scientificName}){
						&log("$id Not yet entered into SMASCH taxon name table: $oldname entered as $scientificName");
					}
					else{
						&skip("$id Name not yet entered into SMASCH taxon name table: $oldname skipped");
						++$badname{"$oldname"};
						next Record;
					}
				}
				else{
					&skip("$id Not yet entered into SMASCH taxon name table: $oldname skipped");
					++$badname{"$oldname"};
					next Record;
				}
			}

########LOCALITY
#$locality is in one field, requires no processing


########STATE, COUNTRY
unless ($state =~ /^California$/) {
	&skip("Not in California: State=$state, County=$county ($id)");
	++$skipped{one};
	next Record;
	}
#State is always California
#Country is sometimes Mexico
#Skip Mexico ones first to detect weird counties that are marked as CA


########COUNTY
	foreach ($county){
	s/^ *//g;
	s/ *$//g;
	s/  */ /g;

		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
			$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
			if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
				&skip("NON-CA COUNTY? $_ ($id)");	#run the &skip function, printing the following message to the error log
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
				&log("COUNTY $_ -> $v_county ($id)");		#call the &log function to print this log message into the change log...
				$_=$v_county;	#and then set $county to whatever the verified $v_county is.
			}
		}
	}




#########HABITAT
#$habitat is a single field. No processing required


##########ELEVATION
foreach ($elev_value){
	s/,//g;
}	
foreach ($elev_units){
	s/ft\./ft/;
}

if ($elev_value =~ /sea level/){
	$elevation = "0 m";
}
elsif ($elev_value && $elev_units){
	$elevation = "$elev_value $elev_units";
}
elsif ($elev_value){
	$elevation = "$elev_value";
}
else {
	$elevation = "";
}


##########COLLECTION DATE##########
#generate date_string from YMD if date string is blank
unless ($date_string){
	if ($year && $month && $day) {
		$date_string = "$year-$month-$day";
	}
	elsif ($year && $month) {
		$date_string = "$year-$month";
	}
	elsif ($year) {
		$date_string = "$year";
	}
	else {
		$date_string = "";
	}	
}

#year month and day do not have leading zeroes
#and are always numerical
#but just in case
foreach ($year) {
	s/^0//;
	s/[^\d]//g;
}
foreach ($month) {
	s/^0//;
	s/[^\d]//g;
}
foreach ($day) {
	s/^0//;
	s/[^\d]//g;
}
 
#generate julian_day
if ($year && $month && $day){
		$JD=julian_day($year, $month, $day);
		$LJD=$JD;
}
elsif($year && $month){	
	if($month==12){	
		$JD=julian_day($year, $month, 1);	
		$LJD=julian_day($year, $month, 31);
	}
	else {
		$JD=julian_day($year, $month, 1);
		$LJD=julian_day($year, $month+1, 1);
		$LJD -= 1;
	}
}
elsif ($year) {
	$JD=julian_day($year, 1, 1);
	$LJD=julian_day($year, 12, 31);
}
else{
		$JD=$LJD="";
}

#check that collection date is somewhere between 1800 and today
	if ($LJD > $today_JD){
		&log("DATE nulled, $date_string ($LJD)  is later than today's date ($today_JD): $id");
		$JD=$LJD="";
	}
	elsif($year < 1800){	#elsif the year is earlier than 1800
		&log("DATE nulled, $date_string ($year) earlier than 1800");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD=""; #...then null the date
	}
#should really test my outputs before going further

#############COLLECTORS#########
#collector is "unknown" if blank
if ($collector =~ "") {
	$collector = "unknown";
}
else {
	$collector = $collector;
}

if (length($other_coll) > 250){
	&log("value in other_collector column suspiciously large: $id");
	$other_coll = "";
}


##############CNUM###########
if ($coll_num eq "None"){
	$CNUM_PREFIX="";
	$CNUM= "";
	$CNUM_SUFFIX="";
}
elsif ($coll_num =~ /\?/){
	$CNUM_PREFIX = $coll_num;
	$CNUM = "";
	$CNUM_SUFFIX="";
}
elsif ($coll_num =~ /([\d]+)\/([\d]+)/){
	$CNUM_PREFIX="";
	$CNUM = $1;
	$CNUM_SUFFIX = "/$2";
}
elsif ($coll_num =~ /^(Y)([\d]+)/){
	$CNUM_PREFIX = $1;
	$CNUM = $2;
	$CNUM_SUFFIX="";
}
elsif ($coll_num =~ /^([^0-9]+)$/){
	warn "collector number non-numeric: $coll_num $id\n";
	&log("collector number non-numeric for $id. Check value: $coll_num");
	$CNUM_PREFIX = "";
	$CNUM = "";
	$CNUM_SUFFIX = "";
}
elsif ($coll_num =~ /^([\d]+)$/){
	$CNUM_PREFIX = "";
	$CNUM = "$1";
	$CNUM_SUFFIX = "";
}	
elsif ($coll_num){
	$CNUM_PREFIX = $coll_num;
	$CNUM = "";
	$CNUM_SUFFIX = "";
}
else {
	$CNUM_PREFIX = "";
	$CNUM = "";
	$CNUM_SUFFIX = "";
}


####NOTES#####
#anno_note is fine as is

####REMAINING FIELDS#####
####Ignored for now
#	$other_number, #or note
#	$another_number,
#	$another_anno,
#	$blank_column,
#	$something_else #either "yes" or "-1"




print OUT <<EOP;
Accession_id: $id
Name: $scientificName
Collector: $collector
Date: $date_string
EJD: $JD
LJD: $LJD
CNUM: $CNUM
CNUM_prefix: $CNUM_PREFIX
CNUM_suffix: $CNUM_SUFFIX
Country: USA
State: CA
County: $county
Location: $locality
Elevation: $elevation
Other_coll: $other_coll
Combined_coll:
Decimal_latitude:
Decimal_longitude:
Lat_long_ref_source:
Datum:
Max_error_distance:
Max_error_units:
Habitat: $habitat
Notes: $anno_note

EOP
}

close(IN);
close(OUT);
close(ERR);



sub skip {	#for each skipped item...
	print ERR "skipping: @_\n"	#print into the ERR file "skipping: "+[item from skip array]+new line
}
sub log {	#for each logged change...
	print ERR "logging: @_\n";	#print into the ERR file "logging: "+[item from log array]+new line
}



