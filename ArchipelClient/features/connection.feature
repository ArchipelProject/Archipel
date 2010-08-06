Feature: connection

    # Scenario: Connexion fails
    #     Given the application is running
    #     When I write "controller2@virt-hyperviseur" in the textfield with tag "connJID"
    #         And I write "password" in the textfield with tag "connPassword"
    #         And I write "wrong service" in the textfield with tag "connService"
    #         And I press the button with title "Connect"
    #     Then the application is not connected because connection fails


    Scenario: Connect with controller2@virt-hyperviseur
        Given the application is running
        When I write "controller2@virt-hyperviseur" in the textfield with tag "connJID"
            And I write "password" in the textfield with tag "connPassword"
            And I write "/http-bind" in the textfield with tag "connService"
            And I press the button with title "Connect"
        Then the application is connected
  