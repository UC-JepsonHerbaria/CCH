$m_to_f="3.2808";
while(<DATA>){
@fields=split(/\t/);
$fields[3]=~s/\+//;
$fields[3]=~s/,//;
$max_elev{$fields[1]}=$fields[3];
}
open(IN,"../CDL/collectors_id") || die;
#open(IN,"all_collectors_2005") || die;
while(<IN>){
chomp;
s/\t.*//;
$coll_comm{$_}++;
}
open(IN,"/Users/rlmoe/CDL_buffer/buffer/tnoan.out") || die;
while(<IN>){
chomp;
s/^.*\t//;
$taxon{$_}++;
}
open(IN,"../CDL/riv_non_vasc") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}






open(IN,"../CDL/alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(IN,"../RSA/oldrsa/RSA/rsa_alter_coll") || die;
while(<IN>){
	chomp;
s/\cJ//;
s/\cM//;
	next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	$alter_coll{$rsa}=$smasch;
}
#while(<IN>){
	#chomp;
#s/\cJ//;
#s/\cM//;
	#next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	#$alter_coll{$rsa}=$smasch;
#}
open(TABFILE,">parse_csusb.out") || die;
open(OUT,">csusb_loading_report.txt") || die;
$date=localtime();
print OUT <<EOP;
$date
Report from running parse_csusb.pl
Name alterations from file alter_names
Name comparisons made against SMASCH taxon names (which are not necessarily correct)
Genera to be excluded from riv_non_vasc

EOP

open(IN,"CSUSB.tab") || die;

#open(IN,"riv_oct_2009" ) || die;
#$/="\cM";
#open(IN,"probs") || die;
Record: while(<IN>){
$assoc=$combined_collectors=$Collector_full_name= $elevation= $name=$lat=$long=$decimal_lat=$decimal_long="";
		$zone=$easting=$northing="";
#next unless m/Annette Winn/;
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
foreach(@fields){
s/^"(.*)"$/$1/;
}
	if($fields[0]=~/^ *$/){
		++$skipped{one};
		print OUT<<EOP;

No accession number, skipped: $_
EOP
		next;
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
		$_=$fields[$i];
		s/ *$//;
		s/^ *//;
		if(length($_)>254){
			$fields[$i]=substr($_, 0, 249) . " ...";
			#print "$fields[$i]\n";
		}
		else{
			$fields[$i]=$_;
		}
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
unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)/i){
		print OUT<<EOP;

		Unknown California county $fields[0]: $_
EOP
	}
			s/\[//;
			s/\]//;
			s/  / /g;
			s/ *\?$//;
			s/ *\/.*//;
			s/ *\(.*//;
			s/-.*//;
			s/East //;
			s/El[Dd]orado/El Dorado/;
			s/Los angeles/Los Angeles/;
			s/Angelos/Angeles/;
			s/:Los/Los/;
			s/ County.*//;
			s/Riveside/Riverside/;
			s/S[Aa][Nn]/San/;
			s/Berbardino/Bernardino/;
			s/Bernadino/Bernardino/;
			s/Brenardino/Bernardino/;
			s/bernadrino/Bernardino/;
			s/obispo/Obispo/;
			s/Barbarba/Barbara/;
			s/Ange;es/Angeles/;
			s/DEL NORTE/Del Norte/;
			s/MENDOCINO/Mendocino/;
			s/MERCED/Merced/;
			s/DIEGO/Diego/;
			s/San Barbara/Santa Barbara/;
			s/RIverside/Riverside/;
			s/Rvierside/Riverside/;
			s/RIVERSIDE/Riverside/;
			s/MONO/Mono/;
			s/NAPA/Napa/;
			s/bernardino/Bernardino/;
			s/Shassta/Shasta/;
s/^ *$/Unknown/;
unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)/i){
		print OUT<<EOP;
		Unknown California county not reconciled $fields[0]: $_ skipped
EOP
		next Record;
	}
		}
		$county{$fields[31]}++;
		foreach($fields[6]){
			s/August/Aug/;
			s/July/Jul/;
			s/April/Apr/;
			s/\.//;
		}
	
		#$date{"$fields[6] $fields[7] $fields[5]"}++;
		#$taxon{"$fields[10] $fields[11] $fields[12] $fields[13]"}++;

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
$long_degrees,
$long_minutes,
$long_seconds,
$E_or_W,
$decimal_long,
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
$plant,
$phenology,
$culture,
$origin,
) = @fields;
print "$UTM_E, $UTM_N $UTM_grid_zone, $UTM_grid_cell, $name_of_UTM_cell\n" if $UTM_E;
#next;
#$Plant_description{$Plant_description}++;
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
	print OUT <<EOP;

Excluded, not a vascular plant: $name
EOP
		++$skipped{one};
	next;
}
#print "TEST $name<\n";
if($alter{$name}){
	print OUT <<EOP;

Spelling altered to $alter{$name}: $name 
EOP
	$name=$alter{$name};
#print "TEST $name<\n";
}
unless($taxon{$name}){
#print "TEST $name<\n";
	$on=$name;
	if($name=~s/subsp\./var./){
		if($taxon{$name}){
			print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
		}
		else{
	print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped $line_store
EOP
		++$skipped{one};
		$needed_name{$name}++;
next;
		}
	}
	elsif($name=~s/var\./subsp./){
#print "TEST $name<\n";
		if($taxon{$name}){
			print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
		}
		else{
#print "TEST $name<\n";
			print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped $line_store
EOP
		++$skipped{one};
		$needed_name{$name}++;
next;
		}
	}
	else{
#print "TEST $name<\n";
	print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $name skipped $line_store
EOP
		++$skipped{one};
		$needed_name{$name}++;
	next;
	}
}

$name{$name}++;

#print "TEST \n\n";
########################COLLECTORS
	$Collector_full_name=$collector;
	foreach($Collector_full_name){
		s/ \./\./g;
		s/([A-Z]\.)([A-Z]\.)([A-Z]\.)/$1 $2 $3 /g;
		s/([A-Z]\.)([A-Z]\.)/$1 $2 /g;
		s/([A-Z]\.)([A-Z][a-z])/$1 $2/g;
		s/([A-Z]\.) ([A-Z]\.)([A-Z])/$1 $2 $3/g;
		s/([A-Z]\.)([A-Z])/$1 $2/g;
		s/,? (&|and) /, /;
		s/([A-Z])([A-Z]) ([A-Z][a-z])/$1. $2. $3/g;
		s/([A-Z]) ([A-Z][a-z])/$1. $2/g;
		s/,([^ ])/, $1/g;
		s/ *, *$//;
		s/, ,/,/g;
		s/  */ /g;
		s/^J\. ?C\. $/J. C./;
		s/John A. Churchill M. ?D. $/John A. Churchill M. D./;
		s/L\. *F\. *La[pP]r./L. F. LaPre/;
		s/B\. ?G\. ?Pitzer/B. Pitzer/;
		s/J. André/J. Andre/;
		s/Jim André/Jim Andre/;
		s/ *$//;
		$_= $alter_coll{$_} if $alter_coll{$_};
			++$collector{$_};
		if($Associated_collectors){
$Associated_collectors=~s/D. *Charlton, *B. *Pitzer, *J. *Kniffen, *R. *Kniffen, *W. *W. *Wright, *Howie *Weir, *D. *E. *Bramlet/D. Charlton, et al./;
$Associated_collectors=~s/Mark *Elvin, *Cathleen *Weigand, *M. *S. *Enright, *Michelle *Balk, *Nathan *Gale, *Anuja *Parikh, *K. *Rindlaub/Mark Elvin, et al./;
$Associated_collectors=~s/P. *Mackay/P. MacKay/;
$Associated_collectors=~s/P. *J. *Mackay/P. J. MacKay/;
$Associated_collectors=~s/.*Boyd.*Bramlet.*Kashiwase.*LaDoux.*Provance.*Sanders.*White/et al./;
$Associated_collectors=~s/.*Boyd.*Bramlet.*Kashiwase.*LaDoux.*Provance.*Sanders.*White/et al./;
$Associated_collectors=~s/.*Boyd.*Kashiwase.*LaDoux.*Provance.*Sanders.*White.*Bramlet/et al./;
			$Associated_collectors=~s/ \./\./g;
			$Associated_collectors=~s/^w *\/ *//;
			$Associated_collectors=~s/([A-Z]\.)([A-Z]\.)([A-Z]\.)/$1 $2 $3 /g;
			$Associated_collectors=~s/([A-Z]\.)([A-Z]\.)/$1 $2 /g;
			$Associated_collectors=~s/([A-Z]\.)([A-Z]\.)/$1 $2/g;
			$Associated_collectors=~s/([A-Z]\.) ([A-Z]\.)([A-Z])/$1 $2 $3/g;
			$Associated_collectors=~s/([A-Z]\.)([A-Z])/$1 $2/g;
			$Associated_collectors=~s/,? (&|and) /, /g;
			$Associated_collectors=~s/([A-Z])([A-Z]) ([A-Z][a-z])/$1. $2. $3/g;
			$Associated_collectors=~s/([A-Z]) ([A-Z][a-z])/$1. $2/g;
			$Associated_collectors=~s/, ,/,/g;
			$Associated_collectors=~s/,([^ ])/, $1/g;
		$Associated_collectors=~s/et\. ?al/et al/;
		$Associated_collectors=~s/et all/et al/;
		$Associated_collectors=~s/et al\.?/et al./;
		$Associated_collectors=~s/etal\.?/et al./;
		$Associated_collectors=~s/([^,]) et al\./$1, et al./;
		$Associated_collectors=~s/ & others/, et al./;
		$Associated_collectors=~s/, others/, et al./;
		$Associated_collectors=~s/L\. *F\. *La[pP]r./L. F. LaPre/;
		$Associated_collectors=~s/B\. ?G\. ?Pitzer/B. Pitzer/;
		$Associated_collectors=~s/ +,/, /g;
		$Associated_collectors=~s/  */ /g;
		$Associated_collectors=~s/,,/,/g;
		$Associated_collectors=~s/J. André/J. Andre/;
		$associated_collectors=~s/Jim André/Jim Andre/;
		#warn $Associated_collectors;
			if(length($_) > 1){
				$combined_collectors="$_, $Associated_collectors";
				if($alter_coll{$combined_collectors}){
				$combined_collectors= $alter_coll{$combined_collectors};
				}
				++$collector{"$combined_collectors"};
				#warn $Associated_collectors, $combined_collectors;
			}
			else{
				if($alter_coll{$Associated_collectors}){
				$Associated_collectors= $alter_coll{$Associated_collectors};
				}
				++$collector{$Associated_collectors};
			}
			#++$collector{$_};
		}
		else{
			#if($alter_coll{$_}){
			#$_= $alter_coll{$_};
			#}
			#++$collector{$_};
		}
	}

if($low_range_f){
	#these incorrectly labelled "m" first loading!
	if($top_range_f){
		$elevation="$low_range_f - $top_range_f ft";
		if($low_range_f > $top_range_f){
				print OUT "$Label_ID_no\tlow range seems to exceed top range: $low_range_f vs $top_range_f\n";
$elevation="";
}
	}
	else{
		$elevation="$low_range_f ft";
	}
	}
elsif($low_range_m){
	if($top_range_m){
		$elevation="$low_range_m - $top_range_m m";
		if($low_range_m > $top_range_m){
				print OUT "$Label_ID_no\tlow range seems to exceed top range: $low_range_m vs $top_range_m\n";
$elevation="";
}
	}
	else{
		$elevation="$low_range_m m";
	}
	}
$elev_test=$elevation;
		$elev_test=~s/.*- *//;
		$elev_test=~s/ *\(.*//;
		$elev_test=~s/ca\.? *//;
		if($elev_test=~s/ (meters?|m)//i){
			$metric="(${elev_test} m)";
			$elev_test=$elev_test * $m_to_f;
			$elev_test= " feet";
		}
		else{
			$metric="";
		}
		if($elev_test=~s/ +(ft|feet)//i){

			if(($elev_test > $max_elev{$fields[31]}) && ($fields[31] !~ /Unknown/)){
				print OUT "$Label_ID_no\t$fields[31]\t ELEV: $elevation $metric greater than max: $max_elev{$fields[31]} discrepancy=", $elev_test-$max_elev{$fields[31]},"\n";
			}
		}

if($ecol_notes=~s/[;.] +([Aa]ssoc.*)//){
$assoc=$1;
}


$long_seconds=~s/^\./0./;
$lat_seconds=~s/^\./0./;
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
if($determiner){
	$annotation="$name; $determiner; $det_year $det_mo $det_day";
}
else{
	$annotation="";
}
$zone=$UTM_grid_zone;
#$UTM_grid_cell,
#$UTM_E,
#$UTM_N,
#$name_of_UTM_cell,
unless(($decimal_lat || $decimal_long)){
	if($zone){
		#use Geo::Coordinates::UTM;
		$easting=$UTM_E;
		$northing=$UTM_N;
		$ellipsoid=23;
		if($zone=~/9|10|11|12/ && $easting=~/\d\d\d\d\d\d/ && $northing=~/\d\d\d\d\d/){
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



#if($low_range_m|$top_range_m|$low_range_f|$top_range_f){
#print <<EOP;
#$Label_ID_no, $elevation
#EOP
#}


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
Notes: $plant
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
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
__END__
1.	Inyo	Mount Whitney	14,495 	Sequoia Sierra Nevada
1.	Tulare	Mount Whitney	14,495 	Sequoia Sierra Nevada
3.	Mono	White Mountain Peak	14,246 	West Great Basin Ranges
4.	Fresno	North Palisade	14,242 	Central Sierra Nevada
5.	Siskiyou	Mount Shasta	14,162 	California Cascades
6.	Madera	Mount Ritter	13,143 	Yosemite-Ritter Sierra Nevada
7.	Tuolumne	Mount Lyell	13,114 	Yosemite-Ritter Sierra Nevada
8.	Mariposa	Parsons Peak-Northwest Ridge	12,040+	Yosemite-Ritter Sierra Nevada
9.	San Bernardino	San Gorgonio Mountain	11,499 	Transverse Ranges
10.	Alpine	Sonora Peak	11,459 	Lake Tahoe-Sonora Pass Sierra Nevada
11.	El Dorado	Freel Peak	10,881 	Lake Tahoe-Sonora Pass Sierra Nevada
12.	Riverside	San Jacinto Peak	10,839 	Peninsular Southern California Ranges
13.	Shasta	Lassen Peak	10,457 	California Cascades
14.	Los Angeles	Mount San Antonio	10,064 	Transverse Ranges
15.	Modoc	Eagle Peak	9892 	Northwest Great Basin Ranges
16.	Amador	Thunder Mountain	9410 	Lake Tahoe-Sonora Pass Sierra Nevada
17.	Tehama	Brokeoff Mountain	9235 	California Cascades
18.	Nevada	Mount Lola	9148 	Northern Sierra Nevada
19.	Placer	Mount Baldy-West Ridge	9040+	Lake Tahoe-Sonora Pass Sierra Nevada
20.	Trinity	Mount Eddy	9025 	Klamath Mountains
21.	Sierra	Mount Lola-North Ridge Peak	8844 	Northern Sierra Nevada
22.	Ventura	Mount Pinos	8831 	Transverse Ranges
23.	Kern	Sawmill Mountain	8818 	Transverse Ranges
24.	Lassen	Hat Mountain	8737 	Northwest Great Basin Ranges
25.	Plumas	Mount Ingalls	8372 	Northern Sierra Nevada
26.	Calaveras	Corral Hollow Hill	8170 	Lake Tahoe-Sonora Pass Sierra Nevada
27.	Glenn	Black Butte	7448 	Northern California Coast Range
28.	Butte	Butte County High Point	7120+	Northern Sierra Nevada
29.	Colusa	Snow Mountain	7056 	Northern California Coast Range
29.	Lake	Snow Mountain	7056 	Northern California Coast Range
31.	Humboldt	Salmon Mountain	6956 	Klamath Mountains
32.	Mendocino	Anthony Peak	6954 	Northern California Coast Range
33.	Santa Barbara	Big Pine Mountain	6800+	Transverse Ranges
34.	San Diego	Hot Springs Mountain	6533 	Peninsular Southern California Ranges
35.	Del Norte	Bear Mountain-Del Norte CoHP	6400+	Klamath Mountains
36.	Monterey	Junipero Serra Peak	5862 	Central California Coast Ranges
37.	Orange	Santiago Peak	5687 	Peninsular Southern California Ranges
38.	San Benito	San Benito Mountain	5241 	Central California Coast Ranges
39.	San Luis Obispo	Caliente Mountain	5106 	Central California Coast Ranges
40.	Yuba	Yuba County High Point	4825+	Northern Sierra Nevada
41.	Imperial	Blue Angels Peak	4548 	Northern Baja California
42.	Sonoma	Cobb Mountain-Southwest Peak	4480+	Northern California Coast Range
43.	Santa Clara	Copernicus Peak	4360+	Central California Coast Ranges
44.	Napa	Mount Saint Helena-East Peak	4200+	Northern California Coast Range
45.	Contra Costa	Mount Diablo	3849 	Central California Coast Ranges
46.	Alameda	Valpe Ridge-Rose Flat	3840+	Central California Coast Ranges
47.	Stanislaus	Mount Stakes	3804 	Central California Coast Ranges
48.	Merced	Laveaga Peak	3801 	Central California Coast Ranges
49.	San Joaquin	Boardman North	3626 	Central California Coast Ranges
50.	Kings	Table Mountain	3473 	Central California Coast Ranges
51.	Santa Cruz	Mount Bielewski	3231 	Central California Coast Ranges
52.	Yolo	Little Blue Ridge	3120+	Northern California Coast Range
53.	Solano	Mount Vaca	2819 	Northern California Coast Range
54.	San Mateo	Long Ridge	2600+	Central California Coast Ranges
55.	Marin	Mount Tamalpais	2571 	Northern California Coast Range
56.	Sutter	South Butte	2120+	Northern Sierra Nevada
57.	San Francisco	Mount Davidson	925+	Central California Coast Ranges
58.	Sacramento	Carpenter Benchmark	828 	Lake Tahoe-Sonora Pass Sierra Nevada
