defmodule Lineups.Scoring do
  alias Lineups.Util

  # if you are wiped out, tiredness = 100%, this is what it what it would subtract from your other ratings.
  @tiredness_skill_weights Nx.tensor([
                             0,
                             0.5,
                             0.5,
                             5,
                             4.5,
                             1.5
                           ])

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

  def score_player_position(
        player_skills,
        position_skill_weights,
        tiredness_skill_weights,
        energy_level
      ) do
    energy_depletion_percentage = 1.0 - energy_level
    # Formula:
    # ([Player Skills] - ([Impact of Tiredness On Each Skill] * Tiredness)) * [Position Skill Weights]
    player_position_score =
      player_skills
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

    if max_position_score == 0.0,
      do: 0.0,
      else: Nx.divide(player_position_score, max_position_score)
  end

  def calculate_energy_level([]), do: 1.0

  def calculate_energy_level(positions),
    do: calculate_energy_level(positions, @position_exhaustion)

  def calculate_energy_level([], _), do: 1.0

  def calculate_energy_level(positions, position_exhaustion) do
    positions
    |> Enum.reverse()
    |> Enum.with_index()
    |> Enum.reduce(1, fn {position, periods_ago}, acc ->
      # IO.inspect({
      #   position,
      #   periods_ago,
      #   Nx.to_scalar(position_exhaustion[position][periods_ago])
      # }, label: "Position, Periods Ago, Energy Loss")
      acc - Nx.to_scalar(position_exhaustion[position][periods_ago])
    end)
    |> Float.round(2)
  end

  def calculate_playing_time_penalty(lineups) do
    {num_periods, num_players, _} = Nx.shape(lineups)

    # get the positions for each player in order over the entire lineup
    num_violations =
      0..(num_players - 1)
      |> Enum.map(fn player ->
        Util.get_previous_player_positions(lineups, player, num_periods)
      end)
      # iterate in pairs, looking for where 2 positions in a row are subs,
      |> Enum.map(fn positions ->
        positions
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.reduce(0, fn [p1, p2], acc ->
          if p1 > 6 and p2 > 6, do: acc + 1, else: acc
        end)
      end)
      |> Enum.sum()

    num_violations * 0.5
  end

  def score(lineups, player_skills), do: score(lineups, player_skills, @position_skill_weights)

  def score(lineups, player_skills, position_skill_weights),
    do: score(lineups, player_skills, position_skill_weights, @position_exhaustion)

  def score(lineups, player_skills, position_skill_weights, position_exhaustion) do
    {num_periods, num_players, _} = Nx.shape(lineups)

    0..(num_periods - 1)
    |> Enum.reduce(0.0, fn period, score ->
      player_score =
        0..(num_players - 1)
        |> Enum.to_list()
        |> Enum.map(fn player ->
          position = lineups[period][player]
          position_index = Util.get_position_index(position)
          previous_positions = Util.get_previous_player_positions(lineups, player, period)
          energy_level = previous_positions |> calculate_energy_level(position_exhaustion)

          score_player_position(
            player_skills[player],
            position_skill_weights[position_index],
            @tiredness_skill_weights,
            energy_level
          )

          # IO.inspect({period, player, energy_level}, label: "Period, Player, Energy Level")
          # was_previously_benched_penalty = if position_index > 6, do: -0.3, else: 0.0
          # Nx.add(player_rating, was_previously_benched_penalty)
        end)
        |> Nx.stack()
        |> Nx.sum()
        |> Nx.to_scalar()

      score + player_score
    end)
    |> Float.round(3)
    |> Kernel.-(calculate_playing_time_penalty(lineups))
  end
end
