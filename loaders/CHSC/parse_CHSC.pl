open(IN,"../collectors_id") || die;
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
open(IN,"chico_non_vasc") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}
open(IN,"../riv_non_vasc") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}
open(IN,"../riv_alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(IN,"../davis/davis_exclude") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}
open(IN,"alter_chico.in") || die;
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
open(IN,"../davis/alter_davis") || die;
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
$/= "<CHSC_for_CalHerbConsort>";
open(ERROR, ">Chico_error") || die;
open(OUT, ">parse_Chico.out") || die;
open(IN,"chsc.xml") || die;
#open(IN,"chico_test") || die;
while(<IN>){
	($err_line=$_)=~s/\n/\t/g;
$comb_coll=$assoc=$genus=$LatitudeDirection=$LongitudeDirection=$date= $collnum= $coll_num_prefix= $coll_num_suffix= $name= $accession_id= $county= $locality= $Unified_TRS= $elevation= $collector= $other_coll= $ecology= $color= $lat= $long= $decimal_lat= $decimal_long="";
s/&quot;/"/g;
s/&apos;/'/g;
s/&amp;/&/g;
s/&lt;/</g;
s/&gt;/>/g;
		$state="CA";
	unless(m/<Accession>\d+<\/Accession>/){
		print ERROR "No Id, skipped $err_line\n";
		next;
	}
	($accession_id)=m/<Accession>(.*)</;
	$accession_id="CHSC$accession_id";
	if($seen{$accession_id}++){
		++$skipped{one};
		warn "Duplicate number: $accession_id<\n";
		print ERROR<<EOP;

Duplicate accession number, skipped: $accession_id
EOP
		next;
	}

	if(m|<CGenus>(.+)</CGenus>|){
		$name=$1;
		$genus=$1;
	unless($genus){
		print ERROR "No generic name, skipped: $err_line\n";
		next;
	}
	}
	if(m|<CSpecificEpithet>(.+)</CSpecificEpithet>|){
		$name.=" " . lc($1);
	}
	if(m|<CRank>(.+)</CRank>|){
		$rank=$1;
		$rank=~s/form.*/f./;
		$rank.=".";
		$rank=~s/\.\././;
		$name.=" $rank";
	}
	if(m|<CInfraspecificName>(.+)</CInfraspecificName>|){
		$name.=" " . lc($1);
	}
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
$name=~s/  */ /g;
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
		$date=~s/T\d.*//;
		$date=~s/<!\[CDATA\[ *(.*)\]\]>/$1/;
#Note ells in date
		$date=~s/l(9\d\d)/1$1/;
=other date formats
		if($date=~m/(\d\d\d\d)-(\d+)-(\d+)/){
			$month=$2; $day=$3; $year=$1;
		}
		elsif($date=~m/^/){
		elsif($date=~m/^\d+[- ]+[A-Za-z.]+[ -]+\d\d\d\d/){
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
=cut
		if($date=~/^([12][0789]\d\d)-(\d\d)-(\d\d)$/){
			$month=$1; $day=$2; $year=$3;
		}
		else{
			print ERROR "Date problem: $date made null $err_line\n";
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
		if($ecology=~s/(Assoc.*)//){
			$assoc=$1;
			foreach($assoc){
				s/Associated? [Ss]pecies://;
				s/Associated? sp+.?://;
				s/Associate[ds]?[:;]? //;
				s/Associations?[:;]? //;
				s/Assoc. [Ss]pp\.?: //;
				s/Assoc. [Ss]pecies: //;
				s/Assoc. [Ss]p\.?: //;
				s/Assoc[.,:]+ //;
				s/^ *//;
	if(length($assoc) > 255){
$overage=length($assoc)- 255;
$assoc=substr($assoc, 0,252) . "...";
		warn "Too long by $overage: $assoc\n";
	}
			}
		}
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
		warn "$collector\n" if $collector=~/\d/;
$collector=~s/.*1996/G. F. Hrusa/;
$collector=~s/Carpenter 16/Carpenter/;
		warn "$collector\n" if $collector=~/\d/;
		$collector=~s/<!\[CDATA\[(.*)\]\]>/$1/;
		if(m|<MoreCollectors>(.*)</MoreCollectors>|){
			$other_coll=$1;
			$other_coll=~s/<!\[CDATA\[(.*)\]\]>/$1/i;
			$other_coll=~s/^ *and //;
			$other_coll=~s/^ *[Ww]ith //;
		}
		#$collector=~s/([A-Z]\.[A-Z]\.)([A-Z][a-z])/$1 $2/g;
		#$collector=~s/([A-Z]\.)([A-Z]\.)/$1 $2/g;
		#$other_coll=~s/([A-Z]\.[A-Z]\.)([A-Z][a-z])/$1 $2/g;
		#$other_coll=~s/([A-Z]\.)([A-Z]\.)/$1 $2/g;
		$comb_coll="$collector, $other_coll" if $other_coll;
	foreach($collector, $comb_coll){
		s/([A-Z]\.)/$1 /g;
		s/^ *//;
		s/ *$//;
		s/ +/ /g;
#processing chico collectors
#read all collectors into %smasch_coll
#alters misspellings, generates isql statements for needed collectors
#
s/  / /g;
s/: .*//;
s/ \./. /g;
s/, & /, /g;
s/ & /, /g;
s/&apos;/'/g;
s/^B\. Castro, L\. P\. Janeway, G\. Kuenster, S\. Innecker, J\. Lacey$/B. Castro, L. P. Janeway, G. Kuenster, S. Innecken, J. Lacey/;
s/^Samatha Mackey Hillaire, Katya Yarosevich, Joe Yarosevich$/Samantha Mackey Hillaire, Katya Yarosevich, Joe Yarosevich/;
s/^V\. H\. Oswald, Lowell Ahart and Robin Ondricek-Fallscheer$/V. H. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer/;
s/^C\. Macdonald, P\. Powers, C\. Raley, J\. Spitler, D\. Stamp$/C. Macdonald, P. Powers, C. Raley, J. Spitler, and D. Stamp/;
s/^Vernon H\. Oswald, B\. Corbin, K\. Earll, G\. Schoolscraft$/Vernon H. Oswald, B. Corbin, K. Earll, G. Schoolcraft/;
s/^V\. H\. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer\.$/V. H. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer/;
s/^V\. H\. Oswald, Lowell Ahart, Robin Ordricek-Fallscheer$/V. H. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer/;
s/^V\. H\. Oswald, Lowell Ahart, Robin Ondricek-Fallsheer$/V. H. Oswald, Lowell Ahart, Robin Ondricek-Fallscheer/;
s/^B\. Castro, M\. A\. Griggs, Plumas NF [Bb]otanists\.$/B. Castro, M. A. Griggs, Plumas NF botanists/;
s/^B\. Castro, M\. A\. Griggs, Plumas NF [bB]otanists?$/B. Castro, M. A. Griggs, Plumas NF botanists/;
s/^Vernon H\. Oswald, Mike Wolder, Joe Silveira\.$/Vernon H. Oswald, Mike Wolder, Joe Silveira/;
s/^J\. D\. Jokerst, T\. B\. Devine, D\. Greenstein$/J. D. Jokerst, T. B. Devine, D. Greemstein/;
s/^Banchero, Fuller, Merryman, R\. A\. Schlising$/R. Banchero, J. Fuller, M. Merryman, R. Schlising/;
s/^Vernon H\. Oswald, Mike Wolder, Joe Silveria$/Vernon H. Oswald, Mike Wolder, Joe Silveira/;
s/^Robert A\. Schlising, N\. Lewsten, L\. Thurman$/Robert A. Schlising, N. Lersten, L. Thurman/;
s/^Robert A\. Schlising, N\. Lerston, L\. Thurman$/Robert A. Schlising, N. Lersten, L. Thurman/;
s/^H\. H\. Schmidt, M\. Merello & L\. Woodruff$/H. H. Schmidt, M. Merello, L. Woodruff/;
s/^D\. E\. Anderson, J\. O\. Sawyer, J\. P\. Smith$/D. E. Anderson, J. O. Sawyer, J. P. Smith, Jr./;
s/^Vernon H\. Oswald, Beth Corbin, Mike Dolan$/Vernon H. Oswald, Beth Corbin, Michael Dolan/;
s/^B\. Castro, Gail Kuentster, Loren Gehrung$/B. Castro, G. Kuenster, L. Gehrung/;
s/^J\. P\. Smith, J\. O\. Swayer, T\. W\. Nelson$/J. P. Smith, J. O. Sawyer, T. W. Nelson/;
s/^H\. H\. Sshmidt, James S\. Miller, A\. Pool$/H. H. Schmidt, James S. Miller, A. Pool/;
s/^Samatha Mackey Hillaire, Charles Hooks$/Samantha Mackey Hillaire, Charles Hooks/;
s/^Samatha Mackey Hillaire, Brian Elliott$/Samantha Mackey Hillaire, Brian Elliott/;
s/^K\. R\. Stern, D\. B\. Joley, J\. G\. Gescke$/K. R. Stern, D. B. Joley, J. G. Geschke/;
s/^Mike O&apos;Bryan, Robert A\. Schlising$/Mike O'Bryan, Robert A. Schlising/;
s/^B\. Castro, R\. Zebell and R\. Fallscheer$/B. Castro, R. Zebell, R. Fallscheer/;
s/^K R\. Stern, D\. B\. Joley, J\. G\. Geschke$/K. R. Stern, D. B. Joley, J. G. Geschke/;
s/^Coleta A\. Lawler, Robert A\. Schlising$/Coleta Lawler, Robert A. Schlising/;
s/^Niall F\. McCarten, Roxanne L\. Bittman$/Niall McCarten, Roxanne Bittman/;
s/^B\. Castro, Robin Ondricek-Fallscheer$/B. Castro, R. Fallscheer/;
s/^B\. Castro, L\. Gehrung & H\. Durio$/B. Castro, L. Gehrung, H. Durio/;
s/^B\. Castro, J\. Witzman, B\. Henrickson$/B. Castro, J. Witzman, B. Hendrickson/;
s/^B\. CAStro, R\. Zebell, R\. Fallscheer$/B. Castro, R. Zebell, R. Fallscheer/;
s/^B\. Castro, R\. Fallscherr, R\. Zebell$/B. Castro, R. Fallscheer, R. Zebell/;
s/^M\. S\. Taylor, J\. Prouty, E Heinitz\.$/M. S. Taylor, J. Prouty, E. Heinitz/;
s/^Timothy Spira, Robert A\. Schlising$/Timothy Spira, Robert Schlising/;
s/^Vernon H\. Oswald, Vernon H\. Oswald$/Vernon H. Oswald/;
s/^Robert A\. Schlising, Lloyd Thurman$/Robert A. Schlising, Lloy Thurman/;
s/^B\. Castro, L\. Janeway, S\. Innecken$/B. Castro, L. P. Janeway, S. Innecken/;
s/^J\. P\. Smith, J\. O\. Sawyer, J\. cole$/J. P. Smith, J. O. Sawyer, J. Cole/;
s/^M\. S\. Taylor, W\. Dakon, T\. Griggs\.$/M. S. Taylor, W. Dakon, T. Griggs/;
s/^Vernon H\. Oswald, Joseph Silveira\.$/Vernon H. Oswald, Joseph Silveira/;
s/^C\. A\. Lawler, Robert A\. Schlising$/C. A. Lawler, R. A. Schlising/;
s/^J\. Lacey, R\. Ondricek-Fallscheer\.$/J. Lacey, R. Ondricek-Fallscheer/;
s/^Barbara Ertter, James R\. Shevock$/Barbara Ertter, J. R. Shevock/;
s/^Robert F\. Thorne, C\. W\. Tolforth$/Robert F. Thorne, C. W. Tilforth/;
s/^J\. Lacey, R\. Oncricek-Fallscheer$/J. Lacey, R. Ondricek-Fallscheer/;
s/^Rober F\. Thorne, C\. W\. Tilforth$/Robert F. Thorne, C. W. Tilforth/;
s/^Coleta Lawler, Robert Schlising$/Coleta Lawler, Robert A. Schlising/;
s/^Vernon H\. Oswald, Lowelll Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^V\. Oswald, W\. Dempsey, D Perske$/V. Oswald, W. Dempsey, D. Perske/;
s/^Timothy Spora, Robert Schlising$/Timothy Spira, Robert Schlising/;
s/^Vernon H\. Oswald, Lowell Ahart\.$/Vernon H. Oswald, Lowell Ahart/;
s/^Vernin H\. Oswald, Lowell Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^R\. A\. Schlising, Lloyd Thurman$/R. A. Schlising, Lloy Thurman/;
s/^Dieter H\. Wilken, Gary Wallace$/Dieter H. Wilken, Gary D. Wallace/;
s/^Tim Spira, Robert A\. Schlising$/Timothy Spira, Robert Schlising/;
s/^Vernn H\. Oswald, Lowell Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^Venon H\. Oswald, Lowell Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^Mike Foster, Pauleen Broyles\.$/Mike Foster, Pauleen Broyles/;
s/^Vernon H\. Oswald, Wes Dempsey$/Vernon H. Oswald, W. Dempsey/;
s/^G\. Dougla Barbe, T\. C\. Fuller$/G. Douglas Barbe, T. C. Fuller/;
s/^Vernon H\. Oswald, Jim Snowden$/Vernon H. Oswald, James Snowden/;
s/^Vernon H\. Owald, Lowell Ahart$/Vernon H. Oswald, Lowell Ahart/;
s/^G\. Douglas Barbe, Ed\. W\. Hale$/G. Douglas Barbe, Ed W. Hale/;
s/^Vernon Oswald, Lowelll Ahart$/Vernon Oswald, Lowell Ahart/;
s/^D\. E\. Brink Jr\., L\. M\. Mayer$/D. E. Brink, Jr., L. M. Mayer/;
s/^Vernon Oswald\., Lowell Ahart$/Vernon Oswald, Lowell Ahart/;
s/^L\. Constance, J\. L\. Morrison$/L. Constance and J. L. Morrison/;
s/^F\. J\. Fuler, R\. A\. Schlising$/F. J. Fuller, R. A. Schlising/;
s/^C\. A\. Janeway, J\. P\. Janeway$/C. A. Janeway, L. P. Janeway/;
s/^M\. R\. Crosby, Nancy R\. Morin$/M. R. Crosby and Nancy Morin/;
s/^Ira W\. Clokey, B\. Templeton$/Ira W. Clokey and B. Templeton/;
s/^Frederic Hrusa, L\. Serafini$/G. F. Hrusa, L. Serafini/;
s/^Vernon oswald, Lowell Ahart$/Vernon Oswald, Lowell Ahart/;
s/^L\. P\. janeway, Jean Witzman$/L. P. Janeway, Jean Witzman/;
s/^B\. Castro, Robin Fallscheer$/B. Castro, R. Fallscheer/;
s/^C\. A\. Janewy, L\. P\. Janeway$/C. A. Janeway, L. P. Janeway/;
s/^L\. P\. Janway, C\. A\. Janeway$/L. P. Janeway, C. A. Janeway/;
s/^B\. Castro, Shirley Innecken$/B. Castro, S. Innecken/;
s/^M\. R\. Crosby, Nancy Morin$/M. R. Crosby and Nancy Morin/;
s/^Vernn Oswald, Lowell Ahart$/Vernon Oswald, Lowell Ahart/;
s/^Tim Spira, Rober Schlising$/Timothy Spira, Robert Schlising/;
s/^G\. F\. Hursa, T\. D\. Wilfred$/G. F. Hrusa, T. D. Wilfred/;
s/^C\. A\. Lawler, R\. Schlising$/C. A. Lawler, R. A. Schlising/;
s/^M\. S> Taylor, J\. Lacey$/M. S. Taylor, J. Lacey/;
s/^L\. Constance, H\. L\. Mason$/L. Constance and H. L. Mason/;
s/^C\. A\. Janeway, L\. Janeway$/C. A. Janeway, L. P. Janeway/;
s/^M\. R\. Crosby, Mancy Morin$/M. R. Crosby and Nancy Morin/;
s/^H\. H Schmidt, L\. Woodruff$/H. H. Schmidt, L. Woodruff/;
s/^Susie Urie, Eric Schroder$/Susi Urie, Eric Schroder/;
s/^Reid Moran, Chas\. Quibell$/Reid Moran and Chas. Quibell/;
s/^R\. L\. Ondricek-Fallsheer$/R. L. Ondricek-Fallscheer/;
s/^L\. J\. Janeway, B\. Castro$/L. P. Janeway, B. Castro/;
s/^Jeffreyi Thomas Gautschi$/Jeffrey Thomas Gautschi/;
s/^B\. Castro, Gail Kuenster$/B. Castro, G. Kuenster/;
s/^B\. Castro, J\. D\. Jokerst$/B. Castro and J. D. Jokerst/;
s/^M\. Pranther, N\. Pranther$/M. Prather, N. Prather/;
s/^C\. Epling, W\. M\. Robison$/C. Epling, Wm. Robison/;
s/^B\. Castro, R\. Fallsheer$/B. Castro, R. Fallscheer/;
s/^Vernon Oswald, L\. Ahart$/Vernon Oswald, Lowell Ahart/;
s/^B\. Castro, B\. Henderson$/B. Castro, B. Hendrickson/;
s/^Samatha Mackey Hillaire$/Samantha Mackey Hillaire/;
s/^M\. S Taylor, W\. Overton$/M. S. Taylor, W. Overton/;
s/^Gary Wallace, L\. Debuhr$/Gary Wallace, L. DeBuhr/;
s/^C\. Janeway, L\. Janeway$/C. A. Janeway, L. P. Janeway/;
s/^Phillip A\. Silverstone$/Philip A. Silverstone/;
s/^B\. Castro, J\. Jurewiez$/B. Castro, J. Jurewicz/;
s/^James Payne Smith, JR\.$/James Payne Smith, Jr./;
s/^B\. Castro, L\. Janeway$/B. Castro, L. P. Janeway/;
s/^D\. E\. Brink, L\. Mayer$/D. E. Brink, Jr., L. M. Mayer/;
s/^f\. t\. Griggs, A\. Pass$/F. T. Griggs, A. Pass/;
s/^F\. T\. Briggs, A\. Pass$/F. T. Griggs, A. Pass/;
s/^M\. S Taylor, M\. Hayes$/M. S. Taylor, M. Hayes/;
s/^Edward Laidlaw Smith$/Edward L. Smith/;
s/^James Payne Smith, Jr$/James Payne Smith, Jr./;
s/^Ted\. H\. Thorsted, Jr\.$/Ted H. Thorsted, Jr./;
s/^James Payne Smith Jr\.$/James Payne Smith, Jr./;
s/^M\. &. N\. Pranther$/M. Prather, N. Prather/;
s/^Robert A\. Schlisingc$/Robert A. Schlising/;
s/^Roberst A\. Schlising$/Robert A. Schlising/;
s/^B\. Castro, L\. Hanson$/B. Castro, Linnea Hanson/;
s/^F\. T\. Giggs, A\. Pass$/F. T. Griggs, A. Pass/;
s/^Thomas E\. Lewis\. Jr\.$/Thomas E. Lewis, Jr./;
s/^B\. Castro, R\. Zabell$/B. Castro, R. Zebell/;
s/^N\. Morin, J\. Griffin$/N. Morin and J. Griffin/;
s/^Lichael P\. Crivello$/Michael P. Crivello/;
s/^Sonia A\. Westerberg$/Sonia R. Westerberg/;
s/^Thomas E\. Lewis Jr\.$/Thomas E. Lewis, Jr./;
s/^L\. Oliver, D\. Slaon$/L. Oliver, D. Sloan/;
s/^Sona R\. Westerberg$/Sonia R. Westerberg/;
s/^Robin L\. Ondericek$/Robin L. Ondricek/;
s/^Robert A\. Schising$/Robert A. Schlising/;
s/^Robert A Schlising$/Robert A. Schlising/;
s/^Robert A\. Schlisng$/Robert A. Schlising/;
s/^Carol G\. Getzinger$/Carol C. Getzinger/;
s/^R\. A> Schlising$/R. A. Schlising/;
s/^Aurthur C\. Barrett$/Arthur C. Barrett/;
s/^Arthur C\. Barrett\.$/Arthur C. Barrett/;
s/^Arthur O\. Barrett$/Arthur C. Barrett/;
s/^Fobin L\. Ondricek$/Robin L. Ondricek/;
s/^W\. Micheal Foster$/W. Michael Foster/;
s/^James D\. Jokerst\.$/James D. Jokerst/;
s/^James D Jokerst$/James D. Jokerst/;
s/^Robert\. F\. Thorne$/Robert F. Thorne/;
s/^Gary J\. Stebbings$/Gary J. Stebbins/;
s/^Virginiga Hagaman$/Virginia Hagaman/;
s/^Mike Carpenter$/Mike Carpenter/;
s/^Dierter H\. Wilken$/Dieter H. Wilken/;
s/^G\. C\. Strausbaugh$/G. Ctrausbaugh/;
s/^James R\. Brownell$/James Brownell/;
s/^Mike O&apos;Bryan$/Mike O'Bryan/;
s/^Dibble and Griggs$/Dibble, Griggs/;
s/^David m\. Thompson$/David M. Thompson/;
s/^M\. A> Callahan$/M. A. Callahan/;
s/^Arthur G\. Barrett$/Arthur C. Barrett/;
s/^Suesie Boergadine$/Sue Boergadine/;
s/^Marria Ulloa-Cruz$/Maria Ulloa-Cruz/;
s/^Michaelle Snipes$/Michelle Snipes/;
s/^Beverly J\. Wise$/Beverley J. Wise/;
s/^Maria Ulloa-Crus$/Maria Ulloa-Cruz/;
s/^Arthur C\. Barret$/Arthur C. Barrett/;
s/^Coleta A\. Lawler$/Coleta Lawler/;
s/^Mary Mac Arthur$/Mary MacArthur/;
s/^Virignia Hagaman$/Virginia Hagaman/;
s/^Gary J\. Sebbings$/Gary J. Stebbins/;
s/^Charles Crannell$/Charlie Crannell/;
s/^Sandra C\. Morey\.$/Sandra C. Morey/;
s/^P\. Delaplane, eb$/P. Delaplane/;
s/^Jomes D\. Jokerst$/James D. Jokerst/;
s/^Vernin H\. Oswald$/Vernon H. Oswald/;
s/^Kath Sommarstrom$/Kathy Sommarstrom/;
s/^Rober F\. Thorne$/Robert F. Thorne/;
s/^Sadie Gaultieri$/Sadie Gualtieri/;
s/^Vernon H Oswald$/Vernon H. Oswald/;
s/^Robin Ondricek$/Robin L. Ondricek/;
s/^G\. Dougla Barbe$/G. Douglas Barbe/;
s/^Roberta A\. Boen$/Roberta A. Boer/;
s/^Pamela Cladwell$/Pamela Caldwell/;
s/^James\. P\. Smith$/James P. Smith/;
s/^Carol Getzinger$/Carol C. Getzinger/;
s/^Vernon H\. Owald$/Vernon H. Oswald/;
s/^Thomas E\. Lewis$/Thomas E. Lewis, Jr./;
s/^D\. E\. Brink Jr\.$/D. E. Brink, Jr./;
s/^Donald M\. Burke$/Donald M. Burk/;
s/^Venon H\. Oswald$/Vernon H. Oswald/;
s/^Veron H\. Oswald$/Vernon H. Oswald/;
s/^Margie Ceollins$/Margie Collins/;
s/^Thomes Chastain$/Thomas Chastain/;
s/^M\. S> Taylor$/M. S. Taylor/;
s/^Jerry Sullivan\.$/Jerry Sullivan/;
s/^H\. E\. MacLennan$/H. E. Mac Lennan/;
s/^Donna Kingsford$/Dona Kingsford/;
s/^G\. Schoolcraft\.$/G. Schoolcraft/;
s/^Paulenn Broyles$/Pauleen Broyles/;
s/^Dibble, Griggs\.$/Dibble, Griggs/;
s/^J\. P\. Kroessing$/J. P. Kroessig/;
s/^Heffrey R\. Peek$/Jeffrey R. Peek/;
s/^Mary Mae Arthur$/Mary MacArthur/;
s/^Lynn R\. Thomas$/Lynn R Thomas/;
s/^Jame D\. Jokerst$/James D. Jokerst/;
s/^David Cherrtham$/David Cheetham/;
s/^Vernn H\. Oswald$/Vernon H. Oswald/;
s/^R\. A\. Schisling$/R. A. Schlisling/;
s/^Theresa Coasta$/Theresa Costa/;
s/^J\. D\. Jokerst`$/J. D. Jokerst/;
s/^Pauleen Broyes$/Pauleen Broyles/;
s/^Puleen Broyles$/Pauleen Broyles/;
s/^Sue Boerqadine$/Sue Boergadine/;
s/^Vernon Oswald\.$/Vernon Oswald/;
s/^Edward L Smith$/Edward L. Smith/;
s/^Frederic Hrusa$/G. F. Hrusa/;
s/^James t\. Nicol$/James T. Nicol/;
s/^J\. D\. Jokerst\.$/J. D. Jokerst/;
s/^Cona Kingsford$/Dona Kingsford/;
s/^H\. Durio, s\.n\.$/H. Durio/;
s/^Jeffrey M Lund$/Jeffrey M. Lund/;
s/^Jerry Sndgrass$/Jerry Snodgrass/;
s/^Sue Boergadino$/Sue Boergadine/;
s/^Vernon Oswalf$/Vernon Oswald/;
s/^Timothy Spora$/Timothy Spira/;
s/^Don Kroessing$/Don Kroessig/;
s/^Robert Jaegal$/Robert Jaegel/;
s/^Eric J\. Miler$/Eric J. Miller/;
s/^Shuan E\. Sims$/Shaun E. Sims/;
s/^M\. A Callahan$/M. A. Callahan/;
s/^S\. Westenberg$/S. Westerberg/;
s/^George Deriso$/George Deniso/;
s/^G\. Stausbaugh$/G. Strausbaugh/;
s/^l\. P\. Janeway$/L. P. Janeway/;
s/^John La Salle$/John LaSalle/;
s/^Edna Caufield$/Edna Canfield/;
s/^Terrance Finn$/Terrence Finn/;
s/^Jomes Jokerst$/James Jokerst/;
s/^Eric Hartwell$/Eric G. Hartwell/;
s/^G\. Straubaugh$/G. Strausbaugh/;
s/^Nancy Mosman\.$/Nancy Mosman/;
s/^A\. W\. Harilik$/A. W. Harvilik/;
s/^Jones Jokerst$/James Jokerst/;
s/^Vernon oswald$/Vernon Oswald/;
s/^Jenifer Estep$/Jennifer Estep/;
s/^Ahart-Jokerst$/Ahart, Jokerst/;
s/^Steven Triana$/Steven Triano/;
s/^Fredric Hrusa$/G. F. Hrusa/;
s/^Ted Edminston$/Ted Edmiston/;
s/^M\. S\. Taylor\.$/M. S. Taylor/;
s/^R\. Cliquennoi$/R. Clicquennoi/;
s/^M\. MacAurther$/M. MacArthur/;
s/^H\. H\. Sshmidt$/H. H. Schmidt/;
s/^R\. Pierce Jr\.$/R. Pierce, Jr./;
s/^Shelly A Kirn$/Shelly A. Kirn/;
s/^L\. J\. Janeway$/L. P. Janeway/;
s/^J\. R\. Neslon$/J. R. Nelson/;
s/^C\. A\. Janewy$/C. A. Janeway/;
s/^W\. Fitswater$/W. Fitzwater/;
s/^Roger Jaegal$/Roger Jaegel/;
s/^Julie Jenson$/Julie Jensen/;
s/^L\. P\. Janewy$/L. P. Janeway/;
s/^H\. H Schmidt$/H. H. Schmidt/;
s/^C\. E\. Leaver$/C. E. Laver/;
s/^C\. F\. Sonnee$/C. F. Sonne/;
s/^D\. G\. Miller$/D. G. Miller III/;
s/^Vernn Oswald$/Vernon Oswald/;
s/^M\. MacSrthur$/M. MacArthur/;
s/^W\. Follettee$/W. Follette/;
s/^Paula Minton$/Paula J. Minton/;
s/^Darci Fields$/Darci Field/;
s/^Sam Poolswat$/Sam Poolsawat/;
s/^Jannae Pitts$/Jeanne Pitts/;
s/^F\. T\. Briggs$/F. T. Griggs/;
s/^f\. t\. Griggs$/F. T. Griggs/;
s/^Rober Jaegel$/Robert Jaegel/;
s/^A\. K\. Reverd$/A. K. Revard/;
s/^L\. P\. Janway$/L. P. Janeway/;
s/^Terence Finn$/Terrence Finn/;
s/^Michaul Ward$/Michael Ward/;
s/^Phil Bulmert$/Phil Blumert/;
s/^C\. E\. Iaver$/C. E. Laver/;
s/^K, R\. Stern$/K. R. Stern/;
s/^G\. F\. Hursa$/G. F. Hrusa/;
s/^P\. Delplane$/P. Delaplane/;
s/^E\. Parreno$/E. P. Parreno/;
s/^Susie Urie$/Susi Urie/;
s/^Susie Uri$/Susi Urie/;
s/^Susi Uri$/Susi Urie/;
s/^F\. J\. Fuler$/F. J. Fuller/;
s/^M\. S Taylor$/M. S. Taylor/;
s/^D\. E\. Brink$/D. E. Brink, Jr./;
s/^C\. Janeway$/C. A. Janeway/;
s/^Agnus Riker$/Agnes Riker/;
s/^Sori H Shad$/Sori H. Shad/;
s/^F\. T\. Giggs$/F. T. Griggs/;
s/^Gail Bufton$/Gail A. Bufton/;
s/^G\. Nielson$/G. Nielsen/;
s/^Bryon Case$/Bryan Case/;
s/^K\. Heneger$/K. Henegar/;
s/^K R\. Stern$/K. R. Stern/;
s/^NEH Prouty$/N. E. H. Prouty/;
s/^D\. Crummet$/D. Crummett/;
s/^Cark Pejsa$/Carl Pejsa/;
s/^A\. Revard$/A. K. Revard/;
s/^M\. Hiller$/M. Hillier/;
s/^NE Heiken$/N. E. Heiken/;
s/^m\. Robbie$/M. Robbie/;
s/^B\. CAStro$/B. Castro/;
s/^R\. Jaegal$/R. Jaegel/;
s/^B\. Castrp$/B. Castro/;
s/^E Parreno$/E. Parreno/;
s/^Kenn Cole$/Ken Cole/;
s/^N\. Jaekal$/N. Jaekel/;
s/^Linda Osborn$/Linda Osborne/;
s/^Ben Mhre$/Ben Myhre/;
s/^Kenn Cole$/Ken Cole/;
s/^H\. Durio, s\.n\.$/H. Durio/;
s/^Wayne \) Baum$/Wayne Baum/;
s/^Waynes O\. Baum$/Wayne O. Baum/;
s/^Z\. Parkenvich$/Z. Parkevich/;
s/^Z\. Barkevich$/Z. Parkevich/;
s/^V\. holt$/V. Holt/;
s/Wesley O\. Griesal$/Wesley O. Griesel/;
s/^V\. H\. Oswald, B\. Corbin, A Sanger, G\. Schoolcraft$/V. H. Oswald, B. Corbin, A. Sanger, G. Schoolcraft/;
s/^Heidi West, Jenny Marr, Caroline Warren, Joyce Lacey-Rickert,$/Heidi West, Jenny Marr, Caroline Warren, Joyce Lacey-Rickert/;
s/^L\. P\. Janeway, Eric Schroder, Katherine Murrell, Todd Adams\.$/L. P. Janeway, Eric Schroder, Katherine Murrell, Todd Adams/;
s/^L\. P\. Janeway, R\. A\. Schlising, B\. Castro, Pauleen Broyles\.$/L. P. Janeway, R. A. Schlising, B. Castro, Pauleen Broyles/;
s/^Caroline Warren, Jenny Marr, Julie Cunningham, Heidi Westq$/Caroline Warren, Jenny Marr, Julie Cunningham, Heidi West/;
s/^Heidi West, Jenny Marr, C\. Warren,J\. Cunningham, N\. Wight$/Heidi West, Jenny Marr, C. Warren, J. Cunningham, N. Wight/;
s/^Lowell Ahart, Barbara Castro, Dan Barth, Diane Mastalir\.$/Lowell Ahart, Barbara Castro, Dan Barth, Diane Mastalir/;
s/^Lowell Ahart, Barbare Castro, Dan Barth, Diane Mastalir$/Lowell Ahart, Barbara Castro, Dan Barth, Diane Mastalir/;
s/^L\. P\. Janeway, B\. Castro, Linnea Hanson, Hal Durio\.$/L. P. Janeway, B. Castro, Linnea Hanson, Hal Durio/;
s/^Robert A\. Schlising, Anna Eagel, Dick Rosenzweig$/Robert A. Schlising, Anna Eagle, Dick Rosenzweig/;
s/^D\. Boud, M\. Eichelberger, T\. Messick, T\. Ranker$/D. Boyd, M. Eichelberger, T. Messick, T. Ranker/;
s/^Julie Cunningham, Heidi West, Caroline Warren\.$/Julie Cunningham, Heidi West, Caroline Warren/;
s/^Robert A\. Schlising, Ben Lilies, Gina Purelis$/Robert A. Schlising, Ben Liles, Gina Purelis/;
s/^L\. P\. Janeway, Lela Burdett, Bernard Burdett\.$/L. P. Janeway, Lela Burdett, Bernard Burdett/;
s/^J\. D\. Jokerst, R\. A\., Schlising, B\. Banchero$/J. D. Jokerst, R. A. Schlising, B. Banchero/;
s/^L\. P\. Janeway, Linnea Hanson, Perrie Cobb\.$/L. P. Janeway, Linnea Hanson, Perrie Cobb/;
s/^Heidi West, Caroline Warren, Jenny Marr`$/Heidi West, Caroline Warren, Jenny Marr/;
s/^M\. S\. Taylor, M\. Hayes, R\. Schlising\.$/M. S. Taylor, M. Hayes, R. Schlising/;
s/^Lowel Ahart, Vernon H\. Oswald$/Lowell Ahart, Vernon H. Oswald/;
s/^L\. M\. Mayer, D\. E\. Brink Jr\.$/L. M. Mayer, D. E. Brink, Jr./;
s/^J\. D\. Jokerst, R\. A\.$/J. D. Jokerst, R. A. Schlising/;
s/^Roberta G\. Roberston$/Roberta G. Robertson/;
s/^Herb Allan Mc Lane$/Herb Allan McLane/;
s/^James Hendrickson$/James Henrickson/;
s/^Herb Allen McLane$/Herb Allan McLane/;
s/^Robert F\. thorne$/Robert F. Thorne/;
s/^Herber G\. Baker$/Herbert G. Baker/;
s/^J\. D> Prouty$/J. D. Prouty/;
s/^G\. Ctrausbaugh$/G. Strausbaugh/;
s/^M\.\. S\. Taylor$/M. S. Taylor/;
s/^Lynn R Thomas$/Lynn R. Thomas/;
s/^Lowell Ahart\.$/Lowell Ahart/;
s/^K\. B\. McShea\.$/K. B. McShea/;
s/^Steve Alverez$/Steve Alvarez/;
s/^Marsha Caount$/Marsha Count/;
s/^L\. P\. janeway$/L. P. Janeway/;
s/^Pauline kunst$/Pauline Kunst/;
s/^Lowell Ahart`$/Lowell Ahart/;
s/^Lowelll Ahart$/Lowell Ahart/;
s/^T\. N\. Cassale$/T. N. Casale/;
s/^Marsha Caunt$/Marsha Count/;
s/^Loweel Ahart$/Lowell Ahart/;
s/^V\. S\. Jacson$/V. S. Jackson/;
s/^Lowel Ahart$/Lowell Ahart/;
s/^K\. Mckenzie$/K. McKenzie/;
s/^M S\. Taylor$/M. S. Taylor/;
s/^K\. Bandegee$/K. Brandegee/;
s/^N\. Jeakel$/N. Jaekel/;
s/^K\. Jaekal$/K. Jaekel/;
s/^M\. yoder$/M. Yoder/;
s/^D\. Boud$/D. Boyd/;
		s/\([^)]+\)//g;
		s/([A-Z]), ([A-Z][a-z])/$1. $2/g;
		#s/([A-Z])\. ([A-Z]) /$1. $2./g;
		s/ ,/,/g;
		s/,,/,/g;

	}
$seen_coll{$collector}++;
$seen_coll{$comb_coll}++ if $other_coll;
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
$LatitudeDirection="N" unless $Latitude_Direction;
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
	s/ *$//;
	s/\?//;
	s/ \(\?\)//;
	s/^ *$/unknown/;
s/^'$/unknown/;
s/^:ale$/unknown/;
s/^4$/unknown/;
s/^aIWEE$/unknown/;
s/^Butte & Tehama line$/Butte/;
s/^Butte VHO$/Butte/;
s/^Butte`$/Butte/;
s/^Can Bernardino$/San Bernardino/;
s/^Clousa$/Colusa/;
s/^Colusaq$/Colusa/;
s/^Conta Costa$/Contra Costa/;
s/^Contra Costra$/Contra Costa/;
s/^El Dorada$/El Dorado/;
s/^El Dorata$/El Dorado/;
s/^Eldorado$/El Dorado/;
s/^Elorado$/El Dorado/;
s/^Frensno$/Fresno/;
s/^Genn$/Glenn/;
s/^Hunmboldt$/Humboldt/;
s/^Lassen`$/Lassen/;
s/^Lassrn$/Lassen/;
s/^Maraposa$/Mariposa/;
s/^Mendecino$/Mendocino/;
s/^Mendicino$/Mendocino/;
s/^Merved$/Merced/;
s/^Mondocino$/Mendocino/;
s/^Monterey SE$/Monterey/;
s/^NE San Bernardino$/San Bernardino/;
s/^Olumas$/Plumas/;
s/^Pluams$/Plumas/;
s/^Plumas & Butte$/Plumas/;
s/^Plumas & Sierra$/Plumas/;
s/^Plumas or Sierra$/Plumas/;
s/^Plumas, Sierra$/Plumas/;
s/^Plumus$/Plumas/;
s/^San Barbara$/Santa Barbara/;
s/^San Ben$/San Benito/;
s/^San Berdo$/San Bernardino/;
s/^San Bernardino NE$/San Bernardino/;
s/^San Bernarndino$/San Bernardino/;
s/^San Cruz$/Santa Cruz/;
s/^San Fransisco$/San Francisco/;
s/^San Juaquin$/San Joaquin/;
s/^San Lius Obispo$/San Luis Obispo/;
s/^San Louis Obispo$/San Luis Obispo/;
s/^Santa Barbara`$/Santa Barbara/;
s/^Santa Cruz`$/Santa Cruz/;
s/^shasta$/Shasta/;
s/^Shasta`$/Shasta/;
s/^Shata$/Shasta/;
s/^Siera$/Sierra/;
s/^Siiskiyou$/Siskiyou/;
s/^Sisikiyou$/Siskiyou/;
s/^Siskyou$/Siskiyou/;
s/^Sntna Barbara$/Santa Barbara/;
s/^Stanilaus$/Stanislaus/;
s/^Stansilaus$/Stanislaus/;
s/^Sutter`$/Sutter/;
s/^Tehana$/Tehama/;
s/^Tehema$/Tehama/;
s/^Toulumne$/Tuolumne/;
s/^Trinity ()$/Trinity/;
s/^Yuba-Butte$/Yuba/;
	s/San Bernadino/San Bernardino/;
	s/San Bernidino/San Bernardino/;
	s/San Beradino/San Bernardino/;
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
	s/Armador/Amador/;
	s/Humbolt/Humboldt/;
	s| */.*||;
	s/ ?- .*//;
	s/ *\.$//;
s/^Jct  Alpine, Amador, El Dorado$/Alpine/;
s/^Lake-Colusa-Glenn jct$/Lake/;
s/^Lake, Colusa, Glenn line$/Lake/;
s/^Alpine, Amador, El Dorado jct\.?$/Alpine/;
}
unless($county=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|unknown|Ventura|Yolo|Yuba)$/i){
		print ERROR "County not in California?, skipped $err_line\n";
		next;
}

if($ecology=~s/[.,;] *([Ff]lowers [^.]+)\././){
$color=$1;
}
else{
$color="";
}









	if(length($locality) > 255){
		foreach($locality){
			s/[Aa]bout /ca. /g;
			s/Highway/Hwy/g;
			s/River/R./g;
			s/[eE]ast-north-?east/NE/g;
			s/[Nn]orth-?west/NW/g;
			s/north-?east/NE/g;
			s/south-?east/SE/g;
			s/south-?west/SW/g;
			s/\b[Ss]outh\b/S/g;
			s/\b[Nn]orth\b/N/g;
			s/ &amp; / & /g;
			s/National Forest/N.F./g;
			s/National Wildlife/N.W./g;
			s/\bRoad\b/Rd/g;
			s/ miles / mi /g;
			s/ mile / mi /g;
			s/\byards\b/yd/g;
			s/ west / W /g;
			s/ east / E /g;
			s/Campground/Cpgd/g;
			s/\bvery\b//g;
			s/DUE TO CONCERNS.*/MORE INFORMATION IS AVAILABLE ON THE SPECIMEN LABEL/;
			s/Western Transverse Range/WTR/;
			s/Thomas Creek Ecol/Thomes Creek Ecol/;
		s/  */ /g;
		s/\.\././g;
		s/ the / /;
		s/ a / /g;
		s/Northern High Sierra Nevada Range/n SNH/;
		s/High Sierra Nevada Range/SNH/;
		s/Sierra Nevada Range/SN/;
		}
	if(length($locality) > 255){
$overage=length($locality)- 255;
$locality=substr($locality, 0,252) . "...";
		warn "Too long by $overage: $locality\n";
	}
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
Collector: $collector
Other_coll: $other_coll
Combined_coll: $comb_coll
Habitat: $ecology
Associated_species: $assoc
Color: $color
Latitude: $lat
Longitude: $long
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Notes: 

EOP
}
foreach(sort(keys(%seen_coll))){
if($coll_comm{$_}){
	#warn "$_ seen\n";
}
else{
	#print "$_\n";
print <<EOP;
print "$_\n";
insert into committee (chair_id, committee_func, committee_abbr, comments, data_src_id) values(0,"coll","$_","Chico bload",6)
go
EOP
}
}
foreach(sort {$noname{$a}<=>$noname{$b}}(keys(%noname))){
print "$_ : $noname{$_}\n";
}
__END__
<CHSC_for_CalHerbConsort>
<Accession>
<Division>
<CFamily>
<CGenus>
<CSpecificEpithet>
<Collector>
<Date>
<DatePrecision>
<GeoTertiaryDivision>
<Elevation>
<ElevationUnits>
<Locality>
<LatLongAddedCheck>
<Notes>
<AnnoYesNo>
</CHSC_for_CalHerbConsort>
<CRank>
<CInfraspecificName>
<CDeterminedBy>
<LatitudeDegree>
<LatitudeMinutes>
<LatitudeSeconds>
<LatitudeDirection>
<LongitudeDegree>
<LongitudeMinutes>
<LongitudeSeconds>
<LongitudeDirection>
<LatLongPrecision>
<LatLongPrecisionUnits>
<DeterminedDate>
<Ecology>
<MoreCollectors>
</Collector>
<CollectionNumber>
<TownshipAndRange>
<USGSQuadrangle>
<USGSQuadrangleScale>
</GeoTertiaryDivision>
</Notes>
</MoreCollectors>
</Ecology>
</dataroot>
