#This will produce insert statements for Committee and bioname which must be run first, and then
#this scriot rerun.
open(IN, "tnoan.out") || die;
while(<IN>){
chomp;
($id, $nan)=split(/\t/);
$NAN{$nan}=$id;
}
open(IN, "BNE") || die;
while(<IN>){
chomp;
($id, $bnn)=split(/\t/);
$bioname{$bnn}=$id;
}
open(IN, "nom_com") || die;
while(<IN>){
chomp;
($id, $an)=split(/\t/);
$author{$an}=$id;
}


#1. Get rid of ineds., formulas
#2. get rid of intermediate authors
#3. store all bionames, verify
#4. store all authors, verify
#5. get fam for bare genera
#6. check for spelling causes (e.g. A. nissenana!)
 #taxon_id parent_id bioname_id author_id ascr_auth_id p_author_id p_ascr_auth_id basionym_id rankkind_id data_src_id taxon_hier                            notho_taxon accessioned notes              CA mod_date   mod_by 
$undetermined=67936;
while(<DATA>){
 	$ascr_p_author=$ascr_author=$noauth_name=$bioname=$taxon_id=$parent_id=$bioname_id=$author_id=$ascr_auth_id=$p_author_id=$p_ascr_auth_id=$basionym_id=$rankkind_id=$data_src_id=$taxon_hier=$notho_taxon=$accessioned=$notes=$CA=$mod_date=$mod_by=$p_author=$author ="";
	next if m/ined\./;
	$problem=0;
	$ascr_p_author_id=$ascr_author_id=$p_author_id= $parent_id = $bioname_id = $rankkind_id = $author_id = $data_src_id = 0;
	chomp;
	s/^\d+ //;
	if(s/^([A-Z][a-z-]+ [a-z-]+ )(.*)(var\.|subsp\.)/$1$3/){
$autonym_author=$2;
}
	else{
$autonym_author="";
}
($noauth_name=$_)=~s/ [A-Z(].*//;
if($NAN{$noauth_name}){
#print " OK $_\n";
next;
}
	#print "$_\n";
	if(m/^(([A-Z][^ ]+ [^ ]+) (var\.|subsp\.)) ([a-z-]+) ([(A-Z].*)/){
		$nan=$2;
		$rank=$3;
		$bioname=$4;
		$author=$5; 
($author_id, $p_author_id, $ascr_author_id, $ascr_p_author_id)=&process_author($author);
$problem=1 unless $author_id;
		if($NAN{$nan}){
			$parent_id=$NAN{$nan};
		}
		else{
			print "1 $nan unidentified\n";
			next;
		}
		if($bioname{$bioname}){
			$bioname_id=$bioname{$bioname};
		}
		else{
			$problem=1;
#print "A\n";
			&insert_bioname($bioname);
		}
		($rankkind_id="'$rank'")=~s/\.//;
		$data_src_id=39;
		unless ($problem){
			push(@taxon_name, <<EOP
print "$_" insert into taxon_name (parent_id, bioname_id, rankkind_id, author_id, p_author_id, data_src_id, ascr_auth_id, p_ascr_auth_id) values ($parent_id, $bioname_id, $rankkind_id, $author_id, $p_author_id, $data_src_id, $ascr_author_id, $ascr_p_author_id)
EOP
);
	}
	}
	elsif(m/^([A-Z][^ ]+ ([^ ]+)) (var\.|subsp\.) (\2)/){
		$nan=$1;
		$rank=$3;
		$bioname=$2;
		$author=$autonym_author;
($author_id, $p_author_id, $ascr_author_id, $ascr_p_author_id)=&process_author($author);
$problem=1 unless $author_id;
		if($NAN{$nan}){
			$parent_id=$NAN{$nan};
		}
		else{
			print "1 $nan unidentified\n";
			next;
		}
		if($bioname{$bioname}){
			$bioname_id=$bioname{$bioname};
		}
		else{
			$problem=1;
#print "A\n";
			&insert_bioname($bioname);
		}
		($rankkind_id="'$rank'")=~s/\.//;
		$data_src_id=39;
		unless ($problem){
			push(@taxon_name, <<EOP
print "$_" insert into taxon_name (parent_id, bioname_id, rankkind_id, author_id, p_author_id, data_src_id, ascr_auth_id, p_ascr_auth_id) values ($parent_id, $bioname_id, $rankkind_id, $author_id, $p_author_id, $data_src_id, $ascr_author_id, $ascr_p_author_id)
EOP
);
	}
	}
	elsif(m/^([A-Z][^ ]+)$/){
		$genus=$1;
		$parent_id=$undetermined;
		if($bioname{$genus}){
			$bioname_id=$bioname{$genus};
			$rankkind_id="'gen'"; $author_id=0; $data_src_id=39;
			unless($genus=~/ceae$/){
				push(@taxon_name, <<EOP
print "$_" insert into taxon_name (parent_id, bioname_id, rankkind_id, author_id, data_src_id) values ($parent_id, $bioname_id, $rankkind_id, $author_id, $data_src_id)
EOP
);
			}
		}
		else{
			$problem=1;
#print "B\n";
			&insert_bioname($bioname);
		}
	}
	elsif(m/^([A-Z][^ ]+) ([(A-Z].*)/){
		$genus=$1; $author=$2; $parent_id=$undetermined;
($author_id, $p_author_id, $ascr_author_id, $ascr_p_author_id)=&process_author($author);
$problem=1 unless $author_id;
		if($bioname{$genus}){
			$bioname_id=$bioname{$genus};
			$rankkind_id="'gen'";
		}
		else{
			$problem=1;
#print "C\n";
			&insert_bioname($genus);
		}
			$data_src_id=39;
			unless($genus=~/ceae$/){
				unless($problem){
				push(@taxon_name, <<EOP
print "$_" insert into taxon_name (parent_id, bioname_id, rankkind_id, author_id, p_author_id, data_src_id, ascr_auth_id, p_ascr_auth_id) values ($parent_id, $bioname_id, $rankkind_id, $author_id, $p_author_id, $data_src_id, $ascr_author_id, $ascr_p_author_id)
EOP
);
		}
	}
}
	elsif(m/^([A-Z][^ ]+) ([^ ]+) ([(A-Z].*)/){
		$nan=$1;
				if($NAN{$nan}){
						$parent_id=$NAN{$nan};
				}
				else{
#print "D $nan\n";
					if($bioname{$nan}){
						print "need generic name $nan\n";
						$problem=1;
					}
					else{
						&insert_bioname($nan);
						$problem=1;
					}
				}
				$bioname=$2;
				if($bioname{$bioname}){
						$bioname_id=$bioname{$bioname};
				}
				else{
#print "E\n";
					&insert_bioname($bioname);
					$problem=1;
				}
		$author=$3;
($author_id, $p_author_id, $ascr_author_id, $ascr_p_author_id)=&process_author($author);
$problem=1 unless $author_id;
				$data_src_id=39;
				$rankkind_id="'sp'";
unless($problem){
				push(@taxon_name, <<EOP
print "$_" insert into taxon_name (parent_id, bioname_id, rankkind_id, author_id, p_author_id, data_src_id, ascr_auth_id, p_ascr_auth_id) values ($parent_id, $bioname_id, $rankkind_id, $author_id, $p_author_id, $data_src_id, $ascr_author_id, $ascr_p_author_id)
EOP
);
}
		}
	elsif(m/^([A-Z][^ ]+) . ([^ ]+) ([(A-Z].*)/){
		$nan=$1;
				if($NAN{$nan}){
						$parent_id=$NAN{$nan};
				}
				else{
#print "D $nan\n";
					&insert_bioname($nan);
				$problem=1;
				}
				$bioname=$2;
				if($bioname{$bioname}){
						$bioname_id=$bioname{$bioname};
				}
				else{
#print "E\n";
					&insert_bioname($bioname);
					$problem=1;
				}
		$author=$3;
($author_id, $p_author_id, $ascr_author_id, $ascr_p_author_id)=&process_author($author);
$problem=1 unless $author_id;
				$data_src_id=39;
				$rankkind_id="'sp'";
unless($problem){
				push(@taxon_name, <<EOP
print "$_" insert into taxon_name (parent_id, bioname_id, rankkind_id, author_id, p_author_id, data_src_id, ascr_auth_id, p_ascr_auth_id, notho_taxon) values ($parent_id, $bioname_id, $rankkind_id, $author_id, $p_author_id, $data_src_id, $ascr_author_id, $ascr_p_author_id, 1)
EOP
);
}
		}
else{print "Fallthru $_\n";}
}
sub author_insert {
local($_)=shift;
push(@committee, <<EOP
insert into committee (committee_abbr, chair_id, committee_func) values ("$_", 0, nomen)
EOP
);
}
sub insert_bioname{
local($bioname)=shift;
unless($seen{$bioname}++){
			push(@bioname, <<EOP
print "$bioname" insert into bioname (bioname_element, data_src_id) values ("$bioname", 39)
go

EOP
);
}
}
foreach(sort(@committee)){
print "$_";
}
foreach(sort(@bioname)){
print "$_";
}
foreach(sort(@taxon_name)){
print "$_";
}
sub process_author {
#($author_id, $p_author_id, $ascr_author_id, $ascr_p_author_id)=&process_author($author);
my($problem);
	my ($author)=shift;
	if($author=~m/\((.*)\) (.*)/){
			$author=$2; $p_author=$1;
		}
	$author=~s/ *$//;
	$p_author=~s/ *$//;
	if($p_author=~ s/(.*) ex (.*)/$2/){
		$ascr_p_author=$1;
	}
	if($author=~ s/(.*) ex (.*)/$2/){
		$ascr_author=$1;
	}
	if($author{$author}){
			$author_id=$author{$author};
	}
	else{
		$problem=1;
		unless($seen{$author}++){
			&author_insert($author);
		}
	}
	if($p_author){
		if($author{$p_author}){
			$p_author_id=$author{$p_author};
		}
		else{
			$problem=1;
			&author_insert($p_author) unless $seen{$p_author}++;
		}
	}
	if($ascr_p_author){
		if($author{$ascr_p_author}){
				$ascr_p_author_id=$author{$ascr_p_author};
		}
		else{
			$problem=1;
			&author_insert($ascr_p_author) unless $seen{$ascr_p_author}++;
			}
		}
	if($ascr_author){
		if($author{$ascr_author}){
			$ascr_author_id=$author{$ascr_author};
		}
		else{
			$problem=1;
			&author_insert($ascr_author) unless $seen{$ascr_author}++;
		}
	}
	if($promlem){
	return(0);
	}
	else{
return($author_id, $p_author_id, $ascr_author_id, $ascr_p_author_id);
}

}
__END__
88216 Acmispon wrangelianus (Fisch. & C. A. Mey.) D. D. Sokoloff
88031 Agnorhiza
88032 Agnorhiza bolanderi (A. Gray) W. A. Weber
88033 Agnorhiza elata (H. M. Hall) W. A. Weber
88034 Agnorhiza invenusta (Greene) W. A. Weber
88035 Agnorhiza ovata (Torr. & A. Gray) W. A. Weber
88036 Agnorhiza reticulata (Greene) W. A. Weber
88037 Agoseris dasycarpa Greene
88295 Aloe saponaria (Aiton) Haw. x Aloe striata Haw.
88296 Aloe x schoenlandii Baker
88002 Alternanthera ficoidea (L.) P. Beauv. var. bettzickiana (Regel) Backer
88038 Ambrosia bipinnatifida (Nutt.) Greene
88039 Ambrosia x platyspina (Seaman) Strother & B. G. Baldwin
88446 Amelanchier utahensis Koehne var. covillei (Standl.) N. H. Holmgren
88447 Amelanchier utahensis Koehne var. utahensis
88352 Amphibromus neesii Steud.
88135 Amsinckia brandegeeae Suksd.
88467 Antirrhinum vexillocalyculatum Kellogg subsp. breweri (A. Gray) D. M. Thomps.
88468 Antirrhinum vexillocalyculatum Kellogg subsp. intermedium D. M. Thomps.
88469 Antirrhinum vexillocalyculatum Kellogg subsp. vexillocalyculatum
88026 Aponogeton distachyon L. f.
88142 Arabis x divaricarpa A. Nelson
88208 Arctostaphylos nissenana Merriam
88041 Arctotis fastuosa Jacq.
88042 Argyranthemum foeniculum (Willd.) Sch. Bip.
88213 Argythamnia claryana Jeps.
88043 Arnica chamissonis Less. var. andina (Nutt.) Ediger & F. A. Barkley
88353 Arrhenatherum elatius (L.) J. Presl & C. Presl subsp. bulbosum (Willd.) Sch&uuml;bl. & Martens
88044 Artemisia arbuscula Nutt. subsp. longicaulis Winward & McArthur
88045 Artemisia campestris L. var. scouleriana (Hook.) Cronquist
88028 Arum palaestinum Boiss.
88297 Asparagus aethiopicus L.
88046 Aster bicolor (L.) Nees
88217 Astragalus gambelianus E. Sheld. var. elmeri (Greene) J. T. Howell
88218 Astragalus gambelianus E. Sheld. var. gambelianus
88219 Astragalus pulsiferae A. Gray var. coronensis S. L. Welsh, Ondricek, & G. Clifton
88220 Astragalus tegetarioides M. E. Jones var. anxius (Meinke & Kaye) S. L. Welsh
88003 Atriplex canescens (Pursh) Nutt. var. angustifolia (Torr.) S. Watson
88004 Atriplex cordulata Jeps. var. cordulata
88005 Atriplex cordulata Jeps. var. erecticaulis (Stutz, G. L. Chu, & S. C. Sand.) S. L. Welsh
88006 Atriplex coronata S. Watson var. vallicola (Hoover) S. L. Welsh
88007 Atriplex covillei (Standl.) J. F. Macbr.
88008 Atriplex parishii S. Watson var. depressa (Jeps.) S. L. Welsh
88009 Atriplex parishii S. Watson var. minuscula (Standl.) S. L. Welsh
88010 Atriplex parishii S. Watson var. parishii
88011 Atriplex parishii S. Watson var. persistens (Stutz & G. L. Chu) S. L. Welsh
88012 Atriplex parishii S. Watson var. subtilis (Stutz & G. L. Chu) S. L. Welsh
88267 Bermudiana bella (S. Watson) Greene
88268 Bermudiana californica (Ker Gawl.) Greene
88269 Bermudiana grandiflora (Douglas) Kuntze
88407 Bistorta officinalis Delarbre
88143 Boechera demissa (Greene) W. A. Weber var. pendulina (Greene) N. H. Holmgren
88144 Boechera hirshbergiae (S. Boyd) Al-Shehbaz
88145 Boechera holboellii (Hornem.) ?. L?ve & D. L?ve var. pendulocarpa (A. Nelson) N. Snow
88146 Boechera selbyi (Rydb.) W. A. Weber var. inyoensis (Rollins) N. H. Holmgren
88329 Botrychium simplex E. Hitchc. var. fontanum Farrar ined.
88354 Brachypodium phoenicoides (L.) Roem. & Schult.
88482 Brodiaea californica Lindl. subsp. californica
88483 Brodiaea californica Lindl. subsp. leptandra (Greene) J. C. Pires
88298 Bulbine semibarbata (R. Br.) Haw.
88158 Bursera hindsiana (Benth.) Engl.
88355 Calamagrostis canadensis (Michx.) P. Beauv. var. langsdorffii (Link) Inman
88221 Calia secundiflora (Ortega) Yakovlev
88190 Carex deflexa Hornem. var. boottii L. H. Bailey
88191 Carex klamathensis B. L. Wilson & Janeway
88192 Carex livida (Wahlenb.) Willd. var. radicalis Paine
88470 Castilleja fruticosa Moran
88437 Ceanothus arboreus Greene var. glaber Jeps.
88170 Celtis australis L.
88356 Cenchrus spinifex Cav.
88047 Centaurea babylonica L.
88048 Centaurea x moncktonii C. E. Britton
88049 Centaurea x pratensis Thuill.
88257 Centaurium arizonicum (A. Gray) A. Heller
88222 Cercis orbiculata Greene
88473 Cestrum elegans (Brongn.) Schltdl.
88448 Chaenomeles sinensis (Thouin) Koehne
88214 Chamaesyce ocellata (Durand & Hilg.) Millsp. var. kirbyi J. T. Howell
88050 Chamomilla suffruticosa (L.) Rydb.
88013 Chenopodium album L. var. striatum (Krasan), comb. nov. ined.
88014 Chenopodium berlandieri Moq. var. zschackei (Murr) Murr ex Aschers.
88051 Chorisiva nevadensis Rydb.
88052 Chrysothamnus californicus Greene
88053 Chrysothamnus nauseosus (Pall. ex Pursh) Britton subsp. viridulus (H. M. Hall) H. M. Hall & Clem.
88054 Chrysothamnus nauseosus (Pall. ex Pursh) Britton subsp. viscosus D. D. Keck
88055 Chrysothamnus nauseosus (Pall. ex Pursh) Britton var. macrophyllus J. T. Howell
88056 Chrysothamnus parryi (A. Gray) Greene subsp. bolanderi (A. Gray) H. M. Hall & Clem.
88057 Chrysothamnus viscidiflorus (Hook.) Nutt. subsp. viscidiflorus var. latifolius (D. C. Eaton) Greene
88058 Cirsium scariosum Nutt. var. congdonii (R. J. Moore & Frankton) D. J. Keil
88059 Cirsium scariosum Nutt. var. robustum D. J. Keil
88491 Cissus antarctica Venten.
88147 Cleomella hillmanii A. Nelson var. hillmanii
88148 Cleomella plocasperma S. Watson var. mohavensis Crum
88403 Collomia tinctoria Kellogg subvar. luxuriosa Brand
88258 Comastoma tenellum (Rottb.) Toyok.
88259 Comastoma tenellum (Rottb.) Toyok. var. tenellum
88186 Convolvulus tricolor L.
88330 Corallorrhiza Gagnebin
88449 Cotoneaster microphylla Lindl.
88450 Cotoneaster pannosa Franch.
88451 Crataegus castlegarensis J. B. Phipps & O'Kennon
88189 Cucurbita pepo L. var. medullosa Alef.
88187 Cuscuta denticulata Engelm. var. veatchii (Brandegee) T. Beliz ined.
88060 Cyclachaena xanthiifolia (Nutt.) Fresen.
88023 Cyclospermum Lag.
88024 Cyclospermum leptophyllum (Pers.) Sprague ex Britton & P. Wilson
88452 Cydonia sinensis Thouin
88159 Cylindropuntia bigelovii (Engelm.) F. M. Knuth var. bigelovii
88160 Cylindropuntia californica (Torr. & A. Gray) F. M. Knuth var. parkeri (J. M. Coult.) Pinkava
88161 Cylindropuntia munzii (C. B. Wolf) Backeb.
88162 Cylindropuntia wigginsii (L. D. Benson) H. Rob.
88163 Cylindropuntia x fosbergii (C. B. Wolf) Rebman, M. A. Baker & Pinkava
88164 Cylindropuntia x wigginsii (L. D. Benson) H. Rob.
88193 Cyperus esculentus L. var. heermannii (Buckley) Britton
88194 Cyperus prolifer Lam.
88223 Dalea occidentalis (A. Heller) Isely
88061 Deinandra ramosissima ined.
88436 Delphinium inflexum Davidson
88062 Dendranthema grandiflorum Kitam.
88171 Dianthus plumarius L. subsp. plumarius
88357 Dichanthelium acuminatum (Sw.) Gould & C. A. Clark subsp. acuminatum
88358 Dichanthelium acuminatum (Sw.) Gould & C. A. Clark subsp. fasciculatum (Torr.) Freckmann & Lelong
88359 Dichanthelium acuminatum (Sw.) Gould & C. A. Clark subsp. lindheimeri (Nash) Freckmann & Lelong
88360 Dichanthelium acuminatum (Sw.) Gould & C. A. Clark subsp. thermale (Bol.) Freckmann & Lelong
88361 Dichanthelium oligosanthes (Schult.) Gould subsp. scribnerianum (Nash) Freckmann & Lelong
88484 Dichelostemma venustum (Greene) Hoover
88063 Dimorphotheca pluvialis (L.) Moench
88362 Dinebra retroflexa (Vahl.) Panz. var. retroflexa
88341 Diplacus bifidus (Pennell) unknown
88342 Diplacus flemingii unknown
88343 Diplacus longiflorus Nutt. subsp. lompocensis (McMinn) ined.
88224 Dipogon lignosus (L.) Verdc.
88001 Disphyma australe (Aiton) J. M. Black
88204 Drosera aliciae Raym.-Hamet
88205 Drosera capensis L.
88188 Dudleya abramsii subsp. calcicola (Bartel & Shevock) K. M. Nakai
88195 Dulichium arundinaceum (L.) Britton var. arundinaceum
88015 Dysphania anthelmintica (L.) Mosyakin & Clemants
88016 Dysphania botrys (L.) Mosyakin & Clemants
88017 Dysphania chilensis (Schrad.) Mosyakin & Clemants
88363 Echinochloa crus-galli (L.) P. Beauv. subsp. spiralis (Vasinger) Tzvelev
88136 Echium lusitanicum L.
88137 Echium strictum L. f.
88337 Ehrendorferia chrysantha (Hook. & Arn.) Rylander
88338 Ehrendorferia ochroleuca (Engelm.) Fukuhara
88196 Eleocharis coloradoensis (Britton) Gilly
88265 Elodea brandegeeae H. St. John
88364 Elytrigia juncea (L.) Nevski subsp. boreo-atlantica (Simonet & Guin.) Hyl.
88064 Encelia californica x Encelia farinosa
88065 Encelia farinosa A. Gray ex Torr. x Encelia frutescens (A. Gray) A. Gray
88206 Ephedra altissima Desf.
88207 Ephedra distachya L.
88066 Erechtites hieraciifolius (L.) DC. var. hieraciifolius
88365 Eremochloa leersioides (Munro) Hack.
88172 Eremogone cliftonii Rabeler & R. L. Hartm. ined. [Rabeler & R. L. Hartm., submitted to Madrono]
88173 Eremogone congesta (Nutt.) Ikonn. var. charlestonensis (Maguire) R. L. Hartm. & Rabeler
88174 Eremogone congesta (Nutt.) Ikonn. var. simulans (Maguire) R. L. Hartm. & Rabeler
88067 Ericameria nauseosa (Pall.) G. L. Nesom & G. I. Baird var. arta (A. Nelson) G. L. Nesom & G. I. Baird
88068 Ericameria x bolanderi (A. Gray) G. L. Nesom & G. I. Baird
88069 Ericameria x viscosa (D. D. Keck) G. L. Nesom & G. I. Baird
88070 Erigeron clokeyi Cronquist var. pinzliae G. L. Nesom
88072 Erigeron pumilus Nutt. var. gracilior Cronquist
88408 Eriogonum apiculatum S. Watson var. apiculatum
88409 Eriogonum apiculatum S. Watson var. galbinum Reveal & A. Sanders ined.
88410 Eriogonum callistum Reveal
88411 Eriogonum marifolium Torr. & A. Gray var. cupulatum (S. Stokes) Reveal
88412 Eriogonum microthecum Nutt. var. lacus-ursi Reveal & A. Sanders
88413 Eriogonum microthecum Nutt. var. schoolcraftii Reveal
88414 Eriogonum oblongifolium Benth.
88415 Eriogonum prociduum Reveal var. prociduum
88416 Eriogonum rupicola Reveal ined.
88417 Eriogonum umbellatum Torr. var. canifolium Reveal
88418 Eriogonum umbellatum Torr. var. nelsonii Reveal ined.
88419 Eriogonum ursinum S. Watson var. erubescens Reveal & J. Knorr
88073 Eriophyllum lanatum (Pursh) J. Forbes var. achilleoides (DC.) Jeps.
88074 Eriophyllum staechadifolium Lag.
88149 Erysimum insulare Greene var. grandifolium Rossbach ined.
88150 Erysimum insulare Greene var. insulare
88151 Erysimum suffrutescens (Abrams) Rossbach var. grandiflorum Rossbach
88325 Eucalyptus lehmannii (Schauer) Benth.
88326 Eucalyptus torquata Luehm.
88075 Euchiton japonicus (Thunb.) Holub
88215 Euphorbia rigida M. Bieb.
88076 Eurybia merita (A. Nelson) G. L. Nesom
88420 Fallopia japonica (Houtt.) Ronse Decr.
88421 Fallopia japonica (Houtt.) Ronse Decr. var. japonica
88422 Fallopia sachalinensis (F. Schmidt) Ronse Decr.
88165 Ferocactus viridescens (Torr. & A. Gray) Britton & Rose var. viridescens
88366 Festuca ammobia Pavlick
88367 Festuca californica Vasey subsp. californica
88368 Festuca californica Vasey subsp. hitchcockiana (E. B. Alexeev) Darbysh.
88369 Festuca californica Vasey subsp. parishii (Piper) Darbysh.
88370 Festuca roemeri (Pavlick) E. B. Alexeev var. klamathensis B. L. Wilson
88371 Festuca roemeri (Pavlick) E. B. Alexeev var. roemeri
88197 Fimbristylis littoralis Gaudich.
88077 Franseria bipinnatifida Nutt.
88327 Fraxinus jonesii Lingelsh.
88328 Fraxinus trifoliata (Torr.) F. H. Lewis & Epling
88025 Funastrum cynanchoides (Decne.) Schltr. subsp. heterophyllum (Engelm. ex Torr.) Kartesz
88078 Gamochaeta stachydifolia (Lam.) Cabrera
88225 Genista aetnensis (Biv.) DC.
88264 Geranium pyrenaicum Burm. f. subsp. pyrenaicum
88404 Gilia grinnellii Brand
88079 Glebionis coronaria (L.) Spach var. coronaria
88080 Glebionis coronaria (L.) Spach var. discolor (d'Urv.) Turland
88372 Glyceria davyi (Merr.) Tzvelev
88081 Gnaphalium luteoalbum L.
88082 Grindelia fraxinipratensis Reveal & Beatley
88083 Grindelia papposa G. L. Nesom & Y. B. Suh
88166 Grusonia parishii (Orcutt) Pinkava
88167 Grusonia pulchella (Engelm.) H. Rob.
88185 Halimium lasianthum (Lam.) Spach
88029 Hedera helix L. subsp. canariensis (Willd.) Cout.
88030 Hedera helix L. subsp. helix
88084 Helianthus maximilianii Schrad.
88085 Helipterum roseum (Hook.) Benth.
88339 Hesperomecon filiformis Fedde
88086 Heterotheca echioides (Benth.) Shinners var. bolanderi (A. Gray) G. L. Nesom
88087 Heterotheca echioides (Benth.) Shinners var. bolanderioides (Semple) G. L. Nesom
88093 Heterotheca sessiliflora (Nutt.) Shinners var. bolanderioides Semple
88094 Heterotheca sessiliflora (Nutt.) Shinners var. camphorata (Eastw.) Semple
88095 Heterotheca sessiliflora (Nutt.) Shinners var. echioides (Benth.) Semple
88096 Heterotheca sessiliflora (Nutt.) Shinners var. fastigiata (Greene) Semple
88097 Heterotheca sessiliflora (Nutt.) Shinners var. sessiliflora
88098 Heterotheca subaxillaris (Lam.) Britton & Rusby subsp. latifolia (Buckley) Semple
88099 Hieracium gracile Hook. subvar. densifloccum Zahn
88314 Hoheria populnea A. Cunn.
88270 Hydastylus longipes E. P. Bicknell
88271 Hydastylus rivularis E. P. Bicknell
88266 Hypericum hookerianum Wight & Arn.
88027 Ilex attenuata Ashe
88374 Ischaemum leersioides Munro
88288 Isoetes tenella L&eacute;man
88272 Ixia campanulata Houtt.
88273 Ixia polystachya L.
88274 Ixia speciosa Andrews
88375 Jarava plumosa (Spreng.) S. W. L. Jacobs & J. Everett
88423 Johanneshowellia puberula (S. Watson) Reveal
88289 Juncus anthelatus (Wiegand) R. E. Brooks
88290 Juncus lesueurii Bol. var. tracyi Jeps.
88018 Kochia scoparia (L.) Schrad. subsp. scoparia
88100 Lasiospermum bipinnatum (Thunb.) Druce
88226 Lathyrus nevadensis S. Watson var. nuttallii (S. Watson) C. L. Hitchc.
88227 Lathyrus nevadensis S. Watson var. pilosellus (M. Peck) C. L. Hitchc.
88101 Leontodon muelleri (Sch. Bip.) Fiori
88102 Leptosyne calliopsidea (DC.) A. Gray
88103 Leptosyne maritima (Nutt.) A. Gray
88376 Leymus californicus (Bol. ex Thurb.) Barkworth
88104 Logfia arizonica (A. Gray) Holub
88105 Logfia californica (Nutt.) Holub
88106 Logfia depressa (A. Gray) Holub
88107 Lorandersonia peirsonii (D. D. Keck) Urbatsch, R. P. Roberts & Neubig
88228 Lotus argophyllus (A. Gray) Greene var. ornithopus (Greene) Ottley x L. dendroideus (Greene) Greene var. traskiae (Noddin) Isely
88229 Lupinus arbustus Douglas var. montanus (Howell) D. B. Dunn
88238 Lupinus polyphyllus Lindl. subsp. bernardinus (Abrams ex C. P. Sm.) Munz
88239 Lupinus polyphyllus Lindl. var. grandifolius (Lindl. ex J. Agardh) Torr. & A. Gray
88240 Lupinus propinquus Greene
88244 Lupinus x alpestris A. Nelson
88474 Lycianthes rantonnetii (Lesc.) Bitter
88475 Lycium ferocissimum Miers
88315 Malva assurgentiflora (Kellogg) M. F. Ray
88316 Malva dendromorpha M. F. Ray
88317 Malva linnaei M. F. Ray
88275 Marica californica Ker Gawl.
88245 Medicago muricata author citation uncertain
88019 Micromonolepis pusilla (Torr. ex S. Watson) Ulbr.
88405 Microsteris gracilis (Hook.) Greene subsp. humilior (Greene) H. Mason ined.
88344 Mimulus langsdorffii Donn ex Greene var. californicus Jeps.
88345 Mimulus langsdorffii Donn ex Greene var. insignis Greene
88108 Monolopia bahiifolia Benth. var. pinnatifida A. Gray
88276 Moraea polystachya Ker Gawl.
88424 Muehlenbeckia hastulata (Sm.) I. M. Johnst. var. hastulata
88377 Muhlenbergia alopecuroides (Griseb.) P. M. Peterson & Columbus, comb. ined.
88109 Mulgedium oblongifolium (Nutt.) Reveal
88299 Narcissus papyraceus Ker Gawl.
88378 Nassella manicata (Desv.) Barkworth
88138 Nemophila rotata Eastw.
88110 Nestotus stenophyllus (A. Gray) R. P. Roberts, Urbatsch & Neubig
88476 Nicotiana x sanderorum W. Wats.
88152 Noccaea fendleri (A. Gray) Holub
88153 Noccaea fendleri (A. Gray) Holub subsp. californica (S. Watson) Al-Shehbaz & M. Koch
88154 Noccaea fendleri (A. Gray) Holub subsp. glauca (A. Nelson) Al-Shehbaz & M. Koch
88300 Nothoscordum borbonicum Kunth
88277 Olsynium grandiflorum (Douglas) Raf.
88168 Opuntia curvispina Griffiths
88169 Opuntia x curvispina Griffiths
88246 Otholobium fruticans (L.) Stirton
88336 Oxalis bowiei W. T. Aiton ex G. Don
88379 Panicum alatum Zuloaga & Morrone
88380 Panicum alatum Zuloaga & Morrone var. alatum
88381 Panicum alatum Zuloaga & Morrone var. longiflorum Zuloaga & Morrone
88382 Panicum alatum Zuloaga & Morrone var. minus (Andersson) Zuloaga & Morrone
88383 Panicum capillare L. subsp. hillmanii (Chase) Freckmann & Lelong
88340 Passiflora cerulea L.
88384 Pennisetum ciliare (L.) Link var. ciliare
88111 Pericallis cruenta (DC.) Webb & Berthel.
88425 Persicaria bistortoides (Pursh) H. R. Hinds
88426 Persicaria maculosa Gray
88427 Persicaria wallichii Greuter & Burdet
88428 Persicaria wallichii Greuter & Burdet var. wallichii
88139 Phacelia eisenii Brandegee var. brandegeeana J. T. Howell
88140 Phacelia imbricata Greene subvar. hansenii Brand
88141 Phacelia tanacetifolia Benth. subvar. tenuisecta Brand
88385 Phalaris coerulescens Desf.
88453 Photinia davidsoniae Rehder & Wilson
88386 Phragmites australis (Cav.) Steud. subsp. americanus Saltonstall, P. M. Peterson, & Soreng
88387 Phragmites australis (Cav.) Steud. subsp. berlandieri (E. Fourn.) Saltonstall & Hauber
88477 Physalis lancifolia Nees
88155 Physaria occidentalis (S. Watson) O'Kane & Al-Shehbaz subsp. occidentalis
88292 Pinguicula macroceras Link subsp. nortensis J. Steiger & J. H. Rondeau
88388 Piptatherum exiguum (Thurb.) Dorn
88349 Pittosporum ralphii T. Kirk
88350 Plantago juncoides Lam. var. californica Fernald
88351 Plantago sempervirens Crantz
88331 Platanthera foetida Geyer ex Hook. f.
88332 Platanthera purpurascens (Rydb.) Sheviak & W. F. Jenn.
88333 Platanthera x correllii W. J. Schrenk
88334 Platanthera x estesii W. J. Schrenk
88335 Platanthera x lassenii W. J. Schrenk
88389 Pleuraphis mutica Buckl.
88390 Poa x limosa Scribn. & T. A. Williams
88429 Polygonum fowleri B. L. Rob. subsp. fowleri
88430 Polygonum multiflorum Thunb.
88431 Polygonum ramosissimum Michx. subsp. prolificum (Small) Costea & Tardif
88432 Polygonum ramosissimum Michx. subsp. ramosissimum
88391 Polypogon imberbis (Phil.) Johow
88324 Proboscidea parviflora (Wooton) Wooton & Standl. var. parviflora
88455 Pyracantha crenatoserrata (Hance) Rehder
88456 Pyracantha crenulata (D. Don) M. Roem.
88256 Quercus x kinseliae (C. H. Mull.) Nixon & C. H. Mull.
88438 Rhamnus purshiana DC. var. annonifolia (Greene) Jeps.
88439 Rhamnus purshiana DC. var. purshiana
88440 Rhamnus rubra Greene var. modocensis (C. B. Wolf) McMinn
88441 Rhamnus rubra Greene var. nevadensis (A. Nelson) C. B. Wolf
88442 Rhamnus rubra Greene var. obtusissima (Greene) Jeps.
88444 Rhamnus rubra Greene var. rubra
88445 Rhamnus rubra Greene var. yosemitana (C. B. Wolf) McMinn
88210 Rhododendron neoglandulosum Harmaja
88211 Rhododendron x columbianum (Piper) Harmaja
88198 Rhynchospora kunthii Nees ex Kunth
88199 Rhynchospora recognita (Gale) Kral
88457 Rosa serafinii Viv.
88458 Rubus armeniacus Focke
88433 Rumex britannica L.
88434 Rumex palustris Sm.
88435 Rumex x erubescens Simonk.
88392 Rytidosperma clavatum (Zotov) Connor & Edgar
88393 Rytidosperma pilosum (R. Br.) Connor & Edgar
88394 Rytidosperma semiannulare (Labill.) Connor & Edgar
88461 Salix eriocephala Michx. subsp. mackenzieana (Hook.) Dorn
88462 Salix eriocephala Michx. var. eriocephala
88463 Salix eriocephala Michx. var. ligulifolia (C. R. Ball ex C. K. Schneid.) Dorn
88464 Salix eriocephala Michx. var. watsonii (Bebb) Dorn
88465 Salix lasiolepis Benth. var. tracyi (C. R. Ball) Argus ined.
88020 Salsola kali L. subsp. pontica (Pall.) Mosyakin
88466 Sarracenia aff. rubra Walter
88022 Schinus terebinthifolius Raddi var. raddianus Engl.
88200 Schoenoplectus glaucus (Lam.) Kartesz
88202 Scirpus prolifer Rottb.
88203 Scirpus ? rubiginosus Beetle
88291 Scutellaria caerulea Moc. & Sesse
88472 Selaginella arizonica Maxon subsp. eremophila (Maxon) Windham & Yatsk. ined.
88112 Senecio ammophilus Greene
88113 Senecio bicolor (Willd.) Tod. subsp. cineraria (DC.) Chater
88114 Senecio glomeratus Desf. ex Poir.
88247 Senna nemophila (A. Cunn.) ined.
88115 Sericocarpus oregonensis Nutt. var. californicus (Durand) G. L. Nesom
88116 Sericocarpus oregonensis Nutt. var. oregonensis
88395 Setaria pumila (Poir.) Roem. & Schult. subsp. pallidefusca (Schumach.) B. K. Simon
88396 Setaria pumila (Poir.) Roem. & Schult. subsp. pumila
88318 Sidalcea malviflora (DC.) Benth. subsp. laciniata C. L. Hitchc. var. laciniata C. L. Hitchc.
88319 Sidalcea malviflora (DC.) Benth. subsp. laciniata C. L. Hitchc. var. sancta C. L. Hitchc.
88175 Silene coniflora Nees ex Otth
88176 Silene dichotoma Ehrh. subsp. dichotoma
88177 Silene laciniata Cav. subsp. californica (Durand) J. K. Morton
88178 Silene pseudatocion Desf.
88182 Silene verecunda S. Watson var. verecunda
88278 Sisyrinchium angustifolium Miller var. bellum (S. Watson) Baker
88279 Sisyrinchium bermudiana L. var. minus (Engelm. & A. Gray) Klatt
88280 Sisyrinchium brachypus (E. P. Bicknell) Henry
88281 Sisyrinchium flavidum Kellogg
88282 Sisyrinchium grandiflorum Douglas ex Lindl.
88283 Sisyrinchium leptocaulon E. P. Bicknell
88284 Sisyrinchium lineatum Torrey
88285 Sisyrinchium oreophilum E. P. Bicknell
88286 Sisyrinchium oreophilum E. P. Bicknell var. occidentale (E. P. Bicknell) D. M. Henderson
88478 Solanum scabrum Mill.
88118 Solidago simplex Kunth var. spathulata (DC.) Cronquist
88183 Spergularia media (L.) C. Presl var. media
88184 Spergularia platensis (Cambess.) Fenzl var. platensis
88460 Spiraea x hitchcockii W. J. Hess & Stoynoff
88156 Streptanthus longisiliquus G. Clifton & R. E. Buck
88119 Symphyotrichum campestre (Nutt.) G. L. Nesom var. bloomeri (Nutt.) G. L. Nesom
88120 Symphyotrichum campestre (Nutt.) G. L. Nesom var. campestre
88121 Symphyotrichum chilense (Nees) G. L. Nesom var. chilense
88122 Symphyotrichum chilense (Nees) G. L. Nesom var. invenustum (Greene) G. L. Nesom
88123 Symphyotrichum chilense (Nees) G. L. Nesom var. medium (Jeps.) G. L. Nesom
88124 Symphyotrichum expansum (Poepp. ex Spreng.) G. L. Nesom
88125 Symphyotrichum foliaceum (Lindl. ex DC.) G. L. Nesom var. apricum (A. Gray) G. L. Nesom
88126 Symphyotrichum foliaceum (Lindl. ex DC.) G. L. Nesom var. canbyi (A. Gray) G. L. Nesom
88127 Symphyotrichum foliaceum (Lindl. ex DC.) G. L. Nesom var. lyallii ined.
88128 Symphyotrichum hendersonii (Fernald) G. L. Nesom
88129 Symphyotrichum spathulatum (Lindl.) G. L. Nesom var. intermedium (A. Gray) G. L. Nesom
88479 Taxus brevifolia Nutt. var. brevifolia
88480 Taxus brevifolia Nutt. var. polychaeta Spjut
88481 Taxus brevifolia Nutt. var. reptaneta Spjut
88302 Toxicoscordion brevibracteatus (M. E. Jones) R. R. Gates
88303 Toxicoscordion exaltatum (Eastw.) A. Heller
88304 Toxicoscordion fontanum (Eastw.) Zomlefer & Judd.
88305 Toxicoscordion fremontii (Torr.) Rydb.
88306 Toxicoscordion micranthum (Eastw.) A. Heller
88130 Tragopogon hybridus L.
88307 Triantha occidentalis (S. Watson) R. R. Gates
88308 Triantha occidentalis (S. Watson) R. R. Gates subsp. occidentalis
88248 Trifolium tomentosum L. var. tomentosum
88249 Trifolium variegatum Nutt. phase 1
88250 Trifolium variegatum Nutt. phase 2
88251 Trifolium variegatum Nutt. phase 3
88252 Trifolium variegatum Nutt. phase 4
88253 Trifolium variegatum Nutt. phase 5
88254 Trifolium willdenovii Spreng.
88309 Trillium ovatum Pursh var. oettingeri (Munz & Thorne) Case
88310 Trillium ovatum Pursh var. ovatum
88485 Triteleia grandiflora Lindl. subsp. howellii (S. Watson) Hoover ined.
88486 Triteleia x versicolor Hoover
88157 Tropidocarpum californicum (Al-Shehbaz) Al-Shehbaz
88348 Tsuga mertensiana (Bong.) Carri?re subsp. grandicona Farjon
88398 Urochloa arizonica (Scribn. & Merr.) Morrone & Zuloaga
88399 Urochloa maxima (Jacq.) R. D. Webster
88400 Urochloa maxima (Jacq.) R. D. Webster var. maxima
88293 Utricularia stygia G. Thor.
88212 Uva-Ursi pechoensis Dudley ex Abrams
88487 Valeriana hookeri Shuttlew.
88311 Veratrum viride Aiton var. eschscholzianum (Roem. & Schult.) Breitung
88471 Verbascum olympicum Boiss. non Bunyard
88488 Verbena venosa Gill. & Hook.
88131 Verbesina encelioides (Cav.) Benth. & Hook. f. ex A. Gray
88255 Vicia bithynica (L.) L.
88132 Viguiera purisimae Brandegee
88489 Viola adunca Sm. var. kirkii V. G. Duran
88490 Viola langsdorffii Fisch. ex Ging.
88133 Volutaria muricata (L.) Marie
88402 x Elyhordeum californicum (Bowden) Barkworth
88134 Youngia japonica (L.) DC. var. japonica
88312 Yucca jaegeriana (McKelvey) L. W. Lenz
88313 Yucca whipplei Torr. subsp. cespitosa (M. E. Jones) A. L. Haines
88260 Zeltnera arizonica (A. Gray) G. Mans.
88261 Zeltnera calycosa (Buckley) G. Mans.
88262 Zeltnera muehlenbergii (Griseb.) G. Mans.
88263 Zeltnera namophila (Reveal, C. R. Broome, & Beatley) G. Mans.
88492 Zostera asiatica Miki
88401 Zoysia pacifica (Goudswaard) M. Hotta & Kuroki
