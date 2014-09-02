<?php
echo('

	<script type="text/javascript">
        	jQuery(window).ready(function(){
			initiate_geolocation();
        	});

        	function initiate_geolocation() {
            		navigator.geolocation.getCurrentPosition(handle_geolocation_data);
        	}
		
		function handle_geolocation_data(position) {
                        document.searchform.lat.value=position.coords.latitude;
                        document.searchform.lon.value=position.coords.longitude;
		}
  	</script>	

');
?>
