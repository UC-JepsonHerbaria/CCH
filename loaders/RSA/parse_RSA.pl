use lib '/Users/richardmoe/4_DATA/CDL';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
&load_noauth_name;

$m_to_f="3.2808";
		use Geo::Coordinates::UTM;

open(ERR,">RSA_problems") || die;

print ERR <<EOP;
$today
Report from running parse_riverside.pl
Name alterations from file ~/data/CDL/alter_names
Name comparisons made against ~/taxon_ids/smasch_taxon_ids (SMASCH taxon names, which are not necessarily correct)
Genera to be excluded from riv_non_vasc

EOP

#die "See what must be done about types\n";

open(IN, "all_rsa_types") || die;
while(<IN>){
	chomp;
	($ID,$kind)=split(/: */);
	$TYPE{$ID}=$kind;
}

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

open(IN,"../CDL/riv_non_vasc") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}
open(IN,"/Users/richardmoe/4_CDL_BUFFER/smasch/mosses") || die;
while(<IN>){
	chomp;
	s/\s.*//;
	$exclude{$_}++;
}






open(IN,"../CDL/alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
















open(TABFILE,">new_parse_rsa.out") || die;
#open(OUT,">rsa_problems") || die;
open(COORDS,">rsa_coord_issues") || die;
$date=localtime();

#open(IN,"clinkers" ) || die;
#open(IN,"UCRData122009.tab" ) || die;
#open(IN,"rsa_sept.txt") || die;

$current_file="RSA_Data";

open(IN,"$current_file") || die;
warn "reading from $current_file\n";

while(<IN>){
	chomp;
	s/\t.*//;
	if($seen_dup{$_}++){
		++$duplicate{$_};
	}
}
close(IN);

open(IN,"$current_file") || die;
#open(IN,"test_ac.tmp") || die;
Record: while(<IN>){
$assoc=$combined_collectors=$Collector_full_name= $elevation= $name=$lat=$long=$decimal_lat=$decimal_long="";
		$zone=$easting=$northing="";
#next unless m/Annette Winn/;
if (m/^Deacc/i){
		++$skipped{one};
				&log("DEACC $_");
next Record;
}
if (m/^unaccess/i){
		++$skipped{one};
				&log("UNACC $_");
next Record;
}
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
	($poss_dup=$_)=~s/\t.*//;
	unless($poss_dup=~/^(RSA|POM)/){
		++$skipped{one};
		print ERR<<EOP;

Not RSA or POM, skipped: $_
EOP
		next Record;
	}
	if($duplicate{$poss_dup}){
		++$skipped{one};
		print ERR<<EOP;

Duplicate number, skipped: $_
EOP
		next Record;
	}
	@fields=split(/\t/);
	if($fields[0]=~/^ *$/){
		++$skipped{one};
		print ERR<<EOP;

No accession number, skipped: $_
EOP
		next Record;
	}
	if($fields[0]=~/^(Un|de)accessioned/i){
		++$skipped{one};
		print ERR<<EOP;

De/Un accessioned accession number, skipped: $_
EOP
		next Record;
	}
	$fields[10]= ucfirst( $fields[10]);
	if($fields[10]=~/Undet/){
		++$skipped{one};
		print ERR<<EOP;

No generic name, skipped: $_
EOP
		next Record;
	}
	if(length($fields[10]) < 3){
		++$skipped{one};
		print ERR<<EOP;

No generic name, skipped: $_
EOP
		next Record;
	}
	if($seen{$fields[0]}++){
		++$skipped{one};
		warn "Duplicate number: $fields[0]<\n";
		print ERR<<EOP;

Duplicate accession number, skipped: $fields[0]
EOP
		next Record;
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
unless($fields[30]=~/^(CA|Ca|Calif\.|California)$/ && $fields[29]=~/^(US|U\.S\.|United States)$/){
		print ERR<<EOP;
		State not California $fields[0]: $_ skipped
EOP
		next Record;
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
$Plant_description,
$plant,
$phenology,
$culture,
$origin,
) = @fields;
$coord_string="D=$lat_degrees, M= $lat_minutes, S= $lat_seconds, H= $N_or_S, DLT= $decimal_lat, D= $long_degrees, M= $long_minutes, S= $long_seconds, H= $E_or_W, DLG= $decimal_long";

$year=~s/\.\.\.?/-/g;
$month=~s/\.\.\.?/-/g;
$day=~s/\.\.\.?/-/g;

#print "$UTM_E, $UTM_N $UTM_grid_zone, $UTM_grid_cell, $name_of_UTM_cell\n" if $UTM_E;
#next;
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
$name=~s/ spp\./ subsp./;
$name=~s/ssp\./subsp./;
$name=~s/ ssp / subsp. /;
$name=~s/ subsp / subsp. /;
$name=~s/ var / var. /;
$name=~s/ var. $//;
$name=~s/ sp\..*//;
$name=~s/ sp .*//;
$name=~s/ [Uu]ndet.*//;
$name=~s/ x / X /;
$name=~s/ × / X /;
$name=~s/ *$//;
#print "TEST $name<\n";

if($name=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
                 $hybrid_annotation=$name;
                 warn "$1 from $name\n";
                 &log("$1 from $name");
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

if($alter{$name}){
        &log("$name altered to $alter{$name}");
                $name=$alter{$name};
}
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
        	&log ("$name is not yet in the master list: skipped");
$needed_name{$name}++;
		++$skipped{one};
		next Record;
	}
}
else{
        &log ("$name is not yet in the master list: skipped");
$needed_name{$name}++;
	++$skipped{one};
	next Record;
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
		s/([A-Z]) ([A-Z]) ([A-Z][a-z])/$1. $2. $3/g;
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
			$elev_test=$elev_test * $m_to_f;
			$elev_test= " feet";
		}
		else{
			$metric="";
		}
		if($elev_test=~s/ +(ft|feet)//i){

			if($elev_test > $max_elev{$fields[31]}){
				print ERR "ELEV fields[31]\t ELEV: $elevation $metric greater than max: $max_elev{$fields[31]} discrepancy=", $elev_test-$max_elev{$fields[31]}," $Label_ID_no\n";
			}
		}

if($ecol_notes=~s/[;.] +([Aa]ssoc.*)//){
$assoc=$1;
}

#####
#Sat Nov 19 09:36:57 PST 2011
if($lat_degrees=~/^[ -]*\d+ *$/ || $long_degrees=~/^[- ]*\d+ *$/){
	$decimal_lat="";
	$decimal_long="";
}
#####



#elsif($lat_degrees=~/(\d+\.\d+)/){
if($lat_degrees=~/(\d+\.\d+)/){
	$decimal_lat=$1;
	if($long_degrees=~/([0-9.]+)/){
		$decimal_long=$1;
	}
	else{
		print COORDS "config problem (1); lat and long nulled:  $coord_string $Label_ID_no\n";
	$lat=$long=$decimal_lat=$decimal_long="";
	}
$long_minutes= $lat_minutes= $lat_degrees= $long_degrees=$long_minutes=$long_seconds="";
}
elsif($long_degrees=~/(\d+\.\d+)/){
	$decimal_long="-$1";
	if($lat_degrees=~/([0-9.]+)/){
		$decimal_lat=$1;
	}
	else{
		print COORDS "config problem (2); lat and long nulled:  $coord_string $Label_ID_no\n";
	$lat=$long=$decimal_long=$decimal_lat="";
	}
$long_minutes= $lat_minutes= $lat_degrees= $long_degrees=$long_minutes=$long_seconds="";
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
$lat_seconds=~ s/^\.(\d)/00.$1/;
$long_seconds=~ s/^\.(\d)/00.$1/;
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

$N_or_S="N" if $lat_degrees=~/\d/;
$E_or_W="W" if $long_degrees=~/\d/;
($lat= "${lat_degrees} ${lat_minutes} ${lat_seconds}$N_or_S")=~s/ ([EWNS])/$1/;
($long= "${long_degrees} ${long_minutes} ${long_seconds}$E_or_W")=~s/ ([EWNS])/$1/;
$lat=~s/^ *([EWNS])//;
$long=~s/^ *([EWNS])//;
$lat=~s/^ *//;
$long=~s/^ *//;
}

if($long=~/\d/){
unless ($long=~/\d\d\d \d\d? \d\d?W/ || $long=~/\d\d\d \d\d?W/ || $long=~/\d\d\d \d\d? \d\d?\.\dW/){
print COORDS "config problem (3); lat and long nulled:  $coord_string $Label_ID_no\n";
#warn "$Label_ID_no: config problem (3); lat and long nulled:  $coord_string\n";
$long="";
$lat="";
}
unless($lat =~ /\d/){
if($long){
	$long="";
		print COORDS <<EOP;
config problem (6); lat and long nulled:  $coord_string $Label_ID_no
EOP
}
}
}
if($lat=~/\d/){
unless ($lat=~/\d\d \d\d? \d\d?N/ || $lat=~/\d\d \d\d?N/ || $lat=~/\d\d \d\d? \d\d?\.\dN/){
print COORDS "$Label_ID_no: Latitude config problem (7); lat and long nulled:  $coord_string\n";
$lat="";
$long="";
}
unless($long=~/\d/){
	$lat="";
		print COORDS<<EOP;
$Label_ID_no: config problem (8); lat and long nulled:  $coord_string
EOP
}
}
$year=~s/ ?\?$//;
$year=~s/^['`]+//;
$year=~s/['`]+$//;
unless($year=~/^(1[789]\d\d|20\d\d)$/){
		print ERR<<EOP;
Date config problem $year $month $day: date nulled 9 $Label_ID_no
EOP
	$year=$month=$day="";
}
unless($day=~/(^[0-3]?[0-9]$)|(^[0-3]?[0-9]-[0-3]?[0-9]$)|(^$)/){
		print ERR<<EOP;
Date config problem $year $month $day: date nulled 10 $Label_ID_no
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
$decimal_lat=~s/^-//;
unless(($decimal_lat || $decimal_long)){
	if($zone){
		$easting=$UTM_E;
		$northing=$UTM_N;
		$easting=~s/[^0-9]*$//;
		$northing=~s/[^0-9]*$//;
		#warn "$fields[0] $zone $easting $northing\n";
		$zone="11S" if $zone==11;
		$zone="11S" if $zone eq "Z11";
		$zone="11S" if $zone eq "S11";
		$zone="10S" if $zone==10;
		$ellipsoid=23;
		if($zone=~/9|10|11|12/ && $easting=~/^\d\d\d\d\d\d/ && $northing=~/^\d\d\d\d\d/){
			($decimal_lat,$decimal_long)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
			print COORDS "$Label_ID_no decimal derived from UTM $decimal_lat, $decimal_long\n";
		}
		else{
			print COORDS "$Label_ID_no UTM problem $zone $easting $northing\n";
		}


		$decimal_long="-$decimal_long" if $decimal_long > 0;
	}  
}
	if($decimal_lat){
		if ($decimal_long > 0){
			print ERR "$decimal_long made -$decimal_long $Label_ID_no\n";
		$decimal_long="-$decimal_long";
		}
	if($decimal_lat > 42.1 || $decimal_lat < 32.5 || $decimal_long > -114 || $decimal_long < -124.5){
		if($zone){
			print COORDS "$Label_ID_no coordinates set to null, Outside California: $accession_id: UTM is $zone $easting $northing --> $decimal_lat $decimal_long\n";
		}
		else{
			print COORDS "$Label_ID_no coordinates set to null, Outside California: D_lat is $decimal_lat D_long is $decimal_long lat is $lat long is $long\n";
		}
	$decimal_lat =$decimal_long="";
}   
}


if($TYPE{$Label_ID_no}){
$Type_status= $TYPE{$Label_ID_no};
}
else{
$Type_status= "";
}

	$decimal_lat =~s/[^0-9]*$//;
	$decimal_long =~s/[^0-9]*$//;

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
Notes: $Plant_description $plant $culture $origin
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation
Reproductive_biology: $phenology
Type_status: $Type_status

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
open(ERR,">new_names_needed") || die;
foreach(sort {$needed_name{$a} <=> $needed_name{$b}}(keys(%needed_name))){
print ERR "$_ $needed_name{$_}\n";
}
open(ERR,">ucr_field_check") || die;
foreach(sort(keys(%Plant_description))){
	print ERR "PD: $_\n";
}
foreach(sort(keys(%plant))){
	print ERR "P: $_\n";
}
foreach(sort(keys(%phenology))){
	print ERR "Phen: $_\n";
}
foreach(sort(keys(%culture))){
	print ERR "C: $_\n";
}
foreach(sort(keys(%origin))){
	print ERR "O: $_\n";
}
sub log {
print ERR "@_\n";
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
