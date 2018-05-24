open(OUT,">seinet.tab") || die;;
    use Text::CSV;
    my $file = 'occurrences.csv';

my $csv = Text::CSV->new ({
     quote_char          => '"',
     escape_char         => '\\',
     sep_char            => ',',
     eol                 => $\,
     binary              => 1,
     });


    open (CSV, "<", $file) or die $!;


    while (<CSV>) {
s/\\r\\n/ /g;
                chomp;
                s/\cK/ /g;
                s/\t/ /g;
        if ($. == 1){
next;
                }
        if ($csv->parse($_)) {
            my @columns = $csv->fields();
                if( $#columns==72){
			splice(@columns,71,1);
		}
                unless( $#columns==71){
warn "$#columns bad field number $_\n";
}
print OUT join ("\t",@columns), "\n";
}
else{
warn "parsing error $_\n";
}
}
