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
    <div class="w-full max-w-lg mx-auto flex flex-col gap-6 py-8 px-4">
      <.flash kind={:info} flash={@flash} />
      <.flash kind={:error} flash={@flash} />

      <header class="flex items-center justify-between gap-4">
        <div class="flex items-center gap-3">
          <div class="avatar">
            <div class="w-12 rounded-full ring ring-primary ring-offset-base-100 ring-offset-2">
              <img src={@avatar_url} alt="User Avatar" />
            </div>
          </div>
          <div>
            <h1 class="text-xl font-bold leading-tight">{@display_name}</h1>
            <p class="text-sm text-base-content/60">Manage your repositories</p>
          </div>
        </div>

        <div class="flex items-center gap-2">
          <label class="btn btn-ghost btn-circle swap swap-rotate">
            <input type="checkbox" class="theme-controller" value="light" />
            <svg
              class="swap-off h-6 w-6 fill-current"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
            >
              <path d="M5.64,17l-.71.71a1,1,0,0,0,0,1.41,1,1,0,0,0,1.41,0l.71-.71A1,1,0,0,0,5.64,17ZM5,12a1,1,0,0,0-1-1H3a1,1,0,0,0,0,2H4A1,1,0,0,0,5,12Zm7-7a1,1,0,0,0,1-1V3a1,1,0,0,0-2,0V4A1,1,0,0,0,12,5ZM5.64,7.05a1,1,0,0,0,.7.29,1,1,0,0,0,.71-.29,1,1,0,0,0,0-1.41l-.71-.71A1,1,0,0,0,4.93,6.34Zm12,.29a1,1,0,0,0,.7-.29l.71-.71a1,1,0,1,0-1.41-1.41L17,5.64a1,1,0,0,0,0,1.41A1,1,0,0,0,17.66,7.34ZM21,11H20a1,1,0,0,0,0,2h1a1,1,0,0,0,0-2Zm-9,8a1,1,0,0,0-1,1v1a1,1,0,0,0,2,0V20A1,1,0,0,0,12,19ZM18.36,17A1,1,0,0,0,17,18.36l.71.71a1,1,0,0,0,1.41,0,1,1,0,0,0,0-1.41ZM12,6.5A5.5,5.5,0,1,0,17.5,12,5.51,5.51,0,0,0,12,6.5Zm0,9A3.5,3.5,0,1,1,15.5,12,3.5,3.5,0,0,1,12,15.5Z" />
            </svg>
            <svg
              class="swap-on h-6 w-6 fill-current"
              xmlns="http://www.w3.org/2000/svg"
              viewBox="0 0 24 24"
            >
              <path d="M21.64,13a1,1,0,0,0-1.05-.14,8.05,8.05,0,0,1-3.37.73A8.15,8.15,0,0,1,9.08,5.49a8.59,8.59,0,0,1,.25-2A1,1,0,0,0,8,2.36,10.14,10.14,0,1,0,22,14.05,1,1,0,0,0,21.64,13Zm-9.5,6.69A8.14,8.14,0,0,1,7.08,5.22v.27A10.15,10.15,0,0,0,17.22,15.63a9.79,9.79,0,0,0,2.1-.22A8.11,8.11,0,0,1,12.14,19.73Z" />
            </svg>
          </label>

          <a href="/logout" class="btn btn-ghost btn-sm gap-2">
            <svg
              xmlns="http://www.w3.org/2000/svg"
              class="h-4 w-4"
              fill="none"
              viewBox="0 0 24 24"
              stroke="currentColor"
            >
              <path
                stroke-linecap="round"
                stroke-linejoin="round"
                stroke-width="2"
                d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1"
              />
            </svg>
            Logout
          </a>
        </div>
      </header>
      <main class="flex flex-col gap-6">
        <div class="card bg-base-100 shadow-lg border border-base-300">
          <div class="card-body">
            <%= if @repos.ok? do %>
              <.form for={%{}} phx-submit="select_repo" class="flex flex-col gap-4">
                <div class="form-control w-full">
                  <label class="label">
                    <span class="label-text font-semibold">Select Repository</span>
                  </label>
                  <select name="repo" class="select select-bordered w-full font-mono">
                    <%= for repo <- @repos.result do %>
                      <option value={repo}>{repo}</option>
                    <% end %>
                  </select>
                </div>

                <div class="form-control w-full">
                  <label class="label">
                    <span class="label-text font-semibold">Amount of Stars</span>
                    <span class="label-text-alt text-base-content/50">Max 1000</span>
                  </label>
                  <input
                    type="number"
                    name="limit"
                    min="0"
                    max="1000"
                    placeholder="e.g., 100"
                    class="input input-bordered w-full"
                  />
                </div>

                <button type="submit" class="btn btn-primary w-full mt-2">
                  Update Repository
                </button>
              </.form>

              <%= if @selected_repo do %>
                <div class="alert alert-success mt-4 py-3">
                  <svg
                    xmlns="http://www.w3.org/2000/svg"
                    class="stroke-current shrink-0 h-5 w-5"
                    fill="none"
                    viewBox="0 0 24 24"
                  >
                    <path
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z"
                    />
                  </svg>
                  <span>Current selection: <strong class="font-mono">{@selected_repo}</strong></span>
                </div>
              <% end %>
            <% else %>
              <div class="flex flex-col items-center justify-center py-12 gap-4">
                <span class="loading loading-spinner loading-lg text-primary"></span>
                <p class="text-base-content/60 animate-pulse">Loading repositories...</p>
              </div>
            <% end %>
          </div>
        </div>

        <div class="flex flex-col gap-4">
          <div class="divider text-error text-sm font-bold uppercase tracking-wider">
            Danger Zone
          </div>

          <.form for={%{}} phx-submit="perm_star">
            <button type="submit" class="btn btn-error btn-outline w-full gap-2">
              <svg
                xmlns="http://www.w3.org/2000/svg"
                class="h-5 w-5"
                viewBox="0 0 20 20"
                fill="currentColor"
              >
                <path d="M9.049 2.927c.3-.921 1.603-.921 1.902 0l1.07 3.292a1 1 0 00.95.69h3.462c.969 0 1.371 1.24.588 1.81l-2.8 2.034a1 1 0 00-.364 1.118l1.07 3.292c.3.921-.755 1.688-1.539 1.118l-2.8-2.034a1 1 0 00-1.175 0l-2.8 2.034c-.784.57-1.838-.197-1.539-1.118l1.07-3.292a1 1 0 00-.364-1.118L2.98 8.72c-.783-.57-.38-1.81.588-1.81h3.461a1 1 0 00.951-.69l1.07-3.292z" />
              </svg>
              Star all repos forever
            </button>
          </.form>
        </div>
      </main>
    </div>
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
        Mudan.Workers.PayDebt.new(%{"user_id" => user_id}) |> Oban.insert()

        Mudan.Workers.PayNewRepo.new(%{"repo_id" => repo, "submitter_id" => user_id})
        |> Oban.insert()

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

  def handle_event("perm_star", _params, socket) do
    user_id = socket.assigns.user_id

    Mudan.Repo.update_all(
      from(u in Mudan.User, where: u.uid == ^user_id),
      inc: [debt: 99_999_999]
    )

    Mudan.Workers.PayDebt.new(%{"user_id" => user_id}) |> Oban.insert()

    socket =
      socket
      |> put_flash(:info, "You now owe 99,999,999 stars. Good luck!")

    {:noreply, socket}
  end
end
