require "spec_helper"

describe Usable do
  subject { Class.new { include Usable }.new }

  describe "#config" do
    it "assigns @config" do
    end
  end

  describe "#use" do
    context "unless (self < mod)" do
      before {}

      it "returns send(:include, mod)" do
      end
    end

    context "when (self < mod)" do
      before {}
    end
    context "when block_given?" do
      before {}

      it "returns yield(config)" do
      end
    end

    context "not block_given?" do
      before {}

      it "returns options.each { |k, v| config.public_send('\#{k}=', v) }" do
      end
    end
  end

end
