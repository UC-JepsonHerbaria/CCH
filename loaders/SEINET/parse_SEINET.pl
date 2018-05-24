use Time::JulianDay;
use Time::ParseDate;
use lib '/Users/davidbaxter/DATA';
use CCH;
$today=`date "+%Y-%m-%d"`;
chomp($today);
($today_y,$today_m,$today_d)=split(/-/,$today);
$today_JD=julian_day($today_y, $today_m, $today_d);

&load_noauth_name; #loads taxon id master list into an array

open(ERR,">SEINET_error2") || die;;	#open error file called SEINET_error, ERR prints into this file
open(OUT,">SEINET2.out") || die;;	#open output file called SEINET.out


%monthno=( '1'=>1, '01'=>1, 'jan'=>1, 'Jan'=>1, 'January'=>1, '2'=>2, '02'=>2, 'feb'=>2, 'Feb'=>2, 'February'=>2, '3'=>3, '03'=>3, 'mar'=>3, 'Mar'=>3, 'March'=>3, '4'=>4, '04'=>4, 'apr'=>4, 'Apr'=>4, 'April'=>4, '5'=>5, '05'=>5, 'may'=>5, 'May'=>5, '6'=>6, '06'=>6, 'jun'=>6, 'Jun'=>6, 'June'=>6, '7'=>7, '07'=>7, 'jul'=>7, 'Jul'=>7, 'July'=>7, '8'=>8, '08'=>8, 'aug'=>8, 'Aug'=>8, 'August'=>8, '9'=>9, '09'=>9, 'sep'=>9, 'Sep'=>9, 'Sept'=>9, 'September'=>9, '10'=>10, 'oct'=>10, 'Oct'=>10, 'October'=>10, '11'=>11, 'nov'=>11, 'Nov'=>11, 'November'=>11, '12'=>12, 'dec'=>12, 'Dec'=>12, 'December'=>12);
######################################



#GET IMAGE URL
open(IN,"images.tab") || die;
while(<IN>){

 	chomp;		#remove trailing new line /n
	@columns=split(/\t/,$_,100); #create an array of columns by splitting on each tab, into scalars, up to 100 times

($id,$url1,$imageURL,@rest);	#split each line into $id and $imageURL on the comma character
$IMAGE{"SEINET$id"}=$imageURL;	#set $IMAGE for each "SEINET[$id]" to $imageURL
}
close(IN);

#############ANNOTATIONS
open(IN,"identifications.tab") || die;
#1956168,"Liz Makings","13 Sept 2011",,"Cryptantha maritima","(Greene) Greene",,,,,,"sheet has three differenct species, this is the main one",78fc71d2-fe85-4e84-bf01-94178e4df5d5
while(<IN>){

 	chomp;		#remove trailing new line /n
	@columns=split(/\t/,$_,100); #create an array of columns by splitting on each tab, into scalars, up to 100 times

($id,$annotator,$annoID,$anno_date,$null,$annoName,@rest);	#split on the comma, into $id,$annotator,$anno_date,$null,$annoName, and dump the rest into an array called @rest
$ANNO{"SEINET$id"}.="$annoName; $annotator; $anno_date\n"; #for $ANNO for each "SEINET$id", print the following into and a new line. ".=" Means accumulate entries, if there are multiple ANNOs per SEINET$id
}
close(IN);



########################################process tab-delimited file. 


    my $file = 'seinet.tab';	#the file this script will act upon is called 'seinet.tab'

open(IN,$file) || die;	#open the file, die.
Record: while(<IN>){	#while in the file, (Records...)

#fix some data quality and formatting problems that make import of fields of certain records impossible
s/redacted/redacted by SEINet/g;		#substitute "redacted" with "redacted by SEINet" so users dont think CCH deleted the information in locality and coordinate fields for some rare taxa
s/(â?¦)/ /g; #substitute weird formatting code "â?¦" with ""
s/""""/"/g;
s/&apos;//g;
s/[nN]\/[aA]//g;
#s/\|/, /g;
#s/""/'/g;
s/\<p/Mo/g;
s/\( A Opentia\) roots one locality.//g;
s/"" ty/ ty/g;	#substitute problem "" in records so that it does not impact the import process
s/"" in/ in/g;
s/and ""/and /g;
s/"Ac\./AC./g;
s/" ty/ ty/g;
s/" in/ in/g;
s/and "/and /g;
s/"" ty/ ty/g;
s/""\)/"\)/g;
s/""White Plains""/'White Plains'/g;
s/""wash""/'wash'/g;
s/""Wild Oats""/'Wild Oats'/g;
s/""Wild Plum""/'Wild Plum'/g;
s/""Blue-eyed grass""/'Blue-eyed grass'/g;
s/""Wild Parsnip""/'Wild Parsnip'/g;
s/""Old Man's Whiskers""/'Old Man's Whiskers'/g;
s/""Yellow mock aster""/'yellow mock aster'/g;
s/""Buffalo Grass; Short-hair grass""/'Buffalo Grass; Short-hair grass'/g;
s/""Indian onion or Onion Lily""/'Indian onion or Onion Lily'/g;
s/'bioblitz""/bioblitz/g;
s/""Summit""/'Summit'/g;
s/"Huckleberry Trail"/'Huckleberry Trail'/g; 
s/"SSheep Corral"/'Sheep Corral'/g;
s/"individuals"/'individuals'/g;
s/"The Potrero"/The Potrero/g;
s/"Kathyrn"//g;
s/5" Q/5' Q/g;
s/6'11", X/6'11" X/g;
s/"\(probably = A\. uva ursi X A\. columbiana, as it occurs only where they are found together\.\)"/probably = A. uva ursi X A. columbiana, as it occurs only where they are found together./g;
s/"Chiricahua Mtns\. Coronado Natl\. Forest\- El Coronado Ranch"/Chiricahua Mountains, Coronado National Forest, El Coronado Ranch/g;
s/"cotton"/'cotton'/g;
s/"Fir Canyon"/'Fir Canyon'/g;
s/"A"/'A'/g;
s/"B"/'B'/g;
s/"C"/'C'/g;
s/"D"/'D'/g;
s/"E"/'E'/g;
s/"G"/'G'/g;
s/"Liana, fruto color naranja 2 cm de diametro\."/Liana, fruto color naranja 2 cm de diametro./g;
s/"no name"/'no name'/g;
s/"Sunset Cove"/Sunset Cove/g;
s/"D St\. Fill"/'D St. Fill'/g;
s/"desert pavement\."/desert pavement/g;
s/"Weak leaf"/Weak leaf/g;
s/"4-pond Valley"/'4-pond Valley'/g;
s/"Brazilian Plume", "Plume Flower"/Brazilian Plume, Plume Flower/g;
s/"wedding mesa"/'wedding mesa'/g;
s/"Hog Wallow"/'Hog Wallow'/g;
s/"Mrs\. Vivian Doney, Vista California 3 December 1971"/Mrs. Vivian Doney, Vista California 3 December 1971/g;
s/"Johnson's Cactus Garden, Paramount, California, 22 November 1965"/Johnson's Cactus Garden, Paramount, California, 22 November 1965/g;
s/"Mineral Spring"/'Mineral Spring'/g;
s/"bioblitz"/bioblitz/g;
s/"Greene"/'Greene'/g;
s/"Race Track"/'Race Track'/g;
s/"Female shrub\, with male flowers olny acc\. - Herbart L\. Mason\, Bot\. 112\."/Female shrub, with male flowers only acc. - Herbert L. Mason, Bot. 112./g;
s/"Sea Fig"/Sea Fig/g;
s/""Dwarf Lupine""/'Dwarf Lupine'/g;
s/"roadise"/'roadise'/g;
s/"Round-leaved Moort"/Round-leaved Moort/g;
s/"troyer citrange"/troyer citrange/g;
s/"The Ranch"/'The Ranch'/g;
s/"banner"/banner/g;
s/"block"/'block'/g;
s/"Sonoran Desert Wildflower"/'Sonoran Desert Wildflower'/g;
s/"skunky\."/skunky\./g;
s/"Forest Home"/'Forest Home'/g;
s/"West Canyon, western edge of the Colorado Desert\."/West Canyon, western edge of the Colorado Desert./g;
s/"Little Volcano"/'Little Volcano'/g;
s/"Salix franciscana Seemen lectotype female shoot\."/Salix franciscana Seemen lectotype female shoot./g;
s/"St Johnswort"/St Johnswort/g;
s/"Mouse-ear Chickweed"/Mouse-ear Chickweed/g;
s/"White sweet"/White sweet/g;
s/"sunken area"/'sunken area'/g;
s/"very young"/very young/g;
s/"Lake Prairie"/'Lake Prairie'/g;
s/"Silk Tassle"/'Silk Tassle'/g;
s/"badlands"/'badlands'/g;
s/11"\-18"/11-18"/g;

	chomp;		#remove trailing new line /n
	@columns=split(/\t/,$_,100); #create an array of columns by splitting on each tab, into scalars, up to 100 times
        if( $#columns==87){	#if the number of values in the columns array is exactly 87
			splice(@columns,86,1); #delete penultimate column ###I don't know what the purpose of this is
		}
        unless( $#columns==86){
		print ERR "$#columns bad field number $_\n";
	}

#id	institutionCode	collectionCode	ownerInstitutionCode	basisOfRecord	occurrenceID
#catalogNumber	otherCatalogNumbers	kingdom	phylum	class	order	family	scientificName	
#scientificNameAuthorship	genus	specificEpithet	taxonRank	infraspecificEpithet
#identifiedBy	dateIdentified	identificationReferences	identificationRemarks	taxonRemarks	identificationQualifier	
#typeStatus	recordedBy	recordedByID	associatedCollectors	recordNumber	eventDate	year	month	day	startDayOfYear
#endDayOfYear	verbatimEventDate	occurrenceRemarks	habitat	substrate	verbatimAttributes	fieldNumber	informationWithheld
#dataGeneralizations	dynamicProperties	associatedTaxa	reproductiveCondition	establishmentMeans	cultivationStatus	
#lifeStage	sex	individualCount	samplingProtocol	samplingEffort	preparations	country	stateProvince	county	
#municipality	locality	locationRemarks	localitySecurity	localitySecurityReason	decimalLatitude	decimalLongitude
#geodeticDatum	coordinateUncertaintyInMeters	verbatimCoordinates	georeferencedBy	georeferenceProtocol	georeferenceSources	
#georeferenceVerificationStatus	georeferenceRemarks	minimumElevationInMeters	maximumElevationInMeters	minimumDepthInMeters
#maximumDepthInMeters	verbatimDepth	verbatimElevation	disposition	language	recordEnteredBy	modified	
#sourcePrimaryKey	collId	recordId	references
#note that if the fields change. The field headers can be found in the occurrences.csv file
($id,
$institutionCode,
$collectionCode,
$ownerInstitutionCode,	#added 2016
$basisOfRecord,
$occurrenceID,
$catalogNumber,
$otherCatalogNumbers,
$kingdom,
$phylum,
#10
$class,
$order,
$family,
$scientificName,
$scientificNameAuthorship,
$genus,
$specificEpithet,
$taxonRank,
$infraspecificEpithet,
$identifiedBy,
#20
$dateIdentified,
$identificationReferences,
$identificationRemarks,
$taxonRemarks,
$identificationQualifier,
$typeStatus,
$recordedBy,
$recordedByID,			#added 2016
$associatedCollectors,	#added 2016
$recordNumber,
#30
$eventDate,
$year,
$month,
$day,
$startDayOfYear,
$endDayOfYear,
$verbatimEventDate,
$occurrenceRemarks,
$habitat,
$substrate,			#added 2016
#40
$verbatimAttributes, #added 2016
$fieldNumber,
$informationWithheld,
$dataGeneralizations,
$dynamicProperties,
$associatedTaxa,
$reproductiveCondition,
$establishmentMeans,
$cultivationStatus,	#added 2016
$lifeStage,
#50
$sex,
$individualCount,
$samplingProtocol,
$samplingEffort,
$preparations,
$country,
$stateProvince,
$county,
$municipality,
$locality,
#60
$locationRemarks, #newly added 2015-10, not processed
$localitySecurity,		#added 2016
$localitySecurityReason,	#added 2016
$decimalLatitude,
$decimalLongitude,
$geodeticDatum,
$coordinateUncertaintyInMeters,
$verbatimCoordinates,
$georeferencedBy,
$georeferenceProtocol,
#70
$georeferenceSources,
$georeferenceVerificationStatus,
$georeferenceRemarks,
$minimumElevationInMeters,
$maximumElevationInMeters,
$minimumDepthInMeters, #newly added 2015-10, not processed
$maximumDepthInMeters, #newly added 2015-10, not processed
$verbatimDepth, #newly added 2015-10, not processed
$verbatimElevation,
$disposition,
#80
$language,
$recordEnteredBy, #newly added 2015-10, not processed
$modified,
$sourcePrimaryKey,  #added 2016
#$rights,
#$rightsHolder,
#$accessRights,
$collID,	#added 2016
$recordId,
$references)=@columns;	#The array @columns is made up on these 87 scalars, in this order

##################Exclude known problematic specimens by id numbers, most from outside California and Baja California
 if ($id =~/^(6010380|3143301|6010483|3288631|5999431|6009962|3828429|3128756|891892|947111|6901995|3236890|3349408|5556965|3920225|3920384|7358734|949278|947283|953299|1910899|960031|7887537|901900|950642|885247|2139875|3236890|7880474|7880475|3349409|3156500|955884|5578801|5578802|8111276|901887|10964957|10899737|10612927|523075|2139878|947426|949080|952106|3840903|10450011|7878637|3350112|5574540|2140016|206575|8094686|6919312|10587155|6059833|6053609|6078071|6084883|6038783|6080815|6092926|6077290|6084618|6090271|6067228|6078439|6062798|6061904|6053009|6048333|6081870|3831133|5578807|957986|948347|7987520|3156332|5585640|5585641|3828429|780313|947147|932794|4090498|5556964|10492513|756181|8892781|10476365|2030103|3131301|5554619|3127702|5578808|5547519|5556946|954279|10789840|892491|952443|4557750|4557751|4134703|8071906|7067885|10791260|8099704|10546522|1004641|7293869|3130961|3158166|8100447|10905080|4041567|7096710|7096711|10789688|7880493|7880446|5556963|10484529|8696461|7096697|7096696|7572142|7579661|6900851|5585639|10731649|5519952|10848658|8215883)$/){
	&skip("excluded problem record or record known to be not from California\t$locality\t--\t$id");
		++$skipped{one};
		next Record;
	}
	
	
##################Exclude known problematic from Baja California and other States in Mexico with "California" as state
 if ($id =~/^(10615070|8720137|3132405|1939552|1939555|9372982|3157806|4182802|982039|982186|986591|10570608|10929212|3150102|3269779|904990|10571329|1940962|957093|4962440|5001448|10593214|10572572|10678657|3129513|903956|10932808|8735151|7718784|10796230|3148362|10678725|10743352|10500255|5501463|3132653|1912776|7247972|3145054|10550870|10546591|10531453|10755578|10794450|10794455|10969903|6165250|10870828|178669|4177487|10846560|1939654|10727925|1939566|3132654|6165302|3132655|5501705|5501448|5501418|5501427|6165662|5500734|6165216|1939553|6165097)$/){
	&skip("Baja California record with California as state\t$id\t--\t$locality");
		++$skipped{one};
		next Record;
	}
	
##################Exclude known problematic localities from other States in Mexico with "California" as state	
 if ($locality =~/(Cedros Island|Cerros Island|Campeche|Tuxpe±a, Camp\.|Clarion Island|Isla del Carmen|Escárcega|HopelchTn|Cd\. del Cármen|Mamantel|Xpujil|Ciudad del Carmen|Tuxpeña, Camp\.)/){
	&skip("Mexico record with California as state\t$id");
		++$skipped{one};
		next Record;
	}	
	
##################Exclude certain institutions, in likely event they are accidentally downloaded from SEINet
 if ($institutionCode =~/^(GEO|UNCA|Nicotiana - RSA|SEINet|RHNM|MABA-Plants|GreaterGood|Sonoran Atlas|NCZP|BUT-IPA|NY|SENEY|SWANER|SIM|TAWES|OBI|UCSC|DAV|GMDRC|SDSU|UCR|SCFS)$/){
	&skip("excluding records from certain Portal institutions\t$institutionCode");
		++$skipped{one};
		next Record;
	}
	
##################Process only these large collections, which are not processed in first script.  The computer runs out of memory before getting to these.
#must combine the two files
 next unless ($institutionCode =~/^(ARIZ|ASU|ASC|BRY|DES|OSC)$/);

	
	
##################Exclude specimens where most fields including locality and lat/long were redacted by herbarium or SEINET (mostly endangered species and cacti), not mappable 
# if ($informationWithheld =~/^field values redacted.*/){
# 	&skip("record not useful, all locality, date, collection number and georeference fields redacted by SEINET\t$id");
#		++$skipped{one};
#		next Record;
#	}
##################Exclude non-vascular plants
	if($family =~ /(Psoraceae|Bryaceae|Wrangeliaceae|Sargassaceae|Ralfsiaceae|Chordariaceae|Porrelaceae|Mielichhoferiaceae Schimp.|Mielichhoferiaceae|Lessoniaceae|Laminariaceae|Dictyotaceae)/){	#if $family is equal to one of the values in this block
		&skip("Non-vascular herbarium specimen: $_\t$id");	#skip it, printing this error message
		++$skipped{one};
		next Record;
	}
	
	if($class =~ /^(Anthocero|Ascomycota|Bryophyta|Chlorophyta|Rhodophyta|Marchant)/){	#if $class is equal to one of the values in this block
		&skip("Non-vascular herbarium specimen: $_\t$id");	#skip it, printing this error message
		++$skipped{one};
		next Record;
	}
	if($scientificName =~ /^(Gemmabryum |Nogopterium |Rosulabryum |Dichelyma |Aulacomnium |Antitrichia |Alsia )/){	#if genus is equal to one of the values in this block
		&skip("Non-vascular herbarium specimen: $_\t$id");	#skip it, printing this error message
		++$skipped{one};
		next Record;
	}	
	
# if collection code contains the word "NONVASC", "OSCB" [OSC Bryophyte Herbarium], etc., skip the record
	if($collectionCode=~/(NONVASC|OSCB)/){
		&skip("Non-vascular herbarium specimen $_\t$id");	#&skip is a function that skips a record and writes to the error log
		++$skipped{one};
		next Record;
	}

##################Exclude problematic specimens with certain locality issues
# if locality or habitat contain the word "cultivated" etc., skip the record
	if($locality=~/^(TBD|PHOTO|Unknown$|Unspecified\.)/){
		&skip("Specimen with problematic locality that is unresolvable $_\t$id");	#&skip is a function that skips a record and writes to the error log
		++$skipped{one};
		next Record;
	}

##################Exclude non-herbarium specimens
# if collection code contains the word "pollen" or "seeds" or etc., skip the record
	if($collectionCode=~/(Pollen|Seeds)/){
				&skip("Record not a herbarium specimen $_\t$id");	#&skip is a function that skips a record and writes to the error log
				++$skipped{one};
				next Record;
	}


###########informationWithheld
		if($informationWithheld=~m/^field values redacted.*/i){ #if there is text is informationWithheld (case insensitive), use the string
	 $informationWithheld = "$informationWithheld; ";
	 &log("specimen redacted by SEINet\t$id");
	 }
	 else{
	 $informationWithheld = ""
	 }


#########Skeletal Records
	if(($informationWithheld =~ m/^$/) && ($municipality =~ m/^$/) && ($locality =~ m/^$/) && ($occurrenceRemarks=~ m/^$/) && ($eventDate =~ m/^$/) && ($habitat =~ m/^$/) && ($decimalLatitude =~ m/^$/) && ($decimalLongitude =~ m/^$/) && ($verbatimCoordinates =~ m/^$/)){ #exclude skeletal records
			&skip("skeletal records without data in most fields icluding locality and coordinates\t$id");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
	}


###############Fix records from UCSH (University of South Carolina Herbarium where all localities are "UNK" or some other non-locality text and locality data erroneously entered into Habitat field
	if(($institutionCode=~/^USCH$/) && ($locality=~m/^UNK$/)){ #fix some really problematic county records
		$locality=$habitat;
		$habitat=~s/.*//;
		&log("USCH Location problem modified: $county\t$locality\t--$habitat\t--\t$id\n");	
	}

##################CNUM
#CNUM is used for sorting, with PREFIX and SUFFIX displayed accordingly
# 		if($recordedBy=~/([A-Z]+[a-z]+\s[A-Z]+[a-z]+)\|([A-Z]+[a-z]+\s[A-Z]+[a-z]+)/){	#if recordedby is a string separated by | (i.e. MO specimens)
# 			$recordedBy=$1;
# 			$otherColl=$2;
# 			$otherColl=~s/\|/\,/;
# 		}
 		
 		
##################CNUM
#CNUM is used for sorting, with PREFIX and SUFFIX displayed accordingly
 		if($recordNumber=~/^(\d+)$/){	#if recordNumber is a digit...
                        $CNUM=$1; $PREFIX=$SUFFIX="";	#CNUM is just that number
                }
                elsif($recordNumber=~/^([A-Z]+[a-z]+)\s?(\d+)$/){
                		$PREFIX=$1; $CNUM=$2; $SUFFIX="";
                }
                elsif($recordNumber=~/^([A-Z]+[a-z]+)\s?([sS]\.[nN]\.)$/){ #collector normal caps and s.n.
                		$PREFIX=$1; $CNUM=$2; $SUFFIX="";
                }
                elsif($recordNumber=~/^([A-Z]+)\s?([sS]\.[nN]\.)$/){   #colletor in all caps and s.n.
                		$PREFIX=$1; $CNUM=$2; $SUFFIX="";
                }		
                elsif($recordNumber=~/^([sS]\.[nN]\.)$/){   #colletor number s.n.
                		$PREFIX=""; $CNUM="s.n."; $SUFFIX="";
                }
                elsif($recordNumber=~/^([sS][nN])$/){   #colletor number sn
                		$PREFIX=""; $CNUM="s.n."; $SUFFIX="";
                }
                elsif($recordNumber=~/^(\d+)-(\d+)$/){	#if two numbers separated by a dash...
                        $PREFIX="$1-"; $CNUM=$2;		#Add the number before the dash (plus the dash) as a prefix
                }
                elsif($recordNumber=~/^(\d+)(\D+)$/){	#if a number followed by non-number
                        $SUFFIX=$2; $CNUM=$1;			#the non-number is added as a suffix
                }
                elsif($recordNumber=~/^(\D+)(\d+)$/){	#if a non-number followed by a number
                        $PREFIX=$1; $CNUM=$2;			#non-number added as a prefix
                }
                elsif($recordNumber=~/^(\D+)(\d+)(.*)/){	#if non-number, number, then point[anything]
                        $PREFIX=$1; $CNUM=$2; $SUFFIX=$3;	#PREFIX, CNUM, SUFFIX in order
                }
                else{	#else show the number as a SUFFIX, but CNUM is blank so it doesn't sort by the value displayed
                        $SUFFIX=$recordNumber;
                        $CNUM="";
                }
                if($CNUM || $PREFIX || $SUFFIX){	#if there is any of these values, set recordedBy to Anonymous if recordedBy is blank 
                        $recordedBy= "Anonymous" unless $recordedBy;
                }
		

###############DATES###############
	if($eventDate=~/(\d\d\d\d)-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##
		$YYYY=$1; $MM=$2; $DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		$MM="" if $MM eq "00";	#If $MM is 00, set it to blank 
		$DD="" if $DD eq "00";	#If $DD is 00, set it to blank
		$MM=~s/^0//;	#if $MM begins with zero, substitute nothing for the zero
		$DD=~s/^0//;	#if $DD begins with zero, substitute nothing for the zero
		unless($MM){
			$MM=$month;	#Unless there's a value in the $month. In that case set $MM equal to the $month value (which has already been cleaned up)
		}
		if($YYYY && $MM && $DD){	#If a year, month, and day value are present,
					$JD=julian_day($YYYY, $MM, $DD);	#create the Julian Day ($JD) based on that year, month, and day
					$LJD=$JD;	#Then set the late Julian Day ($LJD) to $JD because there is no range
		}
		elsif($YYYY && $MM){	#elsif there is only a year and month present
			if($MM=12){		#if the month is december...
					$JD=julian_day($YYYY, $MM, 1);		#Set $JD to Dec 1
					$LJD=julian_day($YYYY, $MM, 31);	#Set $LJD to Dec 31
			}
			else{		#else (if it's not december)
					$JD=julian_day($YYYY, $MM, 1);	#Set $JD to the 1st of this month
					$LJD=julian_day($YYYY, $MM+1, 1);	#Set $LJD to the first of the next month...
						$LJD -= 1;						#...Then subtract one day (to get the last dat of this month)
			}
		}
		elsif($YYYY){	#elsif there is only year
					$JD=julian_day($YYYY, 1, 1);	#Set $JD to Jan 1 of that year
					$LJD=julian_day($YYYY, 12, 31);	#Set $LJD to Dec 31 of that year 
		}
	}
	else{	#else (there is no $eventDate)
		$JD=$LJD=""; #Set $JD and $LJD to null
	}
	$DATE= $verbatimEventDate || $eventDate;	#Set $DATE (= display date) to $verbatimEventDate. If not available, use $eventDate
	if($LJD > $today_JD){	#If $LJD is later than today's JD (calculated at the top of the script)
		&log("DATE nulled, $eventDate ($LJD)  greater than today ($today_JD)\t$id");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD="";	#...then null the date
	}
	elsif($YYYY < 1800){	#elsif the year is earlier than 1800
		&log("DATE nulled, $eventDate ($YYYY) less than 1800\t$id");	#Add this error message to the log, then start a new line on the log...
		$JD=$LJD=""; #...then null the date
	}



###########COUNTRY

# fix records where something other than USA was entered erroneously for California specimens
	foreach ($country){
		s/San Diego/USA/;
		s/California/USA/;
		s/Saint Helena/USA/;
		s/Reunion/USA/;
		s/EE\. UU\./USA/;
		
		if (($country =~ m/Antigua and Barbuda|Argentina|Australia|Anguilla|Belize|Brunei Darussalam|Costa Rica|French Guiana|United Arab Emirates|Mexico|Paraguay|Peru|Honduras|Sierra Leone/ ) && ($stateProvince =~ m/California/) && ($county =~ m/[A-Z].*/)){
			unless(($stateProvince =~ m/California/) && ($county =~ m/null/i)){
			$country = "USA";
			&log("bad country name entered for specimen\t$country\t$stateProvince\t$county\t$id");
			}
		}
			else{
				$country = $country
			}	
}

#(because there are many where State = California but are from another country)
if ($country){
	unless ($country =~ m/(U\. S\. A\.|U\.S\.A\.|United States|USA|USA )/i){
		&skip("country not USA: $country\t$id"); 
		next Record;
	}
}

###########COUNTY
		
	foreach ($county){	#for each $county value
		s/^\?$/Unknown/;
		s/\?$//;
		s/^\[//;
		s/\]$//;
		s/^ *$/Unknown/;
		s/\.\.\..*//;
		s/ *$//;
#		s/ and /-/g;
#		s/ or /-/g;
#		s/ OR /-/g;
#		s/ And /-/g;
#		s/, /-/g;
		s/ & /-/g;
		s/\///g;
		s/; /-/g;
		s/\(//g;
		s/\)//g;
		s/:/ /;


#		s/ +coun?ty.*//i;	#substitute a space followed by the word "county" with "" (case insensitive, with or without the letter n)
#		s/ +co\.//i;	#substitute " co." with "" (case insensitive)
#		s/ +co$//i;		#substitute " co" with "" (case insensitive)
#		s/^$/Unknown/g;
		s/^USA/Unknown/g;		#for records with Country also added to County and thus are skipped below
		s/^United States/Unknown/g;	#"United States" => "unknown" for records with Country also added to County and thus are skipped below
		s/^NULL/Unknown/g;
		s/^County Unknown/Unknown/g;	#"County unknown" => "unknown"
		s/^County unk\./Unknown/g;	#"County unk." => "unknown"
		s/^Unplaced/Unknown/g;	#"Unplaced" => "unknown"
		s/needs research/Unknown/g;


	if($county=~m/\s[cC]ount[iesyr]+/){ #fix some really problematic county records
		$county=~s/\s[cC]ount[iesyr]+//;
		&log("County & variants deleted from County: $county\n");	
	}


	if(($id=~/^8104815$/) && ($county=~m/Natural forest Yosemite/)){ #fix some really problematic county records
		$county=~s/Natural forest Yosemite/Alpine/;
		$locality=~s/.*/Ebbet Pass Toyabe Natural forest Yosemite/;	
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	if(($id=~/^3831368$/) && ($county=~m/Reedly/)){ #fix some really problematic county records
		$county=~s/Reedly/Unknown/;
		$locality=~s/.*/Reedly, Canal Bank./;	
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}	

	if(($id=~/^3142815$/) && ($county=~m/El Dorado.*/)){ #fix some really problematic county records
		$county=~s/.*/El Dorado/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	if(($id=~/^8099705$/) && ($county=~m/Blue Lake/)){ #fix some really problematic county records
		$county=~s/Blue Lake/Humboldt/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	if(($id=~/^8103425$/) && ($county=~m/Plaster city/)){ #fix some really problematic county records
		$county=~s/.*/Imperial/;
		$locality=~s/.*/Plaster City, along Painted George Road./;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	if(($id=~/^8103504$/) && ($county=~m/Coyote Mountains/)){ #fix some really problematic county records
		$county=~s/.*/Imperial/;
		$locality=~s/.*/Coyote Mountains, along Painted George Road./;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
	
	if(($id=~/^8274146$/) && ($county=~m/Obispo/)){ #fix some really problematic county records
		$county=~s/Obispo/Kern/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");
	}

	if(($id=~/^3130265$/) && ($county=~m/[Rrm]+/)){ #fix some really problematic county records
		$county=~s/.*/Kern/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");
	}	
	
	if(($id=~/^(3129414|3143225|4692151|951709)$/) && ($county=~m/(Pasadena|Pasadena County)/)){ #fix some really problematic county records
		$county=~s/.*/Los Angeles/;
		&log("County/Location problem modified: $county\t$id\n");
	}
	
	if(($id=~/^4558813$/) && ($county=~m/Pasadena/)){ #fix some really problematic county records
		$county=~s/Pasadena/Los Angeles/;
		$locality=~s/.*/Pasadena Lisson loleal/;	
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
	
	if(($id=~/^7547025$/) && ($county=~m/Pasadena/)){ #fix some really problematic county records
		$county=~s/Pasadena/Los Angeles/;
		$locality=~s/.*/Pasadena/;	
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
		
	if(($id=~/^(901459|903482)$/) && ($county=~m/(Pasadena|Pasadena County)/)){ #fix some really problematic county records
		$county=~s/.*/Los Angeles/;
		$locality=~s/.*/Pasadena/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");
	}	
	
	if(($stateProvince=~m/^California/) &&($county=~m/Isla San Clemente/)){ #fix some really problematic county records
		$county=~s/Isla San Clemente/Los Angeles/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
	
	if(($stateProvince=~m/^California/) &&($county=~m/San Clemente Island/)){ #fix some really problematic county records
		$county=~s/San Clemente Island/Los Angeles/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
		
	if(($stateProvince=~m/^California/) &&($county=~m/Isla Santa Cruz/)){ #fix some really problematic county records
		$county=~s/Isla Santa Cruz/Los Angeles/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	if(($stateProvince=~m/^California/) &&($county=~m/Santa Cruz Island/)){ #fix some really problematic county records
		$county=~s/Santa Cruz Island/Los Angeles/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	if(($id=~/^8101880$/) && ($county=~m/^California/)){ #fix some really problematic county records
		$county=~s/.*/Marin/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
	
	if(($id=~/^6744629$/) && ($county=~m/Pine/)){ #fix some really problematic county records
		$county=~s/.*/Siskiyou/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");
	}
	
	if(($id=~/^175724$/) && ($county=~m/Santa Rosa/)){ #fix some really problematic county records
		$county=~s/.*/Sonoma/;
		$locality=~s/.*/Santa Rosa/;
		&log("County/Location problem modified: $county\t$id\n");	
	}
	
	if(($id=~/^3358234$/) && ($county=~m/San Jocinto/)){ #fix some really problematic county records
		$county=~s/.*/Riverside/;
		$locality=~s/.*/San Jacinto/;
		&log("County/Location problem modified: $county\t$id\n");	
	}

	if(($stateProvince=~m/^California/) && ($county=~m/Bernardino Basin\s.*/)){ #fix some really problematic county records
		$county=~s/.*/San Bernardino/;
		&log("County problem modified: $county\t$id\n");	
	}	

	if(($id=~/^3292360$/) && ($county=~m/San Francisco, California/)){ #fix some really problematic county records
		$county=~s/San Francisco, California/San Francisco/;
		$locality=~s/.*/Lake Merced, San Francisco, California/;	
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
	
	if(($id=~/^4013256$/) && ($county=~m/Vallejo/)){ #fix some really problematic county records
		$county=~s/Vallejo/Solano/;
		$locality=~s/.*/Vallejo, roadside of Hwy 29/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	if(($id=~/^8100470$/) && ($county=~m/Iron Mountain/)){ #fix some really problematic county records
		$county=~s/Iron Mountain/Santa Barbara/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	
	if(($id=~/^(8103720|8103721|8103722|8103723|8103724)$/) && ($county=~m/Mesa Otay/)){ #fix some really problematic county records
		$county=~s/.*/San Diego/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	if(($id=~/^(8100605|8100604|8100601)$/) && ($county=~m/Jacumba Jim/)){ #fix some really problematic county records
		$county=~s/.*/San Diego/;
		$locality=~s/.*/Jacumba Jim Canyon, off of Carrizo Canyon; aprox. 5.1 mi up Carrizo Canyon from Hwy S2./;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
		
	if(($id=~/^(8100489|8100492|8100496)$/) && ($county=~m/Rancho del Cielo/)){ #fix some really problematic county records
		$county=~s/.*/San Diego/;
		$locality=~s/.*/Rancho del Cielo, Iron Mountain area, south of Ramona./;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
		
	if(($id=~/^(8098264|8102290|8100472)$/) && ($county=~m/(Corte Madera Ranch|Pine Valley)/)){ #fix some really problematic county records
		$county=~s/.*/San Diego/;
		$locality=~s/.*/Corte Madera Ranch, south of Pine Valley./;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
		
	if(($id=~/^(8100662|8100670|8100671|8100675|8101754|8105440)$/) && ($county=~m/San Felipe Valley/)){ #fix some really problematic county records
		$county=~s/.*/San Diego/;
		$locality=~s/.*/San Felipe Valley/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
		
	if(($id=~/^7572182$/) && ($county=~m/Adobe Flats/)){ #fix some really problematic county records
		$county=~s/.*/San Diego/;
		$locality=~s/.*/Adobe Flats/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
		
	if(($id=~/^8103294$/) && ($county=~m/Cuyamaca/)){ #fix some really problematic county records
		$county=~s/.*/San Diego/;
		$locality=~s/.*/Cuyamaca, Along outlet stream below Dam./;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}		
	
	if(($stateProvince=~m/^California/) && ($county=~m/(Y.?cora|Buena Vista|Moonlight|San Antonio|Switzer|Cuyamaca|Los .e.+quitos)/)){ #fix some really problematic county records
		$county=~s/.*/San Diego/;
		&log("County problem modified: $county\t$id\n");	
	}
	
	if(($id=~/^8003721$/) && ($county=~m/Y.+cora/)){ #fix some really problematic county records
		$county=~s/.*/San Diego/;
		&log("County problem modified: $county\t$id\n");	
	}		
	
	if(($id=~/^477014$/) && ($county=~/Davis Yolo/)){ #fix some really problematic county records
		$county=~s/Davis Yolo/Yolo/;
		$locality=~s/.*\s?/Davis/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
	
	if(($id=~/^(4604252|6328916)$/) && ($county=~/[wW]eld/)){ #fix some really problematic county records
		$county=~s/.*/Unknown/;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}

	if(($id=~/^921517$/) && ($occurrenceRemarks=~/.*/)){ #fix some really problematic county records
		$locality=~s/.*\s?/From Old Wilson Trail, S. Cal./;
		&log("County/Location problem modified: $county\t--\t$locality\t$id\n");	
	}
			
		unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Unknown|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|unknown|Unknown)$/){
			$v_county= &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
			if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
				&skip("NON-CA COUNTY? $_\t$id");	#run the &skip function, printing the following message to the error log
				++$skipped{one};
				next Record;
			}

			unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
				&log("COUNTY $_ -> $v_county");		#call the &log function to print this log message into the change log...
				$_=$v_county;	#and then set $county to whatever the verified $v_county is.
			}


		}
	}





#########COORDS
		if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits
			if ($decimalLongitude > 0) {
				$decimalLongitude="-$decimalLongitude" ;	#make decLong = -decLong if it is greater than zero
				&log("Positive longitude made negative\t$id") ;
			}	
			if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california...
				&log("coordinates set to null, Outside California: >$decimalLatitude< >$decimalLongitude<\t$id");	#print this message in the error log...
				$decimalLatitude =$decimalLongitude="";	#and set $decLat and $decLong to ""
			}
		}

###########NAME
$scientificName="" if $scientificName=~/^No name$/i;
$scientificName=~s/^ *//;
$scientificName=ucfirst($scientificName);	#Capitalize first letter
		
unless($scientificName){ #if there's no scientificName, use the verbatimScientificName
	if($verbatimScientificName){
		$scientificName = $verbatimScientificName;
	}
	else{
		$scientificName = "";
	}
}
#fix some problematic records where the name is blank but the scientific name is in the type specimen details field
	if(($id=~/^4855229$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Delphinium parishii";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4855083$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Claytonia chenopodina";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4854784$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Navarretia pauciflora";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4854670$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Glyceria californica";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4854370$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Mimulus nasutus var. insignis";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4854361$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Mimulus guttatus var. insignis";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4853966$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Mentzelia oreophila";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4853970$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Mentzelia reflexa";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4853780$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Trifolium anodon";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4853784$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Trifolium decodon";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}
	
	if(($id=~/^4853751$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Phaca davidsonii";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^(4853159|4853158|4853156)$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Minuartia stolonifera";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}


	if(($id=~/^4853055$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Vesicaria occidentalis";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}

	if(($id=~/^4855347$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Crataegus gaylussacia";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}
	
	if(($id=~/^4853504$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Cystium tehatchapiense";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}
	
	if(($id=~/^4853612$/) && ($genus=~/^\s*$/)){ #fix some really problematic type specimen records
		$scientificName="Lupinus crassulus";
		&log("Scientific Name problem corrected: $scientificName\t$id\n");	
	}	

unless($scientificName){	#if no value, skip the line
	&skip("No name: $id", @columns);
	next Record;
}

($genus=$scientificName)=~s/ .*//;	#copy the first word of $sciName into $genus
if($exclude{$genus}){
	&skip("Non-vascular plant: $id", @columns);
	next Record;
}

foreach ($scientificName){
	s/\xD7/X/;	#change possible mult symbols into a capital X
	s/\303\227/X /g;
	s/×/X/g;
	s/ X / X /g;
	s/ x / X /g;
	s/\xc3\x97/X/g;
	s/\x78\x02/X/g;
	s/ variety /var./;	#set the full word "variety" to "var." 
	s/var\./var. /;		#add a space after "var."
	s/var\./ var./;		#add a space before "var."
	s/  +/ /g;			#collapse consecutive whitespace as many times as possible
}

#####process cultivated specimens
	my $cult;
	if($cultivationStatus =~ m/1/){
		$cult = "P";
		&log("Documented Cultivated specimen, to be purple flagged: $cult\t--\t$scientificName\t--\t$id\n");	
	}
	elsif ((not ($cultivationStatus =~ m/^1/)) || (length($cultivationStatus) == 0)){
		if ($locality =~ m/([cC]+ultivated [andor]+ native|[cC]+ultivated [andor]+ weedy|[wW]+eedy [andor]+ cultivated)/){
		next Record;
		}
		
		elsif (($locality =~ m/^(CULTIVATED|cC]+ultivated [pPlLaA]+nts |[cC]+ultivated at |[cC]+ultivated in |cC]+ultivated hybrid |under [cC]+ultivation|Oxford Terrace Ethnobotany|Internet purchase|Cultivted|[Aa]+rtificial hybrid|Trader Joe\'s\:|Bristol Farms\:|Market\:|Tobacco\:|Yaohan\:|market\:|cultivated collection)/) || ($habitat =~ m/CULTIVATED|[Pp]lanted from seed|[Pp]lanted from a seed/)){
		    $cult = "P";
	   		&log("Cultivated specimen found and needs to be purple flagged: $cult\t--\t$scientificName\t--\t$id\n");
	   	}
	}
	else{	
			&log("skipped Cult flagged: $scientificName\n");
	}
	
# flag known problematic cultivated specimens that are being missed, add "P" for purple flag to Cultivated field	
	if($id =~ m/^(4604252|6328916|10887586|10719982|5581928|863212|893304|768990|10609192|10894381|10948816|10520203|10604471|10604540|4133804|10546740|10546609|892656|892658|10485622|4604252|10532490|10531499|10794454|10612368|10825513|7880454|7880453|1907402|1907440|955757|10717813|956247|10970534|10870705|10745264|5765061|741645|956162)$/){
		$cult = "P";
		&log("Cultivated specimen with problematic locality data, to be purple flagged: $cult\t--\t$scientificName\t--\t$id\n");	
	}	
	
#####process remaining taxa

$scientificName=&strip_name($scientificName);
			#if($scientificName=~/  /){
				if($scientificName=~/^[A-Z][a-z]+ [a-z]+ +[a-z]+$/){
					&log("$scientificName: var. added\t$id");
					$scientificName=~s/^([A-Z][a-z]+ [a-z]+) +([a-z]+)$/$1 var. $2/;
				}
				#$scientificName=~s/  */ /g;
			#}
			if($scientificName =~ m/(CV\.?|'[A-Z]?[a-z]+')/i){		#If $sciName contains "CV", regardless of case, with or without a period
				&skip("Cultivar name needs altered: $scientificName\t$id");
				#$badname{$name}++;
				next Record;
			}
			foreach($scientificName){
				s/ sp\.?$//;	#remove "sp" or "sp."
				s/ forma / fo. /;	#change forma to f.
				s/ subspecies / subsp. /;	#change subspecies to subsp.
				s/ ssp / subsp. /;	#change ssp to subsp.
				s/ spp\.? / subsp. /;	#change ssp. to subsp.
				s/ var / var. /;	#change var to var.
				s/ ssp\. / subsp. /;	#change ssp. to subsp.
				s/ f / fo. /;	#change a lone "f" to forma
				s/ [xX×] / X /;	#change  " x " or " X " to the multiplication sign
			}
			if($scientificName=~/([A-Z][a-z-]+ [a-z-]+) × /){	#If $sciName = "[G][enus] [species] × "
				$hybrid_annotation=$scientificName; #set $hyb_ann equal to $sciName
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			elsif($scientificName=~/^([A-Z][a-z-]+ [a-z-]+) hybrids?$/){	#elsif $sciName = "[G][enus] [species]" + "hybrid(s)"
				$hybrid_annotation=$scientificName;	#set $hyb_ann equal to $sciName
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			elsif($scientificName=~/([A-Z][a-z-]+ [a-z-]+ .*) × /){		#elsif $sciName = "[G][enus] [species]"
				$hybrid_annotation=$scientificName;	#set $hyb_ann equal to $sciName
				warn "$1 from $scientificName\n";
				$scientificName=$1;
			}
			else{	#else, set $hyb_ann to blank
				$hybrid_annotation="";
			}

			if($alter{$scientificName}){
				&log("Spelling altered to $alter{$scientificName}: $scientificName\t$id");
				$scientificName=$alter{$scientificName};
			}
			unless($TID{$scientificName}){
				$on=$scientificName;
				if($scientificName=~s/subsp\./var./){
					if($TID{$scientificName}){
						&log("Not yet entered into SMASCH taxon name table: $on entered as $scientificName\t$id");
					}
					else{
						&skip("Not yet entered into SMASCH taxon name table: $on skipped\t$id");
						++$badname{"$family $on"};
						next Record;
					}
				}
				elsif($scientificName=~s/var\./subsp./){
					if($TID{$scientificName}){
						&log("Not yet entered into SMASCH taxon name table: $on entered as $scientificName\t$id");
					}
					else{
						&skip("Not yet entered into SMASCH taxon name table: $on skipped\t$id");
						++$badname{"$family $on"};
						next Record;
					}
				}
				else{
					&skip("Not yet entered into SMASCH taxon name table: $on skipped\t$id");
					++$badname{"$family $on"};
					next Record;
				}
			}
#####finish process of cultivated specimens			
# flag taxa that are known cultivars that should not be added to the Jepson Interchange, add "P" for purple flag to Cultivated field	

	if (length($cult) == 0){
		$cult =	&flag_cult($cult);
	}
			
######################COLLECTOR

	if(($id=~/^3837360$/) && ($recordedBy=~/10/)){ #fix some really problematic collector records
		$recordedBy=~s/10/J.P. Tracy/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	if(($id=~/^3837354$/) && ($recordedBy=~/200/)){ #fix some really problematic collector records
		$recordedBy=~s/200/P.A. Munz/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	if(($id=~/^891651$/) && ($recordedBy=~/Lower Rochester/)){ #fix some really problematic collector records
		$recordedBy=~s/Lower Rochester/Percy Train/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	if(($id=~/^5628320$/) && ($recordedBy=~/^Fry Canal/)){ #fix some really problematic collector records
		$recordedBy=~s/Fry Canal/C.W. Fallass/;
		$locality=~s/From 8th Calif Fry/Fry Canal/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	if(($id=~/^9655845$/) && ($recordedBy=~/L\. Scattered/)){ #fix some really problematic collector records
		$recordedBy=~s/L\. Scattered/Marla Daily/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	if(($id=~/^9655840$/) && ($recordedBy=~/Santa Cruz/)){ #fix some really problematic collector records
		$recordedBy=~s/Santa Cruz/Marla Daily/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
		
	if(($id=~/^9655856$/) && ($recordedBy=~/Santa Cruz/)){ #fix some really problematic collector records
		$recordedBy=~s/Santa Cruz/Marla Daily/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}		
	
	if(($id=~/^8753990$/) && ($recordedBy=~/9356/)){ #fix some really problematic collector records
		$recordedBy=~s/9356/Richard R. Halse/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}

	if(($id=~/^2444728$/) && ($associatedCollectors=~/^Steven A\. Junak; Tina J\. Ayers/)){ #fix some really problematic collector records
		$recordedBy=~s//Steven A. Junak/;
		$associatedCollectors=~s/Steven A\. Junak; Tina J\. Ayers/Tina J. Ayers/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	if(($id=~/^1906967$/) && ($recordedBy=~/Shrub\./)){ #fix some really problematic collector records
		$recordedBy=~s/Shrub\./Naomi Fraga/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	
	if(($id=~/^3404050$/) && ($recordedBy=~/UTC00094980/)){ #fix some really problematic collector records
		$recordedBy=~s/UTC00094980/Peter H. Raven/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	if(($id=~/^3243471$/) && ($recordedBy=~/West Parcel/)){ #fix some really problematic collector records
		$recordedBy=~s/West Parcel/Virginia Moran/;
		&log("Collector problem modified: $recordedBy\t$id\n");
	}
		
	if(($id=~/^192712$/) && ($recordedBy=~/Wolf 10/)){ #fix some really problematic collector records
		$recordedBy =~ s/^Wolf 10/Carl B. Wolf/;
		$recordNumber =~ s/.*/10/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}

	if(($id=~/^6194880$/) && ($recordedBy=~/^Residio/)){ #fix some really problematic collector records
		$recordedBy=~s/^Residio//;
		$locality=~s/\s?/Presidio/;
		&log("Collector problem modified: $recordedBy\t$id\n");
	}	

	if(($id=~/^514961$/) && ($recordedBy=~/W\. Roderick\/ R\.L\. Prothro 71\.0599$/)){ #fix some really problematic collector records
		$recordedBy=~s/W\. Roderick\/ R\.L\. Prothro 71\.0599$/W. Roderick/;
		$associatedCollectors = "R.L. Prothro";
		$recordNumber =~ s/^$/71.0599/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}		
		
	if(($id=~/^3090948$/) && ($recordedBy=~/A\. C\.$/)){ #fix some really problematic collector records
		$recordedBy=~s/A\. C\./A. C. Sanders/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}	

	if(($recordedBy=~/^(et al)\.?,?\s?([A-Z]+[a-z]?\.?.*)/) && (length($associatedCollectors) == 0)){ #fix some really problematic collector records
		$recordedBy=$2;
		$associatedCollectors = "et al";
		&log("Collector problem modified: $recordedBy\t--\t$associatedCollectors\t$id\n");	
	}		
	
	if(($id=~/^9655826$/) && ($recordedBy=~/Valley Anchorage/) && ($associatedCollectors=~/Santa Cruz; Marla Daily/)){ #fix some really problematic collector records
		$recordedBy=~s/Valley Anchorage$/Marla Daily/;
		$associatedCollectors = "";
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	if(($id=~/^6090529$/) && ($recordedBy=~/Thornes', K,etal/) && (length($associatedCollectors) == 0)){ #fix some really problematic collector records
		$recordedBy=~s/Thornes', K,etal$/K. Thorne/;
		$associatedCollectors = "et al";
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}	
		
	if(($id=~/^3090948$/) && ($recordedBy=~/A\. C\.$/)){ #fix some really problematic collector records
		$recordedBy=~s/A\. C\./A. C. Sanders/;
		&log("Collector problem modified: $recordedBy\t$id\n");	
	}
	
	if(($id=~/^477540$/) && ($recordedBy=~/J\.T\. Rothrock 211\/522/)){ #fix some really problematic collector records
		$recordedBy=~s/J\.T\. Rothrock 211\/522/J.T. Rothrock/;
		$recordNumber=~s/^$/211-522/;
		&log("Collector and number problem, modified: $recordedBy\t$recordNumber\t$id\n");	
	}	

	
	if ($recordedBy =~ m/^(R\.? Corral.*az);?,? (A\.? Corral.*az)/){;
		$recordedBy =~ s/R\.? Corral.*az;?,? A\.? Corral.*az/$1/;
		$associatedCollectors =~ s//$2/;
		&log("Collector problem modified: $recordedBy\t--\t$associatedCollectors\t$id\n");
	}

foreach($recordedBy){

	unless (($recordedBy=~m/^(Mace, Wood.*|Dziekanowski, Dun.*|Wilson, Camach.*|King, Johnso.*|Le ?Doux, Dun.*|Le ?Doux, Ke.*|Le ?Doux, Con.*|Dunn, Le ?Dou.*|Le ?Doux, Morri.*|Bennett, Dun.*|Cooke, Pinkav.*|Cox, Dun.*|Parfitt, Pink.*|Weber, Coo.*|Cooke, Pinkav.*|Pinkava, Bat.*|Pinkava, V.*|Abrams, Wiggins|Eastwood, Howell|Phillips, V.*|Walter, Evans|Wiggins, Gillespie|Stoddart, Smith|Tracy, Evans|True, Howell|Thorne, Chandler|Philbrick, Hochberg|Parish, Greata|Heil, Brack|Robinson, Crocker|Heil, Mietty|Ledoux, Dunn|Kennedy, Doten|Heil, Porter|Michener, Bioletti|Kellogg, Harford|Hicks, Carpenter|Baker, Nutting|Goodding, Hordies|Johnson, Hall|Goodwin, Bellue|Gentry, Fox|Chesnut, Drew|Coville, Funston|Dice, Donoghue|Dunn, Brown)/) || (($recordedBy=~m/^([A-Z]+[a-z]*\.? ?[A-Z]?\.? ?\w?\.? ?\w?\w*-? ?\w+)$/) && (length($associatedCollectors) == 0))){ #skip these collector records

		if ($recordedBy=~/\d+/){
		&log("Collector problem: $recordedBy\t$id\n");
		}
	
		if($recordedBy=~/L\., Constance|Joseph, Tracy|J\.W\., Thompson|Gary, Evans|Thomas, Robbins|Jo, Nixon|C\.L\., Hitchcock|Wm\., Whitaker|M\., Barkworth|Jo, Nixon|Ynez, Winblad|Bassett, Maguire|Lewis, Rose|William, Thompson|C\.R\., Qucih|Frank, Gould|Marcus, Jones|Mark, Cary|Barbara, Rice|Harley, Chandler|H\.E\., Parks|H\.S\., Reed|Rimo, Bacigalupi|Ira, Wiggins|Helen, Sharsmith|Lilla, Brown|Margaret, R. Mulligan|A\.D\., Graham|Elmer, Applegate/){ #fix some really problematic collector records
		$recordedBy=~s/, / /;
		&log("Collector: Misplaced comma problem modified, $recordedBy\t$id\n");	
		}

		if(($recordedBy=~/^([A-Z][a-z]+[A-Z]?[a-z]*), ([A-Z]\.? ?[A-Z]?[a-z]?\.?)$/) && (length($associatedCollectors) == 0)){
	#Zika, P
	#Schallert, P. O.
		$recordedBy="$2 $1";
		&log("Collector modified01: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}
		
		if(($recordedBy=~/^([A-Z][a-z]+[A-Z]?[a-z]*), ([A-Z][a-z]+[A-Z]?[a-z]*)$/) && (length($associatedCollectors) > 1)){
	#Zika, Peter
	#Lincoln, Patricia
		$recordedBy="$2 $1";
		&log("Collector modified02: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}

		if(($recordedBy=~/^([A-Z][a-z]+[A-Z]?[a-z]*), ([A-Z][a-z]+[A-Z]?[a-z]*)$/) && (length($associatedCollectors) == 0)){
	#Zika, Peter
	#Lincoln, Patricia
		$recordedBy="$2 $1";
		&log("Collector modified03: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}
		
#	if(($recordedBy=~/^([A-Z]+[a-z]+), ([A-Z]+\.? ?[A-Z]*\.?), ([A-Z]+[a-z]+\.? ?,?\w?\.? ?.*)/) && (length($associatedCollectors) == 0)){
#		$recordedBy="$2 $1";
#		$associatedCollectors=$3;
#		&log("Collector modified03: $recordedBy\t--\t$associatedCollectors\t$id\n");
#	}
	
	#Carpenter, I. W. & Hicks, M. L.

		if(($recordedBy=~/^([A-Z][a-z]+[A-Z]?[a-z]*), ([A-Z]\.? ?[a-z]*)[,;] +([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#Constance, Lincoln; Beetle, Alan; Tracy, Joseph
	#Wibawa, M.; Hrusa, George; Naughton, J.
		$recordedBy="$2 $1";
		$associatedCollectors=$3;
		&log("Collector modified04: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}

		if(($recordedBy=~/^([A-Z]\.? ?[A-Z]?\.? ?[A-Z]+[a-z]+[A-Z]*[a-z]*); ([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#D Atwood; K Thorne
		$recordedBy=$1;
		$associatedCollectors=$2;
		&log("Collector modified11: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}

	
		if(($recordedBy=~/^([A-Z]+[a-z]+ ?[A-Z]+[a-z]+[A-Z]*[a-z]*) & ([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
		#Rimo Bacigalupi & G. T. Robbins
		$recordedBy=$1;
		$associatedCollectors=$2;
		&log("Collector modified05: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}

		if(($recordedBy=~/^([A-Z]+.? ?[A-Z]?[a-z]?.? [A-Z][a-z]+.?)(;|,| &| A[nN][dD]) +([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#A.A. Heller. | H.E. Brown.
	#C. L. Hitchcock And J. S. Martin
	#C. C. Harris & S. K. Harris
	#C.W. Sharsmith; H.K. Sharsmith
	#C. L. Hitchcock; J. S. Martin
	#C. C. Harris, S. K. Harris
		$recordedBy=$1;
		$associatedCollectors=$3;
		&log("Collector modified06: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}


		if(($recordedBy=~/^([A-Z]+.? ?[A-Z]?[a-z]?.? [A-Z][a-z]+.?)( ?\| ?|;|,| ?&| [Aa][nN][dD]) +([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#A. C. Sanders; Ann Howald
	#Aven Nelson, Ruth Nelson
		$recordedBy=$1;
		$associatedCollectors=$3;
		$associatedCollectors=~s/\|/, /g;
		&log("Collector modified07: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}

		if(($recordedBy=~/^([A-Z][a-z]+ ?[A-Z][a-z]+[A-Z]?[a-z]*) +([wW]ith|W\\?\/?) +([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#Rimo Bacigalupi with Roxana S. Ferris
		$recordedBy=$1;
		$associatedCollectors=$3;
		&log("Collector modified08: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}

		if(($recordedBy=~/^([A-Z][a-z]+\.? +[A-Z][a-z]+[A-Z]?[a-z]*)[;,] +([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#Barbara Ertter, Jeff Strachan, Lowell Ahart
	#Bassett Maguire, Arthur H. Holmgren
	#Cindy Roche; Robert Korfhage
	#Chas. H. Quibell; Edith Quibell
		$recordedBy=$1;
		$associatedCollectors=$2;
		$associatedCollectors=~s/&/,/;
		&log("Collector modified09: $recordedBy\t--\t$associatedCollectors\t$id\n");
	}
	
		if(($recordedBy=~/^([A-Z][a-z]+ [A-Z][a-z]+[A-Z]?[a-z]*) +([aA][Nn][Dd]) +([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#Bassett Maguire and Arthur H. Holmgren
		$recordedBy=$1;
		$associatedCollectors=$3;
		&log("Collector modified18: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}

		if(($recordedBy=~/^([A-Z][a-z]+ [A-Z]\.? [A-Z][a-z]+[A-Z]?[a-z]*); +([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#Andrew C. Sanders; John Wear; Nathan Moorhatch
		$recordedBy=$1;
		$associatedCollectors=$2;
		&log("Collector modified10: $recordedBy\t--\t$associatedCollectors\t$id\n");
	}

		if($recordedBy=~/^([A-Z][a-z]+ [A-Z][a-z]+) \(?(\d+)\)?$/){
	#Richard Halse 3456
		$recordedBy = $1;
		$recordNumber = $2;
		&log("Collector modified16: $recordedBy\t--\t$associatedCollectors\t--\t$recordNumber\t--\t$id\n");
		}
		
		if($recordedBy=~/^([A-Z]\.? [A-Z][a-z]+) \(?(\d+)\)?$/){
	#R Halse 3456
		$recordedBy = $1;
		$recordNumber = $2;
		&log("Collector modified17: $recordedBy\t--\t$associatedCollectors\t--\t$recordNumber\t--\t$id\n");
		}		
		
	if($recordedBy=~/^([A-Z]\.? [A-Z]?\.? [[A-Z][a-z]+).? (\d+)$/){
	#R. L. Ornduff, 3456
		$recordedBy = $1;
		$recordNumber = $2;
		&log("Collector modified15: $recordedBy\t--\t$associatedCollectors\t--\t$recordNumber\t--\t$id\n");
		}
	
		if(($recordedBy=~/^([A-Z][a-z]+[A-Z][a-z]*) +([A-Z][A-Z]?\.? ?[A-Z]?\.?); +([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#Cochrane S A; Holland J S
		$recordedBy="$2 $1";
		$associatedCollectors=$3;
		&log("Collector modified12: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}
		
		if(($recordedBy=~/^([A-Z][a-z]+[A-Z][a-z]*), +([A-Z][a-z]*\.? ?[A-Z]?\.?)[,;&] +([\w ?;?,?\.?'? ?]{1,})/) && (length($associatedCollectors) == 0)){
	#McCaskill, J; Tucker, J.
	#Everett, P.C.; Johnson, E.R.
	#Everett, P.C.& Johnson, E.R.
		$recordedBy="$2 $1";
		$associatedCollectors=$3;
		&log("Collector modified13: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}

	if(($recordedBy=~/^([A-Z][a-z]+[A-Z]*[a-z]*), ([A-Z][a-z]+ [A-Z][a-z]+ ?[A-Z]+[a-z]*.?)/) && (length($associatedCollectors) == 0)){
	#Cuddihy, Sister Mary Agnes
		$recordedBy="$2 $1";
		&log("Collector modified14: $recordedBy\t--\t$associatedCollectors\t$id\n");
		}
	}	

}


	

#s/ \./. /g;
#	s/, & /, /g;
#	s/ & /, /g;

#		s/\.,/./g;
#		s/^ *//g;
#		s/ *$//g;
#		s/; /, /g;
#		s/ +/ /g;
#		
 
#if($recordedBy=~s/; (.*)//){ # if $recordedBy contains a semicolon followed by a space then anything else, replace it with ""...
#$otherColl=$1;	#set the content after the semicolon to $otherColl
#}
#else{
#$otherColl=""; #otherwise #otherColl is blank.
#}

######################Other Collectors

foreach($associatedCollectors){

	unless ($associatedCollectors =~ m/cC|eD|et al/){
		$associatedCollectors =~ s/(\w+)/\u\L$1/g;
	}
	
	unless ($associatedCollectors =~ m/et al/){	
		$associatedCollectors =~ s/^([A-Z])([a-z]) /$1 \u$2 /g;		
	}

}

######################Unknown County List

	if($county=~m/unknown|Unknown/){	#list each $county with unknown value
		&log("COUNTY unknown -> $stateProvince\t--\t$county\t--\t$locality\t$id");		
	}


#####################ELEVATION
foreach( $verbatimElevation){
	s/ [eE]lev.*//;	#remove trailing content that begins with [eE]lev
	s/feet/ft/;	#change feet to ft
	s/\d+ *m\.? \((\d+).*/$1 ft/;
	s/\(\d+\) \((\d+).*/$1 ft/;
	s/'/ft/;	#change ' to ft
	s/FT/ft/;	#change FT to ft
	s/Ft/ft/;	#change Ft to ft
	s/- *ft/ft/;
	s/meters/m/;
	s/[Mm]\.? *$/m/;	#substitute M/m/M./m., followed by anything, with "m"
	s/ft?\.? *$/ft/;	#subst. f/ft/f./ft., followed by anything, with ft
	s/ft/ ft/;		#add a space before ft
	s/m *$/ m/;		#add a space before m
	s/  / /g;		#collapse consecutive whitespace as many times as possible
}

##########################OTHER LABEL NUMBERS
foreach($catalogNumber){

	if((length($catalogNumber) == 0) && ($otherCatalogNumbers=~m/^[A-Z]*\d+[A-Z]*/)){
		$catalogNumber="$otherCatalogNumbers";
		&log("Catalog Number Modified1: $id\n");
	}
	
	if((length($catalogNumber) == 0) && ($otherCatalogNumbers=~m/^\d+$/)){
		$catalogNumber="$institutionCode$otherCatalogNumbers";
		&log("Catalog Number Modified2: $id\n");
	}	
	
	if(($catalogNumber=~m/^\d+$/) && (length($otherCatalogNumbers) == 0)){
		$catalogNumber="$institutionCode$catalogNumber";
		&log("Catalog Number Modified3: $id\n");
	}
	
	if((length($catalogNumber) == 0) && (length($otherCatalogNumbers) == 0)){
		$catalogNumber="$institutionCode";
		&log("Catalog Number Modified4: $id\n");
	}

	
	if(($catalogNumber=~m/^[A-Z]*-?[A-Z]?-?\d+[A-Z]*/) && ($otherCatalogNumbers=~m/^\d+$/)){
		$catalogNumber="$institutionCode$otherCatalogNumbers";
		&log("Catalog Number Modified5: $id\t--\t$catalogNumber\n");
	}
	
	if(($catalogNumber=~m/^\d+$/) && ($otherCatalogNumbers=~m/^[A-Z]+-?\d+[A-Z]*.*/)){
		$catalogNumber="$institutionCode$catalogNumber";
		&log("Catalog Number Modified6: $id\n");
	}	
	
	if(($catalogNumber=~m/^[A-Z]*-?[A-Z]?-?\d+[A-Z]*/) && ($otherCatalogNumbers=~m/^[A-Z]+-?\d+[A-Z]*.*/)){
		&log("Catalog Number NOT Modified: $id\t--\t$catalogNumber\n");
	}	
}

unless($IMAGE{"SEINET$id"}){	#unless an $IMAGE (i.e. image URL) exists for a given SEINET$id
$IMAGE{"SEINET$id"}="";	#$image is set to blank
}
unless($ANNO{"SEINET$id"}){
$ANNO{"SEINET$id"}="";
}


			print OUT <<EOP;
Accession_id: SEINET$id
Other_label_numbers: $catalogNumber
Name: $scientificName
Date: $eventDate
EJD: $JD
LJD: $LJD
CNUM: $CNUM
CNUM_prefix: $PREFIX
CNUM_suffix: $SUFFIX
Country: $country
State: $stateProvince
County: $county
Location: $municipality $locality
T/R/Section: 
Elevation: $verbatimElevation
Collector: $recordedBy
Other_coll: $associatedCollectors
Combined_coll: 
Habitat: $Habitat
Associated_species: $associatedTaxa
Notes: $informationWithheld $fieldNotes $occurrenceRemarks
Color: $color
Type_status: $typeStatus
Macromorphology: $Description
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
UTM: $UTM
Source: $georeferenceSources
Datum: $geodeticDatum
Max_error_distance: $coordinateUncertaintyInMeters
Cultivated: $cult
Image: $IMAGE{"SEINET$id"}
Annotation: $ANNO{"SEINET$id"}

EOP
}

sub skip {	#for each skipped item...
	print ERR "skipping: @_\n"	#print into the ERR file "skipping: "+[item from skip array]+new line
}
sub log {	#for each logged change...
	print ERR "logging: @_\n";	#print into the ERR file "logging: "+[item from log array]+new line
}
