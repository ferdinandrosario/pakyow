require_relative 'support/helper'
include ViewComposerHelpers

describe ViewComposer do
  before do
    @store = ViewStore.new('spec/support/views')
  end

  it "composes at a path" do
    expect(compose_at('/').view).to eq view_for(:default, 'index.html')
  end

  it "composes with a page" do
    expect(compose_helper(page: 'composer').view).to eq view_for(:composer, 'composer/index.html')
  end

  it "fails to compose without a path or page" do
    expect(lambda { compose_helper({}) }).to raise_error(ArgumentError)
  end

  it "composes at a path with overridden template" do
    expect(compose_at('composer', template: :sub).view).to eq view_for(:sub, 'composer/index.html')
  end

  it "composes at a path with overridden page" do
    expect(compose_at('composer', page: 'multi/index').view).to eq view_for(:multi, 'multi/index.html')
  end

  it "composes at a path with overridden template, page, and includes" do
      expect(
        compose_at('/',
        template: :sub,
        page: 'composer',
        includes: {
          one: 'composer/partials/one'
        }
      ).view).to eq view_for(:sub, 'composer/index.html', { one: 'composer/partials/_one.html'})
  end

  it "composes with method chaining" do
    expect(compose_at('/').template(:multi).view).to eq view_for(:multi, 'index.html')
  end

  it "composes with a block" do
    expect(compose_at('/') {
      template(:multi)
    }.view).to eq view_for(:multi, 'index.html')
  end

  it "exposes template" do
    composer = compose_at('/')
    expect(composer.template).to be_a Template
  end

  it "exposes page" do
    composer = compose_at('/')
    expect(composer.page).to be_a Page
  end

  it "exposes partials" do
    composer = compose_at('/partial')
    expect(composer.partial(:partial1)).to be_a Partial
  end

  it "handles container modification" do
    composer = compose_at('/')
    composer.container(:default).remove

    expect(str_to_doc(composer.view.to_html).css('body').children.to_html.strip).to eq ''
  end

  it "handles partial modification" do
    composer = compose_at('/partial')
    partial = composer.partial(:partial1)
    partial.remove

    expect(str_to_doc(composer.view.to_html).css('body').children.to_html.strip).to eq ''
  end

  it "handles attribute modification" do
    composer = compose_at('/attributes')
    composer.container(:default).scope(:attrs).attrs.style = {
      background: 'red'
    }

    expect(str_to_doc(composer.view.to_html).css('body div')[0][:style]).to eq 'background:red'
  end

  it "handles replacements" do
    composer = compose_at('/')
    composer.container(:default).replace('foo')

    expect(str_to_doc(composer.view.to_html).css('body').children.to_html.strip).to eq 'foo'
  end

  it "sets template title" do
    composer = compose_at('/')
    composer.title = 'foo'
    expect(composer.view.title).to eq 'foo'
  end

  it "gets template title" do
    composer = compose_at('/')
    composer.title = 'foo'
    expect(composer.title).to eq 'foo'
  end

  it "gets scopes from parts" do
    composer = compose_at('scopes')
    expect(composer.scope(:scope).length).to eq 3
  end

  it "gets props from parts" do
    skip 'this relies on unscoped props, which are not currently supported'
    composer = compose_at('scopes')
    expect(composer.prop(:prop).length).to eq 3
  end
end
