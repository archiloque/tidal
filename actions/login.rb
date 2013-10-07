# session management
class Tidal

  get '/logout' do
    session[:user] = nil
    flash[:notice] = 'Logout'
    redirect '/'
  end

  private

  def check_logged
    if (!ENV['OPENID_URI']) || @user_logged
      true
    elsif ENV['HTTP_X_SSL_ISSUER'] && (request.env['HTTP_X_SSL_ISSUER'] == ENV['HTTP_X_SSL_ISSUER'])
      session[:user] = ENV['HTTP_X_SSL_ISSUER']
      true
    else
      redirect '/'
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