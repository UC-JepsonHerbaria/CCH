use lib '/Users/davidbaxter/DATA';
use CCH;
$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array

my %month_hash = &month_hash;


open(OUT, ">UCSC.out") || die;
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $file = '2016-05-03_UCSC_Herbarium_Database.txt';
warn "reading from $file\n";

#The file has problems, because it has both MS and Unix line breaks, both area meaningful
#MS line breaks between records, but Unix line breaks within fields
#To get around this, I did the following in vi:
#:%s/[^^M]$/; /
#:%s/\n//g
#:%s/^M/^M/g
#where "^M" = [Ctrl+V][Ctrl+M]
#Also quotation marks surrounding fields with commas.
#this can and should be automated

open(IN,$file) || die;
while(<IN>){
	chomp;
	&CCH::check_file;
}
close(IN);

open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	@columns=split(/\t/,$_,100);
		unless($#columns==16){
		&log_skip("$#columns bad field number $_");
		next Record;
	}

(
$id,
$scientificName,
$recordedBy,
$recordNumber, #coll num
$verbatimEventDate,
$county,
$City,
$Locality, #concatenate with City for verbatimLocality
$verbatimElevation,
$decimalLatitude,
$decimalLongitude,
$georeferenceSource,
$geodeticDatum,
$ErrorRadius,
$ErrorRadiusUnits,
$Annotation,
#$HybridAnnotation,
$Notes
) = @columns; 


######Accession_ID
#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes; add prefix
$id =~ s/^0*//; 
$id = "UCSC$id";

#Remove duplicates
if($seen{$id}++){
	++$skipped{one};
	warn "Duplicate accession number: $id<\n";
	&log_skip("Duplicate accession number\t$id");
	next Record;
}

##########ScientificName
foreach ($scientificName) {
	s/ subsp\.$//;
	s/ subsp\. \?$//;
	s/ var\.$//;
	s/ var\. \?$//;
	s/ sp\.?$//;
	s/  +/ /;
	s/ *$//;
	s/^ *//;
}

if ($scientificName =~ /^([A-Z][a-z]+) X([a-z-]+)$/){ #(e.g. "Aesculus Xcarnea")
	$scientificName = "$1 X $2";
}	

	$scientificName = &strip_name($scientificName);
	$scientificName = &validate_scientific_name($scientificName, $id);


#############COLLECTOR
if ($recordedBy =~ /^0$/){
	$recordedBy = "Unknown";
	&log_change("Collector recorded as '0', entered as Unknown\t$id");
}


########COLL_NUM
#AK's (Al Keuter's?) Collector numbers are like "AK00-093", which makes the CNUM "00" and the suffix "093"
#but note that AK00-045A parses into AK00-, 045, A, which is what we want
if($recordNumber){
	($CNUM_prefix, $CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);
	#print "1 $prefix\t2 $CNUM\t3 $suffix\n";
}
else{
	$CNUM_prefix=$CNUM=$CNUM_suffix="";
}


#########DATE
#there are tons of ugly dates. This parses the most common formats
#$verbatimEventDate
$date_string = $verbatimEventDate;
foreach ($date_string){ #also "early, mid, late, summer, et al"
	s/-/ /g;
	
	s/\?//;
	s/c\. //;
	s/ca //;
	s/\.//g;
	s/,//g;
}

if ($date_string =~ /([A-Z][a-z]+) (\d\d?) (\d\d\d\d)/){
	$MM = $1;
	$DD = $2;
	$YYYY = $3;
	$DD=~s/^0//;
}
elsif ($date_string =~ /(\d\d?) ([A-Z][a-z]+) (\d\d\d\d)/){
	$DD = $1;
	$MM = $2;
	$YYYY = $3;
	$DD=~s/^0//;
}
elsif ($date_string =~ /(\d\d\d\d) ([A-Z][a-z]+) (\d\d?)/){
	$YYYY = $1;
	$MM = $2;
	$DD = $3;
	$DD=~s/^0//;	
}

elsif ($date_string =~ /([A-Z][a-z]+) (\d\d\d\d)/){
	$MM = $1;
	$YYYY = $2;
	$DD = "";
}
elsif ($date_string =~ /^(\d\d\d\d)$/){
	$YYYY = $1;
	$MM = "";
	$DD = "";
}
elsif ($date_string =~ /[Uu]nknown/){
	$DD = $MM = $YYYY = "";
}
elsif ($date_string =~ /.+/){
	&log_change("date format not recognized; entered as verbatim: $verbatimEventDate\t$id");
	$DD = $MM = $YYYY = "";
}


$MM = &get_month_number($MM, $id, %month_hash);
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);




########COUNTY
#the rest of this required code should be made into a separate subroutine that uses &verify_co
if ($county =~ ""){
	$county = "Unknown";
}

unless ($county=~m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
	$v_county= &verify_co($county);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
	if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
		&log_skip("NON-CA COUNTY? $county\t$id");	#run the &log_skip function, printing the following message to the error log
		++$skipped{one};
		next Record;
	}

	unless($v_county eq $county){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
		&log_change("COUNTY $county -> $v_county\t$id");		#call the &log_change function to print this log message into the change log...
		$county=$v_county;	#and then set $county to whatever the verified $v_county is.
	}
}


########LOCALITY
foreach ($Locality){
	s/  - $//; #they have these weird blank dashes at the end of some localities
}
if ($City && $Locality){
	$verbatimLocality = $Locality; #If they have both, they put the city in with Locality anyway
}
elsif ($City || $Locality){
	$verbatimLocality = "$City$Locality"; #if one or the other, print the one that's there
}
else {
	$verbatimLocality = "";
}


##########ELEVATION
$elevation = $verbatimElevation;
foreach($elevation){
	s/feet/ft/g;
	s/ft/ ft/g;
	s/m/ m/g;
	s/ +/ /g;
	s/,//g;
	s/\.//g;
}

if ($elevation){
	unless ($elevation =~ /^([0-9.-]+) ft$/ || $elevation =~ /^([0-9.-])+ m$/){
		&log_change("Elevation value ($elevation) not recognized as elevation:\t$id");
		$elevation="";
	}
}

########LATITUDE AND LONGITUDE

#most is in the decimalLatitude and decimalLongitude fields already, so validate those
if(($decimalLatitude=~/\d/  && $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	if ($decimalLongitude > 0) {
		$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
	}	
	if($decimalLatitude > 42.1 || $decimalLatitude < 32.5 || $decimalLongitude > -114 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
		&log_change("coordinates set to null, Outside California: >$latitude< >$longitude<\t$id");	#print this message in the error log...
		$decimalLatitude =$decimalLongitude="";	#and set $decLat and $decLong to ""
	}
}


######SOURCE, DATUM, ERROR RADIUS
#$georeferenceSource if fine as is
#$geodeticDatum could use some standardization, but is okay for now

#ER and units should have subroutines too, including conversion to meters
#$ErrorRadius,
#$ErrorRadiusUnits,
foreach ($ErrorRadiusUnits){
	s/\.//;
	s/miles?/mi/;
}


#######ANNOTATION
#Format is too varied to parse out. For this reason, I don't think Annotations can be made into a subroutine
#$Annotation,

############NOTES
#$Notes
#lots of different stuff. Not processing it



####PRINT IT ALL OUT
            print OUT <<EOP;
Accession_id: $id
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Name: $scientificName
Country: USA
State: California
County: $county
Location: $verbatimLocality
Collector: $recordedBy
Other_coll: 
Combined_collector: $recordedBy
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Notes: $Notes
Source: $georeferenceSource
Datum: $geodeticDatum
Elevation: $elevation
Max_error_distance: $ErrorRadius
Max_error_units: $ErrorRadiusUnits
Annotation: $Annotation

EOP

}

close IN;

#foreach($Date_collected){
#s/\? Aug 1981/Aug 1981/;
#s/\? Oct 1978/Oct 1978/;
#s/Late Jan\.? 1979/Jan 1979/;
#s/coll. 1983, pressed 7 Sep 1991/1983/;
#s/mid\.? Feb 1977/Feb 1977/;
#s/Jun 1978\?/Jun 1978/;
#}
