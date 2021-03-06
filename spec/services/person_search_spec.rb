# frozen_string_literal: true

require 'rails_helper'
require_relative 'shared_examples_for_search'

RSpec.describe PersonSearch, elastic: true do
  before(:all) do
    clean_up_indexes_and_tables
    @alice = create(:person, given_name: 'Alice', surname: 'Andrews', current_project: 'digital project')
    @bob = create(:person, given_name: 'Bob', surname: 'Browning',
                           location_in_building: '10th floor', building: '102 Petty France',
                           city: 'London', description: 'weekends only',
                           current_project: 'Current project',
                           language_fluent: 'Spanish, Italian',
                           language_intermediate: 'Hindi',
                           key_skills: ['interviewing'],
                           other_learning_and_development: ['foolishness'])
    @andrew = create(:person, given_name: 'Andrew', surname: 'Alice')
    @abraham_kiehn = create(:person, given_name: 'Abraham', surname: 'Kiehn')
    @abe = create(:person, given_name: 'Abe', surname: 'Predovic')
    @oleary = create(:person, given_name: 'Denis', surname: "O'Leary")
    @oleary2 = create(:person, given_name: 'Denis', surname: 'O’Leary')
    @collier = create(:person, given_name: 'John', surname: 'Collier')
    @miller = create(:person, given_name: 'John', surname: 'Miller')
    @scotti = create(:person, given_name: 'John', surname: 'Scotti')
    digital_services = create(:group, name: 'Digital Services')
    @bob.memberships.create(group: digital_services, role: 'Digital Director')
    @john_duplicato1 = create(:person, given_name: 'John', surname: 'Duplicato', email: 'john.duplicato@digital.justice.gov.uk')
    @john_duplicato2 = create(:person, given_name: 'John', surname: 'Duplicato', email: 'john.duplicato2@digital.justice.gov.uk')

    @john_smith = create(:person, given_name: 'John', surname: 'Smith')
    @jonathan_smith = create(:person, given_name: 'Jonathan', surname: 'Smith')

    @john_smyth = create(:person, given_name: 'John', surname: 'Smyth')
    create(:membership, person: @john_smyth, group: digital_services, role: 'Content')

    @peter_smithson = create(:person, given_name: 'Peter', surname: 'Smithson')
    @pete_smithson = create(:person, given_name: 'Pete', surname: 'Smithson')
    @peter_smithson_pa = create(:person, given_name: 'Harold', surname: 'Jone', description: 'PA to Peter Smithson')

    @steve_richards = create(:person, given_name: 'Steve', surname: 'Richards', current_project: 'PF')
    @steven_richards = create(:person, given_name: 'Steven', surname: 'Richards')
    @stephen_richards = create(:person, given_name: 'Stephen', surname: 'Richards')
    @steve_richardson = create(:person, given_name: 'Steve', surname: 'Richardson')
    @steven_richardson = create(:person, given_name: 'Steven', surname: 'Richardson')
    @stephen_richardson = create(:person, given_name: 'Stephen', surname: 'Richardson')
    @john_richards = create(:person, given_name: 'John', surname: 'Richards')
    @steve_edmundson = create(:person, given_name: 'Steve', surname: 'Edmundson')
    @stephen_edmundson = create(:person, given_name: 'Stephen', surname: 'Edmundson')
    @john_richardson = create(:person, given_name: 'John', surname: 'Richardson')
    @john_edmundson = create(:person, given_name: 'John', surname: 'Edmundson') # should not appea
    @jane_medurst = create(:person, given_name: 'Jane', surname: 'Medurst')

    @maurice = create(
      :person,
      given_name: 'Maurice',
      surname: 'Moss',
      primary_phone_country_code: 'GB',
      primary_phone_number: '0118(999)881-999 119 725 ext. 3'
    )

    Person.import force: true
    Person.__elasticsearch__.refresh_index!
  end

  after(:all) do
    clean_up_indexes_and_tables
  end

  context 'with some people' do
    it_behaves_like 'a search'

    it 'searches by email' do
      results = search_for(@alice.email.upcase)
      expect(results.set.first.name).to eq @alice.name
      expect(results.contains_exact_match).to eq true
    end

    it 'searches by phone number' do
      results = search_for('+44 118 999-881 (999) 119 725 3')
      expect(results.set.first.name).to eq @maurice.name
      expect(results.contains_exact_match).to eq(true)
    end

    it 'searches by surname' do
      results = search_for('Andrews')
      expect(results.set.map(&:name)).to match_array [@alice.name, @andrew.name]
      expect(results.contains_exact_match).to eq true
    end

    it 'searches by given name' do
      results = search_for('Alice')
      expect(results.set.map(&:name)).to match_array [@alice.name, @andrew.name]
      expect(results.contains_exact_match).to eq true
    end

    it 'searches by full name' do
      results = search_for('Bob Browning')
      expect(results.set.map(&:name)).not_to include(@alice.name)
      expect(results.set.map(&:name)).to include(@bob.name)
      expect(results.contains_exact_match).to eq true
    end

    it 'copes with two people having the same name' do
      results = search_for('John Duplicato')
      expect(results.set.map(&:email).first(2)).to match_array [@john_duplicato1.email, @john_duplicato2.email]
      expect(results.contains_exact_match).to eq true
    end

    it 'searches by single word non-name match' do
      results = search_for('Digital')
      expect(results.set.map(&:name)).to match_array [@alice.name, @bob.name, @john_smyth.name]
      expect(results.contains_exact_match).to eq true
    end

    xit 'puts name synonym matches in results' do
      results = search_for('Abe Kiehn')
      expect(results.set.map(&:name)).to match_array [@abraham_kiehn.name, @abe.name]
      expect(results.contains_exact_match).to eq false
    end

    it 'puts single name match at top of results when name synonym' do
      results = search_for('Abe')
      expect(results.set.first.name).to eq @abe.name
      expect(results.contains_exact_match).to eq true
    end

    it 'searches by group name and membership role' do
      results = search_for('Director at digiTAL Services')
      expect(results.set.map(&:name)).to include(@bob.name, @john_smyth.name)
      expect(results.contains_exact_match).to eq false
    end

    it 'searches by description, current_project, group and role ' do
      results = search_for('Digital Project')
      expect(results.set.map(&:name)).to include(@bob.name, @john_smyth.name)
      expect(results.contains_exact_match).to eq true
    end

    it 'searches by language_fluent' do
      results = search_for('Spanish')
      expect(results.set.map(&:name)).to include(@bob.name)
      expect(results.contains_exact_match).to eq true
    end

    it 'searches by language_intermediate' do
      results = search_for('Hindi')
      expect(results.set.map(&:name)).to include(@bob.name)
      expect(results.contains_exact_match).to eq true
    end

    it 'searches by key skills' do
      results = search_for('Interviewing')
      expect(results.set.map(&:name)).to include(@bob.name)
      expect(results.contains_exact_match).to eq true
    end

    it 'searches by learning and development interest' do
      results = search_for('Foolishness')
      expect(results.set.map(&:name)).to include(@bob.name)
      expect(results.contains_exact_match).to eq true
    end

    xit 'searches by location' do
      results = search_for('petty france')
      expect(results.set.map(&:name)).not_to include(@alice.name)
      expect(results.set.map(&:name)).to include(@bob.name)
    end

    xit 'searches by description, location' do
      results = search_for('weekends only petty france office')
      expect(results.set.map(&:name)).not_to include(@alice.name)
      expect(results.set.map(&:name)).to include(@bob.name)
    end

    xit 'searches ignoring * in search term' do
      # TODO: Results seems to always be 1, looks like it's random whether it returns
      #       Andrew Alice or Alice Andrews
      results = search_for('Alice *')
      expect(results.set.map(&:name)).to include(@alice.name)
      expect(results.contains_exact_match).to eq true
    end

    it 'searches ignoring " at start of search term' do
      results = search_for('"Alice ')
      expect(results.set.map(&:name)).to include(@alice.name)
      expect(results.contains_exact_match).to eq true
    end

    it 'searches ignoring " at end of search term' do
      results = search_for('Alice"')
      expect(results.set.map(&:name)).to include(@alice.name)
      expect(results.contains_exact_match).to eq true
    end

    xit 'searches ignoring " in middle of search term' do
      results = search_for('Alice" Andrews')
      expect(results.set.map(&:name)).to include(@alice.name)
      expect(results.contains_exact_match).to eq true
    end

    it 'searches apostrophe in name' do
      results = search_for("O'Leary")
      expect(results.set.first.name).to include(@oleary.name)
      expect(results.contains_exact_match).to eq true

      results = search_for('O’Leary')
      expect(results.set.first.name).to include(@oleary2.name)
      expect(results.contains_exact_match).to eq true
    end

    it 'returns [] for blank search' do
      results = search_for('')
      expect(results.set).to eq([])
      expect(results.contains_exact_match).to eq false
    end
  end

  context 'with symbol characters in search query' do
    it 'replaces commas with single whitespace and strips whitespace from ends' do
      search_for(',Smith,Bill,') do |searcher|
        expect(searcher.query).to eql 'Smith Bill'
      end
    end
    it 'replaces all other non-alpha-numeric characters as single whitespace' do
      search_for('\Smith\?Bill*&£23@%') do |searcher|
        expect(searcher.query).to eql 'Smith Bill 23'
      end
    end
  end

  describe 'Search weighting' do
    describe 'Steve\'s Scenario' do
      subject(:results) { search_for(query) }

      context 'search for given and last name' do
        let(:query) { 'Steve Richards' }

        let(:expected_steves) do
          @expected_steves = [
            @steve_richards,
            @steven_richards,
            @stephen_richards,
            @steve_richards_pa,
            @steve_richardson,
            @steven_richardson,
            @stephen_richardson,
            @john_richards
          ].map(&:name)
        end

        it 'test has expected records and ES index documents' do
          expect(Person.count).to be 31
          expect(Person.search('*').results.total).to be 31
        end
      end

      context 'search for given name only' do
        let(:query) { 'Steve' }
        let(:expected_steves) { %w[Steve Steven Stephen] }

        xit 'returns people in order of given names distance from exact name' do
          actual_steves = results.set.map(&:name).map(&:split).map(&:first).uniq
          expect(actual_steves).to match_array expected_steves
          expect(actual_steves.last).to eql expected_steves.last
        end
      end

      context 'search for surname only' do
        let(:query) { 'Richards' }
        let(:expected_richards) { %w[John Steven Stephen Steve] }

        # given name order is unhandled by code
        it 'returns people with only the surname richards in their' do
          actual_richards = results.set.map(&:name).map(&:split).map(&:first).uniq
          expect(actual_richards).to match_array expected_richards
        end
      end
    end
  end

  def results_struct
    SearchResults.new
  end

  def search_for(query)
    searcher = described_class.new(query, results_struct)
    results = searcher.perform_search
    yield searcher if block_given?
    results
  end
end
