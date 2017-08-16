while(<>){
chomp;
($accession_id=$_)=~s/ .*//;
		if($seen{$accession_id}){
			print <<EOP;
$. $accession_id
$seen{$accession_id}
$_

EOP
		}
		($seen{$accession_id}=$_);
	}


