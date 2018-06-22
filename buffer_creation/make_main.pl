#!/bin/perl
#This script was formerly part of the undump script. Putting it by itself led to a ~3 X speedup
#in the whole operation. This has something to do with how BerkeleyDB uses memory.
#As part of the script, processing slowed down after reading ~350,000 lines of main,
#from 5 seconds per 25000 lines to more than 200. After 200000 lines, the rate
#picked up somewhat. The position of the slowdown was independent of content.
#As a self-standing script the rate is approximately constant

use Time::HiRes qw(usleep ualarm gettimeofday tv_interval);

open(LOG, ">cdl_log") || die;
($t)=gettimeofday;
print "start $t\n";
$suppl_coords="all_gbif.txt";
$time= -C "$suppl_coords";
print "Gbif coord file ", int($time)," days old\n";
open(IN,"$suppl_coords") || die;
while(<IN>){
s/^"//;
s/"$//;
chomp;
@gbif_fields=split(/","/);
$gbif_lat{$gbif_fields[0]}=$gbif_fields[1];
$gbif_long{$gbif_fields[0]}=$gbif_fields[2];
$gbif_datum{$gbif_fields[0]}=$gbif_fields[3];
$gbif_source{$gbif_fields[0]}=$gbif_fields[4];
$gbif_error{$gbif_fields[0]}=$gbif_fields[5];
$gbif_units{$gbif_fields[0]}=$gbif_fields[6];
}
open(IN,"georef_non_uc") || die;
while(<IN>){
chomp;
@gbif_fields=split(/\t/);
$gbif_lat{$gbif_fields[0]}=$gbif_fields[1];
$gbif_long{$gbif_fields[0]}=$gbif_fields[2];
$gbif_datum{$gbif_fields[0]}=$gbif_fields[4];
$gbif_source{$gbif_fields[0]}=$gbif_fields[3];
$gbif_error{$gbif_fields[0]}=$gbif_fields[5];
$gbif_units{$gbif_fields[0]}=$gbif_fields[6];
}
#POM223339	35.7804369	-120.2057593	Terrain Navigator	NAD27	1.008	mi
foreach(keys(%gbif_long)){
if(m/(CDA105324|UCD18559)/){
print "$_: $gbif_lat{$_}\n";
}
}
#die;
$t0 = [gettimeofday];
($t)=gettimeofday;
print "after gbif $t\n";



($t)=gettimeofday;
print "start $t\n";
use BerkeleyDB;
$time= -C "cdl_tar";
print "Tar file ", int($time)," days old\n";
system "tar -xvf cdl_tar";
%flat_dbm=(
CDL_DBM =>   'CDL_main.in',
);
system("ls -l CDL_main*");
system("cat cdl/CDL_main.in >> CDL_main.in");
system("ls -l CDL_main*");
	unlink("CDL_TID_TO_CO");
        unlink("CDL_lat");
        unlink("CDL_long");
        unlink("CDL_GEO");
tie %CDL_GEO, "BerkeleyDB::Hash", -Filename => "CDL_GEO", -Flags => DB_CREATE or die "Cannot open file CDL_GEO: $! $BerkeleyDB::Error\n" ;

        my %h_long;
        my %h_lat;
        tie %h_long, 'BerkeleyDB::Hash',
                       -Filename   => "CDL_long",
                       -Flags      => DB_CREATE
             or die "Cannot open $filename: $!\n" ;
        tie %h_lat, 'BerkeleyDB::Hash',
                       -Filename   => "CDL_lat",
                       -Flags      => DB_CREATE
             or die "Cannot open $filename: $!\n" ;
foreach $dbm_file (keys(%flat_dbm)){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
	open(IN,"$filename") || die "couldn't open $filename\n";
	warn "opening $filename, writing to $dbm_file\n";
    	tie %f_contents, "BerkeleyDB::Hash",
                -Filename => $dbm_file,
		-Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

	%fips_to_county=&load_fips();
	%fips=reverse(%fips_to_county);
	tie %tid_to_county, "BerkeleyDB::Hash", -Filename => "CDL_TID_TO_CO", -Flags => DB_CREATE or die "Cannot open file CDL_TID_TO_CO: $! $BerkeleyDB::Error\n" ;
	while(<IN>){
$value=$value_2="";
		($key, $value)=m/^([^ ]+) (.*)/;
if($seen_aid{$key}++){
print "DUPLICATE $key\n";
}
		++$line_c;
 unless ($line_c% 25000){
$t1 = [gettimeofday];
$interval = tv_interval $t0, $t1;
$t0 = [gettimeofday];
print  "$line_c processed in $interval\n";
}
#$store_int{"$line_c $key"} =  $interval;
 #$timeend=time();
#$duration= $timeend-$laststart;
#$laststart=$timeend;
#warn "$line_c processed $duration\n";
#next unless $line_c > 300000;
		chomp;
		s/\t$//;
($inst_code=$key)=~s/\d.*/_count/;
$inst_count{$inst_code}++;

		#$f_contents{$key}=$value;
 		@fields=split(/\t/,$value);
		if( $fields[12] =~/^(1\d\d\.\d+)/){
			$long=$1;
			#print "$long\n";
			#$f_contents{$key}=~s/\t$long/\t-$long/;
			$value=~s/\t$long/\t-$long/;
			#print $f_contents{$key}, "\n";
		}
		if($fields[11] && $fields[12]){
$CDL_GEO{$key}++;
			$long=sprintf("%.2f", $fields[12]);
			$lat=sprintf("%.2f", $fields[11]);
			$h_long{$long}.="$key\t";
			$h_lat{$lat}.="$key\t";
		}
else{
	if($gbif_lat{$key}){
			$long=sprintf("%.2f", $gbif_long{$key});
			$lat=sprintf("%.2f", $gbif_lat{$key});
			$h_long{$long}.="$key\t";
			$h_lat{$lat}.="$key\t";
$fields[11]=$lat;
$fields[12]=$long;
$fields[13]=$gbif_datum{$key};
$fields[14]=$gbif_source{$key};
$fields[16]=$gbif_error{$key};
$fields[17]=$gbif_error{$units};
$CDL_GEO{$key}++;
print LOG  "coordinate data @fields[11,12] added for $key\n";
$value_2=join("\t",@fields);
print LOG <<EOW;
$value
$value_2

EOW
		#$f_contents{$key}=$value_2;
	}
}
	
 		$county=uc($fields[8]);
 		$taxon_id= $fields[0];
#print "$taxon_id: $county\n" if $taxon_id==26890;
#print "key $key $taxon_id: $county\n" if $key eq "UC126402";
#print "key $key $taxon_id: $county\n" if $key eq "RSA470048";
#print "key $key $taxon_id: $county\n" if $key eq "CAS690515";
#print "key $key $taxon_id: $county\n" if $key eq "CDA108128";
		unless($fields[8]=~/[Uu]nknown/i){
			$ALL_CF{$fields[0]}{uc($fields[8])}++;
			if($key=~/^(UC|JEPS)\d/){
				$UCJEPS_CF{$fields[0]}{uc($fields[8])}++;
			}
		}

		foreach($county){
	  		next if m/UNKNOWN/;
#print "$taxon_id: $county\n" if $taxon_id==26890;
	  		$tid_to_county{$taxon_id}.=$fips{$_} unless $store_county{$taxon_id}{$fips{$_}}++;
		}
		$store{$county}{$taxon_id}++;
if($value_2){
		$f_contents{$key}=$value_2;
}
else{
		$f_contents{$key}=$value;
}
	}
close(IN);
 	open(OUT, ">consort_county_list.out") || die;
 	foreach $county (sort(keys(%store))){
 		next if $county=~/UNKNOWN/;
 		next if $county=~/^ *$/;
 		print OUT "\n$county\n";
 		foreach $tid (sort {$a<=>$b}(keys(%TID))){
 			if($store{$county}{$tid}){
 				print OUT "$tid\n";
 			}
 		}
	
	
	}
 	close(OUT);
($t)=gettimeofday;
print "after $dbm_file  $t\n";
}

 tie %TNOAN, "BerkeleyDB::Hash", -Filename => "CDL_TID_TO_NAME" or die "Cannot open file TID_TO_NAME: $! $BerkeleyDB::Error\n" ;
open(OUT,">CF_countylist_exp.txt");
foreach (sort {$TNOAN{$a} cmp $TNOAN{$b}} (keys(%ALL_CF))){
    if($TNOAN{$_}=~/ [a-z]/){
	print OUT "$TNOAN{$_}\t";
        $county_list =join(", ",(sort(keys(%{$ALL_CF{$_}}))));
            print OUT "$county_list\n";
    }
}
close(OUT);

open(OUT,">CF_countylist.txt");
foreach (sort {$TNOAN{$a} cmp $TNOAN{$b}} (keys(%UCJEPS_CF))){
    if($TNOAN{$_}=~/ [a-z]/){
	print OUT "$TNOAN{$_}\t";
        $county_list =join(", ",(sort(keys(%{$UCJEPS_CF{$_}}))));
            print OUT "$county_list\n";
    }
}
close(OUT);
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
