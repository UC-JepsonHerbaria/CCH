use strict;
use warnings;
use lib '/Users/davidbaxter/DATA';
use CCH;
my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.

$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;

open(OUT,">JROH.out") || die;
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $included;
my %skipped;
my $line_store;
my $count;
my $seen;
my %seen;

my $file = 'ConsortiumUpdate3_9_2017.txt';

#####process the file
#JROH file arrives as a tab delimited txt
#Then open in TextWrangler and make sure to save as UTF-8 with Unix line breaks
###############

open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	$line_store=$_;
	++$count;

	s/\xe2\x80\x99/'/g;
	
&CCH::check_file;	
my $annotation;  #$hybridFormula,
my $id;
my $scientificname;
my $scientificName;
my $recordedby;
my $verbatimEventDate;
my $eventDate;
my $recordnumber;
my $recordNumber;
my $county;
my $locality;
my $elevation;
my $collString; #combination of collector, number, and date. Redundant with other fields so is not processed
my $habitat;
my $latitude;
my $longitude;
my $datum;
my $errorRadius;
my $georefSource;
my $voucherInfo; #Macromorphology and/or abundance
my $associatedSpecies;	
my $cultivated; #add this field to the data table for cultivated processing, place an "N" in all records as default

my @columns=split(/\t/,$_,100);
		unless($#columns==18){ #17 fields but first field is field 0 in perl
		&log_skip("$#columns bad field number $_");
		++$skipped{one};
		next Record;
	}
	
($cultivated,
$annotation,
$id,
$scientificname,
$recordedby,
$verbatimEventDate,
$recordNumber,
$county,
$locality,
$elevation,
$collString, #combination of collector, number, and date. Redundant with other fields so is not known
$habitat,
$latitude,
$longitude,
$datum,
$errorRadius,
$georefSource,  #$hybridFormula, field no longer in output?
$voucherInfo, #Macromorphology and/or abundance
$associatedSpecies)=@columns;

################ACCESSION_ID#############
#check for nulls
if ($id=~/^ *$/){
	&log_skip("Record with no accession id $_");
	++$skipped{one};
	next Record;
}

#remove leading zeroes, remove any white space
foreach($id){
	s/^0+//g;
	s/ +/ /;
	s/^ *//g;
	s/ *$//g;
}

#Add prefix, 
$id="JROH$id";

#Remove duplicates
if($seen{$id}++){
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	next Record;
}

##########Begin validation of scientific names
#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in
foreach ($scientificname){
	s/ sp\.//g;
	s/ species$//g;
	s/ sp$//g;
	s/ spp / subsp. /g;
	s/ spp. / subsp. /g;
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/;$//g;
	s/cf.//g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/^ *//g;
	s/ *$//g;
	s/ +/ /g;
	}


#####process taxon names

$scientificName = &strip_name($scientificname);

$scientificName = &validate_scientific_name($scientificname, $id);

#####process cultivated specimens			
# flag taxa that are known cultivars that should not be added to the Jepson Interchange, add "P" for purple flag to Cultivated field	


## regular Cultivated parsing
		if ($locality =~ m/(uncultivated|naturalizing|naturalized|cultivated fields?|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i){
			&log_change("specimen likely not cultivated, purple flagging skipped: $scientificName\t--\t$id\n");
		}
		elsif ($locality =~ m/(cult. |cultivated|cultivated native|cultivated from|cultivated plants|cultivated at |cultivated in |cultivated hybrid|under cultivation|in cultivation|Oxford Terrace Ethnobotany|Internet purchase|Cultivted|cultived at|artificial hybrid|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection)/i) || ($habitat =~ m/(cultivated from|planted from seed|planted from a seed)/i){
		    $cultivated = "P";
	   		&log_change("Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
		
		elsif ($cultivated =~ m/N/){
			if($cult{$scientificName}){
				$cultivated = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			&log_change("Taxon skipped purple flagging: $cultivated\t--\t$scientificName\n");
			$cultivated = "";
			}
		}

##########COLLECTION DATE##########
my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;

foreach ($verbatimEventDate){
	s/ +/ /g;
	s/unspecified//g;
	s/\?//g;
	}

if ($verbatimEventDate=~/(\d{1,2})\/(\d{1,2}?)\/(\d{4})/){
	$MM=$1;
	$DD=$2;
	$YYYY=$3;
	$DD=~s/^0//;
	$MM=~s/^0//;
}

elsif($verbatimEventDate=~/(\d{1,2})\/(\d{4})/){
	$MM=$1;
	$YYYY=$2;
	$MM=~s/^0//;
}

elsif ($verbatimEventDate=~/.+/){
	&log_change("Check date format: $verbatimEventDate\t$id");
}
else {
	$verbatimEventDate = "";
	&log_change("No date: $id")
	}

$MM = &get_month_number($MM, $id, %month_hash);

$eventDate = "$YYYY-$MM-$DD";
($YYYY, $MM, $DD)=&atomize_ISO_8601_date($eventDate);

($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);

###############COLLECTORS
#All collectors in the sample dataset are lone collectors
#Additions may be needed if more collectors added

my $other_collectors;
my $comb_collectors;
my $parseColl;

$parseColl=ucfirst($recordedby);
if ($parseColl=~/(.*),(.*)/){
	$recordedBy=$1;
	$other_collectors=$2;
}

$recordedBy =~ s/^ *//;
$recordedBy =~ s/ *$//;
$recordedBy =~ s/ +/ /;

$other_collectors =~ s/^ *//;
$other_collectors =~ s/ *$//;
$other_collectors =~ s/ +/ /;

if ($recordedBy && $other_collectors){
	$comb_collectors = "$recordedBy; $other_collectors";
}
else {
	$comb_collectors = $recordedBy;
}

#$recordedByFirst=ucfirst($recordedByFirst);
#$recordedByLast=ucfirst($recordedByLast);
#$otherCollFirst=ucfirst($otherCollFirst);
#$otherCollLast=ucfirst($otherCollLast);	
#		
#if ($recordedByFirst=~/^[A-Z]$/){
#	$recordedByFirst = "$recordedByFirst.";
#	}
#if ($recordedByLast=~/^[A-Z]$/){
#	$recordedByLast = "$recordedByLast.";
#	}
#if ($otherCollFirst=~/^[A-Z]$/){
#	$otherCollFirst = "$otherCollFirst.";
#	}
#if ($otherCollLast=~/^[A-Z]$/){
#	$otherCollLast = "$otherCollLast.";
#	}

#$recordedBy = "$recordedByFirst $recordedByLast";
#$recordedBy =~ s/^ *//;
#$recordedBy =~ s/ *$//;
#$recordedBy =~ s/  */ /;
#
#$otherColl = "$otherCollFirst $otherCollLast";
#$otherColl =~ s/^ *//;
#$otherColl =~ s/ *$//;
#$otherColl =~ s/  */ /;



#############CNUM##################

my $CNUM_suffix;
my $CNUM;
my $CNUM_prefix;



if($recordnumber=~/(\d+)(\D+)/){
	$CNUM=$1;
	$CNUM_suffix=$2;
}
elsif($recordnumber=~/(\d+)/){
	$CNUM=$recordNumber;
	$CNUM_suffix="";
}
elsif(length($recordnumber) > 1){
	&log_change("Check collector number format: $recordnumber\t--\t$id");
	$CNUM=$recordNumber;
}
else{
	$CNUM=$CNUM_suffix=$CNUM_prefix="";
}

($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);

######################Unknown County List

my $stateProvince = "CA"; #all specimens from BLMAR are from California

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}
	
##############validate county

my $v_county;
#JROH doesn't use county suffixes
#but still format county as a precaution
$county=&CCH::format_county($county);

foreach ($county){	#for each $county value
        unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown)$/){
            $v_county= &verify_co($_); #Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
            if($v_county=~/SKIP/){ #If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
                &skip("$id NON-CA COUNTY? $_"); #run the &skip function, printing the following message to the error log
                ++$skipped{one};
                next Record;
            }

            unless($v_county eq $_){ #unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
                &log_change("$id COUNTY $_ -> $v_county"); #call the &log function to print this log message into the change log...
                $_=$v_county; #and then set $county to whatever the verified $v_county is.
            }
        }
    }


##########LOCALITY#########
#Locality is all in one field and seems to have no problems, besides some strange characters
foreach($locality){
	s/^ *//g;
	s/ *$//g;
	s/ +/ /g;
}


###############ELEVATION########
foreach($elevation){
	s/feet/ft/g;
	s/ft/ ft/g;
	s/m/ m/g;
	s/  / /g;
	s/,//g;
	s/\.//g;
	s/[A-Z]?[a-z]+ (\d+)/$1/g;
	
	}
	
$elevation=&CCH::is_bad_elev($elevation);	#check to see if elevation exceeds maximum and minimum for the state
$elevation=&CCH::format_county($elevation);	#check to see if elevation exceeds values for each county

#########COORDS, DATUM, ER, SOURCE#########
#Source is a free text field so no editing required
my $lat_sum;
my $long_sum;
my $Check;
my $ER_units;

#All coordinates were in perfect DD, but now one DMS was recorded
#e.g. "N37°24'	W122°14'"
if ($latitude=~/N(\d+)[°¡](\d+)'/){
		$lat_sum=$1+($2/60);
		$latitude=$lat_sum;
		&log_change("coordinates converted from DMS to DD\t$id");
	}
if ($longitude=~/W(\d+)[°¡](\d+)'/){
		$long_sum=($1+($2/60));
		$longitude="-$long_sum";
		&log_change("coordinates converted from DMS to DD\t$id");
	}

#remove all degree signs
$latitude =~ s/[°¡]//g;
$longitude =~ s/[°¡]//g;

if(($latitude=~/\d/  || $longitude=~/\d/)){ #If decLat and decLong are both digits
	if ($longitude > 0) {
		$longitude="-$longitude";	#make decLong = -decLong if it is greater than zero
	}	
	if($latitude > 42.1 || $latitude < 32.5 || $longitude > -114 || $longitude < -124.5){ #if the coordinate range is not within the rough box of california...
		&log_change("coordinates set to null, Outside California: >$latitude< >$longitude<\t$id");	#print this message in the error log...
		$latitude =$longitude="";	#and set $decLat and $decLong to ""
	}
}
elsif($latitude | $longitude){ #if there is a lat or long (which therefore is not a digit)
	&log_change("$Check coordinate formatting: >$latitude< >$longitude<\t$id");
}

foreach($datum){
	s/ //g;
}

if($datum){
	unless ($datum=~m/(WGS84|NAD83|NAD27)/){
		&log_change("Check datum: $datum\t$id");
		$datum="";
	}
}

foreach ($errorRadius){
	s/feet/ft/g;
	s/ft/ ft/g;
	s/m/ m/g;
	s/k m/ km/g; #to correct the previous line from turning "km" into "k m"
	s/  / /g;
	s/,//g;
	s/\.//g;
}

#Error radius must be split because of bulkloader format
if ($errorRadius=~/(\d+) (.*)/){
	$ER_units=$2;
	$errorRadius=$1;
}
else {
	$ER_units="";
}



###########HABITAT#########
#Habitat is all in one field and seems to have no problem




####VOUCHER INFORMATION#####
#Macromorphology, including abundance
#free text field with no editing required


#####ASSOCIATED SPECIES#####
#free text field
foreach ($associatedSpecies){
	s/ ssp / subsp. /g;
	s/ ssp. / subsp. /g;
	s/ var / var. /g;
	s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
	s/^ *//g;
	s/ *$//g;
	s/ +/ /g;
}

#RLM removed JROH prefix from first line : Mon Jun 13 18:18:06 PDT 2016
	print OUT <<EOP;
Accession_id: $id
CNUM_prefix: $CNUM_prefix
CNUM: $CNUM
CNUM_suffix: $CNUM_suffix
Name: $scientificName
Date: $eventDate
EJD: $EJD
LJD: $LJD
County: $county
Location: $locality
Collector: $recordedBy
Other_coll: $other_collectors
Combined_coll: $comb_collectors
Decimal_latitude: $latitude
Decimal_longitude: $longitude
Datum: $datum
Lat_long_ref_source: $georefSource
Max_error_distance: $errorRadius
Max_error_units: $ER_units
Elevation: $elevation
Habitat: $habitat
Associated_species: $associatedSpecies
Macromorphology: $voucherInfo
Annotation: $annotation
Cultivated: $cult

EOP
++$included;
}

print <<EOP;
INCL: $included
EXCL: $skipped{one}
TOTAL: $count
EOP


#####Check final output for characters in problematic formats (non UTF-8), this is Dick's accent_detector.pl
my @words;
my $word;
my $store;
my $match;
my %store;
my %match;
my $seen;
my %seen;

    my $file_out = 'JROH.out';	#the file this script will act upon is called 'HUH_out'
open(IN,"$file_out" ) || die;

while(<IN>){
        chomp;
#split on tab, space and quote
        @words=split(/["        ]+/);
        foreach (@words){
                $word=$_;
#as long as there is a non-ascii string to delete, delete it
                while(s/([^\x00-\x7F]+)//){
#store the word it occurs in unless you've seen that word already

                        unless ($seen{$word . $1}++){
                                $store{$1} .= "$word\t";
                        }
                }
        }
}

	foreach(sort(keys(%store))){
#Get the hex representation of the accent
		$match=  unpack("H*", "$_"), "\n";
#add backslash-x for the pattern
		$match=~s/(..)/\\x$1/g;
#Print out the hex representation of the accent as it occurs in a pattern, followed by the accent, followed by the list of words the accent occurs in
				&log_skip("problem character detected: s/$match/    /g   $_ ---> $store{$_}\n\n");
	}
close(IN);
close(OUT);

