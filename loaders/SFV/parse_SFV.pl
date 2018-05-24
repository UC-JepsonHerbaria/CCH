use lib '/Users/richardmoe/4_DATA/CDL';
use CCH;



use Time::JulianDay;
open(ERR, ">SFV_ERROR.txt") || die;
&load_noauth_name; #FROM CCH.pm
#Load names of non-vascular genera to be excluded
open(IN, "/Users/richardmoe/4_CDL_BUFFER/smasch/mosses") || die;
while(<IN>){
	chomp;
	s/ .*//;
	$exclude{$_}++;
}
close(IN);

open(IN,"SFV_2.txt" ) || die;
while(<IN>){
chomp;
s/\t.*//;
$dups{$_}++;
}
close(IN);

open(OUT, ">SFV.out") || die;
open(IN,"SFV_2.txt" ) || die;

Record: while(<IN>){
#next unless m/dissentifolium/;
chomp;
s/\cK/_x000B_/g;
@fields=split(/\t/,$_,100);
#print join(" | ", @fields[9,10,11]), "\n";
die "FIELD NUMBER PROBLEM $#fields $_\n" unless $#fields==25;
if ($dups{$fields[0]} > 1){
&log("$fields[0] is a duplicated number, skipped\n");
		++$skipped{one};
		next Record;
}
grep(s/^"(.*)"$/$1/g, @fields);
grep(s/^ +//g, @fields);
grep(s/ +$//g, @fields);
grep(s/  / /g, @fields);


	unless($fields[0]=~/^SFV/){
&log("No SFV accession number, skipped: $_");
		++$skipped{one};
		next Record;
	}
	$fields[2]= ucfirst( $fields[2]);
	if(length($fields[2]) < 3){
		&log("No generic name, skipped: $_");
		++$skipped{one};
		next Record;
	}
	if($seen{$fields[0]}++){
		warn "Duplicate number: $fields[0]<\n";
&log("Duplicate accession number, skipped: $fields[0]");
		++$skipped{one};
		next Record;
	}
	foreach $i (0 .. $#fields){
		$fields[$i]=&prune_fields($fields[$i]);
	}

	foreach($fields[18]){
		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)$/){
			$v_county= &verify_co($_);
			if($v_county=~/SKIP/){
				&log("NON-CA county? $_");
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){
				&log("$fields[0] $_ -> $v_county");
				$_=$v_county;
			}


		}
		$county{$_}++;
	}
	#foreach($fields[6]){
		#s/August/Aug/;
		#s/July/Jul/;
		#s/April/Apr/;
		#s/\.//;
	#}
	

($SFV_number, $family, $genus, $species, $var_ssp, $var_ssp_name, $determiner, $determination_year, $collector, $collector_no, $coll_no_pt_2, $coll_no_pt_3, $Associated_collectors, $day, $month, $year, $country, $state, $county, $region, $locality, $latitude, $longitude, $elevation, $ass_Vegetation, $notes)=@fields;
#print "$county\n";
$genus=~s/^[A-Za-z]+/\u\L$&/;
$species=lc($species);
$name= "$genus $species $var_ssp $var_ssp_name";
print NOWHERE <<EOP;
>$name<
>$genus<
>$species<
>$var_ssp<
>$var_ssp_name<

EOP
foreach($name){
s/ssp\./subsp./;
s/ *$//;
s/  */ /g;
}
unless($collector_no=~/^[0-9.]+$/){
$coll_no_pt_2= "$collector_no $coll_no_pt_2";
$collector_no ="";
}
${Coll_no_prefix}="";
${Coll_no}=$collector_no;
${Coll_no_suffix} = "$coll_no_pt_2 $coll_no_pt3";
${Coll_no_suffix} =~s/ *$//;

#print "Y $coll_year\n";
#print "M $coll_month\n";
#print "D $coll_Day\n";
foreach($region){
s/\.$//;
s/Moutains/Mountains/;
   s/Callifornia/California/;
   s/Carrizp/Carrizo/;
   s/Panaminit/Panamint/;
s/Sacremento/Sacramento/;
   s/Mounatains/Mountains/;
   s/Sierra ..evada/Sierra Nevada/;
s/Sierre Nevada/Sierra Nevada/;
   s/warner Mountains/Warner Mountains/;
   s/Santa ynez Mountains/Santa Ynez Mountains/;
   s/Vergudo Mountains/Verdugo Mountains/;
   s/Santa Monical/Santa Monica/;
}
#print "$region\n";
#print "$longitude\n";
#print "$county\n";
#next;
if($long_uncertainty || $lat_uncertainty){
	$extent= ($long_uncertainty || $lat_uncertainty);
	$ExtUnits="m";
}
else{
	$extent= "";
	$ExtUnits="";
}
$SFV_number=~s/-//;
$decimal_lat= $latitude || "";
$decimal_long=$longitude || "";
$decimal_long=-$decimal_long if $decimal_long > 0;
$name=~s/ *$//;
#print "\nTEST $name<\n";
#$name=~s/'//g;
if($name=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
                 $hybrid_annotation=$name;
                 warn "$1 from $name\n";
                 &log("$1 from $name");
                 $name=$1;
             }
	     else{
                 $hybrid_annotation="";
	     }


unless($state=~/^(CA|Ca|Calif|California)$/i){
	&log("Excluded, not a California record: $state  $SFV_number");
	++$skipped{one};
	next Record;
}
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
        &log("$name altered to $alter{$test_name}");
                $name=$alter{$test_name};
}
elsif($test_name=~s/(var\.|subsp\.)/$infra{$1}/){
        if($TID{$test_name}){
                &log("$name not in SMASCH  altered to $test_name");
                $name=$test_name;
        }
        elsif($alter{$test_name}){
                &log("$name not in smasch  altered to $alter{$test_name}");
                $name=$alter{$test_name};
        }
	else{
$needed_name{$name}++;
        	&log ("$name is not yet in the master list: skipped");
		++$skipped{one};
		next Record;
	}
}
else{
$needed_name{$name}++;
        &log ("$name is not yet in the master list: skipped");
	++$skipped{one};
	next Record;
}


$name{$name}++;

#print "TEST \n\n";
########################COLLECTORS
        $Collector_full_name=$collector;
        ($Collector_full_name,$Associated_collectors)=&munge_collectors ($Collector_full_name,$Associated_collectors);
        if($Associated_collectors){
$combined_collectors="$Collector_full_name, $Associated_collectors";
}
else{
$combined_collectors="";
}

$elevation .= " m" if $elevation;


	if($low_range_m){
		if($top_range_m){
			$elevation="$low_range_m - $top_range_m m";
		}
		else{
			$elevation="$low_range_m m";
		}
	}
	elsif($low_range_f){
		#these incorrectly labelled "m" first loading!
		if($top_range_f){
			$elevation="$low_range_f - $top_range_f ft";
		}
		else{
			$elevation="$low_range_f ft";
		}
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
		if($elev_test > $max_elev{$county}){
		$discrep=$elev_test-$max_elev{$county};
		$discrep="$Label_ID_no\t$county $elev_test vs $max_elev{$county}: elevation discrepancy=$discrep";
		&log($discrep);
				warn "$Label_ID_no\t$county $elev_test vs $max_elev{$county}: discrepancy=", $elev_test-$max_elev{$county},"\n";
		}
	}

	if($ecol_notes=~s/[;.] +([Aa]ssoc.*)//){
		$assoc=$1;
	}


	$long_minutes=~ s/['`]//g;
	$lat_minutes=~ s/['`]//g;
	$lat_degrees=~ s/^(\d\d)[^\d]$/$1/g;
	$long_degrees=~ s/^(\d\d\d)[^\d]$/$1/g;
	if($long_minutes=~ s/^(\d*)(\.\d+)$/$1/){
		$long_minutes="00" if $long_minutes eq "";
		$minute_decimal=$2;
		$long_seconds= int($minute_decimal * 60);
	}
	if($lat_minutes=~ s/^(\d*)(\.\d+)$/$1/){
		$lat_minutes="00" if $lat_minutes eq "";
		$minute_decimal=$2;
		$lat_seconds= int($minute_decimal * 60);
	}

	if($lat_seconds=~/(\d+)\.[01234].*/){
		$lat_seconds=$1;
	}
	elsif($lat_seconds=~/(\d+)\.[56789].*/){
		$lat_seconds=${1}+1;
	}
	if($long_seconds=~/(\d+)\.[01234].*/){
		$long_seconds=$1;
	}
	elsif($long_seconds=~/(\d+)\.[56789].*/){
		$long_seconds=${1}+1;
	}
	if($lat_seconds && $lat_seconds==60){
		$lat_seconds="00";
		$lat_minutes +=1;
		if($lat_minutes==60){
			$lat_minutes="00";
			$lat_degrees +=1;
		}
	}
	if($long_seconds && $long_seconds==60){
		$long_seconds="00";
		$long_minutes +=1;
		if($long_minutes==60){
			$long_minutes="00";
			$long_degrees +=1;
		}
	}
	$lat_minutes=~ s/^ *(\d)\./0$1./;
	$lat_seconds=~ s/^ *(\d)\./0$1./;
	$long_minutes=~ s/^ *(\d)\./0$1./;
	$long_seconds=~ s/^ *(\d)\./0$1./;
	$lat_minutes=~ s/^ *(\d) *$/0$1/;
	$lat_seconds=~ s/^ *(\d) *$/0$1/;
	$long_minutes=~ s/^ *(\d) *$/0$1/;
	$long_seconds=~ s/^ *(\d) *$/0$1/;
	unless($lat_minutes eq $orig_lat_min){
		$coord_alter{"$orig_lat_min -> $lat_minutes $lat_seconds"}++;
	}
	unless($long_minutes eq $orig_long_min){
		$coord_alter{"$orig_long_min -> $long_minutes $long_seconds"}++;
	}

	($lat= "${lat_degrees} ${lat_minutes} ${lat_seconds}$N_or_S")=~s/ ([EWNS])/$1/;
	($long= "${long_degrees} ${long_minutes} ${long_seconds}$E_or_W")=~s/ ([EWNS])/$1/;
	$lat=~s/^ *([EWNS])//;
	$long=~s/^ *([EWNS])//;
	$lat=~s/^ *//;
	$long=~s/^ *//;

	if($long){
		unless ($long=~/\d\d\d \d\d? \d\d?W/ || $long=~/\d\d\d \d\d?W/ || $long=~/\d\d\d \d\d? \d\d?\.\dW/){
			&log("$Label_ID_no: Longitude $long config problem; lat and long nulled");
			$long="";
			$lat="";
		}
		#if ($decimal_lat){
	unless($lat =~ /\d/){
		$long="";
		&log("$Label_ID_no: Longitude no latitude config problem; long nulled");
	}
}
if($lat){
unless ($lat=~/\d\d \d\d? \d\d?N/ || $lat=~/\d\d \d\d?N/ || $lat=~/\d\d \d\d? \d\d?\.\dN/){
&log("$Label_ID_no: Latitude $lat config problem; Lat and long nulled");
$lat="";
$long="";
}
unless($long=~/\d/){
	$lat="";
&log("$Label_ID_no: Latitude no longitude config problem; lat nulled");
}
}
$year=~s/ ?\?$//;
$year=~s/^['`]+//;
$year=~s/['`]+$//;
unless($year=~/^(1[789]\d\d|20\d\d)$/){
&log("$Label_ID_no: Date config problem $year $month $day: date nulled");
	$year=$month=$day="";
}
unless($day=~/(^[0-3]?[0-9]$)|(^[0-3]?[0-9]-[0-3]?[0-9]$)|(^$)/){
&log("$Label_ID_no: Date config problem $year $month $day: date nulled");

	$year=$month=$day="";
}


$Unified_TRS="$Township$Range$section";
$country="USA" if $country=~/U\.?S\.?/;
if($annotation=~/Pectocarya anisocarpa/){
	$annotation="$annotation; Ron Kelly; 2012 March 30";
}
elsif($determiner){
	$annotation="$name; $determiner; $det_year $det_mo $det_day";
}
else{
	$annotation="";
}
$zone=$UTM_grid_zone;
$zone=uc($zone);
#$UTM_grid_cell,
#$UTM_E,
#$UTM_N,
#$name_of_UTM_cell,
unless(($decimal_lat || $decimal_long)){
	if($zone){
		use Geo::Coordinates::UTM;
		$easting=$UTM_E;
		$northing=$UTM_N;
		$ellipsoid=23;
		if($zone=~/(9|10|11|12)S/ && $easting=~/\d\d\d\d\d\d/ && $northing=~/\d\d\d\d\d/){
			#warn "$ellipsoid,$zone,$easting,$northing\n";
			($decimal_lat,$decimal_long)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
			warn  "$Label_ID_no UTM $decimal_lat, $decimal_long\n";
		}
		else{
			&log( "$Label_ID_no UTM problem $zone $easting $northing");
		}


		$decimal_long="-$decimal_long" if $decimal_long > 0;
	}  
}
	if($decimal_lat){
		if($decimal_lat > 42.1 || $decimal_lat < 32.5 || $decimal_long > -114 || $decimal_long < -124.5){
			if($zone){
				&log("$Label_ID_no coordinates set to null, Outside California: $accession_id: UTM is $zone $easting $northing --> $decimal_lat $decimal_long");
			}
			else{
				&log("$Label_ID_no coordinates set to null, Outside California: D_lat is $decimal_lat D_long is $decimal_long lat is $lat long is $long\n");
			}
			$decimal_lat =$decimal_long="";
		}   
	}


@notes=split(/_x000B_/,$notes);
foreach(@notes){
#print "$_\n" if m/.../;
if(m/(Flower color.*)/){
$color=$1;
}
elsif(m/^(Very|Abundant|Uncommon|Locally|Rare|Scattered|Frequent|Scarce|Abundance)/){
$Population_biology=$_;
}
elsif(m/Plant height/){
$macromorphology=$_;
}
else{
$habitat.="$_; ";
}
}


if($decimal_lat){
$datum="NAD27";
}
else{
$datum="";
}

print OUT <<EOP;
Date: $month $day $year
CNUM_prefix: ${Coll_no_prefix}
CNUM: ${Coll_no}
CNUM_suffix: ${Coll_no_suffix}
Name: $name
Accession_id: $SFV_number
Family_Abbreviation: $family
Country: $country
State: $state
County: $county
Loc_other: $region
Location: $locality
T/R/Section: $Unified_TRS
USGS_Quadrangle: $topo_quad
Elevation: $elevation
Collector: $collector
Other_coll: $Associated_collectors
Combined_collector: $combined_collectors
Associated_species: $ass_Vegetation
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Datum: $datum
Max_error_distance: $extent
Max_error_units: $ExtUnits
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation
Color: $color
Population_biology: $Population_biology
Macromorphology: $macromorphology
Habitat: $habitat

EOP
$color= $Population_biology= $macromorphology= $habitat="";
++$included;
}

foreach(sort(keys(%name))){
	#print "$_\n" unless $TID{$_};
}
print <<EOP;
INCL: $included
EXCL: $skipped{one};
EOP

open(OUT,">NPR_new_names_needed") || die;
foreach(sort {$needed_name{$a} <=> $needed_name{$b}}(keys(%needed_name))){
print OUT "$_ $needed_name{$_}\n";
}
open(OUT,">NPR_ucr_field_check") || die;
foreach(sort(keys(%Plant_description))){
	print OUT "PD: $_\n";
}
foreach(sort(keys(%plant))){
	print OUT "P: $_\n";
}
foreach(sort(keys(%phenology))){
	print OUT "Phen: $_\n";
}
foreach(sort(keys(%culture))){
	print OUT "C: $_\n";
}
foreach(sort(keys(%origin))){
	print OUT "O: $_\n";
}
sub log {
print ERR "@_\n";
}
