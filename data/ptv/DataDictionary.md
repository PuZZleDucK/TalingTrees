agency_id
    Name: Agency ID
    Type: VARCHAR(20)
    Description: Identifies a transit brand (often synonymous with a transit agency). A dataset may include multiple agencies.
    Fixed Values: (none)

agency_name
    Name: Agency Name
    Type: VARCHAR(500)
    Description: Full official name of the transit agency.

agency_url
    Name: Agency URL
    Type: VARCHAR(500)
    Description: Web address for the transit agency’s homepage.

agency_timezone
    Name: Agency Timezone
    Type: VARCHAR(19)
    Description: Timezone where the agency operates. All agencies in one dataset must share the same timezone.

agency_lang
    Name: Agency Language
    Type: VARCHAR(2)
    Description: Primary language code used by the agency, to guide language-specific formatting.

agency_fare_url
    Name: Agency Fare URL
    Type: VARCHAR(500)
    Description: Web page URL where riders can purchase tickets or fare media online.

service_id (calendar)
    Name: Service ID – calendar
    Type: VARCHAR(50)
    Description: Identifies a recurring service schedule, defined by start_date, end_date, and weekdays.

service_id (calendar_dates)
    Name: Service ID – calendar dates
    Type: VARCHAR(50)
    Description: Identifies an exception date record for a service. Overrides calendar.txt entries if duplicated.

date
    Name: Date
    Type: VARCHAR(8)
    Description: Exception date (YYYYMMDD) for the given service.

exception_type
    Name: Exception Type
    Type: VARCHAR(50)
    Description: Indicates if service is added or removed on that date.
    Fixed Values: 1 (Service Added), 2 (Service Removed)

level_id (levels)
    Name: Level ID
    Type: STRING(10)
    Description: Unique identifier for a level (floor) within a station.

level_index
    Name: Level Index
    Type: FLOAT(2)
    Description: Numeric order of levels: 0 = ground, positive = above, negative = below.

pathway_id
    Name: Pathway ID
    Type: VARCHAR(30)
    Description: Unique identifier for a pedestrian pathway.

from_stop_id
    Name: From Stop ID
    Type: VARCHAR(30)
    Description: Stop or station where the pathway begins.

to_stop_id
    Name: To Stop ID
    Type: VARCHAR(30)
    Description: Stop or station where the pathway ends.

pathway_mode
    Name: Pathway Mode
    Type: ENUM(1)
    Description: Type of connection between stops.
    Fixed Values:
    1 (Walkway), 2 (Stairs), 3 (Moving sidewalk), 4 (Escalator),
    5 (Elevator), 6 (Fare gate), 7 (Exit gate)

is_bidirectional
    Name: Is Bidirectional
    Type: ENUM(1)
    Description: Whether the pathway can be used both ways.
    Fixed Values:
    0 (One-way: from → to), 1 (Bidirectional)

traversal_time
    Name: Traversal Time
    Type: INT(5)
    Description: Average time in seconds to walk the pathway.

route_id (routes)
    Name: Route ID
    Type: VARCHAR(20)
    Description: Unique identifier for a transit route.

route_short_name
    Name: Route Short Name
    Type: VARCHAR(100)
    Description: Abbreviated route identifier (e.g. “32”, “Green”).

route_long_name
    Name: Route Long Name
    Type: VARCHAR(200)
    Description: Full descriptive name, often including destinations.

route_type
    Name: Route Type
    Type: INT(10)
    Description: Mode of transport for the route.
    Fixed Values:
    0 (Tram), 1 (Metro), 2 (Rail), 3 (Bus), 4 (Ferry),
    5 (Cable tram), 6 (Aerial lift), 7 (Funicular),
    11 (Trolleybus), 12 (Monorail)

route_color
    Name: Route Colour
    Type: VARCHAR(50)
    Description: Hex color for route branding; default FFFFFF (white).

route_text_color
    Name: Route Text Colour
    Type: VARCHAR(50)
    Description: Hex color for text on route_color background; default 000000 (black).

shape_id (shapes)
    Name: Shape ID
    Type: VARCHAR(30)
    Description: Identifier for a geospatial polyline describing a trip’s path.

shape_pt_lat
    Name: Shape Point Latitude
    Type: DECIMAL(20)
    Description: Latitude of a point along the shape.

shape_pt_lon
    Name: Shape Point Longitude
    Type: DECIMAL(20)
    Description: Longitude of a point along the shape.

shape_pt_sequence
    Name: Shape Point Sequence
    Type: INT(10)
    Description: Order index for connecting shape points (must increase).

shape_dist_traveled (shapes)
    Name: Shape Distance Traveled
    Type: VARCHAR(50)
    Description: Cumulative distance along the shape from the first point (used for mapping).

stop_id (stops)
    Name: Stop ID
    Type: INT(10)
    Description: Unique identifier for a stop, platform, station, or boarding area.

stop_name
    Name: Stop Name
    Type: VARCHAR(100)
    Description: Official rider-facing name of the location.

stop_lat
    Name: Stop Latitude
    Type: DECIMAL(20)
    Description: Latitude of the boarding location (pole or platform edge).

stop_lon
    Name: Stop Longitude
    Type: DECIMAL(20)
    Description: Longitude of the boarding location (pole or platform edge).

location_type
    Name: Location Type
    Type: VARCHAR(2)
    Description: Indicates kind of location.
    Fixed Values: 0 (Stop), 1 (Station), 2 (Entrance/Exit), 3 (Generic node), 4 (Boarding area)

parent_station
    Name: Parent Station
    Type: VARCHAR(20)
    Description: ID of the parent station for hierarchy in stops.

wheelchair_boarding
    Name: Wheelchair Boarding
    Type: ENUM(1)
    Description: Accessibility information for the stop.
    Fixed Values: 0 or empty (Unknown), 1 (Accessible), 2 (Not accessible)

level_id (stops)
    Name: Level ID
    Type: STRING(10)
    Description: Level (floor) identifier for multi-level stations.

platform_code
    Name: Platform Code
    Type: VARCHAR(2)
    Description: Short platform label (e.g. “G”, “3”) without words like “Platform.”

trip_id (stop_times)
    Name: Trip ID
    Type: VARCHAR(30)
    Description: Identifier for a single vehicle journey.

arrival_time
    Name: Arrival Time
    Type: VARCHAR(8)
    Description: Scheduled arrival at the stop (HH:MM:SS).

departure_time
    Name: Departure Time
    Type: VARCHAR(8)
    Description: Scheduled departure from the stop (HH:MM:SS).

stop_id (stop_times)
    Name: Stop ID (stop_times)
    Type: INTEGER(10)
    Description: ID of the stop being serviced; must refer to a valid stop/platform.

stop_sequence
    Name: Stop Sequence
    Type: INT(10)
    Description: Order of stops on a trip; must increase but need not be consecutive.

stop_headsign
    Name: Stop Headsign
    Type: VARCHAR(50)
    Description: Text displayed at that stop, overriding trips.trip_headsign if needed.

pickup_type
    Name: Pickup Type
    Type: INT(10)
    Description: Conditions for passengers boarding.
    Fixed Values: 0 or empty (Regular), 1 (None), 2 (Phone agency), 3 (Arrange with driver)

drop_off_type
    Name: Drop Off Type
    Type: INT(10)
    Description: Conditions for passengers alighting.
    Fixed Values: 0 or empty (Regular), 1 (None), 2 (Phone agency), 3 (Arrange with driver)

shape_dist_traveled (stop_times)
    Name: Shape Distance Traveled (stop_times)
    Type: VARCHAR(50)
    Description: Portion of the shape to draw up to this stop; units match shapes.txt.

route_id (trips)
    Name: Route ID (trips)
    Type: VARCHAR(20)
    Description: Reference to a route in routes.txt.

service_id (trips)
    Name: Service ID (trips)
    Type: VARCHAR(50)
    Description: Reference to a service schedule in calendar.txt or exceptions in calendar_dates.txt.

trip_id (trips)
    Name: Trip ID (trips)
    Type: VARCHAR(30)
    Description: Unique trip identifier (same as in stop_times.txt).

trip_headsign
    Name: Trip Headsign
    Type: VARCHAR(50)
    Description: Default display text for the entire trip (destination or pattern).

direction_id
    Name: Direction ID
    Type: INT(10)
    Description: Indicates direction of travel (for timetable separation).
    Fixed Values: 0 (Outbound), 1 (Inbound)

block_id
    Name: Block ID
    Type: VARCHAR(10)
    Description: Allows grouping sequential trips on the same vehicle.

shape_id (trips)
    Name: Shape ID (trips)
    Type: VARCHAR(30)
    Description: Reference to the path shape for this trip.

wheelchair_accessible
    Name: Wheelchair Accessible
    Type: ENUM(1)
    Description: Indicates if the vehicle for this trip is accessible.
    Fixed Values: 0 or empty (Unknown), 1 (Accessible), 2 (Not accessible)

