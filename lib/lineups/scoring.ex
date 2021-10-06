@type positions :: :goalie | :def | :stopper | :def_mid | :off_mid | :fwd
GOALIE = 0
DEF = 1
STOPPER = 2
DEF_MID = 3
OFF_MID = 4
FWD = 5

players = [
  %{
    name: "Breccan",
    scores: [0, 4, 5, 4, 4, 2]
  },
  %{
    name: "Harry",
    scores: [3, 4, 2, 2, 3, 3]
  },
  %{
    name: "Paco",
    scores: [0, 3, 2, 3, 4, 2]
  },
  %{
    name: "SamK",
    scores: [0, 2, 1, 3, 2, 2]
  },
  %{
    name: "SamS",
    scores: [0, 4, 5, 4, 4, 2]
  },
  %{
    name: "Evan",
    scores: [3, 4, 2, 2, 3, 3]
  },
  %{
    name: "Jack",
    scores: [5, 5, 3, 4, 4, 4]
  },
  %{
    name: "Richard",
    scores: [0, 2, 1, 2, 1, 1]
  },
  %{
    name: "Linsana",
    scores: [0, 5, 5, 5, 5, 5]
  },
  %{
    name: "Lusaine",
    scores: [0, 5, 5, 5, 5, 5]
  },
  %{
    name: "Ryan",
    scores: [0, 3, 1, 3, 2, 2]
  },
  %{
    name: "Isaiah",
    scores: [0, 3, 2, 4, 3, 3]
  },
  %{
    name: "Cameron",
    scores: [5, 2, 1, 2, 3, 3]
  }
]

defmodule Lineups.Player do
  defstruct name: "", rankings: %{}
end

defmodule Lineups.Lineup do
  # defstruct positions: Player[]
end

defmodule(Lineups.Scoring) do
  defstruct name: "John", age: 27

  def score(lineups, players) do
    lineups
    |> Enum.map(&score_lineup(&1, players))
  end

  defp score_lineup(%Lineup{} = lineup, players) do
  end
end
