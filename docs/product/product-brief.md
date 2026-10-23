# AuraVibes Product Brief

Status: Agreed product definition. Does not describe verified feature
availability. Open delivery decisions remain below.

## Product definition

AuraVibes makes AI easy to use by connecting people's tools and doing everyday
work for them. Users start with default AI access, choose a supported task, and
get a clear result. They can reuse agents and skills for recurring work.

## Audience and purpose

Help everyday people complete personal and practical tasks with AI, without
requiring coding knowledge. See [target users](target-users.md).

## Core tasks

1. **Get help:** ask questions, write, summarize, and plan through chat.
2. **Act through connected services:** find information and perform tasks with
   clear permissions.
3. **Reuse useful help:** save an agent's instructions and skills for recurring
   tasks.

## First successful experience

Success means users feel AI is easy to use: they connect their tools, delegate
a task, and get useful work done for them. Examples include managing calendars
and email, completing work chores, filling in forms, and conducting research.
These are intended outcomes, not promises of current integration support.

The differentiator is easier delegation through connected tools, even when
another AI technically supports the same task. Exclusive capability is not a
requirement.

Users choose their first task from calendar, email, forms, or research rather
than following one fixed demo. Guide them toward options supported by their
connected tools; do not present unsupported tasks as available.

Onboarding should lead to one completed task. Include the minimum connection
or agent setup needed for that task before the result. Introduce other advanced
configuration after users experience value.

## Tool permission classification

Read-only versus write-capable connection tools are not yet classified. Defining
that classification in tool templates is future work. No default read/write
approval policy has been agreed here.

## Task completion

A task is complete when the requested outcome has happened and the user gets
a clear result or confirmation. A draft counts as complete only when the user
requested a draft. Failed or partial work must clearly show what remains.

## Reusable help

An Agent is a reusable AI helper with instructions and selected Skills. A Skill
provides guidance for a particular task. Connections provide access to services;
neither Agents nor Skills own connection credentials. See the
[shared glossary](../concepts/glossary.md).

## Model access

AuraVibes should provide default AI model access so everyday users do not need
to connect their own provider before starting. Connecting another provider is
optional. This is product direction, not a claim of current availability.

Pricing, usage limits, and any account requirement for default access remain
open decisions.

## Later scope

Creating pages, games, and apps is later scope rather than a requirement for the
first version defined here.

## Open decisions

- What pricing, usage limits, and account requirements apply to default model
  access?
- Which connected-service tasks belong in the initial scope?

Use the [shared glossary](../concepts/glossary.md) for settled terminology.
