module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `minus` operator.
    #
    # @example
    #    (prefix ((ex: <http://www.w3.org/2009/sparql/docs/tests/data-sparql11/negation#>))
    #      (project (?animal)
    #        (minus
    #          (bgp (triple ?animal <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ex:Animal))
    #          (filter (|| (= ?type ex:Reptile) (= ?type ex:Insect))
    #            (bgp (triple ?animal <http://www.w3.org/1999/02/22-rdf-syntax-ns#type> ?type))))))
    #
    # @see http://www.w3.org/TR/xpath-functions/#func-numeric-unary-minus
    # @see http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
    class Minus < Operator::Binary
      include Query

      NAME = :minus

      ##
      # Executes each operand with `queryable` and performs the `join` operation
      # by creating a new solution set containing the `merge` of all solutions
      # from each set that are `compatible` with each other.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#defn_algMinus
      # @see    http://www.w3.org/TR/2013/REC-sparql11-query-20130321/#negation
      def execute(queryable, options = {})
        # Let Ω1 and Ω2 be multisets of solution mappings. We define:
        # 
        # Minus(Ω1, Ω2) = { μ | μ in Ω1 . ∀ μ' in Ω2, either μ and μ' are not compatible or dom(μ) and dom(μ') are disjoint }
        # 
        # card[Minus(Ω1, Ω2)](μ) = card[Ω1](μ)
        debug(options) {"Minus"}
        solutions1 = operand(0).execute(queryable, options.merge(:depth => options[:depth].to_i + 1)) || {}
        debug(options) {"=>(left) #{solutions1.inspect}"}
        solutions2 = operand(1).execute(queryable, options.merge(:depth => options[:depth].to_i + 1)) || {}
        debug(options) {"=>(right) #{solutions2.inspect}"}
        @solutions = solutions1.minus(solutions2)
        debug(options) {"=> #{@solutions.inspect}"}
        @solutions
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # Groups of one graph pattern (not a filter) become join(Z, A) and can be replaced by A.
      # The empty graph pattern Z is the identity for join:
      #   Replace join(Z, A) by A
      #   Replace join(A, Z) by A
      #
      # @return [Join, RDF::Query] `self`
      def optimize
        ops = operands.map {|o| o.optimize }.select {|o| o.respond_to?(:empty?) && !o.empty?}
        @operands = ops
        self
      end
    end # Minus
  end # Operator
end; end # SPARQL::Algebra
