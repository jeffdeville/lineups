defmodule Lineups.Scoring do
  @num_players_on_field 7

  # positions
  @goalie 0
  @def1 1
  @def2 2
  @stopper 3
  @def_mid 4
  @off_mid 5
  @fwd 6

  # skill indices
  @goalie_skill 0
  @def 1
  @off 2
  @endurance 3
  @speed 4
  @awareness 5

  @player_skills %{
    Breccan: [0, 5, 4, 5, 4, 5],
    Cameron: [5, 3, 3, 3, 3, 3],
    Evan: [4, 4, 4, 2, 2, 4],
    Harry: [3, 4, 3, 4, 3, 2],
    Isaiah: [0, 4, 3, 4, 4, 3],
    Jack: [4, 5, 4, 3, 3, 4],
    Linsana: [0, 5, 5, 5, 5, 5],
    Lusaine: [0, 5, 5, 5, 5, 5],
    Paco: [0, 3, 3, 5, 3, 3],
    Richard: [0, 2, 1, 2, 1, 1],
    Ryan: [0, 2, 2, 2, 1, 3],
    SamK: [0, 3, 4, 4, 4, 3],
    SamS: [0, 4, 4, 4, 5, 3],
  }

  @max_defense 5
  @max_offense 5
  @max_awareness 5
  @max_speed 5
  @max_desire 1
  @max_freshness 5


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
    |> Enum.map(fn { player, index} -> get_player_position_score(player, index) end)
    |> Enum.reduce(0, fn score, acc -> acc + score end )
    |> :math.pow(2)
  end

  defp score_defense(lineup) do
    [_, def1, def2 | _tail] = lineup
    :math.pow(get_player_position_score(def1, 1) + get_player_position_score(def2, 2), 2)
  end

  defp average_score(total_score, lineups), do: total_score / length(lineups) |> Float.round(3)

  defp any_invalid_lineups?(lineups) do
    lineups
    |> Enum.any?(fn lineup -> any_duplicate_players_or_incomplete_lineups?(lineup) or any_missing_players?(lineup) end)
  end

  defp any_missing_players?(lineup) do
    if Enum.any?(lineup, fn player -> !Map.has_key?(@player_skills, player) end) do
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

  def get_player_position_score(player, position), do: get_player_position_score(player, position, [])

  def get_player_position_score(player, @goalie, prev_positions) do
    num_times_in_goal_so_far = prev_positions
    |> Enum.filter(&(&1 == @goalie))
    |> Kernel.length()
    if num_times_in_goal_so_far >= 4, do: 0, else: goalie(player)
  end

  def get_player_position_score(player, position, prev_positions) when position == @def1 or position == @def2 do
    (defense(player) + desire(player, @def, prev_positions)) / (@max_defense + @max_desire) |> Float.round(3)
  end

  def get_player_position_score(player, @stopper, prev_positions) do
    (
      defense(player) +
      (offense(player) * 0.3) +
      awareness(player) +
      speed(player) +
      desire(player, @stopper, prev_positions) +
      freshness(player, @stopper, prev_positions)
    ) / (
      @max_defense + @max_offense * 0.3 + @max_awareness + @max_speed + @max_desire + @max_freshness
    ) |> Float.round(3)
  end

  def get_player_position_score(player, @def_mid, prev_positions) do
    (
      defense(player) +
      offense(player) * 0.6 +
      awareness(player) * 0.4 +
      speed(player) * 0.7 +
      desire(player, @def_mid, prev_positions) +
      freshness(player, @def_mid, prev_positions)
    ) / (
      @max_defense + @max_offense * 0.6 + @max_awareness * 0.4 + @max_speed * 0.7 + @max_desire + @max_freshness
    ) |> Float.round(3)
  end

  def get_player_position_score(player, @off_mid, prev_positions) do
    (
      defense(player) * 0.4 +
      offense(player) +
      awareness(player) * 0.9 +
      speed(player) +
      desire(player, @off_mid, prev_positions) +
      freshness(player, @def_mid, prev_positions)
    ) / (
      @max_defense * 0.4 + @max_offense + @max_awareness * 0.9 + @max_speed + @max_desire + @max_freshness
    ) |> Float.round(3)
  end

  def get_player_position_score(player, @fwd, prev_positions) do
    (
      offense(player) + awareness(player), endurance(player) * 0.5,  + speed(player) + desire(player, @fwd, prev_positions)
    ) / (
      @max_offense + @max_awareness + @max_desire
    ) |> Float.round(3)
  end

  defp desire(:Paco, position, prev_positions) when position == @off_mid or position == @fwd do
    times_played_offense = prev_positions
    |> Enum.filter(&(&1 == @off_mid or &1 == @fwd))
    |> Kernel.length()

    if times_played_offense > 2, do: 2, else: 1
  end
  defp desire(:Evan, position, _prev_positions) when position in [@def1, @def2], do: 1
  defp desire(_player, _position, _prev_positions), do: 0

  def freshness(player, _position, _prev_positions) do
    endurance(player)
  end

  defp goalie(player), do: Enum.at(@player_skills[player], @goalie_skill)
  defp defense(player), do: Enum.at(@player_skills[player], @def)
  defp offense(player), do: Enum.at(@player_skills[player], @off)
  defp awareness(player), do: Enum.at(@player_skills[player], @awareness)
  defp endurance(player), do: Enum.at(@player_skills[player], @endurance)
  defp speed(player), do: Enum.at(@player_skills[player], @speed)
end
