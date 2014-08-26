require 'rails_helper'
RSpec.describe ReviewsController, type: :controller do
  before do
    authenticate_as(create(:user))
  end

  describe 'GET new' do
    it 'assigns a new review' do
      get :index
      expect(assigns(:review)).to be_a(Review)
    end

    it 'assigns existing reviews' do
      get :index
      expect(assigns(:reviews)).not_to be_nil
    end
  end

  describe 'POST create' do
    describe 'with valid params' do
      it 'creates a new Review' do
        expect {
          post :create, review: valid_attributes
        }.to change(Review, :count).by(1)
      end

      it 'redirects back to the index' do
        post :create, review: valid_attributes
        expect(response).to redirect_to(reviews_path)
      end
    end

    describe 'with invalid params' do
      before do
        post :create, review: { author_email: '' }
      end

      it 'assigns a newly created but unsaved review as @review' do
        expect(assigns(:review)).to be_a_new(Review)
      end

      it 're-renders the index template' do
        expect(response).to render_template('index')
      end
    end
  end

  def valid_attributes
    {
      relationship: 'Colleague',
      author_email: 'danny@example.com',
      author_name: 'Danny Boy'
    }
  end
end
