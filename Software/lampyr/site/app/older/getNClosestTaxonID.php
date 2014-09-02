<?php
	include('../../dblogin.php');
	$hasN=false;
	$N=25;
	if (isset($_GET['N'])) {
		if (is_numeric($_GET['N'])) {
			$N=mysql_real_escape_string($_GET['N']);
			$hasN=true;
		}
	}
	if (isset($_GET['lon'])) {
		if (is_numeric($_GET['lon'])) {
			if (isset($_GET['lat'])) {
				if (is_numeric($_GET['lat'])) {
					$lon=mysql_real_escape_string($_GET['lon']);
					$lat=mysql_real_escape_string($_GET['lat']);
					$nearestsql="SELECT * FROM ( SELECT DISTINCT observation_taxon_id FROM lampyr_observation ORDER BY SQRT(((observation_longitude-".$lon.")*(observation_longitude-".$lon."))+((observation_latitude-".$lat.")*(observation_latitude-".$lat."))) ASC ) T1 ORDER BY RAND() LIMIT ".$N; #uses trick from http://stackoverflow.com/questions/2882647/mysql-order-by-rand-name-asc to get random order in case of ties
					$nearestresult=mysql_query($nearestsql,$dblink);
					if (mysql_num_rows($nearestresult)>0) {
                        			$rows = array();
                        			while($r = mysql_fetch_assoc($nearestresult)) {
                                			$rows[] = $r;
                        			}
                       			 	echo json_encode($rows);
			                }

				}
			}
		}
	}
?>
