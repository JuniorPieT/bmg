require 'spec_helper'
module Bmg
  module Reader
    describe Csv do

      it 'works' do
        file = Path.dir/("example.csv")
        csv = Csv.new(Type::ANY, file)
        expect(csv.to_a).to eql([
          {id: "1", name: "Bernard Lambeau"},
          {id: "2", name: "Yoann;Guyot"}
        ])
      end

      it 'supports an io object' do
        (Path.dir/("example.csv")).open('r') do |io|
          csv = Csv.new(Type::ANY, io)
          expect(csv.to_a).to eql([
            {id: "1", name: "Bernard Lambeau"},
            {id: "2", name: "Yoann;Guyot"}
          ])
        end
      end

    end
  end
end
