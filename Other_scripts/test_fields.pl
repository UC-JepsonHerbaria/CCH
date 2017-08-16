@datafiles=(
"CDA_out",
"new_CAS",
"SD.out",
"RSA_out_new.tab",
"parse_sbbg_export.out",
"IRVC_new.out",
"parse_davis.out",
"PG.out",
"parse_riverside_2012.out",
"parse_chico.out",
"parse_hsc.out",
"SDSU_out_new",
"SJSU_from_smasch",
"nybg.out",
"parse_csusb.out",
"new_HUH",
"YOSE_data.tab",
"sagehen.txt"
);


foreach $datafile (@datafiles){
next if $datafile=~/#/;
	#%seen_dups=();
	#system "uncompress ${datafile}.Z";
	print $datafile, "\n";
	open(IN,"$datafile")|| die;
	while(<IN>){
	#next unless m/564576/;
	next if m/^#/;
if(m/^([^:]+): ./){
print "$datafile $1\n" unless $fields{"$datafile $1"}++;
}
}
}
