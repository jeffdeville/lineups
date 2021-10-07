defmodule Lineups.ScoringTest do
  use ExUnit.Case, async: true
  # alias Lineups.Scoring
  describe "invalid lineups score 0" do
    test "empty lineups score 0" do
      assert Lineups.Scoring.score([]) == 0
    end

    test "incomplete lineups score 0" do
      assert Lineups.Scoring.score([[:Breccan, :Harry, :Isaiah ]]) == 0
    end

    test "any incomplete lineup scores 0" do
      assert Lineups.Scoring.score([[:Breccan, :Harry, :Isaiah, :Cameron, :Paco, :Ryan, :Evan], [:Breccan, :Harry]]) == 0
    end

    test "lineups with duplicate players scores 0" do
      assert Lineups.Scoring.score([[:Breccan, :Breccan, :Breccan, :Breccan, :Breccan, :Breccan, :Breccan]]) == 0
    end

    test "lineups with invalid players scores 0" do
      assert Lineups.Scoring.score([[:ThisIsNotAPlayer, :Harry, :Isaiah, :Cameron, :Paco, :Ryan, :Evan]]) == 0
    end

  end

  describe "valid lineups generate scores" do
    test "a single lineup is scored properly" do
      assert Lineups.Scoring.score([[:Breccan, :Harry, :Isaiah, :Cameron, :Paco, :Ryan, :Evan]]) == 305
    end

    test "lineup scores are averaged, so duplicate lineups should have the same score" do
      lineup1 = [:Breccan, :Harry, :Isaiah, :Cameron, :Paco, :Ryan, :Evan]
      lineup2 = [:Cameron, :Evan, :Richard, :Breccan, :SamK, :Lusaine, :Linsana]
      assert Lineups.Scoring.score([ lineup1, lineup1 ]) == Lineups.Scoring.score([ lineup1])
      assert Lineups.Scoring.score([ lineup1, lineup2 ]) == 591
    end
  end
end
