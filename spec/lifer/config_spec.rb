require "spec_helper"

RSpec.describe Lifer::Config do
  let(:config) { described_class.build(file: file) }

  describe "#collectionables" do
    subject { config.collectionables }

    context "when there are potential collections" do
      let(:file) { support_file "root_with_entries/.config/lifer.yaml" }

      it "returns any potential collections" do
        expect(subject).to eq [:subdirectory_one]
      end
    end

    context "when there are no potential collections" do
      let(:file) {
        support_file "root_with_entries/.config/no-collections-lifer.yaml"
      }

      it { is_expected.to eq [] }
    end
  end

  describe "#file" do
    subject { config.file }

    context "when given a non-existent file" do
      let(:file) { "../haha" }

      it "notifies the user there's no configuration file being loaded" do
        expect { subject }
          .to output(/^No configuration file at/)
          .to_stdout
      end
    end

    context "when given an existing file" do
      let(:file) { support_file "root_with_entries/.config/lifer.yaml" }

      it "doesn't load the default configuration file" do
        expect { subject }
          .not_to output(/^No configuration file at/)
          .to_stdout
      end

      it "uses the given config file" do
        expect(subject).to be_a Pathname
        expect(subject.to_s).to end_with "root_with_entries/.config/lifer.yaml"
      end
    end
  end

  describe "#setting" do
    subject { config.setting name, collection_name: collection.name }

    let(:file) { support_file "root_with_entries/.config/lifer.yaml" }
    let(:name) { :layout_file }
    let(:collection) {
      Lifer::Collection.generate name: :subdirectory_one,
        directory: support_file("root_with_entries/subdirectory_one")
    }
    let(:raw_settings_hash) { {} }

    before do
      allow(Lifer::Utilities)
        .to receive(:symbolize_keys)
        .and_return(raw_settings_hash)
    end

    context "with a collection" do
      context "that has a collection-specific setting available" do
        before do
          raw_settings_hash
            .merge!({subdirectory_one: {layout_file: "collection-layout-file"}})
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

    let(:file) { support_file "root_with_entries/.config/lifer.yaml" }

    it "loads some YAML" do
      expect(subject).to eq(
        {
          subdirectory_one: {uri_strategy: "pretty"},
          uri_strategy: "simple"
        }
      )
    end
  end
end
