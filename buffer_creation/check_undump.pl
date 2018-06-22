use BerkeleyDB;
tie %CDL, "BerkeleyDB::Hash", -Filename=>"CDL_DBM", -Flags=>DB_RDONLY or die "Cannot open file CDL_DBM: $! $BerkeleyDB::Error\n" ;
while(($key,$value)=each(%CDL)){
$AID{$key}++;
if($key=~/POM|RSA/){
++$count;
}
}
print "RSA count $count\n";
die;
tie @h, 'BerkeleyDB::Recno', -Filename => "CDL_AID_recno", -Property => DB_RENUMBER
             or die "Cannot open $filename: $!\n" ;
foreach $i ( 0 .. $#h){
if($AID{$h[$i]}){
if ($seen{$h[$i]}++){
print "$i $seen{$h[$i]} $h[$i]\n";
}
}
}

