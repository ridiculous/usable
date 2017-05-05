require 'spec_helper'
unless require 'usable/struct'
  puts %Q(INFO: We've already included Usable::Struct, you can now remove "#{__FILE__}:#{__LINE__}")
end

describe 'Usable::Struct()' do
  let(:test_struct) do
    Class.new(Usable::Struct(name: 'Ryan', age: 29, contact: false)) do
      config do
        call_out { :ok }
      end
    end
  end

  let(:test_string_key) do
    Class.new(Usable::Struct('foo' => 'bar', 'buzz' => :ok))
  end

  describe 'class behavior' do
    it 'sets the correct usables' do
      expect(test_struct.usables[:name]).to eq 'Ryan'
      expect(test_struct.usables[:age]).to eq 29
      expect(test_struct.usables[:contact]).to eq false
      expect(test_struct.usables.call_out).to eq :ok
    end

    it 'defines settings on the class' do
      expect(test_struct.age).to eq 29
      test_struct.age += 1
      expect(test_struct.age).to eq 30
    end
  end

  describe 'string key behavior' do
    subject { test_string_key.new(buzz: :fail) }

    it 'allows consistent access' do
      expect(subject.foo).to eq 'bar'
      expect(subject.buzz).to eq :fail
      expect(subject[:buzz]).to eq :fail
      expect(subject[:foo]).to eq 'bar'
    end
  end

  describe 'instance behavior' do
    subject { test_struct.new }

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
      subject = test_struct.new name: 'foo', age: nil, someotherstuff: 'here'
      expect(subject.attrs[:someotherstuff]).to eq 'here'
      expect(subject).to_not respond_to :someotherstuff
      expect(subject.name).to eq 'foo'
      expect(subject.age).to eq nil
      expect(subject.contact).to eq false
    end

    it 'can iterate over @attrs with +each+' do
      results = {}
      expect(subject).to respond_to :each
      subject.each do |key, val|
        results[key] = val
      end
      expect(results).to eq name: 'Ryan', age: 29, contact: false, call_out: :ok
    end
  end
end
