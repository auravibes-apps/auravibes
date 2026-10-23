# AuraVibes Target Users

This document records intended users and product direction. It does not promise that every example integration or capability is currently supported.

See the [product brief](product-brief.md) for confirmed core tasks, the first
successful experience, and open product decisions.

## Core users

Everyday people who want AI to help with personal and practical tasks. They may be new to AI or AI-savvy, but coding knowledge is not assumed. They want useful results with little friction, clear language, and focused screens. They want AI to feel capable while understanding and controlling what it can access.

## Main need

Help people get everyday tasks done with AI and the tools or services they already use. Chat is a core way to work with connected tools and get help managing AuraVibes itself. Keep clear UI controls too.

## Secondary users

Solo entrepreneurs and teams may use AuraVibes for business tasks and shared cloud workspaces. One person may both use and configure the workspace; a team may have someone who handles setup. Make advanced controls available to everyone, and show them when relevant so everyday workflows stay clear.

## Creation and connections

Some users will ask AI to create simple pages, games, or apps without learning to code. Treat code as a way to reach those outcomes, not as a reason to turn AuraVibes into a developer IDE. Keep execution within the runtimes available on each platform; do not assume mobile CLI or Bash access.

Users want to connect services and platform capabilities they rely on. Canva, Notion, calendars, and email are examples of desired connections, not promises of current support. Describe the user outcome rather than implementation methods such as MCP, APIs, or browser automation. Check the code and product documentation before claiming a specific integration or runtime is supported.

## Guidance for product work

- Make everyday tasks feel simple and dependable. Keep screens focused and avoid unnecessary information.
- Help users feel capable without requiring technical knowledge.
- Make AI access understandable and keep user control clear. Define exact approval behavior for each feature.
- Treat business, team, and AI-assisted creation needs as extensions of the everyday-user focus.
