require 'csv'
module Rapidfire
  class Survey < ApplicationRecord
    belongs_to :owner, :polymorphic => true
    has_many  :attempts
    has_many  :questions

    validates :name, :presence => true


    if Rails::VERSION::MAJOR == 3
      attr_accessible :name, :introduction, :after_survey_content
    end

    def self.csv_user_attributes=(attributes)
      @@csv_user_attributes = Array(attributes)
    end

    def self.csv_user_attributes
      @@csv_user_attributes || []
    end

    def results_to_csv(filter)
      CSV.generate do |csv|
        header = []
        header += Rapidfire::Survey.csv_user_attributes
        questions.each do |question|
          header << ActionView::Base.full_sanitizer.sanitize(question.question_text, :tags => [], :attributes => [])
        end
        header << "results updated at"
        csv << header
        attempts.where(SurveyResults.filter(filter, 'id')).each do |attempt|
          this_attempt = []

          Survey.csv_user_attributes.each do |attribute|
            this_attempt << attempt.user.try(attribute)
          end

          most_recent_answer_time = attempt.updated_at
          questions.each do |question|
            answer = attempt.answers.detect{|a| a.question_id == question.id }
            this_attempt << answer&.answer_text
            most_recent_answer_time = answer&.updated_at if answer && most_recent_answer_time < answer.updated_at
          end

          this_attempt << most_recent_answer_time

          this_attempt << attempt.updated_at
          csv << this_attempt
        end
      end
    end
  end
end
