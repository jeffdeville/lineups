defmodule Lineups.Search do
  alias Lineups.Util
  alias Lineups.Scoring

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

  def search(current_lineups, current_lineups_score, player_skills, total_iterations) do
    search(current_lineups, current_lineups_score, player_skills, total_iterations, 0, 0)
  end

  def search(
        current_lineups,
        _current_lineups_score,
        _player_skills,
        total_iterations,
        current_iteration,
        has_not_moved_in
      )
      when total_iterations == current_iteration or has_not_moved_in == 2000 do
    current_lineups
  end

  def search(
        current_lineups,
        current_lineups_score,
        player_skills,
        total_iterations,
        current_iteration,
        has_not_moved_in
      ) do
    new_state = evolve(current_lineups)
    new_score = Scoring.score(new_state, player_skills)

    if Integer.mod(current_iteration, 500) == 0 do
      IO.inspect([current_lineups_score, current_iteration], label: "Current Score")
    end

    {best_lineup, best_score, has_not_moved_in} =
      if new_score > current_lineups_score do
        # IO.inspect({current_lineups_score, new_score}, label: "Current, New Score")
        # print(new_state)
        {new_state, new_score, 0}
      else
        {current_lineups, current_lineups_score, has_not_moved_in + 1}
      end

    search(
      best_lineup,
      best_score,
      player_skills,
      total_iterations,
      current_iteration + 1,
      has_not_moved_in
    )
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
    {num_periods, num_players, _} = Nx.shape(current_lineups)

    0..(num_players - 1)
    |> Enum.map(fn player ->
      {@players[player],
       Util.get_previous_player_positions(current_lineups, player, num_periods)
       |> Enum.map(&@positions[&1])}
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
