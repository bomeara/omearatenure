<?php
//fn for direction from http://www.dougv.com/2009/07/13/calculating-the-bearing-and-compass-rose-direction-between-two-latitude-longitude-coordinates-in-php/
function getCompassDirection($bearing) {
     $tmp = round($bearing / 22.5);
     switch($tmp) {
          case 1:
               $direction = "NNE";
               break;
          case 2:
               $direction = "NE";
               break;
          case 3:
               $direction = "ENE";
               break;
          case 4:
               $direction = "E";
               break;
          case 5:
               $direction = "ESE";
               break;
          case 6:
               $direction = "SE";
               break;
          case 7:
               $direction = "SSE";
               break;
          case 8:
               $direction = "S";
               break;
          case 9:
               $direction = "SSW";
               break;
          case 10:
               $direction = "SW";
               break;
          case 11:
               $direction = "WSW";
               break;
          case 12:
               $direction = "W";
               break;
          case 13:
               $direction = "WNW";
               break;
          case 14:
               $direction = "NW";
               break;
          case 15:
               $direction = "NNW";
               break;
          default:
               $direction = "N";
     }
     return $direction;
}

	include('../../dblogin.php');
echo '<body>

<div data-role="page" data-theme="a">
        <div data-role="header">
                <h1>Lampyr</h1>
        </div><!-- /header -->

        <div data-role="content">';
	$hasN=false;
	$N=25;
	$justcommon=false;
	$milerange=20;
	if (isset($_GET['N'])) {
		if (is_numeric($_GET['N'])) {
			$N=mysql_real_escape_string($_GET['N']);
			$hasN=true;
		}
	}
	if (isset($_GET['milerange'])) {
		if (is_numeric($_GET['milerange'])) {
			$milerange=mysql_real_escape_string($_GET['milerange']);
		}
	}
	if (isset($_GET['common'])) {
		if ($_GET['common']=='yes') {
			$justcommon=true;
		}
	}
	$nextmilerange=$milerange;
	
	if (isset($_GET['lon'])) {
		if (is_numeric($_GET['lon'])) {
			if (isset($_GET['lat'])) {
				if (is_numeric($_GET['lat'])) {
					$matchingSpeciesCount=0;
					$lon=mysql_real_escape_string($_GET['lon']);
					$lat=mysql_real_escape_string($_GET['lat']);
					$maxlat=90; #just initializing these so they will be in scope for the nearestsql calls
					$minlat=-90;
					$maxlon=180;
					$minlon=-180;
					//Bounding box uses script copyright Chris Veness,  http://www.movable-type.co.uk/scripts/latlong-db.html
					// first-cut bounding box (in degrees)
					while($matchingSpeciesCount<$N) {
						$milerange=$nextmilerange;
						if ($milerange<100) {
							$nextmilerange=$milerange+10;
						}
						else {
							$nextmilerange=$milerange+50; #because you either want a lot of species or no one dares collect where you are now. Run!
						}
						$R=3959; //radius of earth in miles
						$maxlat = $lat + rad2deg($milerange/$R);
						$minlat = $lat - rad2deg($milerange/$R);
						$maxlat=min(90,$maxlat);
						$minlat=max(-90,$minlat);
						// compensate for degrees longitude getting smaller with increasing latitude
						$maxlon = $lon + rad2deg($milerange/$R/cos(deg2rad($lat)));
						$minlon = $lon - rad2deg($milerange/$R/cos(deg2rad($lat)));
						if ($maxlon>180 || $minlon<-180) { #for users spanning this line, do a belt around the whole world. Sorry.
							$maxlon=180;
							$minlon=-180;
						}
						$countnearestsql="SELECT DISTINCT observation_taxon_id FROM lampyr_observation WHERE ( (observation_latitude BETWEEN ".$minlat." AND ".$maxlat.") AND (observation_longitude BETWEEN ".$minlon." AND ".$maxlon.") )";
						if ($justcommon) {
							$countnearestsql="SELECT DISTINCT observation_taxon_id FROM lampyr_observation, lampyr_taxon WHERE ( (taxon_id = observation_taxon_id) AND (taxon_name_common IS NOT NULL ) AND  (observation_latitude BETWEEN ".$minlat." AND ".$maxlat.") AND (observation_longitude BETWEEN ".$minlon." AND ".$maxlon.") )";
						}
						$countnearestresult=mysql_query($countnearestsql,$dblink);
						$matchingSpeciesCount=mysql_num_rows($countnearestresult);
					}
					#$nearestsql="SELECT * FROM ( SELECT DISTINCT observation_taxon_id FROM lampyr_observation ORDER BY SQRT(((observation_longitude-".$lon.")*(observation_longitude-".$lon."))+((observation_latitude-".$lat.")*(observation_latitude-".$lat."))) ASC ) T1 ORDER BY RAND() LIMIT ".$N; #uses trick from http://stackoverflow.com/questions/2882647/mysql-order-by-rand-name-asc to get random order in case of ties
#	  				$nearestsql="SELECT DISTINCT observation_taxon_id FROM (SELECT observation_taxon_id, ( 3959 * acos( cos( radians(".$lat.") ) * cos( radians( observation_latitude ) ) * cos( radians( observation_longitude ) - radians(".$lon.") ) + sin( radians(".$lat.") ) * sin( radians( observation_latitude ) ) ) ) AS distance FROM (SELECT * from lampyr_observation ORDER BY RAND() ) T2 ORDER BY distance ) T1 LIMIT ".$N; //First randomize order of lampyr table (so ties are chosen randomly), then get all the distances and order by them, then take the closest $N distinct taxa.
                                       #$nearestsql="SELECT DISTINCT observation_taxon_id FROM (SELECT observation_taxon_id, ( 3959 * acos( cos( radians(".$lat.") ) * cos( radians( observation_latitude ) ) * cos( radians( observation_longitude ) - radians(".$lon.") ) + sin( radians(".$lat.") ) * sin( radians( observation_latitude ) ) ) ) AS distance FROM (SELECT * from lampyr_observation, lampyr_taxon WHERE taxon_id = observation_taxon_id ORDER BY RAND() ) T2 ORDER BY distance ) T1 LIMIT ".$N; //First randomize order of lampyr table (so ties are chosen randomly), then get all the distances and order by them, then take the closest $N distinct taxa.
                                       $nearestsql="SELECT DISTINCT observation_taxon_id FROM (SELECT observation_taxon_id, ( 3959 * acos( cos( radians(".$lat.") ) * cos( radians( observation_latitude ) ) * cos( radians( observation_longitude ) - radians(".$lon.") ) + sin( radians(".$lat.") ) * sin( radians( observation_latitude ) ) ) ) AS distance FROM (SELECT * from lampyr_observation, lampyr_taxon WHERE ( (taxon_id = observation_taxon_id) AND (observation_latitude BETWEEN ".$minlat." AND ".$maxlat.") AND (observation_longitude BETWEEN ".$minlon." AND ".$maxlon.") )ORDER BY RAND() ) T2 ORDER BY distance ) T1 LIMIT ".$N; //First randomize order of lampyr table (so ties are chosen randomly), then get all the distances and order by them, then take the closest $N distinct taxa.
					if ($justcommon) {
	                                  #     $nearestsql="SELECT DISTINCT observation_taxon_id FROM (SELECT observation_taxon_id, ( 3959 * acos( cos( radians(".$lat.") ) * cos( radians( observation_latitude ) ) * cos( radians( observation_longitude ) - radians(".$lon.") ) + sin( radians(".$lat.") ) * sin( radians( observation_latitude ) ) ) ) AS distance FROM (SELECT * from lampyr_observation, lampyr_taxon WHERE ( (taxon_id = observation_taxon_id) AND taxon_name_common IS NOT NULL  ) ORDER BY RAND() ) T2 ORDER BY distance ) T1 LIMIT ".$N; //First randomize order of lampyr table (so ties are chosen randomly), then get all the distances and order by them, then take the closest $N distinct taxa.
                                                $nearestsql="SELECT DISTINCT observation_taxon_id FROM (SELECT observation_taxon_id, ( 3959 * acos( cos( radians(".$lat.") ) * cos( radians( observation_latitude ) ) * cos( radians( observation_longitude ) - radians(".$lon.") ) + sin( radians(".$lat.") ) * sin( radians( observation_latitude ) ) ) ) AS distance FROM (SELECT * from lampyr_observation, lampyr_taxon WHERE ( (taxon_id = observation_taxon_id) AND (taxon_name_common IS NOT NULL) AND (observation_latitude BETWEEN ".$minlat." AND ".$maxlat.") AND (observation_longitude BETWEEN ".$minlon." AND ".$maxlon.")  ) ORDER BY RAND() ) T2 ORDER BY distance ) T1 LIMIT ".$N; //First randomize order of lampyr table (so ties are chosen randomly), then get all the distances and order by them, then take the closest $N distinct taxa.
					}
					$nearestresult=mysql_query($nearestsql,$dblink);
					if (mysql_num_rows($nearestresult)>0) {
                        			$rows = array();
                        			while($r = mysql_fetch_assoc($nearestresult)) {
							//print_r($r);
							//print("\n");
							$speciessql="SELECT taxon_id, taxon_name_scientific, taxon_name_common FROM lampyr_taxon WHERE taxon_id = '".mysql_real_escape_string($r['observation_taxon_id'])."'";
							//print($speciessql."\n");
							$speciesresult=mysql_query($speciessql,$dblink);
							if (mysql_num_rows($speciesresult)==1) {
                                				//$rows[] = $mysql_fetch_assoc($speciesresult);
								echo('\n'.mysql_result($speciesresult,0,0).'\t'.mysql_result($speciesresult,0,1).'\t');
								if(strlen(mysql_result($speciesresult,0,2))>1) {
									echo('\t'.mysql_result($speciesresult,0,2));
								}
								else {
									echo('\t');
								}
								$distancesql="SELECT observation_latitude, observation_longitude, ( 3959 * acos( cos( radians(".$lat.") ) * cos( radians( observation_latitude ) ) * cos( radians( observation_longitude ) - radians(".$lon.") ) + sin( radians(".$lat.") ) * sin( radians( observation_latitude ) ) ) ) AS distance FROM lampyr_observation WHERE observation_taxon_id = '".mysql_real_escape_string($r['observation_taxon_id'])."' ORDER BY distance LIMIT 0,1";
                                                                $distanceresult=mysql_query($distancesql, $dblink);
								if (mysql_num_rows($distanceresult)==1) {
                                                                	//fn for bearing from http://www.dougv.com/2009/07/13/calculating-the-bearing-and-compass-rose-direction-between-two-latitude-longitude-coordinates-in-php/
                                                                	$bearing = (rad2deg(atan2(sin(deg2rad(mysql_result($distanceresult,0,1)) - deg2rad($lon)) * cos(deg2rad(mysql_result($distanceresult,0,0))), cos(deg2rad($lat)) * sin(deg2rad(mysql_result($distanceresult,0,0))) - sin(deg2rad($lat)) * cos(deg2rad(mysql_result($distanceresult,0,0))) * cos(deg2rad(mysql_result($distanceresult,0,1)) - deg2rad($lon)))) + 360) % 360;
									echo ('\t'.round(mysql_result($distanceresult,0,2),1)." mi ".getCompassDirection($bearing));
								}
							}
                        			}
                       			 	//echo json_encode($rows);
			                }

				}
			}
		}
	}
?>
