# frozen_string_literal: true

require 'rails_helper'

describe 'Search results page' do
  subject(:search_page) { Pages::Search.new }

  def create_test_data
    clean_up_indexes_and_tables
    create(:group, name: 'HMP Browne')
    create(:group, name: 'SMT Browne')
    create(:person, given_name: 'Jim', surname: 'Browne')
    create(:person, given_name: 'Jon', surname: 'Browne')
    Person.import force: true
    Person.__elasticsearch__.refresh_index!
  end

  before do
    create_test_data
    omni_auth_log_in_as '007'
    visit '/'
  end

  describe 'structure' do
    before { click_button 'Search' }

    it { is_expected.to be_displayed }

    it 'has search bar' do
      expect(subject).to have_search_form
      expect(search_page.search_form).to be_all_there
    end

    it 'has search result summary' do
      expect(subject).to have_search_result_summary
    end

    it 'has search filter sidebar' do
      expect(subject).to have_search_filters_form
      expect(search_page.search_filters_form).to be_all_there
    end

    it 'has search results' do
      expect(subject).to have_search_results
    end
  end

  describe 'filtering', js: true do
    before do
      fill_in 'query', with: 'browne'
      page.execute_script("$('form#mod-search-form').submit()")
    end

    it 'defaults to searching people and teams' do
      expect(search_page.search_form.search_field.value).to eq 'browne'
      expect(search_page.search_result_summary).to have_text('people (2) and teams (2)')
      expect(search_page.search_results).to have_people_results count: 2
      expect(search_page.search_results).to have_team_results count: 2
      expect(search_page.search_results.people_result_names).to include 'Jon Browne', 'Jim Browne'
      expect(search_page.search_results.team_result_names).to include 'HMP Browne', 'SMT Browne'
    end

    it 'on people', js: true do
      uncheck 'Teams'
      expect(search_page.search_result_summary).to have_text('2 results from people')
      expect(search_page.search_results).to have_people_results count: 2
      expect(search_page.search_results).to have_team_results count: 0
      expect(search_page.search_results.people_result_names).to include 'Jon Browne', 'Jim Browne'
    end

    it 'on teams', js: true do
      uncheck 'People'
      expect(search_page.search_result_summary).to have_text('browne not found - 2 similar results from teams')
      expect(search_page.search_results).to have_people_results count: 0
      expect(search_page.search_results).to have_team_results count: 2
      expect(search_page.search_results.team_result_names).to include 'HMP Browne', 'SMT Browne'
    end

    it 'on none', js: true do
      uncheck 'People'
      uncheck 'Teams'
      expect(search_page.search_result_summary).to have_text('browne not found - 0 similar results')
      expect(search_page.search_results).to have_people_results count: 0
      expect(search_page.search_results).to have_team_results count: 0
    end
  end
end
