#converts all .post.txt files to html files for display. Writes output to WEB folder
$suffix="post.txt";
opendir(DIR,".");
$single_file=shift;
@files=grep(/$suffix/,readdir(DIR));
@files=$single_file if $single_file;
die "you might have to rename a .trdone file .post.txt\n" unless @files;
foreach $file (@files){
	warn $file, "\n";
	undef($/);
	open(IN,$file) || die "couldn't open $file\n";
	($outfile=$file)=~s/$suffix/html/;
	($taxon=$outfile)=~s/\.html//g;
	$outfile=lc($outfile);
	#open(OUT, ">WEB/$outfile") || die "couldn't open $outfile\n";
	$header= <<EOP;
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">

<!-- Jepson Herbarium: Jepson Flora Project Public Review -->

<head><title>Jepson Herbarium: Jepson Flora Project: Public Review: $taxon</title> 
<link href="http://ucjeps.berkeley.edu/common/styles/style_main_ucjeps.css" rel="stylesheet" type="text/css" />
</head>

<body>

<!-- Begin banner -->
<table class="banner" width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td colspan="5" align="center" valign="middle">&nbsp;</td>
  </tr>
  <tr>
    <td rowspan="4" width="12" align="center" valign="middle"></td>
    <td rowspan="3" width="120" align="center" valign="middle">
      <a href="http://ucjeps.berkeley.edu/jeps/"><img src="http://ucjeps.berkeley.edu/common/images/logo_jeps_80.png" alt="Jepson Herbarium (JEPS)" width="80" height="79" border="0" /></a></td>
    <td align="center">&nbsp;</td>
    <td rowspan="3" width="120" align="center" valign="middle"></td>
    <td rowspan="4" width="12" align="center" valign="middle"></td>
  </tr>
  <tr>
    <td align="center" valign="middle"><span class="bannerTitle">The Jepson Herbarium</span><br /></td>
  </tr>

  <tr>
     <td align="center" valign="top"><a href="http://www.berkeley.edu" class="bannerTagLine">University of California, Berkeley</a></td>
  </tr>

  <tr>
    <td colspan="3" align="center"></td>
  </tr>
  
  <tr>
    <td height="8" colspan="5" align="center">&nbsp;</td>
  </tr>
  <tr class="bannerBottomBorder">
  	<td colspan="6" height="3"></td>
  </tr>

  <tr>
    <td colspan="6"><img src="http://ucjeps.berkeley.edu/common/images/common_spacer.gif" alt="" width="1" height="1" border="0" /></td>
  </tr>
</table>
<!-- End banner -->

<!-- Beginning of horizontal menu -->
<table class="horizMenu" width="100%" border="0" cellspacing="0" cellpadding="0">
  <tr>
    <td height="21" width="640" align="right">
      <a href="http://ucjeps.berkeley.edu/main/directory.html" class="horizMenuActive">Directory</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/news/" class="horizMenuActive">News</a>
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/main/sitemap.html" class="horizMenuActive">Site Map</a>	
	  &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
      <a href="http://ucjeps.berkeley.edu/" class="horizMenuActive">Home</a>	
    </td>
	<td />
  </tr>
 <tr>
    <td colspan="6" bgcolor="#9FBFFF"><img src="http://ucjeps.berkeley.edu/common/images/common_spacer.gif" alt="" width="1" height="1" border="0" /></td>
  </tr>
</table>
<!-- End of horizontal menu -->

<table border="0">
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
  </tr>
  <tr>
    <td>&nbsp;</td>
    <td>&nbsp;</td>
    <td width="100%"><span class="pageName">DRAFT<br>Second Edition of The Jepson Manual: Vascular Plants of California</span><br /><br />
      <span class="pageAuthorLine">Treatments for public viewing </span><br />
      <br />
	  
<p class="bodyText">This treatment has undergone both technical and   scientific editing within the Jepson Flora Project and is, in the view of the author or authors as well as the Jepson Flora Project Staff and the Jepson Flora Project Editors, ready for public viewing. Please forward any comments or corrections you may have to the Scientific Editor, Dr. Thomas Rosatti (<a href="mailto:rosatti\@berkeley.edu?subject=Second_edition_comments$taxon">rosatti\@berkeley.edu</a>).<br /> 

</td>
</tr>
</table>
EOP
print $header;
	$all_lines=<IN>;
#converts windows line ends#
	$all_lines=~s/\r\n/\n/g;
	@all_pars=split(/\n\n+/,$all_lines);
	foreach(@all_pars){
		$nativity="";
		next if m/^[aA]dmin/;
		s/([0-9])-([0-9])/$1&ndash;$2/g;
		s/â€™/'/;
		s/’/'/g;
		s/</&lt;/g;
###################### KEYS ##########################
		if(s/^[0-9]+[abc]?[.']/<br>$&/mg){
			s/…/.../g;
			s/([0-9])-([0-9])/$1&ndash;$2/;
			s/\.+[-_]*>/--&gt;/g;
			s/-->/--&gt;/g;
			s/--([^&])/&ndash;$1/g;
			s/--&gt;(.*)/--&gt;<I>$1<\/I>/g;
			s/--&gt;(.*)\[(.*)\]<\/I>/--&gt;$1<\/I> [$2]/g;
			s|\+/-|&plusmn;|g;
			s|\+-|&plusmn;|g;
			s/ > or =/ &ge;/g;
			if(s/UNABRIDGED KEY/<span class="treatUnabrKey">/){
				s/$/<\/span>/;
			}
		while(s/_/<I>/){
			s/_/<\/I>/;
		}
			s/UNABRIDGED\n//;
s/  +/ /g;
			print qq{<span class="treatKey">$_<\/span>\n};
			next;
		}
######################################################
		if(s/UNABRIDGED\nURBAN WEED//){
			$nativity=qq{URBAN WEED};
		}
		elsif(s/UNABRIDGED\nEXCLUDED//){
			$nativity=qq{EXCLUDED};
		}
		elsif(s/UNABRIDGED\nWAIF//){
			$nativity=qq{WAIF};
		}
		elsif(s/UNABRIDGED\nAGRICULTURAL WEED//){
			$nativity=qq{AGRICULTURAL WEED};
		}
		elsif(s/NATURALIZED//){
			$nativity=qq{NATURALIZED};
		}
		elsif(s/NATIVE//){
			$nativity=qq{NATIVE};
		}
		#$nativity=qq{<font size="1"><b>$nativity</b></font>} if $nativity;
		s/^UNABRIDGED\n//;
		s|TJM2 AUTHOR:(.*)|<span class="treatTjm2Author">$1</span>|i;
		s|(TJM1 AUTHOR:.*)||i;
		s|^FAMILY: *(.*)|<span class="treatFamily">$1</span>|;
		s|COMMON NAME: (.*)|<span class="treatCommon">$1</span>|;
		s|^([A-Z]+)$|<span class="treatTaxonGenusName">$1</span>|ms;
		s|HABIT\+: *|<span class="treatNativity">$nativity</span>\n<span class="treatDesc">| && s/$/\n<\/span>/;
		s/FLOWERING TIMES?: of sp./<span class="treatFloweringTime">Flowering times of sp.<\/span>/;
		s|FLOWERING TIMES?: *(.*)|<span class="treatFloweringTime">$1</span>|;
		s|^((STAMINATE) FLOWER(S?)):? ?(.*)|<span class="treat${2}Fl">${4}</span>|mg;
		s|^((PISTILLATE) FLOWER(S?)):? ?(.*)|<span class="treat${2}Fl">${4}</span>|mg;
		s!^(FLOWER(S?)):? ?(.*)!<span class="treat$1Fl">$3</span>!mg;
		s|^STEM(S?:?) *(.*)|<span class="treatStem">$2</span>|m;
		s|^SEED(S?:?) *(.*)|<span class="treatSeed">$2</span>|m;
		s|LEAVES:? *(.*)|<span class="treatLf">$1</span>|;
		s|LEAF:? *(.*)|<span class="treatLf">$1</span>|;
		s!^((STAMINATE|PISTILLATE) ?)?INFLORESCENCE(S?:?)(.*)!<span class="treat$2Infl">$4</span>!mg;
		s|^FRUIT(S?:?) *(.*)|<span class="treatFr">$2</span>|m;
		s|GENERA IN FAMILY: *(.*)|<span class="treatGeninFam">$1</span>|;
		s|SPECIES IN GENUS: *(.*)|<span class="treatSpinGen">$1</span>|;
		if(s|CHROMOSOMES: (.*)|<span class="treatChromosomes">$1</span>|){
			s/([xn]) ?= ?/<i>$1<\/i>=/;
		}
		s|TOXICITY: (.*)|<span class="treatTox">$1</span>|;

s|^([A-Z]+)$|<center><font size="3"><b>$1</b></font>|ms;

		s|ETYMOLOGY: (.*)|<span class="treatEtym">$1</span>|;
		s|UNABRIDGED SPECIES IN GENUS: *\[(.*)\]|<span class="treatUnabrSpGen">$1</span>|;
		s|UNABRIDGED REFERENCES?: *\[(.*)\]|<span class="treatUnabrRef">$1</span>|;
		s|UNABRIDGED REFERENCES?: *(.*)|<span class="treatUnabrRef">$1</span>|;
		s|REFERENCES: *\[?(.*)\]?|<span class="treatRef">$1</span>|;
		s|REFERENCE[S()]*: \[?(.*)\]?|<span class="treatRef">$1</span>|;
		s|UNABRIDGED NOTE[()S]*: *(.*)|<span class="treatUnabrNote">$1</span>|;
		if(m/UNABRIDGED SYNONYMS?: *(.+)/){
			$syns=&format_syns($1);
			s|(UNABRIDGED SYNONYMS:).*|<span class="treatUnabrSynonyms">$syns</span>|;
		}
		if(m/^MISAPPLIED NAMES?: *(.+)/m){
			$syns=&format_syns($1);
			s|(MISAPPLIED NAMES:).*|<span class="treatMisapp">$syns</span>|;
		}
		if(m/UNABRIDGED MISAPPLIED NAMES?: *(.+)/){
			$syns=&format_syns($1);
			s|(UNABRIDGED MISAPPLIED NAMES:).*|<span class="treatUnabrMisapp">$syns</span>|;
		}
		s|UNABRIDGED ETYMOLOGY: *(.*)|<span class="treatUnabrEtym">$1</span>|;
		s|HORTICULTURAL INFORMATION: ...*|<span_class="treatHort">{hort link}</span>|;
		s/([a-z-]+) (subsp\.|var\.) (\1)\nTAXON AUTHOR: *(.*)/$1 $4 $2 $1/ ||
		s/\nTAXON AUTHOR: *(.*)/ $1/;
		s|^(([A-Z])[A-Z]+) ([a-z]+.*)|<span class="treatTaxonName" full="$1">$2. $3</span>|m;
		s/ECOLOGY: of sp./Ecology of sp./;
		s/BIOREGIONAL DISTRIBUTION: of sp./<span class="treatBioregDist">Distribution in CA of sp.<\/span>/;
		s|BIOREGIONAL DISTRIBUTION: (.*)|<span class="treatBioregDist">$1</span>|;
		s|DISTRIBUTION OUTSIDE CALIFORNIA: (.*)|<span class="treatExtraCalDist">$1</span>|;
		s/DISTRIBUTION OUTSIDE CALIFORNIA://;
		s|ECOLOGY: (.*?)<span|<span class="treatEcology">$1</span>\n<span|ms;
		s|ELEVATION: *of sp.|<span class="treatElev">Elevation of sp.</span>|;
		s|ELEVATION: (.*)|<span class="treatElev">$1</span>|;
		s/RARITY STATUS: (.*)/<span class="treatRarity">$1<\/span>/;
		s|NOTE[()S]*: (.*)|<span class="treatNote">$1</span>|;
		s/AUTHORSHIP OF PARTS: /<P>/;
		s|\+/-|&plusmn;|g;
		s|\+-|&plusmn;|g;
		s/---/&mdash;/g;
		s/--/&ndash;/g;
	#Hultén
	s/é/&eacute;/g;
#Källersjö 
s/ö/&oslash;/g;
s/ä/&auml;/g;
s/([0-9])-([0-9])/$1&ndash;$2/;
s/Madrono/Madro&ntilde;o/g;
		while(s/_/<I>/){
			s/_/<\/I>/;
		}
		if(m/SYNONYMS?: *(.+)/){
			$syns=&format_syns($1);
			s|(SYNONYMS?:).*|<span class="treatSynonyms">$syns</span>|;
		}
#kluge that became necessary when file was read in as unit
		s/<\/blockquote>\]/]<\/blockquote>/;
		#s/<\/blockquote>\]/]flabba3<\/blockquote>/;
s/  +/ /g;
		print "$_\n<P>";
	}
	print <<EOP;
<table>
<!-- Beginning of footer -->  
  <tr class=banner>
    <td colspan="5" height="18"><img src="http://ucjeps.berkeley.edu/common/images/common_spacer.gif" alt="" width="1" height="1" border="0" /></td>
  </tr>
  <tr><td colspan="5"><a href="http://ucjeps.berkeley.edu/jepsonmanual/review/">View all Second Edition Treatments</a></td></tr>
    <td colspan="5" height="20"><span class="copyrightText">&nbsp;&nbsp;<a href="http://ucjeps.berkeley.edu/main/copyright.html">Copyright</a> &copy; 2006 Regents of the University of California</span></td>
  </tr>
  <tr>
    <td width="15"><img src="http://ucjeps.berkeley.edu/common/images/common_spacer.gif" alt="" width="15" height="1" /></td>
    <td width="15"><img src="http://ucjeps.berkeley.edu/common/images/common_spacer.gif" alt="" width="15" height="1" /></td>
    <td width=688><img src="http://ucjeps.berkeley.edu/common/images/common_spacer.gif" alt="" width="5" height="1" /></td>
    <td width="15"><img src="http://ucjeps.berkeley.edu/common/images/common_spacer.gif" alt="" width="15" height="1" /></td>
    <td width="128"><img src="http://ucjeps.berkeley.edu/common/images/common_spacer.gif" alt="" width="15" height="1" /></td>
  </tr>
</table>
<!-- End of footer -->  

</body>
</html>
EOP
}
sub format_syns {
	local($syns)=shift;
	@syns=split(/; /,$syns);
	foreach(@syns){
		s/^([^ ]+ [^ ]+) [A-Z].*(subsp\.|var\.)/$1 $2/;
		s/^([^ ]+ [^ ]+)/<i>$1<\/i>/;
		s/subsp. ([^ ]+)/subsp. <i>$1<\/i>/;
		s/var. ([^ ]+)/var. <i>$1<\/i>/;
	}
	$syns=join(";\n", @syns);
	$syns=~s/^\[//;
	$syns=~s/\]//;
	$syns;
}

