# Welcome!

Intrigue-core is a framework for external attack surface discovery and automated OSINT. The framework is designed for use cases such as:

  * Asset Discovery (Application and Infrastructure)
  * Security Research and Vulnerability Scanning
  * Exploratory OSINT (People, Systems, Entities)
  * Malware IOC Enrichment
  * General Data Gathering Pipelines

If you'd like assistance getting started or have development-related questions, feel free to join us in slack channel, simply drop a line to hello@intrigue.io

# Users

To get started quickly and play around with an instance, head on over to the [Getting Started Guide](https://core.intrigue.io/getting-started/). We suggest the Docker image as a first place to start. It's actively built on the master branch of Intrigue Core. 

### Using the web interface

To use the web interface, browse to http://127.0.0.1:7777. Once you're able to connect, you can follow the instructions here: http://core.intrigue.io/up-and-running/

### Configuring the system

Many tasks work via external APIs and thus require configuration of keys. To set them up, browse to the "Configure" tab and click on the name of the module. You will be taken to the relevant signup page where you can provision an API key. These keys are ultimately stored in the file: config/config.json.

## The API

Intrigue-core is built API-first, allowing all functions in the UI to be automated. The following methods for automation are provided.

### API usage via curl

You can use curl to drive the framework. See the example below:

```
$ curl -s -X POST -H "Content-Type: application/json" -d '{ "task": "create_entity", "entity": { "type": "DnsRecord", "attributes": { "name": "intrigue.io" } }, "options": {} }' http://127.0.0.1:7777/results
```

### API usage via command line (core-cli)

A command line utility has been added for convenience, core-cli.

List all available tasks:
```
$ bundle exec ./core-cli.rb list
```

Start a task:
```
## core-cli.rb start [Project Name] [Task] [Type#Entity] [Depth] [Option1=Value1#...#...] [Handlers] [Strategy Name] [Auto Enrich]
$ bundle exec ./core-cli.rb start new_project create_entity DnsRecord#intrigue.io 3
Got entity: {"type"=>"DnsRecord", "name"=>"intrigue.io", "details"=>{"name"=>"intrigue.io"}}
Task Result: {"result_id":66103}
```

### API SDK (Ruby)
A Ruby gem is available for your convenience: [![Gem Version](https://badge.fury.io/rb/intrigue_api_client.svg)](http://badge.fury.io/rb/intrigue_api_client)


# Developers

To get started setting up a development environment, follow the instructions below!

### Setting up a development environment

While you can build a local setup and develop, we'd suggest starting with one of the following setup guides:

 * Vagrant - http://core.intrigue.io/getting-started-with-intrigue-core-on-vagrant-virtualbox/
 * Docker - https://core.intrigue.io/2017/03/07/using-intrigue-core-with-docker/

