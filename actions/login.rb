class Tidal

  get '/login' do
    @title = 'Login'
    erb :'login.html'
  end

  post '/login' do
    if resp = request.env['rack.openid.response']
      if resp.status == :success
        session[:user] = resp
        flash[:notice] = 'Connecté'
        redirect '/'
      else
        halt 404, "Error: #{resp.status}"
      end
    else
      openid = params[:openid_identifier]
      if User.where(:openid_identifier => openid).count == 0
        halt 403, 'Openid identifier unknown'
      else
        headers 'WWW-Authenticate' => Rack::OpenID.build_header(:identifier => params[:openid_identifier])
        halt 401, 'got openid?'
      end
    end
  end

  get '/logout' do
    session[:user] = nil
    flash[:notice] = 'Logout'
    redirect '/'
  end

  private
  
  def check_logged
    if ALWAYS_LOGGED || @user_logged
      true
    else
      redirect '/login'
      false
    end
  end

  def check_logged_ajax
    if ALWAYS_LOGGED || @user_logged
      true
    else
      body 'Logged users only'
      false
    end
  end
end