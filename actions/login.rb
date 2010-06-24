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
      headers 'WWW-Authenticate' => Rack::OpenID.build_header(:identifier => ENV['OPENID_URI'])
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
    else
      redirect '/login'
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