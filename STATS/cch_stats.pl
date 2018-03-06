
open(IN, "cch_query_log") || die;
@QL=(<IN>);
close(IN);
foreach (@QL){
#print;
	if(($time)=m/^(\d\d\d\d\d\d\d\d\d\d)/){
		unless($st++){
			$start_time=scalar(localtime($time));
		}
	}
	else{
		if(m/^([A-Z]+)/){
			$store{$1}++;
		}
	}
}
print "<h2>Since $start_time</h2>";
print "<h3>Records returned in general searches</h3>\n<hr><UL>";
foreach(sort(keys(%store))){
print "<LI>$_: $store{$_}\n";
}
print "</UL>";
