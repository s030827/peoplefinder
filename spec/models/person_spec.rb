# frozen_string_literal: true

# == Schema Information
#
# Table name: people
#
#  id                                :integer          not null, primary key
#  given_name                        :text
#  surname                           :text
#  email                             :text
#  primary_phone_number              :text
#  secondary_phone_number            :text
#  location_in_building              :text
#  description                       :text
#  created_at                        :datetime
#  updated_at                        :datetime
#  works_monday                      :boolean          default(TRUE)
#  works_tuesday                     :boolean          default(TRUE)
#  works_wednesday                   :boolean          default(TRUE)
#  works_thursday                    :boolean          default(TRUE)
#  works_friday                      :boolean          default(TRUE)
#  image                             :string
#  slug                              :string
#  works_saturday                    :boolean          default(FALSE)
#  works_sunday                      :boolean          default(FALSE)
#  login_count                       :integer          default(0), not null
#  last_login_at                     :datetime
#  super_admin                       :boolean          default(FALSE)
#  city                              :text
#  secondary_email                   :text
#  profile_photo_id                  :integer
#  last_reminder_email_at            :datetime
#  current_project                   :string
#  pager_number                      :text
#  primary_phone_country_code        :text
#  building                          :string           default([]), is an Array
#  country                           :string
#  skype_name                        :string
#  key_skills                        :string           default([]), is an Array
#  language_fluent                   :text
#  language_intermediate             :text
#  grade                             :text
#  previous_positions                :text
#  learning_and_development          :string           default([]), is an Array
#  networks                          :string           default([]), is an Array
#  additional_responsibilities       :string           default([]), is an Array
#  other_uk                          :text
#  other_overseas                    :text
#  internal_auth_key                 :string
#  other_key_skills                  :string
#  other_learning_and_development    :string
#  other_additional_responsibilities :string
#  professions                       :string           default([]), is an Array
#  other_professions                 :string
#  secondary_phone_country_code      :text
#

require 'rails_helper'

RSpec.describe Person, type: :model do
  let(:person) { build(:person) }

  it { is_expected.to validate_presence_of(:given_name).on(:update) }
  it { is_expected.to validate_presence_of(:surname) }
  it { is_expected.to validate_presence_of(:ditsso_user_id) }
  it { is_expected.to validate_uniqueness_of(:ditsso_user_id) }
  it { is_expected.to validate_presence_of(:email) }
  it { is_expected.to have_many(:groups) }

  it { is_expected.to respond_to(:pager_number) }
  it { is_expected.to respond_to(:skip_group_completion_score_updates) }

  context 'test factory' do
    describe '#create(:person)' do
      let(:person) { create(:person) }

      it 'creates a valid person' do
        expect(person).to be_valid
      end

      it 'defaults team membership to department level' do
        expect(person.memberships.map(&:group)).to include Group.department
      end
    end
  end

  describe '#phone_number_variations' do
    subject do
      build(
        :person,
        primary_phone_number: phone_number,
        primary_phone_country_code: country_code
      )
    end

    let(:phone_number) { '0118 999-881 999 119 (725) ext. 3' }
    let(:country_code) { 'GB' }

    it 'returns the expected variatons' do
      expect(subject.phone_number_variations).to eq(
        %w[
          01189998819991197253
          441189998819991197253
        ]
      )
    end

    context 'when no country is provided' do
      let(:country_code) { nil }

      it 'returns only the country code-less variation' do
        expect(subject.phone_number_variations).to eq(
          %w[
            01189998819991197253
          ]
        )
      end
    end

    context 'when the phone number does not start with "0"' do
      let(:phone_number) { '123456' }

      it 'returns the expected variatons' do
        expect(subject.phone_number_variations).to eq(
          %w[
            123456
            44123456
            0123456
          ]
        )
      end
    end

    context 'when no phone number is provided' do
      let(:phone_number) { nil }

      it 'returns nil' do
        expect(subject.phone_number_variations).to be_nil
      end
    end
  end

  describe '#email' do
    it 'does not raise an invalid format error if blank' do
      person = build :person, email: ''
      expect(person.save).to be false
      expect(person.errors[:email]).to eq(['is required'])
    end

    it 'does raise an invalid format error if present but invalid' do
      person = build :person, email: 'sdsdsdsds'
      expect(person.save).to be false
      expect(person.errors[:email]).to eq(['isn’t valid'])
    end

    it 'is converted to lower case' do
      person = create(:person, email: 'User.Example@digital.justice.gov.uk')
      expect(person.email).to eq 'user.example@digital.justice.gov.uk'
    end
  end

  describe '#email_address_with_name' do
    it 'returns name and email' do
      person = create(:person, given_name: 'Sue', surname: 'Boe', email: 'User.Example@digital.justice.gov.uk')
      expect(person.email_address_with_name).to eq 'Sue Boe <user.example@digital.justice.gov.uk>'
    end
  end

  context 'who has never logged in' do
    before { person.save }

    it 'is returned by .never_logged_in' do
      expect(described_class.never_logged_in).to include(person)
    end

    it 'is not returned by .logged_in_at_least_once' do
      expect(described_class.logged_in_at_least_once).not_to include(person)
    end
  end

  context 'who has logged in' do
    before do
      person.login_count = 1
      person.save!
    end

    it 'is not returned by .never_logged_in' do
      expect(described_class.never_logged_in).not_to include(person)
    end

    it 'is returned by .logged_in_at_least_once' do
      expect(described_class.logged_in_at_least_once).to include(person)
    end
  end

  describe '.non_team_members' do
    before do
      person.memberships.build(group: create(:department))
      person.save!
    end

    it 'does not return people in one or more teams' do
      expect(described_class.non_team_members).not_to include(person)
    end

    it 'returns people in no team' do
      person.memberships.destroy_all
      expect(described_class.non_team_members).to include(person)
    end
  end

  describe '.department_members_in_other_teams' do
    before do
      person.save!
    end

    it 'returns people in department with no role who are also in another team' do
      person.memberships.create(group: create(:group, name: 'Technology'))
      expect(described_class.department_members_in_other_teams).to include(person)
    end

    it 'does not return people in no team' do
      person.memberships.destroy_all
      expect(described_class.department_members_in_other_teams).not_to include(person)
    end

    it 'does not return people only in one team' do
      expect(described_class.department_members_in_other_teams).not_to include(person)
    end

    it 'does not return people in department who are also in another team if they are the department leader' do
      person.memberships.find_by(group_id: Group.department).update(leader: true)
      person.memberships.create(group: create(:group, name: 'Technology'))
      expect(described_class.department_members_in_other_teams).not_to include(person)
    end

    it 'does not return people in department who are also in another team if they have a role in the department' do
      person.memberships.find_by(group_id: Group.department.id).update(role: 'SIRO for peoplefinder')
      person.memberships.create(group: create(:group, name: 'Technology'))
      expect(described_class.department_members_in_other_teams).not_to include(person)
    end

    it 'does not return people in multiple non-department teams' do
      person.memberships.destroy_all
      person.memberships.create(group: create(:group, name: 'Technology'))
      person.memberships.create(group: create(:group, name: 'Digital'))
      expect(described_class.department_members_in_other_teams).not_to include(person)
    end
  end

  describe '#department_memberships_with_no_role' do
    subject { person.department_memberships_with_no_role }

    before do
      person.save!
      person.memberships.create(group: create(:group, name: 'Technology'))
    end

    it 'returns AssociationRelation of memberships' do
      expect(subject).to be_kind_of ActiveRecord::AssociationRelation
      expect(subject.first).to be_kind_of Membership
    end

    it 'returns department memberships only' do
      expect(subject.map(&:group)).to eql [Group.department]
    end

    it 'returns department memberships with no role' do
      expect(subject.count).to be 1
      expect(subject.map(&:role)).to eq [nil]
    end

    it 'treats whitespace only roles as null' do
      person.memberships.find_by(group_id: Group.department.id).update(role: ' ')
      expect(subject.count).to be 1
      expect(subject.map(&:role)).to eq [' ']
    end
  end

  describe '#name' do
    context 'with a given_name and surname' do
      let(:person) { build(:person, given_name: 'Jon', surname: 'von Brown') }

      it 'concatenates given_name and surname' do
        expect(person.name).to eql('Jon von Brown')
      end
    end

    context 'with a surname only' do
      let(:person) { build(:person, given_name: '', surname: 'von Brown') }

      it 'uses the surname' do
        expect(person.name).to eql('von Brown')
      end
    end

    context 'with surname containing digit' do
      let(:person) { build(:person, given_name: 'John', surname: 'Smith2') }

      it 'removes digit' do
        person.valid?
        expect(person.name).to eql('John Smith')
      end
    end
  end

  describe '.all_in_subtree' do
    let!(:team) { create(:group) }
    let!(:subteam) { create(:group, parent: team) }

    it 'calls PeopleInGroupsQuery with group subtrees' do
      query = double PeopleInGroupsQuery
      expect(PeopleInGroupsQuery).to receive(:new).with(team.subtree_ids).and_return(query)
      expect(query).to receive(:call)
      described_class.all_in_subtree(team)
    end

    it 'returns a ActiveRecord::Relation' do
      expect(described_class.all_in_subtree(team)).to be_a(ActiveRecord::Relation)
    end

    it 'returns relation that includes aggregate role_names column' do
      expect { described_class.all_in_subtree(team).pluck(:role_names) }.not_to raise_error
    end
  end

  describe '.all_in_groups' do
    let(:groups) { create_list(:group, 3) }
    let(:people) { create_list(:person, 3) }

    it 'returns all people in any listed groups and .count_in_groups returns correct count' do
      people.zip(groups).each do |person, group|
        create :membership, person: person, group: group
      end
      group_ids = groups.take(2)
      result = described_class.all_in_groups(group_ids)
      expect(result).to include(people[0])
      expect(result).to include(people[1])
      expect(result).not_to include(people[2])

      count = described_class.count_in_groups(group_ids)
      expect(count).to eq(2)

      count = described_class.count_in_groups(group_ids, excluded_group_ids: groups.take(1))
      expect(count).to eq(1)
    end

    it 'concatenates all roles alphabetically with commas' do
      create :membership, person: people[0], group: groups[0], role: 'Prison chaplain'
      create :membership, person: people[0], group: groups[1], role: 'Head of crime'
      result = described_class.all_in_groups(groups.take(2))
      expect(result[0].role_names).to eq('Head of crime, Prison chaplain')
    end

    it 'omits blank roles' do
      create :membership, person: people[0], group: groups[0], role: 'Prison chaplain'
      create :membership, person: people[0], group: groups[1], role: ''
      result = described_class.all_in_groups(groups.take(2))
      expect(result[0].role_names).to eq('Prison chaplain')
    end

    it 'includes each person only once' do
      create :membership, person: people[0], group: groups[0], role: 'Prison chaplain'
      create :membership, person: people[0], group: groups[1], role: 'Head of crime'
      result = described_class.all_in_groups(groups.take(2))
      expect(result.length).to eq(1)
    end
  end

  context '#slug' do
    it 'generates from the first part of the email address if present' do
      person = create(:person, email: 'user.example@digital.justice.gov.uk')
      person.reload
      expect(person.slug).to eql(Digest::SHA1.hexdigest('user.example'))
    end
  end

  context 'search' do
    it 'deletes indexes' do
      expect(described_class.__elasticsearch__).to receive(:delete_index!)
        .with(index: 'test_people')
      described_class.delete_indexes
    end
  end

  context 'elasticsearch indexing helpers' do
    before do
      person.save!
      digital_services = create(:group, name: 'Digital Services')
      estates = create(:group, name: 'Estates')
      person.memberships.create(group: estates, role: 'Cleaner')
      person.memberships.create(group: digital_services, role: 'Designer')
    end

    it 'writes the role and group as a string' do
      expect(person.role_and_group).to match(/Digital Services, Designer/)
      expect(person.role_and_group).to match(/Estates, Cleaner/)
    end
  end

  context 'group member completion score update' do
    include ActiveJob::TestHelper

    let(:person) { build(:person) }
    let!(:digital_services) { create(:group, name: 'Digital Services') }

    before do
      person.save!
      person.memberships.create(group: digital_services, role: 'Service Assessments Lead')
      person.save!
      person.primary_phone_number = '00222'
      clear_enqueued_jobs
    end

    it 'enqueues the UpdateGroupMembersCompletionScoreJob' do
      expect { person.save! }.to have_enqueued_job(UpdateGroupMembersCompletionScoreJob).with(digital_services)
    end
  end

  context 'with two memberships in the same group' do
    before do
      person.save!
      person.memberships.destroy_all
      digital_services = create(:group, name: 'Digital Services')
      person.memberships.create(group: digital_services, role: 'Service Assessments Lead')
      person.memberships.create(group: digital_services, role: 'Head of Delivery')
      person.reload
    end

    it 'allows updates to those memberships' do
      membership = person.memberships.first
      expect(membership.leader).to be false

      membership_attributes = membership.attributes
      person.assign_attributes(
        memberships_attributes: {
          membership_attributes[:id] => membership_attributes.merge(leader: true)
        }
      )
      person.save!
      updated_membership = person.reload.memberships.find(membership.id)
      expect(updated_membership.leader).to be true
    end

    it 'fires UpdateGroupMembersCompletionScoreJob for group on save' do
      expect(UpdateGroupMembersCompletionScoreJob).to receive(:perform_later).with(person.groups.first)
      person.save
    end
  end

  describe '#all_changes' do
    subject { person.all_changes }

    let(:ds) { create(:group, name: 'Digital Services') }
    let(:csg) { create(:group, name: 'Corporate Services Group') }
    let(:membership) { person.memberships.frst }

    before do
      person.assign_attributes(mass_assignment_params)
      person.save!
    end

    context 'adding a membership' do
      let(:mass_assignment_params) do
        {
          email: 'changed.user@digital.justice.gov.uk',
          works_monday: false,
          works_saturday: true,
          profile_photo_id: 2,
          description: 'changed info',
          memberships_attributes: {
            '0' => {
              role: 'Service Assessments Lead',
              group_id: ds.id,
              leader: true,
              subscribed: false
            }
          }
        }
      end

      let(:valid_membership_changes) do
        {
          "membership_#{ds.id}".to_sym =>
            {
              group_id: [nil, ds.id],
              role: [nil, 'Service Assessments Lead'],
              leader: [false, true],
              subscribed: [true, false]
            }
        }
      end

      it 'stores addition of a membership' do
        expect(subject).to include valid_membership_changes
      end
    end
  end

  context '#path' do
    let(:person) { described_class.new }

    context 'when there are no memberships' do
      it 'contains only itself' do
        expect(person.path).to eql([person])
      end
    end

    context 'when there is one membership' do
      it 'contains the group path' do
        group_a = build(:group)
        group_b = build(:group)
        allow(group_b).to receive(:path) { [group_a, group_b] }
        person.groups << group_b
        expect(person.path).to eql([group_a, group_b, person])
      end
    end

    context 'when there are multiple group memberships' do
      let(:groups) { 4.times.map { build(:group) } }

      before do
        allow(groups[1]).to receive(:path) { [groups[0], groups[1]] }
        allow(groups[3]).to receive(:path) { [groups[2], groups[3]] }
        person.groups << groups[1]
        person.groups << groups[3]
      end

      it 'uses the first group path' do
        expect(person.path).to eql([groups[0], groups[1], person])
      end
    end
  end

  describe '#phone' do
    let(:person) { create(:person) }
    let(:primary_phone_number) { '0207-123-4567' }
    let(:secondary_phone_number) { '0208-999-8888' }

    context 'with a primary and secondary phone' do
      before do
        person.primary_phone_number = primary_phone_number
        person.secondary_phone_number = secondary_phone_number
      end

      it 'uses the primary phone number' do
        expect(person.phone).to eql(primary_phone_number)
      end
    end

    context 'with a blank primary and a valid secondary phone' do
      before do
        person.primary_phone_number = ''
        person.secondary_phone_number = secondary_phone_number
      end

      it 'uses the secondary phone number' do
        expect(person.phone).to eql(secondary_phone_number)
      end
    end
  end

  describe '#location' do
    it 'concatenates location_in_building, location, and city' do
      person.location_in_building = '99.99'
      person.building = '102 Petty France'
      person.city = 'London'
      expect(person.location).to eq('99.99, London')
    end

    it 'skips blank fields' do
      person.location_in_building = 'At home'
      person.building = ''
      person.city = nil
      expect(person.location).to eq('At home')
    end
  end

  describe 'valid?' do
    it 'is false when email invalid' do
      person.email = 'bad'
      expect(person.valid?).to be false
      expect(person.errors.messages[:email]).to eq ['isn’t valid']
    end

    it 'is true when email valid' do
      person.email = 'test@digital.justice.gov.uk'
      expect(person.valid?).to be true
    end
  end

  describe '#notify_of_change?' do
    it 'is true if there is no reponsible person' do
      expect(person.notify_of_change?(nil)).to be true
    end

    it 'is false if the reponsible person is this person' do
      expect(person.notify_of_change?(person)).to be false
    end

    it 'is true if the reponsible person is a third party' do
      other_person = build(:person)
      expect(person.notify_of_change?(other_person)).to be true
    end
  end

  describe '#profile_image' do
    context 'when there is a profile photo' do
      it 'delegates to the profile photo' do
        profile_photo = create(:profile_photo)
        person.profile_photo = profile_photo
        expect(person.profile_image).to eq(profile_photo.image)
      end
    end

    context 'when there is a legacy image but no profile photo' do
      it 'returns the mounted uploader' do
        person.assign_attributes image: 'cats.gif'
        expect(person.profile_image).to be_kind_of(ImageUploader)
      end
    end

    context 'when there is no image' do
      it 'returns nil' do
        person.assign_attributes image: nil
        expect(person.profile_image).to be_nil
      end
    end
  end

  describe '#last_reminder_email_at' do
    it 'is nil on create' do
      expect(person.last_reminder_email_at).to be_nil
    end

    it 'can be set to a datetime' do
      datetime = Time.now.in_time_zone
      person.last_reminder_email_at = datetime
      expect(person.last_reminder_email_at).to eq(datetime)
    end
  end

  describe '#reminder_email_sent? within 30 days' do
    it 'is false on create' do
      expect(person.reminder_email_sent?(within: 30.days)).to be false
    end

    it 'is true when last_reminder_email_at is today' do
      person.last_reminder_email_at = Time.now.in_time_zone
      expect(person.reminder_email_sent?(within: 30.days)).to be true
    end

    it 'is true when last_reminder_email_at is 30 days ago' do
      person.last_reminder_email_at = Time.now.in_time_zone - 30.days
      expect(person.reminder_email_sent?(within: 30.days)).to be true
    end

    it 'is false when last_reminder_email_at is 31 days ago' do
      person.last_reminder_email_at = Time.now.in_time_zone - 31.days
      expect(person.reminder_email_sent?(within: 30.days)).to be false
    end
  end

  describe '#skip_group_completion_score_updates' do
    before do
      digital_services = create(:group, name: 'Digital Services')
      person.memberships.build(group: digital_services)
      person.skip_group_completion_score_updates = true
    end

    it 'prevents enqueuing of group completion score update job for bulk upload purposes' do
      expect(UpdateGroupMembersCompletionScoreJob).not_to receive(:perform_later)
      person.save
    end
  end

  describe '#primary_phone_country' do
    it 'returns an instance of ISO3166::Country when a value is present' do
      person.primary_phone_country_code = 'GB'

      expect(person.primary_phone_country).to eq(ISO3166::Country.new('GB'))
    end

    it 'returns nil when a value is not present' do
      person.primary_phone_country_code = nil

      expect(person.primary_phone_country).to be_nil
    end
  end
end
