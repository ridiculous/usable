require "spec_helper"

describe Usable do
  module Versionable
    def versions
      "Saving #{self.class.config.max_versions} versions to #{self.class.config.table_name} table"
    end

    def destroy_version
      "destroying version"
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

      it "uses the config in the method calls" do
        subject.usable mod, table_name: 'versions' do |config|
          config.max_versions = 10
        end
        expect(subject.new.versions).to eq "Saving 10 versions to versions table"
      end
    end

    context "not block_given? we assume it's a hash" do
      it "assign the values to @config" do
        expect {
          subject.usable Versionable, table_name: 'custom'
        }.to change(subject.config, :table_name).from(nil).to('custom')
      end
    end

    context 'when given the :only option' do
      it 'defines the specified method' do
        subject.usable Versionable, only: :destroy_version
        expect(subject.new.destroy_version).to eq "destroying version"
      end

      it 'defines the specified methods' do
        subject.usable Versionable, only: [:destroy_version, :versions]
        expect(subject.new.destroy_version).to eq "destroying version"
        expect(subject.new.versions).to match(/saving/i)
      end

      it 'stubs out the other methods to return nil' do
        subject.usable Versionable, only: :destroy_version
        expect(subject.new.destroy_version).to eq "destroying version"
        expect(subject.new.versions).to be_nil
      end
    end
  end

end
