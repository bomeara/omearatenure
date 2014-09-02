<?php
	include('../../dblogin.php');
	$hasquality=false;
	$focal_quality="";
	$rowsPerQuery=100;
	if (isset($_GET['quality'])) {
		if (is_numeric($_GET['quality'])) {
			$focal_quality=mysql_real_escape_string($_GET['quality']);
			$hasquality=true;
		}
	}
	$countsql="SELECT COUNT(*) FROM lampyr_taxon ";
        if ($hasquality) {
                $countsql=$countsql." WHERE taxon_quality='".$focal_quality."'";
        }
        $countresult=mysql_query($countsql, $dblink);
	$numberQueries=ceil(mysql_result($countresult, 0)/$rowsPerQuery);
	mysql_free_result($countresult);
	for ($queryIndex = 0; $queryIndex<$numberQueries; $queryIndex++) {
		$findsql="SELECT taxon_id FROM lampyr_taxon ";
		if ($hasquality) {
			$findsql=$findsql." WHERE taxon_quality='".$focal_quality."'";
		}
		$findsql=$findsql." LIMIT ".$queryIndex.", ".$rowsPerQuery;
		$findresult=mysql_query($findsql, $dblink);
		#print($findsql);
		if (mysql_num_rows($findresult)>0) {
			$rows = array();
			while($r = mysql_fetch_assoc($findresult)) {
 				$rows[] = $r;
			}
			echo json_encode($rows);
		}
		mysql_free_result($findresult);
	}
?>
