open(IN,"rsa_dups") || die;
while(<IN>){
chomp;
next unless m/^(POM|RSA)/;
s/-//g;
$rsa_dups{$_}++;
}
close(IN);
open(TABFILE,">rsa_out_new.tab") || die;
open(IN,"../CDL/collectors_id") || die;
while(<IN>){
chomp;
s/\t.*//;
s/\cJ//;
s/\cM//;
$coll_comm{uc($_)}++;
}
foreach(keys(%coll_comm)){
	##print "$_\n";
}
open(IN,"../CDL/tnoan.out") || die;
while(<IN>){
	chomp;
s/\cJ//;
s/\cM//;
	s/^.*\t//;
	$taxon{$_}++;
}
foreach(keys(%taxon)){
	#print "$_\n";
}
#die "that was the taxon hash\n";
open(IN,"oldrsa/rsa/rsa_alter_coll") || die;
while(<IN>){
	chomp;
s/\cJ//;
s/\cM//;
	next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	$alter_coll{$rsa}=$smasch;
}
open(IN,"../CDL/alter_names") || die;
while(<IN>){
	chomp;
s/\cJ//;
s/\cM//;
	next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	$alter{$rsa}=$smasch;
}
open(OUT,">RSA_problems") || die;
open(TAXON_OUT,">RSA_missing_taxon") || die;
open(IN,"rsa_2009_in") || die;
#open(IN,"UCJepsExtract.tab") || die;
#open(IN,"all_new_rsa") || die;
#open(IN,"modified records.txt") || die;
#open(IN,"new_reordered") || die;

	RECORD: while(<IN>){
#next RECORD  unless m/505269|519112/;

	chomp;
	s/\cK/ /g;
s/\cM//g;
$name=$Country=$Township=$Range=$section= $month=$day=$year= ${Coll_no_prefix}= ${Coll_no}= ${Coll_no_suffix}= $Full_scientific_name= $Label_ID_no= $family= $Country= $State= $County= $Physiographic_region= $Locality= $Unified_TRS= $topo_quad= $elevation= $Collector_full_name= $Associated_collectors= $Ecological_setting= $assoc= $Plant_specifics= $lat= $long= $decimal_lat= $decimal_long=$lon_degrees=$long_minutes=$long_seconds=$lat_degrees=$lat_minutes=$lat_seconds=$color=$combined_collectors="";
	$line=$_;
	s/, *, /, /g;
	s/^"//;
	s/"$//;
	#s/\t/ /g;
	s/  / /g;
s/Õ/'/g;
#@fields=split(/","/);
@fields=split(/\t/);
#gets rid of genus
#splice(@fields,3,1);
grep(s/^"//,@fields);
grep(s/"$//,@fields);
	if($fields[39]=~s/ *([Aa]ssoc.*)//){
		$assoc=$1;
	}
	elsif($fields[39]=~s/ *([Ww]ith [A-Z].*)//){
if($assoc){
$assoc .= "; $1";
}
else{
		$assoc=$1;
}
}
	if($fields[38]=~s/ *([Aa]ssoc.*)//){
if($assoc){
$assoc .= "; $1";
}
else{
		$assoc=$1;
}
	}
	elsif($fields[38]=~s/ *([Ww]ith [A-Z].*)//){
if($assoc){
$assoc .= "; $1";
}
else{
		$assoc=$1;
}
	}
	if($fields[39]=~s/((Fls|Flowers).*(red|pink|blue|white|purple|orange|violet|green|yellow|black|maroon|brown|cream|lavender)(ish)?.*)//){
$color=$1;
}
	foreach $i (0 .. $#fields){
		#print "$i: $fields[$i]\n";
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







(
$Primary_key,
$Label_ID_no,
$Family_,
$Genus,
$Species,
$Subtype,
$Subtaxon,
$Full_scientific_name,
$Collector_last_name,
$Collector_full_name,
$Collector_number,
$Associated_collectors,
$day,
$month,
$year,
$Country,
$State,
$County,
$Physiographic_region,
$Locality,
$Elevation_lower_range_ft,
$Elevation_top_range_ft,
$Elevation_lower_range_meters,
$Elevation_top_range_meters,
$lat_degrees,
$lat_minutes,
$lat_seconds,
$N_or_S,
$long_degrees,
$long_minutes,
$long_seconds,
$E_or_W,
$Township,
$Range,
$Section,
$Quarter,
$UTM_E,
$UTM_N,
$Ecological_setting,
$Plant_specifics,
$UTM_zone,
$Kind_of_type,
$Type_yes_or_no,
)= @fields;
#$UTM_zone, left out
$N_or_S="N";
$E_or_W="W";
$day=~s/ ?\.\.\. ?/-/;
$day=~s/ ?\.\. ?/-/;
	$Label_ID_no=~s/- *//;
	$Label_ID_no=~s/RSA POM/POM/;
	if(length($Label_ID_no) > 15){
		++$skipped{one};
		print OUT<<EOP;
Something wrong with accession number, skipped: $line
EOP
		next RECORD;
	}
	if($Label_ID_no !~/^(POM|RSA)/i){
		++$skipped{one};
		print OUT<<EOP;
No POM or RSA in accession number, skipped: $line
EOP
		next RECORD;
	}
	if($Label_ID_no=~/^[^0-9]*$/){
		++$skipped{one};
		print OUT<<EOP;
No accession number, skipped: $line
EOP
		next RECORD;
	}
	if($seen{$Label_ID_no}++ || $rsa_dups{$Label_ID_no}){

		print OUT<<EOP;
		Duplicate accession number, skipped: $line
EOP
		next RECORD;
	}
	unless ($State =~/^ *(CA|California|Calif.|Ca) *$/){
		if($State=~/^ *$/){
			if ($County=~m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)$/){
				$State="CA";
			}
			else{
				#warn <<EOP;
#State Null, skipped: $line
#EOP
			next RECORD;
			}
		}
		else{
		print OUT <<EOP;
State $State not CA, skipped: $line
EOP
		next RECORD;
		}
	}
$State="CA";

	foreach($Collector_full_name){

s/O.Brien/O'Brien/g;
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
		if($Associated_collectors){
$Associated_collectors=~s/O[^A-Za-z.-]B/O'B/g;
			$Associated_collectors=~s/ \./\./g;
			$Associated_collectors=~s/^w *\/ *//;
			$Associated_collectors=~s/([A-Z]\.)([A-Z]\.)([A-Z]\.)/$1 $2 $3 /g;
			$Associated_collectors=~s/([A-Z]\.)([A-Z]\.)/$1 $2 /g;
			$Associated_collectors=~s/([A-Z]\.)([A-Z]\.)/$1 $2/g;
			$Associated_collectors=~s/([A-Z]\.) ([A-Z]\.)([A-Z])/$1 $2 $3/g;
			$Associated_collectors=~s/([A-Z]\.)([A-Z])/$1 $2/g;
			$Associated_collectors=~s/,? (&|and) /, /;
			$Associated_collectors=~s/([A-Z])([A-Z]) ([A-Z][a-z])/$1. $2. $3/g;
			$Associated_collectors=~s/([A-Z]) ([A-Z][a-z])/$1. $2/g;
			$Associated_collectors=~s/, ,/,/g;
			$Associated_collectors=~s/,([^ ])/, $1/g;
		$Associated_collectors=~s/  */ /g;
			if(length($_) > 1){
				$combined_collectors="$_, $Associated_collectors";
				if($alter_coll{$combined_collectors}){
				$combined_collectors= $alter_coll{$combined_collectors};
				}
				++$collector{"$combined_collectors"};
			}
			else{
				if($alter_coll{$Associated_collectors}){
				$Associated_collectors= $alter_coll{$Associated_collectors};
				}
				++$collector{$Associated_collectors};
			}
			++$collector{$_};
		}
		else{
				if($alter_coll{$_}){
				$_= $alter_coll{$_};
				}
			++$collector{$_};
		}
	}
foreach($County){
s/ *\?//;
s/boundary between Los Angeles and San Bernardino/Los Angeles/;
s/[\[\]]//g;
s/ Co\.//;
s/ County//;
s/Alemeda/Alameda/;
s/Calavaras/Calaveras/;
s/Conta Costa/Contra Costa/;
s/Eldorado/El Dorado/;
s/Fresno to Monterey/Fresno/;
s/Fresno-Inyo/Fresno/;
s/Humbloldt/Humboldt/;
s/Imperial.*/Imperial/;
s/Inyo.*/Inyo/;
s/InyoInyo/Inyo/;
s/Inyo\?/Inyo/;
s/Kern.*/Kern/;
s/Kern`/kern/;
s/Los Angeles.*/Los Angeles/;
s/Los Angeles.*/Los Angeles/;
s/Los angeles/Los Angeles/;
s/MONO/Mono/;
s/Maroposa/Mariposa/;
s/Mono.*/Mono/;
s/Monoi/Mono/;
s/Monterery/Monterey/;
s/Monterey`/Monterey/;
s/Montery/Monterey/;
s/Not Given/Unknown/;
s/Not given/Unknown/;
s/Orange.*/Orange/;
s/Placer.*/Placer/;
s/Riv erside/Riverside/;
s/Riverside.*/Riverside/;
s/Rvierside/Riverside/;
s/Samta Barbara/Santa Barbara/;
s/San Bernadino/San Bernardino/;
s/San Bernadion/San Bernardino/;
s/San Bernardino.*/San Bernardino/;
s/San Clara/Santa Clara/;
s/San Deigo/San Diego/;
s/San Diego.*/San Diego/;
s/San DiegoSan Diego/San Diego/;
s/San Fracisco/San Francisco/;
s/San Francscio/San Francisco/;
s/San Lius Obisopo/San Luis Obispo/;
s/San Lius Obispo/San Luis Obispo/;
s/San Luis Obisbo/San Luis Obispo/;
s/San Luis Obispo \/ Kern/San Luis Obispo/;
s/San Luis Obispo \/ Santa Barbara/San Luis Obispo/;
s/San Luis obispo/San Luis Obispo/;
s/Sant Barbara/Santa Barbara/;
s/Santa BarbaraSanta Barbara/Santa Barbara/;
s/Santa Mateo/San Mateo/;
s/Sierra-Plumas/Sierra/;
s/Siskiuyou/Siskiyou/;
s/Siskiyou.*/Siskiyou/;
s/Snata Clara/Santa Clara/;
s/Southeastern Humboldt/Humboldt/;
s/Trinuty/Trinity/;
s/Tulare .*/Tulare/;
s/Tuol.*/Tuolumne/;
s/Ventura.*/Ventura/;
s/^Benito/San Benito/;
s/^\?/Unknown/;
s/Humbolt/Humboldt/;
s|Colusa/Lake|Colusa|;
s/^ *$/Unknown/;
s/Fresno line/Fresno/;
}
unless ($County=~m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|[Uu]nknown)$/){
warn "Not a CA county: $County\n";
		print OUT <<EOP;
$County not a CA county, skipped: $line
EOP
next RECORD;
}
		$county{$County}++;
	
	################collector numbers
	foreach($Collector_number){
	s/ *$//;
	s/^ *//;
	if(s/^([0-9]+)(-[0-9]+)$/$2/){
		$Coll_no_prefix=$1;
	}
	if(s/^([0-9]+)(\.[0-9]+)$/$1/){
		$Coll_no_suffix=$2;
	}
	if(s/^([0-9]+)([A-Za-z]+)$/$1/){
		$Coll_no_suffix=$2;
	}
	if(s/^([0-9]+)([^0-9])$/$1/){
		$Coll_no_suffix=$2;
	}
	if(s/^(S\.N\.|s\.n\.)$//){
		$Coll_no_suffix=$1;
	}
	if(s/^([0-9]+-)([0-9]+)([A-Za-z]+)$/$2/){
		$Coll_no_suffix=$3;
		$Coll_no_prefix=$1;
	}
	if(m/[^\d]/){
	s/(.*)//;
		$Coll_no_suffix= $1 . $Coll_no_suffix;
	}
}
$year=~s/ ?\?$//;
$year=~s/^['`]+//;
$year=~s/['`]+$//;
unless($year=~/^(1[789]\d\d|20\d\d)$/){
unless($year=~/^ *$/){
		print OUT<<EOP;
Date config problem year is $year month is $month day is $day: date nulled $Label_ID_no:
EOP
}
	$year=$month=$day="";
}
foreach($month){
next if m/^ *$/;
if(m/[.-]/){
		print OUT<<EOP;
Date config problem $year $month $day: date nulled: $Label_ID_no: 
EOP
	$year=$month=$day="";
}
s/^jan.*/01/i;
s/^feb.*/02/i;
s/^mar.*/03/i;
s/^apr.*/04/i;
s/^ma*y.*/05/i;
s/^jun.*/06/i;
s/^jul.*/07/i;
s/^aug.*/08/i;
s/^sep.*/09/i;
s/^[0o]ct.*/10/i;
s/^nov.*/11/i;
s/^dec.*/12/i;
s/^([1-9])$/0$1/;
unless (m/^(01|02|03|04|05|06|07|08|09|10|11|12)/){
		print OUT<<EOP;
Date config problem $year $month $day: date nulled $Label_ID_no:
EOP
	$year=$month=$day="";
}
}
$day=~s/ ?\.\.\. ?/-/;
$day=~s/ ?\.\. ?/-/;
unless($day=~/(^[0-3]?[0-9]$)|(^[0-3]?[0-9]-[0-3]?[0-9]$)|(^$)/){
		print OUT<<EOP;
Date config problem $year $month $day: date nulled $Label_ID_no
EOP
	$year=$month=$day="";
}






		foreach($Full_scientific_name){
$original_name=$_;
			s/^\.//;
			$_=ucfirst(lc($_));
			s/,//g;
			s/`//g;
	s/ ssp\.? / subsp. /;
	s/ spp\.? / subsp. /;
	s/ ssp\.$//;
	s/ subsp / subsp. /;
	s/ var / var. /;
	s/ forma / f. /;
	s/ fo. / f. /;
	s/ undescr\..*/ sp./;
	s/ [iu]ndet\..*/ sp./;
	s/ sp\.//;
	s/  */ /g;
				s/ [xX] / × /;
			$name=$_;
			s/ssp\./subsp./;
if(s/ (cf\.|aff\.)//){
$note="as $original_name";
}
else{
$note="";
}
			#if($name=~/^ *$/){
		#print OUT<<EOP;
		#No taxon name: $line
#EOP
		#next RECORD;
	#}
			if($name=~/([A-Z][a-z-]+ [a-z-]+) × /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/([A-Z][a-z-]+ [a-z-]+ (var\.|subsp\.) [a-z-]+) × /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			else{
				$hybrid_annotation="";
			}
	if($alter{$name}){
		print TAXON_OUT <<EOP;

Spelling altered to $alter{$name}: $name 
EOP
		$name=$alter{$name};
	}
	if($alter{$name}){
		print TAXON_OUT <<EOP;

Spelling altered further to $alter{$name}: $name 
EOP
		$name=$alter{$name};
	}
	if($name=~/[a-z]+ [a-z]+ +[Xx] +[a-z]+/){
				print TAXON_OUT <<EOP;

Can't deal with unnamed hybrids yet: $name skipped
EOP
		++$skipped{$name};
		next RECORD;
	}
	$name=~s/ssp\./subsp./;
	unless($taxon{$name}){
		$on=$name;
		if($name=~s/subsp\./var./){
			if($taxon{$name}){
				print TAXON_OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
			}
			else{
				print TAXON_OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped
EOP
		++$skipped{$on};
		next RECORD;
		}
	}
	elsif($name=~s/var\./subsp./){
		if($taxon{$name}){
			print TAXON_OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
		}
		else{
			print TAXON_OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped
EOP
		++$skipped{$on};
next RECORD;
		}
	}
	else{
		print TAXON_OUT <<EOP;

Not yet entered into SMASCH taxon name table: $name skipped
EOP
		++$skipped{$on};
	next RECORD;
	}
}
else{
}
		}
			unless($name=~/[A-Za-z]/){
		print OUT<<EOP;
		No taxon name: $line
EOP
		next RECORD;
	}
	++$count;
	#ELEVATION
if($Elevation_lower_range_meters){
	if($Elevation_top_range_meters){
		$elevation="$Elevation_lower_range_meters - $Elevation_top_range_meters m";
	}
	else{
		$elevation="$Elevation_lower_range_meters m";
	}
	}
elsif($Elevation_lower_range_ft){
	if($Elevation_top_range_ft){
		$elevation="$Elevation_lower_range_ft - $Elevation_top_range_ft ft";
	}
	else{
		$elevation="$Elevation_lower_range_ft ft";
	}
	}
	if($long_degrees=~m/(\d+\.\d+)/){
		$decimal_long=$1;
		if($lat_degrees=~m/(\d+\.\d+)/){
			$decimal_lat=$1;
		}
		else{
			print OUT "decimal longitude no latitude config problem; Lat and long nulled $Label_ID_no: \n";
			$decimal_lat=$decimal_long="";
		}
	}
	elsif($lat_degrees=~m/(^\d+\.\d+$)/){
		print OUT "Decimal Latitude no longitude config problem; Lat and long nulled $Label_ID_no: \n";
		$decimal_lat=$decimal_long="";
		}
		else{

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
	if($lat_seconds=="60"){
		$lat_seconds="00";
		$lat_minutes +=1;
		if($lat_minutes=="60"){
			$lat_minutes="00";
			$lat_degrees +=1;
		}
	}
	if($long_seconds=="60"){
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
$long=~s/°//;
$long=~s/º//;
$lat=~s/°//;
$lat=~s/º//;
$lat=~s/Â//;
$long=~s/Â//;
$lat=~s/^ *([EWNS])//;
$long=~s/^ *([EWNS])//;
$lat=~s/^ *//;
$long=~s/^ *//;

if($long){
	unless ($long=~/\d\d\d \d\d? \d\d?W/ || $long=~/\d\d\d \d\d?W/ || $long=~/\d\d\d \d\d? \d\d?\.\dW/){
		print OUT "Longitude $long config problem; lat and long nulled $Label_ID_no: \n";
		$long="";
		$lat="";
	}
	unless($lat =~ /\d/){
		$long="";
		print OUT<<EOP;
Longitude no latitude config problem; long nulled $Label_ID_no: 
EOP
	}
}
if($lat){
unless ($lat=~/\d\d \d\d? \d\d?N/ || $lat=~/\d\d \d\d?N/ || $lat=~/\d\d \d\d? \d\d?\.\dN/){
print OUT "Latitude $lat config problem; Lat and long nulled $Label_ID_no: \n";
$lat="";
$long="";
}
unless($long=~/\d/){
	$lat="";
		print OUT<<EOP;
Latitude no longitude config problem; lat nulled: $Label_ID_no:
EOP
}
}
}
if($lat_degrees=~/\d+/){
if(($lat_degrees > 43 || $lat_degrees < 32)){
$lat="", $long="";
		print OUT<<EOP;
Latitude out of range, nulled: $Label_ID_no 
EOP
}
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


if(($lat_minutes=~/\d/ && $lat_minutes > 59) || ($lat_seconds=~/\d/ && $lat_seconds > 59)){
		print OUT<<EOP;
Latitude misconfig, nulled: $Label_ID_no >$lat_minutes $lat_seconds<
EOP
$lat="", $long="";
}
if(($long_minutes=~/\d/ && $long_minutes > 59) || ($long_seconds=~/\d/ && $long_seconds > 59)){
		print OUT<<EOP;
Longitude misconfig, nulled: $Label_ID_no >$long_minutes $long_seconds<
EOP
$lat="", $long="";
}
	
$Unified_TRS="$Township$Range$Section";
$Country="USA" if $Country=~/U\.?S\.?/;
$Country="USA" if $Country=~/United States$/;
if($Collector_number){
	unless ($Collector_full_name){
		print OUT<<EOP;
$Label_ID_no No collector, but collector number is $Collector_number and other collectors are $Associated_collectors
EOP
if($Associated_collectors){
	warn "$Label_ID_no: No collector\n";
		print OUT<<EOP;
$Label_ID_no No collector, other collectors are $Associated_collectors
EOP
}
else{
	$Collector_full_name="Unknown";
}
}
}
print TABFILE <<EOP;
Date: $month $day $year
CNUM_PREFIX: $Coll_no_prefix
CNUM: $Collector_number
CNUM_SUFFIX: $Coll_no_suffix
Name: $name
Accession_id: $Label_ID_no
Family_Abbreviation: $family
Country: $Country
State: $State
County: $County
Loc_other: $Physiographic_region
Location: $Locality
T/R/Section: $Unified_TRS
USGS_Quadrangle: $topo_quad
Elevation: $elevation
Collector: $Collector_full_name
Other_coll: $Associated_collectors
Combined_coll: $combined_collectors
Habitat: $Ecological_setting
Associated_with: $assoc
Notes: $Plant_specifics
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Color: $color
Hybrid_annotation: $hybrid_annotation
Note: $note
Type_status: $Kind_of_type

EOP
++$included;
}

open(OUT,">RSA_missing_collector") || die;
foreach(sort {$collector{$a}<=>$collector{$b}}(keys(%collector))){
	print OUT "$_: $collector{$_}\n" unless $coll_comm{uc($_)};
}

print "$included included\n";
foreach(sort {$skipped{$a}<=>$skipped{$b}}(keys(%skipped))){
	print "$_: $skipped{$_}\n";
}
