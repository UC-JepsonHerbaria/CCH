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


echo "$?                                          parsing CATA";
perl /JEPS-master/CCH/Loaders/CATA/parse_CATA.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/CATA/CATA_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/CATA/
sort -u log.txt > /JEPS-master/CCH/Loaders/CATA/CATA_log_sort.txt

echo "$?                                          NEXT";


echo "$?                                          parsing CDA";
perl /JEPS-master/CCH/Loaders/CDA/parse_CDA.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/CDA/CDA_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/CDA/
sort -u log.txt > /JEPS-master/CCH/Loaders/CDA/CDA_log_sort.txt

echo "$?                                          NEXT";


echo "$?                                          parsing CHSC";
perl /JEPS-master/CCH/Loaders/CHSC/parse_CHSC.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/CHSC/CHSC_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/CHSC/
sort -u log.txt > /JEPS-master/CCH/Loaders/CHSC/CHSC_log_sort.txt

echo "$?                                          NEXT";


echo "$?                                          parsing UCJEPS";
perl /JEPS-master/CCH/Loaders/CSPACE/parse_CSPACE.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/CSPACE/CSPACE_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/CSPACE/
sort -u log.txt > /JEPS-master/CCH/Loaders/CSPACE/CSPACE_log_sort.txt

echo "$?                                          NEXT";


echo "$?                                          parsing GMDRC";
perl /JEPS-master/CCH/Loaders/GMDRC/parse_GMDRC.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/GMDRC/GMDRC_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/GMDRC/
sort -u log.txt > /JEPS-master/CCH/Loaders/GMDRC/GMDRC_log_sort.txt

echo "$?                                          NEXT";



echo "$?                                          parsing OBI";
perl /JEPS-master/CCH/Loaders/OBI/parse_OBI.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/OBI/OBI_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/OBI/
sort -u log.txt > /JEPS-master/CCH/Loaders/OBI/OBI_log_sort.txt

echo "$?                                          NEXT";



echo "$?                                          parsing UCSC";
perl /JEPS-master/CCH/Loaders/UCSC/parse_UCSC.pl
echo "$?                                          sorting log file";
cp /JEPS-master/CCH/Loaders/UCSC/UCSC_out.txt /JEPS-master/CCH/bulkload/input/new_files/
cp log.txt /JEPS-master/CCH/Loaders/UCSC/
sort -u log.txt > /JEPS-master/CCH/Loaders/UCSC/UCSC_log_sort.txt

echo "$?                                          NEXT";


echo "$?                                          process complete";