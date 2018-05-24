#parse_sd.pl
open(OUT, ">SD_out_new") || die;
open(IN,"SD_non_vasc") || die;
while(<IN>){
	chomp;
	$ignore_name{$_}++;
}
foreach(sort(keys(%ignore_name))){
print " ignore $_\n";
}
#open(IN,"SD_alter_coll") || die;
#while(<IN>){
	#chomp;
	#s/\cJ//;
	#s/\cM//;
	#next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	#$alter_coll{$rsa}=$smasch;
#}
open(IN,"SD_alter_name") || die "SD alter names wont open\n";
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(IN,"../CDL/alter_names") || die "CDL alter names wont open\n";
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(IN,"collectors_id") || die "coll name wont open\n";
while(<IN>){
	chomp;
	($name,$id)=split(/\t/);
	$COLL{$name}=$id;
}
open(IN,"/Users/jfp04/CDL_buffer/buffer/tnoan.out") || die "tnoan wont open\n";
while(<IN>){
	chomp;
	($id,$name)=split(/\t/);
	$taxon{$name}=$id;
}
open(ERR,">SD_error");
    use Text::CSV;
    #my $file = 'UC_Consortium.txt';
    my $file = 'data_in/test';
    #my $file = 'data_in/SD.in';
    #my $csv = Text::CSV->new();
	my $csv = Text::CSV->new({binary => 1});
    open (CSV, "<", $file) or die $!;
#$/="\015\012";

    while (<CSV>) {
		chomp;
		s/\cK/ /g;
		s/\t/ /g;
        if ($. == 1){
			next;
		}
        if ($csv->parse($_)) {
            my @columns = $csv->fields();
            #my @columns = split(/\t/,$_,1000);
			grep(s/ *$//,@columns);
			grep(s/^N\/A$//,@columns);
        	if ($#columns !=27){
				&skip("Not 28 fields", @columns);
				warn "bad record $#columns not 28  $_\n";
				next;
			}
			if($duplicate{$columns[5]}++){
				&skip("Duplicate", @columns);
				warn "Duplicate $columns[5]";
				next;
			}
(
$DATE,
$NUMBER,
$PREFIX,
$SUFFIX,
$name,
$ACCESSNO,
$Country,
$STATE,
$LOCALITY,
$TRS,
$DISTRICT,
$elevation,
$collector,
$combined_collector,
$HABDESCR,
$macromorphology,
$Description,
$Vegetation,
$latitude,
$longitude,
$decimal_latitude,
$decimal_longitude,
$datum,
$extent,
$ExtUnits,
$UTM,
$notes,
$determiner
)=@columns;
$hybrid_annotation="";
$annotation="";
$extent="" unless $ExtUnits;
		unless($ACCESSNO){
			&skip("No accession id", @columns);
		}
		unless($STATE=~/^(CA|Calif)/i){
			&skip("Extra CA record $ACCESION: $STATE");
		}
		if ($DISTRICT=~/^N\/?A$/i){
			$DISTRICT="unknown"
		}
		elsif ($DISTRICT=~/N\/?A/i){
			#print "$ACCESSNO $DISTRICT\n";
		}
		foreach($DISTRICT){
			s/Eldorado/El Dorado/;
		}
		unless($DISTRICT=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|unknown)/i){
			&log("County set to unknown: $ACCESSNO $DISTRICT");
			$DISTRICT="Unknown";
		}
				if($name=~s/^([A-Z][a-z]+ [a-z]+) (ssp\.|subsp\.) [a-z]+ var\. ([a-z]+)/$1 var. $3/){
					&log("$name: quadrinomial converted $ACCESSNO");
				}
				if($name=~s/^([A-Z][a-z]+ [a-z]+) (ssp\.|subsp\.) [a-z]+ ([a-z]+)/$1 var. $3/){
					&log("$name: quadrinomial converted $ACCESSNO");
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
			if($alter{$name}){
				&log ("Spelling altered to $alter{$name}: $name");
				$name=$alter{$name};
			}
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
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			if($name=~/([A-Z][a-z-]+ [a-z-]+ var. [a-z-]+) × /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
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
$elevation="" if $elevation=~/N\/?A/i;
$TRS="" if $TRS=~s/NoTRS//i;
$notes="" if $notes=~/^None$/;
if($elevation && ($elevation > 15000 || $elevation < -1000)){
&log("Elevation set to null: $ACCESSNO: $elevation");
$elevation="";
}
$elevation= "$elevation ft" if $elevation;
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
if($collector){
$combined_collector= "$collector, $combined_collector";
}
else{
$collector=$combined_collector;
$combined_collector= "";
}
}
else{
$combined_collector="";
}
$badcoll{$collector}++ unless $COLL{$collector};
$badcoll{$combined_collector}++ unless $COLL{$combined_collector};
if($NUMBER || $PREFIX || $SUFFIX){
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

if($determiner){
if($determiner=~m/(.*), *(.*)/){
    $annotation="$name; $1; $2";
	}
elsif($determiner=~m/(.+)/){
    $annotation="$name; $1";
}
	else{
	    $annotation="";
		}
	}


foreach($DATE){
s/.*0000.*//;
s/.*year.*//i;
s/Unknown//i;
s/ *$//;
}
++$count_record;
warn "$count_record\n" unless $count_record % 5000;
            print OUT <<EOP;
Date: $DATE
CNUM: $NUMBER
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Name: $name
Accession_id: $ACCESSNO
Country: USA
State: California
County: $DISTRICT
Location: $LOCALITY
T/R/Section: $TRS
Elevation: $elevation
Collector: $collector
Other_coll: 
Combined_collector: $combined_collector
Habitat: $HABDESCR
Associated_species: $Vegetation
Color: $Description
Macromorphology: $macromorphology
Latitude: $latitude
Longitude: $longitude
Decimal_latitude: $decimal_latitude
Decimal_longitude: $decimal_longitude
UTM: $UTM
Notes: $notes
Datum: $datum
Max_error_distance: $extent
Max_error_units: $ExtUnits
Annotation: $annotation
Hybrid_annotation: $hybrid_annotation

EOP
        } else {
            my $err = $csv->error_input;
            print ERR "Failed to parse line: $err";
        }
    }
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
