# Born Gosu Gaming

A collection of bots and tools, as well as eventually a co-server for the website.

## Developing

### First Time
```bash
> brew install elixir
> brew install kerl
> kerl build 22.0 22.0
> kerl install 22.0 ~/kerl/22.0
> git clone ...
```

### Every Time
```bash
> . ~/kerl/22.0/activate
# check - we should see Erlang/TOP 22. 21 causes a bug in the websockets library
> elixir -v
Erlang/OTP 22 [erts-10.4] [source] [64-bit] [smp:4:4] [ds:4:4:10] [async-threads:1] [hipe]

Elixir 1.8.2 (compiled with Erlang/OTP 21)

> mix deps.get
```

### Running Locally

```bash
> iex -S mix
```

### Testing Locally

```bash
> mix test
```

## Secrets

To work:
```bash
> gpg --decrypt-files config/secret/*.gpg
```

To cleanup:
```bash
> rm -rf config/secret/*.exs
```

## Deploying

TBD