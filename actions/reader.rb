# The action of the reader part
class Tidal

  get '/reader' do
    if check_logged
      body 'ok'
    end
  end

end
