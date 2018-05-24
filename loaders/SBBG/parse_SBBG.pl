
#parse_sbbg_export: alternate xml labels
@sggb_precision=(0, 10, 100, 1000, 10000);
open(OUT,">sbbg_problem");
open(IN,"../CDL/collectors_id") || die;
while(<IN>){
chomp;
s/\t.*//;
$coll_comm{$_}++;
}
open(IN,"/Users/richardmoe/4_data/taxon_ids/smasch_taxon_ids.txt") || die;
while(<IN>){
chomp;
($id,$name,@residue)=split(/\t/);
$taxon{$name}++;
}
open(IN,"../CDL/riv_non_vasc") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}
open(IN,"../CDL/alter_names") || die;
while(<IN>){
	next if m/^#/;
	chomp;
s/\cJ//;
s/\cM//;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
#open(IN,"rsa_alter_names") || die;
#while(<IN>){
	#chomp;
	#next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	#$alter{$riv}=$smasch;
#}
open(IN,"sbbg_alter_coll") || die;
while(<IN>){
	chomp;
s/\cJ//;
s/\cM//;
	next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	$alter_coll{$rsa}=$smasch;
}
#open(IN,"rsa_alter_coll") || die;
#while(<IN>){
	#chomp;
#s/\cJ//;
#s/\cM//;
	#next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	#$alter_coll{$rsa}=$smasch;
#}
#open(IN,"riv_alter_coll") || die;
#while(<IN>){
	#chomp;
#s/\cJ//;
#s/\cM//;
	#next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	#$alter_coll{$rsa}=$smasch;
#}
#$/=qq{<SBBGexport>};
#$/=qq{<SBBG8202009>};
$/=qq{<_x0033__x002F_31_x002F_2011export>};

#open(IN,"SBBG3_31_2011export.xml") || die;
$/="";
open(IN,"new_sbbg_export") || die;
#open(IN,"SBBG8202009.xml") || die;
while(<IN>){
s/\cM/ /g;
#s/\n/ /g;
s/&apos;/'/g;
s/  +/ /g;
s/&amp;/&/g;
$Mt_Whitney="4420";
$Death_Valley="-90";

$Accession_id=
$County=
$U_id=
$anno=
$assignor=
$collector =
$collector_number =
$combined_collector=
$date=
$datum=
$day =
$elev_ft =
$elev_m =
$elevation=
$habitat=
$lat_long_ref_source=
$latitude =
$loc_other=
$locality=
$longitude =
$max_error_distance=
$max_error_units=
$month =
$name=
$precision=
$source=
$year =
$CNUM_PREFIX =
$CNUM_SUFFIX =
"";


	($name)=m|<Search_x0020_Name>(.*)</Search_x0020_Name>|;
#                     <Accession_x0020_Number>323</Accession_x0020_Number>
	($Accession_id)=m|<acc_num>(.*)</acc_num>|;
	($county)=m|<county_name>(.*)</county_name>|;
	($loc_other)=m|<ter_name>(.*)</ter_name>|;
	($locality)=m|<local_txt>(.*)</local_txt>|;
	($elev_ft)=m|<elevft_num>(.*)</elevft_num>|;
	($elev_m)= m|<elevm_num>(.*)</elevm_num>|;
	($latitude)=m|<lat_num>(.*)</lat_num>|;
	($longitude)=m|<long_num>(.*)</long_num>|;
	($collector)=m|<coll1_txt>(.*)</coll1_txt>|;
	($collector_number)=m|<coll_num_txt>(.*)</coll_num_txt>|;
unless ($collector_number=~/^\d+$/){
 if($collector_number=~s/^([0-9]+)-([0-9]+)([A-Za-z]*)/$2/){
                $CNUM_PREFIX=$1;
                $CNUM_SUFFIX=$3;
        }
 if($collector_number=~s/^([A-Z]*[0-9]+)-([0-9]+)([A-Za-z]+)/$2/){
                $CNUM_PREFIX=$1;
                $CNUM_SUFFIX=$3;
        }
        if($collector_number=~s/^([A-Z]*[0-9]+-)([0-9]+)(-.*)/$2/){
                $CNUM_PREFIX=$1;
                $CNUM_SUFFIX=$3;
        }
        if($collector_number=~s/^([^0-9]+)//){
                $CNUM_PREFIX=$1;
        }
        if($collector_number=~s/^(\d+)([^\d].*)/$1/){
                $CNUM_SUFFIX=$2;
        }

                #print <<EOP;
#C: $collnum
#P: $CNUM_PREFIX
#S: $CNUM_SUFFIX
#
#EOP
	}

	($month)=m|<month_sym>(.*)</month_sym>|;
	($day)=m|<day_num>(.*)</day_num>|;
	($year)=m|<year_num>(.*)</year_num>|;
	################NEW
	($habitat)=m|<asp_txt>(.*)</asp_txt>|;
	($precision)=m|<prec_num>(.*)</prec_num>|;
	if($precision=~/^[12345]$/){
		$max_error_distance= $sggb_precision[$precision];
		$max_error_units="m";
	}
	($datum)=m|<basereference_txt>(.*)</basereference_txt>|;
	($source)=m|<source_txt>(.*)</source_txt>|;
	if(($anno)=m|<Determinor>(.*)</Determinor>|){
	$anno=&process_anno($anno, $name);
	}
	else{
	$anno="";
	}
	##################

$county=&modify_county($county);
$collector=~s/^([A-Z]\.) (and|&) ([A-Z]\.) ([A-Z][a-z]+)/$1 $4, $3 $4/;
$collector=~s/^([A-Z]\. [A-Z]\.) (and|&) ([A-Z]\. [A-Z]\.) ([A-Z][a-z]+)/$1 $4, $3 $4/;
$collector=~s/^([A-Z]\. [A-Z]\.) (and|&) ([A-Z]\.) ([A-Z][a-z]+)/$1 $4, $3 $4/;
$collector=~s/([A-Z]\.)([A-Z][a-z])/$1 $2/g;
$collector=~s/ *$//;
$collector=~s/ +,/,/;
#$collector=&modify_collector($collector);

$Accession_id="SBBG$Accession_id";
if($seen{$Accession_id}++){
	$Accession_id .= ".$seen{$Accession_id}";
}
unless($name){
warn <<EOW;
No name. $Accession_id skipped
EOW
next;
}
$name=&strip_name($name);
$name=ucfirst(lc($name));
$name=~s/'//g;
$name=~s/`//g;
$name=~s/ *$//;
$name=~s/  +/ /g;
$name=~s/ssp\./subsp./;
$name=~s/ indet//;
$name=~s/ [Xx] / X /;
$name=~s/^� ([a-z])/X \u$1/;
			if($name=~/([A-Z][a-z-]+ [a-z-]+) X /){
				$hybrid_annotation=$name;
				warn "$1 from $name\n";
				$name=$1;
			}
			else{
				$hybrid_annotation="";
			}
($genus=$name)=~s/ .*//;
if($exclude{$genus}){
	print OUT <<EOP;

Excluded, not a vascular plant: $name
EOP
		++$skipped{one};
	next;
}
if($alter{$name}){
	print OUT <<EOP;

Spelling altered to $alter{$name}: $name 
EOP
	$name=$alter{$name};
}
unless($taxon{$name}){
	$on=$name;
	if($name=~s/subsp\./var./){
		if($taxon{$name}){
			print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
		}
		else{
	print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped
EOP
		++$skipped{one};
next;
		}
	}
	elsif($name=~s/var\./subsp./){
		if($taxon{$name}){
			print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on entered as $name
EOP
		}
		else{
			print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $on skipped
EOP
		++$skipped{one};
next;
		}
	}
	else{
	print OUT <<EOP;

Not yet entered into SMASCH taxon name table: $name skipped
EOP
		++$skipped{one};
	next;
	}
}

$name{$name}++;

	($assignor=$collector)=~s/ (with|&|and) .*//;
	$assignor=$alter_coll{$assignor} if $alter_coll{$assignor};
	$assignor=~s/, .*//;
	$need_coll{$assignor}++ unless $coll_comm{$assignor};
	unless($assignor eq $collector){
		$combined_collector="$collector";
		$collector=$assignor;
		$combined_collector=~s/,? (with|&|and) /, /g;
		$combined_collector=~s/ (with|&|and) */, /g;
	$combined_collector=$alter_coll{$combined_collector} if $alter_coll{$combined_collector};
	$need_coll{$combined_collector}++ unless $coll_comm{$combined_collector};
	}
else{
$combined_collector="";
}
if(($elev_ft=~/\d/) || ($elev_m =~/\d/)){
	if($elev_m && ($elev_m < $Mt_Whitney) && ($elev_m > $Death_Valley)){
		$elevation= "$elev_m m";
	}
	elsif($elev_ft && ($elev_ft < ($Mt_Whitney * 3.28)) && ($elev_ft > ($Death_Valley * 3.28))){
		$elevation= "$elev_ft ft";
	}
	elsif($elev_ft =~/near sea level/ || $elev_m =~/near sea level/ ){
	$elevation="0";
	}
	else{
		$elevation="";
print OUT <<EOP;
$Accession_id: elevation out of California range: $elev_ft ft, $elev_m m
EOP
	}
}
	if($year=~/^ *[12][0789]\d\d *$/){
		if($month){
		if($month=~/(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)/i){
			$day=~s/^ *//;
			$day=~s/ *$//;
			if($day){
				if(($day > 0) && ($day < 32) && ($day=~m/^\d+$/)){
					$date="$month $day $year";
				}
					
				else{
					$date="$month $year";
warn <<EOP;
$Accession_id: something wrong with date: $day $month $year set to $date 
EOP
print OUT <<EOP;
$Accession_id: something wrong with date: $day $month $year set to $date 
EOP
				}
			}
			else{
				$date="$month $year";
			}
		}
		else{
			$date=$year;
print OUT <<EOP;
$Accession_id: something wrong with date: $day $month $year  set to $date
EOP
		}
		}
	}
	else{
		$date="";
	}
print  <<EOP;
Date: $date
CNUM: $collector_number
CNUM_prefix: $CNUM_PREFIX
CNUM_suffix: $CNUM_SUFFIX
Name: $name
Accession_id: $Accession_id
Country: US
State: California
County: $county
Loc_other: $loc_other
Location: $locality
T/R/Section:
USGS_Quadrangle:
Elevation: $elevation
Collector: $collector
Combined_collector: $combined_collector
Habitat: $habitat
Associated_species: $associated_species
Notes: $notes
Decimal_latitude: $latitude
Decimal_longitude: $longitude
Datum: $datum
Max_error_distance: $max_error_distance
Max_error_units: $max_error_units
Lat_long_ref_source: $source
Annotation: $anno
Hybrid_annotation: $hybrid_annotation

EOP
}
sub modify_county {
local($_)=shift;
#s/Contra CoStanislaus/Stanislaus/;
s/Eldorado/El Dorado/;
s/King$/Kings/;
#s/^MER$/Merced/;
#s/ShaStanislaus/Stanislaus/;
$_;
}
sub modify_collector {
local($_)=shift;
s/(Dr\.)([A-Z])/$1 $2/;
s/(Mrs?\.)([A-Z])/$1 $2/;
s/(Mrs?\.)([A-Z])/$1 $2/;
s/^unk$//;
s/^Unk$//;
s/A. Carter,.B. Kasapligil/A. Carter, B. Kasapligil/;
s/C. Bornsrein/C. Bornstein/;
s/C. Bornsteim/C. Bornstein/;
s/C. Pergler, D. Elias & A. Griffiths/C. Pergler, D. Elias, A. Griffiths/;
s/C. Smith, M. Benedict/C.F. Smith, M.R. Benedict/;
s/C. Steele & C. Miller/C. Steele, C. Miller/;
s/C. ?F. Smithsun/C. F. Smith/;
s/C. ?F. Snith/C.F. Smith/;
s/C. ?f. ?Smith/C.F. Smith/;
s/C. ?f. ?smith/C.F. Smith/;
s/C. ?F. ?smith/C.F. Smith/;
s/C. ?R. Muller/C. ?H. Muller/;
s/D. Kiehns/D. Kiehn/;
s/D. Young, T. Ayer, R. Scott/D. Young, T. Ayers, R. Scott/;
s/D. ?M. Smith, A Flinck/D.M. Smith, A. Flinck/;
s/D. ?M. Smith, A. Fkinck/D.M. Smith, A. Flinck/;
s/D. ?N. Smith, A. Flinck/D.M. Smith, A. Flinck/;
s/E. ?R. Balkley, R. Ornduff/E.R. Blakley, R. Ornduff/;
s/E. ?R. Balls/E.K. Balls/;
s/E. ?R. Blakley & R. Ornduff/E.R. Blakley, R. Ornduff/;
s/E. ?R. Blakley; R. Ornduff/E.R. Blakley, R. Ornduff/;
s/G,Meadows/G. Meadows/;
s/G. ?I. Webster, E. Gedling, K. Milam/G.L. Webster, E. Gedling, K. Milam/;
s/G. ?L. Webster, E. Gedling, K, Milam/G.L. Webster, E. Gedling, K. Milam/;
s/G. ?L. Webster, E. Gedling, K. Milan/G.L. Webster, E. Gedling, K. Milam/;
s/I. ?R. Wiggins/I.L. Wiggins/;
s/J K McPherson/J.K. McPherson/;
s/J R Haller/J.R. Haller/;
s/J. Sainz & C. Bratt/J. Sainz, C. Bratt/;
s/J. Sainz,L. Towle/J. Sainz, L. Towle/;
s/J. Vanderwier & G. Fellers/J. Vanderwier, G. Fellers/;
s/J. ?E. Haller/J.R. Haller/;
s/J. ?K. McPherson, M. ?R.,Benedict/J.K. McPherson, M.R. Benedict/;
s/J. ?K. McPherson, N. ?R. Benedict/J.K. McPherson, M.R. Benedict/;
s/J. ?K. Mcpherson/J.K. McPherson/;
s/J. ?N. McPherson/J.K. McPherson/;
s/K. McEachern, K. Chess & K. Rindlaub/K. McEachern, K. Chess, K. Rindlaub/;
s/K. ?F. Rigola/K.F. Rigoli/;
s/K. ?F. Rigola/K.F. Rigoli/;
s/L. Laughlin/L. Laughrin/;
s/L. ?L. Loeher/L.L. Loehr/;
s/L. ?R. Hechard/L.R. Heckard/;
s/M,R. Benedict, C. ?F. Smith/M.R. Benedict, C.F. Smith/;
s/M,R. Benedict, D. ?W. Ricker/M.R. Benedict, D.W. Ricker/;
s/M,R. Benedict/M. ?R. Benedict/;
s/M. Benedicy, C. ?F. Smith/M. Benedict, C.F. Smith/;
s/M. Carvens/M. Cravens/;
s/M. Carvens/M. Cravens/;
s/M. Hofhberg/M. Hochberg/;
s/M. Maughton/M. Naughton/;
s/M. ?A. Piiehl/M.A. Piehl/;
s/M. ?A. Piiehl/M.A. Piehl/;
s/M. ?B. Donkle/M.B. Dunkle/;
s/M. ?B. Donkle/M.B. Dunkle/;
s/M. ?B. Dukle/M.B. Dunkle/;
s/M. ?R. Benedict,  C. ?F. Smith/M.R. Benedict, C.F. Smith/;
s/M. ?R. Benedict, C. ?F. Smit/M.R. Benedict, C.F. Smith/;
s/M. ?R. Benedict, D. ?W,Ricker/M.R. Benedict, D.W. Ricker/;
s/M. ?R. Benedict, P..W. Shaw/M.R. Benedict, P.W. Shaw/;
s/N. Cale/N. Gale/;
s/R. Phi;brick, M. Hochberg/R. Philbrick, M. Hochberg/;
s/R. Philbrich, M. Hochberg/R. Philbrick, M. Hochberg/;
s/R. ?E. Broder,  M. ?R. Benedict/R.E. Broder, M.R. Benedict/;
s/R. ?E. Broder, M. ?E. Benedict/R.E. Broder, M.R. Benedict/;
s/R. ?E. Broder, N. ?R. Benedict/R.E. Broder, M.R. Benedict/;
s/S. Junak,  R. Scott/S. Junak, R. Scott/;
s/S. Junak, R. Scott, D. Youg/S. Junak, R. Scott, D. Young/;
s/S. Junak, R. Scott,T. Ayers/S. Junak, R. Scott, T. Ayers/;
s/S. Junak, T. Ayer, R. Scott/S. Junak, T. Ayers, R. Scott/;
s/E. L. Painter\./E. L. Painter,/;
$_;
}
open(OUT,">sbbg_coll_needed") || die;
foreach(sort(keys(%need_coll))){
	print OUT "$_\t$need_coll{$_}\n";
}
sub strip_name{
	local($_) = @_;
	s/\?//;
	s/  */ /g;
	s/Hook\. f\./Hookf/g;
	s/Ait\. f\./Aitf/g;
	s/L\. f\./Lf/g;
if(m/Encelia californica .*Encelia farinosa/){
return("Encelia californica � Encelia farinosa");
}
if(m/Encelia farinosa .*Encelia frutescens/){
return("Encelia farinosa � Encelia frutescens");
}
if(m/Aloe saponaria.*A.*striata.*/){
return("Aloe saponaria � Aloe striata");
}

	s/^ *//;
	s/ x / X /;
	s/^� ?([a-zA-Z])/X \u$1/;
	s/× ?/X /;
s/^x ([A-Z][a-z]+ [a-z]+).*/� $1/;
s/Fragaria � ananassa Duchesne var. cuneifolia.*/Fragaria � ananassa var. cuneifolia/ ||
s/Trifolium variegatum Nutt. phase (\d)/Trifolium variegatum phase $1/ ||
	s/^([A-Z][a-z]+) (X?[-a-z]+).*(subsp.) ([-a-z]+).*(var\.) ([-a-z]+).*/$1 $2 $3 $4 $5 $6/ ||
	s/^([A-Z][a-z]+ [a-z]+) (X [-A-Z][a-z]+ [a-z]+).*/$1 $2/ ||
	s/^([A-Z][a-z]+) (X [-a-z]+).*/$1 $2/ ||
	s/^([A-Z][a-z]+) (X?[-a-z]+).* (ssp\.|var\.|f\.|subsp.) ([-a-z]+).*/$1 $2 $3 $4/ ||
	s/^([A-Z][a-z]+) (X?[-a-z]+).*/$1 $2/||
	s/^(� [A-Z][a-z]+) (X?[-a-z]+).*/$1 $2/||
	s/^([A-Z][a-z]+) [A-Z(].*/$1/||
	warn "$_ no match\n";
warn "SAPONARIA: $_" if m/saponaria/;
	return ($_);
}

sub process_anno {
my($annotator, $current)=@_;
my($person, $year)=split(/, /, $annotator);
return "$current; $person; $year;";
}
__END__
15085 <Determinor
93822 <Search_x0020_Name
63622 <Source
93822 <_x0032__x002F_1_x002F_2012_x0020_export> 
93822 <acc_num
68341 <asp_txt
63669 <basereference_txt
93822 <coll1_txt
64501 <coll_num_txt
93822 <county_name
90761 <day_num
38895 <elevft_num
8073 <elevm_num
63506 <lat_num
93822 <local_txt
63506 <long_num
92904 <month_sym
63542 <prec_num
63275 <ter_name
93756 <year_num
