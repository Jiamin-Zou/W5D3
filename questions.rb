require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
    include Singleton

    def initialize
        super('questions.db')
        self.type_translation = true
        self.results_as_hash = true
    end
end

class User
    attr_accessor :fname, :lname
    attr_reader :id

    def initialize(options)
        @id = options['id']
        @fname = options['fname']
        @lname = options['lname']
    end

    def self.all
        data = QuestionsDatabase.instance.execute('SELECT * FROM users')
        data.map { |datum| User.new(datum)}
    end

    def self.find_by_id(id)
        user = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                users
            WHERE
                id = ?
        SQL

        return nil if user.empty?
        User.new(user.first)
    end

    def self.find_by_name(fname, lname)
        user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
            SELECT
                *
            FROM
                users
            WHERE
                fname = ? AND lname = ?
        SQL
        return nil if user.empty?
        User.new(user.first)
    end

    def authored_questions
        Question.find_by_author_id(@id)
    end

    def authored_replies
        Reply.find_by_user_id(@id)
    end

    def followed_questions
        QuestionFollow.followed_questions_for_user_id(@id)
    end

    def liked_questions
        QuestionLike.liked_questions_for_user_id(@id)
    end

    def average_karma
        questions = self.authored_questions
        likes = questions.map { |q| q.num_likes}
        (1.0*likes.sum) / questions.size
    end

    def save
        if @id.nil? 
            QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
                INSERT INTO
                    users (fname, lname)
                VALUES
                    (?, ?)
            SQL

            @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname, @id)
                UPDATE
                    users
                SET
                    fname = ?, lname = ?
                WHERE
                    id = ?
            SQL
        end
    end

end

class Question
    attr_accessor :title, :body, :user_id
    attr_reader :id

    def initialize(options)
        @id = options['id']
        @title = options['title']
        @body = options['body']
        @user_id = options['user_id']
    end

    def self.all
        data = QuestionsDatabase.instance.execute('SELECT * FROM questions')
        data.map { |datum| Question.new(datum)}
    end

    def self.find_by_id(id)
        question = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                questions
            WHERE
                id = ?
        SQL

        return nil if question.empty?
        Question.new(question.first)
    end

    def self.find_by_author_id(author_id)
        questions = QuestionsDatabase.instance.execute(<<-SQL, author_id)
            SELECT
                *
            FROM 
                questions 
            WHERE
                user_id = ?
        SQL

        return nil if questions.empty?
        questions.map { |q| Question.new(q)}
    end

    def author 
        User.find_by_id(@user_id)
    end

    def replies
        Reply.find_by_question_id(@id)
    end

    def followers
        QuestionFollow.followers_for_question_id(@id)
    end

    def self.most_followed(n)
        QuestionFollow.most_followed_questions(n)
    end

    def likers
        QuestionLike.likers_for_question_id(@id)
    end

    def num_likes
        QuestionLike.likers_for_question_id(@id).size
    end

    def self.most_liked(n)
        most_like = QuestionsDatabase.instance.execute(<<-SQL, n)
            SELECT
                question_id, COUNT(question_id)
            FROM
                question_likes
            GROUP BY
                question_id
            LIMIT
                ?
        SQL

        return nil if most_like.empty?
        most_like.map { |most| Question.find_by_id(most['question_id'])}

    end

    def save
        if @id.nil? 
            QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id)
                INSERT INTO
                    questions (title, body, user_id)
                VALUES
                    (?, ?, ?)
            SQL

            @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @user_id, @id)
                UPDATE
                    questions
                SET
                    title = ?, body = ?, user_id = ?
                WHERE
                    id = ?
            SQL
        end
        
    end


end

class QuestionLike
    attr_accessor :user_id, :question_id
    attr_reader :id

    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end

    def self.all
        data = QuestionsDatabase.instance.execute('SELECT * FROM question_likes')
        data.map { |datum| QuestionLike.new(datum)}
    end

    def self.find_by_id(id)
        like = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                question_likes
            WHERE
                id = ?
        SQL

        return nil if like.empty?
        QuestionLike.new(like.first)
    end

    def self.likers_for_question_id(q_id)
        likers = QuestionsDatabase.instance.execute(<<-SQL, q_id)
            SELECT
                user_id
            FROM
                question_likes
            WHERE
                question_id = ?
        SQL
        return nil if likers.empty?
        likers.map { |liker| User.find_by_id(liker['user_id'])}
    end

    def self.liked_questions_for_user_id(user_id)
        questions = QuestionsDatabase.instance.execute(<<-SQL, user_id)
            SELECT
                question_id
            FROM
                question_likes
            WHERE
                user_id = ?
        SQL

        return nil if questions.empty?
        questions.map { |q| Question.find_by_id(q['question_id'])}
    end

    def self.num_likes_for_question_id(question_id)
        likes = QuestionsDatabase.instance.execute(<<-SQL, question_id)
            SELECT
                COUNT(question_id) AS num_like
            FROM
                question_likes
            WHERE
                question_id = ?
        SQL

        return nil if likes.empty?
        likes.first['num_like']
    end

end

class Reply
    attr_accessor :question_id, :reply_id, :user_id, :body
    attr_reader :id

    def initialize(options)
        @id = options['id']
        @question_id = options['question_id']
        @reply_id = options['reply_id']
        @user_id = options['user_id']
        @body = options['body']
    end

    def self.all
        data = QuestionsDatabase.instance.execute('SELECT * FROM replies')
        data.map { |datum| Reply.new(datum)}
    end

    def self.find_by_id(id)
        reply = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                replies
            WHERE
                id = ?
        SQL

        return nil if reply.empty?
        Reply.new(reply.first)
    end

    def self.find_by_user_id(user_id)
        replies = QuestionsDatabase.instance.execute(<<-SQL, user_id)
        SELECT
            *
        FROM
            replies
        WHERE
            user_id = ?
        SQL

        return nil if replies.empty?
        replies.map { |r| Reply.new(r) }

    end

    def self.find_by_question_id(q_id)
        replies = QuestionsDatabase.instance.execute(<<-SQL, q_id)

        SELECT
            *
        FROM
            replies
        WHERE
            question_id = ?
        SQL

        return nil if replies.empty?
        replies.map { |r| Reply.new(r)}

    end

    def author
        User.find_by_author_id(@user_id)
    end

    def question
        Question.find_by_id(@question_id)
    end

    def parent_reply
        Reply.find_by_id(@reply_id)
    end

    def child_replies
        replies = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
            *
        FROM
            replies
        WHERE
            reply_id = ?
        SQL

        return nil if replies.empty?
        replies.map { |r| Reply.new(r)}
    end

    def save
        if @id,nil? 
            QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id)
                INSERT INTO
                    replies (user_id, question_id)
                VALUES
                    (?, ?)
            SQL

            @id = QuestionsDatabase.instance.last_insert_row_id
        else
            QuestionsDatabase.instance.execute(<<-SQL, @user_id, @question_id, @id)
                UPDATE
                    replies
                SET
                    user_id = ?, question_id = ?
                WHERE
                    id = ?
            SQL
        end
        
    end

end

class QuestionFollow
    attr_accessor :user_id, :question_id
    attr_reader :id

    def initialize(options)
        @id = options['id']
        @user_id = options['user_id']
        @question_id = options['question_id']
    end

    def self.all
        data = QuestionsDatabase.instance.execute('SELECT * FROM question_follows')
        data.map { |datum| QuestionFollow.new(datum)}
    end

    def self.find_by_id(id)
        follow = QuestionsDatabase.instance.execute(<<-SQL, id)
            SELECT
                *
            FROM
                question_follows
            WHERE
                id = ?
        SQL

        return nil if follow.empty?
        QuestionFollow.new(follow.first)
    end

    def self.followers_for_question_id(q_id)
        user_ids = QuestionsDatabase.instance.execute(<<-SQL, q_id)
            SELECT
                user_id
            FROM
                question_follows
            WHERE
                question_id = ?
        SQL

        return nil if user_ids.empty?
        user_ids.map { |id| User.find_by_id(id['user_id']) }
    end

    def self.followed_questions_for_user_id(user_id)
        follow_q = QuestionsDatabase.instance.execute(<<-SQL, user_id)
            SELECT
                question_id
            FROM
                question_follows
            WHERE
                user_id = ?
        SQL

        return nil if follow_q.empty?
        follow_q.map { |id| Question.find_by_id(id['question_id'])}
    end

    def self.most_followed_questions(n)
        most_followed_q = QuestionsDatabase.instance.execute(<<-SQL, n)
        SELECT
            question_id, COUNT(question_id)
        FROM
            question_follows
        GROUP BY
            question_id
        LIMIT ?
        SQL

        return nil if most_followed_q.empty?
        most_followed_q.map { |q| Question.find_by_id(q['question_id'])}
    end
end