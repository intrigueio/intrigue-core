### Environment and external dependencies

The following are presumed available and configured in your environment
 - redis
 - sudo
 - nmap
 - zmap
 - masscan
 - API keys (copy config/config.yml.default -> config/config.yml)

### To start the API and background task processing:

Make sure you have redis installed and running.

```
$ foreman start
```

### API usage via curl:

Request the task type, specify an entity, and the appropriate options:
````
curl -s -X POST -H "Content-Type: application/json" -d '{ "task": "example", "entity": { "type": "IpAddress", "attributes": { "name": "8.8.8.8" } }, "options": {} }' http://localhost:9292/v1/task_runs/
````

### API usage via core-cli:

A command line utility has been added for convenience, core-cli.

List all available tasks:
```
./core-cli.rb list
```

Start a task:
```
./core-cli.rb start dns_lookup_forward DnsRecord#intrigue.io
```

Start a task with options:
```
./core-cli.rb start dns_lookup_forward DnsRecord#intrigue.io resolver#8.8.8.8
```

Check for subdomains on intrigue.io:
```
bundle exec ./core-cli.rb start dns_brute_sub DnsRecord#intrigue.io resolver=8.8.8.8#brute_list=a,b,c,proxy,test,www
http://core.intrigue.io/task_runs/05d975a7-4527-4f76-bfe3-6b1e8c6fa581
DnsRecord#www.intrigue.io
Host#192.0.78.13
```

Check the Alexa top 1000 domains for the existence of security headers:
```
for x in `cat data/domains.txt | head -n 1000`; do ./core-cli.rb start dns_brute_sub DnsRecord#$x;done
```
