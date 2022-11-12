USE [Premier_League]
GO

/****** Object:  StoredProcedure [dbo].[proc_pl_yellow_percent_win_ratio]    Script Date: 25/10/2022 18:16:55 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE OR ALTER PROCEDURE [dbo].[proc_team_percent_yellow_to_fouls]
AS
BEGIN

/* 
Example Call: EXEC Premier_League..proc_team_percent_yellow_to_fouls

Description:
This procedure creates a table that showcases the difference in likelihood of receiving a yellow card
for a foul committed when playing at home vs away for each PL team.

*/

DROP TABLE IF EXISTS #home_fouls_agg
SELECT home_team, MAX(total_yellows) max_yellows, MIN(total_yellows) min_yellows, MAX(total_fouls) max_fouls,
       AVG(total_fouls) avg_fouls, AVG(total_yellows) avg_yellows
  INTO #home_fouls_agg
FROM Premier_League..fouls_17_22
GROUP BY home_team

DROP TABLE IF EXISTS #percent_fouls_yellows_home
SELECT home_team, CONVERT(decimal(5,2), (avg_yellows*1.0 / avg_fouls)) percent_fouls_yellows
  INTO #percent_fouls_yellows_home
FROM #home_fouls_agg
ORDER BY avg_yellows*1.0 / avg_fouls DESC


DROP TABLE IF EXISTS #away_fouls_agg
SELECT away_team, MAX(total_yellows) max_yellows, MIN(total_yellows) min_yellows, MAX(total_fouls) max_fouls,
       AVG(total_fouls) avg_fouls, AVG(total_yellows) avg_yellows
  INTO #away_fouls_agg
FROM Premier_League..fouls_17_22
GROUP BY away_team

DROP TABLE IF EXISTS #percent_fouls_yellows_away
SELECT away_team, CONVERT(decimal(5,2), (avg_yellows*1.0 / avg_fouls)) percent_fouls_yellows_away
  INTO #percent_fouls_yellows_away
FROM #away_fouls_agg
SELECT a.home_team team, a.percent_fouls_yellows home_yellows_percent, b.percent_fouls_yellows_away away_yellow_percent
FROM #percent_fouls_yellows_home a 
  JOIN #percent_fouls_yellows_away b ON a.home_team = b.away_team

SELECT a.home_team team, a.percent_fouls_yellows home_yellows_percent, b.percent_fouls_yellows_away away_yellow_percent
FROM #percent_fouls_yellows_home a 
  JOIN #percent_fouls_yellows_away b ON a.home_team = b.away_team


END
GO


