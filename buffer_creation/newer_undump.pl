#originally called undump_cdl.pl in 2008
#!/bin/perl
 $timestart=time();
use BerkeleyDB;
#system "gunzip cdl_tar.gz";
system "tar -xvf cdl_tar";
%flat_dbm=(
CDL_date_simple => 'CDL_date_simple.in',
CDL_county => 'CDL_counties.in',
CDL_date_range => 'CDL_date_range.in',
CDL_TID_TO_NAME =>   'CDL_tid_to_name.in',
CDL_coll_number =>   'CDL_coll_number.in',
);
system "mv CDL_collectors.in CDL_collectors.txt";
system("chmod 0666 CDL_collectors.txt");
system "mv CDL_loc_list.in CDL_location_words.txt";
system "mv CDL_name_list.in CDL_name_list.txt";

foreach $dbm_file (keys(%flat_dbm)){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
#foreach $filename ($filename, "cdl/$filename"){
	open(IN,"$filename") || die "couldn't open $filename\n";
	warn "opening $filename, writing to $dbm_file\n";
    	tie %f_contents, "BerkeleyDB::Hash",
                -Filename => $dbm_file,
		-Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

while(<IN>){
	++$line_c;
	unless($line_c % 25000){warn "$line_c processed\n";}
	chomp;
	s/\t$//;
	($key, $value)=m/^([^ ]+) (.*)/;
	$key=~s/_/ /g if ($filename=~/counties/);
	#next;
	$f_contents{$key}=$value;
}
system("chmod 0666 $dbm_file");

untie %f_contents;

#}
}
%flat_dbm=(
CDL_DBM =>   'CDL_main.in',
);
	unlink("CDL_TID_TO_CO");
        unlink("CDL_lat");
        unlink("CDL_long");
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
#foreach $filename ($filename, "cdl/$filename"){
	open(IN,"$filename") || die "couldn't open $filename\n";
	warn "opening $filename, writing to $dbm_file\n";
    	tie %f_contents, "BerkeleyDB::Hash",
                -Filename => $dbm_file,
		-Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

	%fips_to_county=&load_fips();
	%fips=reverse(%fips_to_county);
	tie %tid_to_county, "BerkeleyDB::Hash", -Filename => "CDL_TID_TO_CO", -Flags => DB_CREATE or die "Cannot open file CDL_TID_TO_CO: $! $BerkeleyDB::Error\n" ;
        my %h_long ;
        my %h_lat;
	while(<IN>){
		++$line_c;
		++$record_count;
		unless($line_c % 25000){
 $timeend=time();
$duration= $timeend-$laststart;
$laststart=$timeend;
warn "$line_c processed $duration\n";
}
		chomp;
		s/\t$//;
		($key, $value)=m/^([^ ]+) (.*)/;
($inst_code=$key)=~s/\d.*/_count/;
$inst_count{$inst_code}++;

		$f_contents{$key}=$value;
 		@fields=split(/\t/,$value);
		if( $fields[12] =~/^(1\d\d\.\d+)/){
			$long=$1;
			print "$long\n";
			$f_contents{$key}=~s/\t$long/\t-$long/;
			print $f_contents{$key}, "\n";
		}
		if($fields[11] && $fields[12]){
			$long=sprintf("%.2f", $fields[12]);
			$lat=sprintf("%.2f", $fields[11]);
			$h_long{$long}.="$key\t";
			$h_lat{$lat}.="$key\t";
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
	}
#}
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
	system("chmod 0666 $dbm_file");
}
untie %f_contents;

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


%flat_dbm=(
'CDL_notes' => 'CDL_notes.in'
);

foreach $dbm_file (sort(keys(%flat_dbm))){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
#foreach $filename ($filename, "cdl/$filename"){
	open(IN,"$filename") || die "couldn't open $filename\n";
	warn "opening $filename, writing to $dbm_file\n";
    	tie %f_contents, "BerkeleyDB::Hash",
                -Filename => $dbm_file,
		-Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

	while(<IN>){
		++$line_c;
		chomp;
		($key, $value)=split(/\t/);
		$f_contents{$key}=$value;
		unless($line_c % 25000){warn "$line_c processed\n";}
	}
	system("chmod 0666 $dbm_file");

	untie %f_contents;


#}
}
%flat_dbm=(
'CDL_annohist' => 'CDL_annohist.in'
);

foreach $dbm_file (sort(keys(%flat_dbm))){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
#foreach $filename ($filename, "cdl/$filename"){
	open(IN,"$filename") || die "couldn't open $filename\n";
	warn "opening $filename, writing to $dbm_file\n";
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
		unless($line_c % 25000){warn "$line_c processed\n";}
	}
	system("chmod 0666 $dbm_file");

	untie %f_contents;

#}
}
%flat_dbm=(
'CDL_voucher' => 'CDL_voucher.in'
);

foreach $dbm_file (sort(keys(%flat_dbm))){
	$line_c=0;
	unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
#foreach $filename ($filename, "cdl/$filename"){
	open(IN,"$filename") || die "couldn't open $filename\n";
		warn "opening $filename, writing to $dbm_file\n";
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
		unless($line_c % 25000){warn "$key : $value\n";}
	}
	system("chmod 0666 $dbm_file");
	
	untie %f_contents;

#}
}
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
unless($inst=~/^CDA|CAS|DS|UC|JEPS|UCSC|UCSB|SBBG|POM|RSA|UCR|DAV|PGM|CHSC|SJSU|IRVC|SD|HSC$/){
warn "$inst\n";
next;
}
print OUT "$inst: $bar_length{$county}{$inst}\t";
}
print OUT "\n";
}

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
print "$key $value\n";
next;
}
print "$startyear $endyear\n";
@ids=split(/\t/,$value);
foreach $an ($startyear .. $endyear){
if($an > 1799){
grep($seen{$an} .= "$_\t",@ids);
}
}
}
}

foreach $year (sort(keys(%seen))){
if ($year < 2008){
%ids=();
@array=split(/\t/, $seen{$year});
grep($ids{$_}++, @array);
$h[$year]=join("\t", keys(%ids));
}
}
untie(%hash);
           untie(@h);
 untie %CDL;
        untie %h_long;
        untie %h_lat;
	untie %tid_to_county;
open(OUT, ">>record_tally");
 $timeend=time();
$duration= $timeend - $timestart;
print OUT "$timestart Records: $record_count ($duration)\n";
close(OUT);

#system ("tar -c -f consort_tar  CDL_* CF_*");
#system ("gzip consort_tar");
#system ("rm CDL_*");
system ("cat record_tally");
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

$news="$news.html";
#$news=get("http://ucjeps.berkeley.edu/consortium/news.html"):
$inst_count{DAV_count}=$inst_count{UCD_count};
$inst_count{UC_count} += $inst_count{JEPS_count};
$inst_count{UC_count} += $inst_count{UCLA_count};
$inst_count{RSA_count} += $inst_count{POM_count};
$inst_count{CAS_count} +=$inst_count{DS_count};
open(OUT, ">CDL_news.html");
$record_table=<<EOT;
<table class="bodyTest"> <tr><td> CAS-DS</td><td>$inst_count{CAS_count}</td></tr> <tr><td> CDA</td><td>$inst_count{CDA_count}</td></tr> <tr><td> CHSC</td><td>$inst_count{CHSC_count}</td></tr> <tr><td> DAV</td><td>$inst_count{DAV_count}</td></tr> <tr><td> HSC</td><td>$inst_count{HSC_count}</td></tr> <tr><td> IRVC</td><td>$inst_count{IRVC_count}</td></tr> <tr><td> PGM</td><td>$inst_count{PGM_count}</td></tr> <tr><td> RSA-POM</td><td>$inst_count{RSA_count}</td></tr> <tr><td> SBBG</td><td>$inst_count{SBBG_count}</td></tr> <tr><td> SD</td><td>$inst_count{SD_count}</td></tr> <tr><td> SJSU</td><td>$inst_count{SJSU_count}</td></tr> <tr><td> UC-JEPS</td><td>$inst_count{UC_count}</td></tr> <tr><td> UCR</td><td>$inst_count{UCR_count}</td></tr> <tr><td> UCSB</td><td>$inst_count{UCSB_count}</td></tr> <tr><td> UCSC</td><td>$inst_count{UCSC_count}</td></tr> </table>
EOT
$today=localtime();
$today=~s/\d\d:\d\d:\d\d//;
foreach($news){
s!Record count: .*</span><br />!Record count: $record_count ($today)</span><br />!;
s/<table class=.*/$record_table/o;
}
print OUT $news;
foreach (sort(keys(%inst_count))){
#print OUT "$_: $inst_count{$_}\n";
}
