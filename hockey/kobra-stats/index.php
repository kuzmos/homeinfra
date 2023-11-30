<?php

// MIT License
//
// Copyright (c) 2023 kuzmos
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

// Function to parse event data from HTML content
function parseEventData($htmlContent,$query) {
    $dom = new DOMDocument;
    libxml_use_internal_errors(true);
    $dom->loadHTML($htmlContent);
    libxml_clear_errors();

    $xpath = new DOMXPath($dom);

    //$query = '//table/tbody/tr[contains(td[4], "HC Kobra Praha") and starts-with(td[2], "gól")]';

    $trElements = $xpath->query($query);

    $relevantData = [];
    foreach ($trElements as $tr) {
        $tdElements = $tr->getElementsByTagName('td');
        if ($tdElements->length >= 3) {
            $goalContent = trim($tdElements->item(2)->textContent);
            $goalDetails = extractGoalDetails($goalContent);

            $relevantData[] = [
                'Time' => trim($tdElements->item(0)->textContent),
                'Goal' => $goalDetails['Goal'],
                'Assistances' => $goalDetails['Assistances'],
            ];
        }
    }

    return $relevantData;
}

// Function to extract goal details, including assistances, from goal content
function extractGoalDetails($goalContent) {
    $goalDetails = ['Goal' => $goalContent, 'Assistances' => []];

    // Check if the goal content is in brackets
    if (preg_match('/\(([^)]+)\)/', $goalContent, $matches)) {
        $assistanceValues = array_filter(array_map('trim', explode(',', $matches[1])));

        // Split Assistance 1 and Assistance 2 into separate Assistances
        if (!empty($assistanceValues)) {
            $goalDetails['Assistances'] = $assistanceValues;
        }

        // Remove the brackets and content inside from the goal
        $goalDetails['Goal'] = trim(preg_replace('/\([^)]+\)/', '', $goalContent));
    }

    return $goalDetails;
}

// Function to parse additional match information from HTML content
function parseMatchData($htmlContent,$infoQuery) {
    $dom = new DOMDocument;
    libxml_use_internal_errors(true);
    $dom->loadHTML($htmlContent);
    libxml_clear_errors();

    $xpath = new DOMXPath($dom);

    //$infoQuery = '//table[contains(@class, "sortable")]/tr/th | //table[contains(@class, "sortable")]/tr/td';
    $infoElements = $xpath->query($infoQuery);

    $matchInfo = [];
    $currentKey = null;
    foreach ($infoElements as $infoElement) {
        $nodeValue = trim($infoElement->nodeValue);

        if ($infoElement->nodeName === 'th') {
            $currentKey = $nodeValue;
        } elseif ($currentKey !== null) {
            $matchInfo[$currentKey] = $nodeValue;
            $currentKey = null;
        }
    }

    return $matchInfo;
}

// Load the configuration file
$config = parse_ini_file('config.ini', true);

if (isset($config['url']['base_url'])) {
    $base_url = $config['url']['base_url'];
    $points_query = $config['query']['points_query'];
    $match_info_query = $config['query']['match_info_query'];
    $pattern = $config['query']['match_id_pattern'];
    $min_cache_age = $config['cache']['min_age'];
    $max_cache_age = $config['cache']['max_age'];

    $html_base = file_get_contents($base_url);

    //$pattern = '/data-matchId="(\d+)"/';
    preg_match_all($pattern, $html_base, $matches);

    if (!empty($matches[1])) {
        $matchIds = $matches[1];
        // Initialize global counters
        $globalGoalCount = [];
        $globalAssistanceCount = [];

        echo "<!DOCTYPE html>";
        echo "<html lang='cs-cz'>";
        echo "<head>";
	echo "<meta charset='utf-8'>";
	echo "<meta http-equiv='X-UA-Compatible' content='IE=edge,chrome=1'>";
	echo "<meta name='viewport' content='width=device-width, initial-scale=1.0, minimum-scale=1.0, maximum-scale=1.0, user-scalable=no'>";
        echo "<title>Kobra mladší žáci B - statistiky 2023/2024</title>";
        echo "<link href='https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/css/bootstrap.min.css' rel='stylesheet' integrity='sha384-rbsA2VBKQhggwzxH7pPCaAqO46MgnOM80zW1RWuH61DGLwZJEdK2Kadq2F9CUG65' crossorigin='anonymous'>";
	echo "<link rel='stylesheet' href='https://cdn.datatables.net/1.13.8/css/dataTables.bootstrap5.min.css'>";
	echo "<script src='https://cdn.datatables.net/1.13.8/js/jquery.dataTables.min.js'></script>";
	echo "<script src='https://cdn.datatables.net/1.13.8/js/dataTables.bootstrap5.min.js'></script>";
	echo "<script src='https://cdn.jsdelivr.net/npm/bootstrap@5.2.3/dist/js/bootstrap.bundle.min.js' integrity='sha384-kenU1KFdBIe4zVF0s0G1M5b4hcpxyD9F7jL+jjXkk+Q2h455rYXK/7HAuoJl+0I4' crossorigin='anonymous'></script>";
        echo "<script>";
        echo "$(document).ready(function() {";
	echo "$('.sortable').DataTable();";
	echo "$('.dataTables_length').addClass('bs-select');";
        echo "});";
        echo "</script>";

        echo "</head>";
        echo "<body>";
        echo "<div class='container'>";

        // Add h1 with title
	echo "<br/>";
	echo "<h1 id='top'>Kobra mladší žáci B - statistiky 2023/2024</h1>";
	echo "<img src='Kobra_Praha_logo.png' class='img-fluid'>";
	echo "<br/>";
	echo "<br/>";
	echo "<h2><a href='#celkovestatistiky'>Celkové bodování hráčů</a></h2>";
	echo "<br/>";
	echo "<br/>";
        foreach ($matchIds as $matchId) {
            //$cache_dir = getenv("HOME") . "/.cache/kobra-stats";
            $cache_dir = ".cache/kobra-stats";
            if (!file_exists($cache_dir)) {
                mkdir($cache_dir, 0777, true);
            }

            $cache_file = $cache_dir . "/match_" . $matchId . ".html";
            $fetch = true;
            $cache_age = 0;

            if (file_exists($cache_file)) {
                $cache_age = (time() - filemtime($cache_file)) / 60; // age in minutes
                $fetch = $cache_age > rand($min_cache_age, $max_cache_age);
            }

            if ($fetch) {
                $html = file_get_contents($base_url . "&matchId=" . $matchId);
                file_put_contents($cache_file, $html);
            } else {
                $html = file_get_contents($cache_file);
            }

            $result = parseEventData($html,$points_query);
            $matchInfo = parseMatchData($html,$match_info_query);

	    $matchtitle = ""; 
	    foreach ($matchInfo as $key => $value) {
                $matchtitle=$matchtitle . " " . htmlspecialchars($value);
	    }
            echo "<h2>" . $matchtitle . "</h2>";

            // Display link to HTML
            echo "<p><a href='{$base_url}&matchId={$matchId}' target='_blank'>{$base_url}&matchId={$matchId}</a></p>";
	    echo "<p><abbr title='Data source: "  .  ($fetch ? "fetched" : "cache") . ", cache age: " . round($cache_age) . " min' class='initialism'>zdroj</abbr></p>";
            echo "<h4>Info o zápase</h2>";
            // Display additional match information
            echo "<table class='table table-bordered sortable'>";
            foreach ($matchInfo as $key => $value) {
                echo "<tr>";
                echo "<th>$key</th>";
                echo "<td>" . htmlspecialchars($value) . "</td>";
                echo "</tr>";
            }
            echo "</table>";

	    echo "<br/>";
            // Update global counters
            foreach ($result as $data) {
                if (!empty($data['Goal'])) {
                    $globalGoalCount[$data['Goal']] = isset($globalGoalCount[$data['Goal']]) ? $globalGoalCount[$data['Goal']] + 1 : 1;
                }

                foreach ($data['Assistances'] as $assistance) {
                    if (!empty($assistance)) {
                        $globalAssistanceCount[$assistance] = isset($globalAssistanceCount[$assistance]) ? $globalAssistanceCount[$assistance] + 1 : 1;
                    }
                }
            }

            if (!empty($result)) {
		 // Display goal and assistance information

                echo "<h4>Góly a nahrávky</h4>";
                echo "<table class='table table-bordered sortable table-hover'>";
                echo "<thead class='table-light'><tr><th>Čas</th><th>Gól</th><th>Nahrávky</th></tr></thead>";
                echo "<tbody>";
                // Initialize local counters
                $goalCount = [];
                $assistanceCount = [];
                foreach ($result as $data) {
                    echo "<tr>";
                    echo "<td>" . htmlspecialchars($data['Time']) . "</td>";
                    echo "<td>" . htmlspecialchars($data['Goal']) . "</td>";
                    echo "<td>" . htmlspecialchars(implode(', ', $data['Assistances'])) . "</td>";
                    echo "</tr>";
                    // Update counters for non-empty values
                    if (!empty($data['Goal'])) {
                        $goalCount[$data['Goal']] = isset($goalCount[$data['Goal']]) ? $goalCount[$data['Goal']] + 1 : 1;
                    }

                    // Update counters for each assistance
                    foreach ($data['Assistances'] as $assistance) {
                        // Iterate over each assistance
                        if (!empty($assistance)) {
                            $assistanceCount[$assistance] = isset($assistanceCount[$assistance]) ? $assistanceCount[$assistance] + 1 : 1;
                        }
                    }
                }
                echo "</tbody>";
                echo "</table>";

                // Output local counters in a table
                echo "<h4>Statistiky hráčů za zápas</h4>";
                echo "<table class='table table-bordered sortable table-hover'>";
                echo "<thead class='table-light'><tr><th>Hráč</th><th>Góly</th><th>Nahrávky</th><th>Body</th></tr></thead>";
                echo "<tbody>";
                foreach (array_keys($goalCount + $assistanceCount) as $player) {
                    echo "<tr>";
                    echo "<td>" . htmlspecialchars($player) . "</td>";
                    echo "<td>" . (isset($goalCount[$player]) ? $goalCount[$player] : 0) . "</td>";
                    echo "<td>" . (isset($assistanceCount[$player]) ? $assistanceCount[$player] : 0) . "</td>";
                    echo "<td>" . (isset($goalCount[$player]) ? $goalCount[$player] : 0) + (isset($assistanceCount[$player]) ? $assistanceCount[$player] : 0) . "</td>";
                    echo "</tr>";
                }
                echo "</tbody>";
                echo "</table>";
		echo "<br/>";
	    }
	    echo "<a href='#top'>Na začátek stránky</a><br /><br/>";
	    echo "<br/>";
	}

	echo "<br/>";
	// Output global counters in a table
        echo "<h2 id='celkovestatistiky'>Celkové bodování hráčů<br/><small class='text-muted'>Hráči, kteří nejsou v tabulce, nemají ani jeden gól nebo nahrávku</small></h2>";
        echo "<table class='table table-bordered sortable table-hover'>";
        echo "<thead class='table-dark'><tr><th>Hráč</th><th>Góly</th><th>Nahrávky</th><th>Body</th></tr></thead>";
        echo "<tbody>";
        foreach (array_keys($globalGoalCount + $globalAssistanceCount) as $player) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($player) . "</td>";
            echo "<td>" . (isset($globalGoalCount[$player]) ? $globalGoalCount[$player] : 0) . "</td>";
            echo "<td>" . (isset($globalAssistanceCount[$player]) ? $globalAssistanceCount[$player] : 0) . "</td>";
            echo "<td>" . (isset($globalGoalCount[$player]) ? $globalGoalCount[$player] : 0) + (isset($globalAssistanceCount[$player]) ? $globalAssistanceCount[$player] : 0) . "</td>";
            echo "</tr>";
        }
        echo "</tbody>";
        echo "</table>";
        echo "</div>";
        echo "</body>";
        echo "</html>";
    }
}
?>

