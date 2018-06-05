-- Insert all the distinct users

INSERT INTO "user" (id, username)
SELECT DISTINCT user_id, user_name FROM complete_revision ON CONFLICT (id) DO NOTHING;

-- Count edits per user as major and minor

UPDATE "user" SET
    edit_count          = (
        SELECT COUNT(*) FROM complete_revision
        WHERE complete_revision.user_id = "user".id AND complete_revision.user_minor = 0
    ),
    minor_edit_count = (
        SELECT COUNT(*) FROM complete_revision
        WHERE complete_revision.user_id = "user".id AND complete_revision.user_minor = 1
    )
;

-- Insert the distinct articles

INSERT INTO article (id, title)
SELECT DISTINCT article_id, article_title
FROM complete_revision ON CONFLICT (id) DO NOTHING;

-- Insert the revisions

INSERT INTO revision (article_id, user_id, timestamp, word_count)
SELECT article_id, user_id, rev_timestamp, rev_wordcount FROM complete_revision
ON CONFLICT (id) DO NOTHING;


--- Can you become an admin by making only minor edits?

SELECT user_id, username, COUNT(CASE WHEN minor = 1 then 1 ELSE NULL END) as minor_edits, COUNT(CASE WHEN minor = 0 then 1 ELSE NULL END) as major_edits, COUNT(minor) AS edits
  FROM revision_talk INNER JOIN "user" u ON revision_talk.user_id = u.id

  WHERE user_id IN (SELECT "user".id FROM "user" INNER JOIN elections ON "user".id = elections.user_id WHERE promoted = TRUE)
  GROUP BY user_id, username
  HAVING COUNT(CASE WHEN minor = 1 then 1 ELSE NULL END) / (COUNT(CASE WHEN minor = 0 then 1 ELSE NULL END) + 1) >= 1
  ORDER BY minor_edits DESC, edits DESC

/*

    33      Derek_Ross        2037  1183  3220
    4191    Nevilley          529   17    546
    2240    Ktsquare          364   196   560
    5753    Vera_Cruz         331   24    355
    7414    Blimpguy          145   26    171
    135     Malcolm_Farmer    137   7     144
    1689    DavidLevinson     136   118   254
    4551    HollyAm           89    69    158
    2597    Nonenmac          74    24    98
    946     Gritchka          45    37    82
    5650    Blueshade         37    26    63
    7651    KAMiKAZOW         35    4     39
    8237    Anobo             28    0     28
    813     Tommy             17    1     18
    3       Tobias_Hoevekamp  15    3     18
    5465    Trevor_H          12    6     18
    6414    Tero              6     4     10
    4712    Tcascardo         5     3     8
    2831    Gjalexei          4     2     6
    127     Seb               4     2     6
    947     Idknow            4     1     5
    5737    Tjfulopp          3     2     5
    4986    Rabin             3     1     4
    1190    Dlloader          3     0     3
    5092    Rhysca            2     0     2
    794     Joeygoey          1     0     1
    746     Fjor              1     0     1

    execution: 2 s 660 ms, fetching: 19 ms
*/

-- Does an increasing amount of interactions (through user talk pages) with an admin lead to an increased chance to become an admin?

SELECT CONCAT('talked to admin'), promoted, COUNT(*)
FROM elections
WHERE user_id IN
      (
        SELECT DISTINCT revision_user_talk.user_id
        FROM revision_user_talk
          INNER JOIN article ON article.id = revision_user_talk.article_id
        WHERE article.title LIKE ANY (
          SELECT DISTINCT CONCAT('User_talk:', "user".username)
          FROM votes
            INNER JOIN "user" ON votes.user_id = "user".id
        )
      )
GROUP BY promoted

UNION

SELECT CONCAT('not to admin'), promoted, COUNT(*)
FROM elections
WHERE user_id NOT IN
      (
        SELECT DISTINCT revision_user_talk.user_id
        FROM revision_user_talk
          INNER JOIN article ON article.id = revision_user_talk.article_id
        WHERE article.title LIKE ANY (
          SELECT DISTINCT CONCAT('User_talk:', "user".username)
          FROM votes
            INNER JOIN "user" ON votes.user_id = "user".id
        )
      )
GROUP BY promoted;

/*
                    promoted    count
  talked to admin   false       139
  talked to admin   true        122

  not to admin      false       1408
  not to admin      true        1125
*/

-- Does interacting with a certain admin lead to them voting in favour of your request for adminship?

SELECT CONCAT('votes (admin interaction)'), COUNT(CASE WHEN vote = 1 then 1 ELSE NULL END) as favor_count, COUNT(CASE WHEN vote = -1 then 1 ELSE NULL END) AS no_favor_count
FROM votes
  INNER JOIN revision_talk ON votes.user_id = revision_talk.user_id
  INNER JOIN (
    SELECT DISTINCT
      (article_id, elections.id),
      article_id,
      elections.id AS election
    FROM revision_talk
      INNER JOIN article ON revision_talk.article_id = article.id
      INNER JOIN "user" ON revision_talk.user_id = "user".id
      INNER JOIN elections ON elections.user_id = revision_talk.user_id
    WHERE elections.promoted = TRUE
) t ON t.article_id = revision_talk.article_id AND votes.election_id = election

UNION

SELECT CONCAT('votes (all)'),
  COUNT(CASE WHEN vote = 1
    then 1
        ELSE NULL END) as favor_count,
  COUNT(CASE WHEN vote = -1
    then 1
        ELSE NULL END) AS no_favor_count
FROM votes;

/*
  
                      favor_count,  no_favor_count
  admin interaction   3117,         344             90%
  all                 83398,        23051           78%

  execution: 23 s 709 ms, fetching: 14 ms
*/

-- Does your chance of becoming an admin increase if you’re making edits across multiple categories?

SELECT
  elections.promoted,
  AVG(t.count_categories),
  STDDEV(t.count_categories),
  MAX(t.count_categories),
  COUNT(elections.promoted)
FROM elections
  INNER JOIN
  (SELECT
     DISTINCT s.user_id,
     LENGTH(categories) - LENGTH(REPLACE(categories, ' ', '')) AS count_categories,
     edits                                                     AS count_edits
   FROM
     (SELECT
        user_id,
        TRIM(STRING_AGG(DISTINCT category, ' ')) AS categories,
        COUNT(id)                                AS edits
      FROM revision_talk
      GROUP BY user_id) s) t ON elections.user_id = t.user_id
WHERE count_categories > 0
GROUP BY elections.promoted;

/*
                avg_category         std_dev              max   count
  not promoted: 11.2580645161290323, 16.4660615447561997, 69,   31
  promoted:     11.0909090909090909, 15.1842935483601134, 64,   22

  execution: 15 s 679 ms, fetching: 11 ms
*/

-- If you edit more actively maintained pages, does your chance to become an admin increase?

SELECT CONCAT('edited top 100 page'), promoted, COUNT(*)
FROM elections
WHERE user_id IN
      (
        SELECT DISTINCT user_id
        FROM revision_talk
          INNER JOIN (
                       SELECT
                         article_id,
                         COUNT(article_id) AS edits
                       FROM revision_talk
                       GROUP BY article_id
                       ORDER BY edits DESC
                       LIMIT 1000
                     ) art ON art.article_id = revision_talk.article_id
      )
GROUP BY promoted

UNION

SELECT CONCAT('not edited top 100 page'), promoted, COUNT(*)
FROM elections
WHERE user_id NOT IN
      (
        SELECT DISTINCT user_id
        FROM revision_talk
          INNER JOIN (
                       SELECT
                         article_id,
                         COUNT(article_id) AS edits
                       FROM revision_talk
                       GROUP BY article_id
                       ORDER BY edits DESC
                       LIMIT 1000
                     ) art ON art.article_id = revision_talk.article_id
      )
GROUP BY promoted;

/*

  'edited top 100 page'       true       119
  'edited top 100 page'       false      142

  'not edited top 100 page'   true       1128
  'not edited top 100 page'   false      1405
  
  So the change is higher to get promoted if you edited not top 100 articles.

*/
