#useful one liners for debugging:
#perl -lne '$a++ if /Accession_id: CAS-BOT-BC\d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id: CAS\d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id: DS\d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id:/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Decimal_latitude: \d+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Cultivated: P/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Cultivated: [^P]+/; END {print $a+0}' CAS_out.txt
#perl -lne '$a++ if /Accession_id: CAS\d+/; END {print $a+0}' CAS_out.txt


#CAS input has 3 date fields: start date, end date, verbatim date
#apparently the verbatim date is not the most accurate depiction of the date
#This script put the start date into EJD and the end date into LJD and the verbatim date into date.
#This leads to dates apparently sorting out of order when JD and verbatimDate don't agree
# 536  iconv -f utf-16 -t utf-8 *export* >CAS_utf8.tab
print "fix type variables in this script\n";

use Geo::Coordinates::UTM;
use strict;
#use warnings;
use Data::GUID;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
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
my $count_record;
my $GUID;
my %GUID_old;
my %GUID;
my $old_AID;
my $barcode;


open(OUT, ">YOSE_out.txt") || die;

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


my $file = 'FY2014_CCH_data_MOD.txt';	#name on conjoined file produced by merge_CAS.pl
open (IN, $file) or die $!;
Record: while(<IN>){
	chomp;

	$line_store=$_;
	++$count;		

#fix some data quality and formatting problems that make import of fields of certain records problematic

	my $file = 'data_file/FY2014_CCH_data_test.txt';

open(IN,$file) || die;
##############################
#Watch out for field parsing issues
#the tabbifying as done immediately below seems to work well
#but opening the file in Excel/Google Refine, got confused by commas
##############################

Record: while(<IN>){
	s/^"//;
	s/"$//;
	s/","/\t/g; #in 2014, they gave it as comma-separated instead of tab-separated
	#although this isn't working perfectly right now
	chomp;
	@columns=split(/\t/,$_,100);
	unless($#columns==21){
		print ERR "$#columns bad field number $_\n";
	}

foreach (@columns){
	s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Not ?[pP]rovided|Not ?[rR]ecorded) *$//;
}

($catalog_number,
$accession_number,
$Obj_Science,
$Collector,
$coll_date,
$coll_number,
$other_number,
$identified_by,
$id_date,
$locality,
$county,
$state,
$lat_long,
$UTM_Z_E_N,
$habitat1,
$habitat_comm, #with these two, both go into habitat. If both present, do "$habitat1, $habitat_comm"
$elevation,
$waterbody, #ignoring because barely and improperly used
$slope,		#not loading
$aspect, #watch out for messed up degree signs, or worse, "DEGREES", #not loading
$associated_species,
$type_specimen)=@columns;




####Accession Number#####
if ($catalog_number=~/^ *$/){
	&skip("Record with no catalog number $_");
	++$skipped{one};
	next Record;
		}

#Remove duplicates
	if($seen{$catalog_number}++){
		++$skipped{one};
		warn "Duplicate number: $catalog_number<\n";
		print ERR<<EOP;
Duplicate accession number, skipped: $catalog_number
EOP
		next;
	}
$catalog_number=~s/ +//;
$catalog_number=~s/^/YM-/;



#####SCIENTIFIC NAME############
	$name= $Obj_Science;
	@name_fields=split(/ ?__/,$name);
	$name_fields[0]= ucfirst(lc($name_fields[0]));
	$name_fields[2]= lc($name_fields[2]);
	$name_fields[8]= lc($name_fields[8]);
	$name_fields[8]=~s/ .*//;
	$name_fields[5]= lc($name_fields[5]);
	$name_fields[5]=~s/ .*//;
	if($name_fields[8]=~/[a-z]/i){
		$name= "$name_fields[0] $name_fields[2] var. $name_fields[8]";
	}
	elsif($name_fields[5]=~/[a-z]/i){
		$name= "$name_fields[0] $name_fields[2] subsp. $name_fields[5]";
	}
	elsif($name_fields[2]=~/[a-z]/i){
		$name= "$name_fields[0] $name_fields[2]";
	}
	elsif($name_fields[0]=~/[a-z]/i){
#print "$Obj_Science\n";
		$name= "$name_fields[0]";
	}
	else{
		$name="";
	}
$name=~s/  */ /g;
$name=~s/ sp\.//;
$name=~s/ $//;

			if($name=~/([A-Z][a-z-]+ [a-z-]+) [◊×xX] /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/([A-Z][a-z-]+ [a-z-]+ (var\.|subsp\.) [a-z-]+) [◊×xX] /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/ cf\./){
				$hybrid_annotation = $name;
				$name=~s/ cf\.//;
				warn "$name from $hybrid_annotation\n";
			}
			else{
				$hybrid_annotation="";
			}
	if($alter{$name}){
		print ERR <<EOP;
Spelling altered to $alter{$name}: $name 
EOP
		$name=$alter{$name};
	}
	if($alter{$name}){
		print ERR <<EOP;

Spelling altered further to $alter{$name}: $name 
EOP
		$name=$alter{$name};
	}
	if($name=~/[a-z]+ [a-z]+ +[Xx] +[a-z]+/){
				print ERR <<EOP;
Can't deal with unnamed hybrids yet: $name skipped $catalog_number
EOP
		++$needed_name{$name};
		next Record;
	}
	$name=~s/ssp\./subsp./;
	unless($TID{$name}){
		$on=$name;
		if($name=~s/subsp\./var./){
			if($TID{$name}){
				print ERR <<EOP;
Subspecies entered as variety: $on entered as $name
EOP
			}
			else{
				print ERR <<EOP;
Not yet entered into SMASCH taxon name table: $on skipped $Label_ID_no
EOP
		++$needed_name{$on};
		next Record;
		}
	}
	elsif($name=~s/var\./subsp./){
		if($TID{$name}){
			print ERR <<EOP;
Variety entered as subspecies: $on entered as $name
EOP
		}
		else{
			print ERR <<EOP;
Not yet entered into SMASCH taxon name table: $on skipped $Label_ID_no
EOP
		++$needed_name{$on};
next Record;
		}
	}
	else{
		print ERR <<EOP;
Not yet entered into SMASCH taxon name table: $name skipped $Label_ID_no
EOP
		++$needed_name{$on};
	next Record;
	}
}
else{
}
#print "$name\n\n";
			unless($name=~/[A-Za-z]/){
		print ERR<<EOP;
No taxon name: $catalog_number
EOP
		next Record;
}



############COLLECTORS############
	if($Collector){
		$Collector=~s/^ +//;
		$Collector=~s/\// -- /g;
		$Collector=~s/\.(AND|and|&) /. -- /g;
		$Collector=~s/ (AND|and|&) / -- /g;
		$Collector=~s/ ?- ?- ?/\n/g;
		@collectors=split(/\n+/,$Collector);
		foreach(@collectors){
			s/([A-Z])([A-Z]+)/$1\L$2/g;
			s/(.*), *(.*)/$2 $1/;
s/Moncrief, V./V. Moncrief/;
s/Sharsmith, Carl W\.?/Carl W. Sharsmith/;
s/Carl W. Sharxmith/Carl W. Sharsmith/;
s/Carlk W. Sharsmith/Carl W. Sharsmith/;
s/A. Hambecker/A. Hawbecker/;
s/B.O. Schrieber/B.O. Schreiber/;
s/B.O. Shreiber/B.O. Schreiber/;
s/Beryl O Schreiber/Beryl O. Schreiber/;
s/E. Micahel/E. Michael/;
s/E. Micheal/E. Michael/;
s/E. Michaels/E. Michael/;
s/Enid Mciahel/Enid Michael/;
s/Enid Mcihael/Enid Michael/;
s/Wnid Michael/Enid Michael/;
s/H. Willilams/H. Williams/;
s/H. Willilams/H. Williams/;
s/Michael Enid/Enid Michael/;
s/Schreiber Beryl O./Beryl O. Schreiber/;
s/V. Moncreif/V. Moncrief/;
s/W. Augusine/W. Augustine/;
s/W.B. Agustine/W.B. Augustine/;
s/W.B. Augsutine/W.B. Augustine/;
s/W.B. Ausgustine/W.B. Augustine/;
		}
		$Combined_Collectors=join(", ", @collectors);
		$Collector=$collectors[0];
	}
else{
		@collectors=();
		$Combined_Collectors="";
}


##############CollectionDate############
#note that this script does not convert to julian days
%monthno=
("Jan","1",
"Feb","2",
"Mar","3",
"Apr","4",
"May","5",
"Jun","6",
"Jul","7",
"Aug","8",
"Sep","9",
"Oct","10",
"Nov","11",
"Dec","12",
);

if($coll_date){
	$coll_date = ucfirst(lc($coll_date));
	$coll_date=~s/^([A-Z][a-z][a-z])-(\d\d)/$monthno{$1}\/19$2/;
	$coll_date=~s/^([A-Z][a-z][a-z])(\d\d\d\d)/$monthno{$1}\/$2/;
	$coll_date=~s/^0//;
	$coll_date=~s/\/ /\//;
	$coll_date=~s/^-+//;
	unless($coll_date =~m!^(\d+/\d+/[21][089]\d\d|[12][098]\d\d-\d\d\d\d|[12]\d\d\d|\d+/[12][890]\d\d)$!){
		print ERR "Bad date nulled $coll_date --> @columns\n";
		$coll_date="";
	}
}


############COLL NUMBER##########
	if($coll_number=~m/(.*)-(\d+)([A-Za-z-])*/){
		$CNUM=$2; $CNUM_prefix="$1-"; $CNUM_suffix=$3;
	}
	elsif($coll_number=~m/^(\d+)([A-Za-z-])*/){
		$CNUM=$1; $CNUM_prefix=""; $CNUM_suffix=$2;
	}
	elsif($coll_number=~/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Not ?[pP]rovided|Not ?[rR]ecorded)/){
		$CNUM=""; $CNUM_prefix=""; $CNUM_suffix="";
	}
	else{
		$CNUM=""; $CNUM_prefix="$coll_number"; $CNUM_suffix="";
	}



#######COUNTY/STATE###############
if ($county eq "YOSE" && $state eq "Tuolumne"){
	$county = "Tuolumne";
	$state = "CA";
}

unless ($state =~ m/^CA$|^$/){
	&skip("State not California: $state, $catalog_number");
	++$skipped{one};
	next Record;
}

foreach($county){
		s!^(TUOL-MARIPOSA|TUOL/MONO/MARI.|TUOLUAMNE|TUOLULMNE|TUOLUME|TUOLUMNE|TUOLUMNE \(\?\)|TUOLUMNE \(MONO\?|TUOLUMNE\(\?\)|TUOLUMNE-MARI\.|TUOLUMNE-MONO|TUOLUMNE/MADERA|TUOLUMNE/MARI\.|TUOLUMNE/MONO)$!Tuolumne!;
		s!^(MADEDRA|MADERA \(\?\)|MADERA/MONO|MADERA/TUOL|MADERA/TUOL.|MADERA/TUOLUMNE|MADERA)$!Madera!;
		s!^(MARIOSA|MARIPOSA/MADERA|MARIPOSA/TUOL.|MARIPOSAA|MARIPOSA)$!Mariposa!;
		s!^MERCED$!Merced!;
		s!^(MONO|MONO \(\?\)|MONO-TUOLUMNE|MONO/TUOLUMNE)$!Mono!;
		s!POHONO TRAIL!Unknown!;
		s!SANTA BARBARA!Santa Barbara!;
		s!SHEET NO. 4663, HERB. ACCESS. NO.  4559!Unknown!;
		s!SISKIYOU!Siskiyou!;
		s!NOT RECORDED!Unknown!;

		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
			$v_county= &verify_co($_);
			if($v_county=~/SKIP/){		
				&skip("$id NON-CA COUNTY? $_");
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){
				&log("$id COUNTY $_ -> $v_county");	
				$_=$v_county;
			}
		}
}



##########COORDS################
#LAT LONG, then if no lat long, convert UTM
if ($lat_long){
	if ($lat_long =~ /(.*)\/(.*)/){
		$latitude = $1;
		$longitude = $2;
#	print "$longitude\n";
#	next Record;
	}
	
	else {
		$latitude = $longitude = "";
	}

	foreach ($latitude,$longitude){
		s/^"//g;
		s/"$//g;
		s/""//g;
		s/N//g;
		s/W//g;
		s/'/ /g;
		s/"/ /g;
		s/°/ /g;
		s/_/ /g; 
		s/^ *//g;
		s/ *$//g;
		s/  / /g;
	
		s/,/./g;
	}	

	if ($latitude=~m/(\d+) (\d+) (\d+)/){
		$latitude=($1)+($2/60)+($3/3600);
		}
	elsif ($latitude=~m/(\d+) (\d+)/){
		$latitude=($1)+($2/60);
		}
	elsif ($latitude=~m/(\d+)/){
		$latitude=$1;
	}
	elsif ($latitude){
		$latitude = $latitude;
	}
	else{
		$latitude="";
	}
	
	if ($longitude=~m/(\d+) (\d+) (\d+)/){
		$longitude=($1)+($2/60)+($3/3600);
		}
	elsif ($longitude=~m/(\d+) (\d+)/){
		$longitude=($1)+($2/60);
	}
	elsif ($longitude=~m/(\d+)/){
		$longitude=$1;
	}
	elsif ($longitude){
		$longitude = $longitude;
	}
	else{
		$longitude="";
	}
}

#Dick wrote this code. I haven't touched it but it appears to work.
#It ignores the zone provided, and sets it to 11N as default
elsif($UTM_Z_E_N){
	if($UTM_Z_E_N=~m !/(\d\d\d\d\d\d+)\/(\d\d\d\d\d+)!){
		use Geo::Coordinates::UTM;
		$easting=$1;
		$northing=$2;
		$ellipsoid=23;
		$zone="11N";
		if($UTM_Z_E_N=~/9|10|11|12/ && $easting=~/\d\d\d\d\d\d/ && $northing=~/\d\d\d\d\d/){
			($latitude,$longitude)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
		}
		else{
			print "$catalog_number UTM problem $zone $easting $northing\n";
		}		
	}  
}

else {
		$latitude=$longitude="";
}

$longitude="-$longitude" if $longitude > 0;

if ($latitude){
	if ($latitude < 32.5 || $latitude > 42.1){
		print ERR "Latitude $latitude outside CA box; lat and long nulled: $catalog_number\n";
		$latitude="";
		$longitude="";
	}
}
	if ($longitude){
		if ($longitude > -114.0 || $longitude < -124.5){
		print ERR "Longitude $longitude outside CA box; lat and long nulled: $catalog_number\n";
		$longitude="";
		$latitude="";
	}
}


############LOCALITY AND HABITAT#####
#Which includes Datum, error, error units etc

if ($locality=~s/; DATUM IS ([^ ]+)//i){
	$datum = $1;
	$datum=~s/1927/27/;
}
elsif($locality=~s/Datum: NAD83\.//i){
	$datum="NAD83";
}
else{
	$datum="";
}

if($locality=~s/GPS Error: ([0-9.]+) [Mmetrs.]+//){
	$error=$1;
	$units="m";
}
else{
	$error="";
	$units="";
}

#locality requires no other processing, I think


if ($habitat1 && $habitat_comm){
	$habitat = "$habitat1; $habitat_comm";
}
elsif ($habitat1){
	$habitat = $habitat1;
	}
elsif ($habitat_comm){
	$habitat = $habitat_comm;
}
else{
	$habitat="";
}






##############ELEVATION##############
foreach ($elevation) {
	s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Not ?[pP]rovided|Not ?[rR]ecorded).*//;
	s/ *meters?/ m/i;
	s/ *m\.?/ m/i;
	s/ *feet/ ft/i;
	s/ *ft\.?/ ft/i;
	s/^C(\d)/ca. $1/;
	s/,//g;
}

$elev_test=$elevation;
		$elev_test=~s/.*- *//;
		$elev_test=~s/ *\(.*//;
		$elev_test=~s/ca\.? *//;
		if($elev_test=~s/ (meters?|m)//i){
			$metric="(${elev_test} m)";
			$elev_test=$elev_test * $m_to_f;
			$elev_test= " feet";
		}
		else{
			$metric="";
		}
		if($elev_test=~s/ +(ft|feet)//i){

			if($elev_test > $max_elev{$county}){
				print ERR "$catalog_number\t$county\t ELEV: $elevation $metric greater than max: $max_elev{$county} discrepancy=", $elev_test-$max_elev{$county},"\n";
			}
		}


###############TYPE STATUS#############
$type_specimen=~s/"//;
$type_specimen = ucfirst(lc($type_specimen));
unless ($type_specimen=~/type/){
	$type_specimen="";
}


############ANNOTATION############
#incl. type status
if ($hybrid_formula || $identified_by || $id_date || $type_specimen){
	if ($hybrid_formula){
		$annotation = "$hybrid_formula; $identified_by; $id_date; $type_specimen";
	}
	else{
		$annotation = "$name; $identified_by; $id_date; $type_specimen";
	}
}
else {
	$annotation = "";
}

#########EXCLUDING SENSITIVE INFORMATION
$name=~s/ +/ /g;
if($name=~/(Cypripedium montanum|Platanthera yosemitensis)/){
print ERR "Sensitive location redaction $Catalog_id\n";
$Locality="";
$UTM="";
$decimal_lat="";
$decimal_long="";
#$CNUM= $CNUM_prefix= $CNUM_suffix="";
#$coll_date=~s/.*([12]\d\d\d).*/$1/;
}


print OUT <<EOP;
Accession_id: $catalog_number
Date: $coll_date
Name: $name
Collector: $Collector
Combined_collector: $Combined_Collectors
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Location: $locality
Elevation: $elevation
Habitat: $habitat
Associated_species: $associated_species
County: $county
State: $state
UTM: $UTM_Z_E_N
Decimal_latitude: $latitude
Decimal_longitude: $longitude
Notes:
Datum: $datum
Max_error_distance: $error
Max_error_units: $units
Annotation: $annotation

EOP
}

open(OUT, ">YOSE_badname") || die;
foreach (sort(keys(%needed_name))){
print OUT "$_: $needed_name{$_}\n";
}
sub strip_name{
local($_) = @_;

s/ +/ /g;
s/Hook\. f./Hook./g;
s/Rech\. f./Rech./g;
s/Schult\. f./Schult./g;
s/Schultes f./Schultes/g;
#Name: Quercus √ómacdonaldii Greene
s/^([A-Z][A-Za-z]+) (X?[-a-z]+).*(subsp\.|ssp\.|var\.|f\.) ([-a-z]+).*/$1 $2 $3 $4/ ||
s/^([A-Z][A-Za-z]+) √ó ?([-a-z]+) .+/$1 √ó $2/||
s/^([A-Z][A-Za-z]+) √ó ?([-a-z]+)/$1 √ó $2/||
s/^([A-Z][A-Za-z]+) (X?[-a-z]+) .+/$1 $2/||
s/^([A-Z][A-Za-z]+) (indet\.|sp\.)/$1 indet./||
s/^([A-Z][A-Za-z]+) (X?[-a-z]+)/$1 $2/||
s/^([A-Z][A-Za-z]+) (.+)/$1/;
s/ssp\./subsp./;
s/ +$//;
$_;
}


sub skip {	#for each skipped item...
	print ERR "skipping: @_\n"	#print into the ERR file "skipping: "+[item from skip array]+new line
}
sub log {	#for each logged change...
	print ERR "logging: @_\n";	#print into the ERR file "logging: "+[item from log array]+new line
}