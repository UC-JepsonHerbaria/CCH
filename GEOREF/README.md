# Georeference Files and Sciprts

`CDL_new_coords`  Hash file created by the georeferencing webpage.  This is the primary hash file.
`archive_cumu_coords.txt`  Text file with archives of coordinates.  This has coordinates that are in `CDL_new_coords` and some that are not.  It is not known how this file was updated.  
`georef_CUMULATIVE_cull.txt`  Manually updated cumulative georeference file.  This has had the CAS,DS,RSA and POM records removed. The coordinates that fall outside the California state boundary have been removed via QGIS spatial query.
`georef_RSAPOM_temp_oldaccessions.txt`  Manually updated RSA POM records from the above file.  This is temporry as the accession problem is delt with.


`get_georef_dups.pl`  inverse of the delete file, this will pull all duplicates into a new file


### Extracting a Full Report of Georeferences for a Participant

The georeference buffer in CCH is one that has online and offline components.  In the past, once georeferences were extacted from he hash file buffer on Annie, a script was modified and used to delete the exact buffer.  However, this yielded incomplete results as there were still georeferences in the buffer from 2012-2015 and other problem records that have never been delt with.

1.  Extract the participant records from the hash files using `get_output.pl`
	- uncomment the first section of the file to activate searching of `CDL_new_coords`
	- add the herbarium code that needs to be sreached to 
	- uncomment line 21, to search `archive_cumu_coords.txt` for additional records
	- comment out line 20, this step will be reversed later.
	
2.  The coordinates will be displayed onscreen.  Copy them all and seve them in a text file.

3.  

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
			