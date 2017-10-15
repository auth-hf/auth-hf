# auth-hf
[![Gitter](https://img.shields.io/gitter/room/nwjs/nw.js.svg)](https://gitter.im/auth-hf/Lobby)
[![build status](https://travis-ci.org/auth-hf/auth-hf.svg?branch=master)](https://travis-ci.org/auth-hf/auth-hf)

The unofficial OAuth2 provider for HackForums.net.

# Prerequisites
* Dart SDK `>=1.24.2 <2.0.0`
* MongoDB `3.x`

# Running

To run the dev server:

```bash
dart bin/dev.dart
```

There is also a simple example "third-party" that can be run to give a taste
of the OAuth2 flow:

```bash
dart bin/example.dart
```