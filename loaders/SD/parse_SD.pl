use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA/';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
$today_JD = &get_today_julian_day;
my %month_hash = &month_hash;


&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array


#parse_sd.pl
open(OUT, ">SD.out") || die;

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


#####I'm not familiar with the Text::CSV function
#####here's what I do to the SD file to make it parse with this:
###open the file in TextWrangler, Save As with Line Breaks: Unix and Encoding: UTF-8
###Then run it through this and it works
    use Text::CSV;
    my $file = 'Apr2016_SD_original.txt';
#    my $file = 'Oct2015_SD_original.txt';


my $csv = Text::CSV->new ({
     #escape_char         => '\\',
     quote_char          => '"',
     sep_char            => ',',
     binary              => 1,
     });


    open (CSV, "<", $file) or die $!;
#$/="\015\012";

while (<CSV>) {
	chomp;
		
		
		s/ × / X /;
		s/\xc3\x97/X/g;	#×
		s/\xc3\x92/'/g; #Ò, which comes in as a bad quote
		s/\xc3\x93/'/g;  #Ó, same deal
		s/\xe2\x80\x93/-/g; #–
		s/\xe2\x80\x98/'/g;  #‘
		s/\xe2\x80\x99/'/g;  #’  
		s/\xe2\x80\xa6/.../g;  #…
		
		
		&CCH::check_file;
		s/\cK/ /g;
        if ($. == 1){
			next;
		}
        if ($csv->parse($_)) {
            my @columns = $csv->fields();
            #my @columns = split(/\t/,$_,1000);
			grep(s/ *$//,@columns);
			grep(s/^N\/A$//,@columns);
        	if ($#columns !=30){
				&log_skip("Not 31 fields", @columns);
				warn "bad record $#columns not 30  $_\n";
				next;
			}
			if($duplicate{$columns[5]}++){
				&log_skip("Duplicate", @columns);
				warn "Duplicate $columns[5]";
				next;
			}
(
$DATE,
$NUMBER,
$PREFIX,
$SUFFIX,
$scientificName,
$id,
$Country,
$STATE,
$LOCALITY,
$TRS,
$DISTRICT,
$elevation,
$collector,
$combined_collector,
$HABDESCR,
$macromorphology,
$Description,
$Vegetation,
$latitude,
$longitude,
$decimal_latitude,
$decimal_longitude,
$datum,
$extent,
$ExtUnits,
$georeferencedBy,
$georeferenceSource,
$UTM,
$notes,
$determiner,
$imageAvailable
)=@columns;

$hybrid_annotation="";
$annotation="";
$extent="" unless $ExtUnits;

		unless($id){
			&log_skip("No accession id", @columns);
		}


#######Cultivated material used to be excluded
#######It is now included, and indicated as a field

$cultivated= "";
		if($Description=~/Cultivated/){
			$cultivated="yes";
			&log_change ("Record marked as cultivated because of description \"$Description\"\t$id");
		}
		if($macromorphology=~/(Cultivated|Planted)/i){
			$cultivated="yes";
			&log_change ("Record marked as cultivated because of macromorphology \"$macromorphology\"\t$id");

		}
		if($Vegetation=~/Cultivated/){
			$cultivated="yes";
			&log_change ("Record marked as cultivated because of vegetation \"$Vegetation\"\t$id");
		}
		if($LOCALITY=~/(Ex hort|Arboretum)/i){
			$cultivated="yes";
			&log_change ("Record marked as cultivated because of Locality \"$LOCALITY\"\t$id");
		}
		
########Make sure to allow for Baja California when they provide it		
#		unless($STATE=~/^(CA|Calif)/i){
#			&log_skip("Extra-California record $id: $STATE");
#			next Record;
#		}
		if ($DISTRICT=~/^N\/?A$/i){
			$DISTRICT="unknown"
		}
		elsif ($DISTRICT=~/N\/?A/i){
			#print "$id $DISTRICT\n";
		}
		foreach($DISTRICT){
			s/Eldorado/El Dorado/;
		
			unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
				$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
				if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
					&log_skip("NON-CA COUNTY? $_\t$id");	#run the &log_skip function, printing the following message to the error log
					++$skipped{one};
					next;
				}
				unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
					&log_change("COUNTY $_ -> $v_county\t$id");		#call the &log function to print this log message into the change log...
					$_=$v_county;	#and then set $county to whatever the verified $v_county is.
				}
			}
		}
		


########SCIENTIFIC NAME	EDITING	
				$scientificName=~s/ × / X /;
				$scientificName=~s/\xc3\x97/X/g;
				$scientificName=~s/Lupinus formosus .* proximus .*/Lupinus formosus/;
				$scientificName=~s/ ssp\.$//;
				$scientificName=~s/ var\.$//;
				$scientificName=~s/ sp\..*//;
				$scientificName=~s/ *$//;
				if($scientificName=~s/^([A-Z][a-z]+ [a-z]+) (ssp\.|subsp\.) [a-z]+ var\. ([a-z]+)/$1 var. $3/){
					&log_change("$scientificName: quadrinomial converted $id");
				}
				if($scientificName=~s/^([A-Z][a-z]+ [a-z]+) (ssp\.|subsp\.) [a-z]+ ([a-z]+)/$1 var. $3/){
					&log_change("$scientificName: quadrinomial converted $id");
				}
				if($scientificName=~s/^([A-Z][a-z]+ [a-z]+) (ssp\.|subsp\.) [a-z]+ var\. ([a-z]+)/$1 var. $3/){
					&log_change("$scientificName: quadrinomial converted $id");
				}

			
		foreach($scientificName){
				s/ ssp / subsp. /;
				#s/ spp\.? / subsp. /;
				s/ var / var. /;
				s/ ssp\. / subsp. /;
				s/ f / f\. /;
				#s/ [xX] / × /;
				s/ [x] / X /;
				s/ ◊ / X /;
				s/ *$//;
			}


			if($scientificName=~/  /){
				if($scientificName=~/^[A-Z][a-z]+ [a-z]+ +[a-z]+$/){
					&log_change("$scientificName: var. added $id");
					$scientificName=~s/^([A-Z][a-z]+ [a-z]+) +([a-z]+)$/$1 var. $2/;
				}
				$scientificName=~s/  */ /g;
			}
			#######Hybrid name munging
			#if($scientificName=~/([A-Z][a-z-]+ [a-z-]+) × /){
			if($scientificName=~/([A-Z][a-z-]+ [a-z-]+) X /){
				$hybrid_annotation=$scientificName;
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			elsif($scientificName=~/([A-Z][a-z-]+ [a-z-]+) X$/){
				$hybrid_annotation=$scientificName;
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			if($scientificName=~/([A-Z][a-z-]+ [a-z-]+ var. [a-z-]+) X /){
			#if($scientificName=~/([A-Z][a-z-]+ [a-z-]+ var. [a-z-]+) × /){
				$hybrid_annotation=$scientificName;
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			if($scientificName=~/([A-Z][a-z-]+ [a-z-]+ subsp. [a-z-]+) X/){
			#if($scientificName=~/([A-Z][a-z-]+ [a-z-]+ subsp. [a-z-]+) × /){
				$hybrid_annotation=$scientificName;
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			if($scientificName=~/([A-Z][a-z-]+ [a-z-]+ subsp. [a-z-]+)X/){
			#if($scientificName=~/([A-Z][a-z-]+ [a-z-]+ subsp. [a-z-]+) × /){
				$hybrid_annotation=$scientificName;
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			if($scientificName=~/([A-Z][a-z-]+ [a-z-]+ subsp. [a-z-]+)X/){
			#if($scientificName=~/([A-Z][a-z-]+ [a-z-]+ subsp. [a-z-]+) × /){
				$hybrid_annotation=$scientificName;
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			
#####validate scientific name
$scientificName=ucfirst($scientificName);
$scientificName = &validate_scientific_name($scientificName, $id);

#### TRS and Notes
$TRS="" if $TRS=~s/NoTRS//i;
$notes="" if $notes=~/^None$/;

####process elecations
$elevation="" if $elevation=~/N\/?A/i;
if($elevation && ($elevation > 15000 || $elevation < -1000)){
&log_change("Elevation set to null: $id: $elevation");
$elevation="";
}
$elevation= "$elevation ft" if $elevation;
$elevation="" unless $elevation;

######COLLECTORS
$collector= "" unless $collector;
$collector= "" if $collector=~/^None$/i;
$collector=~s/^ *//;
$collector=~s/  +/ /g;
$collector=~s/([A-Z]\.)([A-Z]\.)([A-Z][a-z])/$1 $2 $3/g;
$collector=~s/([A-Z]\.)([A-Z]\.) ([A-Z][a-z])/$1 $2 $3/g;
$collector= $alter_coll{$collector} if $alter_coll{$collector};
if($combined_collector){
	$combined_collector=~s/et al$/et al./;
	$combined_collector=~s/([A-Z]\.)([A-Z]\.)([A-Z][a-z])/$1 $2 $3/g;
	$combined_collector=~s/([A-Z]\.)([A-Z]\.) ([A-Z][a-z])/$1 $2 $3/g;
	$combined_collector=~s/([A-Z]\.)([A-Z][a-z])/$1 $2/g;
	$combined_collector=~s/  +/ /g;
	$combined_collector= $alter_coll{$combined_collector} if $alter_coll{$combined_collector};
	if($collector){
		$combined_collector= "$collector, $combined_collector";
	}
	else{
		$collector=$combined_collector;
		$combined_collector= "";
	}
}
else{
	$combined_collector="";
}

#$badcoll{$collector}++ unless $COLL{$collector};
#$badcoll{$combined_collector}++ unless $COLL{$combined_collector};
if($NUMBER || $PREFIX || $SUFFIX){
$collector= "Anonymous" unless $collector;
}

#Their georeference source field has this extra stuff in it, ~50 records
#It also had carriage returns, but John takes those out on his end
#Georeference source is processed before coordinates, because 
foreach($georeferenceSource){
	s/By__________Date________/ /i;
	}
#they record "coordinates from label" even if there are no coordinates (which they record as 0, 0)
#some of them also have datum=WGS84 if there are no coordinates.
#so we want to null georefsource and datum in addition to coordinates if lat and long are recorded as 0
if(($decimal_latitude==0  || $decimal_longitude==0)){
	$datum="";
	$georeferenceSource="";
	$decimal_latitude =$decimal_longitude="";
}

if(($decimal_latitude=~/\d/  || $decimal_longitude=~/\d/)){
$decimal_longitude="-$decimal_longitude" if $decimal_longitude > 0;
if($decimal_latitude > 42.1 || $decimal_latitude < 30.0 || $decimal_longitude > -114 || $decimal_longitude < -124.5){
&log_change("coordinates set to null, Outside California: $id: >$decimal_latitude< >$decimal_longitude< $latitude $longitude");
$decimal_latitude =$decimal_longitude="";
}
}
$datum="" if $datum=~/^Unk$/i;
#$LOCALITY=~s/^"(.*)"$/$1/;
#$HABDESCR=~s/^"(.*)"$/$1/;

if($determiner){
if($determiner=~m/(.*), *(.*)/){
    $annotation="$scientificName; $1; $2";
	}
elsif($determiner=~m/(.+)/){
    $annotation="$scientificName; $1";
}
	else{
	    $annotation="";
		}
	}

#############PROCESSING DATES
foreach($DATE){
s/.*0000.*//;
s/.*year.*//i;
s/Unknown//i;
s/\.//;
s/^ *//;
s/ *$//;
s/  */ /g;
}
if ($DATE){
	$displayDATE = $DATE;
}
else {
	$displayDATE = "";
}

foreach($DATE) { #some processing to do after the display date is formatted, for weird ranges
s/-(\d+)//;
s/& (\d+)//;
}

if ($DATE=~/([A-Za-z][A-Za-z][A-Za-z]+) (\d\d?), (\d\d\d\d)/){
	$YYYY = $3;
	$MM = $1;
	$DD = $2;
	$DD =~s/^0//;
}
elsif ($DATE =~ /([A-Za-z][A-Za-z][A-Za-z]+), (\d\d\d\d)/){
	$YYYY = $2;
	$MM = $1;
	$DD = "";
}
elsif ($DATE =~ /([A-Za-z][A-Za-z][A-Za-z]+) (\d\d\d\d)/){ ##This also gets "Spring 1920", which just gets a JDate of 1920. Should fix
	$YYYY = $2;
	$MM = $1;
	$DD = "";
}
elsif ($DATE =~ /(\d\d?) ([A-Za-z][A-Za-z][A-Za-z]+) (\d\d\d\d)/){
	$YYYY = $3;
	$MM = $2;
	$DD = $1;
	$DD =~s/^0//;
}
elsif ($DATE =~ /^(\d\d\d\d)$/){
	$YYYY = $1;
	$MM = "";
	$DD = "";
}
elsif ($DATE =~ /^(\d\d?)\/(\d\d?)\/(\d\d\d\d)/){
	$MM = $1;
	$DD = $2;
	$YYYY = $3;	
}
elsif ($DATE =~ /^(\d\d?)\/(\d\d\d\d)/){
	$MM = $1;
	$YYYY = $2;
	$DD = "";
}

elsif ($DATE=~/.+/) {
	&log_change("$id date not formatted; will not sort: $DATE");
	$YYYY = $MM = $DD = "";
}
else {
	$YYYY = $MM = $DD = "";
}

foreach ($DD){
s/^0//;
}

$MM = &get_month_number($MM, $id, %month_hash);

($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);


#image URLs
if ($imageAvailable == 1){
	$aid4url = $id;
	$aid4url =~ s/SD//;
	$imageURL = 'http://SDPlantAtlas.org/StarZoomPA/HiResSynopticSZ.aspx?H='.$aid4url;
}
else {
	$aid4url=$imageURL="";
}

++$count_record;
warn "$count_record\n" unless $count_record % 5000;
            print OUT <<EOP;
Date: $displayDATE
EJD: $EJD
LJD: $LJD
CNUM: $NUMBER
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Name: $scientificName
Accession_id: $id
Country: USA
State: California
County: $DISTRICT
Location: $LOCALITY
T/R/Section: $TRS
Elevation: $elevation
Collector: $collector
Other_coll: 
Combined_collector: $combined_collector
Habitat: $HABDESCR
Associated_species: $Vegetation
Color: $Description
Macromorphology: $macromorphology
Latitude: $latitude
Longitude: $longitude
Decimal_latitude: $decimal_latitude
Decimal_longitude: $decimal_longitude
UTM: $UTM
Notes: $notes
Datum: $datum
Max_error_distance: $extent
Max_error_units: $ExtUnits
Lat_long_ref_source: $georeferenceSource
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation
Image: $imageURL
Cultivated: $cultivated

EOP
	}
	else {
		my $err = $csv->error_input;
		warn "\nFailed to parse line: $err\n";
		&log_skip("Failed to parse line: $err");
	}
}

warn "$count_record\n";
close CSV;
