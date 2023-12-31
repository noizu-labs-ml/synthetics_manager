defmodule SyntheticManagerWeb.SyntheticLive.Upload do
  use SyntheticManagerWeb, :live_view
  alias SyntheticManager.Synthetics.Synthetic
  alias SyntheticManager.Synthetics.Synthetic.Message
  @impl true
  def mount(_params, _session, socket) do
    raw =
      """
      """
    socket = socket
             |> assign(:raw, raw)
             |> assign(:synthetics, socket.assigns[:synthetics] || [])
             |> assign(:live_action, :upload)
             |> assign(:page_title, :upload)
             |> assign(:default_user,  nil)
             |> assign(:user_filter, SyntheticManager.Users.list_users() |> Enum.map(& %{value: &1.id, key: &1}))
             |> assign(:default_organization, nil)
             |> assign(:organization_filter, SyntheticManager.Organizations.list_organizations() |> Enum.map(& %{value: &1.id, key: &1}))
             |> assign(:default_group, nil)
             |> assign(:group_filter, SyntheticManager.Groups.list_groups() |> Enum.map(& %{value: &1.id, key: &1}))
    {:ok, socket}
  end
  @keith 1
  @noizu_labs 1
  @roles %{
    "user" => :user,
    "assistant" => :assistant,
    "system" => :system,
    "function" => :function,
    "function_call" => :function_call,
    "function_response" => :function_response
  }


  defp extract_time(nil), do: nil
  defp extract_time(%DateTime{} = x), do: x
  defp extract_time(s) when is_bitstring("s") do
    case DateTime.from_iso8601(s) do
      {:ok, t} -> t
      _ -> nil
    end
  end
  defp role(role) do
    Enum.find_value(SyntheticManager.MessageRoleEnum.values, :unknown, & (&1 == role || "#{&1}" == role  ) && &1)
  end
  defp status(status) do
    Enum.find_value(SyntheticManager.EntityStatusEnum.values, :enabled, & (&1 == status || "#{&1}" == status  ) && &1)
  end
  defp synthetic_id("ref.synthetic." <> id), do: id
  defp synthetic_id(_), do: nil
  defp org_id("ref.organization." <> id), do: id
  defp org_id(_), do: nil
  defp user_id("ref.user." <> id), do: id
  defp user_id(_), do: nil
  defp group_id("ref.group." <> id), do: id
  defp group_id(_), do: nil
  defp message_id("ref.message." <> id), do: id
  defp message_id(_), do: nil
  defp feature_id("ref.feature." <> id), do: id
  defp feature_id(_), do: nil


  @impl true
  def handle_info({SyntheticManagerWeb.SyntheticLive.FormComponent, {:modified, cs}},  socket) do
    synthetics = socket.assigns.synthetics
                 |> put_in([Access.key(socket.assigns.synthetic_index)], cs)
    synthetic = synthetics[socket.assigns.synthetic_index]
    js = hide_modal("synthetic-upload-modal")

    {:noreply,
      socket
      |> assign(:synthetics, synthetics)
      |> assign(:synthetic, synthetic)
      |> assign(:live_action, :upload)
      |> push_event("js_push", %{js: js.ops})
    }
  end

  def handle_event("search", params = %{ "select-organization" => filter}, socket) do
    search = SyntheticManager.Organizations.filter_organizations(filter)
             |> Enum.map(& %{value: &1.id, key: &1})
    {:noreply,
      socket
      |> assign(:organization_filter_term, filter)
      |> assign(:organization_filter, search)
    }
  end

  def handle_event("search", params = %{ "select-group" => filter}, socket) do
    search = SyntheticManager.Groups.filter_groups(filter)
             |> Enum.map(& %{value: &1.id, key: &1})
    {:noreply,
      socket
      |> assign(:group_filter_term, filter)
      |> assign(:group_filter, search)
    }
  end
  def handle_event("search", params = %{ "select-user" => filter}, socket) do
    search = SyntheticManager.Users.filter_users(filter)
             |> Enum.map(& %{value: &1.id, key: &1})
    {:noreply,
      socket
      |> assign(:user_filter_term, filter)
      |> assign(:user_filter, search)
    }
  end


  def handle_event("validate", %{"edit-user" => user}, socket) do
    user = SyntheticManager.Users.get_user!(UUID.string_to_binary!(user))
    socket = socket
             |> assign(:default_user,  user)
    {:noreply,socket}
  end
  def handle_event("validate", %{"edit-group" => user}, socket) do
    user = SyntheticManager.Groups.get_group!(UUID.string_to_binary!(user))
    socket = socket
             |> assign(:default_group,  user)
    {:noreply,socket}
  end
  def handle_event("validate", %{"edit-organization" => user}, socket) do
    user = SyntheticManager.Organizations.get_organization!(UUID.string_to_binary!(user))
    socket = socket
             |> assign(:default_organization,  user)
    {:noreply,socket}
  end
  def handle_event("validate", _, socket) do
    {:noreply,socket}
  end
  def handle_event("save-all", _, socket) do
    synthetics = Enum.map(socket.assigns.synthetics,
                   fn ({key, synthetic}) ->
                     with {:ok, synthetic} <- synthetic |> SyntheticManager.Repo.insert() do
                       {key, synthetic}
                     end
                   end)
                 |> Enum.reject(&is_nil/1)
                 |> Map.new()
    {:noreply,
      socket
      |> assign(:synthetics, synthetics)
    }
  end
  def handle_event("edit-synthetic-" <> id, form, socket) do
    id = String.to_integer(id)
    synthetic = socket.assigns.synthetics[id]

    js = show_modal("synthetic-upload-modal")

    {:noreply,
      socket
      |> assign(:synthetic_index, id)
      |> assign(:synthetic, synthetic)
      |> assign(:live_action, :modify)
      |> push_event("js_push", %{js: js.ops})
    }
  end
  def handle_event("synthetics:upload", form, socket) do
    case YamlElixir.read_all_from_string(form["upload"]) do
      {:ok, [json]} when is_list(json) ->
        entries = json |> Enum.map(
                            fn
                              x = %{"messages" => messages} ->

                                features = (x["features"] || [])
                                           |> Enum.map(&feature_id/1)
                                           |> Enum.reject(&is_nil/1)
                                messages = Enum.with_index(messages,
                                  fn
                                    m = %{"role" => role, "content"  => content}, sequence ->
                                    role = role(role)
                                    status = status(m["status"])
                                    note = m["note"] || ""
                                    id = message_id(m["id"]) || UUID.uuid4()
                                    features = (x["features"] || [])
                                               |> Enum.map(&feature_id/1)
                                               |> Enum.reject(&is_nil/1)
                                    inserted_at = extract_time(x["inserted_at"])
                                    updated_at = extract_time(x["updated_at"])

                                    %Message{
                                      id: id,
                                      features: features,
                                      content: content,
                                      sequence: sequence,
                                      role: role,
                                      status: status,
                                      note: note,
                                      inserted_at: inserted_at,
                                      updated_at: updated_at,
                                    }
                                    _,_ -> nil
                                  end
                                ) |> Enum.reject(&is_nil/1)
                                %Synthetic{
                                  id: synthetic_id(x["id"]) || nil,
                                  status: status(x["status"]),
                                  name: x["name"],
                                  description: x["description"] || x["notes"],
                                  hidden_prompt: x["hidden_prompt"],
                                  organization_id: org_id(x["organization_id"]) || socket.assigns.default_organization && socket.assigns.default_organization.id,
                                  user_id: user_id(x["user_id"]) || socket.assigns.default_user && socket.assigns.default_user.id,
                                  group_id: group_id(x["group_id"]) || socket.assigns.default_group && socket.assigns.default_group.id,
                                  features: features,
                                  messages: messages,
                                  inserted_at: extract_time(x["inserted_at"]),
                                  updated_at: extract_time(x["updated_at"]),
                                }
                              _ -> nil
                            end
                          )
                  |> Enum.reject(&is_nil/1)
                  |> Enum.with_index(fn(v,i) -> {i,v} end)
                  |> Map.new()

         {
           :noreply,
           socket
           |> assign(:synthetics, entries)
           |> assign(:synthetic, nil)
         }
      _ ->
        # Error
        {:noreply, socket}
    end
  end

end
