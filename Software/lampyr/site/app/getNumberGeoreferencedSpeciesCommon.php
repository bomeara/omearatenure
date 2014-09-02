<?php
	include('../../dblogin.php');
	$countsql="select count(*) from (SELECT DISTINCT observation_taxon_id FROM lampyr_observation, lampyr_taxon WHERE (taxon_id = observation_taxon_id AND taxon_name_common IS NOT NULL) ) T1";
	$countresult=mysql_query($countsql, $dblink);
	print (number_format(mysql_result($countresult, 0)));					
?>
