# frozen_string_literal: true

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
require_module_spec_helper

RSpec.describe Storages::Storages::NextcloudContract, :storage_server_helpers, :webmock do
  let(:current_user) { create(:admin) }
  let(:storage) { build(:nextcloud_storage) }
  let(:mocked_host) { storage.host }

  let!(:capabilities_request) { mock_server_capabilities_response(mocked_host) }
  let!(:host_request) { mock_server_config_check_response(mocked_host) }

  # As the NextcloudContract is selected by the BaseContract to make writable attributes available,
  # the BaseContract needs to be instantiated here.
  subject { Storages::Storages::BaseContract.new(storage, current_user) }

  it "checks the storage url only when changed" do
    subject.validate
    expect(capabilities_request).to have_been_made.once
    expect(host_request).to have_been_made.once

    WebMock.reset_executed_requests!
    storage.save
    subject.validate
    expect(capabilities_request).not_to have_been_made
    expect(host_request).not_to have_been_made
  end

  describe "Nextcloud application credentials validation" do
    context "with valid credentials" do
      let(:storage) { build(:nextcloud_storage, :as_automatically_managed) }

      it "passes validation" do
        credentials_request = mock_nextcloud_application_credentials_validation(storage.host)

        expect(subject).to be_valid
        expect(credentials_request).to have_been_made.once
      end

      context "with invalid credentials" do
        let(:storage) { build(:nextcloud_storage, :as_automatically_managed) }

        it "fails validation" do
          credentials_request = mock_nextcloud_application_credentials_validation(storage.host, response_code: 401)

          expect(subject).not_to be_valid
          expect(subject.errors.to_hash).to eq({ password: ["is not valid."] })

          expect(credentials_request).to have_been_made.once
        end
      end

      context "with timeout" do
        let(:storage) { build(:nextcloud_storage, :as_automatically_managed) }

        it "fails validation" do
          credentials_request = mock_nextcloud_application_credentials_validation(storage.host, timeout: true)

          expect(subject).not_to be_valid
          expect(subject.errors.to_hash)
            .to eq({ password: ["could not be validated. Please check your storage connection and try again."] })

          # twice due to HTTPX retry plugin being enabled.
          expect(credentials_request).to have_been_made.twice
        end
      end

      context "with unknown error" do
        let(:storage) { build(:nextcloud_storage, :as_automatically_managed) }

        it "fails validation" do
          credentials_request = mock_nextcloud_application_credentials_validation(storage.host, response_code: 500)

          expect(subject).not_to be_valid
          expect(subject.errors.to_hash)
            .to eq({ password: ["could not be validated. Please check your storage connection and try again."] })

          expect(credentials_request).to have_been_made.once
        end
      end

      context "when the storage is not automatically managed" do
        let(:storage) { build(:nextcloud_storage, :as_not_automatically_managed) }

        it "skips credentials validation" do
          credentials_request = mock_nextcloud_application_credentials_validation(storage.host)

          expect(subject).to be_valid
          expect(credentials_request).not_to have_been_made
        end
      end

      context "when the storage host has a subpath" do
        let(:storage) { build(:nextcloud_storage, :as_automatically_managed, host: "https://host1.example.com/api") }

        it "passes validation" do
          credentials_request = mock_nextcloud_application_credentials_validation(storage.host)

          expect(subject).to be_valid
          expect(credentials_request).to have_been_made.once
        end
      end
    end

    context "when the storage host is nil" do
      let(:storage) { build(:nextcloud_storage, :as_automatically_managed, host: nil) }
      let(:mocked_host) { "https://example.com/unrelated" }

      before do
        allow(NextcloudApplicationCredentialsValidator).to receive(:new).and_call_original
      end

      it "fails validation" do
        expect(subject).not_to be_valid
        expect(subject.errors.to_hash).to eq({ host: ["is not a valid URL."] })
        expect(NextcloudApplicationCredentialsValidator).not_to have_received(:new)
      end
    end
  end

  describe "authentication_method validation" do
    let(:storage) { build(:nextcloud_storage, :as_not_automatically_managed, authentication_method:) }
    let(:authentication_method) { "two_way_oauth2" }

    it { is_expected.to be_valid }

    context "when the authentication method is oauth2_sso" do
      let(:authentication_method) { "oauth2_sso" }

      it { is_expected.to be_valid }
    end

    context "when the authentication method is unknown" do
      let(:authentication_method) { "magic_unicorns" }

      it { is_expected.not_to be_valid }
    end

    context "when the authentication method is missing" do
      let(:authentication_method) { nil }

      it { is_expected.not_to be_valid }
    end
  end

  describe "nextcloud_audience validation" do
    let(:storage) do
      build(:nextcloud_storage, :as_not_automatically_managed, authentication_method:, nextcloud_audience:)
    end

    context "when authentication happens through bidirectional OAuth 2.0" do
      let(:authentication_method) { "two_way_oauth2" }

      context "and there is no nextcloud_audience" do
        let(:nextcloud_audience) { nil }

        it { is_expected.to be_valid }
      end

      context "and there is a nextcloud_audience" do
        let(:nextcloud_audience) { "nextcloud" }

        it { is_expected.to be_valid }
      end
    end

    context "when authentication happens through a common IDP" do
      let(:authentication_method) { "oauth2_sso" }

      context "and there is no nextcloud_audience" do
        let(:nextcloud_audience) { nil }

        it { is_expected.not_to be_valid }
      end

      context "and there is a nextcloud_audience" do
        let(:nextcloud_audience) { "nextcloud" }

        it { is_expected.to be_valid }
      end
    end
  end
end
