defmodule Pleroma.Web.ActivityPub.MRF.RemovePublicPolicy do
  @moduledoc "MRF policy which drops as:Public from outgoing activities"
  @behaviour Pleroma.Web.ActivityPub.MRF.Policy

  require Logger

  @impl true
  def filter(
    %{"to" => to, "cc" => cc, "actor" => actor} = message
  ) do
    message = if String.starts_with?(actor, Pleroma.Web.Endpoint.url()) do
      to = to |> Enum.filter(fn value ->
           value not in
           ["Public",
            "as:Public",
            "https://www.w3.org/ns/activitystreams#Public"
           ]
           end)
      cc = cc |> Enum.filter(fn value ->
           value not in
           ["Public",
            "as:Public",
            "https://www.w3.org/ns/activitystreams#Public"
           ]
           end)
      message = cond do
        is_map(Map.get(message, "object")) ->
          object = Map.get(message, "object")
                   |> Map.put("to", to)
                   |> Map.put("cc", cc)
          message = Map.put(message, "object", object)
        true ->
          message
      end
      #Logger.info("TO: #{IO.inspect(to)}")
      #Logger.info("CC: #{IO.inspect(cc)}")
      #Logger.info("MESSAGE: #{IO.inspect(message)}")
      message = message
                |> Map.put("to", to)
                |> Map.put("cc", cc)
    end
    {:ok, message}
  end

  @impl true
  def filter(message) do
    {:ok, message}
  end

  @impl true
  def describe do
    {:ok, %{mrf_sample: %{to: "not Public idk"}}}
  end

    @impl true
  def config_description do
    %{
      key: :mrf_remove_public,
      related_policy: "Pleroma.Web.ActivityPub.MRF.RemovePublicPolicy",
      label: "MRF Remove Public Policy",
      description: "Drop as:Public addressing from outgoing activities",
      children: [
        %{
          key: :instances,
          description: "List of instances to which Public should be dropped to private",
          type: {:list, :string},
          placeholder: "instance",
          suggestion: "some.instance"
        }
      ]
    }
  end

end
