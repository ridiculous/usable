require 'spec_helper'

describe Usable::ModExtender do
  subject { Class.new }

  let(:vanilla) { Module.new { def foo(bar: 'bazz') bar end } }
  let(:chocolate) { Module.new }

  describe '#call' do
    it 'can extend a class with a vanilla module' do
      expect {
        described_class.new(vanilla).call(subject)
      }.to change { subject.instance_methods.include?(:foo) }.from(false).to(true)
    end

    it 'can extend a module with a vanilla module' do
      expect {
        described_class.new(vanilla).call(chocolate)
      }.to change { chocolate.instance_methods.include?(:foo) }.from(false).to(true)
    end

    context 'when target is "usable"' do
      before do
        subject.extend Usable
        subject.config do
          cone false
        end
      end

      it 'copies over the usables good stuff' do
        expect(subject.usables).to receive(:add_module).with(vanilla)
        described_class.new(vanilla).call(subject)
      end
    end
  end
end
