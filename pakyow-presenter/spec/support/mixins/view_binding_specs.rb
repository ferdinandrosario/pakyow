shared_examples :binding_specs do
  let :store do
    ViewStore.new('spec/support/views')
  end

  describe 'binding data to a view' do
    context 'when scope is defined in a view and prop in a partial' do
      let :view do
        ViewContext.new(ViewComposer.from_path(store, 'prop_in_partial'), {})
      end

      let :data do
        { prop1: 'prop1', prop2: 'prop2', prop3: 'prop3' }
      end

      it 'binds data to the prop' do
        view.scope(:scope1).bind(data)
        expect(view.scope(:scope1).prop(:prop1)[0].text).to eq(data[:prop1])
        expect(view.scope(:scope1).prop(:prop2)[0].text).to eq(data[:prop2])
        expect(view.scope(:scope1).prop(:prop3)[0].text).to eq(data[:prop3])

        view.scope(:scope2).bind(data)
        expect(view.scope(:scope2).prop(:prop2)[0].text).to eq(data[:prop2])
      end
    end

    context 'when the scope is nested within multiple partials' do
      let :view do
        ViewContext.new(ViewComposer.from_path(store, 'scope_in_multiple_partials'), {})
      end

      let :data do
        {}
      end

      it 'binds data to the scope' do
        view.scope(:article).apply(data)
      end
    end
  end
end
