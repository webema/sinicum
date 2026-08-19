# encoding: utf-8
require 'spec_helper'

module Sinicum
  describe MgnlHelper5 do
    describe "#mgnl_area" do
      let(:content_data) do
        double("content data", jcr_workspace: "website", jcr_path: "/home")
      end
      let(:area) { double("area", children: components) }
      let(:components) { [] }

      before(:each) do
        allow(helper).to receive(:mgnl_content_data).and_return(content_data)
        allow(helper).to receive(:initialize_area).and_return(["module:components/text"])
        allow(helper).to receive(:mgnl_preview_mode).and_return(false)
        allow(helper).to receive(:mgnl_render_component).and_return("rendered".html_safe)
        allow(helper).to receive(:object_from_key_or_object).and_return(area)
      end

      it "should show both add controls by default" do
        result = helper.mgnl_area(:hero)

        expect(result).to include('showAddButton="true"')
        expect(result).to include('showNewComponentArea="true"')
        expect(result).not_to include("maxComponents")
      end

      it "should show both add controls while the area has capacity" do
        result = helper.mgnl_area(:hero, max_components: 1)

        expect(result).to include('maxComponents="1"')
        expect(result).to include('showAddButton="true"')
        expect(result).to include('showNewComponentArea="true"')
      end

      context "when the area has reached its limit" do
        let(:components) { [double("component")] }

        it "should hide both add controls" do
          result = helper.mgnl_area(:hero, max_components: 1)

          expect(result).to include('maxComponents="1"')
          expect(result).to include('showAddButton="false"')
          expect(result).to include('showNewComponentArea="false"')
        end
      end
    end
  end
end
