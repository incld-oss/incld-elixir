defmodule Incld.Approvals do
  @moduledoc "Functions for durable approval requests, decisions, events, and policies."

  alias Incld.Request

  def list(client, params \\ %{}), do: Request.get_page(client, "/approvals", params)
  def get(client, approval_id), do: Request.get_data(client, "/approvals/#{approval_id}")

  def check(client, resource_type, resource_id, action, requester_id) do
    Request.post_data(client, "/approvals/check", %{
      resource_type: resource_type,
      resource_id: resource_id,
      action: action,
      requester_id: requester_id
    })
  end

  def create(client, payload, opts \\ []),
    do: Request.post_data(client, "/approvals", payload, [200, 201], opts)

  def update(client, approval_id, payload),
    do: Request.patch_data(client, "/approvals/#{approval_id}", payload)

  def decide(client, approval_id, decision, approver_id, opts \\ [])
      when decision in ["approved", "rejected"] and is_binary(approver_id) and approver_id != "" do
    Request.post_data(
      client,
      "/approvals/#{approval_id}/decisions",
      %{
        decision: decision,
        approver_id: approver_id,
        reason: Keyword.get(opts, :reason)
      },
      [200],
      opts
    )
  end

  def approve(client, approval_id, approver_id, opts \\ []),
    do: decide(client, approval_id, "approved", approver_id, opts)

  def reject(client, approval_id, approver_id, opts \\ []),
    do: decide(client, approval_id, "rejected", approver_id, opts)

  def cancel(client, approval_id, actor_id, opts \\ []) do
    Request.post_data(client, "/approvals/#{approval_id}/cancel", %{
      actor_id: actor_id,
      reason: Keyword.get(opts, :reason)
    })
  end

  def revoke(client, approval_id, actor_id, opts \\ []) do
    Request.post_data(client, "/approvals/#{approval_id}/revoke", %{
      actor_id: actor_id,
      reason: Keyword.get(opts, :reason)
    })
  end

  def delete(client, approval_id), do: Request.delete(client, "/approvals/#{approval_id}")

  def events(client, approval_id),
    do: Request.get_page(client, "/approvals/#{approval_id}/events")

  def list_policies(client), do: Request.get_page(client, "/approval-policies")

  def get_policy(client, policy_id),
    do: Request.get_data(client, "/approval-policies/#{policy_id}")

  def create_policy(client, payload),
    do: Request.post_data(client, "/approval-policies", payload, [200, 201])

  def update_policy(client, policy_id, payload),
    do: Request.patch_data(client, "/approval-policies/#{policy_id}", payload)

  def delete_policy(client, policy_id),
    do: Request.delete(client, "/approval-policies/#{policy_id}")
end
