open(IN,"rsa.in") || die;
#open(IN,"UCJepsExtract.tab") || die;
#open(IN,"all_new_rsa") || die;
#open(IN,"modified records.txt") || die;
#open(IN,"new_reordered") || die;

	RECORD: while(<IN>){
next RECORD  unless m/ [xX] /;

	chomp;
	s/\cK/ /g;
s/\cM//g;
$name=$Country=$Township=$Range=$section= $month=$day=$year= ${Coll_no_prefix}= ${Coll_no}= ${Coll_no_suffix}= $Full_scientific_name= $Label_ID_no= $family= $Country= $State= $County= $Physiographic_region= $Locality= $Unified_TRS= $topo_quad= $elevation= $Collector_full_name= $Associated_collectors= $Ecological_setting= $assoc= $Plant_specifics= $lat= $long= $decimal_lat= $decimal_long=$lon_degrees=$long_minutes=$long_seconds=$lat_degrees=$lat_minutes=$lat_seconds=$color=$combined_collectors="";
	$line=$_;
	s/, *, /, /g;
	s/^"//;
	s/"$//;
	#s/\t/ /g;
	s/  / /g;
s/Õ/'/g;
#@fields=split(/","/);
@fields=split(/\t/);
#gets rid of genus
splice(@fields,3,1);
grep(s/^"//,@fields);
grep(s/"$//,@fields);




(
$Primary_key,
$Label_ID_no,
$Family_,
$Species,
$Subtype,
$Subtaxon,
$Full_scientific_name,
$Collector_last_name,
$Collector_full_name,
$Collector_number,
$Associated_collectors,
$day,
$month,
$year,
$Country,
$State,
$County,
$Physiographic_region,
$Locality,
$Elevation_lower_range_ft,
$Elevation_top_range_ft,
$Elevation_lower_range_meters,
$Elevation_top_range_meters,
$lat_degrees,
$lat_minutes,
$lat_seconds,
$N_or_S,
$long_degrees,
$long_minutes,
$long_seconds,
$E_or_W,
$Township,
$Range,
$Section,
$Quarter,
$UTM_E,
$UTM_N,
$Ecological_setting,
$Plant_specifics,
$Kind_of_type,
$Type_yes_or_no,
)= @fields;
#$UTM_zone, left out
		foreach($Full_scientific_name){
$original_name=$name;
			s/^\.//;
			#$_=ucfirst(lc($_));
			s/,//g;
			s/`//g;
	s/ ssp\.? / subsp. /g;
	s/ spp\.? / subsp. /g;
	s/ ssp\.$//;
	s/ subsp / subsp. /g;
	s/ var / var. /g;
	s/ forma / f. /g;
	s/ fo. / f. /g;
	s/ undescr\..*/ sp./;
	s/ [iu]ndet\..*/ sp./;
	s/ sp\.//;
	s/  */ /g;
				s/ [xX] / × /;
			$name=$_;
if(s/ (cf\.|aff\.)//){
$note="as $original_name";
}
else{
$note="";
}
print "$name\n" if $name=~/×/;
}
}
