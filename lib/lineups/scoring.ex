defmodule Lineups.Scoring do
  @num_players_on_field 7
  @players %{
      Breccan: [0, 4, 4, 5, 4, 4, 2],
      Cameron: [5, 2, 2, 1, 2, 3, 3],
      Evan: [3, 4, 4, 2, 2, 3, 3],
      Harry: [3, 4, 4, 2, 2, 3, 3],
      Isaiah: [0, 3, 3, 2, 4, 3, 3],
      Jack: [5, 5, 5, 3, 4, 4, 4],
      Linsana: [0, 5, 5, 5, 5, 5, 5],
      Lusaine: [0, 5, 5, 5, 5, 5, 5],
      Paco: [0, 3, 3, 2, 3, 4, 2],
      Richard: [0, 2, 2, 1, 2, 1, 1],
      Ryan: [0, 3, 3, 1, 3, 2, 2],
      SamK: [0, 2, 2, 1, 3, 2, 2],
      SamS: [0, 4, 4, 5, 4, 4, 2],
    }

  @spec score(list(list(atom()))) :: any
  def score([]), do: 0
  def score(lineups) do
    if any_invalid_lineups?(lineups) do
      0
    else
      lineups
      |> Enum.reduce(0, fn lineup, acc -> acc + score_lineup(lineup) + score_defense(lineup) end)
      |> average_score(lineups)
    end
  end

  defp score_lineup(lineup) do
    # a Lineup is just an list of players, their position inferred by index
    lineup
    |> Stream.with_index(0)
    |> Enum.map(fn { player, index} -> Enum.at(@players[player],index) end)
    |> Enum.reduce(0, fn score, acc -> acc + score end )
    |> Integer.pow(2)
  end

  defp score_defense(lineup) do
    [_, def1, def2 | _tail] = lineup
    Integer.pow(Enum.at(@players[def1], 1) + Enum.at(@players[def2], 2), 2)
  end

  defp average_score(total_score, lineups), do: total_score / length(lineups)

  defp any_invalid_lineups?(lineups) do
    lineups
    |> Enum.any?(fn lineup -> any_duplicate_players_or_incomplete_lineups?(lineup) or any_missing_players?(lineup) end)
  end

  defp any_missing_players?(lineup) do
    if Enum.any?(lineup, fn player -> !Map.has_key?(@players, player) end) do
        IO.inspect(lineup, label: "Missing players")
        true
    else
      false
    end
  end

  defp any_duplicate_players_or_incomplete_lineups?(lineup) do
    if MapSet.size(MapSet.new(lineup)) != @num_players_on_field do
      IO.inspect(lineup, label: "duplicate or incomplete lineup")
      true
    else
      false
    end
  end
end
