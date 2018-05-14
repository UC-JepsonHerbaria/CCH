use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA';	
use CCH; #loads non-vascular plant names list ("mosses"), alter_names table, and max_elev values
&load_noauth_name; #loads taxon id master list (smasch_taxon_ids.txt) into an array %TID
$today_JD = &get_today_julian_day;

open(OUT, ">OBI.out") || die;

my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";


#Note: OBI file received as Excel spreadsheet
#Open in Excel then save as tab-delimited txt
#remove MS line breaks
#remove enclosing quotes
$current_file="OBIDATA_Dec_2015.txt";

open(IN, $current_file) || die; 
while(<IN>){
	chomp;
	&CCH::check_file;
}
close(IN);


open(IN, "$current_file") || die;
Record: while(<IN>){
	chomp;
	(@fields)=split(/\t/,$_,100);
	grep(s/^"(.*)"/$1/,@fields); #fix double-double quotes within fields
	unless( $#fields==48){
		&log_skip("$#fields Fields not 49 $_");
		next;
	}
($Accession_number,
$Date_entered, #OBI curatorial field
$Entered_by,
$Search_no,
$Status,
$Collector,
$Collection_no,
$additional_collectors,
$TJM2_Family,
$TJM2_binomial,
$Binomial_on_label,
$same_different, #OBI curatorial field
$Jenn_Yost, #OBI curatorial field
$author_of_binomial,
$subspecies_epithet,
$variety_epithet,
$forma_epithet,
$x_hybrid_epithet,
$infraspecific_epithet_author,
$Annotation,
$Date_B,
$translated_date, #I created this field using the =TEXT function in Excel
$Country,
$State,
$County,
$Collection_locality,
$General_habitat,
$Specific_habitat_abundance,
$Plant_description,
$elev_ft,
$elev_m,
$Origin_of_sheet, #OBI curatorial field
$Notes,
$Y_Lat,
$X_Long,
$Error_Radius,	#NOTE: This field newly added but not populated. Not incorporated in parser yet because not defined
$Georef_Source,	#NOTE: This field newly added but not populated. Not incorporated in parser yet because not defined
$Zone,
$NAD,
$UTM_East,
$UTM_North,
$T_R,
$X_LongMin,
$X_LongMax,
$Y_LatMin,
$Y_LatMax,
$Datum,
$OBI_Collection, #OBI curatorial field
$Loan #OBI curatorial field
)=@fields;


########ACCESSION NUMBER
#hereafter referred to as id
$id=$Accession_number;
#check for nulls
unless ($id=~/^\d+$/){
	&log_skip("Accession number $id is uncertain -> $_");
	next;
}
#add prefix
$id="OBI$id";

#remove duplicates
if($seen{$id}++){
	++$skipped{one};
	warn "Duplicate accession number: $id<\n";
	&log_skip("Duplicate accession number\t$id");
	next;
}


#####COUNTRY
if ($Country){ #ignore records where $Country is blank
	unless($Country=~/USA|United States|^ *$/i){ #Unless Country is USA or spaces only,
	&log_skip("Country $Country not USA\t$id"); #skip it
	next;
	}
}

######STATE
if ($State){
	unless($State=~/^CA$|^California$|^ *$/i){
	#if($State=~/(AK|AZ|Alaska|Arizona|Az|Baja|Baja_Calif_Sur|Baja_California|CO|Chihuahua|Colorado|Free_State_Province|Guam|Guerro|Hawaii|IL|Idaho|Illinois|Kwazulu-natal_Province|Michoacan|Missouri|Montana|Morelos|Mpumalanga_Province|NE|NM|NV|Nevada|New_Mexico|New Mexico|Northwest_Province|Nuevo_Leon|OR|Oaxaca|Oregon|Puebla|SD|Sinaloa|Sonora|State|Tamaulipas|UT|Utah|WA|WY|Washington|Wisconsin|Wyoming)$/){
	&log_skip("State $State not CA\t$id");
	next;
	}
}


#############DATE
$EJD=$LJD="";
$YYYY=$MM=$DD=$late_YYYY=$late_MM=$late_DD="";
#up to the most recent load (Sept 2014), dates were unhelpfully converted to variable date formats by Excel.
#This parsing uses a date-to-text column I added to the Excel file myself
#using the formula '=TEXT(S2,"m/dd/yyyy")'
#note that many dates do not get translated properly by Excel,
#those are handled subsequently

my %month_hash = &month_hash;

foreach($translated_date){
	s/,//g; #remove commas from untranslated dates to make them simpler to work with
	s/^ *//g;
	s/ *$//g;
}
#atomize days months and years
if ($translated_date eq '1/00/1900'){ #how Excel translates an empty string as a date
	&log_change("no date recorded $id");
	$YYYY=$MM=$DD="";
}
elsif ($translated_date =~ /^(\d\d?)\/(\d\d?)\/(\d\d\d\d)$/){ #OBI records dates as m/d/yyyy
	$MM = $1;
	$DD = $2;
	$YYYY = $3;
}
elsif ($translated_date =~ /^([A-Za-z]+) (\d\d?)-(\d\d?) (\d\d\d\d)$/){ #e.g. May 22-25, 1993
	$MM = $1;
	$DD = $2;
	$late_DD = $3;
	$YYYY = $4
}
elsif ($translated_date =~ /^([A-Za-z]+) (\d\d?) (\d\d\d\d)$/){ #e.g. May 22-25, 1993
	$MM = $1;
	$DD = $2;
	$YYYY = $3;
}
elsif ($translated_date =~ /^(\d\d?)-(\d\d?) ([A-Za-z]+) (\d\d\d\d)$/){ #e.g. 17-19 Aug 1984
	$DD=$1;
	$late_DD=$2;
	$MM=$3;
	$YYYY=$4;
}
elsif ($translated_date =~ /^(\d\d?) ([A-Za-z]+) (\d\d\d\d)$/){ #e.g. 17 Aug 1984
	$DD=$1;
	$MM=$2;
	$YYYY=$3;
}
elsif ($translated_date =~ /^([A-Za-z]+) (\d\d\d\d)$/){ #e.g. August 1957
	$MM = $1;
	$YYYY = $2;
}
elsif ($translated_date =~ /^(\d\d\d\d) ([A-Za-z]+) (\d\d?)$/){ #e.g. 1957 August
	$MM = $1;
	$YYYY = $2;
	$DD = $3;
}
elsif ($translated_date =~ /^(\d\d\d\d) ([A-Za-z]+)$/){ #e.g. 1957 August
	$MM = $1;
	$YYYY = $2;
}


elsif ($translated_date){
	&log_change("date not in predicted format $translated_date\t$id");
	$YYYY=$MM=$DD="";
}

$MM = &get_month_number($MM, $id, %month_hash);

####Right now, OBI is the only one where I have started handling more complex date formats
####This should be turned into a subroutine i.e. &make_julian_days_complex
if ($YYYY && $MM && $DD && $late_DD){
	$EJD=julian_day($YYYY, $MM, $DD);
	$LJD=julian_day($YYYY, $MM, $late_DD);
}
if ($YYYY && $MM && $DD){
	$EJD=julian_day($YYYY, $MM, $DD);
	$LJD=$EJD;
}
elsif($YYYY && $MM){	
	if($MM==12){	
		$EJD=julian_day($YYYY, $MM, 1);	
		$LJD=julian_day($YYYY, $MM, 31);
	}
	else{
		$EJD=julian_day($YYYY, $MM, 1);
		$LJD=julian_day($YYYY, $MM+1, 1);
		$LJD -= 1;
	}
}
else{
	$EJD=$LJD="";
}

($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);





####COORDINATES
$decimalLatitude = $Y_Lat;
$decimalLongitude = $X_Long;
if(($decimalLatitude=~/\d/ && $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
	if ($decimalLongitude > 0) {
		$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
		&log_change("minus added to longitude\t$id");
	}	
	if($decimalLatitude > 42.1 || $decimalLatitude < 32.5 || $decimalLongitude > -114 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
		&log_change("coordinates set to null, Outside California: >$latitude< >$longitude<\t$id");	#print this message in the error log...
		$decimalLatitude =$decimalLongitude="";	#and set $decLat and $decLong to ""
	}
}



#######NAME###########

#Infra epithets are processed in the following order
#Because when there are multiple levels of infraspecific taxonomy indicated
#the lowest rank is the correct infra epithet for the scientific name
#thus, f. has priority over var., and var. over subsp.
if ($forma_epithet){
	$Binomial_on_label = "$Binomial_on_label f. $forma_epithet";
}
elsif ($variety_epithet){
	$Binomial_on_label = "$Binomial_on_label var. $variety_epithet";
}
elsif ($subspecies_epithet){
	$Binomial_on_label = "$Binomial_on_label subsp. $subspecies_epithet";
}
elsif ($x_hybrid_epithet){
	$Binomial_on_label = "$Binomial_on_label X $x_hybrid_epithet";
}
else {
	$Binomial_on_label = $Binomial_on_label;
}

unless($Binomial_on_label eq $TJM2_binomial){
	if($Annotation){
		$Annotation .= "; $Binomial_on_label, label,";
	}
	else{
		$Annotation = "$Binomial_on_label, label," if $Binomial_on_label;
	}
}
#print "$Binomial_on_label -> $TJM2_binomial -> $Annotation\n";
$Annotation=~s/; /\nAnnotation: /g;
$Annotation=~s/, */; /g;

$name=$TJM2_binomial;
if($name=~/^ *$/){
	$name=$Binomial_on_label;
}
foreach($name){
		s/^ *//;
		s/ *$//;
		s/  */ /g;
}
$name= ucfirst(lc($name)); #added because they have the problem of Excel capitalizing after a period
foreach($name){
	$old_name = $name;
	if(m/ (cf|aff)\./){
		if($Notes){
			$Notes .= "; as $_";
		}
		else{
			$Notes .= "as $_";
		}
		s/ (cf|aff)\.//;
		&log_change("$old_name altered to $_");
	}
	s/ ssp.? / subsp. /;
	s/ su[sb]p.? / subsp. /;
	s/ su[nb]sp\.? / subsp. /;
	s/ var / var. /;
	s/ var \. / var. /;
	s/ x / X /;
	s/ sp\.?$//;
}

if($name=~/([A-Z][a-z-]+ [a-z-]+) X /){
	$hybrid_annotation=$name;
	warn "$1 from $name\n";
	$name=$1;
}
elsif($name=~/([A-Z][a-z-]+ [a-z-]+ (var\.|subsp\.) [a-z-]+) X /){
	$hybrid_annotation=$name;
	warn "$1 from $name\n";
	$name=$1;
}
else{
	$hybrid_annotation="";
}

if($name=~/([A-Z][a-z-]+ [a-z-]+) \+ /){
	&log_change("$1 from $name\n");
	$name=$1;
}
elsif($name=~/([A-Z][a-z-]+ [a-z-]+) and /){
	&log_change("$1 from $name\n");
	$name=$1;
}

$name = &validate_scientific_name($name, $id);

###########COUNTY###########
foreach($County){
	s/^ *//;
	s/ *$//;
	s/  */ /g;
	s/-.*//;
	s/ Co\.//;
	s/ County//;
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
				&log_skip("$id NON-CA COUNTY? $_");	#run the &skip function, printing the following message to the error log
				++$skipped{one};
				next;
			}

			unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
				&log_change("$id COUNTY $_ -> $v_county");		#call the &log function to print this log message into the change log...
				$_=$v_county;	#and then set $county to whatever the verified $v_county is.
			}


		}
	}



if($elev_ft=~/\d/){
$elevation=$elev_ft;
$elevation=~s/ *$//;
$elevation=~s/^ *//;
$elevation=~s/fe*t\.?//;
$elevation .= " ft";
}
elsif($elev_m=~/\d/){
$elevation=$elev_m;
$elevation=~s/ *$//;
$elevation=~s/^ *//;
$elevation=~s/ ?m\.?//;
$elevation .= " m";
}
else{
$elevation="";
}
$Collection_no=~s/^[" ]+(.*)[ "]+$/$1/;
if($Collection_no=~/^\d+$/){
$CNP=""; $CNS="";
}
elsif($Collection_no=~/s\.? ?n\.?/){
$Collection_no=""; $CNP=""; $CNS="";
}
elsif( $Collection_no=~/^(\d+[^\d])(\d+)$/){
$Collection_no="$2"; $CNP="$1"; $CNS="";
}
elsif( $Collection_no=~/^(\d+)([^\d]+)$/){
$Collection_no="$1"; $CNP=""; $CNS="$2";
}
elsif( $Collection_no=~/^([^\d]+)(\d+)$/){
$Collection_no="$2"; $CNP="$1"; $CNS="";
}
elsif( $Collection_no=~/^([^\d]+)(\d+)([^\d].*)$/){
$Collection_no="$2"; $CNP="$1"; $CNS="$3";
}
else{
$Collection_no=""; $CNP=""; $CNS="$Collection_no";
}

if($General_habitat){
$General_habitat .= "; $Specific_habitat_abundance" if $Specific_habitat_abundance;
}
else{
$General_habitat = "$Specific_habitat_abundance" if $Specific_habitat_abundance;
}
$Datum=~s/, (.*)/\nSource: $1/;

if($decimalLatitude || $decimalLongitude){
    unless( $decimalLongitude=~/^-\d+\.?\d*$/ && $decimalLatitude =~/^\d+\.?\d*$/){
		&log_change("$id: Unexpected coord format-- coords nulled.  Long was $decimalLongitude, Lat was $decimalLatitude");
		$decimalLongitude="";
		$decimalLatitude = "";
	}
}

print OUT <<EOP;
Date: $Date_B
EJD: $EJD
LJD: $LJD
CNUM_prefix: $CNP
CNUM: $Collection_no
CNUM_suffix: $CNS
Name: $name
Accession_id: $id
County: $County
Loc_other: $Physiographic_region
Location: $Collection_locality
T/R/Section: $Unified_TRS
USGS_Quadrangle: $topo_quad
Elevation: $elevation
Collector: $Collector
Other_coll: $additional_collectors
Habitat: $General_habitat
Notes: $Notes
Macromorphology: $Plant_description
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $Datum
Annotation: $Annotation
Hybrid_annotation: $hybrid_annotation
Type_status: $Kind_of_type

EOP

}
