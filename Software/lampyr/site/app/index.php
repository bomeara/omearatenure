<?php
include("header_part1.php");
include("header_locationfn.php");
include("header_part2.php");

echo '<body> 

<div data-role="page" data-theme="a">
	<div data-role="header">
		<h1>Lampyr</h1>
	</div><!-- /header -->

	<div data-role="content">';
flush();
echo '	
		<p>Welcome to Lampyr. 
For more information, see our <a href="http://www.lampyr.org">webpage</a>. There are ';
include("getNumberGeoreferencedSpecies.php");
echo ' georeferenced species and ';
#include("getNumberGeoreferencedSpeciesCommon.php");
#echo ' with common names) and ';
include("getNumberPoints.php");
echo ' points in the database, so <b>it may take a minute to search</b> once you hit the button below.</p>
<form action="getNClosestTaxonIDSpeciesCommon.php" method="get" name="searchform">
	<input type="hidden" name="lat" value="">
	<input type="hidden" name="lon" value="">
	<div data-role="fieldcontain">
		<button type="submit" data-theme="b" name="submit" value="submit-value">Find closest species</button>
		<hr /><p><b>Options</b> (scroll down)
                <br /><label for="common">Use only species with common names (faster, easier to interpret, but fewer species):</label>
                <br /><select name="common" id="common" data-role="slider">
                        <option value="no">No</option>
                        <option value="yes" selected="selected">Yes</option>
                </select></p>
		<br /><label for="flip-b">Use enhanced species only (currently disabled):</label>
		<br /><select name="slider" id="flip-b" data-role="slider" disabled>
			<option value="no">No</option>
			<option value="yes">Yes</option>
		</select></p> 
		<p><label for="N">Number of species to return:</label>
		<br /><input type="range" name="N" id="N" value="25" min="1" max="250" data-theme="b" data-track-theme="b" /></p>
	</div>
</form>
</div><!-- /content -->

</div><!-- /page -->

</body>
</html>
';
?>
