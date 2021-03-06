require './controllers/services/namespace/tag'

class ProyectNamespace < TagNamespace

  helpers ServicesHelpers

  namespace '/proyect' do

    get '/' do
      # Read all proyect
      DB.fetch("SELECT proyects.*,
        (SELECT COUNT(comment_proyects.id)
          FROM comment_proyects WHERE comment_proyects.proyect_id = proyects.id) AS comment_count,
        (SELECT COUNT(like_proyects.id)
          FROM like_proyects WHERE like_proyects.proyect_id = proyects.id) AS like_count
        FROM proyects ORDER BY comment_count DESC").all.to_json
    end

    get '/:id' do
      # Read one proyect by id
      check_if_resource_exist(Proyect, params[:id]).to_json
    end

    post '/', :validate => %i(name description user_id) do
      # Create proyect
      check_nil_string [params[:name], params[:description], params[:user_id]]
      Proyect.create(:name=>params[:name],
                     :description=>params[:description],
                     :user_id=>params[:user_id]).save().to_json
    end

    put '/:id', :validate => %i(name description) do
      # Edit proyect
      check_nil_string [params[:name], params[:description]]
      proyect = Proyect.for_update.first(:id=>params[:id])
      if proyect.equal?(nil)
        halt 404, {:response=>'Resource no found'}.to_json
      else
        proyect.name = params[:name]
        proyect.description = params[:description]
        proyect.save.to_json
      end
    end

    delete '/:id' do
      # Delete proyect
      delete_record(Proyect, params[:id].split(','))
    end

    get '/:id/comment' do
      # Read Comments of proyect
      check_if_resource_exist(Proyect, params[:id]).comment_proyects.to_json
    end

    post '/:id/comment', :validate => %i(body user_id) do
      # Create comment
      check_nil_string [params[:body], params[:user_id]]
      check_if_resource_exist(User, params[:user_id])
      check_if_resource_exist(Proyect, params[:id]).add_comment_proyect(
          CommentProyect.create(:body=>params[:body],
                                :user_id=>params[:user_id],
                                :proyect_id=>params[:id])).to_json
    end

    put '/:id/comment/:comment_id', :validate => %i(body) do
      # Edit comment
      check_nil_string [params[:body]]
      check_if_resource_exist(Proyect, params[:id])
      comment = CommentProyect.for_update.first(:id=>params[:comment_id])
      comment.body = params[:body]
      comment.save.to_json
    end

    delete '/:id/comment/:comment_id' do
      # Delete Comments of proyet
      check_if_resource_exist(Proyect, params[:id])
      c = 0
      params[:comment_id].split(',').each { |id|
        check_if_resource_exist(CommentProyect, id)
        CommentProyect.delete_comment id
        c += 1
      }
      {:response=>"Resources deleted: #{c}"}.to_json
    end

    get '/:id/snippet' do
      # All snippets of proyect proyect_has_snippet

      proyect = check_if_resource_exist(Proyect, params[:id])

      DB.fetch("SELECT snippets.*,
          (SELECT COUNT(comment_snippets.id)
            FROM comment_snippets WHERE comment_snippets.snippet_id = snippets.id) AS comment_count,
          (SELECT COUNT(like_snippets.id)
            FROM like_snippets WHERE like_snippets.snippet_id = snippets.id) AS like_count
          FROM snippets, proyect_has_snippet, proyects
            WHERE snippets.id = proyect_has_snippet.snippet_id
              AND proyect_has_snippet.proyect_id = #{proyect.id}
              AND proyects.id = #{proyect.id}
            ORDER BY comment_count DESC").all.to_json
    end

    post '/:id/snippet/:id_snippet' do
      # Add snippet to proyect
      proyect = check_if_resource_exist(Proyect, params[:id])
      c = 0
      params[:id_snippet].split(',').each { |n|
        snippet = check_if_resource_exist(Snippet, n)
        if Proyect.proyect_have_snippet? proyect.id, snippet.id
          halt 404, {:response=>"Proyect al ready have this snippet #{params[:id_snippet]}"}.to_json
        else
          Proyect.add_snippets proyect, [snippet]
        end
        c += 1
      }
      {:response=>"Resources added: #{c}"}.to_json
    end

    delete '/:id/snippet/:id_snippet' do
      # Remove snippet to proyect
      proyect = check_if_resource_exist(Proyect, params[:id])
      c = 0
      params[:id_snippet].split(',').each { |n|
        snippet = check_if_resource_exist(Snippet, n)
        if !Proyect.proyect_have_snippet? proyect.id, snippet.id
          halt 404, {:response=>"Proyect not have the snippet #{params[:id_snippet]}"}.to_json
        else
          Proyect.remove_snippets proyect, [snippet]
        end
        c += 1
      }
      {:response=>"Resources removed: #{c}"}.to_json
    end

    get '/:id/like' do
      # Count all likes of proyect
      proyect = check_if_resource_exist(Proyect, params['id'])
      likes = LikeProyect.where(:proyect_id=>proyect.id).count
      {:response=>'likes count', :likes=>likes}.to_json
    end

    post '/:id/like/:user_id' do
      # Create or Delete like
      proyect = check_if_resource_exist(Proyect, params['id'])
      user = check_if_resource_exist(User, params['user_id'])
      like = LikeProyect.destroy_or_create(proyect, user)
      {:response=> like[0] ? 'like' : 'unlike', :likes=>like[1]}.to_json
    end

  end

end