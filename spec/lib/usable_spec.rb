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

  describe "#use" do
    context "unless (self < mod)" do
      it "calls :send with :include and -mod-" do
        expect(subject).to receive(:include).with(mod)
        subject.use mod
      end
    end

    context "when (self < mod)" do
      before { subject.use mod }

      it "doesn't call :send" do
        expect(subject).to_not receive(:include)
        subject.use mod
      end
    end

    context "when block_given?" do
      it "yields @config to the given block" do
        expect {
          subject.use mod do |config|
            config.max_versions = 10
          end
        }.to change(subject.config, :max_versions).from(nil).to(10)
      end
    end

    context "not block_given? we assume it's a hash" do
      it "assign the values to @config" do
        expect {
          subject.use Versionable, table_name: 'custom'
        }.to change(subject.config, :table_name).from(nil).to('custom')
      end
    end
  end

end
