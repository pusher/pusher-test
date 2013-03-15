# Pusher Test

Available at <http://test.pusher.com/>.

The objective is to make it trivial to manually test an arbitrary pusher-js version on an arbitrary device, and to expose enough debug info and twiddleable knobs to allow experiment driven problem solving.

## Developing

Copy the provided `config.yml.example` to `config.yml` and fill in your app id, key, and secret.

Install the bundle if required

    bundle install

and run

    bundle exec shotgun

Then visit <http://localhost:9393/>.

## Using multiple environments

It's possible to create multiple environments in `config.yml` and access them by setting a query parameter: <http://localhost:9393/?env=myenv>.

See `Environment#initialize` in `app.rb` for a full list of possible options.

## Developing pusher-js

You may find the `js_host` query parameter useful when combined with `jbundle server`: <http://localhost:9393/?js_host=localhost:5555>.