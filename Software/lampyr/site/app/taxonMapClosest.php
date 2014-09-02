<?php
	include('../../dblogin.php');
 	$hastaxonid=false;
	$haslat=false;
	$haslon=false;
	$limitString=" LIMIT 1";
 	$focal_taxon_id="";
 	if (isset($_GET['taxonid'])) {
                if (is_numeric($_GET['taxonid'])) {
                        $focal_taxon_id=mysql_real_escape_string($_GET['taxonid']);
                        $hastaxonid=true;
                }
        }
        if (isset($_GET['lat'])) {
                if (is_numeric($_GET['lat'])) {
                        $lat=mysql_real_escape_string($_GET['lat']);
                        $haslat=true;
                }
        }
        if (isset($_GET['lon'])) {
                if (is_numeric($_GET['lon'])) {
                        $lon=mysql_real_escape_string($_GET['lon']);
                        $haslon=true;
                }
        }
       	if (isset($_GET['limit'])) {
                if (is_numeric($_GET['limit'])) {
                        $limitString=' LIMIT '.mysql_real_escape_string($_GET['limit']);
                }
        }
	if ($hastaxonid && $haslat && $haslon) {
		$findlocations="SELECT DISTINCT observation_latitude, observation_longitude FROM lampyr_observation WHERE observation_taxon_id='".$focal_taxon_id."' ORDER BY SQRT(((observation_longitude-".$lon.")*(observation_longitude-".$lon."))+((observation_latitude-".$lat.")*(observation_latitude-".$lat."))) ASC".$limitString;
		$locationresult=mysql_query($findlocations, $dblink);
		if (mysql_num_rows($locationresult)>0) {
			$img='http://maps.googleapis.com/maps/api/staticmap?size=280x280&sensor=true&maptype=terrain&markers=size:mid%7Ccolor:blue%7C'.$lat.",".$lon.'&markers=size:mid%7Ccolor:yellow';
			while($r = mysql_fetch_assoc($locationresult)) {
				if(strlen($img)+strlen('%7C'.$r['observation_latitude'].",".$r['observation_longitude'])<2000) { //Due to google static api limits
					$img.='%7C'.$r['observation_latitude'].",".$r['observation_longitude'];
				}
			}
			echo('<img border="0" src="'.$img.'" alt="Species records" />');
		}
	}
?>
