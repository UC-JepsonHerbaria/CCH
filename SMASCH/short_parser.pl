#converts all .post.txt files to html files for display. Writes output to WEB folder
$suffix="post.txt";
opendir(DIR,".");
$single_file=shift;
$viewers=shift;
if($viewers=~/editor/i){
$explanatory_header=<<EOH;
 <p class="bodyText">This treatment has undergone both technical and scientific editing within the Jepson Flora Project. Please forward any comments or corrections you may have to the Scientific Editor, Dr. Thomas Rosatti (<a href="mailto:rosatti\@berkeley.edu?subject=Second_edition_comments$taxon">rosatti\@berkeley.edu</a>).<br /> 
EOH
$pageAuthorLine=qq{<span class="pageAuthorLine">Treatments for editorial viewing </span><br />};
}
else{
$explanatory_header=<<EOH;
<p class="bodyText">This treatment has undergone both technical and scientific editing within the Jepson Flora Project and is, in the view of the author or authors as well as the Jepson Flora Project Staff and the Jepson Flora Project Editors, ready for public viewing. Please forward any comments or corrections you may have to the Scientific Editor, Dr. Thomas Rosatti (<a href="mailto:rosatti\@berkeley.edu?subject=Second_edition_comments$taxon">rosatti\@berkeley.edu</a>).<br /> 
EOH
$pageAuthorLine=qq{<span class="pageAuthorLine">Treatments for public viewing </span><br />};
}
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
	open(OUT, ">WEB/$outfile") || die "couldn't open $outfile\n";
	print OUT <<EOP;
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
<table class=horizMenu width="100%" border="0" cellspacing="0" cellpadding="0">
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
      $pageAuthorLine
      <br />
	  
$explanatory_header

</td>
</tr>
</table>
EOP
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
#1' Involucel tube with 8 valve-like openings; st shaggy-hairy; corolla blue; pl gen ann...-> [S. stellata]
			s/--&gt;( *)\[([A-Z]\. [a-z].*)\]/--&gt;[<I>$2<\/I>]/g;
			s/--&gt;(.*)\[(.*)\]/--&gt;<I>$1<\/I> [$2]/g;
 			s/--&gt; *(subsp\.|var\.|f\.) (.*)/--&gt;<!-- -->$1 <I>$2<\/I>/g;
			s/--&gt;([^<\[].*)/--&gt;<I>$1<\/I>/g;
			s/--&gt;<I> *([A-Z]+) *<\/I>/--&gt; $1/g;
			s/(--&gt;.* [a-z]+) (var\.|subsp\.|f\.) /$1<\/i> $2 <i>/g;
			s|\+/-|&plusmn;|g;
			s|\+-|&plusmn;|g;
			s/ > or =/ &ge;/g;
			if(s/UNABRIDGED KEY/<font color="blue">Unabridged key/){
				s/$/<\/font>/;
			}
		while(s/_/<I>/){
			s/_/<\/I>/;
		}
 s/&95;/_/g;
			s/UNABRIDGED\n//;
s/  +/ /g;
			#print OUT "flabba1<blockquote>$_<\/blockquote>\n";
			print OUT "<blockquote>$_<\/blockquote>\n";
			next;
		}
######################################################
		if(s/UNABRIDGED\nURBAN WEED//){
			$nativity=qq{URBAN WEED};
		}
		elsif(s/UNABRIDGED\nWAIF//){
			$nativity=qq{WAIF};
		}
		elsif(s/^WAIF//){
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
		$nativity=qq{<font size="1"><b>$nativity</b></font>} if $nativity;
		s/^UNABRIDGED\n//;
		s|TJM2 AUTHOR:(.*)|<h4>$1</h4>|i;
		s|(TJM1 AUTHOR:.*)||i;
		s|^FAMILY: *||;
		s|COMMON NAME: (.*)|<font size="3">$1</font>|;
		s|^([A-Z]+)$|<center><font size="4"><b>$1</b></font>|ms;
		s|HABIT\+: *|<br>$nativity</center><blockquote>| && s/$/\n<\/blockquote>/;
		#s|HABIT\+: *|<br><font size="1"><b>$nativity</b></font></center><blockquote>| && s/$/\n<\/blockquote>/;
		#s|HABIT\+: *|<br><font size="1"><b>$nativity</b></font></center>flabba2<blockquote>| && s/$/\n<\/blockquote>/;
		s/FLOWERING TIMES?: of sp./Flowering times of sp./;
		s/FLOWERING TIMES?: *//;
		s!^((STAMINATE|PISTILLATE) ?)?FLOWER(S?:?)!<b>$1FL:</b> !msg;
		s|^STEM(S?:?) *|<b>ST:</b> |m;
		s|^PLANT BODY: *|<b>PL BODY:</b> |m;
		s|^PLANT BODIES: *|<b>PL BODY:</b> |m;
		s|^SEED(S?:?) *|<b>SEED:</b> |m;
		s|LEAVES:?|<b>LF:</b> |;
		s|^LEAF:?|<b>LF:</b> |m;
		s!((STAMINATE|PISTILLATE) ?)?INFLORESCENCE(S?:?)!<B>$1INFL:</b> !g;
		s|^FRUIT(S?:?)|<b>FR:</b> |m;
		s/GENERA IN FAMILY: / /;
		s/SPECIES IN GENUS: / /;
		if(s/CHROMOSOMES: //){
			s/([xn]) ?= ?/<i>$1<\/i>=/;
		}
		s/TOXICITY: //;
		s|^([A-Z]+)$|<center><font size="3"><b>$1</b></font>|ms;
		s|ETYMOLOGY:||;
		s/UNABRIDGED SPECIES IN GENUS: *\[(.*)\]/<br><font color="blue">Unabridged species in genus: [$1]<\/font><br>/;
		s/UNABRIDGED REFERENCE[()S]*?: *\[(.*)\]/<br><font color="blue">Unabridged references: [$1]<\/font><br>/;
		s/UNABRIDGED REFERENCE[()S]*?: *(.*)/<br><font color="blue">Unabridged references: [$1]<\/font><br>/;
		s/REFERENCE[S()]*: \[(.*)\]/[$1]/;
		s/REFERENCE[S()]*: (.*)/[$1]/;
		s/UNABRIDGED NOTE[()S]*:(.*)/<br><font color="blue">Unabridged note: $1<\/font><br>/ && s!((JEPS|UC|CHSC)\d+)!<a href="http://ucjeps.berkeley.edu/cgi-bin/new&95;detail.pl?accn&95;num=$1">$1</a>!g;
		if(m/UNABRIDGED SYNONYMS?: *(.+)/){
			$syns=&format_syns($1);
			s/(UNABRIDGED SYNONYMS:).*/<br><font color="blue">$1 [$syns]<\/font><br>/;
		}
		if(m/^MISAPPLIED NAMES?: *(.+)/m){
			$syns=&format_syns($1);
			s/^(MISAPPLIED NAMES:).*/$1 [$syns]/m;
		}
		if(m/UNABRIDGED MISAPPLIED NAMES?: *(.+)/){
			$syns=&format_syns($1);
			s/(UNABRIDGED MISAPPLIED NAMES:).*/<br><font color="blue">$1 [$syns]<\/font>/;
		}
		s/UNABRIDGED ETYMOLOGY[()S]*?:(.*)/<br><font color="blue">Unabridged etymology: $1<\/font><br>/;
		s/HORTICULTURAL INFORMATION: ...*/{hort link}/;
		if(s|^(([A-Z])[A-Z]+) ([a-z]+.*)|<center><font size="4"><b>$2. $3</b></font>|m){
#SAMBUCUS racemosa var. racemosa
#TAXON AUTHOR: L.
			if(m!^([A-Z].) ([^ ]+) (subsp\.|var\.|f\.) \2!m){
				s!\nTAXON AUTHOR: *(.*)!!;
				$taxaut=$1;
				s!([A-Z]\.) ([^ ]+) (subsp\.|var\.|f\.) \2!$1 $2</b> $taxaut $3 <b>$2!;
print "flabba1";
			}
			else{
print "flabba2 $_";
			s!(<center.*) (subsp\.|var\.|f\.) ([^ ]+)!$1</b> $2 <b>$3!;
			}
		}
		s!\nTAXON AUTHOR: *(.*)! <font size="4">$1</font>!;
		s/ECOLOGY: *\n/ /;
		s/ECOLOGY: of sp./Ecology of sp./;
		s/ECOLOGY: / /;
		s/RARITY STATUS: (.*)/{rarity link: $1}/;
		s/ELEVATION: *of sp./Elevation of sp./;
		s/ELEVATION: *//;
		s/BIOREGIONAL DISTRIBUTION: of sp./Distribution in CA of sp./;
		s/BIOREGIONAL DISTRIBUTION: //;
		s/DISTRIBUTION OUTSIDE CALIFORNIA: of sp./Distribution outside CA of sp./;
		s/DISTRIBUTION OUTSIDE CALIFORNIA://;
		s/NOTE[()S]*: *//;
		s/AUTHORSHIP OF PARTS: /<P>/;
		s|\+/-|&plusmn;|g;
		s|\+-|&plusmn;|g;
		s/---/&mdash;/g;
		s/--/&ndash;/g;
		s/([0-9])-([0-9])/$1&ndash;$2/;
s/Madrono/Madro&ntilde;o/g;
		while(s/_/<I>/){
			s/_/<\/I>/;
		}
 s/&95;/_/g;
		if(m/SYNONYMS?: *(.+)/){
			$syns=&format_syns($1);
			s/SYNONYMS?:.*/[$syns]/;
		}
#kluge that became necessary when file was read in as unit
		s/<\/blockquote>\]/]<\/blockquote>/;
		#s/<\/blockquote>\]/]flabba3<\/blockquote>/;
s/  +/ /g;
		print OUT "$_\n<P>";
	}
	print OUT <<EOP;
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
s/<\/?b>//g;
		s/^([^ ]+ [^ ]+)/<i>$1<\/i>/;
		s/subsp. ([^ ]+)/subsp. <i>$1<\/i>/;
		s/var. ([^ ]+)/var. <i>$1<\/i>/;
	}
	$syns=join("; ", @syns);
	$syns=~s/^\[//;
	$syns=~s/\]//;
	$syns;
}
