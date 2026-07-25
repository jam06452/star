defmodule MudanWeb.Dash do
  use MudanWeb, :live_view
  alias Mudan.Star
  alias Mudan.User
  import Ecto.Query

  def mount(_params, session, socket) do
    user_id = session["user_id"]

    profile = Mudan.Utils.get_user_profile(user_id)

    socket =
      socket
      |> assign(:user_id, user_id)
      |> assign(:display_name, profile.display_name)
      |> assign(:avatar_url, profile.avatar_url)
      |> assign(:selected_repo, nil)
      |> assign_async(:repos, fn ->
        headers = [{"Authorization", "Bearer #{profile.github_token}"}]

        {:ok, res} =
          Req.get("https://api.github.com/users/#{profile.display_name}/repos?type=public",
            headers: headers
          )

        repos = Enum.map(res.body, & &1["full_name"])
        {:ok, %{repos: repos}}
      end)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <.flash kind={:info} flash={@flash} />
    <.flash kind={:error} flash={@flash} />

    <label class="swap swap-rotate">
      <input type="checkbox" class="theme-controller" value="light" />
      
    <!-- sun icon -->
      <svg
        class="swap-off h-10 w-10 fill-current"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
      >
        <path d="M5.64,17l-.71.71a1,1,0,0,0,0,1.41,1,1,0,0,0,1.41,0l.71-.71A1,1,0,0,0,5.64,17ZM5,12a1,1,0,0,0-1-1H3a1,1,0,0,0,0,2H4A1,1,0,0,0,5,12Zm7-7a1,1,0,0,0,1-1V3a1,1,0,0,0-2,0V4A1,1,0,0,0,12,5ZM5.64,7.05a1,1,0,0,0,.7.29,1,1,0,0,0,.71-.29,1,1,0,0,0,0-1.41l-.71-.71A1,1,0,0,0,4.93,6.34Zm12,.29a1,1,0,0,0,.7-.29l.71-.71a1,1,0,1,0-1.41-1.41L17,5.64a1,1,0,0,0,0,1.41A1,1,0,0,0,17.66,7.34ZM21,11H20a1,1,0,0,0,0,2h1a1,1,0,0,0,0-2Zm-9,8a1,1,0,0,0-1,1v1a1,1,0,0,0,2,0V20A1,1,0,0,0,12,19ZM18.36,17A1,1,0,0,0,17,18.36l.71.71a1,1,0,0,0,1.41,0,1,1,0,0,0,0-1.41ZM12,6.5A5.5,5.5,0,1,0,17.5,12,5.51,5.51,0,0,0,12,6.5Zm0,9A3.5,3.5,0,1,1,15.5,12,3.5,3.5,0,0,1,12,15.5Z" />
      </svg>
      
    <!-- moon icon -->
      <svg
        class="swap-on h-10 w-10 fill-current"
        xmlns="http://www.w3.org/2000/svg"
        viewBox="0 0 24 24"
      >
        <path d="M21.64,13a1,1,0,0,0-1.05-.14,8.05,8.05,0,0,1-3.37.73A8.15,8.15,0,0,1,9.08,5.49a8.59,8.59,0,0,1,.25-2A1,1,0,0,0,8,2.36,10.14,10.14,0,1,0,22,14.05,1,1,0,0,0,21.64,13Zm-9.5,6.69A8.14,8.14,0,0,1,7.08,5.22v.27A10.15,10.15,0,0,0,17.22,15.63a9.79,9.79,0,0,0,2.1-.22A8.11,8.11,0,0,1,12.14,19.73Z" />
      </svg>
    </label>

    <p>{@display_name}</p>
    <img src={@avatar_url} />

    <%= if @repos.ok? do %>
      <.form for={%{}} phx-submit="select_repo" class="flex flex-col gap-4 max-w-xs">
        <div class="form-control w-full">
          <label class="label">
            <span class="label-text">Select Repository</span>
          </label>
          <select name="repo" class="select select-bordered w-full">
            <%= for repo <- @repos.result do %>
              <option value={repo}>{repo}</option>
            <% end %>
          </select>
        </div>

        <div class="form-control w-full">
          <label class="label">
            <span class="label-text">Amount of Stars</span>
          </label>
          <input
            type="number"
            name="limit"
            min="0"
            max="1000"
            placeholder="0"
            class="input input-bordered w-full"
          />
        </div>

        <button type="submit" class="btn btn-primary w-full">Select</button>
      </.form>

      <%= if @selected_repo do %>
        <p>You picked: <strong>{@selected_repo}</strong></p>
      <% end %>
    <% else %>
      <p>Loading repos...</p>
    <% end %>
    """
  end

  def handle_event("select_repo", %{"repo" => repo, "limit" => limit}, socket) do
    user_id = socket.assigns.user_id
    needed_likes = String.to_integer(limit)

    case Mudan.Repo.transaction(fn ->
           attrs = %{
             user_uid: user_id,
             repo_id: repo,
             needed_likes: needed_likes,
             status: "pending"
           }

           changeset = Star.changeset(%Star{}, attrs)

           case Mudan.Repo.insert(changeset) do
             {:ok, _star} ->
               Mudan.Repo.update_all(
                 from(u in User, where: u.uid == ^user_id),
                 inc: [debt: needed_likes]
               )

               :ok

             {:error, changeset} ->
               Mudan.Repo.rollback(changeset)
           end
         end) do
      {:ok, :ok} ->
        socket =
          socket
          |> assign(:selected_repo, repo)
          |> put_flash(:info, "Submitted! You now owe #{needed_likes} stars.")

        {:noreply, socket}

      {:error, changeset} ->
        error_msg =
          if changeset.errors[:user_uid] do
            "You can only submit one repo at a time!"
          else
            "Failed to submit repo. Please try again."
          end

        socket = put_flash(socket, :error, error_msg)
        {:noreply, socket}
    end
  end
end
