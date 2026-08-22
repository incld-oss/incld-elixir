defmodule Incld.Webhook do
  @moduledoc """
  Webhook verification and parsing.
  """

  @doc """
  Verifies a timestamped `Incld-Signature` header and returns the parsed payload.

  The signature format is `t=<unix seconds>,v1=<hex digest>`. The digest is an
  HMAC-SHA256 over `<timestamp>.<raw body>`. Signatures older or newer than the
  tolerance are rejected; the default tolerance is five minutes.
  """
  def verify(raw_body, signature, secret, tolerance \\ 300)
      when is_binary(raw_body) and is_binary(signature) and is_binary(secret) and
             is_integer(tolerance) and tolerance >= 0 do
    with {:ok, timestamp, provided_digest} <- parse_signature(signature),
         true <- fresh?(timestamp, tolerance),
         {:ok, provided} <- Base.decode16(provided_digest, case: :mixed),
         expected <- :crypto.mac(:hmac, :sha256, secret, "#{timestamp}.#{raw_body}"),
         true <- secure_compare(expected, provided) do
      Jason.decode(raw_body)
    else
      {:error, %Jason.DecodeError{} = error} -> {:error, error}
      _ -> {:error, :invalid_signature}
    end
  end

  defp parse_signature(signature) do
    parts =
      signature
      |> String.split(",", trim: true)
      |> Enum.reduce(%{}, fn part, acc ->
        case String.split(part, "=", parts: 2) do
          [key, value] -> Map.put_new(acc, String.trim(key), String.trim(value))
          _ -> acc
        end
      end)

    with timestamp when is_binary(timestamp) <- Map.get(parts, "t"),
         {timestamp, ""} when timestamp >= 0 <- Integer.parse(timestamp),
         digest when is_binary(digest) and digest != "" <- Map.get(parts, "v1") do
      {:ok, timestamp, digest}
    else
      _ -> {:error, :invalid_signature}
    end
  end

  defp fresh?(timestamp, tolerance) do
    abs(System.system_time(:second) - timestamp) <= tolerance
  end

  defp secure_compare(left, right) when byte_size(left) == byte_size(right) do
    left_list = :binary.bin_to_list(left)
    right_list = :binary.bin_to_list(right)

    left_list
    |> Enum.zip(right_list)
    |> Enum.reduce(0, fn {left_byte, right_byte}, difference ->
      Bitwise.bor(difference, Bitwise.bxor(left_byte, right_byte))
    end)
    |> Kernel.==(0)
  end

  defp secure_compare(_, _), do: false
end
