# session managment
class Tidal

  get '/login' do
    if resp = request.env['rack.openid.response']
      if resp.status == :success
        session[:user] = resp
        redirect '/reader'
      else
        halt 404, "Error: #{resp.status}"
      end
    elsif ENV['OPENID_URI']
      openid_params = {:identifier => ENV['OPENID_URI']}
      if params[:return_to]
        openid_params[:return_to] = params[:return_to]
      end
      headers 'WWW-Authenticate' => Rack::OpenID.build_header(openid_params)
      halt 401, 'got openid?'
    else
      redirect '/reader'
    end
  end

  get '/logout' do
    session[:user] = nil
    flash[:notice] = 'Logout'
    redirect '/'
  end

  private

  def check_logged
    if (!ENV['OPENID_URI']) || @user_logged
      true
    elsif resp = request.env['rack.openid.response']
      if resp.status == :success
        session[:user] = resp
        true
      else
        halt 404, "Error: #{resp.status}"
        false
      end
    else
      redirect "/login?return_to=#{CGI::escape(request.url)}"
      false
    end
  end

  def check_logged_ajax
    if (!ENV['OPENID_URI']) || @user_logged
      true
    else
      body 'Logged users only'
      false
    end
  end
end