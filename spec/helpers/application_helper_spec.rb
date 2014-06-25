require 'rails_helper'

RSpec.describe ApplicationHelper, :type => :helper do
  let(:stubbed_time) { Time.new(2012, 10, 31, 2, 2, 2, "+01:00") }

  context '#last_update' do
    it 'should show last_update for a person' do
      @person = double(:person, updated_at: stubbed_time)
      expect(last_update).to eql('Last updated: 31 Oct 2012.')
    end

    it 'should show last_update for a group' do
      @group = double(:group, updated_at: stubbed_time)
      expect(last_update).to eql('Last updated: 31 Oct 2012.')
    end

    it 'should not show last_update for a new person' do
      @person = double(:group, updated_at: nil)
      expect(last_update).to be_blank
    end
  end

  context '#govspeak' do
    it 'should render Markdown starting from h3' do
      source = "# Header\n\nPara para"
      fragment = Capybara::Node::Simple.new(govspeak(source))

      expect(fragment).to have_selector('h3', text: 'Header')
    end
  end
end
