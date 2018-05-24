use lib '/Users/richardmoe/4_DATA/CDL';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
&load_noauth_name;

$m_to_f="3.2808";
		use Geo::Coordinates::UTM;

open(ERR,">CLARK_problems") || die;

print ERR <<EOP;
$today
Report from running parse_CLARK.pl
Name alterations from file ~/data/CDL/alter_names
Name comparisons made against ~/taxon_ids/smasch_taxon_ids (SMASCH taxon names, which are not necessarily correct)
Genera to be excluded from riv_non_vasc

EOP


while(<DATA>){
	@fields=split(/\t/);
	$fields[3]=~s/\+//;
	$fields[3]=~s/,//;
	$max_elev{$fields[1]}=$fields[3];
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






open(TABFILE,">parse_CLARK.out") || die;
#open(OUT,">rsa_problems") || die;
open(COORDS,">CLARK_coord_issues") || die;

$current_file="CLARK.txt";


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

#ID	FAMILY	GENUS	SPECIES	SP. AUTH.	SSP.	SSP. AUTH.	COMMON NAME	LOCALITY	LOCALITY NOTES	DATE	COLLECTOR	FIELD #	LAT/LONG	UTM E/N	OTHER #

open(IN,"$current_file") || die;
#open(IN,"test_ac.tmp") || die;
Record: while(<IN>){
$assoc=$combined_collectors=$Collector= $elevation= $name=$lat=$long=$decimal_lat=$decimal_long="";
		$zone=$easting=$northing="";

	chomp;
	@fields=split(/\t/,$_,100);
#unless ($#fields==15){
#foreach  $i (1 .. $#fields){
#print "$i $fields[$i]\n";
foreach(@fields){
s/^"? *//;
s/ *"?$//;
#}
}
#next;

$Label_ID_no="CLARK-$fields[0]";
	$genus=$fields[2];
	$species=$fields[3];
	$infra =$fields[5];
	if($infra){
		$name="$genus $species subsp. $infra";
	}
	else{
		$name="$genus $species";
	}
	$name=~s/ *$//;
	$name=~s/ +/ /g;
	($country,$state,$county,$place)=split(/ ?\| ?/,$fields[8]);
$country=~s/^ *//;
$county=~s/ County//;
	$date=$fields[10];
if($date=~/[Uu]nknown/){
$date="";
}
else{
unless($date=~/\/(1[789]\d\d|20\d\d)$/){
		print ERR<<EOP;
Date config problem $date: date nulled 9 $Label_ID_no
EOP
}
}
	$collector=$fields[11];
	$CNUM=$fields[12];
print "$CNUM\n";
	($decimal_lat,$decimal_long)=split(/ ?[,\|] ?/,$fields[13]);
#print <<EOP;
#$decimal_lat = $decimal_long = $fields[13]
#EOP
	$datum="WGS84/NAD83";
	($easting,$northing)=split(/ ?\| ?/,$fields[14]);
	@local=split(/; /,$fields[9]);
	$elevation="";
$associates="";
#print "$fields[9]\n";
	#foreach $i (0 .. $#local){
#print "$i $local[$i]\n";
#}
	foreach(@local){
		if(s/([Ee]levation.*)//){
			$elevation=$1;
$elevation=~s/elevation //;
$elevation=~s/,//;
$elevation=~s/approximately/ca./;

		}
elsif(s/associated with (.*)//){
$associates=$1;
}
	}
$locality_notes=join("; ",@local);



	$line_store=$_;
	++$count;
	($poss_dup=$_)=~s/\t.*//;
	unless($poss_dup=~/^A\d/){
		++$skipped{one};
		print ERR<<EOP;

Not CLARK, skipped: $_
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
	if($seen{$fields[0]}++){
		++$skipped{one};
		warn "Duplicate number: $fields[0]<\n";
		print ERR<<EOP;

Duplicate accession number, skipped: $fields[0]
EOP
		next Record;
	}

	################collector numbers
	$CNUM=~s/ *$//;
	$CNUM=~s/^ *//;
	$CNUM=~s/,//;
		$Coll_no_prefix= $Coll_no_suffix="";
	if($CNUM=~s/-$//){
		$Coll_no_suffix="-$Coll_no_suffix";
	}
	if($CNUM=~s/^-//){
		$Coll_no_prefix.="-";
	}
	if($CNUM=~s/^([0-9]+)(-[0-9]+)$/$2/){
		$Coll_no_prefix.=$1;
	}
	if($CNUM=~s/^([0-9]+)(\.[0-9]+)$/$1/){
		$Coll_no_suffix=$2 . $Coll_no_suffix;
	}
	if($CNUM=~s/^([0-9]+)([A-Za-z]+)$/$1/){
		$Coll_no_suffix=$2 . $Coll_no_suffix;
	}
	if($CNUM=~s/^([0-9]+)([^0-9])$/$1/){
		$Coll_no_suffix=$2 . $Coll_no_suffix;
	}
	if($CNUM=~s/^(S\.N\.|s\.n\.)$//){
		$Coll_no_suffix=$1 . $Coll_no_suffix;
	}
	if($CNUM=~s/^([0-9]+-)([0-9]+)([A-Za-z]+)$/$2/){
		$Coll_no_suffix=$3 . $Coll_no_suffix;
		$Coll_no_prefix.=$1;
	}
	if($CNUM=~m/[^\d]/){
		$CNUM=~s/(.*)//;
		$Coll_no_suffix=$1 . $Coll_no_suffix;
	}
unless($state=~/^(CA|Ca|Calif\.|California)$/){
		print ERR<<EOP;
		State not California $fields[0] state=$state country=$country: $_ skipped
EOP
		next Record;
	}
		foreach($county){
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

	


$name=ucfirst(lc($name));
#print ">$name<\n";
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
				print ERR "ELEV $county\t ELEV: $elevation $metric greater than max: $max_elev{$county} discrepancy=", $elev_test-$max_elev{$county}," $Label_ID_no\n";
			}
		}

if($ecol_notes=~s/[;.] +([Aa]ssoc.*)//){
$assoc=$1;
}





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
$decimal_lat=~s/[^0-9.]//g;
$decimal_long=~s/[^0-9.]//g;
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




print TABFILE <<EOP;
Date: $date
CNUM_prefix: ${Coll_no_prefix}
CNUM: ${Coll_no}
CNUM_suffix: ${Coll_no_suffix}
Name: $name
Accession_id: $Label_ID_no
Family_Abbreviation: $family
Country: $country
State: $state
County: $county
Loc_other: $place
Location: $locality_notes
T/R/Section: $Unified_TRS
USGS_Quadrangle: $topo_quad
Elevation: $elevation
Collector: $collector
Other_coll: $other_coll
Combined_collector: $combined_collectors
Habitat: $ecol_notes
Associated_species: $associates
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Datum: $datum
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation

EOP
++$included;
}
open(COLL,">missing_coll");

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
