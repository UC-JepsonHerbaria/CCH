@datafiles=(
"CDA_out",
"new_CAS",
"SD.out",
"rsa_missing_records",
"rsa_out_new.tab",
"IRVC_new.out",
"UCD.out",
"UCR.out",
"PG.out",
"chico.out",
"SBBG_2008.tab",
"parse_hsc.out",
"SDSU_out_new",
);
foreach $datafile (@datafiles){
print "$datafile\n";
open(IN, $datafile) || die;
while(<IN>){
print if s/River\x85on/River --- on/;
print if s/V\x87cr\x87t\x97t/V&aacute;cr&aacute;t&oacute;t/;
print "^P\t$_" if s/\cP//g;;
#print "9a\t$_" if m/\x9a/;
#print "b1\t$_" if m/\xb1/;
print "ba\t$_" if s/(\d)\xba/$1$deg;/g;
print if s/Ã…na/Ana/;
print if s/.zelk.k/Ozelkuk/;
print "e1\t$_" if s/\xe1/&aacute;/g;
print "ef\t$_" if s/\xef\xbf\xbd/'/g;
#print "'\t$_" if m/â€™/;
print "â€ th\t$_" if s/\xe2\x80\xA0/t/;
print "fx 6\t$_" if s/\xf6/&ouml;/;
}

}
__END__
‘ ‘ : 1
— Ord—&ntilde;ez : 1
— Siss—n : 1
š Hšlzer : 1
š Stšhr : 4
± ±15 : 1
± ±6 : 1
º 114º : 1
º 34º : 1
½ ½ : 4
Â± 10Â± : 4
Â½ Â½ : 1
Ã… Ã…na : 1
Ã¨ LaferriÃ¨re : 2
Å (Å8 : 1
Ç Çanyon : 1
Ö Özelkük : 2
á á : 1
â€ â€" : 1
â€™ 13,351â€™) : 1
â€  souâ€ h : 1
ï 118ï&frac34;1/4 : 1
ï 119ï&frac34;1/4 : 1
ï 34ï&frac34;1/4 : 1
ï N20ï&frac34;1/4 : 1
ï N5ï&frac34;1/4E : 1
ï S45ï&frac34;1/4E : 1
ï ï&frac34;&plusmn;S : 1
ï ï&frac34;„evada; : 1
ï ï1/4‚ : 1
ö Sözer : 2
