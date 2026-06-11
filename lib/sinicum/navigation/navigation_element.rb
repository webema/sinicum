module Sinicum
  module Navigation
    module NavigationElement
      extend ActiveSupport::Concern

      attr_reader :uuid, :path, :depth, :properties, :children, :has_children

      def initialize(uuid, path, depth, properties, children, has_children = nil)
        @uuid = uuid
        @path = path
        @depth = depth
        @properties = properties
        @children = children
        @has_children = has_children
      end

      def title
      end

      def has_children?
        warn "[DEPRECATION] `has_children?` is deprecated.  Please use `children?` instead."
        children?
      end

      def children?
        return @has_children unless @has_children.nil?

        @children && @children.size > 0
      end

      def children
        NavigationElementList.new(@children)
      end

      module ClassMethods
        def navigation_properties
          []
        end
      end
    end
  end
end
