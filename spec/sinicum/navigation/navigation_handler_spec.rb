require 'spec_helper'

module Sinicum
  module Navigation
    describe NavigationHandler do
      let(:prefix) { "http://content.dievision.de:80/sinicum-rest" }
      let(:base_node) do
          node = double("base_node")
          allow(node).to receive(:uuid).and_return("745efc13-e7da-4717-9153-10fb6472ca73")
          node
        end

      describe "children" do
        let(:api_response) do
          File.read(File.dirname(__FILE__) +
            "/../../fixtures/api/navigation_children.json")
        end

        before(:example) do
          ::Sinicum::Jcr::ApiQueries.configure_jcr = { host: "content.dievision.de" }

          stub_request(:get, "#{prefix}/_navigation/children/#{base_node.uuid}?depth=3&" \
            "properties=title;nav_title;nav_hidden")
            .to_return(body: api_response, headers: { "Content-Type" => "application/json" })
        end

        it "should retrieve the children for a node and filter elements" do
          handler = NavigationHandler.children(base_node, 3)
          expect(handler.elements.size).to eq(7)
        end

        it "should return the navigation elements for the node" do
          handler = NavigationHandler.children(base_node, 3)
          expect(handler.elements.first).to be_kind_of(NavigationElement)
        end

        it "should initialize the children of the elements" do
          handler = NavigationHandler.children(base_node, 3)
          expect(handler.elements.first.children.size).to eq(10)
        end

        it "should initialize the has children metadata" do
          handler = NavigationHandler.children(base_node, 3)
          expect(handler.elements.first.has_children).to be true
        end

        it "should know about unloaded children on level 2" do
          api_response = MultiJson.dump(
            [
              {
                "uuid" => "level-1",
                "path" => "/level-1",
                "depth" => 1,
                "properties" => { "title" => "Level 1" },
                "children" => [
                  {
                    "uuid" => "level-2",
                    "path" => "/level-1/level-2",
                    "depth" => 2,
                    "properties" => { "title" => "Level 2" },
                    "hasChildren" => true
                  }
                ]
              }
            ])

          stub_request(:get, "#{prefix}/_navigation/children/#{base_node.uuid}?depth=2&" \
            "properties=title;nav_title;nav_hidden")
            .to_return(body: api_response, headers: { "Content-Type" => "application/json" })

          handler = NavigationHandler.children(base_node, 2)
          level_two = handler.elements.first.children.first

          expect(level_two.children).to be_empty
          expect(level_two.children?).to be true
        end
      end

      describe "parents" do
        let(:api_response) do
          File.read(File.dirname(__FILE__) +
          "/../../fixtures/api/navigation_parents.json")
        end

        before(:example) do
          ::Sinicum::Jcr::ApiQueries.configure_jcr = { host: "content.dievision.de" }

          stub_request(:get, "#{prefix}/_navigation/parents/#{base_node.uuid}?" \
            "properties=title;nav_title;nav_hidden")
            .to_return(body: api_response, headers: { "Content-Type" => "application/json" })
        end

        it "should retrieve the children for a node and filter elements" do
          handler = NavigationHandler.parents(base_node)
          expect(handler.elements.size).to eq(3)
        end
      end

      describe "faulty navigation" do
        before(:example) do
          ::Sinicum::Jcr::ApiQueries.configure_jcr = { host: "content.dievision.de" }

          stub_request(:get, "#{prefix}/_navigation/children/#{base_node.uuid}?depth=3&" \
            "properties=title;nav_title;nav_hidden")
            .to_return(body: "[]", headers: { "Content-Type" => "application/json" })
        end

        it "should retrieve the children for a node and filter elements" do
          handler = NavigationHandler.children(base_node, 3)
          expect(handler.elements.size).to eq(0)
          expect(handler.elements).to be_empty
        end
      end
    end
  end
end
