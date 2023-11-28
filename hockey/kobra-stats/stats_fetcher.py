import sys
import os
import requests
from bs4 import BeautifulSoup
import re
from collections import Counter
from datetime import datetime, timedelta
import random
import hashlib

# Function to fetch HTML content from URL or cache
def fetch_html_from_url(url):
    # Get the user's home directory
    home_dir = os.path.expanduser("~")
    
    # Set the cache folder path
    cache_folder = os.path.join(home_dir, ".cache", "kobra-stats-fetcher")

    # Ensure the cache directory exists
    if not os.path.exists(cache_folder):
        os.makedirs(cache_folder)

    # Use hashlib to generate a consistent hash for the URL
    url_hash = hashlib.sha256(url.encode()).hexdigest()
    cache_file = os.path.join(cache_folder, f"{url_hash}.html")

    # Check if the cache file exists and is not too old
    if os.path.exists(cache_file):
        mod_time = os.path.getmtime(cache_file)
        last_modified = datetime.fromtimestamp(mod_time)
        current_time = datetime.now()
        age = current_time - last_modified

        # If cache is not older than a random number of minutes between 1 and 5, use cache
        random_age = random.uniform(3, 7)
        if age.total_seconds() / 60 <= random_age:
            with open(cache_file, 'r', encoding='utf-8') as f:
                cached_content = f.read()
                print(f"Using cached version for {url}")
                return cached_content

    try:
        response = requests.get(url)
        response.raise_for_status()

        # Save the new content to cache
        with open(cache_file, 'w', encoding='utf-8') as f:
            f.write(response.text)

        print(f"Fetched a newer version for {url}")
        return response.text
    except requests.exceptions.RequestException as e:
        print(f"Error fetching HTML from URL: {e}")
        sys.exit(1)

def extract_match_ids_from_html(html_content):
    # Use regular expression to find data-matchId attributes
    match_ids = re.findall(r'data-matchId="(\d+)"', html_content)
    return match_ids

def parse_additional_info(html_content):
    # Parse HTML content with BeautifulSoup
    soup = BeautifulSoup(html_content, 'html.parser')

    # Extract information from the specified portion of HTML
    table_rows = soup.select('h1:contains("Liga mladších žáků „B“ (2023/2024)") + table tr')
    info_data = [td.get_text(strip=True) for row in table_rows for td in row.find_all(['th', 'td'])]

    return info_data

def parse_event_data(html_content):
    # Parse HTML content with BeautifulSoup
    soup = BeautifulSoup(html_content, 'html.parser')

    # Find all relevant <tr> elements
    relevant_rows = soup.select('table tbody tr')

    # Extract and return data from the third <td> if conditions are met
    relevant_data = [
        td.get_text(strip=True) for tr in relevant_rows
        for td in tr.find_all('td')
        if 'HC Kobra Praha' in tr.find_all('td')[3].get_text(strip=True) and tr.find_all('td')[1].get_text(strip=True).startswith('gól')
    ]

    return relevant_data

def process_relevant_data(relevant_data):
    processed_data = []
    for i in range(0, len(relevant_data), 4):
        cas, udalost, strelec = relevant_data[i:i + 3]
        
        # Check if the content of the 3rd field contains brackets
        if '(' in strelec and ')' in strelec:
            strelec, asistence = map(str.strip, strelec.split('(', 1))
            asistence = asistence.rstrip(')')

            # Check if there are multiple strings in the "Asistence" field
            if ',' in asistence:
                asistence_1, asistence_2 = map(str.strip, asistence.split(',', 1))
            else:
                asistence_1, asistence_2 = asistence, ''
        else:
            asistence_1, asistence_2 = '', ''

        processed_data.append([cas, udalost, strelec, asistence_1, asistence_2])

    return processed_data

def count_unique_strings(processed_data):
    strelec_counter = Counter()
    asistence_counter = Counter()

    for data in processed_data:
        strelec_counter[data[2]] += 1
        if data[3]:  # Exclude empty strings
            asistence_counter[data[3]] += 1
        if data[4]:  # Exclude empty strings
            asistence_counter[data[4]] += 1

    return strelec_counter, asistence_counter

def beautify_output(counter_dict):
    return ', '.join([f"{key}: {value}" for key, value in counter_dict.items()])

def aggregate_strelec_across_match_ids(match_ids):
    strelec_aggregated = Counter()

    for match_id in match_ids:
        # Parse event data from existing data instead of fetching the page again
        event_data = existing_data[match_id]

        # Process and aggregate strelec data
        processed_data = process_relevant_data(event_data)
        for data in processed_data:
            strelec_aggregated[data[2]] += 1

    return strelec_aggregated

def aggregate_asistence_across_match_ids(match_ids):
    asistence_aggregated = Counter()

    for match_id in match_ids:
        # Parse event data from existing data instead of fetching the page again
        event_data = existing_data[match_id]

        # Process and aggregate asistence data
        processed_data = process_relevant_data(event_data)
        for data in processed_data:
            if data[3]:  # Exclude empty strings
                asistence_aggregated[data[3]] += 1
            if data[4]:  # Exclude empty strings
                asistence_aggregated[data[4]] += 1

    return asistence_aggregated

def main():
    # Check if a URL is provided as a command-line argument
    if len(sys.argv) != 2:
        print("Usage: python script.py <url>")
        sys.exit(1)

    global existing_data
    existing_data = {}  # Store parsed event data for each match ID

    url = sys.argv[1]

    # Fetch HTML content from the specified URL
    html_content = fetch_html_from_url(url)

    # Extract match IDs from HTML content
    match_ids = extract_match_ids_from_html(html_content)

    # Iterate over match IDs and fetch corresponding pages
    for match_id in match_ids:
        match_url = f"https://www.ceskyhokej.cz/hokejove-souteze/liga-mladsich-zaku-b?matchId={match_id}&leagueMatchWidget-clubId=24"
        match_html_content = fetch_html_from_url(match_url)

        # Store parsed event data for each match ID
        existing_data[match_id] = parse_event_data(match_html_content)

        # Parse additional info
        additional_info = parse_additional_info(match_html_content)

        # Output the link once per match ID
        print(f"Match ID: {match_id}")

        for info in additional_info:
            print(info)

        # Add the link field
        print(f"Link: {match_url}")

        # Process and output relevant data
        processed_data = process_relevant_data(existing_data[match_id])
        for data in processed_data:
            cas, udalost, strelec, asistence_1, asistence_2 = data
            asistence_output = f", asistence: {asistence_1}" if asistence_1 else ''
            asistence_output += f", {asistence_2}" if asistence_2 else ''
            print(f"{cas}, {udalost}, strelec: {strelec}{asistence_output}")

        print("=" * 50)
        
        # Count and output unique strings in strelec and asistence
        strelec_counter, asistence_counter = count_unique_strings(processed_data)
        print("Body:")
        for key in set(strelec_counter.keys()) | set(asistence_counter.keys()):
            goly_count = strelec_counter[key]
            asistence_count = asistence_counter[key] + asistence_counter.get('', 0)
            print(f"{key}: {goly_count} + {asistence_count}")

        print("=" * 50)

    # Aggregate strelec data across all match IDs
    strelec_aggregated = aggregate_strelec_across_match_ids(match_ids)

    # Aggregate asistence data across all match IDs
    asistence_aggregated = aggregate_asistence_across_match_ids(match_ids)

    print("=" * 50)
    
    print("Body:")
    for key in set(strelec_aggregated.keys()) | set(asistence_aggregated.keys()):
        goly_count = strelec_aggregated[key]
        asistence_count = asistence_aggregated[key] + asistence_aggregated.get('', 0)
        print(f"{key}: {goly_count} + {asistence_count}")

if __name__ == "__main__":
    main()

