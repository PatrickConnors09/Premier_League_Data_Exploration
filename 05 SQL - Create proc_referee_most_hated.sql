USE [Premier_League]
GO

/****** Object:  StoredProcedure [dbo].[proc_pl_yellow_percent_win_ratio]    Script Date: 25/10/2022 18:12:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[proc_referee_most_hated]
AS
BEGIN

/*
Example call: EXEC Premier_League..proc_referee_most_hated

Description:
This procedure creates a table that compares each team to each referee and shows the amount of yellow
cards they receive compared to fouls given away.

*/

DROP TABLE IF EXISTS #total_home_fouls
SELECT home_team, referee,SUM(home_fouls) fouls, SUM(home_yellow) yellows
  INTO #total_home_fouls
FROM Premier_League..fouls_17_22
GROUP BY home_team, referee

DROP TABLE IF EXISTS #total_away_fouls
SELECT away_team, referee,SUM(away_fouls) fouls, SUM(away_yellow) yellows
  INTO #total_away_fouls
FROM Premier_League..fouls_17_22
GROUP BY away_team, referee

DROP TABLE IF EXISTS #referee_most_hated
SELECT a.home_team team, a.referee, CONVERT(decimal(5,2), (a.yellows + b.yellows)/(a.fouls*1.0 + b.fouls)) yellow_percent
  INTO #referee_most_hated
FROM #total_home_fouls a
  JOIN #total_away_fouls b ON a.home_team = b.away_team 
                            AND a.referee = b.referee

DROP TABLE IF EXISTS Premier_League..referee_most_hated_team
SELECT referee + ' ' + team referee_and_team, team, referee, yellow_percent
  INTO Premier_League..referee_most_hated_team
FROM #referee_most_hated

SELECT TOP 10 * 
                                              FROM Premier_League..referee_most_hated_team 
                                              ORDER BY yellow_percent DESC
END
GO


