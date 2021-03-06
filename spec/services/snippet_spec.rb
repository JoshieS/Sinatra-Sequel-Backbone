require File.dirname(__FILE__) + '/../spec_helper'

describe Snippet do
  before(:each) do
    @user = User.new(:name => 'SnippetMan',
                     :email=>'SnippetMan@gmail.com',
                     :password=>'123456',
                     :password_confirmation=>'123456').save
    @snippet = Snippet.new(:filename=>'file.js',
                           :body=>'lorem',
                           :user_id=>1).save
  end
  context 'get all snippet' do
    it 'should return 200' do
      get '/api/snippet/'

      expect(last_response.status).to eq 200
    end
  end
  context 'get pagination of snippets' do
    it 'should return 200' do
      get '/api/snippet/?page=2'

      expect(last_response.status).to eq 404
    end
    it 'should return 200' do
      get '/api/snippet/?page=1'

      expect(last_response.status).to eq 200
    end
    context 'get pagination with comments and likes counted' do
      before :each do
        @user_comment = User.new(:name => 'Audrey',
                                 :email=>'Audrey@gmail.com',
                                 :image_profile=>'img.png',
                                 :password=>'123456',
                                 :password_confirmation=>'123456').save
        @user_like = User.new(:name => 'Charly',
                                 :email=>'Charly@gmail.com',
                                 :image_profile=>'img.png',
                                 :password=>'123456',
                                 :password_confirmation=>'123456').save
      end
      it 'should the first snippet have 2 comments and 0 likes' do

        2.times {
          @user_comment.add_comment_snippet(:title=>'The sad code',
                                            :body=>'Sad', :line_code=>2,
                                            :snippet_id=>@snippet.id)
        }

        get '/api/snippet/?page=1'


        expect(JSON.parse(last_response.body)[0]['comment_count']).to eq 2
        expect(JSON.parse(last_response.body)[0]['like_count']).to eq 0
      end
      it 'should the first snippet have 3 comments and 2 likes' do

        @snippet_2 = Snippet.new(:filename=>'file.js',
                               :body=>'lorem',
                               :user_id=>1).save

        3.times {
          @user_comment.add_comment_snippet(:title=>'The sad code',
                                            :body=>'Sad', :line_code=>2,
                                            :snippet_id=>@snippet_2.id)
        }

        2.times {
          @user_like.add_like_snippet(:snippet_id=>@snippet_2.id)
        }

        get '/api/snippet/?page=1'

        expect(JSON.parse(last_response.body)[1]['comment_count']).to eq 0
        expect(JSON.parse(last_response.body)[1]['like_count']).to eq 0
        expect(JSON.parse(last_response.body)[0]['comment_count']).to eq 3
        expect(JSON.parse(last_response.body)[0]['like_count']).to eq 2
      end
    end
  end
  context 'get snippet by id' do
    it 'should response a user' do
      get '/api/snippet/1'

      expect(JSON.parse(last_response.body)['filename']).to eq 'file.js'
      expect(last_response.status).to eq 200
    end
    it 'should not found the resource' do
      get '/api/snippet/2'

      expect(JSON.parse(last_response.body)['response']).to eq 'Resource no found'
      expect(last_response.status).to eq 404
    end
  end
  context 'create snippet' do

    let(:route) {'/api/snippet/?filename=carlos.js&body=lorem&user_id=1'}

    it 'should create 1 snippet' do

      1.times { post route }

      expect(last_response.status).to eq 200
      expect(Snippet.all.count).to eq 2
    end
    it 'should create 2 snippets' do

      2.times { post route }

      expect(last_response.status).to eq 200
      expect(Snippet.all.count).to eq 3
    end
  end
  context 'edit snippet' do

    let(:route_id_false) {'/api/snippet/2?filename=lorem.py&body=vendetta'}
    let(:route_id_true) {'/api/snippet/1?filename=lorem.py&body=vendetta'}
    let(:route_params_empty) {'/api/snippet/1?filename=&body='}

    it 'Pass an id that does not exist ' do
      put route_id_false

      expect(JSON.parse(last_response.body)['response']).to eq 'Resource no found'
      expect(last_response.status).to eq 404
    end
    it 'Pass and body and title empty' do
      put route_params_empty

      expect(JSON.parse(last_response.body)['response']).to eq 'Any parameter are empty or null'
      expect(last_response.status).to eq 422
    end
    it 'Pass correct route' do
      put route_id_true

      expect(JSON.parse(last_response.body)['filename']).to eq 'lorem.py'
      expect(Snippet[1].filename).to eq 'lorem.py'
      expect(last_response.status).to eq 200
    end
  end
  context 'delete snippet by id' do
    it 'should delete 1 snippet' do
      delete '/api/snippet/1'

      expect(JSON.parse(last_response.body)['response']).to eq('Resources deleted: 1')
      expect(last_response.status).to eq 200
      expect(Snippet.all.count).to eq 0
    end
  end
  context 'delete snippet by id array' do
    before :each do
      3.times { |n|
        Snippet.new(:filename=>'file.js', :body=>'lorem', :user_id=>1).save
      }
    end
    it 'should delete 4 users' do
      delete '/api/snippet/1,2,3,4'

      expect(JSON.parse(last_response.body)['response']).to eq('Resources deleted: 4')
      expect(last_response.status).to eq 200
      expect(Snippet.all.count).to eq 0
    end
  end
  describe 'Snippet Comments' do
    before :each do
      @user_comment = User.new(:name => 'SuperMan',
                               :image_profile=>'img.png',
                               :email=>'SuperMan@gmail.com',
                               :password=>'123456',
                               :password_confirmation=>'123456').save
    end
    context 'get all comments of snippet' do
      before :each do
        3.times { @user_comment.add_comment_snippet(:body=>'Sad', :line_code=>2, :snippet_id=>@snippet.id) }
      end
      it 'should return 2 comments' do
        get 'api/snippet/1/comment'

        expect(JSON.parse(last_response.body).count).to eq 3
        expect(last_response.status).to eq 200
      end
    end
    context 'create comment snippet' do

      let(:route_true) {'/api/snippet/1/comment?body=aaaaaaaa&title=lorem&user_id=2&line_code=15'}
      let(:route_snippet_false) {'/api/snippet/2/comment?body=aaaaaaaa&title=lorem&user_id=2&line_code=15'}
      let(:route_user_false) {'/api/snippet/2/comment?body=aaaaaaaa&title=lorem&user_id=5&line_code=15'}

      context 'pass routes correctly' do
        it 'should create' do
          post route_true

          expect(CommentSnippet.where(:snippet_id=>1).count).to eq 1
        end
      end
      context 'pass routes with id snippet false' do
        it 'should no created and 404' do
          post route_snippet_false

          expect(JSON.parse(last_response.body)['response']).to eq 'Resource no found'
          expect(CommentSnippet.where(:snippet_id=>1).count).to eq 0
        end
      end
      context 'pass routes with id user false' do
        it 'should no created' do
          post route_user_false

          expect(JSON.parse(last_response.body)['response']).to eq 'Resource no found'
          expect(CommentSnippet.where(:snippet_id=>1).count).to eq 0
        end
      end
    end
    context 'edit, delete and comment snippet' do
      before :each do
        @user_comment.add_comment_snippet(:body=>'Sad', :line_code=>2, :snippet_id=>@snippet.id)
      end
      context 'pass route for edit' do
        it 'should edit comment snippet' do
          put '/api/snippet/1/comment/1?body=nuevo&title=nuevo&line_code=4'

          expect(CommentSnippet[1].body).to eq 'nuevo'
          expect(CommentSnippet[1].title).to eq 'nuevo'
          expect(CommentSnippet[1].line_code).to eq 4
        end
      end
      context 'pass route for delete' do
        it 'should delete one comment' do
          delete '/api/snippet/1/comment/1'

          expect(CommentSnippet.all.count).to eq 0
          expect(CommentSnippet.where(:snippet_id=>1).count).to eq 0
        end
        context 'pass several id comment' do
          before :each do
            3.times {@user_comment.add_comment_snippet(:body=>'Sad', :line_code=>2, :snippet_id=>@snippet.id)}
          end
          it 'should delete several comment' do
            delete '/api/snippet/1/comment/1,2,3'

            expect(JSON.parse(last_response.body)['response']).to eq('Resources deleted: 3')
            expect(CommentSnippet.all.count).to eq 1
          end
        end
      end
    end
  end
  context 'get all likes count of the snippet' do
    before :each do
      @user_like_1 = User.new(:name => 'Name1', :email=>'Name1@gmail.com',
                              :password=>'123456', :password_confirmation=>'123456').save
      @user_like_2 = User.new(:name => 'Name2', :email=>'Name2@gmail.com',
                              :password=>'123456', :password_confirmation=>'123456').save
      @user_like_3 = User.new(:name => 'Name3', :email=>'Name3@gmail.com',
                              :password=>'123456', :password_confirmation=>'123456').save
    end
    it 'should return 3 likes' do
      LikeSnippet.destroy_or_create(@snippet, @user_like_1)
      LikeSnippet.destroy_or_create(@snippet, @user_like_2)
      LikeSnippet.destroy_or_create(@snippet, @user_like_3)

      get '/api/snippet/1/like'

      expect(JSON.parse(last_response.body)['response']).to eq 'likes count'
      expect(JSON.parse(last_response.body)['likes']).to eq 3
      expect(last_response.status).to eq 200
    end

    it 'should return 0 likes' do
      get '/api/snippet/1/like'

      expect(JSON.parse(last_response.body)['response']).to eq 'likes count'
      expect(JSON.parse(last_response.body)['likes']).to eq 0
      expect(last_response.status).to eq 200
    end
  end
  context 'like and unlike the snippet' do
    before :each do
      @user_like = User.new(:name => 'Audrey', :email=>'Audrey@gmail.com',
                            :password=>'123456', :password_confirmation=>'123456').save
    end
    it 'should create like and delete like' do
      post '/api/snippet/1/like/2'

      expect(JSON.parse(last_response.body)['response']).to eq 'like'
      expect(JSON.parse(last_response.body)['likes']).to eq 1
      expect(LikeSnippet.where(:snippet_id=>@snippet.id, :user_id=>@user_like.id).count).to eq(1)

      post '/api/snippet/1/like/2'

      expect(JSON.parse(last_response.body)['response']).to eq 'unlike'
      expect(JSON.parse(last_response.body)['likes']).to eq 0
      expect(LikeSnippet.where(:snippet_id=>@snippet.id, :user_id=>@user_like.id).count).to eq(0)
    end
  end
  context 'add tags to snippet' do
    before :each do
      %w[javascript python c haskell c# cpp coffeescript].each { |n|
        Tag.create(:name=>n, :description=>'language').save
      }
    end
    context 'create tag already that does exist' do
      it 'should add one tag' do
        post '/api/snippet/1/tag?name=javascript'

        expect(JSON.parse(last_response.body)['response']).to eq 'Tags added successfully'
        expect(@snippet.tags.count).to eq 1
        expect(last_response.status).to eq 200
      end
    end
    context 'create request without tag parameter' do
      it 'should return status 422' do
        post '/api/snippet/1/tag'

        expect(JSON.parse(last_response.body)['response']).to_not eq 'Tags added successfully'
        expect(@snippet.tags.count).to eq 0
        expect(last_response.status).to eq 422
      end
    end
    context 'try create tag empty' do
      it 'should return status 422' do
        post '/api/snippet/1/tag?name='

        expect(JSON.parse(last_response.body)['response']).to_not eq 'Tags added successfully'
        expect(@snippet.tags.count).to eq 0
        expect(last_response.status).to eq 422
      end
    end
    context 'try create new tag and add to snippet' do
      it 'should add one tag' do
        post '/api/snippet/1/tag?name=metalscript'

        expect(JSON.parse(last_response.body)['response']).to eq 'Tags added successfully'
        expect(@snippet.tags.count).to eq 1
        expect(last_response.status).to eq 200
      end
    end
    context 'try add tags to snippet and remove' do
      it 'should add two tags and remove one tag correctly' do
        snippet = Snippet[1]

        [Tag[1], Tag[2]].each { |n| snippet.add_tag n}

        expect(snippet.tags.count).to eq 2

        delete '/api/snippet/1/tag?name=javascript'

        snippet = Snippet[1]
        expect(snippet.tags.count).to eq 1
        expect(last_response.status).to eq 200
        expect(JSON.parse(last_response.body)['response']).to eq 'Tags removed successfully'
      end
      it 'should add four tags and remove all tag correctly' do
        snippet = Snippet[1]

        [Tag[1], Tag[2], Tag[3], Tag[4]].each { |n| snippet.add_tag n }

        expect(snippet.tags.count).to eq 4

        delete '/api/snippet/1/tag?name=javascript,python,c,haskell'

        snippet = Snippet[1]
        expect(snippet.tags.count).to eq 0
        expect(last_response.status).to eq 200
        expect(JSON.parse(last_response.body)['response']).to eq 'Tags removed successfully'
      end
    end
  end
end