<?php

	include('/Library/WebServer/Sites/lampyr.org/lampyrGoogleCode/dblogin.php');
	$str=file_get_contents("http://lampyr.org/app/getNClosestTaxonIDSpeciesCommon.php?lat=".rand(0,89)."&lon=-".rand(0,179)."&submit=submit-value&common=yes&N=25");
?>
