use lib '/Users/rlmoe/data/CDL';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
&load_noauth_name;

$m_to_f="3.2808";
		use Geo::Coordinates::UTM;
open(COORDS,">JOTR_coord_issues") || die;
open(IN,"../CDL/riv_non_vasc") || die;
while(<IN>){
	chomp;
	$exclude{$_}++;
}


open(ERR,">JOTR.err") || die;
open(IN,"../CDL/alter_names") || die;
while(<IN>){
	chomp;
	next unless ($riv,$smasch)=m/(.*)\t(.*)/;
	$alter{$riv}=$smasch;
}
open(OUT, ">JOTR.out") || die;
Record: while(<>){
			$zone=$easting=$northing= $extent=$extent_units=$LatLong_Method="";
	$name=$decimal_lat =$decimal_long="";
	$line=$_;
	chomp;
	@fields= split(/\t/,$_,100);
	print "$. $#fields $_\n" unless $#fields==37;
	#print "$#fields\n";
#next;
	foreach $i (0 .. $#fields){
		$fields[$i]=~s/^[ "]*//;
		$fields[$i]=~s/[ "]*$//;
		#print "$i $fields[$i]\n";
	}
	($AnnotationNotes,	$Assoc_Spec,	$Associated_collectors,	$CCH_current_det,	$CCH_Specimen_ID,	$Collection_no,	$Collection_Date,	$Collector,	$County,	$Datum,	$Description,	$Elev,	$Family,	$Genus,	$Habitat,	$Ident_Date,	$Identified_By,	$Latitude,	$Latitude2,	$Latitude3,	$Locality,	$Longitude,	$Longitude2,	$Longitude3,	$Park,	$Quarter,	$R,	$S,	$Species,	$Specimen_Notes,	$State,	$Subtaxon,	$subtype,	$T,	$Topo_Quad,	$Units,	$UTM_E,	$UTM_N,	$UTM_Zone)=@fields;
	if($T){
		$TRS="$T$R$S";
		if($Quarter){
			$TRS="$TRS $Quarter";
			}
		}
	else{
		$TRS="";
	}

	$decimal_lat=  $Latitude +	$Latitude2/60 +	$Latitude3/3600;
	$decimal_long=	$Longitude +	$Longitude2/60 +	$Longitude/3600;
	$decimal_long="-$decimal_long" if $decimal_long > 0;



	$name="$Genus $Species $subtype $Subtaxon";
	$name=ucfirst(lc($name));
	foreach($name){
		s/"//g;
		s/ +/ /g;
	
		s/`//g;
		s/\?//g;
		s/ *$//;
		s/  +/ /g;
		s/ spp\./ subsp./;
		s/ssp\./subsp./;
		s/ ssp / subsp. /;
		s/ subsp / subsp. /;
		s/ var / var. /;
		s/ var. $//;
		s/ sp\..*//;
		s/ sp .*//;
		s/ [Uu]ndet.*//;
		s/ x / X /;
		s/ × / X /;
		s/ *$//;
	}
#print "TEST $name<\n";

	if($name=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
                 $hybrid_annotation=$name;
                 warn "$1 from $name\n";
                 &log("$1 from $name");
                 $name=$1;
             }
	     else{
                 $hybrid_annotation="";
	     }


	if($exclude{$genus}){
		&log("Excluded, not a vascular plant: $name");
		++$skipped{one};
		next Record;
	}

	%infra=( 'var.','subsp.','subsp.','var.');

	if($alter{$name}){
        	&log("$name altered to $alter{$name}");
                $name=$alter{$name};
	}
#print "N>$name<\n";
	$test_name=&strip_name($name);
#print "TN>$test_name<\n";

	if($TID{$test_name}){
        	$name=$test_name;
	}
	elsif($alter{$test_name}){
        	&log("$name altered to $alter{$test_name}");
                $name=$alter{$test_name};
	}
	elsif($test_name=~s/(var\.|subsp\.)/$infra{$1}/){
        	if($TID{$test_name}){
                	&log("$name not in SMASCH  altered to $test_name");
                	$name=$test_name;
        	}
        	elsif($alter{$test_name}){
                	&log("$name not in smasch  altered to $alter{$test_name}");
                	$name=$alter{$test_name};
        	}
		else{
        		&log ("$name is not yet in the master list: skipped");
			$needed_name{$name}++;
			++$skipped{one};
			next Record;
		}
	}
	else{
        	&log ("$name is not yet in the master list: skipped");
		$needed_name{$name}++;
		++$skipped{one};
		next Record;
	}

	$name{$name}++;


if($CCH_current_det=~m/(^[A-Z][a-z. -]+) +([^\d]+) +(.*)/){
$anno_string="$1; $2; $3";
$anno_string=~s/ *;/;/g;
 #If there is not a date/determiner in the CCH Current Det field, it means that it is assumed to be the collector and coll date
}
else{
$anno_string= "$name; $Collector; $Collection_Date";
}


	if($Collector=~s/ (AND|&|and) (.*)//){
		$Associated_collectors.= $2;
	}
	$Collector=~s/, J[rR].*/ Jr./;
	$Collector=~s/(.+), (.+)/$2 $1/;
	$Collector=~s/([A-Z])([A-Z]+)/$1\L$2/g;
	$Associated_collectors=~ s/([A-Z])([A-Z]+)/$1\L$2/g;
	$Collection_No=~s/^0$//;


	if($UTM_Zone){
		$zone=$UTM_Zone;
		$easting=$UTM_E;
		$northing=$UTM_N;
		$easting=~s/[^0-9]*$//;
		$northing=~s/[^0-9]*$//;
		#warn "$fields[0] $zone $easting $northing\n";
		$zone="11S" if $zone==11;
		$zone="11S" if $zone eq "Z11";
		$zone="11S" if $zone eq "S11";
		$zone="10S" if $zone==10;
		$ellipsoid=23;
		if($zone=~/9|10|11|12/ && $easting=~/^\d\d\d\d\d\d/ && $northing=~/^\d\d\d\d\d/){
			($decimal_lat,$decimal_long)=utm_to_latlon($ellipsoid,$zone,$easting,$northing);
			print COORDS "$Label_ID_no decimal derived from UTM $decimal_lat, $decimal_long\n";
$extent="10";
$extent_units="m";
$LatLong_Method="GPS (converted from UTM)";
		}
		else{
			print COORDS "$Label_ID_no UTM problem $zone $easting $northing\n";
$extent="";
$extent_units="";
$LatLong_Method="";
		}


		$decimal_long="-$decimal_long" if $decimal_long > 0;
	}  
	else{
		if($label_latlong=~/(\d\d)[^ ]* ([0-9.]+)' +(1\d+)[^ ]* ([0-9.]+)'/){
			$decimal_lat=$1 + ($2/60);
			$decimal_long= $3 + ($4/60);

		$decimal_long="-$decimal_long" if $decimal_long > 0;
			#print "$decimal_lat, $decimal_long\n";
		}
	}
	if($decimal_lat){
		if ($decimal_long > 0){
			print ERR "$decimal_long made -$decimal_long $Label_ID_no\n";
		$decimal_long="-$decimal_long";
		}
	if($decimal_lat > 42.1 || $decimal_lat < 32.5 || $decimal_long > -114 || $decimal_long < -124.5){
		if($zone){
			print COORDS "$CCH_Specimen_ID coordinates set to null, Outside California: UTM is $zone $easting $northing --> $decimal_lat $decimal_long\n";
		}
		else{
			print COORDS "$CCH_Specimen_ID coordinates set to null, Outside California: D_lat is $decimal_lat D_long is $decimal_long lat is $lat long is $long\n";
		}
	$decimal_lat =$decimal_long="";
}   
}

$County="Unknown" unless $County;
		foreach($County){
		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)$/){
			$v_county= &verify_co($_);
			if($v_county=~/SKIP/){
				&log("NON-CA county? $_");
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){
				&log("$CCH_Specimen_ID $_ -> $v_county");
				$_=$v_county;
			}


		}
		$county{$_}++;
	}

if($decimal_lat==0 || $decimal_long==0){
	$decimal_lat =$decimal_long="";
}
	$PREFIX= $CNUM= $SUFFIX="";
	foreach($Collection_no){
		if(s| *1/2||){
			$SUFFIX="1/2";
		}
		if(m/^(\d+)(.*)/){
			$PREFIX="";
			$CNUM=$1;
			$SUFFIX=$2;
		}
		elsif(m/(.*[^0-9])(\d+)(.*)/){
			$PREFIX=$1;
			$CNUM=$2;
			$SUFFIX=$3;
		}
		else{
			$PREFIX=$_;
			$CNUM="";
			$SUFFIX="";
		}
	}


if($Description && $Specimen_Notes){
$notes="$Description. $Specimen_Notes";
}
elsif($Description){
$notes="$Description";
}
elsif(Specimen_Notes){
$notes="$Description";
}
else{
$notes="";
}
print OUT <<EOP;
Date: $Collection_Date
CNUM_prefix: $PREFIX
CNUM: $CNUM
CNUM_suffix: $SUFFIX
Name: $name
Accession_id: $CCH_Specimen_ID
Family_Abbreviation: $Family
Country: $country
State: $State
County: $County
Loc_other: $Park
Location: $Locality
T/R/Section: $TRS
USGS_Quadrangle: $Topo_Quad
Elevation: $Elev $Units
Collector: $Collector
Other_coll: $Associated_collectors
Combined_collector: $combined_collectors
Habitat: $Habitat
Associated_species: $Assoc_Spec
Notes: $notes
Decimal_latitude: $decimal_lat
Decimal_longitude: $decimal_long
Datum: $Datum
Lat_long_ref_source: $LatLong_Method
Max_error_distance: $extent
Max_error_units: $extent_units
Annotation: $anno_string
Annotation: $AnnotationNotes
Hybrid_annotation: $hybrid_annotation
Reproductive_biology: $phenology
Type_status: $Type_status

EOP

}
sub log {
print ERR "@_\n";
}
