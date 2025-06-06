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

module OpTurbo
  module ComponentStream
    extend ActiveSupport::Concern

    def respond_to_with_turbo_streams(status: turbo_status, &format_block)
      respond_to do |format|
        format.turbo_stream do
          render turbo_stream: turbo_streams, status:
        end

        yield(format) if format_block
      end
    end

    alias_method :respond_with_turbo_streams, :respond_to_with_turbo_streams

    def update_via_turbo_stream(component:, status: :ok, method: nil)
      modify_via_turbo_stream(component:, action: :update, status:, method:)
    end

    def replace_via_turbo_stream(component:, status: :ok, method: nil)
      modify_via_turbo_stream(component:, action: :replace, status:, method:)
    end

    def remove_via_turbo_stream(component:, status: :ok)
      modify_via_turbo_stream(component:, action: :remove, status:)
    end

    def modify_via_turbo_stream(component:, action:, status:, method: nil)
      @turbo_status = status
      turbo_streams << component.render_as_turbo_stream(
        view_context:,
        action:,
        method:
      )
    end

    def append_via_turbo_stream(component:, target_component:)
      turbo_streams << target_component.insert_as_turbo_stream(component:, view_context:, action: :append)
    end

    def prepend_via_turbo_stream(component:, target_component:)
      turbo_streams << target_component.insert_as_turbo_stream(component:, view_context:, action: :prepend)
    end

    def add_before_via_turbo_stream(component:, target_component:)
      turbo_streams << target_component.insert_as_turbo_stream(component:, view_context:, action: :before)
    end

    def render_success_flash_message_via_turbo_stream(**)
      render_flash_message_via_turbo_stream(**, scheme: :success)
    end

    def render_error_flash_message_via_turbo_stream(**)
      render_flash_message_via_turbo_stream(**, scheme: :danger, icon: :stop)
    end

    def render_flash_message_via_turbo_stream(message:, component: OpPrimer::FlashComponent, **)
      instance = component.new(**).with_content(message)
      turbo_streams << instance.render_as_turbo_stream(view_context:, action: :flash)
    end

    def scroll_into_view_via_turbo_stream(target, behavior: :auto, block: :start)
      turbo_streams << OpTurbo::StreamComponent
        .new(action: :scroll_into_view, target:, behavior:, block:)
        .render_in(view_context)
    end

    def add_caption_to_input_element_via_turbo_stream(target, caption:, clean_other_captions: true)
      turbo_streams << OpTurbo::StreamComponent
        .new(action: :addInputCaption, target:, caption:, clean_other_captions:)
        .render_in(view_context)
    end

    def close_dialog_via_turbo_stream(target)
      turbo_streams << OpTurbo::StreamComponent.new(action: :closeDialog, target:).render_in(view_context)
    end

    def turbo_streams
      @turbo_streams ||= []
    end

    def turbo_status
      @turbo_status ||= :ok
    end
  end
end
