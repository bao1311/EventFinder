//
//  View_EventDetailed.swift
//  EventFinder
//
//  Finished by Gia Bao Phi and Shashank Rao on 4/17/25.
//

import SwiftUI
import MapKit

// This is one of the View sections which deals with the event detailed view process
// This is in alignment with the View portion of the MVVM
// The reason the Views have been separated into different files is because, when making an application look nice, the View's generally take a lot of lines to configure everything nicely. For all the different views we have, it would be around 700 lines of code, which would look really clunky. As a result, we have decided that the best approach is to split them up, so that no one file seems too overwhelming or complicated

// The main struct that handles the detailed view
struct EventDetailView: View
{
    // The necessary stuff
    // Obviously passed in an Event for which it is making the detailed view, but we also need the VM
    // Additionally, we need map based variables to make implementation easier
    // Finally, there is a openURl tool that is necessary because part of our detailed view is to redirect the user to the Ticketmaster website so that they can actually sign up for the event in question.
    let event: Event
    @ObservedObject var viewModel: EventFinderViewModel
    @State private var region: MKCoordinateRegion
    @State private var mapAnnotations: [EventAnnotation] = []
    @Environment(\.openURL) private var openURL
    
    // A quick initialization just to get some values in the region and map annotations
    // Researching online showed that this is a good standard to help with performance and load times
    init(event: Event, viewModel: EventFinderViewModel)
    {
        // Basic declaration
        self.event = event
        self.viewModel = viewModel
        
        // We either initialize it with the event coordinates or default values for a region (ASU's location)
        if let coordinate = event.coordinate
        {
            _region = State(initialValue: MKCoordinateRegion(
                center: coordinate,
                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            ))
            _mapAnnotations = State(initialValue: [EventAnnotation(coordinate: coordinate, title: event.name, subtitle: event.venue)])
        } else {
            _region = State(initialValue: MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 33, longitude: 111),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            ))
        }
    }
    
    var body: some View {
        ScrollView
        {
            // Obviously a main VStack to display all of the information
            VStack(alignment: .leading, spacing: 20)
            {
                // This is the same event image process that we used in the EventListView section. Slightly different modifying parameters for each instance, however, which is why we don't use SwiftUI's Group. For documentation on AsyncImage, see EventListView
                if let imageURL = event.imageURL, let url = URL(string: imageURL)
                {
                    AsyncImage(url: url)
                    { phase in
                        switch phase
                        {
                            case .success(let image):
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                                    .clipped()
                            case .failure(_):
                                // Notably, in the case of a failure, we have a default image option lined up. It is the same logic as in the EventListView section. For more documentation on the process behind it, see EventListView
                                ZStack
                                {
                                    Color(.systemGray6)
                                    Image(systemName: EventType.findById(event.typeId)?.iconName ?? "star.fill")
                                        .font(.system(size: 60))
                                        .foregroundColor(AppColors.secondary)
                                }
                                .frame(height: 200)
                                .frame(maxWidth: .infinity)
                            case .empty:
                                ProgressView()
                                    .frame(height: 200)
                                    .frame(maxWidth: .infinity)
                            @unknown default:
                                EmptyView()
                        }
                    }
                } else {
                    // If no image was provided, once again we just use the same code as for the failure section.
                    ZStack
                    {
                        Color(.systemGray6)
                        Image(systemName: EventType.findById(event.typeId)?.iconName ?? "star.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.secondary)
                    }
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                }
                
                // Another VStack for the text portion of the detailed view
                VStack(alignment: .leading, spacing: 15)
                {
                    // Self explanatory mini VStack to format the main event information | Name and Date
                    VStack(alignment: .leading, spacing: 5)
                    {
                        Text(event.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(formatDate(event.date))
                            .foregroundColor(AppColors.text.opacity(0.7))
                    }
                    
                    // A divider to separate the main information from the venue information. A lot of apps choose to divide information for accessibility and UI appeal, so we decided to do the same.
                    Divider()
                    
                    // This mini VStack handles the Venue section
                    VStack(alignment: .leading, spacing: 10)
                    {
                        // Venue icon and text with appropriate modifying parameters
                        Label("Venue", systemImage: "mappin.and.ellipse")
                            .font(.headline)
                            .foregroundColor(AppColors.primary)
                        
                        // Another mini VStack for the more detailed textual information about the venue. This information is all obviously obtained via the view model from the API call which gives very detailed information.
                        VStack(alignment: .leading, spacing: 5)
                        {
                            // Venue name
                            Text(event.venue)
                                .font(.body)
                                .fontWeight(.medium)
                            
                            // Venue Address
                            Text("\(event.address)")
                                .font(.callout)
                            
                            // Venue geolocation
                            Text("\(event.city), \(event.state) \(event.postalCode)")
                                .font(.callout)
                        }
                        .foregroundColor(AppColors.text)
                    }
                    
                    // Another divider to separate the venue section from the map section and a price section if applicable
                    Divider()
                    
                    // If there is a price for the event, we give a price and then a Divider. However, if not, this section is simply ignored
                    if let price = event.price
                    {
                        // Nothing too fancy, just an HStack with the Label that we did for the previous section and also a price formatting on the other end of the HStack
                        HStack
                        {
                            Label("Starting at", systemImage: "dollarsign.circle.fill")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                            
                            Spacer()
                            
                            Text("$\(price, specifier: "%.2f")")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(AppColors.secondary)
                        }
                        
                        Divider()
                    }
                    
                    // The map section if there are coordinates to the event
                    if event.coordinate != nil
                    {
                        // Simple mini VStack that first does the Label that we did for previous sections and then the map which we have implemented in multiple previous labs with the appropriate modifying parameters
                        VStack(alignment: .leading, spacing: 10)
                        {
                            Label("Location", systemImage: "map.fill")
                                .font(.headline)
                                .foregroundColor(AppColors.primary)
                            
                            Map(coordinateRegion: $region, annotationItems: mapAnnotations) { annotation in
                                MapMarker(coordinate: annotation.coordinate, tint: AppColors.primary)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                        }
                    }
                    
                    // This is the final section where we let the user go to the Ticketmaster site if they want to actually sign up for the event if a URl was provided by the JSON
                    if let url = event.url {
                        // Once again, a simple mini VStack to format the section
                        VStack(spacing: 6)
                        {
                            // First, a text informing the user what the button does with the appropriate modifying parameters
                            Text("Get tickets directly from the provider:")
                                .font(.caption)
                                .foregroundColor(AppColors.text.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center)
                            
                            // This button opens the URL when clicked, redirecting the user
                            Button(action: {
                                if let eventURL = URL(string: url)
                                {
                                    openURL(eventURL)
                                }
                            }) {
                                // This simple mini HStack just explains the meaning of the button letting the user know where they will be heading
                                HStack
                                {
                                    Text("Get Tickets on Ticketmaster")
                                        .fontWeight(.semibold)
                                    
                                    Spacer()
                                    
                                    // Additionally, this is a good standard icon to signify users of redirecting
                                    Image(systemName: "arrow.up.right.square")
                                }
                                .padding()
                                .foregroundColor(.white)
                                .background(AppColors.primary)
                                .cornerRadius(10)
                            }
                        }
                        .padding(.top, 10)
                    }
                }
                .padding()
            }
        }
        // Appropriate modifying parameters
        .navigationTitle("Event Details")
        .navigationBarTitleDisplayMode(.inline)
        .background(AppColors.background)
    }
    
    // Nice helper function that formats the date and time. Just makes it look a lot cleaner and DateFormatter() lets us do it really easily.
    /*
     https://medium.com/@jpmtech/swiftui-format-dates-and-times-the-easy-way-fc896b25003b
     */
    // This documentation explained it all very well
    private func formatDate(_ date: Date) -> String
    {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// Preview used to help see UI changes when developing
#Preview {
    LaunchView()
        .modelContainer(for: [Event.self, UserPreferences.self])
}
