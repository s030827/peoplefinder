# frozen_string_literal: true

class PeopleNeverLoggedInQuery < BaseQuery
  def call
    @relation.where(login_count: 0)
  end
end
