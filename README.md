# Welcome!

Intrigue Core is an open framework for discovering and enumerating the attack surface discovery of organizations. It can be used with a human-in-the-loop running individual tasks, or fully automated through the use of machine files. With a flexible entity model and deep enrichment system, it is the most full-featured open source framework for discovering attack surface.

If you'd like assistance getting started or have development-related questions, feel free to join us in our [Intrigue Community slack](https://join.slack.com/t/intrigue-community/shared_invite/zt-fcljntms-rc1Lh_M~Q9iyaLT7d0zLIA) channel. For all other questions, you can simply drop an email to hello-at-intrigue.io

# Users

To get started quickly and play around with an instance, head on over to the [Getting Started Guide](https://core.intrigue.io/getting-started/). We suggest the Docker image as a first place to start. It's actively built on the master branch of Intrigue Core.  

### Using the web interface

To use the web interface, browse to http://127.0.0.1:7777. Once you're able to connect, you can follow the instructions here: http://core.intrigue.io/up-and-running/

### Configuring the system

Many tasks work via external APIs and thus require configuration of keys. To set them up, browse to the "Configure" tab and click on the name of the module. You will be taken to the relevant signup page where you can provision an API key. These keys are ultimately stored in the file: config/config.json.

### Usage via API

Intrigue-core is built API-first, allowing all functions in the UI to be automated. We are currently in the process of a rewrite here. If this is useful to you, please pop into our slack (see link at the bottom of the page)

### Usage via command line (core-cli)

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

# Setting up a Development environment

To get started setting up a development environment, follow the instructions below:

While you can build a local setup and develop, we'd suggest starting with one of the following setup guides:

 * Docker: https://core.intrigue.io/2017/03/07/using-intrigue-core-with-docker/
 * Vagrant: http://core.intrigue.io/getting-started-with-intrigue-core-on-vagrant-virtualbox/
 * Direct install on Ubuntu/Debian: https://github.com/intrigueio/intrigue-core/wiki/Setting-up-a-Test-Environment-on-Ubuntu-Linux

You'll probably want to take a look at the following resources: 

 * Key System Files: https://github.com/intrigueio/intrigue-core/wiki/Understanding-Intrigue-Core%3A-Key-System-Files

# Intrigue Community Slack (User and Development Support)

To get help in real time, join our [Intrigue Community slack](https://join.slack.com/t/intrigue-community/shared_invite/zt-fcljntms-rc1Lh_M~Q9iyaLT7d0zLIA) , where you'll be able to interact directly with the develpment team. Please post a brief 1-2 linee introduction in #general when you arrive. 

  - For immediate (user) help, join the #core-help channel
  - For immediate (dev) help, join the #core-dev channel
  - For updates of development activity, join the #core-updates channel
  - For an ongoing view of the core roadmap, join the #core-roadmap channel

# Key Contributors

Intrigue Core would not be possible without work, time, and attention from the following contributors: 

 * [Anas Ben Salah](https://twitter.com/bensalah_anas)
