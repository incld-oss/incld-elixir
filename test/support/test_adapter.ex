defmodule Incld.TestAdapter do
  @moduledoc false

  def put(adapter) when is_function(adapter, 1) do
    Process.put({__MODULE__, :adapter}, adapter)
  end

  def run(request) do
    case Process.get({__MODULE__, :adapter}) do
      adapter when is_function(adapter, 1) -> adapter.(request)
      nil -> raise "Incld.TestAdapter has not been configured for this test"
    end
  end
end
