=begin
We provide the following API endpoints:

/search
The search endpoint allows searches against the IPv4, Alexa Top Million, and Certificates indexes using the same search syntax as the main site. The endpoint returns a paginated result of the most recent information we know for the set of user selected fields. More information about the returned hosts, websites, and certificates can be fetched using the /view endpoint.

/view
The view endpoint fetches the structured data we have about a specific host, website, or certificate once you know the host's IP address, website's domain, or certificate's SHA-256 fingerprint.

/report
The report endpoint allows you to determine the aggregate breakdown of a value for the results a query, similar to the "Build Report" functionality available in the primary search interface. For example, if you wanted to determine the breakdown of cipher suites selected by all websites in the Top Million.

/query
The SQL query endpoint allows you to execute SQL queries against current and historical snapshots of the IPv4 address space and Top Million website, as well as our full collection of all seen certificates. The endpoint returns flat, paginated resultsets and supports the Google BigQuery SQL syntax. Note: the SQL query end point is restrited to verified researchers.

/export
The export endpoint allows exporting large subsets of data to JSON files, which can then be downloaded for further analysis. For example, if you wanted to export the full records about all hosts that still support SSLv3. Note: the SQL query end point is restrited to verified researchers.

/data
The data endpoint exposes metadata on raw data that can be downloaded from Censys. For example, if you wanted to determine whether a new dataset has been posted in a given series and how to download it.
=end

API_URL = "https://www.censys.io/api/v1"
UID = "e657c8ef-2ae9-471e-907a-b92ea66209ee"
SECRET = "GIp9QjrUB4aJu8tV0lQBsgZj15Lx7tG1"
