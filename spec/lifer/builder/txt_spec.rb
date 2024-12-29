require "spec_helper"

RSpec.describe Lifer::Builder::TXT do
  let(:project) { Support::LiferTestHelpers::TestProject.new files:, config: }

  describe ".execute" do
    subject { described_class.execute(root: project.root) }

    let(:config) { nil }
    let(:files) {
      {
        "text_file.txt" => nil,
        "non_text_file.md" => nil,
        "subdirectory_one/text_file_2.txt" => nil
      }
    }

    it "generates a text file for each text entry" do
      expect { subject }
        .to change {
          Dir.glob("#{project.brain.output_directory}/**/*.txt").count
        }
        .from(0)
        .to(2)
    end

    it "errors out when there's a file conflict" do
      File.open("#{project.brain.output_directory}/text_file.txt", "w") {
        _1.write "Pre-existing file."
      }

      expect { subject }.to raise_error(
        RuntimeError,
        /Cannot build HTML file because.* already exists/
      )
    end

    it "generates text files in the correct subdirectories" do
      expect { subject }
        .to change {
          Dir
            .glob("#{project.brain.output_directory}/subdirectory_one/**/*.txt")
            .count
        }
        .from(0)
        .to(1)
    end
  end

  describe ".name" do
    subject { described_class.name }

    it { is_expected.to eq :txt }
  end
end
