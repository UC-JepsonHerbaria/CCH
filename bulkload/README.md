# CCH data and Scripts

`consort_bulkload.pl`  Script that merges all of the participant's text files into a tab delimited text files ready for converting into hash files.

`G_T_F`  In the `CCH/data_files` directory. Hash file that contains the genus to family cross references

	- used for adding families to various hash files.  
	
	- family data is not preserved in the conversion from the participant's database into the CCH text files. 
	
		- not all databases have a family field either.

`licenses.txt`  In the `CCH/data_files` directory. Text file that contains all of the individual license text requested by participants.


`CDL_cultivated_ids.txt` In the `CCH/data_files` directory. Old file used for flagging cultivated specimens.

	- the old method for flagging cultivated records in CCH was to add the accession to this file once a cultivated specimen was found.  

	- this is still used, but it is being phased out.


`CDL_annohist.in`  Annotation text file, with `\n` as record delimiter. The accession number is on the first line of the record, the annotation is on the second line.  

	- When more than one annotation is present, then there are multiple records for an accession.
	
	- file format:Line[0]`817804\n`Line[1]`current determination (uncorrected): Scrophularia californica\n`[delimiter]`\n`


`CDL_coll_number.in`  Collection number text file that is used to create the collection number hash file used by the CCH search page.

	- The data is the collection number (harvested from the `consort_bulkload` script from the collection number field only, stripped of suffix and prefix.)
	
	- The file format is the collection number, followed by a space, then followed by tab separated accessions that have this collection number, irrespective of collector name.
	
	- file format: `001 RSA273952	RSA818850`

`CDL_collectors.in`  Collector last name text file that is used to create the collector name hash file used by the CCH search page.

	- The data is the collectors last name (harvested from the `consort_bulkload` script from the collector field only, stripped of all other collectors, first names, titles, etc.)
	
	- The file format is the collector last name, followed by a space, then followed by tab separated accessions that have this name.
	
	- Only the last name of the primary collector is used.
	
	- file format: `Abrams POM48668	POM145908`

`CDL_counties.in`  County name text file that is used to create the county name hash file used by the CCH search page.

	- The data is the county name (harvested from the `consort_bulkload` script from the county field, spaces replaced by `_`, and converted to all caps.)
	
	- The file format is the county name, followed by a space, then followed by tab separated accessions that have this name.
	
	- There should never be more than 64 lines in this file. 63 total names (counties from California and municipalities in Baja California) plus one line for all records with `UNKOWN` county values.
	
	- County names as they are found in the participant files are printed on-screen.  If there is more than 64 lines, the participant file has to be corrected to eliminate the bad county.
	
		- the text on the screen shows what participant file has the first found occurrence of this bad name.
		
	- file format:`CONTRA_COSTA RSA817095	RSA817094`

`CDL_date_range.in`   Early Julian Date-Late Julian Date range text file that is used to create the date range hash file used by the CCH search page

	- The data is the early and late julian dates (harvested from the `consort_bulkload` script from the ELD and LJD date fields.)
	
	- The file format is `EJD-LJD`, followed by tab separated accessions that have this date range.
	
	- There are older participant databases that do not have an LJD or and EJD field.
	
		- The original process for `consort_bulkload` was to process the EJD and LJD at this step from the original uncorrected date from the participant database, not at the participant database processing step as is done now.
		
		- prior to 2018, `consort_bulkload` harvested dates from only the verbatim date field.  It ignored corrections that were present in the EJD and LJD participant database field.
		
				- As a result, one could search the CCH and have records come up that display a date not within the range entered.
				
				- This is caused when the EJD and LJD processing has corrected a date that has a bad format or an erroneous date in the verbatim date field.
				
				- This also caused a problem with the search results page.
				
					- The search results are sorted by the EJD and not the verbatim date field.  However the verbatim date is displayed on the search results page (not a converted form of the EJD).
					
					- frequently, dates from outside the desired range would appear in search results.
					
					- also the dates would sort incoherently, since the EJD value was used as the sort and the verbatim date was displayed.
					
						-records with an erroneous date that cannot be converted have a value in verbatim date but no value in EJD.
					
					- this caused much consternation among the users and many complaints were e-mailed.
					
		- `consort_bulkload` has now been modified to use the EJD and LJD from participant files first, then use the verbatim date field when those are missing (as they are in old databases)
		
	- `consort_bulkload` still reports when dates fall outside the known range for the "british use" of the Gregorian Calendar and current date.
	
		- The out of range dates are nulled.  They need to be fixed in the participant database processing step when found.  
		
		- The error is reported on screen.
		
	- file format:`2378497-2378861	 UCSC774	UCSC775	UCSC782`

`CDL_date_simple.in`  Julian Date text file that is used to create the date hash file used by the CCH search page

	- The data are julian dates (harvested from the `consort_bulkload` script from the ELD and LJD date fields.)
	
	- The file format is the JD, followed by a space, and followed by tab separated accessions that have this date.
	
	- The notes from the date range section also apply to this table.
	
	- It is not known whether or not specimens with both an EJD and a LJD, have two records in this file. 

	- file format:`2391279 UC163787	UC163776	UC163789	UC163770`

`CDL_image_links.txt`  Image links text file that is used to population the hash file `SMASCH_IMAGES`

	- The file format is the accession, followed by a tab, and followed by html-formatted URL link that is associated with the image.

	- `consort_bulkload` was creating this file prior to 2018, but the `SMASCH_IMAGES` hash file had not been updated recently.  The last version was created in May of 2015.
		
	- the process was stopped initially in 2015 when the CSpace image links were being changed.  However, it was not re-actived until 2017.
		
	- between 2015 and spring of 2017, most of the image links were broken in CCH due to out-dated URL's.
		
	- The scripts for recreating the hash file were lost.  This process was restarted in 2018 after the scripts for the upload were re-discovered in the CCH file archive.
	
	- file format: `JEPS94985	<a href="https://webapps.cspace.berkeley.edu/ucjeps/imageserver/blobs/d75c1aaf-bb01-481b-aa06/derivatives/OriginalJpeg/content">JEPS94985</a>`
		
		
`CDL_loc_list.in`  Collection location name text file that is used to create the collection location hash file used by the CCH search page.

	- The data obtained from the locality field from participant text files.
	
		- The location is parsed into all words separated by spaces (punctuation removed), words are converted to lower case, and all words are agglomerated from all location fields in all participant files
		
	- The file format is the location word, followed by a space, then followed by tab separated accessions that have this name.
	
	- there are many anomalous words in this hash, which could be as a result of some odd code in `consort_bulkload` or a result of the many typos in participant databases.
	
		- `aaaa, aaaaw, aaae, aaallured, aaan, aancient, aar, aaarn, aaarw, aaw` appear as a words in CCH records, for example.
		
	- Anomalous words could be as a result of the `brute force` parsing code used by `consort_bulkload`, some of which are likely created by the removal of all puncutation.
	
		- some anomalous words are actually typos from the participant database.
		
	- file format:`avenue RSA817920	RSA817917`



`CDL_main.in`  Primary text file that contains the bulk of the date, collection locality, coordinates, and collector number data.

	- The data is obtained from the multiple fields with standardized names from participant text files.
	
		- the standardized names are in the second column of the list below.  
	
		- the field number assignments are listed first.

`key	Accession_id
`name	Name (scientificName)
`fields[0]	Name (scientificName)
`fields[1]	Accession_id
`fields[2]	CNUM_prefix
`fields[3]	CNUM
`fields[4]	CNUM_suffix
`fields[5]	EJD
`fields[6]	LJD
`fields[7]	Date (preferably the verbatim date field)
`fields[8]	County
`fields[9]	Elevation
`fields[10]	Location
`fields[11]	Decimal_latitude
`fields[12]	Decimal_longitude
`fields[13]	Datum
`fields[14]	Lat_long_ref_source
`fields[15]	T/R/Section
`fields[16]	Max_error_distance
`fields[17]	Max_error_units



`CDL_name_list.in`  Taxon name text file that is used to create the taxon name hash file used by the CCH search page.

	- The data is obtained from the taxon name field from participant text files.
	
		- names are parsed into individual words, so `species + infra taxa`, species, genus, and infrataxa name variants have their own lines
		
		- the full name is also listed without the rank value.
		
		- all names are lower case converted. 
		
	- The file format is the taxon word, followed by a space, then followed by tab separated accessions that have this name.
	
	- since the taxon names are corrected by the participant loading scripts and only names in the `smasch_taxon_ids_CCH.txt' file are allowed though, then there should be no mispelled names
	
		- Anomalous words could be as a result of the `brute force` parsing code used by `consort_bulkload`.
		
		- Anomalous words could also come from the small number of old datasets that have not been updated since 2012.
		
	- file format:`abies amabilis POM128167	RSA237368`


`CDL_name_to_code.in`  Taxon name text and taxon ID file that is used to create the taxon name to taxon ID hash file used by the CCH search page and other scripts.

	- The data is obtained from the taxon name field from participant text files.
	
		- the full name is also listed without the rank value is searched for in `smasch_taxon_ids_CCH.txt' and the taxon ID is found
		
	- The file format is the taxon name, followed by a space, then followed by the smasch taxon ID.
	
	- since the taxon names are corrected by the participant loading scripts and only name sin the SMASCH file are allowed though, then there should not be an mispelled names
	
		- Anomalous words could be as a result of the `brute force` parsing code used by `consort_bulkload`.
		
		- Anomalous words could also come from the small number of old datasets that have not been updated since 2012.
		
	- file format:`Arceuthobium douglasii 13884`


`CDL_notes.in`  Note field text file that is used to create the notes hash file that contains data that is linked by accession number to CDL_main.

	- The data is obtained from only the field marked as Notes in the participant text files.
	
		- each participant file can have the data entered in different fields, such as phenology data being entered into a general notes field
		
		- each data type is assigned to one of these field names in the participant database
		
		- `consort_bulkload` assembles the voucher table by adding the field number code from this table to the data for associated field name found in the participant file.

	- Sometime after 2013, the `CDL_voucher.ini` file (see below) was ignored by `consort_bulkload` and the only voucher data added to CCH was that contained in notes.
	
	- In 2017, the voucher file analysis was reinstated and more fields were added to participant loading scripts in order to include all possible voucher data types.


`CDL_tid_to_name.in`  Taxon ID to taxon name text file that is used to create the taxon ID to taxon name hash file used by the CCH search page and other scripts.

	- The data is obtained from the taxon name field from participant text files.
	
		- the full name is also listed without the rank value is searched for in `smasch_taxon_ids_CCH.txt' and the taxon ID is found
		
	- The file format is the smasch taxon ID, followed by a space, then followed by the taxon name.
	
	- all names in this file should have a taxon ID.
	
		- if there are names that have null taxon ID's then there is an error in CCH or in `smasch_taxon_ids_CCH.txt'.
		
	- this file has not been updated since Feburary 2018, which might mean that there is an error in `consort_bulkload`
	
		- however, files such as this were created by many other accessory scripts in the past (one not in David's instructions), and one of these ran during a test in 2018 may be the one updating it.
		
	- file format:`100009 Allium ursinum`



`CDL_voucher.in`  Voucher information field text file that is used to create the voucher hash file that contains data that is linked by accession number to CDL_main.

	- The data is obtained from the multiple fields with standardized names from participant text files.
	
		- each participant file can have the data entered in different fields, such as phenology data being entered into a general notes field
		
		- each data type is assigned to one of these field names in the participant database
		
		- `consort_bulkload` assembles the voucher table by adding the field number code from this table to the data for associated field name found in the participant file.
	
	- The voucher field types and number codes are based on SMASCH field codes, which are:
	
`my %voucher=split(/\t/,$VOUCHER{$key});
`my %voucher_kind=(
`"16","secondary product chemistry",
`"17","cytology",
`"18","embryology",
`"19","micromorphology",
`"20","macromorphology",
`"21","reproductive biology",
`"24","population biology",
`"25","horticulture",
`"26","phenology",
`"27","illustration",
`"28","photograph",
`"29","nomenclature",
`"32","publication",
`"33","data in packet",
`"35","reference used for determination",
`"36","none",
`"39","common name",
`"41","Vegetation Type Map Project",
`"43","odor",
`"44","ethnobotany",
`"47","map",
`"50","color",
`"52","habitat",
`"53","associated species",
`"55","other label numbers",
`"58","biotic interactions",
`"56","type",
`"23","biotic environment -inactive 7/93",
`"22","physical environment -inactive 7/93",
`"61","annotation history",
`"62","Expedition",
`"64","fruit removal",
`"65","physical enviroment",
`"66","physical environment",
`"67","SEM (Scanning Electron Micrograph)",
`"63","material removed",
`"15","nucleic acids",
`"45","genbank code",
`"71","U.C. Botanical Garden",
`"72","other",
`);`
	
	- The file format is the accession number, followed by a tab, then followed by the number code for the data type, followed by a tab, then followed by all other data type records found for each record (all separated by tabs).


	- file format: `UC1136772	52	slope flat, soil black clay, type meadow Gr. Wd., density 0.4, distrib. meadowy types, use light	24	includes biotic interactions	75	5560 ft	55	df37d660-97e8-49c6-8fbe-007e5fb99238`


`CF_full_name_list.in`  Taxon name text file that is identical to `CDL_name_list.in`.

	- The origin of this file is not known.
			
	- The file format is the taxon word, followed by a space, then followed by tab separated accessions that have this name.
	
	- this file has not been updated since Feburary 2018, which might mean that there is an error in `consort_bulkload`
	
		- An entire series of files with the prefix CF_ used to exist and at one time were installed to the server using the CCH install shell script.

		- `CF_` files must have been created by many other accessory scripts in the past (none are present in David's instructions).  One of these ran accidentally during a test in Feb 2018 may be the one currently updating it.

			- These two lines are commented out in `install_cch.sh`

			- `#cp CF_* /usr/local/web/ucjeps_web/interchange`

			- `#echo "new CF files transferred"`

		
	- file format:`abies amabilis POM128167	RSA237368`
	
	
### Refreshing the CCH

1.  Process any new data with parse scripts in respective herbarium's directory
	
2.  Before copying any new `XXX_out.txt`files `/JEPS-master/CCH/bulkload/input`, conserve the old file by copying it into `/JEPS-master/CCH/bulkload/old_files`

3.  Put all new `out` files into  directory `/JEPS-master/CCH/bulkload/input`
	
	- David Baxter used this directory during his tenure: `/davidbaxter/DATA/bulkload_data/data_files`
	
	- He did not have a backup reserve directory for old files.  During his tenure, most of the old versions could be found in various directories on the old Herbaria4 server.

3.  run `consort_bulkload.pl`
	
	- outputs are various `CDL.out` text files and `consort_bulkload_warn`.
	
		- make sure `consort_bulkload_warn` doesn’t have a zillion lines, which means a major error has occurred.  
	
	- compare the new `consort_bulkload_warn` with the last version using `vimdiff` to make sure that no other abnormal problems have occurred.

4.  cd to `cch_scripts` directory and run `refresh_cch.sh` (it knows how to find the files it needs in `/bulkload_data/`)

	- outputs are `cdl_buffer.tar`, as well as its content uncompressed

5.  `vi record_tally` to check that the record numbers are about right

6.  `cd timestamps` and `vi CCH_newrec.html` to make sure the new records looks right and is up to date

7.  from the `cch_scripts directory`, sftp annie.bnhm.berkeley.edu, `cd cdl_buffer`, and `put cdl_buffer.tar` (or use `filezilla` to sftp the file)

8.  exit and ssh back into annie

9.  `cd cdl_buffer`, then `sh install_cch.sh`

10.  `cd yf_eflora_Moe` and run `get_range_anomalies.sh`

	- This will add the yellow flag field to the `CDL_main` hash (Field 18).
	
	- output file is `id_region_problem.txt`
	
11.  then run `hartman.pl`

	- this updates the counts for the georeferenced records tally on the georeference status page (`/images/georef_map.html`)
	
12.  navigate to `/consortium/news.html` and add in a new line for news explaining what was updated and the new totals (totals can be found on `/images/georef_map.html`). 

	- This is not done if the only new data is from CSpace.



### 

