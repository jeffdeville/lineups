defmodule Lineups.ScoringTest do
  use ExUnit.Case, async: true
  alias Lineups.Scoring

  describe "score_player_position" do
    test "test scoring one player precisely" do
      player_skill = Nx.tensor([0, 5, 4, 5, 4, 5])
      position_skill_weights = Nx.tensor([0, 1, 0.3, 1, 1, 1])
      tiredness_skill_weights = Nx.tensor([0, 0.5, 0.5, 1, 0.95, 0.3])

      result =
        Scoring.score_player_position(
          player_skill,
          position_skill_weights,
          tiredness_skill_weights,
          1
        )
        |> Nx.to_scalar()
        |> Float.round(3)

      assert result == 0.94

      result =
        Scoring.score_player_position(
          player_skill,
          position_skill_weights,
          tiredness_skill_weights,
          0.8
        )
        |> Nx.to_scalar()
        |> Float.round(3)

      assert result == 0.815
    end
  end

  describe "calculate_energy_level" do
    test "calculates energy level at beginning of game to be 1" do
      assert Scoring.calculate_energy_level([]) == 1
    end

    test "calculates energy level in middle of game" do
      goalie = 0
      def1 = 1
      def2 = 2
      stopper = 3
      def_mid = 4
      off_mid = 5
      fwd = 6
      bench = 7

      assert Scoring.calculate_energy_level([bench]) == 1
      assert Scoring.calculate_energy_level([bench, bench]) == 1
      assert Scoring.calculate_energy_level([goalie, goalie]) == 1
      assert Scoring.calculate_energy_level([stopper]) < 1

      assert Scoring.calculate_energy_level([stopper, bench]) >
               Scoring.calculate_energy_level([bench, stopper])

      assert Scoring.calculate_energy_level([stopper, stopper]) <
               Scoring.calculate_energy_level([stopper])

      assert Scoring.calculate_energy_level([stopper, fwd]) == 0.5

      assert Scoring.calculate_energy_level([fwd, fwd, fwd, fwd, fwd]) <
               Scoring.calculate_energy_level([fwd, fwd, fwd, fwd])
    end
  end

  describe "score" do
    test "test scoring one player precisely" do
      player_skill = Nx.tensor([[0, 5, 4, 5, 4, 5]])
      position_skill_weights = Nx.tensor([[0, 1, 0.3, 1, 1, 1]])
      tiredness_skill_weights = Nx.tensor([0, 0.5, 0.5, 5, 4.5, 1.5])

      lineup =
        Nx.tensor(
          # lineup
          [
            # players
            [
              # positions
              [
                1
              ]
            ]
          ]
        )

      result = Scoring.score(lineup, player_skill, position_skill_weights)
      assert result == 0.94
    end

    test "test scoring multiple players precisely" do
      skills =
        Nx.tensor([
          [0, 5, 4, 5, 4, 5],
          [5, 3, 3, 3, 3, 3]
        ])

      weightings =
        Nx.tensor([
          [1, 0, 0, 0, 0, 0],
          [0, 1, 0.3, 1, 1, 1]
        ])

      lineup =
        Nx.tensor(
          # lineup
          [
            # players
            [
              # positions
              # Breccan is stopper
              [0, 1],
              # Cameron is goalie
              [1, 0]
            ]
          ]
        )

      result = Scoring.score(lineup, skills, weightings)
      assert result == 1.94
    end

    test "test scoring multiple players and lineups" do
      skills =
        Nx.tensor([
          [0, 5, 4, 5, 4, 5],
          [5, 3, 3, 3, 3, 3]
        ])

      weightings =
        Nx.tensor([
          [1, 0, 0, 0, 0, 0],
          [0, 1, 0.3, 1, 1, 1]
        ])

      position_exhaustion =
        Nx.tensor([
          [0, 0, 0, 0, 0, 0, 0, 0],
          [0.6, 0.20, 0.1, 0.1, 0.1, 0.1, 0.1, 0.1]
        ])

      lineup =
        Nx.tensor(
          # lineup
          [
            # players
            [
              # positions
              # Breccan is stopper
              [0, 1],
              # Cameron is goalie
              [1, 0]
            ],
            [
              # positions
              # Breccan is goalie
              [0, 1],
              # Cameron is stopper
              [1, 0]
            ]
          ]
        )

      result = Scoring.score(lineup, skills, weightings, position_exhaustion)
      assert result < 3.879
    end
  end
end
