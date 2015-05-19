require_relative 'support/helper'

describe 'processor' do
  include ReqResHelpers

  before do
    Pakyow::App.stage(:test)
    Pakyow.app.presenter.prepare_with_context(AppContext.new(mock_request('/')))
  end

  after do
    teardown
  end

  it 'processes views' do
    v = Pakyow.app.presenter.store.view("processor")
    html = str_to_doc(v.to_html).css('body').inner_text.strip
    expect('foo').to eq html
  end

  it 'processes multiple formats' do
    v = Pakyow.app.presenter.store.view("processor2")
    html = str_to_doc(v.to_html).css('body').inner_text.strip
    expect('foo').to eq html
  end
end
