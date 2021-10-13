defmodule Lineups.Search do
  # if you are wiped out, tiredness = 100%, this is what it what it would subtract from your other ratings.
  @tiredness_skill_weights Nx.tensor(
                      [
                        0,
                        0.5,
                        0.5,
                        5,
                        4.5,
                        1.5
                      ]
                    )

  # Used to calculate how tired a player is based on what they've been playing so far.
  # So if Breccan was 60% tired from playing stopper, he'd only be 20% tired after a break.
  @position_exhaustion Nx.tensor([
                         # Most recent position played --> least recent.
                         # goalie
                         [0, 0, 0, 0, 0, 0, 0, 0],
                         # def1
                         [0, 0, 0, 0, 0, 0, 0, 0],
                         # def2
                         [0, 0, 0, 0, 0, 0, 0, 0],
                         # stopper
                         [0.6, 0.20, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
                         # def_mid
                         [0.6, 0.20, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
                         # off_mid
                         [0.6, 0.20, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1],
                         # fwd
                         [0.3, 0.15, 0.05, 0.04, 0.03, 0.02, 0.01, 0.01],
                         # sub
                         [0, 0, 0, 0, 0, 0, 0, 0],
                         # sub
                         [0, 0, 0, 0, 0, 0, 0, 0],
                         # sub
                         [0, 0, 0, 0, 0, 0, 0, 0],
                         # sub
                         [0, 0, 0, 0, 0, 0, 0, 0],
                         # sub
                         [0, 0, 0, 0, 0, 0, 0, 0],
                         # sub
                         [0, 0, 0, 0, 0, 0, 0, 0]
                       ])

  @position_skill_weights Nx.tensor(
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
                            names: [:position, :skill_weights]
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

  def score(lineups, player_skills), do: score(lineups, player_skills, @position_skill_weights)

  def score_player_position(player_skills, position_skill_weights, tiredness_skill_weights, energy_level) do
    energy_depletion_percentage = 1.0 - energy_level
    # Formula:
    # ([Player Skills] - ([Impact of Tiredness On Each Skill] * Tiredness)) * [Position Skill Weights]
    player_position_score = player_skills
    |> Nx.subtract(
      tiredness_skill_weights
      |> Nx.multiply(energy_depletion_percentage)
      |> Nx.multiply(player_skills)
    )
    |> Nx.multiply(position_skill_weights)
    |> Nx.sum(axes: [0])

    max_position_score =
      position_skill_weights
      |> Nx.multiply(@max_skill)
      |> Nx.sum()
      |> Nx.to_scalar()

    if max_position_score == 0.0, do: 0.0, else: Nx.divide(player_position_score, max_position_score)
  end

  defp get_position_index(position) do
    {num_positions} = Nx.shape(position)
    position
    |> Nx.multiply(Nx.iota({num_positions}))
    |> Nx.sum()
    |> Nx.to_scalar()
  end

  def calculate_energy_level([]), do: 1.0
  def calculate_energy_level(positions), do: calculate_energy_level(positions, @position_exhaustion)

  def calculate_energy_level([], _), do: 1.0
  def calculate_energy_level(positions, position_exhaustion) do
    positions
    |> Enum.reverse
    |> Enum.with_index
    |> Enum.reduce(1, fn({position, periods_ago}, acc) ->
      # IO.inspect({
      #   position,
      #   periods_ago,
      #   Nx.to_scalar(position_exhaustion[position][periods_ago])
      # }, label: "Position, Periods Ago, Energy Loss")
      acc - Nx.to_scalar(position_exhaustion[position][periods_ago])
    end)
    |> Float.round(2)
  end

  defp get_previous_player_positions(_lineups, _player, 0), do: []
  defp get_previous_player_positions(lineups, player, current_period) do
    (0..current_period-1)
    |> Enum.map(fn period ->
      # IO.inspect(lineups[period][player], label: "Last Position")
      lineups[period][player] |> get_position_index()
    end)
  end

  def score(lineups, player_skills, position_skill_weights), do: score(lineups, player_skills, position_skill_weights, @position_exhaustion)

  def score(lineups, player_skills, position_skill_weights, position_exhaustion) do
    {num_periods, num_players, _} = Nx.shape(lineups)

    0..(num_periods-1)
    |> Enum.reduce(0.0, fn period, score ->
      player_score = 0..(num_players - 1)
      |> Enum.to_list()
      |> Enum.map(fn player ->
        position = lineups[period][player]
        position_index = get_position_index(position)
        energy_level = get_previous_player_positions(lineups, player, period) |> calculate_energy_level(position_exhaustion)
        # IO.inspect({period, player, energy_level}, label: "Period, Player, Energy Level")
        score_player_position(player_skills[player], position_skill_weights[position_index], @tiredness_skill_weights, energy_level)
      end)
      |> Nx.stack()
      |> Nx.sum()
      |> Nx.to_scalar()

      score + player_score
    end)
    |> Float.round(3)
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
