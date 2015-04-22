Pakyow::App.define do
  configure :test do
    app.log = false
    app.log_output = false

    presenter.view_stores[:default] = File.join(File.dirname(__FILE__), 'views')
  end

  routes do
    default do; end

    get :fail, '/fail' do
      fail!
    end

    get :redirect, '/redirect' do
      redirect :default
    end

    get :reroute, '/reroute' do
      reroute :default
    end

    group :foo do
      get :bar, '/bar' do; end
    end

    get :present, '/present/:path' do
      presenter.path = params[:path]
    end

    get :title, '/title/:title' do
      presenter.path = '/'
      view.title = params[:title]
    end

    get :scoped, '/scoped' do
      if data = params[:data]
        view.scope(:post).apply(data)
      end
    end

    get :nested, '/nested' do
      if data = params[:data]
        view.scope(:post).apply(data) do |view, datum|
          view.scope(:comment).apply(datum[:comments])
        end
      end
    end

    ### view manipulation

    get :attribute, '/attribute' do
      presenter.path = 'scoped'
      view.scope(:post).attrs[params[:name].to_sym] = params[:value]
    end

    get :remove, '/remove' do
      presenter.path = 'scoped'
      view.scope(:post).remove
    end

    get :text, '/text' do
      presenter.path = 'scoped'
      view.scope(:post).text = params[:text]
    end

    get :html, '/html' do
      presenter.path = 'scoped'
      view.scope(:post).html = params[:html]
    end

    get :append, '/append' do
      presenter.path = 'scoped'
      view.scope(:post).append(View.new(params[:text]))
    end

    get :prepend, '/prepend' do
      presenter.path = 'scoped'
      view.scope(:post).prepend(View.new(params[:text]))
    end

    get :after, '/after' do
      presenter.path = 'scoped'
      view.scope(:post).after(View.new(params[:text]))
    end

    get :before, '/before' do
      presenter.path = 'scoped'
      view.scope(:post).before(View.new(params[:text]))
    end

    get :replace, '/replace' do
      presenter.path = 'scoped'
      view.scope(:post).replace(View.new(params[:text]))
    end

    ### view composition

    get :compose_template, '/template' do
      presenter.path = '/'
      view.template = params[:template]
    end
  end
end
