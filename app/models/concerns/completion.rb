# frozen_string_literal: true

# Queries must respond quickly so aggregation
# needs to be done on the DB for efficiency
#
module Concerns::Completion
  extend ActiveSupport::Concern
  include Concerns::BucketedCompletion

  ADEQUATE_FIELDS = %i[
    country
    city
    primary_phone_number
  ].freeze

  COMPLETION_FIELDS = ADEQUATE_FIELDS + %i[
    profile_photo_present?
    email
    given_name
    surname
    groups
  ]

  included do
    def completion_score
      self.class.average_completion_score(id)
    end

    def profile_photo_present?
      profile_photo_id || attributes['image']
    end

    def incomplete?
      completion_score < 100
    end

    def complete?
      !incomplete?
    end

    def needed_for_completion?(field)
      if field == :profile_photo_id
        !profile_photo_present?
      else
        COMPLETION_FIELDS.include?(field) && send(field).blank?
      end
    end
  end

  class_methods do
    def inadequate_profiles
      where(inadequate_profiles_sql)
        .order(:email)
    end

    def completion_score_calculation
      "(\nCOALESCE(#{completion_score_sum},0))::float/#{COMPLETION_FIELDS.size}"
    end

    def overall_completion
      average_completion_score
    end

    def average_completion_score(id = nil)
      results = ActiveRecord::Base.connection.execute(average_completion_sql(id))
      results.first[avg_alias].to_f.round
    end

    private

    def inadequate_profiles_sql
      sql = ADEQUATE_FIELDS.map do |f|
        "COALESCE(cast(#{f} AS text), '') = ''"
      end.join(' OR ')
      profile_photo_missing = "( COALESCE(cast(profile_photo_id AS text), '') = '' AND " \
        "COALESCE(cast(image AS text), '') = '' )"
      sql += " OR #{profile_photo_missing}"
      sql
    end

    def avg_alias
      'average_completion_score'
    end

    def average_completion_sql(id = nil)
      <<-SQL
        SELECT AVG(
        (
          #{completion_score_calculation}
        ) * 100)::numeric(5,2) AS #{avg_alias}
        FROM "people"
        #{where_people_in(id)}
      SQL
    end

    def where_people_in(id = nil)
      "WHERE id IN (#{[id].flatten.join(',')})" if id.present?
    end

    def completion_score_sum
      COMPLETION_FIELDS.map do |field|
        if field == :groups
          groups_exist_sql
        elsif field == :profile_photo_present?
          profile_photo_present_sql
        else
          "(CASE WHEN length(#{field}::varchar) > 0 THEN 1 ELSE 0 END) \n"
        end
      end.join(' + ')
    end

    # requires a join and therefore needs separate handling for scalability
    def groups_exist_sql
      <<-SQL
      CASE WHEN (SELECT 1
                  WHERE EXISTS (SELECT 1
                                FROM memberships m
                                WHERE m.person_id = people.id)) IS NOT NULL
            THEN 1
          ELSE 0
      END
      SQL
    end

    # account for legacy images as well
    def profile_photo_present_sql
      <<-SQL
      (CASE WHEN length(profile_photo_id::varchar) > 0 THEN 1
            WHEN length(image) > 0 THEN 1
            ELSE 0
      END)
      SQL
    end
  end
end
