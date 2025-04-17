//
//  View_Onboarding.swift
//  EventFinder
//
//  Finished by Gia Bao Phi and Shashank Rao on 4/17/25.
//

import SwiftUI

// This is one of the View sections which deals with the onboarding process and the onboarding screen
// This is in alignment with the View portion of the MVVM
// The reason the Views have been separated into different files is because, when making an application look nice, the View's generally take a lot of lines to configure everything nicely. For all the different views we have, it would be around 700 lines of code, which would look really clunky. As a result, we have decided that the best approach is to split them up, so that no one file seems too overwhelming or complicated

// This is the onboarding view for when the user first launches the app
struct OnboardingView: View
{
    // ObservedObject for the VM and a boolean for the button
    @ObservedObject var viewModel: EventFinderViewModel
    @State private var isButtonTapped = false
    
    var body: some View {
        NavigationStack
        {
            ZStack
            {
                // Background color as specified in Assets file
                AppColors.background.edgesIgnoringSafeArea(.all)
                
                VStack(spacing: 20)
                {
                    // App logo that was generated on logo.com
                    // Necessary params to keep it all nice and tidy
                    Image("EventifyImage")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 400, height: 300)
                    
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    Spacer()
                    
                    // A brief list of the features we offer on this app
                    // A helper function is used in order to organize it better and for better abstraction (otherwise it would be way more redundant code and we tried to avoid major smelly code symptoms)
                    VStack(alignment: .leading, spacing: 15)
                    {
                        FeatureRow(icon: "magnifyingglass", text: "Find events tailored to you!")
                        FeatureRow(icon: "mappin.and.ellipse", text: "Search events in your area!")
                        FeatureRow(icon: "ticket", text: "Get event details and locations!")
                        FeatureRow(icon: "signature", text: "Sign up for the events!")
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 40)
                    
                    // The Get Started button which activates the boolean
                    Button(action: {
                        isButtonTapped = true
                    }) {
                        // All the necessary parameters to make it look clean
                        Text("Get Started")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.primary)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    // Send the user to the event selection view where they pick their preferences (this is their first time on the app so we must force it)
                    .navigationDestination(isPresented: $isButtonTapped) {
                        EventSelectionView(viewModel: viewModel, isOnboarding: true)
                    }
                    
                    Spacer()
                }
                .padding()
            }
            // We don't need the bar on the onboarding screen, it wouldn't look nice
            .navigationBarHidden(true)
        }
    }
}

// This is the onboarding view for a RELAUNCH of the app
// The user will have already selected their preferences at this point, so we will show them the onboarding screen but we redirect them to the events page and not the user preferences page. This is pretty much identical to the above method so I won't comment out every single thing
struct OnboardingStartView: View
{
    @Binding var showOnboarding: Bool
    
    var body: some View {
        ZStack
        {
            // Background color
            AppColors.background.edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20)
            {
                // App icon or logo
                Image("EventifyImage")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 400, height: 300)
                
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                Spacer()
                // Features list
                VStack(alignment: .leading, spacing: 15)
                {
                    FeatureRow(icon: "magnifyingglass", text: "Find events tailored to you!")
                    FeatureRow(icon: "mappin.and.ellipse", text: "Search events in your area!")
                    FeatureRow(icon: "ticket", text: "Get event details and locations!")
                    FeatureRow(icon: "signature", text: "Sign up for the events!")
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
                
                // Get started button
                Button(action: {
                    showOnboarding = false
                }) {
                    Text("GO!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(AppColors.primary)
                        .cornerRadius(15)
                }
                .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding()
        }
    }
}

// Helper function to reduce code redundancy
// Just formats the 4 lines that explain app functionality in a clean way
struct FeatureRow: View
{
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 15)
        {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(AppColors.accent)
                .frame(width: 36, height: 36)

            Text(text)
                .font(.body)
                .foregroundColor(AppColors.text)

            Spacer()
        }
    }
}

// A preview of the screen that was used when making it to check design
#Preview {
    LaunchView()
        .modelContainer(for: [Event.self, UserPreferences.self])
}
