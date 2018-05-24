#parse_nybg.pl


#out of state specimens to check and skip:
# NY345833 NY342324 NY337165 NY1043449
 
 
 
open(IN,"Users/rlmoe/data/CDL/riv_non_vasc") || die;
while(<IN>){
	chomp;
	if(m/\cM/){
	die;
	}
	$exclude{$_}++;
}
open(IN,"NY_AdditionalNames.csv") || die;
while(<IN>){
chomp;
#print "\n$_\n";
s/"//g;
($irn,	$DeterminationDate,	$FiledAsName,	$Determinations)=split(/\t/);
if($FiledAsName=~/^Yes$/){
next;
}
else{
@det_date=split(/;/,$DeterminationDate);
@FA_name=split(/;/,$FiledAsName);
@dets=split(/;/,$Determinations);
foreach $det_no (1 .. $#dets){
if($dets[$det_no] !~ $dets[$det_no -1]){
foreach $i (0 .. $#FA_name){
$store_anno{$irn}.="Annotation: $dets[$i];;$det_date[$i]\n";
}
#++$count;
last;
}
}
}
}
#foreach(sort(keys(%store_anno))){
#print $store_anno{$_};
#}
#print "$count\n";

open(OUT, ">NY.out") || die;
open(IN,"ny_alters") || die "SD alter names wont open\n";
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
open(IN,"/Users/rlmoe/CDL_buffer/buffer/tnoan.out") || die "tnoan wont open\n";
while(<IN>){
	chomp;
	($id,$name)=split(/\t/);
	$taxon{$name}=$id;
}
open(ERR,">NYBG_error");
    use Text::CSV;
    my $file = 'CaliforniaVascular.txt';
	my $csv = Text::CSV->new({binary => 1});
    open (CSV, "<", $file) or die $!;

    while (<CSV>) {
$DATE= $NUMBER= $PREFIX= $SUFFIX= $name= $ACCESSNO= $DISTRICT= $LOCALITY= $TRS= $elevation= $collector= $combined_collector= $HABDESCR= $Vegetation= $Description= $macromorphology= $latitude= $longitude= $decimal_latitude= $decimal_longitude= $UTM= $notes= $datum= $extent= $ExtUnits= $anno_string= $hybrid_annotation= $TypeStatus="";
		chomp;
		s/\cK/ /g;
		s/\t/ /g;
        if ($. == 1){
			next;
		}
        if ($csv->parse($_)) {
            my @columns = $csv->fields();
			#print "$#columns\n";
			#next;
            #my @columns = split(/\t/,$_,1000);
			grep(s/ *$//,@columns);
			grep(s/^N\/A$//,@columns);
        	if ($#columns !=52){
				&skip("Not 52 fields", @columns);
				warn "bad record $#columns not 52  $_\n";
				next;
			}
			if($duplicate{$columns[3]}++){
				&skip("Duplicate", @columns);
				warn "Duplicate $columns[3]";
				next;
			}
			#foreach $i (0 .. $#columns){
			#print "$i $columns[$i]\n";
			#}
			#next;
($DateLastModified, $InstitutionCode, $CollectionCode, $CatalogNumber, $ScientificName, $BasisOfRecord,
$Kingdom, $Phylum, $Class, $Order, $Family, $Genus, $Species, $Subspecies, $ScientificNameAuthor,
$IdentifiedBy, $YearIdentified, $MonthIdentified, $DayIdentified,
$TypeStatus,
$CollectorNumber, $FieldNumber, $Collector, $YearCollected, $MonthCollected, $DayCollected, $JulianDay, $TimeOfDay,
$ContinentOcean, $Country, $StateProvince, $County,
$Locality,
$Longitude, $Latitude, $CoordinatePrecision, $DarBoundingBox, $MinimumElevation, $MaximumElevation,
$MinimumDepth, $MaximumDepth, $Sex, $PreparationType, $IndividualCount, $PreviousCatalogNumber, $RelationshipType, $RelatedCatalogItem,
$Notes, $Habitat, $PlantDescription, $Substrate, $Vegetation,
$irn)=@columns;
$DATE="$MonthCollected $DayCollected $YearCollected";
#print "$FieldNumber\n" if $FieldNumber;
$NUMBER=$FieldNumber; $PREFIX=$SUFFIX="";
foreach($NUMBER){
s/ *$//;
s/^ *//;
if(m/^(\d+)$/){
;;
}
elsif( s/^([^\d]+)(\d+)(.*)/$2/){
$PREFIX=$1; $SUFFIX=$3
}
elsif( s/^(\d+[^\d]+)(\d+)(.*)/$2/){
$PREFIX=$1; $SUFFIX=$3
}
elsif( s/^(\d+)(.*)/$1/){
$PREFIX=""; $SUFFIX=$2
}
elsif( s/^(.+[^\d])(\d+)$/$2/){
$PREFIX="$1"; $SUFFIX="";
}
else{
$PREFIX= $_;
$_="";
}
}
if($ScientificName=~/ (var\.|subsp\.|ssp\.) /){
	$infra=$1;
	$name="$Genus $Species $infra $Subspecies";
$name=~s/ *$//;
}
else{
	$infra="";
	$name="$Genus $Species";
$name=~s/ *$//;
}
$orig_name=$name;
$CatalogNumber=~s/^0+//;
$ACCESSNO=$InstitutionCode . $CatalogNumber;
$Country=$Country;
$STATE=$StateProvince;
$LOCALITY=$Locality;
$TRS="";
($DISTRICT=$County)=~s/ (Co|Co\.|County) *$//i;
if($MaximumElevation > $MinimumElevation){
$elevation= "$MinimumElevation - $MaximumElevation";
}
else{
$elevation= "$MinimumElevation";
}
$combined_collector=$Collector;
$HABDESCR="$Habitat $Substrate";
$macromorphology=$PlantDescription;
$Description="";
$Vegetation=$Vegetation;
$decimal_latitude=$Latitude;
$decimal_longitude=$Longitude;
$datum="";
$extent= $CoordinatePrecision;
$notes=$Notes;
#$determiner="$IdentifiedBy $MonthIdentified/$DayIdentified/$YearIdentified";
if($IdentifiedBy){
	if($YearIdentified){
		$id_date="$MonthIdentified-$DayIdentified-$YearIdentified";
	}
	else{
		$id_date="";
	}
$determiner="$IdentifiedBy; $id_date";
}
else{
$determiner="";
}



$hybrid_annotation="";
$annotation="";
#$extent="" unless $ExtUnits;
		unless($ACCESSNO){
			&skip("No accession id", @columns);
		}
		if($PlantDescription=~/Cultivated/){
			&skip("Cultivated plant record $ACCESSNO: $name");
		next;
		}
		if($LOCALITY=~/(Arboretum|Botanical Garden|Botanic Garden)/){
			&skip("Cultivated plant record $ACCESSNO: $name $LOCALITY");
		next;
		}
		if($Habitat=~/Cultivated/){
			&skip("Cultivated plant record $ACCESSNO: $name");
		next;
		}
		if($LOCALITY=~/(Lower California|Baja California|Mexico)/){
			&skip("Not California plant record (mexico?) $ACCESSNO: $name");
		next;
		}
		unless($STATE=~/^(CA|Calif)/i){
			&skip("Extra CA record $ACCESSNO: $STATE");
			next;
		}
		if ($DISTRICT=~/^N\/?A$/i){
			$DISTRICT="unknown"
		}
		elsif ($DISTRICT=~/^ *$/i){
			$DISTRICT="unknown"
		}
		elsif ($DISTRICT=~/N\/?A/i){
			#print "$ACCESSNO $DISTRICT\n";
		}
		foreach($DISTRICT){
			s/Eldorado/El Dorado/;
		}
		unless($DISTRICT=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown)/i){
			&skip("Non-California county: $ACCESSNO $DISTRICT");
			next;
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
			if($exclude{$genus}){
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
						++$badname{$on};
						next;
					}
				}
				elsif($name=~s/var\./subsp./){
		if($taxon{$name}){
&log("Not yet entered into SMASCH taxon name table: $on entered as $name");
		}
		else{
&skip("Not yet entered into SMASCH taxon name table: $on skipped");
++$badname{$on};
next;
		}
	}
	else{
&skip("Not yet entered into SMASCH taxon name table: $on skipped");
++$badname{$on};
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
if($elevation && ($elevation > 5000 || $elevation < -300)){
&log("Elevation set to null: $ACCESSNO: $elevation");
$elevation="";
}
$elevation= "$elevation m" if $elevation;
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

@anno=();
if($determiner){
	push(@anno,"Annotation: $name; $determiner");
}
foreach(split(/ *\n+/,$store_anno{$irn})){
	push(@anno,"$_") if length($_) > 4;
}

if(@anno){
 $anno_string="";
 #print "\n1 ", @anno, "\n";
	foreach(@anno){
	#print "2 $_\n";
		s/^ *//;
		s/ *\n//;
		$anno_string.="$_\n";
	}
	$anno_string=~s/\n+$//;
#print "3 $anno_string\n\n";
}
else{
$anno_string="Annotation: ";
}

foreach($DATE){
s/.*0000.*//;
s/.*year.*//i;
s/Unknown//i;
s/ *$//;
}
++$count_record;
warn "$count_record\n" unless $count_record % 5000;
			#print "$NUMBER\n" if $NUMBER;
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
$anno_string
Hybrid_annotation: $hybrid_annotation
Type_status: $TypeStatus

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
__END__

$DateLastModified,
$InstitutionCode,
$CollectionCode,
$CatalogNumber,
$ScientificName,
$BasisOfRecord,
$Kingdom,
$Phylum,
$Class,
$Order,
$Family,
$Genus,
$Species,
$Subspecies,
$ScientificNameAuthor,
$IdentifiedBy,
$YearIdentified,
$MonthIdentified,
$DayIdentified,
$TypeStatus,
$CollectorNumber,
$FieldNumber,
$Collector,
$YearCollected,
$MonthCollected,
$DayCollected,
$JulianDay,
$TimeOfDay,
$ContinentOcean,
$Country,
$StateProvince,
$County,
$Locality,
$Longitude,
$Latitude,
$CoordinatePrecision,
$DarBoundingBox,
$MinimumElevation,
$MaximumElevation,
$MinimumDepth,
$MaximumDepth,
$Sex,
$PreparationType,
$IndividualCount,
$PreviousCatalogNumber,
$RelationshipType,
$RelatedCatalogItem,
$Notes,
$Habitat,
$PlantDescription,
$Substrate,
$Vegetation,
$irn

