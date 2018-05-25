#Load names of non-vascular genera to be excluded
open(IN, "/Users/richardmoe/4_cdl_buffer/smasch/mosses") || die;
open(OUT, ">UCSB.out") || die;
while(<IN>){
	chomp;
	s/ .*//;
	$exclude{$_}++;
}
close(IN);
use Time::JulianDay;
open(ERR, ">UCSB_ERROR.txt") || die;
&load_noauth_name; #FROM CCH.pm
use lib '/Users/richardmoe/4_data/CDL';
use CCH;

Record: while(<>){
	chomp;
	@fields=split(/\t/, $_, 100);
	grep(s/^"//,@fields);
	grep(s/"$//,@fields);
	unless($#fields==19){
		die   "$_\n Fields should be 19; I count $#fields\n";
	}
#"Cataloged Date"	"Catalog Number"	"Collector Number"	"Start Date"	"End Date"	"Verbatim Date"	"County"	"Locality Name"	"Associate Species/Habitat"	"Verbatim Elevation (m)"	"Latitude1"	"Longitude1"	"Coordinates Source"	"Annotation"	"Family"	"Genus"	"Species"	"subspecies"	"variety"	"Collectors [Aggregated]"
($Cataloged_Date, $Catalog_Number, $CollectorNumber, $Start_Date, $End_Date, $Verbatim_Date, $County, $Locality_Name, $Locality_and_Habitat_Notes, $Elevation, $Latitude1, $Longitude1, $Determination_Remarks, $Annotation, $Family, $Genus, $Species, $subspecies, $variety, $Collectors)=@fields;
#print <<EOP;
#Determination_Remarks $Determination_Remarks
#Annotation $Annotation
#
#EOP
#next;
	$SpecimenNumber="UCSB$Catalog_Number";
	if($Start_Date && ($Start_Date eq $End_Date)){
		$date=$Start_Date;
	}
	elsif($Start_Date && $End_Date){
		$date="$Start_Date - $End_Date";
	}
	elsif($Start_Date){
		$date="$Start_Date";
	}
	elsif($End_Date){
		$date="$Start_Date";
	}
	elsif($Verbatim_Date){
		$date="$Verbatim_Date";
	}
	else{
		print ("$Catalog_Number: Unexpected date $Start_Date, $End_Date, $Verbatim_Date\n");
		$date="";
	}
	$name="$Genus $Species";
	if($subspecies){
		$name .= " subsp. $subspecies";
	}
	elsif($variety){
		$name .= " var. $variety";
	}
	$name=~s/  */ /g;
print "$name\n";



		if($name=~/^\s+$/){
			&log("Skipped $SpecimenNumber No name\n");
			next;
		}
		$CoordinateUncertainty="" if $CoordinateUncertainty==0;
		$name=&strip_name($name);

		if($name=~s/([A-Z][a-z-]+ [a-z-]+) [Xx×] /$1 X /){
                 	$hybrid_annotation=$name;
                 	warn "$1 from $name\n";
                 	&log("$1 from $name");
                 	$name=$1;
        	}
        	else{
           	$hybrid_annotation="";
        	}

		($genus=$name)=~s/\s.*//;

		if($exclude{$Genus}){
        		&log("Excluded, not a vascular plant: $name");
        		++$skipped{one};
        		next Record;
		}

		%infra=( 'var.','subsp.','subsp.','var.');

#print "N>$name<\n";
		$test_name=&strip_name($name);
#print "TN>$test_name<\n";

		if($TID{$test_name}){
        		$name=$test_name;
		}
		elsif($alter{$test_name}){
        		&log("$SpecimenNumber $name altered to $alter{$test_name}");
                	$name=$alter{$test_name};
		}
		elsif($test_name=~s/(var\.|subsp\.)/$infra{$1}/){
        		if($TID{$test_name}){
                		&log("$SpecimenNumber $name not in SMASCH  altered to $test_name");
                		$name=$test_name;
        		}
        		elsif($alter{$test_name}){
                		&log("$SpecimenNumber $name not in smasch  altered to $alter{$test_name}");
                		$name=$alter{$test_name};
        		}
        		else{
                		&log ("$SpecimenNumber $name ($Genus $Species) is not yet in the master list: $name skipped");
                		++$skipped{one};
                		next Record;
        		}
		}
		else{
        			&log ("$SpecimenNumber $name ($Genus $Species) is not yet in the master list: $name skipped");
        			#print "$Determination is not yet in the master list: $name skipped";
        			++$skipped{one};
        			next Record;
		}


foreach($Elevation){
s/\.\d+//;

#print "$_\t";
s/ elev.*//;
s/ <([^>]+)>/ $1/;
s/^\+//;
s/^\~/ca. /;
s/zero/0/;
s/,//g;
s/(Ft|ft|FT|feet|Feet)/ ft/;
s/(m|M|meters?|Meters?)/ m/;
s/\.$//;
s/  +/ /g;
s/ *$//;
#print "$_\n";
}
$Elevation .=" m" if $Elevation;
#next;
		if($CollectorNumber){
			($prefix, $CNUM,$suffix)=&parse_CNUM($CollectorNumber);
			#print "1 $prefix\t2 $CNUM\t3 $suffix\n";
		}
		else{
			$prefix= $CNUM=$suffix="";
		}
 		foreach($County){
			s/^$/Unknown/;
                	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown)$/){
                        	$v_county= &verify_co($_);
                        	if($v_county=~/SKIP/){
                                	&log("SKIPPED NON-CA county? $_\n");
                                	next Record;
                        	}   
	
                        	unless($v_county eq $_){
                                	&log("$SpecimenNumber $_ -> $v_county\n");
                                	$_=$v_county;
                        	}   
                	}   
        	}   

		if($hybrid{$SpecimenNumber}){
			($name=$hybrid{$SpecimenNumber})=~s/ .*//;
			$hybrid_anno= "$hybrid{$SpecimenNumber}   hybrid parentage";
		}
		else{
			$hybrid_anno= "";
		}
		if($Longitude1=~/^1\d\d/){
			print "$SpecimenNumber $Longitude1\n";
			$Longitude1=~s/^/-/;
			&log("$SpecimenNumber: minus added to longitude");
		}
	
		$note{$SpecimenNumber}=~s/^[ .]*$//;


	#($Cataloged_Date, $Catalog_Number, $CollectorNumber, $Start_Date, $End_Date, $Verbatim_Date, $County, $Locality_Name, $Locality_and_Habitat_Notes, $Elevation, $Latitude1, $Longitude1, $Determination_Remarks, $Family, $Genus, $Species, $subspecies, $variety, $Collectors)=@fields;
	$collector="";
	$combined_colls="";
	foreach($Collectors){
		s/  ,/,/g;
		@colls=split(/; */,$_);
		foreach(@colls){
			s/(.*), *(.*)/$2 $1/;
		}
	}
	$collector=$colls[0];
	$combined_colls=join(", ",@colls);
		print OUT <<EOP;
Accession_id: $SpecimenNumber
Name: $name
Collector: $collector
Date: $date
CNUM: $CNUM
CNUM_prefix: $prefix
CNUM_suffix: $suffix
Country: USA
State: CA
County: $County
Location: $Locality_Name
Elevation: $Elevation
Other_coll: 
Combined_coll: $combined_colls
Decimal_latitude: $Latitude1
Decimal_longitude: $Longitude1
Lat_long_ref_source: $CoordinateSource
Datum: $Datum
Max_error_distance: $CoordinateUncertainty
Max_error_units: $CoordinateUncertaintyUnit
Hybrid_annotation: $hybrid_anno
Habitat: $Locality_and_Habitat_Notes
Annotation: $Annotation

EOP



}





sub parse_CNUM{
			local($_)=shift;
			if(m/^\s+$/){
				return("","","");
	}
 	s/ *$//;
        s/^ *//;
        if(m/^([^0-9]*)([0-9]+)([^0-9]*)$/){
return("$1",$2,$3);
        }
        elsif(m/^(\d\d+)-(\d+)$/){
return("$1-",$2,"");
        }
        elsif(m/(.*[12]\d\d\d[^0-9])(\d+)([^0-9]*)/){
return("$1",$2,$3);
        }
        elsif(m/(.*[-\/ ])(\d+)([^0-9].*)/){
return("$1",$2,$3);
        }
        elsif(m/([A-Z]+)(\d+)$/){
return("$1",$2,"");
        }
        elsif(m/([A-Z]+)(\d+)([^0-9].*)/){
return("$1",$2,$3);
        }
else{
	return ("$_","","");
}
}

sub log {
	print ERR "@_\n";
}

__END__
JEPS59501	Mimulus moschatus Douglas ex Lindl.	Ezra Brainerd and Viola B. Baird	256	Jul 17 1915	1915-07-17 04:00:00		1 mi above Bear Rock (cliffs e of river); Sierra Nevada Mts., Truckee River	Placer	6700 ft									0	
