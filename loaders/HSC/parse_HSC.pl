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
open(IN,"Users/rlmoe/data/CDL/riv_non_vasc") || die;
while(<IN>){
	chomp;
	if(m/\cM/){
	die;
	}
	$exclude{$_}++;
}





open(IN,"../CDL/alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(TABFILE,">parse_hsc.out") || die;
open(OUT,">hsc_problems") || die;
$date=localtime();
print OUT <<EOP;
$date
Report from running parse_hsc.pl
Name alterations from file alter_names
Name comparisons made against SMASCH taxon names (which are not necessarily correct)
Genera to be excluded from riv_non_vasc

EOP

#open(IN,"HSC_june_2010.csv") || die;
open(IN,"HSC_all.csv") || die;
#$/="\cM";
#open(IN,"probs") || die;
Record: while(<IN>){
$assoc=$combined_collectors=$Collector_full_name= $elevation= $name=$lat=$long="";
#next unless m/Annette Winn/;
   s/‚Äô/'/g;
s/\cK+$//;
s/\cK//g;
s/\cM/ /g;
s/í/'/g;
s/’/'/g;
s/“/"/g;
s/”/"/g;
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
	if($fields[10]!~/^ *[A-Z]/){
		++$skipped{one};
		print OUT<<EOP;

No generic name (name not beginning with capital), skipped: $_
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
		#if(length($_)>254){
			#$fields[$i]=substr($_, 0, 249) . " ...";
			##print "$fields[$i]\n";
		#}
		#else{
			$fields[$i]=$_;
		#}
	}

	################collector numbers
	$fields[3]=~s/ *$//;
	$fields[3]=~s/^ *//;
	$fields[3]=~s/,//;
	if($fields[3]=~s/-$//){
		$fields[4]="-$fields[4]";
	}
	if($fields[3]=~s/^-//){
		$fields[2].="-";
	}
	if($fields[3]=~s/^([0-9]+)-([0-9]+)$/$2/){
		$fields[2].="$1-";
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
		s/^ *$/unknown/;
unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)$/i){
		print OUT<<EOP;

$fields[0]		Unknown California county: $_
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
			s/Eldorado/El Dorado/;
			s/Los angeles/Los Angeles/;
			s/Angelos/Angeles/;
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
			s/Humboldt and Del Norte/Humboldt/;
			s/Kern and Inyo/Kern/;
s/Riverside and San Bernardino/Riverside/;
s/Siskiyou and Trinity/Trinity/;
s/Trinity and Siskiyou/Siskiyou/;

unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)/i){
		print OUT<<EOP;
$fields[0]		Unknown California county not reconciled: $_ skipped
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
$name=ucfirst(lc($name));
$name=~s/'//g;
$name=~s/`//g;
$name=~s/\?//g;
$name=~s/ *$//;
$name=~s/  +/ /g;
$name=~s/ssp\./subsp./;
$name=~s/ [Xx] / ◊ /;
$name=~s/ *$//;
if($name=~/([A-Z][a-z-]+ [a-z-]+) ◊ /){
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
if($alter{$name}){
	print OUT <<EOP;

Spelling altered to $alter{$name}: $name 
EOP
	$name=$alter{$name};
}
unless($taxon{$name}){
	$on=$name;
	if($name=~s/subsp\./var./){
		if($taxon{$name}){
			print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
		}
		else{
	print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped
EOP
		++$skipped{one};
		$needed_name{$name}++;
next;
		}
	}
	elsif($name=~s/var\./subsp./){
		if($taxon{$name}){
			print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
		}
		else{
			print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped
EOP
		++$skipped{one};
		$needed_name{$name}++;
next;
		}
	}
	else{
	print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $name skipped
EOP
		++$skipped{one};
		$needed_name{$name}++;
	next;
	}
}

$name{$name}++;

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
		s/L\. *F\. *La[pP]r√©/L. F. LaPre/;
		s/B\. ?G\. ?Pitzer/B. Pitzer/;
		s/J. AndrÈ/J. Andre/;
		s/Jim AndrÈ/Jim Andre/;
		s/ *$//;
		$_= $alter_coll{$_} if $alter_coll{$_};
			++$collector{$_};
		if($Associated_collectors){
$Associated_collectors=~s/^, *//;
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
		$Associated_collectors=~s/L\. *F\. *La[pP]r√©/L. F. LaPre/;
		$Associated_collectors=~s/B\. ?G\. ?Pitzer/B. Pitzer/;
		$Associated_collectors=~s/ +,/, /g;
		$Associated_collectors=~s/  */ /g;
		$Associated_collectors=~s/,,/,/g;
		$Associated_collectors=~s/J. AndrÈ/J. Andre/;
		$associated_collectors=~s/Jim AndrÈ/Jim Andre/;
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

if($low_range_m){
	if($top_range_m){
		if($top_range_m > 4300){
			print OUT "Elevation set to null: $Label_ID_no: $top_range_m";
			$elevation="";
		}
		else{

		$elevation="$low_range_m - $top_range_m m";
		}
	}
	else{
		$elevation="$low_range_m m";
	}
	}
elsif($low_range_f){
	#these incorrectly labelled "m" first loading!
	if($top_range_f){
		if($top_range_f > 15000){
			print OUT "Elevation set to null: $Label_ID_no: $top_range_f";
			$elevation="";
		}
		else{
		$elevation="$low_range_f - $top_range_f ft";
		}
	}
	else{
		$elevation="$low_range_f ft";
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
if ($decimal_lat){
if ($decimal_lat < 32.5 || $decimal_lat > 42.1){
print OUT "$Label_ID_no: Latitude $decimal_lat outside CA box; lat and long nulled\n";
$decimal_lat="";
$decimal_long="";
}
}
if ($decimal_long){
if ($decimal_long > -114.0 || $decimal_long < -124.5){
print OUT "$Label_ID_no: Longitude $decimal_long outside CA box; lat and long nulled\n";
$decimal_long="";
$decimal_lat="";
}
}
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
elsif($month=~/^ *$/){
		print OUT<<EOP;
$Label_ID_no: Date config problem $year $month $day: day nulled
EOP
$day="";
}
$Unified_TRS="$Township$Range$section";
$country="USA" if $country=~/U\.?S\.?/;
if($determiner){
	$annotation="$name; $determiner; $det_year $det_mo $det_day";
}
else{
	$annotation="";
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
Other_coll: $Associated_collectors
Combined_collector: $combined_collectors
Habitat: $ecol_notes
Associated_species: $assoc
Notes: $Plant_description
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
Latitude 33 45.75N
UCR151096
UCR151097
UCR151098
UCR151099
UCR151100
UCR151101
UCR151102
UCR151103
UCR151104

Longitude 117 10 49W
UCR153440
UCR153441
UCR153442
UCR153443

Longitude 117 20 0.2W
UCR164850
UCR164919

Latitude 34 12 0.5N
UCR165226

Longitude 115 31 52W
UCR165474
UCR165477
UCR165484
UCR165497
UCR165498
UCR165499
UCR165500
UCR165501
UCR165502
UCR165503
UCR165507
UCR165508
UCR165509
UCR165510
UCR165511
UCR165512
UCR165513
UCR165514
UCR165806
UCR165808

Longitude -120.1663888888888889
UCR168257

Longitude 116 32 18W
UCR171699

Longitude 116 54 0.5W
UCR171753

Longitude 117 06 37.8 W
UCR171802

Latitude 33 46 08N
UCR172733
UCR172734
UCR172735
UCR172736
UCR172737
UCR172738
UCR172739
UCR172740
UCR172741

Longitude 116.7652777777777778
UCR177213
nulled

Latitude 32 51 15N
UCR177538
UCR177539
UCR177540
UCR177610
UCR177611
UCR177612
UCR177613
UCR177781
UCR177782
UCR177783
UCR177788
UCR177791

Longitude 117 59 03W
UCR178923
UCR178925
UCR179229
UCR179230
UCR179231
UCR179232
UCR179233
UCR179274

Longitude 117 27 36W
UCR180068

Longitude 117 27 27W
UCR180077

Longitude 117 27 42W
UCR180085

Longitude 117 27 08W
UCR180086

Latitude 34 19 14.2N
Longitude 116 51 15W
UCR184622

Longitude 115 41 0.2W
UCR185050
UCR185051
UCR185052
UCR185103
UCR185104
UCR185105
UCR185106
UCR185107
UCR185118

Longitude 120 32 08W
UCR185198

Longitude 120 46 02W
UCR185199

Longitude -118.4038888888888889
UCR25840
UCR26009
UCR26038
UCR26039

Latitude 34 17 13N
UCR27112

Latitude 39.8361111111111111
UCR47728

Longitude 117 02 28W
UCR95717
"HSC-81373"	"L.F. LaPr√©"		"sn"		1985	"May"	28		"PLG"	"Eriogonum"		"kennedyi"		"var."	"austromontanum"										"Synonym of most recent determination"				"US"	"CA"	"San Bernardino"			"E end of Bear Valley around Baldwin Lake, north shore in sec 31, near BM 6736"				"N"	0				"W"	0														2073		6800						
"HSC-81374"	"L.F. LaPr√©"		"sn"		1985	"May"	28		"CRY"	"Eremogone"		"ursina"													"Synonym of most recent determination"				"US"	"CA"	"San Bernardino"			"E end of Bear Valley around Baldwin Lake, north shore in sec 31, near BM 6736"				"N"	0				"W"	0														2073		6800						
"HSC-84168"	"B. Pitzer"		"421"		1987	"Mar"	2	"L.F. LaPr√©"	"AST"	"Encelia"		"farinosa"													"A.C. Sanders"	1987	"Mar"		"US"	"CA"	"Riverside"		"Romoland 7.5"	"Bundy Canyon; ca. 2 mi. SE of Lake Elsinore and 0.5 mi. N of Bundy Canyon Rd. off Raciti Rd."				"N"	0				"W"	0	"6S"	"4W"	"24"	"SE 1/4"										701		2300		"Coastal sage scrub  "				
"HSC-86918"	"L.F. LaPr√©"		"sn"		1988	"Mar"	3		"AST"	"Ericameria"		"linearifolia"													"Synonym of most recent determination"				"US"	"CA"	"San Bernardino"	"Santa Ana River Valley"	"Redlands 7.5‚Äô Q."	"Santa Ana River wash, N of Redlands & E  of Orange St. Tri-City Aggregate property"	34	5	37	"N"	34.09	117	10	10	"W"	-117.17	"1S"	"3W"	"11"	"SW/4"	"1S"	"3W"	"14"	"N/2"						427		1400		"Wash & bench with alluvial fan sage scrub dominated by Lepidospartum, Salvia apiana, Senecion douglasii, etc. on sandy & gravelly soil.  "				
"HSC-87025"	"L.F. LaPr√©"		"sn"		1988	"Jun"	3		"AST"	"Deinandra"		"kelloggii"													"Synonym of most recent determination"				"US"	"CA"	"Riverside"	"Peninsular Range"	"Alberhill 7.5‚Äô Q."	"Indian Trails project site, Indian Truck Trail exit on W side of I-15 fwy in Temescal Cyn, ca. 1/4 mi from the freeway"	33	45		"N"	33.75	117	27		"W"	-117.45																		"Dirt rd.  "				
HSC-84169	B.G. Pitzer		432		1987	Mar	2	L.F. LaPr¬é	POA	Muhlenbergia		microsperma																	US	CA	Riverside		Romoland 7.5√ï Q.	"Bundy Canyon, 2 mi SE of Lake Elsinore, 0.5 mi N of Bundy Canyon Road"	33	37		N	33.61666667	117	15		W	-117.25	 6S	4W	24	 SE/4 										703		2300		"Coastal sage scrub on fairly steep slopes, w/ Salvia mellifera, Adenostoma fasciculatum, Artemisia californica & Ceanothus crassifolius."			Wild: native/naturalized	Introduced
