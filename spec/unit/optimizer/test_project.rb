require 'spec_helper'
module Bmg
  describe 'project optimization' do
    context 'project.restrict' do
      let(:relation) {
        Relation.new([
          { a: 1,  b: 2 },
          { a: 11, b: 2 }
        ])
      }

      let(:predicate) {
        Predicate.gt(:a, 10)
      }

      let(:projected) {
        [:a]
      }

      subject {
        relation.project(projected).restrict(predicate)
      }

      it 'optimizes by pushing the restriction down' do
        expect(subject).to be_a(Operator::Project)
        expect(subject.send(:attrlist)).to be(projected)
        expect(operand).to be_a(Operator::Restrict)
        expect(operand.send(:predicate)).to be(predicate)
      end
    end

    context 'project.allbut' do
      let(:relation) {
        Relation.new([
          { a: 1,  b: 2 },
          { a: 11, b: 2 }
        ])
      }

      subject {
        relation.project([:a, :b]).allbut([:b])
      }

      it 'optimizes by removing allbut attributes from the projection' do
        expect(subject).to be_a(Operator::Project)
        expect(subject.send(:attrlist)).to eql([:a])
      end
    end
  end
end
