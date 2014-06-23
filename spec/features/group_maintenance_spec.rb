require 'rails_helper'

feature "Group maintenance" do
  before do
    log_in_as 'test.user@digital.justice.gov.uk'
  end

  scenario "Creating a top-level department" do
    name = "Ministry of Justice"

    visit new_group_path
    fill_in "Name", with: name
    click_button "Create Group"

    dept = Group.find_by_name(name)
    expect(dept.name).to eql(name)
    expect(dept.parent).to be_nil
  end

  scenario "Creating an organisation inside the department" do
    dept = create(:group, name: "Ministry of Justice")

    visit group_path(dept)
    click_link "Add organisation"

    name = "CSG"
    fill_in "Name", with: name
    select dept.name, from: "Parent"
    click_button "Create Group"

    org = Group.find_by_name(name)
    expect(org.name).to eql(name)
    expect(org.parent).to eql(dept)
  end

  scenario "Creating a team inside an organisation from the organisation's page" do
    dept = create(:group, name: "Ministry of Justice")
    org = create(:group, parent: dept)

    visit group_path(org)
    click_link "Add team"

    name = "Digital Services"
    fill_in "Name", with: name
    click_button "Create Group"

    team = Group.find_by_name(name)
    expect(team.name).to eql(name)
    expect(team.parent).to eql(org)
  end

  scenario 'Deleting a group softly' do
    membership = create(:membership)
    group = membership.group
    visit edit_group_path(group)
    click_link('Delete this record')

    expect { Group.find(group) }.to raise_error(ActiveRecord::RecordNotFound)
    expect { Membership.find(membership) }.to raise_error(ActiveRecord::RecordNotFound)

    expect(Group.with_deleted.find(group)).to eql(group)
    expect(Membership.with_deleted.find(membership)).to eql(membership)
  end

  scenario "Editing a group" do
    dept = create(:group, name: "Ministry of Justice")
    org = create(:group, name: "CSG", parent: dept)
    group = create(:group, name: "Digital Services", parent: org)

    visit group_path(group)
    click_link "Edit"

    new_name = "Cyberdigital Cyberservices"
    fill_in "Name", with: new_name
    select dept.name, from: "Parent"
    click_button "Update Group"

    group.reload
    expect(group.name).to eql(new_name)
    expect(group.parent).to eql(dept)
  end
end
