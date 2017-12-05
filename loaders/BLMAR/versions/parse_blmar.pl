use Carp; #to use "croak" instead of "die"
use lib '/Users/davidbaxter/DATA';
use CCH;
$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array

my %month_hash = &month_hash;
my $output_file = "BLMAR.out";

open my $OUT_FILE, '<', $output_file
	or croak( "Can't open $output_file:" );

#two log files for now, while in the process of refactoring
#log.txt is used by subroutines
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";
my $old_error_log = "BLMAR_problems";
open my $OUT_FILE, '<', $old_error_log
	or croak ("Can't open $old_error_log");

##meters to feet conversion
#$meters_to_feet="3.2808";

#####process the file
#BLMAR file arrives as an xlsx file
#I opened it in Excel, saved as txt
#Then imported to Google Refine and exported as a tsv
#There might be a faster way to do it 

my $main_file = 'BLMAR-txt.tsv';
#open(IN,$main_file) || die;
open my $IN_FILE, '<', $main_file
	or croak ("Can't open $main_file");

Record: while(<$IN_FILE>){
	chomp;
	@columns=split(/\t/,$_,100);
	unless($#columns==16){
		print ERR "$#columns bad field number $_\n";
	}
	
($family,
$scientificName,
$commonName,
$locality,
$TRS,
$latitude,
$longitude,
$datum,
$localityDetails,
$habitat,
$notes,
$elevation,
$county,
$CNUM,
$id,
$eventDate,
$recordedBy)=@columns;

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
		warn "Duplicate number: $fields[-3]<\n";
		print ERR<<EOP;
Duplicate accession number, skipped: $fields[-3]
EOP
		next;
	}
	

##################Exclude cult
# if locality starts with "cultivated" etc., skip the record. There are many other localities describing "next to cultivated field" etc.
#	if($locality=~/^(Cultivated|cultivated|Small cultivated|Tree cultivated)/){
#				&skip("$id Specimen from cultivation $_\n");	#&skip is a function that skips a record and writes to the error log
#				++$skipped{one};
#				next Record;
#			}

#############CNUM##################
foreach ($CNUM){
	s/#//;
}
	
if($CNUM=~/(.*) (.*)/){
	&log("$id Collector Number $CNUM truncated to $1");
	$CNUM=$1;
}

##########COLLECTION DATE##########
foreach ($eventDate){
	s/,/ /g;
	s/\./ /g;
	s/  */ /g;
	}
if ($eventDate=~/(\d\d*) ([A-Za-z]+) (\d\d\d\d)/){
	$DD=$1;
	$MM=$2;
	$YYYY=$3;
	$DD=~s/^0//;
	}
elsif ($eventDate=~/(\d\d*)-([A-Za-z]+)-(\d\d)/){
	$DD=$1;
	$MM=$2;
	$YYYY="20$3";
	}
elsif ($eventDate=~/([A-Za-z]+) (\d\d\d\d)/){
	$MM=$1;
	$YYYY=$2;
}
elsif ($eventDate=~/([A-Za-z]+)-(\d\d)/){
	if ($2=~m/82/){
		$MM=$1;
		$YYYY="19$2";
		}
	else{
		$MM=$1;
		$YYYY="20$2";
		}
}
elsif ($eventDate=~/.+/){
&log("$id date format not recognized: $eventDate\n");
}

$MM = &get_month_number($MM, $id, %month_hash);

($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);

##########LOCALITY#########
if ($locality && $localityDetails){
	$locality="$locality".", $localityDetails";
}
elsif ($localityDetails){
	$locality=$localityDetails;
}
else {
	$locality=$locality;
}


###########HABITAT#########
foreach ($habitat){
	s/grwng/growing/g;
	s/grwing/growing/g;
}


###########COUNTY###########

	foreach ($county){ #for each $county value
		s/[()]*//g; #remove all instances of the literal characters "(" and ")"
		s/ +coun?ty.*//i; #substitute a space followed by the word "county" with "" (case insensitive, with or without the letter n)
		s/ +co\.//i; #substitute " co." with "" (case insensitive)
		s/ +co$//i; #substitute " co" with "" (case insensitive)
		s/ *$//;
		s/^$/Unknown/;
		s/County Unknown/unknown/; #"County unknown" => "unknown"
		s/County unk\./unknown/; #"County unk." => "unknown"
		s/Unplaced/unknown/; #"Unplaced" => "unknown"
		#print "$_\n";

        unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
            $v_county= &verify_co($_); #Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
            if($v_county=~/SKIP/){ #If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
                &skip("$id NON-CA COUNTY? $_"); #run the &skip function, printing the following message to the error log
                ++$skipped{one};
                next Record;
            }

            unless($v_county eq $_){ #unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
                &log("$id COUNTY $_ -> $v_county"); #call the &log function to print this log message into the change log...
                $_=$v_county; #and then set $county to whatever the verified $v_county is.
            }
        }
    }
#########COORDS
	foreach ($latitude,$longitude){
	s/^"//g;
	s/"$//g;
	s/""//g;
	s/N//g;
	s/W//g;
	s/'/ /g;
	s/"/ /g;
	s/°/ /g;
	s/^ *//g;
	s/ *$//g;
	s/  / /g;
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
else{
	$longitude="";
	}

if(($latitude=~/\d/  || $longitude=~/\d/)){ #If decLat and decLong are both digits
    if ($longitude > 0) {
        $longitude="-$longitude"; #make decLong = -decLong if it is greater than zero
    }
    if($latitude > 42.1 || $latitude < 32.5 || $longitude > -114 || $longitude < -124.5){ #if the coordinate range is not within the rough box of california...
        &log("$id coordinates set to null, Outside California: >$latitude< >$longitude<"); #print this message in the error log...
        $latitude =$longitude=""; #and set $decLat and $decLong to ""
    }
}

##############TRS
foreach($TRS){
	s/,//g;
	s/\.//g;
}

##########NAME


#######Validate
foreach ($scientificName){
	s/\?//g;
	s/ sp\.//g;
	s/ sp$//g;
	s/ spp / subsp. /g;
	s/ spp. / subsp. /g;
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/[()]//g;
	s/cf.//g;
	s/\/.*//g; #This is to handle Plantago/cryptantha 
	s/ x / X /g;
	s/^ *//g;
	s/ *$//g;
	s/  / /g;
	s/ var / var. /g; 
}
$scientificName=ucfirst($scientificName);
$scientificName = &validate_scientific_name($scientificName, $id);


###############COLLECTORS
$recordedBy=ucfirst($recordedBy);
if ($recordedBy=~/(.*),(.*)/){
	$recordedBy=$1;
	$otherColl=$2;
}

$recordedBy =~ s/^ *//;
$recordedBy =~ s/ *$//;
$recordedBy =~ s/  */ /;

$otherColl =~ s/^ *//;
$otherColl =~ s/ *$//;
$otherColl =~ s/  */ /;


###############ELEVATION########
foreach($elevation){
	s/ft/ ft/g;
	s/m/ m/g;
	s/  / /g;
	s/,//g;
	s/\.//g;
}

if ($elevation=~"#"){
	&log("$id Elevation value ($elevation) not recognized as elevation");
	$elevation="";
}


	print $OUT_FILE <<EOP;
Accession_id: $id
CNUM: $CNUM
Name: $scientificName
Date: $eventDate
EJD: $EJD
LJD: $LJD
County: $county
Location: $locality
Collector: $recordedBy
Other_coll: $otherColl
Habitat: $habitat
Notes: $notes
Decimal_latitude: $latitude
Decimal_longitude: $longitude
Datum: $datum
T/R/Section: $TRS
Elevation: $elevation

EOP
}

sub skip { #for each skipped item...
	print ERR "skipping: @_\n"; #print into the ERR file "skipping: "+[item from skip array]+new line
	return;
}
sub log { #for each logged change...
	print ERR "logging: @_\n"; #print into the ERR file "logging: "+[item from log array]+new line
	return;
}