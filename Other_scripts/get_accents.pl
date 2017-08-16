use utf8;
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
	open(IN,"$datafile")|| die;
	while(<IN>){
next if m/^[-`@$\[\]{}=*!|><#%~+\/\w\s,.?;:"')(&]*$/;
#@words=split(/ +/);
#foreach(@words){
#next if m/^[-`@$\[\]{}=*!|><#%~+\/\w\s,.?;:"')(&]*$/;
#chomp;
#($accent=$_)=~s/^[-`@$\[\]{}=*!|><#%~+\/\w\s,.?;:"')(&]*//;
#$accent=~s/[-`@$\[\]{}=*!|><#%~+\/\w\s,.?;:"')(&].*//;
#$store_accent{"$accent $_"}++;
#}
print;
s/Yâ/&deg;/g;
s/â/&deg;/g;
s/ââ/"/g;
s/â/"/g;
s/â/"/g;
s/â/"/g;
s/Â°/&deg;/g;
s/Âº/&deg;/g;
s/Ë/&deg;/g;
s/Ã©/&eacute;/g;
s/Ã¨/&egrave;/g;
s/í/&iacute;/g;
s/Ã±/&ntilde;/g;
s/ñ/&ntilde;/g;
s/Ã±Ã³/&ntilde;&oacute;/g;
s/ó/&oacute;/g;
s/Ã¶/&ouml;/g;
s/ö/&ouml;/g;
s/Â±/&plusmn;/g;
s/±/&plusmn;/g;
s/Ã¼/&uuml;/g;
s/ü/&uuml;/g;
s/ââ/'/g;
s/â/'/g;
s/ï¿½/'/g;
s/û/'/g;
s/â/'/g;
s/Ô/'/g;
s/Õ/'/g;
s/Â½/&frac12;/g;
s/½/&frac12;/g;
s/Â¼/&frac14;/g;
s/¼/&frac14;/g;
s/Â¾/&frac34;/g;
s/¾/&frac34;/g;
s//"/g;
s//"/g;
s/Ò/"/g;
s/Ó/"/g;
s///g;
s/Ö/&Ouml;/g;
s/&apos;/'/g;
s//'/g;
s//'/g;
s/º/&deg;/g;
s/¡/&deg;/g;
s//&aacute;/g;
s/°/&deg;/g;
s//&eacute;/g;
s/é/&eacute;/g;
s//&egrave;/g;
print "$_\n";
}
}
foreach(sort(keys(%store_accent))){
print "$_ : $store_accent{$_}\n";
}
