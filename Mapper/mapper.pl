#Where you write the data (your local web server)
$map_data_file_out = "/Library/WebServer/documents/Smith/mapper.txt";

#Where you tell Berkeley Mapper to get the data
$map_data_file_URL= "http://herbaria4.herb.berkeley.edu/Smith/mapper.txt";

#Where you tell Berkeley Mapper the configuration file is
$config_file='http://herbaria4.herb.berkeley.edu/Smith/test_mapper.xml';

$sourcename="Test";

while(<>){
chomp;
push(@map_results, $_);
}

open(MAPFILE, ">$map_data_file_out") || warn "cant open map file";
print MAPFILE join("\n",@map_results);
$mappable=<<EOP;
<H3>
<a href="http://berkeleymapper.berkeley.edu/run.php?ViewResults=tab&tabfile=$map_data_file_URL&configfile=$config_file&sourcename=$sourcename&">Link to BerkeleyMapper</a>
</H3>
EOP
open(OUT, ">view_test_map.html") || die;
print OUT $mappable;
#Institution<tab>accession_id<tab>taxon<tab>county<tab>latitude<tab>longitude<tab>datum
