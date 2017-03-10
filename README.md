# Welcome, intrepid user!

WARNING: THAR BE DRAGONS! Intrigue is currently in ALPHA and requires some effort to get set up. We will be providing installation packages at some point in the future. If you're interested in helping test, please join the chat below:

[![Join the chat at https://gitter.im/intrigueio/intrigue-core](https://badges.gitter.im/Join%20Chat.svg)](https://gitter.im/intrigueio/intrigue-core?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

Intrigue-core is an API-first framework for attack surface discovery. It is primarily used for for Internet (security) reconnaissance and research.

<img src="https://raw.githubusercontent.com/intrigueio/intrigue-core/develop/doc/home.png" width="700">

To get started, follow the instructions below!

### Setting up a development environment

Follow the appropriate setup guide:

 * Docker -
 * Ubuntu Linux - https://github.com/intrigueio/intrigue-core/wiki/Setting-up-a-Test-Environment-on-Ubuntu-Linux
 * Kali Linux - https://github.com/intrigueio/intrigue-core/wiki/Setting-up-a-Test-Environment-on-Kali-Linux
 * OSX - https://github.com/intrigueio/intrigue-core/wiki/Setting-up-a-Test-Environment-on-OSX


### Setting up a development environment using docker:
```
# Clone the repository to your current directory
$ git clone https://github.com/intrigueio/intrigue-core
$ cd intrigue-core

# Build the container and run it
$ docker build .
$ docker run -i -t -p 7777:7777
```

Now that you have a working environment, browse to the web interface.

### Using the web interface

To use the web interface, browse to http://127.0.0.1:7777

Please note that if you are using `docker-machine` to start the Intrigue API, the URL that you would need to access the Intrigue UI will be that `docker-machine`'s IP instead of `127.0.0.1`. So, just do a `docker-machine ls` and note the IP of your currently active and running docker machine. Then, after starting the Intrigue API/UI, navigate to that IP:7777.

Getting started should be pretty straightforward, try running a "dns_brute_sub" task on your domain. Now, try with the "use_file" option set to true.


### API usage via core-cli:

A command line utility has been added for convenience, core-cli.

List all available tasks:
```
$ bundle exec ./core-cli.rb list
```

Start a task:
```
$ bundle exec ./core-cli.rb start dns_lookup_forward DnsRecord#intrigue.io
```

Start a task with options:
```
$ bundle exec ./core-cli.rb start dns_brute_sub DnsRecord#intrigue.io resolver=8.8.8.8#brute_list=1,2,3,4,www#use_permutations=true
[+] Starting task
... <snip>
```

### API usage via curl:

You can use the tried and true curl utility to request a task run. Specify the task type, specify an entity, and the appropriate options:

```
$ curl -s -X POST -H "Content-Type: application/json" -d '{ "task": "example", "entity": { "type": "String", "attributes": { "name": "8.8.8.8" } }, "options": {} }' http://127.0.0.1:7777/v1/task_runs
```

### API usage via rubygem
[![Gem Version](https://badge.fury.io/rb/intrigue.svg)](http://badge.fury.io/rb/intrigue)
