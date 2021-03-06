require File.dirname(__FILE__) + '/../spec_helper'

describe User do
  context 'user resources' do
    before :each do
      @user = User.new(:name => 'SnippetMan', :email=>'SnippetMan@gmail.com',
                       :password=>'123456', :password_confirmation=>'123456').save
      Role.new(:name=>'user').save
    end
    context 'get all users' do
      it 'should response all user' do
        get '/api/user/'

        expect(JSON.parse(last_response.body)[0]['name']).to eq 'SnippetMan'
        expect(JSON.parse(last_response.body)[0]['password_digest']).to be_nil
        expect(last_response.status).to eq 200
      end
    end
    context 'get user by id' do
      it 'should response a user' do
        get '/api/user/1'

        expect(JSON.parse(last_response.body)['name']).to eq 'SnippetMan'
        expect(JSON.parse(last_response.body)['password_digest']).to be_nil
        expect(last_response.status).to eq 200
      end
      it 'should not found the resource' do
        get '/api/user/2'

        expect(JSON.parse(last_response.body)['response']).to eq 'Resource no found'
        expect(last_response.status).to eq 404
      end
    end
    context 'create user' do

      let(:route) {'/api/user/?name=carl3os&password=1232dsa' +
          '&password_confirmation=1232dsa&email=carl3os@gmail.com&image_profile=asdadada'}

      it 'should create a user' do
        1.times { post route}

        expect(JSON.parse(last_response.body)['response']).to be_nil
        expect(last_response.status).to eq 200
        expect(JSON.parse(last_response.body)['name']).to eq 'carl3os'
        expect(JSON.parse(last_response.body)['password_digest']).to be_nil
        expect(User.all.count).to eq 2
        # Check if the user have relationship with de role 'user'
        expect(RoleUser.user_have_role? JSON.parse(last_response.body)['id'], 'user').to be_truthy
      end
      it 'should create one user and response 404' do
        2.times { post route }

        expect(last_response.status).to eq 404
        expect(User.all.count).to eq 2
      end
    end
    context 'edit user' do
      let(:route_id_false) {'/api/user/2?name=SnippetMan&password=snippet123123' +
          '&password_confirmation=snippet123123&email=SnippetMan@gmail.com&image_profile=asdadada'}

      let(:route_id_true) {'/api/user/1?name=carl3os&password=1232dsa' +
          '&password_confirmation=1232dsa&email=carl3os@gmail.com&image_profile=asdadada'}

      let(:route_edit_password) {'/api/user/1?name=' + @user.name +
          '&password=1232dsa&password_confirmation=1232dsa&email=' + @user.email + '&image_profile=asdadada'}

      it 'Pass an id that does not exist' do
        put route_id_false

        expect(JSON.parse(last_response.body)['response']).to eq 'Resource no found'
        expect(last_response.status).to eq 404
      end
      it 'Pass an id that exist and edit all attributes' do
        put route_id_true

        expect(User.first(:id=>1).name).to eq 'carl3os'
        expect(last_response.status).to eq 200
      end
      it 'Pass path to edit only the key' do
        put route_edit_password

        expect(JSON.parse(last_response.body)['response']).to_not eq('There is already a resource with this data')
        expect(last_response.status).to eq 200
        expect(JSON.parse(last_response.body)['name']).to eq 'SnippetMan'
        expect(JSON.parse(last_response.body)['password_digest']).to be_nil
        expect(User.first(:id=>1).name).to eq 'SnippetMan' # Should no affected
        expect(User.first(:id=>1).email).to eq 'SnippetMan@gmail.com' # Should no affected
      end

      it 'should edit the name' do
        patch '/api/user/1/name?value=new_name'

        expect(last_response.status).to eq 200
        expect(User.first(:id=>1).name).to eq 'new_name'
      end
    end
    context 'delete user by id' do
      it 'should delete user' do
        delete '/api/user/1'

        expect(JSON.parse(last_response.body)['response']).to eq('Resources deleted: 1')
        expect(last_response.status).to eq 200
        expect(User.all.count).to eq 0
      end
    end
    context 'delete users by id array' do
      before :each do
        3.times { |n|
          User.new(:name=>n.to_s+'abcdef', :email=>n.to_s+'abcdf@gmail.com',
                   :password=>n.to_s+'123456', :password_confirmation=>n.to_s+'123456').save
        }
      end
      it 'should delete 4 users' do
        delete '/api/user/1,2,3,4'

        expect(JSON.parse(last_response.body)['response']).to eq('Resources deleted: 4')
        expect(last_response.status).to eq 200
        expect(User.all.count).to eq 0
      end
    end
    describe 'Role functionality' do
      before :each do
        @admin = User.new(:name => 'admin_user', :email=>'admin@gmail.com',
                          :password=>'123456', :password_confirmation=>'123456').save
        @role = Role.new(:name=>'admin').save
        Role.add_role_to_user(@role, @admin)
      end
      context 'add role to user that does no exist' do
        it 'should return 404 and message' do
          patch '/api/user/123/role/admin'

          expect(JSON.parse(last_response.body)['response']).to eq('Resource no found')
          expect(last_response.status).to eq 404
        end
      end
      context 'add admin role to use' do
        it 'should add admin role to user' do
          # Add admin role to SnippetMan user
          patch '/api/user/1/role/admin'

          expect(JSON.parse(last_response.body)['response']).to eq('Added role successfully')
          expect(last_response.status).to eq 200
        end
      end
      context 'add admin role to user already admin' do
        it 'should return 404 and message' do
          # Try add admin role to user already admin
          patch '/api/user/2/role/admin'

          expect(JSON.parse(last_response.body)['response']).to eq('Action not allowed, this user already has this role')
          expect(last_response.status).to eq 404
        end
      end
      context 'try adding a role that does not exist' do
        it 'should return 404 and message' do
          patch '/api/user/2/role/apple'

          expect(JSON.parse(last_response.body)['response']).to eq('Action not allowed, role does not exist')
          expect(last_response.status).to eq 404
        end
      end
    end
    describe 'followers functionality' do
      before :each do
        3.times { |n|
          User.new(:name=>n.to_s+'abcdef', :email=>n.to_s+'abcdf@gmail.com',
                   :password=>n.to_s+'123456', :password_confirmation=>n.to_s+'123456').save
        }
      end
      it 'should follow and unfollow' do
        post '/api/user/2/follow/1'

        expect(JSON.parse(last_response.body)['response']).to eq 1

        post '/api/user/2/follow/1'

        expect(JSON.parse(last_response.body)['response']).to eq 0
      end
      it 'should followers 3' do
        post '/api/user/1/follow/4'
        post '/api/user/2/follow/4'
        post '/api/user/3/follow/4'

        expect(JSON.parse(last_response.body)['response']).to eq 3
      end
      context 'users following you' do
        it 'should response 3 users' do
          post '/api/user/2/follow/1'
          post '/api/user/3/follow/1'
          post '/api/user/4/follow/1'

          get '/api/user/1/followers'

          expect(JSON.parse(last_response.body)['response']).to eq 3
        end
      end
      context 'users you follow' do
        it 'should return 3 users' do
          post '/api/user/1/follow/2'
          post '/api/user/1/follow/4'
          post '/api/user/1/follow/3'

          get '/api/user/1/follow'

          expect(JSON.parse(last_response.body)['response']).to eq 3
        end
      end
    end
    context 'Get the snippets that belong to a user' do
      before :each do
        @user_comment = User.new(:name => 'Audrey',
                                 :email=>'Audrey@gmail.com',
                                 :password=>'123456',
                                 :password_confirmation=>'123456').save
        snippet_1 = Snippet.new(:filename => 'filename.js',
                                :body=>'Lorem ipsum...',
                                :user_id=>@user.id).save
        2.times {
          @user_comment.add_comment_snippet(:title=>'The sad code',
                                            :body=>'Sad', :line_code=>2,
                                            :snippet_id=>snippet_1.id)
        }
        snippet_2 = Snippet.new(:filename => 'filename.py',
                                :body=>'Lorem ipsum...',
                                :user_id=>@user.id).save
        3.times {
          @user_comment.add_comment_snippet(:title=>'The sad code',
                                            :body=>'Sad', :line_code=>2,
                                            :snippet_id=>snippet_2.id)
        }
        Snippet.new(:filename => 'filename.hs',
                    :body=>'Lorem ipsum...',
                    :user_id=>@user.id).save
      end
      it 'should response have 3 snippets' do
        get '/api/user/1/snippets'

        expect(JSON.parse(last_response.body).count).to eq 3
        expect(JSON.parse(last_response.body)[0]['filename']).to eq 'filename.py'
      end
      it 'should have 2 snippets' do
        get '/api/user/1/snippets?$limit=2'

        expect(JSON.parse(last_response.body).count).to eq 2
        expect(JSON.parse(last_response.body)[0]['filename']).to eq 'filename.py'
      end
      it 'should ignore the limit' do
        get '/api/user/1/snippets?$limit=hacker'

        expect(JSON.parse(last_response.body).count).to eq 3
        expect(JSON.parse(last_response.body)[0]['filename']).to eq 'filename.py'
      end
      it 'should ignore the limit' do
        get '/api/user/1/snippets?$limit='

        expect(JSON.parse(last_response.body).count).to eq 3
        expect(JSON.parse(last_response.body)[0]['filename']).to eq 'filename.py'
      end
    end
    context 'Get the proyect that belong to a user' do
      before :each do
        @user_comment = User.new(:name => 'Audrey',
                                 :email=>'Audrey@gmail.com',
                                 :password=>'123456',
                                 :password_confirmation=>'123456').save
        proyect_1 = Proyect.new(:name=>'proyect_1',
                                :description=>'asdfasdfasdf',
                                :user_id=>@user.id).save
        2.times {
          @user_comment.add_comment_proyect(:body=>'Sad1',
                                            :proyect_id=>proyect_1.id)
        }
        proyect_2 = Proyect.new(:name=>'proyect_2',
                                :description=>'asdfasdfasdf',
                                :user_id=>@user.id).save
        3.times {
          @user_comment.add_comment_proyect(:body=>'Sad2',
                                            :proyect_id=>proyect_2.id)
        }
      end
      it 'should response have 2 proyects' do
        get '/api/user/1/proyects'

        expect(JSON.parse(last_response.body).count).to eq 2
        expect(JSON.parse(last_response.body)[0]['name']).to eq 'proyect_2'
        expect(JSON.parse(last_response.body)[0]['comment_count']).to eq 3
        expect(JSON.parse(last_response.body)[0]['like_count']).to eq 0
      end
      it 'should have 2 proyects' do
        get '/api/user/1/proyects?$limit=1'

        expect(JSON.parse(last_response.body).count).to eq 1
        expect(JSON.parse(last_response.body)[0]['name']).to eq 'proyect_2'
      end
      it 'should ignore the limit' do
        get '/api/user/1/proyects?$limit=hacker'

        expect(JSON.parse(last_response.body).count).to eq 2
        expect(JSON.parse(last_response.body)[0]['name']).to eq 'proyect_2'
      end
      it 'should ignore the limit' do
        get '/api/user/1/proyects?$limit='

        expect(JSON.parse(last_response.body).count).to eq 2
        expect(JSON.parse(last_response.body)[0]['name']).to eq 'proyect_2'
      end
    end
    context 'Get statistics resources' do
      before :each do
        @user_fake = User.new(:name => 'Audrey', :email=>'Audrey@gmail.com',
                         :password=>'123456', :password_confirmation=>'123456').save
      end
      context 'Get the languages most used by the user' do
        it 'should return 4 languages' do

          %w[javascript python c haskell c# cpp coffeescript].each { |n|
            Tag.create(:name=>n, :description=>'language').save
          }

          %w[docker].each { |n|
            Tag.create(:name=>n, :description=>'technology').save
          }

          snippet_1 = Snippet.new(:filename => 'filename.js',
                                :body=>'Lorem ipsum...',
                                :user_id=>@user.id).save

          snippet_1.add_tag(Tag.first(:name=>'javascript')) # 1
          snippet_1.add_tag(Tag.first(:name=>'python')) # 1
          snippet_1.add_tag(Tag.first(:name=>'c')) # 1
          snippet_1.add_tag(Tag.first(:name=>'haskell')) # 1
          snippet_1.add_tag(Tag.first(:name=>'docker')) # Should ignore this

          snippet_2 = Snippet.new(:filename => 'filename.js',
                                  :body=>'Lorem ipsum...',
                                  :user_id=>@user.id).save

          snippet_2.add_tag(Tag.first(:name=>'javascript')) # 2
          snippet_2.add_tag(Tag.first(:name=>'python')) # 2

          snippet_3 = Snippet.new(:filename => 'filename.js',
                                  :body=>'Lorem ipsum...',
                                  :user_id=>@user_fake.id).save

          snippet_3.add_tag(Tag.first(:name=>'javascript'))
          snippet_3.add_tag(Tag.first(:name=>'python'))
          snippet_3.add_tag(Tag.first(:name=>'coffeescript'))
          snippet_3.add_tag(Tag.first(:name=>'cpp'))

          snippet_4 = Snippet.new(:filename => 'filename.js',
                                  :body=>'Lorem ipsum...',
                                  :user_id=>@user.id).save


          snippet_4.add_tag(Tag.first(:name=>'javascript')) # 3
          snippet_4.add_tag(Tag.first(:name=>'haskell')) # 2

          snippet_5 = Snippet.new(:filename => 'filename.js',
                                  :body=>'Lorem ipsum...',
                                  :user_id=>@user.id).save

          snippet_5.add_tag(Tag.first(:name=>'haskell')) # 3

          snippet_6 = Snippet.new(:filename => 'filename.js',
                                  :body=>'Lorem ipsum...',
                                  :user_id=>@user.id).save

          snippet_6.add_tag(Tag.first(:name=>'haskell')) # 4

          get '/api/user/1/statistics/languages'

          puts last_response.body
          expect(JSON.parse(last_response.body).count).to eq 4
          expect(last_response.status).to eq 200
        end
        it 'should return 404 because there no have enough data' do
          get '/api/user/1/statistics/languages'

          expect(last_response.status).to eq 404
        end
      end
    end
  end
end