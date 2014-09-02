<?php
	include('/Users/bomeara/Desktop/lampyr_files_to_keep_out_of_svn/dblogin.php');
	$referenceNumber=$argv[1];
	print($referenceNumber);
	$insertATBI="INSERT INTO lampyr_source (source_gbif_accession, source_date_accessed) VALUES ('".mysql_real_escape_string($referenceNumber)."', UTC_TIMESTAMP() )";
	print($insertATBI);
	mysql_query($insertATBI, $dblink); 
	$selectSourceSQL="SELECT source_id FROM lampyr_source WHERE source_gbif_accession='".mysql_real_escape_string($referenceNumber)."'";
	$selectSourceResult=mysql_query($selectSourceSQL,$dblink);
	if (mysql_num_rows($selectSourceResult)==1) {
		$sourceID=mysql_result($selectSourceResult,0);
	
		$file=fopen('/Library/WebServer/Sites/lampyr.org/lampyrGoogleCode/initialization/gbif/gbif_dataresource_'.$referenceNumber.'.csv', "r");
    	   	while(!feof($file)) {
  	              $newline=trim(fgets($file));
			if (strlen($newline)>3) {
	#                	print($newline);
				$splitArray=explode(',',$newline);
				$taxon=ucfirst(strtolower(trim($splitArray[0])));
				$lat=trim($splitArray[1]);
				$lon=trim($splitArray[2]);
				$findsql="SELECT taxon_id FROM lampyr_taxon WHERE taxon_name_scientific='".mysql_real_escape_string($taxon)."'";
				$findresult=mysql_query($findsql,$dblink);
				if (mysql_num_rows($findresult)==1) {
					#print("\nSuccess: ".$taxon);
					$focal_taxon_id=mysql_result($findresult,0);
					
					$updatesql="UPDATE lampyr_taxon SET  taxon_quality=2 WHERE taxon_id=".$focal_taxon_id;
					mysql_query($updatesql, $dblink);
					$insertsql="INSERT INTO lampyr_observation (observation_latitude, observation_longitude, observation_source_id, observation_taxon_id, observation_curator_id) VALUES ('".mysql_real_escape_string($lat)."', '".mysql_real_escape_string($lon)."',  '".$sourceID."', '".$focal_taxon_id."', '1')";
					mysql_query($insertsql, $dblink);
				}
				else {
					#print("\nFailure: ".$taxon);
					$insertsql="INSERT INTO lampyr_taxon (taxon_name_scientific, taxon_quality) VALUES ('".mysql_real_escape_string($taxon)."', '1')";
					mysql_query($insertsql, $dblink);
		                      	$findsql="SELECT taxon_id FROM lampyr_taxon WHERE taxon_name_scientific='".mysql_real_escape_string($taxon)."'";
	       	 	                $findresult=mysql_query($findsql,$dblink);
	      	          	        if (mysql_num_rows($findresult)==1) {
						$focal_taxon_id=mysql_result($findresult,0);
		                                $insertsql="INSERT INTO lampyr_observation (observation_latitude, observation_longitude, observation_source_id, observation_taxon_id, observation_curator_id) VALUES ('".mysql_real_escape_string($lat)."', '".mysql_real_escape_string($lon)."',  '".$sourceID."', '".$focal_taxon_id."', '1')";

	                                	#print($insertsql."\n");
	                                	mysql_query($insertsql, $dblink);
					}
				}
			}
        	}
        	fclose($file);
	}
?>
