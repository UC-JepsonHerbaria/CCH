
open(IN, "SDSU_out_new") || die;
while(<IN>){
if(m/Accession_id: (.*)/){
$sdsu_old{$1}++;
}
}

open(IN, "/users/jfp04/data/SDSU/SDSU_out_new") || die;
while(<IN>){
if(m/Accession_id: (.*)/){
$sdsu_new{$1}++;
}
}

foreach $aid(keys(%sdsu_old)){
unless($sdsu_new{$aid}){
print "$aid not in new load\n";
}
}
foreach $aid(keys(%sdsu_new)){
unless($sdsu_old{$aid}){
print "$aid new new load\n";
}
}
