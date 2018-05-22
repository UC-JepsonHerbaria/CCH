open(ERR, ">get_smasch_error.txt");
use Time::JulianDay;
use Time::ParseDate;

#Acinetospora nicholsoniae	88609
open(MOSSES,"mosses") || die;
while(<MOSSES>){
	chomp;
	($moss_name,$moss_id)=m/^(.*)\t(.*)/;
	$MOSSES{$moss_id}=$moss_name;
}
close(MOSSES);


#16780	938	annot	A. A. Heller			6	Oct 24 2006  3:16PM	rlmoe	2
#20509	938	coll 	A. A. Heller and B. B. Kennedy			6			20509

open(IN, "nom_comm.out") || die;
while(<IN>){
	chomp;
	@fields=split(/\t/);
	$collector{$fields[0]}=$fields[3] if $fields[2] =~/coll/;
	$anno{$fields[0]}=$fields[3] if $fields[2] =~/annot/;
}

open(IN, "../buffer/tnoan.out") || die;
while(<IN>){
#80761	Aberemoa
chomp;
($tid, $name)=split(/\t/);
$tnoan{$tid}=$name;
}

%seen=();
$today=scalar(localtime());
@today_time= localtime(time);
$thismo=(Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec)[$today_time[4]];
$year= $today_time[5] + 1900;
$catdate= "$thismo $today_time[3] $year";
$today_JD=julian_day($year, $today_time[4]+1, $today_time[3]);
print "Today is $catdate\n";
($year,$month,$day)= inverse_julian_day($today_JD);
print "Today's JD is $today_JD which is $month $day $year\n";
print "NB: Some of the datafiles are updates, some are complete. Records in the datafiles will supersede records in SMASCH\n";
$tnum="";
#1727	UC173596       	2	UC	Univ. Calif. Pub. Bot. 6: 66	1914	 	10924			Kohleria collina Brandegee	UC		0	0	Jul  2 2002 11:25AM	
open(IN, "type_voucher.out") || die;
while(<IN>){
	($count,$aid,$descr)=m/^ +(\d+) ([^ ]+) *\t(.*)/;
	if($seen_type{$aid}){
		$seen_type{$aid} .= $_;
	}
	else{
		$seen_type{$aid} = $_;
	}
}
close(IN);
foreach(keys(%seen_type)){

	$keepline="";
	@types=split(/\n/,$seen_type{$_});
	if(($keepline)= grep(/Holotype:/,@types)){
	}
	elsif(($keepline)= grep(/ectotype:/,@types)){
	}
	elsif(($keepline)= grep(/eotype:/,@types)){
	}
	elsif(($keepline)= grep(/Isotype:/,@types)){
	}
	elsif(($keepline)= grep(/yntype:/,@types)){
	}
	elsif(($keepline)= grep(/Cotype:/,@types)){
	}
	elsif(($keepline)= grep(/Type:/,@types)){
	}
	elsif(($keepline)= grep(/Fragment:/,@types)){
	}
	elsif(($keepline)= grep(/Unspecified/,@types)){
	}
	else{
		next;
	}
	$keepline=~s/.*\t//;
	chomp($keepline);
	$storetype{$_}=$keepline;
#print ">$_< $keepline\n";
	}




#die;
######################################
%monthno=(
'1'=>1,
'01'=>1,
'jan'=>1,
'Jan'=>1,
'January'=>1,
'2'=>2,
'02'=>2,
'feb'=>2,
'Feb'=>2,
'February'=>2,
'3'=>3,
'03'=>3,
'mar'=>3,
'Mar'=>3,
'March'=>3,
'4'=>4,
'04'=>4,
'Apr'=>4,
'April'=>4,
'5'=>5,
'05'=>5,
'may'=>5,
'May'=>5,
'6'=>6,
'06'=>6,
'jun'=>6,
'Jun'=>6,
'June'=>6,
'7'=>7,
'07'=>7,
'jul'=>7,
'Jul'=>7,
'July'=>7,
'8'=>8,
'08'=>8,
'aug'=>8,
'Aug'=>8,
'August'=>8,
'9'=>9,
'09'=>9,
'sep'=>9,
'Sep'=>9,
'Sept'=>9,
'September'=>9,
'10'=>10,
'oct'=>10,
'Oct'=>10,
'October'=>10,
'11'=>11,
'nov'=>11,
'Nov'=>11,
'November'=>11,
'12'=>12,
'dec'=>12,
'Dec'=>12,
'December'=>12
);
######################################





sub get_genus{
	local($_)=@_;
	s/([a-z]) .*/$1/;
	return $_;
}


######################################
%monthno=(
'Jan'=>1,
'Feb'=>2,
'Mar'=>3,
'Apr'=>4,
'May'=>5,
'Jun'=>6,
'Jul'=>7,
'Aug'=>8,
'Sep'=>9,
'Oct'=>10,
'Nov'=>11,
'Dec'=>12,
);
%monthno=reverse(%monthno);
######################################
open (IN, "annotation_asfiled.out") || die;
#JEPS101847	Apr 23 2003  9:58AM	79218	0	8921		0	0	0	0	bulkloaded from DWT Apr 23 2003	1	Jul 27 2006  3:29PM	frontdesk	y
while(<IN>){
	($aid,$date,$tid,@residue)=split(/\t/);
$aid=~s/ *$//;
next unless $aid=~/^(UC|JEPS)/;
++$count;
	$TID{$aid}= $tid;
$AAF{$aid}=$tnoan{$tid};
}
warn " $count AAF read\n";
$count=0;
#die;
#JEPS10         	19		Feb  6 1998  9:36AM
#JEPS10         	20		Feb  6 1998  9:35AM
#JEPS10         	21		Feb  6 1998  9:36AM
#JEPS10         	33		Feb  6 1998  9:36AM
#JEPS10         	61	3/3	Feb  6 1998  9:35AM

open(IN,"voucher.out") || die;

while(<IN>){
	chomp;
	($aid,$voucher_id,$desc,@residue)=split(/\t/);
	$aid=~s/ *$//;
next unless $aid=~/^(UC|JEPS)/;
++$count;
	$cdl_voucher{$aid}.="\t$voucher_id\t$desc";
}
print "$count vouchers entered\n";
$count=0;

open (IN, "accession.out") || die;
#UC1127062      	-1	2671	2671	1				145	USA	CA	San Luis Obispo	Arroyo Grande Quad., se of Newsom Springs	Newsom Springs	.5 mi se; Plot 3	450 ft			fl/fr	no TRS section given; Locality as "Newsom Springs" in packet, "Newsome Springs" on coll. label	32S13E				35.144001007080078	-120.56590270996094	1	Mar 17 1998  4:46PM	cengland	Mar 18 1936	2428246	2428246	<unk>				trs2LL	3.000	mi

open(OUT, ">CDL_main.in") || die;
while(<IN>){
	chomp;
	@fields=split(/\t/);
	unless ($fields[0]=~/^(UC|JEPS)/){
		warn "skipping $fields[0]\n" unless $fields[0]=~/DHN/;
print ERR "$fields[0] not UC\n";
		next;
	}
	unless ($fields[10]=~/^(CA|ca)$/){
		#print "skipping $fields[0] $fields[10]\n";
print ERR "$fields[0] not CA\n";
		next;
	}
	unless ($fields[4] =~/^[231789]/){
		warn "skipping $fields[0] $fields[4]\n" unless $seen{$fields[4]}++;
print ERR "$fields[0] not specimen $fields[4]\n";
		next;
	}
		#print "$accession_id $AAF{$accession_id}\n";
	grep(s/ +$//,@fields);
	grep(s/^ +//,@fields);
	grep(s/\t/ /g,@fields);
	$fields[0]=uc($fields[0]);
		unless( $AAF{$fields[0]}){
print ERR "$fields[0]  no folder name entry\n";
$count--;
next;
}
	if($MOSSES{$TID{$fields[0]}}){
		#print "$accession_id Br: ", $AAF{$fields[0]}, "\n";
		#die;
print ERR "$fields[0]  Moss$AAF{$fields[0]}\n";
$count--;
		next;
	}
if ($not_distinct{$fields[0]}++){
print ERR "$fields[0] apparent duplicate\n";
	next;
}

	++$count;

	( $accession_id,
	$null,
	$coll_committee_id,
	$coll_num_person_id,
	$objkind_id,
	$inst_abbr,
	$coll_num_prefix,
	$coll_num_suffix,
	$coll_number,
	$loc_country,
	$loc_state,
	$loc_county,
	$loc_other,
	$loc_place,
	$loc_distance,
	$loc_elevation,
	$loc_coords,
	$loc_verbatim,
	$phenology,
	$notes,
	$loc_coords_trs,
	$loc_meridian,
	$loc_lat_deg,
	$loc_long_deg,
	$loc_lat_decimal,
	$loc_long_decimal,
	$coord_flag,
	$catalog_date,
	$catalog_by,
	$datestring,
	$early_jdate,
	$late_jdate,
	$bioregion,
	$mod_date,
	$mod_by,
	$datum,
	$lat_long_ref_source,
	$max_error_distance,
	$max_error_units
	)=@fields;
	$accession_id=~s/ *$//;
	$loc_county=ucfirst($loc_county);

	$elevation=~s/(\d),(\d\d\d)/$1$2/g;
	$location = "$loc_distance | $loc_place | $loc_other |  $loc_verbatim";
	foreach($location){
		s/ \| /\t/g;
		s/^ *\|/\t/g;
		s/\| *$/\t/g;
		if(s/^ *\t[\t ]*//){
			s/\t/ - /g;
		}
		else{
			$_=&make_one_loc($location);
		}
		if (m/([^\x00-\x7f]+)/){
			$_=&get_entities($location);
		}
		foreach(split(/[ \|\/-]+/, $_)){
			s/&([a-z])[a-z]*;/$1/g;
			s/[^A-Za-z]//g;
			$_=lc($_);
			next if length($_)<3;
			next if m/^(road|junction|san|near|the|and|along|hwy|side|from|nevada|above|north|south|between|county|end|about|miles|just|hills|area|quad|slope|west|east|state|air|northern|below|region|quadrangle|cyn|with|mouth|head|old|base|collected|city|lower|beach|line|mile|california|edge|del|off|ave)$/;
			$CDL_loc_word{$_} .="$accession_id\t";
		}

	}
	$collector= $collector{$coll_committee_id};

	if($cdl_voucher{$accession_id}=~/\t25\t/){
		if($loc_county=~/(Marin|San Diego|Los Angeles|Alameda|Santa Barbara|Contra Costa|Yolo|Unknown|Sacramento|San Francisco)/){
$count--;
print ERR "$fields[0] apparent hort\n";
			next;
			#print "$accession_id is hort\n";
		}
	}
	$county{uc($loc_county)} .= "$accession_id\t";
	$name=$AAF{$accession_id};
	foreach($name){
		$TID_TO_NAME{$TID{$accession_id}}=$name;
		s/subsp\. //;
		s/var\. //;
		s/f\. //;
		next unless length($_)>1;
		$name_list{lc($_)}.= "$accession_id\t";
		($sp=$_)=~s/[^ ]+ +//;
		next unless length($sp)>1;
		$name_list{lc($sp)}.= "$accession_id\t";
		($infra=$sp)=~s/[^ ]+ +//;
		next unless length($infra)>1;
		$name_list{lc($infra)}.= "$accession_id\t";
	}




if($late_jdate =~/^2\d\d\d\d\d\d$/ && $early_jdate =~/^2\d\d\d\d\d\d$/){
if($late_jdate - $early_jdate ==0){
	$date_simple{$early_jdate} .= "$accession_id\t";
##make $fields[8] canonical date
	if($early_jdate > 2374816){
		($year,$month,$day)= inverse_julian_day($early_jdate);
##dates later than 1789
		$datestring = "$monthno{$month} $day $year";
	}
}
elsif($late_jdate - $early_jdate > 0 &&
$late_jdate - $early_jdate < 2000){
	$date_range{"$early_jdate-$late_jdate\t"} .= "$accession_id\t";
}
}



$loc_lat_decimal="" if $loc_lat_decimal =~/null/i;
$loc_long_decimal="" if $$loc_long_decimal =~/null/i;
#name field not printout
foreach($collector){
#s/ \(with ([^)]+)\)/, $1/;
s/Andrï¾Ž/Andr&eacute;/;
s/AndrŽe/Andr&eacute;/;
s/AndrŽ/Andr&eacute;/;
s/André/Andr&eacute;/;
s/BeauprÃ©/Beaupr&eacute;/;
s/BoÃ«r/Bo&euml;r/;
s/Brinkmann-Bus’/Brinkmann-Bus&eacute;/;
s/ÒCorkyÓ/"Corky"/;
s/Garc’a/Garc&iacute;a/;
s/ÿhorne/Thorne/;
s/LaferriÃ¨re/Laferri&egrave;re/;
s/LaPré/LaPr&eacute;/;
s/LaPrï¿½/LaPr&eacute;/;
s/LaPrï¾Ž/LaPr&eacute;/;
s/LaPrŽ/LaPr&eacute;/;
s/Mu–oz/Mu&ntilde;oz/;
s/Muï¾–oz/Mu&ntilde;oz/;
s/NiedermŸller/Niederm&uuml;ller/;
s/Nordenskišld/Nordenski&ouml;ld/;
s/Oï¿½Berg/O'Berg/;
s/Oï¿½Brien/O'Brien/;
s/Oï¿½/O'/;
s/OrdÃ³Ã±ez/O&d\oacute;&ntilde;ez/;
s/Pe–alosa/Pe&ntilde;alosa/;
s/Peñalosa/Pe&ntilde;alosa/;
s/RenŽe/Renee/;
s/Renée/Renee/;
s/Steve Boyd`/Steve Boyd/;
s/Sšzer 
zelkŸk/S&ouml;zer &Ouml;zelk&ouml;k/;
s/Vern` Yadon/Vern Yadon/;
s/Villaseï¾–or/Villase&ntilde;or/;
s/Villanse–or/Villase&ntilde;or/;
s/Villase–or/Villase&ntilde;or/;
s/Villaseñor/Villase&ntilde;or/;
s/HÃ¶lzer/H&ouml;zer/;
}
	if($collector=~m/^[A-Z]\. ?[A-Z]\. ?[A-Z]\.$/){
$collector=&expand_initials($collector);
	}
$coll=$collector;
foreach($coll){
$_=&modify_collector($_);
	$all_names{$_}.="$accession_id\t" unless $seen{$accession_id}++;
}

####NOTES
foreach($notes){
	s/county supplied by Wetherwax;//;
	if (length($_)>4){
		$CDL_notes{$accession_id}=$_;
	}
		$num=$coll_number;

		if($num=~/[0-9a-zA-Z]/){
			$num=~s/^ *//;
			$num=~s/^[-# ]+//;
			$num=~s/ *$//;
			unless($num=~/^s\.?n\.?$/i){
				$accession_id=~s/ *$//;
				$num{$num}.="$accession_id\t";
			}
		}
}
#########

			print  OUT "$accession_id $TID{$accession_id}\t", join("\t",
$collector,
$coll_num_prefix,
$coll_number,
$coll_num_suffix,
$early_jdate,
$late_jdate,
$datestring,
$loc_county,
$loc_elevation,
$location,
$loc_lat_decimal,
$loc_long_decimal,
$datum,
$lat_long_ref_source,
$loc_coords_trs,
$max_error_distance,
$max_error_units), "\n";
}
print "$count accessions loaded\n";


close(OUT);

############################################################

open(OUT, ">CDL_collectors.in") || die;
foreach (sort (keys(%all_names))){
	print OUT "$_ $all_names{$_}\n";
}
close(OUT);

############################################################

open(OUT, ">CDL_counties.in") || die;
foreach (sort (keys(%county))){
	$orig=$_;
	s/ /_/g;
	print "$_\n" unless $seen{$_}++;
	print OUT "$_ $county{$orig}\n";
}
close(OUT);

############################################################

open(OUT, ">CDL_tid_to_name.in") || die;
foreach (sort (keys(%TID_TO_NAME))){
	print OUT "$_ $TID_TO_NAME{$_}\n";
}
close(OUT);

############################################################

open(OUT, ">CDL_date_simple.in") || die;
foreach (sort (keys(%date_simple))){
	print OUT "$_ $date_simple{$_}\n";
}
close(OUT);

############################################################

open(OUT, ">CDL_date_range.in") || die;
foreach (sort (keys(%date_range))){
	print OUT "$_ $date_range{$_}\n";
}
close(OUT);

############################################################

open(OUT, ">CDL_name_list.in") || die;
foreach(sort(keys(%name_list))){
	print OUT "$_ $name_list{$_}\n";
}
close(OUT);

############################################################

open(OUT, ">CDL_loc_list.in") || die;
foreach(sort(keys(%CDL_loc_word))){
	print OUT "$_ $CDL_loc_word{$_}\n";
}
close(OUT);


############################################################

open(OUT, ">CDL_coll_number.in") || die;
foreach (sort (keys(%num))){
	print  OUT "$_ $num{$_}\n";
}
close(OUT);


############################################################

open(OUT,">CDL_voucher.in") || die;
foreach $key (sort(keys(%cdl_voucher))){
		if($cdl_voucher{$key}=~m/56/){
#print ">$key< $cdl_voucher{$key}\n";
}
	if($storetype{$key}){
		($cdl_voucher{$key}=~s/\t56\t[^\t]*/\t56\t$storetype{$key}/) ||
($cdl_voucher{$key}.="\t56\t$storetype{$key}");
#print "$key : $cdl_voucher{$key}\n";
}
print OUT "$key$cdl_voucher{$key}\n";
}
close(OUT);

############################################################

open(OUT,">CDL_notes.in") || die;
foreach(sort(keys(%CDL_notes))){
($key=$_)=~s/ *$//;
print OUT "$key\t$CDL_notes{$_}\n";
}
close(OUT);


############################################################

#6	Agoseris intermedia Greene	6
open(IN, "vname.out") || die;
while(<IN>){
	chomp;
	($id,$vname,@residue)=split(/\t/);
	$vname{$id}=$vname;
}

open(IN, "annotation_hist.out") || die;
while(<IN>){
	chomp;
#195222	JEPS090765     	3097	2006	2453737	2454101	33773	0	 	0	0	0	Jun  8 2006  1:39PM	rosatti
	($null,$aid,$annotator_id,$date,$null,$null,$tid,$vname_id,$notes,@residue)=split(/\t/);
	$aid=uc($aid);
	$aid=~s/ *$//;
next unless $aid=~/^(UC|JEPS)/;
	if($tid==0){
		$cdl_anno{$aid}.="$vname{$vname_id}; $date; $anno{$annotator_id}; $notes\n";
#warn "vname: $vname_id $vname{$vname_id}\n";
	}
	else{
		$cdl_anno{$aid}.="$tnoan{$tid}; $date; $anno{$annotator_id}; $notes\n";
	}
}

#UC722137 Castilleja applegatei	Castilleja pruinosa
{
local $/="\n";
open(IN, "uc_hybrids") || die;
	while(<IN>){
		chomp;
		if(s/^([^ ]+) //){
			$key=$1;
			s/\t*$//;
			s/\t/ X /g;
			$cdl_anno{$key}.="$_; ; hybrid parentage\n"
		}
	}
}
open (OUT, ">CDL_annohist.in") || die;
foreach(sort(keys(%cdl_anno))){
	print OUT "$_\n$cdl_anno{$_}\n";
}

############################################################

open(OUT, ">CDL_bad_date") || die;
foreach(keys(%null_date)){
print OUT "bad date: $null_date{$_}: $_ \n";
}
close(OUT);
print "$skip_accession accession numbers supplanted\n";
$tar_return=system 'tar -cf cdl_tar CDL*';
print "tar file cdl_tar $tar_return\n";

die;
unlink "CDL_coll_number.in";
unlink "CDL_collectors.in";
unlink "CDL_counties.in";
unlink "CDL_date_range.in";
unlink "CDL_date_simple.in";
unlink "CDL_loc_list.in";
unlink "CDL_main.in";
unlink "CDL_name_list.in";
unlink "CDL_tid_to_name.in";
unlink "CDL_annohist.in";
unlink "CDL_voucher.in";
unlink "CDL_notes.in";
#open (OUT, ">CDL_conversion") || die;
#print OUT $convert;
#close OUT;

sub modify_collector {
local($_)=shift;
	if(m/^[A-Z]\. ?[A-Z]\. ?[A-Z]\.$/){
$_=&expand_initials($_);
	}
s/,? Jr\.?//;
s/&([a-z])[a-z]*;/$1/g;
			if(m/[A-Z]\. ?[A-Z]\. ?[A-Z]\.$/){
				$all_names{$_}.="$hn\t" unless $seen{$hn}++;
				next;
			}
			s/,? [Ee][tT] .*//;
			s/^([A-Z][A-Z][A-Z]+) [A-Z].*/$1/;
#Harold and Virginia Bailey
			s/^[A-Z][a-z]+ and ?[A-Z][a-z-]+ ([A-Z][a-z-]+$)/$1/;
			s/^[A-Z]\. ?[A-Z]\. and [A-Z]\. ?[A-Z]\. (.*)/$1/;
			s/^[A-Z]\. and [A-Z]\. (.*)/$1/;
			s/ \(?(with|and) .*//;
			s/[;,] .*//;
			#s/, .*//;
			s/^.* //;
s/&(.)[^;]*;/\1/g && print "$_\n";
			return ucfirst(lc($_));
}
sub expand_initials {
local($_)=shift;
		s/C\. A\. P\./C. A. Purpus/;
		s/C\. F\. B\./C. F. Baker/;
		s/C\.F\.B\./C.F. Baker/;
		s/E\. L\. G\./E. L. Greene/;
		s/F\. A\. M\./F. A. MacFadden/;
		s/H\. M\. H\./H. M. Hall/;
		s/I\. J\. C\./I. J. Condit/;
		s/M\. K\. C\./M. K. Curran/;
		s/R\. J\. S\./R. J. Smith/;
		s/T\. S\. B\./T. S. Brandegee/;
		s/W\. A\. S\./W. A. Setchell/;
		s/W\. B\. C\./William Bridge Cooke/;
		s/W\. L\. J\./W. L. Jepson/;
$_;
}
sub get_entities{
local($_)=shift;
#warn "$_\n";
study();
s/\xef\xbf\xbd\xef\xbf\xbd/"/g; 
s/\xef\xbf\xbd/'/g; 
s/\xef\xbf\x95/'/g; 
s/\xef\xbe\xbc/&deg;/g; 
s/\xef\xbe\xb1/&plusmn;/g; 
s/\xef\xbe\xb0/&deg;/g; 
s/\xef\xbe\xa1/&deg;/g; 
s/\xef\xbe\x96/&ntilde;/g; 
s/\xef\xbe\x8e/&eacute;/g; 
s/\xef\xbe\x84/N/g; 
s/\xe2\x80\xa6/.../g; 
s/\xe2\x80\x9d/"/g; 
s/\xe2\x80\x99/'/g; 
s/\xe2\x80\x93/&plusmn;/g; 
s/\xf1\xf3/&ntilde;&oacute;/g; 
s/\xef\xbf/&deg;/g; 
s/\xef\xbe/&deg;/g; 
s/\xc3\xb1/&ntilde;/g; 
s/\xc3\xab/&euml;/g; 
s/\xc3\xa9/&eacute;/g; 
s/\xc3\xa8/&egrave;/g; 
s/\xc2\xbe/3\/4/g; 
s/\xc2\xbd/1\/2/g; 
s/\xc2\xbc/1\/4/g; 
s/\xc2\xba/&deg;/g; 
s/\xc2\xb1/&plusmn;/g; 
s/\xc2\xb0/&deg;/g; 
s/\xb1\xbd/&plusmn;1\/2/g; 
s/\xff/T/g; 
s/\xfb/&deg;/g; 
s/\xf5/B/g; 
s/\xf3/&oacute;/g; 
s/\xf1/&ntilde;/g; 
s/\xef/&deg;/g; 
s/\xed/I/g; 
s/\xeb//g; 
s/Andr\x8ee/Andre&eacute;/g;
s/\x9a/&ouml;/g;
s/\xa7/S/g;
s/\xb9/P/g;
s/\xe9/&eacute;/g; 
s/\xe4/R/g; 
s/\xe1//g; 
s/\xd7//g; 
s/\xd4/'/g; 
s/\xd3/"/g; 
s/\xd2/"/g; 
s/\.\.\.\./"/g;
s/\xd0/-/g; 
s/\xca/  /g; 
s/\xbe/3\/4/g; 
s/\xbd/1\/2/g; 
s/\xbc/1\/4/g; 
s/\xb3/&plusmn;/g; 
s/\xb2/&plusmn;/g; 
s/\xb1/&plusmn;/g; 
s/\xb0/&deg;/g; 
s/\xab/'/g; 
s/\xa1/&deg;/g; 
s/\xa0/.../g; 
s/\x9f/&uuml;/g; 
s/\x96/&ntilde;/g; 
s/\x94/"/g; 
s/\x93/"/g; 
s/Garc\x92/Garc&iacute;/g; 
s/\x92/'/g; 
s/\x8e/&eacute;/g; 
s/\x86/U/g; 
s/\x85/.../g; 
s/\x84/N/g; 
s/\x82/C/g; 
s/\x81/A/g; 
s/Â½/1\/2/g;
s/Â¼/1\/4/g;
#warn "$_\n";
$_;
}

	sub make_one_loc {
	local($_)=shift;
$start=$_;
@other=();
	$first_distance=$second_distance=$distance,$place,$other,$verb="";
	($distance,$place,$other,$verb)=split(/\t/);
$distance=~s/; *$//;
	if($other){
		@other=split(/[,;] /,$other);
				foreach $i (0 .. $#other){
					if($other[$i]eq $place){
						$other[$i]="";
					}
				}
	$other=join(", ", @other);
	}
	if($place eq $other){
		$other="";
	}
	if (length($distance) > 0){
			if($place eq $distance){
				$place="";
			}
			if($other){
				@other=split(/[,;] /,$other);
					foreach $i (0 .. $#other){
						if($other[$i]eq $distance){
							$other[$i]="";
						}
					}
			$other=join(", ", @other);
			}
			if($distance=~/(.*); (.*)/){
			$first_distance=$1;
			$second_distance=$2;
				if($place eq $first_distance){
					$place="";
				}
			if($other){
				@other=split(/[,;] /,$other);
					foreach $i (0 .. $#other){
						if($other[$i]eq $first_distance){
							$other[$i]="";
						}
						if($other[$i]eq $second_distance){
							$other[$i]="";
						}
					}
			$other=join(", ", @other);
			}
			if (length($place) >2){
				if($other){
					@other=split(/[,;] /,$other);
						foreach $i (0 .. $#other){
							if($other[$i]eq $place){
								$other[$i]="";
							}
						}
						$other=join(", ", @other);
				}
				($tot_loc=$distance)=~s/; (.*)/ $place ($1) - $other - $verb/;
			}
			elsif (length($other) >2){
				($tot_loc=$distance)=~s/; (.*)/ $other ($1) - $verb/;
			}
			#3#
			else{
				$tot_loc="$distance - $verb";
			}
			#3#
		}
		###########
		else{
				if($place eq $distance){
					$place="";
				}
			if($other){
				@other=split(/[,;] /,$other);
					foreach $i (0 .. $#other){
						if($other[$i]eq $distance){
							$other[$i]="";
						}
					}
			$other=join(", ", @other);
			}
			if (length($place) >2){
				if($other){
					@other=split(/[,;] /,$other);
						foreach $i (0 .. $#other){
							if($other[$i]eq $place){
								$other[$i]="";
							}
						}
						$other=join(", ", @other);
				}
				$tot_loc="$distance $place - $other - $verb";
			}
			elsif (length($other) >2){
				$tot_loc="$distance $other - $verb";
			}
			#2#
			else{
				$tot_loc="$distance - $place -  $other - $verb";
			}
			#2#
		}
		###########
	}
	else{
		if (length($place) >1){
			if($other){
				@other=split(/[,;] /,$other);
					foreach $i (0 .. $#other){
						if($other[$i]eq $place){
							$other[$i]="";
						}
					}
			$other=join(", ", @other);
			}
				$tot_loc="$place - $other - $verb" unless $place eq $other;
			}
		elsif (length($other) >1){
				$tot_loc="$other $verb";;
				}
		elsif (length($verb) >1){
				$tot_loc="$verb";;
		}
}
if (length($tot_loc) > 3){
$tot_loc=~s/  */ /g;
$tot_loc=~s/ $//g;
$tot_loc=~s/^ *//g;
$tot_loc=~s/[ -]*$//g;
}
if($tot_loc=~/Pea Ridge.*Salmon/){
print "$start\n$tot_loc\n";
	print <<EOP;
DISTANCE: $distance
PLACE: $place
OTHER: $other
VERB: $verb
FIRST: $first_distance
SECOND: $second_distance
EOP
}
print "$start\n$tot_loc\n" if length($tot_loc) <2;
return $tot_loc;
}
