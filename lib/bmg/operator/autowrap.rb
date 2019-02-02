module Bmg
  module Operator
    #
    # Autowrap operator.
    #
    # Autowrap can be used to structure tuples ala Tutorial D' wrap, but it works
    # with conventions instead of explicit wrapping, and supports multiple levels
    # or wrapping.
    #
    # Examples:
    #
    #   [{ a: 1, b_x: 2, b_y: 3 }]     => [{ a: 1, b: { x: 2, y: 3 } }]
    #   [{ a: 1, b_x_y: 2, b_x_z: 3 }] => [{ a: 1, b: { x: { y: 2, z: 3 } } }]
    #
    # Autowrap supports the following options:
    #
    # - `postprocessor: :nil|:none|:delete|Hash|Proc` see NoLeftJoinNoise
    # - `split: String` the seperator to use to split keys, defaults to `_`
    #
    class Autowrap
      include Operator::Unary

      DEFAULT_OPTIONS = {
        :postprocessor => :none,
        :split => "_"
      }

      def initialize(type, operand, options = {})
        @type = type
        @operand = operand
        @original_options = options
        @options = normalize_options(options)
      end

    private

      attr_reader :options

    public

      def same_options?(opts)
        normalize_options(opts) == options
      end

      def each
        @operand.each do |tuple|
          yield autowrap_tuple(tuple)
        end
      end

      def to_ast
        [ :autowrap, operand.to_ast, @original_options.dup ]
      end

    protected ### optimization

      def _autowrap(type, opts)
        if same_options?(opts)
          self
        else
          super
        end
      end

      def _page(type, ordering, page_index, opts)
        return super unless operand.type.knows_attrlist?
        roots = Support.wrapped_roots(operand.type.to_attrlist, options[:split])
        attrs = ordering.map{|(a,d)| a }
        if (roots & attrs).empty?
          operand.page(ordering, page_index, opts).autowrap(options)
        else
          super
        end
      end

      def _restrict(type, predicate)
        return super unless operand.type.knows_attrlist?
        roots = Support.wrapped_roots(operand.type.to_attrlist, options[:split])
        vars = predicate.free_variables
        if (roots & vars).empty?
          operand.restrict(predicate).autowrap(options)
        else
          super
        end
      end

    protected ### inspect

      def args
        [ options ]
      end

    private

      def normalize_options(options)
        opts = DEFAULT_OPTIONS.merge(options)
        opts[:postprocessor] = NoLeftJoinNoise.new(opts[:postprocessor])
        opts
      end

      def autowrap_tuple(tuple)
        separator = @options[:split]
        autowrapped = tuple.each_with_object({}){|(k,v),h|
          parts = k.to_s.split(separator).map(&:to_sym)
          sub = h
          parts[0...-1].each do |part|
            sub = (sub[part] ||= {})
          end
          sub[parts[-1]] = v
          h
        }
        autowrapped = postprocessor.call(autowrapped)
        autowrapped
      end

      def postprocessor
        @options[:postprocessor]
      end

      #
      # Removes the noise generated by left joins that were not join.
      #
      # i.e. x is removed in { x: { id: nil, name: nil, ... } }
      #
      # Supported heuristics are:
      #
      # - nil:    { x: { id: nil, name: nil, ... } } => { x: nil }
      # - delete: { x: { id: nil, name: nil, ... } } => { }
      # - none:   { x: { id: nil, name: nil, ... } } => { x: { id: nil, name: nil, ... } }
      # - a Hash, specifying a specific heuristic by tuple attribute
      # - a Proc, `->(tuple,key){ ... }` that affects the tuple manually
      #
      class NoLeftJoinNoise

        REMOVERS = {
          nil:    ->(t,k){ t[k] = nil  },
          delete: ->(t,k){ t.delete(k) },
          none:   ->(t,k){ t           }
        }

        def self.new(remover)
          return remover if remover.is_a?(NoLeftJoinNoise)
          super
        end

        def initialize(remover)
          @remover_to_s = remover
          @remover = case remover
          when NilClass then REMOVERS[:none]
          when Proc     then remover
          when Symbol   then REMOVERS[remover]
          when Hash     then ->(t,k){ REMOVERS[remover[k] || :none].call(t,k) }
          else
            raise "Invalid remover `#{remover}`"
          end
        end
        attr_reader :remover

        def call(tuple)
          tuple.each_key do |k|
            @remover.call(tuple, k) if tuple[k].is_a?(Hash) && all_nil?(tuple[k])
          end
          tuple
        end

        def all_nil?(tuple)
          return false unless tuple.is_a?(Hash)
          tuple.all?{|(k,v)| v.nil? || all_nil?(tuple[k]) }
        end

        def inspect
          @remover_to_s.inspect
        end
        alias :to_s :inspect

        def hash
          remover.hash
        end

        def ==(other)
          other.is_a?(NoLeftJoinNoise) && remover.eql?(other.remover)
        end

      end # NoLeftJoinNoise

      module Support

        def wrapped_roots(attrlist, split_symbol)
          attrlist.map{|a|
            split = a.to_s.split(split_symbol)
            split.size == 1 ? nil : split[0]
          }.compact.uniq.map(&:to_sym)
        end
        module_function :wrapped_roots

      end # module Support

    end # class Autowrap
  end # module Operator
end # module Bmg
