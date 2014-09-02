<?php
	include('/Users/bomeara/Desktop/lampyr_files_to_keep_out_of_svn/dblogin.php');
	system("curl ftp://ftp.ncbi.nih.gov/pub/taxonomy/taxdump.tar.gz > ~/Desktop/taxdump.tar.gz");
	system("open ~/Desktop/taxdump.tar.gz"); #this works only on a mac
	sleep(30);
	system("grep 'scientific name' ~/Desktop/taxdump/names.dmp | grep -v 'sp.' | grep -v 'var.' | grep -v 'Plasmid' | grep -v ' x ' | grep -v '\.' | cut -d '|' -f 1,2 > ~/Desktop/taxdump/names.scientific.dmp");
	system("grep 'genbank common name' ~/Desktop/taxdump/names.dmp | cut -d '|' -f 1,2  > ~/Desktop/taxdump/names.common.dmp");
	sleep(30);
	$file=fopen('/Users/bomeara/Desktop/taxdump/names.scientific.dmp', "r");
	#print($file);
	while(!feof($file)) {
		$newline=trim(fgets($file));
		#print($newline);
		$scientificNames = preg_split('/\|/',$newline);
		$scientificNames[0]=trim($scientificNames[0]);
		$scientificNames[1]=trim($scientificNames[1]);
		print_r($scientificNames);
		$insertionsql="INSERT INTO lampyr_taxon (taxon_name_scientific, taxon_genbank_taxonomy_id) VALUES ('".mysql_real_escape_string($scientificNames[1])."', '".mysql_real_escape_string($scientificNames[0])."')";
		$insertionresult = mysql_query($insertionsql, $dblink);
	}
	fclose($file);
        $file=fopen('/Users/bomeara/Desktop/taxdump/names.common.dmp', "r");
        print($file);
        while(!feof($file)) {
                $newline=trim(fgets($file));
		if (strlen($newline)>3) {
                	#print($newline);
                	$commonNames = preg_split('/\|/',$newline);
                	$commonNames[0]=trim($commonNames[0]);
                	$commonNames[1]=trim($commonNames[1]);
			$findsql="SELECT taxon_id FROM lampyr_taxon WHERE taxon_genbank_taxonomy_id=".mysql_real_escape_string($commonNames[0]);
			$findresult=mysql_query($findsql,$dblink);
			if (mysql_num_rows($findresult)==1) {
				$focal_taxon_id=mysql_result($findresult,0);
				$insertionsql="UPDATE lampyr_taxon SET  taxon_name_common='".mysql_real_escape_string($commonNames[1])."' WHERE taxon_genbank_taxonomy_id=".mysql_real_escape_string($commonNames[0]);
				mysql_query($insertionsql, $dblink);
				print($insertionsql);
				print("\n");
			}
		}
        }
        fclose($file);
?>
