//
//  View_EventSelection.swift
//  EventFinder
//
//  Finished by Gia Bao Phi and Shashank Rao on 4/17/25.
//

import SwiftUI

// This is one of the View sections which deals with the preference selection process
// This is in alignment with the View portion of the MVVM
// The reason the Views have been separated into different files is because, when making an application look nice, the View's generally take a lot of lines to configure everything nicely. For all the different views we have, it would be around 700 lines of code, which would look really clunky. As a result, we have decided that the best approach is to split them up, so that no one file seems too overwhelming or complicated

// Main view that deals with preference selection
struct EventSelectionView: View
{
    // The observed object that gets the VM passed into it
    @ObservedObject var viewModel: EventFinderViewModel
    // Another passed on variable to signify whether this is the first time the user is launching the app (onboarding process) or not
    var isOnboarding: Bool = false
    
    // Necessary variables such as the selected preference types and the location
    @State private var selectedTypes: Set<String> = []
    @State private var location: String = ""
    
    var body: some View {
        VStack
        {
            // Title text that shows the appropriate text based on whether the passed on boolean signifies a first launch of the app or a relaunch
            // This relies heavily on the ternary operator that Swift provides (also in other languages too) for concise code and lack of redundancy
            /*
             https://www.hackingwithswift.com/sixty/3/7/the-ternary-operator
             */
            
            // Self explanatory title text
            
            Text(isOnboarding ? "Set Your Preferences" : "Edit Preferences")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            // Self explanatory subtitle text
            Text("What type of events are you interested in?")
                .font(.headline)
                .foregroundColor(AppColors.text.opacity(0.7))
                .padding(.bottom)
            
            // This is another section where we tried to go above and beyond what we are used to in order to create a better UI experience for the user. With the use of a formatted LazyVGrid, we were able to incoporate a better looking selection UI than what we had previously implemented in our 10% implementation
            /*
             https://developer.apple.com/documentation/swiftui/lazyvgrid
             */
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 15)
            {
                // The iterable nature of EventType makes it a fairly simple implementation. We just need to loop through all the EventTypes and give the information to our helper view which will create the UI layout for it.
                ForEach(EventType.allTypes)
                { eventType in
                    EventTypeCard(
                        eventType: eventType,
                        isSelected: selectedTypes.contains(eventType.id),
                        onToggle:
                        {
                            // Simple logic that deals with the selection and unselection of the VGrid items by either removing or inserting it.
                            if selectedTypes.contains(eventType.id)
                            {
                                selectedTypes.remove(eventType.id)
                            } else {
                                selectedTypes.insert(eventType.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
            
            // VStack that handles the location input
            VStack(alignment: .leading, spacing: 8)
            {
                // Self explanatory explainer text
                Text("Enter your location (only city names please):")
                    .font(.headline)
                    .foregroundColor(AppColors.text)
                    .padding(.top)
                
                // HStack that handles the location text field
                // Autocapitalization to make it easier in future logic
                HStack
                {
                    TextField("City name (e.g., New York, Phoenix)", text: $location)
                        .padding(10)
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                        .autocapitalization(.words)
                }
            }
            .padding(.horizontal)
            .padding(.top)
            
            Spacer()
            
            // If the view model throws an error for some reason, this shows it to the user
            if let error = viewModel.error
            {
                Text(error)
                    .foregroundColor(.red)
                    .padding()
            }
            
            // Button that saves the preference
            // Ternary operator text because based on first launch or relaunch, we will display different text on the button
            Button(action: savePreferences)
            {
                Text(isOnboarding ? "Find Events" : "Update Preferences")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(AppColors.primary)
                    .cornerRadius(15)
            }
            .padding()
            .disabled(location.isEmpty)
        }
        // Self explanatory parameters
        // Notable on appearing on this screen we call a helper function that loads the current preferences for the user. Very helpful
        .background(AppColors.background)
        .onAppear(perform: loadCurrentPreferences)
        .navigationTitle(isOnboarding ? "Set Preferences" : "Edit Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // Self explanatory helper function that just grabs the current user preferences if they have any and displays it to the user when they click on the screen.
    private func loadCurrentPreferences()
    {
        selectedTypes = Set(viewModel.selectedEventTypes)
        location = viewModel.location
    }
    
    // Useful helper function that saves the user preferences on button press
    private func savePreferences()
    {
        // Simply updates the variables first
        viewModel.selectedEventTypes = Array(selectedTypes)
        viewModel.location = location
        
        // Based on whether this is a first launch or a relaunch, we either signify completion of the onboarding process so that the view model can handle the rest of the user experience accordingly or we just save the preferences and fetch the updated events for them
        if isOnboarding
        {
            viewModel.completeOnboarding()
        } else {
            viewModel.saveUserPreferences()
            viewModel.fetchEvents()
        }
    }
}

// This is the helper view that creates the UI layout for the VGrid items for the user in an appealing way
struct EventTypeCard: View
{
    // The passed on parameters
    let eventType: EventType
    let isSelected: Bool
    let onToggle: () -> Void
    
    var body: some View {
        // Each VGrid item is a button that, when pressed, will activate the onToggle function that was passed to it (see above for the explanation of the onToggle function)
        Button(action: onToggle)
        {
            // The layout we decided on and thought would be best was an image and then text below
            // The image is just obtained from the Apple Library's icon and the text is just the self explanatory text
            VStack(spacing: 12)
            {
                Image(systemName: eventType.iconName)
                    .font(.system(size: 30))
                    // Color changes on toggle. This is because selecting the event makes the background blue, so we change the image to white to keep the contrast and design flowing
                    .foregroundColor(isSelected ? .white : AppColors.primary)
                
                Text(eventType.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    // Color changes on toggle. This is because selecting the event makes the background blue, so we change the text to white to keep the contrast and design flowing
                    .foregroundColor(isSelected ? .white : AppColors.text)
            }
            // Necessary self explanatory parameters
            // Notable the .background handles the logic of changing the background to blue if it has been selected and a gray color if not
            .frame(maxWidth: .infinity)
            .padding()
            .background(isSelected ? AppColors.primary : AppColors.VGridbackground)
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// A preview of the screen that was used when making it to check design
#Preview {
    EventSelectionView(viewModel: EventFinderViewModel())
        .modelContainer(for: [Event.self, UserPreferences.self])
}

