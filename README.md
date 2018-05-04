# Welcome!

Intrigue-core is a framework for automated attack surface discovery. There are a number of use cases:

  * Application and Infrastructure (Asset) Discovery
  * Security Research and Vulnerability Discovery
  * Malware Campaign Research & Indicator Enrichment
  * Exploratory OSINT Research

If you'd like assistance getting started or have development-related questions, feel free to join us in the [chat](https://gitter.im/intrigueio/intrigue-core).

# Users

If you just want to get started and play around with an instance, have a look at the [Getting Started Guide](https://intrigue.io/getting-started/)

# Developers

To get started setting up a development environment, follow the instructions below!

### Setting up a development environment

Follow the appropriate setup guide:

 * Vagrant (preferred) - http://intrigue.io/getting-started-with-intrigue-core-on-vagrant-virtualbox/
 * Docker - https://intrigue.io/2017/03/07/using-intrigue-core-with-docker/
 * Ubuntu Linux - https://github.com/intrigueio/intrigue-core/wiki/Setting-up-a-Test-Environment-on-Ubuntu-Linux
 * Kali Linux - https://github.com/intrigueio/intrigue-core/wiki/Setting-up-a-Test-Environment-on-Kali-Linux
 * OS X - https://github.com/intrigueio/intrigue-core/wiki/Setting-up-a-Test-Environment-on-OSX-10.10

Now that you have a working environment, browse to the web interface.

### Using the web interface

To use the web interface, browse to http://127.0.0.1:7777. Once you're able to connect, you can follow the instructions here: https://intrigue.io/2017/03/07/using-intrigue-core-with-docker/

### Configuring the system

Many modules require API keys. To set them up, browse to the "Configure" tab and click on the name of the module. You will be taken to the relevant signup page where you can provision an API key.

## The API

Intrigue-core is built API-first, allowing all functions in the UI to be easily automated. The following methods for automation are provided.

### API usage via core-cli

A command line utility has been added for convenience, core-cli.

List all available tasks:
```
$ bundle exec ./core-cli.rb list
```

Start a task:
```
$ bundle exec ./core-cli.rb background Default dns_brute_sub DnsRecord#intrigue.io 1
Got entity: {"type"=>"DnsRecord", "name"=>"intrigue.io", "details"=>{"name"=>"intrigue.io"}}
Task Result: {"result_id":66103}
```

### API usage via curl

You can use curl to drive the framework. See the example below:

```
$ curl -s -X POST -H "Content-Type: application/json" -d '{ "task": "example", "entity": { "type": "String", "attributes": { "name": "8.8.8.8" } }, "options": {} }' http://127.0.0.1:7777/results
```

### API Client (Ruby Gem)
A Ruby gem is provided for your convenience: [![Gem Version](https://badge.fury.io/rb/intrigue_api_client.svg)](http://badge.fury.io/rb/intrigue_api_client)
