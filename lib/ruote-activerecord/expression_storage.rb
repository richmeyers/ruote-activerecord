require 'ruote/engine/context'
require 'ruote/queue/subscriber'
require 'ruote/storage/base'

module Ruote
  module ActiveRecord

    # ActiveRecord persistence for Ruote expressions (ie engine data)
    #
    # #Expression is the model used by this class.
    class ExpressionStorage

      include EngineContext
      include StorageBase
      include Subscriber

      def context=( c )
        @context = c

        subscribe( :expressions )
      end

      # TOOD: Document
      def find_expressions( query = {} )

        fragments = []
        values = []

        if wfid = query[ :wfid ]
          fragments << [ "wfid LIKE ?" ]
          values    << "%#{wfid}%"
        end

        if expclass = query[ :class ]
          fragments << [ "expclass = ?" ]
          values    << expclass.to_s
        end

        conditions = if fragments.any?
          [ fragments.join(' AND '), *values ]
        else
          nil
        end

        fexps = Model.query do
          Expression.all( :conditions => conditions ).map { |fexp|
            fexp.to_ruote_expression( @context )
          }
        end

        if meth = query[:responding_to]
          fexps.delete_if { |fexp| !fexp.respond_to?( meth ) }
        end

        fexps
      end

      def []=( fei, fexp )
        Expression.create_from( fexp )
      end

      def []( fei )
        Model.query do
          e =  Expression.find_by_fei( fei.to_s )
          e ? e.to_ruote_expression( @context ) : nil
        end
      end

      def delete( fei )
        Model.query { Expression.delete( fei.to_s ) }
      end

      def size
        Model.query { Expression.count }
      end

      def purge!
        Expression.purge
      end

      def draw_ticket( fexp )
        Ticket.draw( self.object_id.to_s, fexp.fei.to_s )
      end

      def discard_all_tickets( fei )
        Ticket.discard_all( fei.to_s )
      end
    end
  end
end
