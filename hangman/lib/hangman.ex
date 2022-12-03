defmodule Hangman do
  use GenServer

  @type game :: pid()

  @type internal_state :: %__MODULE__{
          turns_left: integer,
          game_state: Type.state(),
          letters: list(String.t()),
          used: MapSet.t(String.t())
        }

  defstruct(
    turns_left: 7,
    game_state: :initializing,
    letters: [],
    used: MapSet.new()
  )

  @type state :: :initializing | :won | :lost | :good_guess | :bad_guess | :already_used

  @type tally :: %{
          turns_left: integer,
          game_state: state,
          letters: list(String.t()),
          used: list(String.t())
        }

  ### EXTERNAL API ###
  @spec new_game() :: game
  def new_game() do
    {:ok, pid} = start_link(nil)
    pid
  end

  @spec make_move(game, String.t()) :: {game, Type.tally()}
  def make_move(game, guess) do
    GenServer.call(game, {:make_move, guess})
  end

  @spec tally(game) :: tally()
  def tally(game) do
    GenServer.call(game, {:tally})
  end

  ### GENSERVER INITIALIZATION ###
  # Client process
  def start_link(word) do
    GenServer.start_link(__MODULE__, word)
  end

  # Server process
  def init(_) do
    {:ok, do_new_game()}
  end

  ### GENSERVER CALLBACKS ###
  def handle_call({:make_move, guess}, _from, game) do
    {updated_game, tally} = do_make_move(game, guess)
    {:reply, tally, updated_game}
  end

  def handle_call({:tally}, _from, game) do
    {:reply, do_tally(game), game}
  end

  ### GAME LOGIC ###
  ################ NEW GAME ################
  @spec do_new_game :: internal_state()
  def do_new_game do
    do_new_game(Dictionary.random_word())
  end

  @spec do_new_game(String.t()) :: internal_state()
  def do_new_game(word) do
    %__MODULE__{
      letters: word |> String.codepoints()
    }
  end

  ################ MAKE MOVE ################
  @spec do_make_move(internal_state(), String.t()) :: {internal_state(), tally()}
  def do_make_move(game = %{game_state: state}, _guess) when state in [:won, :lost] do
    game
    |> return_with_tally()
  end

  def do_make_move(game, guess) do
    accept_guess(game, guess, MapSet.member?(game.used, guess))
    |> return_with_tally()
  end

  ################ ACCEPT GUESS ################
  @spec accept_guess(internal_state(), String.t(), boolean) :: internal_state()
  defp accept_guess(game, _guess, _already_used = true) do
    %{game | game_state: :already_used}
  end

  defp accept_guess(game, guess, _already_used = false) do
    %{game | used: MapSet.put(game.used, guess)}
    |> score_guess(Enum.member?(game.letters, guess))
  end

  ################ SCORE GUESS ################
  @spec score_guess(internal_state(), boolean) :: internal_state()
  defp score_guess(game, _good_guess = true) do
    new_state = maybe_won(MapSet.subset?(MapSet.new(game.letters), game.used))
    %{game | game_state: new_state}
  end

  defp score_guess(game = %{turns_left: 1}, _bad_guess) do
    %{game | game_state: :lost, turns_left: 0}
  end

  defp score_guess(game, _bad_guess) do
    %{game | game_state: :bad_guess, turns_left: game.turns_left - 1}
  end

  ################ TALLY ################

  @spec do_tally(internal_state()) :: tally()
  def do_tally(game) do
    %{
      turns_left: game.turns_left,
      game_state: game.game_state,
      letters: reveal_guessed_letters(game),
      used: game.used |> MapSet.to_list() |> Enum.sort()
    }
  end

  @spec return_with_tally(internal_state()) :: {internal_state(), tally()}
  defp return_with_tally(game) do
    {game, tally(game)}
  end

  ################ HELPERS ################

  @spec reveal_guessed_letters(internal_state()) :: MapSet.t(String.t())
  defp reveal_guessed_letters(game = %{game_state: :lost}) do
    game.letters
  end

  defp reveal_guessed_letters(game) do
    game.letters
    |> Enum.map(fn letter -> MapSet.member?(game.used, letter) |> maybe_reveal(letter) end)
  end

  @spec maybe_won(boolean) :: Type.state()
  defp maybe_won(true), do: :won
  defp maybe_won(_), do: :good_guess

  @spec maybe_reveal(boolean, String.t()) :: String.t()
  defp maybe_reveal(_is_in_word = true, letter), do: letter
  defp maybe_reveal(_is_not_in_word, _letter), do: "_"
end
