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
end