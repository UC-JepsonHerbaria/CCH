open(ERR, ">sagehen_err.txt") || die;
open(OUT, ">SCFS.txt") || die;
open(IN,"Users/davidbaxter/DATA/mosses") || die;
while(<IN>){
	chomp;
	if(m/\cM/){
	die;
	}
	$exclude{$_}++;
}
open(IN,"/Users/davidbaxter/DATA/smasch_taxon_ids.txt") || die;
while(<IN>){
chomp;
s/^.*\t//;
$taxon{$_}++;
}
open(IN,"/Users/davidbaxter/DATA/alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
%county=(
"CAL"=>"Calaveras","ED"=>"El Dorado","LAS"=>"Lassen","NEV"=>"Nevada","PLA"=>"Placer","PLU"=>"Plumas","SAC"=>"Sacramento","SIE"=>"Sierra","SIS"=>"Siskiyou","TUO"=>"Tuolumne");
open(IN,"scfs.tab") || die;
while(<IN>){
chomp;
s/\cK/ /g;
($accession_id,
    $name,
    $collectors,
    $coll_number,
    $date,
    $unparsed_locality,
    $precise_locality,
    $elevation,
    $associated_species,
    $notes)=split(/\t/,$_,50);
$accession_id=~s/ *$//;


	if($accession_id=~/^ *$/){
		++$skipped{one};
		print ERR<<EOP;

No accession number, skipped: $_
EOP
		next;
	}
	if($name !~/^ *[A-Z]/){
		++$skipped{one};
		print ERR<<EOP;

No generic name (name not beginning with capital), skipped: $_
EOP
		next;
	}
	if($seen{$accession_id}++){
		++$skipped{one};
		warn "Duplicate number: $fields[0]<\n";
		print ERR<<EOP;

Duplicate accession number, skipped: $fields[0]
EOP
		next;
	}




foreach($unparsed_locality){
if(s/USA: //){
$country="USA";
}
else{
$country="";
}
if(s/CA: //){
$state="California";
}
elsif(s/NV: //){
$state="NV";
}
else{
$state="";
}
if(s/(CAL|ED|LAS|NEV|PLA|PLU|SAC|SIE|SIS|TUO):? ?//){
$county=$county{$1};
}
else{
$county="";
}
}
next unless $state eq "CA";
if($unparsed_locality){
$locality="$unparsed_locality. $precise_locality";
}
else{
$locality="$precise_locality";
}
foreach($date){
 s!6/(\d+)/!$1 Jun !;
 s!7/(\d+)/!$1 Jul !;
s/(\d+ [A-Z][a-z]+) (6[45])/$1 19$2/;
s/1Jul/1 Jul/;
}
unless ($date=~/\d+ [A-Z][a-z]+ \d\d\d\d/){
unless($date=~/[12][890]\d\d/){
#print "$accession_id: date nulled $date\n";
$date="";
}
}
foreach ($collectors){
s/ *$//;
s/^[Uu]nk\.$//;
s/M\. *Fleshner/M. Fleschner/;
s/P.L. Billigs/P.L. Billings/;
s/J\. Brook\b/J. Brooks/;
#print "$collectors\n"
$combined_collectors=$_;
s/, (.*)//;
}

#($accession_id,$name,$collectors,$coll_number, $date, $unparsed_locality, $precise_locality, $elevation, $associated_species,$notes)=split(/\t/,$_,50);
$name=&strip_name($name);


($genus=$name)=~s/ .*//;
$name=ucfirst(lc($name));
$name=~s/'//g;
$name=~s/`//g;
$name=~s/\?//g;
$name=~s/ *$//;
$name=~s/  +/ /g;
$name=~s/ssp\./subsp./;
$name=~s/ [Xx] / × /;
$name=~s/ *$//;
$name=~s/ sp\.*$//;
if($name=~/([A-Z][a-z-]+ [a-z-]+) × /){
                 $hybrid_annotation=$name;
                 warn "$1 from $name\n";
                 print ERR "$1 from $name\n";
                 $name=$1;
             }
	     else{
                 $hybrid_annotation="";
	     }


if($exclude{$genus}){
	print ERR <<EOP;

Excluded, not a vascular plant: $name
EOP
		++$skipped{one};
	next;
}
if($alter{$name}){
	print ERR <<EOP;

Spelling altered to $alter{$name}: $name 
EOP
	$name=$alter{$name};
}
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

Not yet entered into SMASCH taxon name table: $on skipped
EOP
		++$skipped{one};
		$needed_name{$name}++;
next;
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

Not yet entered into SMASCH taxon name table: $on skipped
EOP
		++$skipped{one};
		$needed_name{$name}++;
next;
		}
	}
	else{
	print ERR <<EOP;

Not yet entered into SMASCH taxon name table: $name skipped
EOP
		++$skipped{one};
		$needed_name{$name}++;
	next;
	}
}




if($coll_number=~s/^(\d+)-(\d+)$/$2/){
$COLL_NUM_prefix=$1;
}
else{
$COLL_NUM_prefix="";
}
if($coll_number=~s/^(\d+)([^0-9]+.*)$/$1/){
$COLL_NUM_suffix=$2;
}
else{
$COLL_NUM_suffix="";
}
print OUT <<EOP;
Accession_id: $accession_id
CNUM: $coll_number
CNUM_prefix: $COLL_NUM_prefix
CNUM_suffix: $COLL_NUM_suffix
Date: $date
Name: $name
State: $state
County: $county
Location: $locality
Elevation: $elevation
Collector: $collectors
Combined_collector: $combined_collectors
Associated_species: $associated_species
Notes: $notes
Hybrid_annotation: $hybrid_annotation

EOP
}
sub strip_name{
local($_) = @_;
       s/^([A-Z][-A-Za-z]+) (X?[-a-z]+).*\b(nothosubsp\.|subsp\.|ssp\.|var\.|f\.) ([-a-z]+).*/$1 $2 $3 $4/ ||
s/^([A-Z][A-Za-z]+) ([a-z&][a-z;-]+).*/$1 $2/;
s/ssp\./subsp./;
return (ucfirst(lc($_)));
}
