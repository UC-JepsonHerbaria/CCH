# CCH data and Scripts

`consort_bulkload.pl`  Script that merges all of the participant's text files into a tab delimited text files ready for converting into hash files.
`G_T_F`  In the `CCH/data_files` directory. Hash file that contains the genus to family cross references.  Used for adding families to various hash files.  Family data is not preserved in the conversion from the participant's database into the CCH text files. Not all databases have a family field either.
`licenses.txt`  In the `CCH/data_files` directory.  Text file that contains all of the individual license text requested by participants.
`CDL_cultivated_ids.txt` In the `CCH/data_files` directory.  The old method for flagging cultivated records in CCH was to add the accession to this file once a cultivated specimen was found.  This is still used, but it is being phased out.

`CDL_annohist.in`  Annotation text file, with `\n` as record delimiter.  The accession number is on the first line of the record, the annotation is on the second line.  When more than one annotation is present, then there are multiple records for an accession.
	- file format:
`817804\n`
`current determination (uncorrected): Scrophularia californica\n`
`\n`

`CDL_coll_number.in`  Collection number text file that is used to create the collection number hash file used by the CCH search page.

	- The data is the collection number (harvested from the `consort_bulkload` script from the collection number field only, stripped of suffix and prefix.)
	
	- The file format is the collection number, followed by a space, then followed by tab separated accessions that have this collection number, irrespective of collector name.
	
	- file format:
	
`001 RSA273952	RSA818850`

`CDL_collectors.in`  Collector last name text file that is used to create the collector name hash file used by the CCH search page.
	- The data is the collectors last name (harvested from the `consort_bulkload` script from the collector field only, stripped of all other collectors, first names, titles, etc.)
	- The file format is the collector last name, followed by a space, then followed by tab separated accessions that have this name.
	- Only the last name of the primary collector is used.
	- file format:
`Abrams POM48668	POM145908`


`CDL_counties.in`  County name text file that is used to create the county name hash file used by the CCH search page.
	- The data is the county name (harvested from the `consort_bulkload` script from the county field, spaces replaced by `_`, and converted to all caps.)
	- The file format is the county name, followed by a space, then followed by tab separated accessions that have this name.
	- There should never be more than 64 lines in this file. 63 total names (counties from California and municipalities in Baja California) plus one line for all record with `UNKOWN` county values
	- County names as they are found in the participant files are printed on-screen.  If there is more than 64 lines, the participant file has to be corrected to eliminate the bad county
		- the text on the screen shows what participant file has the first found occurrence of this bad name.
	- file format:
`ALAMEDA RSA817095	RSA817094`

`CDL_date_range.in`   Early Julian Date-Late Julian Date range text file that is used to create the date range hash file used by the CCH search page
	- The data is the early and late julian dates (harvested from the `consort_bulkload` script from the ELD and LJD date fields.)
	- The file format is the EJD-LJD, followed by tab separated accessions that have this date range.
	- There are older participant databases that do not have an LJD or and EJD field.
		- The original process for `consort_bulkload` was to process the EJD and LJD at this step and not at the participant database processing step.
		- prior to 2018, `consort_bulkload` harvested dates from only the verbatim date field, and ignored corrections that were present in the EJD and LJD participant database field
				- As a result, one could search the CCH and have records come up that display a date not within the range entered.
				- This is caused when the EJD and LJD processing has corrected a date that has a bad format or an erroneous date in the verbatim date field.
				- This also caused a problem with the search results page.
					- The search results are sorted by the EJD and not the verbatim date field.  However the verbatim date is displayed on the search results page.
					- frequently, dates from outside the range would appear in search results.   
					- also the dates would sort incoherently, since the EJD value was used as the sort and the verbatim date was displayed
					- this caused much consternation among the users and many complaints were e-mailed.
		- `consort_bulkload` has now been modified to use the EJD and LJD from participant files in first, then use the verbatim date field
	- `consort_bulkload` still reports when dates fall outside the known range for the "british use" of the Julian Calendar and current date.
		- The out of range dates are nulled.  They need to be fixed in the participant database processing step when found.  
		- The error is reported on screen.
	- file format:
`2378497-2378861	 UCSC774	UCSC775	UCSC782`

`CDL_date_simple.in`  Julian Date text file that is used to create the date hash file used by the CCH search page
	- The data are julian dates (harvested from the `consort_bulkload` script from the ELD and LJD date fields.)
	- The file format is the EJD-LJD, followed by a space, and followed by tab separated accessions that have this date.
	
	
`2391279 UC163787	UC163776	UC163789	UC163770`
`CDL_image_links.txt`
`CDL_loc_list.in`
`CDL_main.in`
`CDL_name_list.in`
`CDL_name_to_code.in`
`CDL_notes.in`
`CDL_tid_to_name.in`
`CDL_voucher.in`
`CF_full_name_list.in`

### Refreshing the CCH

1.	Get most recent CSpace data by going to DATA/CCH_loaders/CSPACE/ and running get_cspace.pl. Parse the data with parse_cch_extract.pl (also in the CSPACE directory)
2.	Put all new .out files into /davidbaxter/DATA/bulkload_data/data_files directory
3.	run consort_bulkload.pl
a.	outputs are various CDL.out files and consort_bulkload_warn the latter to make sure it doesn’t have a zillion lines (currently has ~1900)
4.	cd to cch_scripts directory and run refresh_cch.sh (it knows to find the files it needs in /bulkload_data/
a.	outputs are cdl_buffer.tar, as well as its content uncompressed
5.	vi record_tally to check that the record numbers are about right
6.	cd timestamps and vi CCH_newrec.html to make sure the new records looks right and is up to date
7.	from the cch_scripts directory, sftp dbaxter@annie.bnhm.berkeley.edu, cd cdl_buffer, and put cdl_buffer.tar
8.	exit and ssh back into annie (ssh dbaxter@annie.bnhm.berkeley.edu or dbaxter_annie)
9.	cd cdl_buffer, then sh install_cch.sh
10.	From  cdl_buffer/, cd region_gif and run get_range_anomalies.sh
a.	output file is id_region_problem.txt
11.	cd .. then run hartman.pl
12.	navigate to /consortium/news.html and add in a new line for news explaining what was updated and the new totals (totals can be found on /images/georef_map.html). This is not done if the only data is our own, or SEINet’s, etc.





The georeference buffer in CCH is one that has online and offline components.  In the past, once georeferences were extacted from he hash file buffer on Annie, a script was modified and used to delete the exact buffer.  However, this yielded incomplete results as there were still georeferences in the buffer from 2012-2015 and other problem records that have never been delt with.

1.  Process any new data with parse scripts in respective herbarium's directory
	
2.  Before copying any new `XXX_out.txt`files `/JEPS-master/CCH/bulkload/input`, conserve the old file by copying it into `/JEPS-master/CCH/bulkload/old_files`
3.  Put all new .out files into  directory `/JEPS-master/CCH/bulkload/input`
	- David Baxter used this directory during his tenure: `/davidbaxter/DATA/bulkload_data/data_files`
	- He did not have a backup reserve directory for old files.  During his tenure, most of the old versions could be found in various directories on the old Herbaria4 server.

3.  run `consort_bulkload.pl`
	- outputs are various `CDL.out` text files and `consort_bulkload_warn` the latter to make sure it doesn’t have a zillion lines, which means a major error has occurred.  
	- compare the new `consort_bulkload_warn` with the last version using `vimdiff` to make sure that no other abnormal problems has occurred.
4. 

### Extracting parts of georeferences to resolve accession duplicate issues


with original data, take the RSA example and split the original data into two sections with these fields:
new ID, NON, original ID, taxon name, tempcounty, guid, other fields as necessary  ==> this is for all non-duplicate records
- perl -ne '/(RSA|POM)\d+[A-Z]?\tNON/ && print' RSA_ID.txt

barcode ID, BARCODE, original ID, taxon name, tempcounty, guid, other fields as necessary  ==> this is for all records with new, non-duplicate ID's
- perl -ne '/(RSA|POM)\d+[A-Z]?\tBARCODE/ && print' RSA_ID.txt

new ID, DUP, original ID, taxon name, tempcounty, guid, other fields as necessary  ==> this is for all duplicate records that are marked by DUP label in loader
- perl -ne '/(RSA|POM)\d+[A-Z]?DUP\tDUP/ && print' RSA_ID.txt

#### Process Georef Buffer for Paricipants

### Barcode Records BAR file
Barcode records are specimens that have the original replaced with a new barcode ID.  Since not all records may have barcodes , some of these may be duplicates in the past and have the wrong georeference.
This step is different if all records have been replaced with a new barcode ID, as in CAS/DS.
Check duplicate status by finding all records in the original ID field that are duplicates or present in the NON table.  

1.  Use cut to remove all fields from Barcode table except original ID.

	- `cut -f3 RSA_BAR.txt`
	
2.  Find if there are duplicates in the NON text file.

	- GREP: `grep -wf RSA_BAR1.txt RSA_NON.txt`
	- this can be slow for large files, fast for smaller ones; `-w` treat pattern as a word, `-f RSA_BAR1.txt` use this file for the search pattern
	- OR you can use the script `delete_georefs.pl`
		- change the list name to the file with just the accessions, in this case `RSA_BAR1.txt`.
		- change the file to the file with the NON records.
		- run the script.  If any records show up, use the output to get only the duplicate full records from NON and BAR files.
		- add these records to a second DUP file list.
			- these are only needed to find the exact georeferences that are linked to the old duplicate accession and change the ID to the new barcode.
			- if you dont get results, the BARCODE file's field 0 is $key, the duplicate accessions are only going to match the original ID for field 2
				- change `$key` to `$orig` in the if-else statement.
3.  Get only the non-duplicate records from NON and BARCODE
	- use the script `delete_georefs.pl`
	- set the if-else statement to `!~ m/` for not matching the list of duplicate accessions.
	- the same step needs to be applied to the NON file, to get all non-duplicate records
	- the cumulative non-duplicates are now ready for georef extraction. 

4. The above steps also need to be done with the DUP file.  
	- extract the records present in the NON file that match the DUP file.
	- add records to a cumulative DUP file.
	- extract records that are not present in step 3 and not present in step 4.  
		- these are the non duplicates, finally.



7. Cumulative File, modification of cumulative file output from `georef_out.sh`

	- Some records will have extra spaces, sort the output file, then delete empty rows.
	- Duplicate records will need to be removed, if present.
		a. run `delete_georef_dups.pl`
			- creates a `resolved` table that mostly has all duplicates removed.
		b. double check that `resolved` table is not missing any unique accessions from master file.
			- use cut to isolate just the guid's [field 0].
				- `cut -f1 RSA_GEOREF_BARCODE_UNIQUE.txt`
				- save guid's to `RSA_GUID.txt`
				- sort unique `RSA_GUID.txt` to determine number of unique records.
					- if the record number is the same as the `resolved` table, then no unique records were left out.
					- if not, then use `check_lines.pl` using guid file to determine which were left out.
						- can also use vimdiff or grep to view differences if this script does not work.
							`grep -wf RSA_GUID.txt RSA_resolved.txt`
					- copy those left out from master georef file to the `resolved` table.
				
		c. file ready to e-mail to participant.

8. Resolve the issue with the Datum and Source being flipped in the buffer archives.	
	a. run `fix_datum.pl`
		- loads the `resolved` table output file.
		- loads all fields 0-7 into a hash
		- flips the source (field 6) with the datum (field 7), if the source field starts with WGS or NAD



### Unique Records  NON file
The majority of records in this file are unique.  They never had duplicates, so theoretically, the georeferences here should be recovered without issue.

1.  Use `georef_out.sh` to add the GUID to records and recover the georeferences
	- The 3 individual files will need to be modified with new file names.
	- `$name_list` section and variables needs to be commented out because these are unique. Do not need a list of unique ID's
	- Some records will have extra spaces, sort the output file, then delete empty rows.
2. 	Duplicate records will need to be removed, if present.
	a. run `delete_georef_dups.pl`
			- creates a `resolved` table that mostly has all duplicates removed.
	b. double check that `resolved` table is not missing any unique accessions from master file.
		- use cut to isolate just the guid's [field 0].
			- `cut -f1 RSA_GEOREF_NON.txt`
			- save guid's to `RSA_GUID.txt`
			- sort unique `RSA_GUID.txt` to determine number of unique records.
				- if the record number is the same as the `resolved` table, then no unique records were left out.
				- if not, then use `check_lines.pl` using guid file to determine which were left out.
					- can also use vimdiff or grep to view differences if this script does not work.
						`grep -wf RSA_GUID.txt RSA_resolved.txt`
				- copy those left out from master georef file to the `resolved` table.
				
	c. file ready to e-mail to participant.

3. Resolve the issue with the Datum and Source being flipped in the buffer archives.	
	a. run `fix_datum.pl`
		- loads the `resolved` table output file.
		- loads all fields 0-7 into a hash
		- flips the source (field 6) with the datum (field 7), if the source field starts with WGS or NAD
		
		
### Duplicate Records  DUPS file
			