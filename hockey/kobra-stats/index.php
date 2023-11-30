<?php

// Function to parse event data from HTML content
function parseEventData($htmlContent) {
    $dom = new DOMDocument;
    libxml_use_internal_errors(true);
    $dom->loadHTML($htmlContent);
    libxml_clear_errors();

    $xpath = new DOMXPath($dom);

    $query = '//table/tbody/tr[contains(td[4], "HC Kobra Praha") and starts-with(td[2], "gól")]';

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
function parseMatchData($htmlContent) {
    $dom = new DOMDocument;
    libxml_use_internal_errors(true);
    $dom->loadHTML($htmlContent);
    libxml_clear_errors();

    $xpath = new DOMXPath($dom);

    $infoQuery = '//table[contains(@class, "sortable")]/tr/th | //table[contains(@class, "sortable")]/tr/td';
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
    $min_cache_age = $config['cache']['min_age'];
    $max_cache_age = $config['cache']['max_age'];

    $html_base = file_get_contents($base_url);

    $pattern = '/data-matchId="(\d+)"/';
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
        echo "<title>Match Statistics</title>";
        echo "<link rel='stylesheet' href='https://stackpath.bootstrapcdn.com/bootstrap/4.3.1/css/bootstrap.min.css'>";
        echo "</head>";
        echo "<body>";
        echo "<div class='container'>";

        foreach ($matchIds as $matchId) {
            $cache_dir = getenv("HOME") . "/.cache/kobra-stats";
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

            $result = parseEventData($html);
            $matchInfo = parseMatchData($html);

            echo "<h2>Match ID: " . $matchId . "</h2>";
            echo "<p>Data source: " . ($fetch ? "fetched" : "cache") . "</p>";
            echo "<p>Cache age: " . round($cache_age) . " minutes";

            // Display link to HTML
            echo "<p>HTML Link: <a href='{$base_url}&matchId={$matchId}' target='_blank'>{$base_url}&matchId={$matchId}</a></p>";

            // Display additional match information
            echo "<table class='table'>";
            foreach ($matchInfo as $key => $value) {
                echo "<tr>";
                echo "<th>$key:</th>";
                echo "<td>" . htmlspecialchars($value) . "</td>";
                echo "</tr>";
            }
            echo "</table>";

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
                echo "<table class='table'>";
                echo "<thead><tr><th>Time</th><th>Goal</th><th>Assistances</th></tr></thead>";
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
                echo "<table class='table'>";
                echo "<thead><tr><th>Player</th><th>Goals</th><th>Assistances</th></tr></thead>";
                echo "<tbody>";
                foreach (array_keys($goalCount + $assistanceCount) as $player) {
                    echo "<tr>";
                    echo "<td>" . htmlspecialchars($player) . "</td>";
                    echo "<td>" . (isset($goalCount[$player]) ? $goalCount[$player] : 0) . "</td>";
                    echo "<td>" . (isset($assistanceCount[$player]) ? $assistanceCount[$player] : 0) . "</td>";
                    echo "</tr>";
                }
                echo "</tbody>";
                echo "</table>";
            }
        }
        // Output global counters in a table
        echo "<table class='table'>";
        echo "<thead><tr><th>Player</th><th>Goals</th><th>Assistances</th></tr></thead>";
        echo "<tbody>";
        foreach (array_keys($globalGoalCount + $globalAssistanceCount) as $player) {
            echo "<tr>";
            echo "<td>" . htmlspecialchars($player) . "</td>";
            echo "<td>" . (isset($globalGoalCount[$player]) ? $globalGoalCount[$player] : 0) . "</td>";
            echo "<td>" . (isset($globalAssistanceCount[$player]) ? $globalAssistanceCount[$player] : 0) . "</td>";
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

