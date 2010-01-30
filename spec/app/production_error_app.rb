class ProductionErrorApp < Sinatra::Base
  set :environment, :production
  register Sinatra::RespondTo
  get '/missing-template' do
    respond_to do |wants|
      wants.html { haml :missing }
    end
  end
end