# Glass Polish Workstation

An independent workstation microservice that communicates with the
[glass](https://github.com/cmramseyer/glass) app via Kafka.

Glass owns the polishing workflow. This workstation keeps a local,
eventually consistent projection of it, so operators can keep working
even when glass — or Kafka itself — is down.

## How it stays available

- **Local projection.** Tracking rows live in this app's own SQLite
  database, built from the events glass publishes. Reads never leave
  the workstation.
- **Local writes first.** Pressing *Complete one work* increments the
  local counter and stores the event in a transactional outbox — in the
  same database transaction. The operator gets an instant response with
  no network involved.
- **Relayed publishing.** A background relay picks up outbox rows and
  publishes them to Kafka, retrying until the broker acknowledges. If
  Kafka is down, rows simply stay `pending` and go out when it recovers.
- **Resumed consumption.** When Kafka comes back, the consumer group
  picks up where it left off and the projection converges.

The price of this independence is eventual consistency: right after an
outage, local state may lag behind glass in either direction, and it
converges as events flow again. Delivery is at-least-once everywhere,
so both sides deduplicate by `event_id`.

## Event contract

Consumed from `glass.work.queued_polish` (key = `event_id`):

```json
{
  "event_id": "0d55c41c-6396-4f24-9f9e-f6692799d4f4",
  "tracking_id": 123,
  "order_id": 456,
  "customer_name": "Charlie",
  "product_name": "Float 4mm. Clear",
  "extra_data": { "polish_type": "Edge polish" },
  "width": 1000,
  "height": 500,
  "total_line": 5,
  "done": 1,
  "occurred_at": "2026-09-10T22:30:00Z"
}
```

Missing trackings are created (`done → available`, `total_line → total_item`,
`completed = 0`); existing ones update `available = done`. Replays of the
same `event_id` are ignored. The table shows `Pending = available − completed`.

Published to `glass.work.done_polish` (key = `tracking_id`):

```json
{
  "event": "polish_work_done",
  "event_id": "7c9e6679-7425-40de-944b-e07a6b0b7b0e",
  "tracking_id": 123,
  "qty": 1,
  "occurred_at": "2026-09-11T00:55:00Z"
}
```

## Components

- `WorkCompletedConsumer` — applies inbound events with durable
  deduplication (`processed_events`).
- `PolishTrackingsController#complete` — records one finished work unit
  and the outbox row atomically.
- `OutboxMessage` + `OutboxPublisherJob` — transactional outbox relayed
  immediately after commit, with a 30-second Solid Queue sweep as backup.

## Running locally

```sh
bin/rails server -p 3002
bundle exec karafka server
bin/jobs
```

Kafka is expected at `localhost:9092` (override with
`KAFKA_BOOTSTRAP_SERVERS`). Consumer group: `glass-polish-trackings`.

## Stack

Rails 8.1 · SQLite · Karafka (consumers + producer) · Solid Queue · RSpec
