<?php
	include('../../dblogin.php');
	$countsql="SELECT COUNT(*) FROM (SELECT DISTINCT observation_taxon_id FROM lampyr_observation) T1";
	$countresult=mysql_query($countsql, $dblink);
	print (number_format(mysql_result($countresult, 0)));					
?>
