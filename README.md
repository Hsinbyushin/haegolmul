<p align="center">
  <img src="assets/haegolmul-logo.png" alt="Haegolmul logo" width="500">
</p>

<p align="center">
  A lightweight, bot-aware reverse proxy written in Elixir.
</p>


## About

Haegolmul is an experimental reverse proxy and bot-protection system written
in Elixir.

The project is inspired by systems such as Anubis, but is being developed
independently as both a learning project and an exploration of how the
BEAM/OTP model can be used to build resilient network infrastructure.

The long-term goal is to place Haegolmul in front of an existing web
application and evaluate incoming requests before allowing them to reach the
upstream service.

Conceptually:

```text
                 Internet
                    │
                    ▼
              ┌───────────┐
              │ Haegolmul │
              └─────┬─────┘
                    │
             allowed requests
                    │
                    ▼
              ┌───────────┐
              │ Upstream  │
              │   App     │
              └───────────┘
```

Eventually, requests will pass through a decision pipeline:

```text
Request
   │
   ▼
Observation
   │
   ▼
Policy
   │
   ▼
Verdict
   │
   ├── allow
   ├── challenge
   └── deny
```

The bot-protection layer has not been implemented yet. The current development
focus is building and understanding the HTTP reverse-proxy foundation on which
that system will operate.

## Current Status

Haegolmul currently implements a minimal HTTP reverse proxy using:

- **Bandit** as the HTTP server
- **Plug** for the HTTP request/response abstraction and routing
- **Finch** as the HTTP client used to communicate with upstream services

The current proxy can forward:

### Requests

- HTTP methods
- request paths
- raw query strings
- end-to-end request headers
- request bodies

Request bodies are currently buffered in memory and limited to approximately
1 MB. A future version should support streaming and backpressure instead.

Hop-by-hop headers are removed before requests are sent to the upstream.

### Responses

Haegolmul currently forwards:

- HTTP status codes
- response headers
- response bodies
- multiple `Set-Cookie` headers

Hop-by-hop response headers are filtered before the response is returned to
the client.

This means the current request path looks approximately like this:

```text
Client
  │
  │ HTTP request
  ▼
Bandit
  │
  ▼
Plug.Conn
  │
  ▼
Haegolmul.HTTP
  │
  ▼
Haegolmul.Proxy
  │
  ▼
Finch
  │
  ▼
Upstream
  │
  │ HTTP response
  ▼
Finch
  │
  ▼
Haegolmul.Proxy
  │
  ▼
Bandit
  │
  ▼
Client
```

## Security Considerations

Haegolmul is currently experimental software and **must not be considered
production-ready**.

Several security-relevant behaviors are already intentionally handled.

### Hop-by-hop headers

A reverse proxy terminates one HTTP connection and creates another:

```text
Client <──── connection A ────> Haegolmul
Haegolmul <── connection B ───> Upstream
```

Headers describing connection A must not blindly be copied to connection B,
and vice versa.

Haegolmul therefore filters known hop-by-hop headers and also respects
additional hop-by-hop header names declared through the HTTP `Connection`
header.

### Request body limits

Request bodies are currently buffered before being sent upstream.

Because allowing an attacker to make the proxy buffer arbitrary amounts of
data would itself create a denial-of-service risk, Haegolmul currently rejects
request bodies larger than the configured limit.

Large-body streaming will be investigated in a later development phase.

## Development

Install dependencies:

```bash
mix deps.get
```

Run the test suite:

```bash
mix test
```

Start Haegolmul:

```bash
mix run --no-halt
```

The development server currently listens on:

```text
http://localhost:8080
```

and proxies requests to the development upstream at:

```text
http://localhost:4000
```

These values are currently hard-coded for development and will later move into
application configuration.

## Roadmap

The immediate development plan is:

1. Add automated integration tests for the complete proxy path.
2. Replace the external development test server with a controlled test
   upstream for ExUnit.
3. Introduce an observation model for incoming requests.
4. Implement policy evaluation.
5. Introduce explicit verdicts such as `allow`, `challenge`, and `deny`.
6. Design the first bot-detection and challenge mechanisms.
7. Move upstream and server settings into configuration.
8. Investigate streaming request and response bodies.
9. Add observability, metrics, and structured logging.
10. Harden the proxy for adversarial traffic.

## Name

The name **Haegolmul** (해골물, literally "skull water") refers to a famous
story associated with the Korean Buddhist monk Wonhyo.

According to the traditional account, Wonhyo woke during the night while
travelling and drank what he believed to be fresh water from a container.
In daylight he discovered that the water had actually been collected inside
a human skull.

The experience became associated with his realization that perception and
the mind fundamentally shape how reality is experienced.

The name fits the project because Haegolmul similarly does not merely ask
what a request appears to be at first glance. It observes the request and
attempts to determine what is actually behind it.

## License

TBD
