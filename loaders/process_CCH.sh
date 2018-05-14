#this parses the data file for a participant, then it sorts the error log file.  
#this used to be done manually with programs such as vi or vim
#this has an advantage because it preserves the order of the error log (you can see all the errors a specimen record produces)
#and it creates a unique sorted error log file

echo "$?                                          parsing BLMAR";
perl /JEPS-master/CCH/Loaders/BLMAR/parse_BLMAR.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/BLMAR/BLMAR_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/BLMAR/
sort -u log.txt > /JEPS-master/CCH/Loaders/BLMAR/BLMAR_log_sort.txt

echo "$?                                          NEXT";


echo "$?                                          parsing CAS";
perl /JEPS-master/CCH/Loaders/CAS/parse_CAS.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/CAS/CAS_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/CAS/
sort -u log.txt > /JEPS-master/CCH/Loaders/CAS/CAS_log_sort.txt

echo "$?                                          NEXT";


echo "$?                                          parsing OBI";
perl /JEPS-master/CCH/Loaders/OBI/parse_OBI.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/OBI/OBI_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/OBI/
sort -u log.txt > /JEPS-master/CCH/Loaders/OBI/OBI_log_sort.txt

echo "$?                                          NEXT";


echo "$?                                          process complete";