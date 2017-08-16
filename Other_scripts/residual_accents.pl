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
print if s/Åna/Ana/;
print if s/.zelk.k/Ozelkuk/;
print "e1\t$_" if s/\xe1/&aacute;/g;
print "ef\t$_" if s/\xef\xbf\xbd/'/g;
#print "'\t$_" if m/’/;
print "†th\t$_" if s/\xe2\x80\xA0/t/;
print "fx 6\t$_" if s/\xf6/&ouml;/;
}

}
__END__
� � : 1
� Ord�&ntilde;ez : 1
� Siss�n : 1
� H�lzer : 1
� St�hr : 4
� �15 : 1
� �6 : 1
� 114� : 1
� 34� : 1
� � : 4
± 10± : 4
½ ½ : 1
Å Åna : 1
è Laferrière : 2
� (�8 : 1
� �anyon : 1
� �zelk�k : 2
� � : 1
� �" : 1
’ 13,351’) : 1
† sou†h : 1
� 118�&frac34;1/4 : 1
� 119�&frac34;1/4 : 1
� 34�&frac34;1/4 : 1
� N20�&frac34;1/4 : 1
� N5�&frac34;1/4E : 1
� S45�&frac34;1/4E : 1
� �&frac34;&plusmn;S : 1
� �&frac34;�evada; : 1
� �1/4� : 1
� S�zer : 2
