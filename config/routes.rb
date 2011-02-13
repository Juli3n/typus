Rails.application.routes.draw do

  scope "admin", :module => :admin, :as => "admin" do

    match "/" => "dashboard#show", :as => "dashboard"
    match "user_guide" => "base#user_guide"

    if Typus.authentication == :session
      resource :session, :only => [:new, :create, :destroy], :controller => :session
      resources :account, :only => [:new, :create, :show, :forgot_password] do
        collection do
          get :forgot_password
          post :send_password
        end
      end
    end

    Typus.models.map { |i| i.to_resource }.each do |resource|
      match "#{resource}(/:action(/:id(.:format)))", :controller => resource
    end

  end

end
