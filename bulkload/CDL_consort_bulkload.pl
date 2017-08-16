use Smasch;
#use utf8;
use Time::JulianDay;
use Time::ParseDate;
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
warn "NB: Some of the datafiles are updates, some are complete. Records in the datafiles will supersede records in SMASCH\n";
$tnum="";

@sggb_precision=(0, 10, 100, 1000, 10000);

open(OUT, ">CDL_main.in") || die;
open(ERR, ">accent_err") || die;

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
#&load_collectors();
&load_noauth_name();
&load_be();


@datafiles=(
"UCR.out",
);
foreach $datafile (@datafiles){
%seen_dups=();
	print $datafile, "\n";
	open(IN,"$datafile")|| die;
	$/="";
	while(<IN>){
@anno=();
(@anno)=m/Annotation: (...+)/g;
print "anno list: ", join("   ", @anno),"\n";
		s/  +/ /g;
		++$countpar;
		if (s/Accession_id: (...*)/Accession: $1/){
if($seen_dups{$1}++){
			warn "skipping $1 duplicate\n";
next;
}
#if(m/Location: (.*ex hort.*)/){
#$hort=$1;
#($co)=m/County: (.*)/;
			#warn "skipping hort specimen $hort $co\n";
#next;
#}
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
		$collector=$1;
#next if $coll_seen{$collector}++;
#print <<EOP;
#1: $collector
#EOP
		foreach($collector){
			s/Andr�/Andr&eacute;/;
			s/Andr�e/Andr&eacute;/;
			s/Andr�/Andr&eacute;/;
			s/Andrﾎ/Andr&eacute;/;
			s/Beaupré/Beaupr&eacute;/;
			s/Boër/Bo&euml;r/;
			s/Brinkmann-Bus�/Brinkmann-Bus&eacute;/;
			s/Garc�a/Garc&iacute;a/;
			s/Hölzer/H&ouml;zer/;
			s/LaPr�/LaPr&eacute;/;
			s/LaPr�/LaPr&eacute;/;
			s/LaPrﾎ/LaPr&eacute;/;
			s/LaPr�/LaPr&eacute;/;
			s/Laferrière/Laferri&egrave;re/;
			s/Mu�oz/Mu&ntilde;oz/;
			s/Muﾖoz/Mu&ntilde;oz/;
			s/Niederm�ller/Niederm&uuml;ller/;
			s/Nordenski�ld/Nordenski&ouml;ld/;
			s/Ordóñez/Ord&oacute;&ntilde;ez/;
			s/O�/O'/;
			s/O�Berg/O'Berg/;
			s/O�Brien/O'Brien/;
			s/Pe�alosa/Pe&ntilde;alosa/;
			s/Pe�alosa/Pe&ntilde;alosa/;
			s/Ren�e/Renee/;
			s/Ren�e/Renee/;
			s/Steve Boyd`/Steve Boyd/;
			s/Vern` Yadon/Vern Yadon/;
			s/Villanse�or/Villase&ntilde;or/;
			s/Villase�or/Villase&ntilde;or/;
			s/Villaseﾖor/Villase&ntilde;or/;
			s/Villase�or/Villase&ntilde;or/;
			s/�Corky�/"Corky"/;
			s/�horne/Thorne/;
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

		$collector=~s/\.([A-Z])/. $1/g;
		$collector=~s/([A-Z]\.)([A-Z]) ([A-Z])/$1 $2. $3/;
		$collector=~s/([A-Z]\.)([A-Z]\.)([A-Z]\.)/$1 $2 $3/g;
		$collector=~s/([A-Z]\.)([A-Z]\.)/$1 $2/g;
		$collector=~s/(Fr.)([A-Z]\.)/$1 $2/g;
		$collector=~s/([A-Z]\.)([A-Z]')/$1 $2/g;
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
			elsif(m|^([0123]?\d\d?)/([A-Za-z][a-z][a-z])/([12][0789]\d\d)$| && $monthno{$2}){
					$monthno=$monthno{$2};
					$s_day_month=$1;
					$year=$3;
					$JD=julian_day($year, $monthno, $s_day_month);
					$LJD=julian_day($year, $monthno, $s_day_month);
				#print "7a ";
#$par="11a";
			}
			else{
				#warn "$hn Unexpected date; setting jdate to null $ds\n";
				$null_date{$ds}=$hn;
				$LJD=$JD="";
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
s/Trifolium willdenowii/Trifolium willdenovii/;
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
s/Chenopodium berlandieri var. zschackii/Chenopodium berlandieri var. zschackei/;
s/Elytrigia juncea subsp. boreali-atlantica/Elytrigia juncea subsp. boreo-atlantica/;
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

#$name=~s/Quercus �macdonaldii/Quercus � macdonaldii/;
#print "$name\n" if $name=~/alvordiana/;
		$name=~s/Quercus [^a-z] ?alvordiana/Quercus � alvordiana/;
		$name=~s/Quercus [^a-z] ?kinselae/Quercus � kinselae/;
		$name=~s/Equisetum [^a-z] ?ferrissii/Equisetum � ferrissii/;
		$name=~s/Eriogonum [^a-z] ?blissianum/Eriogonum � blissianum/;
		$name=~s/Pelargonium [^a-z] ?hortorum/Pelargonium � hortorum/;
		$name=~s/Hook\. f\./Hook./g;
		$name=~s/Desf. ex //;
		$name=~s/Gnaphalium luteoalbum/Gnaphalium luteo-album/;
		$name=~s/Argyranthemum foeniculum/Argyranthemum foeniculaceum/;
		$name=~s/Gilia austrooccidentalis/Gilia austro-occidentalis/;
		$name=~s/Micropus amphibola/Micropus amphibolus/;
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
	s|�|1/4|g;
	s|�|1/4|g;

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
	$S_accession{'lat_long_ref_source'}= $T_line{'Lat_long_ref_source'};
	$S_accession{'max_error_distance'}= $T_line{'Max_error_distance'};
	$S_accession{'max_error_units'}= $T_line{'Max_error_units'};
	($S_accession{'inst_abbr'}=  $T_line{'Accession'})=~s/ *[-\d]+//;
	$S_accession{'datum'}=  $T_line{'Datum'};
	


##################################
#DD check for correct county spelling some time!
	$S_accession{'loc_county'}=~s/ *$//;
	$S_accession{'loc_county'}=~s/ County *//;
	$S_accession{'loc_county'}=~s/ Co\.?$//;
	unless($S_accession{'loc_county'}=~/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|unknown|Unknown)/){
		$S_accession{'loc_county'}="unknown";
		warn " $S_accession{'loc_county'} unrecognized: set to unknown\n";
	}

	$S_accession{'loc_state'}=~s/California/CA/;
	$S_accession{'loc_state'}=~s/Calif\.?/CA/;
	$county{uc($S_accession{'loc_county'})}.= "$hn\t";
################################
#if($S_accession{'loc_distance'}=~s/; (.*)//){
	#$S_accession{'loc_place'} .= " ($1)";
#}
	#$location_field=join(" | ", "$S_accession{'loc_distance'} $S_accession{'loc_place'}" ,$S_accession{'loc_other'}, $S_accession{'loc_verbatim'});
	#$location_field=join(" | ", $S_accession{'loc_distance'}, $S_accession{'loc_place'},$S_accession{'loc_other'}, $S_accession{'loc_verbatim'});
	$location_field=join(" ", $S_accession{'loc_distance'}, $S_accession{'loc_place'},$S_accession{'loc_other'}, $S_accession{'loc_verbatim'});
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
print "T line $anno\n";
		##$cdl_anno{$S_folder{'accession_id'}}="$T_line{'Annotation'}\n";
		$cdl_anno{$S_folder{'accession_id'}}="$anno\n";
		#push(@cdl_anno,"$S_folder{'accession_id'}\n$T_line{'Annotation'}");
		push(@cdl_anno,"$S_folder{'accession_id'}\n$anno\n");
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
	return $_;
}


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
	print "CDLANNO: $_\n";
	($key,@value)=split(/\n/);
$value=join("\n",@value);
	print "KEY $key value $value\n";
	if($CDL_anno{$key}){
		$CDL_anno{$key}.="\n$value";
	}
	else{
		$CDL_anno{$key}="$value";
	}
}
open (OUT, ">CDL_annohist.in") || die;
foreach(sort(keys(%CDL_anno))){
	$CDL_anno{$_}=~s/×/� /;
	print OUT "$_\n$CDL_anno{$_}\n\n";
	print " add to IN  $_\n$CDL_anno{$_}\n\n";
}

open(OUT, ">CDL_bad_date") || die;
foreach(keys(%null_date)){
print OUT "bad date: $null_date{$_}: $_ \n";
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
$start=$_;
study();
s/Sierra ﾄevada/Sierra Nevada/;
s/Åna/Ana/;
s/.zelk.k/Ozelkuk/;
s/\xC7anyon/Canyon/;
s/River\x85on/River --- on/;
s/V\x87cr\x87t\x97t/V&aacute;cr&aacute;t&oacute;t/;
s/Yâ/&deg;/g;
s/â/&deg;/g;
#s/ââ/"/g;
s/\xef\xbe\x96/&ntilde;/g; 
s/\xef\xbf\xbd/&deg;/g; 
s/\xef\xbe\xa1/&deg;/g; 
s/\xef\xbe/&deg;/g;
s/\xEF\xA3\xBF//g;
s/\xC3\x8E//g;
s/\xEF\xBE\xB1//;
s/\xc3\x91/N/g;
s/\xc2\xa0\xc2\xb1/&plusmn;/g; 
s/\xc2\xb7\xc2\xb1/&plusmn;/g; 
s/±/&plusmn;/g;
s/\xef\xbe\x8e/&eacute;/g; 
s/\xe2\x88\x9e/&deg;/g; 
s/\xef\xbf\xbd/'/g;
s/\xe2\x80\x93/---/g; 
s/\xe2\x80\x99/'/g; 
s/\xe2\x80\x98/'/g; 
s/\xe2\x80\x9d/"/g; 
s/\xe2\x80\x9c/"/g; 
s/\xe2\x80\xA0/t/;
s/\xe2\x80 *\.\.\./' .../g; 
s/\xe2 *\.\.\./ .../g; 
s/\xc2 *\.\.\./" .../g; 
s/\xc21\/4/&frac14;/g; 
s/\xc2\xb7/&deg;/;
s/â/"/g;
s/â/"/g;
s/â/"/g;
s/Â°/&deg;/g;
s/Âº/&deg;/g;
s/\xcb\x9a/&deg;/g; 
s/Ë/&deg;/g;
s/Ã©/&eacute;/g;
s/Ã¨/&egrave;/g;
s/í/&iacute;/g;
s/Ã±/&ntilde;/g;
s/ñ/&ntilde;/g;
s/Ã±Ã³/&ntilde;&oacute;/g;
s/ó/&oacute;/g;
s/Ã¶/&ouml;/g;
s/ö/&ouml;/g;
s/Â±/&plusmn;/g;
s/±/&plusmn;/g;
s/Ã¼/&uuml;/g;
s/ü/&uuml;/g;
s/ââ/'/g;
s/â/'/g;
s/ï¿½/'/g;
s/û/'/g;
s/â/'/g;
s/Ô/'/g;
s/Õ/'/g;
s/Â½/&frac12;/g;
s/½/&frac12;/g;
s/Â¼/&frac14;/g;
s/¼/&frac14;/g;
s/Â¾/&frac34;<1>/g;
s//"/g;
s//"/g;
s/Ò/"/g;
s/Ó/"/g;
s/+//g;
s/Ö/&Ouml;/g;
s/&apos;/'/g;
s/\x91/'/g;
s//'/g;
s//'/g;
s/\xd4/'/g;
s/º/&deg;/g;
s/¡/&deg;/g;
s//&aacute;/g;
s/�/&aacute;/g;
s/\xe9/&eacute;/g; 
s/°/&deg;/g;
s/\x8e/&eacute;/g;
s/é/&eacute;/g;
s/\x8f/&egrave;/g;
s/\x8e/&eacute;/g; 
s/\x92/'/g; 
s/\x94/"/g; 
s/\x93/"/g; 
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
s/±/&plusmn;/g;
s/½/&frac12;/g;
s/\xa1/&deg;/g; 
s/(\d)\xba/$1$deg;/g;
s/\xf6/&ouml;/;
s/\x97/*oacute;/;
s/\x9A/*ouml;/;
s/¾/&frac34;<2>/g;
s/\cP+//g;
s/\xe1/&aacute;/g;
$end=$_;
unless ($start eq $end){
unless ($end=~ m/^[-\\`@$\[\]{}=*!|><#%~+\/\w\s,.?;:"')(&]*$/){
print ERR "$start\n$end\n\n";
}
}
$_;
}

	sub make_one_loc {
	local($_)=shift;
$start=$_;
	($distance,$place,$other,$verb)=split(/\t/);
$distance=~s/; *$//;
	if($other){
		@other=split(/[,;] /,$other);
				foreach $i (0 .. $#other){
					if($other[$i]eq $place){
						$other[$i]="";
					}
				}
	}
	$other=join(", ", @other);
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
print "$start\n$tot_loc\n" if length($tot_loc) <2;
return $tot_loc;
}
#Hybrid_annotation: Encelia californica × farinosa
#Quercus � moreha; M. G. Simpson; ?
