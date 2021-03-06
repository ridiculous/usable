require 'spec_helper'

describe Usable::Config do
  let(:mod) do
    Module.new do
      def yo(name)
        "#{name}? Whodat?"
      end
    end
  end

  describe '#available_methods' do
    context 'when there are no methods' do
      it 'returns an object we can #bind and #call' do
        expect(
          subject.available_methods[:yo].bind(self).call(1, []) do |_|
            puts 'never should i ever be here ' + __LINE__
          end
        ).to be_nil
      end
    end

    context 'when the method is found' do
      before do
        subject.add_module mod
      end

      it 'returns an object we can #bind and #call' do
        expect(subject.available_methods[:yo].bind(self).call('Ryan')).to eq "Ryan? Whodat?"
      end
    end
  end

  describe 'when defining a value with a block' do
    it "saves block and evaluates the first time it's called, returning the value" do
      expect(subject).to_not respond_to(:foo)
      n = 10
      subject.foo { n }
      n += 5
      expect(subject.foo).to eq 15
      n += 5
      # it should be memoized at this point
      expect(subject.foo).to eq 15
    end
  end

  describe '#method_missing' do
    context 'when an unknown error occurs' do
      before { subject.model { UndefinedModel } }

      it 'raises the appropriate error' do
        expect {
          subject.model
        }.to raise_error(NameError, 'uninitialized constant UndefinedModel')
      end
    end
  end

  describe '#respond_to(_missing)?' do
    context 'when the given -name- ends with "="' do
      it 'returns true' do
        expect(subject.foo).to be nil
        expect(subject).to respond_to :foo=
      end
    end

    context 'when the given -name- does not end with a "="' do
      context 'when the -name- is defined on @spec' do
        before { subject.spec[:foo] = :ok }

        it 'returns true' do
          expect(subject).to respond_to :foo
        end
      end

      context 'when neither subject nor @spec respond to the given -name-' do
        it 'returns false' do
          expect(subject).to_not respond_to :foo
        end
      end
    end
  end

  describe 'coercions' do
    describe '#to_hash' do
      it 'returns the hash representation of the spec' do
        expect(subject.to_hash).to eq({})
        subject.spec[:foo] = :ok
        expect(subject.to_hash).to eq foo: :ok
      end
    end

    describe '#to_h' do
      it 'returns the hash representation of the spec' do
        expect(subject.to_h).to eq({})
        subject.spec[:foo] = :ok
        expect(subject.to_h).to eq foo: :ok
      end

      it 'does not add to_h as a key to @spec' do
        expect(subject.to_h).to eq({})
        expect(subject.spec.marshal_dump).to_not have_key(:to_h)
      end

      context 'with block specs' do
        before do
          subject.foo { 'bar' }
          subject.baz = :buzz
          subject.bad = :ok
        end

        it 'includes the block value in the result' do
          expect(subject.to_h).to eq foo: 'bar', baz: :buzz, bad: :ok
        end

        it 'removes the method from the @lazy_loads cache' do
          expect(subject.instance_variable_get(:@lazy_loads)).to_not be_empty
          subject.to_h
          expect(subject.instance_variable_get(:@lazy_loads)).to be_empty
        end

        context 'when combined with other usables that override it with an options hash' do
          let(:klass) { Class.new { extend Usable } }
          before do
            mod.extend Usable
            mod.config do
              host { 'local' }
            end
            klass.usable mod, host: 'prod'
          end

          it 'returns the overridden value of the new usable' do
            expect(klass.usables.to_h).to eq :host => 'prod'
            expect(klass.usables.host).to eq 'prod'
          end

          it 'does not modify source module' do
            expect(mod.usables.to_h).to eq :host => 'local'
            expect(mod.usables.host).to eq 'local'
          end
        end

        context 'when combined with other usables that override it with a block' do
          let(:klass) { Class.new { extend Usable } }
          before do
            mod.extend Usable
            mod.config do
              host { 'local' }
            end
            klass.usable mod do
              host { 'prod' }
            end
          end

          it 'returns the overridden value of the new usable' do
            expect(klass.usables.to_h).to eq :host => 'prod'
            expect(klass.usables.host).to eq 'prod'
          end

          it 'does not modify source module' do
            expect(mod.usables.to_h).to eq :host => 'local'
            expect(mod.usables.host).to eq 'local'
          end
        end
      end
    end
  end

  describe '#merge' do
    before do
      subject.foo { 'bar' }
      subject.buzz = :ok
    end

    it 'returns a new hash with the given attributes merged in with the defaults' do
      expect(subject.merge(buzz: :off)).to eq(foo: 'bar', buzz: :off)
      expect(subject.merge(foo: nil)).to eq(foo: nil, buzz: :ok)
      expect(subject.foo).to eq 'bar'
      expect(subject[:buzz]).to eq :ok
    end
  end

  describe '#merge' do
    before do
      subject.foo { 'bar' }
      subject.buzz = :ok
    end

    it 'updates @spec with the given attributes' do
      expect(subject.buzz).to eq :ok
      subject.merge!(buzz: :off, dat: 'newnew')
      expect(subject.buzz).to eq :off
      expect(subject.dat).to eq 'newnew'
    end

    it 'does not update lazy loaded values (blocks)' do
      subject.merge!(foo: nil)
      expect(subject.foo).to eq 'bar'
      # Can update after called
      subject.merge!(foo: nil)
      expect(subject[:foo]).to eq nil
    end

    it 'accepts strings and symbols' do
      subject.merge! 'buzz' => 'meeeeee'
      expect(subject.buzz).to eq 'meeeeee'
      expect(subject[:buzz]).to eq 'meeeeee'
    end

    it 'returns itself' do
      expect(subject.merge!(buzz: :off)).to be subject
    end
  end

  describe '#initialize' do
    it 'assigns the given options as specs' do
      subject = described_class.new foo: 'bar'
      expect(subject.foo).to eq 'bar'
    end
  end

  describe '#each' do
    before do
      subject.foo { 'bar' }
      subject.baz = :buzz
    end

    it 'renders each item currently in the @spec' do
      subject.each do |key, val|
        expect(key).to eq :baz
        expect(val).to eq :buzz
      end
    end
  end

  describe '#freeze' do
    before do
      subject.foo { 'bar' }
      subject.baz = :buzz
    end

    it 'freezes the subject' do
      expect(subject).to_not be_frozen
      subject.freeze
      expect(subject).to be_frozen
    end

    it 'eager-loads any lazy block specs' do
      expect(subject[:foo]).to eq nil
      subject.freeze
      expect(subject[:foo]).to eq 'bar'
    end

    it 'does not call method_missing after freeze' do
      expect(subject).to_not receive(:method_missing)
      subject.freeze
      expect(subject.foo).to eq 'bar'
      expect(subject.baz).to eq :buzz
    end

    it 'raises an error trying to update a attribute' do
      expect {
        subject.freeze
        subject.foo = 42
      }.to raise_error(RuntimeError, /can't modify frozen/)
    end
  end

  describe 'marshalling' do
    before do
      subject.foo { 'bar' }
      subject.baz = :buzz
    end

    it 'can be marshalled' do
      new_config = Marshal.load(Marshal.dump(subject))
      expect(new_config.baz).to eq :buzz
      expect(new_config.foo).to eq 'bar'
      new_config.foo << 's'
      expect(new_config.foo).to eq 'bars'
      expect(subject.foo).to eq 'bar'
    end
  end

  describe 'include?' do
    before do
      subject.baz = :buzz
      subject.lazy_foo { 'bar' }
    end

    it 'returns boolean depending on whether the @spec contains the key' do
      expect(subject.include?(:baz)).to eq true
      expect(subject.include?(:brazen)).to eq false
    end

    it 'accepts strings or symbols' do
      expect(subject.include?('baz')).to eq true
      expect(subject.include?(:baz)).to eq true
    end

    it 'works with lazy loaded attrs' do
      expect(subject.include?('lazy_foo')).to eq true
      expect(subject.include?(:lazy_foo)).to eq true
    end

    context 'works when frozen' do
      before { subject.freeze }

      it 'returns boolean depending on whether the @spec contains the key' do
        expect(subject.include?(:baz)).to eq true
        expect(subject.include?(:brazen)).to eq false
      end

      it 'accepts strings or symbols' do
        expect(subject.include?('baz')).to eq true
        expect(subject.include?(:baz)).to eq true
      end

      it 'works with lazy loaded attrs' do
        expect(subject.include?('lazy_foo')).to eq true
        expect(subject.include?(:lazy_foo)).to eq true
      end
    end
  end

  describe 'calling unknown attribute when frozen' do
    before do
      subject.foo { 'bar' }
      subject.freeze
    end

    it 'returns nil' do
      expect(subject.foo).to eq 'bar'
      expect(subject.brazen).to eq nil
    end
  end
end
