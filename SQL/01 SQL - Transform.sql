/* 
This script cleans the data and ensures it is ready for analysis.
*/

-- 1. Are all team names the same??

-- 1.1 Create temp table and sort each table by season end and team name
DROP TABLE IF EXISTS #matches_table_teams
SELECT DISTINCT home, Season_End_Year
  INTO #matches_table_teams
FROM Premier_League..premier_league_matches 


DROP TABLE IF EXISTS #fouls_table_teams
SELECT DISTINCT home_team, date,CASE WHEN DATEPART(MONTH, CONVERT(datetime, date)) >=8 THEN DATEPART(year, DATEADD(year, +1, date))
                                     WHEN DATEPART(MONTH, date) <=7 THEN DATEPART(year, date)
						        END season_end_year
  INTO #fouls_table_teams
FROM Premier_League..fouls_17_22


DROP TABLE IF EXISTS #standings_table_teams
SELECT team, '20' + RIGHT(season, 2) Season_End_Year
  INTO #standings_table_teams
FROM Premier_League..premier_league_standings_00_22

-- 1.2 Then see which teams match up. I go two at a time ot make it easier to follow
SELECT *
FROM (SELECT DISTINCT home_team, season_end_year FROM #fouls_table_teams) a
 LEFT JOIN (SELECT DISTINCT home, season_end_year FROM #matches_table_teams) b ON a.season_end_year = b.Season_End_Year
                                                                                AND a.home_team = b.Home
WHERE b.Home IS NULL

-- All of the final two table matched only #matches_table_teams needs Premier_League..premier_league_matches 
SELECT *
FROM (SELECT DISTINCT home_team, season_end_year FROM #fouls_table_teams) a
 LEFT JOIN (SELECT DISTINCT team, season_end_year FROM #standings_table_teams) b ON a.season_end_year = b.Season_End_Year
                                                                                AND a.home_team = b.team
WHERE b.team IS NULL

-- 1.3 Make updates to the table
DECLARE @team_name_to_change varchar(50) = '%Bolton%' 
DECLARE @new_name varchar(50) = 'Bolton Wanderers'

UPDATE Premier_League..premier_league_matches
SET home = @new_name,
  away = @new_name
WHERE (away LIKE @team_name_to_change OR home LIKE @team_name_to_change)

-- 2. Add the year of season end to base tables, enabling joins on this column

-- 2.1 Standing Table
ALTER TABLE Premier_League..premier_league_standings_00_22 
ADD season_end_year smallint

UPDATE b
SET b.season_end_year = a.Season_End_Year
FROM #standings_table_teams a
  JOIN Premier_League..premier_league_standings_00_22 b ON a.team = b.team
                                                          AND a.Season_End_Year =  '20' + RIGHT(b.season, 2)
-- 2.2 Fouls Table														  
ALTER TABLE Premier_League..fouls_17_22
ADD season_end_year smallint

UPDATE Premier_League..fouls_17_22
SET season_end_year = (  CASE WHEN DATEPART(MONTH, CONVERT(datetime, date)) >=8 THEN  DATEPART(year, DATEADD(year, +1, date))
                              WHEN DATEPART(MONTH, date) <=7 THEN DATEPART(year, date) 
				           END ) 

-- 3. Create a Teams reference table
DROP TABLE IF EXISTS Premier_League..ref_teams
SELECT DISTINCT team
INTO Premier_League..ref_teams
FROM Premier_League..premier_league_standings_00_22

UNION 

SELECT DISTINCT home_team
FROM Premier_League..fouls_17_22

UNION 

SELECT DISTINCT Home
FROM Premier_League..premier_league_matches




