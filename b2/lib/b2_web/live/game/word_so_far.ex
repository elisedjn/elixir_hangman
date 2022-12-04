defmodule B2Web.Live.Game.WordSoFar do
  use B2Web, :live_component

  @states %{
    initializing: "Type or click on your first guess",
    good_guess: "Good guess!",
    bad_guess: "That's not in the word",
    won: "You won!",
    lost: "Sorry, you lost. The word was...",
    already_used: "You already picked that letter"
  }

  def mount(socket) do
    {:ok, socket}
  end

  defp state_name(state) do
    @states[state] || "Unknown state"
  end

  def render(assigns) do
    ~H"""
      <div class="word-so-far">
        <div class="game-state"><%= state_name(@tally.game_state) %></div>
        <div class="letters">
          <%= for ch <- @tally.letters do %>
            <% cls = if ch != "_", do: "one-letter correct", else: "one-letter" %>
              <div class={cls}>
                <%= ch %>
              </div>
          <% end %>
        </div>
        <% show = if [:won, :lost] |> Enum.member?(@tally.game_state), do: "play-again", else: "play-again hide" %>
          <button class={show} phx-click="new_game">Play again</button>
      </div>
    """
  end
end
