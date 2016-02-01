require "spec_helper"

describe Usable do
  module Versionable
    def versions
      "Saving #{self.class.config.max_versions} versions to #{self.class.config.table_name}"
    end
  end

  subject { Class.new { extend ::Usable } }

  let(:mod) { Versionable }

  describe "#config" do
    it "assigns @config" do
      expect(subject.config).to be_a Usable::Config
    end
  end

  describe "#usable" do
    context "unless (self < mod)" do
      it "calls :send with :include and -mod-" do
        expect(subject).to receive(:include).with(instance_of(Module))
        subject.usable mod
      end
    end

    context "when block_given?" do
      it "yields @config to the given block" do
        expect {
          subject.usable mod do |config|
            config.max_versions = 10
          end
        }.to change(subject.config, :max_versions).from(nil).to(10)
      end
    end

    context "not block_given? we assume it's a hash" do
      it "assign the values to @config" do
        expect {
          subject.usable Versionable, table_name: 'custom'
        }.to change(subject.config, :table_name).from(nil).to('custom')
      end
    end
  end

end
