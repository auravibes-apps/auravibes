# Conversation Progress Delivery

| Scenario                                | Required result                                                                             |
| --------------------------------------- | ------------------------------------------------------------------------------------------- |
| Continue with healthy Redis/coordinator | The coordinator starts a drain from the job wake, without waiting for a recurring schedule. |
| Duplicate/global wake delivery          | One job lease wins; provider executes once.                                                 |
| Redis unavailable or wake missed        | The durable fallback drain claims the job after recovery interval.                          |
| Coordinator restart                     | Leadership startup recovery drains durable queued work.                                     |
| Provider retry                          | Job remains unavailable until persisted `availableAt`; it is not executed early.            |

Healthy dispatch is durable write -> best-effort global job wake -> elected
coordinator's event-driven dispatcher -> per-job lease claim. The recurring
recovery drain is a fallback only, not healthy-path polling. Global coordinator
and per-job leases remain the ownership boundaries.

Conversation progress is split deliberately between an ordered durable event
stream and transient assistant-text updates. Semantic changes—queue edits,
execution transitions, tool decisions, settings changes, and terminal
results—are appended to `ConversationEvent` in the same transaction as their
projection changes. Clients recover those events from a snapshot plus cursor.

Provider text is transient. `WakeupConversationProgressPublisher` emits text
deltas through the conversation progress channel and checkpoints the assistant
message at most once per second, as well as at execution boundaries. A
transient delta never advances the durable event sequence; reconnecting clients
recover checkpointed text from `ConversationSnapshot`.

Development runs a single Serverpod process, while production and staging use
Redis global messages to fan out conversation wakeups and progress across
instances. If a progress notification is missed, clients reload the
authoritative snapshot rather than replaying a process-local stream.
