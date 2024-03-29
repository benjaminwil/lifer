require "spec_helper"

RSpec.describe Lifer::Selection do
  describe "a selectionsubclass" do
    context "an only-initialized subclass" do
      let(:my_subclass) {
        Class.new described_class do
        end
      }

      it "is given a default name" do
        expect(my_subclass.name).to eq :unnamed_selection
      end

      it "raises an error if `#entries` is not implemented" do
        expect { my_subclass.generate.entries }
          .to raise_error NotImplementedError
      end
    end

    context "a well-formed, initialized subclass" do
      let(:my_subclass) {
        Class.new described_class do
          self.name = :my_selection

          def entries
            []
          end
        end
      }

      it "has a name" do
        expect(my_subclass.name).to eq :my_selection
      end

      it "implements `#entries`" do
        expect(my_subclass.generate.entries).to be_empty
      end
    end
  end
end
