<?php
	include('../../dblogin.php');
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
			$rows = array();
			while($r = mysql_fetch_assoc($findresult)) {
 				$rows[] = $r;
			}
			echo json_encode($rows);
		}
	}
?>
