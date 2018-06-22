#this is the first file found that was actually called newer_undump.pl; all future versions have this name
#!/bin/perl
open(LOG, ">>cdl_log") || die;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

($t)=gettimeofday;
print "start $t\n";
 $timestart=time();
use BerkeleyDB;
%flat_dbm=(
CDL_date_simple => 'CDL_date_simple.in',
CDL_county => 'CDL_counties.in',
CDL_date_range => 'CDL_date_range.in',
CDL_TID_TO_NAME =>   'CDL_tid_to_name.in',
CDL_coll_number =>   'CDL_coll_number.in',
);
($t)=gettimeofday;
print "after tar  $t\n";
foreach $file("CDL_collectors.in", "cdl/CDL_collectors.in"){
	open(IN, $file) || die;
	while(<IN>){
		chomp;
		($key,$value)=m/^([^ ]+) (.*)/;
		if($store_coll{$key}){
		$store_coll{$key}=~s/\t*$//;
			$store_coll{$key}.="\t$value";
		}
		else{
			$store_coll{$key}=$value;
		}
	}
close(IN);
}
open(OUT,">CDL_collectors.txt") || die;
foreach(sort(keys(%store_coll))){
	print OUT "$_ $store_coll{$_}\n";
}
close(OUT);
system("chmod 0666 CDL_collectors.txt");
($t)=gettimeofday;
print "after coll  $t\n";

foreach $file("CDL_loc_list.in", "cdl/CDL_loc_list.in"){
	open(IN, $file) || die;
	while(<IN>){
		chomp;
		($key,$value)=m/^([^ ]+) (.*)/;
		if($store_loc{$key}){
		$store_loc{$key}=~s/\t*$//;
			$store_loc{$key}.="\t$value";
		}
		else{
			$store_loc{$key}=$value;
		}
	}
close(IN);
}
open(OUT,">CDL_location_words.txt") || die;;
foreach(sort(keys(%store_loc))){
	print OUT "$_ $store_loc{$_}\n";
}
close(OUT);
system("chmod 0666 CDL_location_words.txt");
($t)=gettimeofday;
print "after loc  $t\n";

foreach $file("CDL_name_list.in", "cdl/CDL_name_list.in"){
        open(IN, $file) || die;
        while(<IN>){
#print "$file $_"  if m/juglans regia/;
                chomp;
                ($key,$value)=m/^([×a-z -]+) (.*)/;
                if($store_name{$key}){
                $store_name{$key}=~s/\t*$//;
                        $store_name{$key}.="\t$value";
                }
                else{
                        $store_name{$key}=$value;
                }
        }
close(IN);
}
#die;
open(OUT,">CDL_name_list.txt") || die;;
foreach(sort(keys(%store_name))){
        print OUT "$_ $store_name{$_}\n";
}
close(OUT);
system("chmod 0666 CDL_name_list.txt");
($t)=gettimeofday;
print "after name  $t\n";





foreach $dbm_file (keys(%flat_dbm)){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
foreach $filename ($filename, "cdl/$filename"){
	open(IN,"$filename") || die "couldn't open $filename\n";
	print "opening $filename, writing to $dbm_file\n";
    	tie %f_contents, "BerkeleyDB::Hash",
                -Filename => $dbm_file,
		-Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

while(<IN>){
	++$line_c;
	unless($line_c % 25000){
$t1 = [gettimeofday];
$interval = tv_interval $t0, $t1;
$t0 = [gettimeofday];
print "$line_c processed in $interval\n";
}
	chomp;
	s/\t$//;
	($key, $value)=m/^([^ ]+) (.*)/;
	if($f_contents{$key}eq $value){
#print "$filename $key \n$value\n$f_contents{$key}\n";
	next;
	}
	$key=~s/_/ /g if ($filename=~/counties/);
	#next;
	if($f_contents{$key}){
		$store_coll{$key}=~s/\t*$//;
			$f_contents{$key}.="\t$value";
	}
	else{
	$f_contents{$key}=$value;
	}
}
system("chmod 0666 $dbm_file");

untie %f_contents;

close(IN);
}
($t)=gettimeofday;
print "after $dbm_file  $t\n";
}

 tie %TNOAN, "BerkeleyDB::Hash", -Filename => "CDL_TID_TO_NAME" or die "Cannot open file TID_TO_NAME: $! $BerkeleyDB::Error\n" ;
#open(OUT,">CF_countylist_exp.txt");
#foreach (sort {$TNOAN{$a} cmp $TNOAN{$b}} (keys(%ALL_CF))){
    #if($TNOAN{$_}=~/ [a-z]/){
	#print OUT "$TNOAN{$_}\t";
        #$county_list =join(", ",(sort(keys(%{$ALL_CF{$_}}))));
            #print OUT "$county_list\n";
    #}
#}
#close(OUT);
#($t)=gettimeofday;
#print "after countylist  $t\n";

#open(OUT,">CF_countylist.txt");
#foreach (sort {$TNOAN{$a} cmp $TNOAN{$b}} (keys(%UCJEPS_CF))){
    #if($TNOAN{$_}=~/ [a-z]/){
	#print OUT "$TNOAN{$_}\t";
        #$county_list =join(", ",(sort(keys(%{$UCJEPS_CF{$_}}))));
            #print OUT "$county_list\n";
    #}
#}
#close(OUT);
($t)=gettimeofday;
print "after countylist  $t\n";


%flat_dbm=(
'CDL_notes' => 'CDL_notes.in'
);

foreach $dbm_file (sort(keys(%flat_dbm))){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
foreach $filename ($filename, "cdl/$filename"){
	open(IN,"$filename") || die "couldn't open $filename\n";
	print "opening $filename, writing to $dbm_file\n";
    	tie %f_contents, "BerkeleyDB::Hash",
                -Filename => $dbm_file,
		-Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

	while(<IN>){
		++$line_c;
		chomp;
		($key, $value)=split(/\t/);
		$f_contents{$key}=$value;
		unless($line_c % 25000){
$t1 = [gettimeofday];
$interval = tv_interval $t0, $t1;
$t0 = [gettimeofday];
print "$line_c processed in $interval\n";
}
	}
	system("chmod 0666 $dbm_file");

	untie %f_contents;
close(IN);


}
}
($t)=gettimeofday;
print "after $dbm_file  $t\n";
%flat_dbm=(
'CDL_annohist' => 'CDL_annohist.in'
);

foreach $dbm_file (sort(keys(%flat_dbm))){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
foreach $filename ($filename, "cdl/$filename"){
	open(IN,"$filename") || die "couldn't open $filename\n";
	print "opening $filename, writing to $dbm_file\n";
    	tie %f_contents, "BerkeleyDB::Hash",
                -Filename => $dbm_file,
		-Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

	local($/)="";
	while(<IN>){
		++$line_c;
		chomp;
		s/\t$//;
		($key, $value)=m/^(.*)\n([^\000]+)/;
		$f_contents{$key}=$value;
		unless($line_c % 25000){
$t1 = [gettimeofday];
$interval = tv_interval $t0, $t1;
$t0 = [gettimeofday];
print "$line_c processed in $interval\n";
}
	}
	system("chmod 0666 $dbm_file");

	untie %f_contents;
close(IN);

}
}
($t)=gettimeofday;
print "after $dbm_file  $t\n";
%flat_dbm=(
'CDL_voucher' => 'CDL_voucher.in'
);

foreach $dbm_file (sort(keys(%flat_dbm))){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
foreach $filename ($filename, "cdl/$filename"){
	open(IN,"$filename") || die "couldn't open $filename\n";
		print "opening $filename, writing to $dbm_file\n";
    	tie %f_contents, "BerkeleyDB::Hash",
                -Filename => $dbm_file,
		-Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

	local($/)="\n";
	while(<IN>){
		++$line_c;
		chomp;
		s/\t$//;
		($key, $value)=m/^([^\t]+)\t(.*)/;
		$key=~s/ *$//;
		$f_contents{$key}=$value;
		unless($line_c % 25000){
#warn "$key : $value\n";
$t1 = [gettimeofday];
$interval = tv_interval $t0, $t1;
$t0 = [gettimeofday];
print "$line_c processed in $interval\n";
	}
}
	system("chmod 0666 $dbm_file");
	
	untie %f_contents;
close(IN);

}
}
($t)=gettimeofday;
print "after $dbm_file  $t\n";
#system "rm CDL_*.in";
system "chmod +r *.txt";


 tie %CDL, "BerkeleyDB::Hash", -Filename => "CDL_county" or die "Cannot open file CDL_county" ;
 while(($key,$value)=each(%CDL)){
     @fields=split(/\t/,$value);
	 $cc=  $#fields+1;
	$cc{$key}=$cc;
	foreach(@fields){
		if(m/^([A-Za-z]+)/){
			($herb_code=$1)=~s/UCD/DAV/;
		$herb_code="UC" if $herb_code eq "UCLA";
								#$herb_code="UC" if $herb_code eq "DS";
								$bar_length{$key}{$herb_code}++;
							}
				}
	}
open(OUT, ">CDL_county_list.txt") || die;
foreach $county (keys(%bar_length)){
	print OUT "$county\t$cc{$county}\t";
	foreach $inst (keys(%{$bar_length{$county}})){
		unless($inst=~/^CDA|CAS|DS|UC|JEPS|UCSC|UCSB|SBBG|POM|RSA|UCR|DAV|PGM|CHSC|SJSU|IRVC|SD|SDSU|HSC$/){
			warn "$inst unexpected and skipped\n";
			next;
		}
		print OUT "$inst: $bar_length{$county}{$inst}\t";
	}
	print OUT "\n";
}
close(OUT);
($t)=gettimeofday;
print "after more county  $t\n";

           my @h ;
                       unlink("CDL_date_recno");
           tie @h, 'BerkeleyDB::Recno',
                       -Filename   => "CDL_date_recno",
                       -Flags      => DB_CREATE,
                       -Property   => DB_RENUMBER
             or die "Cannot open $filename: $!\n" ;

           tie %hash, 'BerkeleyDB::Hash',
                       -Filename   => "CDL_date_simple"
             or die "Cannot open $filename: $!\n" ;
while(($key, $value)=each(%hash)){
					($year,$month,$day)= inverse_julian_day($key);
if($year > 1799){
$seen{$year} .= "$value\t";
}
}
($t)=gettimeofday;
print "after date processing $t\n";
           tie %hash, 'BerkeleyDB::Hash',
                       -Filename   => "CDL_date_range"
             or die "Cannot open $filename: $!\n" ;
while(($key, $value)=each(%hash)){
if($key=~m/(\d+)-(\d+)/){
$start=$1; $end=$2;
					($startyear,$month,$day)= inverse_julian_day($start);
					($endyear,$month,$day)= inverse_julian_day($end);
$startyear="1800" unless $startyear > 1800;
if($startyear > $endyear){
#print "$key $value\n";
next;
}
#print "$startyear $endyear\n";
@ids=split(/\t/,$value);
foreach $an ($startyear .. $endyear){
if($an > 1799){
grep($seen{$an} .= "$_\t",@ids);
}
}
}
}
($t)=gettimeofday;
print "after more dates  $t\n";

foreach $year (sort(keys(%seen))){
if ($year < 2011){
%ids=();
@array=split(/\t/, $seen{$year});
grep($ids{$_}++, @array);
$h[$year]=join("\t", keys(%ids));
}
}
($t)=gettimeofday;
print "after more dates  $t\n";
print "untieing hash\n";
untie(%hash);
           untie(@h);
print "untieing h\n";
 untie %CDL;
print "untieing CDL\n";
        untie %h_long;
        untie %h_lat;
	untie %tid_to_county;

open(NEWS,"news.html");
#$news=get("http://ucjeps.berkeley.edu/consortium/news.html"):
$inst_count{DAV_count}=$inst_count{UCD_count};
$inst_count{UC_count} += $inst_count{JEPS_count};
$inst_count{UC_count} += $inst_count{UCLA_count};
$inst_count{RSA_count} += $inst_count{POM_count};
$inst_count{CAS_count} +=$inst_count{DS_count};
open(OUT, ">CDL_news.html");
$record_table=<<EOT;
<table class="bodyTest"> <tr><td> CAS-DS</td><td>$inst_count{CAS_count}</td></tr> <tr><td> CDA</td><td>$inst_count{CDA_count}</td></tr> <tr><td> CHSC</td><td>$inst_count{CHSC_count}</td></tr> <tr><td> DAV</td><td>$inst_count{DAV_count}</td></tr> <tr><td> HSC</td><td>$inst_count{HSC_count}</td></tr> <tr><td> IRVC</td><td>$inst_count{IRVC_count}</td></tr> <tr><td> PGM</td><td>$inst_count{PGM_count}</td></tr> <tr><td> RSA-POM</td><td>$inst_count{RSA_count}</td></tr> <tr><td> SBBG</td><td>$inst_count{SBBG_count}</td></tr> <tr><td> SD</td><td>$inst_count{SD_count}</td></tr>
<tr><td> SDSU</td><td>$inst_count{SDSU_count}</td></tr>
<tr><td> SJSU</td><td>$inst_count{SJSU_count}</td></tr>
<tr><td> UC-JEPS</td><td>$inst_count{UC_count}</td></tr> <tr><td> UCR</td><td>$inst_count{UCR_count}</td></tr> <tr><td> UCSB</td><td>$inst_count{UCSB_count}</td></tr> <tr><td> UCSC</td><td>$inst_count{UCSC_count}</td></tr> </table>
EOT
$today=localtime();
$today=~s/\d\d:\d\d:\d\d//;
while(<NEWS>){
s!Record count: .*</span><br />!Record count: $record_count ($today)</span><br />!;
s/<table class=.*/$record_table/o;
print OUT;
}
#foreach (sort(keys(%inst_count))){
#print OUT "$_: $inst_count{$_}\n";
#}
#CDL/CDL_name_list.in:quercus × alvordiana CAS1034	SD71047	


tie (%G_T_F, "BerkeleyDB::Hash", -Filename =>"G_T_F", -Flags => DB_RDONLY) || die "Cannot open file $dbm_file: $! $BerkeleyDB::Error\n" ;
tie(%CODE_TO_NAME, "BerkeleyDB::Hash", -Filename=>"CDL_TID_TO_NAME", -Flags=>DB_RDONLY)|| die "$!";
($t)=gettimeofday;
print "reading main  $t\n";
open(IN, "CDL_main.in") || die;
#use BerkeleyDB;
unlink("CDL_AID_recno");
tie @h, 'BerkeleyDB::Recno', -Filename => "CDL_AID_recno", -Flags => DB_CREATE, -Property => DB_RENUMBER
             or die "Cannot open $filename: $!\n" ;
$dbm_file="CDL_family_vec_hash";
unlink($dbm_file);
tie %FV, "BerkeleyDB::Hash", -Filename => $dbm_file, -Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;
$dbm_file="CDL_date_vec_hash";
unlink($dbm_file);
tie %DV, "BerkeleyDB::Hash", -Filename => $dbm_file, -Flags => DB_CREATE
        or die "Cannot open file $$dbm_file: $! $BerkeleyDB::Error\n" ;

	$line_c=0;
while(<IN>){
	($aid)=m/^([^ ]+)/;
	if($seen_aid{$aid}++){
		print "DUPLICATE $key\n";
	--$main_record_count;
	}
	++$LC;
	++$main_record_count;
	++$line_c;
	unless($line_c % 25000){
$t1 = [gettimeofday];
$interval = tv_interval $t0, $t1;
$t0 = [gettimeofday];
print "$line_c processed in $interval\n";
}
	chomp;
	(@fields)=split(/\t/);
	($aid,$tid)=split(/ /,$fields[0]);
	@rest=@fields[1 .. 9];
	($genus=$CODE_TO_NAME{$tid})=~s/ .*//;
	unless($seen{$genus}++){
		#print <<EOP;
#$aid $tid $genus $G_T_F{$genus}
#EOP
	}
	push(@h,$aid);
	if($genus=~/aceae/){
		$genus=uc($genus);
		vec($FV{$genus},$LC,1)=1;
	}
	else{
		vec($FV{$G_T_F{$genus}},$LC,1)=1;
	}


	#if ( $rest[4] && ($rest[4]==$rest[5])){
	#Nov 6 2009
	if ( $rest[4] && ($rest[5]- $rest[4]< 32)){
		$jdate=$rest[4];
		($year,$month,$day)= inverse_julian_day($jdate);
		$month=("",Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$month];
		vec($DV{$month},$LC,1)=1;
	}
}
($t)=gettimeofday;
print "done reading main  $t\n";

open(OUT, ">>record_tally");
 $timeend=time();
$duration= $timeend - $timestart;
print OUT "$timestart Records: $main_record_count ($duration)\n";
close(OUT);
close(LOG);

system ("cat record_tally");


tie %f_contents, "BerkeleyDB::Hash", -Filename => "CDL_voucher", -Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;
while(($key,$value)=each(%f_contents)){
		unless ($seen_aid{$key}){
			delete $f_contents{$key};
			++$voucher_delete;
		}
	}
print "$voucher_delete voucher deletions\n";




sub inverse_julian_day {
	use integer;
        my($jd) = @_;
        my($jdate_tmp);
        my($m,$d,$y);

        #carp("warning: julian date $jd pre-dates British use of Gregorian calendar\n") if ($jd < $brit_jd);

        $jdate_tmp = $jd - 1721119;
        $y = (4 * $jdate_tmp - 1)/146097;
        $jdate_tmp = 4 * $jdate_tmp - 1 - 146097 * $y;
        $d = $jdate_tmp/4;
        $jdate_tmp = (4 * $d + 3)/1461;
        $d = 4 * $d + 3 - 1461 * $jdate_tmp;
        $d = ($d + 4)/4;
        $m = (5 * $d - 3)/153;
        $d = 5 * $d - 3 - 153 * $m;
        $d = ($d + 5) / 5;
        $y = 100 * $y + $jdate_tmp;
        if($m < 10) {
                $m += 3;
        }
	else {
                $m -= 9;
                ++$y;
        }
        return ($y, $m, $d);
}
				  sub load_fips{
				  return (
				  "06001","ALAMEDA",
				  "06003","ALPINE",
				  "06005","AMADOR",
				  "06007","BUTTE",
				  "06009","CALAVERAS",
				  "06011","COLUSA",
				  "06013","CONTRA COSTA",
				  "06015","DEL NORTE",
				  "06017","EL DORADO",
				  "06019","FRESNO",
				  "06021","GLENN",
				  "06023","HUMBOLDT",
				  "06025","IMPERIAL",
				  "06027","INYO",
				  "06029","KERN",
				  "06031","KINGS",
				  "06033","LAKE",
				  "06035","LASSEN",
				  "06037","LOS ANGELES",
				  "06039","MADERA",
				  "06041","MARIN",
				  "06043","MARIPOSA",
				  "06045","MENDOCINO",
				  "06047","MERCED",
				  "06049","MODOC",
				  "06051","MONO",
				  "06053","MONTEREY",
				  "06055","NAPA",
				  "06057","NEVADA",
				  "06059","ORANGE",
				  "06061","PLACER",
				  "06063","PLUMAS",
				  "06065","RIVERSIDE",
				  "06067","SACRAMENTO",
				  "06069","SAN BENITO",
				  "06071","SAN BERNARDINO",
				  "06073","SAN DIEGO",
				  "06075","SAN FRANCISCO",
				  "06077","SAN JOAQUIN",
				  "06079","SAN LUIS OBISPO",
				  "06081","SAN MATEO",
				  "06083","SANTA BARBARA",
				  "06085","SANTA CLARA",
				  "06087","SANTA CRUZ",
				  "06089","SHASTA",
				  "06091","SIERRA",
				  "06093","SISKIYOU",
				  "06095","SOLANO",
				  "06097","SONOMA",
				  "06099","STANISLAUS",
				  "06101","SUTTER",
				  "06103","TEHAMA",
				  "06105","TRINITY",
				  "06107","TULARE",
				  "06109","TUOLUMNE",
				  "06111","VENTURA",
				  "06113","YOLO",
				  "06115","YUBA"
				  );
				  }
