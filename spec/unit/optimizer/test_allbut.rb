require 'spec_helper'
module Bmg
  describe "allbut optimization" do

    let(:relation) {
      Relation.new([
        { a: 1,  b: 2, c: 3 },
        { a: 11, b: 2, c: 33 }
      ])
    }

    before do
      class Operator::Page
        public :ordering, :page_index, :options
      end
    end

    context 'allbut on empty butlist' do
      subject{
        relation.allbut([])
      }

      it 'returns the operand itself' do
        expect(subject).to be(relation)
      end
    end

    context 'allbut.page' do
      subject{
        relation.allbut(butlist).page(ordering, 1, :page_size => 10)
      }

      context 'when keys are not known' do
        let(:butlist) {
          [:c]
        }
        let(:ordering) {
          [[:a, :asc]]
        }

        it 'is not optimized since duplicate removal changes the pages' do
          expect(subject).to be_a(Operator::Page)
          expect(operand).to be_a(Operator::Allbut)
          expect(operand(operand)).to be(relation)
        end
      end


      context 'when a key is preserved' do
        let(:relation) {
          Relation.new([
            { a: 1,  b: 2, c: 3 },
            { a: 11, b: 2, c: 33 }
          ]).with_type(Type::ANY.with_attrlist([:a, :b, :b]).with_keys([[:a]]))
        }
        let(:butlist) {
          [:c]
        }
        let(:ordering) {
          [[:a, :asc]]
        }

        it 'the page is pushed down the tree' do
          expect(subject).to be_a(Operator::Allbut)
          expect(subject.butlist).to eql(butlist)
          expect(operand).to be_a(Operator::Page)
          expect(operand.ordering).to eql(ordering)
          expect(operand.page_index).to eql(1)
          expect(operand.options).to eql(:page_size => 10)
          expect(operand(operand)).to be(relation)
        end
      end
    end

    context "allbut.restrict" do

      let(:predicate) {
        Predicate.gt(:a, 10)
      }

      let(:allbuted){ [:b] }

      subject{
        relation.allbut(allbuted).restrict(predicate)
      }

      it 'optimizes by pushing the restriction down' do
        expect(subject).to be_a(Operator::Allbut)
        expect(subject.send(:butlist)).to be(allbuted)
        expect(operand).to be_a(Operator::Restrict)
        expect(operand.send(:predicate)).to be(predicate)
      end

    end

    context "allbut.allbut" do

      context 'when butlist are disjoint' do
        subject{
          relation.allbut([:a]).allbut([:b])
        }

        it 'optimizes by unioning butlists' do
          expect(subject).to be_a(Operator::Allbut)
          expect(subject.send(:butlist)).to eql([:a, :b])
          expect(operand).to be(relation)
        end
      end

      context 'when butlist are not disjoint (make no sense, but ok)' do
        subject{
          relation.allbut([:a]).allbut([:b, :a])
        }

        it 'optimizes by unioning butlists' do
          expect(subject).to be_a(Operator::Allbut)
          expect(subject.send(:butlist)).to eql([:a, :b])
          expect(operand).to be(relation)
        end
      end

    end
  end
end
