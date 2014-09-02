<?php
echo('
<!DOCTYPE html> 
<html> 
	<head> 
	<title>Lampyr</title> 
	<meta name="viewport" content="width=device-width, initial-scale=1"> 
	<link rel="stylesheet" href="http://code.jquery.com/mobile/1.0/jquery.mobile-1.0.min.css" />
	<link rel="apple-touch-icon" href="../images/icon.png">
	<script type="text/javascript" src="http://code.jquery.com/jquery-1.6.4.min.js"></script>
	<script type="text/javascript" src="http://code.jquery.com/mobile/1.0/jquery.mobile-1.0.min.js"></script>
	<script type="text/javascript">
        	jQuery(window).ready(function(){
//            		jQuery("#btnInit").click(initiate_geolocation);
			initiate_geolocation();
        	});

        	function initiate_geolocation() {
            		navigator.geolocation.getCurrentPosition(handle_geolocation_query);
        	}

		function handle_geolocation_query(position) {
//			$.getJSON("getNClosestTaxonID.php?lon=" + position.coords.longitude + "&lat=" + position.coords.latitude, function(json) {alert(data);});
//			alert("location");
alert("Lat: " + position.coords.latitude + " " +  
                  "Lon: " + position.coords.longitude);  
$.getJSON("http://www.lampyr.org/app/getNClosestTaxonID.php?lon=" + position.coords.longitude + "&lat=" + position.coords.latitude, function(json) {alert(data);});
alert("try 2");
		}
	</script>
  	
</head> ');
?>
