open(IN,"../CDL/tnoan.out") || die;
while(<IN>){
	chomp;
s/\cJ//;
s/\cM//;
	s/^.*\t//;
	$taxon{$_}++;
}
open(IN,"../CDL/alter_names") || die;
while(<IN>){
	chomp;
s/\cJ//;
s/\cM//;
	next unless ($rsa,$smasch)=m/(.*)\t(.*)/;
	$alter{$rsa}=$smasch;
}

open(IN,"rsa_dec_in") || die;
	RECORD: while(<IN>){
#next RECORD  unless m/505269|519112/;

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
#splice(@fields,3,1);
grep(s/^"//,@fields);
grep(s/"$//,@fields);
(
$Primary_key,
$Label_ID_no,
$Family_,
$Genus,
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
$UTM_zone,
$Kind_of_type,
$Type_yes_or_no,
)= @fields;
next RECORD if $seen{"$Primary_key $Label_ID_no"}++;

		$constructed_name="$Genus $Species $Subtype $Subtaxon";
		$constructed_name=~s/ *$//;
		$constructed_name=~s/  */ /g;
		foreach($Full_scientific_name){
$original_name=$_;
			s/^\.//;
			$_=ucfirst(lc($_));
			s/,//g;
			s/`//g;
	#s/ ssp\.? / subsp. /;
	#s/ spp\.? / subsp. /;
	#s/ ssp\.$//;
	s/ subsp / subsp. /;
	s/ var / var. /;
	s/ forma / f. /;
	s/ fo. / f. /;
	s/ undescr\..*/ sp./;
	s/ [iu]ndet\..*/ sp./;
	s/ sp\.//;
	s/  */ /g;
				s/ *$//;
				s/ [xX] / × /;
			$name=$_;
if(s/ (cf\.|aff\.)//){
$note="as $original_name";
}
else{
$note="";
}
		if($constructed_name && $name){
		   ++$both_names;
			if($constructed_name ne $name){
			++$differ;
			if($name =~ /× /){
			++$formula;
			}
			}
		}
		elsif($constructed_name){
		++$constructed_only;
		}
		elsif($name){
		++$name_only;
		}
		else{
		++$no_name;
		}
		}
		}
		print <<EOP;
		All name fields: $both_names
		Differing: $differ
		Formula: $formula
		Only full scientific name: $name_only
		Only other fields: $constructed_only
		No name: $no_name
EOP
