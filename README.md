## All Your Pants

The website behind the robot behind the legend behind the nonsense.

![woosh](http://s3.amazonaws.com/ayp/ayp-1416892364734.jpg)

## Dependencies

This application is written in [Node](http://nodejs.org/) and uses [Redis](http://redis.io/) for
persistence. To install these in OS X, **install [Homebrew](http://brew.sh/) first** and then run

```sh
$ brew install redis
$ brew install node
```

This will install both of the requirements. The remaining requirements will be installed by the application layer.

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

If nothing goes wrong, you can then load the local database with some test strips.

```sh
$ script/db-seed
=>  I'm gonna stuff your DB with some content.
[..snip..]
```

Now you're **GOOD TO GO**. To run the development server

```sh
$ npm start

Your pants running at http://localhost:5000/
```

And you should be good to go.

:warning: Code changes to `.coffee` files require a restart of the server. Because I'm bad at programming :warning:

## Setting up your fork for contribution

If you have already created a fork, you can add that remote as `origin`

```sh
$ git remote add origin https://github.com/your_name_here/ayp
```

So that newly created branches will push to your fork, but switching to `master` and running
`git pull` will get the latest changes from the upstream repository.
