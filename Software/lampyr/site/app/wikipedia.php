<?php
// Modified by Brian O'Meara, May 4, 2012 from original iSpecies code. iSpecies is GPL2; this is now GPL3

// from http://phpsense.com/php/php-word-splitter.html
function word_split($str,$words=15) {
  $arr = preg_split("/[\s]+/", $str,$words+1);
  $arr = array_slice($arr,0,$words);
  return join(' ',$arr);
}

function extractText($xml)
{
        $xml = preg_replace('/<mediawiki(.*)>/', '<mediawiki>', $xml );
                
        $dom= new DOMDocument;
        $dom->loadXML($xml);
        //echo $xml;
        
        $xpath = new DOMXPath($dom);
        $xpath_query = "//page/revision/text";
        $nodeCollection = $xpath->query ($xpath_query);
        
        $result = '';
        
        foreach($nodeCollection as $node)
        {
                $result = $node->firstChild->nodeValue;
        }

        return $result;
}

function extractId($xml)
{
        $xml = preg_replace('/<mediawiki(.*)>/U', '<mediawiki>', $xml );
                
        $dom= new DOMDocument;
        $dom->loadXML($xml);
        //echo "\n\nXML=$xml";
        
        $xpath = new DOMXPath($dom);
        $xpath_query = "//page/id";
        $nodeCollection = $xpath->query ($xpath_query);
        
        $id = 0;
        
        foreach($nodeCollection as $node)
        {
                $id = $node->firstChild->nodeValue;
        }

        return $id;
}

/**
 *@brief Search Wikipeda
 *
  *
 * @param $search Search string 
 *
 * @return XML result from Yahoo
 *
 */
function WikipediaSearch ($search)
{
        global $config;
        
        $topic = $search;
        $topicId = 0;
        
        $result = '';
        
        $url = "http://en.wikipedia.org/w/index.php?title=Special:Export/"
                . str_replace (" ", "_", $search);

                
        //echo $url;
        
        $ch = curl_init(); 
        curl_setopt($ch, CURLOPT_URL, $url); 
        curl_setopt ($ch, CURLOPT_RETURNTRANSFER, 1); 
        curl_setopt ($ch,CURLOPT_USERAGENT,"iSpecies"); 
        if ($config['proxy_name'] != '')
        {
                curl_setopt ($ch, CURLOPT_PROXY, $config['proxy_name'] . ':' . $config['proxy_port']);
        }

        $xml=curl_exec ($ch); 
        
        if( curl_errno ($ch) != 0 )
        {
        }
                
        $result = extractText($xml);    
        $topicId = extractId($xml);

        if ('' == $result)
        {
                // no Wikipedia page for this topic
        }
        
        if (preg_match('/#redirect/i', $result))
        {
                // Wikipedia page exists under a different title, so handle redirect
                $topic = $result;
                $topic = preg_replace('/#redirect/i', '', $topic);
                $topic = preg_replace('/\[\[/', '', $topic);
                $topic = preg_replace('/\]\]/', '', $topic);
                $topic = preg_replace("/{{.*?}}/m", '', $topic );
                $topic = trim($topic);
                
                $url = "http://en.wikipedia.org/w/index.php?title=Special:Export/"
                        . str_replace (" ", "_", $topic);
                curl_setopt($ch, CURLOPT_URL, $url); 
                
                $xml=curl_exec ($ch); 
                if( curl_errno ($ch) != 0 )
                {
                }
                
                $result = extractText($xml);
                $topicId = extractId($xml);

        }
        curl_close ($ch); 
        
        if ('' != $result)
        {
                // extract snippet we want.
                // Remove Taxobox
                $lines = split("\n", $result);
                $n = count($lines);
                $i = 0;
                $done = false;
                while (($done === false) and ($i < $n))
                {
                        if (preg_match('/}}/', $lines[$i]))
                        {
                                $done = !preg_match('/{{/', $lines[$i]);
                        }
                
                        $i++;
                }
                
                if ($i == $n)
                {
                        $i = 0;
                }
                
                $arr = array_slice($lines,$i);          
                
                $w =  join(' ',$arr);
                
                $w = preg_replace('/<!--(.*)-->/', '', $w );
                $w = preg_replace('/__TOC__/', '', $w );
               	$w = preg_replace('/\[\[File.*\]\]/m',"",$w);
		$w = preg_replace('/\{\{convert.*([\d\.]+)\|(\w+?)[^\}]*\}\}/mU',"$1 $2",$w);  

                $w = preg_replace('/\[\w+([\s\w\(\)])*\|(\w+(\s\w+)*)]/', '$2', $w );

                $w = preg_replace('/\[/', '', $w );
                $w = preg_replace('/\]/', '', $w );
                $w = preg_replace("/'/", '', $w );
		$w = preg_replace("/<ref[^>]*\/>/m","",$w);
		$w = preg_replace("/<ref.*?<\/ref>/m", '', $w );
                $w = preg_replace("/{{.*?}}/m", '', $w );
                                
                // trim before headings
                $pos = strpos($w, '==');
                if ($pos === false)
                {
                }
                else
                {
                        $w = substr($w, 0, $pos);
                }

                //$w = word_split($w, 100) . '...';
                
                $html = 'From <a href="http://en.wikipedia.org/wiki/index.html?curid=' . $topicId . '" target="_blank">Wikipedia article</a>: '. $w;
                
                $result = $html;
        }
	else {
		$result = "No results found, sorry";
	}

        
        
        return $result;
}

//$s = "Parkesia motacilla";
//echo WikipediaSearch($s);

?>

