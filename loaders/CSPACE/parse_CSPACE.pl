use lib '/Users/richardmoe/4_DATA/CDL';
use CCH;

$extract_dir= "data_in/";


#TRS from smasch.
#Temporarily necessary because the extract is skipping verbatim_coordinates sometimes
open(IN,"trs_not_null") || die;
while(<IN>){
chomp;
($id,$trs)=split(/\t/);
$smasch_trs{$id}=$trs;
}
close_IN;


$hybrid_file="${extract_dir}/cch_hybridparents.txt";
$other_vouchers="${extract_dir}/cch_othervouchers.txt";
$anno_vouchers="${extract_dir}/cch_annovouchers.txt";
$types="${extract_dir}/cch_typespecimens.txt";
$determinations="${extract_dir}/cch_determinations.txt";
$accessions="${extract_dir}/cch_accessions.txt";

open(IN,"name_apostr_incl.txt") || die;
while(<IN>){
	chomp;
($id,$name)=split(/\t/);
$apos_name{$id}=$name;
}
close(IN);



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

open(IN,"_excl") || die;
#list of accession numbers to be skipped because they are photographs or are hort vouchers from several counties
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
	elsif($TYPE{$id}{'Type'}){
		$store_voucher{$id}{TYPE}= "Type: $TYPE{$id}{'Type'}";
	}
	elsif($TYPE{$id}{'Syntype'}){
		$store_voucher{$id}{TYPE}= "Syntype: $TYPE{$id}{'Syntype'}";
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
		print "UN NT $_\n";
	}
	$note{$id}=$note unless $note{$id};
}


close(IN);
foreach $voucher (sort(keys(%VK))){
		warn "$voucher: $VK{$voucher}\n";
}
%VK=();



#foreach $id (keys(%store_voucher)){
##print "$id\t";
#foreach $voucher (
	#"VTM",
	#"Associated_species",
	#"Biotic_interactions",
	#"Color",
	#"Data_in_packet",
	#"Macromorphology",
	#"Micromorphology",
	#"Phenology",
	#"Population_biology",
	#"Reproductive_biology",
	#"Horticulture",
	#){
	#if($store_voucher{$id}{$voucher}){
	##print "$voucher -> $voucher{$id}{$voucher}\t";
#}
#}
##print "\n";
#}



#die;

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
	$det_string="$Taxon_Name; $ID_By; $ID_Date; $Notes";
	$ANNO{$Accession_Number}.="Annotation: $det_string\n";
}

use Time::JulianDay;
open(ERR, ">UCJEPS_ERROR.txt") || die;
&load_noauth_name; #FROM CCH.pm
#Load names of non-vascular genera to be excluded
open(IN, "/Users/richardmoe/4_CDL_BUFFER/smasch/mosses") || die;
while(<IN>){
	chomp;
	s/ .*//;
	$exclude{$_}++;
}
close(IN);

open(OUT, ">CSPACE.out") || die;
#supplement.out is list of records under numbers that suffered collision upon migration of Smasch to CSPACE
open(IN,"supplement.out") || die;
while(<IN>){
	print OUT;
}
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
#if($Determination=~/Campylium/){
#print ">$Determination<\n";
#}
$Determination=~s/^ +//;
if($Determination=~/Campylium/){
print ">$Determination<\n";
}
($possible_skip=$Determination)=~s/ .*//;
if($exclude{$possible_skip}){
$excl_NV{$possible_skip}++;
next Record;
}
if($Determination=~/Campylium/){
print "not skipped >$Determination<\n";
}
if ($dup{$SpecimenNumber}){
print "DUP: $SpecimenNumber $Determination\n     $dup{$SpecimenNumber}"
}
$dup{$SpecimenNumber}.= "$SpecimenNumber  $Determination\n";
		$loc_coords_TRS=~s/TRS: //;

###########################REMOVE AFTER EXTRACT IS WORKING with COORDS ####################
unless($loc_coords_TRS){
if($smasch_trs{$SpecimenNumber}){
		$loc_coords_TRS=$smasch_trs{$SpecimenNumber};
#warn "TRS added $loc_coords_TRS\n";
}
}
		if($hort{$SpecimenNumber}){
			#&log("Skipped $SpecimenNumber hort or bad magic\n");
			next;
		}
											#next unless $SpecimenNumber eq "JEPS2760";
		if($Determination=~/^\s*$/){
			#&log("Skipped $SpecimenNumber No name\n");
			next;
		}
		if($Determination=~/^No name$/i){
			#&log("Skipped $SpecimenNumber No name\n");
			next;
		}
		$CoordinateUncertainty="" if $CoordinateUncertainty==0;
		$name=&strip_name($Determination);

		if($name=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
                 	$hybrid_annotation=$name;
                 	warn "$1 from $name\n";
                 	&log("$1 from $name");
                 	$name=$1;
        	}
        	else{
           	$hybrid_annotation="";
        	}

		($genus=$name)=~s/\s.*//;

		if($exclude{$genus}){
        		&log("Excluded, not a vascular plant: $name");
        		++$skipped{one};
        		next Record;
		}

		%infra=( 'var.','subsp.','subsp.','var.');

#print "N>$name<\n";
		$test_name=&strip_name($name);
#print "TN>$test_name<\n";

		if($TID{$test_name}){
        		$name=$test_name;
		}
		elsif($alter{$test_name}){
        		&log("$SpecimenNumber $Determination altered to $alter{$test_name}");
                	$name=$alter{$test_name};
		}
		elsif($test_name=~s/(var\.|subsp\.)/$infra{$1}/){
        		if($TID{$test_name}){
                		&log("$SpecimenNumber $Determination not in SMASCH  altered to $test_name");
                		$name=$test_name;
        		}
        		elsif($alter{$test_name}){
                		&log("$SpecimenNumber $name not in smasch  altered to $alter{$test_name}");
                		$name=$alter{$test_name};
        		}
        		elsif($apos_name{$SpecimenNumber}){
                		&log("$SpecimenNumber $name has apostrophe problem  kluged to $apos_name{$SpecimenNumber}");
                		$name=$apos_name{$SpecimenNumber};
        		}
        		else{
                		&log ("$SpecimenNumber $Determination is not yet in the master list: $name skipped");
                		++$skipped{one};
                		next Record;
        		}
		}
		else{
        		if($apos_name{$SpecimenNumber}){
                		&log("$SpecimenNumber $name has apostrophe problem  kluged to $apos_name{$SpecimenNumber}");
                		$name=$apos_name{$SpecimenNumber};
        		}
			else{
        			&log ("$SpecimenNumber $Determination is not yet in the master list: $name skipped");
        			#print "$Determination is not yet in the master list: $name skipped";
        			++$skipped{one};
        			next Record;
			}
		}

		$MinElevation=~s/^ *$//;
 		$MaxElevation=~s/^ *$//;
 		$Elevation=~s/^ *$//;
		if($MinElevation && $MaxElevation){
			if($Elevation_unit){
				$Elevation="${MinElevation}-${MaxElevation} $Elevation_unit";
				if(${MinElevation} == ${MaxElevation}){
					$Elevation="${MinElevation} $Elevation_unit";
                               		&log("Superfluous elevation  $_\n");
				}
			}
			else{
				#warn "$Elevation no units\n";
				$Elevation="";
                               	&log("Elevation lacking units $_\n");
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
                               	&log("Elevation lacking units $_\n");
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
                               			&log("Elevation lacking units $_\n");
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
#print "$_\n";
}
#next;
		if($CollectorNumber){
			($prefix, $CNUM,$suffix)=&parse_CNUM($CollectorNumber);
			#print "1 $prefix\t2 $CNUM\t3 $suffix\n";
		}
		else{
			$prefix= $CNUM=$suffix="";
		}
 		foreach($County){
			s/^$/Unknown/;
                	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)$/){
                        	$v_county= &verify_co($_);
                        	if($v_county=~/SKIP/){
                                	&log("SKIPPED NON-CA county? $_\n");
                                	next Record;
                        	}   
	
                        	unless($v_county eq $_){
                                	&log("$fields[0] $_ -> $v_county\n");
                                	$_=$v_county;
                        	}   
                	}   
        	}   
					#$JD=julian_day($year, $monthno, $day_month);
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
			&log("$SpecimenNumber: minus added to longitude");
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
Country: USA
State: CA
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
Habitat: $habitat{$SpecimenNumber}
Notes: $note{$SpecimenNumber}
EOP

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
			"Horticulture"
			){
#print "$SpecimenNumber $voucher--------->";
			if($store_voucher{$SpecimenNumber}{$voucher}){
				if(length($store_voucher{$SpecimenNumber}{$voucher}) > 1){
					print OUT "$voucher: $store_voucher{$SpecimenNumber}{$voucher}\n";
			#print "$voucher: $store_voucher{$SpecimenNumber}{$voucher}\n";
				}
			else{
				print OUT "$voucher: Data on label not transcribed.\n";
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
print "Excluded as non vascular\n", join("\n",sort(keys(%excl_NV))), "\n";





sub parse_CNUM{
			local($_)=shift;
			if(m/^\s+$/){
				return("","","");
	}
 	s/ *$//;
        s/^ *//;
        if(m/^([^0-9]*)([0-9]+)([^0-9]*)$/){
return("$1",$2,$3);
        }
        elsif(m/(.*[12]\d\d\d[^0-9])(\d+)([^0-9]*)/){
return("$1",$2,$3);
        }
        elsif(m/(.*[-\/ ])(\d+)([^0-9].*)/){
return("$1",$2,$3);
        }
        elsif(m/([A-Z]+)(\d+)$/){
return("$1",$2,"");
        }
        elsif(m/([A-Z]+)(\d+)([^0-9].*)/){
return("$1",$2,$3);
        }
else{
	return ("$_","","");
}
}

sub log {
	print ERR "@_\n";
}

__END__
JEPS59501	Mimulus moschatus Douglas ex Lindl.	Ezra Brainerd and Viola B. Baird	256	Jul 17 1915	1915-07-17 04:00:00		1 mi above Bear Rock (cliffs e of river); Sierra Nevada Mts., Truckee River	Placer	6700 ft									0	
