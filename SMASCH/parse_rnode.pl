$/="";
while(<DATA>){
	%fields=();
	($timestamp)=m/^(.*)/;
	@fields=split(/\n/);
	foreach (@fields[1 .. $#fields]){
		if(s/^([^:]+): *//){
			$fields{$1}=$_;
			$seen{$1}++;
		}
	}
	if($fields{'cardtype'} eq "NB"){
		&print_bpu_card();
	}
}
sub print_bpu_card{
foreach($fields{'BPU_Title'}){
while(s/_/<em>/){
s/_/<\/em>/;
}
}
		if($fields{'BPU_Illustrations'}){
			$fields{'BPU_Illustrations'}= ", $fields{'BPU_Illustrations'}";
		}
		else{
			$fields{'Illustrations'}= "";
		}
		if($fields{'BPU_Page'}){
			$fields{'BPU_Page'}= ": $fields{'BPU_Page'}";
		}
		else{
			$fields{'BPU_Page'}= "";
		}
		if($fields{'BPU_Issue'}){
			$fields{'BPU_Issue'}= "($fields{'BPU_Issue'})";
		}
		else{
			$fields{'BPU_Issue'}= "";
		}
		if($fields{'BPU_Month'}){
			$fields{'BPU_Month'}= " ($fields{'BPU_Month'})";
		}
		else{
			$fields{'BPU_Month'}= "";
		}

	print <<EOP;
	<table align="center" "width=50%" >
	<tr><td>
$fields{'BPU_Author'}
	</td></tr>
	<tr><td>
$fields{'BPU_Year'}$fields{'BPU_Month'}
	</td></tr>
	<tr><td>
$fields{'BPU_Title'}
	</td></tr>
	<tr><td>
$fields{'BPU_Source'}
$fields{'BPU_Volume'}$fields{'BPU_Issue'}$fields{'BPU_Page'}$fields{'BPU_Illustrations'}
	</td></tr>
	<tr><td>
cardnote: $fields{'BPU_Comments'}
	</td></tr>
	<tr><td>
inhouse: [$timestamp] $fields{'BPU_Inhouse'}
</td></tr>
</table>

EOP
}
__END__
Fri Apr  6 10:12:02 PDT 2007
BPU_Title: Unraveling the _Asteromenia peltata_ species complex with the clarification of the genera _Halichrysis_ and _Drouetia_ (Rhodymeniaceae, Rhodophyta)
BPU_Author: SAUNDERS, Gary W; LANE, Christopher E.; SCHNEIDER, Craig W.; KRAFT, Gerald T.
Your I.D.: 123
BPU_Year: 2006
BPU_Comments: Asteromenia bermudensis sp. nov., A. anastomosans comb. nov., A. pseudocoalescens sp. nov., A. exanimans sp. nov. Asteromenia, Drouetia, and Halichrysis maintained as distinct
BPU_Month: Oct.
cardtype: NB
BPU_Volume: 84
BPU_Issue: 10
BPU_Source: Can. J. Bot
BPU_Illustrations: 82 figs., 3 tables
BPU_Page: 1581-1607

Fri Apr  6 10:19:04 PDT 2007
figures: figs. 13-25
legitimacy assessment: Yes
source: Can. J. Bot.
author: G.W. Saunders, C.E. Lane, C.W. Schneider, & G.T. Kraft
issue: 10
type locality: Bermuda: John Smith's Bay: Canton Point, 9 m depth
enterer: 123
year: 2006
collection number: 01-16-13
collector: Schneider, Saunders, and Lane
cardtype: NS
validity assessment: Yes
holotype: Yes
housed at: UNB
journal volume: 84
latin: Yes
species name: Asteromenia bermudensis
page: 1593
collection date: xi 14 2001

Fri Apr  6 10:23:33 PDT 2007
figures: figs. 42-44
legitimacy assessment: Yes
source: Can. J. Bot.
author: G.W. Saunders, C.E. Lane, C.W. Schneider, & G.T. Kraft
issue: 10
type locality: Australia: Lord Howe I: Yellow Rock, 16 m depth
enterer: 123
year: 2006
collection number: GWS002022
collector: G.W. Saunders
cardtype: NS
validity assessment: Yes
holotype: Yes
housed at: UNB
journal volume: 84
latin: Yes
species name: Asteromenia pseudocoalescens
page: 1595
collection date: 30 i 2004

Fri Apr  6 10:30:06 PDT 2007
figures: figs. 45-56
legitimacy assessment: Yes
source: Can. J. Bot.
author: G.W. Saunders, C.E. Lane, C.W. Schneider, & G.T. Kraft
issue: 10
type locality: Australia: Houtman Abrolhos: Easter Group: Suomi I.
enterer: 123
year: 2006
collector: J. Huisman and G. Kendrick
cardtype: NS
validity assessment: Yes
holotype: Yes
housed at: PERTH 07150377
journal volume: 84
latin: Yes
species name: Asteromenia exanimans
derivation: first viewing left Saunders breathless [SCUBA joke?]
page: 1595
collection date: 28 ix 1991

Fri Apr  6 10:33:32 PDT 2007
legitimacy assessment: Yes
source: Can. J. Bot.
author: G.W. Saunders, C.E. Lane, C.W. Schneider, & G.T. Kraft
basionym date: 1926
issue: 10
combination: Asteromenia anastomosans
enterer: 123
basionym: Rhodymenia anastomosans
cardtype: NC
validity assessment: Yes
parenthetical author: Weber-van Bosse
journal volume: 84
nom. or comb.: comb._nov.
page: 1593

Fri Apr  6 10:50:19 PDT 2007
figures: fig. 39
legitimacy assessment: Yes
source: Vid. Medd. Dansk Naturh. For. Ko\*/benhavn
author: Weber-van Bosse
comments: as Rhodymenia ? anastomosans
type locality: Indonesia: Kei Is.: Doe-Roa, 20 m depth
enterer: 123
year: 1926
cardtype: NS
validity assessment: Yes
journal volume: 81
latin: Yes
species name: Rhodymenia anastomosans
page: 150

Fri Apr  6 10:57:02 PDT 2007
legitimacy assessment: Yes
source: S. Afr. J. Bot.
author: R. Norris & Aken
basionym date: 1926
combination: Leptofauchea anastomosans
enterer: 123
basionym: Rhodymenia anastomosans
cardtype: NC
validity assessment: Yes
parenthetical author: Weber-van Bosse
journal volume: 51
nom. or comb.: comb._nov.
page: 58

