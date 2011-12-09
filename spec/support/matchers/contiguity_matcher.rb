# Usage examples:
#   folder.documents.should be_contiguous
#   folder.documents.should be_contiguous.starting_at(1)
RSpec::Matchers.define :be_contiguous do

  match do |array|
    @start ||= 0
    array.each_with_index do |current, index|
      current.reload.position.should == index + @start
    end
  end

  def starting_at(start)
    @start = start
    self
  end

  failure_message_for_should do |actual|
    message = "expected that"
    actual.each do |current|
      message << " [#{current.id}, #{current.position}]"
    end
    message << " would be contiguous"
  end

end