use lib '/Users/richardmoe/4_DATA/CDL';
		use Geo::Coordinates::UTM;
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
&load_noauth_name;
##meters to feet conversion
$meters_to_feet="3.2808";

open(TABFILE,">ucla.out") || die;
open(ERR,">ucla_problems") || die;

print ERR <<EOP;
$today
Report from running parse_ucla.pl
Name alterations from file ~/4_data/CDL/alter_names
Name comparisons made against ~/taxon_ids/smasch_taxon_ids (SMASCH taxon names, which are not necessarily correct)
Genera to be excluded from mosses
outfile id ucla.out

EOP

$ucla_input=shift;
open(IN, $ucla_input) || die;
Record: while(<IN>){
	chomp;
	@fields=split(/\t/,$_,150);
grep(s/^"(.*)"/$1/,@fields);
grep(s/  +/ /g,@fields);
#print "$#fields\n";
#next;
($CNUM,
$CNUM_prefix,
$CNUM_suffix,
$Name,
$ACCESSION_id,
$Country,
$County,
$Floristic_Region_subregion,
$Geog_Unit,
$Geog_Subunit,
$Parks_Reserves,
$Location,
$T_R_Section,
$Collector,
$Other_coll,
$Habitat,
$Assoc_species_preface,
$Associated_species,
$Specimen_data,
$formatted_UTM_Lat_Long,
$DegreesLat,
$MinutesLat,
$SecondsLat,
$DegreesLong,
$MinutesLong,
$SecondsLong,
$Decimal_latitude,
$Decimal_longitude,
$Easting,
$Northing,
$Geographic_source,
$UTM_Zone,
$Datum,
$Accuracy,
$Minimum_Elev,
$Maximum_Elev,
$Units_Elev,
$NOTES,
$Name_annotation1,
$Determination_annotation1,
$Annotator1,
$Date_Annot_1,
$Comment_annotation1,
$Name_annotation2,
$Determination_annotation2,
$Annotator2,
$Date_Annot_2,
$Comment_annotation2,
$Name_annotation3,
$Determination_annotation3,
$Annotator3,
$Date_Annot_3,
$Comment_annotation3,
$Type_status,
$Hybrid_annotation,
$day_1,
$month_1,
$year_1,
$day_2,
$month_2,
$year_2,
$state)=@fields;
print "$. $_\n" unless $#fields== 61;
if($NOTES){
	if($Specimen_data){
		$Specimen_data.=". $NOTES";
	}
	else{
		$Specimen_data="$NOTES";
	}
}

if($Determination_annotation1){
$annotation_1="$Determination_annotation1; $Annotator1; $Date_Annot_1; $Comment_annotation1";
}
else{
$annotation_1="";
}
if($Determination_annotation2){
$annotation_2="$Determination_annotation2; $Annotator2; $Date_Annot_2; $Comment_annotation2";
}
else{
$annotation_2="";
}
if($Determination_annotation3){
$annotation_3="$Determination_annotation3; $Annotator3; $Date_Annot_3; $Comment_annotation3";
}
else{
$annotation_3="";
}

	$fields[3]= ucfirst( $fields[3]);
	if(length($fields[3]) < 3){
		&log("No generic name, skipped: $_");
		++$skipped{one};
		next Record;
	}
	#if($seen{$fields[4]}++){
		#warn "Duplicate number: $fields[4]<\n";
	#&log("Duplicate accession number, skipped: $fields[4]");
		#++$skipped{one};
		#next Record;
	#}

	unless($fields[4]=~/^LA\d/){
&log("No UCLA accession number, skipped: $_");
		++$skipped{one};
		next Record;
	}

	foreach($County){
		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)$/){
			$v_county= &verify_co($_);
			if($v_county=~/SKIP/){
				&log("NON-CA county? $_");
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){
				&log("$fields[4] $_ -> $v_county");
				$_=$v_county;
			}


		}
		$county{$_}++;
	}

($genus=$Name)=~s/ .*//;
if($Name=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
                 $hybrid_annotation=$Name;
                 warn "$1 from $Name\n";
                 &log("$1 from $Name");
                 $Name=$1;
             }
	     else{
                 $hybrid_annotation="";
	     }


if($exclude{$genus}){
	&log("Excluded, not a vascular plant: $Name");
	++$skipped{one};
	next Record;
}

%infra=( 'var.','subsp.','subsp.','var.');

#print "N>$Name<\n";
$test_name=&strip_name($Name);
#print "TN>$test_name<\n";

if($TID{$test_name}){
        $Name=$test_name;
}
elsif($alter{$test_name}){
        &log("$Name altered to $alter{$test_name}");
                $Name=$alter{$test_name};
}
elsif($test_name=~s/(var\.|subsp\.)/$infra{$1}/){
        if($TID{$test_name}){
                &log("$Name not in SMASCH  altered to $test_name");
                $Name=$test_name;
        }
        elsif($alter{$test_name}){
                &log("$Name not in smasch  altered to $alter{$test_name}");
                $Name=$alter{$test_name};
        }
	else{
$needed_name{$Name}++;
        	&log ("$Name is not yet in the master list: skipped");
		++$skipped{one};
		next Record;
	}
}
else{
$needed_name{$Name}++;
        &log ("$Name is not yet in the master list: skipped");
	++$skipped{one};
	next Record;
}


$name{$Name}++;

if($Minimum_Elev && $Maximum_Elev && $Maximum_Elev > $Minimum_Elev){
$elevation= "${Minimum_Elev}-${Maximum_Elev} $Units_Elev";
}
elsif($Minimum_Elev){
$elevation= "${Minimum_Elev} $Units_Elev";
}
elsif($Maximum_Elev){
$elevation= "${Maximum_Elev} $Units_Elev";
}
else{
$elevation= "";
}

	$elev_test=$elevation;
	$elev_test=~s/.*- *//;
	$elev_test=~s/ *\(.*//;
	$elev_test=~s/ca\.? *//;
	if($elev_test=~s/ (meters?|m)//i){
		$metric="(${elev_test} m)";
		$elev_test=int($elev_test * $meters_to_feet);
		$elev_test.= " feet";
	}
	else{
		$metric="";
	}
	if($elev_test=~s/ +(ft|feet)//i){
		if($elev_test > $max_elev{$County}){
		$discrep=$elev_test-$max_elev{$County};
		$discrep="$Label_ID_no\t$County $elev_test vs $max_elev{$County}: elevation discrepancy=$discrep";
		&log($discrep);
				warn "$Label_ID_no\t$County $elev_test vs $max_elev{$County}: discrepancy=", $elev_test-$max_elev{$County},"\n";
		}
	}
        ($Collector,$Other_coll)=&munge_collectors ($Collector,$Other_coll);

unless(($Decimal_latitude || $Decimal_longitude)){
if($UTM_Zone){
		$ellipsoid=23;
		if($UTM_Zone=~/(9|10|11|12)S?/ && $Easting=~/\d\d\d\d\d\d/ && $Northing=~/\d\d\d\d\d\d\d/){
			warn "$ACCESSION_id $ellipsoid,$UTM_Zone,$Easting,$Northing\n";
			($Decimal_latitude,$Decimal_longitude)=utm_to_latlon($ellipsoid,"${UTM_Zone}S",$Easting,$Northing);
			warn  "$Label_ID_no UTM $Decimal_latitude, $Decimal_longitude\n";
		}
		else{
			&log( "$ACCESSION_id UTM problem $UTM_Zone $Easting $Northing");
			warn "$ACCESSION_id UTM problem $UTM_Zone $Easting $Northing\n";
		}


	}  
}
		$Decimal_longitude="-$Decimal_longitude" if $Decimal_longitude > 0;
	if($Decimal_latitude){
		if($Decimal_latitude > 42.1 || $Decimal_latitude < 32.5 || $Decimal_longitude > -114 || $Decimal_longitude < -124.5){
			if($zone){
				&log("$Label_ID_no coordinates set to null, Outside California: $accession_id: UTM is $zone $easting $northing --> $Decimal_latitude $Decimal_longitude");
			}
			else{
				&log("$Label_ID_no coordinates set to null, Outside California: D_lat is $Decimal_latitude D_long is $Decimal_longitude lat is $lat long is $long\n");
			}
			$Decimal_latitude =$Decimal_longitude="";
		}   
	}


if($year_2){
	if($year_1){
		$date="$month_1 $day_1 $year_1 - $month_2 $day_2 $year_2";
	}
	else{
		$date="$month_2 $day_2 $year_2";
	}
}
else{
	if($year_1){
		$date="$month_1 $day_1 $year_1";
	}
	else{
		$date="";
	}
}
if($Hybrid_annotation){
$hybrid_annotation.= "($Hybrid_annotation)";
}
if($Acuracy){
$error_units="m";
}
else{
$error_units="";
}

$count{$ACCESSION_id}++;
$print{$ACCESSION_id} = <<EOP;
Date: $date
CNUM_prefix: $CNUM_prefix
CNUM: $CNUM
CNUM_suffix: $CNUM_suffix
Name: $Name
Accession_id: $ACCESSION_id
Country: $Country
State: $state
County: $County
Location: $Location
T/R/Section: $T_R_Section
USGS_Quadrangle: 
Elevation: $elevation
Collector: $Collector
Other_coll: $Other_coll
Combined_collector: $combined_collectors
Habitat: $Habitat
Associated_species: $Assoc_species_preface $Associated_species
Notes: $Specimen_data
Latitude: $lat
Longitude: $long
Decimal_latitude: $Decimal_latitude
Decimal_longitude: $Decimal_longitude
Datum: $Datum
Source: $Geographic_source
Max_error_distance: $Accuracy
Max_error_units: $error_units
Annotation: $annotation_1
Annotation: $annotation_2
Annotation: $annotation_3
Hybrid_annotation: $hybrid_annotation 
Type status: $Type_status

EOP
}
foreach $id (keys(%count)){
if($count{$id}==1){
print TABFILE "$print{$id}\n\n";
}
else{
&log("$id: $count{$id} duplicates. Skipped");
}
}

sub log {
print ERR "@_\n";
}
