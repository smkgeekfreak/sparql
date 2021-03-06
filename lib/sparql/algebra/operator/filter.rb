module SPARQL; module Algebra
  class Operator
    ##
    # The SPARQL GraphPattern `filter` operator.
    #
    # @example
    #   (select (?v)
    #     (project (?v)
    #       (filter (= ?v 2)
    #         (bgp (triple ?s <http://example/p> ?v)))))
    #
    # @see http://www.w3.org/TR/rdf-sparql-query/#evaluation
    class Filter < Operator::Binary
      include Query
      
      NAME = [:filter]

      ##
      # Executes this query on the given `queryable` graph or repository.
      # Then it passes each solution through one or more filters and removes
      # those that evaluate to false or generate a _TypeError_.
      #
      # Note that the last operand returns a solution set, while the first
      # is an expression. This may be a variable, simple expression,
      # or exprlist.
      #
      # @param  [RDF::Queryable] queryable
      #   the graph or repository to query
      # @param  [Hash{Symbol => Object}] options
      #   any additional keyword options
      # @return [RDF::Query::Solutions]
      #   the resulting solution sequence
      # @see    http://www.w3.org/TR/rdf-sparql-query/#sparqlAlgebra
      # @see    http://www.w3.org/TR/rdf-sparql-query/#ebv
      def execute(queryable, options = {})
        debug(options) {"Filter #{operands.first.to_sxp}"}
        @solutions = operands.last.execute(queryable, options.merge(:depth => options[:depth].to_i + 1))
        debug(options) {"=>(before) #{@solutions.map(&:to_hash).inspect}"}
        opts = options.merge(:queryable => queryable, :depth => options[:depth].to_i + 1)
        @solutions = @solutions.filter do |solution|
          # Evaluate the solution, which will return true or false
          #debug(options) {"===>(evaluate) #{operands.first.inspect} against #{solution.to_hash.inspect}"}
          
          # From http://www.w3.org/TR/rdf-sparql-query/#tests
          # FILTERs eliminate any solutions that, when substituted into the expression, either
          # result in an effective boolean value of false or produce an error.
          begin
            res = boolean(operands.first.evaluate(solution, opts)).true?
            debug(options) {"===>#{res} #{solution.to_hash.inspect}"}
            res
          rescue
            debug(options) {"rescue(#{$!}): #{solution.to_hash.inspect}"}
            false
          end
        end
        @solutions = RDF::Query::Solutions.new(@solutions)
        debug(options) {"=>(after) #{@solutions.map(&:to_hash).inspect}"}
        @solutions
      end
      
      ##
      # Returns an optimized version of this query.
      #
      # Return optimized query
      #
      # @return [Union, RDF::Query] `self`
      def optimize
        operands = operands.map(&:optimize)
      end
    end # Filter
  end # Operator
end; end # SPARQL::Algebra
