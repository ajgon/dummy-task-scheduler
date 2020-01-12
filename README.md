# Dummy task scheduler and metrics provider

This is a simple Ruby task scheduler, prometheus metrics collector and provider.

## Dependencies

The scheduler uses Redis to keep its queues - so a running instance is necessary.

## Usage

The idea is based on set of "tasks" living in `tasks/` folder. These are simple
ruby Sidekiq worker classes, fetching some data and collecting metrics for them.

### Running server and scheduler

To run task scheduler:

```
bundle exec sidekiq -r ./lib/sidekiq.rb -C ./config/sidekiq.yml
```

To run built-in server:

```
bundle exec puma
```

### Writing task

Tasks live in `tasks/` directory. An example task may look like this:

```ruby
module Tasks
  class RandomTask < ApplicationTask
    def self.interval
      '15s'
    end

    def perform
      gauges[:random_number].set(rand, labels: { mood: %w[happy sad bored].sample })
    end

    private

    def gauges
      @gauges ||= {
        random_number: Prometheus::Client::Gauge.new(:random_number, docstring: 'A random number between 0 and 1', labels: [:mood])
      }
    end
  end
end
```

Task needs to be under `Tasks` module, and inherit from `ApplicationTask`.

The `perform` method is required - it will be called by scheduler. Here you can
code all the stuff your task needs to do.

The `self.interval` static method can be used, to customize the interval in which
task is ran. Defaults to `1m` (1 minute).

If you need to provide metrics, you can use special methods: `gauges`, `counters`,
`histograms` and `summaries`. Each method as a result should provide a hash,
where key is a metric name, and value is a `Prometheus::Client` object for given
metric. Check [prometheus-client documentation](https://github.com/prometheus/client_ruby#metrics)
for more details. The app and scheduler will register metrics automatically and
take care of concurency. Don't forget to call `<metric>[<name>].set(...)` to
actually set a metric value.

If you need pass variables to tasks, use `ENV.fetch(...)` stanza.

You can check some [example tasks](example/tasks/) to get the idea.

### Receiving data

App comes with simple rack application and puma server listening on port `7777`
by default. Visiting `http://localhost:7777/metrics` will return all the
data in openmetrics format.

## Docker

You can build your own docker image from provided `Dockerfile`.

To build:

```
docker build -t myimage .
```

To run:

```
docker run --rm --name myname -p 7777:7777 -e REDIS_URL=redis://myredis:6397 -v /path/to/tasks:/app/tasks myimage
```

Custom written tasks live in `/app/tasks`, which can be mounted to a separate
volume.

## Troubleshoot

Comments and contributions are welcome.

## License

[MIT](LICENSE.txt)
