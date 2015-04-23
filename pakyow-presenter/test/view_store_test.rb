require_relative 'support/helper'

class ViewStoreTest < Minitest::Test
  def setup
    capture_stdout do
      @store = ViewStore.new('test/support/views')
    end
  end

  def test_finds_path_at_file
    assert(@store.at?('sub'))
    assert(@store.at?('sub/'))
    assert(@store.at?('/sub'))
    assert(@store.at?('/sub/'))
  end

  def test_finds_path_at_dir
    assert(@store.at?('sub_dir'))
    assert(@store.at?('sub_dir/'))
    assert(@store.at?('/sub_dir'))
    assert(@store.at?('/sub_dir/'))
  end

  def test_does_not_find_undefined_paths
    refute(@store.at?('missing'))
    refute(@store.at?('missing/'))
    refute(@store.at?('/missing'))
    refute(@store.at?('/missing/'))
  end

  def test_uses_default_template
    assert_equal(:default, @store.template('/').name)
    assert_equal(:default, @store.template('').name)

    assert_equal(:default, @store.template('pageless').name)
    assert_equal(:default, @store.template('/pageless').name)
    assert_equal(:default, @store.template('pageless/').name)
    assert_equal(:default, @store.template('/pageless/').name)
  end

  def test_uses_page_specified_template
    assert_equal(:sub, @store.template('sub').name)
  end

  def test_uses_page_specified_title
    assert_equal('custom title', @store.view('title').title)
  end

  def test_template_title_not_reset_when_no_title_specified
    assert_equal('pakyow', @store.view('no_title').title)
  end

  def test_fails_when_no_template
    #TODO rewrite since loading views fails when no template
    # assert_raises(StandardError) {
    #   @store.template('no_template')
    # }
  end

  def test_uses_default_page_content
    assert_equal('index', str_to_doc(@store.view('/').to_html).css('body').children.to_html.strip)
  end

  def test_uses_named_page_content
    assert_equal('multi side', str_to_doc(@store.view('multi').to_html).css('body').children.to_html.strip)
  end

  def test_falls_back_when_no_page
    assert_equal 'index', str_to_doc(@store.view("no_page").to_html).css('body').inner_text.strip
  end

  def test_includes_partial_at_current_path
    assert_equal('partial1', str_to_doc(@store.view('/partial').to_html).css('body').children.to_html.strip)
  end

  def test_partials_can_be_overridden
    assert_equal('partial1.1', str_to_doc(@store.view('/partial/override').to_html).css('body').children.to_html.strip)
  end

  def test_partials_include_other_partials
    assert_equal('partial2', str_to_doc(@store.view('/partial/inception').to_html).css('body').children.to_html.strip)
  end

  def test_template_includes_partials
    assert_equal('partial1', str_to_doc(@store.view('/partial/template').to_html).css('body').children.to_html.strip)
  end

  def test_template_is_retrievable_by_name
    template = @store.template(:multi)
    assert_equal 'multi', str_to_doc(template.to_html).css('title').inner_html.strip
  end

  def test_partial_can_be_retrieved_for_path
    name = :partial1
    partial = @store.partial('/', name)
    assert_equal 'partial1', partial.to_html.strip
  end

  def test_partials_can_be_included_multiple_times
    assert_equal("partial1partial1", str_to_doc(@store.view('/partial/multiple').to_html).css('body').inner_text.strip.gsub("\n", ''))
  end

  def test_view_building_does_not_modify_template
    html = @store.template('/').to_html
    @store.view('/')

    assert_equal html, @store.template('/').to_html
  end

  def test_iterates_over_views
    @store.views do |view, path|
      assert_instance_of Pakyow::Presenter::View, view
    end
  end

  def test_dotfiles_are_ignored
    assert_raises(Pakyow::Presenter::MissingView) {
      file = @store.template('.vimswap.swp')
    }
  end
end
