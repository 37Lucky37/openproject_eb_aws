#-- copyright
# OpenProject is an open source project management software.
# Copyright (C) the OpenProject GmbH
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License version 3.
#
# OpenProject is a fork of ChiliProject, which is a fork of Redmine. The copyright follows:
# Copyright (C) 2006-2013 Jean-Philippe Lang
# Copyright (C) 2010-2013 the ChiliProject Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
#
# See COPYRIGHT and LICENSE files for more details.
#++

require "spec_helper"

RSpec.describe Queries::WorkPackages::Filter::CategoryFilter do
  it_behaves_like "basic query filter" do
    let(:type) { :list_optional }
    let(:class_key) { :category_id }

    describe "#available?" do
      context "within a project" do
        before do
          allow(project)
            .to receive_message_chain(:categories, :exists?)
            .and_return true
        end

        it "is true" do
          expect(instance).to be_available
        end

        it "is false without a type" do
          allow(project)
            .to receive_message_chain(:categories, :exists?)
            .and_return false

          expect(instance).not_to be_available
        end
      end

      context "without a project" do
        let(:project) { nil }

        it "is false" do
          expect(instance).not_to be_available
        end
      end
    end

    describe "#allowed_values" do
      let(:category) { build_stubbed(:category) }

      before do
        allow(project)
          .to receive(:categories)
          .and_return [category]
      end

      it "returns an array of type options" do
        expect(instance.allowed_values)
          .to contain_exactly([category.name, category.id.to_s])
      end
    end

    describe "#value_objects" do
      let(:category1) { build_stubbed(:category) }
      let(:category2) { build_stubbed(:category) }

      before do
        allow(project)
          .to receive(:categories)
          .and_return [category1, category2]

        instance.values = [category2.id.to_s]
      end

      it "returns an array of category" do
        expect(instance.value_objects)
          .to contain_exactly(category2)
      end
    end

    describe "#ar_object_filter?" do
      it "is true" do
        expect(instance)
          .to be_ar_object_filter
      end
    end
  end
end
