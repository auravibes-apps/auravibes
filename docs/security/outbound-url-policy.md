# Outbound URL policy

`PublicUrlGuard` rejects unsafe URL syntax, blocked host labels, and any DNS
answer in a blocked address range. A mixed public/private answer is rejected as
a whole. Callers that make HTTP requests must keep validation connected to the
transport so a later DNS lookup cannot change the destination.

## Shared pinned request path

The URL tool and Connector HTTP adapter call `resolvePublicUri` or
`resolveHttpsUri`, then pass the returned addresses to `UrlService`. On IO,
`UrlService` uses the pinned HTTP adapter, preserves the original hostname for
the HTTP Host header and TLS check, and disables automatic redirects. A 3xx
destination is validated before the response is returned; the service does not
follow it. Connector authorization headers therefore are never automatically
sent to a redirect origin.

## Safe image path

`SafeImageLoader` validates each HTTPS URL and disables automatic redirects.
Its IO connection factory resolves and validates the destination when opening
the socket, then connects to that validated address while retaining the URL
hostname for TLS. Redirects are processed one at a time, so each new host is
validated before its request. This is a separate connection-time pinning path;
it does not attach application credentials to image requests.

## Separate outbound paths

OAuth authorization and device-verification URLs are handed to the system
browser after HTTPS/public-host validation. The browser owns DNS resolution,
transport pinning, and redirect handling for those navigations.

Model-provider API requests and OAuth token/device-code exchanges also validate
their configured endpoint through `PublicUrlGuard`, but use their own
`package:http` or Dio clients rather than `UrlService`'s pinned-address
contract. The redirect and connection behavior of those flows is outside this
focused regression suite and remains part of the broader credential lifecycle
review tracked by #972.
