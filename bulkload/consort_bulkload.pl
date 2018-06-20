#consort_bulkload.pl
@time=localtime(time);
$this_year=$time[5] + 1900;
use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA/';
use CCH;
use Smasch;

#there is a load_noauth_name in both Smasch.pm and CCH.pm.
#this is using the CCH one
#the Smasch one (and the module in general) should be retired
&load_noauth_name(); 

open(IN, "other_inputs/CDL_skip_these" ) || die; #see if you can get rid of this file by making corrections in home databases (or seeing if it has already been done)
while(<IN>){
	chomp;
	$skip_it{$_}++;
}
close(IN);

%magic_no =( #used for objkind_id in this script
	'Mounted_on_paper'=>1,
	'types_cabinet'=>2,
	'main_coll'=>1,
	'reference_coll'=>4,
);

open(WARNINGS,">logs/consort_bulkload_warn") || die;

%seen=();
$today=scalar(localtime());
@today_time= localtime(time);
$thismo=(Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec)[$today_time[4]];
$year= $today_time[5] + 1900;
$catdate= "$thismo $today_time[3] $year";
$today_JD=julian_day($year, $today_time[4]+1, $today_time[3]);
warn "Today is $catdate\n";
($year,$month,$day)= inverse_julian_day($today_JD);
warn "Today's JD is $today_JD which is $month $day $year\n";
warn "NB: Some of the datafiles are updates, some are complete. Records in the datafiles will supercede records in SMASCH\n";
$tnum="";


open(OUT, ">CDL_main.in") || die;
open(ERR, ">logs/accent_err") || die;
open(IMG, ">CDL_image_links.txt") || die;


open(CULT, ">CDL_cultivated_ids.txt") || die;

#print "known cultivated" ids to the cultivated ids file
open(IN, "other_inputs/CDL_known_cultivated_ids.txt");
while (<IN>) {
	chomp;
	my $cult_id=$_;
	next if $_ =~/^#/;	
	print CULT "$_";
}

######################################
%monthno = &month_hash;

@datafiles=(
"BLMAR_out.txt",
"UCR_out.txt",
"CAS_out.txt",
"CATA_out.txt",
"CDA_out.txt",
"CHSC_out.txt",
"CLARK_2015.out", #CLARK sends their files in confusing chunks, so I'm including the newest parse (2015) along with the last one (2014)
"CLARK_2014.out",
"CSPACE_out.txt",
"CSUSB.out",
"GMDRC_out.txt",
"HSC.out",
"HUH.out",
"IRVC.out",
"JOTR.out",
"JROH_out.txt",
"LA.out",
"MACF.out",
"NY.out",
"OBI.out",
"PASA.out",
"PGM.out",
"RSA_specify_out.txt", #load all files from RSA's current database load
"RSA_fmp_out.txt", #then load any other records that are still only in their old FMP database
"SACT.out",
"SBBG.out",
"SCFS_out.txt",
"SD_out.txt",
"SDSU_out.txt",
"SEINET_out.txt",
"SFV.out",
"SJSU.out",
"UCD_out.txt",
"UCSB.out",
"UCSB_from_smasch.txt", #if there are duplications in this from SMASCH file, the one from the other file will be taken since it is processed first in this list
"UCSC_out.txt",
"VVC.out",
"YM.out"
);
$data_files_path = "data_files";

foreach $datafile (@datafiles){
	next if $datafile=~/#/;
	#%seen_dups=();
	#system "uncompress ${datafile}.Z";
	print $datafile, "\n";
	open(IN,"$data_files_path/$datafile")|| die;
	$/="";
	while(<IN>){
		#next unless m/564576/;
		next if m/^#/;
		s/  +/ /g;
		@anno=();
		(@anno)=m/Annotation: (...+)/g;

		#print join("\n",@anno), "\n\n" if @anno;
		++$countpar;
		if (s/Accession_id: (...*)/Accession: $1/){
			if($skip_it{$1}){
				print WARNINGS "skipping $1 on skip list CDL_skip_these\n";
				next;
			}
			if($seen_dups{$1}){
				print WARNINGS "skipping $1 duplicate from $seen_dups{$1}\n";
				$seen_dups{$1}.=" $datafile";
				next;
			}
			else{
				$seen_dups{$1}=$datafile;
				process_entry($_);
			}
		}
		else{
			print WARNINGS "skipping $.\n";
		}
	}
}
print <<EOP;
paragraph count: $countpar
entries processed: $countprocess
collectors: $countcoll
entries printed: $countprint
$nocnum without cnum
EOP
#die;

sub process_entry {
$oc="";
	$all_collectors="";
	local($/)="";
	$_ = shift;
	foreach($_){
		s/\0//g; #remove any and all null bytes
		s/\x00//g; #remove any and all null bytes
		#### I think this works at this level, to remove all null bytes from each paragraph
		#### but I haven't confirmed it yet, because the null byte would hide after bulkload and re-emerge in the DwC-A on the IPT
	}
	
	
	++$countprocess;
	s/Associated_with:/Associated_species:/;
	my(@suppl)=();
	%T_line=();
	($hn)=m/Accession: *(.*)/;
	$hn=uc($hn);
	$hn=~s/ *$//;
	if(m/Collector: ([A-Za-z].*)/){
		$collector=$1;
#next if $coll_seen{$collector}++;
#print <<EOP;
#1: $collector
#EOP
		foreach($collector){

			s/Renée/Renee/;
			s/RenÈe/Renee/;
			s/Steve Boyd`/Steve Boyd/;
			s/Vern` Yadon/Vern Yadon/;

			s/“Corky”/"Corky"/;
			s/ˇhorne/Thorne/;
			
			s/\xc2\xbd/1\/2/g;

			s/\xc2\xbc/1\/4/g;

		
			s/LaDoux/La Doux/; #because Tasha La Doux is sometimes incorrectly recorded as LaDoux
		}
		++$countcoll;
		$assignor=$collector;
#print <<EOP;
#2: $collector
#EOP

		if(m/Combined_coll[^:]*: (.+)/){
			$collector =$1;
#print <<EOP;
#3: $collector
#EOP
		}
		elsif(m/(More|Other)_coll[^:]*: (.+)/){
			$oc=$2;
			if(m/Combined_coll[^:]*: (..+)/){
				$collector =$1;
#print <<EOP;
#4: $collector
#EOP
			}
			else{
if($oc){
				$collector .= ", $oc";
}
#print <<EOP;
#5: $collector
#EOP
			}
		}


		$collector=~s/Sent in for det: //;
		$collector=~s/Submitted for det: //;

		$collector=~s/ s\.n.*//;
		$collector=~s/Unknown, Bot. 108/unknown/;
		$collector=~s/collector unknown/unknown/;
		$collector=~s/Unknown collector/unknown/;
		$collector=~s/ *$//;
		$collector=~s/,,/,/g;
		$collector=~s/, others/, and others/;
		$collector=~s/, C. N. P. S./, and C. N. P. S./;

		$all_collectors=$collector;
#print <<EOP;
#6: $collector
#EOP


		foreach($collector){
			$_=&get_entities($_);
			$_=&modify_collector($_);
			$all_names{$_}.="$hn\t" unless $seen{$hn}++;
#print <<EOP;
#7: $collector
#EOP
		}
	}
	else{
		$assignor="unknown"; $collector="unknown";
	}

	if(m/CNUM:(.*)/){
		$tnum=uc($1);
		$tnum=~s/ *$//;
		$tnum=~s/^0*//;
		if(m/EJD: (\d+)/){
			$JD=$1;
			if(m/LJD: (\d+)/){
				$LJD=$1;
			}
			if(m/Date: +(.*)/){

$ds=$1;
$vdate=$1;


if($vdate=~/([12][890]\d\d)/){
$vyear=$1;
if ($vyear < 1800){
warn "BAD YEAR $vyear $_\n";
				print WARNINGS "$hn Misentered date $vdate; setting jdate to null $ds\n";
#$vdate=""; $JD=""; $EJD="";
}
if ($vyear > $this_year){
warn "BAD YEAR$vyear $_\n";
				print WARNINGS "$hn Misentered date $vdate; setting jdate to null $ds\n";
#$vdate=""; $JD=""; $EJD="";
}
}

					$T_line{Date}=  "$vdate";



			}
					else{
					warn "No verbatim date, but JD is $EJD\n";
					$T_line{Date}=  "";
					}
			if($JD > $today_JD){
				print WARNINGS "$hn Misentered date $JD > $today_JD; setting jdate to null $ds\n";
				$null_date{$ds}=$hn;
				$LJD=$JD="";
			}
			if($JD - $LJD ==0){
				$date_simple{$JD} .= "$hn\t";
##make $fields[8] canonical date
				if($JD > 2374816){
					($year,$month,$day)= inverse_julian_day($JD);
##dates later than 1789
					unless($T_line{Date}){
						$T_line{Date}=  "$monthno{$month} $day $year";
					}
				}
			}
			elsif($LJD - JD > 0 &&
				$LJD - $JD < 2000){
				$date_range{"$JD-$LJD\t"} .= "$hn\t";
			}
		}
		elsif(m/Date: +(.*)/){
$vdate=$1;
$ds=$1;


if($vdate=~/([12][890]\d\d)/){
$vyear=$1;
if ($vyear < 1800){
warn "BAD YEAR $vyear $_\n";
				print WARNINGS "$hn Misentered date $vdate; setting jdate to null $ds\n";
$vdate=""; $JD=""; $EJD="";
}
if ($vyear > $this_year){
warn "BAD YEARav$year $_\n";
				print WARNINGS "$hn Misentered date $vdate; setting jdate to null $ds\n";
$vdate=""; $JD=""; $EJD="";
}
}
			$ds=$vdate;
			foreach($ds){
				$LJD=$JD="";
				s/  */ /g;
				s/ $//;
				s/ *\?//;
				if(m|(\d\d?)/(\d\d?)/([0-9][0-9])$|){
					$JD=julian_day("19$3", $1, $2);
					$LJD=$JD;
#$par="1";
				}
				elsif(m|(\d\d) (\d\d) ([12]\d[0-9][0-9])$|){
					$JD=julian_day("$3", $1, $2);
					$LJD=$JD;
					#print "1 ";
#$par="2";
				}
				elsif(m|(\d\d?)/(\d\d?)/19([0-9][0-9])$|){
					$JD=julian_day("19$3", $1, $2);
					$LJD=$JD;
					#print "2 ";
#$par="3";
				}
#bad date: DS735113: 1961-08-26 
			elsif(m|^([12][0789]\d\d)-(\d+)-(\d+)$|){
					$year=$1;
					$day_month=$3;
					$monthno=$2;
					$day_month=~s/^0//;
					$monthno=~s/^0//;
					$JD=julian_day($year, $monthno, $day_month);
					$LJD=$JD;
					#print "$_ year: $year month: $monthno day: $day_month $JD $LJD\n";
#$par="11a";
			}
				elsif(m|(\d\d?)/(\d\d?)/20(0[0-9])$|){
					$JD=julian_day("20$3", $1, $2);
					$LJD=$JD;
					#print "3 ";
#$par="4";
				}
######################
				elsif( m|([A-Za-z0-9]+)\.? (\d\d?),? (1[89]\d\d)$| && $monthno{$1}){
					$monthno=$monthno{$1};
					$day_month=$2;
					$year=$3;
					$JD=julian_day($year, $monthno, $day_month);
					$LJD=$JD;
				}
				elsif( m|([A-Za-z0-9]+)\.? (\d\d?),? (20\d\d)$| && $monthno{$1}){
					$monthno=$monthno{$1};
					$day_month=$2;
					$year=$3;
					$JD=julian_day($year, $monthno, $day_month);
					$LJD=$JD;
					#print "5 ";
#$par="6";
				}
				elsif( m|^(\d+) ([A-Za-z]+)\.? ([12][089]\d\d)$| && $monthno{$2}){
					$monthno=$monthno{$2};
					$day_month=$1;
					$year=$3;
					$JD=julian_day($year, $monthno, $day_month);
					$LJD=$JD;
				}
######################
				elsif( m|^([A-Za-z0-9]+)\.?,? (\d\d\d\d)$| && $monthno{$1}){
					$monthno=$monthno{$1};
					$day_month=1;
					$year=$2;
					$JD=julian_day($year, $monthno, $day_month);
##$par="7";
					if($monthno==12){
						$lmonthno=1;
						$lyear=$year+1;
						$day_month=1;
#$par="8";
					}
					else{
						$lyear=$year;
						$lmonthno=$monthno+1;
						$day_month=1;
#$par="9";
					}
					$LJD=julian_day($lyear, $lmonthno, $day_month);
					$LJD-=1;
				#print "6 ";
#$par="10";
				}
				elsif( m|^([A-Za-z]+)-([A-Za-z]+),? (\d\d\d\d)$| && $monthno{$1} && $monthno{$2}){
					$s_monthno=$monthno{$1};
					$lmonthno=$monthno{$2};
					$day_month=1;
					$year=$3;
					$JD=julian_day($year, $s_monthno, $day_month);
##$par="7";
					if($lmonthno==12){
						$lmonthno=1;
						$lyear=$year+1;
						$day_month=1;
#$par="8";
					}
					else{
						$lyear=$year;
						$lmonthno=$lmonthno+1;
						$day_month=1;
#$par="9";
					}
					$LJD=julian_day($lyear, $lmonthno, $day_month);
					$LJD-=1;
				#print "6 ";
#$par="10";
				}
				elsif(m/^(\d\d\d\d)$/){
					$JD=julian_day($1, 1, 1);
					$LJD=julian_day($1, 12, 31);
					#print "7 ";
	#$par="11";
				}
				elsif( m|([A-Za-z0-9]+)\.? (\d\d?)-(\d\d?),? ([21][7890]\d\d)$| && $monthno{$1}){
					$monthno=$monthno{$1};
					$s_day_month=$2;
					$e_day_month=$3;
					$year=$4;
					$JD=julian_day($year, $monthno, $s_day_month);
					$LJD=julian_day($year, $monthno, $e_day_month);
					#print "4 ";
#$par="12";
				}
			elsif(m|^([0123]?\d\d?)[-/]([0123]?\d) ([A-Za-z][a-z][a-z]) ([12][0789]\d\d)$| && $monthno{$3}){
					$monthno=$monthno{$3};
					$s_day_month=$1;
					$e_day_month=$2;
					$year=$4;
					$JD=julian_day($year, $monthno, $s_day_month);
					$LJD=julian_day($year, $monthno, $e_day_month);
				#print "7 ";
#$par="11";
			}
			elsif(m|^([0123]?\d\d?)/([A-Za-z][a-z][a-z])/([12][0789]\d\d)$| && $monthno{$2}){
					$monthno=$monthno{$2};
					$s_day_month=$1;
					$year=$3;
					$JD=julian_day($year, $monthno, $s_day_month);
					$LJD=julian_day($year, $monthno, $s_day_month);
				#print "7a ";
#$par="11a";
			}
			elsif(m|^(\d+)/(\d+)/([12][0789]\d\d)$|){
					$monthno=$monthno{$1};
					$s_day_month=$2;
					$year=$3;
					$JD=julian_day($year, $monthno, $s_day_month);
					$LJD=julian_day($year, $monthno, $s_day_month);
				#print "7a ";
#$par="11a";
			}
				elsif( m|^(\d\d\d\d)-(\d\d\d\d)|){
					$JD=julian_day($1, 1, 1);
					$LJD=julian_day($2, 12, 31);
					}
			elsif(m|^(\d+)[*-](\d+)[*-]([12][0789]\d\d)$|){
					$monthno=$monthno{$1};
					$s_day_month=$2;
					$year=$3;
					$JD=julian_day($year, $monthno, $s_day_month);
					$LJD=julian_day($year, $monthno, $s_day_month);
#$par="11a";
			}
			else{
				#warn "$hn Unexpected date; setting jdate to null $ds\n";
				$null_date{$ds}=$hn;
				$LJD=$JD="";
			}
			if($JD > $today_JD){
				print WARNINGS "$hn Misentered date $JD > $today_JD; setting jdate to null $ds\n";
				$null_date{$ds}=$hn;
				$LJD=$JD="";
			}
			if($JD - $LJD ==0){
				$date_simple{$JD} .= "$hn\t";
##make $fields[8] canonical date
				if($JD > 2374816){
					($year,$month,$day)= inverse_julian_day($JD);
##dates later than 1789
					$T_line{Date}=  "$monthno{$month} $day $year";
				}
			}
			elsif($LJD - JD > 0 &&
				$LJD - $JD < 2000){
				$date_range{"$JD-$LJD\t"} .= "$hn\t";
			}
		}
	}

	if(m/Name: +(.*)/){
		$old_name=$name=$1;
		($gen=$name)=~s/ [a-z]+.*//;
$gen=~s/ X$//;
		if($exclude{$name}){
warn "Excluded name: $name\n";
			print WARNINGS "$hn EXCLUDED NAME" . $name, &strip_name($name) ."\n";
			return(0);
		}
		if($exclude{$gen}){
warn "Excluded name: $gen\n";
			print WARNINGS "$hn EXCLUDED NAME" . $name, &strip_name($name) ."\n";
			return(0);
		}
		if($name=~/^ *$/){
warn "No name: $name\n";
			print WARNINGS "$hn NO NAME" . $name, &strip_name($name) ."\n";
			return(0);
		}

		if($name=~/aceae/){
warn "FAMILY: $name\n";
			print WARNINGS "$hn FAMILY" . $name, &strip_name($name) ."\n";
			#return(0);
		}
		if($exclude{$gen}){
			print WARNINGS "$hn THIS CAN'T BE STORED: NON VASC>" . $name, &strip_name($name) ."\n";
			return(0);
		}
#	unless($seen_ICPN_genus{$gen}){
			#print WARNINGS "$hn $gen not in ICPN>" . $name, &strip_name($name) ."\n";
			#warn "$hn $gen not in ICPN, but I continue $name\n";
#$not_in_ICPN{$gen}++;
#		}

		foreach($name){


unless($seen_name{$name}++){
		print "$old_name -> $name\n" unless $old_name eq $name;
}
		}


	if($TID{&strip_name($name)}=~/^\d+$/){
		$S_folder{'taxon_id'}= $TID{&strip_name($name)};
		#warn $T_line{'Name'}, &strip_name($name) ."\n";
	}
	else{
		print WARNINGS "$hn THIS CAN'T BE STORED: Something wrong with TID >" . $name, &strip_name($name) ."\n";
		$stripped=  &strip_name($name);
		print "HERE:  $hn cant find $name stripped as $stripped\n";
		return(0);
	}
	
	unless($S_folder{'genus_id'}= $TID{&get_genus($name)}){
			print  WARNINGS "$hn THIS CAN'T BE STORED: Something wrong with >" . $name . "with respect to genus_id extraction\n";
print "$hn $name genus problem\n";
return(0);
		}

#$S_folder{'genus'}= &get_genus($T_line{'Name'});

#$name=~s/Quercus ×macdonaldii/Quercus × macdonaldii/;
#print "$name\n" if $name=~/alvordiana/;

		foreach($name){
			#print $S_folder{'taxon_id'}, "\n" if m/alvordiana/;
			$TID_TO_NAME{$S_folder{'taxon_id'}}=$name;
			s/subsp\. //;
			s/var\. //;
			s/f\. //;
			next unless length($_)>1;
			$name_list{lc($_)}.= "$hn\t";
			($sp=$_)=~s/[^ ]+ +//;
			next unless length($sp)>1;
			$name_list{lc($sp)}.= "$hn\t";
			($infra=$sp)=~s/[^ ]+ +//;
			next unless length($infra)>1;
			$name_list{lc($infra)}.= "$hn\t";
		}

#next;
	}
	s|¨|1/4|g;
	s|º|1/4|g;

@T_line=split(/\n/);

foreach(keys(%S_accession)){
	$S_accession{$_}="";
}
$T_line{'Accession'}=$hn;
$seen_accession{$hn}++;

foreach(@T_line){
	if(m/^([^:]+): +(.+)/){
	$T_line{$1}=$2;
	}
}
	
$T_line{'Name'}=$name;


###############Process coordinates
if($T_line{'Latitude'}){
	($S_accession{'loc_lat_decimal'}, $S_accession{'loc_lat_deg'})= &parse_lat($T_line{'Latitude'});
	if($S_accession{'loc_lat_decimal'} eq ""){
		print WARNINGS "$hn: coordinates nulled $T_line{'Latitude'} $_line{'Longitude'}\n";
	}
	$convert.="$S_accession{'loc_lat_decimal'}, $S_accession{'loc_lat_deg'}\n";
}
else{$T_line{'Longitude'}="";}

if($T_line{'Decimal_latitude'}){
	$S_accession{'loc_lat_decimal'}= $T_line{'Decimal_latitude'};
}
if($T_line{'Longitude'}){
	($S_accession{'loc_long_decimal'}, $S_accession{'loc_long_deg'})= &parse_long($T_line{'Longitude'});
	if($S_accession{'loc_long_decimal'} eq ""){
		print WARNINGS "$hn: coordinates nulled $T_line{'Latitude'} $T_line{'Longitude'}\n";
	}
	$convert.="$S_accession{'loc_long_decimal'}, $S_accession{'loc_long_deg'}\n";
}
else{$T_line{'Latitude'}="";}

if($T_line{'Decimal_longitude'}){
	$S_accession{'loc_long_decimal'}= $T_line{'Decimal_longitude'};
}
if($S_accession{'loc_lat_decimal'}){
	if($S_accession{'loc_lat_decimal'} > 42.1 ||
	$S_accession{'loc_lat_decimal'} < 30.0 || ###was 32.5 for California, now 30.0 to include CFP-Baja
	$S_accession{'loc_long_decimal'} > -114 ||
	$S_accession{'loc_long_decimal'} < -124.5){
		print WARNINGS "$hn: coordinates nulled $S_accession{'loc_lat_decimal'} $S_accession{'loc_long_decimal'}\n";
		$S_accession{'loc_lat_decimal'} = "";
		$S_accession{'loc_long_decimal'} = "";
	}
}


############Country, etc.
	if($T_line{Country}){
		$T_line{Country}="US" if $T_line{Country} eq "U.S.A.";
	}
	else{$T_line{Country}="US";}
	$T_line{CNUM}=~s/(\d),(\d\d\d)/$1$2/;
	if($T_line{CNUM_PREFIX}=~m/^(\d+),(\d\d\d)$/ && $T_LINE{CNUM} eq ""){
	$T_line{CNUM_PREFIX}="";
	$T_line{CNUM}="$1$2";
	warn "$T_line{CNUM} from prefix\n";
	}
	if($T_line{CNUM_SUFFIX}=~m/^(\d+),(\d\d\d)$/ && $T_LINE{CNUM} eq ""){
	$T_line{CNUM_SUFFIX}="";
	$T_line{CNUM}="$1$2";
	warn "$T_line{CNUM} from suffix\n";
	}
	if($T_line{CNUM}=~s/^([A-Z]*[0-9]+)-([0-9]+)([A-Za-z]+)/$2/){
		$T_line{CNUM_PREFIX}=$1;
		$T_line{CNUM_SUFFIX}=$3;
	}
	if($T_line{CNUM}=~s/^([A-Z]*[0-9]+-)([0-9]+)(-.*)/$2/){
		$T_line{CNUM_PREFIX}=$1;
		$T_line{CNUM_SUFFIX}=$3;
	}
	if($T_line{CNUM}=~s/^([^0-9]+)//){
		$T_line{CNUM_PREFIX}=$1;
	}
	if($T_line{CNUM}=~s/^(\d+)([^\d].*)/$1/){
		$T_line{CNUM_SUFFIX}=$2;
	}
	if($T_line{CNUM}=~s/^[Ss]\.? *[nN]\.?//){
		$assignor="unknown";
	}
	if($T_line{CNUM}=~s/^\s*$//){
		$assignor="unknown";
	}


	if($T_line{'T/R/Section'}){
		foreach($T_line{'T/R/Section'}){
			next if m/^$/;
			($coords, $coord_notes)= &get_TRS($_);
#print "$_     $coords     $coord_notes\n";
			$S_accession{'coord_flag'}= 1;
			if($coords){
				$S_accession{'loc_coords_trs'}=  $coords;
				if($coord_notes){
					$S_accession{'notes'}="" unless $S_accession{'notes'};
					$S_accession{'notes'}.= $coord_notes;
				}
			}
			else{
				$S_accession{'loc_coords_trs'}= "";
				$S_accession{'coord_flag'}= 0;
				$S_accession{'notes'}="" unless $S_accession{'notes'};
				$S_accession{'notes'}.= $coord_notes;
			}
		}
	}

	$S_accession{'accession_id'}= $T_line{'Accession'};
	$S_accession{'coll_committee_id'}= $all_collectors;
	$S_accession{'coll_num_person_id'}= $assignor;
	$S_accession{'objkind_id'}= $magic_no{'Mounted_on_paper'};
	$S_accession{'inst_abbr'}= "UC";
	$S_accession{'coll_num_suffix'}= $T_line{CNUM_SUFFIX} || $T_line{CNUM_suffix};
	$S_accession{'coll_num_prefix'}= $T_line{CNUM_PREFIX} || $T_line{CNUM_prefix};
	$S_accession{'coll_number'}= $T_line{CNUM};
	if($S_accession{'coll_number'}==0){
		$S_accession{'coll_number'}="" unless ( $S_accession{'coll_num_suffix'} || $S_accession{'coll_num_prefix'});
	}
	$S_accession{'loc_country'}= $T_line{Country};
	$S_accession{'loc_state'}= $T_line{State};
	$S_accession{'loc_county'}= $T_line{County};
	$T_line{Elevation}=~s/&quot;//g;
	$T_line{Elevation}=~s/,//g;
	$S_accession{'loc_elevation'}= &CCH::get_elev($T_line{Elevation});
	$S_accession{'loc_verbatim'}= $T_line{Location};
	$S_accession{'loc_other'}= $T_line{Loc_other};
	$S_accession{'datestring'}= $T_line{Date};
	$S_accession{'early_jdate'}= $JD;
	$S_accession{'bioregion'}= $T_line{Jepson_Manual_Region};
	$S_accession{'late_jdate'}= $LJD;
	$S_accession{'catalog_date'} = $catdate;
	$S_accession{'catalog_by'} = "Bload";
	$S_accession{'lat_long_ref_source'}= $T_line{'Source'} if $T_line{'Source'};
	$S_accession{'lat_long_ref_source'}= $T_line{'Lat_long_ref_source'} if $T_line{'Lat_long_ref_source'};
	$S_accession{'max_error_distance'}= $T_line{'Max_error_distance'};
	$S_accession{'max_error_units'}= $T_line{'Max_error_units'};
	($S_accession{'inst_abbr'}=  $T_line{'Accession'})=~s/ *[-\d]+//;
	$S_accession{'datum'}=  $T_line{'Datum'};
	
#####DGB adding in parsing for the "Image" tag, in order to make a separate output file of AID/Image link pairs
	$S_accession{'image_link'}= $T_line{'Image'};
#####DGB adding in parsing for the "Cultivated" tag, which will be used for map drawing and database filtering
	$S_accession{'cultivated'}= $T_line{'Cultivated'};

###DGB: Print cultivated file
if ($S_accession{'cultivated'}) {
	print CULT "$S_accession{'accession_id'}\n",
}
####

##################################
#DD check for correct county spelling some time!
	$S_accession{'loc_county'}=~s/ *$//;
	$S_accession{'loc_county'}=~s/ County *//;
	$S_accession{'loc_county'}=~s/ Co\.?$//;
	unless($S_accession{'loc_county'}=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Tecate|Tijuana|Rosarito, Playas de|unknown|Unknown)/){
		$S_accession{'loc_county'}="unknown";
		print WARNINGS " $S_accession{'loc_county'} unrecognized: set to unknown\n";
	}

	$S_accession{'loc_state'}=~s/California/CA/;
	$S_accession{'loc_state'}=~s/Calif\.?/CA/;
	$county{uc($S_accession{'loc_county'})}.= "$hn\t";
################################
	$location_field=join(" ", $S_accession{'loc_other'}, $S_accession{'loc_verbatim'});
	$location_field=~s/^ *//;
	
foreach($location_field){
	s/on lable/on label/;
}
#$location_field=&make_one_loc($location_field);
#print "TEST $location_field\n";
foreach(split(/[ \|\/-]+/, $location_field)){
	s/&([a-z])[a-z]*;/$1/g;
	s/[^A-Za-z]//g;
	$_=lc($_);
	next if length($_)<3;
	next if m/^(road|junction|san|near|the|and|along|hwy|side|from|nevada|above|north|south|between|county|end|about|miles|just|hills|area|quad|slope|west|east|state|air|northern|below|region|quadrangle|cyn|with|mouth|head|old|base|collected|city|lower|beach|line|mile|california|edge|del|off|ave)$/;
	$CDL_loc_word{$_} .="$hn\t";
}
	if($T_line{'USGS_Quadrangle'}){
		$S_accession{'notes'}="" unless $S_accession{'notes'};
		$S_accession{'notes'}.= "USGS quad: $T_line{USGS_Quadrangle}; ";
	}
	if($T_line{'Notes'}){
		$S_accession{'notes'}="" unless $S_accession{'notes'};
		$S_accession{'notes'}.= "$T_line{Notes}; ";
	}
	if($T_line{'UTM'}){
		$S_accession{'notes'}="" unless $S_accession{'notes'};
		$S_accession{'notes'}.= "$T_line{UTM}; ";
	}
	$T_line{'CNUM_SUFFIX'}="" unless $T_line{'CNUM_SUFFIX'};
	$T_line{'CNUM_PREFIX'}="" unless $T_line{'CNUM_PREFIX'};
		$num=$S_accession{'coll_number'};
		foreach($num){
			next unless /[0-9a-zA-Z]/;
			s/^ *//;
			s/^[-# ]+//;
			s/ *$//;
			s/,//g;
			next if /^s\.?n\.?$/i;
			$num{$_}.="$hn\t";
		}
	}
	else{
		++$nocnum;
	}
	++$countprint;
	print OUT "$hn ";
	foreach($location_field){
		if (m/([^\x00-\x7f]+)/){
			$_=&get_entities($_);
		}
	}
	unless($S_accession{'loc_lat_decimal'} && $S_accession{'loc_long_decimal'}){
		$S_accession{'loc_lat_decimal'}= $S_accession{'loc_long_decimal'}="";
	}
	if($S_accession{'loc_long_decimal'}=~ /^(1\d\d\.\d+)/){
		$S_accession{'loc_long_decimal'}="-$S_accession{'loc_long_decimal'}";
	}
	$location_field=~s/Sterling/Stirling/ if $S_accession{'loc_county'}=~/Butte/;
	$S_accession{'coll_committee_id'}=&get_entities($S_accession{'coll_committee_id'});
#extract elevations out of locality field if there are none in the elevation field





	unless($T_line{'Elevation'}){
		if($location_field=~m/(\b[Ee]lev\.?:? [,0-9 -]+ *[MFmf'])/ || $location_field=~m/([Ee]levation:? [,0-9 -]+ *[MFmf'])/ || $location_field=~m/([,0-9 -]+ *(feet|ft|ft\.|m|meter|meters|'|f|f\.) *[Ee]lev)/i || $location_field=~m/\b([Ee]lev\.? (ca\.?|about) [0-9, -]+ *[MmFf])/|| $location_field=~m/([Ee]levation (about|ca\.) [0-9, -] *[FfmM'])/){
		#` print "LF: $location_field: $1\n";
				$pre_e=$e=$1;
				foreach($e){
					s/Elevation[.:]* *//i;
					s/Elev[.:]* *//i;
					s/(about|ca\.?)/ca./i;
					s/ ?, ?//g;
					s/(feet|ft|f|ft\.|f\.|')/ ft/i;
					s/(m\.|meters?|m\.?)/ m/i;
					s/^ *//;
					s/  */ /g;
					s/[. ]*$//;
					s/ *- */-/;
					s/-ft/ ft/;
					s/(\d) (\d)/$1$2/g;
					next unless m/\d/;
					if(m/(\d+)-(\d+)/){
						if ($1 > $2){
				print WARNINGS "$hn Elevation skipped $_\n";
						#next;
						}
					}
					elsif(m/(\d\d\d\d\d+) f/){
						if ($1 > 14500){
				print WARNINGS "$hn Elevation skipped $_\n";
				#next;
				}
					}
					elsif(m/(-\d\d\d+) f/){
						if ($1 < -300){
				print WARNINGS "$hn Elevation skipped $_\n";
				#next;
				}
					}
					#$S_accession{'loc_elevation'}=$_;
				print WARNINGS "$hn Elevation added $_  ($pre_e): $location_field\n";
				}
			}
		}
	unless($S_accession{'loc_lat_decimal'} && $S_accession{'loc_long_decimal'}){
		$S_accession{'datum'}="";
	}
	unless($S_accession{'max_error_distance'}){
		$S_accession{'max_error_units'}="";
	}
	$S_accession{'loc_lat_decimal'}=~s/[^.0-9]*$//;
	$S_accession{'loc_long_decimal'}=~ s/[^.0-9]*$//;
	print OUT join("\t",
	$S_folder{'taxon_id'},
	$S_accession{'coll_committee_id'},
	$S_accession{'coll_num_prefix'},
	$S_accession{'coll_number'},
	$S_accession{'coll_num_suffix'},
	$S_accession{'early_jdate'},
	$S_accession{'late_jdate'},
	$S_accession{'datestring'},
	$S_accession{'loc_county'},
	$S_accession{'loc_elevation'},
	$location_field,
	$S_accession{'loc_lat_decimal'},
	$S_accession{'loc_long_decimal'},
	$S_accession{'datum'},
	$S_accession{'lat_long_ref_source'},
	$S_accession{'loc_coords_trs'},
	$S_accession{'max_error_distance'},
	$S_accession{'max_error_units'}),
	"\n";

###DGB: Print image_links file
###Image links, cultivatedness etc. are separate files, because modifying the main CDL hash structure (CDL_main.in) would be very complicated and probably break something
###This is the best method I could come up with for adding new fields to CCH
if ($S_accession{'image_link'}) {
	print IMG join("\t", 
	$S_accession{'accession_id'},
	$S_accession{'image_link'}),
	"\n";
}
####

	
if ($S_accession{'notes'}){
$CDL_notes{$hn}=&get_entities($S_accession{'notes'});
#unless($S_accession{'notes'} eq $CDL_notes{$hn}){
#print <<EOP;
#$S_accession{'notes'}
#$CDL_notes{$hn}
#
#EOP
#}
}


	$S_folder{'accession_id'}= $T_line{'Accession'};

	if($T_line{'Hybrid_annotation'}){
		#$cdl_anno{$S_folder{'accession_id'}}="$T_line{'Hybrid_annotation'};;;Name on sheet\n";
		if($T_line{'Hybrid_annotation'}=~/; /){
			push(@cdl_anno,"$S_folder{'accession_id'}\n$T_line{'Hybrid_annotation'}");
		}
		else{
			push(@cdl_anno,"$S_folder{'accession_id'}\n$T_line{'Hybrid_annotation'};;;Name on sheet");
		}
	}
	if($T_line{'Annotation'}){
		$anno =join("\n",@anno);
		#print "2 $anno\n\n";
#$cdl_anno{$S_folder{'accession_id'}}="$T_line{'Annotation'}\n";
#push(@cdl_anno,"$S_folder{'accession_id'}\n$T_line{'Annotation'}");
                $cdl_anno{$S_folder{'accession_id'}}="$anno\n";
                push(@cdl_anno,"$S_folder{'accession_id'}\n$anno\n");
        
	}
	if($T_line{'Habitat'} ||
		$T_line{'Associated_species'} ||
		$T_line{'Color'} ||
		$T_line{'Physical_environment'} ||
		$T_line{'Other_label_numbers'} ||
		$T_line{'Reproductive_biology'} ||
		$T_line{'Odor'} ||
		$T_line{'Type_status'} ||
		$T_line{'Population_biology'} ||
		$T_line{'Phenology'} ||
		$T_line{'Type_status'} ||
		$T_line{'Genbank_code'} ||
		$T_line{'Verbatim_coordinates'} ||
		$T_line{'Other_data'} ||
		$T_line{'Macromorphology'}){
			foreach $voucher (keys(%vouchers)){
				if($T_line{$voucher}=~/[a-zA-Z0-9]/){
					$cdl_voucher{$S_folder{'accession_id'}}.= "\t$vouchers{$voucher}\t$T_line{$voucher}";
				}
			}
	}
	return $_;
}


#possible fields to add:
#"16","secondary product chemistry",
#"17","cytology",
#"18","embryology",
#"19","micromorphology",
#"20","macromorphology",
#"21","reproductive biology",
#"24","population biology",
#"25","horticulture",
#"26","phenology",
#"27","illustration",
#"28","photograph",
#"29","nomenclature",
#"32","publication",
#"33","data in packet",
#"35","reference used for determination",
#36","none",
#"39","common name",
#"41","Vegetation Type Map Project",
#"43","odor",
#"44","ethnobotany",
#"47","map",
#"50","color",
#"52","habitat",
#"53","associated species",
#"55","other label numbers",
#"58","biotic interactions",
#"56","type",
#"23","biotic environment -inactive 7/93",
#"22","physical environment -inactive 7/93",
#"61","annotation history",
#"62","Expedition",
#"64","fruit removal",
#"65","physical enviroment",
#"66","physical environment",
#"67","SEM (Scanning Electron Micrograph)",
#"63","material removed",
#"15","nucleic acids",
#45","genbank code",
#"71","U.C. Botanical Garden",
#"72","other",
#"73","verbatim coordinates",



sub get_genus{
	local($_)=@_;
	s/([a-z]) .*/$1/;
	return $_;
}

close(OUT);
open(OUT, ">CDL_collectors.in") || die;
foreach (sort (keys(%all_names))){
	print OUT "$_ $all_names{$_}\n";
}
close(OUT);
open(OUT, ">CDL_counties.in") || die;
foreach (sort (keys(%county))){
	$orig=$_;
#s/(.)([^ ]+) (.)([^ ]+) (.)(.+)/\u$1\l$2 \u$3\l$4 \u$5\l$6/ ||
#s/(.)([^ ]+) (.)(.+)/\u$1\l$2 \u$3\l$4/ ||
#s/(.)(.+)/\u$1\l$2/;
	s/ /_/g;
	warn "$_\n" unless $seen{$_}++;
	print OUT "$_ $county{$orig}\n";
}
close(OUT);
open(OUT, ">CDL_tid_to_name.in") || die;
foreach (sort (keys(%TID_TO_NAME))){
	print OUT "$_ $TID_TO_NAME{$_}\n";
}
close(OUT);
open(OUT, ">CDL_date_simple.in") || die;
foreach (sort (keys(%date_simple))){
	print OUT "$_ $date_simple{$_}\n";
}
close(OUT);
open(OUT, ">CDL_date_range.in") || die;
foreach (sort (keys(%date_range))){
	print OUT "$_ $date_range{$_}\n";
}
close(OUT);
open(OUT, ">CDL_name_list.in") || die;
foreach(sort(keys(%name_list))){
	print OUT "$_ $name_list{$_}\n";
}
close(OUT);
open(OUT, ">CDL_loc_list.in") || die;
foreach(sort(keys(%CDL_loc_word))){
	print OUT "$_ $CDL_loc_word{$_}\n";
}
close(OUT);
open(OUT, ">CDL_coll_number.in") || die;
foreach (sort (keys(%num))){
	print  OUT "$_ $num{$_}\n";
}
close(OUT);

open(OUT,">CDL_voucher.in") || die;
foreach(sort(keys(%cdl_voucher))){
print OUT "$_$cdl_voucher{$_}\n";
}
close(OUT);
open(OUT,">CDL_notes.in") || die;
foreach(sort(keys(%CDL_notes))){
print OUT "$_\t$CDL_notes{$_}\n";
}
close(OUT);

foreach(@cdl_anno){
	($key,@value)=split(/\n/);
	foreach $value(@value){
	if($CDL_anno{$key}){
		$CDL_anno{$key}.="\n$value";
	}
	else{
		$CDL_anno{$key}="$value";
	}
	}
}
open (OUT, ">CDL_annohist.in") || die;
foreach(sort(keys(%CDL_anno))){
	$CDL_anno{$_}=~s/√ó/× /;
	print OUT "$_\n$CDL_anno{$_}\n\n";
}

open(OUT, ">logs/CDL_bad_date") || die;
foreach(keys(%null_date)){
print OUT "bad date: $null_date{$_}: $_ \n";
}
close(OUT);
open(OUT, ">logs/not_in_icpn.txt") || die;
foreach(sort(keys(%not_in_ICPN))){
print OUT "$_ $not_in_ICPN{$_}\n";
}
close(OUT);
#UND
sub modify_collector {
s/,? Jr\.?//;
s/&([a-z])[a-z]*;/$1/g;
			s/W\. ?L\. ? J\./Jepson/;
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
			s! \(?(w/|with|and|&) .*!!;
			s! \[(w/|with|and|&) .*!!;
			s/[;,] .*//;
			#s/, .*//;
			s/^.* //;
s/&(.)[^;]*;/\1/g && print "$_\n";
			return ucfirst(lc($_));
}
sub get_entities{
local($_)=shift;
#warn "$_\n";
$start=$_;
study();

s/\xc3\xa2\xe2\x82\xac\xe2\x80\x9c/"/g;
s/\xC3\xA2\xE2\x82\xAC\xE2\x80\x9C/---/g;
s/\xc2\xa0\xc2\xb1/&plusmn;/g; 
s/\xc2\xb7\xc2\xb1/&plusmn;/g; 
s/\xC3\x83\xC21\/4/&uuml;/g;
s/\xC3\x83\xC2\xBC/1\/4/g;
s/\xC3\x83\xC2\xBE/3\/4/g;
s/\xC3\x83\xC2\xB1/&ntilde;/g;

s/V\x87cr\x87t\x97t/V&aacute;cr&aacute;t&oacute;t/;
s/\xef\xbe\x8e/&eacute;/g; 
s/\xe2\x88\x9e/&deg;/g; 
s/\xef\xbf\xbd/'/g;
s/\xe2\x80\x93/---/g; 
s/\xe2\x80\x99/'/g; 
s/\xe2\x80\x98/'/g; 
s/\xe2\x80\x9d/"/g; 
s/\xe2\x80\x9c/"/g; 
s/\xe2\x80\xA0/t/;
s/\xe2\x80\x93/&mdash;/g;
s/\xe2\x80\xa6/.../g;
s/\xe2\x89\xa4/&leq;/g;
s/\xe2\x89\xa5/&geq;/g;
s/\xe2\x99\x80/&female;/g;
s/\xe2\x99\x82/&male;/g;
s/\xef\xbe\x96/&ntilde;/g; 
s/\xef\xbf\xbd/&deg;/g; 
s/\xef\xbe\xa1/&deg;/g; 

s/\372\361/&uacute;&ntilde;/g;

s/\xef\xbe/&deg;/g;
s/\xEF\xA3\xBF//g;
s/\xC3\x8E//g;
s/\xEF\xBE\xB1//;
s/\xc3\x91/N/g;
s/\xC2\xBE/3\/4/g;
s/\xA0\xB1/&plusmn;/g;
s/\xc2\xa3/&pound;/g;
s/\xc2\xb0/&deg;/g;
s/\xc2\xb1/&plusmn;/g;
s/\xc2\xb2/&sup2;/g;
s/\xc2\xb9/&sup1;/g;
s/\xc2\xbe/3\/4/g;

s/\xe2\x80 *\.\.\./' .../g; 
s/\xe2 *\.\.\./ .../g; 
s/\xc2 *\.\.\./" .../g; 

s/¬±/&plusmn;/g;
s/Y√¢¬Ä¬ô/&deg;/g;
s/√¢¬à¬û/&deg;/g;
s/Sierra ÔæÑevada/Sierra Nevada/;
s/√Öna/Ana/;
s/.zelk.k/Ozelkuk/;
s/\xC7anyon/Canyon/;
s/River\x85on/River --- on/;
s/\xc3\xa1/&aacute;/g;

#s/√¢¬Ä¬ô√¢¬Ä¬ô/"/g;		
			s/\xc3\xbc/&uuml;/g;
			s/\xc3\xb1/&ntilde;/g;
			s/\xc2\xbd/ 1\/2/g;
			s/\xc3\xa9/&eacute;/g;
			s/\xc2\xbc/ 1\/4/g;
			s/\xc3\xb6/&ouml;/g;
			s/\xc3\xb3/&oacute;/g;
			s/\xc3\xad/&iacute;/g;
			s/\xc3\x85/&Aring;/g;
			s/\xc3\x97/&times;/g;
			s/\xc3\xa1/&aacute;/g;
			s/\xc3\xa8/&egrave;/g;
			s/\xc3\xa9/&eacute;/g;
			s/\xc3\xaa/&ecirc;/g;
			s/\xc3\xb4/&ocirc;/g;
			s/\xc3\xb8/&oslash;/g;		

s/√±/&ntilde;/g;

s/\xc21\/4/&frac14;/g; 
s/\xc2\xb7/&deg;/;
s/√¢¬Ä¬ò/"/g;
s/√¢¬Ä¬ú/"/g;
s/√¢¬Ä¬ù/"/g;
s/√Ç¬∞/&deg;/g;
s/√Ç¬∫/&deg;/g;
s/\xcb\x9a/&deg;/g; 
s/√ã¬ö/&deg;/g;
s/√É¬©/&eacute;/g;
s/√É¬®/&egrave;/g;
s/√≠/&iacute;/g;
s/√É¬±/&ntilde;/g;
s/√±/&ntilde;/g;
s/√É¬±√É¬≥/&ntilde;&oacute;/g;
s/√≥/&oacute;/g;
s/√É¬∂/&ouml;/g;
s/√∂/&ouml;/g;
s/√Ç¬±/&plusmn;/g;
s/¬±/&plusmn;/g;
s/√É¬º/&uuml;/g;
s/√º/&uuml;/g;
s/√¢¬Ä¬ò√¢¬Ä¬ô/'/g;
s/√¢¬Ä¬ô/'/g;
s/√Ø¬ø¬Ω/'/g;
s/√ª/'/g;
s/√¢/'/g;
s/√î/'/g;
s/√ï/'/g;
s/√Ç¬Ω/&frac12;/g;
s/¬Ω/&frac12;/g;
s/√Ç¬º/&frac14;/g;
s/¬º/&frac14;/g;
s/√Ç¬æ/&frac34;<1>/g;
s/¬ì/"/g;
s/¬î/"/g;
s/√í/"/g;
s/√ì/"/g;
s/+//g;
s/√ñ/&Ouml;/g;
s/&apos;/'/g;
s/\x91/'/g;
s/¬ë/'/g;
s/¬í/'/g;
s/\xd4/'/g;
s/¬∫/&deg;/g;
s/¬°/&deg;/g;
s/°/&deg;/g;
s/¬à/&aacute;/g;
s/à/&aacute;/g;
s/\xe9/&eacute;/g; 
s/¬∞/&deg;/g;
s/\x8e/&eacute;/g;
s/√©/&eacute;/g;
s/\x8f/&egrave;/g;
s/\x8e/&eacute;/g; 
s/\x92/'/g; 
s/\x94/"/g; 
s/\x93/"/g; 
s/\xc2\xbd/&frac12;/g;
s/\xbd/&frac12;/g; 
s/\xc2\xb1/&plusmn;/g; 
s/\xb1/&plusmn;/g; 
s/\xd3/"/g; 
s/\xd2/"/g; 
s/\xd5/'/g; 
s/\xf1/&ntilde;/g; 
s/\xf3/&oacute;/g; 
s/\xa1/&deg;/g; 
s/\xb0/&deg;/g; 
s/\xed/&iacute;/g; 
s/\x96/&ntilde;/g; 
s/\xab/'/g; 
s/\xbe/&frac34;<3>/g; 
s/\xbd/&frac12;/g; 
s/\xbc/&frac14;/g; 
s/\xb3/&plusmn;/g; 
s/\xb2/&plusmn;/g; 
s/¬±/&plusmn;/g;
s/¬Ω/&frac12;/g;
s/\xa1/&deg;/g; 
s/(\d)\xba/$1$deg;/g;
s/\xf6/&ouml;/;
s/\x97/&oacute;/;
s/\x9A/&ouml;/;
s/¬æ/&frac34;<2>/g;
s/\cP+//g;
s/\xe1/&aacute;/g;
s/\xC5/~/g;
s/\xFB/&deg;/g;
s/\xD3/"/g;
s/\xF6/&ouml;/g;
s/\xC1/&Aacute;/g;

$end=$_;
unless ($start eq $end){
unless ($end=~ m/^[-\\`@$\[\]{}=*!|><#%~+\/\w\s,.?;:"')(&]*$/){
print ERR "$start\n$end\n\n";
}
}
$_;
}
