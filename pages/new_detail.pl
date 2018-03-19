#!/usr/bin/perl
$CP{"JEPS101133"}=<<EOP;
  <tr>
<td valign="top"> <a href="http://calphotos.berkeley.edu/cgi/img_query?query_src=photos_custom&seq_num=263479&one=T">View image in CalPhotos</a></td>
  </tr>

EOP
my $aid =$ENV{QUERY_STRING};
$detail_help="<a href=\"/detail_help.html#";
if($aid=~s/&related=yes//){
$related=1;
}
else{
$related="";
}
#my $aid =shift;
$aid=~s/.*=//;
$aid=~s/[^.%_A-Za-z0-9-]//g;
if($aid=~/SDSU(\d+)/){
#$zpad="0" x (5-length($1));
#$aid=~s/SDSU/SDSU$zpad/;
#$aid=~s/SDSU00264/SDSU0264/;
#$aid=~s/SDSU00255/SDSU0255/;
}
elsif($aid=~/PGM(\d+)/){
$zpad="0" x (4-length($1));
$aid=~s/PGM/PGM$zpad/;
}
$data_path	="/usr/local/web/ucjeps_data/";
if($aid=~m/^(CAS|CDA|CHSC|DS|HSC|IRVC|JEPS|PGM|POM|RSA|SBBG|SD|SDSU|SJSU|UC|UCD|UCR|UCSB|UCSC|NY)\d+[A-Z]?$/){
open(QLOG, ">>${data_path}cch_query_log");
print QLOG join("\n",time(),"$aid\t"),"\n";
close(QLOG);
}
$start_time=time;
$tab_file_name="CHC_" . substr($start_time,6,4) . $$ . ".txt";
$map_file_path="/usr/local/web/ucjeps_web/";

$map_file_out = "tmp/ms_tmp/$tab_file_name";
$map_file_URL= "http://ucjeps.berkeley.edu/$map_file_out";
use CGI;
use BerkeleyDB;
tie(%CDL_notes, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/CDL_notes", -Flags=>DB_RDONLY);
if($aid=~/(JEPS|UC)\d/){
	open(IN,"/usr/local/web/ucjeps_data/cp_list.txt") || die;
	while(<IN>){
next if m/^#/;
#foreach(split(/ /)){
		chomp;
		($cp_aid,$seq_num,$cp_name)=split(/\t/);
		if($aid eq $cp_aid){
			$CP{$aid}=<<EOP;
  <tr>
<td valign="top"> <a href="http://calphotos.berkeley.edu/cgi/img_query?query_src=&seq_num=$seq_num&one=T">View pertinent image in CalPhotos</a></td>
  </tr>

EOP
			last;
		}
	}
}

close(IN);


tie(%suggs, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/suggs_tally", -Flags=>DB_RDONLY)|| die "$!";
  #tie %CDL, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/CDL_DBM", -Flags=>DB_RDONLY or die "Cannot open file CDL_DBM: $! $BerkeleyDB::Error\n" ;
  tie %CDL, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/CDL_DBM", -Flags=>DB_RDONLY or die "Cannot open file CDL_DBM: $! $BerkeleyDB::Error\n" ;
			@CDL_fields=split(/\t/,$CDL{$aid});
grep(s/</&lt;/g,@CDL_fields);
grep(s/>/&gt;/g,@CDL_fields);
 tie(%ANNO_HIST, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/CDL_annohist", -Flags=>DB_RDONLY)|| die "$!";
 tie(%VOUCHER, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/CDL_voucher", -Flags=>DB_RDONLY)|| die "$!";
 tie(%TID_TO_NAME, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/CDL_TID_TO_NAME", -Flags=>DB_RDONLY)|| die "$!";
tie(%image_location, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/SMASCH_IMAGES", -Flags=>DB_RDONLY)|| die "$!";
			grep(s/>/&gt;/g,@CDL_fields);
			grep(s/</&lt;/g,@CDL_fields);
($ejdate,$ljdate,$date)=@CDL_fields[5,6,7];
if($ejdate==$ljdate){
		($year,$month,$day)=inverse_julian_day($ejdate);
}
elsif($ljdate - $ejdate < 31){
		($year,$month,$day)=inverse_julian_day($ejdate);
$day=0;
}
elsif($ljdate - $ejdate < 365){
		($year,$month,$day)=inverse_julian_day($ejdate);
$day=0;
$month=0;
}
else{$ejdate=""};

$chc_header=<<EOH;

<table width="100%" class="banner" border="0" cellpadding="0" cellspacing="0">
  <tr><td width="80" align="center"><img src="/consortium/images/CCH_logo_02_60.png" width="60" height="62"></td>
  <td>
<table class="banner" width="100%" border="0">
  <tr>
    <td align="center">Consortium of California Herbaria</td>
  </tr>
  <tr>
    <td class="bannerHerbs" align="center">
          <font  face="Times New Roman, Times, serif" color="#FEFEFE"><b>
        <a href="http://www.calacademy.org/research/botany/" target="_blank" class="bannerHerbs">
          CAS-DS</a> &middot; 
<a href="http://cdfa.ca.gov/phpps/PPD/herbarium.html" target="_blank" class="bannerHerbs">
	  CDA</a> &middot; 
        <a href="http://www.csuchico.edu/biol/Herb/" target="_blank" class="bannerHerbs">
          CHSC</a> &middot; 
        <a href="http://herbarium.ucdavis.edu/" target="_blank" class="bannerHerbs">
          DAV</a> &middot; 
        <a href="http://www.humboldt.edu/herbarium/index.html" target="_blank" class="bannerHerbs">
          HSC</a> &middot; 
        <a href="http://ucjeps.berkeley.edu/consortium/irvc.html" target="_blank" class="bannerHerbs">
          IRVC</a> &middot; 
        <a href="http://www.calpoly.edu/~bio/Herbarium.html" target="_blank" class="bannerHerbs">
          OBI</a> &middot;
        <a href="http://www.pgmuseum.org/" target="_blank" class="bannerHerbs">
          PGM</a> &middot;
        <a href="http://www.rsabg.org/" target="_blank" class="bannerHerbs">
          RSA-POM</a> &middot; 
        <a href="http://www.sbbg.org/" target="_blank" class="bannerHerbs">
          SBBG</a> &middot; 
        <a href="http://www.sdnhm.org/research/botany/" target="_blank" class="bannerHerbs">
          SD</a> &middot; 
         <a href="http://www.sci.sdsu.edu/herb" target="_blank" class="bannerHerbs">
         SDSU</a> &middot; 
        <a href="http://www2.sjsu.edu/depts/herbarium/" target="_blank" class="bannerHerbs">
          SJSU</a>  &middot; 
        <a href="http://ucjeps.berkeley.edu/" target="_blank" class="bannerHerbs">
          UC-JEPS</a>  &middot; 
        <a href="http://www.herbarium.ucr.edu/" target="_blank" class="bannerHerbs">
          UCR</a> &middot; 
        <a href="http://ccber.lifesci.ucsb.edu/" target="_blank" class="bannerHerbs">
          UCSB</a> &middot; 
        <a href="http://mnhc.ucsc.edu/" target="_blank" class="bannerHerbs">
          UCSC</a> 
        </b></font>
        </td>
  </tr>
</table>
</td></tr><tr><td colspan="2">

<!-- Beginning of horizontal menu -->
<table class=horizMenu width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td height="21" width="640" align="center">
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/participants.html" class="horizMenuActive">
	    Participants</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/news.html" class="horizMenuActive">News</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/" class="horizMenuActive">Search</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/consortium/about.html" class="horizMenuActive ">About</a>
    </td>
	<td></td>
  </tr>
 <tr>
    <td colspan="6" bgcolor="#9FBFFF"><img src="/common/images/common_spacer.gif" alt="" width="1" height="1" border="0" /></td>
  </tr>
</table>
<!-- End of horizontal menu -->
</td></tr></table>

EOH

$consortium_footer=<<EOH;
<!-- Footer begins -->
<table width="100%" border="0" cellpadding="0" cellspacing="0">
  <tr>
    <td height="18" bgcolor="9090AA"><img src="/common/images/common_spacer.gif" alt="" width="1" height="1" border="0" /></td>
  </tr>
  <tr>
<td class="bodyText">
Explanations of the fields are available by clicking on the left-hand headings.
Information about the collector is available by clicking on the collector name.
The location can be mapped by clicking on "BerkeleyMapper".
Other possibly pertinent records can be retrieved by clicking on "Related searches".
<hr width="15%">
</td>
  </tr>
  <tr>
    <td height="20"><span class="copyrightText">&nbsp;&nbsp;Copyright &copy; 2008 Regents of the University of California<br>
</span>
</td>
  </tr>
</table>
<script src="http://www.google-analytics.com/urchin.js" type="text/javascript">
</script>
<script type="text/javascript">
_uacct = "UA-1304595-1";
urchinTracker();
</script>
</body></html>

<!-- Footer ends -->

EOH

	if($aid=~m|([A-Z]+)-?[0-9.]+|){
		$herb=$1;
		$herb="UC" if $herb eq "UCLA";
		$herb="UC" if $herb eq "LA";
		if($herb eq "UCD"){
			$banner="UCD.gif";
			$herb_url="http://herbarium.ucdavis.edu/";
		}
		elsif($herb eq "IRVC"){
			$banner="UCI.jpg";
			$herb_url="http://ucjeps.berkeley.edu/consortium/irvc.html";
		}
		elsif($herb eq "UCR"){
			$banner="UCR.gif";
			$herb_url="http://herbarium.ucr.edu/Herbarium.html";
		}
		elsif($herb eq "UCSB"){
			$banner="UCSB.gif";
			$herb_url="http://ccber.lifesci.ucsb.edu/collections/botanical/vascular_plants/";
		}
		elsif($herb eq "UCSC"){
			$banner="UCSC.gif";
			$herb_url="http://herbarium.ucsc.edu/index.html";
		}
		elsif($herb eq "CHSC"){
			$banner="chsc_logo.jpg";
			$banner="chsc_logo.gif";
			$herb_url="http://www.csuchico.edu/biol/Herb/index.html";
		}
		elsif($herb eq "SBBG"){
			$banner="SBBG.gif";
			$herb_url="http://www.sbbg.org";
		}
		elsif($herb eq "POM"){
			$banner="rsa.png";
			$herb_url="http://www.rsabg.org/herbarium/database/";
		}
		elsif($herb eq "RSA"){
			$banner="rsa.png";
			$herb_url="http://www.rsabg.org/herbarium/database/";
		}
		elsif($herb eq "SJSU"){
			$banner="csw_banner.gif";
			$herb_url="http://www2.sjsu.edu/depts/herbarium/";
		}
		elsif($herb eq "SD"){
			$banner="sd.jpg";
			$herb_url="http://www.sdnhm.org/research/botany/";
		}
		elsif($herb eq "SDSU"){
			$banner="sdsu.jpg";
			$herb_url="http://www.sci.sdsu.edu/herb";
		}
		elsif($herb eq "PGM"){
			$banner="PG_logo.jpg";
			$herb_url="http://www.pgmuseum.org/";
$herb="Pacific Grove Museum of Natural History";
		}
elsif($herb =~/HSC/){
            $banner="hsu.jpg";
            $banner="humboldt.gif";
		$herb="Humboldt State University herbarium";
$herb_url="http://www.humboldt.edu/herbarium/index.html";
       }
elsif($herb =~/CAS|DS/){
            $banner="CAS_Logo_HorizontalColor.gif";
		$herb="California Academy of Sciences";
$herb_url="http://www.calacademy.org/research/botany/";
       }
elsif($herb =~/NY/){
            $banner="nybg.gif";
#$herb_url="http://sciweb.nybg.org/science2/ScienceHome.asp";
       }
elsif($herb =~/CDA/){
            $banner="department_header.gif";
			$herb_url="http://cdfa.ca.gov/phpps/PPD/herbarium.html";

		$herb="California Department of Food and Agriculture: Plant Pest Diagnostics Branch, Botany Laboratory and Herbarium";
       }

		else{
			$banner= "sm_ucjeps_banner.gif";
			$herb_url="/index.html";
		}
}
$taxon=$TID_TO_NAME{$CDL_fields[0]};
$taxon=~s/ /+/g;
#$possible_thumb="/usr/local/web/ucjeps_web/images/thumb/${aid}.jpg";
$possible_thumb="/data_ucjeps/images/thumb/${aid}.jpg";
if(-e $possible_thumb){
$detail_header=<<EOH;
Content-Type: text/html

<html>
<head>
<Meta NAME="ROBOTS" CONTENT="NOINDEX, NOFOLLOW">
<title>Consortium of California Herbaria: Detail Page</title>
<link href="../consortium/style_consortium.css" rel="stylesheet" type="text/css">
</head>
<body>
$chc_header
<br>
<table width="100%">
<tr>
<td width="33%">
<IMG src="/$banner">
</td>
<th align="center" width="33%">
<h2 >
Accession Detail Results
</h2>
</th>
<td width="33%">
<a href="/cgi-bin/display_smasch_img.pl?smasch_accno=$aid"><IMG SRC="/new_images/thumb/${aid}.jpg"></a>
</td></tr>
</table>
EOH
}
else{
$detail_header=<<EOH;
Content-Type: text/html

<html>
<head>
<Meta NAME="ROBOTS" CONTENT="NOINDEX, NOFOLLOW">
<title>Consortium of California Herbaria: Detail Page</title>
<link href="../consortium/style_consortium.css" rel="stylesheet" type="text/css">
</head>
<body>
$chc_header
<br />
<span class="pageSubheading">
&nbsp;&nbsp;Please cite data retrieved from this page: Data provided by the participants of the Consortium of California Herbaria (ucjeps.berkeley.edu/consortium/).
</span>
<br>
<IMG src="/$banner">
<h3 align="center">
Accession Detail Results
</h3>
EOH
}
@anno=split(/\n/,$ANNO_HIST{$aid});
if(@anno){
	$anno="";
	foreach(sort(@anno)){
		@anno_unit=split(/; /, $_, 4);
		$anno_unit[1]=~s|[uU]nknown|<font size="-2">Annotator unknown</font>|;
		$anno_unit[2]=~s|[uU]nknown||;
		$anno_unit[3]=~s|;||;
		foreach($anno_unit[3]){
s/\bnocl\b/Name on collection label/;
s/\bdip\b/data in packet/;
}
		$anno .="<tr><td>$anno_unit[0]</td><td>$anno_unit[1]</td><td>$anno_unit[2]</td><td>$anno_unit[3]</td></tr>";
	}
	$anno="<tr><td>${detail_help}Annotations and/or curatorial actions\">Annotations and/or<br> curatorial actions</a></td><td><table cellspacing=5>$anno</table></td></tr>";
$anno=~s/\303\251/&eacute;/g;
#$notes=$CDL_notes{$aid};
#if($notes){
#$notes=~s/</&lt;/g;
#$notes=~s/>/&gt;/g;
    #$anno.="<tr><td>${detail_help}Notes\">2Notes</a></td><td>$notes</td></tr>";
#}
}
else{
	#$anno="<tr><td>No Annotations $aid</td><td>$ANNO_HIST{$aid}</td></tr>";
}
%voucher=split(/\t/,$VOUCHER{$aid});
%voucher_kind=(
"16","secondary product chemistry",
"17","cytology",
"18","embryology",
"19","micromorphology",
"20","macromorphology",
"21","reproductive biology",
"24","population biology",
"25","horticulture",
"26","phenology",
"27","illustration",
"28","photograph",
"29","nomenclature",
"32","publication",
"33","data in packet",
"35","reference used for determination",
"36","none",
"39","common name",
"41","Vegetation Type Map Project",
"43","odor",
"44","ethnobotany",
"47","map",
"50","color",
"52","habitat",
"53","associated species",
"55","other label numbers",
"58","biotic interactions",
"56","type",
"23","biotic environment -inactive 7/93",
"22","physical environment -inactive 7/93",
"61","annotation history",
"62","Expedition",
"64","fruit removal",
"65","physical enviroment",
"66","physical environment",
"67","SEM (Scanning Electron Micrograph)",
"63","material removed",
"15","nucleic acids",
"45","genbank code",
"71","U.C. Botanical Garden",
"72","other",
);
if(%voucher){
foreach(sort(keys(%voucher))){
$voucher{$_}=~s/Õ/'/g;
if($_ eq "52"){
$voucher{$_}=~s/>/&gt;/g;
$voucher{$_}=~s/</&lt;/g;
$habitat=<<EOF;
<tr><td>${detail_help}Habitat">Habitat</a></td><td>$voucher{$_}</td></tr>
EOF
next;
}
elsif($_ eq "56"){
	next if $voucher{$_}=~/non-type/;
	if($aid=~/(UC|JEPS)\d/){
		unless($voucher{$_}=~/[Tt]opo-?type/){
		$voucher{$_}=<<EOV;
<a href="/cgi-bin/gtt.pl?gtt=$aid">$voucher{$_}</a>
EOV
}
	}
}
elsif($_ eq "36"){
next;
}
elsif($_ eq "45"){
$voucher{$_}=~s|([A-Z]+\d+)|<A HREF="http://www.ncbi.nlm.nih.gov/sites/entrez?db=nuccore&cmd=DetailsSearch&term=$1">$1</a>|g;
}
elsif($_ eq "61"){
next if $anno;
$voucher{$_}=~s|(([23456789])/([123456789]))|$1 <font size="-2">($3 names used in $2 annotations)</font>|;
}
$voucher{$_}="<font size=\"-2\">Data on label not transcribed.</font>" unless $voucher{$_};
push(@voucher_table,"<tr><td width=\"10%\"><i>$voucher_kind{$_}</i></td><td>$voucher{$_}</td></tr>");
}
if(@voucher_table){
unshift(@voucher_table,"<tr><td>${detail_help}Voucher information\">Voucher information</a></td><td><table cellspacing=5>");
push(@voucher_table,"</table></td></tr>");
}
}
else{
@voucher=();
}
$notes=$CDL_notes{$aid};
if($notes){
$notes=~s/</&lt;/g;
$notes=~s/>/&gt;/g;
    $anno.="<tr><td>${detail_help}Notes\">Notes</a></td><td>$notes</td></tr>";
}

if($taxon){
	if($herb eq "NY"){
		($ny_id=$aid)=~s/NY//;
		$herb_url="http://sweetgum.nybg.org/vh/specimen_list.php?QueryName=DetailedQuery&col_int_ColBarcode=$ny_id";
		print <<EOH;
$detail_header
<br>
&nbsp;<a href="$herb_url">$herb, the home institution for this record, has additional information</a> </span>
EOH
	}
	else{
$today=localtime();
		print <<EOH;
$detail_header
<br>
&nbsp;<a href="$herb_url">$herb is the home institution for this record.</a>
<br>
&nbsp;Please cite data retrieved from this page: Data provided by the participants of the Consortium of California Herbaria (ucjeps.berkeley.edu/consortium/; $today).

</span>
EOH
	}

if($CDL_fields[9]){
$elevation=<<EOE;
<tr><td>${detail_help}Elevation">Elevation</a></td> <td>$CDL_fields[9]</td></tr>
EOE
}
else{
$elevation="";
}
if($CDL_fields[11]){
$CDL_fields[11]=~s/\.(...).*/.$1/;
$CDL_fields[12]=~s/\.(...).*/.$1/;
($institution=$aid)=~s/\d.*//;
push(@map_results, join("\t", $institution, $aid, $TID_TO_NAME{$CDL_fields[0]}, @CDL_fields[1 .. $#CDL_fields], "NAD 27"));
if(@map_results){
grep(s/\|/_/g,@map_results);
$mappable=<<EOP;
<a href="http://berkeleymapper.berkeley.edu/run.php?ViewResults=tab&tabfile=$map_file_URL&configfile=http%3A%2F%2Fucjeps.berkeley.edu%2Fucjeps.xml&sourcename=Consortium+of+California+Herbaria+result+set&maptype=Terrain"><font size=\"-2\">BerkeleyMapper</font></a>
EOP
open(MAPFILE, ">$map_file_path$map_file_out") || print "cant open map file";
print MAPFILE join("\n",@map_results);
close(MAPFILE);
}
else{
$mappable="";
}
$coordinates=<<EOC;
<tr><td>${detail_help}Coordinates">Coordinates</a></td>
<td>$CDL_fields[11]  $CDL_fields[12] $mappable</td></tr>
EOC
if($CDL_fields[14]){
$coordinate_source .=<<EOC;
<tr><td>${detail_help}Coordinate source">Coordinate source</a></td><td>$CDL_fields[14]</td></tr>
EOC
}
else{
$coordinate_source .=<<EOC;
<tr><td>${detail_help}Coordinate source">Coordinate source</a></td><td><font size=\"-2\">Not recorded</font></td></tr>
EOC
}
if($CDL_fields[13]){
$datum .=<<EOC;
<tr><td>Datum</td><td>$CDL_fields[13]</td></tr>
EOC
}
else{
if($coordinate_source=~/Biogeomancer/){
$datum .=<<EOC;
<tr><td>Datum</td><td>WGS84</td></tr>
EOC
}
else{
$datum .=<<EOC;
<tr><td>Datum</td><td><font size=\"-2\">Not recorded</font></td></tr>
EOC
}
}
if($CDL_fields[15]){
$coordinates .=<<EOC;
<tr><td>Township/Range/Section</td><td>$CDL_fields[15]</td></tr>
EOC
}
}
else{
$coordinates="";
if($CDL_fields[15]){
$coordinates .=<<EOC;
<tr><td>Township/Range/Section</td><td>$CDL_fields[15]</td></tr>
EOC
}
}
if( $aid =~/^(JEPS102066|UC249775)$/){
$image_link=qq{<a href="/images/${1}_001.jpg"> <img src="/common/images/ico_camera.gif" alt="Image available" border="0"></a>};
}
#### remove > 200 do restore image display
elsif($image_location{$aid}){
	#if($image_location{$aid} =~/\/image/){
$image_link=qq{<a href="/cgi-bin/display_smasch_img.pl?smasch_accno=$aid"> <img src="/common/images/ico_camera.gif" alt="Image available" border="0"></a>};
#Hide E. truncatum
$image_link="" if $aid eq "UC692153";
$image_link="" if $aid eq "JEPS26640";
$image_link="" if $aid eq "JEPS27371";
$image_link="" if $aid eq "UC1212010";
#}
}
else{
$image_link="";
}
push(@display, qq{<tr><td width="20%">${detail_help}Accession number">Accession number</a></td> <td>$aid</td></tr>});
push(@display, qq{<tr><td>${detail_help}Determination">Determination</a></td> <td><i>$TID_TO_NAME{$CDL_fields[0]}</i> $image_link<br> <a href="/cgi-bin/get_cpn.pl?$taxon"><font size=\"-2\">More information: Jepson Online Interchange</font></a> </td></tr>});
$archon_link_pre=qq{<a href="http://ucjeps.berkeley.edu/archon/index.php?p=collections/controlcard&amp;id=};
$archon_link_post=qq{&amp;q=field">};
if($CDL_fields[1]=~/^W\. A\. Setchell/){
$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/history/biog/setchell.html">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/^I.*Clokey/){
$CDL_fields[1]=qq{<a href="http://www.iraclokey.com/">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/^(Annetta)[M. ]+Carter/){
$CDL_fields[1]=qq(${archon_link_pre}84$archon_link_post$CDL_fields[1]</a>);
}
elsif($CDL_fields[1]=~/H\. P\. Bracelin/){
$CDL_fields[1]=qq(${archon_link_pre}32$archon_link_post$CDL_fields[1]</a>);
}
elsif($CDL_fields[1]=~/N\. (F\.|Floy) Bracelin/){
$CDL_fields[1]=qq(${archon_link_pre}32$archon_link_post$CDL_fields[1]</a>);
}
elsif($CDL_fields[1]=~/^(M\.|Milo)[S. ]+Baker/){
$CDL_fields[1]=qq(${archon_link_pre}24$archon_link_post$CDL_fields[1]</a>);
}
elsif($CDL_fields[1]=~/^(Charles|C.|Chas\.)[M. ]+Belshaw/){
$CDL_fields[1]=qq(${archon_link_pre}16$archon_link_post$CDL_fields[1]</a>);
}
elsif($CDL_fields[1]=~/^(Elizabeth|Liz|E.) Neese/){
$CDL_fields[1]=qq(${archon_link_pre}3$archon_link_post$CDL_fields[1]</a>);
}
elsif($CDL_fields[1]=~/^(A\.|Alice)[M. ]+Ottley/){
$CDL_fields[1]=qq(${archon_link_pre}51$archon_link_post$CDL_fields[1]</a>);
}
elsif($CDL_fields[1]=~/^(Lauramay|L\.)[T. ]+Dempster/){
$CDL_fields[1]=qq(${archon_link_pre}12$archon_link_post$CDL_fields[1]</a>);
}
elsif($CDL_fields[1]=~/^(R\.|Ralph) Hoffmann/){
$CDL_fields[1]=qq{<a href="http://www.geocities.com/Yosemite/Gorge/5604/rhoffmann1920-1932travels.htm">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/^(W\.|Willis) ?(L\.|Linn) ?(J\.|Jepson)/){
	$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/history/biog/jepson/jepson_the_botany_man.html">$CDL_fields[1]</a>};
	tie(%field_book, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/jepson_collno", -Flags=>DB_RDONLY)|| die "$!";
	if(length($CDL_fields[3])>0){
		if($field_book{$CDL_fields[3]}){
			$jeps_collno=qq{<a href="/cgi-bin/display_fb.pl?page_no=$field_book{$CDL_fields[3]}">$CDL_fields[3] <img src="/ob.gif"></a>};
			#$jeps_collno=qq{<a href="/images/fieldbooks/$field_book{$CDL_fields[3]}">$CDL_fields[3]</a>};
		}
	}
}
elsif($CDL_fields[1]=~/(Brewer|Bolander|State Survey)/){
			$jeps_collno=qq{<a href="http://herbaria4.herb.berkeley.edu/cgi-bin/brewer.pl?$CDL_fields[3]">$CDL_fields[3] <img src="/ob.gif"></a>};
}
elsif($CDL_fields[1]=~/^C\. ?A\. Purpus/){
$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/Purpus/">$CDL_fields[1]</a>};
	tie(%field_book, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/CDL_PURPUS_CN", -Flags=>DB_RDONLY)|| die "$!";
		if($field_book{$CDL_fields[3]}){
			$jeps_collno=qq{<a href="$field_book{$CDL_fields[3]}">$CDL_fields[3] <img src="/ob.gif"></a>};
		}
}
elsif($CDL_fields[1]=~/^(A\.|Annie) M. Alexander/){
	$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/Alexander/indexA.html">$CDL_fields[1]</a>};
	tie(%field_book, "BerkeleyDB::Hash", -Filename=>"/usr/local/web/ucjeps_data/CDL_ALEX_CN", -Flags=>DB_RDONLY)|| die "$!";
	if(length($CDL_fields[3])>0){
if($date=~/1911/){
		if($field_book{"$CDL_fields[3].1"}){
			$jeps_collno=qq{<a href="$field_book{"$CDL_fields[3].1"}">$CDL_fields[3] <img src="/ob.gif"></a>};
		}
}
else{
		if($field_book{$CDL_fields[3]}){
			$jeps_collno=qq{<a href="$field_book{$CDL_fields[3]}">$CDL_fields[3] <img src="/ob.gif"></a>};
		}
}
	}
}
elsif($CDL_fields[1]=~/R.*Moran/){
$CDL_fields[1]=qq{<a href="http://bajaflora.org/MoranNotesSearch.aspx">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/Victor Duran/){
$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/history/biog/Victor_Duran.html">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/Louise Kellogg/){
$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/history/biog/kellogg.html">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/^Charlotte N. Nash/){
$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/history/biog/nash.html">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/^(R\.|Rimo) Bacigalupi/){
$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/history/biog/bacigalupi_obit.html">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/^[F. ]*Guirado/){
$CDL_fields[1]=qq{<a href="http://www.sfgenealogy.com/spanish/obitsg.htm">$CDL_fields[1]</a>};
}

elsif($CDL_fields[1]=~/^M.* Bowerman/){
$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/history/biog/bowerman.html">$CDL_fields[1]</a>};
}


elsif($CDL_fields[1]=~/(Harriet.*Walker)|(H. A. Walker)/){
$CDL_fields[1]=qq{<a href="http://ucjeps.berkeley.edu/history/biog/walker.html">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/(Dr. )?C. C. Parry/){
$CDL_fields[1]=qq{<a href="http://www.csupomona.edu/~larryblakely/whoname/who_pary.htm">$CDL_fields[1]</a>};
}

elsif($CDL_fields[1]=~/Alice Eastwood/){
$CDL_fields[1]=qq{<a href="http://www.csupomona.edu/~larryblakely/whoname/who_east.htm">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/S. W. Austin/){
$CDL_fields[1]=qq{<a href="http://www.csupomona.edu/~larryblakely/whoname/who_aust.htm">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/(J. W. )?Blankinship/){
$CDL_fields[1]=qq{<a href="http://gemini.oscs.montana.edu/~mlavin/herb/jwb.htm">$CDL_fields[1]</a>};
}
elsif($CDL_fields[1]=~/(Dr. )?C. L. Anderson/){
$CDL_fields[1]=qq{<a href="http://www.csupomona.edu/~larryblakely/whoname/who_andr.htm">$CDL_fields[1]</a>};
}
else{
$huh=&get_coll_last_name($CDL_fields[1]);
$CDL_fields[1]=qq{<a href="http://asaweb.huh.harvard.edu:8080/databases/botanists?name=$huh">$CDL_fields[1]</a>};
}



$disp_collno=$jeps_collno || $CDL_fields[3];
$CDL_fields[10]=~s/on lable/on label/;
$CDL_fields[10]=~ s/Ë&ouml;/&deg;/g;
$CDL_fields[10]=~ s/â€œ/"/g;
	$CDL_fields[10]=~s/[ -]*$//;
	$CDL_fields[10]=~s/\[\]//;
push(@display, qq{<tr><td>${detail_help}Collector, number, date">Collector, number, date</a></td> <td>$CDL_fields[1], $CDL_fields[2]$disp_collno$CDL_fields[4], $date</td></tr>}) if $CDL_fields[1];
push(@display, qq{<tr><td>${detail_help}County">County</a></td> <td>$CDL_fields[8]</td></tr>});
push(@display, qq{<tr><td>${detail_help}Locality">Locality</a></td> <td>$CDL_fields[10]</td></tr>}) if $CDL_fields[10];
push(@display, qq{$elevation}) if $elevation;
push(@display, qq{$habitat}) if $habitat;
push(@display, qq{$coordinates}) if $coordinates;
push(@display, qq{$datum}) if $coordinates;
push(@display, qq{$coordinate_source}) if $coordinate_source;
push(@display, join(" ",@voucher_table)) if @voucher_table;
push(@display, qq{$anno}) if $anno;
#http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?county=DEL%20NORTE&source=All&taxon_name=Castilleja%20arachnoidea&collector=&excl_collector=&aid=&year=&month=0&day=0&loc=&coll_num=&max_rec=500&SO=8
##http://ucjeps.berkeley.edu/cgi-bin/get_consort.pl?county=DEL%20NORTE&source=All&taxon_name=Castilleja%20arachnoidea&collector=&excl_collector=&aid=&year=month=0&day=0&loc=&coll_num=&max_rec=500&SO=8
($county=$CDL_fields[8])=~s/ /%20/g;
$county=uc($county);
($taxon_name=$TID_TO_NAME{$CDL_fields[0]})=~s/ /%20/g;
#July30 2009
$taxon_name=~s/(var\.|subsp\.|f\.)%20//g;


$collector=$CDL_fields[1];
$coll_num=$CDL_fields[3];

foreach($collector){
$collector="W.L. Jepson" if $collector=~/W\. ?L\. ?J\./;
s/^.*">//;
s/<\/a>//;
s/^([A-Z]. ?)+ (and|&) ([A-Z]. ?)+ ([A-Z][a-z])/$4/;
s/^([A-Z][a-z]+) (and|&) ([A-Z][a-z]+) ([A-Z][a-z]+)/$4/;
s/, .*//;
s/ and .*//;
s/ \(?with .*//;
s/^.* //;
}

if($related){
$related_display=<<EOP;
<LI><a href="/cgi-bin/get_consort.pl?taxon_name=$taxon_name">taxon=$TID_TO_NAME{$CDL_fields[0]}</a>
<LI><a href="/cgi-bin/get_consort.pl?county=$county&source=All&taxon_name=$taxon_name&collector=&excl_collector=&aid=&year=&month=0&day=0&loc=&coll_num=&max_rec=500&SO=0"> county=$CDL_fields[8]; taxon=$TID_TO_NAME{$CDL_fields[0]}</a>
EOP
if($collector){
$related_display.=<<EOP;
<LI><a href="/cgi-bin/get_consort.pl?county=$county&source=All&taxon_name=&collector=$collector&excl_collector=&aid=&year=&month=0&day=0&loc=&coll_num=&max_rec=500&SO=8"> county=$CDL_fields[8]; collector=$collector</a>
<LI><a href="/cgi-bin/get_consort.pl?county=&source=All&taxon_name=$taxon_name&collector=$collector&excl_collector=&aid=&year=&month=0&day=0&loc=&coll_num=&max_rec=500&SO=0"> collector=$collector; taxon=$TID_TO_NAME{$CDL_fields[0]}</a>
EOP
if($coll_num){
$related_display.=<<EOP;
<LI><a href="/cgi-bin/get_consort.pl?county=&source=All&taxon_name=&collector=$collector&excl_collector=&aid=&year=&month=0&day=0&loc=&coll_num=$coll_num&max_rec=500&SO=8">collector=$collector; number=$coll_num</a>
<LI><a href="/cgi-bin/get_consort.pl?county=&source=All&taxon_name=&collector=$collector&excl_collector=&aid=&year=&month=0&day=0&loc=&coll_num=$coll_num&adj_num=1&max_rec=500&SO=8">collector=$collector; number=$coll_num; include nearby numbers</a>
EOP
}
if($ejdate){
$related_display.=<<EOP;
<LI><a href="/cgi-bin/get_consort.pl?county=&source=All&taxon_name=&collector=$collector&excl_collector=&aid=&year=$year&month=$month&day=$day&loc=&coll_num=&max_rec=500&SO=3">date=$date; collector=$collector</a>
EOP
$related_display.=<<EOP;
<LI><a href="/cgi-bin/get_consort.pl?county=$county&source=All&taxon_name=&collector=&excl_collector=&aid=&year=$year&month=$month&day=$day&loc=&coll_num=&max_rec=500&SO=0"> date=$date; county=$CDL_fields[8]</a>
EOP
}
#<LI><a href="/cgi-bin/get_consort.pl?county=$county&source=All&taxon_name=$taxon_name&collector=$collector&excl_collector=yes&aid=&year=&month=0&day=0&loc=&coll_num=&max_rec=500&SO=1">taxon=$TID_TO_NAME{$CDL_fields[0]}; county=$CDL_fields[8]; collector=not $collector</a> N.B. this is slow
$related_display.=<<EOP;
<LI><a href="http://data.gbif.org/species/$taxon_name">Possible GBIF records</a> <font color="red">[External]</font>
EOP
if($CDL_fields[11] && $CDL_fields[12]){
$lat_max=$CDL_fields[11]+.05;
$lat_min=$CDL_fields[11]-.05;
$long_max=$CDL_fields[12]+.05;
$long_min=$CDL_fields[12]-.05;
$related_display.=<<EOP;
<LI><a href="/cgi-bin/get_consort.pl?lat_max=$lat_max&lat_min=$lat_min&long_max=$long_max&long_min=$long_min">Return geographically nearby records (within ~3 mi)</a>.
<a href="/cgi-bin/get_consort.pl?make_tax_list=1&lat_max=$lat_max&lat_min=$lat_min&long_max=$long_max&long_min=$long_min">&nbsp;&nbsp;List of names, 1 record each</a>
EOP
}
}
}
else{
$related_display="";
}
foreach $i (0 .. $#display){
$display[$i]=~s/<tr>/<tr bgcolor="#eeeeee">/ unless $i % 2;
}


if($suggs{$aid}){
	($sugg_suffix=$aid)=~s/\d.*//;
	$sugg_suffix=lc($sugg_suffix);
	$sugg_suffix="rsa" if $sugg_suffix eq "pom";
	$sugg_suffix="ucb" if $sugg_suffix eq "uc";
	$sugg_suffix="ucb" if $sugg_suffix eq "jeps";
#<a href="/suggs_${sugg_suffix}.html#$suggs{$aid}"><br>Read comments</a>
	$seen_sugg=<<EOP;
<a href="/cgi-bin/display_chc_comment.pl?comment_id=$aid"><br>Read comments</a>
EOP
}
else{
$seen_sugg="";
}

if($related){
$related_link=qq{<font size="+1">Related searches:</font><br>};
}
else{
$related_link=qq(<a href="/cgi-bin/new_detail.pl?${aid}&related=yes"><font size="+1" color="red">Related searches</font></a><br>);
}

$display[1]=~s/ \xD7 / &times;/;
print <<EOP;
<hr width="33%">
<table width="95%" align="center">
@display
  <tr>
<td valign="top"> <a href="/cgi-bin/get_consort.pl?sugg=$aid">Comment</a> $seen_sugg</td>
  </tr>
$CP{$aid}
  <tr>
<td valign="top"> <a href="http://ucjeps.berkeley.edu/detail_help.html">Help</a></td>
  </tr>
</table>
<P>
<OL>
$related_link
$related_display
</OL>
$consortium_footer
EOP
}
else{
if((@voucher_table ||$anno) && $aid){
push(@display, join(" ",@voucher_table)) if @voucher_table;
push(@display, qq{$anno}) if $anno;
foreach $i (0 .. $#display){
$display[$i]=~s/<tr>/<tr bgcolor="#eeeeee">/ unless $i % 2;
}
print <<EOH;
$detail_header
<h3>The entry for $aid is incomplete:</h3>
<hr width="33%">
<table width="95%" align="center">
@display
</table>
$consortium_footer
EOH
}
else{
$aid= "the null value" unless $aid;
if($aid =~ /UC(392253)/){
$fern_ref= qq{: <a href="/cgi-bin/gft.pl?gft=$1">See the UC fern types table</a>};
}
else{
$fern_ref="";
}
print <<EOH;
$detail_header
<h3>There seems to be no entry for $aid$fern_ref</h3>
It's possible that the database is misconfigured.
It's possible that $aid was never in the database, that it has been
removed, or that the entry is incomplete.
$consortium_footer
EOH
}
}
print somewhere_else <<EOP;
<tr><td width="20%">Accession number 2</td> <td>$aid</td></tr>
<tr><td>Determination</td> <td><i>$TID_TO_NAME{$CDL_fields[0]}</i> $image_link<br> <a href="/cgi-bin/get_cpn.pl?$taxon"><font size=\"-2\">More information: Jepson Online Interchange</font></a> </td></tr>
<tr><td>Collector, number, date</td> <td>$CDL_fields[1], $CDL_fields[2]$CDL_fields[3]$CDL_fields[4], $date</td></tr>
<tr><td>County</td> <td>$CDL_fields[8]</td></tr>
<tr><td>Locality</td> <td>$CDL_fields[10]</td></tr>
$elevation
$habitat
$coordinates
@voucher_table
$anno
</table>
$consortium_footer
EOP

sub inverse_julian_day
{
use integer;
        my($jd) = @_;
        my($jdate_tmp);
        my($m,$d,$y);

        #carp("warning: julian date $jd pre-dates British use of Gregorian calendar\n") if ($jd < $brit_jd);

        $jdate_tmp = $jd - 1721119;
        $y = (4 * $jdate_tmp - 1)/146097;
        $jdate_tmp = 4 * $jdate_tmp - 1 - 146097 * $y;
        $d = $jdate_tmp/4;
        $jdate_tmp = (4 * $d + 3)/1461;
        $d = 4 * $d + 3 - 1461 * $jdate_tmp;
        $d = ($d + 4)/4;
        $m = (5 * $d - 3)/153;
        $d = 5 * $d - 3 - 153 * $m;
        $d = ($d + 5) / 5;
        $y = 100 * $y + $jdate_tmp;
        if($m < 10) {
                $m += 3;
        } else {
                $m -= 9;
                ++$y;
        }
        return ($y, $m, $d);
}
sub get_coll_last_name {
local($_)=@_;
my $residue="";
#Harold and Virginia Bailey
                        s/^([A-Z][a-z]+) and ?([A-Z][a-z-]+) ([A-Z][a-z-]+$)/$3$1$2/ ||
                        s/^([A-Z]\.) ?([A-Z]\.) and ([A-Z]\.) ?([A-Z]\.) (.*)/$5$1$2$3$4/ ||
                        s/^([A-Z]\.) and ([A-Z]\.) (.*)/$3$1$21/ ;
		if(s/ \((with|and|&) (.*)//){
$residue=$2;
}
		if(s/ ?\(?(with|and|&) (.*)//){
$residue=$2;
}
		if(s/, (.*)//){
$residue=$1;
}
		s/^ *//;
		s/(.+) (.+)/$2/;
s/ .*//g;
$_;
}
