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
          Req.get("https://api.github.com/users/#{profile.display_name}/repos?type=public&per_page=100",
            headers: headers
          )

        repos = Enum.map(res.body, & &1["full_name"])
        {:ok, %{repos: repos}}
      end)

    {:ok, socket}
  end

  def render(assigns) do
    ~H"""
    <div class="min-h-screen bg-gray-50 dark:bg-gray-950 transition-colors duration-200" id="dashboard">
      <div class="mx-auto max-w-3xl px-4 py-8 sm:px-6 lg:px-8">
        <!-- Header Section -->
        <header class="mb-8">
          <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <div class="flex items-center gap-4">
              <div>
                <h1 class="text-2xl font-bold text-gray-900 dark:text-gray-100">
                  <%= @display_name %>
                </h1>
                <p class="text-gray-500 dark:text-gray-400 text-sm mt-0.5">
                  GitHub Stars Dashboard
                </p>
              </div>
            </div>
            <div class="flex items-center gap-3">
              <Layouts.theme_toggle />
              <a href="/logout" class="px-5 py-2.5 rounded-xl bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-200 font-medium hover:bg-gray-200 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-all duration-200 text-sm">
                Logout
              </a>
            </div>
          </div>
        </header>

        <!-- Flash Messages -->
        <div id="flash-messages" class="mb-6">
          <.flash kind={:info} flash={@flash} />
          <.flash kind={:error} flash={@flash} />
        </div>

        <!-- Repository Selection Section -->
        <section class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-800 p-6 space-y-6" id="repo-selection">
          <div class="flex items-center justify-between mb-6">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100 flex items-center gap-2">
              <.icon name="hero-code-bracket" class="size-5" />
              Select Repository
            </h2>
            <%= if @repos.ok? && @repos.result && length(@repos.result) > 0 do %>
              <span class="px-3 py-1 text-xs font-semibold rounded-full bg-blue-100 dark:bg-blue-900/30 text-blue-800 dark:text-blue-200"><%= length(@repos.result) %> repos</span>
            <% end %>
          </div>

          <%= if @repos.ok? do %>
            <.form for={%{}} phx-submit="select_repo" id="repo-form" class="space-y-5">
              <!-- Repository Select -->
              <div>
                <label for="repo" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Repository</label>
                <select name="repo" id="repo" class="w-full px-4 py-3 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 appearance-none bg-no-repeat bg-right pr-10 bg-[url('data:image/svg+xml;utf8,<svg xmlns=%22http://www.w3.org/2000/svg%22 fill=%22none%22 viewBox=%220 0 20 20%22><path stroke=%22%236b7280%22 stroke-linecap=%22round%22 stroke-linejoin=%22round%22 stroke-width=%221.5%22 d=%22M6 8l4 4 4-4%22/>')]" required>
                  <option value="" disabled selected>Choose a repository...</option>
                  <%= for repo <- @repos.result do %>
                    <option value={repo}><%= repo %></option>
                  <% end %>
                </select>
                <p class="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
                  Public repositories from your GitHub account
                </p>
              </div>

              <!-- Stars Limit Input -->
              <div>
                <label for="limit" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">Amount of Stars</label>
                <div class="relative">
                  <input
                    type="number"
                    name="limit"
                    id="limit"
                    min="1"
                    max="1000"
                    value="10"
                    required
                    class="w-full px-4 py-3 rounded-xl border border-gray-200 dark:border-gray-700 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 placeholder:text-gray-400 dark:placeholder:text-gray-500 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent transition-all duration-200 pr-12"
                    placeholder="10"
                  />
                  <span class="absolute right-3 top-1/2 -translate-y-1/2 text-gray-400 text-sm font-medium">
                    stars
                  </span>
                </div>
                <p class="mt-1.5 text-sm text-gray-500 dark:text-gray-400">
                  How many stars you want to owe (1-1000)
                </p>
              </div>

              <!-- Submit Button -->
              <button type="submit" class="w-full px-6 py-3.5 rounded-xl bg-blue-600 text-white font-semibold hover:bg-blue-700 active:bg-blue-800 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2 transition-all duration-200 disabled:opacity-50 disabled:cursor-not-allowed" phx-disable-with="Submitting...">
                Start Starring
              </button>
            </.form>

            <!-- Selected Repo Confirmation -->
            <%= if @selected_repo do %>
              <div class="mt-6 p-4 bg-green-50 dark:bg-green-900/20 border border-green-200 dark:border-green-800 rounded-lg animate-slide-in">
                <div class="flex items-center gap-3">
                  <.icon name="hero-check-circle" class="size-5 text-green-600 dark:text-green-400 shrink-0" />
                  <div class="flex-1">
                    <p class="text-green-800 dark:text-green-200 font-medium">Repository Selected</p>
                    <p class="text-green-700 dark:text-green-300 text-sm mt-0.5 font-mono text-base">
                      <%= @selected_repo %>
                    </p>
                  </div>
                  <span class="px-3 py-1 text-xs font-semibold rounded-full bg-green-100 dark:bg-green-900/30 text-green-800 dark:text-green-200">
                    Pending
                  </span>
                </div>
              </div>
            <% end %>

          <% else %>
            <!-- Loading State -->
            <div class="space-y-4">
              <div class="animate-pulse bg-gray-200 dark:bg-gray-700 h-10 w-3/4 rounded-lg" />
              <div class="animate-pulse bg-gray-200 dark:bg-gray-700 h-10 w-1/2 rounded-lg" />
              <div class="animate-pulse bg-gray-200 dark:bg-gray-700 h-12 w-1/4 rounded-lg" />
            </div>
          <% end %>
        </section>

        <!-- Permanent Star Section -->
        <section class="bg-white dark:bg-gray-900 rounded-2xl shadow-sm border border-gray-200 dark:border-gray-800 p-6 space-y-6" id="perm-star">
          <div class="flex items-center justify-between mb-4">
            <h2 class="text-lg font-semibold text-gray-900 dark:text-gray-100 flex items-center gap-2">
              <.icon name="hero-sparkles" class="size-5 text-amber-500" />
              Nuclear Option
            </h2>
          </div>

          <div class="bg-amber-50 dark:bg-amber-900/20 border border-amber-200 dark:border-amber-800 rounded-lg p-5 mb-4">
            <div class="flex items-start gap-3">
              <.icon name="hero-exclamation-triangle" class="size-5 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
              <div class="flex-1">
                <h3 class="text-amber-800 dark:text-amber-200 font-semibold">Permanent Star Debt</h3>
                <p class="text-amber-700 dark:text-amber-300 text-sm mt-1">
                  This will add 99,999,999 stars to your debt. Once submitted, you'll need to star
                  that many repositories to clear it. This action cannot be undone.
                </p>
              </div>
            </div>
          </div>

          <.form for={%{}} phx-submit="perm_star" id="perm-star-form">
            <button
              type="submit"
              class="w-full px-6 py-3.5 rounded-xl bg-red-600 text-white font-semibold hover:bg-red-700 active:bg-red-800 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-all duration-200"
              phx-click="confirm_perm_star"
              phx-disable-with="Are you absolutely sure? Click again to confirm."
            >
              I Understand - Star Everything Forever
            </button>
          </.form>
        </section>

        <!-- Footer Info -->
        <footer class="mt-10 pt-6 border-t border-gray-200 dark:border-gray-700">
          <p class="text-center text-sm text-gray-500 dark:text-gray-400">
            UI made by <a href="github.com/seradedstripes" class="text-blue-600 dark:text-blue-400 hover:underline">SeradedStripes</a>
          </p>
        </footer>
      </div>
    </div>

    <!-- Confirmation Modal for Perm Star -->
    <div
      id="confirm-modal"
      class="fixed inset-0 z-50 hidden items-center justify-center p-4 bg-black/50 backdrop-blur-sm"
      phx-hook="ConfirmModal"
    >
      <div class="bg-white dark:bg-gray-800 rounded-xl shadow-xl max-w-md w-full animate-slide-in">
        <div class="p-6">
          <div class="flex items-center gap-3 mb-4">
            <div class="w-12 h-12 rounded-full bg-red-100 dark:bg-red-900/30 flex items-center justify-center">
              <.icon name="hero-exclamation-triangle" class="size-6 text-red-600 dark:text-red-400" />
            </div>
            <h3 class="text-lg font-semibold text-gray-900 dark:text-gray-100">Confirm Permanent Star Debt</h3>
          </div>
          <p class="text-gray-600 dark:text-gray-300 mb-6">
            This will add <strong class="text-red-600 dark:text-red-400">99,999,999 stars</strong> to your debt.
            You'll need to star that many repositories to clear it. This action is irreversible.
          </p>
          <div class="flex gap-3">
            <button
              type="button"
              class="flex-1 px-5 py-2.5 rounded-xl bg-gray-100 dark:bg-gray-800 text-gray-700 dark:text-gray-200 font-medium hover:bg-gray-200 dark:hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-gray-500 focus:ring-offset-2 transition-all duration-200"
              phx-click="cancel_perm_star"
            >
              Cancel
            </button>
            <button
              type="submit"
              form="perm-star-form"
              class="flex-1 px-6 py-3.5 rounded-xl bg-red-600 text-white font-semibold hover:bg-red-700 active:bg-red-800 focus:outline-none focus:ring-2 focus:ring-red-500 focus:ring-offset-2 transition-all duration-200"
              phx-click="confirm_perm_star"
            >
              Confirm
            </button>
          </div>
        </div>
      </div>
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

  def handle_event("confirm_perm_star", _params, socket) do
    user_id = socket.assigns.user_id

    Mudan.Repo.update_all(
      from(u in Mudan.User, where: u.uid == ^user_id),
      inc: [debt: 99_999_999]
    )

    Mudan.Workers.PayDebt.new(%{"user_id" => user_id}) |> Oban.insert()

    socket =
      socket
      |> put_flash(:info, "You now owe 99,999,999 stars. Good luck!")
      |> push_event("hide_modal", %{})

    {:noreply, socket}
  end

  def handle_event("cancel_perm_star", _params, socket) do
    {:noreply, push_event(socket, "hide_modal", %{})}
  end

  def handle_event("perm_star", _params, socket) do
    {:noreply, push_event(socket, "show_modal", %{})}
  end
end