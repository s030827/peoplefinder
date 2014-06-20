class Person < ActiveRecord::Base
  has_paper_trail ignore: [:updated_at, :created_at, :id]
  acts_as_paranoid

  validates_presence_of :surname
  has_many :memberships, dependent: :destroy
  has_many :groups, through: :memberships

  def name
    [given_name, surname].compact.join(' ').strip
  end

  def to_s
    name
  end
end
