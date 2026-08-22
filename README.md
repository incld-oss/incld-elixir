# incld Elixir SDK

Req-based trusted-server client for the incld v1 API.

```elixir
client = Incld.client(System.fetch_env!("INCLD_SECRET_KEY"))

{:ok, schedule} =
  Incld.Schedules.create(
    client,
    %{
      action: "sync_contacts",
      external_user_id: "user_123",
      recurrence: recurrence,
      timezone: "Australia/Melbourne"
    },
    idempotency_key: request_id
  )
```

Modules cover Actions, Schedules, Runs, Sessions, Approvals and policies, Audit, Bulk, and signed webhook verification. Collection helpers return `{:ok, %{data: items, meta: meta}}`; resource helpers return the unwrapped data object. API failures return `%Incld.APIError{status, code, message, fields, request_id}`.

Schedule commands use stable action identifiers, canonical Audit paths are `/audit-events`, and canonical Bulk paths are `/bulk-operations`. Pass `idempotency_key:` to supported create calls when retrying mutations.

## Configure the Req client

```elixir
client =
  Incld.client(System.fetch_env!("INCLD_SECRET_KEY"),
    base_url: "https://api.incld.dev/v1"
  )
```

This is a trusted-server client. Do not expose it or its key to LiveView hooks or browser JavaScript. If a Phoenix application uses the incld React packages, build a same-origin controller that authenticates the current user, allowlists routes, scopes reads, and injects actor identity.

## Modules and functions

| Module | Functions |
| --- | --- |
| `Incld.Actions` | `define/2`, `list/2`, `get/2` |
| `Incld.Schedules` | `list/2`, `get/2`, `create/3`, `update/3`, `delete/2`, `pause/2`, `resume/2`, `list_runs/3`, `events/3`, `preview/3` |
| `Incld.Runs` | `list/2`, `get/2` |
| `Incld.Approvals` | `list/2`, `get/2`, `check/5`, `create/3`, `update/3`, `decide/5`, `approve/4`, `reject/4`, `cancel/4`, `revoke/4`, `delete/2`, `events/2` |
| Approval policies | `list_policies/1`, `get_policy/2`, `create_policy/2`, `update_policy/3`, `delete_policy/2` |
| `Incld.Audit` | `list/2`, `get/2`, `create/3` |
| `Incld.Bulk` | `list/2`, `get/2`, `create/3`, `chunks/2`, `events/2`, `cancel/3` |
| `Incld.Sessions` | `create/2` |
| `Incld.Webhook` | `verify/3`, `verify/4` |

## Pages, idempotency, and errors

```elixir
{:ok, %{data: schedules, meta: meta}} =
  Incld.Schedules.list(client, %{limit: 100, cursor: nil})

if meta["has_more"] do
  Incld.Schedules.list(client, %{limit: 100, cursor: meta["next_cursor"]})
end
```

Pass the cursor unchanged. Supported create/decision functions accept `idempotency_key:`; cancellation functions accept actor/reason options according to their module signature.

```elixir
case Incld.Approvals.get(client, approval_id) do
  {:ok, approval} -> approval

  {:error, %Incld.APIError{} = error} ->
    Logger.error("incld request failed",
      status: error.status,
      code: error.code,
      fields: error.fields,
      request_id: error.request_id
    )
end
```

## Verify signed delivery

Capture the exact raw request body before Plug JSON decoding changes it:

```elixir
with [signature] <- get_req_header(conn, "incld-signature"),
     {:ok, event} <- Incld.Webhook.verify(raw_body, signature, webhook_secret) do
  dispatch(event)
end
```

`verify/3` uses a 300-second tolerance; `verify/4` accepts a custom tolerance. It parses the timestamped `t=…,v1=…` header, compares HMAC-SHA256 in constant time, and returns decoded JSON only after verification. Deduplicate application side effects before acknowledging delivery.
