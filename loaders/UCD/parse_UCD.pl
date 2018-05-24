open(IN,"davis_alter_coll") || die;
while(<IN>){
	chomp;
s/\cJ//;
s/\cM//;
	next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	$alter_coll{$rsa}=$smasch;
}
open(IN,"../collectors_id") || die;
#open(IN,"../all_collectors_2005") || die;
while(<IN>){
	chomp;
s/\t.*//;
	$coll_comm{$_}++;
}
open(IN,"../tnoan.out") || die;
while(<IN>){
	chomp;
	s/^.*\t//;
	$taxon{$_}++;
}
open(IN,"../riv_non_vasc") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}
open(IN,"davis_alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(IN,"../riv_alter_names") || die;
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
open(IN,"alter_davis") || die;
@alters=<IN>;
chomp(@alters);
foreach $i (0 .. $#alters){
	unless($i % 2){
		if($alters[$i]=~s/ :.*//){
			$alter{$alters[$i]}=$alters[$i+1];
		}
		else{
			die "misconfig: $i $alters[$i]";
		}
	}
}
$/="<UCConsortium>";
open(ERROR, ">Davis_problems") || die;
open(OUT, ">parse_davis.out") || die;
open(IN,"2006/UCConsortium.xml") || die;

while(<IN>){
	($err_line=$_)=~s/\n/\t/g;
	$combined_collector=$assignor=$genus=$LatitudeDirection=$LongitudeDirection=$date= $collnum= $coll_num_prefix= $coll_num_suffix= $name= $accession_id= $county= $locality= $Unified_TRS= $elevation= $collector= $other_coll= $ecology= $color= $lat= $long= $decimal_lat= $decimal_long="";
	s/&apos;/'/g;
	s/&quot;/"/g;
	s/&amp;/&/g;
	unless(m/<GeoSecondaryDivision>California/){
		($state)=m/<GeoSecondaryDivision>(.*)</;
		print ERROR "Non-California record, skipped: $state $err_line\n";
		next;
	}
	unless(m/<ID>\d+<\/ID>/){
		print ERROR "No Id, skipped $err_line\n";
		next;
	}
	($accession_id)=m/<ID>(.*)</;
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

	if(m|<Genus>(.+)</Genus>|){
		$name=$1;
		$genus=$1;
			$genus=~s/^ *//;
		unless($genus){
			print ERROR "No generic name, skipped: $err_line\n";
			next;
		}
	}
	if(m|<SpecificEpithet>(.+)</SpecificEpithet>|){
		$name.=" " . lc($1);
	}
	if(m|<Rank>(.+)</Rank>|){
		$rank=$1;
		$rank=~s/form.*/f./;
		$rank.=".";
		$rank=~s/\.\././;
		$name.=" $rank";
	}
	if(m|<InfraspecificName>(.+)</InfraspecificName>|){
		$name.=" " . lc($1);
	}
	$name=~s/ +/ /g;
	$name=~s/ $//g;
	$name=~s/^ +//g;
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
		if(m|<MoreCollectors>(.*)</MoreCollectors>|){
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
	if(m|<CollectionNumber>(.*)</CollectionNumber>|){
		$collnum=$1;
		$collnum=~s/<!\[CDATA\[ *(.*)\]\]>/$1/;
		if(m|<Prefix>(.*)</Prefix>|){
			$coll_num_prefix=$1;
		}
		if(m|<Suffix>(.*)</Suffix>|){
			$coll_num_suffix=$1;
		}
	}
	else{
		#warn "NO CNUM$_\n";
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
$LongitudeDirection="W" unless $LongitudeDirection;
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
$LatitudeDirection="N" unless $Latitude_Lirection;
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
foreach($county){
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
	s/El Dorodo/El Dorado/;
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
}

if($ecology=~s/[.,;] *([Ff]lowers [^.]+)\././){
$color=$1;
}
else{
$color="";
}
$decimal_latitude="" unless $decimal_longitude;
$decimal_longitude="" unless $decimal_latitude;
$longitude=~s/E/W/;
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
