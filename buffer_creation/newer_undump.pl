#!/bin/perl
open(LOG, ">>cdl_log") || die;
use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);
use Time::JulianDay;
use BerkeleyDB;
use lib '/Users/davidbaxter/DATA';
use CCH; #for &load_fips



($t)=gettimeofday;
print "start $t\n";
 $timestart=time();
%flat_dbm=(
CDL_date_simple => 'CDL_date_simple.in',
CDL_county => 'CDL_counties.in',
CDL_date_range => 'CDL_date_range.in',
CDL_coll_number =>   'CDL_coll_number.in',
);
#CDL_TID_TO_NAME =>   'CDL_tid_to_name.in',
($t)=gettimeofday;
print "after tar  $t\n";
foreach $file("CDL_collectors.in", "/Users/davidbaxter/DATA/bulkload_data/CDL_collectors.in"){
	open(IN, $file) || die;
	while(<IN>){
		chomp;
		($key,$value)=m/^([^ ,]+),? (.*)/;
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

foreach $file("CDL_loc_list.in", "/Users/davidbaxter/DATA/bulkload_data/CDL_loc_list.in"){
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

foreach $file("CDL_name_list.in", "/Users/davidbaxter/DATA/bulkload_data/CDL_name_list.in"){
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


##SEPARATED
#unlink("CDL_TID_TO_NAME");
    	#tie %f_contents, "BerkeleyDB::Hash",
                #-Filename => "CDL_TID_TO_NAME",
		#-Flags => DB_CREATE
        #or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;
	#open(IN,"CDL_tid_to_name.in") || die "couldn't open name dile CDL_tid_to_name.in\n";
#while(<IN>){
	#chomp;
	#s/\t$//;
	#($key, $value)=m/^([^ ]+) (.*)/;
	#$f_contents{$key}=$value;
#}



foreach $dbm_file (keys(%flat_dbm)){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
foreach $filename ($filename, "/Users/davidbaxter/DATA/bulkload_data/$filename"){
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
print "$dbm_file $line_c processed in $interval\n";
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

 #tie %TNOAN, "BerkeleyDB::Hash", -Filename => "CDL_TID_TO_NAME" or die "Cannot open file TID_TO_NAME: $! $BerkeleyDB::Error\n" ;
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
foreach $filename ($filename, "/Users/davidbaxter/DATA/bulkload_data/$filename"){
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
print "$dbm_file $line_c processed in $interval\n";
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
foreach $filename ($filename, "/Users/davidbaxter/DATA/bulkload_data/$filename"){
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
print "$dbm_file $line_c processed in $interval\n";
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
foreach $filename ($filename, "/Users/davidbaxter/DATA/bulkload_data/$filename"){
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
		$herb_code="HUH" if $herb_code eq "A";
		$herb_code="HUH" if $herb_code eq "GH";
		$herb_code="HUH" if $herb_code eq "AMES";
		$herb_code="HUH" if $herb_code eq "ECON";
		$herb_code="YM" if $herb_code eq "YM-YOSE";
								#$herb_code="UC" if $herb_code eq "DS";
								$bar_length{$key}{$herb_code}++;
							}
				}
	}
open(OUT, ">CDL_county_list.txt") || die;
foreach $county (keys(%bar_length)){
	print OUT "$county\t$cc{$county}\t";
	foreach $inst (keys(%{$bar_length{$county}})){
		unless($inst=~/^(CDA|CAS|DS|UC|JEPS|UCSC|UCSB|SBBG|POM|RSA|UCR|DAV|PGM|CHSC|SJSU|IRVC|SD|SDSU|HSC|CSUSB|SCFS|NY|HUH|YM|OBI|GMDRC|JOTR|VVC|SFV|LA|SEINET|CLARK|SACT|BLMAR|JROH|PASA|CATA|MACF)$/){
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
					($year,$month,$day)= &inverse_julian_day($key);
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
					($startyear,$month,$day)= &inverse_julian_day($start);
					($endyear,$month,$day)= &inverse_julian_day($end);
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

my $next_year= (localtime)[5]+1901;
foreach $year (sort(keys(%seen))){
if ($year < $next_year){
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


#foreach (sort(keys(%inst_count))){
#print OUT "$_: $inst_count{$_}\n";
#}
#CDL/CDL_name_list.in:quercus × alvordiana CAS1034	SD71047	


tie (%G_T_F, "BerkeleyDB::Hash", -Filename =>"G_T_F", -Flags => DB_RDONLY) || die "Cannot open file genus_to_family_hash: $! $BerkeleyDB::Error\n" ;
tie(%CODE_TO_NAME, "BerkeleyDB::Hash", -Filename=>"CDL_TID_TO_NAME", -Flags=>DB_RDONLY)|| die "$!";
($t)=gettimeofday;
print "reading main  $t\n";
open(IN, "CDL_main.in") || die;

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
	if($genus=~/aceae$/i){
		$genus=uc($genus);
		vec($FV{$genus},$LC,1)=1;
	}
	else{
		vec($FV{$G_T_F{$genus}},$LC,1)=1;
	}


	#if ( $rest[4] && ($rest[4]==$rest[5]))#
	#Nov 6 2009
	if ( $rest[4] && ($rest[5]- $rest[4]< 32)){
		$jdate=$rest[4];
		($year,$month,$day)= &inverse_julian_day($jdate);
		$month=("",Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec)[$month];
		vec($DV{$month},$LC,1)=1;
	}
}

system ("cat record_tally");


tie %f_contents, "BerkeleyDB::Hash", -Filename => "CDL_voucher", -Flags => DB_CREATE or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;
while(($key,$value)=each(%f_contents)){
		unless ($seen_aid{$key}){
			delete $f_contents{$key};
			++$voucher_delete;
		}
	}
print "$voucher_delete voucher deletions\n";

($t)=gettimeofday;
print "done reading main  $t\n";
$t0 = [gettimeofday];
unlink("CDL_AID_recno");
tie @h_BDB, 'BerkeleyDB::Recno', -Filename => "CDL_AID_recno", -Flags => DB_CREATE, -Property => DB_RENUMBER or die "Cannot open $filename: $!\n" ;
@h_BDB=@h;
untie @h_BDB;
$t1 = [gettimeofday];
$interval = tv_interval $t0, $t1;
$t0 = [gettimeofday];
print "RECNO copied in $interval\n";

$dbm_file="CDL_family_vec_hash";
unlink($dbm_file);
tie %FV_BDB, "BerkeleyDB::Hash", -Filename => $dbm_file, -Flags => DB_CREATE or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;


while(($key,$value)=each(%FV)){
	$FV_BDB{$key}=$value;
}
untie %FV_BDB;
$t1 = [gettimeofday];
$interval = tv_interval $t0, $t1;
$t0 = [gettimeofday];
print "FV copied in $interval\n";



$dbm_file="CDL_date_vec_hash";
unlink($dbm_file);
tie %DV_BDB, "BerkeleyDB::Hash", -Filename => $dbm_file, -Flags => DB_CREATE or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;
while(($key,$value)=each(%DV)){
	$DV_BDB{$key}=$value;
}

untie %DV_BDB;
$t1 = [gettimeofday];
$interval = tv_interval $t0, $t1;
$t0 = [gettimeofday];
print "DV copied in $interval\n";


($t)=gettimeofday;
print "done reading main  $t\n";

open(OUT, ">>record_tally");
 $timeend=time();
$duration= $timeend - $timestart;
print OUT "$timestart Records: $main_record_count ($duration)\n";
close(OUT);
close(LOG);
