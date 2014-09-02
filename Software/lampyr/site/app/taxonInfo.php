<?php
        include('header_part1.php');
        include('header_part2.php');
	include('../../dblogin.php');
	include('wikipedia.php');
	echo('<body>'."\n");
	echo('<div data-role="page" data-theme="a">');
	echo('<div data-role="content"  data-theme="a">');
	$hastaxonid=false;
	$focal_taxon_id="";
	if (isset($_GET['taxonid'])) {
		if (is_numeric($_GET['taxonid'])) {
			$focal_taxon_id=mysql_real_escape_string($_GET['taxonid']);
			$hastaxonid=true;
		}
	}
	if ($hastaxonid) {
		$findsql="SELECT taxon_parent_id, taxon_name_scientific, taxon_name_common, taxon_rank_id, taxon_description, taxon_anecdote_evolution, taxon_anecdote_ecology, taxon_curator_id, taxon_genbank_taxonomy_id, taxon_quality, taxon_lastupdated FROM lampyr_taxon WHERE taxon_id='".$focal_taxon_id."'";
		$findresult=mysql_query($findsql, $dblink);
		#print($findsql);
		if (mysql_num_rows($findresult)==1) {
			echo('<h2><i>'.mysql_result($findresult,0,1).'</i>');
			if(strlen(mysql_result($findresult,0,2))>1) {
				echo(' ('.mysql_result($findresult,0,2).')');
			
			}
			echo('</h2>');
                        echo('<div data-role="collapsible" data-collapsed="true"><h3>Map to closest record</h3><p>');
                        include('taxonMapClosest.php');
                        echo('</p></div>');
			echo('<div data-role="collapsible" data-collapsed="true"><h3>Map to many individuals</h3><p>');
			include('taxonMap.php');
			echo('</p></div>');
			echo('<div data-role="collapsible" data-collapsed="true"><h3>Description</h3><p>'.WikipediaSearch(mysql_result($findresult,0,1)).'</p></div>');
			if (strlen(mysql_result($findresult,0,4))>0) {
				echo('<div data-role="collapsible" data-collapsed="true"><h3>Evolution anecdote</h3><p>'.mysql_result($findresult,0,4).'</p></div>');
			}
			if (strlen(mysql_result($findresult,0,5))>0) {
                        	echo('<div data-role="collapsible" data-collapsed="true"><h3>Ecology anecdote</h3><p>'.mysql_result($findresult,0,5).'</p></div>');
			}
                        echo('<div data-role="collapsible" data-collapsed="true"><h3>Other sites</h3><p><a href="http://ispecies.org/?q='.urlencode(mysql_result($findresult,0,1)).'" data-role="button">iSpecies</a></p></div>');
		}
	}
	echo '</div></div></body></html>';
?>
