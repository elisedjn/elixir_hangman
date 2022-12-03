defmodule TextClient.Impl.Player do
  @typep game :: Hangman.game()
  @typep tally :: Hangman.tally()
  @typep state :: {game, tally}

  ########## START ##########
  @spec start :: :ok
  def start() do
    game = Hangman.new_game()
    tally = Hangman.tally(game)
    interact({game, tally})
  end

  ########## INTERACT ##########
  @spec interact(state) :: :ok
  def interact({_game, _tally = %{game_state: :won}}) do
    IO.puts("Congratulations. You won!")
  end

  def interact({_game, tally = %{game_state: :lost}}) do
    IO.puts("Sorry, you lost... the word was #{tally.letters |> Enum.join()}")
  end

  def interact({game, tally}) do
    IO.puts(feedback_for(tally))
    IO.puts(current_word(tally))

    Hangman.make_move(game, get_guess())
    |> interact()
  end

  ########## FEEDBACK FOR ##########
  @spec feedback_for(tally) :: String.t()
  def feedback_for(tally = %{game_state: :initializing}) do
    "Welcome I'm thinking of a #{tally.letters |> length} letters word"
  end

  def feedback_for(%{game_state: :good_guess}) do
    "Good guess!"
  end

  def feedback_for(%{game_state: :bad_guess}) do
    "Sorry, that letter isn't in the word"
  end

  def feedback_for(%{game_state: :already_used}) do
    "You already used that letter"
  end

  ########## CURRENT WORD ##########
  @spec current_word(tally) :: list(String.t())
  def current_word(tally) do
    [
      IO.ANSI.format([:green, "Word so far: "]),
      tally.letters |> Enum.join(" "),
      IO.ANSI.format([:green, "    turns left: "]),
      IO.ANSI.format([:cyan, tally.turns_left |> to_string()]),
      IO.ANSI.format([:green, "    used so far: "]),
      IO.ANSI.format([:yellow, tally.used |> Enum.join(",")])
    ]
  end

  ########## GET GUESS ##########
  @spec get_guess() :: String.t()
  def get_guess() do
    IO.gets("Next letter: ")
    |> String.trim()
    |> String.downcase()
  end
end
