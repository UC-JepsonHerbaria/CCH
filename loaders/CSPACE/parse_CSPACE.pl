use lib '/Users/davidbaxter/DATA/';
use CCH;

my $extract_dir= "data_in/";

my $hybrid_file="${extract_dir}/cch_hybridparents.txt";
my $other_vouchers="${extract_dir}/cch_othervouchers.txt";
my $anno_vouchers="${extract_dir}/cch_annovouchers.txt";
my $types="${extract_dir}/cch_typespecimens.txt";
my $determinations="${extract_dir}/cch_determinations.txt";
my $accessions="${extract_dir}/cch_accessions.txt";
my $solr_file="4solr.ucjeps.public.csv";

open(IN,"$hybrid_file") || die "couldnt open $hybrid_file $!";
while(<IN>){
	chomp;
	#catalognumber	pos	hybridparentname	hybridparentqualifier
	@fields=split(/\t/);
	$fields[3]=~s/× //;
	$next_parent=&strip_name($fields[3]);
	if($hybrid{$fields[0]}){
		$hybrid{$fields[0]} .= " X $next_parent";
	}
	else{
		$hybrid{$fields[0]} = $next_parent;
	}
}
#foreach (sort(keys(%hybrid))){
#print "$_: $hybrid{$_}\n";
#}

#list of accession numbers to be skipped because they are photographs or are hort vouchers from several counties
#the right way to do this would be to
#1) have all these properly indicated as being photographs and hort vouchers in CCH
#2) export the "Cultivated" and "Form" stuff to CCH extract (or exclude photographs at that point
#3) export cultivated = yes to be used in CCH.
open(IN,"_excl") || die;
while(<IN>){
	chomp;
	$hort{$_}++;
}

%voucher_tags=(
				"data in packet" => "Data_in_packet",
				"micromorphology" => "Micromorphology",
				"macromorphology" => "Macromorphology",
				"cytology" => "Cytology",
				"reproductive biology" => "Reproductive_biology",
				"phenology" => "Phenology",
				"horticulture" => "Horticulture",
				"biotic interactions" => "Biotic_interactions",
				"associated taxa" => "Associated_species",
				"Vegetation Type Map" => "VTM",
				"odor" => "Odor",
);


#JEPS13972	Isotype	Saxifraga fragarioides Greene	W. L. J.
#JEPS14006	Type	Eryngium racemosum Jeps.	unknown
#List of type specimens

open(IN, $types) || die;
while(<IN>){
	chomp;
	($id,$tt,$bn,$ref)=split(/\t/);
	$TYPE{$id}{$tt}=$bn;
}

#Transfer to TYPE hash
foreach $id(keys(%TYPE)){
	if($TYPE{$id}{'Holotype'}){
		$store_voucher{$id}{TYPE}= "Holotype: $TYPE{$id}{'Holotype'}";
	}
		elsif($TYPE{$id}{'Isotype'}){
		$store_voucher{$id}{TYPE}= "Isotype: $TYPE{$id}{'Isotype'}";
	}
	elsif($TYPE{$id}{'Lectotype'}){
		$store_voucher{$id}{TYPE}= "Lectotype: $TYPE{$id}{'Lectotype'}";
	}
	elsif($TYPE{$id}{'Isolectotype'}){
		$store_voucher{$id}{TYPE}= "Isolectotype: $TYPE{$id}{'Isolectotype'}";
	}
	elsif($TYPE{$id}{'Neotype'}){
		$store_voucher{$id}{TYPE}= "Neotype: $TYPE{$id}{'Neotype'}";
	}
	elsif($TYPE{$id}{'Isoneotype'}){
		$store_voucher{$id}{TYPE}= "Isoneotype: $TYPE{$id}{'Isoneotype'}";
	}
	elsif($TYPE{$id}{'Epitype'}){
		$store_voucher{$id}{TYPE}= "Epitype: $TYPE{$id}{'Epitype'}";
	}
	elsif($TYPE{$id}{'Isoepitype'}){
		$store_voucher{$id}{TYPE}= "Isoepitype: $TYPE{$id}{'Isoepitype'}";
	}
	elsif($TYPE{$id}{'Type'}){
		$store_voucher{$id}{TYPE}= "Type: $TYPE{$id}{'Type'}";
	}
	elsif($TYPE{$id}{'Non-type'}){
		$store_voucher{$id}{TYPE}= "Not a Type: $TYPE{$id}{'Non-type'}";
	}
	elsif($TYPE{$id}{'Syntype'}){
		$store_voucher{$id}{TYPE}= "Syntype: $TYPE{$id}{'Syntype'}";
	}
	elsif($TYPE{$id}{'Isosyntype'}){
		$store_voucher{$id}{TYPE}= "Isosyntype: $TYPE{$id}{'Isosyntype'}";
	}
	elsif($TYPE{$id}{'Cotype'}){
		$store_voucher{$id}{TYPE}= "Cotype: $TYPE{$id}{'Cotype'}";
	}
	elsif($TYPE{$id}{'Unspecified type'}){
		$store_voucher{$id}{TYPE}= "Unspecified type: $TYPE{$id}{'Unspecified type'}";
	}
	elsif($TYPE{$id}{'Fragment'}){
		$store_voucher{$id}{TYPE}= "Type fragment: $TYPE{$id}{'Fragment'}";
	}
}
 #96 Cotype
 #376 Unspecified type


#named vouchers from list of annotations
open(IN, "$anno_vouchers") || die;
while(<IN>){
	chomp;
	($id,$csid,$type,$desc)=split(/\t/);
											#next unless $id eq "JEPS2760";
	$desc="_" if $desc=~/^ *$/;
	if($type=~/Vegetation Type Map Project/){
		$store_voucher{$id}{'VTM'}=$desc;
		$VK{$type}++;
	}
	elsif($type=~/population biology/){
		$store_voucher{$id}{'Population_biology'}=$desc;
		$VK{$type}++;
	}
	elsif($type=~/type/){
		$store_voucher{$id}{'type'}=$desc;
		$VK{$type}++;
	}
	elsif($type=~/other number/){
		$store_voucher{$id}{'Other_label_number'}=$desc;
		$VK{$type}++;
	}
}
close IN;
foreach $voucher (sort(keys(%VK))){
		warn "$voucher: $VK{$voucher}\n";
}
%VK=();
warn "=========\n";

#vouchers stuck in notes field
open(IN, "$other_vouchers") || die;
while(<IN>){
	chomp;
	($id,$csid,$notetype,$note)=split(/\t/);
											#next unless $id eq "JEPS2760";
	if($notetype eq "habitat"){
		$habitat{$id}=$note;
		$note="";
	}
	elsif($notetype eq "brief description"){
		if($note=~/includes/){
			#print "$note\n";
			@includes=split(/[; ]*includes /,$note);
			$note="";
			foreach $i (0 .. $#includes){
				if($includes[$i]=~s/;? ?(color): (.*)//){
					$store_voucher{$id}{"Color"}=$2;
					$VK{"Color"}++;
				}
				if($includes[$i]=~s/;? ?(data in packet|micromorphology|macromorphology|cytology|reproductive biology|phenology|biotic interactions|horticulture)[: ]*(.*)//){
					$desc=$2;
					$type=$voucher_tags{$1};
					$desc="_" if $desc=~/^ *$/;
					$store_voucher{$id}{$type}=$desc;
					$VK{$type}++;
				}
				else{
					$note.="$includes[$i]. ";
				}
			}
		}
		else{
				if($note=~s/;? ?(color): (.*)//){
					$store_voucher{$id}{"Color"}=$2;
					$VK{"Color"}++;
				}
				if($note=~s/;? ?(data in packet|micromorphology|macromorphology|cytology|reproductive biology|phenology|biotic interactions|horticulture)[: ]*(.*)//){
					$store_voucher{$id}{$voucher_tags{$1}}=$2;
					$VK{$voucher_tags{$1}}++;
				}
			}
		}
	elsif($notetype eq "comment"){
		$note=~s/county supplied by Wetherwax; *//;
		if($note=~s/(material removed):? (.*)//){
			$store_voucher{$id}{$1}=$2;
			$VK{$1}++;
		}
		if($note=~/includes/){
			@includes=split(/[; ]*includes /,$note);
			$note="";
			foreach $i (0 .. $#includes){
				if($includes[$i]=~s/(associated taxa|data in packet|odor):? ?(.*)//){
					die ">$1< $_\n"  unless $voucher_tags{$1};
					$store_voucher{$id}{$voucher_tags{$1}}=$2;
					$VK{$voucher_tags{$1}}++;
				}
				else{
					$note.="$includes[$i]. ";
				}
			#print "$note\n";
			}
		}
		else{
				if($note=~s/(associated taxa):? ?(.*)//){
					$desc=$2;
					$type="Associated_species";
					$desc="_" if $desc=~/^ *$/;
					$store_voucher{$id}{$type}=$desc;
					$VK{$type}++;
				}
				elsif($note=~s/(data in packet):? ?(.*)//){
					$desc=$2;
					$type="Data_in_packet";
					$desc="_" if $desc=~/^ *$/;
					$store_voucher{$id}{$type}=$desc;
					$VK{$type}++;
				}
				elsif($note=~s/(Vegetation Type Map Project):? ?(.*)//){
					$desc=$2;
					$type="VTM";
					$desc="_" if $desc=~/^ *$/;
					$store_voucher{$id}{$type}=$desc;
					$VK{$type}++;
				}
				else{
					$note{$id}=$note;
				}
			#print "\n$note\n";
		}
			#print "$note\n";
	}
	else{
		#unexpected note type?
		print "unexpected note type\t$_\n";
	}
	$note{$id}=$note unless $note{$id};
}


close(IN);
foreach $voucher (sort(keys(%VK))){
		warn "$voucher: $VK{$voucher}\n";
}
%VK=();


##########GET IMAGE LINKS FROM CSPACE PUBLIC PORTAL SOLR DUMP

open(IN, "$solr_file") || die;
while(<IN>){
	$solr_blob="";
	chomp;
	@solr_fields=split(/\t/,$_,100);

#The number of fields in the solr core changes over time as more fields are added
#however the image_blob field has always been last, and csid should remain in position [1]
$solr_csid = $solr_fields[1];
$solr_blob = $solr_fields[$#solr_fields];
next unless $solr_blob;

if ($solr_blob =~ /(.*),(.*)/){
	$solr_blob = $1
}
else {
	($solr_blob = $solr_blob);
}

$IMG{$solr_csid} = "https://ucjeps.cspace.berkeley.edu/ucjeps_project/imageserver/blobs/$solr_blob/derivatives/OriginalJpeg/content";
}

##########END IMAGE PROCESSING


open(IN, "$determinations") || die;
#annotation history
while(<IN>){
	$det_string="";
next if m/bulkloaded from norris/;
next if m/D\. *H\. Norris/;
	chomp;
	($Accession_Number,
	$csid,
	$Determination_Position,
	$Taxon_Name,
	$Qualifier,
	$ID_By,
	$ID_Date,
	$ID_Kind,
	$Notes) = split(/\t/);
											#next unless $Accession_Number eq "JEPS2760";
	$Notes=~s/ *Data Source: Accession sheet//;
	if(m/original label/){
		unless(s/nocl/Identification on label/){
			$Notes="Identification on label. $Notes";
		}
	}
	$Notes=~s/nocl/Identification on label/;
	#print "$Notes\n" if $Notes;
	$det_string="$Taxon_Name, $ID_By, $ID_Date, $Notes";
	$ANNO{$Accession_Number}.="Annotation: $det_string\n";
}

##########Add Country and State (to allow exclusion of Mexico specimens with missing county data
$solr_file="4solr.ucjeps.public.csv";
open(IN,"$solr_file") || die "couldnt open $solr_file $!";
while(<IN>){
	chomp;
        @fields=split(/\t/, $_,100);
        $group=$fields[5];
        $accession=$fields[2];
        $country=$fields[16];
        $state=$fields[15];
        $county=$fields[14];
        $locality=$fields[13];
        
#		next unless ($country =~ /Mexico/);
#		next unless ((length($county) == 0) || 
		next if ($group =~ /(Algae|Bryophytes)/);

$COUNTRY{$accession}=$country;
$COUNTY{$accession}=$county2;
$STATE{$accession}=$state;
}

##########
use Time::JulianDay;
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

open(DUP, ">UCJEPS_DUP.txt") || die;
&load_noauth_name; #FROM CCH.pm
#Load names of non-vascular genera to be excluded
open(IN, "/Users/davidbaxter/DATA/mosses") || die;
while(<IN>){
	chomp;
	s/ .*//;
	$exclude{$_}++;
}
close(IN);



open(OUT, ">CSPACE.out") || die;

foreach ($accessions){

	open(IN,$accessions) || die;
	open(CSID, ">AID_CSID.txt") || die;
	Record: while(<IN>){
		chomp;
		@fields=split(/\t/, $_, 100);
		($SpecimenNumber,
		$csid,
		$Determination,
		$Collector,
		$CollectorNumber,
		$CollectionDate,
		$EarlyCollectionDate,
		$LateCollectionDate,
		$Locality,
		$County,
		$Elevation,
		$MinElevation,
		$MaxElevation,
		$Elevation_unit,
		$Habitat,
		$DecLatitude,
		$DecLongitude,
		$loc_coords_TRS,
		$Datum,
		$CoordinateSource,
		$CoordinateUncertainty,
		$CoordinateUncertaintyUnit,
		) = @fields;
		#print "$Elevation, $MinElevation, $MaxElevation, $Elevation_unit,\n";

	$Other_coll= $Combined_coll="";

	foreach($Collector){
		if(s/^(.*) with (.*)$/$1/){
			$Other_coll=$2;
			$Combined_coll="$1, $2";
		}
		elsif(s/^(.*) \[with (.*)\]?/$1/){
			$Other_coll=$2;
			$Combined_coll="$1, $2";
		}
	}
	
##################Exclude known problematic specimens from Baja California and other States in Mexico with unknown or blank county field
# if ($SpecimenNumber =~/^(10615070|8720137|3132405|1939552|1939555|9372982|3157806|4182802|982039|982186|986591|10570608|10929212|3150102|3269779|904990|10571329|1940962|957093|4962440|5001448|10593214|10572572|10678657|3129513|903956|10932808|8735151|7718784|10796230|3148362|10678725|10743352|10500255|5501463|3132653|1912776|7247972|3145054|10550870|10546591|10531453|10755578|10794450|10794455|10969903|6165250|10870828|178669|4177487|10846560|1939654|10727925|1939566|3132654|6165302|3132655|5501705|5501448|5501418|5501427|6165662|5500734|6165216|1939553|6165097)$/){
#	&skip("Mexico record with unknown or blank county field\t$id\t--\t$locality");
#		++$skipped{one};
#		next Record;
#	}
##################	

($possible_skip=$Determination)=~s/ .*//;
if($exclude{$possible_skip}){
$excl_NV{$possible_skip}++;
next Record;
}

	
#Remove duplicates
	if($seen{$SpecimenNumber}++){
		++$skipped{one};
		warn "Duplicate number: $fields[0]<\n";
		print DUP<<EOP;
Duplicate accession number, skipped: $fields[0]
EOP
		next;
	}

###########REMOVE FIELD STATION IDs for now
	if ($SpecimenNumber =~/(BFRS|HREC|SCFS)/){
		next;
	}
##################
		#####exclude cultivated stuff from _excl list
#		if($hort{$SpecimenNumber}){
			#&log_skip("Skipped $SpecimenNumber hort or bad magic"); disabled now
			#next;
#		}
#####finish process of cultivated specimens
	if ($cultivated =~ m/TRUE/){
		$cult eq "P";
		&log("Cultivated specimen, needs to be purple flagged\t--\t$scientificName\n");
	}
	else{
		$cult =	&flag_cult($cult);
	}

		$CoordinateUncertainty="" if $CoordinateUncertainty==0;


		$name=&strip_name($Determination);

		if($name=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
        	$hybrid_annotation=$name;
            warn "$1 from $name\n";
            &log_change("$1 from $name");
            $name=$1;
        }
        else{
           	$hybrid_annotation="";
        }

$name= &validate_scientific_name($name, $SpecimenNumber);
$name=~s/unknown//;
$name=~s/ *$//;
#added to try to remove the word "unknown" for some new records



#############ELEVATIONS##########

$MinElevation=~s/^ *$//;
$MaxElevation=~s/^ *$//;
$Elevation=~s/^ *$//;
if($MinElevation && $MaxElevation){
	if($Elevation_unit){
		$Elevation="${MinElevation}-${MaxElevation} $Elevation_unit";
		if(${MinElevation} == ${MaxElevation}){
			$Elevation="${MinElevation} $Elevation_unit";
			&log_change("Superfluous elevation  $_");
		}
	}
	else{
		#warn "$Elevation no units\n";
		$Elevation="";
		&log_change("Elevation lacking units $_");
	}
}
elsif($MinElevation || $MaxElevation){
	$Elevation= ($MinElevation || $MaxElevation);
	if($Elevation_unit){
		$Elevation.=" $Elevation_unit";
	}
	else{
		#warn "$Elevation no units\n";
		$Elevation="";
		&log_change("Elevation lacking units $_");
	}
}
elsif($Elevation){
	unless($Elevation=~/[FfMm]/){
		if($Elevation_unit){
			$Elevation .= " $Elevation_unit";
		}
		else{
			if($Elevation=~/^(0|zero|sea level)/){
				$Elevation= "0 ft";
			}
			else{
				$Elevation="";
				&log_change("Elevation lacking units $_");
			}
		}
	}
}
foreach($Elevation){
	#print "$_\t";
	s/ elev.*//;
	s/ <([^>]+)>/ $1/;
	s/^\+//;
	s/^\~/ca. /;
	s/zero/0/;
	s/,//g;
	s/(Ft|ft|FT|feet|Feet)/ ft/;
	s/(m|M|meters?|Meters?)/ m/;
	s/\.$//;
	s/  +/ /g;
}


########COLLECTOR NUMBER
if($CollectorNumber){
	($prefix, $CNUM,$suffix)=&parse_CNUM($CollectorNumber);
}
else{
	$prefix= $CNUM=$suffix="";
}


###########COUNTIES
foreach($County){


	s/Unknown/unknown/;
	
	if((length($County) == 0) && ($COUNTRY{$SpecimenNumber} =~m/Mexico/)){
		&log_change("Mexico record with unknown or blank county field\t$id\t--\t$locality");
			++$skipped{one};
			next Record;
	}
	if(($County=~m/unknown/) && ($COUNTRY{$SpecimenNumber} =~m/Mexico/)){
		&log_change("Mexico record with unknown or blank county field\t$id\t--\t$Locality");
			++$skipped{one};
			next Record;
	}
	
	s/^$/unknown/;
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Tecate|Tijuana|Rosarito, Playas de|unknown)$/){
		$v_county= &verify_co($_);
		if($v_county=~/SKIP/){
			&log_change("SKIPPED NON-CA county? $_\t$SpecimenNumber\n");
			next Record;
		}   
	   	unless($v_county eq $_){
			&log_change("$fields[0] $_ -> $v_county\n");
			$_=$v_county;
		}   
	}   
	
}

 ######################Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $stateProvince\t--\t$County\t--\t$locality\t$id");		
	}

  
					
					
#########COLLECTION DATES
if( $EarlyCollectionDate=~m/^(\d+)-(\d+)-(\d+)/){
	$EJD=julian_day($1, $2, $3);
	if( $LateCollectionDate=~m/^(\d+)-(\d+)-(\d+)/){
		$LJD=julian_day($1, $2, $3);
	}
	else{
		$LJD=$EJD;
	}
}
else{
	$EJD=$LJD="";
}
################################################## KLUGE TO COMPENSATE FOR A CSPACE  SINGLE DAY PROBLEM #####################
if($LJD-$EJD==1 && $CollectionDate !~/-/){
#print "$SpecimenNumber\t$CollectionDate\t$EarlyCollectionDate\t$LateCollectionDate\n";
$EJD+=1;
}
#############################################################################################################################



#get rid of carriage return in Locality
		$Locality=~s/\\n/ /g;
		if($hybrid{$SpecimenNumber}){
			($name=$hybrid{$SpecimenNumber})=~s/ .*//;
			$hybrid_anno= "$hybrid{$SpecimenNumber}   hybrid parentage";
		}
		else{
			$hybrid_anno= "";
		}
		if($DecLongitude=~/^1\d\d/){
			print "$SpecimenNumber $DecLongitude\n";
			$DecLongitude=~s/^/-/;
			&log_change("$SpecimenNumber: minus added to longitude");
		}
	
		$note{$SpecimenNumber}=~s/^[ .]*$//;


print CSID "$SpecimenNumber\t$csid\n";
		print OUT <<EOP;
Accession_id: $SpecimenNumber
Name: $name
Collector: $Collector
Date: $CollectionDate
EJD: $EJD
LJD: $LJD
CNUM: $CNUM
CNUM_prefix: $prefix
CNUM_suffix: $suffix
Country: $COUNTRY{$SpecimenNumber}
State: $STATE{$SpecimenNumber}
County: $County
Location: $Locality
T/R/Section: $loc_coords_TRS
Elevation: $Elevation
Other_coll: $Other_coll
Combined_coll: $Combined_coll
Decimal_latitude: $DecLatitude
Decimal_longitude: $DecLongitude
Lat_long_ref_source: $CoordinateSource
Datum: $Datum
Max_error_distance: $CoordinateUncertainty
Max_error_units: $CoordinateUncertaintyUnit
Hybrid_annotation: $hybrid_anno
Cultivated: $cult
Habitat: $habitat{$SpecimenNumber}
Notes: $note{$SpecimenNumber}
Image: $IMG{$csid}
EOP
++$included;

		foreach $voucher (
			"VTM",
			"Associated_species",
			"Biotic_interactions",
			"Color",
			"Data_in_packet",
			"Macromorphology",
			"Micromorphology",
			"Phenology",
			"Population_biology",
			"Reproductive_biology",
			"Other_label_number",
			"Horticulture"
			){
#print "$SpecimenNumber $voucher--------->";
			if($store_voucher{$SpecimenNumber}{$voucher}){
				if(length($store_voucher{$SpecimenNumber}{$voucher}) > 1){
					print OUT "$voucher: $store_voucher{$SpecimenNumber}{$voucher}\n";
			#print "$voucher: $store_voucher{$SpecimenNumber}{$voucher}\n";
				}
			else{
				###These are voucher information like "includes macromorphology" from the SMASCH days, when existence of voucher information was indicated but not transcribed
				###We don't publish these, because it looks weird
				#print OUT "$voucher: Data on label not transcribed.\n";
				#print "$voucher: Data on label not transcribed.\n";
			}
		}
	}
	if($store_voucher{$SpecimenNumber}{TYPE}){
		print OUT "Type_status: $store_voucher{$SpecimenNumber}{TYPE}\n";
	}
	elsif($store_voucher{$SpecimenNumber}{type}){
		print OUT "Type_status: $store_voucher{$SpecimenNumber}{type}\n";
	}
	print OUT $ANNO{$SpecimenNumber};
	print OUT "\n";


	}
}

}


print <<EOP;
INCL: $included
EXCL: $skipped{one}
EOP

print "Excluded as non vascular\n", join("\n",sort(keys(%excl_NV))), "\n";


close(IN);
close(OUT);
close(DUP);

#print out the dupes at the end so you won't miss them
open(DATA, "<UCJEPS_DUP.txt" ) or die "Can't open $file : $!";
while( <DATA> ) {
	print "$_";
}
close DATA;

