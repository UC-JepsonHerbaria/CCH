#!/bin/perl
use BerkeleyDB;
 #tie %CDL, "BerkeleyDB::Hash", -Filename => "CDL_DBM" or die "Cannot open file CDL_DBM: $! $BerkeleyDB::Error\n" ;
#%fips_to_county=&load_fips();
#%fips=reverse(%fips_to_county);
tie %tid_to_county, "BerkeleyDB::Hash", -Filename => "CDL_TID_TO_CO", -Flags => DB_CREATE or die "Cannot open file CDL_TID_TO_CO: $! $BerkeleyDB::Error\n" ;
print <<EOP;
43930: $tid_to_county{43930}
43877: $tid_to_county{43877}
EOP
#%tid_to_county=();
 while(($key,$value)=each(%tid_to_county)){
 print "$key\n";
 }
__END__

 while(($key,$value)=each(%CDL)){
 	@fields=split(/\t/,$value);

 	$county=uc($fields[8]);
 	$taxon_id= $fields[0];
	if($taxon_id==43930){
	print "$taxon_id: $county\n";
	}
	foreach($county){
	  	next if m/unknown|UNKNOWN/;
	  	$tid_to_county{$taxon_id}.=$fips{$_} unless $store_county{$taxon_id}{$fips{$_}}++;
	}
	$store{$county}{$taxon_id}++;

}
print <<EOP;
43930: $tid_to_county{43930}
43877: $tid_to_county{43877}
EOP


				  sub load_fips{
				  return (
				  "06001","ALAMEDA",
				  "06003","ALPINE",
				  "06005","AMADOR",
				  "06007","BUTTE",
				  "06009","CALAVERAS",
				  "06011","COLUSA",
				  "06013","CONTRA COSTA",
				  "06015","DEL NORTE",
				  "06017","EL DORADO",
				  "06019","FRESNO",
				  "06021","GLENN",
				  "06023","HUMBOLDT",
				  "06025","IMPERIAL",
				  "06027","INYO",
				  "06029","KERN",
				  "06031","KINGS",
				  "06033","LAKE",
				  "06035","LASSEN",
				  "06037","LOS ANGELES",
				  "06039","MADERA",
				  "06041","MARIN",
				  "06043","MARIPOSA",
				  "06045","MENDOCINO",
				  "06047","MERCED",
				  "06049","MODOC",
				  "06051","MONO",
				  "06053","MONTEREY",
				  "06055","NAPA",
				  "06057","NEVADA",
				  "06059","ORANGE",
				  "06061","PLACER",
				  "06063","PLUMAS",
				  "06065","RIVERSIDE",
				  "06067","SACRAMENTO",
				  "06069","SAN BENITO",
				  "06071","SAN BERNARDINO",
				  "06073","SAN DIEGO",
				  "06075","SAN FRANCISCO",
				  "06077","SAN JOAQUIN",
				  "06079","SAN LUIS OBISPO",
				  "06081","SAN MATEO",
				  "06083","SANTA BARBARA",
				  "06085","SANTA CLARA",
				  "06087","SANTA CRUZ",
				  "06089","SHASTA",
				  "06091","SIERRA",
				  "06093","SISKIYOU",
				  "06095","SOLANO",
				  "06097","SONOMA",
				  "06099","STANISLAUS",
				  "06101","SUTTER",
				  "06103","TEHAMA",
				  "06105","TRINITY",
				  "06107","TULARE",
				  "06109","TUOLUMNE",
				  "06111","VENTURA",
				  "06113","YOLO",
				  "06115","YUBA"
				  );
				  }


