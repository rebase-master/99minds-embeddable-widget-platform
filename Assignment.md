# Senior Backend Engineer (Ruby on Rails) - Take-Home Assignment

## Multi-Tenant Trigger Engine for an Embeddable Widget Platform

**Estimated time:** 8–10 hours of focused work. Spread it over a few days if you like.

---

## Background

We operate a SaaS platform whose merchants embed a JavaScript widget on their storefronts. The widget displays UI elements - toasts, modals, banners - but it doesn't decide *what* to show or *when*. That decision lives in our backend.

The flow looks like this:

1. A merchant's storefront sends us events as the shopper interacts with it: `cart.updated`, `order.placed`, `product.viewed`, etc.
2. Each merchant has configured **campaigns** - rules like "when a shopper's cart total exceeds $50, push a free-shipping banner" or "when a shopper places their third order, push a loyalty modal."
3. Our backend ingests the event, evaluates which campaigns match, and dispatches a render trigger in near real-time to the merchant's embedded SDK instance for that shopper.
4. The SDK renders the component on the storefront.

You're being asked to design and build the backend service that does this.

---

## Your Task

Build a Ruby on Rails application that:

1. Exposes a **webhook ingestion API** for merchants' storefronts to send shopper events.
2. Lets a merchant configure **campaigns** (event-driven rules) and **themes** (visual configuration the SDK reads) via a clean HTTP API.
3. Evaluates incoming events against active campaigns and dispatches a **render trigger** in near real-time to the appropriate connected SDK instance.
4. Exposes an SDK-facing endpoint that lets a browser-embedded widget connect, identify itself, fetch its theme, and receive triggers as they happen.
5. Is multi-tenant - merchants must not be able to see each other's data, and one merchant's traffic spike should not degrade another's experience meaningfully.

You do not need to build the SDK or a UI. A `curl` or two and a minimal HTML page that connects to your real-time channel is enough to demonstrate end-to-end flow.

---

## Functional Requirements

### Webhook ingestion

A storefront sends events to your backend:

```http
POST /v1/events
Authorization: Bearer <merchant_api_key>
X-Signature: <hmac-sha256 of body with merchant_secret>

{
  "shopper_id": "shp_xyz789",
  "event_type": "cart.updated",
  "occurred_at": "2026-05-23T10:14:22Z",
  "data": {
    "cart_total_cents": 7500,
    "currency": "USD",
    "item_count": 3
  }
}
```

The endpoint must:

- Authenticate the merchant (API key + HMAC signature verification on the body).
- Persist the event (durably enough that we can replay if needed).
- Acknowledge fast - the storefront should not wait for downstream evaluation.
- Reject duplicates (the same event sent twice must not fire two triggers).

### Campaign configuration

A merchant manages campaigns via authenticated HTTP API. Example shape (yours can differ - show us your API design taste):

```http
POST /v1/campaigns
Authorization: Bearer <merchant_api_key>

{
  "name": "Free shipping over $50",
  "active": true,
  "trigger": {
    "event_type": "cart.updated",
    "conditions": [
      { "field": "data.cart_total_cents", "op": "gte", "value": 5000 }
    ]
  },
  "render": {
    "component": "banner",
    "payload": {
      "title": "You've unlocked free shipping",
      "body": "No code needed - applied at checkout",
      "cta": { "label": "Continue", "url": "/checkout" }
    }
  }
}
```

Standard CRUD applies. The condition language doesn't need to be elaborate - equality, numeric comparison, and presence checks are enough. Be ready to talk about how you'd extend it.

### Theme configuration

Each merchant has a theme that the SDK fetches on load:

```http
GET /v1/sdk/theme
Authorization: Bearer <sdk_public_key>
```

Returns the merchant's color tokens, fonts, labels, etc. This endpoint will be hit by every page view on every storefront, so think about caching.

### Real-time trigger delivery

When an event arrives and matches an active campaign, deliver a render trigger to the connected SDK instance for that shopper in near real-time (target sub-second from event ingestion to trigger arriving at the browser).

**You choose the transport.** Action Cable, Server-Sent Events, an external service (Anycable, Centrifugo, Pusher), HTTP long-polling - pick one and be ready to defend the choice in your README. We care about the reasoning, not the specific answer.

Build a minimal HTML page (genuinely minimal - `<script>` tag and a `<pre>`) that connects to your real-time channel as a fake SDK instance, prints incoming triggers, and lets us watch the end-to-end flow during your demo.

### Multi-tenancy

Every query, every cache key, every channel name must be scoped by merchant. A bug here is the worst possible bug. Show us the pattern you use to make cross-tenant leakage hard to write by accident.

---

## Technical Constraints

- **Rails 7.1+ (Rails 8 welcomed).** Ruby 3.2+.
- **Database is yours to pick** - PostgreSQL or MySQL. Justify briefly.
- **Background jobs** - Sidekiq, GoodJob, Solid Queue, your call. If event evaluation is synchronous in your design, defend that.
- **Webhook ingestion should be fast.** The storefront must not block on rule evaluation. Aim for the ingestion endpoint to respond within tens of milliseconds at p99 on local hardware.
- **HMAC verification, idempotency, and tenant scoping are non-negotiable.** A senior engineer who ships any of these wrong on a webhook endpoint is a senior engineer who has caused an incident.
- **No production-grade infrastructure expected.** Docker Compose or a Procfile is fine. We will run it locally.

---

## Bonus / Stretch (not required, but we'll notice)

Pick what interests you. We do not expect all of these.

- **Race condition handling** on campaign evaluation - if two events arrive for the same shopper within milliseconds, what happens? Show us you've thought about it.
- **Rate limiting** on the ingestion endpoint (per-merchant, with a sensible fallback).
- **Replay endpoint** - given a past event ID, re-evaluate and re-fire.
- **Observability** - structured logging, basic metrics (events ingested, triggers fired, lag), even just well-placed instrumentation hooks.
- **Database performance** - indexes that hold up under realistic query patterns, an `EXPLAIN` or two in the README.
- **Frequency caps** - "don't show this campaign to the same shopper more than once a day." Where does this state live? How is it consistent?
- **Test suite** - request specs, model specs, and a couple of integration tests covering the happy path and at least one nasty edge case.
- **A simple seed script** that creates a merchant, a couple of campaigns, and a theme, so we can run your `curl` examples without setup.

---

## Deliverables

1. **A public GitHub (or GitLab) repo** containing:
    - Rails app source.
    - A `docker-compose.yml` or `Procfile.dev` plus a `README.md` covering: how to run it, your architectural decisions, the trade-offs you considered (especially around the real-time transport and the evaluation pipeline), and what you'd do differently with more time.
    - A `requests.http` or `curl` snippets file showing how to exercise every endpoint.
    - The minimal HTML "fake SDK" page for the demo.
2. **A short walkthrough video (max 10 minutes)** - Loom or similar - where you walk through your architecture, run a real event end-to-end, and talk through the key decisions.
3. **A deployed demo is nice-to-have but not required.** Local-runnable is fine.

---

## How We'll Evaluate

In rough order of weight:

1. **Architectural judgment.** Did you pick the right tools and patterns for the constraints, and can you defend the choices? Multi-tenancy strategy, real-time transport, sync vs. async evaluation - these are where senior engineers separate themselves.
2. **Correctness on the dangerous parts.** Webhook auth, idempotency, tenant scoping, and race conditions. Getting these right is the job.
3. **API design.** Are the merchant-facing endpoints intuitive, consistent, hard to misuse? Are errors actionable?
4. **Code quality.** Idiomatic Rails. Service objects, jobs, models in their right shapes. Readable, organized.
5. **Communication.** Does the README and walkthrough show clear thinking? Do you know what's good about your solution *and* what's wrong with it?

We are explicitly **not** evaluating: exhaustive feature coverage, perfect test coverage percentages, a polished UI, or production concerns like horizontal scaling. Mention them in the README if you'd like.

---

## Ground Rules

- AI-assisted development is expected. The 8–10 hour estimate assumes you use it.
- If you hit something ambiguous, make a call, write it down in the README, and move on. We'd rather see your judgment than have you wait on us to clarify.
- If the assignment will take you significantly more than 10 hours, stop and ship what you have. We'd rather see a smaller, finished thing than a sprawling unfinished one.

---

## Questions?

Reply to this email mrudul@99minds.io - we aim to respond within one business day.

Good luck. We're looking forward to seeing what you build.