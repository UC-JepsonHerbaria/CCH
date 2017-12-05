open(OUT,">BLMAR.tab") || die;;
    use Text::CSV;
    my $file = 'BLMAR_Oct_2013.csv';

my $csv = Text::CSV->new ({
     quote_char          => '"',
     escape_char         => '\\',
     sep_char            => ',',
eol => '\cM',
     binary              => 1,
     });


    open (CSV, "<", $file) or die $!;


    while (<CSV>) {
                chomp;
                s/\cK/ /g;
                s/\t/ /g;
        if ($. == 1){
next;
                }
        if ($csv->parse($_)) {
        print $_;
            my @columns = $csv->fields();
                unless( $#columns==10){
warn "$#columns bad field number $_\n";
}
print OUT join ("\t",@columns), "\n";
}
else{
warn "parsing error $_\n";
}
}