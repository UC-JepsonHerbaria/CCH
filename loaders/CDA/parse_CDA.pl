#use utf8; #not sure if this is necessary
use lib '/Users/davidbaxter/DATA';
use CCH; #loads alter_names has %alter, non-vascular genus has %exclude, county %max_elev hash, and various processing subroutines
$today_JD = &get_today_julian_day;
&load_noauth_name; #load taxonID-to-scientificName hash %TID
my %month_hash = &month_hash;

open(OUT, ">CDA.out") || die;
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

my $file = 'CDAtoCCH4_16.txt';
###File arrives as an Excel xlsx file, with a lot of unfortunate in-cell line breaks
###Use find replace to remove "\n" to remove in-cell line breaks
###then save as a utf8 tab-delimited text file with no quotes
###N.B. You can load the file without removing the line breaks to make an informative log file for CDA
#Some problem specimens:
###CDA29638	M. Beyers	105, is a duplicate with the wrong accession number, change to CDA29638b
###CDA33958	M. Beyers	823A id'd to just Agrostis is a duplicate of the next record, change to CDA33958b
###CDA24566	M. Beyers	865 is a duplicate with the wrong accession number, change to CDA24566b
###CDA30254	G.F. Hrusa	16650 is a duplicate with the wrong accession number, change to CDA30254b
###CDA41051	T.C. Fuller	33b-58 is a duplicate with the wrong accession number, change to CDA41051b
###CDA6208 Unknown	s.n.	Jan	1	1906 is two mostly similar records, delete the second, incomplete record
###CDA20081	T. Gibson	PDR 1089395 is two identical records, delete one

open(IN,$file) || die;
Record: while(<IN>){
	chomp;
	s/\cK/ /g;
	s/\cB//g;
	s/Â±/+\/-/g;
	s/Ã/--/g;
	s/Ã/~/g;
	s/â/&ntilde;/g;
	s/Ã/--/g;
	s/&apos;/'/g;
	@fields=split(/\t/,$_,100);

	unless($#fields==32){
		&log_skip("Fields should be 32; I count $#fields\t$_");
		next Record;
	}

	$scientificName=$latitude=$longitude=$T_R_Section="";

($id, 
$collector, 
$recordNumber, 
$other_coll, 
$month, 
$day, 
$year, 
$genus, 
$specificEpithet,  
$infra_rank,
$infraspecificEpithet,
$identifiedBy,
$label_subhead, #i.e. "Plants of $label_subhead". Generally not published
$locality,
$habitat,
$occurrenceRemarks, #called PLCHARS for plant characteristics
$county,
$elevation,
$elev_units, # needs to be processed/shortened
$lat_degn,
$lat_minn,
$lat_secn,
$lat_hem,
$lon_degn,
$lon_minn,
$lon_secn,
$lon_hem,
$township, #so far not processed
$range,
$section,
$quarter,
$bm, #I don't know what this means. Basemap???
$quad #name of quad map
)=@fields;

#######ACCESSION ID
#check for nulls
if ($id=~/^ *$/){
	&skip("Record with no accession id $_");
	next Record;
}

#Remove duplicates
if($seen{$id}++){
	++$skipped{one};
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate accession number\t$id");
	next Record;
}


###COLLECTOR###
if($other_coll){
	$recordedBy="$collector, $other_coll";
}
else{
	$recordedBy=$collector;
}

#####COLLECTOR NUMBER####
$CNUM_prefix= $CNUM_suffix="";
($CNUM_prefix, $CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);


####COLLECTION DATE

#clean up date fields
foreach ($year){
	s/before 1920//g;
	s/\?$//g;
	s/s$//g;
}

foreach ($day){
	s/late//g;
	s/28-Aug-64/28/g;
	s/'//g;
	s/,//g;
	s/5-Mar//g;
	s/11-Sep//g;
	s/0+//g;    
}

$verbatimDate=$EJD=$LJD="";
#assemble verbatimDate from date fields
$verbatimDate="$month $day $year";
$verbatimDate=~s/^ *//;
$verbatimDate=~s/ *$//;
$verbatimDate=~s/  */ /;

#make julian days
$month = &get_month_number($month, $id, %month_hash);
($EJD, $LJD)=&make_julian_days($year, $month, $day, $id);
($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);


######SCIENTIFIC NAME###
#assemble name
$scientificName="$genus $specificEpithet $infra_rank $infraspecificEpithet";
$scientificName=~s/ *`//g;
$scientificName=~s/ *$//;

#create hybrid annotation
if($scientificName=~/([A-Z][a-z-]+ [a-z-]+) × /){
	$hybrid_annotation=$scientificName;
	warn "$1 from $scientificName\n";
	$scientificName=$1;
}
else{
	$hybrid_annotation="";
}

#remove cultivar records
if($scientificName=~/(CV\.? | '[a-z]+)/i){
	&log_skip("Can't deal with cultivars yet\t$id", $scientificName);
	next Record;
}
#remove problem specimen records, possible cultivars or not from California
if($id=~/(CDA6932)/){
	&log_skip("Problematic specimens not from California or possible cultivars\t$id", $scientificName);
	next Record;
}

#validate name
$scientificName=ucfirst(lc($scientificName));
$scientificName = &strip_name($scientificName);
$scientificName = &validate_scientific_name($scientificName, $id);


####ANNOTATION (based on $identifiedBy)
if($identifiedBy=~m|^(.+)|){
	$annotation="$scientificName; $1"
}
else{ $annotation=""; }


#########LOCALITY, HABITAT, OCCURRENCEREMARKS
##no processing required for $locality, $habitat, $occurrenceRemarks

#########COUNTY
foreach ($county){
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
		$v_county= &verify_co($_); #Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){ #If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&log_skip("NON-CA COUNTY? $_\t$id"); #run the &skip function, printing the following message to the error log
    		++$skipped{one};
            next Record;
        }

        unless($v_county eq $_){ #unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
            &log_change("COUNTY $_ -> $v_county\t$id"); #call the &log function to print this log message into the change log...
            $_=$v_county; #and then set $county to whatever the verified $v_county is.
        }
    }
}


########ELEVATION
#construct DwC verbatimElevation
if ($elevation){
	$verbatimElevation="$elevation $elev_units";
}
else {$verbatimElevation=""; }

#clean up and check units
foreach ($elev_units) {
	s/meters?/m/;
	s/feet/ft/;
	s/\.//;
}
if ($elev_units){
	unless ($elev_units eq "ft" || $elev_units eq "m"){
		warn "weird elev units >$elev_units<\t$id\n";
		&log_change("weird elev units >$elev_units<; elevation nulled\t$id");
		$elevation=$elev_units="";
	}
}

#isolate numeric value of elevation
foreach ($elevation){
	s/[~><\+±, ]//g;
}
#if ($elevation){
#	unless ($elevation=~/^([0-9.-]+)$/) {
	
		if(($elevation=~/^([0-9.-]+)([FfTtMm.]+)/) && ($elev_units eq "")){ #fix some really problematic elevations
			$elevation=$1;
			$elev_units=$2;
			$elev_units=~s/\.//;
			warn "elevation not numeric only >$id<\n";
			&log_change("elevation >$elevation< changed because not numeric; may contain units\t$id");
			}
#	}
#}

#######LATITUDE, LONGITUDE, etc.
#assemble verbatimLatitude and verbatimLongitude
$verbatimLatitude = "$lat_degn $lat_minn $lat_secn $lat_hem";
$verbatimLongitude = "$lon_degn $lon_minn $lon_secn $lon_hem";
foreach ($verbatimLatitude, $verbatimLongitude){
	s/^ *//;
	s/ $//;
	s/  */ /g;
}

#calculate decimalLatitude and decimalLongitude
$decimalLatitude= &dms2decimal($lat_degn, $lat_minn, $lat_secn);
$decimalLongitude= &dms2decimal($lon_degn, $lon_minn, $lon_secn);
if($decimalLongitude){
	unless ($decimalLongitude=~/^-/) {
		$decimalLongitude="-$decimalLongitude";
	}
}

#check lat and lon reversed
if($latitude=~/^-1\d\d/){
	$hold=$decimalLatitude;
	$decimalLatitude=$decimalLongitude;
	$decimalLatitude=$hold;
	&log_change("lat and long reversed; corrected for CCH\t$id");
}

#Check if outside California box
($decimalLatitude,$decimalLongitude)=&outside_CA_box($decimalLatitude,$decimalLongitude,$id);


####TOWNSHIP RANGE SECTION
#put prefixes if not there
if ($township) {
	unless ($township=~/^[Tt]/){
		$township=~"T$township";
	}
}
if ($range) {
	unless ($range=~/^[Rr]/){
		$range=~"R$range";
	}
}
if ($section) {
	unless ($section=~/^[Ss]/){
		$section=~"S$section";
	}
}

#assemble TRS
$T_R_Section="$township$range$section $quarter";
$T_R_Section=~s/ *$//;
$T_R_Section="" if $T_R_Section eq "0";

#T_R_Section is not a darwin core field but it is used by CCH
#for DwC, the whole $T_R_Section could be published as verbatimCoordinates
#with verbatimCoordinateSystem set as "Township Range Section" or similar


#print out the final printout
print OUT <<EOP;
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Accession_id: $id
Name: $scientificName
Date: $verbatimDate
EJD: $EJD
LJD: $LJD
Collector: $collector
Combined_collector: $recordedBy
Other_coll: $other_coll
Loc_other: $loc_other
Location: $locality
Habitat: $habitat
Macromorphology: $occurrenceRemarks
Country: USA
State: California
County: $county
Latitude: $verbatimLatitude
Longitude: $verbatimLongitude
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Elevation: $verbatimElevation
T/R/Section: $T_R_Section
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation
Notes: 

EOP
}

#Darwin Core values processed by this script but not output to CCH format:
#$recordNumber
#$identifiedBy