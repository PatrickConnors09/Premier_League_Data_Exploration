/*
This script is exploring the data and analysising the tables.
*/

-- 1. Fouls

-- 1.1 What is the average amount of fouls & yellows per game?

SELECT 'Averages', AVG(home_fouls) home_fouls, AVG(away_fouls) away_fouls, AVG(home_yellow) home_yellows, AVG(away_yellow) away_yellows,
  AVG(total_yellows) total_yellows, AVG(total_fouls) total_fouls, CONVERT(decimal(5,2), AVG(total_yellows)*1.0 / AVG(total_fouls)*100) foul_yellow_percent
FROM Premier_League..fouls_17_22


-- What is the range of total fouls committed in PL games?

SELECT MIN(total_fouls) minimum_fouls, MAX(total_fouls) max_fouls, avg(total_fouls) avg_fouls
FROM Premier_League..fouls_17_22;


-- On average the home and away team give away same number of fouls and get the same number of yellow cards.

-- 1.2 Which referee gives out the most fouls?

DROP TABLE IF EXISTS #referee_average_fouls_game
SELECT referee, AVG(total_fouls) avg_total_fouls, AVG(home_fouls) home_fouls, AVG(away_fouls) away_fouls
  INTO #referee_average_fouls_game
FROM Premier_League..fouls_17_22
GROUP BY referee
ORDER BY AVG(total_fouls) DESC

-- Tim Robinson gives both the most total fouls and give 5 more fould to home than away team.
-- All referees seem to give away similiar amounts of fouls to both home and away teams except Tim Robinson 
-- who gives about 40% more to the away teams

-- 2.1 What season had the highest foul count?
SELECT season_end_year, AVG(total_fouls) average_fouls, AVG(total_yellows) average_yellows
FROM  Premier_League..fouls_17_22
GROUP BY season_end_year
ORDER BY  AVG(total_fouls) DESC, AVG(total_yellows) DESC


-- 20/21 is the season with the highest fould count. All years produced the same amount of yellows per game.


-- 2.2 Which referee gives away most  fouls in one game?
SELECT referee, MAX(total_fouls) max_fouls, MAX(total_yellows) max_yellows, avg(total_fouls) avg_fouls, avg(total_yellows) avg_yellows
FROM Premier_League..fouls_17_22
GROUP BY referee
ORDER BY MAX(total_fouls) DESC 

-- The highest was Martin Atkinson, who gave away 51 fouls in one game.


-- 2.3 When playing at home what is the distribution of fouls like for each team?
-- Also at home, how many fouls that teams commit convert to yellows?
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

-- Bournemouth and Wolves have both the most fouls that convert to yellows. 
-- While Stoke, Burnley and West Brom have the least. 

-- How do these differ while playing away?

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
ORDER BY avg_yellows*1.0 / avg_fouls DESC

-- Man Utd convert the most fouls to yellows while playing away and Sheffield and Fulham the least. 

-- 3. Does the % of yellow cards teams receive/total fouls committed change when playing
--    at home vs away?
DROP TABLE IF EXISTS #home_v_away_fouls_to_yellows
SELECT a.home_team team, a.percent_fouls_yellows home_yellows_percent, b.percent_fouls_yellows_away away_yellow_percent,
  ABS(a.percent_fouls_yellows - b.percent_fouls_yellows_away) difference
  INTO #home_v_away_fouls_to_yellows
FROM #percent_fouls_yellows_home a 
  JOIN #percent_fouls_yellows_away b ON a.home_team = b.away_team
ORDER BY ABS(a.percent_fouls_yellows - b.percent_fouls_yellows_away) DESC

-- The percent tames receive yellow cards for fouls committed differs by 3% on average between home and away games.

-- 3.1 Do teams give away more fouls at home or away?
SELECT CONVERT(decimal(5,2), avg(difference)) avg_difference, 
  SUM(CASE WHEN home_yellows_percent > away_yellow_percent THEN 1 ELSE 0 END) higher_home_ratio,
  SUM(CASE WHEN home_yellows_percent < away_yellow_percent THEN 1 ELSE 0 END) higher_away_ratio,
  SUM(CASE WHEN home_yellows_percent = away_yellow_percent THEN 1 ELSE 0 END) same_home_and_away
FROM #home_v_away_fouls_to_yellows

-- 12 teams are more likely to receive yellow card when they foul and are playing away.
-- 10 teams are more likely to receive yellow card when they foul and are playing at home.
-- 6 teams receive the same amount of yellow cards for fouls committed at home & away.

-- 4. Based on this % do referees become more strict for certain teams ie do they have most hated teams 
-- and favourite teams?

-- 2.41 First I Go by home games and then I will do away games and sum both to get total fouls and yellows 
-- given to each team by each referee.
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

SELECT *
FROM #referee_most_hated
ORDER BY yellow_percent DESC

-- The most "hated" team by any referee is Wolves who are hated most by Roger East 
-- There are five potentially most loved teams with 0 percent yellows. 
-- However I want to see if they have ever been referees have ever had a match with these teams. 

SELECT DISTINCT a.team, a.referee, b.season_end_year
FROM #referee_most_hated a
  LEFT JOIN Premier_League..fouls_17_22 b ON (a.team = b.home_team OR a.team = b.away_team) -- OR because we want both home and away matches
                                       AND a.referee = b.referee
WHERE yellow_percent = 0

-- They have all referee'd at least one game for their most "loved" team. So these can be considered as the referree's favourite team.
-- by each referee



 


