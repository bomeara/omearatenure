<?php
	include('/Users/bomeara/Desktop/lampyr_files_to_keep_out_of_svn/dblogin.php');
	$insertOMeara="INSERT INTO lampyr_curator (curator_first, curator_middle, curator_last, curator_email, curator_website) VALUES ('Brian', 'C', '".mysql_real_escape_string("O'Meara")."', '".mysql_real_escape_string('bomeara@utk.edu')."', 'http://www.brianomeara.info')";
	print($insertOMeara);
	mysql_query($insertOMeara, $dblink);
	$insertATBI="INSERT INTO lampyr_source (source_name, source_url, source_date_accessed) VALUES ('ATBI', 'http://www.dlia.org/node/204', UTC_TIMESTAMP() )";
	mysql_query($insertATBI, $dblink); 
	$file=fopen('/Users/bomeara/Desktop/atbi.pruned.txt', "r");
        while(!feof($file)) {
                $newline=trim(fgets($file));
		if (strlen($newline)>3) {
#                	print($newline);
			$taxon=trim($newline);
			$findsql="SELECT taxon_id FROM lampyr_taxon WHERE taxon_name_scientific='".mysql_real_escape_string($taxon)."'";
			$findresult=mysql_query($findsql,$dblink);
			if (mysql_num_rows($findresult)==1) {
				print("\nSuccess: ".$taxon);
				$focal_taxon_id=mysql_result($findresult,0);
				
				$updatesql="UPDATE lampyr_taxon SET  taxon_quality=2 WHERE taxon_id=".$focal_taxon_id;
				mysql_query($updatesql, $dblink);
				$insertsql="INSERT INTO lampyr_observation (observation_latitude, observation_longitude, observation_precision_km, observation_source_id, observation_taxon_id, observation_curator_id) VALUES ('35.5834273', '-83.4998852', '42', '1', '".$focal_taxon_id."', '1')";
				mysql_query($insertsql, $dblink);
			}
			else {
				print("\nFailure: ".$taxon);
				$insertsql="INSERT INTO lampyr_taxon (taxon_name_scientific, taxon_quality) VALUES ('".mysql_real_escape_string($taxon)."', '1')";
				mysql_query($insertsql, $dblink);
	                      	$findsql="SELECT taxon_id FROM lampyr_taxon WHERE taxon_name_scientific='".mysql_real_escape_string($taxon)."'";
        	                $findresult=mysql_query($findsql,$dblink);
                	        if (mysql_num_rows($findresult)==1) {
					$focal_taxon_id=mysql_result($findresult,0);
					$insertsql="INSERT INTO lampyr_observation (observation_latitude, observation_longitude, observation_precision_km, observation_source_id, observation_taxon_id, observation_curator_id) VALUES ('35.5834273', '-83.4998852', '42', '1', '".$focal_taxon_id."', '1')";
                                	#print($insertsql."\n");
                                	mysql_query($insertsql, $dblink);
				}
			}
		}
        }
        fclose($file);
?>
