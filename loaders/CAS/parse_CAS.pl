#"Herbarium","AccessionNo","AccNoSuffix","Taxon","Collectors","StartDate","CollNumber","County","Locality","Locality continued","Habitat","Description","Geo Township","Geo Range","Geo Section","Latitude1","Longitude1","LatLong Method","Notes","Elev Min","Elev Max","Elev Units"
#($Herbarium, $AccessionNo, $AccNoSuffix, $Taxon, $Collectors, $StartDate, $CollNumber, $County, $Locality, $Locality continued, $Habitat, $Description, $Geo Township, $Geo Range, $Geo Section, $Latitude1, $Longitude1, $LatLong Method, $Notes)=

open(OUT, ">new_CAS") || die;
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
#open(IN,"../San_Diego/collectors_id") || die;
#while(<IN>){
	#chomp;
	#($name,$id)=split(/\t/);
	#$COLL{$name}=$id;
#}
open(IN,"../CDL/tnoan.out") || die;
while(<IN>){
	chomp;
	($id,$name)=split(/\t/);
	$taxon{$name}=$id;
}
open(ERR,">CAS_error");
    use Text::CSV;
$version = Text::CSV->version();
print $version,"\n\n";
    #my $file = 'SpecifyExport_CA.txt';
    my $file = 'CAS_linefeed.txt';
    my $csv = Text::CSV->new();
    open (CSV, "<", $file) or die $!;

    while (<CSV>) {
$elevation="";
		chomp;
		s/\cK/ /g;
		s/\t/ /g;
s/\^//g;
        if ($csv->parse($_)) {
            my @columns = $csv->fields();
			grep(s/ *$//,@columns);
        	if ($#columns !=21){
				&skip("Not 22 fields", @columns);
				warn "bad record $#columns not 21  $_\n";
				next;
			}
($Herbarium, $AccessionNo, $AccNoSuffix, $name, $Collectors, $DATE, $CollNumber, $County, $Locality, $Locality_continued, $Habitat, $Description, $Geo_Township, $Geo_Range, $Geo_Section, $Latitude1, $Longitude1, $LatLong_Method, $Notes,$elev_min,$elev_max, $elev_units)=@columns;
if($seen{$Herbarium . $AccessionNo .$AccNoSuffix}++){
				&skip("Duplicate record", @columns);
				warn "Duplicate record  $_\n";
				next;
}
$extent="" unless $ExtUnits;
$Geo_Township=~s/T//;
$Geo_Range=~s/R//;
$TRS="$Geo_Township$Geo_Range$Geo_Section";
($decimal_latitude=$Latitude1)=~s/[^0-9.-]//g;
($decimal_longitude=$Longitude1)=~s/[^0-9.-]//g;
#foreach $i ( 0 .. $#columns){
#print "$i $columns[$i]\n";
#}
#next;
		$ACCESSNO="$Herbarium$AccessionNo$AccNoSuffix";
		@collectors=();
		$collector="";
		if($Collectors){
		@collectors=split(/; /,$Collectors);
		foreach(@collectors){
		s/(.*), (.*)/$2 $1/;
		}
		$collector=$collectors[0];
		if($#collectors >0){
		$other_coll=join(", ", @collectors[1 .. $#collectors]);
		$combined_collector=join(", ", @collectors);
		}
		else{
		$combined_collector="";
		}
		}

		unless($ACCESSNO){
			&skip("No accession id", @columns);
		}

		if ($County=~/^N\/?A$/i){
			$County="unknown"
		}
		elsif ($County=~/N\/?A/i){
			#print "$ACCESSNO $County\n";
		}
		unless($County=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|unknown)/i){
			&log("County set to unknown: $ACCESSNO $County");
			$County="Unknown";
		}
		$name="" if $name=~/^No name$/i;
			unless($name){
				&skip("No name: $ACCESSNO", @columns);
				next;
			}
			($genus=$name)=~s/ .*//;
			if($ignore_name{$genus}){
				&skip("Non-vascular plant: $ACCESSNO", @columns);
				next;
			}
			$name=ucfirst($name);
			if($name=~/  /){
				if($name=~/^[A-Z][a-z]+ [a-z]+ +[a-z]+$/){
					&log("$name: var. added $ACCESSNO");
					$name=~s/^([A-Z][a-z]+ [a-z]+) +([a-z]+)$/$1 var. $2/;
				}
				$name=~s/  */ /g;
			}
			if($name=~/CV\.? /i){
				&skip("Can't deal with cultivars yet: $ACCESSNO", $name);
				#$badname{$name}++;
				next;
			}
			foreach($name){
				s/ ssp / subsp. /;
				s/ spp\.? / subsp. /;
				s/ var / var. /;
				s/ ssp\. / subsp. /;
				s/ f / f\. /;
				s/ [xX] / × /;
			}
			if($name=~/([A-Z][a-z-]+ [a-z-]+) × /){
				$annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			else{
				$annotation="";
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
						&skip("Not yet entered into SMASCH taxon name table: $on skipped");
						++$badname{$name};
						next;
					}
				}
				elsif($name=~s/var\./subsp./){
		if($taxon{$name}){
&log("Not yet entered into SMASCH taxon name table: $on entered as $name");
		}
		else{
&skip("Not yet entered into SMASCH taxon name table: $on skipped");
++$badname{$name};
next;
		}
	}
	else{
&skip("Not yet entered into SMASCH taxon name table: $on skipped");
++$badname{$name};
	next;
	}
}

#unless($taxon{$name}){
#&skip("$name not in SMASCH, skipped: $ACCESSNO");
#$badname{$name}++;
#next;
#}
$TRS="" if $TRS=~s/NoTRS//i;
$notes="" if $Notes=~/^None$/;
$elev_max=~s/\.00//;
$elev_min=~s/\.00//;
if($elev_min && $elev_max && ($elev_max > $elev_min)){
$elevation="$elev_min-$elev_max $elev_units";
}
elsif($elev_min){
$elevation="$elev_min $elev_units";
}
elsif($elev_max){
$elevation="$elev_max $elev_units";
}
#if($elevation && ($elevation > 15000 || $elevation < -1000)){
#&log("Elevation set to null: $ACCESSNO: $elevation");
#$elevation="";
#}
#$elevation= "$elevation ft" if $elevation;
$elevation="" unless $elevation;
$collector= "" unless $collector;
$collector= "" if $collector=~/^None$/i;
$collector=~s/^ *//;
$collector=~s/  +/ /g;
$collector=~s/([A-Z]\.)([A-Z]\.)([A-Z][a-z])/$1 $2 $3/g;
$collector=~s/([A-Z]\.)([A-Z]\.) ([A-Z][a-z])/$1 $2 $3/g;
		$collector= $alter_coll{$collector} if $alter_coll{$collector};
if($combined_collector){
	$combined_collector=~s/et al$/et al./;
	$combined_collector=~s/([A-Z]\.)([A-Z]\.)([A-Z][a-z])/$1 $2 $3/g;
	$combined_collector=~s/([A-Z]\.)([A-Z]\.) ([A-Z][a-z])/$1 $2 $3/g;
	$combined_collector=~s/([A-Z]\.)([A-Z][a-z])/$1 $2/g;
	$combined_collector=~s/  +/ /g;
		$combined_collector= $alter_coll{$combined_collector} if $alter_coll{$combined_collector};
}
else{
$combined_collector="";
$other_coll="";
}
$badcoll{$collector}++ unless $COLL{$collector};
$badcoll{$combined_collector}++ unless $COLL{$combined_collector};
if($CollNumber){
$collector= "Anonymous" unless $collector;
}
if(($decimal_latitude==0  || $decimal_longitude==0)){
$decimal_latitude =$decimal_longitude="";
}
if(($decimal_latitude=~/\d/  || $decimal_longitude=~/\d/)){
$decimal_longitude="-$decimal_longitude" if $decimal_longitude > 0;
if($decimal_latitude > 42.1 || $decimal_latitude < 32.5 || $decimal_longitude > -114 || $decimal_longitude < -124.5){
&log("coordinates set to null, Outside California: $ACCESSNO: >$decimal_latitude< >$decimal_longitude< $latitude $longitude");
$decimal_latitude =$decimal_longitude="";
}
}
$datum="" if $datum=~/^Unk$/i;
#$LOCALITY=~s/^"(.*)"$/$1/;
#$HABDESCR=~s/^"(.*)"$/$1/;
foreach($DATE){
s/^00//;
s/__//;
s/Unknown//i;
s/ *$//;
}
$PREFIX= $CNUM= $SUFFIX="";
foreach($CollNumber){
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
++$count_record;
warn "$count_record\n" unless $count_record % 5000;
#($Herbarium, $AccessionNo, $AccNoSuffix, $name, $Collectors, $DATE, $CollNumber, $County, $Locality, $Locality_continued, $Habitat, $Description, $Geo_Township, $Geo_Range, $Geo_Section, $Latitude1, $Longitude1, $LatLong_Method, $Notes)=@columns;
if($Description=~s/(Fl.*(white|maroon|green|cream|yellow|red|blue|purple|orange|pink|lavender).*)//){
$color=$1;
}
else{
$color="";
}
if($Habitat=~m/ (with .*)/){
$Associates=$1;
}
else{
$Associates="";
}

            print OUT <<EOP;
Date: $DATE
CNUM: $CNUM
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Name: $name
Accession_id: $ACCESSNO
Country: USA
State: California
County: $County
Location: $Locality $Locality_continued
T/R/Section: $TRS
Collector: $collector
Other_coll: $other_coll
Combined_collector: $combined_collector
Habitat: $Habitat
Associated_species: $Associates
Color: $color
Macromorphology: $Description
Latitude: $latitude
Longitude: $longitude
Decimal_latitude: $decimal_latitude
Decimal_longitude: $decimal_longitude
UTM: $UTM
Notes: $Notes
Source: $LatLong_Method
Datum: $datum
Elevation: $elevation
Max_error_distance: $extent
Max_error_units: $ExtUnits
Hybrid_annotation: $annotation

EOP
        } else {
            my $err = $csv->error_input;
            print ERR "Failed to parse line: $err";
        }
    }
	#die;
warn "$count_record\n";
    close CSV;

open(OUT,">CSV_badcoll") || die;
foreach(sort(keys(%badcoll))){
print OUT "$_: $badcoll{$_}\n";
}
open(OUT,">CSV_badname") || die;
foreach(sort(keys(%badname))){
print OUT "$_: $badname{$_}\n";
}
sub skip {
print ERR "skipping: @_\n"
}
sub log {
print ERR "logging: @_\n";
}
