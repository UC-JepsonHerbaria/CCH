		%monthno=
("Jan","1",
"Feb","2",
"Mar","3",
"Apr","4",
"May","5",
"Jun","6",
"Jul","7",
"Aug","8",
"Sep","9",
"Oct","10",
"Nov","11",
"Dec","12");

$m_to_f="3.2808";
while(<DATA>){
	@fields=split(/\t/);
	$fields[3]=~s/\+//;
	$fields[3]=~s/,//;
	$max_elev{$fields[1]}=$fields[3];
}
open(IN,"/users/rlmoe/CDL_buffer/buffer/tnoan.out") || die;
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

$/="\n";
open(IN,"YOSE_2011.tab.csv") || die;
#open(IN,"new_y.csv") || die;
open(OUT,">YOSE_data.tab") || die;
open(ERR,">YOSE_data.err") || die;

RECORD:
while(<IN>){
$line=$_;
	s/^"//;
	s/"$//;
	s/\t"/\t/g;
	s/"\t/\t/g;
	chomp;
	@fields=split(/\t/,$_,100);
if ($fields[2]=~/Paleo/i){
		print ERR <<EOP;
$fields[0]: non living plant skipped\n
EOP
	next RECORD
}
if ($fields[2]=~/Paleo/i){
		print ERR <<EOP;
$fields[0]: non living plant skipped\n
EOP
	next RECORD
}
if ($fields[39]=~/MISSING/i){
		print ERR <<EOP;
$fields[0]: missing specimen plant skipped\n
EOP
	next RECORD
}
unless($#fields == 43){
die "$#fields bad field number not 43  $_ \n";
}
if($fields[13]=~/DATUM IS ([^ ]+)/i){
$datum=$1;
$datum=~s/1927/27/;
}
elsif($fields[13]=~/Datum: ([^ ]+)/i){
$datum=$1;
$datum=~s/1927/27/;
}
else{
$datum="";
}
	foreach (@fields){
	s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Not ?[pP]rovided|Not ?[rR]ecorded) *$//;
	}
	$Collector=$decimal_long=$decimal_lat="";
		$CNUM=""; $CNUM_prefix=""; $CNUM_suffix="";
@collectors=();

	($Catalog_id, $Accession_id, $Class_1, $Class_2, $Class_3, $Class, $Order, $Family, $Obj_Science, $Location, $Common_Name, $TSN, $Item_Count, $Description, $Collector, $Collection_Date, $Collection_id, $Other_Numbers, $Identified_By, $Ident_Date, $Locality, $Unit, $County, $State, $Lat_LongN_W, $UTM_Z_E_N, $Habitat, $Habitat_Comm, $Elevation, $Watrbody_Drain, $Slope, $Aspect, $Assoc_Spec, $Exotic_Native, $Threat_Endang, $Rare, $Type_Specimen, $Cataloger, $Catalog_Date, $Object_Status)=@fields;
$Catalog_id=~s/ +//;
$Catalog_id=~s/^/YM-/;
	if($County){
		foreach($County){
			s!^(TUOL-MARIPOSA|TUOL/MONO/MARI.|TUOLUAMNE|TUOLULMNE|TUOLUME|TUOLUMNE|TUOLUMNE \(\?\)|TUOLUMNE \(MONO\?|TUOLUMNE\(\?\)|TUOLUMNE-MARI\.|TUOLUMNE-MONO|TUOLUMNE/MADERA|TUOLUMNE/MARI\.|TUOLUMNE/MONO)$!Tuolumne!;
			s!^(MADEDRA|MADERA \(\?\)|MADERA/MONO|MADERA/TUOL|MADERA/TUOL.|MADERA/TUOLUMNE|MADERA)$!Madera!;
			s!^(MARIOSA|MARIPOSA/MADERA|MARIPOSA/TUOL.|MARIPOSAA|MARIPOSA)$!Mariposa!;
			s!^MERCED$!Merced!;
			s!^(MONO|MONO \(\?\)|MONO-TUOLUMNE|MONO/TUOLUMNE)$!Mono!;
			s!POHONO TRAIL!Unknown!;
			s!SANTA BARBARA!Santa Barbara!;
			s!SHEET NO. 4663, HERB. ACCESS. NO.  4559!Unknown!;
			s!SISKIYOU!Siskiyou!;
		}
	}
else{
$County="Unknown";
}

	if($Collection_id=~m/(.*)-(\d+)([A-Za-z-])*/){
		$CNUM=$2; $CNUM_prefix="$1-"; $CNUM_suffix=$3;
	}
	elsif($Collection_id=~m/^(\d+)([A-Za-z-])*/){
		$CNUM=$1; $CNUM_prefix=""; $CNUM_suffix=$2;
	}
	elsif($Collection_id=~/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Not ?[pP]rovided|Not ?[rR]ecorded)/){
		$CNUM=""; $CNUM_prefix=""; $CNUM_suffix="";
	}
	else{
		$CNUM=""; $CNUM_prefix="$Collection_id"; $CNUM_suffix="";
	}



#NAME
	$name= $Obj_Science;
	@name_fields=split(/ ?__/,$name);
	$name_fields[0]= ucfirst(lc($name_fields[0]));
	$name_fields[2]= lc($name_fields[2]);
	$name_fields[8]= lc($name_fields[8]);
	$name_fields[8]=~s/ .*//;
	$name_fields[5]= lc($name_fields[5]);
	$name_fields[5]=~s/ .*//;
	if($name_fields[8]=~/[a-z]/i){
		$name= "$name_fields[0] $name_fields[2] var. $name_fields[8]";
	}
	elsif($name_fields[5]=~/[a-z]/i){
		$name= "$name_fields[0] $name_fields[2] subsp. $name_fields[5]";
	}
	elsif($name_fields[2]=~/[a-z]/i){
		$name= "$name_fields[0] $name_fields[2]";
	}
	elsif($name_fields[0]=~/[a-z]/i){
#print "$Obj_Science\n";
		$name= "$name_fields[0]";
	}
	else{
		$name="";
	}
$name=~s/  */ /g;
$name=~s/ sp\.//;
$name=~s/ $//;

			if($name=~/([A-Z][a-z-]+ [a-z-]+) � /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			elsif($name=~/([A-Z][a-z-]+ [a-z-]+ (var\.|subsp\.) [a-z-]+) � /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			else{
				$hybrid_annotation="";
			}
	if($alter{$name}){
		print ERR <<EOP;
Spelling altered to $alter{$name}: $name 
EOP
		$name=$alter{$name};
	}
	if($alter{$name}){
		print ERR <<EOP;

Spelling altered further to $alter{$name}: $name 
EOP
		$name=$alter{$name};
	}
	if($name=~/[a-z]+ [a-z]+ +[Xx] +[a-z]+/){
				print ERR <<EOP;

Can't deal with unnamed hybrids yet: $name skipped $Label_ID_no
EOP
		++$needed_name{$name};
		next RECORD;
	}
	$name=~s/ssp\./subsp./;
	unless($taxon{$name}){
		$on=$name;
		if($name=~s/subsp\./var./){
			if($taxon{$name}){
				print ERR <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
			}
			else{
				print ERR <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped $Label_ID_no
EOP
		++$needed_name{$on};
		next RECORD;
		}
	}
	elsif($name=~s/var\./subsp./){
		if($taxon{$name}){
			print ERR <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
		}
		else{
			print ERR <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped $Label_ID_no
EOP
		++$needed_name{$on};
next RECORD;
		}
	}
	else{
		print ERR <<EOP;

Not yet entered into SMASCH taxon name table: $name skipped $Label_ID_no
EOP
		++$needed_name{$on};
	next RECORD;
	}
}
else{
}
#print "$name\n\n";
			unless($name=~/[A-Za-z]/){
		print ERR<<EOP;
No taxon name: $line
EOP
		next RECORD;
}


	if($Collector){
		$Collector=~s/^ +//;
		$Collector=~s/\// -- /g;
		$Collector=~s/\.(AND|and|&) /. -- /g;
		$Collector=~s/ (AND|and|&) / -- /g;
		$Collector=~s/ ?- ?- ?/\n/g;
		@collectors=split(/\n+/,$Collector);
		foreach(@collectors){
			s/([A-Z])([A-Z]+)/$1\L$2/g;
			s/(.*), *(.*)/$2 $1/;
s/Moncrief, V./V. Moncrief/;
s/Sharsmith, Carl W\.?/Carl W. Sharsmith/;
s/Carl W. Sharxmith/Carl W. Sharsmith/;
s/Carlk W. Sharsmith/Carl W. Sharsmith/;
s/A. Hambecker/A. Hawbecker/;
s/B.O. Schrieber/B.O. Schreiber/;
s/B.O. Shreiber/B.O. Schreiber/;
s/Beryl O Schreiber/Beryl O. Schreiber/;
s/E. Micahel/E. Michael/;
s/E. Micheal/E. Michael/;
s/E. Michaels/E. Michael/;
s/Enid Mciahel/Enid Michael/;
s/Enid Mcihael/Enid Michael/;
s/Wnid Michael/Enid Michael/;
s/H. Willilams/H. Williams/;
s/H. Willilams/H. Williams/;
s/Michael Enid/Enid Michael/;
s/Schreiber Beryl O./Beryl O. Schreiber/;
s/V. Moncreif/V. Moncrief/;
s/W. Augusine/W. Augustine/;
s/W.B. Agustine/W.B. Augustine/;
s/W.B. Augsutine/W.B. Augustine/;
s/W.B. Ausgustine/W.B. Augustine/;
		}
		$Combined_Collectors=join(", ", @collectors);
		$Collector=$collectors[0];
	}
else{
		@collectors=();
		$Combined_Collectors="";
}
	$Elevation=~s/^(NONE|NOT ?GIVEN|NOT ?PROVIDED|NOT ?RECORDED|Not ?[pP]rovided|Not ?[rR]ecorded).*//;
	$Elevation=~s/ *meters?/ m/i;
	$Elevation=~s/ *m\.?/ m/i;
	$Elevation=~s/ *feet/ ft/i;
	$Elevation=~s/ *ft\.?/ ft/i;
	$Elevation=~s/^C(\d)/ca. $1/;
	$Elevation=~s/,//g;
#print " Elev-> $Elevation\n";
#next;
$elev_test=$Elevation;
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

			if($elev_test > $max_elev{$County}){
				print ERR "$Catalog_id\t$County\t ELEV: $elevation $metric greater than max: $max_elev{$fields[31]} discrepancy=", $elev_test-$max_elev{$fields[31]},"\n";
			}
		}




	if($UTM_Z_E_N){
	if($UTM_Z_E_N=~m !/(\d\d\d\d\d\d+)\/(\d\d\d\d\d+)!){
		use Geo::Coordinates::UTM;
		$easting=$1;
		$northing=$2;
		$ellipsoid=23;
		$zone="11N";
		if($UTM_Z_E_N=~/9|10|11|12/ && $easting=~/\d\d\d\d\d\d/ && $northing=~/\d\d\d\d\d/){
			($decimal_lat,$decimal_long)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
			print NOERR <<EOP;
			$Catalog_id
			$decimal_lat, $decimal_long
			E->$easting
			N->$northing
			$Lat_LongN_W
EOP
		}
		else{
			print "$Catalog_id UTM problem $zone $easting $northing\n";
		}


		$decimal_long="-$decimal_long" if $decimal_long > 0;
	}  
}
else{
		$decimal_long=$decimal_lat="";
}


if ($decimal_lat){
if ($decimal_lat < 32.5 || $decimal_lat > 42.1){
print ERR "Latitude $decimal_lat outside CA box; $UTM_Z_E_N lat and long nulled: $Catalog_id\n";
$decimal_lat="";
$decimal_long="";
}
}
if ($decimal_long){
if ($decimal_long > -114.0 || $decimal_long < -124.5){
print ERR "Longitude $decimal_long outside CA box; $UTM_Z_E_N lat and long nulled: $Catalog_id\n";
$decimal_long="";
$decimal_lat="";
}
}



if($Locality=~s/Datum: NAD83\.//i){
$datum="NAD83";
}
if($Locality=~s/GPS Error: ([0-9.]+) [Mmetrs.]+//){
$error=$1;
$units="m";
}
else{
$error="";
$units="";
}
if($Collection_Date){
$Collection_Date=~s/^([A-Z][a-z][a-z])-(\d\d)/$monthno{$1}\/19$2/;
$Collection_Date=~s/^0//;
$Collection_Date=~s/\/ /\//;
$Collection_Date=~s/^-+//;
unless($Collection_Date =~m!^(\d+/\d+/[21][089]\d\d|[12][098]\d\d-\d\d\d\d|[12]\d\d\d|\d+/[12][890]\d\d)$!){
print ERR "Bad date nulled $Collection_Date $line";
$Collection_Date="";
}
}


$name=~s/ +/ /g;
#next unless ($name=~/(Cypripedium montanum|Platanthera yosemitensis)/);
#foreach $field (0 .. 43){
#if(length($fields[$field]) > 1){
#print OUT "$field: $fields[$field]\n";
#}
#}
if($name=~/(Cypripedium montanum|Platanthera yosemitensis)/){
print ERR "Sensitive location redaction $Catalog_id\n";
$Locality="";
$UTM="";
$decimal_lat="";
$decimal_long="";
#$CNUM= $CNUM_prefix= $CNUM_suffix="";
#$Collection_Date=~s/.*([12]\d\d\d).*/$1/;
}
print OUT <<EOP;
Accession_id: $Catalog_id
Date: $Collection_Date
Name: $name
Collector: $Collector
Combined_collector: $Combined_Collectors
CNUM: $CNUM
CNUM_prefix: $CNUM_prefix
CNUM_suffix: $CNUM_suffix
Location: $Locality
Elevation: $Elevation
Habitat: $Habitat
Associated_species: $Assoc_Spec
County: $County
State: $State
UTM: $UTM_Z_E_N
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Notes: $fields[13]
Datum: $datum
Max_error_distance: $error
Max_error_units: $units
Annotation:

EOP
}

open(OUT, ">YOSE_badname") || die;
foreach (sort(keys(%needed_name))){
print OUT "$_: $needed_name{$_}\n";
}
sub strip_name{
local($_) = @_;

s/ +/ /g;
s/Hook\. f./Hook./g;
s/Rech\. f./Rech./g;
s/Schult\. f./Schult./g;
s/Schultes f./Schultes/g;
#Name: Quercus ×macdonaldii Greene
s/^([A-Z][A-Za-z]+) (X?[-a-z]+).*(subsp\.|ssp\.|var\.|f\.) ([-a-z]+).*/$1 $2 $3 $4/ ||
s/^([A-Z][A-Za-z]+) × ?([-a-z]+) .+/$1 × $2/||
s/^([A-Z][A-Za-z]+) × ?([-a-z]+)/$1 × $2/||
s/^([A-Z][A-Za-z]+) (X?[-a-z]+) .+/$1 $2/||
s/^([A-Z][A-Za-z]+) (indet\.|sp\.)/$1 indet./||
s/^([A-Z][A-Za-z]+) (X?[-a-z]+)/$1 $2/||
s/^([A-Z][A-Za-z]+) (.+)/$1/;
s/ssp\./subsp./;
s/ +$//;
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
59.	Unknown	Mount Whitney	14,495 	Sequoia Sierra Nevada
