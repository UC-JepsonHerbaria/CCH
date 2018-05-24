$m_to_f="3.2808";
while(<DATA>){
@fields=split(/\t/);
$fields[3]=~s/\+//;
$fields[3]=~s/,//;
$max_elev{$fields[1]}=$fields[3];
}
#open(IN,"davis_alter_coll") || die;
#while(<IN>){
	#chomp;
#s/\cJ//;
#s/\cM//;
	#next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	#$alter_coll{$rsa}=$smasch;
#}
#open(IN,"../collectors_id") || die;
#open(IN,"../all_collectors_2005") || die;
#while(<IN>){
	#chomp;
#s/\t.*//;
	#$coll_comm{$_}++;
#}
open(IN,"/users/jfp04/CDL_buffer/buffer/tnoan.out") || die;
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
open(IN,"davis_alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(IN,"davis_exclude") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}
#open(IN,"alter_davis") || die;
#@alters=<IN>;
#chomp(@alters);
#foreach $i (0 .. $#alters){
	#unless($i % 2){
		#if($alters[$i]=~s/ :.*//){
			#$alter{$alters[$i]}=$alters[$i+1];
		#}
		#else{
			#die "misconfig: $i $alters[$i]";
		#}
	#}
#}
use Geo::Coordinates::UTM;
$/="<UCConsortium>";
open(ERROR, ">Davis_problems") || die;
open(OUT, ">parse_davis.out") || die;
open(IN,"UCConsortium.xml") || die;
#open(IN,"2009/UCConsortiumXML/UCConsortium.xml") || die;

warn "processing XML\n";
# 73 </Locality
# 44679 </UCConsortium
# 1 </dataroot
# 1 <?xml version="1.0" encoding="UTF-8"?
# 23964 <Accession
# 41816 <Authority
# 4141 <InfraspecificAuthority
# 6204 <InfraspecificName
# 1103 <LatLongAccuracy
# 5775 <LatLongDatum
# 9697 <LatitudeDecimal
# 9697 <LatitudeDegree
# 9690 <LatitudeDirection
# 9684 <LatitudeMinutes
# 7974 <LatitudeSeconds
# 44546 <Locality
# 9697 <LongitudeDecimal
# 9699 <LongitudeDegree
# 9695 <LongitudeDirection
# 9688 <LongitudeMinutes
# 8124 <LongitudeSeconds
# 10907 <MoreCollectors
# 4014 <Prefix
# 6171 <Rank
# 42612 <SpecificEpithet
# 1783 <Suffix
# 4920 <TownshipAndRange
# 53 <TypeStatus
# 44679 <UCConsortium
# 4475 <USGSQuadrangle
# 3459 <USGSQuadrangleScale
# 3562 <UTMZone
# 1 <dataroot xmlns:od="urn:schemas-microsoft-com:officedata"
# 3585 <easting
# 3585 <northing

Record: while(<IN>){
warn "$.  " unless $.%10000;
	($err_line=$_)=~s/\n/\t/g;
	$combined_collector=$assignor=$genus=$LatitudeDirection=$LongitudeDirection=$date= $collnum= $coll_num_prefix= $coll_num_suffix= $name= $accession_id= $county= $locality= $Unified_TRS= $elevation= $collector= $other_coll= $ecology= $color= $lat= $long= $decimal_lat= $decimal_long=$zone="";
	s/&apos;/'/g;
	s/&quot;/"/g;
	s/&amp;/&/g;
	unless(m/<GeoSecondaryDivision> *California *</){
		($state)=m/<GeoSecondaryDivision>(.*)</;
		print ERROR "Non-California record, skipped: $state $err_line\n";
		next;
	}
	unless(m/<HerbID>\d+<\/HerbID>/){
		print ERROR "No Id, skipped $err_line\n";
		next;
	}
	if(m/<Locality>.*Arboretum.*<\/Locality>/s){
		print ERROR "Arboretum plant: skipped $err_line\n";
		next;
	}
	($accession_id)=m/<HerbID>(.*)</;
	$accession_id="UCD$accession_id";
	if($seen{$accession_id}++){
		$genus_tag="AGenus";
		$species_tag="ASpecificEpithet";
		$infra_tag="AInfraspecificName";
		++$skipped{one};
		warn "Duplicate number: $accession_id<\n";
		print ERROR<<EOP;

Duplicate accession number $accession_id
EOP
		#next;
	}

	if(m|<Genus>(.+)</Genus>|s){
		$name=$1;
		$genus=$1;
			$genus=~s/^ *//;
		unless($genus){
			print ERROR "No generic name, skipped: $err_line\n";
			next;
		}
	}
	if(m|<SpecificEpithet>(.+)</SpecificEpithet>|s){
		$name.=" " . lc($1);
	}
	if(m|<Rank>(.+)</Rank>|s){
		$rank=$1;
		$rank=~s/ *$//;
		$rank=~s/^ *//;
		$rank=~s/ssp\.?/subsp./;
		$rank=~s/form.*/f./;
		$rank.=".";
		$rank=~s/\.\././;
		$name.=" $rank";
	}
	if(m|<InfraspecificName>(.+)</InfraspecificName>|s){
		$name.=" " . lc($1);
	}
	$name=~s/\?//g;
	$name=~s/s\. *l\.//g;
	$name=~s/ var\. *$//;
	$name=~s/ +/ /g;
	$name=~s/ *$//g;
	$name=~s/^ +//g;
	$name=~s/ +\(.*//;
	unless($name){
		print ERROR "No name, skipped: $err_line\n";
		next;
	}
	if($exclude{$genus}){
		print ERROR <<EOP;
Excluded, not a vascular plant: $name $err_line
EOP
	next;
	}
	if($alter{$name}){
		print ERROR <<EOP;
Spelling altered to $alter{$name}: $name 
EOP
		$name=$alter{$name};
	}


		$name=~s/ssp\./subsp./;
		$name=~s/<!\[CDATA\[(.*)\]\]>/$1/i;
		$name=~s/ cultivar\. .*//;
		$name=~s/ (cf\.|affn?\.|sp\.)//;
	$name=~s/ +/ /g;
	$name=~s/ $//g;
	$name=~s/^ +//g;
		unless($taxon{$name}){
			$name=~s/var\./subsp./;
			if($alter{$name}){
				print ERROR <<EOP;
Spelling altered to $alter{$name}: $name 
EOP
				$name=$alter{$name};
			}
			unless($taxon{$name}){
				$name=~s/subsp\./var./;
				if($alter{$name}){
					print ERROR <<EOP;
Spelling altered to $alter{$name}: $name 
EOP
					$name=$alter{$name};
				}
				unless($taxon{$name}){
					$noname{$name}++;
					print ERROR <<EOP;
Name not yet entered into smasch, skipped: $accession_id $name 
EOP
					next;
				}
			}
		}
	$name=~s/ *\?//;
#if(($first_parent)=m|<Herbarium_x0020_Labels_hybridspp1>(.*)</Herbarium_x0020_Labels_hybridspp1>| &&
#($second_parent)=m|<Herbarium_x0020_Labels_hybridspp2>(.*)</Herbarium_x0020_Labels_hybridspp2>|){
                 #$hybrid_annotation="$name $first_parent X $name $second_parent";
             #}
	     #else{
                 #$hybrid_annotation="";
				#$first_parent=$second_parent="";
	     #}



	if(m|<Elevation2>(.+)</Elevation2>|s){
		$elevation=$1;
		if(m|<Elevation>(.+)</Elevation>|s){
			$elevation = "$1 - $elevation";
		}
		if(m|<ElevationUnits>(.*)</ElevationUnits>|s){
			$elevation.=" $1";
			#$elevation=~s/\. *//;
		}
	}
	elsif(m|<Elevation>(.+)</Elevation>|s){
		$elevation=$1;
		if(m|<ElevationUnits>(.*)</ElevationUnits>|s){
			$elevation.=" $1";
			#$elevation=~s/\. *//;
		}
	}
	elsif(s/ *(Elevation|Elev\.) (\d+) *'//i){
		$elevation="$2 ft";
	}
	elsif(s/ *(Elevation|Elev\.) (\d+) *ft\.?//i){
		$elevation="$2 ft";
	}
	elsif(s/ *(Elevation|Elev\.) (\d+) *feet\.?//i){
		$elevation="$2 ft";
	}
	elsif(s/ *(Elevation|Elev\.) (\d+) *m\.?//i){
		$elevation="$2 m";
	}
	else{
		$elevation="";
	}
	if(($locality)=m|<Locality>(.+)</Locality>|s){
		$locality=~s/<!\[CDATA\[(.*)\]\]>/$1/;
		$locality=~s/CALIFORNIA[:,.] .*(CO|County)[.:;,]+//i;
		$locality=~s/^ *[,.:;] *//;
		$locality=~s/[,.:; ]+$//;
		#print "$locality\n";
	}
	else{
		$locality="";
	}
#<CorrectedDate>1974-04-22T00:00:00</CorrectedDate>
	if(($year,$month,$day)=m|<CorrectedDate>(\d\d\d\d)-(\d\d)-(\d\d).*</CorrectedDate>|s){
$date = "$month $day $year";
#print "picking up Cdate ";
}
	else{
	if(m|<Date>(.*)</Date>|s){
		$date=$1;
		$date=~s/<!\[CDATA\[ *(.*)\]\]>/$1/;
#Note ells in date
		$date=~s/l(9\d\d)/1$1/;
		if($date=~m/^\d+[- ]+[A-Za-z.]+[ -]+\d\d\d\d/){
			($day,$month,$year)=split(/[- .]+/,$date);
			$month=substr($month,0,3);
			unless($month=~/[A-Za-z][a-z][a-z]/){
				warn "1 Date problem:  $date\n";
			}
		}
		elsif($date=~m/([A-Za-z.]+) +(\d+),? +(\d\d\d\d)/){
			$month=$1; $day=$2; $year=$3;
		}
		elsif($date=~m/^([A-Za-z.,]+) +(\d\d\d\d)/){
			$month=$1; $year=$2; $day="";
		}
		elsif($date=~m|\d+/\d+/\d\d\d\d|){
			#date is OK;
		}
		elsif($date=~m|^(\d\d\d\d)\??|){
			$date=$1;
		}
		elsif($date=~m|(\d+)[/ ]*([A-Za-z,.]+)[/ ]*(\d\d\d\d)|){
			$day=$1; $month=$2;$year=$3;
		}
		elsif($date=~m|(\d+)[/ ]*([A-Za-z,.]+)[/ ]*([1-9]\d)$|){
			$day=$1; $month=$2;$year="19$3";
			print ERROR "Y2K problem, $date = $year?: $err_line\n";
		}
		elsif($date=~m|(\d+)/(\d+)/([1-9]\d)$|){
			$day=$1; $month=$2;$year="19$3";
			print ERROR "Y2K problem, $date = $year?: $err_line\n";
		}
		elsif($date=~m|(\d+)[/ ]*([A-Za-z,.]+)[/ ]*(0\d)$|){
				$day=$1; $month=$2;$year="20$3";
		print ERROR "Y2K problem, $date = $year?: $err_line\n";
		}
		elsif($date=~m|(\d+)/(\d+)/(0\d)$|){
				$day=$1; $month=$2;$year="20$3";
		print ERROR "Y2K problem, $date = $year?: $err_line\n";
		}
		elsif($date=~m|(\d+-\d+)[- ]+([A-Za-z.])+[ -]+(\d\d\d\d)|){
				$day=$1; $month=$2;$year=$3;
			}
		elsif($date=~m|19(\d)_\?|){
			$year="19${1}0s";
			}
		elsif($date=~m|19__\?|){
			$year="1900s";
			}
		else{
			print ERROR "Fall thru Date problem: $date made null $err_line\n";
			$date="";
		}
$day="" if $day eq "00";
			$month=substr($month,0,3);
$date = "$month $day $year";
$date=~s/  */ /g;
	}
	}
	if(m|<Ecology>(.*)</Ecology>|s){
		$ecology=$1;
		$ecology=~s/<!\[CDATA\[(.*)\]\]>/$1/;
	}
	else{
		$ecology=""
	}
	if(m|<Habitat>(.*)</Habitat>|s){
		$habitat=$1;
	}
	else{
		$habitat=""
	}
	if(m|<Collector>(.*)</Collector>|s){
		$collector=$1;
		$collector=~s/<!\[CDATA\[(.*)\]\]>/$1/;
		$collector=~s/([A-Z]\.) (and|&) ([A-Z]\.) ([A-Z][a-z]+)/$1 $4, $3 $4/;
		$collector=~s/([A-Z]\.)([A-Z][a-z])/$1 $2/g;
		$collector=~s/\./. /g;
		$collector=~s/ +,/,/;
		$collector=~s/  +/ /g;
		$collector=~s/ *$//;
		$collector=~s/^ *//;
		$assignor=$collector;
		$assignor=&modify_coll($assignor);
		$assignor=$alter_coll{$assignor} if $alter_coll{$assignor};
		$need_coll{$assignor}++ unless $coll_comm{$assignor};
		if(m|<MoreCollectors>(.*)</MoreCollectors>|s){
			$other_coll=$1;
			$other_coll=~s/<!\[CDATA\[(.*)\]\]>/$1/i;
			$other_coll=~s/^ *and //;
			$other_coll=~s/^ *[Ww]ith //;
			$combined_collector= "$collector, $other_coll";
			$collector=$assignor;
			$combined_collector=~s/,? (with|&|and) /, /g;
			$combined_collector=~s/ (with|&|and) */, /g;
		$combined_collector=~s/\./. /g;
		$combined_collector=~s/ +,/,/;
		$combined_collector=~s/  +/ /g;
		$combined_collector=~s/ *$//;
		$combined_collector=~s/^ *//;
			$combined_collector=&modify_coll($combined_collector);
			$combined_collector=$alter_coll{$combined_collector} if $alter_coll{$combined_collector};
			$need_coll{$combined_collector}++ unless $coll_comm{$combined_collector};
		}
		else{
			$combined_collector="";
		}
	}
	if(m|<CollectionNumber>(.*)</CollectionNumber>|s){
		$collnum=$1;
		$collnum=~s/<!\[CDATA\[ *(.*)\]\]>/$1/;
		if(m|<Prefix>(.*)</Prefix>|s){
			$coll_num_prefix=$1;
		}
		if(m|<Suffix>(.*)</Suffix>|s){
			$coll_num_suffix=$1;
		}
	}
	else{
		#warn "NO CNUM$_\n";
	}
if(m/<UTMZone>/){
	$zone=$easting=$northing="";
	if(m/<UTMZone>(\d+).*/){
		$zone="${1}N";
		#print "1 $zone $&\n";
	}
	elsif(m/<UTMZone>Zone (\d+).*/){
		$zone="${1}N";
		#print "2 $zone $&\n";
	}
	if (m/<easting>(\d+)/){
		$easting=$1;
	}
	if (m/<northing>(\d+)/){
		$northing=$1;
	}
	if(m/Datum>(.*)</){
		$datum=$1;
		if($datum=~/WGS.*84/){
			$ellipsoid=23;
		}
		elsif($datum=~/NAD.*83/i){
			$ellipsoid=23;
		}
		elsif($datum=~/NAD.*27/){
			$ellipsoid=5;
		}
		else {
			print "$datum\n";
		}
	}
	else{
		$datum="";
		$zone="";
	}
}
if(m|<LongitudeDegree>(.+)</LongitudeDegree>|s){
	$long=$1;
	$long=~s/^ //;
	if(m|<LongitudeMinutes>(.+)</LongitudeMinutes>|s){
		$minutes=$1;
		$minutes="0$minutes" if $minutes=~/^.$/;
		$long.=" $minutes";
		if(m|<LongitudeSeconds>(.+)</LongitudeSeconds>|s){
			$long.=" $1";
		}
	}
	elsif(m|<LongitudeSeconds>(.+)</LongitudeSeconds>|s){
		$long.=" 00 $1";
		}
($LongitudeDirection)=m|<LongitudeDirection>(.*)</LongitudeDirection>|;
$LongitudeDirection="W" unless $LongitudeDirection;
$long .= $LongitudeDirection;
$long=~s/  */ /g;
print "L: $long\n";
}
else{
$long="";
}
if(m|Datum>(.*)</.*Datum>|s){
$datum=$1;
}
else{
$datum="";
}

if(m|<LatitudeDegree>(.+)</LatitudeDegree>|s){
	$lat=$1;
	$lat=~s/^ //;
	if(m|<LatitudeMinutes>(.+)</LatitudeMinutes>|s){
		$minutes=$1;
		$minutes="0$minutes" if $minutes=~/^.$/;
		$lat.=" $minutes";
		if(m|<LatitudeSeconds>(.+)</LatitudeSeconds>|s){
			$lat.=" $1";
		}
	}
	elsif(m|<LatitudeSeconds>(.+)</LatitudeSeconds>|s){
		$lat.=" 00 $1";
		}
($LatitudeDirection)=m|<LatitudeDirection>(.*)</LatitudeDirection>|;
$LatitudeDirection="N" unless $Latitude_Direction;
$lat .= $LatitudeDirection;
$lat=~s/  */ /g;
print "LT: $lat\n";
}
else{
$lat="";
}


if(m|<LatitudeDecimal>([\d.]+)</LatitudeDecimal>|){
$decimal_lat=$1;
}
else{
$decimal_lat="";
}
if(m|<LongitudeDecimal>([\d.-]+)</LongitudeDecimal>|){
$decimal_long=$1;
		print " LD $decimal_lat, $decimal_long\n";
}
else{
$decimal_long="";
}
	if($zone){
		($decimal_lat,$decimal_long)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
		print " UTM $decimal_lat, $decimal_long\n";
	}


if(($decimal_lat=~/\d/  || $decimal_long=~/\d/)){
	$decimal_long="-$decimal_long" if $decimal_long > 0;
	if($decimal_lat > 42.1 || $decimal_lat < 32.5 || $decimal_long > -114 || $decimal_long < -124.5){
		if($zone){
		print ERROR "coordinates set to null, Outside California: $accession_id: UTM is $zone $easting $northing --> $decimal_lat $decimal_long\n";
		}
		else{
		print ERROR "coordinates set to null, Outside California: D_lat is $decimal_lat D_long is $decimal_long lat is $lat long is $long\n";
		}
$decimal_lat =$decimal_long="";
}   
}  





if(m|<TownshipAndRange>T.*(\d+).*(N).*R.*(\d+).*(E).*Sect.*(\d+)</TownshipAndRange>|s){
$Unified_TRS="$1$2$3$4$5";
}
else{
$Unified_TRS="";
}
if(m/<GeoTertiaryDivision>(.+)</){
$county=$1;
$county=~s/ *County//i;
	}
else{
$county="unknown";
}
foreach($county){
#unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)/i){
		#print ERROR <<EOP;
		#Unknown California county; $accession_id: $_
#EOP
#}
	s/San Bernadino/San Bernardino/;
	s/San Bernidino/San Bernardino/;
	s/San Beradino/San Bernardino/;
	s/San Berardino/San Bernardino/;
	s/Santa Barabara/Santa Barbara/;
	s/Toulomne/Tuolumne/;
	s/Tuolomne/Tuolumne/;
	s/Los Angelos/Los Angeles/;
	s/Monterrey/Monterey/;
	s/Montery/Monterey/;
	s/Santo Cruz/Santa Cruz/;
	s/Calveras/Calaveras/;
	s/Yolo Grasslands Park/Yolo/;
	s/ and.*//;
	s/^S\. ?E\. ?//;
	s/^Western //;
	s/El ?Dorodo/El Dorado/;
	s/El ?dorodo/El Dorado/;
	s/Mododc/Modoc/;
	s/Solona/Solano/;
	s/Glen$/Glenn/;
	s/UC Davis Campus/Yolo/;
	s/Armador/Amador/;
	s/Humbolt/Humboldt/;
	s/Mendicino/Mendocino/;
	s/-.*//;
	s/ or .*//;
	s/ Co\.?$//;
	s/\?//;
	s| */.*||;
	s/ ?- .*//;
	s/ *\.$//;
	s/^ *$/unknown/;
	s/^ *//;
	s/ *$//;
unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)/i){
		print ERROR <<EOP;
		Unknown California county, not corrected; skipping $accession_id: $_
EOP
next Record;
	}
	}
	unless ($county=~/[Uu]nknown/){
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

			if($elev_test > $max_elev{$county}){
				print ERROR "$accession_id\t$county\t ELEV: $elevation $metric greater than max: $max_elev{$county} discrepancy=", $elev_test-$max_elev{$county},"\n";
			}
		}
	}

if($ecology=~s/[.,;] *([Ff]lowers [^.]+)\././){
$color=$1;
}
else{
$color="";
}
$decimal_lat="" unless $decimal_long;
$decimal_long="" unless $decimal_lat;
$long=~s/E/W/;
if(m/<DeterminedBy>(.*)<\/DeterminedBy>/){
$annotation="$name; $1";
}
else{
$annotation="";
}
foreach(
$annotation,
$date,
$collnum,
$coll_num_prefix,
$coll_num_suffix,
$name,
$accession_id,
$county,
$locality,
$Unified_TRS,
$elevation,
$assignor,
$other_coll,
$combined_collector,
$ecology,
$color,
$lat,
$long,
$decimal_lat,
$decimal_long,
){
s/\n/ /g;
s/[ 	][ 	]*/ /g;
}
print OUT <<EOP;
Date: $date
CNUM: $collnum
CNUM_prefix: $coll_num_prefix
CNUM_suffix: $coll_num_suffix
Name: $name
Accession_id: $accession_id
Country: USA
State: California
County: $county
Location: $locality
T/R/Section: $Unified_TRS
Elevation: $elevation
Collector: $assignor
Other_coll: $other_coll
Combined_collector: $combined_collector
Habitat: $ecology
Color: $color
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Notes: 
Annotation: $annotation

EOP
}
foreach(sort {$noname{$a}<=>$noname{$b}}(keys(%noname))){
print "$_ : $noname{$_}\n";
}
foreach(sort(keys(%need_coll))){
print "$_: $need_coll{$_}\n";
}
sub modify_coll {
local($_)=shift;
		s/Andrienne/Adrienne/;
s/Paul Brodmann/Paul Broadmann/;
s/A. Solomechch/A. Solomeshch/;
s/A. T. Wittemore/A. T. Whittemore/;
s/A. M Shapiro/A. M. Shapiro/;
s/BiF Soper/Bif Soper/;
s/Bif Sopez/Bif Soper/;
s/Bijou Dehgan/Bijan Dehgan/;
s/Brian W. Boose./Brian W. Boose/;
s/Charlote Glenn/Charlotte K. Glenn/;
s/Craig Thompson/Craig Thomsen/;
s/Harry Agamelian/Harry Agamalian/;
s/Joe Di Tomaso/Joe Ditomaso/;
s/Joe DiTomaso/Joe Ditomaso/;
s/Joseph Laferriere/Joseph Laferrière/;
s/Katherine Countrey/Katherine Courtney/;
s/Katherine Courtny/Katherine Courtney/;
s/Kathi A. Zurakowskai/Kathi A. Zurakowski/;
s/Kathi A. Zukrakowski/Kathi A. Zurakowski/;
s/Kathleen worden/Kathleen Worden/;
s/Kristine L . Preston/Kristine L. Preston/;
s/L. K. Manu/L.K. Mann/;
s/Lurie Oleksiewicz/Laurie Oleksiewicz/;
s/M. Rejmanch/M. Rejmanek/;
s/Maura Cullinare/Maura Cullinane/;
s/Maura Cullinene/Maura Cullinane/;
s/Ralph Philips/Ralph Phillips/;
s/Ramona Robison/Ramona Robinson/;
s/Rex Plamer/Rex Palmer/;
s/Rob Ickel/Rob Ickes/;
s/Susan J. Schmidale/Susan J. Schmickle/;
s/Walter. R Spiver/Walter R. Spiver/;
s/  / /g;
$_;
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
