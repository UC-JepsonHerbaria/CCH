use Smasch;
use Time::JulianDay;
use Time::ParseDate;
%seen=();
$password=shift;
die "Need password on command line\n" unless $password;
$today=scalar(localtime());
@today_time= localtime(time);
$thismo=(Jan, Feb, Mar, Apr, May, Jun, Jul, Aug, Sep, Oct, Nov, Dec)[$today_time[4]];
$year= $today_time[5] + 1900;
$catdate= "$thismo $today_time[3] $year";
$today_JD=julian_day($year, $today_time[4]+1, $today_time[3]);
warn "Today is $catdate\n";
($year,$month,$day)= inverse_julian_day($today_JD);
warn "Today's JD is $today_JD which is $month $day $year\n";
warn "NB: Some of the datafiles are updates, some are complete. Records in the datafiles will supersede records in SMASCH\n";
$tnum="";

@sggb_precision=(0, 10, 100, 1000, 10000);

#$datafile=shift;
#unless(length($datafile) >1){
	#warn "Enter the name of the data file from which to get the data\n";
	#$datafile = <>;
	#die "The data file is the file containing the collection data\n" unless $datafile;
#}
open(OUT, ">CDL_main.in") || die;

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
&load_collectors();
&load_noauth_name();
&load_be();


@datafiles=(
"SD.out",
"missing_rsa.tab",
"RSA.out",
"IRVC_new.out",
"UCD.out",
"UCR.out",
"PG.out",
"chico.out",
"sbbg.out"
);
#@datafiles=();
foreach $datafile (@datafiles){
	system "uncompress ${datafile}.Z";
	print $datafile, "\n";
	open(IN,"$datafile")|| die;
	$/="";
	while(<IN>){
		s/  +/ /g;
		++$countpar;
		if (s/Accession_id: (..)/Accession: $1/){
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
s/Sšzer …zelkŸk/S&ouml;zer &Ouml;zelk&ouml;k/;
s/Vern` Yadon/Vern Yadon/;
s/Villaseï¾–or/Villase&ntilde;or/;
s/Villanse–or/Villase&ntilde;or/;
s/Villase–or/Villase&ntilde;or/;
s/Villaseñor/Villase&ntilde;or/;
s/HÃ¶lzer/H&ouml;zer/;
			&process_entry($_);
		}
		else{
			warn "skipping $.\n";
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
	++$countprocess;
	s/Associated_with:/Associated_species:/;
	my(@suppl)=();
	%T_line=();
	($hn)=m/Accession: *(.*)/;
	$hn=uc($hn);
	if(m/Collector: ([A-Za-z].*)/){
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
s/Sšzer …zelkŸk/S&ouml;zer &Ouml;zelk&ouml;k/;
s/Vern` Yadon/Vern Yadon/;
s/Villaseï¾–or/Villase&ntilde;or/;
s/Villanse–or/Villase&ntilde;or/;
s/Villase–or/Villase&ntilde;or/;
s/Villaseñor/Villase&ntilde;or/;
s/HÃ¶lzer/H&ouml;zer/;
		++$countcoll;
		$collector=$assignor=$1;

		if(m/(More|Other)_coll[^:]*: *([A-Za-z].+)/){
			$oc=$2;
			if(m/Combined_coll[^:]*: (.*)/){
				$collector =$1;
			}
			else{
				$collector .= ", $oc";
			}
		}

		$collector=~s/\.([A-Z])/. $1/g;
		$collector=~s/([A-Z]\.)([A-Z]) ([A-Z])/$1 $2. $3/;


		$collector=~s/([A-Z]\.)([A-Z]\.)([A-Z]\.)/$1 $2 $3/g;
		$collector=~s/([A-Z]\.)([A-Z]\.)/$1 $2/g;
		$collector=~s/(Fr.)([A-Z]\.)/$1 $2/g;
		$collector=~s/([A-Z]\.)([A-Z]')/$1 $2/g;
#$collector=~s/ and /, /;
		$collector=~s/Sent in for det: //;
		$collector=~s/Submitted for det: //;
		$collector=~s/(B. Crampton), 1247, May 11, 1953.*/$1/;
		$collector=~s/R & J. Kniffen/R. & J. Kniffen/;
		$collector=~s/ s\.n.*//;
		$collector=~s/Unknown, Bot. 108/unknown/;
		$collector=~s/collector unknown/unknown/;
		$collector=~s/Unknown collector/unknown/;
		$collector=~s/ *$//;
		$collector=~s/,,/,/g;
		$collector=~s/, others/, and others/;
		$collector=~s/, C. N. P. S./, and C. N. P. S./;
		$collector=~s/([A-Z]\.)(-[A-Z]\.)/$1 $2/;
		$all_collectors=$collector;


		foreach($collector){
$_=&get_entities($_);
$_=&modify_collector($_);
			$all_names{$_}.="$hn\t" unless $seen{$hn}++;
		}
	}
	else{
		$assignor="unknown"; $collector="unknown";
	}

	if(m/CNUM:(.*)/){
		$tnum=uc($1);
		$tnum=~s/ *$//;
		$tnum=~s/^0*//;
		if(m/Date: +(.*)/){
			$ds=$1;
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
			else{
				#warn "$hn Unexpected date; setting jdate to null $ds\n";
$null_date{$ds}=$hn;
				$LJD=$JD="";
				#print "parse_date ";
#$par="13";
			}
if($JD > $today_JD){
				warn "$hn Misentered date $JD > $today_JD; setting jdate to null $ds\n";
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
		$name=$1;
foreach($name){
s/Viguiera purissimae/Viguiera purisimae/;
s/Erechtites minima/Erechtites minimus/;
s/Erechtites glomerata/Erechtites glomeratus/;
s/Erechtites arguta/Erechtites argutus/;
s/Arabis.*divaricarpa/Arabis divaricarpa/;
s/Dudleya cespitosa/Dudleya caespitosa/;
s/Spergularia bocconii/Spergularia bocconi/;
s/gussonianum/gussoneanum/;
s/Stylocline gnaphalioides/Stylocline gnaphaloides/;
s/Juncus lesueurii/Juncus lescurii/;
}
		if($PARENT{&strip_name($name)}=~/^\d+$/){
			$S_folder{'taxon_id'}= $PARENT{&strip_name($name)};
#warn $T_line{'Name'}, &strip_name($name) ."\n";
		}
		else{
			print "$hn THIS CAN'T BE STORED: Something wrong with PARENT >" . $name, &strip_name($name) ."\n";
			return(0);
		}
		unless($S_folder{'genus_id'}= $PARENT{&get_genus($name)}){
			print "$hn THIS CAN'T BE STORED: Something wrong with >" . $T_line{'Name'} . "with respect to genus_id extraction\n";
			return(0);
		}

#$S_folder{'genus'}= &get_genus($T_line{'Name'});

#$name=~s/Quercus ×macdonaldii/Quercus × macdonaldii/;
#print "$name\n" if $name=~/alvordiana/;
		$name=~s/Quercus [^a-z] ?alvordiana/Quercus × alvordiana/;
		$name=~s/Quercus [^a-z] ?kinselae/Quercus × kinselae/;
		$name=~s/Equisetum [^a-z] ?ferrissii/Equisetum × ferrissii/;
		$name=~s/Eriogonum [^a-z] ?blissianum/Eriogonum × blissianum/;
		$name=~s/Pelargonium [^a-z] ?hortorum/Pelargonium × hortorum/;
		$name=~s/Hook\. f\./Hook./g;
		$name=~s/Desf. ex //;
		$name=~s/Gnaphalium luteoalbum/Gnaphalium luteo-album/;
		$name=~s/Argyranthemum foeniculum/Argyranthemum foeniculaceum/;
		$name=~s/Gilia austrooccidentalis/Gilia austro-occidentalis/;
		$name=~s/Micropus amphibola/Micropus amphibolus/;
#print "$name\n" if $name=~/alvordiana/;
		foreach($name){
#print "$_\n" if m/alvordiana/;
			print $S_folder{'taxon_id'}, "\n" if m/alvordiana/;
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
	s|¬|1/4|g;
	s|¼|1/4|g;

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
	if($T_line{'Latitude'}){
		($S_accession{'loc_lat_decimal'}, $S_accession{'loc_lat_deg'})= &parse_lat($T_line{'Latitude'});
$convert.="$S_accession{'loc_lat_decimal'}, $S_accession{'loc_lat_deg'}\n";
	}
	else{$T_line{'Longitude'}="";}
	if($T_line{'Decimal_latitude'}){
		$S_accession{'loc_lat_decimal'}= $T_line{'Decimal_latitude'};
	}
	if($T_line{'Longitude'}){
		($S_accession{'loc_long_decimal'}, $S_accession{'loc_long_deg'})= &parse_long($T_line{'Longitude'});
$convert.="$S_accession{'loc_long_decimal'}, $S_accession{'loc_long_deg'}\n";

	}
	else{$T_line{'Latitude'}="";}
	if($T_line{'Decimal_longitude'}){
		$S_accession{'loc_long_decimal'}= $T_line{'Decimal_longitude'};
	}

	if($T_line{Country}){
		$T_line{Country}="US" if $T_line{Country} eq "U.S.A.";
	}
	else{$T_line{Country}="US";}
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

	#$T_line{'Name'} =~ s/ sp\. / indet./;


	if($T_line{'T/R/Section'}){
		foreach($T_line{'T/R/Section'}){
			next if m/^$/;
			($coords, $coord_notes)= &get_TRS($_);
			$S_accession{'coord_flag'}= 1;
			if($coords){ $S_accession{'loc_coords_trs'}=  $coords;}
			else{
				$S_accession{'loc_coords_trs'}= "";
				$S_accession{'coord_flag'}= 0;
				$S_accession{'notes'}="" unless $S_accession{'notes'};
				$S_accession{'notes'}.= $coord_notes;
			}
		}
	}

	foreach( $T_line{County}){
s/RVIERSIDE/RIVERSIDE/g;
s/Rvierside/Riverside/g;
}
	$S_accession{'accession_id'}= $T_line{'Accession'};
	$S_accession{'coll_committee_id'}= $all_collectors;
	$S_accession{'coll_num_person_id'}= $assignor;
	$S_accession{'objkind_id'}= $magic_no{'Mounted_on_paper'};
	$S_accession{'inst_abbr'}= "UC";
	$S_accession{'coll_num_suffix'}= $T_line{CNUM_SUFFIX} || $T_line{CNUM_suffix};
	$S_accession{'coll_num_prefix'}= $T_line{CNUM_PREFIX} || $T_line{CNUM_prefix};
	$S_accession{'coll_number'}= $T_line{CNUM};
	$S_accession{'loc_country'}= $T_line{Country};
	$S_accession{'loc_state'}= $T_line{State};
	$S_accession{'loc_county'}= $T_line{County};
	$S_accession{'loc_elevation'}= &get_elev($T_line{Elevation});
	$S_accession{'loc_verbatim'}= $T_line{Location};
	$S_accession{'loc_other'}= $T_line{Loc_other};
	$S_accession{'loc_place'}= $T_line{Loc_place};
	$S_accession{'datestring'}= $T_line{Date};
	$S_accession{'early_jdate'}= $JD;
	$S_accession{'bioregion'}= $T_line{Jepson_Manual_Region};
	$S_accession{'late_jdate'}= $LJD;
	$S_accession{'catalog_date'} = $catdate;
	$S_accession{'catalog_by'} = "Bload";
	#if($T_line{Precision}=~/^[12345]$/){
		$S_accession{'lat_long_ref_source'}= $T_line{'Lat_long_ref_source'};
		$S_accession{'max_error_distance'}= $T_line{'Max_error_distance'};
		$S_accession{'max_error_units'}= $T_line{'Max_error_units'};
	#}
	#else{
		#$S_accession{'lat_long_ref_source'}="";
		#$S_accession{'max_error_distance'}= "";
		#$S_accession{'max_error_units'}="";
	#}
	($S_accession{'inst_abbr'}=  $T_line{'Accession'})=~s/ *[-\d]+//;
	$S_accession{'datum'}=  $T_line{'Datum'};
	#$S_accession{inst_abbr}=  $T_line{Herbarium_acronym};
	


##################################
#DD check for correct county spelling some time!
	$S_accession{'loc_state'}=~s/California/CA/;
	$S_accession{'loc_state'}=~s/Calif\.?/CA/;
$county{uc($S_accession{'loc_county'})}.= "$hn\t";
################################
	$location_field=join(" | ", $S_accession{'loc_distance'}, $S_accession{'loc_place'},$S_accession{'loc_other'}, $S_accession{'loc_verbatim'});
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
	if($S_accession{'loc_long_decimal'}=~ /^(1\d\d\.\d+)/){
		$S_accession{'loc_long_decimal'}="-$S_accession{'loc_long_decimal'}";
	}
	$location_field=~s/Sterling/Stirling/ if $S_accession{'loc_county'}=~/Butte/;
	$S_accession{'coll_committee_id'}=&get_entities($S_accession{'coll_committee_id'});
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


	$S_folder{'accession_id'}= $T_line{'Accession'};

	if($T_line{'Hybrid_annotation'}){
		$cdl_anno{$S_folder{'accession_id'}}="$T_line{'Hybrid_annotation'};;;Name on sheet\n";
#warn <<EOP;
		#$S_folder{'accession_id'}
		#$cdl_anno{$S_folder{'accession_id'}}="$T_line{'Hybrid_annotation'};;;Name on sheet";
#
#EOP
}
	if($T_line{'Annotation'}){
		$cdl_anno{$S_folder{'accession_id'}}="$T_line{'Annotation'}\n";
}
	if($T_line{'Habitat'} ||
		$T_line{'Associated_species'} ||
		$T_line{'Color'} ||
		$T_line{'Other_label_numbers'} ||
		$T_line{'Reproductive_biology'} ||
		$T_line{'Odor'} ||
		$T_line{'Population_biology'} ||
		$T_line{'Macromorphology'}){

			foreach $voucher (keys(%vouchers)){
				if($T_line{$voucher}=~/[a-zA-Z0-9]/){
$cdl_voucher{$S_folder{'accession_id'}}.= "\t$vouchers{$voucher}\t$T_line{$voucher}";
				}

	}
}
}


#open(OUT, ">CDL_loc_list.in") || die;
#foreach(sort(keys(%CDL_loc_word))){
#	print OUT "$_ $CDL_loc_word{$_}\n";
#}
#close(OUT);

#close(OUT);
#open(OUT, ">CDL_counties.in") || die;
#foreach (sort (keys(%county))){
	#$orig=$_;
##s/(.)([^ ]+) (.)([^ ]+) (.)(.+)/\u$1\l$2 \u$3\l$4 \u$5\l$6/ ||
##s/(.)([^ ]+) (.)(.+)/\u$1\l$2 \u$3\l$4/ ||
##s/(.)(.+)/\u$1\l$2/;
	#s/ /_/g;
	#warn "$_\n" unless $seen{$_}++;
	#print OUT "$_ $county{$orig}\n";
#}
#open(OUT, ">CDL_name_list.in") || die;
#foreach(sort(keys(%name_list))){
	#print OUT "$_ $name_list{$_}\n";
#}
#close(OUT);
#
#open(OUT, ">CDL_date_simple.in") || die;
#foreach (sort (keys(%date_simple))){
	#print OUT "$_ $date_simple{$_}\n";
#}
#close(OUT);
#open(OUT, ">CDL_date_range.in") || die;
#foreach (sort (keys(%date_range))){
	#print OUT "$_ $date_range{$_}\n";
#}
#close(OUT);
#
#open(OUT, ">CDL_collectors.in") || die;
#foreach (sort (keys(%all_names))){
	#print OUT "$_ $all_names{$_}\n";
#}
#close(OUT);
#open(OUT, ">CDL_tid_to_name.in") || die;
#foreach (sort (keys(%TID_TO_NAME))){
	#print OUT "$_ $TID_TO_NAME{$_}\n";
#}
#close(OUT);

#open(OUT, ">CDL_coll_number.in") || die;
#foreach (sort (keys(%num))){
	#print  OUT "$_ $num{$_}\n";
#}
#close(OUT);
sub get_genus{
local($_)=@_;
s/([a-z]) .*/$1/;
#$_ = &get_author($_);
$_;

sub get_author {
local($_)=@_;
#$author_lookup{$_};
}
}

#cdl_extract.pl

use Time::JulianDay;
use Time::ParseDate;
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
#open(OUT, ">CDL_main.in") || die;
use Sybase::CTlib;
$dbh=new Sybase::CTlib 'rlmoe', $password;

$query=<<EOQ;
select
a.accession_id,
b.taxon_id,
committee_abbr,
coll_num_prefix,
coll_number,
coll_num_suffix,
early_jdate,
late_jdate,
datestring,
loc_county,
loc_elevation,
loc_distance +" | " + loc_place +" | " +  loc_other + " | " + loc_verbatim,
noauth_name,
loc_lat_decimal,
loc_long_decimal,
datum,
lat_long_ref_source,
loc_coords_TRS,
max_error_distance,
max_error_units
  from accession a, annotation_asfiled b, committee d, taxon_noauth_name e
where
(
a.accession_id=b.accession_id
and a.coll_committee_id=d.committee_id
and b.taxon_id=e.taxon_id
and a.loc_state="CA"
and a.objkind_id != 5
and a.objkind_id != 6
and a.accession_id not like "UCR%"
and a.accession_id not like "UCD%"
and a.accession_id not like "UCI%"
and a.accession_id not like "SDSU%"
and a.accession_id not like "CHSC%"
and a.accession_id not like "SBBG%"
)

EOQ
$dbh->ct_execute("$query");
while($dbh->ct_results($restype) == CS_SUCCEED){
	next unless $dbh->ct_fetchable($restype);
	while((@fields)= $dbh->ct_fetch){
grep(s/ +$//,@fields);
grep(s/^ +//,@fields);
grep(s/\t/ /g,@fields);
$fields[0]=uc($fields[0]);
if($seen_accession{$fields[0]}){
$skip_accession++;
next;
}

foreach($fields[11]){
s/Sterling/Stirling/ if $fields[9]=~/Butte/;
if (m/([^\x00-\x7f]+)/){
$_=&get_entities($_);
}
}

foreach(split(/[ \|\/-]+/, $fields[11])){
s/&([a-z])[a-z]*;/$1/g;
	s/[^A-Za-z]//g;
	$_=lc($_);
	next if length($_)<3;
	next if m/^(road|junction|san|near|the|and|along|hwy|side|from|nevada|above|north|south|between|county|end|about|miles|just|hills|area|quad|slope|west|east|state|air|northern|below|region|quadrangle|cyn|with|mouth|head|old|base|collected|city|lower|beach|line|mile|california|edge|del|off|ave)$/;
	$CDL_loc_word{$_} .="$fields[0]\t";
}





$county{uc($fields[9])} .= "$fields[0]\t";

$name=$fields[12];
foreach($name){
$TID_TO_NAME{$fields[1]}=$name;
	s/subsp\. //;
	s/var\. //;
	s/f\. //;
	next unless length($_)>1;
	$name_list{lc($_)}.= "$fields[0]\t";
	($sp=$_)=~s/[^ ]+ +//;
	next unless length($sp)>1;
	$name_list{lc($sp)}.= "$fields[0]\t";
	($infra=$sp)=~s/[^ ]+ +//;
	next unless length($infra)>1;
	$name_list{lc($infra)}.= "$fields[0]\t";
}





if($fields[7] - $fields[6] ==0){
	$date_simple{$fields[6]} .= "$fields[0]\t";
##make $fields[8] canonical date
	if($fields[6] > 2374816){
		($year,$month,$day)= inverse_julian_day($fields[6]);
##dates later than 1789
		$fields[8] = "$monthno{$month} $day $year";
	}
}
elsif($fields[7] - $fields[6] > 0 &&
$fields[7] - $fields[6] < 2000){
	$date_range{"$fields[6]-$fields[7]\t"} .= "$fields[0]\t";
}

$coll=$fields[2];
foreach($coll){
$_=&modify_collector($_);
	#s/W\. ?L\. ? J\./Jepson/;
	#if(m/[A-Z]\. ?[A-Z]\. ?[A-Z]\.$/){
		#$all_names{$_}.="$fields[0]\t" unless $seen{$fields[0]}++;
		#next;
	#}
	#s/,? [Ee][tT] .*//;
			#s/[A-Z][a-z]+ and ?[A-Z][a-z-]+ ([A-Z][a-z-])/$1/;
	#s/^([A-Z][A-Z][A-Z]+) [A-Z].*/$1/;
	#s/[A-Z]\. ?[A-Z]\. and [A-Z]\. ?[A-Z]\. (.*)/$1/;
	#s/[A-Z]\. and [A-Z]\. (.*)/$1/;
	#s/ \(?(with|and) .*//;
	#s/[;,] .*//;
	#s/, .*//;
	#s/^.* //;
	#ucfirst(lc($_));
	$all_names{$_}.="$fields[0]\t" unless $seen{$fields[0]}++;
}


$fields[13]="" if $fields[13] =~/null/i;
$fields[14]="" if $fields[13] =~/null/i;
#name field not printout
			print  OUT "$fields[0] ", join("\t",@fields[1 .. 11,13,14,15,16,17,18,19]), "\n";
	}
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
$dbh=new Sybase::CTlib 'rlmoe', $password;
$query=<<EOQ;
select accession_id, coll_num_prefix, coll_number, coll_num_suffix
from accession where
(
loc_state="CA"
and accession_id not like "UCR%"
and accession_id not like "UCD%"
and accession_id not like "UCI%"
and accession_id not like "SDSU%"
and accession_id not like "CHSC%"
and accession_id not like "SBBG%"
and objkind_id !=5
)
EOQ
$dbh->ct_execute("$query");
while($dbh->ct_results($restype) == CS_SUCCEED){
	next unless $dbh->ct_fetchable($restype);
	while((@fields)= $dbh->ct_fetch){
		$fields[0]=uc($fields[0]);
		$num=$fields[2];
		#$num=join("",@fields[1.. 3]);
		next unless $num=~/[0-9a-zA-Z]/;
		$num=~s/^ *//;
		$num=~s/^[-# ]+//;
		$num=~s/ *$//;
		next if $num=~/^s\.?n\.?$/i;
		$fields[0]=~s/ *$//;
		$num{$num}.="$fields[0]\t";
	}
}
open(OUT, ">CDL_coll_number.in") || die;
foreach (sort (keys(%num))){
	print  OUT "$_ $num{$_}\n";
}
close(OUT);

$dbh=new Sybase::CTlib 'rlmoe', $password;
$query=<<EOQ;
select a.accession_id, a.vouchkind_id, a.descr
from voucher a, accession b
where
(
a.accession_id=b.accession_id and b.loc_state="CA"
and a.accession_id not like "UCR%"
and a.accession_id not like "UCD%"
and a.accession_id not like "UCI%"
and a.accession_id not like "SDSU%"
and a.accession_id not like "CHSC%"
and a.accession_id not like "SBBG%"
and b.objkind_id !=5
)
EOQ
$dbh->ct_execute("$query");
while($dbh->ct_results($restype) == CS_SUCCEED){
	next unless $dbh->ct_fetchable($restype);
	while((@fields)= $dbh->ct_fetch){
		$fields[0]=uc($fields[0]);
$cdl_voucher{$fields[0]}.="\t$fields[1]\t$fields[2]";
}
}
open(OUT,">CDL_voucher.in") || die;
foreach(sort(keys(%cdl_voucher))){
print OUT "$_$cdl_voucher{$_}\n";
}

$dbh=new Sybase::CTlib 'rlmoe', $password;
$query=<<EOQ;
select a.accession_id, noauth_name, committee_abbr, anno_datestring, a.anno_note
from annotation_history a, committee b, taxon_noauth_name c, accession d
where
(
a.taxon_id=c.taxon_id
and a.annotator_id=b.committee_id
and vname_id = 0
and a.accession_id=d.accession_id
and d.loc_state="CA"
and a.accession_id not like "UCR%"
and a.accession_id not like "UCD%"
and a.accession_id not like "UCI%"
and a.accession_id not like "SDSU%"
and a.accession_id not like "CHSC%"
and a.accession_id not like "SBBG%"
and d.objkind_id !=5
)
EOQ
$dbh->ct_execute("$query");
while($dbh->ct_results($restype) == CS_SUCCEED){
	next unless $dbh->ct_fetchable($restype);
	while((@fields)= $dbh->ct_fetch){
		$fields[0]=uc($fields[0]);
		$fields[0]=~s/ *$//;
		$cdl_anno{$fields[0]}.="$fields[1]; $fields[2]; $fields[3]; $fields[4]\n"
	}
}
$query=<<EOQ;
select a.accession_id, variant_name, committee_abbr, anno_datestring, anno_note
from annotation_history a, committee b, variant_taxon_name c, accession d
where a.vname_id=c.vname_id
and a.annotator_id=b.committee_id
and taxon_id = 0
and a.accession_id=d.accession_id
and d.objkind_id !=5
EOQ
$dbh->ct_execute("$query");
while($dbh->ct_results($restype) == CS_SUCCEED){
	next unless $dbh->ct_fetchable($restype);
	while((@fields)= $dbh->ct_fetch){
		$fields[0]=uc($fields[0]);
		$fields[0]=~s/ *$//;
		next if $fields[1]=~/^none/;
		next if $fields[1]=~/^Not applicable/;
		$cdl_anno{$fields[0]}.="$fields[1]; $fields[2]; $fields[3]; $fields[4]\n"
	}
}
open (OUT, ">CDL_annohist.in") || die;
foreach(sort(keys(%cdl_anno))){
	print OUT "$_\n$cdl_anno{$_}\n";
}

open(OUT, ">CDL_bad_date") || die;
foreach(keys(%null_date)){
print OUT "bad date: $null_date{$_}: $_ \n";
}
close(OUT);
print "$skip_accession accession numbers supplanted\n";
$tar_return=system 'tar -cf cdl_tar CDL*';
print "tar file cdl_tar $tar_return\n";
#die;
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
#open (OUT, ">CDL_conversion") || die;
#print OUT $convert;
#close OUT;

sub modify_collector {
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
			s/ \(?(with|and) .*//;
			s/[;,] .*//;
			#s/, .*//;
			s/^.* //;
s/&(.)[^;]*;/\1/g && print "$_\n";
			return ucfirst(lc($_));
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
#warn "$_\n";
$_;
}
