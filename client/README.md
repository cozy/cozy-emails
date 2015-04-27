### Unit tests

Running unit tests requires [io.js](https://iojs.org/en/index.html) and an
additional parameter to setup `jsdom`.

### Use io.js

To use `io.js` it's recommended to run it via a node environment manager like
[nvm](https://github.com/creationix/nvm).

#### Install NVM (requires bash)

```bash
curl https://raw.githubusercontent.com/creationix/nvm/v0.25.0/install.sh | bash
```

#### Install io.js

```bash
nvm install iojs-v1.8.1
```

#### Use io.js

```bash
nvm use iojs-v1.8.1
```

### Run tests

Tests require mocha and a setup process to start `jsdom`.

```bash
mocha -r unit-tests/setup.coffee --reporter spec --compilers
coffee:coffee-script/register unit-tests
```

Or simply run this in the client folder

```bash
npm test
```
