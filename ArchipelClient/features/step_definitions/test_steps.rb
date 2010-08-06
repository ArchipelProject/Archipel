Given /^the application is running$/ do
  windows = app.gui.wait_for "//CPButton[title='Connect']"
  
  raise "Application didn't start" if windows.nil?
end

When /^I press the button with title "([^\"]*)"$/ do |arg1|
  app.gui.press "//CPButton[title='#{arg1}']"
end

When /^I write "([^\"]*)" in the textfield with tag "([^\"]*)"$/ do |arg1, arg2|
  app.gui.fill_in arg1, "//CPTextField[tag='#{arg2}']"
end


Then /^the application is connected$/ do
  windows = app.gui.wait_for "//CPWindow[title='Archipel']"
  
  raise "Cannot login" if windows.nil?
end

