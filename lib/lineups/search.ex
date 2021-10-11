defmodule Lineups.Search do
# goalie
# defense
# offense
# speed
# endurance
# awareness
# not_here
@position_skills Nx.tensor(
    [
      # goalie
      [1, 0, 0, 0, 0, 0, 0],
      # def1
      [0, 1, 0, 0, 0, 0, 0],
      # def2
      [0, 1, 0, 0, 0, 0, 0],
      # stopper
      [0, 1, 0.3, 1, 1, 1, 0],
      # def_mid
      [0, 1, 0.6, 1, 0.7, 0.4, 0],
      # off_mid
      [0, 0.4, 1, 1, 1, 0.9, 0],
      # fwd
      [0, 0, 1, 0.5, 1, 1, 0],
      # sub1
      [0, 0, 0, 0, 0, 0, 1],
      # sub2
      [0, 0, 0, 0, 0, 0, 1],
      # sub3
      [0, 0, 0, 0, 0, 0, 1],
      # sub4
      [0, 0, 0, 0, 0, 0, 1],
      # sub5
      [0, 0, 0, 0, 0, 0, 1],
      # sub6
      [0, 0, 0, 0, 0, 0, 1]
    ],
    names: [:position, :skill_weighting]
  )

  # Store the model or something here? - I should send in the list of kids
  # who are playing here, so that after that, it's all just figured out and
  # unneeded data is dropped
  # @spec init(map(string, list(number)), any) :: nil
  def init(position_weightings, num_periods) do
    {num_positions, _} = position_weightings |> Nx.shape

    game_lineup =
      0..(num_periods-1)
      |> Enum.to_list()
      |> Enum.map(fn _ -> Nx.eye({num_positions, num_positions}) end)
      |> Nx.stack()

    game_lineup
  end

  def search(current_lineups, _current_lineups_score, _player_skills, _position_weights, total_iterations, current_iteration) when total_iterations == current_iteration do
    current_lineups
  end

  def search(current_lineups, current_lineups_score, player_skills,position_weights, total_iterations, current_iteration) do
    new_state = evolve(current_lineups)
    new_score = score(new_state)
    {best_lineup, best_score} = if new_score > current_lineups_score do
      {new_state, new_score}
    else
      {current_lineups, current_lineups_score}
    end
    search(best_lineup, best_score, player_skills, position_weights, total_iterations, current_iteration + 1)
  end

  def score(_lineups) do
    0.5
  end

  def evolve(current_lineups) do
    # Get number of periods and kids
    {num_periods, num_positions, _} = Nx.shape(current_lineups)

    # which period am I changing
    period = Enum.random(0..num_periods-1)

    # which kids' positions to swap
    all_positions = 0..(num_positions-1) |> Enum.to_list()
    [pos1, pos2] = all_positions |> Enum.take_random(2)
    new_position_indices = swap(all_positions, pos1, pos2)
    mutate(current_lineups, period, new_position_indices)
  end

  def mutate(current_lineups, period, new_position_indices) do\
    {num_periods, _, _} = Nx.shape(current_lineups)

    # reposition players
    new_lineup = Nx.take(current_lineups[period], Nx.tensor(new_position_indices))

    lineup_list = (0..num_periods-1)
      |> Enum.map(fn
        ^period -> new_lineup
        index -> current_lineups[index]
      end)

    Nx.stack(lineup_list)
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
