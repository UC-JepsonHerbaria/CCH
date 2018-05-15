use utf8;
BEGIN{
push(@INC,"/Users/jfp04/data/CDL");
}
use Smasch;
open(OUT, ">CDA_out") || die;
open(IN,"CAS_non_vasc") || warn "no non vasc file\n";
while(<IN>){
	chomp;
	$ignore_name{$_}++;
}
foreach(sort(keys(%ignore_name))){
print " ignore $_\n";
}
open(IN,"CAS_alter_coll") || warn "no alternative collector file\n";
while(<IN>){
	chomp;
	s/\cJ//;
	s/\cM//;
	next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	$alter_coll{$rsa}=$smasch;
}
open(IN,"../CDL/alter_names") || warn "no alternative name file\n";
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(IN,"alter_CDA") || warn "no alternative name file\n";
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
#open(IN,"../CDL/tnoan.out") || die;
#while(<IN>){
#74515	Centaurea × pouzinii
#warn "×  TNOAN $_\n" if m/pouzin/;
	#chomp;
	#($id,$name)=split(/\t/);
	#$taxon{$name}=$id;
#}
&load_noauth_name();
foreach(keys(%PARENT)){
print "$_\n" if m/pouzin/;
}
%taxon=%PARENT;
foreach(keys(%taxon)){
warn "×  HASH $_\n" if m/pouzin/;
}
open(ERR,">CDA_error");
while(<>){
s/\cB//g;
s/Â±/+\/-/g;
s/Ã/--/g;
s/Ã/~/g;
s/â/&ntilde;/g;
s/Ã/--/g;
	s/&apos;/'/g;
	#print if m/pouzin/;
	chomp;
	@fields=split(/\t/,$_,100);
#unless ($#fields>25){
#print "\n$#fields\n";
#foreach $i (0 .. $#fields){
#print "$i $fields[$i]\n";
#}
#}
#next;
	grep(s/^"(.*)"$/$1/,@fields);
#warn "FIELDS $#fields $_\n" unless $#fields==27;
#cda_num	col_num	genus	spec_epith	rank	intra	datac	datac2	county	elev	elev_unit	lat_degn	lat_minn	lat_secn	lon_degn	lon_minn	lon_secn	twnshp	range	sec	bm	month	day	year	collector	quad	quad_scale	collect2	subhead	det_by
	$other_coll=$name=$accession_id= $collector= $combined_collector= $CNUM =$loc_other= $location= $county= $genus= $species= $i_rank= $variety= $latitude= $longitude= $elevation= $elev_u= $month= $day= $year= $township= $range= $section= $T_R_Section="";
#$township, 
#$range,
($accession_id,
$CNUM,
$genus,
$species,
$i_rank, 
$variety,
$datac,
$datac2,
$county, 
$elevation,
$elev_u,
$lat_degn,
$lat_minn, 
$lat_secn,
$lat_hem,
$lon_degn,
$lon_minn,
$lon_secn,
$lon_hem,
$month,
$day,
$year,
$collector,
$quad,
$quad_scale,
$combined_collector,
$loc_other, 
$det_by)=@fields;
	if($combined_collector){
		$combined_collector="$collector, $combined_collector";
		$other_coll=$combined_collector;
	}
	else{
		$combined_collector="";
	}
$PREFIX= $SUFFIX="";
foreach($CNUM){
	s/(\d),(\d\d\d)$/$1$2/;
	if(s| *1/2||){
		$SUFFIX="1/2";
	}
	if(m/^(\d+)(.*)/){
		$PREFIX="";
		$CNUM=$1;
		$SUFFIX=$2;
	}
	elsif(m/(.*[^0-9])(\d+)(.*)/){
		$PREFIX=$1;
		$CNUM=$2;
		$SUFFIX=$3;
	}
	else{
		$PREFIX=$_;
		$CNUM="";
		$SUFFIX="";
	}
}
	$loc_other=~s/.*(weeds|flora|plants) of the //i;
	$loc_other=~s/.*(weeds|flora|plants) of //i;
$location=$datac;
if($datac2){
$location .=  " $datac2";
}
$county=uc($county);
$county=~s/ELDORADO/EL DORADO/;
$county=~s/^ *$/UNKNOWN/;
$county=~s/ \/.*//;
unless($county=~m/^(SHASTA|LOS ANGELES|SAN DIEGO|BUTTE|INYO|TRINITY|PLUMAS|SONOMA|NAPA|SOLANO|MENDOCINO|SANTA BARBARA|SAN LUIS OBISPO|LASSEN|YOLO|GLENN|SACRAMENTO|PLACER|SIERRA|TULARE|MONO|MERCED|MONTEREY|SAN BERNARDINO|COLUSA|MODOC|AMADOR|SUTTER|LAKE|TEHAMA|NEVADA|SISKIYOU|EL DORADO|HUMBOLDT|TUOLUMNE|CALAVERAS|KERN|CONTRA COSTA|SAN JOAQUIN|ALAMEDA|FRESNO|SAN BENITO|SANTA CRUZ|ALPINE|SANTA CLARA|MARIN|YUBA|SAN MATEO|MADERA|DEL NORTE|IMPERIAL|RIVERSIDE|VENTURA|MARIPOSA|STANISLAUS|ORANGE|KINGS|SAN FRANCISCO|UNKNOWN)$/){
print ERR "County $county not California $accession_id\n";
next;
}
$county=ucfirst(lc($county));
$county=~s/ (.)/ \u$1/g;

$name="$genus $species $i_rank $variety";
$name=~s/ *`//g;
$name=~s/ *$//;


		$name="" if $name=~/^No name$/i;
			unless($name){
				&skip("No name: $accession_id", @columns);
				next;
			}
			($genus=$name)=~s/ .*//;
			if($ignore_name{$genus}){
				&skip("Non-vascular plant: $accession_id", @columns);
				next;
			}
			$name=ucfirst($name);
			if($name=~/  /){
				if($name=~/^[A-Z][a-z]+ [a-z]+ +[a-z]+$/){
					&log("$name: var. added $accession_id");
					$name=~s/^([A-Z][a-z]+ [a-z]+) +([a-z]+)$/$1 var. $2/;
				}
				$name=~s/  */ /g;
			}
			if($name=~/CV\.? /i){
				&skip("Can't deal with cultivars yet: $accession_id", $name);
				#$badname{$name}++;
				next;
			}
			foreach($name){
$original_name=$name;
warn "$_\n" if m/pouzin/;
				s/ ssp / subsp. /;
				s/ spp\.? / subsp. /;
				s/ var / var. /;
				s/ ssp\. / subsp. /;
				s/ f / f\. /;
				s/ [xX] / × /;
				#s/ [xX] / × /;
warn "$_\n" if m/pouzin/;
if(s/ (cf\.|aff\.)//){
$note="as $original_name";
}
else{
$note="";
}
			}
			if($name=~/([A-Z][a-z-]+ [a-z-]+) × /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			else{
				$hybrid_annotation="";
			}

			if($alter{$name}){
				&log ("Spelling altered to $alter{$name}: $name");
				$name=$alter{$name};
			}
			unless($taxon{$name}){
				$on=$name;
				if($name=~s/subsp\./var./){
					if($taxon{$name}){
						&log("Not yet entered into SMASCH taxon name table: $on entered as $name");
					}
					else{
						&skip("Not yet entered into SMASCH taxon name table: $original_name skipped");
						++$badname{$name};
						next;
					}
				}
				elsif($name=~s/var\./subsp./){
		if($taxon{$name}){
&log("Not yet entered into SMASCH taxon name table: $on entered as $name");
		}
		else{
&skip("Not yet entered into SMASCH taxon name table: $original_name skipped");
++$badname{$name};
next;
		}
	}
	else{
&skip("Not yet entered into SMASCH taxon name table: $original_name skipped");
++$badname{$name};
	next;
	}
}





if($lat_degn){
	$latitude=$lat_degn;
	if($lat_minn){
		$latitude.=" $lat_minn";
		if($lat_secn){
			$latitude.=" $lat_secn";
		}
	}
	$latitude .="N";
}
$latitude=~s/ (\d) / 0$1 /;
$latitude=~s/ (\dN)/ 0$1/;
$latitude="" if $latitude=~/^0+ /;

if($lon_degn){
	$longitude=$lon_degn;
	if($lon_minn){
		$longitude.=" $lon_minn";
		if($lon_secn){
			$longitude.=" $lon_secn";
		}
	}
	$longitude .="W";
}

$longitude=~s/ (\d) / 0$1 /;
$longitude=~s/ (\dW)/ 0$1/;
$longitude="" if $longitude=~/^0+ /;

if($latitude=~/^1\d\d/){
$hold=$latitude;
$latitude=$longitude;
$longitude=$hold;
$longitude=~s/N/W/;
$latitude=~s/W/N/;
&log("$accession_id: lat and long reversed");
}
#if(($decimal_latitude=~/\d/  && $decimal_longitude=~/\d/)){
    #$decimal_longitude="-$decimal_longitude" if $decimal_longitude > 0;
	    #if($decimal_latitude > 42.1 || $decimal_latitude < 32.5 || $decimal_longitude > -114 || $decimal_longitude < -124.5){
		        #&log( "1 coordinates set to null, Outside California: $accession_id: >$decimal_latitude< >$decimal_longitude< $latitude $longitude");
				#}
#}
if($latitude && $longitude){
	unless($latitude=~/[nN]/ && $longitude=~/[Ww]/){
	&log ("2 direction missing: $accession_id: >$decimal_latitude< >$decimal_longitude< $latitude $longitude");
	$latitude=$longitude="";
		}
		unless(&verify_cal_lat($latitude) && &verify_cal_long($longitude)){
		&log("3 coordinates set to null, Outside California: $accession_id: >$decimal_latitude< >$decimal_longitude< $latitude $longitude ");
		warn "3 coordinates set to null, Outside California: $accession_id: >$decimal_latitude< >$decimal_longitude< $latitude $longitude ";
	$latitude=$longitude="";
		}
		}
		#else{
		#print "4 coordinates set to null, coordinate missing: $accession_id: >$decimal_latitude< >$decimal_longitude< $latitude $longitude\n";
#}




$elevation="$elevation $elev_u" if $elevation;;
$month="" if $month=~/^0*$/;
$day="" if $day=~/^0*$/;
$year="" if $year=~/^0*$/;
$date="$month $day $year";
$T_R_Section="$township$range$section";
$T_R_Section="" if $T_R_Section eq "0";
if($det_by=~m|^(.+)|){
$annotation="$name; $1"
}
else{
$annotation="";
}

print OUT <<EOP;
Date: $date
CNUM: $CNUM
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Accession_id: $accession_id
Name: $name
Collector: $collector
Combined_collector: $combined_collector
Other_coll: $other_coll
Loc_other: $loc_other
Location: $location
Country: USA
State: California
County: $county
Latitude: $latitude
Longitude: $longitude
Elevation: $elevation
T/R/Section: $T_R_Section
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation
Note: $note

EOP
}
sub skip {
print ERR "skipping: @_\n"
}
sub log {
print ERR "logging: @_\n";
}
__END__
