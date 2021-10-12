defmodule Lineups.Search do
  # goalie
  # defense
  # offense
  # speed
  # endurance
  # awareness
  @position_skills Nx.tensor(
                     [
                       # goalie
                       [1, 0, 0, 0, 0, 0],
                       # def1
                       [0, 1, 0, 0, 0, 0],
                       # def2
                       [0, 1, 0, 0, 0, 0],
                       # stopper
                       [0, 1, 0.3, 1, 1, 1],
                       # def_mid
                       [0, 1, 0.6, 1, 0.7, 0.4],
                       # off_mid
                       [0, 0.4, 1, 1, 1, 0.9],
                       # fwd
                       [0, 0, 1, 0.5, 1, 1],
                       # sub1
                       [0, 0, 0, 0, 0, 0],
                       # sub2
                       [0, 0, 0, 0, 0, 0],
                       # sub3
                       [0, 0, 0, 0, 0, 0],
                       # sub4
                       [0, 0, 0, 0, 0, 0],
                       # sub5
                       [0, 0, 0, 0, 0, 0],
                       # sub6
                       [0, 0, 0, 0, 0, 0]
                     ],
                     names: [:position, :skill_weighting]
                   )
  @max_skill Nx.broadcast(5, {6})
  @players %{
    0 => :Breccan,
    1 => :Cameron,
    2 => :Evan,
    3 => :Harry,
    4 => :Isaiah,
    5 => :Jack,
    6 => :Linsana,
    7 => :Lusaine,
    8 => :Paco,
    9 => :Richard,
    10 => :Ryan,
    11 => :SamK,
    12 => :SamS
  }

  @positions %{
    0 => :goalie,
    1 => :def1,
    2 => :def2,
    3 => :stopper,
    4 => :def_mid,
    5 => :off_mid,
    6 => :fwd
  }

  # TODO: I should send in the list of kids
  # who are playing here, so that I can cut down the number of positions and whatnot that are needed. (Remove positions from the end of the list, and just assume that if the number of real positions is greater than the number of players, that you're in an invalid state anyway)
  # unneeded data is dropped
  # @spec init(map(string, list(number)), any) :: nil
  def init(player_skills, num_periods) do
    {num_players, _} = player_skills |> Nx.shape()

    game_lineup =
      0..(num_periods - 1)
      |> Enum.to_list()
      |> Enum.map(fn _ -> Nx.eye({num_players, num_players}) end)
      |> Nx.stack()

    game_lineup
  end

  def search(
        current_lineups,
        _current_lineups_score,
        _player_skills,
        total_iterations,
        current_iteration
      )
      when total_iterations == current_iteration do
    current_lineups
  end

  def search(
        current_lineups,
        current_lineups_score,
        player_skills,
        total_iterations,
        current_iteration
      ) do
    new_state = evolve(current_lineups)
    new_score = score(new_state, player_skills)
    # IO.inspect({current_lineups_score, new_score}, label: "\tscores")
    {best_lineup, best_score} =
      if new_score > current_lineups_score do
        # IO.inspect({current_lineups_score, new_score}, label: "Current, New Score")
        # print(new_state)
        {new_state, new_score}
      else
        {current_lineups, current_lineups_score}
      end

    search(
      best_lineup,
      best_score,
      player_skills,
      total_iterations,
      current_iteration + 1
    )
  end

  def score(lineups, player_skills) do
    {_num_periods, num_players, _} = Nx.shape(lineups)
    {_, num_skills} = Nx.shape(@position_skills)

    # yields a player / position of scores for each player in each position
    player_ratings =
      0..(num_players - 1)
      |> Enum.to_list()
      |> Enum.map(fn position ->
        player_skills
        |> Nx.transpose()
        |> Nx.multiply(
          Nx.broadcast(@position_skills[position], {num_skills, num_players}, axes: [0])
        )
        |> Nx.sum(axes: [0])
        # |> Nx.divide(@position_skills[position] |> Nx.multiply(@max_skill) |> Nx.sum())
      end)
      |> Nx.stack()
      |> Nx.transpose()

    Nx.multiply(Nx.broadcast(player_ratings, lineups), lineups) |> Nx.sum() |> Nx.to_scalar()
  end

  def evolve(current_lineups) do
    # Get number of periods and kids
    {num_periods, num_positions, _} = Nx.shape(current_lineups)

    # which period am I changing
    period = Enum.random(0..(num_periods - 1))

    # which kids' positions to swap
    all_positions = 0..(num_positions - 1) |> Enum.to_list()
    [pos1, pos2] = all_positions |> Enum.take_random(2)
    new_position_indices = swap(all_positions, pos1, pos2)
    mutate(current_lineups, period, new_position_indices)
  end

  def mutate(current_lineups, period, new_position_indices) do
    {num_periods, _, _} = Nx.shape(current_lineups)

    # reposition players
    new_lineup = Nx.take(current_lineups[period], Nx.tensor(new_position_indices))

    lineup_list =
      0..(num_periods - 1)
      |> Enum.map(fn
        ^period -> new_lineup
        index -> current_lineups[index]
      end)

    Nx.stack(lineup_list)
  end

  def collect_lineups(current_lineups) do
    {num_periods, num_players, _num_positions} = Nx.shape(current_lineups)

    0..(num_periods - 1)
    |> Enum.map(fn period ->
      0..(num_players - 1)
      |> Enum.reduce(%{}, fn player, acc ->
        position_index =
          current_lineups[period][player]
          |> Nx.to_flat_list()
          |> Enum.find_index(&(&1 == 1))

        position = @positions[position_index]
        Map.put(acc, @players[player], position)
      end)
    end)
  end

  def print(current_lineups) do
    IO.inspect(collect_lineups(current_lineups))
  end

  defp swap(a, i1, i2) do
    a = :array.from_list(a)

    v1 = :array.get(i1, a)
    v2 = :array.get(i2, a)

    a = :array.set(i1, v2, a)
    a = :array.set(i2, v1, a)

    :array.to_list(a)
  end
end
