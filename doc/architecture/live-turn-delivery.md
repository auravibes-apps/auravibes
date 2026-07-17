# Live Turn Delivery

Live turn events are ephemeral. Provider text is published through
`LiveTurnBroker`; it is never stored in `ConversationDelta`, `WorkspaceEvent`,
or a Redis list/cache.

Development runs a single process, so its process-local broker fans out to all
local subscribers. Production and staging enable Redis. Serverpod global
messages then fan out live events across server instances, preserving the
publisher's event order per turn.

Without Redis, multiple instances deliver live events only to subscribers on
the publisher's process. Clients receive no in-flight text after a
cross-instance connection. They recover only the final durable turn/message
state; no polling or replay of text chunks occurs.
