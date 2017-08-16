@datafiles=(
"revised_coords.out",
"CDA_out_new",
"new_CAS",
"SD.out",
"RSA_out_new.tab",
"parse_sbbg_export.out",
"IRVC_new.out",
"parse_davis.out",
"parse_riverside_2009.out",
"PG.out",
"chico.out",
"parse_hsc.out",
"SDSU_out_new",
);
$_;
foreach $datafile (@datafiles){
	open(IN,"$datafile")|| die;
	$/="";
	while(<IN>){
print "$datafile $1\n" if m/Name: (Cylindro.*parkeri)/;
}
}
