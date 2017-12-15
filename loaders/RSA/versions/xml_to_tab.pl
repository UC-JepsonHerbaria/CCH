$/="</ROW>";
while(<>){
s/\cM/ /g;
s/\cJ/ /g;
s/\t/ /g;
s|</COL><COL>|\t|g;
s/<\/?DATA>//g;
s|</COL></ROW>||;
s|<COL>||;
s/<ROW[^>]+>//;
print "$_\n";
}
