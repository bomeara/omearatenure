<?php
	include('../../dblogin.php');
	$countsql="SELECT COUNT(*) FROM lampyr_observation";
	$countresult=mysql_query($countsql, $dblink);
	echo(number_format(mysql_result($countresult, 0)));					
?>
