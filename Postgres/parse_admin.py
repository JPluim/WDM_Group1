#!/usr/bin/python
import pgdb
import re
import sys

reload(sys)
sys.setdefaultencoding('utf8')

hostname = 'localhost'
username = 'web-data-management'
password = ''
database = 'web-data-management'

connection = pgdb.connect( host=hostname, user=username, password=password, database=database )

fp = open("wikiElec.ElecBs3.txt")
item_count = 1
# max_count = 11629605
max_count = 35

promoted = 0
user_id = ''
user_name = ''
vote_supported = 0
vote_neutral = 0
vote_oppose = 0
votes = []

for line in fp:
    line = line.replace('\r\n', '')

    elements = line.split('\t')

    if elements[0] == 'E':
        promoted = int(elements[1])
    elif elements[0] == 'U':
        user_id = str(elements[1])
        user_name = re.escape(elements[2]).decode('utf-8', 'ignore')
    elif elements[0] == 'V':
        votes.append(
            [
                item_count,
                int(elements[1]),
                str(elements[2]),
                str(elements[3]),
                str(re.escape(elements[4]).decode('utf-8', 'ignore'))
            ]
        )

    cur = connection.cursor()
    if not line.strip():
        insertQuery = 'INSERT INTO public.elections (id, user_id, promoted) VALUES (%s, %s, %s)'

        cur.execute(insertQuery, (
                item_count,
                str(user_id),
                str(promoted)
            )
        )

        for vote in votes:
            print vote

            insertVoteQuery = 'INSERT INTO public.votes (election_id, vote, user_id, vote_time, screen_name) VALUES (%s, %s, %s, %s, %s)'
            cur.execute(insertVoteQuery, (
                vote[0],
                vote[1],
                vote[2],
                vote[3],
                vote[4]
            )
        )

        connection.commit()

        promoted = 0
        user_id = ''
        user_name = ''
        votes = []

        item_count += 1