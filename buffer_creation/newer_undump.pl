#originally called undump_CDL.pl in 2005
#!/bin/perl
use BerkeleyDB;
%flat_dbm=(
CDL_date_simple => 'CDL_date_simple.in',
CDL_county => 'CDL_counties.in',
CDL_date_range => 'CDL_date_range.in',
CDL_DBM =>   'CDL_main.in',
CDL_TID_TO_NAME =>   'CDL_tid_to_name.in'
);
system "mv CDL_collectors.in CDL_collectors.txt";
system("chmod 0666 CDL_collectors.txt");
system "mv CDL_loc_list.in CDL_location_words.txt";
system "mv CDL_name_list.in CDL_name_list.txt";

foreach $dbm_file (sort(keys(%flat_dbm))){
$line_c=0;
unlink($dbm_file);
	my $filename = "$flat_dbm{$dbm_file}";
open(IN,"$filename") || die "couldn't open $filename\n";
	warn "opening $filename, writing to $dbm_file\n";
    	tie %f_contents, "BerkeleyDB::Hash",
                -Filename => $dbm_file,
		-Flags => DB_CREATE
        or die "Cannot open file $filename: $! $BerkeleyDB::Error\n" ;

while(<IN>){
++$line_c;
chomp;
s/\t$//;
($key, $value)=m/^([^ ]+) (.*)/;
$key=~s/_/ /g if ($filename=~/counties/);
$f_contents{$key}=$value;
unless($line_c % 25000){warn "$line_c processed\n";}
}
system("chmod 0666 $dbm_file");

untie %f_contents;

}
