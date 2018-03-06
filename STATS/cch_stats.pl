#!/usr/bin/perl
#cch_query_log is the one to truncate
# in ucjeps_data on annie, use the command cat /dev/null >| cch_query_log

use CGI;
$query = new CGI;                        # create new CGI object
print $query->header unless $header_printed++;                    # create the HTTP header
$common_html_head=<<EOH;
<html>
<head>
<Meta NAME="ROBOTS" CONTENT="NOINDEX, NOFOLLOW">
<META http-equiv="Content-Type" content="text/html; charset=UTF-8">
<title>UC/JEPS: CCH query statistics</title>
<link href="http://ucjeps.berkeley.edu/consortium/style_consortium.css" rel="stylesheet" type="text/css">
</head>
<body>
EOH
print $common_html_head;
print &load_header;
$data_path	="/usr/local/web/ucjeps_data/ucjeps_data/";
$tail=`tail ${data_path}CCH_searches.txt`;
$tail=~s/\&?max_rec=\d+//g;
$tail=~s/[\n\r]+/<br>/g;
open(IN, "${data_path}cch_query_log") || die;
@QL=(<IN>);
close(IN);
$now=scalar(localtime());
foreach (@QL){
#print;
	if(($time)=m/^(\d\d\d\d\d\d\d\d\d\d)/){
++$queries;
		unless($st++){
			$start_time=scalar(localtime($time));
		}
	}
	else{
s/^CLARK-A/CLARK/;
s/^YM-YOSE/YM/;
s/^CAS-BOT-BC/CAS/; #change to account for the CAS/DS code change
s/^DS/CAS/;
#s/UCLA/UC/; not sure this is needed because the UCLA specimens at UC are converted to UC in the loader now
s/^ECON/HUH/;
s/^AMES/HUH/;
s/^A/HUH/;
s/^GH/HUH/;
		if(m/^([A-Z]+)/){
			$store{$1}++;
$total++;
		}
		if(m/^([A-Z]+).*\t/){
			$store_detail{$1}++;
$detail_total++;
		}
	}
}
print qq{<table border=1 cellpadding=5><tr><td align="center">};
print <<EOP;


<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>$start_time</tt></td></tr>
<tr><td>To:</td><td><tt>$now</tt></td></tr>
</table>
</td></tr>
EOP
print "<tr><td><h3>Records returned in general searches</h3>\n<table>";
foreach(sort(keys(%store))){
print "<tr><th>$_</th><td align=right>$store{$_}</td></tr>\n";
}
print "</table>";
print "Total: $total in $queries searches</td></tr>";
print "<tr><td><h3>Records returned in detail displays</h3>\n<table>";
foreach(sort(keys(%store_detail))){
print "<tr><th>$_</th><td align=right> $store_detail{$_}</td></tr>\n";
}
print "</table>";
print "Total: $detail_total</td></tr></table>\n\n";
print "<H3>Last 10 general searches</H3>$tail<P>";
while(<DATA>){
print;
}
sub load_header{
return <<EOH;
<table width="100%" class="banner" border="0" cellpadding="0" cellspacing="0">
  <tr><td width="100" align="center"><img src="/consortium/images/CCH_logo_02_80.png" width="80" height="82"></td>
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
	<a class="bannerHerbs" href="">CSUSB</a> &middot; 
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
<a href="http://www.sci.sdsu.edu/herb" target="_blank" class="bannerHerbs">          SDSU</a> &middot; 
        <a href="http://www2.sjsu.edu/depts/herbarium/" target="_blank" class="bannerHerbs">
          SJSU</a>  &middot; 
        <a href="http://ucjeps.berkeley.edu/" target="_blank" class="bannerHerbs">
          UC-JEPS</a>  &middot; 
        <a href="http://www.herbarium.ucr.edu/" target="_blank" class="bannerHerbs">
          UCR</a> &middot; 
        <a href="http://ccber.lifesci.ucsb.edu/collections/botanical/" target="_blank" class="bannerHerbs">
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
    <td width="1" >&nbsp;</td>
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
}
__END__
<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Tue Feb 13 10:50:59 2018</tt></td></tr>
<tr><td>To:</td><td><tt>Tue Mar  6 09:11:53 2018</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BFRS</th><td align=right>3830</td></tr>
<tr><th>BLMAR</th><td align=right>1729</td></tr>
<tr><th>C</th><td align=right>1</td></tr>
<tr><th>CAS</th><td align=right>1408803</td></tr>
<tr><th>CATA</th><td align=right>33062</td></tr>
<tr><th>CDA</th><td align=right>108168</td></tr>
<tr><th>CHSC</th><td align=right>303916</td></tr>
<tr><th>CLARK</th><td align=right>33579</td></tr>
<tr><th>CSUSB</th><td align=right>9896</td></tr>
<tr><th>GMDRC</th><td align=right>46686</td></tr>
<tr><th>HREC</th><td align=right>2142</td></tr>
<tr><th>HSC</th><td align=right>248225</td></tr>
<tr><th>HUH</th><td align=right>223645</td></tr>
<tr><th>IRVC</th><td align=right>30928</td></tr>
<tr><th>JEPS</th><td align=right>554435</td></tr>
<tr><th>JOTR</th><td align=right>46336</td></tr>
<tr><th>JROH</th><td align=right>36327</td></tr>
<tr><th>LA</th><td align=right>86448</td></tr>
<tr><th>MACF</th><td align=right>1152</td></tr>
<tr><th>NY</th><td align=right>51451</td></tr>
<tr><th>OBI</th><td align=right>165513</td></tr>
<tr><th>PASA</th><td align=right>8695</td></tr>
<tr><th>PGM</th><td align=right>22760</td></tr>
<tr><th>POM</th><td align=right>382214</td></tr>
<tr><th>RSA</th><td align=right>1781603</td></tr>
<tr><th>SACT</th><td align=right>5995</td></tr>
<tr><th>SBBG</th><td align=right>763213</td></tr>
<tr><th>SCFS</th><td align=right>4147</td></tr>
<tr><th>SD</th><td align=right>796408</td></tr>
<tr><th>SDSU</th><td align=right>103416</td></tr>
<tr><th>SEINET</th><td align=right>317407</td></tr>
<tr><th>SFV</th><td align=right>36617</td></tr>
<tr><th>SJSU</th><td align=right>35153</td></tr>
<tr><th>U</th><td align=right>1</td></tr>
<tr><th>UC</th><td align=right>1107984</td></tr>
<tr><th>UCD</th><td align=right>382724</td></tr>
<tr><th>UCR</th><td align=right>922314</td></tr>
<tr><th>UCSB</th><td align=right>180021</td></tr>
<tr><th>UCSC</th><td align=right>33126</td></tr>
<tr><th>VVC</th><td align=right>10193</td></tr>
<tr><th>YM</th><td align=right>25370</td></tr>
</table>Total: 10315633 in 267057 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BFRS</th><td align=right> 10</td></tr>
<tr><th>BLMAR</th><td align=right> 26</td></tr>
<tr><th>CAS</th><td align=right> 8091</td></tr>
<tr><th>CATA</th><td align=right> 59</td></tr>
<tr><th>CDA</th><td align=right> 1170</td></tr>
<tr><th>CHSC</th><td align=right> 3439</td></tr>
<tr><th>CLARK</th><td align=right> 256</td></tr>
<tr><th>CSUSB</th><td align=right> 36</td></tr>
<tr><th>GMDRC</th><td align=right> 336</td></tr>
<tr><th>HREC</th><td align=right> 15</td></tr>
<tr><th>HSC</th><td align=right> 2965</td></tr>
<tr><th>HUH</th><td align=right> 2056</td></tr>
<tr><th>IRVC</th><td align=right> 166</td></tr>
<tr><th>JEPS</th><td align=right> 11650</td></tr>
<tr><th>JOTR</th><td align=right> 204</td></tr>
<tr><th>JROH</th><td align=right> 259</td></tr>
<tr><th>LA</th><td align=right> 654</td></tr>
<tr><th>MACF</th><td align=right> 12</td></tr>
<tr><th>NY</th><td align=right> 641</td></tr>
<tr><th>OBI</th><td align=right> 1602</td></tr>
<tr><th>PASA</th><td align=right> 54</td></tr>
<tr><th>PGM</th><td align=right> 318</td></tr>
<tr><th>POM</th><td align=right> 2931</td></tr>
<tr><th>RSA</th><td align=right> 13702</td></tr>
<tr><th>SACT</th><td align=right> 52</td></tr>
<tr><th>SBBG</th><td align=right> 4064</td></tr>
<tr><th>SCFS</th><td align=right> 37</td></tr>
<tr><th>SD</th><td align=right> 4572</td></tr>
<tr><th>SDSU</th><td align=right> 702</td></tr>
<tr><th>SEINET</th><td align=right> 2256</td></tr>
<tr><th>SFV</th><td align=right> 245</td></tr>
<tr><th>SJSU</th><td align=right> 437</td></tr>
<tr><th>UC</th><td align=right> 10788</td></tr>
<tr><th>UCD</th><td align=right> 3984</td></tr>
<tr><th>UCR</th><td align=right> 6709</td></tr>
<tr><th>UCSB</th><td align=right> 1445</td></tr>
<tr><th>UCSC</th><td align=right> 341</td></tr>
<tr><th>VVC</th><td align=right> 76</td></tr>
<tr><th>YM</th><td align=right> 331</td></tr>
</table>Total: 86691</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Wed Jan 24 13:25:53 2018</tt></td></tr>
<tr><td>To:</td><td><tt>Tue Feb 13 10:50:59 2018</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BFRS</th><td align=right>435</td></tr>
<tr><th>BLMAR</th><td align=right>3365</td></tr>
<tr><th>CAS</th><td align=right>2092100</td></tr>
<tr><th>CATA</th><td align=right>30809</td></tr>
<tr><th>CDA</th><td align=right>178163</td></tr>
<tr><th>CHSC</th><td align=right>522529</td></tr>
<tr><th>CLARK</th><td align=right>69062</td></tr>
<tr><th>CSUSB</th><td align=right>20699</td></tr>
<tr><th>GMDRC</th><td align=right>29131</td></tr>
<tr><th>HREC</th><td align=right>2023</td></tr>
<tr><th>HSC</th><td align=right>379808</td></tr>
<tr><th>HUH</th><td align=right>397903</td></tr>
<tr><th>IRVC</th><td align=right>47847</td></tr>
<tr><th>JEPS</th><td align=right>765496</td></tr>
<tr><th>JOTR</th><td align=right>24465</td></tr>
<tr><th>JROH</th><td align=right>63853</td></tr>
<tr><th>LA</th><td align=right>164559</td></tr>
<tr><th>MACF</th><td align=right>2140</td></tr>
<tr><th>NY</th><td align=right>82918</td></tr>
<tr><th>OBI</th><td align=right>551017</td></tr>
<tr><th>PASA</th><td align=right>16191</td></tr>
<tr><th>PGM</th><td align=right>48714</td></tr>
<tr><th>POM</th><td align=right>799469</td></tr>
<tr><th>RSA</th><td align=right>3021336</td></tr>
<tr><th>SACT</th><td align=right>9819</td></tr>
<tr><th>SBBG</th><td align=right>1053487</td></tr>
<tr><th>SCFS</th><td align=right>9017</td></tr>
<tr><th>SD</th><td align=right>1819324</td></tr>
<tr><th>SDSU</th><td align=right>226047</td></tr>
<tr><th>SEINET</th><td align=right>564047</td></tr>
<tr><th>SFV</th><td align=right>54380</td></tr>
<tr><th>SJSU</th><td align=right>57655</td></tr>
<tr><th>UC</th><td align=right>1987451</td></tr>
<tr><th>UCD</th><td align=right>671176</td></tr>
<tr><th>UCR</th><td align=right>1566531</td></tr>
<tr><th>UCSB</th><td align=right>267662</td></tr>
<tr><th>UCSC</th><td align=right>98968</td></tr>
<tr><th>VVC</th><td align=right>17523</td></tr>
<tr><th>YM</th><td align=right>44983</td></tr>
</table>Total: 17762102 in 237900 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BFRS</th><td align=right> 2</td></tr>
<tr><th>BLMAR</th><td align=right> 46</td></tr>
<tr><th>CAS</th><td align=right> 16676</td></tr>
<tr><th>CATA</th><td align=right> 90</td></tr>
<tr><th>CDA</th><td align=right> 1575</td></tr>
<tr><th>CHSC</th><td align=right> 3826</td></tr>
<tr><th>CLARK</th><td align=right> 266</td></tr>
<tr><th>CSUSB</th><td align=right> 56</td></tr>
<tr><th>GMDRC</th><td align=right> 240</td></tr>
<tr><th>HREC</th><td align=right> 13</td></tr>
<tr><th>HSC</th><td align=right> 3173</td></tr>
<tr><th>HUH</th><td align=right> 2152</td></tr>
<tr><th>IRVC</th><td align=right> 191</td></tr>
<tr><th>JEPS</th><td align=right> 6735</td></tr>
<tr><th>JOTR</th><td align=right> 259</td></tr>
<tr><th>JROH</th><td align=right> 200</td></tr>
<tr><th>LA</th><td align=right> 882</td></tr>
<tr><th>MACF</th><td align=right> 22</td></tr>
<tr><th>NY</th><td align=right> 653</td></tr>
<tr><th>OBI</th><td align=right> 2518</td></tr>
<tr><th>PASA</th><td align=right> 62</td></tr>
<tr><th>PGM</th><td align=right> 503</td></tr>
<tr><th>POM</th><td align=right> 4343</td></tr>
<tr><th>RSA</th><td align=right> 15337</td></tr>
<tr><th>SACT</th><td align=right> 77</td></tr>
<tr><th>SBBG</th><td align=right> 5041</td></tr>
<tr><th>SCFS</th><td align=right> 66</td></tr>
<tr><th>SD</th><td align=right> 7100</td></tr>
<tr><th>SDSU</th><td align=right> 765</td></tr>
<tr><th>SEINET</th><td align=right> 3647</td></tr>
<tr><th>SFV</th><td align=right> 324</td></tr>
<tr><th>SJSU</th><td align=right> 649</td></tr>
<tr><th>UC</th><td align=right> 14820</td></tr>
<tr><th>UCD</th><td align=right> 5294</td></tr>
<tr><th>UCR</th><td align=right> 6613</td></tr>
<tr><th>UCSB</th><td align=right> 1727</td></tr>
<tr><th>UCSC</th><td align=right> 460</td></tr>
<tr><th>VVC</th><td align=right> 74</td></tr>
<tr><th>YM</th><td align=right> 300</td></tr>
</table>Total: 106777</td></tr></table>
<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Wed Nov 22 08:38:05 2017</tt></td></tr>
<tr><td>To:</td><td><tt>Wed Jan 24 13:25:53 2018</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BFRS</th><td align=right>17</td></tr>
<tr><th>BLMAR</th><td align=right>2735</td></tr>
<tr><th>CAS</th><td align=right>16829</td></tr>
<tr><th>CATA</th><td align=right>56461</td></tr>
<tr><th>CDA</th><td align=right>215918</td></tr>
<tr><th>CHSC</th><td align=right>488312</td></tr>
<tr><th>CLARK</th><td align=right>493</td></tr>
<tr><th>CSUSB</th><td align=right>23686</td></tr>
<tr><th>GMDRC</th><td align=right>78912</td></tr>
<tr><th>HREC</th><td align=right>17</td></tr>
<tr><th>HSC</th><td align=right>486986</td></tr>
<tr><th>HUH</th><td align=right>452236</td></tr>
<tr><th>IRVC</th><td align=right>51613</td></tr>
<tr><th>JEPS</th><td align=right>975704</td></tr>
<tr><th>JOTR</th><td align=right>77112</td></tr>
<tr><th>JROH</th><td align=right>38543</td></tr>
<tr><th>LA</th><td align=right>169773</td></tr>
<tr><th>MACF</th><td align=right>2578</td></tr>
<tr><th>NY</th><td align=right>167286</td></tr>
<tr><th>OBI</th><td align=right>690619</td></tr>
<tr><th>PASA</th><td align=right>17991</td></tr>
<tr><th>PGM</th><td align=right>47598</td></tr>
<tr><th>POM</th><td align=right>783335</td></tr>
<tr><th>RSA</th><td align=right>3401432</td></tr>
<tr><th>SACT</th><td align=right>12363</td></tr>
<tr><th>SBBG</th><td align=right>1321135</td></tr>
<tr><th>SCFS</th><td align=right>8805</td></tr>
<tr><th>SD</th><td align=right>1539358</td></tr>
<tr><th>SDSU</th><td align=right>188788</td></tr>
<tr><th>SEINET</th><td align=right>720824</td></tr>
<tr><th>SFV</th><td align=right>70687</td></tr>
<tr><th>SJSU</th><td align=right>74447</td></tr>
<tr><th>UC</th><td align=right>2400095</td></tr>
<tr><th>UCD</th><td align=right>739328</td></tr>
<tr><th>UCR</th><td align=right>1768774</td></tr>
<tr><th>UCSB</th><td align=right>366069</td></tr>
<tr><th>UCSC</th><td align=right>84838</td></tr>
<tr><th>VVC</th><td align=right>47178</td></tr>
<tr><th>YM</th><td align=right>818</td></tr>
</table>Total: 17589693 in 410309 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BFRS</th><td align=right> 17</td></tr>
<tr><th>BLMAR</th><td align=right> 46</td></tr>
<tr><th>CAS</th><td align=right> 16829</td></tr>
<tr><th>CATA</th><td align=right> 245</td></tr>
<tr><th>CDA</th><td align=right> 2318</td></tr>
<tr><th>CHSC</th><td align=right> 5891</td></tr>
<tr><th>CLARK</th><td align=right> 493</td></tr>
<tr><th>CSUSB</th><td align=right> 75</td></tr>
<tr><th>GMDRC</th><td align=right> 588</td></tr>
<tr><th>HREC</th><td align=right> 17</td></tr>
<tr><th>HSC</th><td align=right> 6414</td></tr>
<tr><th>HUH</th><td align=right> 6954</td></tr>
<tr><th>IRVC</th><td align=right> 335</td></tr>
<tr><th>JEPS</th><td align=right> 10667</td></tr>
<tr><th>JOTR</th><td align=right> 695</td></tr>
<tr><th>JROH</th><td align=right> 485</td></tr>
<tr><th>LA</th><td align=right> 1784</td></tr>
<tr><th>MACF</th><td align=right> 33</td></tr>
<tr><th>NY</th><td align=right> 2452</td></tr>
<tr><th>OBI</th><td align=right> 3782</td></tr>
<tr><th>PASA</th><td align=right> 115</td></tr>
<tr><th>PGM</th><td align=right> 506</td></tr>
<tr><th>POM</th><td align=right> 9272</td></tr>
<tr><th>RSA</th><td align=right> 39130</td></tr>
<tr><th>SACT</th><td align=right> 97</td></tr>
<tr><th>SBBG</th><td align=right> 8949</td></tr>
<tr><th>SCFS</th><td align=right> 65</td></tr>
<tr><th>SD</th><td align=right> 10304</td></tr>
<tr><th>SDSU</th><td align=right> 1365</td></tr>
<tr><th>SEINET</th><td align=right> 6396</td></tr>
<tr><th>SFV</th><td align=right> 641</td></tr>
<tr><th>SJSU</th><td align=right> 902</td></tr>
<tr><th>UC</th><td align=right> 24021</td></tr>
<tr><th>UCD</th><td align=right> 9610</td></tr>
<tr><th>UCR</th><td align=right> 15624</td></tr>
<tr><th>UCSB</th><td align=right> 3423</td></tr>
<tr><th>UCSC</th><td align=right> 819</td></tr>
<tr><th>VVC</th><td align=right> 2052</td></tr>
<tr><th>YM</th><td align=right> 818</td></tr>
</table>Total: 194229</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Thu Oct  5 12:51:54 2017</tt></td></tr>
<tr><td>To:</td><td><tt>Wed Nov 22 08:21:23 2017</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BFRS</th><td align=right>7</td></tr>
<tr><th>BLMAR</th><td align=right>2599</td></tr>
<tr><th>CAS</th><td align=right>18001</td></tr>
<tr><th>CATA</th><td align=right>52440</td></tr>
<tr><th>CD</th><td align=right>1</td></tr>
<tr><th>CDA</th><td align=right>200800</td></tr>
<tr><th>CHSC</th><td align=right>511373</td></tr>
<tr><th>CLARK</th><td align=right>889</td></tr>
<tr><th>CSUSB</th><td align=right>21500</td></tr>
<tr><th>GMDRC</th><td align=right>70479</td></tr>
<tr><th>HREC</th><td align=right>33</td></tr>
<tr><th>HSC</th><td align=right>391921</td></tr>
<tr><th>HUH</th><td align=right>451713</td></tr>
<tr><th>IRVC</th><td align=right>59593</td></tr>
<tr><th>JEPS</th><td align=right>871492</td></tr>
<tr><th>JOTR</th><td align=right>49751</td></tr>
<tr><th>JROH</th><td align=right>42232</td></tr>
<tr><th>LA</th><td align=right>228045</td></tr>
<tr><th>MACF</th><td align=right>2313</td></tr>
<tr><th>NY</th><td align=right>129119</td></tr>
<tr><th>OBI</th><td align=right>440037</td></tr>
<tr><th>PASA</th><td align=right>17356</td></tr>
<tr><th>PGM</th><td align=right>53482</td></tr>
<tr><th>POM</th><td align=right>802830</td></tr>
<tr><th>RSA</th><td align=right>3399896</td></tr>
<tr><th>SACT</th><td align=right>9679</td></tr>
<tr><th>SBBG</th><td align=right>1229546</td></tr>
<tr><th>SCFS</th><td align=right>9189</td></tr>
<tr><th>SD</th><td align=right>1656672</td></tr>
<tr><th>SDSU</th><td align=right>210981</td></tr>
<tr><th>SEINET</th><td align=right>761487</td></tr>
<tr><th>SFV</th><td align=right>73859</td></tr>
<tr><th>SJSU</th><td align=right>89573</td></tr>
<tr><th>U</th><td align=right>1</td></tr>
<tr><th>UC</th><td align=right>2263663</td></tr>
<tr><th>UCD</th><td align=right>759226</td></tr>
<tr><th>UCR</th><td align=right>1949045</td></tr>
<tr><th>UCSB</th><td align=right>294052</td></tr>
<tr><th>UCSC</th><td align=right>78457</td></tr>
<tr><th>VVC</th><td align=right>31332</td></tr>
<tr><th>YM</th><td align=right>1483</td></tr>
</table>Total: 17236147 in 564667 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BFRS</th><td align=right> 7</td></tr>
<tr><th>BLMAR</th><td align=right> 130</td></tr>
<tr><th>CAS</th><td align=right> 18001</td></tr>
<tr><th>CATA</th><td align=right> 225</td></tr>
<tr><th>CDA</th><td align=right> 4470</td></tr>
<tr><th>CHSC</th><td align=right> 14152</td></tr>
<tr><th>CLARK</th><td align=right> 889</td></tr>
<tr><th>CSUSB</th><td align=right> 182</td></tr>
<tr><th>GMDRC</th><td align=right> 1054</td></tr>
<tr><th>HREC</th><td align=right> 33</td></tr>
<tr><th>HSC</th><td align=right> 12088</td></tr>
<tr><th>HUH</th><td align=right> 7446</td></tr>
<tr><th>IRVC</th><td align=right> 639</td></tr>
<tr><th>JEPS</th><td align=right> 21205</td></tr>
<tr><th>JOTR</th><td align=right> 919</td></tr>
<tr><th>JROH</th><td align=right> 733</td></tr>
<tr><th>LA</th><td align=right> 2706</td></tr>
<tr><th>MACF</th><td align=right> 66</td></tr>
<tr><th>NY</th><td align=right> 2474</td></tr>
<tr><th>OBI</th><td align=right> 6560</td></tr>
<tr><th>PASA</th><td align=right> 197</td></tr>
<tr><th>PGM</th><td align=right> 1250</td></tr>
<tr><th>POM</th><td align=right> 12014</td></tr>
<tr><th>RSA</th><td align=right> 50911</td></tr>
<tr><th>SACT</th><td align=right> 311</td></tr>
<tr><th>SBBG</th><td align=right> 15985</td></tr>
<tr><th>SCFS</th><td align=right> 146</td></tr>
<tr><th>SD</th><td align=right> 18751</td></tr>
<tr><th>SDSU</th><td align=right> 2782</td></tr>
<tr><th>SEINET</th><td align=right> 8817</td></tr>
<tr><th>SFV</th><td align=right> 1090</td></tr>
<tr><th>SJSU</th><td align=right> 1902</td></tr>
<tr><th>UC</th><td align=right> 45798</td></tr>
<tr><th>UCD</th><td align=right> 17534</td></tr>
<tr><th>UCR</th><td align=right> 26243</td></tr>
<tr><th>UCSB</th><td align=right> 5397</td></tr>
<tr><th>UCSC</th><td align=right> 1685</td></tr>
<tr><th>VVC</th><td align=right> 675</td></tr>
<tr><th>YM</th><td align=right> 1483</td></tr>
</table>Total: 306950</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Aug 21 14:35:35 2017</tt></td></tr>
<tr><td>To:</td><td><tt>Thu Oct  5 12:07:33 2017</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BFRS</th><td align=right>1660</td></tr>
<tr><th>BLMAR</th><td align=right>4022</td></tr>
<tr><th>CAS</th><td align=right>1932417</td></tr>
<tr><th>CATA</th><td align=right>25190</td></tr>
<tr><th>CDA</th><td align=right>223085</td></tr>
<tr><th>CHSC</th><td align=right>585420</td></tr>
<tr><th>CLARK</th><td align=right>51076</td></tr>
<tr><th>CSUSB</th><td align=right>15131</td></tr>
<tr><th>GMDRC</th><td align=right>77203</td></tr>
<tr><th>HREC</th><td align=right>6876</td></tr>
<tr><th>HSC</th><td align=right>605469</td></tr>
<tr><th>HUH</th><td align=right>432498</td></tr>
<tr><th>IRVC</th><td align=right>43666</td></tr>
<tr><th>JEPS</th><td align=right>1027243</td></tr>
<tr><th>JOTR</th><td align=right>37206</td></tr>
<tr><th>JROH</th><td align=right>46515</td></tr>
<tr><th>LA</th><td align=right>164561</td></tr>
<tr><th>MACF</th><td align=right>1890</td></tr>
<tr><th>NY</th><td align=right>149791</td></tr>
<tr><th>OBI</th><td align=right>496624</td></tr>
<tr><th>PASA</th><td align=right>13725</td></tr>
<tr><th>PGM</th><td align=right>48304</td></tr>
<tr><th>POM</th><td align=right>766255</td></tr>
<tr><th>RSA</th><td align=right>3065258</td></tr>
<tr><th>SACT</th><td align=right>16504</td></tr>
<tr><th>SBBG</th><td align=right>960726</td></tr>
<tr><th>SCFS</th><td align=right>10279</td></tr>
<tr><th>SD</th><td align=right>1298664</td></tr>
<tr><th>SDSU</th><td align=right>157545</td></tr>
<tr><th>SEINET</th><td align=right>847731</td></tr>
<tr><th>SFV</th><td align=right>69866</td></tr>
<tr><th>SJSU</th><td align=right>99244</td></tr>
<tr><th>UC</th><td align=right>2401940</td></tr>
<tr><th>UCD</th><td align=right>829302</td></tr>
<tr><th>UCR</th><td align=right>1581180</td></tr>
<tr><th>UCSB</th><td align=right>298949</td></tr>
<tr><th>UCSC</th><td align=right>59891</td></tr>
<tr><th>VVC</th><td align=right>23655</td></tr>
<tr><th>YM</th><td align=right>75143</td></tr>
</table>Total: 18551704 in 662995 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BFRS</th><td align=right> 13</td></tr>
<tr><th>BLMAR</th><td align=right> 160</td></tr>
<tr><th>CAS</th><td align=right> 13674</td></tr>
<tr><th>CATA</th><td align=right> 279</td></tr>
<tr><th>CDA</th><td align=right> 5844</td></tr>
<tr><th>CHSC</th><td align=right> 17278</td></tr>
<tr><th>CLARK</th><td align=right> 1100</td></tr>
<tr><th>CSUSB</th><td align=right> 234</td></tr>
<tr><th>GMDRC</th><td align=right> 1416</td></tr>
<tr><th>HREC</th><td align=right> 16</td></tr>
<tr><th>HSC</th><td align=right> 15028</td></tr>
<tr><th>HUH</th><td align=right> 7815</td></tr>
<tr><th>IRVC</th><td align=right> 809</td></tr>
<tr><th>JEPS</th><td align=right> 26326</td></tr>
<tr><th>JOTR</th><td align=right> 991</td></tr>
<tr><th>JROH</th><td align=right> 518</td></tr>
<tr><th>LA</th><td align=right> 2893</td></tr>
<tr><th>MACF</th><td align=right> 62</td></tr>
<tr><th>NY</th><td align=right> 2862</td></tr>
<tr><th>OBI</th><td align=right> 7052</td></tr>
<tr><th>PASA</th><td align=right> 231</td></tr>
<tr><th>PGM</th><td align=right> 1230</td></tr>
<tr><th>POM</th><td align=right> 14710</td></tr>
<tr><th>RSA</th><td align=right> 61056</td></tr>
<tr><th>SACT</th><td align=right> 344</td></tr>
<tr><th>SBBG</th><td align=right> 17613</td></tr>
<tr><th>SCFS</th><td align=right> 170</td></tr>
<tr><th>SD</th><td align=right> 20266</td></tr>
<tr><th>SDSU</th><td align=right> 2877</td></tr>
<tr><th>SEINET</th><td align=right> 9351</td></tr>
<tr><th>SFV</th><td align=right> 1410</td></tr>
<tr><th>SJSU</th><td align=right> 2124</td></tr>
<tr><th>UC</th><td align=right> 54616</td></tr>
<tr><th>UCD</th><td align=right> 20861</td></tr>
<tr><th>UCR</th><td align=right> 32229</td></tr>
<tr><th>UCSB</th><td align=right> 5611</td></tr>
<tr><th>UCSC</th><td align=right> 1503</td></tr>
<tr><th>VVC</th><td align=right> 477</td></tr>
<tr><th>YM</th><td align=right> 1691</td></tr>
</table>Total: 352740</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Tue Jul 11 11:05:39 2017</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Aug 21 14:31:48 2017</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BFRS</th><td align=right>172</td></tr>
<tr><th>BLMAR</th><td align=right>2164</td></tr>
<tr><th>CAS</th><td align=right>1153146</td></tr>
<tr><th>CATA</th><td align=right>26950</td></tr>
<tr><th>CDA</th><td align=right>164712</td></tr>
<tr><th>CHSC</th><td align=right>337358</td></tr>
<tr><th>CLARK</th><td align=right>1</td></tr>
<tr><th>CSUSB</th><td align=right>11476</td></tr>
<tr><th>GMDRC</th><td align=right>27298</td></tr>
<tr><th>HREC</th><td align=right>468</td></tr>
<tr><th>HSC</th><td align=right>335179</td></tr>
<tr><th>HUH</th><td align=right>309318</td></tr>
<tr><th>IRVC</th><td align=right>35443</td></tr>
<tr><th>JEPS</th><td align=right>616980</td></tr>
<tr><th>JOTR</th><td align=right>29089</td></tr>
<tr><th>JROH</th><td align=right>35749</td></tr>
<tr><th>LA</th><td align=right>130394</td></tr>
<tr><th>MACF</th><td align=right>1308</td></tr>
<tr><th>NY</th><td align=right>93697</td></tr>
<tr><th>OBI</th><td align=right>263046</td></tr>
<tr><th>PASA</th><td align=right>9460</td></tr>
<tr><th>PGM</th><td align=right>31751</td></tr>
<tr><th>POM</th><td align=right>579915</td></tr>
<tr><th>RSA</th><td align=right>2260422</td></tr>
<tr><th>SACT</th><td align=right>9318</td></tr>
<tr><th>SBBG</th><td align=right>782626</td></tr>
<tr><th>SCFS</th><td align=right>3765</td></tr>
<tr><th>SD</th><td align=right>1314848</td></tr>
<tr><th>SDSU</th><td align=right>143113</td></tr>
<tr><th>SEINET</th><td align=right>352266</td></tr>
<tr><th>SFV</th><td align=right>42672</td></tr>
<tr><th>SJSU</th><td align=right>49368</td></tr>
<tr><th>UC</th><td align=right>1609599</td></tr>
<tr><th>UCD</th><td align=right>508029</td></tr>
<tr><th>UCR</th><td align=right>1244129</td></tr>
<tr><th>UCSB</th><td align=right>215149</td></tr>
<tr><th>UCSC</th><td align=right>43924</td></tr>
<tr><th>VVC</th><td align=right>11805</td></tr>
<tr><th>YM</th><td align=right>1557</td></tr>
</table>Total: 12787666 in 682677 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 120</td></tr>
<tr><th>CAS</th><td align=right> 54593</td></tr>
<tr><th>CATA</th><td align=right> 415</td></tr>
<tr><th>CDA</th><td align=right> 5592</td></tr>
<tr><th>CHSC</th><td align=right> 14976</td></tr>
<tr><th>CLARK</th><td align=right> 1</td></tr>
<tr><th>CSUSB</th><td align=right> 221</td></tr>
<tr><th>GMDRC</th><td align=right> 1068</td></tr>
<tr><th>HSC</th><td align=right> 13840</td></tr>
<tr><th>HUH</th><td align=right> 8140</td></tr>
<tr><th>IRVC</th><td align=right> 693</td></tr>
<tr><th>JEPS</th><td align=right> 23384</td></tr>
<tr><th>JOTR</th><td align=right> 862</td></tr>
<tr><th>JROH</th><td align=right> 658</td></tr>
<tr><th>LA</th><td align=right> 3543</td></tr>
<tr><th>MACF</th><td align=right> 68</td></tr>
<tr><th>NY</th><td align=right> 2780</td></tr>
<tr><th>OBI</th><td align=right> 9303</td></tr>
<tr><th>PASA</th><td align=right> 261</td></tr>
<tr><th>PGM</th><td align=right> 1177</td></tr>
<tr><th>POM</th><td align=right> 15471</td></tr>
<tr><th>RSA</th><td align=right> 64841</td></tr>
<tr><th>SACT</th><td align=right> 321</td></tr>
<tr><th>SBBG</th><td align=right> 21052</td></tr>
<tr><th>SCFS</th><td align=right> 153</td></tr>
<tr><th>SD</th><td align=right> 27163</td></tr>
<tr><th>SDSU</th><td align=right> 3171</td></tr>
<tr><th>SEINET</th><td align=right> 7123</td></tr>
<tr><th>SFV</th><td align=right> 1452</td></tr>
<tr><th>SJSU</th><td align=right> 2149</td></tr>
<tr><th>UC</th><td align=right> 54872</td></tr>
<tr><th>UCD</th><td align=right> 18697</td></tr>
<tr><th>UCR</th><td align=right> 32129</td></tr>
<tr><th>UCSB</th><td align=right> 5948</td></tr>
<tr><th>UCSC</th><td align=right> 1484</td></tr>
<tr><th>VVC</th><td align=right> 407</td></tr>
<tr><th>YM</th><td align=right> 1557</td></tr>
</table>Total: 399685</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Wed May  3 05:05:03 2017</tt></td></tr>
<tr><td>To:</td><td><tt>Tue Jul 11 11:05:39 2017</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>3193</td></tr>
<tr><th>CAS</th><td align=right>2612697</td></tr>
<tr><th>CATA</th><td align=right>29436</td></tr>
<tr><th>CDA</th><td align=right>213788</td></tr>
<tr><th>CHSC</th><td align=right>561193</td></tr>
<tr><th>CSUSB</th><td align=right>13993</td></tr>
<tr><th>GMDRC</th><td align=right>61808</td></tr>
<tr><th>HSC</th><td align=right>558256</td></tr>
<tr><th>HUH</th><td align=right>410082</td></tr>
<tr><th>IRVC</th><td align=right>40543</td></tr>
<tr><th>JEPS</th><td align=right>906421</td></tr>
<tr><th>JOTR</th><td align=right>34122</td></tr>
<tr><th>JROH</th><td align=right>60367</td></tr>
<tr><th>LA</th><td align=right>158998</td></tr>
<tr><th>MACF</th><td align=right>2160</td></tr>
<tr><th>NY</th><td align=right>135815</td></tr>
<tr><th>OBI</th><td align=right>355932</td></tr>
<tr><th>PASA</th><td align=right>16132</td></tr>
<tr><th>PGM</th><td align=right>55084</td></tr>
<tr><th>POM</th><td align=right>773536</td></tr>
<tr><th>RSA</th><td align=right>3236784</td></tr>
<tr><th>SACT</th><td align=right>12436</td></tr>
<tr><th>SBBG</th><td align=right>1016382</td></tr>
<tr><th>SDSU</th><td align=right>130537</td></tr>
<tr><th>SCFS</th><td align=right>6907</td></tr>
<tr><th>SD</th><td align=right>1096885</td></tr>
<tr><th>SEINET</th><td align=right>304572</td></tr>
<tr><th>SFV</th><td align=right>69484</td></tr>
<tr><th>SJSU</th><td align=right>86187</td></tr>
<tr><th>UC</th><td align=right>2325853</td></tr>
<tr><th>UCD</th><td align=right>711095</td></tr>
<tr><th>UCR</th><td align=right>1739119</td></tr>
<tr><th>UCSB</th><td align=right>291799</td></tr>
<tr><th>UCSC</th><td align=right>46617</td></tr>
<tr><th>VVC</th><td align=right>28896</td></tr>
<tr><th>YM</th><td align=right>2936</td></tr>
</table>Total: 18110070 in 891555 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 188</td></tr>
<tr><th>CAS</th><td align=right> 80335</td></tr>
<tr><th>CATA</th><td align=right> 391</td></tr>
<tr><th>CDA</th><td align=right> 6894</td></tr>
<tr><th>CHSC</th><td align=right> 23086</td></tr>
<tr><th>CSUSB</th><td align=right> 298</td></tr>
<tr><th>GMDRC</th><td align=right> 1662</td></tr>
<tr><th>HSC</th><td align=right> 20912</td></tr>
<tr><th>HUH</th><td align=right> 11260</td></tr>
<tr><th>IRVC</th><td align=right> 1044</td></tr>
<tr><th>JEPS</th><td align=right> 31903</td></tr>
<tr><th>JOTR</th><td align=right> 1213</td></tr>
<tr><th>JROH</th><td align=right> 849</td></tr>
<tr><th>LA</th><td align=right> 4187</td></tr>
<tr><th>MACF</th><td align=right> 87</td></tr>
<tr><th>NY</th><td align=right> 4164</td></tr>
<tr><th>OBI</th><td align=right> 9653</td></tr>
<tr><th>PASA</th><td align=right> 347</td></tr>
<tr><th>PGM</th><td align=right> 1603</td></tr>
<tr><th>POM</th><td align=right> 19594</td></tr>
<tr><th>RSA</th><td align=right> 80374</td></tr>
<tr><th>SACT</th><td align=right> 476</td></tr>
<tr><th>SBBG</th><td align=right> 23586</td></tr>
<tr><th>SDSU</th><td align=right> 3557</td></tr>
<tr><th>SCFS</th><td align=right> 225</td></tr>
<tr><th>SD</th><td align=right> 28506</td></tr>
<tr><th>SEINET</th><td align=right> 8057</td></tr>
<tr><th>SFV</th><td align=right> 1894</td></tr>
<tr><th>SJSU</th><td align=right> 2609</td></tr>
<tr><th>UC</th><td align=right> 72234</td></tr>
<tr><th>UCD</th><td align=right> 28191</td></tr>
<tr><th>UCR</th><td align=right> 45976</td></tr>
<tr><th>UCSB</th><td align=right> 9016</td></tr>
<tr><th>UCSC</th><td align=right> 1999</td></tr>
<tr><th>VVC</th><td align=right> 705</td></tr>
<tr><th>YM</th><td align=right> 2936</td></tr>
</table>Total: 530011</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Feb  6 12:21:41 2017</tt></td></tr>
<tr><td>To:</td><td><tt>Wed May  3 05:05:03 2017</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>4961</td></tr>
<tr><th>CAS</th><td align=right>2799037</td></tr>
<tr><th>CATA</th><td align=right>20662</td></tr>
<tr><th>CDA</th><td align=right>224439</td></tr>
<tr><th>CHSC</th><td align=right>544267</td></tr>
<tr><th>CSUSB</th><td align=right>20637</td></tr>
<tr><th>GMDRC</th><td align=right>70756</td></tr>
<tr><th>HSC</th><td align=right>506879</td></tr>
<tr><th>HUH</th><td align=right>428022</td></tr>
<tr><th>IRVC</th><td align=right>56015</td></tr>
<tr><th>JEPS</th><td align=right>947017</td></tr>
<tr><th>JOTR</th><td align=right>57003</td></tr>
<tr><th>JROH</th><td align=right>46145</td></tr>
<tr><th>LA</th><td align=right>171548</td></tr>
<tr><th>MACF</th><td align=right>1643</td></tr>
<tr><th>NY</th><td align=right>135988</td></tr>
<tr><th>OBI</th><td align=right>394392</td></tr>
<tr><th>PASA</th><td align=right>21756</td></tr>
<tr><th>PGM</th><td align=right>69454</td></tr>
<tr><th>POM</th><td align=right>792900</td></tr>
<tr><th>RSA</th><td align=right>3300774</td></tr>
<tr><th>SACT</th><td align=right>10800</td></tr>
<tr><th>SBBG</th><td align=right>995287</td></tr>
<tr><th>SDSU</th><td align=right>160833</td></tr>
<tr><th>SCFS</th><td align=right>5802</td></tr>
<tr><th>SD</th><td align=right>1340391</td></tr>
<tr><th>SEINET</th><td align=right>319635</td></tr>
<tr><th>SFV</th><td align=right>66997</td></tr>
<tr><th>SJSU</th><td align=right>77255</td></tr>
<tr><th>UC</th><td align=right>2321338</td></tr>
<tr><th>UCD</th><td align=right>702101</td></tr>
<tr><th>UCR</th><td align=right>1754365</td></tr>
<tr><th>UCSB</th><td align=right>333477</td></tr>
<tr><th>UCSC</th><td align=right>53661</td></tr>
<tr><th>VVC</th><td align=right>25422</td></tr>
<tr><th>YM</th><td align=right>187</td></tr>
</table>Total: 18781851 in 218166 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 28</td></tr>
<tr><th>CAS</th><td align=right> 13060</td></tr>
<tr><th>CATA</th><td align=right> 81</td></tr>
<tr><th>CDA</th><td align=right> 1194</td></tr>
<tr><th>CHSC</th><td align=right> 2782</td></tr>
<tr><th>CSUSB</th><td align=right> 67</td></tr>
<tr><th>GMDRC</th><td align=right> 461</td></tr>
<tr><th>HSC</th><td align=right> 2435</td></tr>
<tr><th>HUH</th><td align=right> 2814</td></tr>
<tr><th>IRVC</th><td align=right> 207</td></tr>
<tr><th>JEPS</th><td align=right> 4684</td></tr>
<tr><th>JOTR</th><td align=right> 231</td></tr>
<tr><th>JROH</th><td align=right> 108</td></tr>
<tr><th>LA</th><td align=right> 1029</td></tr>
<tr><th>MACF</th><td align=right> 9</td></tr>
<tr><th>NY</th><td align=right> 1760</td></tr>
<tr><th>OBI</th><td align=right> 2114</td></tr>
<tr><th>PASA</th><td align=right> 70</td></tr>
<tr><th>PGM</th><td align=right> 318</td></tr>
<tr><th>POM</th><td align=right> 2796</td></tr>
<tr><th>RSA</th><td align=right> 15368</td></tr>
<tr><th>SACT</th><td align=right> 28</td></tr>
<tr><th>SBBG</th><td align=right> 4172</td></tr>
<tr><th>SCASU</th><td align=right> 799</td></tr>
<tr><th>SCFS</th><td align=right> 4</td></tr>
<tr><th>SD</th><td align=right> 5561</td></tr>
<tr><th>SEINET</th><td align=right> 1655</td></tr>
<tr><th>SFV</th><td align=right> 284</td></tr>
<tr><th>SJSU</th><td align=right> 326</td></tr>
<tr><th>UC</th><td align=right> 11419</td></tr>
<tr><th>UCD</th><td align=right> 3139</td></tr>
<tr><th>UCR</th><td align=right> 8352</td></tr>
<tr><th>UCSB</th><td align=right> 1429</td></tr>
<tr><th>UCSC</th><td align=right> 315</td></tr>
<tr><th>VVC</th><td align=right> 111</td></tr>
<tr><th>YM</th><td align=right> 187</td></tr>
</table>Total: 89397</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri Nov 18 18:49:39 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Feb  6 12:09:16 2017</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>2460</td></tr>
<tr><th>CAS</th><td align=right>1260545</td></tr>
<tr><th>CATA</th><td align=right>29135</td></tr>
<tr><th>CDA</th><td align=right>170558</td></tr>
<tr><th>CHSC</th><td align=right>407274</td></tr>
<tr><th>CSUSB</th><td align=right>12100</td></tr>
<tr><th>DS</th><td align=right>772385</td></tr>
<tr><th>GMDRC</th><td align=right>49426</td></tr>
<tr><th>HSC</th><td align=right>396735</td></tr>
<tr><th>HUH</th><td align=right>306671</td></tr>
<tr><th>IRVC</th><td align=right>38088</td></tr>
<tr><th>JEPS</th><td align=right>706081</td></tr>
<tr><th>JOTR</th><td align=right>34800</td></tr>
<tr><th>JROH</th><td align=right>37441</td></tr>
<tr><th>LA</th><td align=right>125844</td></tr>
<tr><th>MACF</th><td align=right>1344</td></tr>
<tr><th>NY</th><td align=right>107737</td></tr>
<tr><th>OBI</th><td align=right>288495</td></tr>
<tr><th>PASA</th><td align=right>10416</td></tr>
<tr><th>PGM</th><td align=right>45537</td></tr>
<tr><th>POM</th><td align=right>565393</td></tr>
<tr><th>RSA</th><td align=right>2473353</td></tr>
<tr><th>SACT</th><td align=right>12219</td></tr>
<tr><th>SBBG</th><td align=right>735992</td></tr>
<tr><th>SCFS</th><td align=right>6543</td></tr>
<tr><th>SD</th><td align=right>793333</td></tr>
<tr><th>SDSU</th><td align=right>93556</td></tr>
<tr><th>SEINET</th><td align=right>237882</td></tr>
<tr><th>SFV</th><td align=right>48894</td></tr>
<tr><th>SJSU</th><td align=right>57755</td></tr>
<tr><th>UC</th><td align=right>1710446</td></tr>
<tr><th>UCD</th><td align=right>563374</td></tr>
<tr><th>UCR</th><td align=right>1300436</td></tr>
<tr><th>UCSB</th><td align=right>222110</td></tr>
<tr><th>UCSC</th><td align=right>52899</td></tr>
<tr><th>VVC</th><td align=right>18192</td></tr>
<tr><th>YM</th><td align=right>244</td></tr>
</table>Total: 13695693 in 148578 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 17</td></tr>
<tr><th>CAS</th><td align=right> 7243</td></tr>
<tr><th>CATA</th><td align=right> 658</td></tr>
<tr><th>CDA</th><td align=right> 1001</td></tr>
<tr><th>CHSC</th><td align=right> 2567</td></tr>
<tr><th>CSUSB</th><td align=right> 58</td></tr>
<tr><th>DS</th><td align=right> 3747</td></tr>
<tr><th>GMDRC</th><td align=right> 245</td></tr>
<tr><th>HSC</th><td align=right> 2052</td></tr>
<tr><th>HUH</th><td align=right> 1824</td></tr>
<tr><th>IRVC</th><td align=right> 138</td></tr>
<tr><th>JEPS</th><td align=right> 4083</td></tr>
<tr><th>JOTR</th><td align=right> 120</td></tr>
<tr><th>JROH</th><td align=right> 356</td></tr>
<tr><th>LA</th><td align=right> 567</td></tr>
<tr><th>MACF</th><td align=right> 6</td></tr>
<tr><th>NY</th><td align=right> 1034</td></tr>
<tr><th>OBI</th><td align=right> 1564</td></tr>
<tr><th>PASA</th><td align=right> 59</td></tr>
<tr><th>PGM</th><td align=right> 247</td></tr>
<tr><th>POM</th><td align=right> 2359</td></tr>
<tr><th>RSA</th><td align=right> 11399</td></tr>
<tr><th>SACT</th><td align=right> 37</td></tr>
<tr><th>SBBG</th><td align=right> 3494</td></tr>
<tr><th>SCFS</th><td align=right> 19</td></tr>
<tr><th>SD</th><td align=right> 3676</td></tr>
<tr><th>SDSU</th><td align=right> 518</td></tr>
<tr><th>SEINET</th><td align=right> 1183</td></tr>
<tr><th>SFV</th><td align=right> 231</td></tr>
<tr><th>SJSU</th><td align=right> 349</td></tr>
<tr><th>UC</th><td align=right> 8979</td></tr>
<tr><th>UCD</th><td align=right> 2804</td></tr>
<tr><th>UCR</th><td align=right> 5357</td></tr>
<tr><th>UCSB</th><td align=right> 979</td></tr>
<tr><th>UCSC</th><td align=right> 324</td></tr>
<tr><th>VVC</th><td align=right> 68</td></tr>
<tr><th>YM</th><td align=right> 244</td></tr>
</table>Total: 69606</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Thu Oct 27 00:33:30 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Fri Nov 18 18:49:39 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table>
<tr><th>BLMAR</th><td align=right>3898</td></tr>
<tr><th>CAS</th><td align=right>1789594</td></tr>
<tr><th>CATA</th><td align=right>16431</td></tr>
<tr><th>CDA</th><td align=right>189811</td></tr>
<tr><th>CHSC</th><td align=right>503925</td></tr>
<tr><th>CSUSB</th><td align=right>14919</td></tr>
<tr><th>DS</th><td align=right>1075193</td></tr>
<tr><th>GMDRC</th><td align=right>57675</td></tr>
<tr><th>HSC</th><td align=right>516025</td></tr>
<tr><th>HUH</th><td align=right>380036</td></tr>
<tr><th>IRVC</th><td align=right>42608</td></tr>
<tr><th>JEPS</th><td align=right>936753</td></tr>
<tr><th>JOTR</th><td align=right>53340</td></tr>
<tr><th>JROH</th><td align=right>58137</td></tr>
<tr><th>LA</th><td align=right>159902</td></tr>
<tr><th>MACF</th><td align=right>2591</td></tr>
<tr><th>NY</th><td align=right>134882</td></tr>
<tr><th>OBI</th><td align=right>331123</td></tr>
<tr><th>PASA</th><td align=right>18927</td></tr>
<tr><th>PGM</th><td align=right>58681</td></tr>
<tr><th>POM</th><td align=right>924578</td></tr>
<tr><th>RSA</th><td align=right>3805049</td></tr>
<tr><th>SACT</th><td align=right>6994</td></tr>
<tr><th>SBBG</th><td align=right>946020</td></tr>
<tr><th>SCFS</th><td align=right>6290</td></tr>
<tr><th>SD</th><td align=right>929078</td></tr>
<tr><th>SDSU</th><td align=right>125138</td></tr>
<tr><th>SEINET</th><td align=right>315300</td></tr>
<tr><th>SFV</th><td align=right>65275</td></tr>
<tr><th>SJSU</th><td align=right>81256</td></tr>
<tr><th>UC</th><td align=right>2383824</td></tr>
<tr><th>UCD</th><td align=right>637138</td></tr>
<tr><th>UCR</th><td align=right>1764703</td></tr>
<tr><th>UCSB</th><td align=right>312616</td></tr>
<tr><th>UCSC</th><td align=right>43908</td></tr>
<tr><th>VVC</th><td align=right>36645</td></tr>
<tr><th>YM</th><td align=right>2088</td></tr>
</table>Total: 18730390 in 1269648 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 157</td></tr>
<tr><th>CAS</th><td align=right> 58834</td></tr>
<tr><th>CATA</th><td align=right> 856</td></tr>
<tr><th>CDA</th><td align=right> 6083</td></tr>
<tr><th>CHSC</th><td align=right> 17606</td></tr>
<tr><th>CSUSB</th><td align=right> 280</td></tr>
<tr><th>DS</th><td align=right> 33525</td></tr>
<tr><th>GMDRC</th><td align=right> 1961</td></tr>
<tr><th>HSC</th><td align=right> 19338</td></tr>
<tr><th>HUH</th><td align=right> 11142</td></tr>
<tr><th>IRVC</th><td align=right> 1153</td></tr>
<tr><th>JEPS</th><td align=right> 30223</td></tr>
<tr><th>JOTR</th><td align=right> 1253</td></tr>
<tr><th>JROH</th><td align=right> 1373</td></tr>
<tr><th>LA</th><td align=right> 4349</td></tr>
<tr><th>MACF</th><td align=right> 73</td></tr>
<tr><th>NY</th><td align=right> 5084</td></tr>
<tr><th>OBI</th><td align=right> 10368</td></tr>
<tr><th>PASA</th><td align=right> 481</td></tr>
<tr><th>PGM</th><td align=right> 1828</td></tr>
<tr><th>POM</th><td align=right> 22213</td></tr>
<tr><th>RSA</th><td align=right> 91492</td></tr>
<tr><th>SACT</th><td align=right> 261</td></tr>
<tr><th>SBBG</th><td align=right> 27579</td></tr>
<tr><th>SCFS</th><td align=right> 241</td></tr>
<tr><th>SD</th><td align=right> 28537</td></tr>
<tr><th>SDSU</th><td align=right> 3833</td></tr>
<tr><th>SEINET</th><td align=right> 9574</td></tr>
<tr><th>SFV</th><td align=right> 1892</td></tr>
<tr><th>SJSU</th><td align=right> 2833</td></tr>
<tr><th>UC</th><td align=right> 69127</td></tr>
<tr><th>UCD</th><td align=right> 21139</td></tr>
<tr><th>UCR</th><td align=right> 38667</td></tr>
<tr><th>UCSB</th><td align=right> 10011</td></tr>
<tr><th>UCSC</th><td align=right> 1395</td></tr>
<tr><th>VVC</th><td align=right> 682</td></tr>
<tr><th>YM</th><td align=right> 2088</td></tr>
</table>Total: 537531</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Thu Aug 25 13:04:16 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Thu Oct 27 00:33:30 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>2139</td></tr>
<tr><th>CAS</th><td align=right>1339323</td></tr>
<tr><th>CATA</th><td align=right>10305</td></tr>
<tr><th>CDA</th><td align=right>168655</td></tr>
<tr><th>CHSC</th><td align=right>392165</td></tr>
<tr><th>CSUSB</th><td align=right>35432</td></tr>
<tr><th>DS</th><td align=right>898973</td></tr>
<tr><th>GMDRC</th><td align=right>75446</td></tr>
<tr><th>HSC</th><td align=right>314747</td></tr>
<tr><th>HUH</th><td align=right>393169</td></tr>
<tr><th>IRVC</th><td align=right>63943</td></tr>
<tr><th>JEPS</th><td align=right>749974</td></tr>
<tr><th>JOTR</th><td align=right>46466</td></tr>
<tr><th>JROH</th><td align=right>23192</td></tr>
<tr><th>LA</th><td align=right>176266</td></tr>
<tr><th>MACF</th><td align=right>3036</td></tr>
<tr><th>NY</th><td align=right>104083</td></tr>
<tr><th>OBI</th><td align=right>254575</td></tr>
<tr><th>PASA</th><td align=right>28697</td></tr>
<tr><th>PGM</th><td align=right>28646</td></tr>
<tr><th>POM</th><td align=right>1102802</td></tr>
<tr><th>RSA</th><td align=right>5100957</td></tr>
<tr><th>SACT</th><td align=right>11990</td></tr>
<tr><th>SBBG</th><td align=right>758777</td></tr>
<tr><th>SCFS</th><td align=right>5410</td></tr>
<tr><th>SD</th><td align=right>1453517</td></tr>
<tr><th>SDSU</th><td align=right>175557</td></tr>
<tr><th>SEINET</th><td align=right>339120</td></tr>
<tr><th>SFV</th><td align=right>65149</td></tr>
<tr><th>SJSU</th><td align=right>51887</td></tr>
<tr><th>UC</th><td align=right>2040591</td></tr>
<tr><th>UCD</th><td align=right>509950</td></tr>
<tr><th>UCR</th><td align=right>2743947</td></tr>
<tr><th>UCSB</th><td align=right>254223</td></tr>
<tr><th>UCSC</th><td align=right>35907</td></tr>
<tr><th>VVC</th><td align=right>68369</td></tr>
<tr><th>YM</th><td align=right>176</td></tr>
</table>Total: 19827565 in 172427 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 18</td></tr>
<tr><th>CAS</th><td align=right> 8253</td></tr>
<tr><th>CATA</th><td align=right> 48</td></tr>
<tr><th>CDA</th><td align=right> 1283</td></tr>
<tr><th>CHSC</th><td align=right> 1877</td></tr>
<tr><th>CSUSB</th><td align=right> 64</td></tr>
<tr><th>DS</th><td align=right> 3674</td></tr>
<tr><th>GMDRC</th><td align=right> 351</td></tr>
<tr><th>HSC</th><td align=right> 1422</td></tr>
<tr><th>HUH</th><td align=right> 2068</td></tr>
<tr><th>IRVC</th><td align=right> 201</td></tr>
<tr><th>JEPS</th><td align=right> 3945</td></tr>
<tr><th>JOTR</th><td align=right> 195</td></tr>
<tr><th>JROH</th><td align=right> 157</td></tr>
<tr><th>LA</th><td align=right> 664</td></tr>
<tr><th>MACF</th><td align=right> 20</td></tr>
<tr><th>NY</th><td align=right> 813</td></tr>
<tr><th>OBI</th><td align=right> 1630</td></tr>
<tr><th>PASA</th><td align=right> 134</td></tr>
<tr><th>PGM</th><td align=right> 130</td></tr>
<tr><th>POM</th><td align=right> 3105</td></tr>
<tr><th>RSA</th><td align=right> 14534</td></tr>
<tr><th>SACT</th><td align=right> 36</td></tr>
<tr><th>SBBG</th><td align=right> 4995</td></tr>
<tr><th>SCFS</th><td align=right> 11</td></tr>
<tr><th>SD</th><td align=right> 4421</td></tr>
<tr><th>SDSU</th><td align=right> 581</td></tr>
<tr><th>SEINET</th><td align=right> 1441</td></tr>
<tr><th>SFV</th><td align=right> 301</td></tr>
<tr><th>SJSU</th><td align=right> 294</td></tr>
<tr><th>UC</th><td align=right> 8278</td></tr>
<tr><th>UCD</th><td align=right> 2678</td></tr>
<tr><th>UCR</th><td align=right> 8327</td></tr>
<tr><th>UCSB</th><td align=right> 1255</td></tr>
<tr><th>UCSC</th><td align=right> 200</td></tr>
<tr><th>VVC</th><td align=right> 149</td></tr>
<tr><th>YM</th><td align=right> 176</td></tr>
</table>Total: 77729</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Wed May 18 04:08:53 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Thu Aug 25 12:58:56 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>2590</td></tr>
<tr><th>CAS</th><td align=right>1686348</td></tr>
<tr><th>CATA</th><td align=right>30612</td></tr>
<tr><th>CDA</th><td align=right>215825</td></tr>
<tr><th>CHSC</th><td align=right>476655</td></tr>
<tr><th>CSUSB</th><td align=right>18289</td></tr>
<tr><th>DS</th><td align=right>1053719</td></tr>
<tr><th>GMDRC</th><td align=right>68491</td></tr>
<tr><th>HSC</th><td align=right>421353</td></tr>
<tr><th>HUH</th><td align=right>465185</td></tr>
<tr><th>IRVC</th><td align=right>65836</td></tr>
<tr><th>JEPS</th><td align=right>939272</td></tr>
<tr><th>JOTR</th><td align=right>33228</td></tr>
<tr><th>JROH</th><td align=right>29210</td></tr>
<tr><th>LA</th><td align=right>203300</td></tr>
<tr><th>MACF</th><td align=right>2488</td></tr>
<tr><th>NY</th><td align=right>245963</td></tr>
<tr><th>OBI</th><td align=right>424030</td></tr>
<tr><th>PASA</th><td align=right>30619</td></tr>
<tr><th>PGM</th><td align=right>39147</td></tr>
<tr><th>POM</th><td align=right>787890</td></tr>
<tr><th>RSA</th><td align=right>3636707</td></tr>
<tr><th>SACT</th><td align=right>12134</td></tr>
<tr><th>SBBG</th><td align=right>1051824</td></tr>
<tr><th>SCFS</th><td align=right>7057</td></tr>
<tr><th>SD</th><td align=right>1360180</td></tr>
<tr><th>SDSU</th><td align=right>170798</td></tr>
<tr><th>SEINET</th><td align=right>345179</td></tr>
<tr><th>SFV</th><td align=right>67032</td></tr>
<tr><th>SJSU</th><td align=right>88737</td></tr>
<tr><th>UC</th><td align=right>2365271</td></tr>
<tr><th>UCD</th><td align=right>684255</td></tr>
<tr><th>UCR</th><td align=right>1837950</td></tr>
<tr><th>UCSB</th><td align=right>374108</td></tr>
<tr><th>UCSC</th><td align=right>50571</td></tr>
<tr><th>VVC</th><td align=right>33388</td></tr>
<tr><th>YM</th><td align=right>374</td></tr>
</table>Total: 19325627 in 382427 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 27</td></tr>
<tr><th>CAS</th><td align=right> 14881</td></tr>
<tr><th>CATA</th><td align=right> 81</td></tr>
<tr><th>CDA</th><td align=right> 1918</td></tr>
<tr><th>CHSC</th><td align=right> 5096</td></tr>
<tr><th>CSUSB</th><td align=right> 121</td></tr>
<tr><th>DS</th><td align=right> 9089</td></tr>
<tr><th>GMDRC</th><td align=right> 238</td></tr>
<tr><th>HSC</th><td align=right> 4290</td></tr>
<tr><th>HUH</th><td align=right> 4651</td></tr>
<tr><th>IRVC</th><td align=right> 350</td></tr>
<tr><th>JEPS</th><td align=right> 10366</td></tr>
<tr><th>JOTR</th><td align=right> 247</td></tr>
<tr><th>JROH</th><td align=right> 142</td></tr>
<tr><th>LA</th><td align=right> 2269</td></tr>
<tr><th>MACF</th><td align=right> 24</td></tr>
<tr><th>NY</th><td align=right> 4578</td></tr>
<tr><th>OBI</th><td align=right> 3848</td></tr>
<tr><th>PASA</th><td align=right> 470</td></tr>
<tr><th>PGM</th><td align=right> 262</td></tr>
<tr><th>POM</th><td align=right> 4386</td></tr>
<tr><th>RSA</th><td align=right> 29265</td></tr>
<tr><th>SACT</th><td align=right> 65</td></tr>
<tr><th>SBBG</th><td align=right> 6165</td></tr>
<tr><th>SCFS</th><td align=right> 24</td></tr>
<tr><th>SD</th><td align=right> 17023</td></tr>
<tr><th>SDSU</th><td align=right> 1209</td></tr>
<tr><th>SEINET</th><td align=right> 3690</td></tr>
<tr><th>SFV</th><td align=right> 567</td></tr>
<tr><th>SJSU</th><td align=right> 818</td></tr>
<tr><th>UC</th><td align=right> 21024</td></tr>
<tr><th>UCD</th><td align=right> 8133</td></tr>
<tr><th>UCR</th><td align=right> 14664</td></tr>
<tr><th>UCSB</th><td align=right> 6272</td></tr>
<tr><th>UCSC</th><td align=right> 591</td></tr>
<tr><th>VVC</th><td align=right> 1955</td></tr>
<tr><th>YM</th><td align=right> 374</td></tr>
</table>Total: 179173</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sat Mar 12 15:00:28 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Wed May 18 04:08:53 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>2743</td></tr>
<tr><th>CA</th><td align=right>1</td></tr>
<tr><th>CAS</th><td align=right>1671767</td></tr>
<tr><th>CATA</th><td align=right>33394</td></tr>
<tr><th>CDA</th><td align=right>176978</td></tr>
<tr><th>CHSC</th><td align=right>626137</td></tr>
<tr><th>CSUSB</th><td align=right>23111</td></tr>
<tr><th>DS</th><td align=right>1048521</td></tr>
<tr><th>GMDRC</th><td align=right>83463</td></tr>
<tr><th>HSC</th><td align=right>526614</td></tr>
<tr><th>HUH</th><td align=right>493834</td></tr>
<tr><th>IRVC</th><td align=right>56563</td></tr>
<tr><th>JEPS</th><td align=right>1002853</td></tr>
<tr><th>JOTR</th><td align=right>34796</td></tr>
<tr><th>JROH</th><td align=right>68572</td></tr>
<tr><th>LA</th><td align=right>198109</td></tr>
<tr><th>MACF</th><td align=right>2798</td></tr>
<tr><th>NY</th><td align=right>106809</td></tr>
<tr><th>OBI</th><td align=right>412922</td></tr>
<tr><th>PASA</th><td align=right>18548</td></tr>
<tr><th>PGM</th><td align=right>47526</td></tr>
<tr><th>POM</th><td align=right>871868</td></tr>
<tr><th>RSA</th><td align=right>3513272</td></tr>
<tr><th>SACT</th><td align=right>15371</td></tr>
<tr><th>SBBG</th><td align=right>1136060</td></tr>
<tr><th>SCFS</th><td align=right>11388</td></tr>
<tr><th>SD</th><td align=right>1362564</td></tr>
<tr><th>SDSD</th><td align=right>1</td></tr>
<tr><th>SDSU</th><td align=right>196573</td></tr>
<tr><th>SEINET</th><td align=right>296703</td></tr>
<tr><th>SFV</th><td align=right>74248</td></tr>
<tr><th>SJSU</th><td align=right>80557</td></tr>
<tr><th>SSA</th><td align=right>1</td></tr>
<tr><th>UC</th><td align=right>2526597</td></tr>
<tr><th>UCD</th><td align=right>829907</td></tr>
<tr><th>UCR</th><td align=right>1803951</td></tr>
<tr><th>UCSB</th><td align=right>309114</td></tr>
<tr><th>UCSC</th><td align=right>68174</td></tr>
<tr><th>VVC</th><td align=right>44046</td></tr>
<tr><th>YM</th><td align=right>514</td></tr>
</table>Total: 19776979 in 223024 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 38</td></tr>
<tr><th>CAS</th><td align=right> 10252</td></tr>
<tr><th>CATA</th><td align=right> 67</td></tr>
<tr><th>CDA</th><td align=right> 1379</td></tr>
<tr><th>CHSC</th><td align=right> 4528</td></tr>
<tr><th>CSUSB</th><td align=right> 58</td></tr>
<tr><th>DS</th><td align=right> 4924</td></tr>
<tr><th>GMDRC</th><td align=right> 361</td></tr>
<tr><th>HSC</th><td align=right> 3407</td></tr>
<tr><th>HUH</th><td align=right> 2623</td></tr>
<tr><th>IRVC</th><td align=right> 186</td></tr>
<tr><th>JEPS</th><td align=right> 8942</td></tr>
<tr><th>JOTR</th><td align=right> 295</td></tr>
<tr><th>JROH</th><td align=right> 87</td></tr>
<tr><th>LA</th><td align=right> 834</td></tr>
<tr><th>MACF</th><td align=right> 10</td></tr>
<tr><th>NY</th><td align=right> 983</td></tr>
<tr><th>OBI</th><td align=right> 2235</td></tr>
<tr><th>PASA</th><td align=right> 84</td></tr>
<tr><th>PGM</th><td align=right> 325</td></tr>
<tr><th>POM</th><td align=right> 3641</td></tr>
<tr><th>RSA</th><td align=right> 15965</td></tr>
<tr><th>SACT</th><td align=right> 129</td></tr>
<tr><th>SBBG</th><td align=right> 4388</td></tr>
<tr><th>SCFS</th><td align=right> 51</td></tr>
<tr><th>SD</th><td align=right> 5212</td></tr>
<tr><th>SDSU</th><td align=right> 1093</td></tr>
<tr><th>SEINET</th><td align=right> 1756</td></tr>
<tr><th>SFV</th><td align=right> 334</td></tr>
<tr><th>SJSU</th><td align=right> 430</td></tr>
<tr><th>UC</th><td align=right> 15221</td></tr>
<tr><th>UCD</th><td align=right> 5088</td></tr>
<tr><th>UCR</th><td align=right> 8675</td></tr>
<tr><th>UCSB</th><td align=right> 1470</td></tr>
<tr><th>UCSC</th><td align=right> 433</td></tr>
<tr><th>VVC</th><td align=right> 156</td></tr>
<tr><th>YM</th><td align=right> 514</td></tr>
</table>Total: 106174</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sun Mar  6 05:39:31 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Sat Mar 12 15:00:28 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1548</td></tr>
<tr><th>CAS</th><td align=right>1517337</td></tr>
<tr><th>CATA</th><td align=right>63808</td></tr>
<tr><th>CDA</th><td align=right>133902</td></tr>
<tr><th>CHSC</th><td align=right>607963</td></tr>
<tr><th>CSUSB</th><td align=right>22676</td></tr>
<tr><th>DS</th><td align=right>1008799</td></tr>
<tr><th>GMDRC</th><td align=right>65424</td></tr>
<tr><th>HSC</th><td align=right>356969</td></tr>
<tr><th>HUH</th><td align=right>527390</td></tr>
<tr><th>IRVC</th><td align=right>70085</td></tr>
<tr><th>JEPS</th><td align=right>908726</td></tr>
<tr><th>JOTR</th><td align=right>24186</td></tr>
<tr><th>JROH</th><td align=right>124846</td></tr>
<tr><th>LA</th><td align=right>204706</td></tr>
<tr><th>MACF</th><td align=right>2302</td></tr>
<tr><th>NY</th><td align=right>77125</td></tr>
<tr><th>OBI</th><td align=right>357803</td></tr>
<tr><th>PASA</th><td align=right>15403</td></tr>
<tr><th>PGM</th><td align=right>30073</td></tr>
<tr><th>POM</th><td align=right>946437</td></tr>
<tr><th>RSA</th><td align=right>3573842</td></tr>
<tr><th>SACT</th><td align=right>13851</td></tr>
<tr><th>SBBG</th><td align=right>1427725</td></tr>
<tr><th>SCFS</th><td align=right>4300</td></tr>
<tr><th>SD</th><td align=right>1668495</td></tr>
<tr><th>SDSU</th><td align=right>214398</td></tr>
<tr><th>SEINET</th><td align=right>266499</td></tr>
<tr><th>SFV</th><td align=right>76059</td></tr>
<tr><th>SJSU</th><td align=right>56624</td></tr>
<tr><th>UC</th><td align=right>2563921</td></tr>
<tr><th>UCD</th><td align=right>674355</td></tr>
<tr><th>UCR</th><td align=right>1827025</td></tr>
<tr><th>UCSB</th><td align=right>284424</td></tr>
<tr><th>UCSC</th><td align=right>83135</td></tr>
<tr><th>VVC</th><td align=right>28280</td></tr>
<tr><th>YM</th><td align=right>461</td></tr>
</table>Total: 19830902 in 169098 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 37</td></tr>
<tr><th>CAS</th><td align=right> 9406</td></tr>
<tr><th>CATA</th><td align=right> 22</td></tr>
<tr><th>CDA</th><td align=right> 1109</td></tr>
<tr><th>CHSC</th><td align=right> 4734</td></tr>
<tr><th>CSUSB</th><td align=right> 53</td></tr>
<tr><th>DS</th><td align=right> 4982</td></tr>
<tr><th>GMDRC</th><td align=right> 291</td></tr>
<tr><th>HSC</th><td align=right> 3609</td></tr>
<tr><th>HUH</th><td align=right> 2071</td></tr>
<tr><th>IRVC</th><td align=right> 128</td></tr>
<tr><th>JEPS</th><td align=right> 6161</td></tr>
<tr><th>JOTR</th><td align=right> 595</td></tr>
<tr><th>JROH</th><td align=right> 115</td></tr>
<tr><th>LA</th><td align=right> 671</td></tr>
<tr><th>MACF</th><td align=right> 11</td></tr>
<tr><th>NY</th><td align=right> 634</td></tr>
<tr><th>OBI</th><td align=right> 1866</td></tr>
<tr><th>PASA</th><td align=right> 68</td></tr>
<tr><th>PGM</th><td align=right> 210</td></tr>
<tr><th>POM</th><td align=right> 3203</td></tr>
<tr><th>RSA</th><td align=right> 13556</td></tr>
<tr><th>SACT</th><td align=right> 157</td></tr>
<tr><th>SBBG</th><td align=right> 3998</td></tr>
<tr><th>SCFS</th><td align=right> 40</td></tr>
<tr><th>SD</th><td align=right> 4606</td></tr>
<tr><th>SDSU</th><td align=right> 490</td></tr>
<tr><th>SEINET</th><td align=right> 1727</td></tr>
<tr><th>SFV</th><td align=right> 338</td></tr>
<tr><th>SJSU</th><td align=right> 486</td></tr>
<tr><th>UC</th><td align=right> 13618</td></tr>
<tr><th>UCD</th><td align=right> 4762</td></tr>
<tr><th>UCR</th><td align=right> 7404</td></tr>
<tr><th>UCSB</th><td align=right> 1157</td></tr>
<tr><th>UCSC</th><td align=right> 263</td></tr>
<tr><th>VVC</th><td align=right> 127</td></tr>
<tr><th>YM</th><td align=right> 461</td></tr>
</table>Total: 93166</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Tue Mar  1 10:01:52 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Sun Mar  6 05:39:31 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1399</td></tr>
<tr><th>CAS</th><td align=right>1436715</td></tr>
<tr><th>CATA</th><td align=right>119542</td></tr>
<tr><th>CDA</th><td align=right>119828</td></tr>
<tr><th>CHSC</th><td align=right>621820</td></tr>
<tr><th>CSUSB</th><td align=right>18439</td></tr>
<tr><th>DS</th><td align=right>969515</td></tr>
<tr><th>GMDRC</th><td align=right>36621</td></tr>
<tr><th>HSC</th><td align=right>334240</td></tr>
<tr><th>HUH</th><td align=right>552386</td></tr>
<tr><th>IRVC</th><td align=right>84700</td></tr>
<tr><th>JEPS</th><td align=right>797016</td></tr>
<tr><th>JOTR</th><td align=right>22396</td></tr>
<tr><th>JROH</th><td align=right>102278</td></tr>
<tr><th>LA</th><td align=right>223057</td></tr>
<tr><th>MACF</th><td align=right>1960</td></tr>
<tr><th>NY</th><td align=right>81319</td></tr>
<tr><th>OBI</th><td align=right>337440</td></tr>
<tr><th>PASA</th><td align=right>13405</td></tr>
<tr><th>PGM</th><td align=right>34980</td></tr>
<tr><th>POM</th><td align=right>937801</td></tr>
<tr><th>RSA</th><td align=right>3425333</td></tr>
<tr><th>SACT</th><td align=right>11796</td></tr>
<tr><th>SBBG</th><td align=right>2076434</td></tr>
<tr><th>SCFS</th><td align=right>7704</td></tr>
<tr><th>SD</th><td align=right>1709318</td></tr>
<tr><th>SDSU</th><td align=right>226328</td></tr>
<tr><th>SEINET</th><td align=right>247258</td></tr>
<tr><th>SFV</th><td align=right>73588</td></tr>
<tr><th>SJSU</th><td align=right>50828</td></tr>
<tr><th>UC</th><td align=right>2445342</td></tr>
<tr><th>UCD</th><td align=right>672245</td></tr>
<tr><th>UCR</th><td align=right>1626910</td></tr>
<tr><th>UCSB</th><td align=right>313533</td></tr>
<tr><th>UCSC</th><td align=right>82701</td></tr>
<tr><th>VVC</th><td align=right>26321</td></tr>
<tr><th>YM</th><td align=right>409</td></tr>
</table>Total: 19842905 in 157099 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 17</td></tr>
<tr><th>CAS</th><td align=right> 8452</td></tr>
<tr><th>CATA</th><td align=right> 31</td></tr>
<tr><th>CDA</th><td align=right> 1006</td></tr>
<tr><th>CHSC</th><td align=right> 4453</td></tr>
<tr><th>CSUSB</th><td align=right> 47</td></tr>
<tr><th>DS</th><td align=right> 4454</td></tr>
<tr><th>GMDRC</th><td align=right> 281</td></tr>
<tr><th>HSC</th><td align=right> 3223</td></tr>
<tr><th>HUH</th><td align=right> 2037</td></tr>
<tr><th>IRVC</th><td align=right> 168</td></tr>
<tr><th>JEPS</th><td align=right> 5906</td></tr>
<tr><th>JOTR</th><td align=right> 298</td></tr>
<tr><th>JROH</th><td align=right> 86</td></tr>
<tr><th>LA</th><td align=right> 699</td></tr>
<tr><th>MACF</th><td align=right> 8</td></tr>
<tr><th>NY</th><td align=right> 837</td></tr>
<tr><th>OBI</th><td align=right> 1786</td></tr>
<tr><th>PASA</th><td align=right> 49</td></tr>
<tr><th>PGM</th><td align=right> 187</td></tr>
<tr><th>POM</th><td align=right> 2765</td></tr>
<tr><th>RSA</th><td align=right> 12769</td></tr>
<tr><th>SACT</th><td align=right> 112</td></tr>
<tr><th>SBBG</th><td align=right> 3582</td></tr>
<tr><th>SCFS</th><td align=right> 12</td></tr>
<tr><th>SD</th><td align=right> 4731</td></tr>
<tr><th>SDSU</th><td align=right> 567</td></tr>
<tr><th>SEINET</th><td align=right> 1509</td></tr>
<tr><th>SFV</th><td align=right> 279</td></tr>
<tr><th>SJSU</th><td align=right> 404</td></tr>
<tr><th>UC</th><td align=right> 11829</td></tr>
<tr><th>UCD</th><td align=right> 3943</td></tr>
<tr><th>UCR</th><td align=right> 7081</td></tr>
<tr><th>UCSB</th><td align=right> 1109</td></tr>
<tr><th>UCSC</th><td align=right> 264</td></tr>
<tr><th>VVC</th><td align=right> 100</td></tr>
<tr><th>YM</th><td align=right> 409</td></tr>
</table>Total: 85490</td></tr></table>

<H3>For Jan and Feb 2016 CCH was hit with a bot, accounting for nearly all traffic in that time. Reports for those months have been hidden</H3><br>
<!-- For Jan and Feb 2016 CCH was hit with a bot, accounting for nearly all traffic reported in that period. Those months have been hidden -->
<!--
<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Feb 15 01:39:27 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Thu Feb 18 15:20:01 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>832</td></tr>
<tr><th>CAS</th><td align=right>1004288</td></tr>
<tr><th>CATA</th><td align=right>26499</td></tr>
<tr><th>CDA</th><td align=right>84326</td></tr>
<tr><th>CHSC</th><td align=right>399485</td></tr>
<tr><th>CSUSB</th><td align=right>13573</td></tr>
<tr><th>DS</th><td align=right>682909</td></tr>
<tr><th>GMDRC</th><td align=right>16267</td></tr>
<tr><th>HSC</th><td align=right>220712</td></tr>
<tr><th>HUH</th><td align=right>356939</td></tr>
<tr><th>IRVC</th><td align=right>55804</td></tr>
<tr><th>JEPS</th><td align=right>562262</td></tr>
<tr><th>JOTR</th><td align=right>13158</td></tr>
<tr><th>JROH</th><td align=right>96608</td></tr>
<tr><th>LA</th><td align=right>180733</td></tr>
<tr><th>MACF</th><td align=right>1368</td></tr>
<tr><th>NY</th><td align=right>46768</td></tr>
<tr><th>OBI</th><td align=right>220201</td></tr>
<tr><th>PASA</th><td align=right>10018</td></tr>
<tr><th>PGM</th><td align=right>26117</td></tr>
<tr><th>POM</th><td align=right>625309</td></tr>
<tr><th>RSA</th><td align=right>2324877</td></tr>
<tr><th>SACT</th><td align=right>7736</td></tr>
<tr><th>SBBG</th><td align=right>1272010</td></tr>
<tr><th>SCFS</th><td align=right>4842</td></tr>
<tr><th>SD</th><td align=right>1272356</td></tr>
<tr><th>SDSU</th><td align=right>158700</td></tr>
<tr><th>SEINET</th><td align=right>182999</td></tr>
<tr><th>SFV</th><td align=right>58330</td></tr>
<tr><th>SJSU</th><td align=right>37782</td></tr>
<tr><th>UC</th><td align=right>1660780</td></tr>
<tr><th>UCD</th><td align=right>430743</td></tr>
<tr><th>UCR</th><td align=right>1185865</td></tr>
<tr><th>UCSB</th><td align=right>210215</td></tr>
<tr><th>UCSC</th><td align=right>53806</td></tr>
<tr><th>VVC</th><td align=right>16565</td></tr>
<tr><th>YM</th><td align=right>190</td></tr>
</table>Total: 13521972 in 109103 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 18</td></tr>
<tr><th>CAS</th><td align=right> 5927</td></tr>
<tr><th>CATA</th><td align=right> 33</td></tr>
<tr><th>CDA</th><td align=right> 723</td></tr>
<tr><th>CHSC</th><td align=right> 2661</td></tr>
<tr><th>CSUSB</th><td align=right> 36</td></tr>
<tr><th>DS</th><td align=right> 3342</td></tr>
<tr><th>GMDRC</th><td align=right> 123</td></tr>
<tr><th>HSC</th><td align=right> 2341</td></tr>
<tr><th>HUH</th><td align=right> 1375</td></tr>
<tr><th>IRVC</th><td align=right> 147</td></tr>
<tr><th>JEPS</th><td align=right> 3570</td></tr>
<tr><th>JOTR</th><td align=right> 159</td></tr>
<tr><th>JROH</th><td align=right> 105</td></tr>
<tr><th>LA</th><td align=right> 559</td></tr>
<tr><th>MACF</th><td align=right> 21</td></tr>
<tr><th>NY</th><td align=right> 530</td></tr>
<tr><th>OBI</th><td align=right> 1472</td></tr>
<tr><th>PASA</th><td align=right> 53</td></tr>
<tr><th>PGM</th><td align=right> 179</td></tr>
<tr><th>POM</th><td align=right> 2122</td></tr>
<tr><th>RSA</th><td align=right> 9239</td></tr>
<tr><th>SACT</th><td align=right> 84</td></tr>
<tr><th>SBBG</th><td align=right> 3047</td></tr>
<tr><th>SCFS</th><td align=right> 9</td></tr>
<tr><th>SD</th><td align=right> 3636</td></tr>
<tr><th>SDSU</th><td align=right> 444</td></tr>
<tr><th>SEINET</th><td align=right> 1000</td></tr>
<tr><th>SFV</th><td align=right> 253</td></tr>
<tr><th>SJSU</th><td align=right> 278</td></tr>
<tr><th>UC</th><td align=right> 8077</td></tr>
<tr><th>UCD</th><td align=right> 2831</td></tr>
<tr><th>UCR</th><td align=right> 4608</td></tr>
<tr><th>UCSB</th><td align=right> 1068</td></tr>
<tr><th>UCSC</th><td align=right> 167</td></tr>
<tr><th>VVC</th><td align=right> 84</td></tr>
<tr><th>YM</th><td align=right> 190</td></tr>
</table>Total: 60511</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Tue Feb  2 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Sun Feb 14 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1267</td></tr>
<tr><th>CAS</th><td align=right>1441480</td></tr>
<tr><th>CATA</th><td align=right>58049</td></tr>
<tr><th>CDA</th><td align=right>117274</td></tr>
<tr><th>CHSC</th><td align=right>650316</td></tr>
<tr><th>CSUSB</th><td align=right>20494</td></tr>
<tr><th>DS</th><td align=right>1062745</td></tr>
<tr><th>GMDRC</th><td align=right>30365</td></tr>
<tr><th>HSC</th><td align=right>438637</td></tr>
<tr><th>HUH</th><td align=right>526337</td></tr>
<tr><th>IRVC</th><td align=right>70258</td></tr>
<tr><th>JEPS</th><td align=right>876236</td></tr>
<tr><th>JOTR</th><td align=right>25574</td></tr>
<tr><th>JROH</th><td align=right>168960</td></tr>
<tr><th>LA</th><td align=right>219131</td></tr>
<tr><th>MACF</th><td align=right>2171</td></tr>
<tr><th>NY</th><td align=right>92466</td></tr>
<tr><th>OBI</th><td align=right>267151</td></tr>
<tr><th>PASA</th><td align=right>15573</td></tr>
<tr><th>PGM</th><td align=right>34354</td></tr>
<tr><th>POM</th><td align=right>956459</td></tr>
<tr><th>RSA</th><td align=right>3472824</td></tr>
<tr><th>SACT</th><td align=right>13020</td></tr>
<tr><th>SBBG</th><td align=right>1312284</td></tr>
<tr><th>SCFS</th><td align=right>9660</td></tr>
<tr><th>SD</th><td align=right>1825105</td></tr>
<tr><th>SDSU</th><td align=right>256090</td></tr>
<tr><th>SEINET</th><td align=right>283204</td></tr>
<tr><th>SFV</th><td align=right>76458</td></tr>
<tr><th>SJSU</th><td align=right>64850</td></tr>
<tr><th>UC</th><td align=right>2471356</td></tr>
<tr><th>UCD</th><td align=right>688212</td></tr>
<tr><th>UCR</th><td align=right>1783947</td></tr>
<tr><th>UCSB</th><td align=right>269901</td></tr>
<tr><th>UCSC</th><td align=right>137532</td></tr>
<tr><th>VVC</th><td align=right>30382</td></tr>
<tr><th>YM</th><td align=right>557</td></tr>
</table>Total: 19770679 in 229319 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 33</td></tr>
<tr><th>CAS</th><td align=right> 10872</td></tr>
<tr><th>CATA</th><td align=right> 45</td></tr>
<tr><th>CDA</th><td align=right> 1104</td></tr>
<tr><th>CHSC</th><td align=right> 6591</td></tr>
<tr><th>CSUSB</th><td align=right> 53</td></tr>
<tr><th>DS</th><td align=right> 5511</td></tr>
<tr><th>GMDRC</th><td align=right> 342</td></tr>
<tr><th>HSC</th><td align=right> 4581</td></tr>
<tr><th>HUH</th><td align=right> 2545</td></tr>
<tr><th>IRVC</th><td align=right> 186</td></tr>
<tr><th>JEPS</th><td align=right> 7278</td></tr>
<tr><th>JOTR</th><td align=right> 386</td></tr>
<tr><th>JROH</th><td align=right> 91</td></tr>
<tr><th>LA</th><td align=right> 831</td></tr>
<tr><th>MACF</th><td align=right> 32</td></tr>
<tr><th>NY</th><td align=right> 720</td></tr>
<tr><th>OBI</th><td align=right> 1801</td></tr>
<tr><th>PASA</th><td align=right> 75</td></tr>
<tr><th>PGM</th><td align=right> 241</td></tr>
<tr><th>POM</th><td align=right> 3665</td></tr>
<tr><th>RSA</th><td align=right> 15851</td></tr>
<tr><th>SACT</th><td align=right> 235</td></tr>
<tr><th>SBBG</th><td align=right> 4329</td></tr>
<tr><th>SCFS</th><td align=right> 48</td></tr>
<tr><th>SD</th><td align=right> 5419</td></tr>
<tr><th>SDSU</th><td align=right> 601</td></tr>
<tr><th>SEINET</th><td align=right> 1922</td></tr>
<tr><th>SFV</th><td align=right> 409</td></tr>
<tr><th>SJSU</th><td align=right> 568</td></tr>
<tr><th>UC</th><td align=right> 15427</td></tr>
<tr><th>UCD</th><td align=right> 5460</td></tr>
<tr><th>UCR</th><td align=right> 8105</td></tr>
<tr><th>UCSB</th><td align=right> 1371</td></tr>
<tr><th>UCSC</th><td align=right> 369</td></tr>
<tr><th>VVC</th><td align=right> 110</td></tr>
<tr><th>YM</th><td align=right> 557</td></tr>
</table>Total: 107764</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Tue Jan 26 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Feb 1 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1578</td></tr>
<tr><th>CAS</th><td align=right>1354713</td></tr>
<tr><th>CATA</th><td align=right>92791</td></tr>
<tr><th>CDA</th><td align=right>119164</td></tr>
<tr><th>CHSC</th><td align=right>718104</td></tr>
<tr><th>CSUSB</th><td align=right>22513</td></tr>
<tr><th>DS</th><td align=right>998190</td></tr>
<tr><th>GMDRC</th><td align=right>39170</td></tr>
<tr><th>HSC</th><td align=right>458208</td></tr>
<tr><th>HUH</th><td align=right>508381</td></tr>
<tr><th>IRVC</th><td align=right>69657</td></tr>
<tr><th>JEPS</th><td align=right>857864</td></tr>
<tr><th>JOTR</th><td align=right>20806</td></tr>
<tr><th>JROH</th><td align=right>168603</td></tr>
<tr><th>LA</th><td align=right>211135</td></tr>
<tr><th>MACF</th><td align=right>1985</td></tr>
<tr><th>NY</th><td align=right>79410</td></tr>
<tr><th>OBI</th><td align=right>266692</td></tr>
<tr><th>PASA</th><td align=right>14558</td></tr>
<tr><th>PGM</th><td align=right>33293</td></tr>
<tr><th>POM</th><td align=right>939975</td></tr>
<tr><th>RSA</th><td align=right>3504133</td></tr>
<tr><th>SACT</th><td align=right>13228</td></tr>
<tr><th>SBBG</th><td align=right>1302211</td></tr>
<tr><th>SCFS</th><td align=right>9418</td></tr>
<tr><th>SD</th><td align=right>1942299</td></tr>
<tr><th>SDSD</th><td align=right>2</td></tr>
<tr><th>SDSU</th><td align=right>271068</td></tr>
<tr><th>SEINET</th><td align=right>274572</td></tr>
<tr><th>SFV</th><td align=right>78784</td></tr>
<tr><th>SJSU</th><td align=right>60484</td></tr>
<tr><th>UC</th><td align=right>2487562</td></tr>
<tr><th>UCD</th><td align=right>658438</td></tr>
<tr><th>UCR</th><td align=right>1836128</td></tr>
<tr><th>UCSB</th><td align=right>249755</td></tr>
<tr><th>UCSC</th><td align=right>85036</td></tr>
<tr><th>VVC</th><td align=right>30324</td></tr>
<tr><th>YM</th><td align=right>597</td></tr>
</table>Total: 19780829 in 220219 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 49</td></tr>
<tr><th>CAS</th><td align=right> 10372</td></tr>
<tr><th>CATA</th><td align=right> 104</td></tr>
<tr><th>CDA</th><td align=right> 919</td></tr>
<tr><th>CHSC</th><td align=right> 6290</td></tr>
<tr><th>CSUSB</th><td align=right> 94</td></tr>
<tr><th>DS</th><td align=right> 6048</td></tr>
<tr><th>GMDRC</th><td align=right> 251</td></tr>
<tr><th>HSC</th><td align=right> 5415</td></tr>
<tr><th>HUH</th><td align=right> 2767</td></tr>
<tr><th>IRVC</th><td align=right> 157</td></tr>
<tr><th>JEPS</th><td align=right> 6680</td></tr>
<tr><th>JOTR</th><td align=right> 180</td></tr>
<tr><th>JROH</th><td align=right> 148</td></tr>
<tr><th>LA</th><td align=right> 971</td></tr>
<tr><th>MACF</th><td align=right> 40</td></tr>
<tr><th>NY</th><td align=right> 737</td></tr>
<tr><th>OBI</th><td align=right> 1844</td></tr>
<tr><th>PASA</th><td align=right> 82</td></tr>
<tr><th>PGM</th><td align=right> 324</td></tr>
<tr><th>POM</th><td align=right> 3721</td></tr>
<tr><th>RSA</th><td align=right> 15247</td></tr>
<tr><th>SACT</th><td align=right> 85</td></tr>
<tr><th>SBBG</th><td align=right> 4346</td></tr>
<tr><th>SCFS</th><td align=right> 56</td></tr>
<tr><th>SD</th><td align=right> 6315</td></tr>
<tr><th>SDSU</th><td align=right> 850</td></tr>
<tr><th>SEINET</th><td align=right> 1897</td></tr>
<tr><th>SFV</th><td align=right> 484</td></tr>
<tr><th>SJSU</th><td align=right> 570</td></tr>
<tr><th>UC</th><td align=right> 14917</td></tr>
<tr><th>UCD</th><td align=right> 4958</td></tr>
<tr><th>UCR</th><td align=right> 7318</td></tr>
<tr><th>UCSB</th><td align=right> 1696</td></tr>
<tr><th>UCSC</th><td align=right> 414</td></tr>
<tr><th>VVC</th><td align=right> 71</td></tr>
<tr><th>YM</th><td align=right> 597</td></tr>
</table>Total: 107014</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Jan 18 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Jan 25 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1059</td></tr>
<tr><th>CAS</th><td align=right>1522574</td></tr>
<tr><th>CATA</th><td align=right>88671</td></tr>
<tr><th>CDA</th><td align=right>115477</td></tr>
<tr><th>CHSC</th><td align=right>721712</td></tr>
<tr><th>CSUSB</th><td align=right>16769</td></tr>
<tr><th>DS</th><td align=right>1020558</td></tr>
<tr><th>GMDRC</th><td align=right>29495</td></tr>
<tr><th>HSC</th><td align=right>458024</td></tr>
<tr><th>HUH</th><td align=right>507974</td></tr>
<tr><th>IRVC</th><td align=right>60420</td></tr>
<tr><th>JEPS</th><td align=right>871001</td></tr>
<tr><th>JOTR</th><td align=right>18358</td></tr>
<tr><th>JROH</th><td align=right>112659</td></tr>
<tr><th>LA</th><td align=right>209083</td></tr>
<tr><th>MACF</th><td align=right>1683</td></tr>
<tr><th>NY</th><td align=right>84216</td></tr>
<tr><th>OBI</th><td align=right>266709</td></tr>
<tr><th>PASA</th><td align=right>14236</td></tr>
<tr><th>PGM</th><td align=right>27425</td></tr>
<tr><th>POM</th><td align=right>947135</td></tr>
<tr><th>RSA</th><td align=right>3485435</td></tr>
<tr><th>SACT</th><td align=right>12283</td></tr>
<tr><th>SBBG</th><td align=right>1475581</td></tr>
<tr><th>SCFS</th><td align=right>14280</td></tr>
<tr><th>SD</th><td align=right>1757736</td></tr>
<tr><th>SDSU</th><td align=right>254657</td></tr>
<tr><th>SEINET</th><td align=right>256839</td></tr>
<tr><th>SFV</th><td align=right>81649</td></tr>
<tr><th>SJSU</th><td align=right>65760</td></tr>
<tr><th>UC</th><td align=right>2479862</td></tr>
<tr><th>UCD</th><td align=right>684104</td></tr>
<tr><th>UCR</th><td align=right>1690856</td></tr>
<tr><th>UCSB</th><td align=right>271444</td></tr>
<tr><th>UCSC</th><td align=right>79560</td></tr>
<tr><th>VVC</th><td align=right>31633</td></tr>
<tr><th>YM</th><td align=right>712</td></tr>
</table>Total: 19737634 in 262365 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 40</td></tr>
<tr><th>CAS</th><td align=right> 11566</td></tr>
<tr><th>CATA</th><td align=right> 96</td></tr>
<tr><th>CDA</th><td align=right> 1029</td></tr>
<tr><th>CHSC</th><td align=right> 6043</td></tr>
<tr><th>CSUSB</th><td align=right> 103</td></tr>
<tr><th>DS</th><td align=right> 7002</td></tr>
<tr><th>GMDRC</th><td align=right> 296</td></tr>
<tr><th>HSC</th><td align=right> 7918</td></tr>
<tr><th>HUH</th><td align=right> 3106</td></tr>
<tr><th>IRVC</th><td align=right> 243</td></tr>
<tr><th>JEPS</th><td align=right> 7754</td></tr>
<tr><th>JOTR</th><td align=right> 137</td></tr>
<tr><th>JROH</th><td align=right> 195</td></tr>
<tr><th>LA</th><td align=right> 1452</td></tr>
<tr><th>MACF</th><td align=right> 35</td></tr>
<tr><th>NY</th><td align=right> 734</td></tr>
<tr><th>OBI</th><td align=right> 2159</td></tr>
<tr><th>PASA</th><td align=right> 105</td></tr>
<tr><th>PGM</th><td align=right> 330</td></tr>
<tr><th>POM</th><td align=right> 4856</td></tr>
<tr><th>RSA</th><td align=right> 18454</td></tr>
<tr><th>SACT</th><td align=right> 101</td></tr>
<tr><th>SBBG</th><td align=right> 5489</td></tr>
<tr><th>SCFS</th><td align=right> 97</td></tr>
<tr><th>SD</th><td align=right> 9122</td></tr>
<tr><th>SDSU</th><td align=right> 1276</td></tr>
<tr><th>SEINET</th><td align=right> 2414</td></tr>
<tr><th>SFV</th><td align=right> 612</td></tr>
<tr><th>SJSU</th><td align=right> 705</td></tr>
<tr><th>UC</th><td align=right> 18907</td></tr>
<tr><th>UCD</th><td align=right> 5892</td></tr>
<tr><th>UCR</th><td align=right> 8291</td></tr>
<tr><th>UCSB</th><td align=right> 2077</td></tr>
<tr><th>UCSC</th><td align=right> 499</td></tr>
<tr><th>VVC</th><td align=right> 111</td></tr>
<tr><th>YM</th><td align=right> 712</td></tr>
</table>Total: 129958</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sun Jan 10 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Sun Jan 17 2015</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>933</td></tr>
<tr><th>CAS</th><td align=right>1414470</td></tr>
<tr><th>CATA</th><td align=right>54791</td></tr>
<tr><th>CDA</th><td align=right>139718</td></tr>
<tr><th>CHSC</th><td align=right>841482</td></tr>
<tr><th>CSUSB</th><td align=right>18530</td></tr>
<tr><th>DS</th><td align=right>952925</td></tr>
<tr><th>GMDRC</th><td align=right>51516</td></tr>
<tr><th>HSC</th><td align=right>408495</td></tr>
<tr><th>HUH</th><td align=right>479842</td></tr>
<tr><th>IRVC</th><td align=right>69363</td></tr>
<tr><th>JEPS</th><td align=right>894654</td></tr>
<tr><th>JOTR</th><td align=right>38087</td></tr>
<tr><th>JROH</th><td align=right>91374</td></tr>
<tr><th>LA</th><td align=right>203116</td></tr>
<tr><th>MACF</th><td align=right>1815</td></tr>
<tr><th>NY</th><td align=right>83078</td></tr>
<tr><th>OBI</th><td align=right>286158</td></tr>
<tr><th>PASA</th><td align=right>16915</td></tr>
<tr><th>PGM</th><td align=right>32261</td></tr>
<tr><th>POM</th><td align=right>926938</td></tr>
<tr><th>RSA</th><td align=right>3613891</td></tr>
<tr><th>SACT</th><td align=right>13624</td></tr>
<tr><th>SBBG</th><td align=right>1525480</td></tr>
<tr><th>SCFS</th><td align=right>11597</td></tr>
<tr><th>SD</th><td align=right>1567205</td></tr>
<tr><th>SDSU</th><td align=right>209989</td></tr>
<tr><th>SEINET</th><td align=right>272978</td></tr>
<tr><th>SFV</th><td align=right>76912</td></tr>
<tr><th>SJSU</th><td align=right>56283</td></tr>
<tr><th>UC</th><td align=right>2429559</td></tr>
<tr><th>UCD</th><td align=right>693376</td></tr>
<tr><th>UCR</th><td align=right>1923015</td></tr>
<tr><th>UCSB</th><td align=right>267481</td></tr>
<tr><th>UCSC</th><td align=right>64223</td></tr>
<tr><th>VVC</th><td align=right>39214</td></tr>
<tr><th>YM</th><td align=right>697</td></tr>
</table>Total: 19771985 in 228019 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 34</td></tr>
<tr><th>CAS</th><td align=right> 13070</td></tr>
<tr><th>CATA</th><td align=right> 93</td></tr>
<tr><th>CDA</th><td align=right> 1496</td></tr>
<tr><th>CHSC</th><td align=right> 5815</td></tr>
<tr><th>CSUSB</th><td align=right> 80</td></tr>
<tr><th>DS</th><td align=right> 7329</td></tr>
<tr><th>GMDRC</th><td align=right> 346</td></tr>
<tr><th>HSC</th><td align=right> 5543</td></tr>
<tr><th>HUH</th><td align=right> 2759</td></tr>
<tr><th>IRVC</th><td align=right> 292</td></tr>
<tr><th>JEPS</th><td align=right> 7830</td></tr>
<tr><th>JOTR</th><td align=right> 315</td></tr>
<tr><th>JROH</th><td align=right> 225</td></tr>
<tr><th>LA</th><td align=right> 1141</td></tr>
<tr><th>MACF</th><td align=right> 19</td></tr>
<tr><th>NY</th><td align=right> 786</td></tr>
<tr><th>OBI</th><td align=right> 2449</td></tr>
<tr><th>PASA</th><td align=right> 117</td></tr>
<tr><th>PGM</th><td align=right> 386</td></tr>
<tr><th>POM</th><td align=right> 5248</td></tr>
<tr><th>RSA</th><td align=right> 20956</td></tr>
<tr><th>SACT</th><td align=right> 142</td></tr>
<tr><th>SBBG</th><td align=right> 6198</td></tr>
<tr><th>SCFS</th><td align=right> 76</td></tr>
<tr><th>SD</th><td align=right> 7913</td></tr>
<tr><th>SDSU</th><td align=right> 994</td></tr>
<tr><th>SEINET</th><td align=right> 2409</td></tr>
<tr><th>SFV</th><td align=right> 483</td></tr>
<tr><th>SJSU</th><td align=right> 695</td></tr>
<tr><th>UC</th><td align=right> 17117</td></tr>
<tr><th>UCD</th><td align=right> 6148</td></tr>
<tr><th>UCR</th><td align=right> 9554</td></tr>
<tr><th>UCSB</th><td align=right> 1961</td></tr>
<tr><th>UCSC</th><td align=right> 325</td></tr>
<tr><th>VVC</th><td align=right> 164</td></tr>
<tr><th>YM</th><td align=right> 697</td></tr>
</table>Total: 131205</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Tue Jan 5 2016</tt></td></tr>
<tr><td>To:</td><td><tt>Fri Jan 9 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1103</td></tr>
<tr><th>CAS</th><td align=right>1385252</td></tr>
<tr><th>CATA</th><td align=right>54879</td></tr>
<tr><th>CDA</th><td align=right>128595</td></tr>
<tr><th>CHSC</th><td align=right>858557</td></tr>
<tr><th>CSUSB</th><td align=right>19263</td></tr>
<tr><th>DS</th><td align=right>1005250</td></tr>
<tr><th>GMDRC</th><td align=right>73671</td></tr>
<tr><th>HSC</th><td align=right>360871</td></tr>
<tr><th>HUH</th><td align=right>464406</td></tr>
<tr><th>IRVC</th><td align=right>75821</td></tr>
<tr><th>JEPS</th><td align=right>829830</td></tr>
<tr><th>JOTR</th><td align=right>36778</td></tr>
<tr><th>JROH</th><td align=right>76500</td></tr>
<tr><th>LA</th><td align=right>198798</td></tr>
<tr><th>MACF</th><td align=right>2323</td></tr>
<tr><th>NY</th><td align=right>94304</td></tr>
<tr><th>OBI</th><td align=right>281211</td></tr>
<tr><th>PASA</th><td align=right>17998</td></tr>
<tr><th>PGM</th><td align=right>33953</td></tr>
<tr><th>POM</th><td align=right>999575</td></tr>
<tr><th>RSA</th><td align=right>3920800</td></tr>
<tr><th>SACT</th><td align=right>10554</td></tr>
<tr><th>SBBG</th><td align=right>1333839</td></tr>
<tr><th>SCFS</th><td align=right>7243</td></tr>
<tr><th>SD</th><td align=right>1520982</td></tr>
<tr><th>SDSU</th><td align=right>213998</td></tr>
<tr><th>SEINET</th><td align=right>282598</td></tr>
<tr><th>SFV</th><td align=right>71412</td></tr>
<tr><th>SJSU</th><td align=right>57046</td></tr>
<tr><th>UC</th><td align=right>2318141</td></tr>
<tr><th>UCD</th><td align=right>645063</td></tr>
<tr><th>UCR</th><td align=right>2094742</td></tr>
<tr><th>UCSB</th><td align=right>268295</td></tr>
<tr><th>UCSC</th><td align=right>52582</td></tr>
<tr><th>VVC</th><td align=right>47138</td></tr>
<tr><th>YM</th><td align=right>509</td></tr>
</table>Total: 19843880 in 156125 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 31</td></tr>
<tr><th>CAS</th><td align=right> 8728</td></tr>
<tr><th>CATA</th><td align=right> 111</td></tr>
<tr><th>CDA</th><td align=right> 1100</td></tr>
<tr><th>CHSC</th><td align=right> 3757</td></tr>
<tr><th>CSUSB</th><td align=right> 37</td></tr>
<tr><th>DS</th><td align=right> 4644</td></tr>
<tr><th>GMDRC</th><td align=right> 208</td></tr>
<tr><th>HSC</th><td align=right> 3998</td></tr>
<tr><th>HUH</th><td align=right> 1650</td></tr>
<tr><th>IRVC</th><td align=right> 155</td></tr>
<tr><th>JEPS</th><td align=right> 4923</td></tr>
<tr><th>JOTR</th><td align=right> 136</td></tr>
<tr><th>JROH</th><td align=right> 210</td></tr>
<tr><th>LA</th><td align=right> 619</td></tr>
<tr><th>MACF</th><td align=right> 8</td></tr>
<tr><th>NY</th><td align=right> 564</td></tr>
<tr><th>OBI</th><td align=right> 1527</td></tr>
<tr><th>PASA</th><td align=right> 92</td></tr>
<tr><th>PGM</th><td align=right> 349</td></tr>
<tr><th>POM</th><td align=right> 3384</td></tr>
<tr><th>RSA</th><td align=right> 12592</td></tr>
<tr><th>SACT</th><td align=right> 29</td></tr>
<tr><th>SBBG</th><td align=right> 3238</td></tr>
<tr><th>SCFS</th><td align=right> 42</td></tr>
<tr><th>SD</th><td align=right> 3913</td></tr>
<tr><th>SDSU</th><td align=right> 577</td></tr>
<tr><th>SEINET</th><td align=right> 1480</td></tr>
<tr><th>SFV</th><td align=right> 164</td></tr>
<tr><th>SJSU</th><td align=right> 472</td></tr>
<tr><th>UC</th><td align=right> 11068</td></tr>
<tr><th>UCD</th><td align=right> 4242</td></tr>
<tr><th>UCR</th><td align=right> 5479</td></tr>
<tr><th>UCSB</th><td align=right> 1359</td></tr>
<tr><th>UCSC</th><td align=right> 280</td></tr>
<tr><th>VVC</th><td align=right> 95</td></tr>
<tr><th>YM</th><td align=right> 509</td></tr>
</table>Total: 81770</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri Dec 25 2015</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Jan 4 2016</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1560</td></tr>
<tr><th>CAS</th><td align=right>1519497</td></tr>
<tr><th>CATA</th><td align=right>30213</td></tr>
<tr><th>CDA</th><td align=right>151736</td></tr>
<tr><th>CHSC</th><td align=right>863854</td></tr>
<tr><th>CSUSB</th><td align=right>19983</td></tr>
<tr><th>DS</th><td align=right>978005</td></tr>
<tr><th>GMDRC</th><td align=right>73192</td></tr>
<tr><th>HSC</th><td align=right>405607</td></tr>
<tr><th>HUH</th><td align=right>459139</td></tr>
<tr><th>IRVC</th><td align=right>70577</td></tr>
<tr><th>JEPS</th><td align=right>950177</td></tr>
<tr><th>JOTR</th><td align=right>24942</td></tr>
<tr><th>JROH</th><td align=right>95415</td></tr>
<tr><th>LA</th><td align=right>192038</td></tr>
<tr><th>MACF</th><td align=right>1676</td></tr>
<tr><th>NY</th><td align=right>85298</td></tr>
<tr><th>OBI</th><td align=right>281972</td></tr>
<tr><th>PASA</th><td align=right>15285</td></tr>
<tr><th>PGM</th><td align=right>37066</td></tr>
<tr><th>POM</th><td align=right>922197</td></tr>
<tr><th>RSA</th><td align=right>3612661</td></tr>
<tr><th>SACT</th><td align=right>17879</td></tr>
<tr><th>SBBG</th><td align=right>1231022</td></tr>
<tr><th>SCFS</th><td align=right>4288</td></tr>
<tr><th>SD</th><td align=right>1497896</td></tr>
<tr><th>SDSU</th><td align=right>187784</td></tr>
<tr><th>SEINET</th><td align=right>284414</td></tr>
<tr><th>SFV</th><td align=right>73683</td></tr>
<tr><th>SJSU</th><td align=right>59551</td></tr>
<tr><th>UC</th><td align=right>2422429</td></tr>
<tr><th>UCD</th><td align=right>781565</td></tr>
<tr><th>UCR</th><td align=right>1944420</td></tr>
<tr><th>UCSB</th><td align=right>279275</td></tr>
<tr><th>UCSC</th><td align=right>55976</td></tr>
<tr><th>VVC</th><td align=right>40097</td></tr>
<tr><th>YM</th><td align=right>762</td></tr>
</table>Total: 19673131 in 326874 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 64</td></tr>
<tr><th>CAS</th><td align=right> 18944</td></tr>
<tr><th>CATA</th><td align=right> 154</td></tr>
<tr><th>CDA</th><td align=right> 2461</td></tr>
<tr><th>CHSC</th><td align=right> 7837</td></tr>
<tr><th>CSUSB</th><td align=right> 130</td></tr>
<tr><th>DS</th><td align=right> 9881</td></tr>
<tr><th>GMDRC</th><td align=right> 566</td></tr>
<tr><th>HSC</th><td align=right> 7313</td></tr>
<tr><th>HUH</th><td align=right> 3480</td></tr>
<tr><th>IRVC</th><td align=right> 292</td></tr>
<tr><th>JEPS</th><td align=right> 11693</td></tr>
<tr><th>JOTR</th><td align=right> 280</td></tr>
<tr><th>JROH</th><td align=right> 468</td></tr>
<tr><th>LA</th><td align=right> 1337</td></tr>
<tr><th>MACF</th><td align=right> 11</td></tr>
<tr><th>NY</th><td align=right> 1249</td></tr>
<tr><th>OBI</th><td align=right> 3370</td></tr>
<tr><th>PASA</th><td align=right> 191</td></tr>
<tr><th>PGM</th><td align=right> 657</td></tr>
<tr><th>POM</th><td align=right> 6926</td></tr>
<tr><th>RSA</th><td align=right> 26500</td></tr>
<tr><th>SACT</th><td align=right> 123</td></tr>
<tr><th>SBBG</th><td align=right> 8000</td></tr>
<tr><th>SCFS</th><td align=right> 83</td></tr>
<tr><th>SD</th><td align=right> 9320</td></tr>
<tr><th>SDSU</th><td align=right> 1049</td></tr>
<tr><th>SEINET</th><td align=right> 3184</td></tr>
<tr><th>SFV</th><td align=right> 489</td></tr>
<tr><th>SJSU</th><td align=right> 876</td></tr>
<tr><th>UC</th><td align=right> 24138</td></tr>
<tr><th>UCD</th><td align=right> 8924</td></tr>
<tr><th>UCR</th><td align=right> 12410</td></tr>
<tr><th>UCSB</th><td align=right> 2515</td></tr>
<tr><th>UCSC</th><td align=right> 495</td></tr>
<tr><th>VVC</th><td align=right> 142</td></tr>
<tr><th>YM</th><td align=right> 762</td></tr>
</table>Total: 176314</td></tr></table>
-->


<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sun Dec 13 2015</tt></td></tr>
<tr><td>To:</td><td><tt>Thu Dec 24 2015</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1506</td></tr>
<tr><th>CAS</th><td align=right>1643083</td></tr>
<tr><th>CATA</th><td align=right>46259</td></tr>
<tr><th>CDA</th><td align=right>163307</td></tr>
<tr><th>CHSC</th><td align=right>593224</td></tr>
<tr><th>CSUSB</th><td align=right>18587</td></tr>
<tr><th>DS</th><td align=right>983786</td></tr>
<tr><th>GMDRC</th><td align=right>66062</td></tr>
<tr><th>HSC</th><td align=right>422613</td></tr>
<tr><th>HUH</th><td align=right>454421</td></tr>
<tr><th>IRVC</th><td align=right>81261</td></tr>
<tr><th>JEPS</th><td align=right>928999</td></tr>
<tr><th>JOTR</th><td align=right>21726</td></tr>
<tr><th>JROH</th><td align=right>81381</td></tr>
<tr><th>LA</th><td align=right>182333</td></tr>
<tr><th>MACF</th><td align=right>1640</td></tr>
<tr><th>NY</th><td align=right>87228</td></tr>
<tr><th>OBI</th><td align=right>306713</td></tr>
<tr><th>PASA</th><td align=right>15054</td></tr>
<tr><th>PGM</th><td align=right>37007</td></tr>
<tr><th>POM</th><td align=right>924637</td></tr>
<tr><th>RSA</th><td align=right>3594985</td></tr>
<tr><th>SACT</th><td align=right>16691</td></tr>
<tr><th>SBBG</th><td align=right>1411089</td></tr>
<tr><th>SCFS</th><td align=right>8249</td></tr>
<tr><th>SD</th><td align=right>1404093</td></tr>
<tr><th>SDSU</th><td align=right>168825</td></tr>
<tr><th>SEINET</th><td align=right>287468</td></tr>
<tr><th>SFV</th><td align=right>70012</td></tr>
<tr><th>SJSU</th><td align=right>64148</td></tr>
<tr><th>UC</th><td align=right>2466726</td></tr>
<tr><th>UCD</th><td align=right>777277</td></tr>
<tr><th>UCR</th><td align=right>1955720</td></tr>
<tr><th>UCSB</th><td align=right>262975</td></tr>
<tr><th>UCSC</th><td align=right>54465</td></tr>
<tr><th>VVC</th><td align=right>38666</td></tr>
<tr><th>YM</th><td align=right>645</td></tr>
</table>Total: 19642861 in 357143 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 30</td></tr>
<tr><th>CAS</th><td align=right> 18340</td></tr>
<tr><th>CATA</th><td align=right> 79</td></tr>
<tr><th>CDA</th><td align=right> 2564</td></tr>
<tr><th>CHSC</th><td align=right> 6180</td></tr>
<tr><th>CSUSB</th><td align=right> 128</td></tr>
<tr><th>DS</th><td align=right> 9026</td></tr>
<tr><th>GMDRC</th><td align=right> 830</td></tr>
<tr><th>HSC</th><td align=right> 5055</td></tr>
<tr><th>HUH</th><td align=right> 3692</td></tr>
<tr><th>IRVC</th><td align=right> 288</td></tr>
<tr><th>JEPS</th><td align=right> 11412</td></tr>
<tr><th>JOTR</th><td align=right> 343</td></tr>
<tr><th>JROH</th><td align=right> 119</td></tr>
<tr><th>LA</th><td align=right> 1270</td></tr>
<tr><th>MACF</th><td align=right> 15</td></tr>
<tr><th>NY</th><td align=right> 993</td></tr>
<tr><th>OBI</th><td align=right> 2906</td></tr>
<tr><th>PASA</th><td align=right> 140</td></tr>
<tr><th>PGM</th><td align=right> 432</td></tr>
<tr><th>POM</th><td align=right> 6495</td></tr>
<tr><th>RSA</th><td align=right> 28815</td></tr>
<tr><th>SACT</th><td align=right> 177</td></tr>
<tr><th>SBBG</th><td align=right> 14280</td></tr>
<tr><th>SCFS</th><td align=right> 69</td></tr>
<tr><th>SD</th><td align=right> 9054</td></tr>
<tr><th>SDSU</th><td align=right> 969</td></tr>
<tr><th>SEINET</th><td align=right> 3014</td></tr>
<tr><th>SFV</th><td align=right> 629</td></tr>
<tr><th>SJSU</th><td align=right> 753</td></tr>
<tr><th>UC</th><td align=right> 24963</td></tr>
<tr><th>UCD</th><td align=right> 8966</td></tr>
<tr><th>UCR</th><td align=right> 16052</td></tr>
<tr><th>UCSB</th><td align=right> 2274</td></tr>
<tr><th>UCSC</th><td align=right> 441</td></tr>
<tr><th>VVC</th><td align=right> 191</td></tr>
<tr><th>YM</th><td align=right> 645</td></tr>
</table>Total: 181629</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sun Nov 15 2015</tt></td></tr>
<tr><td>To:</td><td><tt>Sat Dec 12 2015</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>2275</td></tr>
<tr><th>CAS</th><td align=right>1822225</td></tr>
<tr><th>CATA</th><td align=right>25023</td></tr>
<tr><th>CDA</th><td align=right>165903</td></tr>
<tr><th>CHSC</th><td align=right>678187</td></tr>
<tr><th>CSUSB</th><td align=right>14925</td></tr>
<tr><th>DS</th><td align=right>1071423</td></tr>
<tr><th>GMDRC</th><td align=right>61184</td></tr>
<tr><th>HSC</th><td align=right>509359</td></tr>
<tr><th>HUH</th><td align=right>489199</td></tr>
<tr><th>IRVC</th><td align=right>56419</td></tr>
<tr><th>JEPS</th><td align=right>1075808</td></tr>
<tr><th>JOTR</th><td align=right>29915</td></tr>
<tr><th>JROH</th><td align=right>70872</td></tr>
<tr><th>LA</th><td align=right>145844</td></tr>
<tr><th>MACF</th><td align=right>1613</td></tr>
<tr><th>NY</th><td align=right>117366</td></tr>
<tr><th>OBI</th><td align=right>354527</td></tr>
<tr><th>PASA</th><td align=right>13037</td></tr>
<tr><th>PGM</th><td align=right>59791</td></tr>
<tr><th>POM</th><td align=right>872864</td></tr>
<tr><th>RSA</th><td align=right>3282729</td></tr>
<tr><th>SACT</th><td align=right>18166</td></tr>
<tr><th>SBBG</th><td align=right>1163165</td></tr>
<tr><th>SCFS</th><td align=right>6112</td></tr>
<tr><th>SD</th><td align=right>1089739</td></tr>
<tr><th>SDSU</th><td align=right>136733</td></tr>
<tr><th>SEINET</th><td align=right>296672</td></tr>
<tr><th>SFV</th><td align=right>66315</td></tr>
<tr><th>SJSU</th><td align=right>81188</td></tr>
<tr><th>UC</th><td align=right>2680201</td></tr>
<tr><th>UCD</th><td align=right>945618</td></tr>
<tr><th>UCR</th><td align=right>1740338</td></tr>
<tr><th>UCSB</th><td align=right>240712</td></tr>
<tr><th>UCSC</th><td align=right>107324</td></tr>
<tr><th>VVC</th><td align=right>35878</td></tr>
<tr><th>YM</th><td align=right>905</td></tr>
</table>Total: 19529554 in 470449 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 52</td></tr>
<tr><th>CAS</th><td align=right> 23183</td></tr>
<tr><th>CATA</th><td align=right> 85</td></tr>
<tr><th>CDA</th><td align=right> 3586</td></tr>
<tr><th>CHSC</th><td align=right> 10756</td></tr>
<tr><th>CSUSB</th><td align=right> 78</td></tr>
<tr><th>DS</th><td align=right> 13335</td></tr>
<tr><th>GMDRC</th><td align=right> 700</td></tr>
<tr><th>HSC</th><td align=right> 8524</td></tr>
<tr><th>HUH</th><td align=right> 5314</td></tr>
<tr><th>IRVC</th><td align=right> 365</td></tr>
<tr><th>JEPS</th><td align=right> 16675</td></tr>
<tr><th>JOTR</th><td align=right> 351</td></tr>
<tr><th>JROH</th><td align=right> 200</td></tr>
<tr><th>LA</th><td align=right> 1358</td></tr>
<tr><th>MACF</th><td align=right> 15</td></tr>
<tr><th>NY</th><td align=right> 1934</td></tr>
<tr><th>OBI</th><td align=right> 4342</td></tr>
<tr><th>PASA</th><td align=right> 131</td></tr>
<tr><th>PGM</th><td align=right> 1243</td></tr>
<tr><th>POM</th><td align=right> 9670</td></tr>
<tr><th>RSA</th><td align=right> 34666</td></tr>
<tr><th>SACT</th><td align=right> 198</td></tr>
<tr><th>SBBG</th><td align=right> 14021</td></tr>
<tr><th>SCFS</th><td align=right> 49</td></tr>
<tr><th>SD</th><td align=right> 8083</td></tr>
<tr><th>SDSU</th><td align=right> 1226</td></tr>
<tr><th>SEINET</th><td align=right> 3974</td></tr>
<tr><th>SFV</th><td align=right> 684</td></tr>
<tr><th>SJSU</th><td align=right> 1543</td></tr>
<tr><th>UC</th><td align=right> 36327</td></tr>
<tr><th>UCD</th><td align=right> 13176</td></tr>
<tr><th>UCR</th><td align=right> 16417</td></tr>
<tr><th>UCSB</th><td align=right> 2825</td></tr>
<tr><th>UCSC</th><td align=right> 1384</td></tr>
<tr><th>VVC</th><td align=right> 266</td></tr>
<tr><th>YM</th><td align=right> 905</td></tr>
</table>Total: 237641</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Tue Oct  6 09:02:22 2015</tt></td></tr>
<tr><td>To:</td><td><tt>Sat Nov 14 2015</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>4959</td></tr>
<tr><th>CAS</th><td align=right>1835672</td></tr>
<tr><th>CATA</th><td align=right>38312</td></tr>
<tr><th>CDA</th><td align=right>149503</td></tr>
<tr><th>CHSC</th><td align=right>626776</td></tr>
<tr><th>CSUSB</th><td align=right>17933</td></tr>
<tr><th>DS</th><td align=right>1169071</td></tr>
<tr><th>GMDRC</th><td align=right>80963</td></tr>
<tr><th>HSC</th><td align=right>657667</td></tr>
<tr><th>HUH</th><td align=right>543123</td></tr>
<tr><th>IRVC</th><td align=right>49836</td></tr>
<tr><th>JEPS</th><td align=right>972576</td></tr>
<tr><th>JOTR</th><td align=right>47211</td></tr>
<tr><th>JROH</th><td align=right>93345</td></tr>
<tr><th>LA</th><td align=right>160721</td></tr>
<tr><th>MACF</th><td align=right>1663</td></tr>
<tr><th>NY</th><td align=right>102756</td></tr>
<tr><th>OBI</th><td align=right>389946</td></tr>
<tr><th>PASA</th><td align=right>14522</td></tr>
<tr><th>PGM</th><td align=right>84418</td></tr>
<tr><th>POM</th><td align=right>922681</td></tr>
<tr><th>RSA</th><td align=right>3421589</td></tr>
<tr><th>SACT</th><td align=right>17442</td></tr>
<tr><th>SBBG</th><td align=right>1241046</td></tr>
<tr><th>SCFS</th><td align=right>6737</td></tr>
<tr><th>SD</th><td align=right>1050967</td></tr>
<tr><th>SDSU</th><td align=right>128239</td></tr>
<tr><th>SEINET</th><td align=right>289103</td></tr>
<tr><th>SFV</th><td align=right>67978</td></tr>
<tr><th>SJSU</th><td align=right>83705</td></tr>
<tr><th>UC</th><td align=right>2588508</td></tr>
<tr><th>UCD</th><td align=right>780686</td></tr>
<tr><th>UCR</th><td align=right>1710002</td></tr>
<tr><th>UCSB</th><td align=right>284189</td></tr>
<tr><th>UCSC</th><td align=right>95746</td></tr>
<tr><th>VVC</th><td align=right>27190</td></tr>
<tr><th>YM</th><td align=right>290</td></tr>
</table>Total: 19757071 in 242932 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 33</td></tr>
<tr><th>CAS</th><td align=right> 9821</td></tr>
<tr><th>CATA</th><td align=right> 65</td></tr>
<tr><th>CDA</th><td align=right> 1006</td></tr>
<tr><th>CHSC</th><td align=right> 2825</td></tr>
<tr><th>CSUSB</th><td align=right> 78</td></tr>
<tr><th>DS</th><td align=right> 6366</td></tr>
<tr><th>GMDRC</th><td align=right> 252</td></tr>
<tr><th>HSC</th><td align=right> 3044</td></tr>
<tr><th>HUH</th><td align=right> 2672</td></tr>
<tr><th>IRVC</th><td align=right> 217</td></tr>
<tr><th>JEPS</th><td align=right> 5432</td></tr>
<tr><th>JOTR</th><td align=right> 190</td></tr>
<tr><th>JROH</th><td align=right> 89</td></tr>
<tr><th>LA</th><td align=right> 518</td></tr>
<tr><th>MACF</th><td align=right> 9</td></tr>
<tr><th>NY</th><td align=right> 611</td></tr>
<tr><th>OBI</th><td align=right> 2191</td></tr>
<tr><th>PASA</th><td align=right> 73</td></tr>
<tr><th>PGM</th><td align=right> 585</td></tr>
<tr><th>POM</th><td align=right> 3679</td></tr>
<tr><th>RSA</th><td align=right> 13489</td></tr>
<tr><th>SACT</th><td align=right> 33</td></tr>
<tr><th>SBBG</th><td align=right> 4505</td></tr>
<tr><th>SCFS</th><td align=right> 25</td></tr>
<tr><th>SD</th><td align=right> 4346</td></tr>
<tr><th>SDSU</th><td align=right> 659</td></tr>
<tr><th>SEINET</th><td align=right> 1286</td></tr>
<tr><th>SFV</th><td align=right> 268</td></tr>
<tr><th>SJSU</th><td align=right> 699</td></tr>
<tr><th>UC</th><td align=right> 13428</td></tr>
<tr><th>UCD</th><td align=right> 3671</td></tr>
<tr><th>UCR</th><td align=right> 5955</td></tr>
<tr><th>UCSB</th><td align=right> 1308</td></tr>
<tr><th>UCSC</th><td align=right> 628</td></tr>
<tr><th>VVC</th><td align=right> 94</td></tr>
<tr><th>YM</th><td align=right> 290</td></tr>
</table>Total: 90440</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Sep 14 13:52:22 2015</tt></td></tr>
<tr><td>To:</td><td><tt>Tue Sep 29 11:43:57 2015</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1529</td></tr>
<tr><th>CAS</th><td align=right>1432905</td></tr>
<tr><th>CATA</th><td align=right>69497</td></tr>
<tr><th>CDA</th><td align=right>115380</td></tr>
<tr><th>CHSC</th><td align=right>281687</td></tr>
<tr><th>CSUSB</th><td align=right>13962</td></tr>
<tr><th>DS</th><td align=right>1086729</td></tr>
<tr><th>GMDRC</th><td align=right>117108</td></tr>
<tr><th>HSC</th><td align=right>258714</td></tr>
<tr><th>HUH</th><td align=right>494945</td></tr>
<tr><th>IRVC</th><td align=right>167077</td></tr>
<tr><th>JEPS</th><td align=right>780644</td></tr>
<tr><th>JOTR</th><td align=right>130483</td></tr>
<tr><th>JROH</th><td align=right>16398</td></tr>
<tr><th>LA</th><td align=right>184805</td></tr>
<tr><th>MACF</th><td align=right>1588</td></tr>
<tr><th>NY</th><td align=right>151545</td></tr>
<tr><th>OBI</th><td align=right>339095</td></tr>
<tr><th>PASA</th><td align=right>20761</td></tr>
<tr><th>PGM</th><td align=right>90807</td></tr>
<tr><th>POM</th><td align=right>1081688</td></tr>
<tr><th>RSA</th><td align=right>4269784</td></tr>
<tr><th>SACT</th><td align=right>6718</td></tr>
<tr><th>SBBG</th><td align=right>1130337</td></tr>
<tr><th>SCFS</th><td align=right>5721</td></tr>
<tr><th>SD</th><td align=right>2823005</td></tr>
<tr><th>SDSU</th><td align=right>387322</td></tr>
<tr><th>SEINET</th><td align=right>313253</td></tr>
<tr><th>SFV</th><td align=right>55445</td></tr>
<tr><th>SJSU</th><td align=right>46081</td></tr>
<tr><th>UC</th><td align=right>2169604</td></tr>
<tr><th>UCD</th><td align=right>514842</td></tr>
<tr><th>UCR</th><td align=right>2075537</td></tr>
<tr><th>UCSB</th><td align=right>319130</td></tr>
<tr><th>UCSC</th><td align=right>118006</td></tr>
<tr><th>VVC</th><td align=right>17642</td></tr>
<tr><th>YM</th><td align=right>1836</td></tr>
</table>Total: 21091645 in 1170290 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 17</td></tr>
<tr><th>CAS</th><td align=right> 41941</td></tr>
<tr><th>CATA</th><td align=right> 1453</td></tr>
<tr><th>CDA</th><td align=right> 3009</td></tr>
<tr><th>CHSC</th><td align=right> 8476</td></tr>
<tr><th>CSUSB</th><td align=right> 314</td></tr>
<tr><th>DS</th><td align=right> 32205</td></tr>
<tr><th>GMDRC</th><td align=right> 2331</td></tr>
<tr><th>HSC</th><td align=right> 3903</td></tr>
<tr><th>HUH</th><td align=right> 14589</td></tr>
<tr><th>IRVC</th><td align=right> 3580</td></tr>
<tr><th>JEPS</th><td align=right> 21726</td></tr>
<tr><th>JOTR</th><td align=right> 4042</td></tr>
<tr><th>JROH</th><td align=right> 187</td></tr>
<tr><th>LA</th><td align=right> 4977</td></tr>
<tr><th>MACF</th><td align=right> 33</td></tr>
<tr><th>NY</th><td align=right> 2687</td></tr>
<tr><th>OBI</th><td align=right> 10293</td></tr>
<tr><th>PASA</th><td align=right> 581</td></tr>
<tr><th>PGM</th><td align=right> 3882</td></tr>
<tr><th>POM</th><td align=right> 31672</td></tr>
<tr><th>RSA</th><td align=right> 119018</td></tr>
<tr><th>SACT</th><td align=right> 110</td></tr>
<tr><th>SBBG</th><td align=right> 29760</td></tr>
<tr><th>SCFS</th><td align=right> 31</td></tr>
<tr><th>SD</th><td align=right> 72679</td></tr>
<tr><th>SDSU</th><td align=right> 8980</td></tr>
<tr><th>SEINET</th><td align=right> 8122</td></tr>
<tr><th>SFV</th><td align=right> 1298</td></tr>
<tr><th>SJSU</th><td align=right> 1106</td></tr>
<tr><th>UC</th><td align=right> 57813</td></tr>
<tr><th>UCD</th><td align=right> 9640</td></tr>
<tr><th>UCR</th><td align=right> 54632</td></tr>
<tr><th>UCSB</th><td align=right> 8962</td></tr>
<tr><th>UCSC</th><td align=right> 3869</td></tr>
<tr><th>VVC</th><td align=right> 455</td></tr>
<tr><th>YM</th><td align=right> 1836</td></tr>
</table>Total: 570209</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri Aug 7 2015</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Sep 14 2015</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>3976</td></tr>
<tr><th>CAS</th><td align=right>1918622</td></tr>
<tr><th>CATA</th><td align=right>40607</td></tr>
<tr><th>CDA</th><td align=right>197236</td></tr>
<tr><th>CHSC</th><td align=right>566138</td></tr>
<tr><th>CSUSB</th><td align=right>22166</td></tr>
<tr><th>DS</th><td align=right>1234217</td></tr>
<tr><th>GMDRC</th><td align=right>76773</td></tr>
<tr><th>HSC</th><td align=right>519174</td></tr>
<tr><th>HUH</th><td align=right>554157</td></tr>
<tr><th>IRVC</th><td align=right>71967</td></tr>
<tr><th>JEPS</th><td align=right>1105851</td></tr>
<tr><th>JOTR</th><td align=right>54452</td></tr>
<tr><th>JROH</th><td align=right>55196</td></tr>
<tr><th>LA</th><td align=right>232699</td></tr>
<tr><th>MACF</th><td align=right>3384</td></tr>
<tr><th>NY</th><td align=right>205803</td></tr>
<tr><th>OBI</th><td align=right>505553</td></tr>
<tr><th>PASA</th><td align=right>19937</td></tr>
<tr><th>PGM</th><td align=right>84928</td></tr>
<tr><th>POM</th><td align=right>1003466</td></tr>
<tr><th>RSA</th><td align=right>4060745</td></tr>
<tr><th>SACT</th><td align=right>14203</td></tr>
<tr><th>SBBG</th><td align=right>1381178</td></tr>
<tr><th>SCFS</th><td align=right>5080</td></tr>
<tr><th>SD</th><td align=right>1802509</td></tr>
<tr><th>SDSU</th><td align=right>248607</td></tr>
<tr><th>SEINET</th><td align=right>355348</td></tr>
<tr><th>SFV</th><td align=right>94657</td></tr>
<tr><th>SJSU</th><td align=right>81070</td></tr>
<tr><th>UC</th><td align=right>2846972</td></tr>
<tr><th>UCD</th><td align=right>809621</td></tr>
<tr><th>UCR</th><td align=right>1957706</td></tr>
<tr><th>UCSB</th><td align=right>473002</td></tr>
<tr><th>UCSC</th><td align=right>69799</td></tr>
<tr><th>VVC</th><td align=right>30097</td></tr>
<tr><th>YM</th><td align=right>559</td></tr>
</table>Total: 22707458 in 291600 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 3</td></tr>
<tr><th>CAS</th><td align=right> 8730</td></tr>
<tr><th>CATA</th><td align=right> 189</td></tr>
<tr><th>CDA</th><td align=right> 741</td></tr>
<tr><th>CHSC</th><td align=right> 1495</td></tr>
<tr><th>CSUSB</th><td align=right> 79</td></tr>
<tr><th>DS</th><td align=right> 5653</td></tr>
<tr><th>GMDRC</th><td align=right> 158</td></tr>
<tr><th>HSC</th><td align=right> 1883</td></tr>
<tr><th>HUH</th><td align=right> 3475</td></tr>
<tr><th>IRVC</th><td align=right> 290</td></tr>
<tr><th>JEPS</th><td align=right> 6035</td></tr>
<tr><th>JOTR</th><td align=right> 374</td></tr>
<tr><th>JROH</th><td align=right> 329</td></tr>
<tr><th>LA</th><td align=right> 1110</td></tr>
<tr><th>MACF</th><td align=right> 24</td></tr>
<tr><th>NY</th><td align=right> 2262</td></tr>
<tr><th>OBI</th><td align=right> 1993</td></tr>
<tr><th>PASA</th><td align=right> 80</td></tr>
<tr><th>PGM</th><td align=right> 826</td></tr>
<tr><th>POM</th><td align=right> 3893</td></tr>
<tr><th>RSA</th><td align=right> 20879</td></tr>
<tr><th>SACT</th><td align=right> 32</td></tr>
<tr><th>SBBG</th><td align=right> 6173</td></tr>
<tr><th>SCFS</th><td align=right> 2</td></tr>
<tr><th>SD</th><td align=right> 9428</td></tr>
<tr><th>SDSU</th><td align=right> 1416</td></tr>
<tr><th>SEINET</th><td align=right> 1905</td></tr>
<tr><th>SFV</th><td align=right> 359</td></tr>
<tr><th>SJSU</th><td align=right> 299</td></tr>
<tr><th>UC</th><td align=right> 13173</td></tr>
<tr><th>UCD</th><td align=right> 3085</td></tr>
<tr><th>UCR</th><td align=right> 10343</td></tr>
<tr><th>UCSB</th><td align=right> 2133</td></tr>
<tr><th>UCSC</th><td align=right> 660</td></tr>
<tr><th>VVC</th><td align=right> 144</td></tr>
<tr><th>YM</th><td align=right> 559</td></tr>
</table>Total: 110212</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>April 2 2015</tt></td></tr>
<tr><td>To:</td><td><tt>Fri Aug 7 09:24:44 2015</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>3329</td></tr>
<tr><th>CAS</th><td align=right>1802721</td></tr>
<tr><th>CATA</th><td align=right>51598</td></tr>
<tr><th>CDA</th><td align=right>189058</td></tr>
<tr><th>CHSC</th><td align=right>536832</td></tr>
<tr><th>CSUSB</th><td align=right>20593</td></tr>
<tr><th>DS</th><td align=right>1109121</td></tr>
<tr><th>GMDRC</th><td align=right>60649</td></tr>
<tr><th>HSC</th><td align=right>487077</td></tr>
<tr><th>HUH</th><td align=right>488963</td></tr>
<tr><th>IRVC</th><td align=right>74136</td></tr>
<tr><th>JEPS</th><td align=right>1001504</td></tr>
<tr><th>JOTR</th><td align=right>36514</td></tr>
<tr><th>JROH</th><td align=right>64588</td></tr>
<tr><th>LA</th><td align=right>198915</td></tr>
<tr><th>MACF</th><td align=right>2748</td></tr>
<tr><th>NY</th><td align=right>134660</td></tr>
<tr><th>OBI</th><td align=right>414755</td></tr>
<tr><th>PASA</th><td align=right>18176</td></tr>
<tr><th>PGM</th><td align=right>53122</td></tr>
<tr><th>POM</th><td align=right>972363</td></tr>
<tr><th>RSA</th><td align=right>3850055</td></tr>
<tr><th>SACT</th><td align=right>17972</td></tr>
<tr><th>SBBG</th><td align=right>1563198</td></tr>
<tr><th>SCFS</th><td align=right>8560</td></tr>
<tr><th>SD</th><td align=right>1699564</td></tr>
<tr><th>SDSU</th><td align=right>200600</td></tr>
<tr><th>SEINET</th><td align=right>325569</td></tr>
<tr><th>SFV</th><td align=right>82438</td></tr>
<tr><th>SJSU</th><td align=right>74392</td></tr>
<tr><th>UC</th><td align=right>2600263</td></tr>
<tr><th>UCD</th><td align=right>833270</td></tr>
<tr><th>UCR</th><td align=right>1816876</td></tr>
<tr><th>UCSB</th><td align=right>385215</td></tr>
<tr><th>UCSC</th><td align=right>51998</td></tr>
<tr><th>VVC</th><td align=right>46271</td></tr>
<tr><th>YM</th><td align=right>1335</td></tr>
</table>Total: 21279002 in 720888 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 98</td></tr>
<tr><th>CAS</th><td align=right> 31063</td></tr>
<tr><th>CATA</th><td align=right> 448</td></tr>
<tr><th>CDA</th><td align=right> 3332</td></tr>
<tr><th>CHSC</th><td align=right> 10250</td></tr>
<tr><th>CSUSB</th><td align=right> 243</td></tr>
<tr><th>DS</th><td align=right> 17495</td></tr>
<tr><th>GMDRC</th><td align=right> 1135</td></tr>
<tr><th>HSC</th><td align=right> 10184</td></tr>
<tr><th>HUH</th><td align=right> 6079</td></tr>
<tr><th>IRVC</th><td align=right> 859</td></tr>
<tr><th>JEPS</th><td align=right> 17859</td></tr>
<tr><th>JOTR</th><td align=right> 592</td></tr>
<tr><th>JROH</th><td align=right> 539</td></tr>
<tr><th>LA</th><td align=right> 3394</td></tr>
<tr><th>MACF</th><td align=right> 65</td></tr>
<tr><th>NY</th><td align=right> 2000</td></tr>
<tr><th>OBI</th><td align=right> 6719</td></tr>
<tr><th>PASA</th><td align=right> 291</td></tr>
<tr><th>PGM</th><td align=right> 988</td></tr>
<tr><th>POM</th><td align=right> 13299</td></tr>
<tr><th>RSA</th><td align=right> 53109</td></tr>
<tr><th>SACT</th><td align=right> 329</td></tr>
<tr><th>SBBG</th><td align=right> 16628</td></tr>
<tr><th>SCFS</th><td align=right> 132</td></tr>
<tr><th>SD</th><td align=right> 21176</td></tr>
<tr><th>SDSU</th><td align=right> 2269</td></tr>
<tr><th>SEINET</th><td align=right> 6340</td></tr>
<tr><th>SFV</th><td align=right> 1041</td></tr>
<tr><th>SJSU</th><td align=right> 1333</td></tr>
<tr><th>UC</th><td align=right> 40486</td></tr>
<tr><th>UCD</th><td align=right> 14196</td></tr>
<tr><th>UCR</th><td align=right> 21824</td></tr>
<tr><th>UCSB</th><td align=right> 6129</td></tr>
<tr><th>UCSC</th><td align=right> 1004</td></tr>
<tr><th>VVC</th><td align=right> 1210</td></tr>
<tr><th>YM</th><td align=right> 1335</td></tr>
</table>Total: 315473</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Tue Feb  3 2015</tt></td></tr>
<tr><td>To:</td><td><tt>Wed April 1 2015</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>6098</td></tr>
<tr><th>CAS</th><td align=right>2121401</td></tr>
<tr><th>CATA</th><td align=right>14763</td></tr>
<tr><th>CDA</th><td align=right>259268</td></tr>
<tr><th>CHSC</th><td align=right>693285</td></tr>
<tr><th>CSUSB</th><td align=right>28894</td></tr>
<tr><th>DS</th><td align=right>1218485</td></tr>
<tr><th>GMDRC</th><td align=right>97971</td></tr>
<tr><th>HSC</th><td align=right>768730</td></tr>
<tr><th>HUH</th><td align=right>601966</td></tr>
<tr><th>IRVC</th><td align=right>72684</td></tr>
<tr><th>JEPS</th><td align=right>1334518</td></tr>
<tr><th>JOTR</th><td align=right>71866</td></tr>
<tr><th>JROH</th><td align=right>50091</td></tr>
<tr><th>LA</th><td align=right>264223</td></tr>
<tr><th>MACF</th><td align=right>1692</td></tr>
<tr><th>NY</th><td align=right>163737</td></tr>
<tr><th>OBI</th><td align=right>523305</td></tr>
<tr><th>PASA</th><td align=right>26323</td></tr>
<tr><th>PGM</th><td align=right>85467</td></tr>
<tr><th>POM</th><td align=right>1008168</td></tr>
<tr><th>RS</th><td align=right>2</td></tr>
<tr><th>RSA</th><td align=right>4266685</td></tr>
<tr><th>SACT</th><td align=right>23011</td></tr>
<tr><th>SBBG</th><td align=right>1269526</td></tr>
<tr><th>SCFS</th><td align=right>8380</td></tr>
<tr><th>SD</th><td align=right>1927743</td></tr>
<tr><th>SDSU</th><td align=right>220247</td></tr>
<tr><th>SEINET</th><td align=right>420523</td></tr>
<tr><th>SFV</th><td align=right>89091</td></tr>
<tr><th>SJSU</th><td align=right>101273</td></tr>
<tr><th>UC</th><td align=right>3155921</td></tr>
<tr><th>UCD</th><td align=right>1094870</td></tr>
<tr><th>UCR</th><td align=right>2238236</td></tr>
<tr><th>UCSB</th><td align=right>431253</td></tr>
<tr><th>UCSC</th><td align=right>74517</td></tr>
<tr><th>VVC</th><td align=right>38715</td></tr>
<tr><th>YM</th><td align=right>243</td></tr>
</table>Total: 24773184 in 226679 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 39</td></tr>
<tr><th>CAS</th><td align=right> 8426</td></tr>
<tr><th>CATA</th><td align=right> 47</td></tr>
<tr><th>CDA</th><td align=right> 2021</td></tr>
<tr><th>CHSC</th><td align=right> 5242</td></tr>
<tr><th>CSUSB</th><td align=right> 112</td></tr>
<tr><th>DS</th><td align=right> 4039</td></tr>
<tr><th>GMDRC</th><td align=right> 458</td></tr>
<tr><th>HSC</th><td align=right> 3911</td></tr>
<tr><th>HUH</th><td align=right> 2126</td></tr>
<tr><th>IRVC</th><td align=right> 217</td></tr>
<tr><th>JEPS</th><td align=right> 7854</td></tr>
<tr><th>JOTR</th><td align=right> 227</td></tr>
<tr><th>JROH</th><td align=right> 143</td></tr>
<tr><th>LA</th><td align=right> 743</td></tr>
<tr><th>MACF</th><td align=right> 11</td></tr>
<tr><th>NY</th><td align=right> 815</td></tr>
<tr><th>OBI</th><td align=right> 2881</td></tr>
<tr><th>PASA</th><td align=right> 56</td></tr>
<tr><th>PGM</th><td align=right> 431</td></tr>
<tr><th>POM</th><td align=right> 2790</td></tr>
<tr><th>RSA</th><td align=right> 13973</td></tr>
<tr><th>SACT</th><td align=right> 60</td></tr>
<tr><th>SBBG</th><td align=right> 5997</td></tr>
<tr><th>SCFS</th><td align=right> 11</td></tr>
<tr><th>SD</th><td align=right> 6550</td></tr>
<tr><th>SDSU</th><td align=right> 2073</td></tr>
<tr><th>SEINET</th><td align=right> 2051</td></tr>
<tr><th>SFV</th><td align=right> 373</td></tr>
<tr><th>SJSU</th><td align=right> 951</td></tr>
<tr><th>UC</th><td align=right> 14182</td></tr>
<tr><th>UCD</th><td align=right> 4724</td></tr>
<tr><th>UCR</th><td align=right> 8223</td></tr>
<tr><th>UCSB</th><td align=right> 2137</td></tr>
<tr><th>UCSC</th><td align=right> 728</td></tr>
<tr><th>VVC</th><td align=right> 185</td></tr>
<tr><th>YM</th><td align=right> 243</td></tr>
</table>Total: 105050</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri Nov 21 20:13:04 2014</tt></td></tr>
<tr><td>To:</td><td><tt>Tue Feb  3 08:37:52 2015</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>1499</td></tr>
<tr><th>CAS</th><td align=right>671605</td></tr>
<tr><th>CDA</th><td align=right>79000</td></tr>
<tr><th>CHSC</th><td align=right>197714</td></tr>
<tr><th>CSUSB</th><td align=right>9357</td></tr>
<tr><th>DS</th><td align=right>432200</td></tr>
<tr><th>HSC</th><td align=right>203296</td></tr>
<tr><th>HUH</th><td align=right>238708</td></tr>
<tr><th>IRVC</th><td align=right>36051</td></tr>
<tr><th>JEPS</th><td align=right>429040</td></tr>
<tr><th>JOTR</th><td align=right>20375</td></tr>
<tr><th>JROH</th><td align=right>19838</td></tr>
<tr><th>LA</th><td align=right>91090</td></tr>
<tr><th>NY</th><td align=right>55428</td></tr>
<tr><th>OBI</th><td align=right>171896</td></tr>
<tr><th>PASA</th><td align=right>8700</td></tr>
<tr><th>PGM</th><td align=right>30768</td></tr>
<tr><th>POM</th><td align=right>365894</td></tr>
<tr><th>RSA</th><td align=right>1559517</td></tr>
<tr><th>SACT</th><td align=right>5033</td></tr>
<tr><th>SBBG</th><td align=right>395562</td></tr>
<tr><th>SCFS</th><td align=right>2758</td></tr>
<tr><th>SD</th><td align=right>543801</td></tr>
<tr><th>SDSU</th><td align=right>65568</td></tr>
<tr><th>SEINET</th><td align=right>104622</td></tr>
<tr><th>SFV</th><td align=right>38973</td></tr>
<tr><th>SJSU</th><td align=right>43032</td></tr>
<tr><th>UC</th><td align=right>1126603</td></tr>
<tr><th>UCD</th><td align=right>336142</td></tr>
<tr><th>UCR</th><td align=right>835089</td></tr>
<tr><th>UCSB</th><td align=right>143656</td></tr>
<tr><th>UCSC</th><td align=right>52810</td></tr>
<tr><th>VVC</th><td align=right>12952</td></tr>
<tr><th>YM</th><td align=right>59</td></tr>
</table>Total: 8328643 in 68228 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 8</td></tr>
<tr><th>CAS</th><td align=right> 2357</td></tr>
<tr><th>CDA</th><td align=right> 267</td></tr>
<tr><th>CHSC</th><td align=right> 786</td></tr>
<tr><th>CSUSB</th><td align=right> 12</td></tr>
<tr><th>DS</th><td align=right> 1027</td></tr>
<tr><th>HSC</th><td align=right> 621</td></tr>
<tr><th>HUH</th><td align=right> 654</td></tr>
<tr><th>IRVC</th><td align=right> 45</td></tr>
<tr><th>JEPS</th><td align=right> 2142</td></tr>
<tr><th>JOTR</th><td align=right> 50</td></tr>
<tr><th>JROH</th><td align=right> 35</td></tr>
<tr><th>LA</th><td align=right> 272</td></tr>
<tr><th>NY</th><td align=right> 221</td></tr>
<tr><th>OBI</th><td align=right> 550</td></tr>
<tr><th>PASA</th><td align=right> 22</td></tr>
<tr><th>PGM</th><td align=right> 206</td></tr>
<tr><th>POM</th><td align=right> 943</td></tr>
<tr><th>RSA</th><td align=right> 4697</td></tr>
<tr><th>SACT</th><td align=right> 3</td></tr>
<tr><th>SBBG</th><td align=right> 1084</td></tr>
<tr><th>SD</th><td align=right> 1168</td></tr>
<tr><th>SDSU</th><td align=right> 244</td></tr>
<tr><th>SEINET</th><td align=right> 294</td></tr>
<tr><th>SFV</th><td align=right> 90</td></tr>
<tr><th>SJSU</th><td align=right> 223</td></tr>
<tr><th>UC</th><td align=right> 3992</td></tr>
<tr><th>UCD</th><td align=right> 965</td></tr>
<tr><th>UCR</th><td align=right> 3119</td></tr>
<tr><th>UCSB</th><td align=right> 362</td></tr>
<tr><th>UCSC</th><td align=right> 343</td></tr>
<tr><th>VVC</th><td align=right> 35</td></tr>
<tr><th>YM</th><td align=right> 59</td></tr>
</table>Total: 26896</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri May 23 22:20:14 2014</tt></td></tr>
<tr><td>To:</td><td><tt>Fri Nov 21 20:05:54 2014</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>3865</td></tr>
<tr><th>CAS</th><td align=right>1814185</td></tr>
<tr><th>CDA</th><td align=right>196569</td></tr>
<tr><th>CHSC</th><td align=right>562354</td></tr>
<tr><th>CSUSB</th><td align=right>24133</td></tr>
<tr><th>DS</th><td align=right>1075647</td></tr>
<tr><th>HSC</th><td align=right>598146</td></tr>
<tr><th>HUH</th><td align=right>548557</td></tr>
<tr><th>IRVC</th><td align=right>66141</td></tr>
<tr><th>JEPS</th><td align=right>1082161</td></tr>
<tr><th>JOTR</th><td align=right>57479</td></tr>
<tr><th>JROH</th><td align=right>68412</td></tr>
<tr><th>LA</th><td align=right>230749</td></tr>
<tr><th>NY</th><td align=right>165071</td></tr>
<tr><th>OBI</th><td align=right>441395</td></tr>
<tr><th>PASA</th><td align=right>21033</td></tr>
<tr><th>PGM</th><td align=right>67996</td></tr>
<tr><th>POM</th><td align=right>957410</td></tr>
<tr><th>RSA</th><td align=right>4149783</td></tr>
<tr><th>RSASD</th><td align=right>2</td></tr>
<tr><th>SACT</th><td align=right>17560</td></tr>
<tr><th>SBBG</th><td align=right>1082684</td></tr>
<tr><th>SCFS</th><td align=right>9902</td></tr>
<tr><th>SD</th><td align=right>1381940</td></tr>
<tr><th>SDSU</th><td align=right>178404</td></tr>
<tr><th>SEINET</th><td align=right>244523</td></tr>
<tr><th>SFV</th><td align=right>88896</td></tr>
<tr><th>SJSU</th><td align=right>85569</td></tr>
<tr><th>UC</th><td align=right>2760834</td></tr>
<tr><th>UCD</th><td align=right>891052</td></tr>
<tr><th>UCR</th><td align=right>2009659</td></tr>
<tr><th>UCSB</th><td align=right>283697</td></tr>
<tr><th>UCSC</th><td align=right>49246</td></tr>
<tr><th>VVC</th><td align=right>44383</td></tr>
<tr><th>YM</th><td align=right>176</td></tr>
</table>Total: 21259640 in 187097 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 18</td></tr>
<tr><th>CAS</th><td align=right> 6481</td></tr>
<tr><th>CDA</th><td align=right> 980</td></tr>
<tr><th>CHSC</th><td align=right> 2992</td></tr>
<tr><th>CSUSB</th><td align=right> 113</td></tr>
<tr><th>DS</th><td align=right> 2952</td></tr>
<tr><th>HSC</th><td align=right> 1498</td></tr>
<tr><th>HUH</th><td align=right> 1886</td></tr>
<tr><th>IRVC</th><td align=right> 179</td></tr>
<tr><th>JEPS</th><td align=right> 5787</td></tr>
<tr><th>JOTR</th><td align=right> 69</td></tr>
<tr><th>JROH</th><td align=right> 101</td></tr>
<tr><th>LA</th><td align=right> 750</td></tr>
<tr><th>NY</th><td align=right> 589</td></tr>
<tr><th>OBI</th><td align=right> 2157</td></tr>
<tr><th>PASA</th><td align=right> 32</td></tr>
<tr><th>PGM</th><td align=right> 243</td></tr>
<tr><th>POM</th><td align=right> 2793</td></tr>
<tr><th>RSA</th><td align=right> 12871</td></tr>
<tr><th>SACT</th><td align=right> 29</td></tr>
<tr><th>SBBG</th><td align=right> 3587</td></tr>
<tr><th>SCFS</th><td align=right> 1</td></tr>
<tr><th>SD</th><td align=right> 3603</td></tr>
<tr><th>SDSU</th><td align=right> 625</td></tr>
<tr><th>SEINET</th><td align=right> 782</td></tr>
<tr><th>SFV</th><td align=right> 316</td></tr>
<tr><th>SJSU</th><td align=right> 413</td></tr>
<tr><th>UC</th><td align=right> 10683</td></tr>
<tr><th>UCD</th><td align=right> 3461</td></tr>
<tr><th>UCR</th><td align=right> 7080</td></tr>
<tr><th>UCSB</th><td align=right> 1358</td></tr>
<tr><th>UCSC</th><td align=right> 250</td></tr>
<tr><th>VVC</th><td align=right> 71</td></tr>
<tr><th>YM</th><td align=right> 176</td></tr>
</table>Total: 74926</td></tr></table>



<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Feb 10 20:07:29 2014</tt></td></tr>
<tr><td>To:</td><td><tt>Fri May 23 22:15:44 2014</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>BLMAR</th><td align=right>4780</td></tr>
<tr><th>CAS</th><td align=right>1435104</td></tr>
<tr><th>CDA</th><td align=right>188435</td></tr>
<tr><th>CHSC</th><td align=right>582901</td></tr>
<tr><th>CSUSB</th><td align=right>19538</td></tr>
<tr><th>DS</th><td align=right>862031</td></tr>
<tr><th>HSC</th><td align=right>481585</td></tr>
<tr><th>HUH</th><td align=right>550720</td></tr>
<tr><th>IRVC</th><td align=right>56522</td></tr>
<tr><th>JEPS</th><td align=right>949019</td></tr>
<tr><th>JOTR</th><td align=right>31293</td></tr>
<tr><th>JROH</th><td align=right>117143</td></tr>
<tr><th>LA</th><td align=right>162237</td></tr>
<tr><th>NY</th><td align=right>100306</td></tr>
<tr><th>OBI</th><td align=right>350158</td></tr>
<tr><th>PGM</th><td align=right>45563</td></tr>
<tr><th>POM</th><td align=right>794137</td></tr>
<tr><th>RSA</th><td align=right>3049455</td></tr>
<tr><th>SACT</th><td align=right>18029</td></tr>
<tr><th>SBBG</th><td align=right>988357</td></tr>
<tr><th>SCFS</th><td align=right>5721</td></tr>
<tr><th>SD</th><td align=right>1092974</td></tr>
<tr><th>SDSU</th><td align=right>153353</td></tr>
<tr><th>SEINET</th><td align=right>212765</td></tr>
<tr><th>SFV</th><td align=right>66225</td></tr>
<tr><th>SJSU</th><td align=right>69735</td></tr>
<tr><th>UC</th><td align=right>2423063</td></tr>
<tr><th>UCD</th><td align=right>886575</td></tr>
<tr><th>UCR</th><td align=right>1452562</td></tr>
<tr><th>UCSB</th><td align=right>246233</td></tr>
<tr><th>UCSC</th><td align=right>59070</td></tr>
<tr><th>VVC</th><td align=right>16860</td></tr>
<tr><th>YM</th><td align=right>120</td></tr>
</table>Total: 17472571 in 136025 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>BLMAR</th><td align=right> 24</td></tr>
<tr><th>CAS</th><td align=right> 4243</td></tr>
<tr><th>CDA</th><td align=right> 705</td></tr>
<tr><th>CHSC</th><td align=right> 2073</td></tr>
<tr><th>CSUSB</th><td align=right> 35</td></tr>
<tr><th>DS</th><td align=right> 1872</td></tr>
<tr><th>HSC</th><td align=right> 1089</td></tr>
<tr><th>HUH</th><td align=right> 1251</td></tr>
<tr><th>IRVC</th><td align=right> 155</td></tr>
<tr><th>JEPS</th><td align=right> 4300</td></tr>
<tr><th>JOTR</th><td align=right> 58</td></tr>
<tr><th>JROH</th><td align=right> 186</td></tr>
<tr><th>LA</th><td align=right> 476</td></tr>
<tr><th>NY</th><td align=right> 308</td></tr>
<tr><th>OBI</th><td align=right> 872</td></tr>
<tr><th>PGM</th><td align=right> 89</td></tr>
<tr><th>POM</th><td align=right> 2541</td></tr>
<tr><th>RSA</th><td align=right> 12974</td></tr>
<tr><th>SACT</th><td align=right> 20</td></tr>
<tr><th>SBBG</th><td align=right> 3222</td></tr>
<tr><th>SCFS</th><td align=right> 1</td></tr>
<tr><th>SD</th><td align=right> 2782</td></tr>
<tr><th>SDSU</th><td align=right> 465</td></tr>
<tr><th>SEINET</th><td align=right> 669</td></tr>
<tr><th>SFV</th><td align=right> 246</td></tr>
<tr><th>SJSU</th><td align=right> 191</td></tr>
<tr><th>UC</th><td align=right> 6982</td></tr>
<tr><th>UCD</th><td align=right> 2018</td></tr>
<tr><th>UCR</th><td align=right> 5790</td></tr>
<tr><th>UCSB</th><td align=right> 546</td></tr>
<tr><th>UCSC</th><td align=right> 194</td></tr>
<tr><th>VVC</th><td align=right> 51</td></tr>
<tr><th>YM</th><td align=right> 120</td></tr>
</table>Total: 56548</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Thu Oct 17 10:05:57 2013</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Feb 10 20:07:29 2014</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>806495</td></tr>
<tr><th>CDA</th><td align=right>146917</td></tr>
<tr><th>CHSC</th><td align=right>400234</td></tr>
<tr><th>CSUSB</th><td align=right>9989</td></tr>
<tr><th>DS</th><td align=right>444754</td></tr>
<tr><th>HSC</th><td align=right>315675</td></tr>
<tr><th>HUH</th><td align=right>289049</td></tr>
<tr><th>IRVC</th><td align=right>40225</td></tr>
<tr><th>JEPS</th><td align=right>657835</td></tr>
<tr><th>JOTR</th><td align=right>27934</td></tr>
<tr><th>LA</th><td align=right>16014</td></tr>
<tr><th>NY</th><td align=right>83256</td></tr>
<tr><th>OBI</th><td align=right>185534</td></tr>
<tr><th>PGM</th><td align=right>33448</td></tr>
<tr><th>POM</th><td align=right>489983</td></tr>
<tr><th>RSA</th><td align=right>2083595</td></tr>
<tr><th>SACT</th><td align=right>19676</td></tr>
<tr><th>SBBG</th><td align=right>570411</td></tr>
<tr><th>SCFS</th><td align=right>11008</td></tr>
<tr><th>SD</th><td align=right>757981</td></tr>
<tr><th>SDSU</th><td align=right>101045</td></tr>
<tr><th>SEINET</th><td align=right>173674</td></tr>
<tr><th>SFV</th><td align=right>44101</td></tr>
<tr><th>SJSU</th><td align=right>48404</td></tr>
<tr><th>UC</th><td align=right>1589800</td></tr>
<tr><th>UCD</th><td align=right>486612</td></tr>
<tr><th>UCR</th><td align=right>1121234</td></tr>
<tr><th>UCSB</th><td align=right>112566</td></tr>
<tr><th>UCSC</th><td align=right>41849</td></tr>
<tr><th>VVC</th><td align=right>14059</td></tr>
<tr><th>YM</th><td align=right>141</td></tr>
</table>Total: 11123501 in 123819 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 2572</td></tr>
<tr><th>CDA</th><td align=right> 637</td></tr>
<tr><th>CHSC</th><td align=right> 1735</td></tr>
<tr><th>CSUSB</th><td align=right> 30</td></tr>
<tr><th>DS</th><td align=right> 1144</td></tr>
<tr><th>HSC</th><td align=right> 1176</td></tr>
<tr><th>HUH</th><td align=right> 840</td></tr>
<tr><th>IRVC</th><td align=right> 145</td></tr>
<tr><th>JEPS</th><td align=right> 3771</td></tr>
<tr><th>JOTR</th><td align=right> 31</td></tr>
<tr><th>LA</th><td align=right> 80</td></tr>
<tr><th>NY</th><td align=right> 411</td></tr>
<tr><th>OBI</th><td align=right> 574</td></tr>
<tr><th>PGM</th><td align=right> 148</td></tr>
<tr><th>POM</th><td align=right> 2223</td></tr>
<tr><th>RSA</th><td align=right> 11480</td></tr>
<tr><th>SACT</th><td align=right> 31</td></tr>
<tr><th>SBBG</th><td align=right> 2128</td></tr>
<tr><th>SCFS</th><td align=right> 6</td></tr>
<tr><th>SD</th><td align=right> 2895</td></tr>
<tr><th>SDSU</th><td align=right> 407</td></tr>
<tr><th>SEINET</th><td align=right> 312</td></tr>
<tr><th>SFV</th><td align=right> 254</td></tr>
<tr><th>SJSU</th><td align=right> 215</td></tr>
<tr><th>UC</th><td align=right> 7733</td></tr>
<tr><th>UCD</th><td align=right> 1752</td></tr>
<tr><th>UCR</th><td align=right> 5550</td></tr>
<tr><th>UCSB</th><td align=right> 440</td></tr>
<tr><th>UCSC</th><td align=right> 210</td></tr>
<tr><th>VVC</th><td align=right> 29</td></tr>
<tr><th>YM</th><td align=right> 141</td></tr>
</table>Total: 49100</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sun Aug  4 09:17:15 2013</tt></td></tr>
<tr><td>To:</td><td><tt>Thu Oct 17 10:05:57 2013</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>806495</td></tr>
<tr><th>CDA</th><td align=right>146917</td></tr>
<tr><th>CHSC</th><td align=right>400234</td></tr>
<tr><th>CSUSB</th><td align=right>9989</td></tr>
<tr><th>DS</th><td align=right>444754</td></tr>
<tr><th>HSC</th><td align=right>315675</td></tr>
<tr><th>HUH</th><td align=right>289049</td></tr>
<tr><th>IRVC</th><td align=right>40225</td></tr>
<tr><th>JEPS</th><td align=right>657835</td></tr>
<tr><th>JOTR</th><td align=right>27934</td></tr>
<tr><th>LA</th><td align=right>16014</td></tr>
<tr><th>NY</th><td align=right>83256</td></tr>
<tr><th>OBI</th><td align=right>185534</td></tr>
<tr><th>PGM</th><td align=right>33448</td></tr>
<tr><th>POM</th><td align=right>489983</td></tr>
<tr><th>RSA</th><td align=right>2083595</td></tr>
<tr><th>SACT</th><td align=right>19676</td></tr>
<tr><th>SBBG</th><td align=right>570411</td></tr>
<tr><th>SCFS</th><td align=right>11008</td></tr>
<tr><th>SD</th><td align=right>757981</td></tr>
<tr><th>SDSU</th><td align=right>101045</td></tr>
<tr><th>SEINET</th><td align=right>173674</td></tr>
<tr><th>SFV</th><td align=right>44101</td></tr>
<tr><th>SJSU</th><td align=right>48404</td></tr>
<tr><th>UC</th><td align=right>1589800</td></tr>
<tr><th>UCD</th><td align=right>486612</td></tr>
<tr><th>UCR</th><td align=right>1121234</td></tr>
<tr><th>UCSB</th><td align=right>112566</td></tr>
<tr><th>UCSC</th><td align=right>41849</td></tr>
<tr><th>VVC</th><td align=right>14059</td></tr>
<tr><th>YM</th><td align=right>141</td></tr>
</table>Total: 11123501 in 123819 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 2572</td></tr>
<tr><th>CDA</th><td align=right> 637</td></tr>
<tr><th>CHSC</th><td align=right> 1735</td></tr>
<tr><th>CSUSB</th><td align=right> 30</td></tr>
<tr><th>DS</th><td align=right> 1144</td></tr>
<tr><th>HSC</th><td align=right> 1176</td></tr>
<tr><th>HUH</th><td align=right> 840</td></tr>
<tr><th>IRVC</th><td align=right> 145</td></tr>
<tr><th>JEPS</th><td align=right> 3771</td></tr>
<tr><th>JOTR</th><td align=right> 31</td></tr>
<tr><th>LA</th><td align=right> 80</td></tr>
<tr><th>NY</th><td align=right> 411</td></tr>
<tr><th>OBI</th><td align=right> 574</td></tr>
<tr><th>PGM</th><td align=right> 148</td></tr>
<tr><th>POM</th><td align=right> 2223</td></tr>
<tr><th>RSA</th><td align=right> 11480</td></tr>
<tr><th>SACT</th><td align=right> 31</td></tr>
<tr><th>SBBG</th><td align=right> 2128</td></tr>
<tr><th>SCFS</th><td align=right> 6</td></tr>
<tr><th>SD</th><td align=right> 2895</td></tr>
<tr><th>SDSU</th><td align=right> 407</td></tr>
<tr><th>SEINET</th><td align=right> 312</td></tr>
<tr><th>SFV</th><td align=right> 254</td></tr>
<tr><th>SJSU</th><td align=right> 215</td></tr>
<tr><th>UC</th><td align=right> 7733</td></tr>
<tr><th>UCD</th><td align=right> 1752</td></tr>
<tr><th>UCR</th><td align=right> 5550</td></tr>
<tr><th>UCSB</th><td align=right> 440</td></tr>
<tr><th>UCSC</th><td align=right> 210</td></tr>
<tr><th>VVC</th><td align=right> 29</td></tr>
<tr><th>YM</th><td align=right> 141</td></tr>
</table>Total: 49100</td></tr></table>






<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Jun 10 09:32:49 2013</tt></td></tr>
<tr><td>To:</td><td><tt>Sun Aug  4 09:12:50 2013</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>595886</td></tr>
<tr><th>CDA</th><td align=right>95484</td></tr>
<tr><th>CHSC</th><td align=right>272286</td></tr>
<tr><th>CSUSB</th><td align=right>13432</td></tr>
<tr><th>DS</th><td align=right>323089</td></tr>
<tr><th>HSC</th><td align=right>248465</td></tr>
<tr><th>HUH</th><td align=right>195145</td></tr>
<tr><th>IRVC</th><td align=right>25187</td></tr>
<tr><th>JEPS</th><td align=right>472789</td></tr>
<tr><th>JOTR</th><td align=right>14214</td></tr>
<tr><th>LA</th><td align=right>8514</td></tr>
<tr><th>NY</th><td align=right>48695</td></tr>
<tr><th>OBI</th><td align=right>126428</td></tr>
<tr><th>PGM</th><td align=right>21114</td></tr>
<tr><th>POM</th><td align=right>349935</td></tr>
<tr><th>RSA</th><td align=right>1475789</td></tr>
<tr><th>SBBG</th><td align=right>371497</td></tr>
<tr><th>SCFS</th><td align=right>2829</td></tr>
<tr><th>SD</th><td align=right>479508</td></tr>
<tr><th>SDSU</th><td align=right>67056</td></tr>
<tr><th>SEINET</th><td align=right>34595</td></tr>
<tr><th>SFV</th><td align=right>33900</td></tr>
<tr><th>SJSU</th><td align=right>32572</td></tr>
<tr><th>UC</th><td align=right>1099389</td></tr>
<tr><th>UCD</th><td align=right>367776</td></tr>
<tr><th>UCR</th><td align=right>641560</td></tr>
<tr><th>UCSB</th><td align=right>70757</td></tr>
<tr><th>UCSC</th><td align=right>22242</td></tr>
<tr><th>VVC</th><td align=right>9630</td></tr>
<tr><th>YM</th><td align=right>56</td></tr>
</table>Total: 7519820 in 67990 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 1442</td></tr>
<tr><th>CDA</th><td align=right> 407</td></tr>
<tr><th>CHSC</th><td align=right> 1673</td></tr>
<tr><th>CLARK</th><td align=right> 1</td></tr>
<tr><th>CSUSB</th><td align=right> 10</td></tr>
<tr><th>DS</th><td align=right> 569</td></tr>
<tr><th>HSC</th><td align=right> 681</td></tr>
<tr><th>HUH</th><td align=right> 443</td></tr>
<tr><th>IRVC</th><td align=right> 65</td></tr>
<tr><th>JEPS</th><td align=right> 2736</td></tr>
<tr><th>JOTR</th><td align=right> 54</td></tr>
<tr><th>LA</th><td align=right> 69</td></tr>
<tr><th>NY</th><td align=right> 127</td></tr>
<tr><th>OBI</th><td align=right> 825</td></tr>
<tr><th>PGM</th><td align=right> 62</td></tr>
<tr><th>POM</th><td align=right> 915</td></tr>
<tr><th>RSA</th><td align=right> 4259</td></tr>
<tr><th>SBBG</th><td align=right> 1036</td></tr>
<tr><th>SCFS</th><td align=right> 6</td></tr>
<tr><th>SD</th><td align=right> 981</td></tr>
<tr><th>SDSU</th><td align=right> 207</td></tr>
<tr><th>SEINET</th><td align=right> 93</td></tr>
<tr><th>SFV</th><td align=right> 154</td></tr>
<tr><th>SJSU</th><td align=right> 76</td></tr>
<tr><th>UC</th><td align=right> 4448</td></tr>
<tr><th>UCD</th><td align=right> 1062</td></tr>
<tr><th>UCR</th><td align=right> 2341</td></tr>
<tr><th>UCSB</th><td align=right> 242</td></tr>
<tr><th>UCSC</th><td align=right> 128</td></tr>
<tr><th>VVC</th><td align=right> 30</td></tr>
<tr><th>YM</th><td align=right> 56</td></tr>
</table>Total: 25198</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Wed Apr  3 15:57:50 2013</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Jun 10 09:28:30 2013</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table>
<tr><th>CAS</th><td align=right>719128</td></tr>
<tr><th>CDA</th><td align=right>101882</td></tr>
<tr><th>CHSC</th><td align=right>303310</td></tr>
<tr><th>CSUSB</th><td align=right>11198</td></tr>
<tr><th>DS</th><td align=right>416023</td></tr>
<tr><th>HSC</th><td align=right>334203</td></tr>
<tr><th>HUH</th><td align=right>269757</td></tr>
<tr><th>IRVC</th><td align=right>35226</td></tr>
<tr><th>JEPS</th><td align=right>588403</td></tr>
<tr><th>JOTR</th><td align=right>21154</td></tr>
<tr><th>NY</th><td align=right>77021</td></tr>
<tr><th>OBI</th><td align=right>142600</td></tr>
<tr><th>PGM</th><td align=right>33572</td></tr>
<tr><th>POM</th><td align=right>430752</td></tr>
<tr><th>RSA</th><td align=right>1750198</td></tr>
<tr><th>SBBG</th><td align=right>478486</td></tr>
<tr><th>SCFS</th><td align=right>4565</td></tr>
<tr><th>SD</th><td align=right>656522</td></tr>
<tr><th>SDSU</th><td align=right>87757</td></tr>
<tr><th>SFV</th><td align=right>43176</td></tr>
<tr><th>SJSU</th><td align=right>41446</td></tr>
<tr><th>UC</th><td align=right>1376853</td></tr>
<tr><th>UCD</th><td align=right>374771</td></tr>
<tr><th>UCR</th><td align=right>761870</td></tr>
<tr><th>UCSB</th><td align=right>96983</td></tr>
<tr><th>UCSC</th><td align=right>37888</td></tr>
<tr><th>VVC</th><td align=right>11505</td></tr>
<tr><th>YM</th><td align=right>129</td></tr>
</table>Total: 9206383 in 104392 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 2993</td></tr>
<tr><th>CDA</th><td align=right> 684</td></tr>
<tr><th>CHSC</th><td align=right> 2961</td></tr>
<tr><th>CSUSB</th><td align=right> 12</td></tr>
<tr><th>DS</th><td align=right> 1272</td></tr>
<tr><th>HSC</th><td align=right> 745</td></tr>
<tr><th>HUH</th><td align=right> 992</td></tr>
<tr><th>IRVC</th><td align=right> 78</td></tr>
<tr><th>JEPS</th><td align=right> 4937</td></tr>
<tr><th>JOTR</th><td align=right> 88</td></tr>
<tr><th>NY</th><td align=right> 215</td></tr>
<tr><th>OBI</th><td align=right> 1996</td></tr>
<tr><th>PGM</th><td align=right> 100</td></tr>
<tr><th>POM</th><td align=right> 1434</td></tr>
<tr><th>RSA</th><td align=right> 5994</td></tr>
<tr><th>SBBG</th><td align=right> 2518</td></tr>
<tr><th>SCFS</th><td align=right> 3</td></tr>
<tr><th>SD</th><td align=right> 1402</td></tr>
<tr><th>SDSU</th><td align=right> 213</td></tr>
<tr><th>SFV</th><td align=right> 295</td></tr>
<tr><th>SJSU</th><td align=right> 204</td></tr>
<tr><th>UC</th><td align=right> 7996</td></tr>
<tr><th>UCD</th><td align=right> 1777</td></tr>
<tr><th>UCR</th><td align=right> 2854</td></tr>
<tr><th>UCSB</th><td align=right> 1433</td></tr>
<tr><th>UCSC</th><td align=right> 130</td></tr>
<tr><th>VVC</th><td align=right> 57</td></tr>
<tr><th>YM</th><td align=right> 129</td></tr>
</table>Total: 43512</td></tr></table>




<table border=1 cellpadding=5><tr><td align="center">

<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sun Jan 20 20:57:27 2013</tt></td></tr>
<tr><td>To:</td><td><tt>Wed Apr  3 15:53:59 2013</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>504623</td></tr>
<tr><th>CDA</th><td align=right>78097</td></tr>
<tr><th>CHSC</th><td align=right>315317</td></tr>
<tr><th>CSUSB</th><td align=right>10936</td></tr>
<tr><th>DS</th><td align=right>322735</td></tr>
<tr><th>HSC</th><td align=right>245457</td></tr>
<tr><th>HUH</th><td align=right>229699</td></tr>
<tr><th>IRVC</th><td align=right>22294</td></tr>
<tr><th>JEPS</th><td align=right>483857</td></tr>
<tr><th>JOTR</th><td align=right>12951</td></tr>
<tr><th>NY</th><td align=right>54828</td></tr>
<tr><th>OBI</th><td align=right>58524</td></tr>
<tr><th>PGM</th><td align=right>46807</td></tr>
<tr><th>POM</th><td align=right>357722</td></tr>
<tr><th>RSA</th><td align=right>1421929</td></tr>
<tr><th>SBBG</th><td align=right>415896</td></tr>
<tr><th>SCFS</th><td align=right>3614</td></tr>
<tr><th>SD</th><td align=right>465098</td></tr>
<tr><th>SDSU</th><td align=right>64973</td></tr>
<tr><th>SFV</th><td align=right>37617</td></tr>
<tr><th>SJSU</th><td align=right>35496</td></tr>
<tr><th>UC</th><td align=right>1171277</td></tr>
<tr><th>UCD</th><td align=right>305632</td></tr>
<tr><th>UCR</th><td align=right>645552</td></tr>
<tr><th>UCSB</th><td align=right>68936</td></tr>
<tr><th>UCSC</th><td align=right>21931</td></tr>
<tr><th>VVC</th><td align=right>11560</td></tr>
<tr><th>YM</th><td align=right>61</td></tr>
</table>Total: 7413420 in 81335 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 1880</td></tr>
<tr><th>CDA</th><td align=right> 561</td></tr>
<tr><th>CHSC</th><td align=right> 1551</td></tr>
<tr><th>CSUSB</th><td align=right> 10</td></tr>
<tr><th>DS</th><td align=right> 980</td></tr>
<tr><th>HSC</th><td align=right> 551</td></tr>
<tr><th>HUH</th><td align=right> 1190</td></tr>
<tr><th>IRVC</th><td align=right> 61</td></tr>
<tr><th>JEPS</th><td align=right> 2979</td></tr>
<tr><th>JOTR</th><td align=right> 74</td></tr>
<tr><th>NY</th><td align=right> 209</td></tr>
<tr><th>OBI</th><td align=right> 150</td></tr>
<tr><th>PGM</th><td align=right> 123</td></tr>
<tr><th>POM</th><td align=right> 1364</td></tr>
<tr><th>RSA</th><td align=right> 6343</td></tr>
<tr><th>SBBG</th><td align=right> 1864</td></tr>
<tr><th>SCFS</th><td align=right> 1</td></tr>
<tr><th>SD</th><td align=right> 1490</td></tr>
<tr><th>SDSU</th><td align=right> 452</td></tr>
<tr><th>SFV</th><td align=right> 183</td></tr>
<tr><th>SJSU</th><td align=right> 98</td></tr>
<tr><th>UC</th><td align=right> 4646</td></tr>
<tr><th>UCD</th><td align=right> 1312</td></tr>
<tr><th>UCR</th><td align=right> 3247</td></tr>
<tr><th>UCSB</th><td align=right> 168</td></tr>
<tr><th>UCSC</th><td align=right> 168</td></tr>
<tr><th>VVC</th><td align=right> 52</td></tr>
<tr><th>YM</th><td align=right> 61</td></tr>
</table>Total: 31768</td></tr></table>


<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Dec  3 19:28:42 2012</tt></td></tr>
<tr><td>To:</td><td><tt>Sun Jan 20 20:52:54 2013</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table>
<tr><th>CAS</th><td align=right>347571</td></tr>
<tr><th>CDA</th><td align=right>54202</td></tr>
<tr><th>CHSC</th><td align=right>193673</td></tr>
<tr><th>CSUSB</th><td align=right>5706</td></tr>
<tr><th>DS</th><td align=right>211605</td></tr>
<tr><th>HSC</th><td align=right>250397</td></tr>
<tr><th>HUH</th><td align=right>109443</td></tr>
<tr><th>IRVC</th><td align=right>16859</td></tr>
<tr><th>JEPS</th><td align=right>353122</td></tr>
<tr><th>JOTR</th><td align=right>17322</td></tr>
<tr><th>NY</th><td align=right>39376</td></tr>
<tr><th>OBI</th><td align=right>42206</td></tr>
<tr><th>PGM</th><td align=right>17349</td></tr>
<tr><th>POM</th><td align=right>256584</td></tr>
<tr><th>RSA</th><td align=right>939505</td></tr>
<tr><th>SBBG</th><td align=right>245972</td></tr>
<tr><th>SCFS</th><td align=right>3911</td></tr>
<tr><th>SD</th><td align=right>388368</td></tr>
<tr><th>SDSU</th><td align=right>39731</td></tr>
<tr><th>SJSU</th><td align=right>25014</td></tr>
<tr><th>U</th><td align=right>7</td></tr>
<tr><th>UC</th><td align=right>775514</td></tr>
<tr><th>UCD</th><td align=right>186675</td></tr>
<tr><th>UCR</th><td align=right>440697</td></tr>
<tr><th>UCSB</th><td align=right>49313</td></tr>
<tr><th>UCSC</th><td align=right>20558</td></tr>
<tr><th>UD</th><td align=right>2</td></tr>
<tr><th>VVC</th><td align=right>6588</td></tr>
<tr><th>YM</th><td align=right>89</td></tr>
</table>Total: 5037382 in 41779 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 1255</td></tr>
<tr><th>CDA</th><td align=right> 357</td></tr>
<tr><th>CHSC</th><td align=right> 1390</td></tr>
<tr><th>CSUSB</th><td align=right> 3</td></tr>
<tr><th>DS</th><td align=right> 769</td></tr>
<tr><th>HSC</th><td align=right> 401</td></tr>
<tr><th>HUH</th><td align=right> 458</td></tr>
<tr><th>IRVC</th><td align=right> 43</td></tr>
<tr><th>JEPS</th><td align=right> 1628</td></tr>
<tr><th>JOTR</th><td align=right> 59</td></tr>
<tr><th>NY</th><td align=right> 104</td></tr>
<tr><th>OBI</th><td align=right> 63</td></tr>
<tr><th>PGM</th><td align=right> 26</td></tr>
<tr><th>POM</th><td align=right> 570</td></tr>
<tr><th>RSA</th><td align=right> 2382</td></tr>
<tr><th>SBBG</th><td align=right> 1129</td></tr>
<tr><th>SCFS</th><td align=right> 1</td></tr>
<tr><th>SD</th><td align=right> 820</td></tr>
<tr><th>SDSU</th><td align=right> 128</td></tr>
<tr><th>SJSU</th><td align=right> 81</td></tr>
<tr><th>UC</th><td align=right> 2240</td></tr>
<tr><th>UCD</th><td align=right> 380</td></tr>
<tr><th>UCR</th><td align=right> 1168</td></tr>
<tr><th>UCSB</th><td align=right> 120</td></tr>
<tr><th>UCSC</th><td align=right> 149</td></tr>
<tr><th>VVC</th><td align=right> 45</td></tr>
<tr><th>YM</th><td align=right> 89</td></tr>
</table>Total: 15858</td></tr></table>


<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sat Oct 13 14:51:35 2012</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Dec  3 19:23:09 2012</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>329055</td></tr>
<tr><th>CDA</th><td align=right>63941</td></tr>
<tr><th>CHSC</th><td align=right>372571</td></tr>
<tr><th>CSUSB</th><td align=right>4813</td></tr>
<tr><th>DS</th><td align=right>172136</td></tr>
<tr><th>HSC</th><td align=right>191996</td></tr>
<tr><th>HUH</th><td align=right>127737</td></tr>
<tr><th>IRVC</th><td align=right>17040</td></tr>
<tr><th>JEPS</th><td align=right>338648</td></tr>
<tr><th>JOTR</th><td align=right>12148</td></tr>
<tr><th>NY</th><td align=right>42010</td></tr>
<tr><th>OBI</th><td align=right>46104</td></tr>
<tr><th>PGM</th><td align=right>21110</td></tr>
<tr><th>POM</th><td align=right>260906</td></tr>
<tr><th>RSA</th><td align=right>981039</td></tr>
<tr><th>SBBG</th><td align=right>250167</td></tr>
<tr><th>SCFS</th><td align=right>1312</td></tr>
<tr><th>SD</th><td align=right>416682</td></tr>
<tr><th>SDSU</th><td align=right>48580</td></tr>
<tr><th>SJSU</th><td align=right>22629</td></tr>
<tr><th>UC</th><td align=right>831310</td></tr>
<tr><th>UCD</th><td align=right>283591</td></tr>
<tr><th>UCR</th><td align=right>509022</td></tr>
<tr><th>UCSB</th><td align=right>52741</td></tr>
<tr><th>UCSC</th><td align=right>19315</td></tr>
<tr><th>VVC</th><td align=right>16327</td></tr>
<tr><th>YM</th><td align=right>104</td></tr>
</table>Total: 5433034 in 70154 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 1410</td></tr>
<tr><th>CDA</th><td align=right> 369</td></tr>
<tr><th>CHSC</th><td align=right> 1427</td></tr>
<tr><th>CSUSB</th><td align=right> 15</td></tr>
<tr><th>DS</th><td align=right> 619</td></tr>
<tr><th>HSC</th><td align=right> 591</td></tr>
<tr><th>HUH</th><td align=right> 491</td></tr>
<tr><th>IRVC</th><td align=right> 53</td></tr>
<tr><th>JEPS</th><td align=right> 2740</td></tr>
<tr><th>JOTR</th><td align=right> 122</td></tr>
<tr><th>NY</th><td align=right> 128</td></tr>
<tr><th>OBI</th><td align=right> 464</td></tr>
<tr><th>PGM</th><td align=right> 102</td></tr>
<tr><th>POM</th><td align=right> 962</td></tr>
<tr><th>RSA</th><td align=right> 3466</td></tr>
<tr><th>SBBG</th><td align=right> 4485</td></tr>
<tr><th>SCFS</th><td align=right> 5</td></tr>
<tr><th>SD</th><td align=right> 1151</td></tr>
<tr><th>SDSU</th><td align=right> 176</td></tr>
<tr><th>SJSU</th><td align=right> 151</td></tr>
<tr><th>UC</th><td align=right> 3708</td></tr>
<tr><th>UCD</th><td align=right> 1063</td></tr>
<tr><th>UCR</th><td align=right> 1728</td></tr>
<tr><th>UCSB</th><td align=right> 322</td></tr>
<tr><th>UCSC</th><td align=right> 94</td></tr>
<tr><th>VVC</th><td align=right> 61</td></tr>
<tr><th>YM</th><td align=right> 104</td></tr>
</table>Total: 26007</td></tr></table>


<table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri Aug 17 09:28:16 2012</tt></td></tr>
<tr><td>To:</td><td><tt>Sat Oct 13 14:48:40 2012</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>380025</td></tr>
<tr><th>CDA</th><td align=right>73473</td></tr>
<tr><th>CHSC</th><td align=right>173708</td></tr>
<tr><th>CSUSB</th><td align=right>8509</td></tr>
<tr><th>DS</th><td align=right>239099</td></tr>
<tr><th>HSC</th><td align=right>195068</td></tr>
<tr><th>HUH</th><td align=right>143642</td></tr>
<tr><th>IRVC</th><td align=right>29255</td></tr>
<tr><th>JEPS</th><td align=right>363110</td></tr>
<tr><th>JOTR</th><td align=right>27307</td></tr>
<tr><th>NY</th><td align=right>70177</td></tr>
<tr><th>OBI</th><td align=right>41528</td></tr>
<tr><th>PGM</th><td align=right>25685</td></tr>
<tr><th>POM</th><td align=right>329515</td></tr>
<tr><th>RSA</th><td align=right>1195039</td></tr>
<tr><th>SBBG</th><td align=right>333859</td></tr>
<tr><th>SCFS</th><td align=right>2857</td></tr>
<tr><th>SD</th><td align=right>356230</td></tr>
<tr><th>SDSU</th><td align=right>53431</td></tr>
<tr><th>SJSU</th><td align=right>26311</td></tr>
<tr><th>UC</th><td align=right>1006248</td></tr>
<tr><th>UCD</th><td align=right>224134</td></tr>
<tr><th>UCR</th><td align=right>520900</td></tr>
<tr><th>UCSB</th><td align=right>49325</td></tr>
<tr><th>UCSC</th><td align=right>15401</td></tr>
<tr><th>YM</th><td align=right>29</td></tr>
</table>Total: 5883870 in 66518 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 1179</td></tr>
<tr><th>CDA</th><td align=right> 421</td></tr>
<tr><th>CHSC</th><td align=right> 1645</td></tr>
<tr><th>CSUSB</th><td align=right> 71</td></tr>
<tr><th>DS</th><td align=right> 639</td></tr>
<tr><th>HSC</th><td align=right> 667</td></tr>
<tr><th>HUH</th><td align=right> 472</td></tr>
<tr><th>IRVC</th><td align=right> 117</td></tr>
<tr><th>JEPS</th><td align=right> 2954</td></tr>
<tr><th>JOTR</th><td align=right> 43</td></tr>
<tr><th>NY</th><td align=right> 202</td></tr>
<tr><th>OBI</th><td align=right> 175</td></tr>
<tr><th>PGM</th><td align=right> 181</td></tr>
<tr><th>POM</th><td align=right> 1593</td></tr>
<tr><th>RSA</th><td align=right> 5791</td></tr>
<tr><th>SBBG</th><td align=right> 3935</td></tr>
<tr><th>SCFS</th><td align=right> 2</td></tr>
<tr><th>SD</th><td align=right> 1552</td></tr>
<tr><th>SDSU</th><td align=right> 271</td></tr>
<tr><th>SJSU</th><td align=right> 217</td></tr>
<tr><th>UC</th><td align=right> 5055</td></tr>
<tr><th>UCD</th><td align=right> 769</td></tr>
<tr><th>UCR</th><td align=right> 3446</td></tr>
<tr><th>UCSB</th><td align=right> 270</td></tr>
<tr><th>UCSC</th><td align=right> 67</td></tr>
<tr><th>YM</th><td align=right> 29</td></tr>
</table>Total: 31763</td></tr></table>



<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Wed Jul  4 10:29:30 2012</tt></td></tr>
<tr><td>To:</td><td><tt>Fri Aug 17 09:22:10 2012</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>327119</td></tr>
<tr><th>CDA</th><td align=right>77545</td></tr>
<tr><th>CHSC</th><td align=right>160910</td></tr>
<tr><th>CSUSB</th><td align=right>5543</td></tr>
<tr><th>DS</th><td align=right>192343</td></tr>
<tr><th>GMDRC</th><td align=right>10</td></tr>
<tr><th>HSC</th><td align=right>215249</td></tr>
<tr><th>HUH</th><td align=right>100100</td></tr>
<tr><th>IRVC</th><td align=right>14624</td></tr>
<tr><th>JEPS</th><td align=right>358535</td></tr>
<tr><th>NY</th><td align=right>40696</td></tr>
<tr><th>OBI</th><td align=right>40762</td></tr>
<tr><th>PGM</th><td align=right>21933</td></tr>
<tr><th>POM</th><td align=right>235684</td></tr>
<tr><th>RSA</th><td align=right>946306</td></tr>
<tr><th>S</th><td align=right>2</td></tr>
<tr><th>SBBG</th><td align=right>246351</td></tr>
<tr><th>SCFS</th><td align=right>4722</td></tr>
<tr><th>SD</th><td align=right>284822</td></tr>
<tr><th>SDSU</th><td align=right>35555</td></tr>
<tr><th>SJSU</th><td align=right>24684</td></tr>
<tr><th>UC</th><td align=right>857639</td></tr>
<tr><th>UCD</th><td align=right>204145</td></tr>
<tr><th>UCR</th><td align=right>405652</td></tr>
<tr><th>UCSB</th><td align=right>36906</td></tr>
<tr><th>UCSC</th><td align=right>11035</td></tr>
<tr><th>YM</th><td align=right>32</td></tr>
</table>Total: 4848906 in 43725 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 960</td></tr>
<tr><th>CDA</th><td align=right> 292</td></tr>
<tr><th>CHSC</th><td align=right> 945</td></tr>
<tr><th>CSUSB</th><td align=right> 13</td></tr>
<tr><th>DS</th><td align=right> 349</td></tr>
<tr><th>GMDRC</th><td align=right> 10</td></tr>
<tr><th>HSC</th><td align=right> 534</td></tr>
<tr><th>HUH</th><td align=right> 303</td></tr>
<tr><th>IRVC</th><td align=right> 81</td></tr>
<tr><th>JEPS</th><td align=right> 1710</td></tr>
<tr><th>NY</th><td align=right> 84</td></tr>
<tr><th>OBI</th><td align=right> 135</td></tr>
<tr><th>PGM</th><td align=right> 56</td></tr>
<tr><th>POM</th><td align=right> 500</td></tr>
<tr><th>RSA</th><td align=right> 2613</td></tr>
<tr><th>SBBG</th><td align=right> 872</td></tr>
<tr><th>SD</th><td align=right> 1217</td></tr>
<tr><th>SDSU</th><td align=right> 169</td></tr>
<tr><th>SJSU</th><td align=right> 76</td></tr>
<tr><th>UC</th><td align=right> 2867</td></tr>
<tr><th>UCD</th><td align=right> 551</td></tr>
<tr><th>UCR</th><td align=right> 1472</td></tr>
<tr><th>UCSB</th><td align=right> 179</td></tr>
<tr><th>UCSC</th><td align=right> 102</td></tr>
<tr><th>YM</th><td align=right> 32</td></tr>
</table>Total: 16122</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon May 28 19:12:32 2012</tt></td></tr>
<tr><td>To:</td><td><tt>Wed Jul  4 10:18:40 2012</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table>
<tr><th>CAS</th><td align=right>328211</td></tr>
<tr><th>CDA</th><td align=right>60747</td></tr>
<tr><th>CHSC</th><td align=right>156913</td></tr>
<tr><th>CSUSB</th><td align=right>6957</td></tr>
<tr><th>DS</th><td align=right>206704</td></tr>
<tr><th>HSC</th><td align=right>204988</td></tr>
<tr><th>HUH</th><td align=right>158985</td></tr>
<tr><th>IRVC</th><td align=right>18755</td></tr>
<tr><th>JEPS</th><td align=right>295781</td></tr>
<tr><th>NY</th><td align=right>62948</td></tr>
<tr><th>OBI</th><td align=right>78317</td></tr>
<tr><th>PGM</th><td align=right>15948</td></tr>
<tr><th>POM</th><td align=right>262142</td></tr>
<tr><th>RSA</th><td align=right>1054485</td></tr>
<tr><th>SBBG</th><td align=right>284522</td></tr>
<tr><th>SCFS</th><td align=right>14193</td></tr>
<tr><th>SD</th><td align=right>345985</td></tr>
<tr><th>SDSU</th><td align=right>47619</td></tr>
<tr><th>SJSU</th><td align=right>21029</td></tr>
<tr><th>UC</th><td align=right>764552</td></tr>
<tr><th>UCD</th><td align=right>189605</td></tr>
<tr><th>UCR</th><td align=right>505618</td></tr>
<tr><th>UCSB</th><td align=right>36390</td></tr>
<tr><th>UCSC</th><td align=right>13755</td></tr>
<tr><th>YM</th><td align=right>106</td></tr>
</table>Total: 5135261 in 82906 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 1873</td></tr>
<tr><th>CDA</th><td align=right> 583</td></tr>
<tr><th>CHSC</th><td align=right> 1434</td></tr>
<tr><th>CSUSB</th><td align=right> 33</td></tr>
<tr><th>DS</th><td align=right> 932</td></tr>
<tr><th>HSC</th><td align=right> 1069</td></tr>
<tr><th>HUH</th><td align=right> 505</td></tr>
<tr><th>IRVC</th><td align=right> 81</td></tr>
<tr><th>JEPS</th><td align=right> 2492</td></tr>
<tr><th>NY</th><td align=right> 654</td></tr>
<tr><th>OBI</th><td align=right> 110</td></tr>
<tr><th>PGM</th><td align=right> 56</td></tr>
<tr><th>POM</th><td align=right> 1511</td></tr>
<tr><th>RSA</th><td align=right> 5946</td></tr>
<tr><th>SBBG</th><td align=right> 1819</td></tr>
<tr><th>SCFS</th><td align=right> 9</td></tr>
<tr><th>SD</th><td align=right> 1694</td></tr>
<tr><th>SDSU</th><td align=right> 265</td></tr>
<tr><th>SJSU</th><td align=right> 86</td></tr>
<tr><th>UC</th><td align=right> 4832</td></tr>
<tr><th>UCD</th><td align=right> 1330</td></tr>
<tr><th>UCR</th><td align=right> 2622</td></tr>
<tr><th>UCSB</th><td align=right> 203</td></tr>
<tr><th>UCSC</th><td align=right> 62</td></tr>
<tr><th>YM</th><td align=right> 106</td></tr>
</table>Total: 30307</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Wed Mar 14 21:32:13 2012</tt></td></tr>
<tr><td>To:</td><td><tt>Mon May 28 19:07:52 2012</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table>
<tr><th>CAS</th><td align=right>1108369</td></tr>
<tr><th>CDA</th><td align=right>370885</td></tr>
<tr><th>CHSC</th><td align=right>1051434</td></tr>
<tr><th>CSUSB</th><td align=right>28584</td></tr>
<tr><th>DS</th><td align=right>628961</td></tr>
<tr><th>HSC</th><td align=right>961801</td></tr>
<tr><th>HUH</th><td align=right>305479</td></tr>
<tr><th>IRVC</th><td align=right>89830</td></tr>
<tr><th>JEPS</th><td align=right>1601429</td></tr>
<tr><th>NY</th><td align=right>194554</td></tr>
<tr><th>PGM</th><td align=right>111438</td></tr>
<tr><th>POM</th><td align=right>1162870</td></tr>
<tr><th>RSA</th><td align=right>4476636</td></tr>
<tr><th>SBBG</th><td align=right>1381116</td></tr>
<tr><th>SCFS</th><td align=right>11116</td></tr>
<tr><th>SD</th><td align=right>1629778</td></tr>
<tr><th>SDSU</th><td align=right>256601</td></tr>
<tr><th>SJSU</th><td align=right>127305</td></tr>
<tr><th>UC</th><td align=right>3878888</td></tr>
<tr><th>UCD</th><td align=right>1318908</td></tr>
<tr><th>UCR</th><td align=right>2344999</td></tr>
<tr><th>UCSB</th><td align=right>261502</td></tr>
<tr><th>UCSC</th><td align=right>79128</td></tr>
<tr><th>YM</th><td align=right>392</td></tr>
</table>Total: 23382009 in 352907 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 3566</td></tr>
<tr><th>CDA</th><td align=right> 2476</td></tr>
<tr><th>CHSC</th><td align=right> 6661</td></tr>
<tr><th>CSUSB</th><td align=right> 161</td></tr>
<tr><th>DS</th><td align=right> 1636</td></tr>
<tr><th>HSC</th><td align=right> 3579</td></tr>
<tr><th>HUH</th><td align=right> 568</td></tr>
<tr><th>IRVC</th><td align=right> 539</td></tr>
<tr><th>JEPS</th><td align=right> 12147</td></tr>
<tr><th>NY</th><td align=right> 2182</td></tr>
<tr><th>PGM</th><td align=right> 775</td></tr>
<tr><th>POM</th><td align=right> 6649</td></tr>
<tr><th>RSA</th><td align=right> 27492</td></tr>
<tr><th>SBBG</th><td align=right> 10300</td></tr>
<tr><th>SCFS</th><td align=right> 16</td></tr>
<tr><th>SD</th><td align=right> 10448</td></tr>
<tr><th>SDSU</th><td align=right> 1584</td></tr>
<tr><th>SJSU</th><td align=right> 898</td></tr>
<tr><th>UC</th><td align=right> 28682</td></tr>
<tr><th>UCD</th><td align=right> 8144</td></tr>
<tr><th>UCR</th><td align=right> 14481</td></tr>
<tr><th>UCSB</th><td align=right> 2207</td></tr>
<tr><th>UCSC</th><td align=right> 499</td></tr>
<tr><th>YM</th><td align=right> 392</td></tr>
</table>Total: 146082</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri Dec 30 11:35:55 2011</tt></td></tr>
<tr><td>To:</td><td><tt>Wed Mar 14 21:29:20 2012</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>438610</td></tr>
<tr><th>CDA</th><td align=right>136566</td></tr>
<tr><th>CHSC</th><td align=right>373339</td></tr>
<tr><th>CSUSB</th><td align=right>15401</td></tr>
<tr><th>DS</th><td align=right>275268</td></tr>
<tr><th>HSC</th><td align=right>333091</td></tr>
<tr><th>HUH</th><td align=right>54087</td></tr>
<tr><th>IRVC</th><td align=right>32622</td></tr>
<tr><th>JEPS</th><td align=right>553189</td></tr>
<tr><th>NY</th><td align=right>107708</td></tr>
<tr><th>PGM</th><td align=right>50369</td></tr>
<tr><th>POM</th><td align=right>411132</td></tr>
<tr><th>RSA</th><td align=right>1612254</td></tr>
<tr><th>SBBG</th><td align=right>511360</td></tr>
<tr><th>SCFS</th><td align=right>11620</td></tr>
<tr><th>SD</th><td align=right>619268</td></tr>
<tr><th>SDSU</th><td align=right>87839</td></tr>
<tr><th>SJSU</th><td align=right>37774</td></tr>
<tr><th>UC</th><td align=right>1421882</td></tr>
<tr><th>UCD</th><td align=right>306118</td></tr>
<tr><th>UCR</th><td align=right>820878</td></tr>
<tr><th>UCSB</th><td align=right>77195</td></tr>
<tr><th>UCSC</th><td align=right>29020</td></tr>
<tr><th>YM</th><td align=right>96</td></tr>
</table>Total: 8316688 in 111722 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 2197</td></tr>
<tr><th>CDA</th><td align=right> 838</td></tr>
<tr><th>CHSC</th><td align=right> 3398</td></tr>
<tr><th>CSUSB</th><td align=right> 34</td></tr>
<tr><th>DS</th><td align=right> 1491</td></tr>
<tr><th>HSC</th><td align=right> 1886</td></tr>
<tr><th>HUH</th><td align=right> 211</td></tr>
<tr><th>IRVC</th><td align=right> 152</td></tr>
<tr><th>JEPS</th><td align=right> 5429</td></tr>
<tr><th>NY</th><td align=right> 699</td></tr>
<tr><th>PGM</th><td align=right> 102</td></tr>
<tr><th>POM</th><td align=right> 1395</td></tr>
<tr><th>RSA</th><td align=right> 6580</td></tr>
<tr><th>SBBG</th><td align=right> 2688</td></tr>
<tr><th>SCFS</th><td align=right> 14</td></tr>
<tr><th>SD</th><td align=right> 3501</td></tr>
<tr><th>SDSU</th><td align=right> 403</td></tr>
<tr><th>SJSU</th><td align=right> 140</td></tr>
<tr><th>UC</th><td align=right> 10696</td></tr>
<tr><th>UCD</th><td align=right> 1894</td></tr>
<tr><th>UCR</th><td align=right> 4799</td></tr>
<tr><th>UCSB</th><td align=right> 264</td></tr>
<tr><th>UCSC</th><td align=right> 88</td></tr>
<tr><th>YM</th><td align=right> 96</td></tr>
</table>Total: 48995</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri Oct 28 20:16:50 2011</tt></td></tr>
<tr><td>To:</td><td><tt>Fri Dec 30 11:26:36 2011</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>349139</td></tr>
<tr><th>CDA</th><td align=right>120638</td></tr>
<tr><th>CHSC</th><td align=right>158521</td></tr>
<tr><th>CSUSB</th><td align=right>15993</td></tr>
<tr><th>DS</th><td align=right>281548</td></tr>
<tr><th>HSC</th><td align=right>169580</td></tr>
<tr><th>HUH</th><td align=right>15133</td></tr>
<tr><th>IRVC</th><td align=right>24907</td></tr>
<tr><th>JEPS</th><td align=right>308605</td></tr>
<tr><th>NY</th><td align=right>50897</td></tr>
<tr><th>PGM</th><td align=right>16846</td></tr>
<tr><th>POM</th><td align=right>260473</td></tr>
<tr><th>RSA</th><td align=right>1012804</td></tr>
<tr><th>SBBG</th><td align=right>259385</td></tr>
<tr><th>SD</th><td align=right>374613</td></tr>
<tr><th>SDSU</th><td align=right>56437</td></tr>
<tr><th>SJSU</th><td align=right>20877</td></tr>
<tr><th>UC</th><td align=right>771314</td></tr>
<tr><th>UCD</th><td align=right>132436</td></tr>
<tr><th>UCR</th><td align=right>540419</td></tr>
<tr><th>UCSB</th><td align=right>40039</td></tr>
<tr><th>UCSC</th><td align=right>12204</td></tr>
<tr><th>YM</th><td align=right>44</td></tr>
</table>Total: 4992852 in 55798 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 659</td></tr>
<tr><th>CDA</th><td align=right> 447</td></tr>
<tr><th>CHSC</th><td align=right> 1160</td></tr>
<tr><th>CSUSB</th><td align=right> 19</td></tr>
<tr><th>DS</th><td align=right> 301</td></tr>
<tr><th>HSC</th><td align=right> 296</td></tr>
<tr><th>HUH</th><td align=right> 116</td></tr>
<tr><th>IRVC</th><td align=right> 106</td></tr>
<tr><th>JEPS</th><td align=right> 2138</td></tr>
<tr><th>NY</th><td align=right> 200</td></tr>
<tr><th>PGM</th><td align=right> 55</td></tr>
<tr><th>POM</th><td align=right> 901</td></tr>
<tr><th>RSA</th><td align=right> 4241</td></tr>
<tr><th>SBBG</th><td align=right> 1043</td></tr>
<tr><th>SD</th><td align=right> 2811</td></tr>
<tr><th>SDSU</th><td align=right> 438</td></tr>
<tr><th>SJSU</th><td align=right> 89</td></tr>
<tr><th>UC</th><td align=right> 3697</td></tr>
<tr><th>UCD</th><td align=right> 430</td></tr>
<tr><th>UCR</th><td align=right> 2763</td></tr>
<tr><th>UCSB</th><td align=right> 99</td></tr>
<tr><th>UCSC</th><td align=right> 70</td></tr>
<tr><th>YM</th><td align=right> 44</td></tr>
</table>Total: 22123</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri Aug 26 14:45:56 2011</tt></td></tr>
<tr><td>To:</td><td><tt>Fri Oct 28 20:13:56 2011</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>187508</td></tr>
<tr><th>CDA</th><td align=right>87528</td></tr>
<tr><th>CHSC</th><td align=right>211497</td></tr>
<tr><th>CSUSB</th><td align=right>11552</td></tr>
<tr><th>DS</th><td align=right>116638</td></tr>
<tr><th>HSC</th><td align=right>138075</td></tr>
<tr><th>HUH</th><td align=right>7567</td></tr>
<tr><th>IRVC</th><td align=right>19623</td></tr>
<tr><th>JEPS</th><td align=right>464403</td></tr>
<tr><th>NY</th><td align=right>64064</td></tr>
<tr><th>PGM</th><td align=right>26396</td></tr>
<tr><th>POM</th><td align=right>276942</td></tr>
<tr><th>RSA</th><td align=right>1122454</td></tr>
<tr><th>SBBG</th><td align=right>384079</td></tr>
<tr><th>SD</th><td align=right>454908</td></tr>
<tr><th>SDSU</th><td align=right>65179</td></tr>
<tr><th>SJSU</th><td align=right>37369</td></tr>
<tr><th>UC</th><td align=right>1242817</td></tr>
<tr><th>UCD</th><td align=right>199250</td></tr>
<tr><th>UCR</th><td align=right>609321</td></tr>
<tr><th>UCSB</th><td align=right>46017</td></tr>
<tr><th>UCSC</th><td align=right>36021</td></tr>
<tr><th>YM</th><td align=right>36</td></tr>
</table>Total: 5809246 in 67322 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 767</td></tr>
<tr><th>CDA</th><td align=right> 464</td></tr>
<tr><th>CHSC</th><td align=right> 1403</td></tr>
<tr><th>CSUSB</th><td align=right> 15</td></tr>
<tr><th>DS</th><td align=right> 309</td></tr>
<tr><th>HSC</th><td align=right> 372</td></tr>
<tr><th>HUH</th><td align=right> 86</td></tr>
<tr><th>IRVC</th><td align=right> 81</td></tr>
<tr><th>JEPS</th><td align=right> 2580</td></tr>
<tr><th>NY</th><td align=right> 239</td></tr>
<tr><th>PGM</th><td align=right> 83</td></tr>
<tr><th>POM</th><td align=right> 889</td></tr>
<tr><th>RSA</th><td align=right> 3910</td></tr>
<tr><th>SBBG</th><td align=right> 1137</td></tr>
<tr><th>SD</th><td align=right> 2296</td></tr>
<tr><th>SDSU</th><td align=right> 685</td></tr>
<tr><th>SJSU</th><td align=right> 103</td></tr>
<tr><th>UC</th><td align=right> 4759</td></tr>
<tr><th>UCD</th><td align=right> 806</td></tr>
<tr><th>UCR</th><td align=right> 2148</td></tr>
<tr><th>UCSB</th><td align=right> 150</td></tr>
<tr><th>UCSC</th><td align=right> 115</td></tr>
<tr><th>YM</th><td align=right> 36</td></tr>
</table>Total: 23433</td></tr></table>



<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Wed Jun  8 20:09:58 2011</tt></td></tr>
<tr><td>To:</td><td><tt>Fri Aug 26 14:42:11 2011</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>240326</td></tr>
<tr><th>CDA</th><td align=right>81038</td></tr>
<tr><th>CHSC</th><td align=right>242697</td></tr>
<tr><th>CSUSB</th><td align=right>9449</td></tr>
<tr><th>DS</th><td align=right>134921</td></tr>
<tr><th>HSC</th><td align=right>138179</td></tr>
<tr><th>IRVC</th><td align=right>22723</td></tr>
<tr><th>JEPS</th><td align=right>433960</td></tr>
<tr><th>NY</th><td align=right>70491</td></tr>
<tr><th>PGM</th><td align=right>32198</td></tr>
<tr><th>POM</th><td align=right>311501</td></tr>
<tr><th>RSA</th><td align=right>1228301</td></tr>
<tr><th>SBBG</th><td align=right>377794</td></tr>
<tr><th>SD</th><td align=right>333353</td></tr>
<tr><th>SDSU</th><td align=right>56944</td></tr>
<tr><th>SJSU</th><td align=right>33314</td></tr>
<tr><th>UC</th><td align=right>1116968</td></tr>
<tr><th>UCD</th><td align=right>176570</td></tr>
<tr><th>UCR</th><td align=right>665557</td></tr>
<tr><th>UCSB</th><td align=right>54167</td></tr>
<tr><th>UCSC</th><td align=right>25904</td></tr>
</table>Total: 5786355 in 78349 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 1139</td></tr>
<tr><th>CDA</th><td align=right> 694</td></tr>
<tr><th>CHSC</th><td align=right> 1787</td></tr>
<tr><th>CSUSB</th><td align=right> 8</td></tr>
<tr><th>DS</th><td align=right> 431</td></tr>
<tr><th>HSC</th><td align=right> 498</td></tr>
<tr><th>IRVC</th><td align=right> 131</td></tr>
<tr><th>JEPS</th><td align=right> 4152</td></tr>
<tr><th>NY</th><td align=right> 416</td></tr>
<tr><th>PGM</th><td align=right> 173</td></tr>
<tr><th>POM</th><td align=right> 1100</td></tr>
<tr><th>RSA</th><td align=right> 5109</td></tr>
<tr><th>SBBG</th><td align=right> 2018</td></tr>
<tr><th>SD</th><td align=right> 1858</td></tr>
<tr><th>SDSU</th><td align=right> 206</td></tr>
<tr><th>SJSU</th><td align=right> 196</td></tr>
<tr><th>UC</th><td align=right> 6728</td></tr>
<tr><th>UCD</th><td align=right> 1061</td></tr>
<tr><th>UCR</th><td align=right> 2794</td></tr>
<tr><th>UCSB</th><td align=right> 235</td></tr>
<tr><th>UCSC</th><td align=right> 152</td></tr>
</table>Total: 30886</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Fri Mar 25 09:56:42 2011</tt></td></tr>
<tr><td>To:</td><td><tt>Wed Jun  8 20:07:23 2011</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>151332</td></tr>

<tr><th>CDA</th><td align=right>100063</td></tr>
<tr><th>CHSC</th><td align=right>287831</td></tr>
<tr><th>DS</th><td align=right>75623</td></tr>
<tr><th>HSC</th><td align=right>164308</td></tr>
<tr><th>IRVC</th><td align=right>34688</td></tr>
<tr><th>JEPS</th><td align=right>510653</td></tr>
<tr><th>NY</th><td align=right>83829</td></tr>
<tr><th>PGM</th><td align=right>39122</td></tr>
<tr><th>POM</th><td align=right>348879</td></tr>
<tr><th>RSA</th><td align=right>1462494</td></tr>
<tr><th>SBBG</th><td align=right>444007</td></tr>
<tr><th>SD</th><td align=right>535003</td></tr>
<tr><th>SDSU</th><td align=right>103079</td></tr>
<tr><th>SJSU</th><td align=right>39336</td></tr>
<tr><th>UC</th><td align=right>1278723</td></tr>
<tr><th>UCD</th><td align=right>245084</td></tr>
<tr><th>UCR</th><td align=right>808055</td></tr>
<tr><th>UCSB</th><td align=right>88790</td></tr>
<tr><th>UCSC</th><td align=right>23244</td></tr>
</table>Total: 6824144 in 89864 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 1247</td></tr>
<tr><th>CDA</th><td align=right> 923</td></tr>
<tr><th>CHSC</th><td align=right> 1982</td></tr>
<tr><th>DS</th><td align=right> 521</td></tr>
<tr><th>HSC</th><td align=right> 1055</td></tr>
<tr><th>IRVC</th><td align=right> 144</td></tr>
<tr><th>JEPS</th><td align=right> 4320</td></tr>

<tr><th>NY</th><td align=right> 519</td></tr>
<tr><th>PGM</th><td align=right> 107</td></tr>
<tr><th>POM</th><td align=right> 897</td></tr>
<tr><th>RSA</th><td align=right> 4790</td></tr>
<tr><th>SBBG</th><td align=right> 1387</td></tr>
<tr><th>SD</th><td align=right> 1803</td></tr>
<tr><th>SDSU</th><td align=right> 429</td></tr>
<tr><th>SJSU</th><td align=right> 226</td></tr>
<tr><th>UC</th><td align=right> 7277</td></tr>
<tr><th>UCD</th><td align=right> 1279</td></tr>
<tr><th>UCR</th><td align=right> 3779</td></tr>
<tr><th>UCSB</th><td align=right> 231</td></tr>
<tr><th>UCSC</th><td align=right> 134</td></tr>
</table>Total: 33050</td></tr></table>


<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Thu Feb 10 10:56:27 2011</tt></td></tr>
<tr><td>To:</td><td><tt>Fri Mar 25 09:50:22 2011</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>109115</td></tr>
<tr><th>CDA</th><td align=right>57637</td></tr>
<tr><th>CHSC</th><td align=right>151843</td></tr>
<tr><th>DS</th><td align=right>62220</td></tr>
<tr><th>HSC</th><td align=right>100500</td></tr>
<tr><th>IRVC</th><td align=right>16889</td></tr>
<tr><th>JEPS</th><td align=right>310463</td></tr>
<tr><th>NY</th><td align=right>56771</td></tr>
<tr><th>PGM</th><td align=right>24575</td></tr>
<tr><th>POM</th><td align=right>252665</td></tr>
<tr><th>RSA</th><td align=right>812423</td></tr>
<tr><th>SBBG</th><td align=right>232406</td></tr>
<tr><th>SD</th><td align=right>233458</td></tr>

<tr><th>SDSU</th><td align=right>37134</td></tr>
<tr><th>SJSU</th><td align=right>24221</td></tr>
<tr><th>UC</th><td align=right>849465</td></tr>
<tr><th>UCD</th><td align=right>106758</td></tr>
<tr><th>UCR</th><td align=right>520174</td></tr>
<tr><th>UCSB</th><td align=right>39348</td></tr>

<tr><th>UCSC</th><td align=right>23579</td></tr>
</table>Total: 4021644 in 45557 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 497</td></tr>
<tr><th>CDA</th><td align=right> 621</td></tr>
<tr><th>CHSC</th><td align=right> 1255</td></tr>

<tr><th>DS</th><td align=right> 187</td></tr>
<tr><th>HSC</th><td align=right> 390</td></tr>
<tr><th>IRVC</th><td align=right> 94</td></tr>
<tr><th>JEPS</th><td align=right> 2152</td></tr>
<tr><th>NY</th><td align=right> 206</td></tr>

<tr><th>PGM</th><td align=right> 57</td></tr>
<tr><th>POM</th><td align=right> 442</td></tr>
<tr><th>RSA</th><td align=right> 2881</td></tr>
<tr><th>SBBG</th><td align=right> 722</td></tr>
<tr><th>SD</th><td align=right> 1098</td></tr>

<tr><th>SDSU</th><td align=right> 203</td></tr>
<tr><th>SJSU</th><td align=right> 122</td></tr>
<tr><th>UC</th><td align=right> 3555</td></tr>
<tr><th>UCD</th><td align=right> 442</td></tr>
<tr><th>UCR</th><td align=right> 1994</td></tr>

<tr><th>UCSB</th><td align=right> 97</td></tr>
<tr><th>UCSC</th><td align=right> 38</td></tr>
</table>Total: 17053</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sun Dec 19 18:22:57 2010</tt></td></tr>
<tr><td>To:</td><td><tt>Thu Feb 10 10:50:12 2011</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>49826</td></tr>

<tr><th>CDA</th><td align=right>45349</td></tr>
<tr><th>CHSC</th><td align=right>212378</td></tr>
<tr><th>DS</th><td align=right>28006</td></tr>
<tr><th>HSC</th><td align=right>108343</td></tr>
<tr><th>IRVC</th><td align=right>14222</td></tr>
<tr><th>JEPS</th><td align=right>300952</td></tr>

<tr><th>NY</th><td align=right>38235</td></tr>
<tr><th>PGM</th><td align=right>18212</td></tr>
<tr><th>POM</th><td align=right>235616</td></tr>
<tr><th>RSA</th><td align=right>654137</td></tr>
<tr><th>SBBG</th><td align=right>179811</td></tr>
<tr><th>SD</th><td align=right>280660</td></tr>

<tr><th>SDSU</th><td align=right>39227</td></tr>
<tr><th>SJSU</th><td align=right>20563</td></tr>
<tr><th>UC</th><td align=right>774750</td></tr>
<tr><th>UCD</th><td align=right>102829</td></tr>
<tr><th>UCR</th><td align=right>384064</td></tr>
<tr><th>UCSB</th><td align=right>28562</td></tr>

<tr><th>UCSC</th><td align=right>11764</td></tr>
</table>Total: 3527506 in 36985 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 208</td></tr>
<tr><th>CDA</th><td align=right> 262</td></tr>
<tr><th>CHSC</th><td align=right> 879</td></tr>

<tr><th>DS</th><td align=right> 56</td></tr>
<tr><th>HSC</th><td align=right> 245</td></tr>
<tr><th>IRVC</th><td align=right> 74</td></tr>
<tr><th>JEPS</th><td align=right> 1753</td></tr>
<tr><th>NY</th><td align=right> 129</td></tr>

<tr><th>PGM</th><td align=right> 57</td></tr>
<tr><th>POM</th><td align=right> 334</td></tr>
<tr><th>RSA</th><td align=right> 1725</td></tr>
<tr><th>SBBG</th><td align=right> 564</td></tr>
<tr><th>SD</th><td align=right> 961</td></tr>

<tr><th>SDSU</th><td align=right> 118</td></tr>
<tr><th>SJSU</th><td align=right> 40</td></tr>
<tr><th>UC</th><td align=right> 2657</td></tr>
<tr><th>UCD</th><td align=right> 390</td></tr>
<tr><th>UCR</th><td align=right> 1346</td></tr>

<tr><th>UCSB</th><td align=right> 109</td></tr>
<tr><th>UCSC</th><td align=right> 40</td></tr>
</table>Total: 11947</td></tr></table>




<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Tue Oct 19 21:41:16 2010</tt></td></tr>
<tr><td>To:</td><td><tt>Sun Dec 19 18:17:27 2010</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>79439</td></tr>

<tr><th>CDA</th><td align=right>46464</td></tr>
<tr><th>CHS</th><td align=right>2</td></tr>
<tr><th>CHSC</th><td align=right>141698</td></tr>
<tr><th>DS</th><td align=right>48142</td></tr>
<tr><th>HSC</th><td align=right>86211</td></tr>
<tr><th>IRVC</th><td align=right>24860</td></tr>

<tr><th>JEPS</th><td align=right>286810</td></tr>
<tr><th>NY</th><td align=right>50179</td></tr>
<tr><th>PGM</th><td align=right>21468</td></tr>
<tr><th>POM</th><td align=right>240174</td></tr>
<tr><th>RSA</th><td align=right>962528</td></tr>

<tr><th>SBBG</th><td align=right>196784</td></tr>
<tr><th>SD</th><td align=right>387396</td></tr>
<tr><th>SDSU</th><td align=right>66316</td></tr>
<tr><th>SJSU</th><td align=right>21234</td></tr>
<tr><th>UC</th><td align=right>885311</td></tr>
<tr><th>UCD</th><td align=right>102140</td></tr>

<tr><th>UCR</th><td align=right>602223</td></tr>
<tr><th>UCSB</th><td align=right>40497</td></tr>
<tr><th>UCSC</th><td align=right>17742</td></tr>
</table>Total: 4307619 in 50570 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 261</td></tr>
<tr><th>CDA</th><td align=right> 323</td></tr>

<tr><th>CHSC</th><td align=right> 872</td></tr>
<tr><th>DS</th><td align=right> 137</td></tr>
<tr><th>HSC</th><td align=right> 196</td></tr>
<tr><th>IRVC</th><td align=right> 89</td></tr>
<tr><th>JEPS</th><td align=right> 1725</td></tr>

<tr><th>NY</th><td align=right> 159</td></tr>
<tr><th>PGM</th><td align=right> 78</td></tr>
<tr><th>POM</th><td align=right> 587</td></tr>
<tr><th>RSA</th><td align=right> 2744</td></tr>
<tr><th>SBBG</th><td align=right> 708</td></tr>

<tr><th>SD</th><td align=right> 1298</td></tr>
<tr><th>SDSU</th><td align=right> 262</td></tr>
<tr><th>SJSU</th><td align=right> 89</td></tr>
<tr><th>UC</th><td align=right> 3515</td></tr>
<tr><th>UCD</th><td align=right> 643</td></tr>

<tr><th>UCR</th><td align=right> 2004</td></tr>
<tr><th>UCSB</th><td align=right> 120</td></tr>
<tr><th>UCSC</th><td align=right> 84</td></tr>
</table>Total: 15894</td></tr></table>

<tr><td>From:</td><td><tt>Mon Sep  6 11:46:04 2010</tt></td></tr>
<tr><td>To:</td><td><tt>Tue Oct 19 21:38:07 2010</tt></td></tr>
</table>
<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Sep  6 11:46:04 2010</tt></td></tr>
<tr><td>To:</td><td><tt>Tue Oct 19 21:38:07 2010</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>70999</td></tr>

<tr><th>CDA</th><td align=right>47340</td></tr>
<tr><th>CHSC</th><td align=right>176259</td></tr>
<tr><th>DS</th><td align=right>45543</td></tr>
<tr><th>HSC</th><td align=right>141176</td></tr>
<tr><th>IRVC</th><td align=right>28447</td></tr>
<tr><th>JEPS</th><td align=right>353081</td></tr>

<tr><th>NY</th><td align=right>63479</td></tr>
<tr><th>PGM</th><td align=right>30064</td></tr>
<tr><th>POM</th><td align=right>257013</td></tr>
<tr><th>RSA</th><td align=right>874183</td></tr>
<tr><th>SBBG</th><td align=right>383618</td></tr>
<tr><th>SD</th><td align=right>369389</td></tr>

<tr><th>SDSU</th><td align=right>58719</td></tr>
<tr><th>SJSU</th><td align=right>25420</td></tr>
<tr><th>UC</th><td align=right>948769</td></tr>
<tr><th>UCD</th><td align=right>109151</td></tr>
<tr><th>UCR</th><td align=right>494519</td></tr>
<tr><th>UCSB</th><td align=right>41228</td></tr>

<tr><th>UCSC</th><td align=right>14558</td></tr>
</table>Total: 4532955 in 56062 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 369</td></tr>
<tr><th>CDA</th><td align=right> 499</td></tr>
<tr><th>CHSC</th><td align=right> 954</td></tr>

<tr><th>DS</th><td align=right> 160</td></tr>
<tr><th>HSC</th><td align=right> 279</td></tr>
<tr><th>IRVC</th><td align=right> 95</td></tr>
<tr><th>JEPS</th><td align=right> 2743</td></tr>
<tr><th>NY</th><td align=right> 635</td></tr>

<tr><th>PGM</th><td align=right> 143</td></tr>
<tr><th>POM</th><td align=right> 581</td></tr>
<tr><th>RSA</th><td align=right> 3475</td></tr>
<tr><th>SBBG</th><td align=right> 1980</td></tr>
<tr><th>SD</th><td align=right> 1435</td></tr>

<tr><th>SDSU</th><td align=right> 174</td></tr>
<tr><th>SJSU</th><td align=right> 111</td></tr>
<tr><th>UC</th><td align=right> 4549</td></tr>
<tr><th>UCD</th><td align=right> 736</td></tr>
<tr><th>UCR</th><td align=right> 2287</td></tr>

<tr><th>UCSB</th><td align=right> 264</td></tr>
<tr><th>UCSC</th><td align=right> 55</td></tr>
</table>Total: 21524</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sun Jul 25 14:13:29 2010</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Sep  6 11:42:02 2010</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>59810</td></tr>
<tr><th>CDA</th><td align=right>84289</td></tr>
<tr><th>CHSC</th><td align=right>224010</td></tr>
<tr><th>DS</th><td align=right>42584</td></tr>
<tr><th>HSC</th><td align=right>126495</td></tr>
<tr><th>IRVC</th><td align=right>20236</td></tr>
<tr><th>JEPS</th><td align=right>386751</td></tr>
<tr><th>NY</th><td align=right>69967</td></tr>
<tr><th>PGM</th><td align=right>31128</td></tr>
<tr><th>POM</th><td align=right>242892</td></tr>
<tr><th>RSA</th><td align=right>892609</td></tr>
<tr><th>SBBG</th><td align=right>275952</td></tr>
<tr><th>SD</th><td align=right>339160</td></tr>
<tr><th>SDSU</th><td align=right>53764</td></tr>
<tr><th>SJSU</th><td align=right>32977</td></tr>
<tr><th>UC</th><td align=right>1051474</td></tr>
<tr><th>UCD</th><td align=right>156668</td></tr>
<tr><th>UCR</th><td align=right>508200</td></tr>
<tr><th>UCSB</th><td align=right>55057</td></tr>
<tr><th>UCSC</th><td align=right>17339</td></tr>
</table>Total: 4671362 in 44542 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 152</td></tr>
<tr><th>CDA</th><td align=right> 189</td></tr>
<tr><th>CHSC</th><td align=right> 739</td></tr>
<tr><th>DS</th><td align=right> 61</td></tr>
<tr><th>HSC</th><td align=right> 201</td></tr>
<tr><th>IRVC</th><td align=right> 59</td></tr>
<tr><th>JEPS</th><td align=right> 1811</td></tr>
<tr><th>NY</th><td align=right> 173</td></tr>
<tr><th>PGM</th><td align=right> 83</td></tr>
<tr><th>POM</th><td align=right> 396</td></tr>
<tr><th>RSA</th><td align=right> 2067</td></tr>
<tr><th>SBBG</th><td align=right> 608</td></tr>
<tr><th>SD</th><td align=right> 1138</td></tr>
<tr><th>SDSU</th><td align=right> 117</td></tr>
<tr><th>SJSU</th><td align=right> 60</td></tr>
<tr><th>UC</th><td align=right> 2908</td></tr>
<tr><th>UCD</th><td align=right> 304</td></tr>
<tr><th>UCR</th><td align=right> 1379</td></tr>
<tr><th>UCSB</th><td align=right> 102</td></tr>
<tr><th>UCSC</th><td align=right> 38</td></tr>
</table>Total: 12585</td></tr></table>

<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Sat Jun  5 07:10:17 2010</tt></td></tr>
<tr><td>To:</td><td><tt>Sun Jul 25 14:05:45 2010</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>60462</td></tr>
<tr><th>CDA</th><td align=right>48070</td></tr>
<tr><th>CHSC</th><td align=right>193449</td></tr>
<tr><th>DS</th><td align=right>42223</td></tr>
<tr><th>HSC</th><td align=right>118642</td></tr>
<tr><th>IRVC</th><td align=right>21732</td></tr>
<tr><th>JEPS</th><td align=right>377687</td></tr>
<tr><th>NY</th><td align=right>119068</td></tr>
<tr><th>PGM</th><td align=right>28196</td></tr>
<tr><th>POM</th><td align=right>213749</td></tr>
<tr><th>RSA</th><td align=right>787191</td></tr>
<tr><th>SBBG</th><td align=right>257370</td></tr>
<tr><th>SD</th><td align=right>412159</td></tr>
<tr><th>SDSU</th><td align=right>54597</td></tr>
<tr><th>SJSU</th><td align=right>27646</td></tr>
<tr><th>UC</th><td align=right>1086291</td></tr>
<tr><th>UCD</th><td align=right>171563</td></tr>
<tr><th>UCR</th><td align=right>400248</td></tr>
<tr><th>UCSB</th><td align=right>41446</td></tr>
<tr><th>UCSC</th><td align=right>21253</td></tr>
</table>Total: 4483042 in 60060 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 281</td></tr>
<tr><th>CDA</th><td align=right> 335</td></tr>
<tr><th>CHSC</th><td align=right> 861</td></tr>
<tr><th>DS</th><td align=right> 133</td></tr>
<tr><th>HSC</th><td align=right> 424</td></tr>
<tr><th>IRVC</th><td align=right> 93</td></tr>
<tr><th>JEPS</th><td align=right> 2276</td></tr>
<tr><th>NY</th><td align=right> 743</td></tr>
<tr><th>PGM</th><td align=right> 117</td></tr>
<tr><th>POM</th><td align=right> 544</td></tr>
<tr><th>RSA</th><td align=right> 3271</td></tr>
<tr><th>SBBG</th><td align=right> 893</td></tr>
<tr><th>SD</th><td align=right> 1455</td></tr>
<tr><th>SDSU</th><td align=right> 160</td></tr>
<tr><th>SJSU</th><td align=right> 101</td></tr>
<tr><th>UC</th><td align=right> 4891</td></tr>
<tr><th>UCD</th><td align=right> 587</td></tr>
<tr><th>UCR</th><td align=right> 2406</td></tr>
<tr><th>UCSB</th><td align=right> 133</td></tr>
<tr><th>UCSC</th><td align=right> 107</td></tr>
</table>Total: 19811</td></tr></table>
<table border=1 cellpadding=5><tr><td align="center"><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Mon Apr 19 21:18:36 2010</tt></td></tr>
<tr><td>To:</td><td><tt>Sat Jun  5 07:04:47 2010</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>59749</td></tr>
<tr><th>CDA</th><td align=right>46917</td></tr>

<tr><th>CHSC</th><td align=right>180266</td></tr>
<tr><th>DS</th><td align=right>25756</td></tr>
<tr><th>HSC</th><td align=right>39279</td></tr>
<tr><th>IRVC</th><td align=right>23764</td></tr>
<tr><th>JEPS</th><td align=right>331147</td></tr>
<tr><th>NY</th><td align=right>50205</td></tr>

<tr><th>PGM</th><td align=right>20809</td></tr>
<tr><th>POM</th><td align=right>208836</td></tr>
<tr><th>RSA</th><td align=right>868774</td></tr>
<tr><th>SBBG</th><td align=right>242249</td></tr>
<tr><th>SD</th><td align=right>375456</td></tr>
<tr><th>SDSU</th><td align=right>58577</td></tr>

<tr><th>SJSU</th><td align=right>24836</td></tr>
<tr><th>UC</th><td align=right>819309</td></tr>
<tr><th>UCD</th><td align=right>128729</td></tr>
<tr><th>UCR</th><td align=right>503912</td></tr>
<tr><th>UCSB</th><td align=right>46576</td></tr>
<tr><th>UCSC</th><td align=right>27536</td></tr>

</table>Total: 4082682 in 46978 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 188</td></tr>
<tr><th>CDA</th><td align=right> 325</td></tr>
<tr><th>CHSC</th><td align=right> 1044</td></tr>
<tr><th>DS</th><td align=right> 99</td></tr>

<tr><th>HSC</th><td align=right> 68</td></tr>
<tr><th>IRVC</th><td align=right> 79</td></tr>
<tr><th>JEPS</th><td align=right> 1894</td></tr>
<tr><th>NY</th><td align=right> 263</td></tr>
<tr><th>PGM</th><td align=right> 77</td></tr>

<tr><th>POM</th><td align=right> 543</td></tr>
<tr><th>RSA</th><td align=right> 2398</td></tr>
<tr><th>SBBG</th><td align=right> 892</td></tr>
<tr><th>SD</th><td align=right> 1409</td></tr>
<tr><th>SDSU</th><td align=right> 233</td></tr>

<tr><th>SJSU</th><td align=right> 96</td></tr>
<tr><th>UC</th><td align=right> 3265</td></tr>
<tr><th>UCD</th><td align=right> 455</td></tr>
<tr><th>UCR</th><td align=right> 2247</td></tr>
<tr><th>UCSB</th><td align=right> 80</td></tr>

<tr><th>UCSC</th><td align=right> 91</td></tr>
</table>Total: 15746</td></tr></table>



<table border=1><tr><td><table bgcolor="#dddddd" cellspacing=5 cellpadding=5>
<tr><td>From:</td><td><tt>Thu Mar 18 14:03:29 2010</tt></td></tr>
<tr><td>To:</td><td><tt>Mon Apr 19 21:11:26 2010</tt></td></tr>
</table>
</td></tr>
<tr><td><h3>Records returned in general searches</h3>
<table><tr><th>CAS</th><td align=right>32311</td></tr>
<tr><th>CDA</th><td align=right>36011</td></tr>

<tr><th>CHSC</th><td align=right>142131</td></tr>
<tr><th>DS</th><td align=right>14129</td></tr>
<tr><th>HSC</th><td align=right>8543</td></tr>
<tr><th>IRVC</th><td align=right>18411</td></tr>
<tr><th>JEPS</th><td align=right>238324</td></tr>
<tr><th>NY</th><td align=right>5093</td></tr>

<tr><th>PGM</th><td align=right>15231</td></tr>
<tr><th>POM</th><td align=right>144205</td></tr>
<tr><th>RSA</th><td align=right>607396</td></tr>
<tr><th>SBBG</th><td align=right>164990</td></tr>
<tr><th>SD</th><td align=right>263584</td></tr>
<tr><th>SDSU</th><td align=right>41494</td></tr>

<tr><th>SJSU</th><td align=right>18841</td></tr>
<tr><th>UC</th><td align=right>605799</td></tr>
<tr><th>UCD</th><td align=right>117836</td></tr>
<tr><th>UCR</th><td align=right>342329</td></tr>
<tr><th>UCSB</th><td align=right>35839</td></tr>
<tr><th>UCSC</th><td align=right>8954</td></tr>

</table>Total: 2861451 in 33581 searches</td></tr><tr><td><h3>Records returned in detail displays</h3>
<table><tr><th>CAS</th><td align=right> 142</td></tr>
<tr><th>CDA</th><td align=right> 304</td></tr>
<tr><th>CHSC</th><td align=right> 919</td></tr>
<tr><th>DS</th><td align=right> 49</td></tr>

<tr><th>HSC</th><td align=right> 25</td></tr>
<tr><th>IRVC</th><td align=right> 45</td></tr>
<tr><th>JEPS</th><td align=right> 1634</td></tr>
<tr><th>NY</th><td align=right> 94</td></tr>
<tr><th>PGM</th><td align=right> 68</td></tr>

<tr><th>POM</th><td align=right> 460</td></tr>
<tr><th>RSA</th><td align=right> 2006</td></tr>
<tr><th>SBBG</th><td align=right> 653</td></tr>
<tr><th>SD</th><td align=right> 797</td></tr>
<tr><th>SDSU</th><td align=right> 88</td></tr>

<tr><th>SJSU</th><td align=right> 107</td></tr>
<tr><th>UC</th><td align=right> 2502</td></tr>
<tr><th>UCD</th><td align=right> 578</td></tr>
<tr><th>UCR</th><td align=right> 1801</td></tr>
<tr><th>UCSB</th><td align=right> 79</td></tr>

<tr><th>UCSC</th><td align=right> 53</td></tr>
</table>Total: 12404</td></tr></table>


