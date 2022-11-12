USE [Premier_League]
GO

/****** Object:  StoredProcedure [dbo].[proc_pl_yellow_percent_win_ratio]    Script Date: 25/10/2022 18:12:39 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[proc_pl_yellow_percent_win_ratio]
AS
BEGIN

/* 

Example call: EXEC [Premier_League].[dbo].[proc_pl_yellow_percent_win_ratio]

Description:

This procedure joins each match with the teams yellow percentage for that year and populates a table.
I will use this see if there is any relation between the match result and the ratio of yellows:fouls a referee
gives certain teams.

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

DROP TABLE IF EXISTS #yellow_percent_opposition
SELECT DISTINCT a.*, b.season_end_year, CASE WHEN b.home_team = a.team THEN 'Home'
                                                     ELSE 'Away' END home_or_away,
												CASE WHEN b.home_team <> a.team THEN b.home_team
												     ELSE b.away_team END opposition
  INTO #yellow_percent_opposition
FROM #referee_most_hated a
  JOIN Premier_League..fouls_17_22 b ON (a.team = b.home_team OR a.team = b.away_team) -- OR because we want both home and away matches
                                       AND a.referee = b.referee

-- Give the points the team would have received for each game. We can then see if the is a correlation betweem
-- the yellow to fouls ratio and wins.
DROP TABLE IF EXISTS Premier_League..referee_yellows_to_wins 
SELECT a.team, a.referee, a.yellow_percent, home_or_away,CASE WHEN b.FTR = 'H' AND a.home_or_away = 'Home' THEN 3
                                                              WHEN b.FTR = 'A' AND a.home_or_away = 'Away' THEN 3
															  WHEN b.FTR = 'H' AND a.home_or_away = 'Away' THEN 0
                                                              WHEN b.FTR = 'A' AND a.home_or_away = 'Home' THEN 0
															  WHEN b.FTR = 'D' THEN 1 END match_points
INTO Premier_League..referee_yellows_to_wins                         
FROM #yellow_percent_opposition a
  JOIN Premier_League..premier_league_matches b ON CASE WHEN a.home_or_away = 'Home' THEN b.Home ELSE b.Away END = a.team
                                                   AND CASE WHEN a.home_or_away = 'Home' THEN b.away ELSE b.home END = a.opposition
												   AND a.season_end_year = b.Season_End_Year


END

