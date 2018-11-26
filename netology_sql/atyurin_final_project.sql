create table player
(
  id                 INTEGER
    primary key,
  player_api_id      INTEGER
    unique,
  player_name        TEXT,
  player_fifa_api_id INTEGER
    unique,
  birthday           TEXT,
  height             NUMERIC,
  weight             NUMERIC
);

create table player_attributes
(
  id                  INTEGER
    primary key,
  player_fifa_api_id  INTEGER
    references Player (player_fifa_api_id),
  player_api_id       INTEGER
    references Player (player_api_id),
  date                TIMESTAMP,
  overall_rating      INTEGER,
  potential           INTEGER,
  preferred_foot      TEXT,
  attacking_work_rate TEXT,
  defensive_work_rate TEXT,
  crossing            INTEGER,
  finishing           INTEGER,
  heading_accuracy    INTEGER,
  short_passing       INTEGER,
  volleys             INTEGER,
  dribbling           INTEGER,
  curve               INTEGER,
  free_kick_accuracy  INTEGER,
  long_passing        INTEGER,
  ball_control        INTEGER,
  acceleration        INTEGER,
  sprint_speed        INTEGER,
  agility             INTEGER,
  reactions           INTEGER,
  balance             INTEGER,
  shot_power          INTEGER,
  jumping             INTEGER,
  stamina             INTEGER,
  strength            INTEGER,
  long_shots          INTEGER,
  aggression          INTEGER,
  interceptions       INTEGER,
  positioning         INTEGER,
  vision              INTEGER,
  penalties           INTEGER,
  marking             INTEGER,
  standing_tackle     INTEGER,
  sliding_tackle      INTEGER,
  gk_diving           INTEGER,
  gk_handling         INTEGER,
  gk_kicking          INTEGER,
  gk_positioning      INTEGER,
  gk_reflexes         INTEGER
);

create table team
(
 id               INTEGER
   primary key,
 team_api_id      INTEGER
   unique,
 team_fifa_api_id INTEGER,
 team_long_name   TEXT,
 team_short_name  TEXT
)

create table team_attributes
(
 id                             INTEGER
   primary key,
 team_fifa_api_id               INTEGER
   references Team (team_fifa_api_id),
 team_api_id                    INTEGER
   references Team (team_api_id),
 date                           TIMESTAMP,
 buildUpPlaySpeed               INTEGER,
 buildUpPlaySpeedClass          TEXT,
 buildUpPlayDribbling           INTEGER,
 buildUpPlayDribblingClass      TEXT,
 buildUpPlayPassing             INTEGER,
 buildUpPlayPassingClass        TEXT,
 buildUpPlayPositioningClass    TEXT,
 chanceCreationPassing          INTEGER,
 chanceCreationPassingClass     TEXT,
 chanceCreationCrossing         INTEGER,
 chanceCreationCrossingClass    TEXT,
 chanceCreationShooting         INTEGER,
 chanceCreationShootingClass    TEXT,
 chanceCreationPositioningClass TEXT,
 defencePressure                INTEGER,
 defencePressureClass           TEXT,
 defenceAggression              INTEGER,
 defenceAggressionClass         TEXT,
 defenceTeamWidth               INTEGER,
 defenceTeamWidthClass          TEXT,
 defenceDefenderLineClass       TEXT
)

create table country
(
  id   INTEGER
    primary key,
  name TEXT
    unique
);

create table league
(
  id         INTEGER
    primary key,
  country_id INTEGER
    references country,
  name       TEXT
    unique
);

create table match
(
  id               INTEGER
    primary key,
  country_id       INTEGER
    references country,
  league_id        INTEGER
    references league,
  season           TEXT,
  stage            INTEGER,
  date             TIMESTAMP,
  match_api_id     INTEGER
    unique,
  home_team_api_id INTEGER
    references Team (team_api_id),
  away_team_api_id INTEGER
    references Team (team_api_id),
  home_team_goal   INTEGER,
  away_team_goal   INTEGER,
  goal             TEXT,
  shoton           TEXT,
  shotoff          TEXT,
  foulcommit       TEXT,
  card             TEXT,
  "cross"          TEXT,
  corner           TEXT,
  possession       TEXT
);

copy player FROM '/soccer_db/player.tsv' DELIMITER E'\t';
copy player_attributes FROM '/soccer_db/player_attributes.tsv' DELIMITER E'\t';
copy team FROM '/soccer_db/team.tsv' DELIMITER E'\t';
copy team_attributes FROM '/soccer_db/team_attributes.tsv' DELIMITER E'\t';
copy country FROM '/soccer_db/country.tsv' DELIMITER E'\t';
copy league FROM '/soccer_db/league.tsv' DELIMITER E'\t';
copy match FROM '/soccer_db/match.tsv' DELIMITER E'\t';

-- список лиг и стран
SELECT * FROM League JOIN Country ON Country.id = League.country_id;

-- коичество матчей, сыгранных в каждом сезоне
SELECT season, count(id) as number_of_matches FROM match GROUP BY season ORDER BY season;

-- как сыграли команды Шотландской Премеьр-Лиги дома и на выезде
SELECT match.id,
       country.name AS country_name,
       league.name AS league_name,
       season,
       date,
       HT.team_long_name AS  home_team,
       AT.team_long_name AS away_team,
       home_team_goal,
       away_team_goal
FROM match
JOIN country on country.id = match.country_id
JOIN league on league.id = match.league_id
LEFT JOIN team AS HT on HT.team_api_id = match.home_team_api_id
LEFT JOIN team AS AT on AT.team_api_id = match.away_team_api_id
WHERE country.name = 'Scotland'
ORDER by date
LIMIT 10;

-- статистика по количеству забитых мячей в матчах, 
-- сгруппированная по странам, лигам и сезонам и отфильтрованная по колчичеству стадий
SELECT country.name AS country_name, 
       league.name AS league_name, 
       season,
       count(distinct HT.team_long_name) AS number_of_teams,
       avg(home_team_goal) AS avg_home_team_goals, 
       avg(away_team_goal) AS avg_away_team_goals, 
       avg(home_team_goal+away_team_goal) AS avg_goals, 
       sum(home_team_goal+away_team_goal) AS total_goals                                       
FROM match
JOIN country on country.id = match.country_id
JOIN league on league.id = match.league_id
LEFT JOIN team AS HT on HT.team_api_id = match.home_team_api_id
LEFT JOIN team AS AT on AT.team_api_id = match.away_team_api_id
WHERE country.name in ('Spain', 'Germany', 'France', 'Italy', 'England')
GROUP BY country.name, league.name, season
HAVING count(distinct stage) > 10
ORDER BY country.name, league.name, season DESC;

-- насколько успешны игроки с различными антропометрическими показателями
SELECT ROUND(height),
       COUNT(height) AS distribution,
       avg(weight/2.205) AS avg_weight,
       avg(pa_grouped.avg_overall_rating) AS avg_overall_rating,
       avg(pa_grouped.avg_potential) AS avg_potential
FROM player
LEFT JOIN (SELECT player_attributes.player_api_id,
            avg(player_attributes.overall_rating) AS avg_overall_rating,
            avg(player_attributes.potential) AS avg_potential
            FROM player_Attributes
            GROUP BY player_Attributes.player_api_id)
            AS pa_grouped ON player.player_api_id = pa_grouped.player_api_id
GROUP BY ROUND(height)
ORDER BY ROUND(height);

-- кто точнее в ударах: левши или правши
SELECT preferred_foot, avg(free_kick_accuracy) FROM player_attributes GROUP BY preferred_foot;

-- процентное распределение ростов футболистов по квартилям
-- 50% выше 183см, а в 185см укладываются 75%
SELECT
  percentile_cont(0.25) within group (ORDER BY ROUND(height) ASC) AS percentile_25,
  percentile_cont(0.50) within group (ORDER BY ROUND(height) ASC) AS percentile_50,
  percentile_cont(0.75) within group (ORDER BY ROUND(height) ASC) AS percentile_75,
  percentile_cont(0.95) within group (ORDER BY ROUND(height) ASC) AS percentile_95
FROM player;

-- кто из футболистов выходил на поле в свой день рождения
WITH match_dates as (SELECT DISTINCT to_char(date, 'DD-MM') as date from match)
SELECT player.player_name FROM player
JOIN match_dates on to_char(player.birthday, 'DD-MM') = match_dates.date;

-- корреляция: насколько агрессивность игрока влияюет на частоту подкатов
-- 0 - не влияет, 
-- -1 - чем выше агрессивность, тем реже он делает подкаты, 
-- +1 - чем выше агрессивность, тем чаще он делает подкаты, 
SELECT player_api_id, corr(aggression, sliding_tackle) FROM player_attributes 
GROUP BY player_api_id HAVING corr(aggression, sliding_tackle) IS NOT NULL;

-- Количественное соотношение корреляций агрессивность/подкаты
-- ответ: у 69% футболистов корреляция позитивная
WITH correlation as (SELECT player_api_id, corr(aggression, sliding_tackle) FROM player_attributes 
                     GROUP BY player_api_id HAVING corr(aggression, sliding_tackle) IS NOT NULL)
SELECT sum (case when corr < 0 then 1 else 0 end) as neg,
       sum (case when corr = 0 then 1 else 0 end) as zero,
       sum (case when corr > 0 then 1 else 0 end) as pos FROM correlation;

