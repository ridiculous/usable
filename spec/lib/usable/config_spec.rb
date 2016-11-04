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
end
