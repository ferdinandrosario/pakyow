require 'rubygems'
require 'minitest'
require 'minitest/unit'
require 'minitest/autorun'
require 'pp'

require '../pakyow-support/lib/pakyow-support'
require '../pakyow-core/lib/pakyow-core'
require '../pakyow-presenter/lib/pakyow-presenter'
require '../pakyow-mailer/lib/pakyow-mailer'

require 'support/test_mailer'
require 'support/test_application'

class TestMailer
  def self.mailer
    from_store("test_message", Pakyow.app.presenter.store)
  end
end
