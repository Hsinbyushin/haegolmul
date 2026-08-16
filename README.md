<p align="center">
  <img src="assets/haegolmul-logo.png" alt="Haegolmul logo" width="320">
</p>

<p align="center">
  A lightweight, bot-aware reverse proxy written in Elixir.
</p>

> **Status:** Haegolmul is currently an experimental project under active development.
> It is not ready for production use.

## What is Haegolmul?

Haegolmul is an experimental reverse proxy designed to protect web applications from aggressive bots, scrapers, and automated traffic.

Instead of trying to definitively determine whether a client is a human or a bot, Haegolmul evaluates what it can actually observe about an incoming request.

Based on those observations, a request receives a verdict:

```text
                         Request
                            │
                            ▼
                       Observation
                            │
              ┌─────────────┼─────────────┐
              │             │             │
           Headers         Rate        Behaviour
              │             │             │
              └─────────────┼─────────────┘
                            │
                            ▼
                         Policy
                            │
                            ▼
                         Verdict
                            │
                 ┌──────────┼──────────┐
                 │          │          │
                 ▼          ▼          ▼
               ALLOW    CHALLENGE     DENY
                 │
                 ▼
              Upstream
```

Clients considered suspicious may be asked to perform a computational challenge before they are allowed to reach the upstream application.

The project is inspired in part by [Anubis](https://github.com/TecharoHQ/anubis), while exploring how such a system can be designed around Elixir, OTP, functional programming, and the BEAM.

## Why "Haegolmul"?

**Haegolmul (해골물)** means roughly **"skull water"** in Korean.

The name refers to a famous story associated with the Korean Buddhist philosopher **Wonhyo (원효)**.

According to the traditional story, Wonhyo awoke during the night feeling extremely thirsty. In the darkness, he found water and drank from it. The water seemed refreshing and satisfying.

When daylight came, he discovered that the water he had enjoyed had been collected in a human skull. Upon seeing what he had actually drunk, his perception of the same water changed completely.

The story is traditionally associated with Wonhyo's insight into the role of mind and perception.

That idea provides the guiding metaphor for Haegolmul:

> **We do not know what a client is. We judge what we can observe.**

A User-Agent does not make a client human.

An IP address does not make a client malicious.

Executing JavaScript does not prove that a client is legitimate.

Haegolmul therefore treats bot detection as the evaluation of **evidence**, rather than an attempt to establish an absolute identity.

## Design goals

Haegolmul aims to be:

* **Lightweight** — suitable as a small service in front of an existing application.
* **Observable** — decisions should be explainable rather than mysterious.
* **Stateless where possible** — clients should not force the server to maintain expensive per-challenge state.
* **Composable** — policies should consist of small, understandable rules.
* **Resilient** — hostile traffic should not easily exhaust the protection layer itself.
* **Protocol-conscious** — proxy behavior should be predictable and correct.
* **Educational** — the project intentionally explores how a security-oriented network service can be designed using Elixir and OTP.

## Planned architecture

```text
                           Internet
                              │
                              ▼
                     ┌─────────────────┐
                     │     Bandit      │
                     │   HTTP Server   │
                     └────────┬────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │   Haegolmul     │
                     │   Observation   │
                     └────────┬────────┘
                              │
                              ▼
                     ┌─────────────────┐
                     │  Policy Engine  │
                     └────────┬────────┘
                              │
                  ┌───────────┼───────────┐
                  │           │           │
                  ▼           ▼           ▼
                ALLOW     CHALLENGE      DENY
                  │           │
                  │           ▼
                  │     Proof of Work
                  │           │
                  │      valid token
                  │           │
                  └───────────┤
                              │
                              ▼
                     ┌─────────────────┐
                     │  Reverse Proxy  │
                     └────────┬────────┘
                              │
                              ▼
                           Upstream
```

The initial implementation uses:

* **Elixir / OTP** for the application and supervision model
* **Bandit** as the HTTP server
* **Plug** as the HTTP request/response abstraction
* **Finch** for upstream HTTP connections

The policy engine, challenge system, token format, proof-of-work validation, and mitigation logic are intended to remain part of Haegolmul itself.

## Roadmap

### v0.1 — Proof of concept

* [x] OTP application
* [x] Bandit HTTP server
* [x] Basic Plug routing
* [x] HTTP tests
* [ ] Reverse proxy
* [ ] Request observation
* [ ] Policy engine
* [ ] `allow`, `challenge`, and `deny` verdicts
* [ ] Signed challenge tokens
* [ ] SHA-256 proof-of-work challenge
* [ ] Browser challenge page
* [ ] Temporary access tokens/cookies
* [ ] Basic rate limiting
* [ ] Structured logging
* [ ] Health endpoint
* [ ] Docker image

### Later

Potential future work includes:

* weighted policies
* IP/CIDR policies
* trusted proxy handling
* configurable challenge difficulty
* key rotation
* Prometheus metrics
* streaming proxy support
* WebSocket support
* more sophisticated client observations
* load and adversarial testing

## Development

Requirements:

* Elixir
* Erlang/OTP

Install dependencies:

```bash
mix deps.get
```

Run the development server:

```bash
mix run --no-halt
```

Haegolmul currently listens on:

```text
http://localhost:8080
```

Test it with:

```bash
curl -i http://localhost:8080
```

Run the test suite:

```bash
mix test
```

## Security

Haegolmul is currently a learning and research project.

**Do not use it as a security boundary for production systems yet.**

Anti-bot systems operate in an adversarial environment. A proof-of-work challenge does not prove that a client is human, and heuristics can produce both false positives and false negatives.

The goal is not to make automated access impossible.

The goal is to make abusive automated access **more expensive while keeping legitimate access inexpensive**.

## Inspiration

Haegolmul is inspired by the ideas behind [Anubis](https://github.com/TecharoHQ/anubis), particularly the use of client-side computational challenges to increase the cost of large-scale automated scraping.

Haegolmul is not a port of Anubis. It is an independent implementation intended to explore a similar problem through the architecture and concurrency model of Elixir/OTP.

## License

License to be determined.
