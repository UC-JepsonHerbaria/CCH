
open(IN,"SDSU_out_new") || die;
$/="";
while(<IN>){
	if(m/Accession_id: +(.*)/){
		$store{$1}=$_;
	}
}
$/="\n";
open(IN,"CDL_main.in") || die;
while(<IN>){
	if(m/^SDSU/){
		$line=$_;
		chomp;
		s/ .*//;
		unless($store{$_}){
			print "\\\n>$_<\nTHIS ISNT POSSIBLE: $line not in SDSU file\n";
		}
		$store{$_}="";
	}
}
foreach(keys(%store)){
print ">$_<: \n$store{$_}\n" unless $store{$_} eq "";
}
