# frozen_string_literal: true

require 'rails_helper'

describe 'Audit trail' do
  before do
    omni_auth_log_in_as_super_admin
  end

  it 'Auditing an edit of a person' do
    with_versioning do
      person = create(:person, surname: 'original surname')
      visit edit_person_path(person)
      fill_in 'Last name', with: 'something else'
      click_button 'Save', match: :first

      visit '/audit_trail'
      expect(page).to have_text('Person Edited')
      expect(page).to have_text('Surname changed from original surname to something else')

      click_button 'undo', match: :first

      person.reload
      expect(person.surname).to eq('original surname')
    end
  end

  it 'Auditing the deletion of a person' do
    with_versioning do
      person = create(:person, surname: 'Dan', given_name: 'Greg')
      visit person_path(person)
      click_delete_profile

      visit '/audit_trail'
      expect(page).to have_text('Deleted Person')
      expect(page).to have_text('Name: Greg Dan')

      expect do
        click_button 'undo', match: :first
      end.to change(Person, :count).by(1)
    end
  end

  it 'Auditing an edit of a group' do
    with_versioning do
      group = create(:group, name: 'original name')
      visit edit_group_path(group)
      fill_in 'Team name', with: 'something else'
      click_button 'Save', match: :first

      visit '/audit_trail'
      expect(page).to have_text('Group Edited')
      expect(page).to have_text('Name changed from original name to something else')
    end
  end

  it 'Auditing the creation of a group' do
    with_versioning do
      visit new_group_group_path(Group.department.id)
      fill_in 'Team name', with: 'Jon'
      click_button 'Save', match: :first

      visit '/audit_trail'
      expect(page).to have_text('New Group')
      expect(page).to have_text('Name set to: Jon')
    end
  end

  it 'Auditing the deletion of a group' do
    with_versioning do
      group = create(:group, name: 'original name')
      visit edit_group_path(group)
      click_link('Delete this team')

      visit '/audit_trail'
      expect(page).to have_text('Deleted Group')
      expect(page).to have_text('Name: original name')
    end
  end

  it 'Auditing the creation of a membership', js: true do
    create(:group, name: 'Digital Justice')
    person = create(:person, given_name: 'Bob', surname: 'Smith')
    person.memberships.destroy_all

    with_versioning do
      visit edit_person_path(person)
      select_in_team_select 'Digital Justice'
      within last_membership do
        fill_in 'Job title', with: 'Jefe'
      end
      click_button 'Save'
    end

    visit '/audit_trail'
    within('tbody tr:first-child') do
      expect(page).to have_text('New Membership')
      expect(page).to have_text('Person set to: Bob Smith')
      expect(page).to have_text('Team set to: Digital Justice')
      expect(page).to have_text('Job title set to: Jefe')
      expect(page).to have_text('Leader set to: No')
      expect(page).not_to have_button 'undo'
    end
  end

  # FIXME: works via app but not here
  it 'Auditing the deletion of a membership', skip: 'FIXME: works via app but not here' do
    group = create(:group, name: 'Digital Justice')
    person = create(:person, given_name: 'Joe', surname: 'Bob')
    person.memberships.destroy_all
    person.memberships.create(group: group, role: 'Jefe', leader: true)

    Timecop.freeze(1.day.from_now) do
      with_versioning do
        visit edit_person_path(person)
        within last_membership do
          click_link 'Leave team'
        end
        click_button 'Save'
      end
    end

    visit '/audit_trail'

    within('tbody tr:first-child') do
      expect(page).to have_text('Deleted Membership')
      expect(page).to have_text('Person was: Joe Bob')
      expect(page).to have_text('Team was: Digital Justice')
      expect(page).to have_text('Job title was: Jefe')
      expect(page).to have_text('Leader was: Yes')
      expect(page).not_to have_button 'undo'
    end
  end
end
