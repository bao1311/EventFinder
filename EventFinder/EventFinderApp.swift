//
//  EventFinderApp.swift
//  EventFinder
//
//  Finished by Gia Bao Phi and Shashank Rao on 04/17/25.
//

import SwiftUI
import SwiftData

// This is the App section where @main is and where everything runs. Minimal changes were made here

@main
struct EventFinderApp: App {
    var body: some Scene {
        WindowGroup {
            LaunchView()
                .modelContainer(for: [Event.self, UserPreferences.self])
        }
    }
}

// Content View with a slight change
struct ContentView: View {
    // Obviously, we need the model context because we need to give it to the view model and we can do that here itself. That is why we declare the VM here itself and pass it on everywhere else to all other views as ObservedObject
    // Of course, we also have the UserPreferences that we need to know.
    // Also a first launch boolean that it takes in to help with first launch vs relaunch logic
    @Environment(\.modelContext) private var modelContext
    @Query var preferences: [UserPreferences]
    @State private var viewModel: EventFinderViewModel?
    var isFirstLaunch: Bool
    
    var body: some View {
        // Using Group because we need the .onAppear modifying parameter to apply to all of these different instances, and it helps make it easy. For more information on Group documentation, see EventListView
        Group
        {
            // Checks if there is a view model. If there isn't we will have to show a loading screen until there is one
            if let viewModel = viewModel
            {
                // If the user has not completed the onboarding process, we call the OnboardingView to make them complete it. The booleans in our viewmodel help a lot with this logic. If it is not their first launch, we just take them to the main tab view
                if isFirstLaunch || !viewModel.hasOnboarded {
                    OnboardingView(viewModel: viewModel)
                } else {
                    MainTabView(viewModel: viewModel)
                }
            } else {
                ProgressView("Loading...")
            }
        }
        .onAppear
        {
            // We need this to happen for every instance described above, which is why we use Group
            self.viewModel = EventFinderViewModel(modelContext: modelContext)
        }
    }
}

// This is a new view that we created in order to match the different onboarding views. Obviously, on a relaunch of the app, we still want the user to see the main launch screen, but not the preferences section, and this helps with that
struct LaunchView: View {
    // Necessary model context and booleans
    @State private var showOnboarding = true
    @Query var preferences: [UserPreferences]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        // Essentially, what is happening here is this. If the boolean is true, we call OnboardingStartView. That view does a lot of logic based decisions on what view to show as well. Otherwise, if the variable is false, we can just default back to ContentView which handles everything else well.
        Group
        {
            if showOnboarding
            {
                OnboardingStartView(showOnboarding: $showOnboarding)
            } else {
                // Check if preferences exist and if user has onboarded before
                if preferences.isEmpty || !preferences.first!.hasOnboarded
                {
                    ContentView(isFirstLaunch: true)
                } else {
                    ContentView(isFirstLaunch: false)
                }
            }
        }
    }
}

// This struct is another new struct that was added here because it deals with the App itself, not any particular view. It just sets the layout for the tabular design so that the user can switch between events and also updating their preferences seamlessly
struct MainTabView: View {
    // Obviously it is passed down the view model
    @ObservedObject var viewModel: EventFinderViewModel
    
    var body: some View {
        TabView
        {
            // The first thing shown is the EventListView which shows the list of events
            NavigationStack
            {
                EventListView(viewModel: viewModel)
            }
            // Appropriate label for it
            .tabItem {
                Label("Events", systemImage: "calendar")
            }
            
            // The second thing shown is the preferences tab where the user can update their preferences at any time.
            NavigationStack
            {
                EventSelectionView(viewModel: viewModel)
            }
            // Appropriate label for it
            .tabItem {
                Label("Preferences", systemImage: "gear")
            }
        }
    }
}

#Preview {
    LaunchView()
        .modelContainer(for: [Event.self, UserPreferences.self])
}
