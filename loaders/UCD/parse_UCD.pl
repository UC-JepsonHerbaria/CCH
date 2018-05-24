$/="<HerbariumXML>";
open(ERROR, ">Davis_problems") || die;
open(OUT, ">Davis_parsed.out") || die;
while(<>){
$LatitudeDirection=$LongitudeDirection=$date= $collnum= $coll_num_prefix= $coll_num_suffix= $name= $accession_id= $county= $locality= $Unified_TRS= $elevation= $collector= $other_coll= $ecology= $color= $lat= $long= $decimal_lat= $decimal_long="";
	unless(m/<GeoSecondaryDivision>California/){
		($state)=m/<GeoSecondaryDivision>(.*)</;
		print ERROR "Non-California record, skipped: $state\n";
		next;
	}
	unless(m/<ID>\d+<\/ID>/){
		print ERROR "No Id, skipped $_\n";
		next;
	}
	($accession_id)=m/<ID>(.*)</;
	$accession_id="UCD$accession_id";
	if(m|<Genus>(.+)</Genus>|){
		$name=$1;
	}
	if(m|<SpecificEpithet>(.+)</SpecificEpithet>|){
		$name.=" $1";
	}
	if(m|<Rank>(.+)</Rank>|){
		$name.=" $1";
	}
	if(m|<InfraspecificName>(.+)</InfraspecificName>|){
		$name.=" $1";
	}
	unless($name){
		print ERROR "No name, skipped: $_\n";
		next;
	}
	if(m|<Elevation>(.+)</Elevation>|){
		$elevation=$1;
		if(m|<ElevationUnits>(.*)</ElevationUnits>|){
			$elevation.=" $1";
			$elevation=~s/\. *//;
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
	if(($locality)=m|<Locality>(.+)</Locality>|){
		$locality=~s/<!\[CDATA\[(.*)\]\]>/$1/;
		$locality=~s/CALIFORNIA[:,.] .*(CO|County)[.:;,]+//i;
$locality=~s/^ *[,.:;] *//;
$locality=~s/[,.:; ]+$//;
		#print "$locality\n";
	}
	else{
		$locality="";
	}
	if(m|<Date>(.*)</Date>|){
		$date=$1;
#Note ells in date
		$date=~s/l(9\d\d)/1$1/;
		if($date=~m/\d+[- ]+[A-Za-z.]+[ -]+\d\d\d\d/){
			($day,$month,$year)=split(/[- .]+/,$date);
			$month=substr($month,0,3);
			unless($month=~/[A-Z][a-z][a-z]/){
				warn "Date problem:  $date\n";
			}
		}
		elsif($date=~m/([A-Za-z.]+) +(\d+),? +(\d\d\d\d)/){
			$month=$1; $day=$2; $year=$3;
		}
		elsif($date=~m/^([A-Za-z.,]+) +(\d\d\d\d)/){
			$month=$1; $year=$2; $day="";
			$month=substr($month,0,3);
		}
		else{
			warn " Date problem: $date\n";
			$date="";
		}
$day="" if $day eq "00";
$date = "$month $day $year";
$date=~s/  */ /g;
	}
	if(m|<Ecology>(.*)</Ecology>|){
		$ecology=$1;
		$ecology=~s/<!\[CDATA\[(.*)\]\]>/$1/;
	}
	else{
		$ecology=""
	}
	if(m|<Habitat>(.*)</Habitat>|){
		$habitat=$1;
	}
	else{
		$habitat=""
	}
	if(m|<Collector>(.*)</Collector>|){
		$collector=$1;
		$collector=~s/<!\[CDATA\[(.*)\]\]>/$1/;
		if(m|<MoreCollectors>(.*)</MoreCollectors>|){
			$other_coll=$1;
		$other_coll=~s/<!\[CDATA\[(.*)\]\]>/$1/;
			$other_coll=~s/^ *and //;;
		}
	}
	if(m|<CollectionNumber>(.*)</CollectionNumber>|){
		$collnum=$1;
		if(m|<Prefix>(.*)</Prefix>|){
			$coll_num_prefix=$1;
		}
		if(m|<Suffix>(.*)</Suffix>|){
			$coll_num_suffix=$1;
		}
	}
if(m|<LongitudeDegree>(.+)</LongitudeDegree>|){
	$long=$1;
	$long=~s/^ //;
	if(m|<LongitudeMinutes>(.+)</LongitudeMinutes>|){
		$minutes=$1;
		$minutes="0$minutes" if $minutes=~/^.$/;
		$long.=" $minutes";
		if(m|<LongitudeSeconds>(.+)</LongitudeSeconds>|){
			$long.=" $1";
		}
	}
	elsif(m|<LongitudeSeconds>(.+)</LongitudeSeconds>|){
		$long.=" 00 $1";
		}
($LongitudeDirection)=m|<LongitudeDirection>(.*)</LongitudeDirection>|;
$long .= $LongitudeDirection;
$long=~s/  */ /g;
}
else{
$long="";
}
if(m|<LatitudeDegree>(.+)</LatitudeDegree>|){
	$lat=$1;
	$lat=~s/^ //;
	if(m|<LatitudeMinutes>(.+)</LatitudeMinutes>|){
		$minutes=$1;
		$minutes="0$minutes" if $minutes=~/^.$/;
		$lat.=" $minutes";
		if(m|<LatitudeSeconds>(.+)</LatitudeSeconds>|){
			$lat.=" $1";
		}
	}
	elsif(m|<LatitudeSeconds>(.+)</LatitudeSeconds>|){
		$lat.=" 00 $1";
		}
($LatitudeDirection)=m|<LatitudeDirection>(.*)</LatitudeDirection>|;
$lat .= $LatitudeDirection;
$lat=~s/  */ /g;
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
if(m|<LongitudeDecimal>(-[\d.]+)</LongitudeDecimal>|){
$decimal_long=$1;
}
else{
$decimal_long="";
}
if(m|<TownshipAndRange>T.*(\d+).*(N).*R.*(\d+).*(E).*Sect.*(\d+)</TownshipAndRange>|){
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

if($ecology=~s/[.,;] *([Ff]lowers [^.]+)\././){
$color=$1;
}
else{
$color="";
}
$seen_coll{$collector}++;
$seen_coll{"$collector, $other_coll"}++ if $other_coll;
		$name=~s/ssp\./subsp./;
		$name=~s/<!\[CDATA\[(.*)\]\]>/$1/;
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
Collector: $collector
Other_coll: $other_coll
Habitat: $ecology
Color: $color
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Notes: 

EOP
}
foreach(sort(keys(%seen_coll))){
print "$_\n";
}
