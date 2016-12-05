require 'spec_helper'
unless require 'usable/struct'
  puts %Q(INFO: We've already included Usable::Struct, you can now remove "#{__FILE__}:#{__LINE__}")
end

describe 'Usable::Struct()' do
  class TestStruct < Usable::Struct(name: 'Ryan', age: 29, contact: false)
    config do
      call_out { :ok }
    end
  end

  describe 'class behavior' do
    it 'sets the correct usables' do
      expect(TestStruct.usables[:name]).to eq 'Ryan'
      expect(TestStruct.usables[:age]).to eq 29
      expect(TestStruct.usables[:contact]).to eq false
      expect(TestStruct.usables.call_out).to eq :ok
    end
  end

  describe 'instance behavior' do
    subject { TestStruct.new }

    it 'sets the correct default values' do
      expect(subject.attrs[:name]).to eq 'Ryan'
      expect(subject.attrs[:age]).to eq 29
      expect(subject.attrs[:contact]).to eq false
      expect(subject.attrs[:call_out]).to eq :ok
    end

    it 'defines attributes as accessor methods' do
      expect(subject).to respond_to :name
      expect(subject).to respond_to :age
      expect(subject).to respond_to :contact
      subject.name = 'Bryan'
      subject.age = :old
      subject.contact = true
      expect(subject.name).to eq 'Bryan'
      expect(subject.age).to eq :old
      expect(subject.contact).to eq true
      subject.contact = false
      expect(subject.contact).to eq false
    end

    it 'allows defaults to be overridden' do
      subject = TestStruct.new name: 'foo', age: nil, someotherstuff: 'here'
      expect(subject.attrs[:someotherstuff]).to eq 'here'
      expect(subject).to_not respond_to :someotherstuff
      expect(subject.name).to eq 'foo'
      expect(subject.age).to eq nil
      expect(subject.contact).to eq false
    end
  end
end
