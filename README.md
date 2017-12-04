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

## Deploying

```
heroku git:remote --app pusher-test-heroku
git push heroku master
```

### Adding a new cluster

1. Add the new cluster name to [this array](https://github.com/pusher/pusher-test/blob/58fb702f182c9159c6b5c095a5ca41d7cbf1baba/app.rb#L35) and deploy
2. Create an app within the cluster
    1. `heroku run rails console --app global-production`
    2. `Account.where(email: "services+pushertest@pusher.com").first.apps.create(name: "test.pusher.com <cluster name>", cluster_id: <cluster ID>, ssl_only: false, client_events: true, batch_webhooks: true, counting: false)`
3. Modify the `CONFIG_JSON` environment variable in Heroku with the details for the new cluster and app
