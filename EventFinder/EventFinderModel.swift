//
//  EventFinderModel.swift
//  EventFinder
//
//  Finished by Gia Bao Phi and Shashank Rao on 4/17/25.
//

import SwiftUI
import SwiftData
import MapKit

// This is the Model portion of the app which fulfills the Model section of MVVM architecture.

// The Event class with @Model to signify that it can and should be stored in SwiftData
@Model
class Event
{
    // Populate with all the necessary variables that are worth storing.
    // Some are optional because they may not be included and we need to account for that.
    var id: String
    var name: String
    var date: Date
    var imageURL: String?
    var desc: String?
    var price: Double?
    var venue: String
    var address: String
    var city: String
    var state: String
    var postalCode: String
    var latitude: Double?
    var longitude: Double?
    var url: String?
    var isSaved: Bool
    var typeId: String
    
    // Initializer, pretty self explanatory and necessary
    init(id: String, name: String, date: Date, imageURL: String? = nil, description: String? = nil,
         price: Double? = nil, venue: String, address: String, city: String, state: String,
         postalCode: String, latitude: Double? = nil, longitude: Double? = nil, url: String? = nil,
         isSaved: Bool = false, typeId: String)
    {
        self.id = id
        self.name = name
        self.date = date
        self.imageURL = imageURL
        self.desc = description
        self.price = price
        self.venue = venue
        self.address = address
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.latitude = latitude
        self.longitude = longitude
        self.url = url
        self.isSaved = isSaved
        self.typeId = typeId
    }
}

// Minor extension to the Event class to add a coordinate variable and address variable.
// The coordinate is used in order to map the event on a map in the detailed view, but it is an extension
// because we don't need it right away. We only need it after the API call which is why we leave it as an extension
extension Event
{
    var coordinate: CLLocationCoordinate2D? {
        guard let latitude = latitude, let longitude = longitude else { return nil }
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var fullAddress: String {
        return "\(venue)\n\(address)\n\(city), \(state) \(postalCode)"
    }
}

// UserPreferences class. We also need to store this in SwiftData, hence the @Model
@Model
class UserPreferences
{
    // Var for the selected event types as well as the location
    var selectedEventTypes: [String]
    var location: String
    
    // This is a nifty variable used to keep track of whether the user has completed the onboarding process or not.
    // If they have, we don't need to show them the preferences screen again and they can go right to seeing the events on relaunch of the app
    var hasOnboarded: Bool
    
    // Basic initializer
    init(selectedEventTypes: [String] = [], location: String = "", hasOnboarded: Bool = false)
    {
        self.selectedEventTypes = selectedEventTypes
        self.location = location
        self.hasOnboarded = hasOnboarded
    }
}

// Struct for Event Types. This is obviously identifiable but it is also Hashable. This is because we would like to use this in sets/dictionaries, and making it Hashable makes it INFINITELY easier to do this
/*
 https://developer.apple.com/documentation/swift/hashable
 */
struct EventType: Identifiable, Hashable
{
    let id: String
    let name: String
    let segmentID: String
    let iconName: String
    
    // Predefined event to match the Ticketmaster segments
    // This makes it easier for API calling because we use the ID that Ticketmaster will be familiar with
    static let allTypes: [EventType] = [
        EventType(id: "KZFzniwnSyZfZ7v7nJ", name: "Music", segmentID: "KZFzniwnSyZfZ7v7nJ", iconName: "music.note"),
        EventType(id: "KZFzniwnSyZfZ7v7nE", name: "Sports", segmentID: "KZFzniwnSyZfZ7v7nE", iconName: "sportscourt"),
        EventType(id: "KZFzniwnSyZfZ7v7na", name: "Arts & Theater", segmentID: "KZFzniwnSyZfZ7v7na", iconName: "theatermasks"),
        EventType(id: "KZFzniwnSyZfZ7v7nn", name: "Family", segmentID: "KZFzniwnSyZfZ7v7nn", iconName: "figure.2.and.child.holdinghands"),
        EventType(id: "KZFzniwnSyZfZ7v7nl", name: "Comedy", segmentID: "KZFzniwnSyZfZ7v7nl", iconName: "face.smiling"),
        EventType(id: "KZFzniwnSyZfZ7v7n1", name: "Miscellaneous", segmentID: "KZFzniwnSyZfZ7v7n1", iconName: "ellipsis.circle")
    ]
    
    // Helper function to find event types by ID. Helpful when it comes to the logic in the View Model
    static func findById(_ id: String) -> EventType?
    {
        return allTypes.first { $0.id == id }
    }
}

// This is a helper struct that is used in the EventDetailView. It helps for the UI layout of our map
struct EventAnnotation: Identifiable
{
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let title: String
    let subtitle: String
}

// Defining the AppColors in the Model simply assigning them the value that we have already given in the Assets file.
// This was a step taken to bring our app's UI appeal to the next level, as having a consistent color scheme makes the whole thing look much better.
// Additionally, the colors we chose are of various hex codes that don't naturally show in SwiftUI's basic color option, so we needed it.
struct AppColors
{
    static let primary = Color("PrimaryColor")
    static let secondary = Color("SecondaryColor")
    static let background = Color("BackgroundColor")
    static let text = Color("TextColor")
    static let accent = Color("AccentColor")
    static let VGridbackground = Color("VGridColor")
}


// Codable API response structs from the Ticketmaster API
struct TicketmasterResponse: Codable
{
    // This is what it contains
    let embedded: Embedded?
    let page: Page
    
    // However, it contains an underscore for some reason and I didn't want the variable names to start with an underscore so I found this trick
    /*
     https://developer.apple.com/documentation/swift/codingkey
     */
    // This way, I can map the embedded case to the _embedded key in the JSON format.
    enum CodingKeys: String, CodingKey
    {
        case embedded = "_embedded"
        case page
    }
    
    // Embedded contains a lot of events, so we use an array of another struct as highlighted in class slides
    struct Embedded: Codable
    {
        let events: [TicketmasterEvent]
    }
    
    // the page struct is pretty self explanatory, we just take it from the JSON output
    struct Page: Codable
    {
        let totalElements: Int
        let totalPages: Int
        let size: Int
        let number: Int
    }
}

// The mini struct inside the embedded variable in the initial JSON
struct TicketmasterEvent: Codable, Identifiable
{
    // Pretty self explanatory fields except for the second embedded variable
    let id: String
    let name: String
    let url: String?
    let dates: Dates
    let images: [Image]?
    let priceRanges: [PriceRange]?
    let embedded: Embedded?
    let classifications: [Classification]?
    
    // Because there is another embedded variable, we need to use coding key to match it to the _ version which allows for the JSON output to get read accurately.
    enum CodingKeys: String, CodingKey
    {
        case id, name, url, dates, images, priceRanges
        case embedded = "_embedded"
        case classifications
    }
    
    // Self explanatory setting up the date struct
    struct Dates: Codable
    {
        let start: Start
        
        struct Start: Codable
        {
            let dateTime: String?
            let localDate: String?
            let localTime: String?
        }
    }
    
    // Self explanatory setting up the image struct. The ticketmaster JSON gives image URL's which is handy to us when displaying the view in Event List View so we take extra precaution to make sure we receive this field.
    struct Image: Codable
    {
        let url: String
        let ratio: String?
        let width: Int
        let height: Int
    }
    
    // Self explanatory price range struct
    struct PriceRange: Codable
    {
        let min: Double
        let max: Double
        let currency: String
    }
    
    // The second embedded field
    struct Embedded: Codable
    {
        // Contains a var: venue's which may be an array
        let venues: [Venue]?
    
        // The venue struct is listed here with all of the appropriate information, along with any mini structs that it also needs because of object relationships.
        struct Venue: Codable
        {
            let name: String
            let city: City
            let state: State?
            let country: Country
            let address: Address?
            let postalCode: String?
            let location: Location?
            
            struct City: Codable
            {
                let name: String
            }
            
            struct State: Codable
            {
                let name: String
                let stateCode: String?
            }
            
            struct Country: Codable
            {
                let name: String
                let countryCode: String
            }
            
            struct Address: Codable
            {
                let line1: String?
            }
            
            // Rather important field that gives us the location of the event in terms of latitude and longitude
            // This will be very useful for putting it on a map in the detailed view
            struct Location: Codable
            {
                let latitude: String?
                let longitude: String?
            }
        }
    }
    
    // Finally, a classification struct that is also part of the JSON output in the event section.
    struct Classification: Codable
    {
        // Pretty self explanatory, just basic stuff that the field dictates we need.
        let segment: Segment?
        
        struct Segment: Codable
        {
            let id: String
            let name: String
        }
    }
}
