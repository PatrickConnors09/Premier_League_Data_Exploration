-- Create Views For Python
/*
This script creates some views that I can possibly use for visualisations in a
Jupyter Notebook.
*/ 

USE
Premier_League

GO 
-- 1. Fouls distribution
CREATE OR ALTER VIEW vw_PL_fouls_distribution AS

SELECT MIN(total_fouls) minimum_fouls, MAX(total_fouls) max_fouls, avg(total_fouls) avg_fouls
FROM Premier_League..fouls_17_22

GO
-- 2. Fouls by season
CREATE OR ALTER VIEW vw_PL_fouls_by_season AS 

SELECT season_end_year, AVG(total_fouls) average_fouls, AVG(total_yellows) average_yellows
FROM  Premier_League..fouls_17_22
GROUP BY season_end_year

GO

-- 3. The average amount of yellow cards received and fouls commited by each team.
CREATE OR ALTER VIEW vw_PL_team_fouls_yellow_per_game AS 


SELECT team, AVG(CASE WHEN a.team = b.home_team THEN b.home_fouls
                  WHEN a.team = b.away_team THEN b.away_fouls
			      END) average_fouls,
			 AVG(CASE WHEN a.team = b.home_team THEN b.home_yellow
                  WHEN a.team = b.away_team THEN b.away_yellow
			      END) average_yellows
FROM Premier_League..ref_teams a
  JOIN Premier_League..fouls_17_22 b ON (a.team = b.home_team OR a.team = B.away_team)
GROUP BY a.team


GO

CREATE OR ALTER VIEW vw_PL_referee_most_fouls AS

-- 3. Referee with most fouls.
SELECT referee, AVG(total_fouls) average_fouls, AVG(total_yellows) average_yellows
FROM  Premier_League..fouls_17_22
GROUP BY referee


GO

-- 4. The correlation of total fouls to final PL standings
CREATE OR ALTER VIEW vw_correlation_fouls_standings 
AS

SELECT b.team, a.season_end_year,SUM(CASE WHEN b.team = a.home_team THEN a.home_fouls ELSE away_fouls END) total_fouls,
  SUM(CASE WHEN b.team = a.home_team THEN a.home_yellow ELSE away_yellow END) total_yellows, AVG(b.pts) points,
  AVG(b.gd) goal_difference, AVG(b.gf) goals_for, AVG(b.ga) goals_against, AVG(b.w) wins, AVG(b.l) losses
FROM Premier_League..fouls_17_22 a
  JOIN Premier_League..premier_league_standings_00_22 b ON (b.team = a.away_team OR b.team = a.home_team)
                                                            AND a.season_end_year = b.season_end_year
GROUP BY b.team, a.season_end_year


							

