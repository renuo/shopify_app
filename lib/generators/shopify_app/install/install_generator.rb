# frozen_string_literal: true

require "rails/generators/base"

module ShopifyApp
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      source_root File.expand_path("../templates", __FILE__)

      class_option :application_name, type: :array, default: ["My", "Shopify", "App"]
      class_option :scope, type: :array, default: ["read_products"]
      class_option :embedded, type: :string, default: "true"
      class_option :api_version, type: :string, default: nil

      def create_shopify_app_initializer
        @application_name = format_array_argument(options["application_name"])
        @scope = format_array_argument(options["scope"])
        @api_version = options["api_version"] || ShopifyAPI::LATEST_SUPPORTED_ADMIN_VERSION

        template("shopify_app.rb", "config/initializers/shopify_app.rb")
      end

      def create_session_store_initializer
        copy_file("session_store.rb", "config/initializers/session_store.rb")
      end

      def create_embedded_app_layout
        return unless embedded_app?

        copy_file("embedded_app.html.erb", "app/views/layouts/embedded_app.html.erb")
        copy_file("_flash_messages.html.erb", "app/views/layouts/_flash_messages.html.erb")

        if ShopifyApp.use_webpacker?
          copy_file("shopify_app.js", "app/javascript/shopify_app/shopify_app.js")
          copy_file("flash_messages.js", "app/javascript/shopify_app/flash_messages.js")
          copy_file("shopify_app_index.js", "app/javascript/shopify_app/index.js")
          append_to_file("app/javascript/packs/application.js", "require(\"shopify_app\")\n")
        elsif ShopifyApp.use_importmap?
          copy_file("shopify_app_importmap.js", "app/javascript/lib/shopify_app.js")
          copy_file("flash_messages.js", "app/javascript/lib/flash_messages.js")
          append_to_file("config/importmap.rb", "pin_all_from \"app/javascript/lib\", under: \"lib\"\n")
        else
          copy_file("shopify_app.js", "app/assets/javascripts/shopify_app.js")
          copy_file("flash_messages.js", "app/assets/javascripts/flash_messages.js")
        end
      end

      def mount_engine
        route("mount ShopifyApp::Engine, at: '/'")
      end

      def insert_hosts_into_development_config
        inject_into_file(
          "config/environments/development.rb",
          "  config.hosts = (config.hosts rescue []) << /\[-\\w\\.]+\\.ngrok\\.io/\n",
          after: "Rails.application.configure do\n"
        )
      end

      private

      def embedded_app?
        options["embedded"] == "true"
      end

      def format_array_argument(array)
        array.join(" ").tr('"', "")
      end
    end
  end
end
