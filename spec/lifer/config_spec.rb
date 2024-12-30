require "spec_helper"

RSpec.describe Lifer::Config do
  let(:config) { described_class.build file: file, root: root }
  let(:root) {
    temp_dir_with_files "entry.md" => nil,
      "named_collection/sub.md" => nil
  }
  let(:file) { temp_file "temp.yaml", config_file_contents }

  describe "#collectionables" do
    subject { config.collectionables }

    context "when there are potential collections" do
      let(:config_file_contents) {
       <<~CONFIG
         unregistered_setting: does nothing
         uri_strategy: simple
         named_collection:
           uri_strategy: pretty
        CONFIG
      }

      it "returns any potential collections" do
        expect(subject).to eq [:named_collection]
      end
    end

    context "when there are no potential collections" do
      let(:config_file_contents) { "uri_strategy: simple" }

      it { is_expected.to eq [] }
    end
  end

  describe "#file" do
    subject { config.file }

    context "when given a non-existent file" do
      let(:file) { "../haha" }

      it "notifies the user there's no configuration file being loaded" do
        allow(ENV).to receive(:[]).and_call_original
        allow(ENV).to receive(:[]).with("LIFER_ENV").and_return("not-test")

        expect { subject }
          .to output(/^No configuration file at/)
          .to_stdout
      end
    end

    context "when given an existing file" do
      let(:config_file_contents) { "" }

      it "doesn't load the default configuration file" do
        expect { subject }
          .not_to output(/^No configuration file at/)
          .to_stdout
      end

      it "uses the given config file" do
        expect(subject).to be_a Pathname
        expect(subject.to_s).to include "temp.yaml"
      end
    end
  end

  describe "#register_settings" do
    subject { config.register_settings setting }

    let(:config_file_contents) { "" }

    context "with a simple setting" do
      let(:setting) { :my_new_setting }

      it "adds the setting to the registered settings" do
        expect { subject }
          .to change { config.registered_settings }
          .from(Lifer::Config::DEFAULT_REGISTERED_SETTINGS)
          .to(Lifer::Config::DEFAULT_REGISTERED_SETTINGS + [:my_new_setting])
      end
    end

    context "with a setting tree" do
      let(:setting) {
        {
          my_new_setting: [
            :sub_setting_one,
            :sub_setting_two,
            sub_setting_three: [:sub_sub_setting_one]
          ]
        }
      }

      it "adds all the settings to the registered settings" do
        expect { subject }
          .to change {
            config.registered_settings.include?(setting)
          }
          .from(false)
          .to(true)
      end
    end
  end

  describe "#setting" do
    subject {
      config.setting name, collection_name: collection_name, strict: strict_mode
    }

    let(:config_file_contents) {
      <<~CONFIG
        unregistered_setting: does nothing
        uri_strategy: simple
        named_collection:
          uri_strategy: pretty
      CONFIG
    }
    let(:name) { :layout_file }
    let(:collection) {
      Lifer::Collection.generate name: :named_collection,
        directory: "#{root}/named_collection"
    }
    let(:collection_name) { :named_collection }
    let(:raw_settings_hash) { {} }
    let(:strict_mode) { false }

    before do
      allow(Lifer::Utilities)
        .to receive(:symbolize_keys)
        .and_return(raw_settings_hash)
    end

    context "when strict mode is enabled" do
      let(:strict_mode) { true }

      before do
        raw_settings_hash
          .merge!({named_collection: {layout_file: "collection-layout-file"}})
      end

      context "and no collection name is given" do
        let(:collection_name) { nil }

        it { is_expected.to be_nil }
      end

      context "and a collection is given" do
        it "returns the collection setting" do
          expect(subject).to eq "collection-layout-file"
        end
      end
    end

    context "with a collection" do
      context "that has a collection-specific setting available" do
        before do
          raw_settings_hash
            .merge!({named_collection: {layout_file: "collection-layout-file"}})
        end

        it "uses the collection setting" do
          expect(subject).to eq "collection-layout-file"
        end
      end

      context "that does not have a collection-specific setting available" do
        before do
          raw_settings_hash.merge!({layout_file: "root-layout-file"})
        end

        it "uses the root setting" do
          expect(subject).to eq "root-layout-file"
        end
      end

      context "that does not have any setting available" do
        it "uses the default setting" do
          expect(subject).to end_with "lib/lifer/templates/layout.html.erb"
        end
      end

      context "when given a nested setting name" do
        subject {
          config.setting :some,
            :double,
            :nested,
            collection_name: collection.name
        }

        it "finds the nested setting if available" do
          raw_settings_hash.merge! some: {double: {nested: "setting-value"}}

          expect(subject).to eq "setting-value"
        end

        it "returns nil if unavailable" do
          expect(subject).to be_nil
        end
      end
    end
  end

  describe "#settings" do
    subject { config.settings }

    let(:config_file_contents) {
     <<~CONFIG
       unregistered_setting: does nothing
       uri_strategy: simple
       named_collection:
         uri_strategy: pretty
      CONFIG
    }

    it "loads some YAML" do
      expect(subject).to eq(
        {
          named_collection: {uri_strategy: "pretty"},
          uri_strategy: "simple"
        }
      )
    end
  end
end
