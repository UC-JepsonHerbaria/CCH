use lib '/Users/rlmoe/data/CDL';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
&load_noauth_name;
##meters to feet conversion
$meters_to_feet="3.2808";




open(TABFILE,">parse_granite.out") || die;
open(ERR,">granite_problems") || die;
$date=localtime();
print OUT <<EOP;
$date
Report from running parse_granite.pl
Name alterations from file ~/data/CDL/alter_names
Name comparisons made against ~/taxon_ids/smasch_taxon_ids (SMASCH taxon names, which are not necessarily correct)
Genera to be excluded from riv_non_vasc

EOP
open(IN,"../../RSA/oldrsa/RSA/rsa_alter_coll") || die;
while(<IN>){
        chomp;
        s/\cJ//;
        s/\cM//;
        next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
        $alter_coll{$rsa}=$smasch;
}


$data_file="";
open(IN,"$data_file" ) || die;

Record: while(<IN>){
	$annotation=$assoc=$combined_collectors=$Collector_full_name= $elevation= $name=$lat=$long=$decimal_lat=$decimal_long="";
	$zone=$easting=$northing="";
	s/\cK+$//;
	s/\cK//g;
	s/\cM/ /g;
	s/\x91/'/g;
	s/’/'/g;
	s/Õ/'/g;
	s/Ò/"/g;
	s/Ó/"/g;
	$line_store=$_;
	++$count;
	chomp;
	@fields=split(/\t/);
	unless($fields[0]=~/^GMDRC/){
		++$skipped{one};
		print OUT<<EOP;

No GM accession number, skipped: $_
EOP
		next Record;
	}
	$fields[10]= ucfirst( $fields[10]);
	if(length($fields[10]) < 3){
		++$skipped{one};
		print OUT<<EOP;

No generic name, skipped: $_
EOP
		next;
	}
	if($seen{$fields[0]}++){
		++$skipped{one};
		warn "Duplicate number: $fields[0]<\n";
		print OUT<<EOP;

Duplicate accession number, skipped: $fields[0]
EOP
		next;
	}
foreach $i (0 .. $#fields){     
                $fields[$i]=&prune_fields($fields[$i]); #from CCH.pm
        }


	################collector numbers
	$fields[3]=~s/ *$//;
	$fields[3]=~s/^ *//;
	if($fields[3]=~s/-$//){
		$fields[4]="-$fields[4]";
	}
	if($fields[3]=~s/^-//){
		$fields[2].="-";
	}
	if($fields[3]=~s/^([0-9]+)(-[0-9]+)$/$2/){
		$fields[2].=$1;
	}
	if($fields[3]=~s/^([0-9]+)(\.[0-9]+)$/$1/){
		$fields[4]=$2 . $fields[4];
	}
	if($fields[3]=~s/^([0-9]+)([A-Za-z]+)$/$1/){
		$fields[4]=$2 . $fields[4];
	}
	if($fields[3]=~s/^([0-9]+)([^0-9])$/$1/){
		$fields[4]=$2 . $fields[4];
	}
	if($fields[3]=~s/^(S\.N\.|s\.n\.)$//){
		$fields[4]=$1 . $fields[4];
	}
	if($fields[3]=~s/^([0-9]+-)([0-9]+)([A-Za-z]+)$/$2/){
		$fields[4]=$3 . $fields[4];
		$fields[2].=$1;
	}
	if($fields[3]=~m/[^\d]/){
		$fields[3]=~s/(.*)//;
		$fields[4]=$1 . $fields[4];
	}

 foreach($fields[31]){
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


		foreach($fields[6]){
			s/August/Aug/;
			s/July/Jul/;
			s/April/Apr/;
			s/\.//;
		}
	

(
$Label_ID_no,
$collector,
$Coll_no_prefix,
$Coll_no,
$Coll_no_suffix,
$year,
$month,
$day,
$Associated_collectors,
$family,
$genus,
$genus_doubted,
$species,
$sp_doubted,
$subtype,
$subtaxon,
$subsp_doubted,
$hybrid_category,
$Snd_genus,
$Snd_genusDoubted,
$Snd_species,
$Snd_species_doubted,
$Snd_subtype,
$Snd_subtaxon,
$Snd_subtaxon_doubted,
$determiner,
$det_year,
$det_mo,
$det_day,
$country,
$state,
$county_mpio,
$physiographic_region,
$topo_quad,
$locality,
$lat_degrees,
$lat_minutes,
$lat_seconds,
$N_or_S,
$decimal_lat,
$lat_uncertainty,
$long_degrees,
$long_minutes,
$long_seconds,
$E_or_W,
$decimal_long,
$long_uncertainty,
$Township,
$Range,
$section,
$Fraction_of_section,
$Snd_township,
$Snd_Range,
$Snd_section,
$Snd_Fraction_of_section,
$UTM_grid_zone,
$UTM_grid_cell,
$UTM_E,
$UTM_N,
$name_of_UTM_cell,
$low_range_m,
$top_range_m,
$low_range_f,
$top_range_f,
$ecol_notes,
$Plant_description,
$plant,
$phenology,
$culture,
$origin,
) = @fields;
if($long_uncertainty || $lat_uncertainty){
$extent= ($long_uncertainty || $lat_uncertainty);
$ExtUnits="m";
}
else{
$extent= "";
$ExtUnits="";
}
$lat_degrees= $lat_minutes= $lat_seconds= $N_or_S= $long_degrees= $long_minutes= $long_seconds= "";
#print "$UTM_E, $UTM_N $UTM_grid_zone, $UTM_grid_cell, $name_of_UTM_cell\n" if $UTM_E;
#print "DLT: $decimal_lat DLG: $decimal_long\n";
$Plant_description{$Plant_description}++;
$plant{$plant}++;
$phenology{$phenology}++;
$culture{$culture}++;
$origin{$origin}++;
$Label_ID_no=~s/-//;
$orig_lat_min=$lat_minutes;
$orig_long_min=$long_minutes;
$decimal_lat="" if $decimal_lat eq 0;
$decimal_long="" if $decimal_long eq 0;
$name=$genus ." " .  $species . " ".  $subtype . " ".  $subtaxon;
#print "\nTEST $name<\n";
$name=ucfirst(lc($name));
#$name=~s/'//g;
$name=~s/`//g;
$name=~s/\?//g;
$name=~s/ *$//;
$name=~s/  +/ /g;
$name=~s/ssp\./subsp./;
$name=~s/ [Xx] / × /;
#print "TEST $name<\n";

if($name=~/([A-Z][a-z-]+ [a-z-]+) × /){
                 $hybrid_annotation=$name;
                 warn "$1 from $name\n";
                 print OUT "$1 from $name\n";
                 $name=$1;
             }
	     else{
                 $hybrid_annotation="";
	     }


if($exclude{$genus}){
        &log("Excluded, not a vascular plant: $name");
        ++$skipped{one};
        next Record;
}

%infra=( 'var.','subsp.','subsp.','var.');

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
                &log ("$name is not yet in the master list: skipped");
                ++$skipped{one};
                next Record;
        }
}
else{
        &log ("$name is not yet in the master list: skipped");
        ++$skipped{one};
        next Record;
}


$name{$name}++;

########################COLLECTORS from CCH.pm
	$Collector_full_name=$collector;
	($Collector_full_name,$Associated_collectors)=&munge_collectors ($Collector_full_name,$Associated_collectors);

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
			$elev_test=$elev_test * $meters_to_feet;
			$elev_test= " feet";
		}
		else{
			$metric="";
		}
		if($elev_test=~s/ +(ft|feet)//i){

			if($elev_test > $max_elev{$fields[31]}){
				print OUT "$Label_ID_no\t$fields[31]\t ELEV: $elevation $metric greater than max: $max_elev{$fields[31]} discrepancy=", $elev_test-$max_elev{$fields[31]},"\n";
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
	if($lat_seconds==60){
		$lat_seconds="00";
		$lat_minutes +=1;
		if($lat_minutes==60){
			$lat_minutes="00";
			$lat_degrees +=1;
		}
	}
	if($long_seconds==60){
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
print OUT "$Label_ID_no: Longitude $long config problem; lat and long nulled\n";
$long="";
$lat="";
}
#if ($decimal_lat){
#if ($decimal_lat < 32.5 || $decimal_lat > 42.1){
#print OUT "$Label_ID_no: Latitude $decimal_lat outside CA box; lat and long nulled\n";
#$decimal_lat="";
#$decimal_long="";
#}
#}
#if ($decimal_long){
#if ($decimal_long > -114.0 || $decimal_long < -124.5){
#print OUT "$Label_ID_no: Longitude $decimal_long outside CA box; lat and long nulled\n";
#$decimal_long="";
#$decimal_lat="";
#}
#}
unless($lat =~ /\d/){
	$long="";
		print OUT<<EOP;
$Label_ID_no: Longitude no latitude config problem; long nulled

EOP
}
}
if($lat){
unless ($lat=~/\d\d \d\d? \d\d?N/ || $lat=~/\d\d \d\d?N/ || $lat=~/\d\d \d\d? \d\d?\.\dN/){
print OUT "$Label_ID_no: Latitude $lat config problem; Lat and long nulled\n";
$lat="";
$long="";
}
unless($long=~/\d/){
	$lat="";
		print OUT<<EOP;
$Label_ID_no: Latitude no longitude config problem; lat nulled
EOP
}
}
$year=~s/ ?\?$//;
$year=~s/^['`]+//;
$year=~s/['`]+$//;
unless($year=~/^(1[789]\d\d|20\d\d)$/){
		print OUT<<EOP;
$Label_ID_no: Date config problem $year $month $day: date nulled
EOP
	$year=$month=$day="";
}
unless($day=~/(^[0-3]?[0-9]$)|(^[0-3]?[0-9]-[0-3]?[0-9]$)|(^$)/){
		print OUT<<EOP;
$Label_ID_no: Date config problem $year $month $day: date nulled
EOP
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
			print "$ellipsoid,$zone,$easting,$northing\n";
			($decimal_lat,$decimal_long)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
			print "$Label_ID_no UTM $decimal_lat, $decimal_long\n";
		}
		else{
			print "$Label_ID_no UTM problem $zone $easting $northing\n";
		}


		$decimal_long="-$decimal_long" if $decimal_long > 0;
	}  
}
	if($decimal_lat){
	if($decimal_lat > 42.1 || $decimal_lat < 32.5 || $decimal_long > -114 || $decimal_long < -124.5){
		if($zone){
			print OUT "$Label_ID_no coordinates set to null, Outside California: $accession_id: UTM is $zone $easting $northing --> $decimal_lat $decimal_long\n";
		}
		else{
			print OUT "$Label_ID_no coordinates set to null, Outside California: D_lat is $decimal_lat D_long is $decimal_long lat is $lat long is $long\n";
		}
	$decimal_lat =$decimal_long="";
}   
}





print TABFILE <<EOP;
Date: $month $day $year
CNUM_prefix: ${Coll_no_prefix}
CNUM: ${Coll_no}
CNUM_suffix: ${Coll_no_suffix}
Name: $name
Accession_id: $Label_ID_no
Family_Abbreviation: $family
Country: $country
State: $state
County: $county_mpio
Loc_other: $physiographic_region
Location: $locality
T/R/Section: $Unified_TRS
USGS_Quadrangle: $topo_quad
Elevation: $elevation
Collector: $Collector_full_name
Other_coll: $other_coll
Combined_collector: $combined_collectors
Habitat: $ecol_notes
Associated_species: $assoc
Notes: $Plant_description
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Max_error_distance: $extent
Max_error_units: $ExtUnits
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation

EOP
++$included;
}
open(COLL,">missing_coll");
foreach(sort(keys(%collector))){
#print "$_\n" if $coll_comm{$_};
	$key=$_;
#s/\./. /g;
s/\. ,/., /;
s/  +/ /g;
s/ *$//;
next if $coll_comm{$_};
print COLL "$_\t$collector{$key}\n";
}

foreach(sort(keys(%name))){
	#print "$_\n" unless $taxon{$_};
}
print <<EOP;
INCL: $included
EXCL: $skipped{one};
EOP

foreach(sort(keys(%coord_alter))){
	#print "$_\n";
}
open(OUT,">new_names_needed") || die;
foreach(sort {$needed_name{$a} <=> $needed_name{$b}}(keys(%needed_name))){
print OUT "$_ $needed_name{$_}\n";
}
open(OUT,">ucr_field_check") || die;
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
__END__
