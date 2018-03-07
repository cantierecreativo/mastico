require "spec_helper"
require "rspec/expectations"

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

      context "with a Hash as parameter" do
        let(:options) do
          {
            query: "something",
            fields: {title: {boost: 1.0, types: [:term, :fuzzy]}}
          }
        end

        it "calls .query with the expected parameters" do
          expected = {
            bool: {
              should: [
                {
                  bool: {
                    should: [
                      {term: {title: {value: "something", boost: 1.0}}}
                    ],
                    minimum_should_match: 0
                  }
                },
                {
                  bool: {
                    should: [
                      {
                        fuzzy:
                          {title: {value: "something", fuzziness: 4, boost: 0.2}}
                      }
                    ],
                    minimum_should_match: 0
                  }
                }
              ]
            }
          }
          expect(scope).to have_received(:query).with(expected)
        end
      end

      context "with an array as parameter" do
        let(:options) do
          { query: "something", fields: [:title, :description] }
        end

        it "calls .query with the expected parameters" do
          expected = {
            bool: {
              should: [
                {
                  bool: {
                    should: [
                      {term: {title: {value: "something", boost: 1.0}}}
                    ],
                    minimum_should_match: 0
                  }
                },
                {
                  bool: {
                    should: [
                      {term: {description: {value: "something", boost: 1.0}}}
                    ],
                    minimum_should_match: 0
                  }
                },
                {
                  bool: {
                    should: [
                      {prefix: {title: {value: "something", boost: 0.7}}}
                    ],
                    minimum_should_match: 0
                  }
                },
                {
                  bool: {
                    should: [
                      {prefix: {description: {value: "something", boost: 0.7}}}
                    ],
                    minimum_should_match: 0
                  }
                },
                {
                  bool: {
                    should: [
                      {wildcard: {title: {value: "*something*", boost: 0.4}}}
                    ],
                    minimum_should_match: 0
                  }
                },
                {
                  bool: {
                    should: [
                      {
                        wildcard:
                         {description: {value: "*something*", boost: 0.4}}
                      }
                    ],
                    minimum_should_match: 0
                  }
                },
                {
                  bool: {
                    should: [
                      {
                        fuzzy:
                          {title: {value: "something", fuzziness: 4, boost: 0.2}}
                      }
                    ],
                    minimum_should_match: 0
                  }
                },
                {
                  bool: {
                    should: [
                      {
                        fuzzy: {
                          description:
                            {value: "something", fuzziness: 4, boost: 0.2}
                        }
                      }
                    ],
                    minimum_should_match: 0
                  }
                }
              ]
            }
          }
          expect(scope).to have_received(:query).with(expected)
        end
      end
    end
  end
end




