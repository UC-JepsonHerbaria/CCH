#useful one liners for debugging:
#perl -lne '$a++ if /Accession_id: UC\d+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Accession_id: JEPS\d+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Accession_id: UCLA\d+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Accession_id: HREC\d+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Accession_id: BFRS\d+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Accession_id:/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Decimal_latitude: \d+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Macromorphology: .+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Habitat: .+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Population_biology: .+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Reproductive_biology: .+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Other_data: .+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Color: .+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Notes: .+/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Cultivated: P/; END {print $a+0}' CSPACE_out.txt
#perl -lne '$a++ if /Cultivated: [^P]+/; END {print $a+0}' CSPACE_out.txt

#perl -lne '$a++ if /Accession_id: UCLA\d+/; END {print $a+0}' CSPACE_out.txt

#use utf8;
use Geo::Coordinates::UTM;
use strict;
#use warnings;
use lib '/JEPS-master/Jepson-eFlora/Modules';
use CCH; #load non-vascular hash %exclude, alter_names hash %alter, and max county elevation hash %max_elev
use utf8; #use only when original has problems with odd character substitutions
use Text::Unidecode;

my $today_JD;

$| = 1; #forces a flush after every write or print, so the output appears as soon as it's generated rather than being buffered.

$today_JD = &get_today_julian_day;
&load_noauth_name; #loads taxon id master list into an array

my %month_hash = &month_hash;
my %count_record;
my $count_record;

#log.txt is used by logging subroutines in CCH.pm
my $error_log = "log.txt";
unlink $error_log or warn "making new error log file $error_log";

####INSERT NAMES OF CSPACE FILES and assign variables
my $date_dir = "JUN18_2018"; #directory date of the unzipped file, change when new upload is unzipped

my $extract_dir= "/JEPS-master/CCH/Loaders/CSPACE/data_files/$date_dir/";
my $home_dir= "/JEPS-master/CCH/Loaders/CSPACE/data_files/$date_dir/home/app_webapps/extracts/cch/current";

my $hybrid_file="${home_dir}/cch_hybridparents.txt";
my $other_vouchers="${home_dir}/cch_othervouchers.txt";
my $anno_vouchers="${home_dir}/cch_annovouchers.txt";
my $types="${home_dir}/cch_typespecimens.txt";
my $determinations="${home_dir}/cch_determinations.txt";
my $accessions="${home_dir}/cch_accessions.txt";
my $solr_file="${extract_dir}/4solr.ucjeps.public.csv";
my $media_file="${extract_dir}/4solr.ucjeps.media.csv";


my $included;
my %skipped;
my %skipped_nonvasc;
my $line_store;
my $count;
my $seen;
my %seen;
#unique to this dataset
my %voucher_tags;
my $voucher;
my %habitat;
my $habitat;
my $solr_group;
my $accession;
my $solr_country;
my $solr_state;
my $solr_county;
my $solr_locality;
my $det_string;
my $ANNO;
my %ANNO;
my %COUNTRY;
my %COUNTY;
my %STATE;
my %CULT;
my %UNITS;
my %ELEV;
my @hfields;	
my $hfields;	
my $next_parent;	
my $hybrid;
my %hybrid;
my $t_csid;
my $det_orig;
my $otherdata;
my $othernotes;
my $other_description;
my $phenology;
my $reproductive_biology;
my $population_biology;
my $macromorphology;
my %otherdata;
my %othernotes;
my %other_description;
my %S_habitat;
my $S_habitat;
my %reproductive_biology;
my %population_biology;
my %phenology;
my %macromorphology;
my %micromorph;
my $micromorph;
my $color_note;
my %color_note;
my $odor;
my $odor_note;
my %odor_note;
my $horticulture;
my %horticulture;
my $cytology;
my %cytology;
my $NAME;
my %NAME;
my $solr_name;
my $temp_name;

open(IN,"$hybrid_file") || die "couldnt open $hybrid_file $!";
while(<IN>){
	chomp;
	#catalognumber	pos	hybridparentname	hybridparentqualifier

        if ($. == 1){#activate if need to skip header lines
			next;
		}

	s/×/X /g;  #this odd code may be correcting oddly using the unidecode

$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8


#fix some data quality and formatting problems	

		s/&apos;/'/g;			#UC1871063

		s/«//g;
		
	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ê/e/g;

	s/ä/a/g;
	s/á/a/g;
	s/í/i/g;
	s/ú/u/g;
	s/ń/n/g;				
	s/ñ/n/g;

	s/µ/u/g;
		s/Á/ /g;
		s/Â/ /g;

		s/â€šÃ„Ã®/ /g;
		s/â/ /g;
		s/±/+-/g;	#JEPS105676	JEPS102219UC1731225	
		s/¼/ 1\/4 /g;	
		s/½/ 1\/2 /g;	
		s/¾/ 3\/4 /g;	
		s/⅓/ 1\/3 /g;
		s/⅓/ 1\/3 /g;
		s/⅔/ 2\/3 /g;
		s/⅕/ 1\/5 /g;
		s/⅗/ 3\/5 /g;
		s/⅙/ 1\/6 /g;
		s/⅛/ 1\/8 /g;
		s/⅜/ 3\/8 /g;
		
		
		s/—/-/g;
		s/’/'/g;
		s/”/"/g;


	@hfields=split(/\t/);
	$hfields[3]=~s/×/ X /;
	$hfields[3]=~s/  +/ /g;
	$next_parent=&strip_name($hfields[3]);
	if($hybrid{$hfields[0]}){
		$hybrid{$hfields[0]} .= " X $next_parent";
	}
	else{
		$hybrid{$hfields[0]} = $next_parent;
	}

foreach (sort(keys(%hybrid))){
#print "$_: $hybrid{$_}\n";
}

}
#die;
#list of accession numbers to be skipped because they are photographs or are hort vouchers from several counties
#the right way to do this would be to
#1) have all these properly indicated as being photographs and hort vouchers in CCH
#2) export the "Cultivated" and "Form" stuff to CCH extract (or exclude photographs at that point
#3) export cultivated = yes to be used in CCH.
#open(IN,"_excl") || die;
#while(<IN>){
#	chomp;
#	$hort{$_}++;
#}

%voucher_tags=(
				"other note" => "Notes",
				"other data" => "Other_data",
				"other desc" => "Other_desc",
				"micromorphology" => "Micromorphology",
				"macromorphology" => "Macromorphology",
				"cytology" => "Cytology",
				"reproductive biology" => "Reproductive_biology",
				"population biology" => "Population_biology",
				"phenology" => "Phenology",
				"horticulture" => "Horticulture",
				"biotic interactions" => "Biotic_interactions",
				"associated taxa" => "Associated_species",
				"Vegetation Type Map" => "VTM",
				"color" => "Color",
				"odor" => "Odor"
);


#JEPS13972	Isotype	Saxifraga fragarioides Greene	W. L. J.
#JEPS14006	Type	Eryngium racemosum Jeps.	unknown
#List of type specimens

my $type_id;	
my %TYPE;
my $TYPE;
my $tt;
my $bn;
my $ref;
my $store_voucher;
my %store_voucher;



open(IN, $types) || die;
while(<IN>){
	chomp;
#		&CCH::check_file;
#		s/\cK/ /g;
#        if ($. == 1){	#activate if need to skip header lines
#			next;
#		}

	s/×/X /g;  #this odd code may be correcting oddly using the unidecode

$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8



#fix some data quality and formatting problems	

	
	
	($type_id,$t_csid,$tt,$bn,$ref)=split(/\t/);
	$TYPE{$t_csid}{$tt}=$bn;
}

#Transfer to TYPE hash
foreach $t_csid(keys(%TYPE)){
	if($TYPE{$t_csid}{'Holotype'}){
		$store_voucher{$t_csid}{TYPE}= "Holotype: $TYPE{$t_csid}{'Holotype'}";
	}
	elsif($TYPE{$t_csid}{'Isotype'}){
		$store_voucher{$t_csid}{TYPE}= "Isotype: $TYPE{$t_csid}{'Isotype'}";
	}
	elsif($TYPE{$t_csid}{'Lectotype'}){
		$store_voucher{$t_csid}{TYPE}= "Lectotype: $TYPE{$t_csid}{'Lectotype'}";
	}
	elsif($TYPE{$t_csid}{'Isolectotype'}){
		$store_voucher{$t_csid}{TYPE}= "Isolectotype: $TYPE{$t_csid}{'Isolectotype'}";
	}
	elsif($TYPE{$t_csid}{'Neotype'}){
		$store_voucher{$t_csid}{TYPE}= "Neotype: $TYPE{$t_csid}{'Neotype'}";
	}
	elsif($TYPE{$t_csid}{'Isoneotype'}){
		$store_voucher{$t_csid}{TYPE}= "Isoneotype: $TYPE{$t_csid}{'Isoneotype'}";
	}
	elsif($TYPE{$t_csid}{'Epitype'}){
		$store_voucher{$t_csid}{TYPE}= "Epitype: $TYPE{$t_csid}{'Epitype'}";
	}
	elsif($TYPE{$t_csid}{'Isoepitype'}){
		$store_voucher{$t_csid}{TYPE}= "Isoepitype: $TYPE{$t_csid}{'Isoepitype'}";
	}
	elsif($TYPE{$t_csid}{'Type'}){
		$store_voucher{$t_csid}{TYPE}= "Type: $TYPE{$t_csid}{'Type'}";
	}
	elsif($TYPE{$t_csid}{'Non-type'}){
		$store_voucher{$t_csid}{TYPE}= "Not a Type: $TYPE{$t_csid}{'Non-type'}";
	}
	elsif($TYPE{$t_csid}{'Syntype'}){
		$store_voucher{$t_csid}{TYPE}= "Syntype: $TYPE{$t_csid}{'Syntype'}";
	}
	elsif($TYPE{$t_csid}{'Isosyntype'}){
		$store_voucher{$t_csid}{TYPE}= "Isosyntype: $TYPE{$t_csid}{'Isosyntype'}";
	}
	elsif($TYPE{$t_csid}{'Cotype'}){
		$store_voucher{$t_csid}{TYPE}= "Cotype: $TYPE{$t_csid}{'Cotype'}";
	}
	elsif($TYPE{$t_csid}{'Unspecified type'}){
		$store_voucher{$t_csid}{TYPE}= "Unspecified type: $TYPE{$t_csid}{'Unspecified type'}";
	}
	elsif($TYPE{$t_csid}{'Fragment'}){
		$store_voucher{$t_csid}{TYPE}= "Type fragment: $TYPE{$t_csid}{'Fragment'}";
	}
}
 #96 Cotype
 #376 Unspecified type

close(IN);
#named vouchers from list of annotations


my $annid;
my $ann_csid;
my $type;
my $desc;
my $store_voucher;
my $VK;
my %store_voucher;
my %VK;

open(IN, "$anno_vouchers") || die;
while(<IN>){
	chomp;

#        if ($. == 1){	#activate if need to skip header lines
#			next;
#		}

	s/×/X /g;  #this odd code may be correcting oddly using the unidecode

$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8


#fix some data quality and formatting problems	

}
my %VK=();
warn "=========\n";

#vouchers stuck in notes field

my $other_id;
my $other_csid;
my $notetype;
my $note;
my %note;
my @includes;
my $store_voucher;
my %store_voucher;
my $VK;
my $i;
my $voucher_tags;
my $desc;
my $color;
my $macro;
my $other;
my $biology;
my $pop;
my $phen;
my $cyt;
my $micro;
my $hort;


open(IN, "$other_vouchers") || die;
while(<IN>){
#		&CCH::check_file;
#		s/\cK/ /g;
#        if ($. == 1){	#activate if need to skip header lines
#			next;
#		}

	s/×/X /g;  #this odd code may be correcting oddly using the unidecode

$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8



#fix some data quality and formatting problems	
		s/♂/ male /g;	
		s/♀/ female /g;	
		s/…/./;

	s/»/>>/g;
		s/≤/<=/g;
			s/≥/>=/g;
		#s/º/ deg. /g;	#masculine ordinal indicator used as a degree symbol
		#s/°/ deg. /g;
		#s/˚/ deg. /g;
	s/ø/o/g;
	s/ö/o/g;
	s/õ/o/g;

	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ê/e/g;

	s/ä/a/g;
	s/á/a/g;
	s/í/i/g;
	s/ú/u/g;
	s/ü/u/g;	#U+00FC	ü	\xc3\xbc
	s/ñ/n/g;	
		s/–/--/g;	
		s/—/--/g;
		s/`/'/g;		
		s/‘/'/g;
		s/’/'/g;
		s/”/'/g;
		s/“/'/g;
		s/”/'/g;
		s/±/+-/g;	#JEPS105676	JEPS102219UC1731225
		s/²/ squared /g;
		s/¹/ /g;
		
		s/¼/ 1\/4 /g;	
		s/½/ 1\/2 /g;	
		s/¾/ 3\/4 /g;	

		s/«//g;
		
	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ê/e/g;

	s/ä/a/g;
	s/á/a/g;
	s/í/i/g;
	s/ú/u/g;
	s/ń/n/g;				
	s/ñ/n/g;

	s/µ/u/g;
		s/Á/ /g;
		s/Â/ /g;

		s/â€šÃ„Ã®/ /g;
		s/â/ /g;
		s/±/+-/g;	#JEPS105676	JEPS102219UC1731225	
		s/¼/ 1\/4 /g;	
		s/½/ 1\/2 /g;	
		s/¾/ 3\/4 /g;	
		s/⅓/ 1\/3 /g;
		s/⅓/ 1\/3 /g;
		s/⅔/ 2\/3 /g;
		s/⅕/ 1\/5 /g;
		s/⅗/ 3\/5 /g;
		s/⅙/ 1\/6 /g;
		s/⅛/ 1\/8 /g;
		s/⅜/ 3\/8 /g;
		
		
		s/—/-/g;
		s/’/'/g;
		s/”/"/g;

	($other_id,$other_csid,$notetype,$note)=split(/\t/);
											#next unless $id eq "JEPS2760";
	if($notetype eq "habitat"){
		$S_habitat{$other_csid}{$notetype}=$note;
		$note="";
	}
	elsif($notetype eq "brief description"){	
		if($note =~ m/includes/){	
#includes reproductive biology: ; includes phenology: ; color:	
			@includes=split(/;/,$note);
			foreach $i (0 .. $#includes){
				if($includes[$i]=~s/includes (reproductive biology): *([0-9A-Za-z- ,.\/]+)//){
					$biology = $2;
					$type = $voucher_tags{$1};
					$reproductive_biology{$other_csid}{$notetype} = $biology;
					$VK{$type}++;
				}
				elsif($includes[$i]=~s/includes (macromorphology): *([0-9A-Za-z- ,.\/]+)//){
					$macro = $2;
					$type = $voucher_tags{$1};
					$macromorphology{$other_csid}{$notetype} = $macro;
					$VK{$type}++;
				}
				elsif($includes[$i]=~s/(color): *([0-9A-Za-z- ,.\/]+)//){
					$color = $2;
					$type = $voucher_tags{$1};
					$color_note{$other_csid}{$notetype} = $color;
					$VK{$type}++;
				}
				elsif($includes[$i]=~s/(odor): *([0-9A-Za-z- ,.\/]+)//){
					$odor = $2;
					$type = $voucher_tags{$1};
					$odor_note{$other_csid}{$notetype} = $odor;
					$VK{$type}++;
				}
				elsif($includes[$i]=~s/(odor):? ?//){
					$color = $2;
					$type = $voucher_tags{$1};
					$color_note{$other_csid}{$notetype} = $color;
					$VK{$type}++;
				}
				elsif($includes[$i]=~s/includes ([a-z]+): *([0-9A-Za-z- ,.\/]+)//){
					$other = $2;
					$other =~ s/^ //;
					$other =~ s/ $//;
					$other =~ s/^ +$//;
					$type = $voucher_tags{$1};
					
					if($type =~ m/cytology/i){
						$cyt = $other;
						$cytology{$other_csid}{$notetype} = $cyt;
						$VK{$type}++;
					}
					elsif($type =~ m/phenology/i){
							$phen = $other;
							$phen =~ s/\//,/;
							$phen =~ s/,/, /;
							$phen =~ s/  +/ /;
							$phenology{$other_csid}{$notetype} = $phen;
							$VK{$type}++;
					}
					elsif($type =~ m/micromorphology/i){
							$micro = $other;
							$micromorph{$other_csid}{$notetype} = $micro;
							$VK{$type}++;
					}
					elsif($type =~ m/horticulture/i){
							$hort = $other;
							$horticulture{$other_csid}{$notetype} = $hort;
							$VK{$type}++;
					}
					elsif($other =~ m/\d?[nN]-?\d*/i){
						$type = "Cytology";
						$cyt = $other;
						$cytology{$other_csid}{$notetype} = $cyt;
						$VK{$type}++;
					}
					elsif(length($other) >= 3){
						$type = "Other_data";
						$otherdata{$other_csid}{$notetype} = $other;
						$VK{$type}++;
					}
					elsif(length($other) == 0){
						next;
					}
					else{
						print "brief descriptions found, but not parsed\t($type==>$other==>$other_csid)\n";
						$note="";
					}
				}
				else{
					$includes[$i] =~ s/^ //;
					$includes[$i] =~ s/ $//;
					$includes[$i] =~ s/^ +$//;
					
					if($includes[$i]!~m/includes ([a-z]+): */){
						if($includes[$i]=~m/([0-9A-Za-z- ,.\/]+)+/){
							if($includes[$i]=~s/ ?(color): *([0-9A-Za-z- ,.\/]+)//){
								$color = $2;
								$type = $voucher_tags{$1};
								$color_note{$other_csid}{$notetype} = $color;
								$VK{$type}++;
							}
							elsif($includes[$i]=~s/ ?(odor): *([0-9A-Za-z- ,.\/]+)//){
								$odor = $2;
								$type = $voucher_tags{$1};
								$odor_note{$other_csid}{$notetype} = $odor;
								$VK{$type}++;
							}
							else{
							$pop = $includes[$i];
							$type = "Population_biology";
							$population_biology{$other_csid}{$notetype} = $pop;
							$VK{$type}++;
							}
						}
					}
					elsif($includes[$i]=~s/^ ?[;:.,] ?$//){
						$includes[$i]=$note="";
					}
					elsif(length($includes[$i]) > 1){
						$includes[$i] =~ s/includes reproductive biology:? *;?//;
						$includes[$i] =~ s/includes macromorphology:? *;?//;
						$includes[$i] =~ s/includes horticulture:? *;?//;
						$includes[$i] =~ s/includes associated taxa:? *;?//;
						$includes[$i] =~ s/includes map:? *;?//;
						$includes[$i] =~ s/includes color:? *;?//;
						$includes[$i] =~ s/includes odor:? *;?//;
						$includes[$i] =~s/includes photograph:? *;?//;
						$includes[$i] =~s/includes common name:? *;?//;
						$includes[$i] =~s/includes cytology:? *;?//;
						$includes[$i] =~s/includes illustration:? *;?//;
						$includes[$i] =~s/  +/ /;
						$pop = $includes[$i];
						$type = "Population_biology";
						$population_biology{$other_csid}{$notetype} = $pop;
						$VK{$type}++;
					}
					else{
						print "unexpected brief description\t$includes[$i]\t$other_csid\n";
						$note="";
					}	
				}
			}
		}
		else{
			foreach ($note){
			s/[,:;]$//g;
			#s/^[a-zA-Z-]$//g;
			s/: *$//g;
			s/  +/ /g;
			s/^ +$//g;
			s/^ +//g;
			s/ +$//g;
			}
			$note=~s/county supplied by Wetherwax;? */county interpreted by Wetherwax; /;
			$note=~s/data in packet:? *;?//;
			$note=~s/odor:? *;?//;
			$note=~s/includes map:? *;?//;
			$note=~s/includes associated taxa:? *;?//;
			$note=~s/includes photograph:? *;?//;
			$note=~s/includes common name:? *;?//;
				if($note=~s/(color): *([0-9A-Za-z- ,.\/]+)//){
					$color = $2;
					$type = $voucher_tags{$1};
					$color_note{$other_csid}{$notetype} = $color;
					$VK{$type}++;
				}
				elsif($note=~s/(odor): *([0-9A-Za-z- ,.\/]+)//){
					$odor = $2;
					$type = $voucher_tags{$1};
					$odor_note{$other_csid}{$notetype} = $odor;
					$VK{$type}++;
				}
				elsif(length($note) >= 3){
					$desc = $note;
					$type = "Other_desc";
					$other_description{$other_csid}{$notetype} = $desc;
					$VK{$type}++;
				}
				elsif(length($other) == 0){
						next;
					}
				else{
					print "unexpected notes in brief description\t$note\t$other_csid\n";
					$note="";
				}
		}
	}
	elsif($notetype eq "comment"){
		$note=~s/county supplied by Wetherwax;? */county interpreted by Wetherwax; /;
		$note=~s/data in packet:? *;?//;
		$note=~s/odor:? *;?//;
		$note=~s/includes associated taxa:? *;?//;
		$note=~s/includes photograph:? *;?//;
		$note=~s/includes map:? *;?//;
		$note=~s/includes illustration:? *;?//;
		$note=~s/includes common name:? *;?//;
		$type = "Notes";
		$othernotes{$other_csid}{$notetype} = $note;
		$VK{$type}++;
	}
	else{
		#unexpected note type?
		print "unexpected note type\t$_\n";
		$note="";
	}
#	$note{$other_csid}=$note unless $note{$other_id};
}
close(IN);


foreach $voucher (sort(keys(%VK))){
		warn "$voucher: $VK{$voucher}";
}

warn "=========\n\n\n";

##########GET IMAGE LINKS FROM CSPACE PUBLIC PORTAL SOLR DUMP

my $IMG;
my %IMG;
my @solr_fields;
my $solr_fields;
my $solr_csid;
my $solr_blob;


open(IN, "$solr_file") || die;
while(<IN>){
	my $solr_blob="";
	chomp;
#		&CCH::check_file;
#		s/\cK/ /g;
#        if ($. == 1){	#activate if need to skip header lines
#			next;
#		}

	s/×/X /g;  #this odd code may be correcting oddly using the unidecode

$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8



#fix some data quality and formatting problems	
	 
	@solr_fields=split(/\t/,$_,100);

#The number of fields in the solr core changes over time as more fields are added
#however the image_blob field has always been last, and csid should remain in position [1]
	$solr_csid = $solr_fields[1];
    $solr_group=$solr_fields[5];
	$solr_blob = $solr_fields[$#solr_fields];
		next unless $solr_blob;
		next if ($solr_group =~ /(Algae|Bryophytes|Fungi|Lichen)/);

if ($solr_blob =~ /(.*),(.*)/){
	$solr_blob = $1
}
else {
	($solr_blob = $solr_blob);
}

#$IMG{$solr_csid} = "https://ucjeps.cspace.berkeley.edu/ucjeps_project/imageserver/blobs/$solr_blob/derivatives/OriginalJpeg/content"; #old url? from 2016?, does not work anymore
$IMG{$solr_csid} = "https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/$solr_blob/derivatives/OriginalJpeg/content";
}
close(IN);

##########Annotations
my $Accession_Number;
my $ACCcsid;
my $Accession_Number;
my $det_AID;
my $det_date;
my $det_rank;
my $det_name;
my $det_determiner;
my $det_date;
my $det_stet;
my $ID_Kind;
my $ACCNotes;

open(IN, "$determinations") || die;
#annotation history
while(<IN>){
	$det_string="";
next if m/bulkloaded from norris/;
next if m/D\. *H\. Norris/;
	chomp;

#		s/\cK/ /g;
#        if ($. == 1){	#activate if need to skip header lines
#			next;
#		}

	s/×/X /g;  #this odd code may be correcting oddly using the unidecode

$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8



#fix some data quality and formatting problems	

s/♀/female/g;#UC1980521
s/♂/male/g;#UC1980521
		s/…/./;

	s/»/>>/g;
		s/≤/<=/g;
			s/≥/>=/g;
		#s/º/ deg. /g;	#masculine ordinal indicator used as a degree symbol
		#s/°/ deg. /g;
		#s/˚/ deg. /g;
	s/ø/o/g;
	s/ö/o/g;
	s/õ/o/g;

	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ê/e/g;

	s/ä/a/g;
	s/á/a/g;
	s/í/i/g;
	s/ú/u/g;
	s/ü/u/g;	#U+00FC	ü	\xc3\xbc
	s/ñ/n/g;	
		s/–/--/g;	
		s/—/--/g;
		s/`/'/g;		
		s/‘/'/g;
		s/’/'/g;
		s/”/'/g;
		s/“/'/g;
		s/”/'/g;
		s/±/+-/g;	#JEPS105676	JEPS102219UC1731225
		s/²/ squared /g;

		s/&apos;/'/g;			#UC1871063

		s/«//g;
		
	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ê/e/g;

	s/ä/a/g;
	s/á/a/g;
	s/í/i/g;
	s/ú/u/g;
	s/ń/n/g;				
	s/ñ/n/g;

	s/µ/u/g;

		s/±/+-/g;	#JEPS105676	JEPS102219UC1731225	
		s/¼/ 1\/4 /g;	
		s/½/ 1\/2 /g;	
		s/¾/ 3\/4 /g;	
		s/⅓/ 1\/3 /g;
		s/⅓/ 1\/3 /g;
		s/⅔/ 2\/3 /g;
		s/⅕/ 1\/5 /g;
		s/⅗/ 3\/5 /g;
		s/⅙/ 1\/6 /g;
		s/⅛/ 1\/8 /g;
		s/⅜/ 3\/8 /g;
		
		
		s/—/-/g;
		s/’/'/g;
		s/”/"/g;

	
#UC179656	c023d60a-b0d1-4399-a016-a52e563ce56a	1	Calycadenia ciliosa Greene		unknown	 	original label determination	nocl
#UC179656	c023d60a-b0d1-4399-a016-a52e563ce56a	2	Calycadenia ciliosa Greene		D. D. Keck	1934	identification or reidentification	as "!"
	
	($Accession_Number,
	$ACCcsid,
	$det_rank,
	$det_name,
	$det_stet,
	$det_determiner,
	$det_date,
	$ID_Kind,
	$ACCNotes) = split(/\t/);
											#next unless $Accession_Number eq "JEPS2760";
	$ACCNotes=~s/ *Data Source: Accession sheet//;
	#if(m/original label/){
	#	unless(s/nocl/Identification on label/){
	#		$ACCNotes="Identification on label. $ACCNotes";
	#	}
	#}
	$ACCNotes=~s/nocl/Identification on label/;
	#print "$Notes\n" if $Notes;

	$det_rank =~ s/^0$/current determination (uncorrected)/;

foreach ($det_name,$det_name,$det_stet,$det_determiner,$det_date,$ACCNotes){
	s/  +/ /g;
	s/^ $//g;
	s/^ +//g;
	s/ +$//g;
}


	
	#format det_string correctly
	if ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($ACCNotes) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($ACCNotes) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) > 1) && (length($ACCNotes) == 0) && (length($det_stet) == 0) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_date, $det_determiner";
	}	
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($ACCNotes) == 0) && (length($det_stet) >= 1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet, $det_determiner";
	}	
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($ACCNotes) == 0) && (length($det_stet) == 0) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_date";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($ACCNotes) == 0) && (length($det_stet) == 0) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name, $det_date";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($ACCNotes) == 0) && (length($det_stet) >= 1) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name $det_stet, $det_date";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($ACCNotes) == 0) && (length($det_stet) >= 1) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name $det_stet, $det_determiner, $det_date";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($ACCNotes) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($ACCNotes) >= 1) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $det_determiner, $ACCNotes";
	}	
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($ACCNotes) >= 1) && (length($det_stet) >= 1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet, $det_determiner, $ACCNotes";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($ACCNotes) >= 1) && (length($det_stet) >= 1) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name $det_stet, det. anonymous, $ACCNotes";
	}	
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($ACCNotes) >= 1) && (length($det_stet) == 0) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name, $det_determiner, $det_date, $ACCNotes";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($ACCNotes) >= 1) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name, $ACCNotes";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($ACCNotes) >= 1) && (length($det_stet) == 0) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name, $det_date, $ACCNotes";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($ACCNotes) >= 1) && (length($det_stet) >= 1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet, $ACCNotes";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) == 0) && (length($ACCNotes) == 0) && (length($det_stet) >= 1) && (length($det_date) == 0)){
		$det_string="$det_rank: $det_name $det_stet";
	}
	elsif ((length($det_name) > 1) && (length($det_determiner) > 1) && (length($ACCNotes) >= 1) && (length($det_stet) >= 1) && (length($det_date) > 1)){
		$det_string="$det_rank: $det_name $det_stet, $det_determiner, $det_date, $ACCNotes";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) == 0) && (length($ACCNotes) >=1) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$ACCNotes";
	}
	elsif ((length($det_name) == 0) && (length($det_determiner) > 1) && (length($ACCNotes) == 0) && (length($det_stet) == 0) && (length($det_date) == 0)){
		$det_string="$det_determiner";
	}
	else{
		&log_change("det string problem:\t$det_rank: $det_name $det_stet, $det_determiner, $det_date ($ACCNotes)\n");
		$det_string="";
	}


	$ANNO{$ACCcsid}.="Annotation: $det_string\n";
}


##########Add Country and State (to allow exclusion of Mexico specimens with missing county data, need to check if these field numbers stay the same
my @solr_fields;
my $solr_fields;
my $cultivated_s;
my $solr_elev;
my $solr_units;
my $pub_csid;


open(IN,"$solr_file") || die "couldnt open $solr_file $!";
while(<IN>){
	chomp;
#	&CCH::check_file;
#		s/\cK/ /g;
        if ($. == 1){#activate if need to skip header lines
			next;
		}

	s/×/X /g;  #this odd code may be correcting oddly using the unidecode

$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8



#fix some data quality and formatting problems	

s/°/ deg. /g;	#JEPS119456
s/º/ deg. /g;	#JEPS126506
s/½/ 1\/2 /g;	#JEPS126519
s/¼/ 1\/4 /g;	#JEPS126530
s/¾/ 3\/4 /g;	#JEPS127029
s/⅛/ 1\/8 /g;	#JEPS127201
s/⅝/5\/8/g; #JEPS127052 about 2 ⅝ miles 

		s/&apos;/'/g;			#UC1871063

		s/«//g;
		
	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ê/e/g;

	s/ä/a/g;
	s/á/a/g;
	s/í/i/g;
	s/ú/u/g;
	s/ń/n/g;				
	s/ñ/n/g;

	s/µ/u/g;

		s/±/+-/g;	#JEPS105676	JEPS102219UC1731225	
		s/¼/ 1\/4 /g;	
		s/½/ 1\/2 /g;	
		s/¾/ 3\/4 /g;	
		s/⅓/ 1\/3 /g;
		s/⅓/ 1\/3 /g;
		s/⅔/ 2\/3 /g;
		s/⅕/ 1\/5 /g;
		s/⅗/ 3\/5 /g;
		s/⅙/ 1\/6 /g;
		s/⅛/ 1\/8 /g;
		s/⅜/ 3\/8 /g;
		
		
		s/—/-/g;
		s/’/'/g;
		s/”/"/g;


	 
        @solr_fields=split(/\t/, $_,100);
        $solr_group=$solr_fields[5];
        $pub_csid=$solr_fields[1];
        $accession=$solr_fields[2];
        $solr_country=$solr_fields[16];
        $solr_state=$solr_fields[15];
        $solr_county=$solr_fields[14];
        $solr_locality=$solr_fields[13];
        $solr_elev=$solr_fields[17];
        $solr_units=$solr_fields[20];
        $cultivated_s = $solr_fields[45];
        $solr_name = $solr_fields[3];
        
		#next unless ($solr_country =~ /Mexico/);
		#next unless ((length($solr_county) == 0) || 
		next if ($solr_group =~ /(Algae|Bryophytes|Fungi|Lichen)/);
}

$COUNTRY{$pub_csid}=$solr_country;
$COUNTY{$pub_csid}=$solr_county;
$STATE{$pub_csid}=$solr_state;
$NAME{$pub_csid}=$solr_name;



#$ELEV{$pub_csid}=$solr_elev;
#$UNITS{$pub_csid}=$solr_units;

####add links to other fields such as cultivated_s
$CULT{$pub_csid}=$cultivated_s;

#id	csid_s	accessionnumber_s	determination_s	termformatteddisplayname_s	family_s	taxonbasionym_s	majorgroup_s	
#collector_ss	collectornumber_s	collectiondate_s	earlycollectiondate_dt	latecollectiondate_dt	
#locality_s	collcounty_s	collstate_s	collcountry_s	elevation_s	minelevation_s	maxelevation_s	elevationunit_s	habitat_s	location_0_coordinate	location_1_coordinate	latlong_p	trscoordinates_s	datum_s	coordinatesource_s	coordinateuncertainty_f	coordinateuncertaintyunit_s	localitynote_s	localitysource_s	localitysourcedetail_s	updatedat_dt	labelheader_s	labelfooter_s	previousdeterminations_ss	localname_s	briefdescription_txt	depth_s	mindepth_s	maxdepth_s	depthunit_s	associatedtaxa_ss	typeassertions_ss	cultivated_s	sex_s	phase_s	othernumber_ss	ucbgaccessionnumber_s	determinationdetails_s	loanstatus_s	loannumber_s	collectorverbatim_s	otherlocalities_ss	alllocalities_ss	hastypeassertions_s	determinationqualifier_s	comments_ss	numberofobjects_s	objectcount_s	sheet_s	blob_ss
close(IN);



##########

open(OUT, ">CSPACE_out.txt") || die;

#foreach ($accessions){

	open(IN,$solr_file) || die;
	open(CSID, ">AID_CSID.txt") || die;
	Record: while(<IN>){
		chomp;
#
#        if ($. == 1){	#activate if need to skip header lines
#			next;
#		}
#fix some data quality and formatting problems	

	s/×/X /g;  #this odd code may be correcting oddly using the unidecode

$_ =~ s/([^[:ascii:]]+)/unidecode($1)/ge; #use only in conjunction with utf8 and unidecode to try to fix bad characters in text that is poorly converted to UTF8



s/coll.n /collection/g;	#JEPS102248
s/Douglas. spiraea/Douglas spiraea/;
s/Brewer.s oak/Brewer's oak/;
s/°/ deg. /g;	#JEPS119456
s/º/ deg. /g;	#JEPS126506
s/½/ 1\/2 /g;	#JEPS126519
s/¼/ 1\/4 /g;	#JEPS126530
s/¾/ 3\/4 /g;	#JEPS127029
s/⅛/ 1\/8 /g;	#JEPS127201
s/⅝/5\/8/g; #JEPS127052 about 2 ⅝ miles 


		s/&apos;/'/g;			#UC1871063
		s/«//g;
		
	s/ô/o/g;
	s/ó/o/g;
	s/é/e/g;
	s/è/e/g;
	s/ë/e/g;	#U+00EB	ë	\xc3\xab
	s/ê/e/g;

	s/ä/a/g;
	s/á/a/g;
	s/í/i/g;
	s/ú/u/g;
	s/ń/n/g;				
	s/ñ/n/g;

	s/µ/u/g;
		s/Á/ /g;
		s/Â/ /g;

		s/â/ /g;
		s/±/+-/g;	#JEPS105676	JEPS102219UC1731225	
		s/¼/ 1\/4 /g;	
		s/½/ 1\/2 /g;	
		s/¾/ 3\/4 /g;	
		s/⅓/ 1\/3 /g;
		s/⅓/ 1\/3 /g;
		s/⅔/ 2\/3 /g;
		s/⅕/ 1\/5 /g;
		s/⅗/ 3\/5 /g;
		s/⅙/ 1\/6 /g;
		s/⅛/ 1\/8 /g;
		s/⅜/ 3\/8 /g;

#skipping: problem character detected: s/\xc2\x92/    /g    ---> (colln	Douglas	colln	elegans?--colln	Brewers	
#skipping: problem character detected: s/\xc2\x93/    /g    ---> Service	
#skipping: problem character detected: s/\xc2\x94/    /g    ---> Service	
#skipping: problem character detected: s/\xc2\x96/    /g    ---> 656900657200	39890003989300	0(13).	
#skipping: problem character detected: s/\xc2\x97/    /g    ---> 	
#skipping: problem character detected: s/\xc2\xa0/    /g     ---> herb. Common	Erect annual	Erect annual.	
#skipping: problem character detected: s/\xc2\xa1/    /g   ¡ ---> 37¡27'14	119¡54'40	25¡	34¡	20¡	15¡	33¡	5¡	17¡	35¡	10¡	30¡	7¡	40¡	28¡	
#skipping: problem character detected: s/\xc2\xab/    /g   « ---> 7«'	N«	
#skipping: problem character detected: s/\xc2\xb1/    /g   ± ---> ±overlooking	±	
#skipping: problem character detected: s/\xc2\xb5/    /g   µ ---> µ	=25µ	=27.6µ	
#skipping: problem character detected: s/\xc3\x81/    /g   Á ---> Á.	
#skipping: problem character detected: s/\xc3\x82/    /g   Â ---> Â+-prostrate.	Â+-flat;	Â+-clay	2Â	Â+-glaucous	Â+-flat	Â+-	
#skipping: problem character detected: s/\xc3\xa1/    /g   á ---> Mártir:	Mártir.	Juárez.	Tomás.	Juárez,	Mártir	Maártir	Mártir,	Lázaro	Cárdenas.	Juárez	Juárez;	Seán	Cataviná.	
#skipping: problem character detected: s/\xc3\xa2\xc2\x80\xc2\x93/    /g   â ---> â	
#skipping: problem character detected: s/\xc3\xa2\xc2\x80\xc2\x99/    /g   â ---> muleâs-ears);	
#skipping: problem character detected: s/\xc3\xa2\xc2\x80\xc2\x9c/    /g   â ---> âsalvageâ	âplantationâ	
#skipping: problem character detected: s/\xc3\xa2\xc2\x80\xc2\x9d/    /g   â ---> âsalvageâ	âplantationâ	
#skipping: problem character detected: s/\xc3\xa2\xe2\x82\xac\xc5\xa1\xc3\x83\xe2\x80\x9e\xc3\x83\xc2\xae/    /g   â€šÃ„Ã® ---> 5â€šÃ„Ã®8,	
#skipping: problem character detected: s/\xc3\xa9/    /g   é ---> André,	Pénjamo	Pénjamo.	Calamajué	Calamajué,	Ciprés	Héroes	Indés.	José.	José	Eréndira.	Ciprés.	Médano	Calamajué.	Bartolomé	
#skipping: problem character detected: s/\xc3\xad/    /g   í ---> Quintín	Bahía	Rosalía	Augustín.	Quintín.	María.	Sandía,	Sandía.	Nejí.	Nejí	Martír.	Río	Maríano,	Matomí	Matomí.	Matmí	Maxíminos	Vizcaíno	
#skipping: problem character detected: s/\xc3\xb1/    /g   ñ ---> Cañada	Cañon,	Cataviña.	Cataviña	cañon	Cañon	Doña	Desengaño	Piñon.	Peñasco	[Piñon]	Cataviña,	Cataviñacito,	Montaña	Año	cañon.	Cañon.	
#skipping: problem character detected: s/\xc3\xb1\xc3\xa1/    /g   ñá ---> Cataviñá.	
#skipping: problem character detected: s/\xc3\xb1\xc3\xb3/    /g   ñó ---> Cañón	Cañón,	
#skipping: problem character detected: s/\xc3\xb3/    /g   ó ---> Misión	Missión	Quemazón	Quemazón.	Misión.	Concepción.	ex-Misión	bolsón	Constitución	Hipólito.	Unión	Simón,	
#skipping: problem character detected: s/\xc3\xba/    /g   ú ---> Jesús	
#skipping: problem character detected: s/\xc5\x84/    /g   ń ---> Desenganńo	
#skipping: problem character detected: s/\xcb\x9c/    /g   ˜ ---> ˜	
#skipping: problem character detected: s/\xe2\x80\x94/    /g   — ---> —	18—20,	July—October,	Jan.—March,	north—facing	south—west	March—June,	Jan—March	N—facing	6—15,	
#skipping: problem character detected: s/\xe2\x80\x99/    /g   ’ ---> 14’00.3”N,	18’16.7”W.	7.5’	7.5’quad,	33Y’20’27”N,	118Y’27’10”W,	7.5’USGS	
#skipping: problem character detected: s/\xe2\x80\x9d/    /g   ” ---> 14’00.3”N,	18’16.7”W.	33Y’20’27”N,	118Y’27’10”W,	
#skipping: problem character detected: s/\xe2\x85\x93/    /g   ⅓ ---> ⅓	
#skipping: problem character detected: s/\xe2\x85\x94/    /g   ⅔ ---> ⅔	
#skipping: problem character detected: s/\xe2\x85\x95/    /g   ⅕ ---> ⅕	
#skipping: problem character detected: s/\xe2\x85\x97/    /g   ⅗ ---> ⅗	
#skipping: problem character detected: s/\xe2\x85\x99/    /g   ⅙ ---> ⅙	
#skipping: problem character detected: s/\xe2\x85\x9b/    /g   ⅛ ---> ⅛	
#skipping: problem character detected: s/\xe2\x85\x9c/    /g   ⅜ ---> ⅜	
#skipping: problem character detected: s/\xe2\x89\xa1/    /g   ≡ ---> 2011\n≡	
#skipping: problem character detected: s/\xe2\x9c\x95/    /g   ✕ ---> 2-6✕	✕	
#skipping: problem character detected: s/\xef\xbf\xbd/    /g   � ---> 0�0.2	0.4�0.6	26.45�	39.3007�N,	120.1368�W;	39.0808�N,	120.2438�W;	39.3037�N,	120.1372�W:	39.1937�N,	120.2647�W;	38.3522�N,	119.6474�W;	dam.39.3348�N,	120.1269�W	38.2792�N,	119.2181�W:	38.3532�N,	119.6513�W;	39.5619�N,	120.0453�W;	Pass:37.9184�N,	119.2385�W	39.3271�N,	120.9942�W.	39.1902�N,	120.2763�W;	39.1885�N,	120.2775�W;	38.3550�N,	119.6471�W;	39.3275�N,	120.9967�W.	39.3008�N,	120.1361�W;	39.3033�N	120.1211�W,	39.1842�N,	120.1085�W;	39.3294�N,	120.9856�W.	39.3355�N,	120.8040�W	39.3016�N,	120.1324�W;	39.4093�N,	120.0826�W	37.8970�N,	119.1959�W	37.9244�N,	119.2296�W	37.9200�N,	119.2303�W	38.4371�N,	119.3619�W	38.3807�N,	119.4332�W	38.4001�N,	119.3983�W	reservoir.39.3270�N,	120.1128�W	39.0800�N	120.2429�W;	39.3101�N,	120.7714�W.	reservoir.39.3178�N,	120.1220�W	38.7958�N,	119.9705�W;	39.3054�N,	120.1182�W;	reservoir.39.3257�N,	120.1108�W	reservoir.39.3252�N,	120.1159�W	38.5193�N,	119.5576�W	39.2923�N,	120.1291�W.	39.2957�N,	38.5226�N,	119.5442�W;	39.3038�N,	120.1222�W;	reservoir.39.3262�N,	120.1107�W	reservoir.39.3260�N,	120.1101�W.	39.2915�N,	120.1352�W:	reservoir.39.3220�N,	120.1166�W	38.9422�N,	119.9937�W;	39.3220�N,	120.3737�W.	39.3087�N,	120.4133�W;	38.8456�N,	120.0415�W;	;39.2871�N,	120.1407�W:	39.2866�N,	120.1401�W:	39.2872�N,	120.1382�W:	39.2870�N,	120.1399�W:	39.3021�N,	120.1342�W:	120.1254�W;	39.3198�N,	120.1160�W;	39.3030�N,	120.1209�W;	39.3011�N,	120.1330�W;	40.0185�N	121.0356�W.	121.0356�W,	40.0174�N	121.0594�W.	39.3019�N,	120.1264�W.	39.2873�N,	120.1068�W;	39.2973�N,	120.1170�W;	39.2974�N,	39.2944�N,	120.1261�W;	339.2950�N,	120.1420�W;	120.1240�W;	39.2981�N,	120.1258�W;	39.3014�N,	120.1326�W;	37.9188�N,	37.9618�N,	119.2598�W	39.2471�N,	120.0388�W	location.37.9790�N,	119.1261�W;	38.0886�N,	119.1804�W	37.9078�N,	119.0505�W	37.9596�N,	119.2601�W	37.9076�N,	119.0502�W;	37.9556�N,	119.2530�W	37.9551�N,	119.2524�W	119.2527�W	39.1942�N,	120.2721�W	39.2899�N,	120.1367�W:	120.1361�W:	39.2267�N,	120.2599�W	39.2312�N,	120.2615�W;	39.2682�N,	120.0620�W	39.1886�N,	120.2773�W	dam.39.3253�N,	120.1008�W	reservoir.39.3253�N,	120.1124�W	39.3250�N,	120.1145�W;	Summit;39.3134�N,	120.3262�W;	tunnel;39.3154�N,	120.3209�W;	39.3033�N,	120.1211�W.	39.3006�N,	120.1362�W;	38.5121�N,	119.5344�W;	Ca�ada	7�'	�	34.8106�N,	119.0109�W.	34.8124�N	119.0101�W.	36.16023�N	118.68695�W	35.28361�N	120.68354�W	35�	120�	35.20391�N	120.47009�W	32.425�N	119.022�W.	(35�18.497'	119�59.275')	35.3442�N,	120.6800�W	(35.1413�N,	120.5995�W).	35.50206�N	120.07846�W	35.4035�N,	120.6199�W	(35.389�N	120.581�W)	(35.419�N	120.599�W)Riparian	35.35708�N	120.56807�W	(35�03.432'	119�46.937'	40�37.859'N	121�28.610'W	40�36.386'N	121�31.381'W	35�15'02.40''N	120�41'26.73''W	35�15'43.55''N	120�42'40.90''W.	(35�09.851	120�05.922'	35.64231�N	117.98826�W	Monta�a	35.32769�N	120.75183�W	35�08'13.61''N	120�29'19''W.	35�21.61'N,	35.41629�	120.28222�	

#skipping: problem character detected: s/\xc2\x80\xc2\x9c/    /g    ---> salvage	plantation	
#skipping: problem character detected: s/\xc2\x80\xc2\x9d/    /g    ---> 	
#skipping: problem character detected: s/\xcb\x9c/    /g   ˜ ---> ˜	



		$line_store=$_;
		++$count;	
		
				
 	
my $id;
my $country;
my $stateProvince;
my $county;
my $tempCounty;
my $locality; 
my $family;
my $scientificName;
my $genus;
my $species;
my $rank;
my $subtaxon;
my $name;
my $hybrid_annotation;
my $identifiedBy;
my $dateIdentified;
my $recordedby;
my $recordedBy;
my $Collector_full_name;
my $eventDate;
my $verbatimEventDate;
my $collector;
my $collectors;
my %collectors;
my %coll_seen;
my $other_collectors;
my $other_coll;
my $Associated_collectors;
my $verbatimCollectors; 
my $coll_month; 
my $coll_day;
my $coll_year;
my $recordNumber;
my $CNUM;
my $CNUM_prefix;
my $CNUM_suffix;
my $verbatimElevation;
my $elevation;
my $elev_feet;
my $elev_meters;
my $CCH_elevationInMeters;
my $elevationInMeters;
my $elevationInFeet;
my $minimumElevationInMeters;
my $maximumElevationInMeters;
my $minimumElevationInFeet;
my $maximumElevationInFeet;
my $verbatimLongitude;
my $verbatimLatitude;
my $TRS;
my $Township;
my $Range;
my $Section;
my $Fraction_of_section;
my $topo_quad;
my $UTME;
my $UTMN; 
my $zone;
my $habitat;
my $latitude;
my $lat_degrees;
my $lat_minutes;
my $lat_seconds;
my $decimalLatitude;
my $longitude;
my $decimalLongitude;
my $long_degrees;
my $long_minutes;
my $long_seconds;
my $datum;
my $errorRadius;
my $errorRadiusUnits;
my $coordinateUncertaintyInMeters;
my $coordinateUncertaintyUnits;
my $georeferenceSource;
my $associatedSpecies;	
my $plant_description;
my $phenology;
my $abundance;
my $associatedTaxa;
my $cultivated; #add this field to the data table for cultivated processing, place an "N" in all records as default
my $location;
my $localityDetails;
my $commonName;
my $occurrenceRemarks;
my $substrate;
my $plant_description;
my $phenology;
my $abundance;
my $notes;
#unique to this dataset
my $csid;
my $EarlyCollectionDate;
my $LateCollectionDate;
my $minimumElevation;
my $maximumElevation;
my $elevation_units;
my $cchid;
my $verbatimCoordinates;
my $formatname;
my $basionym;
my $major;
my $localityNote;
my $localitySource;
my $localitySourceDetail;
my $update;
my $labelHeader;
my $labelFooter;
my $previousDeterminations;
my $localName;
my $briefDescription;
my $depth;
my $minDepth;
my $maxDepth;
my $depthUnit;
my $associatedTaxa;
my $typeAssertions;
my $cultivated;
my $sex;
my $phase;
my $othernumber;
my $ucbgaccessionnumber;
my $determinationdetails;
my $loanstatus;
my $loannumber;
my $collectorverbatim;
my $otherlocalities;
my $alllocalities;
my $hastypeassertions;
my $determinationqualifier;
my $comments;
my $numberofobjects;
my $objectcount;
my $sheet;
my $create;
my $posttopublic;
my $references;
my $blob; 
my $collectorsFormatted;
		
		my @fields=split(/\t/, $_, 100);
		
		
		
	unless($#fields == 66){	#if the number of values in the columns array is exactly 67

	&log_skip ("$#fields bad field number $_\n");
	++$skipped{one};
	next Record;
	}	
		

#id	csid_s	accessionnumber_s	determination_s	termformatteddisplayname_s	family_s	taxonbasionym_s	majorgroup_s	collector_ss	collectornumber_s	
#collectiondate_s	earlycollectiondate_dt	latecollectiondate_dt	locality_s	collcounty_s	collstate_s	collcountry_s	elevation_s	minelevation_s	maxelevation_s	elevationunit_s	
#habitat_s	location_0_d	location_1_d	latlong_p	trscoordinates_s	datum_s	coordinatesource_s	coordinateuncertainty_f	coordinateuncertaintyunit_s	
#localitynote_s	localitysource_s	localitysourcedetail_s	updatedat_dt	labelheader_s	labelfooter_s	previousdeterminations_ss	localname_s	briefdescription_txt	
#depth_s	mindepth_s	maxdepth_s	depthunit_s	associatedtaxa_ss	typeassertions_ss	cultivated_s	sex_s	phase_s	othernumber_ss	ucbgaccessionnumber_s	
#determinationdetails_s	loanstatus_s	loannumber_s	collectorverbatim_s	otherlocalities_ss	alllocalities_ss	hastypeassertions_s	determinationqualifier_s	
#comments_ss	numberofobjects_s	objectcount_s	sheet_s	createdat_dt	posttopublic_s	references_ss	collectors_verbatim_s	blob_ss

		($cchid,
		$csid,
		$id,
		$temp_name,
		$formatname,
		$family,
		$basionym,
		$major,
		$collectorsFormatted,
		$recordNumber, #10
		$verbatimEventDate,
		$EarlyCollectionDate,
		$LateCollectionDate,
		$locality, 
		$tempCounty,
		$stateProvince,
		$country,
		$verbatimElevation,
		$minimumElevation,
		$maximumElevation, #20
		$elevation_units,
		$habitat,
		$verbatimLatitude,
		$verbatimLongitude, 
		$verbatimCoordinates,
		$TRS,
		$datum,  
		$georeferenceSource,
		$errorRadius,
		$coordinateUncertaintyUnits,#30
		$localityNote,
		$localitySource,
		$localitySourceDetail,
		$update,
		$labelHeader,
		$labelFooter,
		$previousDeterminations,
		$localName,
		$briefDescription,
		$depth, #40
		$minDepth,
		$maxDepth,
		$depthUnit,
		$associatedTaxa,
		$typeAssertions,
		$cultivated,
		$sex,
		$phase,
		$othernumber,
		$ucbgaccessionnumber, #50
		$determinationdetails,
		$loanstatus,
		$loannumber,
		$collectorverbatim,
		$otherlocalities,
		$alllocalities,
		$hastypeassertions,
		$determinationqualifier,
		$comments,
		$numberofobjects, #60
		$objectcount,
		$sheet,
		$create,
		$posttopublic,
		$references,
		$verbatimCollectors,
		$blob #67
		) = @fields;
		#print "$verbatimElevation, $minimumElevation, $maximumElevation, $elevation_units,\n";
		#print "$verbatimEventDate, $EarlyCollectionDate, $LateCollectionDate\n";

#########Skeletal Records
	if((length($county) < 2) && (length($locality) < 2) && (length($habitat) < 2) && (length($verbatimEventDate) < 2) && (length($verbatimCollectors) < 2) && (length($decimalLatitude) == 0) && (length($decimalLongitude) == 0)){ #exclude skeletal records
			&log_skip("VOUCHER: skeletal records without data in most fields including locality and coordinates\t$id");	#run the &log_skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
	}

		#next unless ($major =~ /Spermatophytes|Pteridophytes/);
		next unless ($country =~ /^USA|Mexico/);
		#next unless ((length($solr_county) == 0) || 

################ACCESSION_ID#############
#check for nulls, remove '-' from ID
#skip

#remove leading zeroes, remove any white space
foreach($id){
	s/  +/ /;
	s/^ +//g;
	s/ +$//g;
}

#Add prefix 
#skip

	
#Remove duplicates
	if($seen{$id}++){
	warn "Duplicate number: $id<\n";
	&log_skip("Duplicate accession number, skipped:\t$id");
	++$skipped{one};
	next Record;
	}


###########REMOVE FIELD STATION IDs for now
#	if ($id =~/(BFRS|HREC|SCFS)/){  #unblocking all but Sagehen, which is in Symbiota
	if ($id =~/(SCFS|JOMU)/){
		&log_skip("John Muir Herbarium or Field Station Herbarium specimen, skipped:\t$id");
		++$skipped{one};
		next Record;
	}

##################Exclude known problematic specimens by id numbers, most from outside California and Baja California

if ($id =~ m/^(UC171474)$/){ 
		&log_skip("SPECIMEN Not from California\t$locality\t$tempCounty\t--\t$id\n");
		++$skipped{one};
		next Record;
}

if ($id =~ m/^(UC1560582)$/){ 
		&log_skip("SPECIMEN Not from CA-FP in Baja California Specimen\t$locality\t$tempCounty\t--\t$id\n");
		++$skipped{one};
		next Record;
}


if ($id =~ m/^(JEPS16877|JEPS74548|UC73411|UC5084|UC5083|UC367200|UC35805|UC337937|UC337812|UC337520|UC336341|UC336233|UC335495|UC335336|UC25260|UC24745|UC24639|UC24498|UC188749|UC101487)$/){ 
		&log_skip("SPECIMEN Fort Mohave was in Mohave Co., Arizona, Not a California Specimen\t$locality\t$tempCounty\t--\t$id\n");
		++$skipped{one};
		next Record;
}


#Include only specimens from California and Baja California
##kick these out here before processing the scientific names, then dont have to waste time on researching taxa that were kicked out later
	unless($stateProvince=~m/^(CA|Baja)/){	
		&log_change("SPECIMEN out of California or Baja California -> $country\t--\t$stateProvince\t--\t$tempCounty\t--\t$locality\t$id");
		++$skipped{one}; 
			next Record;
	}


	if(($tempCounty!~m/(Ensenada|Mexicali|Rosarito|Tecate|Tijuana)/) && ($country =~m/Mexico/)){
		&log_change("Mexico record outside CA-FP states or municipalities\t$id\t==>$tempCounty\t$locality");
			++$skipped{one};
			next Record;
	}

##########Begin validation of scientific names

###########SCIENTIFICNAME

#Many of these don't apply to the original dataset
#but it doesn't hurt to leave them in

foreach ($temp_name){
	s/;$//g;
	s/cf.//g;
	s/A-- Elymordeum/X Elymordeum/;
	s/A-- ?ganderi/A-- ganderi/;
	s/ A-- / X /g;
	s/Pelargonium L.H.+/Pelargonium/g;
	s/Eucalyptus L.H.+/Eucalyptus/g;
	s/Salvinia S.+guier/Salvinia/g;
	s/^[nN]one$//g;
	s/  +/ /g;
	s/^ $//g;
	s/^Boechera .+ L.ve . D. L.ve/Boechera/;
	s/^Packera .+ L.ve.*/Packera/;
	s/^ +//g;
	s/ +$//g;
}

$temp_name =~ s/([A-Z][a-z]+) [A-Z]\..*/$1/; #fix specimens determined only as Genus but has a type 1 authority abbreviation==> L.
$temp_name =~ s/([A-Z][a-z]+) [A-Z][a-z]+\..*/$1/; #fix specimens determined only as Genus but has a type 2 authority==> Dougl.
$temp_name =~ s/([A-Z][a-z]+) [A-Z][a-z]+ ..*/$1/; #fix specimens determined only as Genus but has a type 3 authority==> Webb & Bert
$temp_name =~ s/([A-Z][a-z]+) \([A-Z].*/$1/; #fix specimens determined only as Genus but has a type 4 authority==> (Nutt. ex Hook.) Copel.
$temp_name =~ s/^([A-Z][a-z]+) [A-Z][a-z]+$/$1/; #fix specimens determined only as Genus but has a type 5 authority==> Webb

#Fix records with unpublished or problematic name determination that should not be fixed in AlterNames
#allows name to pass through to CCH; the name is only corrected herein and not global in case name is published

#if (($id =~ m/^(JEPS127680|JEPS127678|JEPS125099|JEPS22393|JEPS44262|JEPS44285|JEPS44289|JEPS44290|JEPS44291|JEPS44293|JEPS44295|UC114460|UC1215056|UC1505753|UC1564840|UC1565014|UC1565015|UC1586890|UC2048900|UC2048902|UC2048903|UC562979|UC604156|UC625269|UC642628|UC642629|UC642630|UC642780|UC673318|UC673326|UC694460|UC702072)$/) && (length($TID{$name}) == 0)){ 
#	$name =~ s/Potentilla amicarum Ertter ined\./Potentilla amicarum/;
	#&log_change("Scientific name error - Potentilla amicarum Ertter ined. not a published name, modified to\t$name\t--\t$id\n");
#}
if (($id =~ m/^(UC1430154|UC81765)$/) && (length($TID{$temp_name}) == 0)){ 
	$temp_name =~ s/Lathyrus vestitus Nutt\. subsp\. barbarae/Lathyrus vestitus/;
	&log_change("Scientific name error - Lathyrus vestitus Nutt. subsp. barbarae not a published name,  modified to: $temp_name\t--\t$id\n");
}
if (($id =~ m/^(UC1094724|UC1174399|UC1174400|UC1223895|UC1787425|UC1787432|UC517425|UC80753|UC80754)$/) && (length($TID{$temp_name}) == 0)){ 
	$temp_name =~ s/Acmispon argophyllus \(A\. Gray\) Greene var\. ornithopus/Acmispon argophyllus/;
	&log_change("Scientific name error - Acmispon argophyllus (A. Gray) Greene var. ornithopus not a published name, modified to: $temp_name\t--\t$id\n");
}
if (($id =~ m/^(UC1235779|UC1235780|UC770351|UC792416|UC80739|UC80745|UC935988)$/) && (length($TID{$temp_name}) == 0)){ 
	$temp_name =~ s/Acmispon watsoni.*/Acmispon/;
	&log_change("Scientific name error - Acmispon watsonii not a published combination, modified to: $temp_name\t--\t$id\n");
}
if (($id =~ m/^(UC764800|UC764583|UC708724|UC676887|UC64919|UC16059|UC155289|UC1542855|UC1542856|UC1542857|UC1542851|UC1542852|UC1129254)$/) && (length($TID{$temp_name}) == 0)){ 
	$temp_name =~ s/Lupinus andersonii S. Watson var\. mariposanus \(Eastwood\) M\. L\. Conrad/Lupinus andersonii/;
	&log_change("Scientific name error - Lupinus andersonii S. Watson var. mariposanus (Eastwood) M. L. Conrad not a published name, modified to: $temp_name\t--\t$id\n");
}
if (($id =~ m/^(UC2062861)$/) && (length($TID{$temp_name}) == 0)){ 
	$temp_name =~ s/Lupinus formosus Greene subsp\. proximus Conrad/Lupinus formosus/;
	&log_change("Scientific name not published: Lupinus formosus subsp. proximus modified to: $temp_name\t==>\t$id\n");
}



#format hybrid names
if($temp_name=~m/([A-Z][a-z-]+ [a-z-]+) [Xx×] /){
	$hybrid_annotation=$temp_name;;
	warn "Hybrid Taxon: $1 removed from $temp_name\n";
	&log_change("Hybrid Taxon: $1 removed from $temp_name");
	$name=$1;
}
else{
	if($hybrid{$csid}=~m/([A-Z][a-z-]+ [a-z-]+) [Xx×] /){
		$hybrid_annotation = $hybrid{$csid};
		warn "Hybrid Taxon: $1 removed from hybrid table record: $hybrid{$csid}\n";
		$name = $1;
	}
	else{
		$hybrid_annotation= "";
	}
}

#fix a problem hybrid genus name
if($temp_name=~m/Elymordeum/){
	$temp_name =~ s/^([^A-Z- ]+)Elymordeum/X Elymordeum/;
	warn "Problem Taxon: $1 removed from $temp_name\n";
}

#####process taxon names
#count number of non-vascular plants skipped in CCH module
	($genus=$temp_name)=~s/ .*//;
	if($exclude{$genus}){	
		++$skipped_nonvasc{non};
	}


$scientificName=&strip_name($temp_name);
$scientificName=&validate_scientific_name($scientificName, $id);

#####process cultivated specimens			
# flag taxa that are known cultivars that should not be added to the Jepson Interchange, add "P" for purple flag to Cultivated field	

## dedicated Cultivated field parsing
		if (($CULT{$csid}) =~ m/true/){
			$cultivated_s = "P"; #P for purple flag
			&log_change ("Cultivated (1): CSpace record marked as Cultivated: $cultivated_s\t--$CULT{$id}\t--\t$scientificName\t--\t$id\n");
		}
## regular Cultivated parsing
		elsif ((($CULT{$csid}) =~ m/false/) && ($locality =~ m/(weed[y .]+|uncultivated[ ,]|naturalizing[ ,]|naturalized[ ,]|cultivated fields?[ ,]|cultivated (and|or) native|cultivated (and|or) weedy|weedy (and|or) cultivated)/i)){
			#&log_change("CULT Taxon not cultivated, skipping purple flagging: $cultivated\t--$scientificName\n");
			$cultivated_s = "N";
		}
		elsif ((($CULT{$csid}) =~ m/false/) && (($locality =~ m/(Bot\. Garden[ ,]|Botanical Garden, University of California|cultivated native[ ,]|cultivated from |cultivated plants[ ,]|cultivated at |cultivated in |cultivated hybrid[ ,]|under cultivation[ ,]|in cultivation[ ,]|Oxford Terrace Ethnobotany|Internet purchase|cultivated from |artificial hybrid[ ,]|Trader Joe's:|Bristol Farms:|Market:|Tobacco:|Yaohan:|cultivated collection)/i) || ($habitat =~ m/(cultivated from|planted from seed|planted from a seed)/i))){
		    $cultivated_s = "P";
	   		&log_change("Cultivated (2): Cultivated specimen found and purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");
		}
		
		elsif ($cultivated_s !~ m/P/){
			if($cult{$scientificName}){
		   		$cultivated_s = $cult{$scientificName};
				print $cult{$scientificName},"\n";
				&log_change("Cultivated (3): Documented cultivated taxon, now purple flagged: $cultivated\t--\t$scientificName\t--\t$id\n");	
			}
			else {
			#&log_change("CULT Taxon skipped purple flagging: $cultivated\t--\t$scientificName\n");
			$cultivated_s = "";
			}
		}
		else {
			&log_change("CULT Taxon not cultivated\t$scientificName\n");
			$cultivated_s = "";
		}




##########COLLECTION DATE##########

my $DD;
my $DD2;
my $MM;
my $MM2;
my $YYYY;
my $EJD;
my $LJD;
my $formatEventDate;

#YYYY-MM-DD format for dwc eventDate
#EJD/LJD format for CCH machine date
#$coll_month, #three letter month name: Jan, Feb, Mar etc.
#$coll_day,
#$coll_year,
#verbatim date for dwc verbatimEventDate and CCH "Date"


foreach ($verbatimEventDate){
	s/^ *//g;
	s/'//g;
	s/ *$//g;
	s/  +/ /g;
	
}

#fix some really problematic date records
#skip
#this is customized for CSpace and not the normal date processing script

if(length($EarlyCollectionDate) >=2 ){

	if($EarlyCollectionDate=~/^00(\d\d)-(\d\d)-(\d\d)/){	#if eventDate is in the format 00##-##-##, change year to 19##
		$YYYY="19$1";  #for some reason some, but not all CSpace  dates like 6-9-53 is converted to 0053-06-09 and trips a gregorian calendar date error
		$MM=$2; 
		$DD=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
		#warn "Date Changed:(1)$EarlyCollectionDate\t$id";
	}
	elsif($EarlyCollectionDate=~/^(19\d\d)-(\d\d)-(\d\d)/){	#if eventDate is in the format 19##-##-##, keep year as 19##
		$YYYY=$1;
		$MM=$2; 
		$DD=$3;
	#warn "(2)$EarlyCollectionDate\t$id";
	}
	elsif($EarlyCollectionDate=~/^(20\d\d)-(\d\d)-(\d\d)/){	#if eventDate is in the format 20##-##-##, keep year as 20##
		$YYYY=$1;
		$MM=$2; 
		$DD=$3;
	#warn "(3)$EarlyCollectionDate\t$id";
	}	
	elsif($EarlyCollectionDate=~/^(1[0-9]{3})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##, keep year as 1####, dont allow other odd year combinations
		$YYYY=$1;
		$MM=$2; 
		$DD=$3;
	#warn "(4)$EarlyCollectionDate\t$id";
	}
	elsif($EarlyCollectionDate=~/^(10[0-9]{2})-(\d\d)-(\d\d)/){	#if eventDate is in the format 10##-##-##, keep year as 19###, dont allow other odd year combinations
		$YYYY="19$1";
		$MM=$2; 
		$DD=$3;
	warn "(5)$EarlyCollectionDate\t$id";
	}
	else{
		&log_change("Date: date format not recognized: $EarlyCollectionDate==>($verbatimEventDate)\t$id\n");;
	}
}
elsif (length($EarlyCollectionDate) == 0){
	$YYYY="";
	$MM2 = "";
	$DD2 = "";
	$DD = "";
	$MM="";
	&log_change("Date: EarlyCollectionDate NULL $id\n");;
}
else{
	&log_change("Date: EarlyCollectionDate format problem: $EarlyCollectionDate==>($verbatimEventDate)\t$id\n");;
}


if(length($LateCollectionDate) >=2 ){

	if($LateCollectionDate=~/^00(\d\d)-(\d\d)-(\d\d)/){	#if eventDate is in the format 00##-##-##, change year to 19##
		$MM2=$2; 
		$DD2=$3;	#set the first four to $YYYY, 5&6 to $MM, and 7&8 to $DD
	#warn "Date Changed: (5)$LateCollectionDate\t$id";
	}
	elsif($LateCollectionDate=~/^(19\d\d)-(\d\d)-(\d\d)/){	#if eventDate is in the format 19##-##-##, keep year as 19##
		$MM2=$2; 
		$DD2=$3;
	#warn "(6)$LateCollectionDate\t$id";
	}
	elsif($LateCollectionDate=~/^(20\d\d)-(\d\d)-(\d\d)/){	#if eventDate is in the format 20##-##-##, keep year as 20##
		$YYYY=$1;
		$MM2=$2; 
		$DD2=$3;
	#warn "(7)$LateCollectionDate\t$id";
	}	
	elsif($LateCollectionDate=~/^(1[0-9]{3})-(\d\d)-(\d\d)/){	#if eventDate is in the format ####-##-##, keep year as 1####, dont allow other odd year combinations
		$MM2=$2; 
		$DD2=$3;
	#warn "(8)$LateCollectionDate\t$id";
	}
	else{
		$MM2 = "";
		$DD2 = ""
		&log_change("Date: date format not recognized: $LateCollectionDate==>($verbatimEventDate)\t$id\n");
	}
}
elsif (length($LateCollectionDate) == 0){
	$MM2 = "";
	$DD2 = "";
	&log_change("Date: LateCollectionDate NULL $id\n");;
}
else{
	&log_change("Date: LateCollectionDate format problem: $LateCollectionDate==>($verbatimEventDate)\t$id\n");
}






#convert to YYYY-MM-DD for eventDate and Julian Dates
$MM = &get_month_number($MM, $id, %month_hash);
$MM2 = &get_month_number($MM2, $id, %month_hash);

#$formatEventDate = "$YYYY-$MM-$DD";
#($YYYY, $MM, $DD)=&atomize_ISO_8601_date($formatEventDate);
#warn "$EarlyCollectionDate\t--\t$LateCollectionDate\t--\t$id";

if ($MM =~ m/^(\d)$/){ #see note above, JulianDate module needs leading zero's for single digit days and months
	$MM = "0$1";
}
if ($DD =~ m/^(\d)$/){
	$DD = "0$1";
}
if ($MM2 =~ m/^(\d)$/){
	$MM2 = "0$1";
}
if ($DD2 =~ m/^(\d)$/){
	$DD2 = "0$1";
}

#$MM2= $DD2 = ""; #set late date to blank if only one date exists
($EJD, $LJD)=&make_julian_days($YYYY, $MM, $DD, $MM2, $DD2, $id);
#warn "$formatEventDate\t--\t$EJD, $LJD\t--\t$id";

################################################## KLUGE TO COMPENSATE FOR A CSPACE  SINGLE DAY PROBLEM #####################
if($LJD-$EJD==1 && $verbatimEventDate !~/-/){
#print "$SpecimenNumber\t$CollectionDate\t$EarlyCollectionDate\t$LateCollectionDate\n";
$EJD+=1;
}
#############################################################################################################################


($EJD, $LJD)=&check_julian_days($EJD, $LJD, $today_JD, $id);

###############COLLECTORS

foreach ($verbatimCollectors){
	s/'$//g;
	s/"//g;
	s/\[//g;
	s/\]//g;
	s/\?//g;
	s/s\. n\. ?/ /g;
	s/, with/ with/;
	s/ w\/ ?/ with /g;
	s/, M\. ?D\.//g;
	s/, Jr\./ Jr./g;
	s/, Jr/ Jr./g;
	s/, Esq./ Esq./g;
	s/, Sr\./ Sr./g;
	s/Jim AndrA.c., /Jim Andre, /g;
	s/ZAoA+-iga/Zuniga/g;
	s/^'//g;
	s/  +/ /;
	s/^ +//;
	s/ +$//;

$collectors = ucfirst($verbatimCollectors);
}
	
	if ($collectors =~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collectors, $id);	
	#D Atwood; K Thorne
		$other_coll=$2;
		#warn "Names 1: $verbatimCollectors===>$collectors\t--\t$recordedBy\t--\t$other_coll\n";
		&log_change("COLLECTOR (1): modified: $verbatimCollectors==>$collectors--\t$recordedBy\t--\t$other_coll\t$id\n");	
	}
	
	elsif ($collectors !~ m/(;|,|:| ?&| [Aa][nN][dD]| [Ww][iI][Tt][Hh]) ([A-Z].*)$/){
		$recordedBy = &CCH::validate_collectors($collectors, $id);
		#warn "Names 2: $verbatimCollectors===>$collectors\t--\t$recordedBy\t--\t$other_coll\n";
	}
	elsif (length($collectors == 0)) {
		$recordedBy = "Unknown";
		&log_change("COLLECTOR (2): modified from NULL to Unknown\t$id\n");
	}	
	else{
		&log_change("COLLECTOR (3): name format problem: $verbatimCollectors==>$collectors\t--$id\n");
	}
	
	
###further process other collectors
foreach ($other_coll){
	s/"//g;
	s/'$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;

$other_collectors = ucfirst($other_coll);
}



#############CNUM##################COLLECTOR NUMBER####
#clean up collector numbers, prefixes and suffixes

foreach ($recordNumber){
	s/none//i;
	s/'//g;
	s/"//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
}



($CNUM_prefix,$CNUM,$CNUM_suffix)=&parse_CNUM($recordNumber);


####COUNTRY / StateProvince
#my $country = $COUNTRY{$csid};
#my $state = $STATE{$csid};

foreach ($stateProvince){
	s/  +/ /;
	s/^ *$//;
	s/^ +//;
	s/ +$//;
}

foreach ($country){
	s/  +/ /;
	s/^ *$//;
	s/^ +//;
	s/ +$//;
}
		
#########################County/MPIO
#delete some problematic Mexico specimens

my %country;

	if((length($tempCounty) == 0) && ($country =~m/Mexico/)){
		&log_skip("Mexico record with unknown or blank county field\t$id\t--\t$locality");
			++$skipped{one}; #do not skip once the Country and State are in CCH display
			next Record;
	}
	if(($tempCounty=~m/[Uu]nknown/) && ($country =~m/Mexico/)){
		&log_skip("Mexico record with unknown or blank county field\t$id\t--\t$locality");
			++$skipped{one};
			next Record;
	}

######################COUNTY
	foreach ($tempCounty){
	s/'//g;
	s/^ $//;
	s/Playas De Rosarito/Rosarito, Playas de/g; #this is not being detected by the below checker despite many tries
}
#format county as a precaution
$county=&CCH::format_county($tempCounty,$id);




##Unknown County List

	if($county=~m/(unknown|Unknown)/){	#list each $county with unknown value
		&log_change("COUNTY unknown -> $country\t--\t$stateProvince\t--\t$county\t--\t$locality\t$id");		
	}

##validate county
my $v_county;


	foreach ($county){ #for each $county value
	unless(m/^(Alameda|Alpine|Amador|Butte|Calaveras|Colusa|Contra Costa|Del Norte|El Dorado|Fresno|Glenn|Humboldt|Imperial|Inyo|Kern|Kings|Lake|Lassen|Los Angeles|Madera|Marin|Mariposa|Mendocino|Merced|Modoc|Mono|Monterey|Napa|Nevada|Orange|Placer|Plumas|Riverside|Sacramento|San Benito|San Bernardino|San Diego|San Francisco|San Joaquin|San Luis Obispo|San Mateo|Santa Barbara|Santa Clara|Santa Cruz|Shasta|Sierra|Siskiyou|Solano|Sonoma|Stanislaus|Sutter|Tehama|Trinity|Tulare|Tuolumne|Ventura|Yolo|Yuba|Ensenada|Mexicali|Rosarito, Playas de|Tecate|Tijuana|Unknown)$/){
		$v_county = &verify_co($_);	#Unless $county matches one of the county names from the above list, create a value $v_county for that value using the &verify_co function
		if($v_county=~/SKIP/){		#If $v_county is "/SKIP/" (i.e. &verify_co cannot recognize it)
			&log_skip("COUNTY (2): NON-CA COUNTY?\t$_\t--\t$id");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		unless($v_county eq $_){	#unless $v_county is exactly equal to what was input into the &verify_co function (i.e. if &verify_co successfully changed the county)
			&log_change("COUNTY (3): COUNTY $county ==> $v_county--\t$id");		#call the &log function to print this log message into the change log...
			$_=$v_county;	#and then set $county to whatever the verified $v_county is.
		}
	}
}

####LOCALITY

foreach($locality){
	s/^ *//g;
	s/\\n/ /g; #get rid of carriage return in Locality, added by David
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
}



#############ELEVATIONS##########

my $minimumElevation;
my $maximumElevation;
my $hold_elev;

foreach($minimumElevation){
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
}

foreach($maximumElevation){
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
}


foreach($verbatimElevation){
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/,//;
}
		my $elevation_mod;
		my $units_mod=$elevation_units;

	#format elevation correctly
	if ((length($verbatimElevation) >= 1) && (length($minimumElevation) == 0) && (length($maximumElevation) == 0)){
		$elevation_mod = $verbatimElevation;
	}
	elsif ((length($verbatimElevation) >= 1) && (length($minimumElevation) >= 1) && (length($maximumElevation) == 0)){
		$elevation_mod = $verbatimElevation;
	}
	elsif ((length($verbatimElevation) >= 1) && (length($minimumElevation) == 0) && (length($maximumElevation) >= 1)){
		$elevation_mod = $verbatimElevation;
	}
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevation) >= 1) && (length($maximumElevation) == 0)){
		$elevation_mod = $minimumElevation;
		$verbatimElevation = "$minimumElevation $elevation_units";
	}	
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevation) >= 1) && (length($maximumElevation) >= 1)){
		$elevation_mod = $minimumElevation;
		$verbatimElevation = "$minimumElevation - $maximumElevation $elevation_units";
	}	
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevation) == 0) && (length($maximumElevation) >= 1)){
		$elevation_mod = $maximumElevation;
		$verbatimElevation = "$maximumElevation $elevation_units";
	}
	elsif ((length($verbatimElevation) >= 1) && (length($minimumElevation) >= 1) && (length($maximumElevation) >= 1)){
		$elevation_mod = $minimumElevation;
	}
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevation) == 0) && (length($maximumElevation) >= 1)){
		$elevation_mod = $maximumElevation;
		$verbatimElevation = "";
	}
	elsif ((length($verbatimElevation) == 0) && (length($minimumElevation) == 0) && (length($maximumElevation) == 0)){
		&log_change("ELEV: all fields NULL\t$id==>$verbatimElevation MIN: $minimumElevation, MAX: $maximumElevation UNITS: $units_mod\n");
		$elevation_mod = "";
		$units_mod = "";
		$verbatimElevation = "";
	}
	else{
		&log_change("ELEV: elevation problem:\t$id==>$verbatimElevation MIN: $minimumElevation, MAX: $maximumElevation UNITS: $units_mod\n");
		$elevation_mod = "";
		$units_mod = "";
		$verbatimElevation = "";
	}


	#format verbatim elevation correctly
	if (($verbatimElevation =~m/\d+ *[fm].*/) && (length($units_mod) == 0)){
		#do nothing, verbatim elevation has units;
	}
	elsif (($verbatimElevation =~m/\d+ *[fm].*/) && (length($units_mod) >= 1)){
		#do nothing, verbatim elevation has units, ignore the units field;
	}
	elsif (($verbatimElevation =~m/^\d+$/) && (length($units_mod) >= 1)){
		$hold_elev = $verbatimElevation;
		$verbatimElevation = $hold_elev." ".$units_mod;
	}
	elsif (($verbatimElevation =~m/^\d+$/) && (length($units_mod) == 0)){
		#verbatim elevation missing units, do nothing
		
	}	
	elsif ((length($verbatimElevation) == 0) && (length($units_mod) >= 1)){
		#units could refer to the min max fields
	}	
	elsif ((length($verbatimElevation) == 0) && (length($units_mod) == 0)){
		#elevation is likely null
	}
	else{
		&log_change("ELEV: verbatim elevation problem:\t$id==>$verbatimElevation MIN: $minimumElevation, MAX: $maximumElevation UNITS: $units_mod\n");
		$elevation_mod = "";
		$units_mod = "";
		$verbatimElevation = "";
	}


foreach($elevation_mod){
	#warn "x";
	s/ elev.*//;
	#s/ <([^>]+)>/ $1/;
	s/^\+//;
	s/^near /ca /;
	s/^\~/ca /;
	s/ca\./ca /;
	s/c./ca/;
	s/zero/0/;
	s/sea level/0/;
	s/</ /;
	s/>/ /;
	s/\?//;
	s/g / /;
	s/to/-/;
	s/F/f/g;
	s/M/m/g;
	s/\.30-\.50 m/1m/;
	s/0\.00/0/;
	s/0\.1/0/;
	s/0\.5/1/;
	s/\.9ft/1ft/;
	s/\.$//;
	s/^ *//g;
	s/ *$//g;
	s/^ *$//;
	s/  +/ /g;
	s/,//g;
	s/ //g;
}
foreach($units_mod){
#warn "#";
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
}


if ((length($elevation_mod) >= 1) && ($units_mod =~m/m.*/i)){
	#warn "elevation 0 $id\n";
		#print "x";
		if ($elevation_mod =~ m/^(-?[\d]{1,5})\.[\d]+m?/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})m?/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^[a-z]+([\d]{1,5})m?/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^([\d]{1,5})-([\d]{1,5})m?/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^([\d]{1,5})-(-?[\d]{1,5})m?/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^[a-z]+([\d]{1,5})-([\d]{1,5}+)m?/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		else {
		&log_change("Check elevation (1) METERS: orig:$verbatimElevation--\tMOD:$elevation_mod--\tproblematic formatting or missing units\t$id");
		$elevationInMeters="";
		}
}
elsif ((length($elevation_mod) >= 1) && ($units_mod =~m/f.*/i)){
	#warn "elevation 1 $id\n";
		#print ".";	
	if ($elevation_mod =~ m/^(-?[\d]{1,5})\.[\d]+f?/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation_mod =~ m/^(-?[\d]{1,5})f?/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation_mod =~ m/^(-?[\d]{1,5})f?/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	
	elsif ($elevation_mod =~ m/^[a-z]+([\d]{1,5})f?/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}

	elsif ($elevation_mod =~ m/^([\d]{1,5})-(-?[\d]{1,5})f?/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation_mod =~ m/^([\d]{1,5})-(-?[\d]{1,5})f?/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	elsif ($elevation_mod =~ m/^[a-z]+(-?[\d]{1,5})f?/){
		$elevationInFeet = $1;
		$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
		$CCH_elevationInMeters = "$elevationInMeters m";
	}
	else {
		&log_change("Check elevation (2) FEET: orig:$verbatimElevation--\tMOD:$elevation_mod--\tproblematic formatting or missing units\t$id");
		$elevationInMeters="";
	}
}
elsif ((length($elevation_mod) >= 1) && (length($units_mod) == 0)){
	#warn "elevation 2 $id\n";
	#print "#";
		if ($elevation_mod =~ m/^(-?[\d]{1,5})\.[\d]+m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^[a-z]+([\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^([\d]{1,5})-([\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^([\d]{1,5})-(-?[\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^[a-z]+([\d]{1,5})-([\d]{1,5}+)m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})\.[\d]+f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
	
		elsif ($elevation_mod =~ m/^[a-z]+([\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}

		elsif ($elevation_mod =~ m/^([\d]{1,5})-(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^([\d]{1,5})-(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^[a-z]+(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		else {
			&log_change("Check elevation (3): orig:$verbatimElevation--\tMOD:$elevation_mod--\tproblematic formatting or missing units\t$id");
			$elevationInMeters="";
		}
}
elsif ((length($elevation_mod) >= 1) && (length($units_mod) >= 1)){
			warn "elevation 3 $id\n";
			$elevation_mod = "$elevation_mod$units_mod";
	#print "#";
		if ($elevation_mod =~ m/^(-?[\d]{1,5})\.[\d]+.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^[a-z]+([\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^([\d]{1,5})-([\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^([\d]{1,5})-(-?[\d]{1,5})m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^[a-z]+([\d]{1,5})-([\d]{1,5}+)m.*/){
			$elevationInMeters = $1;
			$elevationInFeet = int($elevationInMeters * 3.2808); #make it an integer to remove false precision		
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})\.[\d]+f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
	
		elsif ($elevation_mod =~ m/^[a-z]+([\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}

		elsif ($elevation_mod =~ m/^([\d]{1,5})-(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^([\d]{1,5})-(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		elsif ($elevation_mod =~ m/^[a-z]+(-?[\d]{1,5})f.*/){
			$elevationInFeet = $1;
			$elevationInMeters = int($elevationInFeet / 3.2808); #make it an integer to remove false precision
			$CCH_elevationInMeters = "$elevationInMeters m";
		}
		else {
			&log_change("Check elevation (3): orig:$verbatimElevation--\tMOD:$elevation_mod--\tproblematic formatting or missing units\t$id");
			$elevationInMeters="";
		}
}
elsif ($elevation_mod =~ m/^0$/){
warn "elevation 0 $id\n";
	#print "0";
		#warn "$elevation_units\n";
		$elevationInFeet = int(0); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "0 m";
}
elsif ($elevation_mod =~ m/^0[metrsf]+/i){
	warn "elevation 0-1 $id\n";
	#print "o";	
		$elevationInFeet = int(0); #make it an integer to remove false precision		
		$CCH_elevationInMeters = "0 m";
}
elsif (length($elevation_mod) == 0){
	#warn "elevation NULL $id\n";
		$elevationInFeet=$elevationInMeters=$CCH_elevationInMeters = "";
}
else {
	warn "elevation problem $id\n";
	&log_change("Check elevation (4): orig:$verbatimElevation--\tMOD:$elevation_mod--\tproblematic formatting or missing units\t$id");
	$elevationInMeters="";
	$CCH_elevationInMeters="";
}	

#####check to see if elevation exceeds maximum and minimum for each county

my $elevation_test = int($elevationInFeet);
	if($elevation_test > $max_elev{$county}){
		&log_change ("ELEV\t$county:\t $elevation_test ft. ($elevationInMeters m.) greater than $county maximum ($max_elev{$county} ft.): discrepancy=", (($elevation_test)-$max_elev{$county}),"\t$id\n");
		if ((($elevation_test)-$max_elev{$county}) >= 500 ){
			$CCH_elevationInMeters = "";
			&log_change ("ELEV\t$county: discrepancy=", (($elevation_test)-$max_elev{$county})," greater than 500 ft, elevation changed to NULL\t$id\n");
		}
	}

#########COORDS, DATUM, ER, SOURCE#########

my %count_LL;
my $count_LL;
my $hold;
my $lat_degrees;
my $lat_minutes;
my $lat_seconds;
my $lat_decimal;
my $long_degrees;
my $long_minutes;
my $long_seconds;
my $long_decimal;
my $zone_number;


foreach ($verbatimLatitude){
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/,/ /g;
		s/-//g; #remove negative latitudes, we dont map specimens from southern hemisphere, so if "-" is present, it is an error
		s/deg\.?/ /;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
		
}

foreach ($verbatimLongitude){
		s/ø/ /g;
		s/'/ /g;
		s/"/ /g;
		s/,/ /g;
		s/deg\.?/ /;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
		
}

#check to see if lat and lon reversed
	if (($verbatimLatitude =~ m/^-?1\d\d\./) && ($verbatimLongitude =~ m/^\d\d\./)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		 
		&log_change("COORDINATE decimals apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d +\d/) && ($verbatimLongitude =~ m/^\d\d +\d/)){
		$hold = $verbatimLatitude;
		$latitude = $verbatimLongitude;
		$longitude = $hold;
		 
		&log_change("COORDINATE apparently reversed, switching latitude with longitude\t$id");
	}	
	elsif (($verbatimLatitude =~ m/^-?1\d\d$/) && ($verbatimLongitude =~ m/^\d\d/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		 
		&log_change("COORDINATE latitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^-?1\d\d/) && ($verbatimLongitude =~ m/^\d\d$/)){
		$hold = $verbatimLatitude;
		$latitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 38.000
		$longitude = $hold;
		&log_change("COORDINATE longitude degree only (no decimal or seconds) and apparently reversed, switching latitude with longitude\t$id");
	}
	elsif (($verbatimLatitude =~ m/^\d\d\./) && ($verbatimLongitude =~ m/^-?1\d\d\./)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
	}
	elsif (($verbatimLatitude =~ m/^\d\d \d/) && ($verbatimLongitude =~ m/^-?1\d\d \d/)){
			$latitude = $verbatimLatitude;
			$longitude = $verbatimLongitude;
	}
	elsif (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d/)){
			$latitude = sprintf ("%.3f",$verbatimLatitude); #convert to decimal, should report cf. 38.000
			$longitude = $verbatimLongitude; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
			&log_change("COORDINATE latitude integer degree only: $verbatimLatitude converted to $latitude==>$id");
	}
	elsif (($verbatimLatitude =~ m/^\d\d/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
			$latitude = $verbatimLatitude; #parser below will catch variant of this one, except where both lat & long are degree only, no decimal or minutes, which we do not want as they are almost always very inaccurate
			$longitude = sprintf ("%.3f",$verbatimLongitude); #convert to decimal, should report cf. 122.000
			&log_change("COORDINATE longitude integer degree only: $verbatimLongitude converted to $longitude==>$id");
	}	
	elsif ((length($verbatimLatitude) == 0) && (length($verbatimLongitude) == 0)){
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}
	else {
		&log_change("COORDINATE: Coordinate conversion problem for $id\t$verbatimLatitude\t--\t$verbatimLongitude\n");
		$decimalLongitude = $decimalLatitude = $latitude = $longitude = "";
	}

#NULL coordinates that are only integer degrees, these are highly inaccurate and not useful for mapping
	if (($verbatimLatitude =~ m/^\d\d$/) && ($verbatimLongitude =~ m/^-?1\d\d$/)){
		$decimalLatitude=$latitude = "";
		$decimalLongitude=$longitude = "";
		&log_change("COORDINATE decimal Lat/Long only to degree, now NULL: $verbatimLatitude\t--\t$verbatimLongitude\n");
	}


foreach ($latitude, $longitude){
		s/  +/ /g;
		s/^ +//;
		s/ +$//;
		s/^\s$//;
}	


#use combined Lat/Long field format for CSPACE
	
	#convert to decimal degrees
if((length($latitude) >= 2)  && (length($longitude) >= 3)){ 
		if ($latitude =~ m/^(\d\d) +(\d\d?) +(\d\d?\.?\d*)/){ #if there are seconds
				$lat_degrees = $1;
				$lat_minutes = $2;
				$lat_seconds = $3;
				if($lat_seconds == 60){ #translating 60 seconds into +1 minute
					$lat_seconds == 0;
					$lat_minutes += 1;
				}
				if($lat_minutes == 60){
					$lat_minutes == 0;
					$lat_degrees += 1;
				}
				if(($lat_degrees > 90) || $lat_minutes > 60 || $lat_seconds > 60){
					&log_change("COORDINATE 1) Latitude problem, set to null,\t$id\t$verbatimLatitude\n");
					$lat_degrees=$lat_minutes=$lat_seconds=$decimalLatitude="";
				}
				else{
					#print "1a) $lat_degrees\t-\t$lat_minutes\t-\t$lat_seconds\t-\t$latitude\n";
	  				$lat_decimal = $lat_degrees + ($lat_minutes/60) + ($lat_seconds/3600);
					$decimalLatitude = sprintf ("%.6f",$lat_decimal);
					print "1b)$decimalLatitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script"; #only needed to be stated once, if lat id converted, so is long
				}
		}
		elsif ($latitude =~ m/^(\d\d) +(\d\d?\.\d*)/){
				$lat_degrees= $1;
				$lat_minutes= $2;
				if($lat_minutes == 60){
					$lat_minutes == 0;
					$lat_degrees += 1;
				}
				if(($lat_degrees > 90) || ($lat_minutes > 60) ){
					&log_change("COORDINATE 2) Latitude problem, set to null,\t$id\t$latitude\n");
					$lat_degrees=$lat_minutes=$decimalLatitude="";
				}
				else{
					#print "2a) $lat_degrees\t-\t$lat_minutes\t-\t$latitude\n";
					$lat_decimal= $lat_degrees+($lat_minutes/60);
					$decimalLatitude=sprintf ("%.6f",$lat_decimal);
					print "2b) $decimalLatitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($latitude =~ m/^(\d\d) +(\d\d?)/){
				$lat_degrees= $1;
				$lat_minutes= $2;
				if($lat_minutes == 60){
					$lat_minutes == 0;
					$lat_degrees += 1;
				}
				if(($lat_degrees > 90) || ($lat_minutes > 60) ){
					&log_change("COORDINATE 2c) Latitude problem, set to null,\t$id\t$latitude\n");
					$lat_degrees=$lat_minutes=$decimalLatitude="";
				}
				else{
					#print "2a) $lat_degrees\t-\t$lat_minutes\t-\t$latitude\n";
					$lat_decimal= $lat_degrees+($lat_minutes/60);
					$decimalLatitude=sprintf ("%.6f",$lat_decimal);
					print "2d) $decimalLatitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($latitude =~ m/^(\d\d\.\d+)/){
				$lat_degrees = $1;
				if($lat_degrees > 90){
					&log_change("COORDINATE 3) Latitude problem, set to null,\t$id\t$lat_degrees\n");
					$lat_degrees=$latitude=$decimalLatitude="";		
				}
				else{
					$decimalLatitude=sprintf ("%.6f",$lat_degrees);
					#print "3a) $decimalLatitude\t--\t$id\n";
				}
		}
		elsif (length($latitude) == 0){
			$decimalLatitude="";
		}
		else {
			&log_change("check Latitude format: ($latitude) $id");	
			$decimalLatitude="";
		}
		
		if ($longitude =~ m/^(-?1\d\d) +(\d\d?) +(\d\d?\.?\d*)/){ #if there are seconds
				$long_degrees = $1;
				$long_minutes = $2;
				$long_seconds = $3;
				if($long_seconds == 60){ #translating 60 seconds into +1 minute
					$long_seconds == 0;
					$long_minutes += 1;
				}
				if($long_minutes == 60){
					$long_minutes == 0;
					$long_degrees += 1;
				}
				if(($long_degrees > 180) || $long_minutes > 60 || $long_seconds > 60){
					&log_change("COORDINATE 5) Longitude problem, set to null,\t$id\t$longitude\n");
					$long_degrees=$long_minutes=$long_seconds=$decimalLongitude="";
				}
				else{				
					#print "5a) $long_degrees\t-\t$long_minutes\t-\t$long_seconds\t-\t$longitude\n";
 	 				$long_decimal = $long_degrees + ($long_minutes/60) + ($long_seconds/3600);
					$decimalLongitude=sprintf ("%.6f",$long_decimal);
					print "5b) $decimalLongitude\t--\t$id\n";
				}
		}	
		elsif ($longitude =~m /^(-?1\d\d) +(\d\d?\.\d*)/){
				$long_degrees= $1;
				$long_minutes= $2;
				if($long_minutes == 60){
					$long_minutes == 0;
					$long_degrees += 1;
				}
				if(($long_degrees > 180) || ($long_minutes > 60) ){
					&log_change("COORDINATE 6) Longitude problem, set to null,\t$id\t$longitude\n");
					$long_degrees=$long_minutes=$decimalLongitude="";
				}
				else{
					$long_decimal= $long_degrees+($long_minutes/60);
					$decimalLongitude = sprintf ("%.6f",$long_decimal);
					print "6a) $decimalLongitude\t--\t$id\n";
					$georeferenceSource = "DMS conversion by CCH loading script";
				}
		}
		elsif ($longitude =~m /^(-?1\d\d) +(\d\d?)/){
			$long_degrees= $1;
			$long_minutes= $2;
			if($long_minutes == 60){
				$long_minutes == 0;
				$long_degrees += 1;
			}
			if(($long_degrees > 180) || ($long_minutes > 60) ){
				&log_change("COORDINATE 6c) Longitude problem, set to null,\t$id\t$longitude\n");
				$long_degrees=$long_minutes=$decimalLongitude="";
			}
			else{
				$long_decimal= $long_degrees+($long_minutes/60);
				$decimalLongitude = sprintf ("%.6f",$long_decimal);
				print "6d) $decimalLongitude\t--\t$id\n";
				$georeferenceSource = "DMS conversion by CCH loading script";
			}
		}
		elsif ($longitude =~m /^(-?1\d\d\.\d+)/){
				$long_degrees= $1;
				if($long_degrees > 180){
					&log_change("COORDINATE 7) Longitude problem, set to null,\t$id\t$long_degrees\n");
					$long_degrees=$longitude=$decimalLongitude="";		
				}
				else{
					$decimalLongitude=sprintf ("%.6f",$long_degrees);
					#print "7a) $decimalLongitude\t--\t$id\n";
				}
		}
		elsif (length($longitude == 0)) {
			$decimalLongitude="";
		}
		else {
			&log_change("COORDINATE check longitude format: $longitude $id");
			$decimalLongitude="";
		}
}
elsif ((length($latitude) == 0) && (length($longitude) == 0)){ 
#UTM is not present in these data, skipping conversion of UTM and reporting if there are cases where lat/long is problematic only
		&log_change("COORDINATE No coordinates for $id\n");
}
elsif(($latitude==0 && $longitude==0)){
	$datum = "";
	$georeferenceSource = "";
	$decimalLatitude =$decimalLongitude = "";
		&log_change("COORDINATE coordinates entered as '0', changed to NULL $id\n");
}

else {
		&log_change("COORDINATE poorly formatted or non-numeric coordinates for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
		$decimalLatitude = $decimalLongitude = $georeferenceSource = "";
}


#check datum

	foreach ($datum){
		s/.//g;
		s/WGS83/WGS84/;
		s/Not Recorded//;
		s/[Ww][Gg][Ss] /WGS/;
		s/[Nn][aA][dD] /NAD/;
		s/ *19//; #WGS1984, WGS 1984 are not a valid datum values
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	}
	
if(($decimalLatitude=~/\d/  || $decimalLongitude=~/\d/)){ #If decLat and decLong are both digits

	if ($datum){ #report is datum is present
		unless ($datum=~m/(WGS84|NAD83|NAD27)/){
		&log_change("Check datum: $datum\t$id");
		$datum="";
		}
	}
	else {
		$datum = "not recorded"; #use this only if datum are blank, set it for records with coords
	}
# check UNCERTAINTY AND UNITS
	if((length($errorRadius) >= 1) && (length($coordinateUncertaintyUnits) == 0)){ 
		$coordinateUncertaintyUnits = "not recorded";
	}		
	elsif ((length($errorRadius) == 0) && (length($coordinateUncertaintyUnits) >= 1)){ 
		$coordinateUncertaintyUnits = "";
	}
}
#final check of Longitude
	if ($decimalLongitude > 0) {
			$decimalLongitude="-$decimalLongitude";	#make decLong = -decLong if it is greater than zero
			&log_change("Longitude made negative\t--\t$id");
	}


#final check for rough out-of-boundary coordinates
if((length($decimalLatitude) >= 2)  && (length($decimalLongitude) >= 3)){ 
	if($decimalLatitude > 42.1 || $decimalLatitude < 30.0 || $decimalLongitude > -114.0 || $decimalLongitude < -124.5){ #if the coordinate range is not within the rough box of california and northern Baja...
	###was 32.5 for California, now 30.0 to include CFP-Baja
		if ($decimalLatitude < 30.0){ #if the specimen is in Baja California Sur or farther south
			&log_skip("COORDINATE: Mexico specimen mapping to south of the CA-FP boundary?\t$stateProvince\t\t$county\t$locality\t--\t$id>$decimalLatitude< >$decimalLongitude<\n");	#run the &skip function, printing the following message to the error log
			++$skipped{one};
			next Record;
		}
		else{
		&log_change("coordinates set to null for $id, Outside California and CA-FP in Baja: >$decimalLatitude< >$decimalLongitude<\n");	#print this message in the error log...
		$decimalLatitude = $decimalLongitude = $georeferenceSource = $datum="";	#and set $decLat and $decLong to ""  
		}
	}
}
else{
		if((length($decimalLatitude) == 0)  && (length($decimalLongitude) == 0)){
			#do nothing, NULL reported elsewhere above, this is done to shorten the error log
		}
		else{
			&log_change("COORDINATE problems for $id: ($verbatimLatitude) \t($verbatimLongitude) \t(ZONE:$zone \t($UTME) \t($UTMN)\n");
			$decimalLatitude = $decimalLongitude = $datum = $georeferenceSource = "";
		}
}



#######Plant Description (dwc ??) and Abundance (dwc occurrenceRemarks)
#skip

#######Habitat and Notes 

#free text fields

my $solr_habitat = $S_habitat{$csid}{'habitat'};  #for using the solr field instead?

foreach ($habitat,$solr_habitat){
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;

		s/&apos;/'/g;			#UC1871063
}
my $solr_pop = $population_biology{$csid}{'brief description'};

foreach ($solr_pop){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
}

my $solr_macro = $macromorphology{$csid}{'brief description'};

foreach ($solr_macro){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
}

my $solr_micro = $micromorph{$csid}{'brief description'};

foreach ($solr_micro){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
}



my $solr_color = $color_note{$csid}{'brief description'};

foreach ($solr_color){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
}

my $solr_odor = $odor_note{$csid}{'brief description'};

foreach ($solr_odor){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
}

my $solr_biology = $reproductive_biology{$csid}{'brief description'};

foreach ($solr_biology){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
}

my $solr_hort = $horticulture{$csid}{'brief description'};

foreach ($solr_hort){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
}

my $solr_phen = $phenology{$csid}{'brief description'};
foreach ($solr_phen){
#fix some data quality and formatting problems	
	s/  +/ /;
	s/[fF][lL]/flowering/;
	s/[fF][rR]/fruiting/;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/[.,;:]$//g;
	s/\n//;
}

my $solr_cyt = $cytology{$csid}{'brief description'};
foreach ($solr_cyt){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
}

my $solr_data = $otherdata{$csid}{'brief description'};
	foreach ($solr_data){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
		s/&apos;/'/g;			#UC1871063
	}

my $solr_desc = $other_description{$csid}{'brief description'};
	foreach ($solr_desc){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
		s/&apos;/'/g;			#UC1871063
	}


#Other_data: $solr_desc $solr_hort $solr_data
my $otherData;

	#format  other string correctly
	if ((length($solr_desc) > 1) && (length($solr_hort) == 0) && (length($solr_data) == 0)){
		$otherData="$solr_desc";
	}
	elsif ((length($solr_desc) > 1) && (length($solr_hort) > 1) && (length($solr_data) == 0)){
		$otherData="$solr_desc| $solr_hort";
	}
	elsif ((length($solr_desc) > 1) && (length($solr_hort) > 1) && (length($solr_data) > 1)){
		$otherData="$solr_desc| $solr_hort| $solr_data";
	}
	elsif ((length($solr_desc) == 0) && (length($solr_hort) > 1) && (length($solr_data) > 1)){
		$otherData="$solr_hort| $solr_data";
	}
	elsif ((length($solr_desc) == 0) && (length($solr_hort) > 1) && (length($solr_data) == 0)){
		$otherData="$solr_hort";
	}
	elsif ((length($solr_desc) > 1) && (length($solr_hort) == 0) && (length($solr_data) > 1)){
		$otherData="$solr_desc| $solr_data";
	}
	elsif ((length($solr_desc) == 0) && (length($solr_hort) == 0) && (length($solr_data) > 1)){
		$otherData="$solr_data";
	}
	elsif ((length($solr_desc) == 0) && (length($solr_hort) == 0) && (length($solr_data) == 0)){
		$otherData="";
	}	
	else{
		&log_change("other data problem==>$solr_desc|$solr_hort|$solr_data\n");
		$otherData="";
	}

if (($id =~ m/^(UCLA\d+)/) && (length($otherData) == 0)){ 
	$otherData =~ s/.*/Transferred to UC from LA in 1977, to be cited as LA in UC/;
	&log_change("NOTE: UCLA specimen note added: $otherData\t==>\t$id\n");
}
elsif(($id =~ m/^(UCLA\d+)/) && (length($otherData) >= 1)){
	$otherData =~ s/^(.+)/$1; Transferred to UC from LA in 1977, to be cited as LA in UC/;
	&log_change("NOTE: UCLA specimen note added: $otherData\t==>\t$id\n");
}



my $solr_note = $othernotes{$csid}{'comment'};
foreach ($solr_note){
#fix some data quality and formatting problems	
	s/[,;:]$//g;
	s/  +/ /;
	s/^ $//;
	s/^ +//;
	s/ +$//;
	s/\n//;
}
++$count_record;
warn "$count_record\n" unless $count_record % 10000;




print CSID "$id\t$csid\n";
		print OUT <<EOP;
Accession_id: $id
Other_label_numbers:
Name: $scientificName
Date: $verbatimEventDate
EJD: $EJD
LJD: $LJD
Collector: $recordedBy
Other_coll: $other_collectors
Combined_coll: $verbatimCollectors
CNUM_prefix: $CNUM_prefix
CNUM: $CNUM
CNUM_suffix: $CNUM_suffix
Country: $country
State: $stateProvince
County: $county
Location: $locality
Habitat: $solr_habitat
T/R/Section: $TRS
Decimal_latitude: $decimalLatitude
Decimal_longitude: $decimalLongitude
Datum: $datum
Lat_long_ref_source: $georeferenceSource
Max_error_distance: $errorRadius
Max_error_units: $coordinateUncertaintyUnits
Elevation: $CCH_elevationInMeters
Verbatim_elevation: $verbatimElevation
Verbatim_county: $tempCounty
Macromorphology: $solr_macro
Micromorphology: $solr_micro
Population_biology: $solr_pop
Phenology: $solr_phen
Cytology: $solr_cyt
Reproductive_biology: $solr_biology
Other_data: $otherData
Color: $solr_color
Notes: $solr_note 
Cultivated: $cultivated
Hybrid_annotation: $hybrid_annotation
Image: $IMG{$csid}
EOP

#add one to the count of included records
++$included;

#this voucher section is not working.  It i parsing nonsensical informaiton into Associated species, skipping
#		foreach $voucher (
#			"VTM",
#			"Associated_species",
#			"Biotic_interactions",
#			"Color",
#			"Data_in_packet",
#			"Macromorphology",
#			"Micromorphology",
#			"Phenology",
#			"Population_biology",
#			"Reproductive_biology",
#			"Other_label_number",
#			"Horticulture"
#			){
#print "$SpecimenNumber $voucher--------->";
#			if($store_voucher{$csid}{$voucher}){
#				if(length($store_voucher{$csid}{$voucher}) > 1){
#					print OUT "$voucher: $store_voucher{$csid}{$voucher}\n";
			#print "$voucher: $store_voucher{$id}{$voucher}\n";
#				}
#				else{
				###These are voucher information like "includes macromorphology" from the SMASCH days, when existence of voucher information was indicated but not transcribed
				###We don't publish these, because it looks weird
#				print OUT "$voucher: data on label present, but not transcribed.\n";
				#print "$voucher: Data on label not transcribed.\n";
#				}
#			}
#		}
	if($store_voucher{$id}{TYPE}){
		print OUT "Type_status: $store_voucher{$csid}{TYPE}\n";
	}
	elsif($store_voucher{$id}{type}){
		print OUT "Type_status: $store_voucher{$csid}{type}\n";
	}
	print OUT $ANNO{$csid};
	print OUT "\n";


}


my $skipped_taxa = $count-($included+$skipped_nonvasc{non});
print <<EOP;
INCL: $included
EXCL: $skipped{one}
TOTAL: $count

SKIPPED TAXA: $skipped_taxa

SKIPPED NON_VASCULARS: $skipped_nonvasc{non}

EOP

close(IN);
close(OUT);


#    my $file_in = 'CSPACE_out.txt';	#the file this script will act upon is called 'CATA.out'
#open(IN,"$file_in" ) || die;

#while(<IN>){
#        chomp;



#####Check final output for characters in problematic formats (non UTF-8), this is Dick's accent_detector.pl
my @words;
my $word;
my $store;
my $match;
my %store;
my %match;
my %seen;
%seen=();


    my $file_in = '/JEPS-master/CCH/Loaders/CSPACE/CSPACE_out.txt';	#the file this script will act upon is called 'CATA.out'
open(IN,"$file_in" ) || die;

while(<IN>){
        chomp;
#split on tab, space and quote
        @words=split(/["        ]+/);
        foreach (@words){
                $word=$_;
#as long as there is a non-ascii string to delete, delete it
                while(s/([^\x00-\x7F]+)//){
#store the word it occurs in unless you've seen that word already

                        unless ($seen{$word . $1}++){
                                $store{$1} .= "$word\t";
                        }
                }
        }
}

	foreach(sort(keys(%store))){
#Get the hex representation of the accent
		$match=  unpack("H*", "$_"), "\n";
#add backslash-x for the pattern
		$match=~s/(..)/\\x$1/g;
#Print out the hex representation of the accent as it occurs in a pattern, followed by the accent, followed by the list of words the accent occurs in
				&log_skip("problem character detected: s/$match/    /g   $_ ---> $store{$_}\n\n");
	}
close(IN);