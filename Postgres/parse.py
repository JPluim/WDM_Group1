#!/usr/bin/python
import pgdb
import re
import sys
import progressbar as pb

reload(sys)
sys.setdefaultencoding('utf8')

hostname = 'localhost'
username = 'web-data-management'
password = ''
database = 'web-data-management'

connection = pgdb.connect( host=hostname, user=username, password=password, database=database )

article_id = 0
rev_id = 0
article_title = ''
timestamp = ''
username = ''
user_id = 0
comment = ''
minor = ''
word_count = 0
article_category = ''
article_related_pages = ''

def reset_vars():
    article_id = 0
    rev_id = 0
    article_title = ''
    timestamp = ''
    username = ''
    user_id = 0
    comment = ''
    minor = ''
    word_count = 0
    article_category = ''
    article_related_pages = ''


fp = open("enwiki-20080103.user_talk")
revision_idx = 0
max_count = 11000000

timer = pb.ProgressBar(maxval = max_count).start()

for revision in range(0, max_count):
    timer.update(revision)
    elements = []
    article_related_pages = ''
    reset_vars()

    for row in range(0, 14):
        line = fp.readline().replace('\n', '')
        elements = line.split(' ')

        if elements[0] == 'REVISION':
            article_id = str(elements[1])
            rev_id = elements[2]
            article_title = str(elements[3])
            timestamp = str(elements[4])
            username = str(elements[5])
            user_id = str(elements[6])
        elif elements[0] == 'MINOR':
            minor = str(elements[1])
        elif elements[0] == 'TEXTDATA':
            word_count = elements[1]
        elif elements[0] == 'CATEGORY':
            article_category = ' '.join(elements[1:])
        elif elements[0] == 'MAIN' or elements[0] == 'TALK' or elements[0] == 'USER' or elements[0] == 'USER_TALK' :
            article_related_pages += (' ' + ' '.join(elements[1:3])).strip()

        cur = connection.cursor()
        if line == '':
            revision_idx += 1
            if (revision_idx == max_count):
                break

            insertQuery = 'INSERT INTO public.complete_revision (rev_id, rev_timestamp, rev_wordcount, article_id, article_title, user_name, user_id, rev_minor, article_category, article_related_pages) VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s) ON CONFLICT (rev_id) DO NOTHING'
            cur.execute(insertQuery, (
                int(rev_id),
                str(timestamp),
                int(word_count),
                int(article_id),
                str(article_title),
                str(username),
                str(user_id),
                str(minor),
                str(article_category),
                str(article_related_pages.strip())
            ))
            connection.commit()

timer.finish()
    