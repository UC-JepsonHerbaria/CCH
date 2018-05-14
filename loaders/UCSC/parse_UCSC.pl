open(OUT, ">ucsc.out") || die;
open (IN, "/users/jfp04/data/CDL/collectors_id") || die;
while(<IN>){
chomp;
($coll,$coll_code)=split(/\t/);
$coll_code{$coll}=$coll_code;
}
open (IN, "/users/jfp04/data/CDL/tnoan.out") || die;
while(<IN>){
chomp;
($tid,$name)=split(/\t/);
$tnoan{$name}=$tid;
}
while(<>){
s/\cK//g;
chomp;
s/ *\t/\t/g;
s/\t */\t/g;
s/\xD2/"/g;
s/\xD3/"/g;
s/\xD5/'/g;
s/\xD4/'/g;
(
$City,
$Collector,
$Country,
$County,
$Date_collected,
$Elevation,
$Extra_orig_desc,
$JepsMan_family,
$JepsMan_namer,
$Latitude,
$Longitude,
$RM_JepsMan_author,
$RM_JepsMan_name,
$RM_orig_desc,
$RM_orig_loc,
$RM_orig_name,
$RM_orig_name_author,
$State,
$UCSC_access_no,
$UTM,
)=split(/\t/);
foreach($Collector){
s/  */ /g;
s/P Holleran/P. Holleran/;
}
print "$Collector\n" unless $coll_code{$Collector};
foreach($RM_JepsMan_name, $RM_orig_name){
s/ *$//;
s/^ *//;
s/ +/ /;
s/ sp\.?$//;
s/ ?\?.*//;
s/^ *$/UNDETERMINED/;
s/^` *$/UNDETERMINED/;
s/Deschamspia danthonioides/Deschampsia danthonioides/;
s/Equisetum x ferrissii/Equisetum ◊ ferrissii/;
s/Equisetum Å~ferrissii/Equisetum ◊ ferrissii/;
s/Erechtites glomerata/Erechtites glomeratus/;
s/Gnaphalium luteoalbum/Pseudognaphalium luteoalbum/;
s/Gnaphalium sp. and Gnaphalium palustre Nutt./Gnaphalium palustre/;
s/Juncus bufonius L., Juncus capitatus/Juncus bufonius/;
s/Lasthenis/Lasthenia/;
s/Piperia elegans decurtata, P. elegans/Piperia elegans/;
s/Piperia transversa Suksd. , Piperia colemanii Rand. Morgan & Glicenstein/Piperia colemanii/;
s/Piperia transversa Suksdorf, Piperia colemanii R. Morgan & Glicenstein/Piperia colemanii/;
s/Plagiobothyrus chorisianus/Plagiobothrys chorisianus/;
s/Quercus x morehus/Quercus ◊ morehus/;
s/Unidentified grass/Poaceae/;
}
#print "$RM_JepsMan_name\n" unless $tnoan{$RM_JepsMan_name};
#print "$RM_orig_name\n" unless $tnoan{$RM_orig_name};
foreach($County){
s/Probably Santa Cruz/Santa Cruz/;
s/San Bernadino/San Bernardino/;
s/San Jose/Santa Clara/;
s/San Luis Obisbo/San Luis Obispo/;
s/ Co\.//;
s/Santa Rosa/Sonoma/;
s/Saratoga/Santa Clara/;
s/St anislaus/Stanislaus/;
s/^ *$/Unknown/;
}
if ($State=~/California/){
$State="CA";
}
elsif ($State=~/Oregon/){
$State="OR";
}
else{
$State="Unknown";
}
$UCSC_access_no=~s/ //g;
$UCSC_access_no=~s/^/UCSC/ unless $UCSC_access_no=~/UCSC/;
$Elevation=~s/ elevation//i;
if($City){
$Location="$City: $Location";
}
$Latitude="${Latitude}N" if $Latitude;
$Longitude="${Longitude}W" if $Longitude;
$Date_collected="" if $Date_collected=~/^Unk/i;
foreach($Date_collected){
s/\? Aug 1981/Aug 1981/;
s/\? Oct 1978/Oct 1978/;
s/Late Jan\.? 1979/Jan 1979/;
s/coll. 1983, pressed 7 Sep 1991/1983/;
s/mid\.? Feb 1977/Feb 1977/;
s/Jun 1978\?/Jun 1978/;
}
print OUT <<EOP;
Accession_id: $UCSC_access_no
Date: $Date_collected
CNUM: 
CNUM_prefix: 
CNUM_suffix: 
Name: $RM_JepsMan_name
Country: USA
State: $State
County: $County
Location: $RM_orig_loc
T/R/Section: 
Elevation: $Elevation
Collector: $Collector
Other_coll: 
Combined_coll: 
Habitat: $Extra_orig_desc
Associated_species: 
Color: 
Latitude: ${Latitude}
Longitude: ${Longitude}
Decimal_latitude: 
Decimal_longitude: 
Annotation: 
Macromorphology: $RM_orig_desc
Notes: 

EOP

}


