require_relative 'mutator'
require_relative 'channel_builder'
require_relative 'ui_view'

module Pakyow
  module UI
    # The UI context available during routing.
    #
    # @api public
    class UI
      attr_accessor :context
      attr_reader :mutator

      # Informs Pakyow that a mutation has occurred in application state,
      # triggering all the necessary realtime view updates.
      #
      # @api public
      def mutated(scope, data = nil, context = nil)
        context ||= @context

        MutationStore.instance.mutations(scope).each do |mutation|
          view = UIView.new(scope, mutation[:session])

          qualified = true

          # qualifiers are defined with the mutation
          unless mutation[:qualifiers].empty? || data.nil?
            mutation[:qualifiers].each_with_index do |qualifier, i|
              qualified = false unless data[qualifier] == mutation[:query_args][i]
            end
          end

          qualified = false if data.nil? && !mutation[:qualifications].empty?

          # qualifications are set on the subscription
          unless !qualified || mutation[:qualifications].empty? || data.nil?
            mutation[:qualifications].each_pair do |key, value|
              qualified = false unless data[key.to_sym] == value
            end
          end

          next unless qualified

          mutable_data = Mutator.instance.mutable(scope, context).send(mutation[:query_name], *mutation[:query_args]).data
          Mutator.instance.mutate(mutation[:mutation].to_sym, view, mutable_data)

          Pakyow.app.socket.push(
            view.finalize,

            ChannelBuilder.build(
              scope: scope,
              mutation: mutation[:mutation].to_sym,
              qualifiers: mutation[:qualifiers],
              data: mutable_data,
              qualifications: mutation[:qualifications]
            )
          )
        end
      end

      # Addresses a component rendered on the client-side.
      #
      # @api public
      def component(name, qualifications = {})
        UIComponent.new(name, qualifications)
      end

      # @api private
      def load(mutators, mutables)
        # TODO: this is another pattern I see all over the place
        @mutator = Mutator.instance.reset

        mutators.each_pair do |scope, block|
          @mutator.set(scope, &block)
        end

        mutables.each_pair do |scope, block|
          @mutator.mutable(scope, &block)
        end
      end
    end
  end
end
