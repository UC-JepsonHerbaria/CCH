use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/richardmoe/4_data/CDL';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
$today_JD=julian_day($today_y, $today_m, $today_d);

&load_noauth_name;

open(ERR,">SEINET_error") || die;;
open(OUT,">SEINET.out") || die;;


%monthno=( '1'=>1, '01'=>1, 'jan'=>1, 'Jan'=>1, 'January'=>1, '2'=>2, '02'=>2, 'feb'=>2, 'Feb'=>2, 'February'=>2, '3'=>3, '03'=>3, 'mar'=>3, 'Mar'=>3, 'March'=>3, '4'=>4, '04'=>4, 'apr'=>4, 'Apr'=>4, 'April'=>4, '5'=>5, '05'=>5, 'may'=>5, 'May'=>5, '6'=>6, '06'=>6, 'jun'=>6, 'Jun'=>6, 'June'=>6, '7'=>7, '07'=>7, 'jul'=>7, 'Jul'=>7, 'July'=>7, '8'=>8, '08'=>8, 'aug'=>8, 'Aug'=>8, 'August'=>8, '9'=>9, '09'=>9, 'sep'=>9, 'Sep'=>9, 'Sept'=>9, 'September'=>9, '10'=>10, 'oct'=>10, 'Oct'=>10, 'October'=>10, '11'=>11, 'nov'=>11, 'Nov'=>11, 'November'=>11, '12'=>12, 'dec'=>12, 'Dec'=>12, 'December'=>12);
######################################



#GET IMAGE URL
open(IN,"images.csv") || die;
while(<IN>){
($id,$imageURL)=split(/,/);
$IMAGE{"SEINET$id"}=$imageURL;
}
close(IN);

#############ANNOTATIONS
open(IN,"identifications.csv") || die;
#1956168,"Liz Makings","13 Sept 2011",,"Cryptantha maritima","(Greene) Greene",,,,,,"sheet has three differenct species, this is the main one",78fc71d2-fe85-4e84-bf01-94178e4df5d5
while(<IN>){
chomp;
s/"//g;
($id,$annotator,$anno_date,$null,$annoName,@rest)=split(/,/);
$ANNO{"SEINET$id"}.="Annotation: $annoName; $annotator; $anno_date\n";
}
close(IN);





########################################process tab-delimited file. 


    my $file = 'seinet.tab';

open(IN,$file) || die;
Record: while(<IN>){
s/\[Redacted\]//g;
	chomp;
	@columns=split(/\t/,$_,100);
        if( $#columns==72){
#delete penultimate column
		splice(@columns,71,1);
	}
        unless( $#columns==71){
		print ERR "$#columns bad field number $_\n";
	}

($id,
$institutionCode,
$collectionCode,
$basisOfRecord,
$occurrenceID,
$catalogNumber,
$otherCatalogNumbers,
$ownerInstitutionCode,
$family,
$scientificName,
$genus,
$specificEpithet,
$taxonRank,
$infraspecificEpithet,
$scientificNameAuthorship,
$taxonRemarks,
$identifiedBy,
$dateIdentified,
$identificationReferences,
$identificationRemarks,
$identificationQualifier,
$typeStatus,
$recordedBy,
$recordNumber,
$eventDate,
$year,
$month,
$day,
$startDayOfYear,
$endDayOfYear,
$verbatimEventDate,
$habitat,
$fieldNotes,
$fieldNumber,
$occurrenceRemarks,
$informationWithheld,
$dynamicProperties,
$associatedTaxa,
$reproductiveCondition,
$establishmentMeans,
$lifeStage,
$sex,
$individualCount,
$samplingProtocol,
$preparations,
$country,
$stateProvince,
$county,
$municipality,
$locality,
$decimalLatitude,
$decimalLongitude,
$geodeticDatum,
$coordinateUncertaintyInMeters,
$footprintWKT,
$verbatimCoordinates,
$georeferencedBy,
$georeferenceProtocol,
$georeferenceSources,
$georeferenceVerificationStatus,
$georeferenceRemarks,
$minimumElevationInMeters,
$maximumElevationInMeters,
$verbatimElevation,
$disposition,
$language,
$rights,
$rightsHolder,
$accessRights,
$modified,
$recordId,
$references)=@columns;


	if($family =~ /\b(Psoraceae|Bryaceae)\b/){
		&skip( "$id Non-vascular plant: $_\n");
		next Record;
	}




##################Exclude cult
	if($locality=~/(CULTIVATED|Cultivated|Huntington Botanic)/ || $habitat=~/CULTIVATED|Cultivated/){
				&skip("$id Specimen from cultivation $_\n");
				++$skipped{one};
				next Record;
			}


##################CNUM
 		if($recordNumber=~/^(\d+)$/){
                        $CNUM=$1; $PREFIX=$SUFFIX="";
                }
                elsif($recordNumber=~/^(\d+)-(\d+)$/){
                        $PREFIX="$1-"; $CNUM=$2;
                }
                elsif($recordNumber=~/^(\d+)(\D+)$/){
                        $SUFFIX=$2; $CNUM=$1;
                }
                elsif($recordNumber=~/^(\D+)(\d+)$/){
                        $PREFIX=$1; $CNUM=$2;
                }
                elsif($recordNumber=~/^(\D+)(\d+)(.*)/){
                        $PREFIX=$1; $CNUM=$2; $SUFFIX=$3;
                }
                else{
                        $SUFFIX=$recordNumber;
                        $CNUM="";
                }
                if($CNUM || $PREFIX || $SUFFIX){
                        $recordedBy= "Anonymous" unless $recordedBy;
                }


###############DATES###############
	if($eventDate=~/(\d\d\d\d)-(\d\d)-(\d\d)/){
		$YYYY=$1; $MM=$2; $DD=$3;
		$MM="" if $MM eq "00";
		$DD="" if $DD eq "00";
		$MM=~s/^0//;
		$DD=~s/^0//;
		unless($MM){
			$MM=$month;
		}
		if($YYYY && $MM && $DD){
					$JD=julian_day($YYYY, $MM, $DD);
					$LJD=$JD;
		}
		elsif($YYYY && $MM){
			if($MM=12){
					$JD=julian_day($YYYY, $MM, 1);
					$LJD=julian_day($YYYY, $MM, 31);
			}
			else{
					$JD=julian_day($YYYY, $MM, 1);
					$LJD=julian_day($YYYY, $MM+1, 1);
						$LJD -= 1;
			}
		}
		elsif($YYYY){
					$JD=julian_day($YYYY, 1, 1);
					$LJD=julian_day($YYYY, 12, 31);
		}
	}
	else{
		$JD=$LJD="";
	}
	$DATE= $verbatimEventDate || $eventDate;
	if($LJD > $today_JD){
		&log("$id DATE nulled, $eventDate ($LJD)  greater than today ($today_JD)\n");
		$JD=$LJD="";
	}
	elsif($YYYY < 1800){
		&log("$id DATE nulled, $eventDate ($YYYY) less than 1800\n");
		$JD=$LJD="";
	}

#print "$institutionCode, $catalogNumber, $ownerInstitutionCode,\n";


###########COUNTY

	foreach ($county){
		s/[()]*//g;
		s/ +coun?ty.*//i;
		s/ +co\.//i;
		s/ +co$//i;
		s/ *$//;
		s/^$/unknown/;
		s/County Unknown/unknown/;
		s/County unk\./unknown/;
		s/Unplaced/unknown/;
		#print "$_\n";

		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|unknown|Unknown)$/){
			$v_county= &verify_co($_);
			if($v_county=~/SKIP/){
				&skip("$id NON-CA COUNTY? $_");
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){
				&log("$id COUNTY $_ -> $v_county");
				$_=$v_county;
			}


		}
	}





#########COORDS
		if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){
			$decimalLongitude="-$decimalLongitude" if $decimalLongitude > 0;
			if($decimalLatitude > 42.1 || $decimalLatitude < 32.5 || $decimalLongitude > -114 || $decimalLongitude < -124.5){
				&log("$id coordinates set to null, Outside California: >$decimalLatitude< >$decimalLongitude<");
				$decimalLatitude =$decimalLongitude="";
			}
		}

###########NAME
		$scientificName="" if $scientificName=~/^No name$/i;
		$scientificName=ucfirst($scientificName);
		unless($scientificName){
				&skip("$id No name: $id", @columns);
				next Record;
		}
		($genus=$scientificName)=~s/ .*//;
		if($exclude{$genus}){
				&skip("$id Non-vascular plant: $id", @columns);
				next Record;
		}
foreach ($scientificName){
s/\xD7/X/;
s/\303\227/X /g;
	s/ variety /var./;
	s/var\./var. /;
	s/var\./ var./;
	s/  +/ /g;
}
$scientificName=&strip_name($scientificName);
			#if($scientificName=~/  /){
				if($scientificName=~/^[A-Z][a-z]+ [a-z]+ +[a-z]+$/){
					&log("$id $scientificName: var. added $id");
					$scientificName=~s/^([A-Z][a-z]+ [a-z]+) +([a-z]+)$/$1 var. $2/;
				}
				#$scientificName=~s/  */ /g;
			#}
			if($scientificName=~/CV\.? /i){
				&skip("$id Can't deal with cultivars yet: $id", $scientificName);
				#$badname{$name}++;
				next Record;
			}
			foreach($scientificName){
s/ sp\.?$//;
				s/ forma / f. /;
				s/ ssp / subsp. /;
				s/ spp\.? / subsp. /;
				s/ var / var. /;
				s/ ssp\. / subsp. /;
				s/ f / f\. /;
				s/ [xX] / × /;
			}
			if($scientificName=~/([A-Z][a-z-]+ [a-z-]+) × /){
				$hybrid_annotation=$scientificName;
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			elsif($scientificName=~/^([A-Z][a-z-]+ [a-z-]+) hybrids?$/){
				$hybrid_annotation=$scientificName;
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			elsif($scientificName=~/([A-Z][a-z-]+ [a-z-]+ .*) × /){
				$hybrid_annotation=$scientificName;
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			else{
				$hybrid_annotation="";
			}

			if($alter{$scientificName}){
				&log ("$id Spelling altered to $alter{$scientificName}: $scientificName");
				$scientificName=$alter{$scientificName};
			}
			unless($TID{$scientificName}){
				$on=$scientificName;
				if($scientificName=~s/subsp\./var./){
					if($TID{$scientificName}){
						&log("$id Not yet entered into SMASCH taxon name table: $on entered as $scientificName");
					}
					else{
						&skip("$id Not yet entered into SMASCH taxon name table: $on skipped");
						++$badname{"$family $on"};
						next Record;
					}
				}
				elsif($scientificName=~s/var\./subsp./){
					if($TID{$scientificName}){
						&log("$id Not yet entered into SMASCH taxon name table: $on entered as $scientificName");
					}
					else{
						&skip("$id Not yet entered into SMASCH taxon name table: $on skipped");
						++$badname{"$family $on"};
						next Record;
					}
				}
				else{
					&skip("$id Not yet entered into SMASCH taxon name table: $on skipped");
					++$badname{"$family $on"};
					next Record;
				}
			}
######################COLLECTOR
if($recordedBy=~s/; (.*)//){
$otherColl=$1;
}
else{
$otherColl="";
}



#####################ELEVATION
foreach( $verbatimElevation){
	s/ [eE]lev.*//;
	s/feet/ft/;
	s/\d+ *m\.? \((\d+).*/$1 ft/;
	s/\(\d+\) \((\d+).*/$1 ft/;
	s/'/ft/;
	s/FT/ft/;
	s/Ft/ft/;
	s/- *ft/ft/;
	s/meters/m/;
	s/[Mm]\.? *$/m/;
	s/ft?\.? *$/ft/;
	s/ft/ ft/;
	s/m *$/ m/;
	s/  / /g;
	#print "$_\n";
}
#next Record;

unless($IMAGE{"SEINET$id"}){
$IMAGE{"SEINET$id"}="";
}
unless($ANNO{"SEINET$id"}){
$ANNO{"SEINET$id"}="";
}


			print OUT <<EOP;
Accession_id: SEINET$id
Other_label_numbers: $institutionCode, $catalogNumber
Name: $scientificName
Date: $eventDate
EJD: $JD
LJD: $LJD
Habitat: $habitat
CNUM: $CNUM
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Associated_species: $associatedTaxa
County: $county
Location: $municipality $locality
T/R/Section: 
Collector: $recordedBy
Other_coll: $otherColl
Combined_collector: 
Habitat: $Habitat
Color: $color
Type_status: $typeStatus
Macromorphology: $Description
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
UTM: $UTM
Notes: $fieldNotes $occurrenceRemarks
Hybrid_annotation: $hybrid_annotation
Source: $georeferenceSources
Datum: $geodeticDatum
Elevation: $verbatimElevation
Max_error_distance: $coordinateUncertaintyInMeters
Image: $IMAGE{"SEINET$id"}
$ANNO{"SEINET$id"}

EOP
}

sub skip {
	print ERR "skipping: @_\n"
}
sub log {
	print ERR "logging: @_\n";
}
