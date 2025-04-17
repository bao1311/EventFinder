//
//  View_EventList.swift
//  EventFinder
//
//  Finished by Gia Bao Phi and Shashank Rao on 4/17/25.
//

import SwiftUI

// This is one of the View sections which deals with the event list process
// This is in alignment with the View portion of the MVVM
// The reason the Views have been separated into different files is because, when making an application look nice, the View's generally take a lot of lines to configure everything nicely. For all the different views we have, it would be around 700 lines of code, which would look really clunky. As a result, we have decided that the best approach is to split them up, so that no one file seems too overwhelming or complicated

// The main event list view
struct EventListView: View
{
    @ObservedObject var viewModel: EventFinderViewModel
    
    var body: some View {
        ZStack
        {
            // Main content
            VStack
            {
                // Uses a helpful bookkeeping variable in the VM
                // This boolean sets to true whenever fetchEvents is called, which means we should indicate to the user that we are attempting to fetch events. Hence, a progress view with "Fetching Events" when the boolean is true
                if viewModel.isLoading
                {
                    ProgressView("Fetching events...")
                        .padding()
                } else if viewModel.events.isEmpty {
                    // We always have to account for the fact that there are simply no events in the area that the user has mentioned (if they are in a rural area perhaps) so this takes care of that
                    emptyStateView
                } else {
                    // We use a List and a For Each loop like in a lot of previous lab implementations to display all of the events. A helper view is called to prevent messy code because it is rather long since there is a lot to format
                    List
                    {
                        ForEach(viewModel.events)
                        { event in
                            NavigationLink(destination: EventDetailView(event: event, viewModel: viewModel))
                            {
                                EventCardView(event: event)
                                    .listRowInsets(EdgeInsets())
                            }
                            // These are two qualities that made the UI appeal look messy. Since we already have backgrounds of our own, we don't need them so we just hide the properties
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    // For the sake of better UI layouts, we don't want a very inset List, which is automatic, so we set it to .plain which makes it less inset and better looking
                    /*
                     https://sarunw.com/posts/swiftui-list-style/
                     */
                    .listStyle(.plain)
                    .background(AppColors.background)
                }
                
                // Using the VM to check for errors and displaying appropriately
                if let error = viewModel.error
                {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
        }
        // Necessary parameters
        .navigationTitle("Events near \(viewModel.location)")
        .navigationBarTitleDisplayMode(.inline)
        // Notably, we have a toolbar item which basically acts as a "refresh" feature. It refreshes the events by calling the fetchEvents method again and is essentially used to refresh the events after updating preferences
        .toolbar
        {
            ToolbarItem(placement: .navigationBarTrailing)
            {
                Button(action: {
                    viewModel.fetchEvents()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
        }
    }
    
    // The helper view that we call to make a better UI design for the elements of the event view.
    struct EventCardView: View
    {
        // Naturally, it is passed the event which it is making the view for
        let event: Event
        
        var body: some View {
            HStack(alignment: .top, spacing: 15)
            {
                // Notably, we experimented with the Group feature here. Not really experimented per se but we needed it to prevent extremely messy code. There are a lot of different cases in this logic that you will see shortly to determine what image gets shown in the list row. Instead of dealing with the modifying parameters for each single case individually, the Group allows us to apply it to whichever image choice is chosen
                /*
                 https://developer.apple.com/documentation/swiftui/group
                 */
                Group
                {
                    // Obtain the URL from the event field because that is how the JSON gives images for Ticketmaster API
                    if let imageURL = event.imageURL, let url = URL(string: imageURL)
                    {
                        // AsyncImage is used because this is SwiftUI's way of displaying an image through a URL and not something in the Assets file or a system image
                        /*
                         https://developer.apple.com/documentation/swiftui/asyncimage
                         */
                        AsyncImage(url: url)
                        { phase in
                            // Basic switch statement but the cases rely on the success of the image loading
                            switch phase
                            {
                                // If the image loading is successful, we can just let the image be and apply the necessary modifying parameters
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                // If the image loading is a failure, we will either use ternary operator to display a relevant icon based on the event type name OR
                                // in the case that that doesn't work, we will use a default star fill icon that was used in the 10% implementation
                                case .failure(_):
                                    Image(systemName: EventType.findById(event.typeId)?.iconName ?? "star.fill")
                                        .font(.system(size: 30))
                                        .foregroundColor(AppColors.secondary)
                                        .padding()
                                // Simply display the loading progress view if there is an empty case
                                case .empty:
                                    ProgressView()
                                // Default SwiftUI standards dictate that EmptyView is the best for an unknown instance
                                @unknown default:
                                    EmptyView()
                            }
                        }
                    // If no image was given by the JSON for the event, we just do the same thing we did for the failure instance.
                    } else {
                        Image(systemName: EventType.findById(event.typeId)?.iconName ?? "star.fill")
                            .font(.system(size: 30))
                            .foregroundColor(AppColors.secondary)
                            .padding()
                    }
                }
                // These modifying parameters apply to ALL of the image options, no matter which one ended up being selected
                .frame(width: 80, height: 80)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                
                // Self explanatory VStack that just puts some basic explanatory information about the event
                VStack(alignment: .leading, spacing: 6)
                {
                    // Name of the event with modifying parameters. Notably, we set a line limit because we do not want a needlessly long title to mess up formatting
                    Text(event.name)
                        .font(.headline)
                        .lineLimit(2)
                        .foregroundColor(AppColors.text)
                    
                    // Name of the event's venue with modifying parameters. Notably, we set a line limit because we especially don't need a venue name messing up formatting
                    Text(event.venue)
                        .font(.subheadline)
                        .foregroundColor(AppColors.text.opacity(0.8))
                        .lineLimit(1)
                    
                    // Date of the event with modifying parameters
                    Text(event.date, style: .date)
                        .font(.caption)
                        .foregroundColor(AppColors.text.opacity(0.7))
                    
                    // Price of the event IF there is a price
                    if let price = event.price
                    {
                        Text("Starting at $\(price, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(AppColors.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
        }
    }
    
    // Pretty self explanatory empty view.
    private var emptyStateView: some View
    {
        // Simple VStack that formats the necessary information
        VStack(spacing: 20)
        {
            // A quick image for UI purposes
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 70))
                .foregroundColor(AppColors.secondary.opacity(0.7))
                .padding()
            
            // Explanation text mentioning that no events were found and to adjust preferences to find more events
            Text("No Events Found")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Try adjusting your preferences or location to find more events.")
                .font(.body)
                .foregroundColor(AppColors.text.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            // A refresh button for this view as well that acts just as the toolbar button does in the regular event view. However, this time it is an actual button because it is essentially the main focus of the view
            Button(action: {
                viewModel.fetchEvents()
            }) {
                Text("Refresh")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 12)
                    .background(AppColors.primary)
                    .cornerRadius(10)
            }
            .padding(.top, 10)
        }
        .padding()
    }
}

// Preview that was used to test UI
#Preview {
    LaunchView()
        .modelContainer(for: [Event.self, UserPreferences.self])
}

