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
        before { subject.spec :foo, :ok }

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
        subject.spec :foo, :ok
        expect(subject.to_hash).to eq foo: :ok
      end
    end

    describe '#to_h' do
      it 'returns the hash representation of the spec' do
        expect(subject.to_h).to eq({})
        subject.spec :foo, :ok
        expect(subject.to_h).to eq foo: :ok
      end

      it 'does not add to_h as a key to @spec' do
        expect(subject.to_h).to eq({})
        expect(subject._spec.marshal_dump).to_not have_key(:to_h)
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
      end
    end
  end
end
