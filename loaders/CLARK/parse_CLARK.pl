use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

$m_to_f="3.2808";
use Geo::Coordinates::UTM;

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

open(TABFILE,">CLARK.out") || die;


#note that CLARK sends their data in separate Excel files
#I amalgamate them all into a single text file
#As of September 2014 there are four Excel files

#####RECORD DUPLICATION
#Almost all of the records in the second CLARK file ("CCH list2 for Riverside CLARK.xls")
#Are duplicated in the third and fourth file ("Sept2014_CCH... and "Complete List-Second...")
#Since the newer records are desired, I used comm to determine what IDs were unique to the second list (92 IDs)
#then extract those from that file, concatenate with the other three files, then run the parser on that
#send the list of good records to CLARK and maybe they can do something with it

$current_file="CLARK2015_files/CLARK_2015.txt";
#$current_file="Sept2014_CLARK.txt";

open(IN,"$current_file") || die;
warn "reading from $current_file\n";
Record: while(<IN>){
	&CCH::check_file;
	chomp;
	@fields=split(/\t/,$_,100);
	unless ($#fields>=13){
		&log_skip("$#fields bad field number $_");
		next Record;
	}

foreach(@fields){
	s/^"? *//;
	s/ *"?$//;
}

($id,
$family,
$genus,
$species,
$species_author,
$infra,
$infra_author,
$higher_geography,
$locality_notes,
$eventDate,
$collector,
$CNUM,
$latitude,
$longitude)=@fields;

########ACCESSION NUMBER
$id="CLARK-$id";

#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	next Record;
}
#remove duplicates
if ($seen{$id}++){
	&log_skip("Duplicate number: $id<");
	next Record;
}


########SCIENTIFIC NAMES
#$family not used
$scientificName= "";
	if($infra){
		$scientificName="$genus $species subsp. $infra";
	}
	else{
		$scientificName="$genus $species";
	}
	
$scientificName=ucfirst(lc($scientificName));
$scientificName=~s/ sp\..*//;
$scientificName=~s/ x / X /;
$scientificName=~s/ × / X /;
$scientificName=~s/ *$//;
$scientificName=~s/ +/ /g;

if($scientificName=~s/([A-Z][a-z-]+ [a-z-]+) [Xx◊] /$1 X /){
	$hybrid_annotation=$scientificName;
	warn "$1 from $scientificName\n";
	&log_change("$1 from $scientificName");
	$scientificName=$1;
}
else{
	$hybrid_annotation="";
}

$scientificName = &validate_scientific_name($scientificName, $id);
$scientificName{$scientificName}++;


######HIGHER GEOGRAPHY AND LOCALITY
($country,$state,$county,$place)=split(/ ?, ?/,$higher_geography);
$country=~s/^ *//;
$country="USA" if $country=~/U\.?S\.?/;
$state=~s/^ *//;
$county=~s/^ *//;
unless($state=~/^(CA|Ca|Calif\.|California)$/){
	&log_skip("State not California $id state=$state country=$country: skipped");
	next Record;
}

$county=~s/ County//;
foreach($county){
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown)$/){
		$v_county= &verify_co($_);
		if($v_county=~/SKIP/){
			&log_change("NON-CA county? $_");
			next Record;
		}
		unless($v_county eq $_){
			&log_change("$id $_ -> $v_county");
			$_=$v_county;
		}
	}
	$county{$_}++;
}

########LOCALITY
#split up locality_notes to get elevation and associated species
$associates=$elevation=$locality="";
@locality_notes_split=split(/; /,$locality_notes);
foreach(@locality_notes_split){
	if(s/([Ee]levation.*)//){
		$elevation=$1;
		$elevation=~s/elevation //;
		$elevation=~s/,//g;
		$elevation=~s/approximately/ca./;
		$elevation=~s/ feet/ ft/;
	}		
	elsif(s/associated with (.*)//){
		$associates=$1;
	}
}

#join the rest back together, then concatenate with $place to get DwC locality 
$locality_notes=join("; ",@local_notes_split);
$locality = "$place, $locality_notes";
$locality =~ s/, $//;


############ELEVATION (from locality notes)
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
				print ERR "ELEV $county\t ELEV: $elevation $metric greater than max: $max_elev{$county} discrepancy=", $elev_test-$max_elev{$county}," $id\n";
			}
		}
		
		

####### COLLECTION DATES
if($eventDate=~/[Uu]nknown/){
	$eventDate="";
}

if ($eventDate=~/(\d\d?)\/(\d\d?)\/(\d\d\d\d)/){
	$MM=$1;
	$DD=$2;
	$YYYY=$3;
	$DD=~s/^0//;
	$MM=~s/^0//;
}

##CLARK data contains many two digit years
##but I have confirmed that they are all 1900s
elsif ($eventDate=~/(\d\d?)\/(\d\d?)\/(\d\d)/){
	$MM=$1;
	$DD=$2;
	$YYYY="19$3";
	$DD=~s/^0//;
	$MM=~s/^0//;
}	
elsif($eventDate=~/(\d\d?)\/(\d\d\d\d)/){
	$MM=$1;
	$YYYY=$2;
	$MM=~s/^0//;
}
elsif ($eventDate=~/.+/){
	unless($eventDate=~/(1[789]\d\d|20\d\d)$/){
		&log_change("Date config problem $eventDate: date nulled 9 $id");
	}
}
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);


#########COLLECTORS
if ($collector=~/(.*) \| (.*)/){
	$collector=$1;
	$other_coll=$2;
}
elsif ($collector=~/(.*)\|(.*)/){
	$collector=$1;
	$other_coll=$2;
}
elsif ($collector=~/(.*) ?- ?(.*)/){
	$collector=$1;
	$other_coll=$2;
}
else {
	$collector=$collector;
	$other_coll="";
}


#########COLLECTOR NUMBER
$CNUM=~s/ *$//;
$CNUM=~s/^ *//;
$CNUM=~s/,//;

if ($CNUM){
	($Coll_no_prefix, $Coll_no, $Coll_no_suffix)=&parse_CNUM($CNUM);
}
else {
	$Coll_no_prefix=$Coll_no=$Coll_no_suffix="";
}


######LATITUDE AND LONGITUDE
$datum="WGS84/NAD83";
if($latitude){
$latitude=~s/[^0-9.]//g;
$longitude=~s/[^0-9.]//g;
		if ($longitude > 0){
			#&log_change("$longitude made -$longitude $id"); #commented out, since all longitudes are not negative
		$longitude="-$longitude";
		}
	if($latitude > 42.1 || $latitude < 32.5 || $longitude > -114 || $longitude < -124.5){
		&log_change("$id coordinates set to null, Outside California: lat is $latitude long is $longitude");
		$latitude =$longitude="";
	}   
}


print TABFILE <<EOP;
Date: $eventDate
EJD: $EJD
LJD: $LJD
CNUM_prefix: $Coll_no_prefix
CNUM: $Coll_no
CNUM_suffix: $Coll_no_suffix
Name: $scientificName
Accession_id: $id
Country: $country
State: $state
County: $county
Location: $locality
USGS_Quadrangle: $topo_quad
Elevation: $elevation
Collector: $collector
Other_coll: $other_coll
Habitat: 
Associated_species: $associates
Decimal_latitude: $latitude
Decimal_longitude: $longitude
Datum: $datum
Hybrid_annotation: $hybrid_annotation

EOP
}
