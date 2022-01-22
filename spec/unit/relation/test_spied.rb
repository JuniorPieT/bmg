require 'spec_helper'
module Bmg
  module Relation
    describe Spied do

      let(:base) {
        Relation.new [{a: 1}]
      }

      let(:spied) {
        base.spied(spy)
      }

      let(:spy) {
        ->(r){ puts r }
      }

      class SpyWithMeasure
        attr_accessor :seen

        def measure(relation, &bl)
          self.seen = relation
          bl.call
        end
      end

      describe "algebra" do

        it 'forwards all algebra methods' do
          r = spied.restrict(a: 1)
          expect(r).to be_a(Spied)
          expect(operand(r)).to be_a(Operator::Restrict)
          expect(predicate_of(operand(r))).to eql(Predicate.eq(a: 1))
        end

        it 'unspies right operands' do
          r = spied.matching(base.spied(spy))
          expect(r).to be_a(Spied)
          expect(operand(r)).to be_a(Operator::Matching)
          expect(left_operand(operand(r))).to be(base)
          expect(right_operand(operand(r))).not_to be_a(Operator::Spied)
        end

      end # algebra

      describe "each" do
        it 'calls the spy but keep eaching normally' do
          seen = nil
          spied = base.spied(->(r){
            seen = r
          })
          expect(spied.to_a).to eql(base.to_a)
          expect(seen).to be(spied)
        end

        it 'calls spy''s measure if it exists' do
          spy = SpyWithMeasure.new
          spied = base.spied(spy)
          expect(spied.to_a).to eql(base.to_a)
          expect(spy.seen).to be(spied)
        end
      end

      describe "count" do
        it 'calls the spy but keep counting normally' do
          seen = nil
          spied = base.spied(->(r){
            seen = r
          })
          expect(spied.count).to eql(1)
          expect(seen).to be(spied)
        end

        it 'calls spy''s measure if it exists' do
          spy = SpyWithMeasure.new
          spied = base.spied(spy)
          expect(spied.count).to eql(1)
          expect(spy.seen).to be(spied)
        end
      end

    end
  end
end
