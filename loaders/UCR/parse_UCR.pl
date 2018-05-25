#open(IN,"collectors_id") || die;
open(IN,"all_collectors_2005") || die;
while(<IN>){
chomp;
#s/\t.*//;
$coll_comm{$_}++;
}
open(IN,"tnoan.out") || die;
while(<IN>){
chomp;
s/^.*\t//;
$taxon{$_}++;
}
open(IN,"riv_non_vasc") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}
open(IN,"riv_alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
$/="\cM";
open(TABFILE,">parse_riverside.out") || die;
open(OUT,">riv_problems") || die;
$date=localtime();
print OUT <<EOP;
$date
Report from running parse_riverside.pl
Name alterations from file riv_alter_names
Name comparisons made against SMASCH taxon names (which are not necessarily correct)
Genera to be excluded from riv_non_vasc

EOP

open(IN,"UCBerkeleyCAData.tab") || die;
while(<IN>){
s/\cK+$//;
s/\cK//g;
s/Õ/'/g;
s/Ò/"/g;
s/Ó/"/g;
	++$count;
	chomp;
	@fields=split(/\t/);
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
		foreach($fields[25]){
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
			s/RIVERSIDE/Riverside/;
			s/MONO/Mono/;
			s/bernardino/Bernardino/;
		}
		$county{$fields[25]}++;
		foreach($fields[6]){
			s/August/Aug/;
			s/July/Jul/;
			s/April/Apr/;
			s/\.//;
		}
	
		#$date{"$fields[6] $fields[7] $fields[5]"}++;
		#$taxon{"$fields[10] $fields[11] $fields[12] $fields[13]"}++;




$assoc= $elevation= $name=$lat=$long="";
(
$Label_ID_no,
$collector,
$Coll_no_prefix,
$Coll_no,
$Coll_no_suffix,
$year,
$month,
$day,
$other_coll,
$family,
$genus,
$species,
$subtype,
$subtaxon,
$hybrid_category,
$Snd_genus,
$Snd_species,
$Snd_subtype,
$Snd_subtaxon,
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
$Plant_description
) = @fields;
$name=$genus ." " .  $species . " ".  $subtype . " ".  $subtaxon;
$name=ucfirst(lc($name));
$name=~s/'//g;
$name=~s/`//g;
$name=~s/ *$//;
$name=~s/  +/ /g;
$name=~s/ssp\./subsp./;
$name=~s/ [Xx] / × /;
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
	print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $name
EOP
		++$skipped{one};
next;
}

$name{$name}++;
	$collector=~s/([A-Z]\.[A-Z]\.)([A-Z][a-z])/$1 $2/g;
	$collector=~s/([A-Z]\.) ([A-Z]\.)/$1$2/g;
	$other_coll=~s/([A-Z]\.[A-Z]\.)([A-Z][a-z])/$1 $2/g;
	$other_coll=~s/([A-Z]\.) ([A-Z]\.)/$1$2/g;
	foreach($collector, $other_coll){
		s/\([^)]+\)//g;
s/l, L\./L./;
s/T, T\./T./;
s/c, Y\./Y./;
s/(Adrienne Russel)([^l])/$1l$2/;
s/(D\.R\. Schram)([n])/$1m/;
s/(D\.R\. Schram)([^m])/$1m$2/;
s/Frank Ambrey/Frank Aubrey/;
s/G\. K Helmkamp/G. K. Helmkamp/;
s/Nevers,S\./Nevers, S./;
s/Thompson\./Thompson/;
s/James D. Morfield/James D. Morefield/;
s/K. Neisess/K. Neisses/;
s/Mc[cC][ou]lloh/McCulloh/;
s/L.C. Wheelr/L.C. Wheeler/;
s/Margariet Wetherwax/Margriet Wetherwax/;
s/P. Athley/P. Athey/;
s/R. F. .horne/R. F. Thorne/;
		s/Annab le/Annable/;
		s/Steve Boys/Steve Boyd/;
		s/R. *A. Pimental/R. A. Pimentel/;
		s/R. *R. Pimental/R. R. Pimentel/;
		s/R. Riggens Pimental/R. Riggens Pimentel/;
s/S Ogg/S. Ogg/;
		s/Koutnick/Koutnik/;
		s/A\. Pignioli/A. Pigniolo/;
		s/MIllet/Millett/;
s/Wiegand/Weigand/;
s/Tiliforth/Tilforth/;
		s/MacKay\./MacKay,/;
		s/Ochoterena/Ochoterana/;
		s/Rigggins/Riggins/;
		s/Walllace/Wallace/;
		s/L\. *F\. *La[pP]r./L. F. LaPre/;
		s/et\. al/et al/;
		s/et all/et al/;
		s/et al/et al./;
		s/et al\.\./et al./;
		s/ & others/, et al./;
		s/, others/, et al./;
		s/([A-Z]), ([A-Z][a-z])/$1. $2/g;
		s/([A-Z])\. ([A-Z]) /$1. $2./g;
		s/ ,/,/g;
		s/  / /g;

	}
$collector{$collector}++;
if(length($other_coll) > 2){
$coll_comm= "$collector, $other_coll";
$coll_comm=~s/, , /, /g;
$coll_comm=~s/,, /, /g;
$collector{$coll_comm}++;
($assig=$coll_comm)=~s/,.*//;
	$collector{$assig}++;
}
if($low_range_m){
	if($top_range_m){
		$elevation="$low_range_m - $top_range_m m";
	}
	else{
		$elevation="$low_range_m m";
	}
	}
elsif($low_range_f){
	if($top_range_f){
		$elevation="$low_range_f - $top_range_f m";
	}
	else{
		$elevation="$low_range_f m";
	}
	}

if($ecol_notes=~s/[;.] +([Aa]ssoc.*)//){
$assoc=$1;
}


if($long_minutes=~ s/(\d+)\.(\d)\d?/$1/){
$minute_decimal=$2;
$long_seconds= int(($minute_decimal * 60)/10);
}
if($lat_minutes=~ s/(\d+)\.(\d)\d?/$1/){
$minute_decimal=$2;
$lat_seconds= int(($minute_decimal * 60)/10);
}


($lat= "${lat_degrees} ${lat_minutes} ${lat_seconds}$N_or_S")=~s/ ([EWNS])/$1/;
($long= "${long_degrees} ${long_minutes} ${long_seconds}$E_or_W")=~s/ ([EWNS])/$1/;
$Unified_TRS="$Township$Range$section";
$country="USA" if $country=~/U\.?S\.?/;
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
Collector: $collector
Other_coll: $other_coll
Habitat: $ecol_notes
Associated_with: $assoc
Notes: $Plant_description
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long

EOP
++$included;
}
foreach(sort(keys(%collector))){
#print "$_\n" if $coll_comm{$_};
s/\./. /g;
s/  / /g;
s/ *$//;
next if $coll_comm{$_};
print "$_\n";
}

foreach(sort(keys(%name))){
	#print "$_\n" unless $taxon{$_};
}
print <<EOP;
INCL: $included
EXCL: $skipped{one};
EOP
