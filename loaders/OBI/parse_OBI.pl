open(IN,"/Users/richardmoe/4_data/taxon_ids/smasch_taxon_ids.txt") || die;
while(<IN>){
	chomp;
($code,$name,@rest)=split(/\t/);
	$taxon{$name}++;
}
open(IN,"../CDL/alter_names") || die;
while(<IN>){
	chomp;
s/\cJ//;
s/\cM//;
	next if m/^#/;
	next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	$alter{$rsa}=$smasch;
}
open(OUT, ">OBI.out") || die;
open(ERR, ">OBI_err") || die;

open(IN, "Sorted_OBIDATA_27A_June_2013.csv") || die;
@lines=(<IN>);
foreach(@lines){
($aid=$_)=~s/\t.*\n//;
$seen{$aid}++;
}
foreach(@lines){
(@fields)=split(/\t/,$_,100);
grep(s/^"(.*)"/$1/,@fields);
unless( $#fields==33){
print ERR "$#fields Fields not 33 $_\n";
next;
}
($Accession_number,
$Date_entered,
$Search_no,
$Status,
$Collector,
$Collection_no,
$additional_collectors,
$TJM2_Family,
$TJM2_binomial,
$Binomial_on_label,
$author_of_binomial,
$infraspecific_rank,
$infraspecific_epithet,
$infraspecific_epithet,
$Annotation,
$Date_B,
$Country,
$State,
$County,
$Collection_locality,
$General_habitat,
$Specific_habitat_abundance,
$Plant_description,
$elev_ft,
$elev_m,
$Notes,
$X_Long,
$Y_Lat,
$X_LongMin,
$X_LongMax,
$Y_LatMin,
$Y_LatMax,
$Datum)=@fields;
if($Country=~/^(MX|Mexico|Peru|LESOTHO|South Africa)$/i){
print ERR "Skipped: country $Country not USA $_\n";
next;
}
if($State=~/(AK|AZ|Alaska|Arizona|Az|Baja|Baja_Calif_Sur|Baja_California|CO|Chihuahua|Colorado|Free_State_Province|Guam|Guerro|Hawaii|IL|Idaho|Illinois|Kwazulu-natal_Province|Michoacan|Missouri|Montana|Morelos|Mpumalanga_Province|NE|NM|NV|Nevada|New_Mexico|Northwest_Province|Nuevo_Leon|OR|Oaxaca|Oregon|Puebla|SD|Sinaloa|Sonora|State|Tamaulipas|UT|Utah|WA|WY|Washington|Wisconsin|Wyoming)$/){
print ERR "Skipped: State $State not CA $_\n";
next;
}
#print "$Date_A $Date_B\n";
if($X_Long || $Y_Lat){
$X_Long=~s/[^0-9.]//g;
$Y_Lat=~s/[^0-9.]//g;
if($X_Long<50 && $X_Long > 35){
$decimal_lat = $X_Long;
}
if($Y_Lat > 115 && $Y_Lat < 135){
$decimal_long="-$Y_Lat";
}
else{
$decimal_long="-$X_Long";
$decimal_lat = $Y_Lat;
}
#print <<EOP;
#$decimal_lat
#$decimal_long
#$Datum
#
#EOP
}
else{
$decimal_long="";
$decimal_lat = "";
}
#next;

unless($Binomial_on_label eq $TJM2_binomial){
	if($Annotation){
		$Annotation .= "; $Binomial_on_label, label,";
	}
	else{
		$Annotation = "$Binomial_on_label, label," if $Binomial_on_label;
	}
}
#print "$Binomial_on_label -> $TJM2_binomial -> $Annotation\n";
$Annotation=~s/; /\nAnnotation: /g;
$Annotation=~s/, */; /g;

unless ($Accession_number=~/^\d+$/){
print ERR "Skipped: Accession number $Accession_number is uncertain -> $_\n";
next;
}
if ($seen{$Accession_number}>1){
print ERR "Skipped: Accession number $Accession_number is duplicated ($seen{$Accession_number})\n";
next;
}
$Accession_number="OBI$Accession_number";
$name=$TJM2_binomial;
foreach($name){
s/^ *//;
s/ *$//;
s/  */ /g;
}
if($name=~/^ *$/){
$name=$Binomial_on_label;
foreach($name){
s/^ *//;
s/ *$//;
s/  */ /g;
}
}
foreach($name){
	if(m/ (cf|aff)\./){
		if($Notes){
			$Notes .= "; as $_";
		}
		else{
			$Notes .= "as $_";
		}
		s/ (cf|aff)\.//;
print ERR "Logging: $TJM2_binomial altered to $_\n";
	}
s/ ssp.? / subsp. /;
s/ su[sb]p.? / subsp. /;
s/ su[nb]sp\.? / subsp. /;
s/ var / var. /;
s/ x / X /;
s/ sp\.?$//;
}
			if($name=~/([A-Z][a-z-]+ [a-z-]+) X /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/([A-Z][a-z-]+ [a-z-]+ (var\.|subsp\.) [a-z-]+) X /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			else{
				$hybrid_annotation="";
			}
if($alter{$name}){
$name=$alter{$name};
print ERR "Logging: $TJM2_binomial altered to $name\n";
}
if($name=~/^ *$/){
print ERR "Skipped: $Accession_number no name\n";
next;
}




unless($taxon{$name}){
                if($name=~s/subsp\./var./){
                        if($taxon{$name}){
                                print ERR <<EOP;
Logging: $TJM2_binomial not yet entered into SMASCH taxon name table: entered as $name
EOP
                        }
        }
        elsif($name=~s/var\./subsp./){
                if($taxon{$name}){
                        print TAXON_OUT <<EOP;
Logging: $TJM2_binomial not yet entered into SMASCH taxon name table: entered as $name
EOP
                }
}
}









unless($taxon{$name}){
print ERR "Skipped: $TJM2_binomial not in SMASCH\n";
$NIS{$TJM2_binomial}++;
next;
}
foreach($County){
s/^ *//;
s/ *$//;
s/  */ /g;
s/-.*//;
s/ Co\.//;
s/ County//;
$o_county=$_;
s/Solana/Solano/;
s/Del Monte/Del Norte/;
s/Alemeda/Alameda/;
s/Calavaras/Calaveras/;
s/Conta Costa/Contra Costa/;
s/Eldorado/El Dorado/;
s/Fresno to Monterey/Fresno/;
s/Fresno-Inyo/Fresno/;
s/Humbloldt/Humboldt/;
s/Imperial.+/Imperial/;
s/Inyo.+/Inyo/;
s/Inyo\?/Inyo/;
s/Kern.*/Kern/;
s/Los Angeles.+/Los Angeles/;
s/Los angeles/Los Angeles/;
s/Mono.*/Mono/;
s/Montery/Monterey/;
s/Not Given/Unknown/;
s/Not given/Unknown/;
s/Orange.*/Orange/;
s/Placer.*/Placer/;
s/Riverside.*/Riverside/;
s/San Bernadino/San Bernardino/;
s/San Clara/Santa Clara/;
s/San Deigo/San Diego/;
s/San Diego.*/San Diego/;
s/Santa Mateo/San Mateo/;
s/^Mateo/San Mateo/;
s/Sierra-Plumas/Sierra/;
s/Trinuty/Trinity/;
s/Tulare .*/Tulare/;
s/Ventura.*/Ventura/;
s/^Benito/San Benito/;
s/Humbolt/Humboldt/;
s|Colusa/Lake|Colusa|;
s/^ *$/Unknown/;
s/^[Uu][nN][Kk]$/Unknown/;
s/Sikiyou/Siskiyou/;
s/^\?$/Unknown/;
s/SL:O/San Luis Obispo/;
s/^SLO$/San Luis Obispo/i;
s/^SB$/Santa Barbara/i;
s/Humbodt/Humboldt/;
s/Fresno line/Fresno/;
unless ($_ eq $o_county){
print ERR "Logging: $o_county altered to $_\n";
}
}
unless ($County=~m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|[Uu]nknown)$/){
#warn "Not a CA county: >$County<\n";
		print ERR <<EOP;
Skipped: Not a CA county, $County $Accession_no
EOP
next;
}
#($Accession_number, $Date_entered, $Search_no, $Status, $Collector, $Collection_no, $additional_collectors, $TJM2_Family, $TJM2_binomial, $Binomial_on_label, $author_of_binomial, $infraspecific_rank, $infraspecific_epithet, $infraspecific_epithet, $Annotation, $Date_A, $Date_B, $Country, $State, $County, $Collection_locality, $General_habitat, $Specific_habitat_abundance, $Plant_description, $elev_ft, $elev_m, $Notes, $X_Long, $Y_Lat, $X_LongMin, $X_LongMax, $Y_LatMin, $Y_LatMax, $Datum)=@fields;
#print "$County $State\n";

if($elev_ft=~/\d/){
$elevation=$elev_ft;
$elevation=~s/ *$//;
$elevation=~s/^ *//;
$elevation=~s/fe*t\.?//;
$elevation .= " ft";
}
elsif($elev_m=~/\d/){
$elevation=$elev_m;
$elevation=~s/ *$//;
$elevation=~s/^ *//;
$elevation=~s/ ?m\.?//;
$elevation .= " m";
}
else{
$elevation="";
}
$Collection_no=~s/^[" ]+(.*)[ "]+$/$1/;
if($Collection_no=~/^\d+$/){
$CNP=""; $CNS="";
}
elsif($Collection_no=~/s\.? ?n\.?/){
$Collection_no=""; $CNP=""; $CNS="";
}
elsif( $Collection_no=~/^(\d+[^\d])(\d+)$/){
$Collection_no="$2"; $CNP="$1"; $CNS="";
}
elsif( $Collection_no=~/^(\d+)([^\d]+)$/){
$Collection_no="$1"; $CNP=""; $CNS="$2";
}
elsif( $Collection_no=~/^([^\d]+)(\d+)$/){
$Collection_no="$2"; $CNP="$1"; $CNS="";
}
elsif( $Collection_no=~/^([^\d]+)(\d+)([^\d].*)$/){
$Collection_no="$2"; $CNP="$1"; $CNS="$3";
}
else{
$Collection_no=""; $CNP=""; $CNS="$Collection_no";
}

if($General_habitat){
$General_habitat .= "; $Specific_habitat_abundance" if $Specific_habitat_abundance;
}
else{
$General_habitat = "$Specific_habitat_abundance" if $Specific_habitat_abundance;
}
$Datum=~s/, (.*)/\nSource: $1/;

print OUT <<EOP;
Date: $Date_B
CNUM_prefix: $CNP
CNUM: $Collection_no
CNUM_suffix: $CNS
Name: $name
Accession_id: $Accession_number
County: $County
Loc_other: $Physiographic_region
Location: $Collection_locality
T/R/Section: $Unified_TRS
USGS_Quadrangle: $topo_quad
Elevation: $elevation
Collector: $Collector
Other_coll: $additional_collectors
Habitat: $General_habitat
Notes: $Notes
Macromorphology: $Plant_description
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Datum: $Datum
Annotation: $Annotation
Hybrid_annotation: $hybrid_annotation
Type_status: $Kind_of_type

EOP

foreach $i (0 .. $#fields){
#print "$i   $fields[$i]\n";
}
}
open(OUT, ">NIS") || die;
foreach(sort {$NIS{$a}<=> $NIS{$b}}(keys(%NIS))){
print OUT "$NIS{$_} $_\t$_\n";
}

