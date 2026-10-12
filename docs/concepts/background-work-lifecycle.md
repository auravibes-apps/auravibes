# Background work lifecycle

This matrix records the lifecycle contract for detached tool work. A result is
conversation history only after it has been delivered as a conversation
message. A `BackgroundWork` record or a pending completion is never executable
history.

| Operation | Local conversation | Cloud conversation |
| --- | --- | --- |
| Export/archive | Export is a point-in-time transcript snapshot. The source conversation keeps processing its work; the exported copy excludes work IDs, arguments, stored result records, and queued operations. Results already delivered as transcript messages are included. | When the app exports a cloud-backed transcript, it is the same static snapshot: export does not stop the server-side source operation, and importing the file creates a new conversation with no executable work. |
| Delete conversation | Fence new detach, request durable stop and the available handle cancellation, then delete the local conversation tree and its cascaded work records. If cancellation is not confirmed, a late completion cannot be persisted. A failed delete reopens the fence. | The server cancels its persisted turns/jobs and purges the conversation tree and cascaded work records. A server-side tool future may still finish if its provider cannot be interrupted; with the work record and conversation gone, it cannot deliver a completion to another conversation. |
| Delete workspace | Fence new detach and request cancellation for tracked handles before deleting the local workspace and cascaded conversation/work records. Unconfirmed late completions are not persisted. | Soft-delete the workspace and mark running work `stopRequested`. A late completion sees the deleted workspace and is terminalized as `outcome_unknown` without result content, completion event, or follow-up turn. Existing completed content remains subject to the retention and purge rules in #972/#1310. |
| Restore/restart | Importing a conversation archive creates fresh message/conversation identities, maps incomplete messages to errors, and creates no background-work records. At app startup, active local work created before startup is terminalized as failed/`outcome_unknown`; it is never re-executed. | Server startup terminalizes active work owned by that server instance as failed/`outcome_unknown`, without replay. A queued user event resumes only under #1225's rule: the conversation was not explicitly stopped. A database backup restore must reapply deletions before serving data; that service-level exercise is tracked by #1310. |
| Fork | Copy delivered transcript history, but remove tool calls linked to any detached-work record, regardless of its status. Do not copy in-memory queued drafts. Keep unrelated delivered tool history. | Copy only durable messages. Do not copy queued messages/events, pending turns/jobs, or detached tool calls/results; keep unrelated delivered history. |

For archive export, “the archived conversation continues” means the original
source continues and can receive its own completion. The file is only a
snapshot; it cannot receive later completions or resume the operation.

## Retention boundary

Conversation and workspace deletion use the existing local/server deletion
paths above. Backup expiry, data-copy inventory, vendor retention controls,
and deletion replay after restoring a cloud backup are service-level controls,
not guarantees made by the conversation archive format. #1228 requires the
background-work records, pending completions, and stored results to be listed
in #972's inventory, and requires #1310's restore exercise to prove that deleted
conversation data, executable work, and follow-up turns do not return before a
restored service is exposed.

The retention targets and legal review are already specified in #972; the
implementation and staging evidence are specified in #1310. No new product
decision is needed for the behaviors in this matrix. If a provider cannot meet
an approved target, track an owner and release decision in #972 before claiming
compliance.
