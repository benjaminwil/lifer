require "spec_helper"
require "lifer/cli"

RSpec.describe "bin/lifer", type: :system do
  before do
    spec_lifer!
  end

  describe "bin/lifer (no arguments)" do
    subject {
      Dir.chdir(Lifer.root) do
        system "lifer"
      end
    }

    it "builds the Lifer project" do
      expect { subject }
        .to change { Dir.glob("#{Lifer.output_directory}/*").size }
        .from(0)
        .and output(/Using default configuration/)
        .to_stdout_from_any_process
    end
  end

  describe "bin/lifer build" do
    subject {
      Dir.chdir(Lifer.root) do
        system "lifer build"
      end
    }

    it "builds the Lifer project" do
      expect { subject }
        .to change { Dir.glob("#{Lifer.output_directory}/*").size }
        .from(0)
        .and output(/Using default configuration/)
        .to_stdout_from_any_process
    end
  end

  describe "bin/lifer haha" do
    subject {
      Dir.chdir(Lifer.root) do
        system "lifer haha"
      end
    }

    it "outputs a useful message" do
      expect { subject }
        .to output(/\e\[1mhaha\e\[0m is not a supported subcommand/i)
        .to_stdout_from_any_process
    end

    it "builds the Lifer project" do
      expect { subject }
        .to change { Dir.glob("#{Lifer.output_directory}/*").size }
        .from(0)
        .and output(/Using default configuration/)
        .to_stdout_from_any_process
    end
  end

  describe "bin/lifer help" do
    subject {
      Dir.chdir(Lifer.root) do
        system "lifer help"
      end
    }

    # FIXME:
    # `#to_stdout_from_any_process` is slow.
    #
    it "displays help text" do
      expect { subject }
        .to output(/Lifer, the static site generator/)
        .to_stdout_from_any_process
    end
  end

  describe "bin/lifer -h" do
    subject {
      Dir.chdir(Lifer.root) do
        system "lifer -h"
      end
    }

    # FIXME:
    # `#to_stdout_from_any_process` is slow.
    #
    it "displays help text" do
      expect { subject }
        .to output(/Lifer, the static site generator/)
        .to_stdout_from_any_process
    end
  end

  describe "bin/lifer serve" do
    subject {
      Dir.chdir(Lifer.root) do
        # FIXME:
        # Obviously, this is slow.
        #
        process_id = fork { exec "lifer serve" }
        sleep 3
        Process.kill "SIGTERM", process_id
      end
    }

    it "runs the dev server" do
      expect { subject }
        .to output(/Puma starting in single mode.../i)
        .to_stdout_from_any_process
    end
  end
end
