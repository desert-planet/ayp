## All Your Pants

The website behind the robot behind the legend behind the nonsense.

![woosh](http://s3.amazonaws.com/ayp/ayp-1416892364734.jpg)

Gods help us all.

## Dependencies

This application is written in [Node](http://nodejs.org/) and uses [Redis](http://redis.io/) for
persistence. To install these in OS X, **install [Homebrew](http://brew.sh/) first** and then run

```sh
$ brew install redis
$ brew install node
```

This will install both of the requirements. The remaining requirements will be installed by the application layer.

## Tech Stack and Tech Stack Accessories

![fun](http://pixxx.wtf.cat/image/3F1M3J3o0h3L/fun.jpg)

  * We use [LESS](http://lesscss.org/) as the CSS language, and CSS is stored in [/style](./style) in the repository
  * We use [Handlebars](http://handlebarsjs.com/) templates, in [/views](./views) running inside the `main` layout in
  [/views/layouts](./views/layouts)
  * Handlebars integration is provided with the [express-handlebars](https://www.npmjs.org/package/express-handlebars) package
  * Anything placed in [/public](./public) is accessible on the site as `/static/..`
  * The [production site](http://ayp.wtf.cat/) runs in [Heroku](https://www.heroku.com/)
  * :cat2: Planet

That's about it. If something is stupid or confusing, **FILE A FUCKING ISSUE** so that it can get fixed.

## Local development

First, clone the repository, and set the name of the remote to `upstream`. This will become useful
when you fork the repository to contribute changes.

```sh
$ git clone https://github.com/desert-planet/ayp
$ cd ayp
$ git remote rename origin upstream
```

Now use [npm](https://www.npmjs.org/), which should have been installed with node, to install the application
and all of its dependencies.

```sh
$ npm install
```

If nothing goes wrong, you can then load the local database with some test strips after loading the
dev environment.

```sh
$ . script/ayp-env
$ script/db-seed
=>  I'm gonna stuff your DB with some content.
[..snip..]
```

Now you're **GOOD TO GO**. To run the development server

```sh
$ npm start

Your pants running at http://localhost:5000/
```

:warning: :warning: :warning:

**Code changes to `.coffee` files require a restart of the server. Because I'm bad at programming**

:warning: :warning: :warning:

## Setting up your fork for contribution

If you have already created a fork, you can add that remote as `origin`

```sh
$ git remote add origin https://github.com/your_name_here/ayp
```

So that newly created branches will push to your fork, but switching to `master` and running
`git pull` will get the latest changes from the upstream repository.
