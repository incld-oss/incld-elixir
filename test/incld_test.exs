defmodule IncldTest do
  use ExUnit.Case

  test "creates a req client" do
    client = Incld.client("my-api-key")
    assert "https://api.incld.dev/v1" in List.wrap(client.options.base_url)
    assert client.options.auth == {:bearer, "my-api-key"}
  end

  test "supports a custom API base URL" do
    client = Incld.client("my-api-key", base_url: "http://localhost:4000/v1")
    assert "http://localhost:4000/v1" in List.wrap(client.options.base_url)
    assert client.options.auth == {:bearer, "my-api-key"}
  end

  test "supports organization and end-user API scope" do
    adapter = fn request ->
      assert Req.Request.get_header(request, "incld-organization-id") == ["org_trusted"]
      assert Req.Request.get_header(request, "incld-user-id") == ["user_trusted"]

      {request,
       Req.Response.new(
         status: 200,
         body: %{"data" => [], "meta" => %{"has_more" => false, "next_cursor" => nil}}
       )}
    end

    client =
      "my-api-key"
      |> Incld.client(
        base_url: "http://incld.test",
        organization_id: "org_trusted",
        user_id: "user_trusted"
      )
      |> Req.merge(adapter: adapter)

    assert {:ok, %{data: []}} = Incld.Schedules.list(client)
  end

  test "rejects user scope without an organization" do
    assert_raise ArgumentError, fn -> Incld.client("my-api-key", user_id: "user_trusted") end
  end

  test "rejects empty scope identifiers" do
    assert_raise ArgumentError, fn -> Incld.client("my-api-key", organization_id: " ") end

    assert_raise ArgumentError, fn ->
      Incld.client("my-api-key", organization_id: "org_trusted", user_id: "")
    end
  end

  test "webhook verify valid signature" do
    secret = "secret123"
    payload = %{"type" => "schedule.run", "run_id" => "run_abc"}
    raw_body = Jason.encode!(payload)
    timestamp = System.system_time(:second)

    digest =
      :crypto.mac(:hmac, :sha256, secret, "#{timestamp}.#{raw_body}")
      |> Base.encode16(case: :lower)

    signature = "t=#{timestamp},v1=#{digest}"

    assert {:ok, parsed_payload} = Incld.Webhook.verify(raw_body, signature, secret)
    assert parsed_payload == payload
  end

  test "webhook verify invalid signature" do
    secret = "secret123"
    raw_body = ~s({"type":"schedule.run"})
    signature = "invalid_signature"

    assert {:error, :invalid_signature} = Incld.Webhook.verify(raw_body, signature, secret)
  end

  test "webhook verify rejects an expired timestamp" do
    secret = "secret123"
    raw_body = ~s({"type":"schedule.run"})
    timestamp = System.system_time(:second) - 301

    digest =
      :crypto.mac(:hmac, :sha256, secret, "#{timestamp}.#{raw_body}")
      |> Base.encode16(case: :lower)

    assert {:error, :invalid_signature} =
             Incld.Webhook.verify(raw_body, "t=#{timestamp},v1=#{digest}", secret)
  end

  test "webhook verify accepts a caller-supplied tolerance" do
    secret = "secret123"
    raw_body = ~s({"type":"schedule.run"})
    timestamp = System.system_time(:second) - 301

    digest =
      :crypto.mac(:hmac, :sha256, secret, "#{timestamp}.#{raw_body}")
      |> Base.encode16(case: :lower)

    assert {:ok, _event} =
             Incld.Webhook.verify(raw_body, "t=#{timestamp},v1=#{digest}", secret, 600)
  end

  test "lists schedule events through the canonical Audit history route" do
    adapter = fn request ->
      assert request.method == :get
      assert request.url.path == "/schedules/sch_123/events"
      assert URI.decode_query(request.url.query)["cursor"] == "evt_0"

      response =
        Req.Response.new(
          status: 200,
          body: %{
            "data" => [%{"id" => "evt_1", "component" => "schedules"}],
            "meta" => %{"has_more" => false, "next_cursor" => nil}
          }
        )

      {request, response}
    end

    client =
      "my-api-key"
      |> Incld.client(base_url: "http://incld.test")
      |> Req.merge(adapter: adapter)

    assert {:ok, %{data: [%{"id" => "evt_1"}]}} =
             Incld.Schedules.events(client, "sch_123", %{cursor: "evt_0"})
  end

  test "gets one project run" do
    adapter = fn request ->
      assert request.method == :get
      assert request.url.path == "/runs/run_123"

      {request,
       Req.Response.new(
         status: 200,
         body: %{"data" => %{"id" => "run_123", "schedule_id" => "sch_123"}}
       )}
    end

    client =
      "my-api-key"
      |> Incld.client(base_url: "http://incld.test")
      |> Req.merge(adapter: adapter)

    assert {:ok, %{"id" => "run_123", "schedule_id" => "sch_123"}} =
             Incld.Runs.get(client, "run_123")
  end
end
