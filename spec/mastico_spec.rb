require "spec_helper"
require "rspec/expectations"

RSpec::Matchers.define :have_query do |type, field, boost = nil|
  match do |actual|
    args = ::RSpec::Mocks.space.proxy_for(actual).messages_arg_list
    first = args[0][0]
    parts = first[:bool][:should]
    true
  end
end

RSpec.describe Mastico do
  it "has a version number" do
    expect(Mastico::VERSION).not_to be nil
  end

  describe Mastico::Query do
    describe "#perform" do
      let(:scope) { double("chewy_scope") }
      let(:new_scope) { double("chewy_scope") }
      let(:options) do
        { query: "text", fields: [:title] }
      end

      let(:result) do
        Mastico::Query.new(options).perform(scope)
      end

      before do
        allow(scope).to receive(:query).and_return(new_scope)

        result
      end

      it "returns the new chewy scope" do
        expect(result).to eq(new_scope)
      end

      context "with an hash as parameter" do
        let(:options) do
          { query: "text", fields: {title: {boost: 1.0, types: [:term, :fuzzy]}} }
        end

        it "calls .query with the expected parameters" do
          expect(scope).to have_received(:query).with({:bool => {:should => [{:bool => {:should => [{:term => {:title => {:value => "text", :boost => 1.0}}}],:minimum_should_match => 0}},{:bool => {:should => [{:prefix => {:title => {:value => "text", :boost => 0.7}}}],:minimum_should_match => 0}},{:bool => {:should => [{:wildcard => {:title => {:value => "*text*", :boost => 0.4}}}],:minimum_should_match => 0}}]}})
        end
      end

      context "with an array as parameter" do
        let(:options) do
          { query: "text", fields: [:title, :description] }
        end

        it "calls .query with the expected parameters" do
          expect(scope).to have_received(:query).with({:bool => {:should => [{:bool => {:should => [{:term => {:title => {:value => "text", :boost => 1.0}}}], :minimum_should_match => 0}}, {:bool => {:should => [{:term => {:description => {:value => "text", :boost => 1.0}}}], :minimum_should_match => 0}}, {:bool => {:should => [{:prefix => {:title => {:value => "text", :boost => 0.7}}}], :minimum_should_match => 0}}, {:bool => {:should => [{:prefix => {:description => {:value => "text", :boost => 0.7}}}], :minimum_should_match => 0}}, {:bool => {:should => [{:wildcard => {:title => {:value => "*text*", :boost => 0.4}}}], :minimum_should_match => 0}}, {:bool => {:should => [{:wildcard => {:description => {:value => "*text*", :boost => 0.4}}}], :minimum_should_match => 0}}]}})
        end
      end
    end
  end
end
