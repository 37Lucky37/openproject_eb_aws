# -- copyright
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
# ++

module Queries
  module Selects
    module AvailableSelects
      def select_for(key)
        select = (find_available_select(key) || ::Queries::Selects::NotExistingSelect)
          .new(key.to_sym)

        # It might be that while the class of selects is available, the instantiated select isn't.
        # This can e.g. be the case for custom fields that had once been available and have a key that
        # leads to them being found by the find_available_select but when instantiated, the custom
        # field they refer to is no longer available.
        select.available? ? select : ::Queries::Selects::NotExistingSelect.new(key.to_sym)
      end

      def available_selects
        registered_and_available
          .flat_map(&:all_available)
      end

      private

      def find_available_select(key)
        registered_and_available.detect do |s|
          s.key === key.to_sym
        end
      end

      def registered_and_available
        ::Queries::Register
          .selects[self.class]
          .select(&:available?)
      end
    end
  end
end
