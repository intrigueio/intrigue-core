### Environment and external dependencies

The following are presumed available and configured in your environment
 - redis
 - sudo
 - nmap
 - zmap
 - masscan
 - API keys (copy config/config.yml.default -> config/config.yml)

### To start:

Make sure you have redis installed and running.

```
bundle exec rackup ## start the UI
bundle exec sidekiq -r ./core.rb ## Start the background processing
```



### curl usage:

Request the task type, specify an entity, and the appropriate options:
````
curl -s -X POST -H "Content-Type: application/json" -d '{ "task": "example", "entity": { "type": "Host", "attributes": { "name": "4.4.4.4" } }, "options": {} }' http://localhost:9292/task_runs/
````

### core-cli interface

A command line utility has been added for convenience

List tasks:
```
./core-cli.rb list
```

Start a task:
```
./core-cli.rb start dns_lookup_forward DnsRecord#wow.com
```

Start a task with options:
```
./core-cli.rb start dns_lookup_forward DnsRecord#wow.com resolver#8.8.8.8
```

Check for a subdomain on iastate.edu:
```
INTRIGUE_ENV=production  ./core-cli.rb start_and_wait dns_brute_sub DnsRecord#iastate.edu resolver=8.8.8.8#brute_list=a,b,c,proxy,test,www
http://core.intrigue.io/task_runs/05d975a7-4527-4f76-bfe3-6b1e8c6fa581
DnsRecord#www.iastate.edu
Host#129.186.23.166
```

Check the top 1000 domains for the existence of security headers:
```
for x in `cat data/domains.txt | head -n 1000`; do ./core-cli.rb start_and_wait dns_sub_brute DnsRecord#http://$x;done
```
