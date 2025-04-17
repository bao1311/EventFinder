//
//  EventFinderViewModel.swift
//  EventFinder
//
//  Finished by Gia Bao Phi and Shashank Rao on 4/17/25.
//

import SwiftUI
import SwiftData
import Combine

// This is the View Model portion of the app which fulfills the View Model section of the MVVM architecture.
// All of the logic is handled here such as making API calls, populating the necessary structs, putting things in data, fetching things from data, etc.
// It communicates with the Views and the Model accordingly to ensure a functioning app with proper responsibilities

// Interestingly enough, we only needed the one ViewModel because most of the functionalities we needed the view model to handle didn't need separate VM's.
class EventFinderViewModel: ObservableObject
{
    // Necessary published variables that we simply just need
    @Published var events: [Event] = []
    @Published var selectedEventTypes: [String] = []
    @Published var location: String = ""
    
    // Helpful bookkeeping variables that contain potential error messages and booleans that help determine what state the user is in.
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    @Published var hasOnboarded: Bool = false
    
    // Private variables that we need in order to handle logic and functionalities
    private let ticketmasterAPIKey = "oSqh6kV1oEGFrQZqxHyIAN8fi2hFX54g"
    private var modelContext: ModelContext?
    private var cancellables = Set<AnyCancellable>()
    
    // Initialize the model context using our helper function. Same as Shashank's Lab 6 implementation
    init(modelContext: ModelContext? = nil)
    {
        self.modelContext = modelContext
        loadUserPreferences()
    }
    
    // The helper function to load the model context
    func loadUserPreferences()
    {
        guard let modelContext = modelContext else { return }
        
        do
        {
            // use Fetch Descriptor just like Shashank's Lab 6 implementation to get the user preferences that may be in SwiftData
            let descriptor = FetchDescriptor<UserPreferences>()
            let preferences = try modelContext.fetch(descriptor)
            
            // If they exist, we can populate the appropriate fields with what we see in SwiftData.
            // Additionally, existence implies that the user has opened the app before and completed the onboarding process, which means we do not need
            // to show them the user preferences screen again. This boolean helps with that logic
            if let userPrefs = preferences.first
            {
                self.selectedEventTypes = userPrefs.selectedEventTypes
                self.location = userPrefs.location
                self.hasOnboarded = userPrefs.hasOnboarded
                
                // If the user has onboarded, we can just fetch the events immediately based on what the preferences
                // Of course, the user can always go back and update their preferences/location for other updates.
                if hasOnboarded && !location.isEmpty
                {
                    fetchEvents()
                }
            } else {
                // If they don't exist, we will insert the default user preferences into user data so that there is something. Notably,
                // we don't set the onboarding variable so the user will be prompted to select preferences naturally.
                let newPrefs = UserPreferences()
                modelContext.insert(newPrefs)
                try modelContext.save()
            }
        } catch {
            self.error = "Failed to load preferences: \(error.localizedDescription)"
        }
    }
    
    // This helper function saves user preferences to SwiftData
    func saveUserPreferences()
    {
        guard let modelContext = modelContext else { return }
        
        do
        {
            // Same use of FetchDescriptor as in the other function
            let descriptor = FetchDescriptor<UserPreferences>()
            let preferences = try modelContext.fetch(descriptor)
            
            // Initial check to see if we h ave the preferences from data
            if let userPrefs = preferences.first
            {
                userPrefs.selectedEventTypes = self.selectedEventTypes
                userPrefs.location = self.location
                userPrefs.hasOnboarded = true
            // This is the new logic, we create new UserPreferences based on what the user has selected
                // Then we save it to the SwiftData and update the boolean so that on further launches of the app, we will not have to prompt them with user preferences since they already exist
                // Of course, they can always change it if they desire.
            } else {
                let newPrefs = UserPreferences(
                    selectedEventTypes: self.selectedEventTypes,
                    location: self.location,
                    hasOnboarded: true
                )
                modelContext.insert(newPrefs)
            }
            
            try modelContext.save()
        } catch {
            self.error = "Failed to save preferences: \(error.localizedDescription)"
        }
    }
    
    // Simple helper function to highlight the onboarding process as complete. If the user has selected user preferences, we save it to swift data and display events for them
    // This signifies the completion of the onboarding process and, as mentioned above, the user will not be prompted with user preferences on relaunch.
    func completeOnboarding()
    {
        hasOnboarded = true
        saveUserPreferences()
        fetchEvents()
    }
    
    // Crucial function that fetches events through API calls and displays them.
    func fetchEvents()
    {
        // We can't get events if there is no location entered, so we prompt an error | A location is PIVOTAL
        // We can deal with no event preferences, but not an empty location field.
        guard !location.isEmpty else
        {
            self.error = "Please enter a location"
            return
        }
        
        // Simple UI feature of showing a spinning loading wheel while events are populating
        // Additionally, set the error message back to nil because we will need a fresh one for potential API errors
        isLoading = true
        error = nil
        
        // We need a segment query because it is entirely possible, and even likely, that the user will have multiple preferences selected. Because of this, we will need to segment it with all of the possible preferences chosen.
        let segmentQuery = selectedEventTypes.isEmpty ? "" : "&segmentId=\(selectedEventTypes.joined(separator: ","))"
        
        // Craft the appropriate URL string using our housekeeping values
        /*
         https://developer.apple.com/documentation/foundation/nsstring/addingpercentencoding(withallowedcharacters:)
         */
        // Additionally, the above makes it so that our application doesn't break if the location input had some funky characters.
        let urlString = "http://app.ticketmaster.com/discovery/v2/events.json?apikey=\(ticketmasterAPIKey)&city=\(location.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&size=50\(segmentQuery)"
        
        // Check the validity of the URL string as per specifications
        guard let url = URL(string: urlString) else
        {
            self.isLoading = false
            self.error = "Invalid URL"
            return
        }
        
        // URLSession.shared.dataTask was too slow. Because we sometimes have 50 events to display, it can take a long time when using a manual dispatch
        // After doing some research, this is much faster and it is also automatic because it will do the DispatchQueue automatically
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .decode(type: TicketmasterResponse.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            // Additionally, for the handling, what is often used with dataTaskPublisher is sink with receiveCompletion and receiveValue
            /*
             https://developer.apple.com/documentation/combine/publisher/sink(receivecompletion:receivevalue:)
             */
            /*
             https://medium.com/@ramdhas/understanding-the-sink-operator-in-combine-framework-d622bd9fd960
             */
            // The following articles were very helpful in figuring out how to use it
            // Essentially, it checks if the request fails and, if it does, it will show an error.
            // However, if it is successful, it will parse the response appropriately and update the necessary components which will update the views
            // We wanted to go above and beyond with this project, which includes efficiency, which is why we took the time to learn the fastest way to fetch API's and update views accordingly, since that was the slowest portion of our program.
            .sink(receiveCompletion: { [weak self] completion in
                self?.isLoading = false
                
                if case .failure(let error) = completion {
                    self?.error = "Failed to fetch events: \(error.localizedDescription)"
                }
            }, receiveValue: { [weak self] response in
                guard let self = self else { return }
                
                // This is where we use the response in order to convert the API JSON response into events using a helper function
                self.events = self.convertToEvents(from: response)
            })
            .store(in: &cancellables)
    }
    
    // This is the helper function that converts the JSON format into the Events that we use.
    private func convertToEvents(from response: TicketmasterResponse) -> [Event]
    {
        // Check if there are even events in the response, otherwise just return an empty list.
        guard let apiEvents = response.embedded?.events else { return [] }
        
        // If there are events, we will parse through it here
        return apiEvents.compactMap
        { apiEvent in
            // First, we grab the date using a date formatter that Shashank has used in previous labs and one that Ticketmaster's API is gracious enough to follow
            let dateFormatter = ISO8601DateFormatter()
            var eventDate = Date()
            // This grabs the date
            if let dateTimeString = apiEvent.dates.start.dateTime
            {
                if let date = dateFormatter.date(from: dateTimeString)
                {
                    eventDate = date
                }
            // However, sometimes the date isn't given, so our default is to just use the local date and local time, although this is a last resort and we really hope that it isn't the case.
            } else if let localDate = apiEvent.dates.start.localDate, let localTime = apiEvent.dates.start.localTime{
                if let date = DateFormatter().date(from: "\(localDate) \(localTime)") {
                    eventDate = date
                }
            }
            
            // Grab information about the venue, this is important
            let venue = apiEvent.embedded?.venues?.first
            
            // Grab the image url which we will use to display an image of the event. Ideally, we want the ratio to be 16:9 because it fits best with the views, but if it isn't possible, we grab the first image and just work with it and ensure scalability in the View section.
            let imageURL = apiEvent.images?.first(where: { $0.ratio == "16_9" })?.url ?? apiEvent.images?.first?.url
            
            // Pricing is very important, so we see if it is possible to get a price. We list the minimum as is the standard for event finder apps.
            let price = apiEvent.priceRanges?.first?.min
            
            // This lets us obtain the latitude and longitude values.
            // This is critical as we need these values to display the map easier.
            // Of course, we could always just use forward geocoding but if the JSON gives us the latitude and longitude, we might as well use that instead. It will be way more accurate and therefore the app wi ll be better
            var latitude: Double? = nil
            var longitude: Double? = nil
            if let latString = venue?.location?.latitude, let latDouble = Double(latString) {
                latitude = latDouble
            }
            if let lngString = venue?.location?.longitude, let lngDouble = Double(lngString) {
                longitude = lngDouble
            }
            
            // This gets the segment ID which in turn gets the event type which will be useful again in the detailed view
            let typeId = apiEvent.classifications?.first?.segment?.id ?? ""
            
            // With all the values obtained, we fill in an event struct and return it
            // Some checking for unknown values and default options are given in case the values are unknown
            return Event(
                id: apiEvent.id,
                name: apiEvent.name,
                date: eventDate,
                imageURL: imageURL,
                description: nil,
                price: price,
                venue: venue?.name ?? "Unknown Venue",
                address: venue?.address?.line1 ?? "Unknown Address",
                city: venue?.city.name ?? "Unknown City",
                state: venue?.state?.name ?? "Unknown State",
                postalCode: venue?.postalCode ?? "Unknown Postal Code",
                latitude: latitude,
                longitude: longitude,
                url: apiEvent.url,
                isSaved: false,
                typeId: typeId
            )
        // Sort by date so that the events are sorted by date when displayed
        }.sorted { $0.date < $1.date }
    }
}
