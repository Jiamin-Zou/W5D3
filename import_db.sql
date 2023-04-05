PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS question_follows;
DROP TABLE IF EXISTS replies;
DROP TABLE IF EXISTS question_likes;
DROP TABLE IF EXISTS questions;
DROP TABLE IF EXISTS users;

CREATE TABLE question_follows (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE replies (
    id INTEGER PRIMARY KEY,
    question_id INTEGER NOT NULL,
    reply_id INTEGER,
    user_id INTEGER NOT NULL,
    body TEXT NOT NULL,

    FOREIGN KEY (question_id) REFERENCES questions(id),
    FOREIGN KEY (reply_id) REFERENCES replies(id),
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
    id INTEGER PRIMARY KEY,
    user_id INTEGER NOT NULL,
    question_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (question_id) REFERENCES questions(id)
);

CREATE TABLE questions (
    id INTEGER PRIMARY KEY,
    title TEXT NOT NULL,
    body TEXT NOT NULL,
    user_id INTEGER NOT NULL,

    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE TABLE users (
    id INTEGER PRIMARY KEY,
    fname TEXT NOT NULL,
    lname TEXT NOT NULL
);

INSERT INTO 
    users (fname, lname)
VALUES
    ('John', 'Doe'),
    ('Snow', 'White');

INSERT INTO
    questions (title, body, user_id)
VALUES
    ('Why', 'Why is her hair blue', (SELECT id FROM users WHERE fname = 'John' AND lname = 'Doe')),
    ('Who', 'Who is Snow White', (SELECT id FROM users WHERE fname = 'Snow' AND lname = 'White'));

INSERT INTO 
    replies (question_id, reply_id, user_id, body)
VALUES
    (1, NULL, 2, 'Great question'),
    (1, 1, 1, 'Awful question');

INSERT INTO
    question_follows (user_id, question_id)
VALUES
    (1, 1),
    (2, 1),
    (1, 2);

INSERT INTO
    question_likes (user_id, question_id)
VALUES
    (2, 1),
    (2, 2),
    (1, 1);