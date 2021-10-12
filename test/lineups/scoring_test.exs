defmodule Lineups.ScoringTest do
  use ExUnit.Case, async: true
  alias Lineups.Scoring

  @goalie 0
  @def1 1
  @def2 2
  @stopper 3
  @def_mid 4
  @off_mid 5
  @fwd 6

  describe "invalid lineups score 0" do
    test "empty lineups score 0" do
      assert Scoring.score([]) == 0
    end

    test "incomplete lineups score 0" do
      assert Scoring.score([[:Breccan, :Harry, :Isaiah]]) == 0
    end

    test "any incomplete lineup scores 0" do
      assert Scoring.score([
               [:Breccan, :Harry, :Isaiah, :Cameron, :Paco, :Ryan, :Evan],
               [:Breccan, :Harry]
             ]) == 0
    end

    test "lineups with duplicate players scores 0" do
      assert Scoring.score([
               [:Breccan, :Breccan, :Breccan, :Breccan, :Breccan, :Breccan, :Breccan]
             ]) == 0
    end

    test "lineups with invalid players scores 0" do
      assert Scoring.score([[:ThisIsNotAPlayer, :Harry, :Isaiah, :Cameron, :Paco, :Ryan, :Evan]]) ==
               0
    end
  end

  describe "valid lineups generate scores" do
    test "a single lineup is scored properly" do
      assert Scoring.score([[:Breccan, :Harry, :Isaiah, :Cameron, :Paco, :Ryan, :Evan]]) == 15.351
    end

    test "lineup scores are averaged, so duplicate lineups should have the same score" do
      lineup1 = [:Breccan, :Harry, :Isaiah, :Cameron, :Paco, :Ryan, :Evan]
      lineup2 = [:Cameron, :Evan, :Richard, :Breccan, :SamK, :Lusaine, :Linsana]
      assert Scoring.score([lineup1, lineup1]) == Scoring.score([lineup1])
      assert Scoring.score([lineup1, lineup2]) == 54.589
    end
  end

  describe "goalie" do
    test "goalies scoring accounts for skill and how long they've been there" do
      assert Scoring.get_player_position_score(:Breccan, @goalie, []) == 0
      assert Scoring.get_player_position_score(:Cameron, @goalie, []) == 5
      assert Scoring.get_player_position_score(:Cameron, @goalie, [@goalie]) == 5
      assert Scoring.get_player_position_score(:Cameron, @goalie, [@goalie, @goalie]) == 5

      assert Scoring.get_player_position_score(:Cameron, @goalie, [
               @goalie,
               @goalie,
               @goalie,
               @goalie
             ]) == 0
    end
  end

  describe "defense" do
    test "def + desire" do
      assert Scoring.get_player_position_score(:Breccan, @def1, []) == 0.833
      assert Scoring.get_player_position_score(:Breccan, @def2, []) == 0.833
      assert Scoring.get_player_position_score(:Evan, @def1, []) == 0.833
      assert Scoring.get_player_position_score(:Evan, @def2, []) == 0.833
    end
  end

  describe "stopper" do
    test "def + off + awareness + speed + endurance - tiredness(prev_positions)" do
      assert Scoring.get_player_position_score(:Breccan, @stopper, []) == 0.898
      assert Scoring.get_player_position_score(:Ryan, @stopper, []) == 0.382
      assert Scoring.get_player_position_score(:Linsana, @stopper, []) == 0.956
    end
  end

  describe "defensive mid" do
    test "calculate" do
      assert Scoring.get_player_position_score(:Breccan, @def_mid, []) == 0.882
      assert Scoring.get_player_position_score(:Ryan, @def_mid, []) == 0.364
      assert Scoring.get_player_position_score(:Linsana, @def_mid, []) == 0.949
    end
  end

  describe "offensive mid" do
    test "calculate" do
      assert Scoring.get_player_position_score(:Breccan, @off_mid, []) == 0.867
      assert Scoring.get_player_position_score(:Ryan, @off_mid, []) == 0.378
      assert Scoring.get_player_position_score(:Linsana, @off_mid, []) == 0.956
    end
  end

  describe "fwd" do
    test "calculate" do
      assert Scoring.get_player_position_score(:Breccan, @fwd, []) == 0.818
      assert Scoring.get_player_position_score(:Ryan, @fwd, []) == 0.455
      assert Scoring.get_player_position_score(:Linsana, @fwd, []) == 0.909
    end
  end
end
