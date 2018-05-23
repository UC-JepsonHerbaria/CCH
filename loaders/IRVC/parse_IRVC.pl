#use BerkeleyDB;
#tie %f_contents, "BerkeleyDB::Hash",
                #-Filename => "/Users/rlmoe/CDL_buffer/buffer/CDL_DBM",
                #-Flags => DB_CREATE
        #or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;
#
##0 accn	herbarium	family	genus	species	subtype	subtaxon	collector	coll._____prefix	coll_no	coll. suffix	assoc___________colls	day	month	year	type	type of type	determiner	detDay	det. Month	det. Year	fr/ft	coll. source	notes	lat deg	lat min	lat sec	n/s	lat accuracy	long deg	long min	long sec	w/e	long accuracy	country	state	county	primary physiographic area	topo quad	location	utm zone	utme	utmn	utm accuracy	meters	meters top	feet	feet top	vegetation	township	range	section	quarter	georef determination
##(acc	herbarium	Family	Genus	species	subtype	subtaxon	collector	collector_prefix	Coll_no	coll_Suffix	associated_collectors	day	month	year	Type	type_of_type	determiner	det_Day	det_month	det_year	fr_ft	coll_source	notes	lat_deg	lat_min	lat_sec	n_s	lat_accuuracy	long_deg	long_min	long_sec	w_e	long_accuracy	country	state	County	primary_physiograpic_area	Topo_quad	location	utm_zone	utme	utmn	utm_accuracy	meters	meter_top	feet	feet_top	vegetation	township	range	section	quarter	geref_determination)=split(/\t/,_,100);
#
open(IN,"/Users/rlmoe/CDL_buffer/buffer/CDL/IRVC_new.out") || die;
$/="";
while(<IN>){
if(m/Accession_id: (.*)/){
$store{$1}=$_;
}
}
$/="\n";
open(IN,"/Users/rlmoe/CDL_buffer/buffer/tnoan.out") || die;
while(<IN>){
chomp;
($code,$name)=split(/\t/);
$TNOAN{$code}=$name;
$taxon{$name}++;
}
open(IN,"../../CDL/riv_non_vasc") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}
open(IN,"../../CDL/alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(TABFILE,">parse_irvine.out") || die;
open(OUT,">irvine_problems") || die;
$date=localtime();
print OUT <<EOP;
$date
Report from running parse_irvine.pl
Name alterations from file alter_irvine
Name comparisons made against SMASCH taxon names (which are not necessarily correct)
Genera to be excluded from riv_non_vasc

EOP

open(IN,"IRVC.tab") || die;
while(<IN>){
$vegetation=$elevation=$Label_ID_no= $collector= $Coll_no_prefix= $Coll_no= $Coll_no_suffix= $year= $month= $day= $other_coll= $family= $genus= $species= $subtype= $subtaxon= $hybrid_category= $Snd_genus= $Snd_species= $Snd_subtype= $Snd_subtaxon= $determiner= $det_year= $det_mo= $det_day= $country= $state= $county_mpio= $physiographic_region= $topo_quad= $locality= $lat_degrees= $lat_minutes= $lat_seconds= $N_or_S= $long_degrees= $long_minutes= $long_seconds= $E_or_W= $Township= $Range= $section= $Fraction_of_section= $Snd_township= $Snd_Range= $Snd_section= $Snd_Fraction_of_section= $something= $UTM_grid_zone= $UTM_grid_cell= $UTM_E= $UTM_N= $name_of_UTM_cell= $low_range_m= $top_range_m= $low_range_f= $top_range_f= $ecol_notes= $Plant_description="";

	++$count;
	s/\cK//g;
	chomp;
	$line_store=$_;
	@fields=split(/\t/, $_,100);
	if($fields[0]=~/^ *$/){
		++$skipped{one};
		print OUT<<EOP;

No accession number, skipped: $_
EOP
		next;
	}
	$fields[0]=~s/^0*//;

	if($fields[2]!~/^ *[A-Z]/){
		++$skipped{one};
		print OUT<<EOP;

No generic name (name not beginning with capital: $fields[2]), skipped: $Label_ID_no $_
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

$Label_ID_no="IRVC$fields[0]";

	unless($fields[35]=~/^(CA|Calif)/){
		++$skipped{one};
		warn "Non-California record: $fields[0] $fields[35] $fields[36]<\n";
		print OUT<<EOP;

Non-California record: $Label_ID_no $fields[0] $fields[35] $fields[36]
EOP
		next;
	}




	foreach $i (0 .. $#fields){
		$_=$fields[$i];
		s/ *$//;
		s/^ *//;
		s/^"(.*)"$/$1/;
	}

	################collector numbers
	$fields[9]=~s/ *$//;
	$fields[9]=~s/^ *//;
	if($fields[9]=~s/-$//){
		$fields[10]="-$fields[10]";
	}
	if($fields[9]=~s/^-//){
		$fields[8].="-";
	}
	if($fields[9]=~s/^([0-10]+)(-[0-10]+)$/$2/){
		$fields[8].=$1;
	}
	if($fields[9]=~s/^([0-10]+)(\.[0-10]+)$/$1/){
		$fields[10]=$2 . $fields[10];
	}
	if($fields[9]=~s/^([0-10]+)([A-Za-z]+)$/$1/){
		$fields[10]=$2 . $fields[10];
	}
	if($fields[9]=~s/^([0-10]+)([^0-10])$/$1/){
		$fields[10]=$2 . $fields[10];
	}
	if($fields[9]=~s/^(S\.N\.|s\.n\.)$//){
		$fields[10]=$1 . $fields[10];
	}
	if($fields[9]=~s/^([0-10]+-)([0-10]+)([A-Za-z]+)$/$2/){
		$fields[10]=$3 . $fields[10];
		$fields[8].=$1;
	}
	if($fields[9]=~m/[^\d]/){
	$fields[9]=~s/(.*)//;
		$fields[10]=$1 . $fields[10];
	}
		foreach($fields[36]){
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
			s/Santan Barbara/Santa Barbara/;
			s/RIverside/Riverside/;
			s/RIVERSIDE/Riverside/;
			s/MONO/Mono/;
			s/Toulumne/Tuolumne/;
			s/Tulrae/Tulare/;
			s/bernardino/Bernardino/;
		}
		$county{$fields[36]}++;
		foreach($fields[12]){
			s/August/Aug/;
			s/July/Jul/;
			s/April/Apr/;
			s/\.//;
		}
	
$combined_collectors=$UTM_accuracy=$lat_accuracy=$long_accuracy=$type=$type_of_type=$assoc= $elevation= $name=$lat=$long="";
#(acc	herbarium	Family	Genus	species	subtype	subtaxon	collector	collector_prefix	Coll_no	coll_Suffix	associated_collectors	day	month	year	Type	type_of_type	determiner	det_Day	det_month	det_year
#fr_ft	coll_source	notes	lat_deg	lat_min	lat_sec	n_s	lat_accuuracy	long_deg	long_min	long_sec	w_e	long_accuracy	country	state	County	primary_physiograpic_area	Topo_quad	location	utm_zone
#utme	utmn	utm_accuracy	meters	meter_top	feet	feet_top	vegetation	township	range	section	quarter	geref_determination)=split(/\t/,_,100);
(
$null,
$herbarium,
$family,
$genus,
$species,
$subtype,
$subtaxon,
$collector,
$Coll_no_prefix,
$Coll_no,
$Coll_no_suffix,
$other_coll,
$day,
$month,
$year,
$type,
$type_of_type,
$determiner,
$det_day,
$det_month,
$det_year,
$phenology,
$coll_source,
$ecol_notes,
$lat_degrees,
$lat_minutes,
$lat_seconds,
$N_or_S,
$lat_accuracy,
$long_degrees,
$long_minutes,
$long_seconds,
$E_or_W,
$long_accuracy,
$country,
$state,
$county_mpio,
$physiographic_region,
$Topo_quad,
$locality,
$utm_zone,
$utme,
$utmn,
$utm_accuracy,
$low_range_m,
$top_range_m,
$low_range_f,
$top_range_f,
$vegetation,
$township,
$range,
$section,
$quarter,
$georef_det
) = @fields;
@raw_fields=@fields;
$raw_list=join("\n",@raw_fields);
$raw_list=~s/\n+/\n/g;
$collector=~s/"$//;
$collector=~s/^"//;
$locality=~s/"$//;
$locality=~s/^"//;
$other_coll=~s/"$//;
$other_coll=~s/^"//;
#$Label_ID_no=~s/^/IRVC/;
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

Excluded, not a vascular plant: $Label_ID_no $name
EOP
		++$skipped{one};
	next;
}
if($alter{$name}){
	print OUT <<EOP;

Spelling altered to $alter{$name}: $Label_ID_no $name 
EOP
	$name=$alter{$name};
}



		$name=~s/ssp\./subsp./;
		$name=~s/ cultivar\. .*//;
		$name=~s/ (cf\.|affn?\.|sp\.)//;
		unless($taxon{$name}){
			$name=~s/var\./subsp./;
if($alter{$name}){
	print OUT <<EOP;
Spelling altered to $alter{$name}: $name 
EOP
	$name=$alter{$name};
}
			unless($taxon{$name}){
				$name=~s/subsp\./var./;
if($alter{$name}){
	print OUT <<EOP;
Spelling altered to $alter{$name}: $name 
EOP
	$name=$alter{$name};
}
				unless($taxon{$name}){
					$noname{$name}++;
	print OUT <<EOP;
Name not yet entered into smasch, skipped: $accession_id $name 
EOP
	next;
				}
			}
		}



$name=~s/ *\?//;




unless($taxon{$name}){
$name{$name}++;
	print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $Label_ID_no $name
EOP
		++$skipped{one};
next;
}

$name{$name}++;
	foreach($collector, $other_coll){
		s/\([^)]+\)//g;
	s/([A-Z]\.[A-Z]\.)([A-Z][a-z])/$1 $2/g;
	s/([A-Z]\.) ([A-Z]\.)/$1$2/g;
s/l, L\./L./;
s/T, T\./T./;
s/c, Y\./Y./;
s/Greg de Nevers/Greg De Nevers/;
s/(Adrienne Russel)([^l])/$1l$2/;
s/(D\.R\. Schram)([n])/$1m/;
s/(D\.R\. Schram)([^m])/$1m$2/;
s/D\.L Banks/D. L. Banks/;
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
		s/, *, /, /g;
		s/ ,/,/g;
		s/  / /g;
		s/,$//;
	s/A.B. Magee/A. B. McGee/;
	s/L. MaCabe/L. McCabe/;
	s/De Vault/DeVault/;
	s/Peirrmann/Pfirrmann/;
	s/E.*P.*Cowpe$/E. P. Cowper/;
	s/Hazan$/Hazen/;
	s/Stilgenbaurer/Stilgenbauer/;
	s/Acevado$/Acevedo/;
s/anonymous/unknown/;
s/Annonymous/unknown/;
s/Unknown/unknown/;
	if($alter_coll{$_}){
				$_= $alter_coll{$_};
				}
	}
	foreach($other_coll){
s/\. ?\. ?\.//;
s/D. *Charlton, *B. *Pitzer, *J. *Kniffen, *R. *Kniffen, *W. *W. *Wright, *Howie *Weir, *D. *E. *Bramlet/D. Charlton, et al./;
s/Mark *Elvin, *Cathleen *Weigand, *M. *S. *Enright, *Michelle *Balk, *Nathan *Gale, *Anuja *Parikh, *K. *Rindlaub/Mark Elvin, et al./;
s/P. *Mackay/P. MacKay/;
s/P. *J. *Mackay/P. J. MacKay/;
s/.*Boyd.*Bramlet.*Kashiwase.*LaDoux.*Provance.*Sanders.*White/et al./;
s/.*Boyd.*Bramlet.*Kashiwase.*LaDoux.*Provance.*Sanders.*White/et al./;
s/.*Boyd.*Kashiwase.*LaDoux.*Provance.*Sanders.*White.*Bramlet/et al./;
s/.*Elvin.*Weigand.*Enright.*Balk.*Parikh.*Rindlaub.*/Mark A. Elvin, et al./;
s/M. Elvin.* Burrascano.* Pignoli.* Thompson.*/Mark A. Elvin, et al./;
}
$collector{$collector}++;
if(length($other_coll) > 2){
	$coll_comm= "$collector, $other_coll";
	foreach($coll_comm){
		s/, , /, /g;
		s/,, /, /g;
	if($alter_coll{$_}){
				$_= $alter_coll{$_};
				}
	}
				$combined_collectors=$coll_comm;

	$collector{$coll_comm}=$line_store;
	($assig=$coll_comm)=~s/,.*//;
	$collector{$assig}=$line_store;
}
if($low_range_m =~/\d/){
	if($top_range_m){
		$elevation="$low_range_m - $top_range_m m";
		if($low_range_m - $top_range_m > 0){
			print OUT <<EOP;
$Label_ID_no elevation range problem: LF: $low_range_m, TF: $top_range_m,
EOP
$elevation="";
		}
	}
	else{
		$elevation="$low_range_m m";
	}
}
elsif($low_range_f =~/\d/){
	if($top_range_f){
		$elevation="$low_range_f - $top_range_f f";
		if($low_range_f - $top_range_f > 0){
					print OUT <<EOP;
$Label_ID_no elevation range problem LF: $low_range_f, TF: $top_range_f, 
EOP
$elevation="";
		}
	}
	else{
		$elevation="$low_range_f f";
	}
}
elsif($top_range_m =~/\d/){
		$elevation="$top_range_m m";
}
elsif($top_range_f =~/\d/){
		$elevation="$top_range_f f";
}
else{
$elevation="";
}

if($ecol_notes=~s/[;.] +([Aa]ssoc.*)//){
$assoc=$1;
}


$long_minutes=~ s/['`]//g;
$long_minutes=~ s/^[^\d](\d\d)/$1/g;
$lat_minutes=~ s/['`]//g;
$lat_degrees=~ s/(\d\d)[^\d]/$1/g;
$long_degrees=~ s/(\d\d\d)[^\d]/$1/g;
if($long_minutes=~ s/(\d*)\.(\d)\d?/$1/){
	$long_minutes="00" if $long_minutes eq "";
$minute_decimal=$2;
$long_seconds= int(($minute_decimal * 60)/10);
}
if($lat_minutes=~ s/(\d*)\.(\d)\d?/$1/){
	$lat_minutes="00" if $lat_minutes eq "";
$minute_decimal=$2;
$lat_seconds= int(($minute_decimal * 60)/10);
}


($lat= "${lat_degrees} ${lat_minutes} ${lat_seconds}$N_or_S")=~s/ ([EWNS])/$1/;
($long= "${long_degrees} ${long_minutes} ${long_seconds}$E_or_W")=~s/ ([EWNS])/$1/;
$lat=~s/^ *([EWNS])//;
$long=~s/^ *([EWNS])//;
$lat=~s/^ *$//;
$long=~s/^ *$//;

if($long){
	unless ($long=~/^\d\d\d \d\d? \d\d?W/ || $long=~/^\d\d\d \d\d?W/ || $long=~/^\d\d\d \d\d? \d\d?\.\dW/){
		warn "$Label_ID_no: Longitude $long config problem\n";
		print OUT <<EOP;

Longitude $decimal_long config problem: $Label_ID_no, nulled
EOP
	$long="";$lat="";
	}
}
if($lat){
	unless ($lat=~/^\d\d \d\d? \d\d?N/ || $lat=~/^\d\d \d\d?N/ || $lat=~/^\d\d \d\d? \d\d?\.\dN/){
	warn "$Label_ID_no: Latitude $lat config problem\n";
		print OUT <<EOP;

Latitude $decimal_lat config problem: $Label_ID_no, nulled
EOP
	$long="";$lat="";
	}
}
if($decimal_lat){
	unless ($decimal_lat=~/^\d+[.0-9]*$/){
		warn "$Label_ID_no: Decimal latitude $decimal_lat config problem\n";
		print OUT <<EOP;

Decimal latitude $decimal_lat config problem: $Label_ID_no, nulled
EOP
		$decimal_long="";
		$decimal_lat="";
	}
}
if($decimal_long=~/[^ ]/){
	unless ($decimal_long=~/^-\d\d\d[.0-9]*$/){
		warn "$Label_ID_no: Decimal longitude $decimal_long config problem\n";
	print OUT <<EOP;

Decimal longitude $decimal_long config problem: $Label_ID_no, nulled
EOP
		$decimal_long="";
		$decimal_lat="";
}
}
$Unified_TRS="$township$range$section";
$country="USA" if $country=~/U\.?S\.?/;
#IRVC35 50163	R. H. Whittaker, W. A. Niering	SJ	6		2438177	2438177	May 27 1963	Riverside	1250 - 1265 m	  Hemet Hwy, between Hemet and Mtn Center. Peninsular Ranges, San Jacinto Mountains							
if($store{$Label_ID_no}){
@CDL_fields=split(/\t/,$f_contents{$Label_ID_no}, 100);
print TABFILE <<EOP;
Raw
$raw_list

New
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
Combined_collector: $combined_collectors
Habitat: $vegetation
Associated_species: $assoc
Notes: $ecol_notes
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Datum: $datum

from CCH
$store{$Label_ID_no}
==================================================================

EOP
++$included;
}
}
foreach(sort(keys(%collector))){
#print "$_\n" if $coll_comm{$_};
	$key=$_;
s/\./. /g;
s/  / /g;
s/ *$//;
next if $coll_comm{$_};
print "$_$collector{$key}\n";
}

foreach(sort(keys(%name))){
	print "$_ $name{$_}\n" unless $taxon{$_};
}

print <<EOP;
INCL: $included
EXCL: $skipped{one};
EOP
