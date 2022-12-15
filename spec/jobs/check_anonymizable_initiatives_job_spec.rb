# frozen_string_literal: true

require "spec_helper"

describe CheckAnonymizableInitiativesJob do
  subject { described_class }

  it "doesn't raise an error" do
    expect { subject.perform_now }.not_to raise_error
  end

  it "calls the service" do
    expect(Decidim::CheckAnonymizableInitiativesService).to receive(:run)
    subject.perform_now
  end
end
