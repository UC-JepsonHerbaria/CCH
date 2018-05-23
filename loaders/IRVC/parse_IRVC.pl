print join("\t", "IRVC",
"GENUS",
"SPECIES",
"AUTHOR",
"INFRARANK",
"INFRA",
"INFRAAUTHOR",
"PR",
"ELEVATION",
"ELEVUNITS",
"VEGETATION",
"COLLECTOR",
"ASSOCCOLLECTOR",
"COLLECTORNUMBER",
"DAY",
"MONTH",
"YEAR",
"UTMZONE",
"UTME",
"UTMN",
"LAT_DEG",
"LAT_MIN",
"LAT_SEC",
"LAT_DIR",
"LONG_DEG",
"LONG_MIN",
"LONG_SEC",
"LONG_DIR",
"LOCALITY",
"NOTES"),"\n";

while(<>){
chomp;
@fields=split(/\t/);
#$fields[$#fields]=~s/"$//;
foreach $i (0 .. $#fields){
$fields[$i]=~s/^"//;
$fields[$i]=~s/"$//;
$fields[$i]=~s/""/"/g;
$fields[$i]=~s/ +$//;
$fields[$i]=~s/^ +//;

$seen_field[$i]{$fields[$i]}++;
}
$g=$s=$sa=$v=$in=$ina="";
($g,$s,$sa,$v,$in,$ina)=&parse_name($fields[1]);
($elev, $eu)=&parse_elev($fields[3]);
$fields[4]=~s/[:;.,]*$//;
($day, $month, $year)= &parse_date($fields[8]);
foreach($fields[10], $fields[11]){
s/ //g;
s/[eEMmnN]*$//;
}
($lat_deg,$lat_min,$lat_sec,$lat_dir)=&parse_lat($fields[12]);
($long_deg,$long_min,$long_sec,$long_dir)=&parse_long($fields[13]);
print join("\t",
$fields[0],
$g,
$s,
$sa,
$v,
$in,
$ina,
$fields[2],
$elev,
$eu,
$fields[4],
$fields[5],
$fields[6],
$fields[7],
$day,
$month,
$year,
$fields[9],
$fields[10],
$fields[11],
$lat_deg,
$lat_min,
$lat_sec,
$lat_dir,
$long_deg,
$long_min,
$long_sec,
$long_dir,
$fields[14],
$fields[15]), "\n";
#print <<EOP;
#IRVC: $fields[0]
#GENUS: $g
#SPECIES: $s
#AUTHOR: $sa
#INFRARANK: $v
#INFRA: $in
#INFRAAUTHOR: $ina
#PR: $fields[2]
#ELEVATION: $elev
#ELEVUNITS: $eu
#VEGETATION: $fields[4]
#COLLECTOR: $fields[5]
#ASSOCCOLLECTOR: $fields[6]
#COLLECTORNUMBER: $fields[7]
#DAY: $day
#MONTH: $month
#YEAR: $year
#UTMZONE: $fields[9]
#UTME: $fields[10]
#UTMN: $fields[11]
#LAT_DEG: $lat_deg
#LAT_MIN: $lat_min
#LAT_SEC: $lat_sec
#LAT_DIR: $lat_dir
#LONG_DEG: $long_deg
#LONG_MIN: $long_min
#LONG_SEC: $long_sec
#LONG_DIR: $long_dir
#LOCALITY: $fields[14]
#NOTES: $fields[15]
#
#EOP
}
foreach $i (0 .. $#fields){
#print "\n\n==============>$i\n";
	foreach $key (sort(keys(%{$seen_field[$i]}))){
		#print "$key\n";
	}
}
sub parse_name {
$g=$s=$sa=$v=$in=$ina="";
local($_)=@_;
	s/^ *//;
	if(m/^([A-Z][a-z]+) +(X?[-a-z]+)(.*)(ssp\.|var\.|f\.|subsp.) +([-a-z]+)(.*)/){
$g=$1;
$s=$2;
$sa=$3;
$v=$4;
$in=$5;
$ina=$6;
$sa=~s/ *$//;
$sa=~s/^ *//;
$ina=~s/ *$//;
$ina=~s/^ *//;
}
elsif(m/^([A-Z][a-z]+) +(X?[-a-z]+)(.*)/){
$g=$1;
$s=$2;
$sa=$3;
$sa=~s/ *$//;
$sa=~s/^ *//;
$ina=~s/ *$//;
$ina=~s/^ *//;
}
else{
	return ($_);
}
return($g,$s,$sa,$v,$in,$ina);
}

sub parse_elev {
local($_)=@_;
if(m/^(-?\d+) *([a-zA-Z.]+)/){
return($1,$2);
}
else{
return $_;
}
}
sub parse_date {
local($_)=@_;
if(m|(\d+)/(\d+)/(\d+)|){
return($2,$1,$3);
}
if(m|(\d+)/(\d+)|){
return("",$1,$2);
}
else{
return $_;
}
}
sub parse_lat {
local($_)=@_;
if(m/(\d+)[^0-9]+(\d+)[^0-9]+([0-9.]+)[^0-9]*([nN])/){
return($1,$2,$3,$4);
}
elsif(m/(\d+)[^0-9]+([0-9.]+)[^0-9]*([nN])/){
return($1,$2,"",$3);
}
else{
return $_;
}
}
sub parse_long {
local($_)=@_;
if(m/(\d+)[^0-9]+(\d+)[^0-9]+([0-9.]+)[^0-9]*([wW])/){
return($1,$2,$3,$4);
}
elsif(m/(\d+)[^0-9]+([0-9.]+)[^0-9]*([wW])/){
return($1,$2,"",$3);
}
else{
return $_;
}
}
